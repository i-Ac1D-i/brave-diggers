local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local resource_logic = require "logic.resource"
local mining_logic = require "logic.mining"
local time_logic = require "logic.time"
local bag_logic = require "logic.bag"
local panel_util = require "ui.panel_util"

local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local icon_tempalte = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"

local RESOURCE_TYPE = constants.RESOURCE_TYPE

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 151

local reset_sub_panel = panel_prototype.New()
reset_sub_panel.__index = reset_sub_panel

function reset_sub_panel.New()
    return setmetatable({}, reset_sub_panel)
end

function reset_sub_panel:Init(root_node, golem_index)

    self.reset_main_panel = nil
    self.root_node = root_node
    self.golem_index = golem_index

    self.name_text = self.root_node:getChildByName("name")    --
    self.desc_text = self.root_node:getChildByName("desc")    --巨魔等级重置到Lv
    self.condition_text = self.root_node:getChildByName("condition")    --需要当前巨魔等级

    self.icon_tempalte = icon_tempalte.New(nil, 2)
    self.icon_tempalte:Init(root_node, true)
    self.icon_tempalte.root_node:setPosition(80, 78)

    self.icon_text = self.icon_tempalte.num_text

    self.refresh_btn = root_node:getChildByName("refresh_btn")
    self.refresh_desc = self.refresh_btn:getChildByName("desc")

    self.conf = config_manager.mining_refresh_config[golem_index]
    self.reset_lv = self.conf.reset_lv
    self.golem_lv = self.conf.golem_lv

    self:RegiserWidgetEvent()
end

function reset_sub_panel:DisableBtn()
end

function reset_sub_panel:EnableBtn()
end

function reset_sub_panel:UpdateBtn()
    self.refresh_btn:setColor(panel_util:GetColor4B(0x7F7F7F))

    local string = lang_constants:Get("mining_refresh_btn3")

    if self.reset_main_panel.mystic_stone == 0 and mining_logic.refresh_time > time_logic:Now() then
        string = lang_constants:Get("mining_refresh_btn1")

    elseif mining_logic.golem_lv < self.reset_lv then
        string = lang_constants:Get("mining_refresh_btn2")

    elseif not resource_logic:CheckResourceNum(RESOURCE_TYPE["tnt"], self.conf.tnt) or not resource_logic:CheckResourceNum(RESOURCE_TYPE["ultimate_tool"], self.conf.ultimate_tool) then
        string = lang_constants:Get("resource_general_not_enough")
    else
        self.refresh_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    self.refresh_desc:setString(string)
end

function reset_sub_panel:Show()
    self.root_node:setVisible(true)

    local template_id = constants["RESOURCE_TYPE"]["golem"]
    local conf = config_manager.resource_config[template_id]

    local lv_text = lang_constants:Get("level_shot_string") .. self.golem_lv
    self.icon_tempalte:Load(constants["RESOURCE_TYPE"]["resource"], conf.icon, 6, lv_text, "", "", true)

    self.desc_text:setString(string.format(lang_constants:Get("mining_reset_result"), self.golem_lv))
    self.condition_text:setString(string.format(lang_constants:Get("mining_reset_condition"), self.reset_lv))
    --FYD 
    local font_size =  platform_manager:GetChannelInfo().mining_reset_panel_condition_text
    if font_size then
        self.condition_text:setFontSize(font_size) 
    end 

    self.duration = time_logic:GetDurationToFixedTime(mining_logic:GetAreaRefreshTime())

    self:UpdateBtn()
end

function reset_sub_panel:RegiserWidgetEvent()
    -- button点击
    self.refresh_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local mode = client_constants.CONFIRM_MSGBOX_MODE["reset_golem_level"]
            local data1 = self.conf
            local data2 = self.reset_main_panel.mystic_stone
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, data1, data2)
        end
    end)
end

local mining_reset_panel = panel_prototype.New(true)
function mining_reset_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mining_refresh_msgbox.csb")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.desc_text = self.root_node:getChildByName("desc")
    self.reset_list = self.root_node:getChildByName("reset_list")
    self.level_text = self.root_node:getChildByName("level_value")

    self.template = self.root_node:getChildByName("reset_list"):getChildByName("level_template")
    self.template:setVisible(false)

    self.reset_sub_panels = {}
    self.sum_panels_num = 0
    self.mystic_stone = 0
    self:RegiserWidgetEvent()
end

function mining_reset_panel:Show(mystic_stone)
    self.mystic_stone = mystic_stone or 0

    self.root_node:setVisible(true)
    self.level_text:setString(lang_constants:Get("level_shot_string") .. mining_logic:GetGolemLv())
    self:CreateSubPanels()
    self.duration = time_logic:GetDurationToFixedTime(mining_logic:GetAreaRefreshTime())
    self:UpdateSubPanels()

    self:UpdateTime()
end

function mining_reset_panel:CreateSubPanels()

    local GOLEM_RESET = config_manager.mining_refresh_config
    local num = #GOLEM_RESET
    local golem_level = mining_logic:GetGolemLv()
    for i = 1, num do
        local sub_panel = reset_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)
        self.reset_sub_panels[i] = sub_panel
        sub_panel.root_node:setPositionY(875 - (i-1) * 160)
        sub_panel.reset_main_panel = self
        self.reset_list:addChild(sub_panel.root_node)
        self.sum_panels_num = i
    end
end

local time_deleta = 0
local MIN_DURATION = 0
local DURATION_SIGN = -1

function mining_reset_panel:Update(elapsed_time)

    if self.duration == DURATION_SIGN then
        return
    end

    time_deleta = time_deleta + elapsed_time

    if time_deleta >= 1 then
        self.duration = math.max(self.duration - time_deleta, MIN_DURATION)
        time_deleta = 0
        self:UpdateTime()
        self:UpdateSubPanels()
    end
end

function mining_reset_panel:UpdateTime()

    if self.mystic_stone == 0 and self.duration > 0 then
        self.desc_text:setString(string.format(lang_constants:Get("mining_reset_golem_desc2"), panel_util:GetTimeStr(self.duration)))
    else
        self.desc_text:setString(lang_constants:Get("mining_reset_golem_desc1"))
        self.duration = DURATION_SIGN
    end
end

function mining_reset_panel:UpdateSubPanels()

    for i, sub_panel in ipairs(self.reset_sub_panels) do
        sub_panel:Show()
    end
end

function mining_reset_panel:RegiserWidgetEvent()

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return mining_reset_panel
