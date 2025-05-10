local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType


local rule_panel = panel_prototype.New(true)
function rule_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_rule_msgbox.csb")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self:RegisterWidgetEvent()
end

function rule_panel:Show()
    self.root_node:setVisible(true)
end

function rule_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return rule_panel

