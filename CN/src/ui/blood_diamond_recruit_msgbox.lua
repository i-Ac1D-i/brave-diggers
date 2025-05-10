local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"
local user_logic = require "logic.user"

local time_logic = require "logic.time"
local panel_util = require "ui.panel_util"

local BLOOD_DIAMOND = constants.RESOURCE_TYPE["blood_diamond"]

local blood_diamond_recuit_msgbox = panel_prototype.New(true)

function blood_diamond_recuit_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/blood_diamond_recruit_msgbox.csb")
    local root_node = self.root_node

    self.hero_recruit_img_bg = root_node:getChildByName("hero_recruit")

    self.ten_recruit_img_bg = root_node:getChildByName("ten_recruit")

    self:RegisterWidgetEvent()
end

function blood_diamond_recuit_msgbox:Show()
    self.root_node:setVisible(true)
end

function blood_diamond_recuit_msgbox:RegisterWidgetEvent()
    --英雄招募
    self.hero_recruit_img_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            -- 检查血钻消耗
            local num = constants.RECRUIT_COST["hero_door"]
            if not  panel_util:CheckBloodDiamond(num) then
                return
            end

            troop_logic:RecruitMercenary("hero_door")
        end
    end)

    --十重招募
    self.ten_recruit_img_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            -- 检查血钻消耗
            local num = constants.RECRUIT_COST["ten_mercenary_door"]
            if not panel_util:CheckBloodDiamond(num) then
                return
            end

            troop_logic:RecruitMercenary("ten_mercenary_door")
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), "blood_diamond_recruit_msgbox")
end

return blood_diamond_recuit_msgbox
