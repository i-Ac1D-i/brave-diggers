local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local campaign_logic = require "logic.campaign"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"


local guild_logic = require "logic.guild"
local graphic = require "logic.graphic"


local PLIST_TYPE = ccui.TextureResType.plistType

local guild_setting_msgbox = panel_prototype.New(true)
function guild_setting_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/guild_setting_panel.csb")
    local root_node = self.root_node

    local bg_condition = root_node:getChildByName("bp_condition")
    self.sub_btn = bg_condition:getChildByName("sub_btn")
    self.add_btn = bg_condition:getChildByName("add_btn")
    self.threshold_txt = bg_condition:getChildByName("buy_num")

    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self:RegisterWidgetEvent()
end

function guild_setting_msgbox:Show()
    self.root_node:setVisible(true)
    self.guild_threshold_idx  = guild_logic.bp_limit_idx or 1
    self:RefreshJoinThreshold()
end

function guild_setting_msgbox:RefreshJoinThreshold()
    local battle_point = constants["GUILD_JOIN_THRESHOLD"][self.guild_threshold_idx]
    if battle_point == 0 then
        self.threshold_txt:setString(lang_constants:Get("guild_threshold_none"))
    else
        self.threshold_txt:setString(panel_util:ConvertUnit(battle_point))
    end
end

function guild_setting_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "guild_setting_msgbox")
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), "guild_setting_msgbox")

    self.sub_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.guild_threshold_idx  == 1 then
                self.guild_threshold_idx = #constants["GUILD_JOIN_THRESHOLD"]
            else
                self.guild_threshold_idx = self.guild_threshold_idx - 1
            end
            self:RefreshJoinThreshold()
        end
    end)

    self.add_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.guild_threshold_idx >= #constants["GUILD_JOIN_THRESHOLD"] then
                self.guild_threshold_idx = 1
            else
                self.guild_threshold_idx = self.guild_threshold_idx + 1
            end

            self:RefreshJoinThreshold()
        end
    end)

    self.confirm_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:SetSetting(self.guild_threshold_idx)
            graphic:DispatchEvent("hide_world_sub_panel", "guild_setting_msgbox")
        end
    end)
end

return guild_setting_msgbox
