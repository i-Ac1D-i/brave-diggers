local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType


local guild_boss_rule_msgbox = panel_prototype.New(true)
function guild_boss_rule_msgbox:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guild_boss_rule_msgbox.csb")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self:RegisterWidgetEvent()
end

function guild_boss_rule_msgbox:Show()
    self.root_node:setVisible(true)
end

function guild_boss_rule_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return guild_boss_rule_msgbox

