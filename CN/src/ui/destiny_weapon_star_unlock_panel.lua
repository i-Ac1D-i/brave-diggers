local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"
local platform_manager = require "logic.platform_manager"
local channel_info = platform_manager:GetChannelInfo()

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"


local destiny_weapon_star_unlock_panel = panel_prototype.New(true)
function destiny_weapon_star_unlock_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/leader_weapon_stars_up_unlock_msgbox.csb")

    self:RegisterWidgetEvent()
end

function destiny_weapon_star_unlock_panel:Show()
    self.root_node:setVisible(true)
end

function destiny_weapon_star_unlock_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close1_btn"), self:GetName())
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("confirm_btn"), self:GetName())
end

return destiny_weapon_star_unlock_panel

