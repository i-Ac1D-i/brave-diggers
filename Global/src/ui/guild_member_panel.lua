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

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 118
local FIRST_SUB_PANEL_OFFSET = -80

local member_sub_panel = panel_prototype.New()
member_sub_panel.__index = member_sub_panel

function member_sub_panel.New()
    return setmetatable({}, member_sub_panel)
end

function member_sub_panel:Init(root_node, tag)

    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)

    self.tag = tag
    self.name_text = root_node:getChildByName("name")
    self.login_time_text = root_node:getChildByName("login_time")

    self.change_btn = root_node:getChildByName("change_btn")
    self.remove_btn = root_node:getChildByName("removed_btn")

    self.role_node = root_node:getChildByName("role")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node)
    self.icon_panel:SetPosition(56, 60)
    self.icon_panel.root_node:setTouchEnabled(false)

    self.show_btn_flag = false
end

function member_sub_panel:Show()
    
    self.root_node:setVisible(true)
    self.change_btn:setTag(self.tag)
    self.remove_btn:setTag(self.tag)

    local member_info = guild_logic.member_list[self.tag]
    if member_info.user_id == user_logic:GetUserId() then
        self.change_btn:setVisible(false)
        self.remove_btn:setVisible(false)
    else
        self.change_btn:setVisible(self.show_btn_flag)
        self.remove_btn:setVisible(self.show_btn_flag)
    end
    

    if member_info.grade_type == constants["GUILD_GRADE"]["chairman"]  then
        self.name_text:setString(member_info.leader_name .. lang_constants:Get("guild_chairman"))
    else
        self.name_text:setString(member_info.leader_name)
    end

    self.login_time_text:setString(panel_util:GetLastLoginTimeStr(member_info.last_login_time))
    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], member_info.template_id, nil, nil, false)
end


local guild_member_panel = panel_prototype.New(true)
function guild_member_panel:Init()

    self.root_node = cc.CSLoader:createNode("ui/guild_members_panel.csb")
    local root_node = self.root_node

    local member_num_panel = root_node:getChildByName("guild_member_num")
    self.member_num_txt = member_num_panel:getChildByName("time")

    self.more_btn = root_node:getChildByName("more_btn")
    self.delete_btn = root_node:getChildByName("delete_btn")
    self.delete_txt = self.delete_btn:getChildByName("desc")

    self.scroll_view = root_node:getChildByName("scrollview")
    self.sview_inner_height = self.scroll_view:getInnerContainer():getPositionY()
    self.scroll_view:setClippingEnabled(true)
    
    root_node:removeChild(root_node:getChildByName("list_view"))

    self.template = self.root_node:getChildByName("template")
    self.member_sub_panels = {}
    self.sub_panel_num = 0
    self.show_btn_flag = false

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.member_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return guild_logic:GetCurMemberNum()
        end,

        function(self, sub_panel)
            sub_panel:Show()
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function guild_member_panel:ShowSubPanels()

    local nums = guild_logic:GetCurMemberNum()

    if self.sub_panel_num > nums then
        for i = nums + 1, self.sub_panel_num do
            self.member_sub_panels[nums + 1].root_node:setVisible(false)
            self.scroll_view:removeChild(self.member_sub_panels[nums + 1].root_node)
            table.remove(self.member_sub_panels ,nums + 1)
        end

    elseif self.sub_panel_num < nums then
        for i = self.sub_panel_num + 1, nums do
            local sub_panel = member_sub_panel.New()
            sub_panel:Init(self.template:clone(), i)
            self.member_sub_panels[i] = sub_panel
            self.scroll_view:addChild(sub_panel.root_node)

            sub_panel.change_btn:addTouchEventListener(self.change_member_fun)
            sub_panel.remove_btn:addTouchEventListener(self.remove_member_fun)
        end
    end
    self.sub_panel_num = nums

    self.template:setVisible(false)

    local sview_height = self.scroll_view:getContentSize().height
    local sview_width = self.scroll_view:getContentSize().width
    local height = math.max(nums * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, #self.member_sub_panels do
        local pos_x = 272
        local sub_panel = self.member_sub_panels[i]

        sub_panel.root_node:setPosition(pos_x, height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        sub_panel.show_btn_flag = self.show_btn_flag
        sub_panel:Show()
    end

    self.reuse_scrollview:Show(height, 0)
end

function guild_member_panel:Show()
    self.root_node:setVisible(true)

    self.member_num_txt:setString(guild_logic:GetCurMemberNum().."/"..guild_logic:GetMaxMemberNum())

    -- 如果是公会会长的话
    if guild_logic:IsGuildChairman() then
        self.delete_txt:setString(lang_constants:Get("guild_dismiss_text"))
        self.more_btn:setVisible(true)
    else
        self.delete_txt:setString(lang_constants:Get("guild_exit_text"))
        self.more_btn:setVisible(false)
        self.show_btn_flag = false
    end

    self:ShowSubPanels()
end

function guild_member_panel:RegisterEvent()

    graphic:RegisterEvent("update_guild_member", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)
end

function guild_member_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "guild_member_panel")

    self.more_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            -- print("点击更多")
            if guild_logic:IsGuildChairman() then
                self.show_btn_flag = not self.show_btn_flag
                for k, v in pairs(self.member_sub_panels) do
                    v.show_btn_flag = self.show_btn_flag
                    v:Show()
                end
            end
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

    self.remove_member_fun = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local title = lang_constants:Get("guild_msgbox_title_remove")
            local desc = lang_constants:Get("guild_msgbox_desc_remove")
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")
            graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                -- print("移除成员 = ", index)
                if guild_logic.member_list[index] then
                    -- 移除成员
                    guild_logic:FireGuild(guild_logic.member_list[index].user_id)
                end
            end)
        end
    end

    self.change_member_fun = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local title = lang_constants:Get("guild_msgbox_title_change")
            local desc = lang_constants:Get("guild_msgbox_desc_change")
            local confirm = lang_constants:Get("common_confirm")
            local cancel  = lang_constants:Get("common_cancel")
            graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                -- print("转让 = ", index)
                if guild_logic.member_list[index] then
                    -- 转让工会
                    guild_logic:TransferGuild(guild_logic.member_list[index].user_id)
                end
            end)
        end
    end
end

return guild_member_panel
