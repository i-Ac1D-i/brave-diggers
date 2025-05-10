local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local reminder_logic = require "logic.reminder"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local notification_msgbox = panel_prototype:New()
function notification_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/notification_msgbox.csb")

    self.close1_btn = self.root_node:getChildByName("close1_btn")
    self.close2_btn = self.root_node:getChildByName("close2_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.notify_btn = self.root_node:getChildByName("notify_btn")
    self.notify_img = self.root_node:getChildByName("notify_img")

    self.time_text = self.root_node:getChildByName("txt")

    self.desc_text = self.root_node:getChildByName("desc")

    self.root_node:setVisible(false)

    local hide = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end

    self.close1_btn:addTouchEventListener(hide)
    self.close2_btn:addTouchEventListener(hide)

    self.notify_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.show_notify = not self.show_notify

            if self.mode == 1 then
                reminder_logic:SetShowForgeNotify(self.show_notify)
            elseif self.mode == 2 then
                reminder_logic:SetShowGuildWarNotify(self.show_notify)
            end

            self.notify_img:setVisible(not self.show_notify)
        end
    end)

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

            local callback = self.callback
            if callback then
                callback()
            end
        end
    end)
end

function notification_msgbox:Show(mode, callback)
    self.root_node:setVisible(true)
    self.notify_img:setVisible(true)

    self.mode = mode
    self.callback = callback
    self.show_notify = false

    if mode == 1 then
        self.desc_text:setString(lang_constants:Get("mercenary_forge_weapon_warning"))
        self.time_text:setString(lang_constants:Get("notification_msgbox_time_text1"))
        reminder_logic:SetShowForgeNotify(self.show_notify)

    elseif mode == 2 then
        self.desc_text:setString(lang_constants:Get("guild_war_enter_for_desc"))
        self.time_text:setString(lang_constants:Get("notification_msgbox_time_text2"))
        reminder_logic:SetShowGuildWarNotify(self.show_notify)
    end
end

return notification_msgbox
