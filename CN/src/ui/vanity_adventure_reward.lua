
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local reward_logic = require "logic.reward"

local vanity_adventure_reward = panel_prototype.New(true)
function vanity_adventure_reward:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_reward.csb")


    self.add_score_text = self.root_node:getChildByName("bp_limit"):getChildByName("limit_value")

    self.last_all_mercenarys = self.root_node:getChildByName("bp_limit"):getChildByName("value")

    self.close_btn = self.root_node:getChildByName("close1_btn")

    self.ok_btn = self.root_node:getChildByName("confirm_btn")

    self:RegisterWidgetEvent()
end

function vanity_adventure_reward:Show(add_score)
    self.root_node:setVisible(true)
    self.add_score = add_score

    --最后还剩余佣兵个数展现
    self.last_all_mercenarys:setString(troop_logic:GetVanityCanUseNumber())

    --额外奖励积分文本
    self.add_score_text:setString(add_score)

end

function vanity_adventure_reward:ClosePanel()
    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

	--展示额外获得的积分
    local reward_info_list = {{id = constants["REWARD_TYPE"].resource, param1 = constants["RESOURCE_TYPE"].vanity_adventure, param2 = self.add_score}}
    reward_logic:AddRewardInfo(0, reward_info_list)
    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
end

function vanity_adventure_reward:RegisterWidgetEvent()

    self.close_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ClosePanel()
        end
    end)

    self.ok_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ClosePanel()
        end
    end)
end

return vanity_adventure_reward

