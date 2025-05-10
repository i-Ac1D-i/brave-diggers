--选择佣兵上阵时，对比选中的英雄信息
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local client_constants = require "util.client_constants"

local panel_prototype = require "ui.panel"
local lang_constants = require "util.language_constants"

local mercenary_preview_panel = require "ui.mercenary_preview_panel"
local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local mercenary_compare_panel = panel_prototype.New(true)

function mercenary_compare_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_compare_panel.csb")
    local root_node = self.root_node

    self.preview_sub_panel = mercenary_preview_panel.New(self.root_node:getChildByName("preview_node"))
    self.preview_sub_panel:Init(MERCENARY_PREVIEW_SHOW_MOD["compare"])

    self.confirm_btn = self.preview_sub_panel.confirm_btn
    self.cancel_btn = self.preview_sub_panel.cancel_btn

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_compare_panel:Show(mode, first_mercenary_id, first_mercenary_position, second_mercenary_id, formation_id)

    self.first_mercenary_id = first_mercenary_id
    self.first_mercenary_position = first_mercenary_position
    self.second_mercenary_id = second_mercenary_id

    self.formation_id = formation_id or 1

    self.mode = mode

    self.root_node:setVisible(true)

    self.preview_sub_panel:Show(second_mercenary_id)

end

function mercenary_compare_panel:RegisterEvent()

    -- --更新被拦截信息
    -- graphic:RegisterEvent("update_be_robbed_list", function()
    --     self:RefreshRemainBeRobbedTimes()
    -- end)

    --下阵成功后上阵开始
    graphic:RegisterEvent("rest_mercenary_success", function()
        if not self.root_node:isVisible() then
            return
        end
        
        self:LoadMineNode()
    end)
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
            
            if self.mode == CHOOSE_SHOW_MODE["formation"] then
                local mercenary = troop_logic:GetMercenaryInfo(self.second_mercenary_id)
                local mine_status1, mine_status2, formation_id = troop_logic:IsMercenaryInMineFormation(mercenary)   --矿山的状态
                --是否在矿山阵容中
                if mine_status1 and troop_logic:IsMineFormation(self.formation_id) then
                    --该佣兵正在进行开采，无法进行调整
                    graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("mercenary_in_mine_now_title"),
                                lang_constants:Get("mercenary_in_mine_now_desc"),
                                lang_constants:Get("common_confirm"),
                                lang_constants:Get("common_cancel"),
                    function()
                         if self.first_mercenary_id == 0 then
                            --空位上阵
                            troop_logic:InsertMercenaryToFormation(self.formation_id, self.second_mercenary_id, 0)
                        else
                            --替换
                            troop_logic:ReplaceMercenaryFromFormation(self.formation_id, self.first_mercenary_id, self.second_mercenary_id)
                        end
                        graphic:DispatchEvent("hide_world_sub_scene")
                    end)
                    return 
                end

                if self.first_mercenary_id == 0 then
                    --空位上阵
                    troop_logic:InsertMercenaryToFormation(self.formation_id, self.second_mercenary_id, 0)
                else
                    --替换
                    troop_logic:ReplaceMercenaryFromFormation(self.formation_id, self.first_mercenary_id, self.second_mercenary_id)
                end
                graphic:DispatchEvent("hide_world_sub_scene")

            elseif self.mode == CHOOSE_SHOW_MODE["contract"] then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_contract_sub_scene", nil, self.second_mercenary_id)

            else
                local mercenary = troop_logic:GetMercenaryInfo(self.second_mercenary_id)
                graphic:DispatchEvent("show_world_sub_scene", "transmigration_sub_scene", SCENE_TRANSITION_TYPE["none"], self.mode, mercenary)
            end
            
        end
    end)
end

return mercenary_compare_panel
