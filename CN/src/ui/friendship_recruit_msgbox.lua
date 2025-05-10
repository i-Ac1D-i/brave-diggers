local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"

local panel_util = require "ui.panel_util"

local friendship_recruit_msgbox = panel_prototype.New(true)

function friendship_recruit_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/recruit_friend_panel.csb")
    local root_node = self.root_node

    self.single_recruit_img_bg = root_node:getChildByName("hero_recruit")

    self.ten_recruit_img_bg = root_node:getChildByName("ten_recruit")
    local friendship_text = root_node:getChildByName("friendship_text")
    self.friendship_pt_text = root_node:getChildByName("friendship_quantity")

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function friendship_recruit_msgbox:Show()
    self.root_node:setVisible(true)
    self.friendship_pt_text:setString(resource_logic:GetResourceNum(constants.RESOURCE_TYPE["friendship_pt"]))
end

function friendship_recruit_msgbox:RegisterWidgetEvent()
    --单次招募
    self.single_recruit_img_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:RecruitMercenary("friendship_door")
        end
    end)

    --十重招募
    self.ten_recruit_img_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            troop_logic:RecruitMercenary("ten_friendship_door")
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), "friendship_recruit_msgbox")
end

function friendship_recruit_msgbox:RegisterEvent()
    graphic:RegisterEvent("recruit_mercenary", function(door_type)
        if not self.root_node:isVisible() then
            return
        end

        if door_type == "ten_friendship_door" or door_type == "friendship_door" then
            self.friendship_pt_text:setString(resource_logic:GetResourceNum(constants.RESOURCE_TYPE["friendship_pt"]))
        end

    end)
end

return friendship_recruit_msgbox
