local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local adventure_logic = require "logic.adventure"
local config_manager = require "logic.config_manager"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"

local quick_battle_reward_msgbox = panel_prototype.New(true)
function quick_battle_reward_msgbox:Init(root_node)

    self.root_node = cc.CSLoader:createNode("ui/quick_battle_reward_msgbox.csb")
    self.time_txt = self.root_node:getChildByName("Text_28")
    self.maze_txt = self.root_node:getChildByName("Text_28_0")
    self.gold_coin_txt = self.root_node:getChildByName("Text_28_0_0")
    self.exp_txt = self.root_node:getChildByName("Text_28_0_0_0")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self:RegisterWidgetEvent()
end

function quick_battle_reward_msgbox:Show(recv_msg)

    self.root_node:setVisible(true)

    local adventure_buy_config = config_manager.adventure_buy_config
    local adventure_buy_info = adventure_buy_config[adventure_logic.buy_adventure_num]
    self.time_txt:setString(panel_util:GetTimeStr(adventure_buy_info.mins))
    self.maze_txt:setString(lang_constants:Get("adventure_difficulty"..recv_msg.difficulty).." "..recv_msg.maze_name)
    self.gold_coin_txt:setString(string.format("%d", recv_msg.get_gold_coin))
    self.exp_txt:setString(string.format("%d", recv_msg.get_exp))

end

function quick_battle_reward_msgbox:RegisterWidgetEvent()

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())
end

return quick_battle_reward_msgbox

