local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"

local PLIST_TYPE = ccui.TextureResType.plistType

local create_msgbox = panel_prototype.New(true)
function create_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/guild_found_panel.csb")
    local root_node = self.root_node

    local guild_name = root_node:getChildByName("guild_name")
    self.default_txt = guild_name:getChildByName("default_txt")
    self.guild_name_textfield = guild_name:getChildByName("guild_name_textfield")

    local bg_condition = root_node:getChildByName("bp_condition")
    self.sub_btn = bg_condition:getChildByName("sub_btn")
    self.add_btn = bg_condition:getChildByName("add_btn")

    self.threshold_txt = bg_condition:getChildByName("buy_num")

    self.cost_bg = root_node:getChildByName("cost_bg")
    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function create_msgbox:Show()
    self.root_node:setVisible(true)
    self.guild_threshold_idx  = guild_logic.bp_limit_idx or 1
    self:RefreshJoinThreshold()
end

function create_msgbox:RefreshJoinThreshold()
    local battle_point = constants["GUILD_JOIN_THRESHOLD"][self.guild_threshold_idx]
    if battle_point == 0 then
        self.threshold_txt:setString(lang_constants:Get("guild_threshold_none"))
    else
        self.threshold_txt:setString(panel_util:ConvertUnit(battle_point))
    end
end

function create_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "guild.create_msgbox")
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("canel_btn"), "guild.create_msgbox")

    self.confirm_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local guild_name = self.guild_name_textfield:getString()
            audio_manager:PlayEffect("click")
            guild_logic:CreateGuild(guild_name, self.guild_threshold_idx)
        end
    end)

    self.sub_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.guild_threshold_idx == 1 then
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

    self.guild_name_textfield:addEventListener(function(sender, event_type)
        if event_type == ccui.TextFiledEventType.attach_with_ime then
            self.default_txt:setVisible(false)
        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
        end
    end)
end

function create_msgbox:RegisterEvent()
    graphic:RegisterEvent("join_guild", function()
        if not self.root_node:isVisible() then
            return
        end

        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
    end)
end

return create_msgbox
