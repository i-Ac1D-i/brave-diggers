local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local reuse_scrollview = require "widget.reuse_scrollview"
local config_manager = require "logic.config_manager"

local PLIST_TYPE = ccui.TextureResType.plistType
local ENTERFOR_STATUS ={
      ["UNENTER"] = 1,
      ["ENTERED"] = 2,
}

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 114
local FIRST_SUB_PANEL_OFFSET = -60
local MAX_SUB_PANEL_NUM = 7

local cell_panel = panel_prototype.New(true)

cell_panel.__index = cell_panel

function cell_panel.New()
    local t = {}
    return setmetatable(t, cell_panel)
end

function cell_panel:Init(root_node)
    self.root_node = root_node

    self.buff_text = self.root_node:getChildByName("buff_number")
    self.bp_text = self.root_node:getChildByName("bp_value")
    self.name_text = self.root_node:getChildByName("name")

    self.detail_btn = self.root_node:getChildByName("detail_btn")

    self.role_bg = self.root_node:getChildByName("bg_0")
    self.role_img = self.role_bg:getChildByName("icon")

    self.role_bg:ignoreContentAdaptWithSize(true)
    self.role_img:ignoreContentAdaptWithSize(true)

    self.role_img:setScale(2, 2)

    self:RegisterWidgetEvent()
end

function cell_panel:Show(member)

    self.member = member 

    self.name_text:setString(self.member.leader_name)
    self.bp_text:setString(tostring(self.member.bp))
    self.buff_text:setString(tostring(self.member.buff_num))

    local conf = config_manager.mercenary_config[self.member.template_id]
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)

    self.root_node:setVisible(true)
end

function cell_panel:RegisterWidgetEvent()

    self.detail_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:QueryMemberTroop(self.member.user_id, client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"]["view"])   
        end
    end)
end


local camp_panel = panel_prototype.New(true)
function camp_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_camp_panel.csb")

    self.title_text = self.root_node:getChildByName("desc")
    self.template_node = self.root_node:getChildByName("template")
    self.template_node:setVisible(false)

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.member_sub_panels = {}
    self.sub_panel_num = 0

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.member_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.member_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.no_warfield_members[index])
        end
    )

    self:RegisterWidgetEvent()
end

function camp_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.member_num)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local member_cell = cell_panel.New()
        member_cell:Init(self.template_node:clone())

        self.member_sub_panels[i] = member_cell
        member_cell:GetRootNode():setPositionX(258)

        self.scroll_view:addChild(member_cell:GetRootNode()) 
    end

    self.sub_panel_num = num
end

function camp_panel:Show()
    self.title_text:setString(lang_constants:GetFormattedStr("guild_war_camp_member_not_in_war", guild_logic:GetMembersInWarField(client_constants["NO_WAR_FIELD"])))

    self.no_warfield_members = guild_logic:GetFieldMembersByField(client_constants["NO_WAR_FIELD"])
    table.sort(self.no_warfield_members, function(a, b) return a.bp > b.bp end)

    self.member_num = #self.no_warfield_members

    self:CreateSubPanels()

    local height = self.reuse_scrollview:CalcHeight()

    for i = 1, self.sub_panel_num do
        local sub_panel = self.member_sub_panels[i]
        local member = self.no_warfield_members[i]

        if member then
            sub_panel:Show(member)
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end

function camp_panel:UpdateEnterForStatus()
    self.enter_for_btn:setVisible(false)
    self.un_enter_for_btn:setVisible(false)
    if guild_logic:IsEnterForCurrentWar() then 
        self.enter_for_btn:setTitleText(lang_constants:Get("guild_war_enterfor_tip2"))
        self.enter_for_btn:setTag(ENTERFOR_STATUS["ENTERED"])
        self.enter_for_btn:setVisible(true)
    else
        if guild_logic:IsGuildChairman() or guild_logic:IsGuildManager() then 
           self.enter_for_btn:setTitleText(lang_constants:Get("guild_war_enterfor_tip1"))
           self.enter_for_btn:setTag(ENTERFOR_STATUS["UNENTER"])
           self.enter_for_btn:setVisible(true)
        else
           self.un_enter_for_btn:setVisible(true)
        end
    end
end

function camp_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return camp_panel

