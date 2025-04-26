local config_manager = require "logic.config_manager"

local audio_manager = require "util.audio_manager"

local panel_prototype = require "ui.panel"
local constants = require "util.constants"

local graphic = require "logic.graphic"

local resource_logic = require "logic.resource"
local user_logic = require "logic.user"
local daily_logic = require "logic.daily"
local time_logic = require "logic.time"
local temple_logic = require "logic.temple"
local panel_util = require "ui.panel_util"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local icon_template = require "ui.icon_panel"

local MAX_REFREDH_TIME = 1
local SCENE_TRANSITION_TYPE = constants.SCENE_TRANSITION_TYPE
local MERCENARY_QUALITY = constants.MERCENARY_QUALITY

local SHOW_MERCENARY_MAX_NUM = 4
local MERCENARY_PANEL_START_POS_Y = 573.00
local MERCENARY_DISTANCE_Y = 163

local TYPE_PANEL_START_POS_Y = 1540
local TYPE_PANEL_DISTANCE_Y = 770

--mercenary_sub_panel
local mercenary_sub_panel = panel_prototype.New()
mercenary_sub_panel.__index = mercenary_sub_panel

function mercenary_sub_panel.New()
    return setmetatable({}, mercenary_sub_panel)
end

function mercenary_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")
    self.desc_text = root_node:getChildByName("desc")
    self.soul_chip_text = root_node:getChildByName("cost_resource_num")

    self.exchange_btn = root_node:getChildByName("exchange_btn")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(75, 90)
    self:RegisterWidgetEvent()
end

function mercenary_sub_panel:Show(mercenary_id)
    self.mercenary_id = mercenary_id or 0

    local conf = self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], mercenary_id, nil, nil, true)
    self.desc_text:setString(conf.desc)
    self.name_text:setString(conf.name)

    local price = temple_logic:GetTempleMercenaryPrice(mercenary_id)
    self.soul_chip_text:setString(tostring(price))
end

function mercenary_sub_panel:RegisterWidgetEvent()
    self.exchange_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.mercenary_id ~= 0 then
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["revive_mercenary"], self.mercenary_id)
            end
        end
    end)
end

--神殿佣兵类别panel
local type_panel = panel_prototype.New()
type_panel.__index = type_panel

function type_panel.New()
    return setmetatable({}, type_panel)
end

function type_panel:Init(root_node, index)
    self.root_node = root_node
    self.index = index

    local template = root_node:getChildByName("mercenary_template")
    self.mercenary_sub_panels = {}
    local start_y = MERCENARY_PANEL_START_POS_Y

    for i = 1, 4 do
        local sub_panel = mercenary_sub_panel.New()
        sub_panel:Init(template:clone())
        self.root_node:addChild(sub_panel.root_node)

        local tag  = (index - 1) * 4 + i
        sub_panel.root_node:setTag(tag)

        pos_y = start_y - (i - 1) * MERCENARY_DISTANCE_Y
        sub_panel.root_node:setPositionY(pos_y)

        self.mercenary_sub_panels[i] = sub_panel
    end
    template:setVisible(false)

    local type_name_text = root_node:getChildByName("mercenary_title"):getChildByName("type_name")

    local title = lang_constants:Get("temple_title" .. index)
    type_name_text:setString(title)
end

local temple_panel = panel_prototype.New()

function temple_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/temple_panel.csb")
    local root_node = self.root_node

    self.soul_chip_text = root_node:getChildByName("soul_chip_cost")
    self.scroll_view = root_node:getChildByName("scroll_view")
    local panel_template = root_node:getChildByName("template_panel")

    self.duration = 0

    self.type_panels = {1, 2, 3}
    local start_y = TYPE_PANEL_START_POS_Y
    for i = 1, 3 do
        local sub_panel = type_panel.New()
        sub_panel:Init(panel_template:clone(), i)
        self.scroll_view:addChild(sub_panel.root_node)

        local pos_y = start_y - (i - 1) * TYPE_PANEL_DISTANCE_Y
        sub_panel.root_node:setPositionY(pos_y)

        self.type_panels[i] = sub_panel
    end

    panel_template:setVisible(false)

    self.desc_text = self.root_node:getChildByName("desc")
    self.explain_text = self.root_node:getChildByName("explain")

    self.show_explain_img = self.root_node:getChildByName("title"):getChildByName("desc_btn")

    --记录面板对应的id
    self.mercenary_ids = {}

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function temple_panel:ReLoadMercenaryInfo()

    local leader_counter = 1
    local legend_counter = 1
    local hero_counter = 1

    for template_id, mercenary in pairs(self.temple_mercenarys) do
        local quality = mercenary.quality

        if  quality ==  MERCENARY_QUALITY["leader"] or quality ==  MERCENARY_QUALITY["king_leader"] then
            self.type_panels[1].mercenary_sub_panels[leader_counter]:Show(template_id)
            leader_counter = leader_counter + 1

        elseif  quality ==  MERCENARY_QUALITY["legend"] then
            self.type_panels[2].mercenary_sub_panels[legend_counter]:Show(template_id)
            legend_counter = legend_counter + 1

        elseif  quality ==  MERCENARY_QUALITY["hero"] then
            self.type_panels[3].mercenary_sub_panels[hero_counter]:Show(template_id)
            hero_counter = hero_counter + 1
        end
    end
end

function temple_panel:Show()
    self.root_node:setVisible(true)
    self.explain_text:setVisible(false)

    self.temple_mercenarys = temple_logic:GetTempleMercenarys()
    self:ReLoadMercenaryInfo()

    --灵魂碎片
    local soul_chip_num = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["soul_chip"])
    self.soul_chip_text:setString(tostring(soul_chip_num))

    self.duration = time_logic:GetDurationToNextDay()

    if daily_logic:GetDailyTag(constants.DAILY_TAG["temple_recruit"]) then
        self.desc_text:setString(string.format(lang_constants:Get("temple_revive_countdown"), panel_util:GetTimeStr(self.duration)))
    else
        self.desc_text:setString(lang_constants:Get("temple_revive_desc"))
    end
end

function temple_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time

    if daily_logic:GetDailyTag(constants.DAILY_TAG["temple_recruit"]) then
        self.desc_text:setString(string.format(lang_constants:Get("temple_revive_countdown"), panel_util:GetTimeStr(self.duration)))
    end
end

function temple_panel:RegisterEvent()
    --招募成功
    graphic:RegisterEvent("temple_recruit_success", function()
        --灵魂碎片
        if not self.root_node:isVisible() then
            return
        end

        local soul_chip_num = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["soul_chip"])
        self.soul_chip_text:setString(tostring(soul_chip_num))
    end)
end

function temple_panel:RegisterWidgetEvent()
    --返回
    self.root_node:getChildByName("back_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "recruit_sub_scene")
        end
    end)

    self.show_explain_img:addTouchEventListener(function(widget, event_type)

        if event_type == ccui.TouchEventType.began then
            self.explain_text:setVisible(true)

        elseif event_type == ccui.TouchEventType.canceled or event_type == ccui.TouchEventType.ended then
            self.explain_text:setVisible(false)
        end
    end)
end

return temple_panel
