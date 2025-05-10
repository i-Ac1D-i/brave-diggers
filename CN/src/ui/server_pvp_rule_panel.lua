local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local server_pvp_rule_panel = panel_prototype.New(true)
function server_pvp_rule_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/server_pvp_rule_msgbox.csb")

    self:RegisterWidgetEvent()
end

function server_pvp_rule_panel:Show()
    self.root_node:setVisible(true)
end

function server_pvp_rule_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return server_pvp_rule_panel

