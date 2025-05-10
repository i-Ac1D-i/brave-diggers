local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local temple_logic = require "logic.temple"
local carnival_logic = require "logic.carnival"
local daily_logic = require "logic.daily"

local time_logic = require "logic.time"
local panel_util = require "ui.panel_util"

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local SCENE_TRANSITION_TYPE = constants.SCENE_TRANSITION_TYPE

local MAX_REFREDH_TIME = 1
local SUB_PANEL_HEIGHT = 190

local recruit_panel = panel_prototype.New()
function recruit_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/recruit_panel.csb")
    local root_node = self.root_node

    self.list_view = self.root_node:getChildByName("list_view")

    self.gold_coin_recruit_btn = self.list_view:getChildByName("coin_recruit")
    self.gold_coin_text = self.gold_coin_recruit_btn:getChildByName("coin_cost")

    self.blood_diamond_recruit_btn = self.list_view:getChildByName("blood_diamond_recruit")

    self.temple_recruit_btn  = self.list_view:getChildByName("temple")
    self.temple_cd_text = self.temple_recruit_btn:getChildByName("reset_time")

    self.friend_recruit_btn = self.list_view:getChildByName("friend_recruit")

    -- self.friend_recruit_btn:getChildByName("friend_cost"):setString(tostring(constants["RECRUIT_COST"]["friendship_door"]))

    self.magic_recruit_btn = self.list_view:getChildByName("magic_recruit")
    self.magic_recruit_btn:setVisible(false)

    self.magic_recruit_time_text = self.magic_recruit_btn:getChildByName("timetip"):getChildByName("time")
    self.magic_recruit_cost_text = self.magic_recruit_btn:getChildByName("blood_diamond_cost")

    self.top = self.magic_recruit_btn:getPositionY()

    self.recruit_sub_panels = {}
    self.recruit_sub_panels[1] = self.magic_recruit_btn
    self.recruit_sub_panels[2] = self.blood_diamond_recruit_btn
    self.recruit_sub_panels[3] = self.gold_coin_recruit_btn
    self.recruit_sub_panels[4] = self.friend_recruit_btn
    self.recruit_sub_panels[5] = self.temple_recruit_btn

    for i = 2, 5 do
        self.recruit_sub_panels[i]:setPositionY(self.top - (i-2) * SUB_PANEL_HEIGHT)
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end


function recruit_panel:Show()
    self.root_node:setVisible(true)

    self:UpdateCost()
    self.duration = time_logic:GetDurationToNextDay()

    self:UpdateMagicDoor()
    self.list_view:jumpToTop()
end

function recruit_panel:UpdateMagicDoor()
    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["magic_door"], constants.CARNIVAL_TYPE["magic_door"])

    if conf then
        if not self.magic_recruit_btn:isVisible() and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["magic"], false) then
            self.magic_recruit_btn:setVisible(true)
            self.magic_recruit_cost_text:setString(tostring(conf.extra_num1))

            for i = 1, 5 do
                self.recruit_sub_panels[i]:setPositionY(self.top - (i-1) * SUB_PANEL_HEIGHT)
            end
        end

        local cur_time = time_logic:Now()
        self.magic_recruit_time_text:setString(panel_util:GetTimeStr(conf.end_time - cur_time))

    elseif self.magic_recruit_btn:isVisible() then
        for i = 2, 5 do
            self.recruit_sub_panels[i]:setPositionY(self.top - (i-2) * SUB_PANEL_HEIGHT)
        end

        self.magic_recruit_btn:setVisible(false)
    end
end

function recruit_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time

    if self.duration <= 0 then
        self.duration = time_logic:GetDurationToNextDay()
    end

    self.temple_cd_text:setString(panel_util:GetTimeStr(self.duration))

    self:UpdateMagicDoor()
end

function recruit_panel:UpdateCost()
    panel_util:ConvertUnit(daily_logic:GetRecruitCost(), self.gold_coin_text)
end

function recruit_panel:RegisterEvent()
    graphic:RegisterEvent("recruit_mercenary", function(door_type)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateCost()
    end)
end

function recruit_panel:RegisterWidgetEvent()
    --金币招募
    self.gold_coin_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["recruit_mercenary"], "recruiting_door")
        end
    end)

    --友情招募
    self.friend_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "friendship_recruit_msgbox")
        end
    end)

    --血钻招募
    self.blood_diamond_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "blood_diamond_recruit_msgbox")
        end
    end)

    --神殿
    self.temple_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["temple"]) then
                temple_logic:MercenaryQuery()
            end
        end
    end)

    --秘术招募
    self.magic_recruit_btn:getChildByName("magic_recruit"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "magic_recruit_msgbox")
        end
    end)
end

return recruit_panel
