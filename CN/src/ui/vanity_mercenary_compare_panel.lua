--选择佣兵上阵时，对比选中的英雄信息
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local client_constants = require "util.client_constants"

local panel_prototype = require "ui.panel"
local lang_constants = require "util.language_constants"

local vanity_mercenary_preview_panel = require "ui.vanity_mercenary_preview_panel"
local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local mercenary_compare_panel = panel_prototype.New(true)

function mercenary_compare_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_compare_panel.csb")
    local root_node = self.root_node
    --佣兵详细面板
    self.preview_sub_panel = vanity_mercenary_preview_panel.New(self.root_node:getChildByName("preview_node"))
    self.preview_sub_panel:Init(MERCENARY_PREVIEW_SHOW_MOD["compare"])
    --确定和取消按钮
    self.confirm_btn = self.preview_sub_panel.confirm_btn
    self.cancel_btn = self.preview_sub_panel.cancel_btn

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_compare_panel:Show(replace_mercenary_position, second_mercenary_id, battle_num_not_enough)

    --要替换的佣兵位置
    self.replace_mercenary_position = replace_mercenary_position
    --选择的佣兵id
    self.second_mercenary_id = second_mercenary_id

    self.root_node:setVisible(true)
    --上阵次数是否充足
    self.battle_num_not_enough = battle_num_not_enough
    --展示佣兵详细
    self.preview_sub_panel:Show(second_mercenary_id)

end

function mercenary_compare_panel:RegisterEvent()

end


function mercenary_compare_panel:RegisterWidgetEvent()

    --取消
    self.cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --确认
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            if self.battle_num_not_enough then
                --提示上阵次数不足
                graphic:DispatchEvent("show_prompt_panel", "not_enough_battle_num")
                return
            end

            if self.replace_mercenary_position then
                --替换佣兵
                troop_logic:ReplaceToBattle(self.second_mercenary_id, self.replace_mercenary_position)
            else
                --上阵佣兵
                troop_logic:GoToBattle(self.second_mercenary_id)
            end

            graphic:DispatchEvent("hide_world_sub_scene")

            troop_logic:CalcVanityTroopBP(true)
        end
    end)
end

return mercenary_compare_panel
