local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"
local escort_logic = require "logic.escort"


local escort_start_rob_panel = panel_prototype.New(true)
function escort_start_rob_panel:Init(root_node)
	self.root_node = cc.Node:create()

    animation_manager:LoadAnimation("start_rob")
    self.animation_node = animation_manager:GetAnimationNode("start_rob")
    self.animation_node:setPosition(320, 568)

    self.spine_node = self.animation_node:getChildByName("Panel_1"):getChildByName("Node_spine_car")

    --矿车动画
    self.tramcar_spine_node = spine_manager:GetNode("kuangche", 1.0, true)
    self.tramcar_spine_node:setTimeScale(1.0)
    self.tramcar_spine_node:setScale(2.0)

    self.spine_node:addChild(self.tramcar_spine_node)

    self.root_node:addChild(self.animation_node)
end

function escort_start_rob_panel:Show(rob_target_info, target_info, battle_property, battle_record, is_winner)
	self.rob_target_info = rob_target_info

    local spine_name = escort_logic:GetTramcarSpineName(self.rob_target_info.tramcar_id, escort_logic:GetCurBeRobbedList(self.rob_target_info.escort_beg_time, self.rob_target_info.be_robbed_list))
    self.tramcar_spine_node:setToSetupPose()
    self.tramcar_spine_node:setAnimation(0, spine_name, true)

    local time_line_action = animation_manager:GetTimeLine("start_rob_timeline")
    self.animation_node:stopAllActions()
    self.animation_node:runAction(time_line_action)

    time_line_action:clearFrameEventCallFunc()
    time_line_action:setFrameEventCallFunc(function(frame)
        local event_name = frame:getEvent()
        if event_name == "end" then
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

            local battle_type = client_constants.BATTLE_TYPE["vs_escort_target"]
            graphic:DispatchEvent("show_battle_room", battle_type, target_info, battle_property, battle_record, is_winner, function()
                --战斗播放完毕 自动弹出奖励`
                if is_winner then
                    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                end
            end)

    	end
    end)
    time_line_action:gotoFrameAndPlay(0, 188, false)

    self.root_node:setVisible(true)
end

return escort_start_rob_panel

