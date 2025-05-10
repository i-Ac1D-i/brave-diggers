local config_manager = require "logic.config_manager"
local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local icon_template = require "ui.icon_panel"

local intro_panel = panel_prototype.New()

local intro_panel = panel_prototype.New()
intro_panel.__index = intro_panel

function intro_panel.New()
    return setmetatable({}, intro_panel)
end

function intro_panel:Init()
    self.root_node = ccui.ImageView:create()

    self.root_node:loadTexture("ui/war3.png", ccui.TextureResType.localType)
    self.root_node:getVirtualRenderer():getSprite():getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    self.root_node:setAnchorPoint(0.5, 1.0)
end

function intro_panel:Show(config, index)

end

return intro_panel
