local panel_prototype = require "ui.panel"
local platform_manager = require "logic.platform_manager"

--文本展示活动
local text_panel = panel_prototype.New()
text_panel.__index = text_panel

function text_panel.New()
    return setmetatable({}, text_panel)
end

function text_panel.InitMeta(root_node)
    text_panel.meta_root_node = root_node
end

function text_panel:Init(root_node)
    self.root_node = self.meta_root_node:clone()

    self.name_text = self.root_node:getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")
    self.tip_desc_text = self.root_node:getChildByName("tip_bg"):getChildByName("desc")

    local append = platform_manager:GetChannelInfo().text_pannel_appending
    if append then
        local size = self.desc_text:getContentSize()
        size.height = size.height + append
        self.desc_text:setContentSize(size) 
        local x,y = self.desc_text:getPosition()
        self.desc_text:setPosition(x,y+append/2)
    end
end

function text_panel:Show(config, index)
    self.name_text:setString(self:GetLocaleInfoString(config, "mult_str1", index))
    self.desc_text:setString(self:GetLocaleInfoString(config, "mult_str2", index))
    self.tip_desc_text:setString(self:GetLocaleInfoString(config, "mult_str2", index + #config.mult_str2 / 2))
    self.root_node:setVisible(true)
end

function text_panel:GetLocaleInfoString( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

return text_panel
