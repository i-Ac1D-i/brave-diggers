local carnival_logic = require "logic.carnival"

local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local icon_template = require "ui.icon_panel"

--优惠活动信息
local discount_panel = panel_prototype.New()
discount_panel.__index = discount_panel

function discount_panel.New()
    return setmetatable({}, discount_panel)
end

function discount_panel.InitMeta(root_node)
    discount_panel.meta_root_node = root_node
end

function discount_panel:Init()
    self.root_node = self.meta_root_node:clone()
    self.icon_img = self.root_node:getChildByName("icon")
    self.desc_text = self.root_node:getChildByName("desc")
end

function discount_panel:Show(config, index)
    local str_index = config.mult_str1 == 1 and 1 or index
    local icon_index = config.mult_str2 == 1 and 1 or index
    self.desc_text:setString(self:GetLocaleInfoString(config, "mult_str1", str_index))
    self.icon_img:loadTexture(config.mult_str2[icon_index], PLIST_TYPE)
    self.root_node:setVisible(true)
end

function discount_panel:GetLocaleInfoString( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

return discount_panel
