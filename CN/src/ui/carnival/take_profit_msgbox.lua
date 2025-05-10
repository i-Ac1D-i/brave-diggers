local config_manager = require "logic.config_manager"

local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local carnival_logic = require "logic.carnival"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"
local reuse_scrollview = require "widget.reuse_scrollview"

local FIRST_SUB_PANEL_OFFSET = -64
local MAX_SUB_PANEL_NUM = 7
local SUB_PANEL_HEIGHT = 124

local daily_reward_sub_panel = panel_prototype.New()
daily_reward_sub_panel.__index = daily_reward_sub_panel

function daily_reward_sub_panel.New()
    return setmetatable({}, daily_reward_sub_panel)
end

function daily_reward_sub_panel:Init(root_node)
    self.root_node = root_node

    self.date_text = self.root_node:getChildByName("date")
    self.get_img = self.root_node:getChildByName("get")

    self.icon_panels = {}

    local x, y = 194, 65

    for i = 1, 3 do
        local icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text1"])
        icon_panel:Init(self.root_node)
        icon_panel.root_node:setPosition(x + (i-1) * 120, y)

        self.icon_panels[i] = icon_panel
    end

    self.get_img:setLocalZOrder(1)
end

function daily_reward_sub_panel:Show(conf, carnival_info, profit_duration)

    local reward_list = conf.reward_list

    for i = 1, #reward_list do
        local reward_info = reward_list[i]
        self.icon_panels[i]:Show(reward_info.reward_type, reward_info.param1, reward_info.param2)
    end

    for i = #reward_list+1, 3 do
        self.icon_panels[i]:Hide()
    end

    local conf_type = conf.type
    if conf_type > 3 then
        conf_type = conf_type - 3
    end

    local has_taken = (profit_duration - carnival_info.step_reward[conf_type]) >= conf.step
    
    self.date_text:setString(string.format(lang_constants:Get("fund_date"),conf.step))
    
    self.get_img:setVisible(has_taken)

    self.step = conf.step

    self.root_node:setVisible(true)
end

local take_profit_msgbox = panel_prototype.New(true)
function take_profit_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/carnival_fund_msgbox.csb")

    self.take_btn = self.root_node:getChildByName("take_btn")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.template = self.root_node:getChildByName("template")
    
    self.scroll_view = self.root_node:getChildByName("scrollview")
    
    self.sub_panels = {}
    self.sub_panel_num = 0

    self.template:setVisible(false)

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.profit_duration
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            local conf = config_manager.fund_config[self.parent_panel.step_index][index]
            sub_panel:Show(conf, self.parent_panel.carnival_info, self.parent_panel.profit_duration)
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function take_profit_msgbox:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.profit_duration)

    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = daily_reward_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.sub_panels[i] = sub_panel

        sub_panel.root_node:setPositionX(320)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function take_profit_msgbox:Show(carnival_config, step_index)
    self.root_node:setVisible(true)

    self.step_index = step_index

    self.carnival_info = carnival_logic:GetCarnivalInfo(carnival_config.key)
    self.carnival_config = carnival_config

    self.profit_duration = config_manager.fund_config[self.step_index].profit_duration
    
    self:CreateSubPanels()

    self.data_offset = 0
    local height = math.max(self.profit_duration * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.sub_panels[i]
        local conf = config_manager.fund_config[self.step_index][i]

        if conf then
            sub_panel:Show(conf, self.carnival_info, self.profit_duration)
            sub_panel.root_node:setPosition(10, height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)
end

function take_profit_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.take_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local step_index = self.step_index 
            if step_index > 3 then
                step_index = step_index - 3
            end
            carnival_logic:TakeFundProfit(self.carnival_config.key, step_index)
        end
    end)
end

function take_profit_msgbox:RegisterEvent()
    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key, step_index)
        if not self.root_node:isVisible() then
            return
        end

        if self.carnival_config.key ~= key then
            return
        end

        if self.step_index ~= step_index then
            return
        end

        for i = 1, self.sub_panel_num do
            local sub_panel = self.sub_panels[i]
            local index = self.reuse_scrollview:GetDataIndex(i)
            local conf = config_manager.fund_config[self.step_index][index]

            if conf then
                sub_panel:Show(conf, self.carnival_info, self.profit_duration)
            else
                sub_panel:Hide()
            end
        end
    end)
end

return take_profit_msgbox
