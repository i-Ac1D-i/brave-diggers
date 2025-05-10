local panel_prototype = require "ui.panel"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local VISIBLE_SIZE_WIDTH
local VISIBLE_SIZE_HEIGHT

local prompt_panel = panel_prototype.New()
prompt_panel.__index = prompt_panel

function prompt_panel.New()
    return setmetatable({}, prompt_panel)
end
   
function prompt_panel:Init()
    VISIBLE_SIZE_WIDTH = cc.Director:getInstance():getVisibleSize().width
    VISIBLE_SIZE_HEIGHT = cc.Director:getInstance():getVisibleSize().height

    self.root_node = ccui.Text:create("", client_constants["FONT_FACE"], 36)
    self.duration = 0
    self.max_duration = 2
    local prompt_color = platform_manager:GetChannelInfo().prompt_color
    if prompt_color then
        self.root_node:setFontSize(42)
        self.root_node:setTextColor(prompt_color)
    else
        self.root_node:setTextColor({ r = 255, g = 235, b = 0, a = 255 })
    end
    
    self.root_node:ignoreContentAdaptWithSize(false)
    self.root_node:setContentSize(620, 36)
    self.root_node:setTextHorizontalAlignment(1)
    self.root_node:setPosition(VISIBLE_SIZE_WIDTH * 0.5, VISIBLE_SIZE_HEIGHT * 0.75)

    self.root_node:enableOutline({ r = 0, g = 0, b = 0, a = 255 }, 3)
    if not platform_manager:GetChannelInfo().is_open_system and not PlatformSDK.openChangeSystem then
        self.root_node:getVirtualRenderer():setAdditionalKerning(-5)
    end

    self.root_node:setVisible(false)
end

function prompt_panel:Show(prompt_id, ...)
    self.max_duration = 2
    self.duration = self.max_duration

    self.root_node:setPosition(VISIBLE_SIZE_WIDTH * 0.5, VISIBLE_SIZE_HEIGHT * 0.75)
    self.root_node:setOpacity(255)

    local str = ""
    if prompt_id ~= "" then
        local arg = {...}
        if prompt_id == "feature_unlock" and arg[1] == "FYD_MINING_BOSS" then   --FYD 礦區最後一個BOSS 提示未開放
            str = arg[2] 
        else 
            str = lang_constants:Get(prompt_id) and string.format(lang_constants:Get(prompt_id), ...) or "" 
        end

    else
        local arg = {...}
        str = arg[1]
    end

    self.root_node:setString(str)
    --FYD  增加文本的高度，使得字符可以换行
    local extern_height = platform_manager:GetChannelInfo().extern_height or 0
    local line_num = self.root_node:getVirtualRenderer():getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
        local size = self.root_node:getAutoRenderSize()
        local content_size = self.root_node:getVirtualRenderer():getContentSize()
        line_num = math.ceil(size.width / content_size.width) 
    end 
    local text_height = line_num * 36 + 55 + extern_height

    self.root_node:setContentSize(620, text_height)

    self.root_node:setVisible(true)
end

function prompt_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time

    if self.duration < 0 then
        self:Hide()

    else
        self.root_node:setPositionY(VISIBLE_SIZE_HEIGHT * ( 0.75 + 0.05 * ( 1 - self.duration / self.max_duration)))
        self.root_node:setOpacity(self.duration / self.max_duration * 255)
    end
end

return prompt_panel

