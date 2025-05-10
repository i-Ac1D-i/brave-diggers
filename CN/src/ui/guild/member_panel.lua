local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local campaign_logic = require "logic.campaign"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local icon_template = require "ui.icon_panel"
local guild_logic = require "logic.guild"
local graphic = require "logic.graphic"
local user_logic = require "logic.user"
local reuse_scrollview = require "widget.reuse_scrollview"
local resource_logic = require "logic.resource"
local feature_config = require "logic.feature_config"

local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local SUB_PANEL_HEIGHT = 118
local FIRST_SUB_PANEL_OFFSET = -80
local MAX_SUB_PANEL_NUM = 7

local manage_panel = panel_prototype.New()
function manage_panel:Init(root_node)
    self.root_node = root_node

    self.member_info = nil 
    self.change_btn = self.root_node:getChildByName("change_btn")
    self.remove_btn = self.root_node:getChildByName("removed_btn")
    self.appoint_btn = self.root_node:getChildByName("appoint_btn")

    self.close_btn = self.root_node:getChildByName("close1_btn")

    self:RegisterWidgetEvent()
end

function manage_panel:Show(data)
    self.member_info = data

    self.change_btn:setVisible(false)
    self.remove_btn:setVisible(false)
    self.appoint_btn:setVisible(false)

    if guild_logic:IsGuildChairman() then 
        self.change_btn:setVisible(true)
        self.remove_btn:setVisible(true)
        self.appoint_btn:setVisible(true) 

        if self.member_info.grade_type == constants["GUILD_GRADE"]["staff"] then 
            self.appoint_btn:setTitleText(lang_constants:Get("guild_member_appoint_title"))

        elseif self.member_info.grade_type == constants["GUILD_GRADE"]["highstaff"] then 
            self.appoint_btn:setTitleText(lang_constants:Get("guild_member_reset_appoint_title"))
        end

    elseif guild_logic:IsGuildManager() then 
        self.remove_btn:setVisible(true)
    end

    self.root_node:setVisible(true)
end

function manage_panel:RegisterWidgetEvent()
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:Hide()
        end
    end)

    self.remove_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local title = lang_constants:Get("guild_msgbox_title_remove")
            local desc = lang_constants:Get("guild_msgbox_desc_remove")
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")
            graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                -- 移除成员
                guild_logic:FireMember(self.member_info.user_id) 
                self:Hide()  
            end)
        end
    end)

    self.change_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local title = lang_constants:Get("guild_msgbox_title_change")
            local desc = lang_constants:Get("guild_msgbox_desc_change")
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")
            graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                -- 转让工会
                guild_logic:TransferGuild(self.member_info.user_id) 
                self:Hide()  
            end)
        end
    end)

    self.appoint_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local title = lang_constants:Get("guild_msgbox_title_reset")
            local desc = lang_constants:Get("guild_msgbox_desc_reset")
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")

            if self.member_info.grade_type == constants["GUILD_GRADE"]["highstaff"] then 
                graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                    -- 转让工会
                    guild_logic:AppointMember(self.member_info.user_id, constants["GUILD_GRADE"]["staff"])  
                    self:Hide() 
                end)
            elseif self.member_info.grade_type == constants["GUILD_GRADE"]["staff"] then 
                guild_logic:AppointMember(self.member_info.user_id, constants["GUILD_GRADE"]["highstaff"])   
                self:Hide()
            end
        end
    end)
end

local member_sub_panel = panel_prototype.New()
member_sub_panel.__index = member_sub_panel

function member_sub_panel.New()
    return setmetatable({}, member_sub_panel)
end

function member_sub_panel:Init(root_node)

    self.root_node = root_node
    self.member_info = nil
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)

    self.name_text = root_node:getChildByName("name")
    self.login_time_text = root_node:getChildByName("login_time_0")

    self.manager_btn = root_node:getChildByName("more_btn")
   
    self.role_node = root_node:getChildByName("role")

    self.contribution_label = root_node:getChildByName("login_time_1")
    self.contribution_icon = root_node:getChildByName("Image_186")
    if self.contribution_label then
        self.contribution_label:setVisible(feature_config:IsFeatureOpen("guild_boss"))
        self.contribution_icon:setVisible(feature_config:IsFeatureOpen("guild_boss"))
    end

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node)
    self.icon_panel:SetPosition(56, 60)
    self.icon_panel.root_node:setTouchEnabled(false)

    self:RegisterWidgetEvent()
end

function member_sub_panel:Show(tag)
    self.root_node:setVisible(true)

    self.tag = tag
    self.manager_btn:setTag(self.tag)

    self.member_info = guild_logic.member_list[self.tag]  

    if self:CheckRights() then 
        self.manager_btn:setVisible(true)
    else
        self.manager_btn:setVisible(false)
    end
    
    local name_text = self.member_info.leader_name
    if self.member_info.grade_type == constants["GUILD_GRADE"]["chairman"]  then
        name_text = self.member_info.leader_name .. lang_constants:Get("guild_chairman")

    elseif self.member_info.grade_type == constants["GUILD_GRADE"]["highstaff"]  then
        name_text = self.member_info.leader_name .. lang_constants:Get("guild_highstaff")
    end

    local contribution = self.member_info.contribution or 0

    if self.member_info.user_id == user_logic:GetUserId() then 
        contribution = resource_logic:GetResourceNum(RESOURCE_TYPE["guild_boss_contribution"])
    end

    if self.contribution_label then
        self.contribution_label:setString(contribution)
    end
    self.name_text:setString(name_text)
    self.login_time_text:setString(panel_util:GetLastLoginTimeStr(self.member_info.last_login_time))
    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], self.member_info.template_id, nil, nil, false)
end

function member_sub_panel:CheckRights()
    if self.member_info.user_id == user_logic:GetUserId() then 
        return false
    end

    if guild_logic:IsGuildChairman() then 
        return true 
    end

    if guild_logic:IsGuildManager() and self.member_info.grade_type == constants["GUILD_GRADE"]["staff"] then 
        return true
    end

    return false
end

function member_sub_panel:RegisterWidgetEvent()
    self.manager_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self:CheckRights() then 
                manage_panel:Show(guild_logic.member_list[widget:getTag()])
            end
        end
    end)
end

local member_panel = panel_prototype.New(true)
function member_panel:Init()

    self.root_node = cc.CSLoader:createNode("ui/guild_members_panel.csb")
    local root_node = self.root_node

    local member_num_panel = root_node:getChildByName("guild_member_num")
    self.member_num_text = member_num_panel:getChildByName("time")

    self.delete_btn = root_node:getChildByName("exit_btn")
    self.delete_text = self.delete_btn:getChildByName("desc_0")

    self.scroll_view = root_node:getChildByName("ScrollView_3")
    self.sview_inner_height = self.scroll_view:getInnerContainer():getPositionY()
    self.scroll_view:setClippingEnabled(true)
    
    self.template = root_node:getChildByName("template")
    self.template:setVisible(false)

    self.member_sub_panels = {}
    self.sub_panel_num = 0
    
    manage_panel:Init(self.root_node:getChildByName("msgbox"))
    manage_panel:Hide()

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.member_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return guild_logic:GetCurMemberNum()
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(index)
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function member_panel:CreateSubPanel()
    local num = math.min(MAX_SUB_PANEL_NUM, guild_logic:GetCurMemberNum())

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = member_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.member_sub_panels[i] = sub_panel
        sub_panel.root_node:setPositionX(self.scroll_view:getContentSize().width/2)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function member_panel:Show()
    self.root_node:setVisible(true)

    self.member_num_text:setString(guild_logic:GetCurMemberNum() .. "/" .. constants.GUILD_MAX_MEMBER)

    -- 公会会长
    if guild_logic:IsGuildChairman() then
        self.delete_text:setString(lang_constants:Get("guild_dismiss_text"))
    else
        self.delete_text:setString(lang_constants:Get("guild_exit_text"))
    end

    guild_logic:SortMemberList(client_constants["MEMBER_SORT_TYPE"]["login_time"])
    
    self:CreateSubPanel()

    local member_list = guild_logic:GetMemberList()

    local height = math.max(#member_list * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, #self.member_sub_panels do
        local sub_panel = self.member_sub_panels[i]

        if member_list[i] then
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
            sub_panel:Show(i)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)
end

function member_panel:RegisterEvent()

    graphic:RegisterEvent("update_guild_member", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("update_guild_member_grade", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("exit_guild", function()
        if not self.root_node:isVisible() then
            return
        end
        graphic:DispatchEvent("hide_world_sub_scene")
    end)
    
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["guild_boss_contribution"]) then
            self:Show()
        end
    end)
end

function member_panel:RegisterWidgetEvent()

    self.root_node:getChildByName("back_btn"):addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene") 
        end
    end)
    
    self.delete_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local title = nil
            local desc = nil
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")
            if guild_logic:IsGuildChairman() then
                title = lang_constants:Get("guild_msgbox_title_delete1")
                desc = lang_constants:Get("guild_msgbox_desc_delete1")
            else
                title = lang_constants:Get("guild_msgbox_title_delete2")
                desc = lang_constants:Get("guild_msgbox_desc_delete2")
            end

            graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                if guild_logic:IsGuildChairman() then
                    guild_logic:DismissGuild()
                else
                    guild_logic:ExitGuild()
                end
            end)
        end
    end)
end

return member_panel
