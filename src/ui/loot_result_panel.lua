local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local adventure_logic = require 'logic.adventure'
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local panel_prototype = require "ui.panel"
local panel_util= require "ui.panel_util"

local reward_logic = require "logic.reward"
local cost_item_panel = require "ui.icon_panel"
local store_logic = require "logic.store"

local MAX_ITEM_NUM = 10
local REWARD_TYPE = constants.REWARD_TYPE

local loot_result_panel = panel_prototype.New(true)

function loot_result_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/loot_result_msgbox.csb")

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.resut_sview = self.root_node:getChildByName("result_view")

    local r_node = self.root_node:getChildByName("result")
    self.gain_num_text = r_node:getChildByName("gain_num")
    self.add_btn = r_node:getChildByName("btn")

    self.item_sub_panels = {}

    self.template = self.resut_sview:getChildByName("template")
    self.template:setCascadeColorEnabled(false)
    self.template:setCascadeOpacityEnabled(false)

    for i = 1, MAX_ITEM_NUM do
        local root_node = i == 1 and self.template or self.template:clone()
        local item_sub_panel = cost_item_panel.New(root_node)

        item_sub_panel:Init()
        item_sub_panel.name_text = item_sub_panel.root_node:getChildByName("name")

        self.item_sub_panels[i] = item_sub_panel

        local x, y = self.resut_sview:getChildByName("shadow" .. i):getPosition()

        item_sub_panel.root_node:setPosition(x, y)

        if i ~= 1 then
            self.resut_sview:addChild(item_sub_panel.root_node)
        end
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function loot_result_panel:Show(opened_box_num)
    local reward_info_list = opened_box_num > 0 and reward_logic:GetRewardInfoList() or {}

    local index = 0
    for i = 1, #reward_info_list do
        local reward_info = reward_info_list[i]

        index = index + 1

        local conf = self.item_sub_panels[index]:Show(reward_info.id, reward_info.param1, reward_info.param2, false, false)
        self.item_sub_panels[index].name_text:setString(conf.name)

        if index >= MAX_ITEM_NUM then
            break
        end
    end

    for i = index + 1, MAX_ITEM_NUM do
        self.item_sub_panels[i]:Hide()
    end

    self.gain_num_text:setString(opened_box_num .. "/" .. adventure_logic.max_box_num)

    self.root_node:setVisible(true)
end

function loot_result_panel:RegisterEvent()
    graphic:RegisterEvent("store_buy_success", function(goods_id)
        if not self.root_node:isVisible() then
            return
        end

        local goods_info = store_logic:GetGoodsInfoById(goods_id)
        if not goods_info then
            return
        end


        if goods_info.type == constants.STORE_GOODS_TYPE["max_box_num"] then
            self.gain_num_text:setString(adventure_logic.cur_maze_info["box_num"] .. "/" .. adventure_logic.max_box_num)
        end
    end)
end

function loot_result_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.confirm_btn, "loot_result_panel")


    self.add_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local goods_index = store_logic:GetExploreGoodsIndex()
            local mode = client_constants.BATCH_MSGBOX_MODE.blood_store
            if goods_index then
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
            end
        end
    end)
end

return loot_result_panel
