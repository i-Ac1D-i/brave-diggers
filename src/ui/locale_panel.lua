local common_function = require "util.common_function"
local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local language_logic = require "logic.language"
local scene_manager = require "scene.scene_manager"

local locale_sub_panel = panel_prototype.New()
locale_sub_panel.__index = locale_sub_panel

function locale_sub_panel.New()
    return setmetatable({}, locale_sub_panel)
end

function locale_sub_panel:Init(root_node, language)
    self.root_node = root_node
    self.template_choose = self.root_node:getChildByName( "template_choose" )
    self.chosen_icon = self.template_choose:getChildByName( "chosen_icon" )
    self.language_bg = self.root_node:getChildByName( "language_bg" )
    self.language_img = self.root_node:getChildByName( "language_img" )
    self.language_img:setVisible(false)

    self.language_image = cc.Sprite:create("res/ui/language_"..language..".png")
    if self.language_image then
        self.language_image:setPosition(self.language_img:getPositionX(), self.language_img:getPositionY())
        self.root_node:addChild(self.language_image)
    end

    self.language_mark = language

    self:Choose(false)
end

function locale_sub_panel:Show()
    self.root_node:setVisible(true)
end

function locale_sub_panel:Choose(chosen)
    self.chosen_icon:setVisible(chosen)
    self.language_bg:setVisible(chosen)
end

function locale_sub_panel:Load()
    local cut_language = language_logic:GetLocales()[language_logic:GetChosenLocale()]
    if self.language_mark == cut_language then
        self:Choose(true)
    else
        self:Choose(false)
    end
end

local NODE_BASE_TAG = 100
local SUB_PANEL_HEIGHT = 0
local choose_index = 1
local locale_panel = panel_prototype.New(true)
local login_panel_able = false
function locale_panel:Init(login_panel)
    login_panel_able = login_panel
    self.root_node = cc.CSLoader:createNode( "ui/language_msgbox.csb" )
    self.close_btn = self.root_node:getChildByName( "close_btn" )
    self.confirm_btn = self.root_node:getChildByName( "confirm_btn" )

    self.locale_options = {}

    self.template = self.root_node:getChildByName("language2_bg")
    self.template:setVisible(false)
    SUB_PANEL_HEIGHT = self.template:getContentSize().height
    

    self:RegisterWidgetEvent()
    self:CreateSubPanel()
end

function locale_panel:CreateSubPanel()

    local pos_x = self.template:getPositionX()
    local pos_y = self.template:getPositionY()
    
    local i = 1
    for k, v in pairs(language_logic:GetLocales()) do
        local sub_panel = locale_sub_panel.New()
        sub_panel:Init( self.template:clone(), v )
        sub_panel.root_node:setTag( NODE_BASE_TAG + i )
        sub_panel.root_node:setPosition(pos_x, pos_y - (i - 1) * ( SUB_PANEL_HEIGHT + 21))
        self.root_node:addChild(sub_panel.root_node)
        sub_panel:Show()
        self.locale_options[i] = sub_panel
        sub_panel.root_node:addTouchEventListener(self.choose_fun)
        if platform_manager:GetChannelInfo().locale_panel_touch_all then
            sub_panel.root_node:getChildByName("template_choose"):setTouchEnabled(false)
        end
        i = i + 1
    end
end

function locale_panel:Show()
    
    self:UpdateOptions()

    self.root_node:setVisible(true)
end

function locale_panel:UpdateOptions()
    local i = 1
    for k, v in pairs(language_logic:GetLocales()) do
        local sub_panel = self.locale_options[i]
        sub_panel:Load()

        i = i + 1
    end
end

function locale_panel:RegisterWidgetEvent()

    self.choose_fun = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            language_logic:SetChosenLocale(widget:getTag() - NODE_BASE_TAG)
            self:UpdateOptions()
        end
    end

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local cur_locale = language_logic:GetLocales()[language_logic:GetChosenLocale()]
            configuration:SetLocale(cur_locale)
            configuration:Save()

            lang_constants:Init(cur_locale)

            --common_function.CopyFile(string.format("res/ui/fonts/%s.ttf", platform_manager:GetLocale()), string.format("res/ui/fonts/general.ttf"))
            local icon_panel = require "ui.icon_panel"
            icon_panel:ClearMeta()

            self:Hide()

            -- graphic:DispatchEvent("user_logout", false)
            if login_panel_able then
                scene_manager:ChangeScene("loading", "login")
            else
                graphic:DispatchEvent("user_logout", false)
            end
        end
    end)

    if login_panel_able then
        self.close_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                self:Hide()
            end
        end)
    else
        panel_util:RegisterCloseMsgbox(self:GetRootNode():getChildByName("close_btn"), self:GetName())
    end
    
end

return locale_panel

