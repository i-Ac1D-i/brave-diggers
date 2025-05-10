local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local troop_logic = require "logic.troop"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local resource_template = require "ui.icon_panel"
local utils = require "util.utils"
local time_logic = require "logic.time"
local lang_constants = require "util.language_constants"
local MAX_SUB_PANEL_NUM = 5
local BUY_CONF = config_manager.vanity_buy_other_pay_config


local vanity_recruit_mercenary_panel = panel_prototype.New(true)

function vanity_recruit_mercenary_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_explore.csb")
    self.save_mercenary_btn = self.root_node:getChildByName("confirm_btn")
    self.cost_bg = self.root_node:getChildByName("cost_bg")

    self.desc = self.root_node:getChildByName("desc")
    self.maze_id = 0
    
    self.item_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = resource_template.New()
        sub_panel:Init(self.cost_bg)
        self.item_sub_panels[i] = sub_panel
        self.item_sub_panels[i].root_node:setPositionY(self.cost_bg:getContentSize().height/3)
    end

    self:RegisterWidgetEvent()
end

--获得通关所获得佣兵提示面板
function vanity_recruit_mercenary_panel:Show()
    --要领取关卡的id
    self.root_node:setVisible(true)

    local week = utils:getWDay(time_logic:Now())

    local conf = BUY_CONF[week]


    self.desc:setString(string.format(lang_constants:Get("recruit_mercenary_desc"), conf.mercenary_num))
    local costs = utils:splitStr(conf.consume, "|")
    local now_index = conf.recruit_num - troop_logic.reduce_search_times + 1
    panel_util:LoadCostResourceInfo({["blood_diamond"] = tonumber(costs[now_index])}, self.item_sub_panels, self.cost_bg:getContentSize().height/3, MAX_SUB_PANEL_NUM, self.cost_bg:getContentSize().width/2)
end

function vanity_recruit_mercenary_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), self:GetName())

    self.save_mercenary_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            troop_logic:GetVanityOtherMercenary()
        end
    end)
end

return vanity_recruit_mercenary_panel

