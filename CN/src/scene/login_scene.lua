local scene_mananger = require "scene.scene_manager"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"

local prompt_panel = require "ui.prompt_panel"
local graphic = require "logic.graphic"
local config_manager = require "logic.config_manager"
local feature_config = require "logic.feature_config"

local user_logic = require "logic.user"
local login_logic = require "logic.login"
local platform_manager = require "logic.platform_manager"
local spine_manager = require "util.spine_manager"
local common_function = require "util.common_function"

local login_scene = class("login_scene", function()
    return cc.Scene:create()
end)

function login_scene:ctor(switch_account)
    self.is_switch_account = switch_account

    self:registerScriptHandler(function(event)
        if event == "enter" then
            --R2修复小语种进入游戏因缺少字体会奔溃的问题
            if platform_manager:GetChannelInfo().meta_channel == "r2games" then
                common_function.CopyFile(string.format("res/ui/fonts/%s.ttf", platform_manager:GetChannelInfo().locale[1]), string.format("res/ui/fonts/general.ttf"))
            end

            configuration:Save()
            config_manager:Init()

            login_logic:Init(self.is_switch_account)

            spine_manager:SetLocale(platform_manager:GetLocale())

            if aandm.createBorder then
                aandm.createBorder("ui/border.png")
            end

            local icon_panel = require "ui.icon_panel"
            icon_panel:InitMeta()

            self.spine_node = spine_manager:GetNode("login", 1.0, true)
            self.spine_node:setPosition(320, 0)
            self:addChild(self.spine_node)

            --随机皮肤
            -- self.spine_node:setSkin("decorate" .. tostring(math.random(1, 6)))
            self.random_num = tostring(1)
            self.ui_root = require "ui.login_panel"
            self.ui_root:Init()
            self:addChild(self.ui_root:GetRootNode())

            self.msgbox = require "ui.simple_msgbox"
            self.msgbox:Init()
            self.msgbox:Hide()
            self:addChild(self.msgbox:GetRootNode())

            self.prompt_panel = prompt_panel.New()
            self.prompt_panel:Init()
            self:addChild(self.prompt_panel:GetRootNode())

            --TAG:MASTER_MERGE
            self.animation_state = 1
            if platform_manager:GetChannelInfo().region == "china" then
                if not _G["HAS_SHOW_NOTIC"] then
                    self.animation_state = 0
                end
            end
            
            self.ui_root:HideAllSubPanel()

            self:RegisterEvent()

            local texture_cache = cc.Director:getInstance():getTextureCache()
            local tex = texture_cache:getTextureForKey("ui/login.png")
            if tex then
                tex:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            end

            self.spine_node:registerSpineEventHandler(function (event)
                if event.animation == "start" .. "_" .. self.random_num then
                    self.spine_node:setAnimation(1, "loop" .. "_" .. self.random_num, true)
                    self.animation_state = 3

                    if login_logic.has_parsed_server_list then
                        self:Reset()
                    else
                        self.ui_root:SetLoadingTime(5)
                    end
                end
            end, sp.EventType.ANIMATION_END)

        elseif event == "exit" then
            self.prompt_panel:Clear()
            self:removeAllChildren()
        end
    end)
end

function login_scene:Update(elapsed_time)
    if self.prompt_panel then
        self.prompt_panel:Update(elapsed_time)
    end

    self.ui_root:Update(elapsed_time)

    if self.animation_state == 0 then
        local visible_size = cc.Director:getInstance():getVisibleSize()

        local logo_health_sprite = cc.Sprite:create("res/ui/logo_healthNotice.png")
        logo_health_sprite:setPosition(visible_size.width / 2, visible_size.height / 2)

        self:addChild(logo_health_sprite)

        logo_health_sprite:runAction(cc.Sequence:create( 
                                                    cc.FadeIn:create(0.5),
                                                    cc.DelayTime:create(3),
                                                    cc.FadeOut:create(0.5),
                                                    cc.CallFunc:create(function()
                                                            _G["HAS_SHOW_NOTIC"] = true
                                                            self.animation_state = 1
                                                        end)
                                                    )
        )

        self.animation_state = nil
    elseif self.animation_state == 1 then
        self.spine_node:setAnimation(0, "start" .. "_" .. self.random_num, false)
        self.animation_state = 2
    end
end

function login_scene:Reset()
    if self.animation_state ~= 3 then
        return
    end

    if _G["AUTH_MODE"] then
        PlatformSDK.createAdBanner()
    end

    local network = require "util.network"
    if not _G["NETWORK_POLL_SCHEDULE_ID"] then
        network:RegisterProto()
        _G["NETWORK_POLL_SCHEDULE_ID"] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function(elapsed_time)
            network:Update(elapsed_time)
        end, 0, false)
    end

    if not _G["SHOW_SDK_NOTICE"] then
        --检测是否需要显示渠道商的公告
        _G["SHOW_SDK_NOTICE"] = true

        if PlatformSDK.isFunctionSupported and PlatformSDK.isFunctionSupported(109) then
            PlatformSDK.callFunction(109)
        end
    end

    self.ui_root:ShowBottom()

    if self.is_switch_account then
        self.is_switch_account = false
        self.ui_root:AuthSuccess()
    end

    audio_manager:SetEffectMute(configuration:GetEffectMute())
    audio_manager:SetMusicMute(configuration:GetMusicMute())

    audio_manager:StopCurrentMusic()
    audio_manager:StopEffect("dig_block")

    audio_manager:PlayMusic("field", true)

    cc.Director:getInstance():getEventDispatcher():setEnabled(true)
end

--注册逻辑事件
function login_scene:RegisterEvent()

    graphic:RegisterEvent("fetch_server_list", function(success)
        self.ui_root.loading_node:setVisible(false)

        if success then
            self:Reset()
        else
            local title = lang_constants:Get("network_unable_connect_title")
            local desc = lang_constants:Get("network_unable_connect")
            local confirm_txt = lang_constants:Get("network_unable_connect_confirm")
            local cancel_txt = lang_constants:Get("common_cancel")

            self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                self.ui_root:SetLoadingTime(5)
                login_logic:ParseServerList()
            end,

            function()
                cc.Director:getInstance():endToLua()
            end)
        end
    end)

    graphic:RegisterEvent("update_app_msgbox", function(url)

        local title = lang_constants:Get("force_update_msg_title")
        local desc = lang_constants:Get("force_update_msg_desc")
        local confirm_txt = lang_constants:Get("force_update_msg_update_btn")
        local cancel_txt = lang_constants:Get("force_update_msg_closed_btn")

        self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
            cc.Application:getInstance():openURL(url)
            cc.Director:getInstance():endToLua()
        end,

        function()
            cc.Director:getInstance():endToLua()
        end)
    end)

    graphic:RegisterEvent("show_login_panel", function()
        self.ui_root:ShowBottom()
    end)

    graphic:RegisterEvent("show_prompt_panel", function(prompt_id, ...)
        if scene_mananger:GetCurrentSceneName() == "login" then
            self.prompt_panel:Show(prompt_id, ...)
        end
    end)

    graphic:RegisterEvent("user_finish_login", function(user_id, reconnect_token, is_create)
        user_logic:Init(user_id, reconnect_token)

        if is_create then
            scene_mananger:ChangeScene("create_leader")

        else
            scene_mananger:ChangeScene("loading", "world")
            user_logic:Query()
        end

    end)

    graphic:RegisterEvent("show_login_result", function(result, arg)
        if result == "forbidden_login" then
            local title = lang_constants:Get("account_forbid_login_title")
            local desc = lang_constants:Get("account_forbid_login")
            local confirm_txt = lang_constants:Get("common_confirm")
            local cancel_txt = lang_constants:Get("common_cancel")

            self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()

            end,
            function()
            end)

        elseif result == "version_too_low" then
            local title = lang_constants:Get("account_version_too_low_title")
            local desc = lang_constants:Get("account_version_too_low")
            local confirm_txt = lang_constants:Get("account_version_too_low_confirm")
            local cancel_txt = lang_constants:Get("common_cancel")

            self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                cc.Director:getInstance():endToLua()
            end,

            function()
            end)
        end
    end)

    --监听手机返回键
    local key_listener = cc.EventListenerKeyboard:create()
    key_listener:registerScriptHandler(function(key, event)
        if key ~= cc.KeyCode.KEY_ESCAPE then
            return
        end
        local has_exit = false
        if PlatformSDK.showExit then
            has_exit = PlatformSDK.showExit()
        end

        if not has_exit then
            local title = lang_constants:Get("exit_title")
            local desc = lang_constants:Get("exit_desc")
            local confirm_txt = lang_constants:Get("common_confirm")
            local cancel_txt = lang_constants:Get("common_close")

            self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                cc.Director:getInstance():endToLua()
            end,

            function()
            end)
        end

    end, cc.Handler.EVENT_KEYBOARD_RELEASED)

    local event_dispatcher = self:getEventDispatcher()
    event_dispatcher:addEventListenerWithSceneGraphPriority(key_listener, self)
end

return login_scene
