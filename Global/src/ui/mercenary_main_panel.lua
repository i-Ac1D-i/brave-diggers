local feature_config = require "logic.feature_config"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local destiny_logic = require "logic.destiny_weapon"
local time_logic = require "logic.time"
local reminder_logic = require "logic.reminder"

local adventure_logic = require "logic.adventure"
local client_constants = require "util.client_constants"
local configuration = require "util.configuration"

local panel_prototype = require "ui.panel"
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local panel_util = require "ui.panel_util"
local lang_constants = require "util.language_constants"
local mercenary_main_panel = panel_prototype.New()

function mercenary_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_main_panel.csb")

    self.list_btn = self.root_node:getChildByName("mercenary_list")
    self.formation_btn = self.root_node:getChildByName("formation")
    self.transmigration_btn = self.root_node:getChildByName("transmigration")
    self.destiny_btn = self.root_node:getChildByName("destiny")
    self.fire_btn = self.root_node:getChildByName("fire")
    self.library_btn = self.root_node:getChildByName("library")
    self.contract_btn = self.root_node:getChildByName("contract")

    self.transmigration_flag_img = self.transmigration_btn:getChildByName("tipbg")
    self.transmigration_count_down_text = self.transmigration_flag_img:getChildByName("count_down")
    --出战阵容有空位 并且 还有佣兵可以上阵 的提醒绿点
    self.formation_remind_btn = self.formation_btn:getChildByName("tipbg")
    self.free_time_limit = user_logic.base_info.create_time + time_logic:GetSecondsFromDays(constants['NOVICE_DAYS'])
    self:RegisterWidget()
    self:RegisterWidgetEvent()
    self.contract_btn:setVisible(feature_config:IsFeatureOpen("sign_contract"))
end

--检测免费灵力转移
function mercenary_main_panel:CheckTransmigrationFree()
    local now_time = time_logic:Now()
    if  now_time < self.free_time_limit then
        self.transmigration_count_down_text:setString(string.format(lang_constants:Get("transmigration_free_time_tip") , panel_util:GetTimeStr(self.free_time_limit - now_time) ))
        configuration:SetViewedFreeTransmigration(true)
    else
        configuration:SetViewedFreeTransmigration(false)
    end

    self.transmigration_flag_img:setVisible(configuration:GetViewedFreeTransmigration())
end

--限免灵力转移活动
function mercenary_main_panel:CheckCarnivalTransmigration()
    if  not configuration:GetViewedFreeTransmigration() then 
        local carnival_end_time = configuration:GetCarnivalTransmigrationEndTime()
        if carnival_end_time > 0 then 
           local now_time = time_logic:Now()
           if carnival_end_time  > now_time then 
              self.transmigration_count_down_text:setString(string.format(lang_constants:Get("transmigration_carnival_time_tip") , panel_util:GetTimeStr(carnival_end_time - now_time ) ))
              self.transmigration_flag_img:setVisible(true)
           else
              self.transmigration_flag_img:setVisible(false)
           end
        else
            self.transmigration_flag_img:setVisible(false)
        end
    end
end

function mercenary_main_panel:Update(elapsed_time)
    self:CheckTransmigrationFree()
    self:CheckCarnivalTransmigration() 
end

function mercenary_main_panel:Show()
    --出战阵容有空位 并且 还有佣兵可以上阵 的提醒
    self:CheckTransmigrationFree()
    self:CheckCarnivalTransmigration()

    reminder_logic:CheckFormationReminder()

    self.root_node:setVisible(true)
end

function mercenary_main_panel:RegisterWidget()
    graphic:RegisterEvent("remind_world_sub_scene", function(index, visible)
        --出战阵容有空位的提醒
        if index == 6 then
            self.formation_remind_btn:setVisible(visible)
        end
    end)
end

function mercenary_main_panel:RegisterWidgetEvent()
    --阵型
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], true, client_constants["FORMATION_PANEL_MODE"]["multi"])
        end
    end)

    --营帐
    self.list_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_list_sub_scene", SCENE_TRANSITION_TYPE["none"])
        end
    end)

    --转生
    self.transmigration_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "transmigration_sub_scene", SCENE_TRANSITION_TYPE["none"])
        end
    end)

    --宿命武器
    self.destiny_btn:addTouchEventListener(function(widget, event_type)
        --锻造武器
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if destiny_logic:HasDestinyWeapon() then
                graphic:DispatchEvent("show_world_sub_scene", "leader_weapon_sub_scene", SCENE_TRANSITION_TYPE["none"])
            end
        end
    end)

    --批量解雇
    self.fire_btn:addTouchEventListener(function(widget, event_type)
        --提升觉醒等级
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["fire"]) then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_fire_sub_scene", SCENE_TRANSITION_TYPE["none"])
            end
        end
    end)

    --阵型
    self.library_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_library_sub_scene", SCENE_TRANSITION_TYPE["none"])
        end
    end)

    --契约
    self.contract_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if troop_logic:IsContractUnlock() then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_contract_sub_scene", SCENE_TRANSITION_TYPE["none"])
            end
        end
    end)
end

return mercenary_main_panel
