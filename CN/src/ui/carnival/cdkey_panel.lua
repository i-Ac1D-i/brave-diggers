local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local user_logic = require "logic.user"
local lang_constants = require "util.language_constants"
local client_constants = require "util.client_constants"
local panel_util = require "ui.panel_util"

--礼包码panel
local cdkey_panel = panel_prototype.New()
function cdkey_panel:Init(root_node)
    self.exchange_btn = root_node:getChildByName("exchange_btn")
    self.paste_btn = root_node:getChildByName("paste_btn")
    self.cdkey_textfield = root_node:getChildByName("textfield")
    self.desc_text = root_node:getChildByName("text")
    self.root_node = root_node

    if platform_manager:GetChannelInfo().disable_paste_btn then
        self.paste_btn:setVisible(false)
    end

    self.like_btn = nil
    if platform_manager:GetChannelInfo().cdkey_panel_has_like_btn then
        --天下网游临时like按钮
        local like_btn = ccui.Button:create(
            'button/buttonbg_1.png',
            'button/buttonbg_1.png',
            'button/buttonbg_1.png',
            ccui.TextureResType.plistType
        )

        like_btn:setTitleText(lang_constants:Get("cdkey_panel_like_btn"))
        like_btn:setTitleFontName(client_constants["FONT_FACE"])
        like_btn:setTitleColor(panel_util:GetColor4B(0x000000))
        like_btn:setTitleFontSize(28)
        like_btn:setPosition(320, 400)
        self.root_node:addChild(like_btn)
        self.like_btn = like_btn
    end

    self:RegisterWidgetEvent()
end

function cdkey_panel:RegisterWidgetEvent()
    self.exchange_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local cdkey = self.cdkey_textfield:getString()
            if cdkey ~= "" then
                carnival_logic:TakeRewardByCdkey(cdkey)
            end
        end
    end)

    self.paste_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.paste_btn:setVisible(false)

            local clip_text = platform_manager:GetClipboardText()
            if not clip_text or clip_text == "" then
                graphic:DispatchEvent("show_prompt_panel", "paste_not_string")
            else
                self.desc_text:setVisible(false)
                self.cdkey_textfield:setString(clip_text)
            end
        end
    end)

    self.cdkey_textfield:addEventListener(function(widget, event_type)
        local tag = widget:getTag()
        if event_type == ccui.TextFiledEventType.attach_with_ime then
            self.desc_text:setVisible(false)
            if not platform_manager:GetChannelInfo().disable_paste_btn then
                self.paste_btn:setVisible(true)
            end
        end
    end)

    --TAG:MASTER_MERGE
    if self.like_btn then
        self.like_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TextFiledEventType.attach_with_ime then
                audio_manager:PlayEffect("click")

                local resault = ""

                if platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then
                    local server_info = configuration:GetServerInfo()
                    resault = server_info.id.."|"..user_logic:GetUserLeaderName()
                end

                PlatformSDK.getThirdPartyCarnival(resault)
            end
        end)
    end
end

return cdkey_panel
