local json = require "util.json"
local login_logic = require "logic.login"
local user_logic = require "logic.user"

local platform_manager = require "logic.platform_manager"

local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"

local panel_prototype = require "ui.panel"

local register_panel = panel_prototype.New()
function register_panel:Init(root_node)
    self.root_node = root_node

    self.username_bg_img = self.root_node:getChildByName("username_bg")
    self.password_bg_img =self.root_node:getChildByName("password_bg")

    self.username_textfield = self.username_bg_img:getChildByName("textfield")
    self.pwd_textfield = self.password_bg_img:getChildByName("textfield")

    local touch_size = {width = 508, height = 60}
    self.username_textfield:setTouchAreaEnabled(true)
    self.username_textfield:setTouchSize(touch_size)

    self.pwd_textfield:setTouchAreaEnabled(true)
    self.pwd_textfield:setTouchSize(touch_size)

    self.username_desc_text = self.root_node:getChildByName("desc3")
    self.pwd_desc_text = self.root_node:getChildByName("desc4")

    self.username_textfield:setTag(1)
    self.pwd_textfield:setTag(2)

    self.title_text = self.root_node:getChildByName("title"):getChildByName("name")

    self.confirm_btn = self.root_node:getChildByName("confirm")

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local name = self.username_textfield:getString()
            local pwd = self.pwd_textfield:getString()

            if self.is_register then
                login_logic:SignUp(name, pwd)

            else
                login_logic:SignIn(name, pwd)
            end
        end
    end)

    local click_textfield_method = function(widget, event_type)
        local tag = widget:getTag()
        if event_type == ccui.TextFiledEventType.attach_with_ime then

            if widget:getTag() == self.username_textfield:getTag() then
                self.username_desc_text:setVisible(false)

            else
                self.pwd_desc_text:setVisible(false)
            end

        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
        end
    end

    self.username_textfield:addEventListener(click_textfield_method)
    self.pwd_textfield:addEventListener(click_textfield_method)
end

function register_panel:Show(is_register)

    self.is_register = is_register

    self.username_desc_text:setVisible(true)
    self.pwd_desc_text:setVisible(true)

    self.username_textfield:setString("")
    self.pwd_textfield:setString("")

    if self.is_register then
        self.confirm_btn:setTitleText(lang_constants:Get("account_bind_signup_btn"))
        self.title_text:setString(lang_constants:Get("account_bind_signup_title"))

    else
        self.confirm_btn:setTitleText(lang_constants:Get("account_bind_auth_btn"))
        self.title_text:setString(lang_constants:Get("account_bind_auth_title"))
    end

    self.root_node:setVisible(true)
end

local bind_msgbox = panel_prototype.New()

function bind_msgbox:Init(root_node)
    self.root_node = root_node

    self.confirm_btn = self.root_node:getChildByName("btn")

    self.desc_text = self.root_node:getChildByName("desc")
end

function bind_msgbox:Show()
    self.root_node:setVisible(true)

    self:Load(false)
end

function bind_msgbox:Load(is_success)
    if is_success then
        self.confirm_btn:setTitleText(lang_constants:Get("account_bind_confirm_btn2"))
        self.desc_text:setString(lang_constants:Get("account_bind_desc2"))
    else
        self.confirm_btn:setTitleText(lang_constants:Get("account_bind_confirm_btn1"))
        self.desc_text:setString(lang_constants:Get("account_bind_desc1"))
    end

    self.is_success = is_success
end

local account_bind_panel = panel_prototype.New(true)
function account_bind_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guest_login_panel.csb")

    self.choose_node = self.root_node:getChildByName("choose_node")

    self.register_node = self.root_node:getChildByName("register_node")
    register_panel:Init(self.register_node)

    self.bind_node = self.root_node:getChildByName("bind_node")
    bind_msgbox:Init(self.bind_node)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function account_bind_panel:Show()
    self.choose_node:setVisible(true)
    self.register_node:setVisible(false)
    self.bind_node:setVisible(false)

    self.root_node:setVisible(true)
end

function account_bind_panel:RegisterEvent()
    graphic:RegisterEvent("show_auth_result", function(result)
        if not self.root_node:isVisible() then
            return
        end

        local scene = cc.Director:getInstance():getRunningScene()
        if scene and scene.__name == "world" and result == "platform_auth_success" and platform_manager:IsGuestMode() then
            self.register_node:setVisible(false)
            bind_msgbox:Show(false)
        else
            graphic:DispatchEvent("show_prompt_panel", result)
        end
    end)

    graphic:RegisterEvent("show_bind_account_result", function(result)
        if result == "success" then
            bind_msgbox:Load(true)

        elseif result == "invalid_pwd" then
            self.bind_success = false
            graphic:DispatchEvent("show_prompt_panel", "account_bind_invalid_pwd")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

        elseif result == "invalid_account" then
            self.bind_success = false
            graphic:DispatchEvent("show_prompt_panel", "account_bind_already_create_leader")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

        else
            self.bind_success = false
            graphic:DispatchEvent("show_prompt_panel", "unknown_error")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

function account_bind_panel:RegisterWidgetEvent()

    self.choose_node:getChildByName("close_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --创建新账号
    self.choose_node:getChildByName("new_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.choose_node:setVisible(false)

            register_panel:Show(true)
        end
    end)

    --绑定旧有账号
    self.choose_node:getChildByName("old_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.choose_node:setVisible(false)
            
            register_panel:Show(false)
        end
    end)

    self.register_node:getChildByName("close_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.choose_node:setVisible(true)
            self.register_node:setVisible(false)
        end
    end)

    --绑定确认
    bind_msgbox.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if bind_msgbox.is_success then
                user_logic:StartLogout()

            else
                login_logic:BindAccount()
            end
        end
    end)
end

return account_bind_panel
