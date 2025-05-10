local graphic = require "logic.graphic"
local user_logic = require "logic.user"
local sns_logic = require "logic.sns"

local client_constants = require "util.client_constants"

local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"

local platform_manager = require "logic.platform_manager"
local feedback_manager = require "logic.feedback_manager"
local panel_prototype = require "ui.panel"

local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()
local LOCALE_BUTTON_POS_X = 372
local LOCALE_BUTTON_POS_Y = 60
local PLIST_TYPE = ccui.TextureResType.plistType
local channel_info = platform_manager:GetChannelInfo()

local setting_panel = panel_prototype.New(true)
function setting_panel:Init()
    local channel_info = platform_manager:GetChannelInfo()

    if channel_info.meta_channel == "r2games" then
        self.root_node = cc.CSLoader:createNode("ui/setting_r2gamestw_panel.csb")
    elseif channel_info.meta_channel == "txwy" then
        self.root_node = cc.CSLoader:createNode("ui/setting_r2gamestw_panel.csb")
    elseif channel_info.meta_channel == "qikujp" then
         self.root_node = cc.CSLoader:createNode("ui/setting_r2gamestw_panel.csb")
    elseif channel_info.meta_channel == "txwy_dny" then
        self.root_node = cc.CSLoader:createNode("ui/setting_r2gamestw_panel.csb")
    else
        self.root_node = cc.CSLoader:createNode("ui/setting_panel.csb")
    end

    --音乐图片
    self.music_btn = self.root_node:getChildByName("music_btn")
    --音乐图片 关闭
    self.music_off_icon = self.music_btn:getChildByName("off_icon")
    self.music_text = self.music_btn:getChildByName("text")

    --当前音乐设置
    self.music_off_icon:setVisible(self.music_is_mute)

    --音效图片
    self.music_effect_btn = self.root_node:getChildByName("music_effect_btn")
    --音效图片 关闭
    self.music_effect_off_icon = self.music_effect_btn:getChildByName("off_icon")
    self.music_effect_text = self.music_effect_btn:getChildByName("text")

    --当前音效设置
    self.effect_is_mute = configuration:GetEffectMute()
    self.music_is_mute = configuration:GetMusicMute()

    self:UpdateMusicState()
    self:UpdateSoundEffectState()

    --版本号
    self.version_text = self.root_node:getChildByName("version_text")
    self.version_text:setString("Version " .. configuration:GetVersion())

    --按钮登出
    self.logout_btn = self.root_node:getChildByName("logout_btn")

    --提醒按钮
    self.remind_button = self.root_node:getChildByName("remind_button")
    --开发者list
    self.developers_btn = self.root_node:getChildByName("developer_btn")
    if channel_info.develop_btn_visible ~= nil then
        self.developers_btn:setVisible(channel_info.develop_btn_visible)
    end

    --公司名字
    self.comp_text = self.root_node:getChildByName("comp_text")
    if channel_info.comp_text_visible ~= nil then
        self.comp_text:setVisible(channel_info.comp_text_visible)
    end

    self.usercenter_btn = self.root_node:getChildByName("usercenter_btn")
    if self.usercenter_btn then
        if channel_info.has_user_center_ex then
            -- self.usercenter_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn2"))
        else
            self.usercenter_btn:setVisible(false)
        end
    end
    
    self.customer_btn = self.root_node:getChildByName("customer_btn")
    if self.customer_btn then
        if channel_info.has_customer_btn then
            -- self.customer_btn:getChildByName("text"):setString(lang_constants:Get("feedback_btn_title"))
        else
            self.customer_btn:setVisible(false)
        end
    end
    

    --账号绑定
    self.bind_btn = self.root_node:getChildByName("bind_btn")
    --公告按钮
    self.notice_btn = self.root_node:getChildByName("news_btn")
    if self.notice_btn then
        self.notice_btn:setVisible(false)
    end

    if platform_manager:IsGuestMode() then
        self.bind_btn:setVisible(true)
        self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn1"))

    elseif channel_info.has_user_center then
        self.bind_btn:setVisible(true)
        self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn2"))

    elseif channel_info.third_party_account then
        self.bind_btn:setVisible(true)
        if sns_logic.has_game_bind_fb then
            self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn4"))
        else
            self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn3"))
        end
        --self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn3"))
        
    else
        self.bind_btn:setVisible(false)
        if self.notice_btn then
            self.notice_btn:setVisible(true)
        end
    end

    self.feedback_btn = self.root_node:getChildByName("feedback_bg"):getChildByName("btn")
    self.feedback_btn:setVisible(channel_info.has_feedback)

    self.feedback_new_message_img = self.root_node:getChildByName("feedback_bg"):getChildByName("remind_icon")
    self.feedback_desc_text = self.root_node:getChildByName("feedback_bg"):getChildByName("desc")
    self.feedback_desc_text:setContentSize(350, 80)

    if channel_info.clean_setting_feedback_desc then
        local desc = ""
        self.feedback_desc_text:setString(desc)
    end
    --r2位置修改
    local feedback_desc_text_pos_y=platform_manager:GetChannelInfo().setting_panel_feedback_desc_text_pos_y
    if feedback_desc_text_pos_y~=nil then
        self.feedback_desc_text:setPositionY(self.feedback_desc_text:getPositionY()+feedback_desc_text_pos_y)
    end

    self.language_btn = self.root_node:getChildByName("language_btn")
    if self.language_btn then
        self.language_btn:setVisible(false)
        if type(channel_info.locale) == "table" and #channel_info.locale > 1 then
            self.language_btn:setVisible(true)
        end
    end

    --self.feedback_btn:setTitleText(lang_constants:Get("feedback_btn_title"))
    --self.feedback_btn:setTitleText("Support")

    --[[
    self.locale_btn:setVisible(type(channel_info.locale) == "table")
    --语言切换
    local locale_btn = ccui.Button:create(
        'button/buttonbg_1.png',
        'button/buttonbg_1.png',
        'button/buttonbg_1.png',
        PLIST_TYPE
    )

    locale_btn:setTitleText(lang_constants:Get("locale_btn_title"))
    locale_btn:setTitleFontName(client_constants["FONT_FACE"])
    locale_btn:setTitleColor(panel_util:GetColor4B(0x000000))
    locale_btn:setTitleFontSize(28)
    locale_btn:setPosition(LOCALE_BUTTON_POS_X, LOCALE_BUTTON_POS_Y)
    self.root_node:getChildByName("feedback_bg"):addChild(locale_btn)
    self.locale_btn = locale_btn`

    --先不需要语言切换
    self.locale_btn:setVisible(false)
    --]]
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function setting_panel:Show()
    self.root_node:setVisible(true)
    self.need_save_config = false
    print('gc ', collectgarbage("count"))
    collectgarbage("collect")
    print('gc ', collectgarbage("count"))
end

function setting_panel:UpdateBindState()
    if channel_info.third_party_account then
        if sns_logic.has_game_bind_fb then
            self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn4"))
        else
            self.bind_btn:getChildByName("text"):setString(lang_constants:Get("account_bind_btn3"))
        end
    end
end

function setting_panel:Hide()
    if self.need_save_config then
        self.need_save_config = false
        configuration:Save()
    end

    self.root_node:setVisible(false)
end

function setting_panel:UpdateMusicState()
    if self.music_is_mute then
        self.music_text:setString(lang_constants:Get("setting_music_btn2"))
    else
        self.music_text:setString(lang_constants:Get("setting_music_btn1"))
    end

    self.music_off_icon:setVisible(self.music_is_mute)
end

function setting_panel:UpdateSoundEffectState()
    if self.effect_is_mute then
        self.music_effect_text:setString(lang_constants:Get("setting_sound_btn2"))
    else
        self.music_effect_text:setString(lang_constants:Get("setting_sound_btn1"))
    end
    self.music_effect_off_icon:setVisible(self.effect_is_mute)
end

function setting_panel:RegisterEvent()
    graphic:RegisterEvent("update_setting_bind_state", function()
        self:UpdateBindState()
    end)
end

function setting_panel:RegisterWidgetEvent()
    --音乐开关
    self.music_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self.music_is_mute  = not self.music_is_mute
            audio_manager:SetMusicMute(self.music_is_mute)
            configuration:SetMusicMute(self.music_is_mute)

            self:UpdateMusicState()

            self.need_save_config = true

            -- test
            -- graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            -- graphic:DispatchEvent("show_world_sub_panel", "locale_panel")
        end
    end)

    --音效开关
    self.music_effect_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.effect_is_mute = not self.effect_is_mute
            audio_manager:SetEffectMute(self.effect_is_mute)
            configuration:SetEffectMute(self.effect_is_mute)

            self:UpdateSoundEffectState()

            self.need_save_config = true
        end
    end)

    --登出按钮
    self.logout_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if channel_info.has_signout then
                PlatformSDK.signOut()
            else
                user_logic:StartLogout()
            end
        end
    end)

    --提醒按钮
    self.remind_button:addTouchEventListener(function(widget,event_type)
        if event_type == ccui.TouchEventType.ended then 
           audio_manager:PlayEffect("click")
           graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
           graphic:DispatchEvent("show_world_sub_panel", "remind_list_panel")
        end
    end)

    --开发者list
    self.developers_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_panel", "developer_panel")
        end
    end)

    --账号绑定
    if not channel_info.disable_bind_btn then
        self.bind_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                local channel_info = platform_manager:GetChannelInfo()

                if channel_info.has_user_center then
                    platform_manager:ShowUserCenter()

                elseif platform_manager:IsGuestMode() then
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                    graphic:DispatchEvent("show_world_sub_panel", "account_bind_panel")

                elseif channel_info.third_party_account then
                     if sns_logic.has_game_bind_fb then
                         --登出第三方账号
                         if PlatformSDK.logoutThirdPartyAccount() then
                            sns_logic.has_game_bind_fb = false
                            self:UpdateBindState()
                            graphic:DispatchEvent("remind_sns_reward")
                         end
                     else
                        --绑定第三方账号 state == 1 是绑定账号
                        PlatformSDK.bindThirdPartyAccount(channel_info.third_party_account, 1)
                     end
                end
            end
        end)
    end

    --公告按钮
    if self.notice_btn then
        self.notice_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("show_new_notice")
            end
        end)
    end

    if channel_info.has_user_center_ex then
        self.usercenter_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                platform_manager:ShowUserCenterEx()
            end
        end)
    end

    if channel_info.has_customer_btn then
        self.customer_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                feedback_manager:ShowFeedback(false)
            end
        end)
    end

    --切换语言按钮
    if self.language_btn then
        self.language_btn:addTouchEventListener(function(widget, event_type)

            if event_type ~= ccui.TouchEventType.ended then
                return
            end

            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_panel", "locale_panel", false)
        end)
    end


    --反馈按钮
    self.feedback_btn:addTouchEventListener(function(widget, event_type)
        if event_type ~= ccui.TouchEventType.ended then
            return
        end
        audio_manager:PlayEffect("click")
        feedback_manager:ShowFeedback(false)
    end)

    --关闭按钮
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return setting_panel
