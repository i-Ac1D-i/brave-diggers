local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local bit_extension = require "util.bit_extension"

local guild_logic = require "logic.guild"

local panel_util = require "ui.panel_util"
local reuse_scrollview = require "widget.reuse_scrollview"

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 160
local FIRST_SUB_PANEL_OFFSET = -20
local MAX_SUB_PANEL_NUM = 7

local single_troop_sub_panel = panel_prototype.New()
single_troop_sub_panel.__index = single_troop_sub_panel

function single_troop_sub_panel.New()
    return setmetatable({}, single_troop_sub_panel)
end

function single_troop_sub_panel:Init(root_node)
    self.root_node = root_node

    self.arm_img = self.root_node:getChildByName("arm_icon")

    self.buff_img = self.root_node:getChildByName("buff_icon")
    self.buff_text = self.root_node:getChildByName("buff_value")
    self.buff_text:setLocalZOrder(2)

    self.bp_text = self.root_node:getChildByName("bp_value")
    self.name_text = self.root_node:getChildByName("name")
    self.view_img = self.root_node:getChildByName("view_icon")
    self.view_img:setLocalZOrder(2)

    self.role_img = self.root_node:getChildByName("role")

    self.arm_img:setTouchEnabled(true)
    self.view_img:setTouchEnabled(true)
end

function single_troop_sub_panel:Show(member)
    self.name_text:setString(member.leader_name)

    self.bp_text:setString(tostring(member.battle_point))
    self.buff_text:setString(tostring(member.buff_num))

    local conf = config_manager.mercenary_config[member.template_id]
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)

    if guild_logic:GetScoutLevel() == 3 then
        self.arm_img:setVisible(true)
        self.view_img:setVisible(true)
        self.buff_img:setVisible(true)
        self.buff_text:setVisible(true)
    else
        self.arm_img:setVisible(false)
        self.view_img:setVisible(false)
        self.buff_img:setVisible(false)
        self.buff_text:setVisible(false)
    end

    self.member = member
    self.user_id = member.user_id
    self.root_node:setVisible(true)
end

local troop_row_panel = panel_prototype.New()
troop_row_panel.__index = troop_row_panel

function troop_row_panel.New()
    return setmetatable({}, troop_row_panel)
end

function troop_row_panel:Init(template, parent_node)
    for i = 1, 3 do
        self[i] = single_troop_sub_panel.New()
        single_troop_sub_panel:Init(template:clone())
        parent_node:addChild(single_troop_sub_panel:GetRootNode())
    end
end

function troop_row_panel:Show()

end

function troop_row_panel:Hide()
    for i = 1, 3 do
        self[i]:Hide()
    end
end

local scout_main_panel = panel_prototype.New(true)
function scout_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guildwar_scout_panel.csb")

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.scout_btn = self.root_node:getChildByName("scout_btn")

    self.member_num_text = self.root_node:getChildByName("num_desc")
    self.enemy_text = self.root_node:getChildByName("enemy_txt")
    self.enemy_num = self.root_node:getChildByName("enemy_num")

    self.desc_text = self.root_node:getChildByName("node_txt")

    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.template = self.scroll_view:getChildByName("template")
    self.template:setVisible(false)

    self.single_troop_sub_panels = {}

    self.tab_btns = {}

    for i = 1, constants["MAX_WAR_FIELDS"] do
        self.tab_btns[i] = self.root_node:getChildByName("tab" .. i)
        self.tab_btns[i]:setTag(i)
    end

    local content_size = self.scroll_view:getContentSize()
    self.sview_width, self.sview_height = content_size.width, content_size.height

    self.cur_field = 1

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function scout_main_panel:Show()
    self:UpdateFieldInfo(self.cur_field)

    self.root_node:setVisible(true)
end

function scout_main_panel:UpdateFieldInfo(field)
    self.cur_field = field

    for i = 1, constants["MAX_WAR_FIELDS"] do
        local color = i == field and 0xFFFFFF or 0x7F7F7F
        self.tab_btns[i]:setColor(panel_util:GetColor4B(color))
    end

    local rival_info = guild_logic:GetRivalInfo()

    if rival_info and rival_info.troop_nums then
        self.member_num_text:setVisible(true)
        self.member_num_text:setString(lang_constants:GetFormattedStr("guild_rival_field_member_num", rival_info.troop_nums[field]))
    else
        self.member_num_text:setVisible(false)
    end

    if rival_info and rival_info.field_troop then
        self.desc_text:setVisible(false)
        self:LoadTroopInfo(rival_info.field_troop[field].troop_list)
    else
        self.desc_text:setVisible(true)
        self:LoadTroopInfo({})
    end

    if guild_logic:GetScoutLevel() == 1 then
        self.enemy_num:setString(tostring(rival_info.troop_nums[field]))
        self.enemy_text:setVisible(true)
        self.enemy_num:setVisible(true)
    else
        self.enemy_text:setVisible(false)
        self.enemy_num:setVisible(false)
    end
end

function scout_main_panel:CreateSubPanel(num)
    if #self.single_troop_sub_panels > num then
        return
    end

    for i = #self.single_troop_sub_panels + 1, num do
        local sub_panel = single_troop_sub_panel.New()
        self.single_troop_sub_panels[i] = sub_panel
        sub_panel:Init(self.template:clone())
        self.scroll_view:addChild(sub_panel:GetRootNode())
        sub_panel.arm_img:setTag(i)
        sub_panel.arm_img:addTouchEventListener(self.view_arm_method)
        sub_panel.view_img:setTag(i)
        sub_panel.view_img:addTouchEventListener(self.view_troop_method)
    end
end

function scout_main_panel:LoadTroopInfo(troop_list)
    local n = troop_list and #troop_list or 0
    self:CreateSubPanel(n)

    local START_X = 110
    local SUB_PANEL_WIDTH, SUB_PANEL_HEIGHT = 200, 159

    local height = math.max(self.sview_height, math.ceil(n/3) * SUB_PANEL_HEIGHT)

    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))
    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    
    for i = 1, n do
        local member = troop_list[i]
        local sub_panel = self.single_troop_sub_panels[i]

        sub_panel:Show(member)

        local row = math.floor(i / 3)
        local col = i % 3

        if col == 0 then
            row = row - 1
            col = 3
        end

        local x, y = START_X + (col-1) * SUB_PANEL_WIDTH, height - (row + 1) * SUB_PANEL_HEIGHT
        sub_panel:GetRootNode():setPosition(x, y)
    end

    for i = n + 1, #self.single_troop_sub_panels do
        self.single_troop_sub_panels[i]:Hide()
    end
end

function scout_main_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.scout_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")

            if guild_logic:GetCurStatus() == client_constants.CLIENT_GUILDWAR_STATUS["MATCHING"] then 
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                graphic:DispatchEvent("show_world_sub_panel", "guild.scout_buy_msgbox")
            else
                graphic:DispatchEvent("show_prompt_panel", "guild_scout_wrong_status")
            end
        end
    end)

    local click_tab_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            self:UpdateFieldInfo(widget:getTag())
        end
    end

    for i = 1, constants["MAX_WAR_FIELDS"] do
        self.tab_btns[i]:addTouchEventListener(click_tab_method)
    end

    self.view_arm_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            local sub_panel = self.single_troop_sub_panels[widget:getTag()]
            guild_logic:QueryRivalTroopInfo(sub_panel.user_id, client_constants["SCOUT_TROOP_SHOW_TYPE"]["ARM"])
        end
    end

    self.view_troop_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            local sub_panel = self.single_troop_sub_panels[widget:getTag()]
            guild_logic:QueryRivalTroopInfo(sub_panel.user_id, client_constants["SCOUT_TROOP_SHOW_TYPE"]["VIEW"])
        end
    end
end

function scout_main_panel:RegisterEvent()
    graphic:RegisterEvent("update_guild_scout_info", function()
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateFieldInfo(self.cur_field)
    end)
end

return scout_main_panel
