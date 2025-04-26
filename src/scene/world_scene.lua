local constants = require "util.constants"

local user_logic = require "logic.user"
local time_logic = require "logic.time"
local notice_logic = require "logic.notice"
local mail_logic = require "logic.mail"
local daily_logic = require "logic.daily"
local troop_logic = require "logic.troop"
local payment_logic = require "logic.payment"
local reminder_logic = require "logic.reminder"
local platform_manager = require "logic.platform_manager"
local sns_logic = require "logic.sns"
local configuration = require "util.configuration"

local battle_room = require "scene.battle_room"
local scene_manager = require "scene.scene_manager"
local transition_manager = require "scene.transition_manager"
local sub_scene_factory = require "scene.sub_scene_factory"

local prompt_panel = require "ui.prompt_panel"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"

local error_tracer = require "util.error_tracer"
local network = require "util.network"

local graphic = require "logic.graphic"

local SUB_SCENE_ZORDER = 0
local BATTLE_ROOM_ZORDER = 3
local SUB_PANEL_ZORDER = 4
local WORLD_PANEL_ZORDER = 1000
local COMMON_MASK_ZORDER = 1100
local MODAL_PANEL_ZORDER = 1200
local ALERT_PANEL_ZORDER = 1600
local PROMPT_PANEL_ZORDER = 1400
local GLOBAL_FLOATING_PANEL_ZORDER = 1399
local NOVICE_ZORDER = 1500

local MASK_ORIGIN = { x = 0, y = 0 }
local MASK_DESTINATION = { x = 640, y = 1136 }
local MASK_COLOR = { a = 0.8, r = 0.0, g = 0.0, b = 0.0 }

local NOVICE_TRIGGER_TYPE = client_constants.NOVICE_TRIGGER_TYPE

local world_scene = class("world_scene", function()
    return cc.Scene:create()
end)

function world_scene:ctor()
    self:registerScriptHandler(function(event)
        if event == "enter" then
            if PlatformSDK.hideAdBanner then
                PlatformSDK.hideAdBanner()
            end

            if aandm.createBorder then
                aandm.createBorder("ui/border.png")
            end

            self:InitEventDispatcherStack()

            self.ui_root = require "ui.world_panel"
            self.ui_root:Init()
            self:addChild(self.ui_root:GetRootNode(), WORLD_PANEL_ZORDER)

            battle_room:Init()
            self:addChild(battle_room:GetRootNode(), BATTLE_ROOM_ZORDER)

            self.mask_node = ccui.Layout:create()
            self.mask_node:setContentSize(640, 1136)
            self.mask_node:setBackGroundColor(panel_util:GetColor4B(0x000000))
            self.mask_node:setBackGroundColorOpacity(220)
            self.mask_node:setBackGroundColorType(1)
            self.mask_node:setTouchEnabled(true)
            self.mask_node:setVisible(false)
            self:addChild(self.mask_node, COMMON_MASK_ZORDER)

            local channel = platform_manager:GetChannelInfo()
            self.enable_appstore_pay = channel.enable_appstore_pay

            if self.enable_appstore_pay then
                self.loading_spine_node = spine_manager:GetNode("loading", 1.0, false)
                self.loading_spine_node:setPosition(320, 568)

                self.loading_spine_node:setSkin("1")

                self:addChild(self.loading_spine_node, ALERT_PANEL_ZORDER)
            end

            --[[
            self.touch_spine_node = spine_manager:GetNode("touch_effect", 1.0, false)
            self.touch_spine_node:setVisible(false)
            self.touch_spine_node:setTimeScale(1.2)
            self:addChild(self.touch_spine_node, ALERT_PANEL_ZORDER)
            --]]

            self.prompt_panel = prompt_panel.New()
            self.prompt_panel:Init()
            self:addChild(self.prompt_panel:GetRootNode(), PROMPT_PANEL_ZORDER)

            self.global_floating_panel = require "ui.global_floating_panel"
            self.global_floating_panel:Init()
            self:addChild(self.global_floating_panel:GetRootNode(), GLOBAL_FLOATING_PANEL_ZORDER)

            self.novice_manager = require "scene.novice"
            self.novice_manager:Init()
            self:addChild(self.novice_manager:GetRootNode(), NOVICE_ZORDER)

            self.msgbox = require "ui.simple_msgbox"
            self.msgbox:Init()
            self.msgbox:Hide()
            self:addChild(self.msgbox:GetRootNode(), ALERT_PANEL_ZORDER)

            self.sub_scenes = {}
            self.sub_panels = {}

            self.cur_common_sub_panel_zorder = WORLD_PANEL_ZORDER
            self.cur_modal_sub_panel_zorder = MODAL_PANEL_ZORDER

            error_tracer:Init(user_logic:GetUserId() .. "_" .. troop_logic:GetLeaderName(), 120)

            self:RegisterEvent()

            cc.Director:getInstance():getTextureCache():removeUnusedTextures()

            self:OnEnterScene()

        elseif event == "exit" then
            for _, sub_panel in pairs(self.sub_panels) do
                sub_panel:Clear()
            end

            for name, sub_scene in pairs(self.sub_scenes) do
                sub_scene:Clear()
            end

            battle_room:Clear()

            self:removeAllChildren()
        end
    end)
end

function world_scene:InitEventDispatcherStack()
    self.sub_panel_stack = {}

    self.cur_active_sub_scene = nil
    self.next_sub_scene = nil

    self.origin_event_dispatcher = cc.Director:getInstance():getEventDispatcher()

    self.sub_panel_stack[1] = nil
    self.sub_panel_stack_index = 0

    self.sub_scene_stack = {}
    self.sub_scene_stack_index = 0
end

function world_scene:GetSubScene(name)
    local sub_scene = self.sub_scenes[name]

    if not sub_scene then
        local director = cc.Director:getInstance()
        local cur_event_dispatcher = director:getEventDispatcher()

        director:setEventDispatcher(self.origin_event_dispatcher)

        sub_scene = sub_scene_factory:Create(name)

        self.sub_scenes[name] = sub_scene

        self:addChild(sub_scene:GetRootNode(), SUB_SCENE_ZORDER)

        self:sortAllChildren()
        sub_scene:GetRootNode():setVisible(false)

        director:setEventDispatcher(cur_event_dispatcher)
    end

    return sub_scene
end

function world_scene:GetSubPanel(name)
    local sub_panel = self.sub_panels[name]

    if not sub_panel then
        sub_panel = require("ui." .. name)
        sub_panel.__name = name

        local director = cc.Director:getInstance()
        local cur_event_dispatcher = director:getEventDispatcher()
        director:setEventDispatcher(self.origin_event_dispatcher)

        if sub_panel.is_modal then
            sub_panel:Init()
            self:addChild(sub_panel:GetRootNode(), MODAL_PANEL_ZORDER)

        else
            sub_panel:Init()
            self:addChild(sub_panel:GetRootNode(), WORLD_PANEL_ZORDER)
        end
        director:setEventDispatcher(cur_event_dispatcher)

        sub_panel:GetRootNode():setVisible(false)
        self.sub_panels[name] = sub_panel
    end

    return sub_panel
end

function world_scene:FinishChangeSubScene()
    if self.cur_active_sub_scene then
        self.cur_active_sub_scene:Hide(self.next_sub_scene:GetName())
        self.cur_active_sub_scene:GetRootNode():setPosition(0, 0)
    end

    self.cur_active_sub_scene = self.next_sub_scene
    self.next_sub_scene = nil
    self.transition = nil

    self.origin_event_dispatcher:setEnabled(true)
end

function __G__TRACKBACK__(msg)

    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")

    local str = "----------------------------------------\n".. "LUA ERROR: " .. tostring(msg) .. "\n" .. debug.traceback()
    error_tracer:PushErrorInfo(str)

    return msg
end

function world_scene:Update(elapsed_time)
    local success, err = pcall(error_tracer.Update, error_tracer, elapsed_time)

    user_logic:Update(elapsed_time)

    if self.cur_active_sub_scene then
        self.cur_active_sub_scene:Update(elapsed_time)
    end

    --sub_scene 切换
    if self.next_sub_scene then
        if self.transition then
            self.transition:Update(elapsed_time)
        else
            self:FinishChangeSubScene()
        end
    end

    --提示文本
    self.prompt_panel:Update(elapsed_time)

    self.ui_root:Update(elapsed_time)

    if network.cur_msg_name and network.cur_msg_content and self.novice_manager:IsVisbile() then
        self.novice_manager:OnRecvMsg(network.cur_msg_name, network.cur_msg_content)
        network.cur_msg_name = nil
        network.cur_msg_content = nil
    end

    self.novice_manager:Update(elapsed_time)

    battle_room:Update(elapsed_time)

    for name, panel in pairs(self.sub_panels) do
        if panel:IsVisible() then
            panel:Update(elapsed_time)
        end
    end
end

function world_scene:PushSubScene(sub_scene)
    self.sub_scene_stack_index = self.sub_scene_stack_index + 1
    self.sub_scene_stack[self.sub_scene_stack_index] = sub_scene
end

function world_scene:PopSubScene()
    local sub_scene = self.sub_scene_stack[self.sub_scene_stack_index]
    self.sub_scene_stack_index = self.sub_scene_stack_index - 1

    return sub_scene
end

function world_scene:PushSubPanel(sub_panel)
    self.sub_panel_stack_index = self.sub_panel_stack_index + 1
    self.sub_panel_stack[self.sub_panel_stack_index] = sub_panel

    self.mask_node:setVisible(true)
    self.mask_node:setLocalZOrder(self.cur_modal_sub_panel_zorder - 1)
end

function world_scene:PopSubPanel()
    local sub_panel = self.sub_panel_stack[self.sub_panel_stack_index]
    self.sub_panel_stack_index = self.sub_panel_stack_index - 1

    return sub_panel
end

function world_scene:GetCurSubScene()
    return self.cur_active_sub_scene
end

function world_scene:ShowMainSubScene()
    local main_sub_scene = self:GetSubScene("main_sub_scene")
    self.next_sub_scene = main_sub_scene

    self.ui_root:Show("main_sub_scene")
    main_sub_scene:Show()

    self:FinishChangeSubScene()
end

function world_scene:OnEnterScene()
    --检测未完成的订单
    payment_logic:OnFinishAllQuery()

    --显示首页 main_sub_scene
    self:ShowMainSubScene()

    if user_logic:IsJustCreateLeader() and self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["create_leader"]) then
        self.novice_manager:Show()

    else
        if notice_logic:OpenNotice() then
            --公告
            local channel = platform_manager:GetChannelInfo()
            if channel.notice_url then
                notice_logic:SetNewNotice(false)
                graphic:DispatchEvent("show_world_sub_panel", "web_panel", channel.notice_url, "notice_panel_title")

            else
                -- graphic:DispatchEvent("show_world_sub_panel", "notice_panel")
            end

        elseif mail_logic:HasNewMail() then
            --邮件
            graphic:DispatchEvent("show_world_sub_panel", "mail_panel")

        elseif not daily_logic:AlreadyCheckin() and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["explore_box"]) then
            --签到
            daily_logic:RequestDaily()
        end
    end

    --出战阵容有空位 并且 还有佣兵可以上阵 的提醒
    reminder_logic:CheckFormationReminder()
    --检测强化提醒
    reminder_logic:CheckForgeReminder()
end

function world_scene:HideAllSubPanels()
    self.mask_node:setVisible(false)

    for name, panel in pairs(self.sub_panels) do
        if panel:IsVisible() then
            panel:Hide()

            if panel.is_modal then
                self:PopSubPanel()
                self.cur_modal_sub_panel_zorder = self.cur_modal_sub_panel_zorder - 1
            else
                self.cur_common_sub_panel_zorder = self.cur_common_sub_panel_zorder - 1
            end
        end
    end
end

local last_enter_background_time = 0
function world_scene:DidEnterBackground()
    last_enter_background_time = os.time()
end

function world_scene:DidEnterForeground()
    if last_enter_background_time ~= 0 then
        local time_logic = require "logic.time"

        local diff_time = (os.time() - last_enter_background_time)

        time_logic:Update(diff_time)

        self:Update(diff_time)

        last_enter_background_time = 0
    end
end

function world_scene:RegisterEvent()

    graphic:RegisterEvent("show_world_sub_scene", function(sub_scene_name, transition_type, ...)

        if battle_room:IsVisible() then
            return
        end

        local sub_scene = self:GetSubScene(sub_scene_name)
        if sub_scene:IsVisible() then
            return
        end

        self.next_sub_scene = sub_scene

        if self.cur_active_sub_scene then
            if sub_scene:IsRememberFromScene() then
                self:PushSubScene(self.cur_active_sub_scene)
            else
                self.sub_scene_stack_index = 0
            end
        end

        local transition
        if transition_type then
            transition = transition_manager:GetTransition(transition_type)
        end

        if not transition then
            self:FinishChangeSubScene()
        else
            transition:Init(self)
        end

        self.transition = transition

        self.ui_root:Show(sub_scene_name)

        sub_scene:Show(...)
        if self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["first_open_panel"], sub_scene_name) then
            self.novice_manager:Show()
        end
    end)

    graphic:RegisterEvent("hide_world_sub_scene", function()
        local last_sub_scene = self:PopSubScene()

        if self.cur_active_sub_scene then
            self.cur_active_sub_scene:Hide(last_sub_scene and last_sub_scene:GetName() or "main_sub_scene")
            self.cur_active_sub_scene = nil
        end

        if last_sub_scene then
            self.cur_active_sub_scene = last_sub_scene
            if rawget(last_sub_scene, "ShowEx") then
                last_sub_scene:ShowEx()

            else
                last_sub_scene:Show()
            end

            self.ui_root:Show(last_sub_scene:GetName())
        else
            self:ShowMainSubScene()
        end
    end)

    graphic:RegisterEvent("show_battle_room", function(battle_type, data, property, record, is_winner, callback)
        self.ui_root:Hide()

        self.cur_active_sub_scene:HideQuick()
        self:HideAllSubPanels()

        assert(not battle_room.__origin_event_dispatcher, string.format("battle_room is show %s %s %d", tostring(battle_room:IsVisible()), tostring(battle_room.battle_type), battle_type))

        battle_room:PushEventDispatcher()
        battle_room:Show(battle_type, data, property, record, is_winner, callback)
    end)

    graphic:RegisterEvent("hide_battle_room", function()
        if not battle_room:IsVisible() then
            return
        end

        if self.cur_active_sub_scene then
            self.ui_root:Show(self.cur_active_sub_scene:GetName())
        end

        self.cur_active_sub_scene:ShowQuick()

        battle_room:PopEventDispatcher()
        battle_room:Hide()

        if battle_room.battle_status ~= client_constants["BATTLE_STATUS"]["win"] and battle_room.battle_type == client_constants["BATTLE_TYPE"]["vs_monster"] then
            if self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["first_battle_failure"]) then
                self.novice_manager:Show()
            end
        end
    end)

    graphic:RegisterEvent("show_world_sub_panel", function(panel_name, ...)
        
        --当引导时不打开这里的界面
        if panel_name == "campaign_reward_msgbox" and self.novice_manager:IsVisible()then
            return
        elseif panel_name == "campaign_rule_msgbox" and self.novice_manager:IsVisible()then
            return
        end

        if battle_room:IsVisible() then
            return
        end

        local panel = self:GetSubPanel(panel_name)

        if panel.is_modal then
            local index = 0
            for i = 1, self.sub_panel_stack_index do
                local sub_panel = self.sub_panel_stack[i]
                if sub_panel:GetName() == panel:GetName() then
                    index = i
                    break
                end
            end

            if index ~= 0 then
                table.remove(self.sub_panel_stack, index)
                self.sub_panel_stack_index = self.sub_panel_stack_index - 1
                for i = index, self.sub_panel_stack_index do
                    local sub_panel = self.sub_panel_stack[i]
                    sub_panel.root_node:setLocalZOrder(sub_panel.root_node:getLocalZOrder())
                end
            else
                self.cur_modal_sub_panel_zorder = self.cur_modal_sub_panel_zorder + 1
            end

            self:PushSubPanel(panel)
            panel.root_node:setLocalZOrder(self.cur_modal_sub_panel_zorder)

        else
            if panel:IsVisible() then
                return
            end
            self.cur_common_sub_panel_zorder = self.cur_common_sub_panel_zorder + 1
            panel.root_node:setLocalZOrder(self.cur_common_sub_panel_zorder)
        end

        panel:Show(...)
        if self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["first_open_panel"], panel_name) then
            self.novice_manager:Show()
        end
    end)

    local hide_world_sub_panel = function(panel_name, ...)
        local panel = self:GetSubPanel(panel_name)
        if not panel:IsVisible() then
            return
        end

        --隐藏遮罩层
        if panel.is_modal then
            local sub_panel = self.sub_panel_stack[self.sub_panel_stack_index]
            if sub_panel:GetName() ~= panel_name then
                return
            end

            self:PopSubPanel()
            local sub_panel = self.sub_panel_stack[self.sub_panel_stack_index]
            self.cur_modal_sub_panel_zorder = self.cur_modal_sub_panel_zorder - 1

            if sub_panel then
                self.mask_node:setVisible(true)
                self.mask_node:setLocalZOrder(self.cur_modal_sub_panel_zorder - 1)
            else
                self.mask_node:setVisible(false)
            end

        else
            self.cur_common_sub_panel_zorder = self.cur_common_sub_panel_zorder - 1
        end

        panel:Hide(...)

        --检测是否触发新手引导
        if self.cached_event_id and panel_name == "reward_panel" then
            if self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["solve_event"], self.cached_event_id) then
                self.novice_manager:Show()
            end

            self.cached_event_id = nil

        elseif panel_name == "web_panel" then

            --先判断是否是公告的URL
            local channel = platform_manager:GetChannelInfo()
            if panel:GetUrl() == channel.notice_url then
                if mail_logic:HasNewMail() then
                    graphic:DispatchEvent("show_world_sub_panel", "mail_panel")
                else
                    if not daily_logic:AlreadyCheckin() and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["explore_box"], false) then
                        daily_logic:RequestDaily()
                    end
                end
            end

        elseif panel_name == "notice_panel" then
            if mail_logic:HasNewMail() then
                graphic:DispatchEvent("show_world_sub_panel", "mail_panel")
            else
                if not daily_logic:AlreadyCheckin() and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["explore_box"], false) then
                    daily_logic:RequestDaily()
                end
            end

        elseif panel_name == "mail_panel" then
            if not daily_logic:AlreadyCheckin() and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["explore_box"], false) then
                daily_logic:RequestDaily()
            end
        end
    end

    graphic:RegisterEvent("hide_world_sub_panel", hide_world_sub_panel)

    graphic:RegisterEvent("show_prompt_panel", function(prompt_id, ...)
        if scene_manager:GetCurrentSceneName() == "world" then
            self.prompt_panel:Show(prompt_id, ...)
        end
    end)

    graphic:RegisterEvent("show_floating_panel", function(...)
        if scene_manager:GetCurrentSceneName() == "world" then
            self.global_floating_panel:Show(...)
        end
    end)

    graphic:RegisterEvent("hide_floating_panel", function(...)
        if scene_manager:GetCurrentSceneName() == "world" then
            self.global_floating_panel:Hide(...)
        end
    end)

    graphic:RegisterEvent("user_logout", function(is_switch_account)
        cc.Director:getInstance():setEventDispatcher(self.origin_event_dispatcher)
        self.origin_event_dispatcher:removeEventListener(self.touch_listener)

        user_logic:DoLogout()
        scene_manager:ChangeScene("login", is_switch_account)
    end)

    graphic:RegisterEvent("show_auth_result", function(result)
        local scene = cc.Director:getInstance():getRunningScene()
        if not scene or scene.__name ~= "world" then
            return
        end

        if result == "platform_auth_success" and not platform_manager:IsGuestMode() then
            --非游客模式，切换账号
            user_logic:StartLogout(true)
        end

        if platform_manager:GetChannelInfo().third_party_account then
            if result == "platform_auth_success" or result == "platform_auth_fb_band_success" then 
                sns_logic.has_game_bind_fb = true
            end
        end

    end)

    graphic:RegisterEvent("start_waiting", function()
        self.mask_node:setVisible(true)
        cc.Director:getInstance():getEventDispatcher():setEnabled(false)

        if self.enable_appstore_pay then
            self.loading_spine_node:setVisible(true)
            self.loading_spine_node:setAnimation(0, "animation", true)
        end
    end)

    graphic:RegisterEvent("finish_waiting", function(tag)
        local vip_panel = self.sub_panels["vip_panel"]
        if not vip_panel or not vip_panel:IsVisible() then
            self.mask_node:setVisible(false)
        end

        cc.Director:getInstance():getEventDispatcher():setEnabled(true)

        if self.enable_appstore_pay then
            self.loading_spine_node:setVisible(false)
            self.loading_spine_node:clearTrack(0)
        end
    end)

    --完成事件之后需要检查是否触发新手引导
    graphic:RegisterEvent("solve_event_result", function(event_id, is_finish, have_battle)
        if is_finish then
            if have_battle then
                self.cached_event_id = event_id
            else
                if self.novice_manager:Trigger(NOVICE_TRIGGER_TYPE["solve_event"], event_id) then
                    self.novice_manager:Show()
                end
            end
        end
    end)

    --触发新手引导
    graphic:RegisterEvent("trigger_novice_guide", function(trigger_type, param)
        if self.novice_manager:Trigger(trigger_type, param) then
            self.novice_manager:Show()
        end
    end)

    --进入迷宫
    graphic:RegisterEvent("enter_maze", function(area_id, difficulty)
        if self.cur_active_sub_scene:GetName() == "exploring_sub_scene" then
            self.cur_active_sub_scene.maze_component:LoadInfo()
            self.cur_active_sub_scene.ui_root:LoadInfo(area_id, difficulty)

        else
            graphic:DispatchEvent("show_world_sub_scene", "exploring_sub_scene", nil, area_id, difficulty)
        end
    end)

    --网络断开连接
    graphic:RegisterEvent("lost_connection", function()
        self:HideAllSubPanels()

        local title = lang_constants:Get("network_unable_connect_title")
        local desc = lang_constants:Get("network_unable_connect")
        local confirm_txt = lang_constants:Get("network_unable_connect_confirm")
        local login_txt = lang_constants:Get("network_unable_connect_login")

        self.msgbox.root_node:setLocalZOrder(ALERT_PANEL_ZORDER)

        self.msgbox:Show(title, desc, confirm_txt, login_txt, function()
            user_logic:DoReconnect()
        end,

        function()
            user_logic:StartLogout()
        end)
    end)

    --支付开始
    graphic:RegisterEvent("start_purchase", function(product_id)
        local title = lang_constants:Get("payment_order_title")

        local desc = ""
        local product = payment_logic:GetProductInfo(product_id)
        if product then
            desc = string.format(lang_constants:Get("payment_order_desc"), product.name)
        else
            desc = string.format(lang_constants:Get("payment_order_desc"), "")
        end

        local confirm_txt = lang_constants:Get("payment_order_btn1")
        local cancel_txt = lang_constants:Get("payment_order_btn2")

        self.msgbox.root_node:setLocalZOrder(ALERT_PANEL_ZORDER)

        self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
            payment_logic:CheckOrder()
        end,

        function()
            payment_logic:CancelOrder()
        end)
    end)

    graphic:RegisterEvent("finish_purchase", function()
        self.msgbox:Hide()
    end)

    graphic:RegisterEvent("hide_all_sub_panel", function()
        self:HideAllSubPanels()
    end)

    graphic:RegisterEvent("show_simple_msgbox", function(title, desc, confirm_txt, close_txt, callback, close_callback, close_callback2)
        self.msgbox.root_node:setLocalZOrder(ALERT_PANEL_ZORDER)
        self.msgbox:Show(title, desc, confirm_txt, close_txt, callback, close_callback, close_callback2)
    end)

    graphic:RegisterEvent("show_new_notice", function()
        local channel = platform_manager:GetChannelInfo()
        if channel.notice_url then
            notice_logic:SetNewNotice(false)
            graphic:DispatchEvent("show_world_sub_panel", "web_panel", channel.notice_url, "notice_panel_title")

        else
            graphic:DispatchEvent("show_world_sub_panel", "notice_panel")
        end
    end)

    --监听手机返回键
    local key_listener = cc.EventListenerKeyboard:create()
    key_listener:registerScriptHandler(function(key, event)
        if key ~= cc.KeyCode.KEY_ESCAPE then
            return
        end

        if self.novice_manager:IsVisible() then
            return
        end

        if battle_room:IsVisible() then
            return
        end

        local sub_panel = self.sub_panel_stack[self.sub_panel_stack_index]

        
        if self.sub_panel_stack_index > 0 then
            local top_panel = self.sub_panel_stack[self.sub_panel_stack_index]
            hide_world_sub_panel(top_panel:GetName())
        elseif self.ui_root.return_to_main then
            self:ShowMainSubScene()
        elseif self.sub_scene_stack_index > 0 then
            graphic:DispatchEvent("hide_world_sub_scene")
        else
            self:HideAllSubPanels()

            local has_exit = false
            if PlatformSDK.showExit then
                has_exit = PlatformSDK.showExit()
            end
            if self.msgbox:IsVisible() then
                has_exit = true;
            end

            if not has_exit then
                local title = lang_constants:Get("exit_title")
                local desc = lang_constants:Get("exit_desc")
                local confirm_txt = lang_constants:Get("common_confirm")
                local cancel_txt = lang_constants:Get("common_close")

                self.msgbox.root_node:setLocalZOrder(ALERT_PANEL_ZORDER)

                self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                    cc.Director:getInstance():endToLua()
                end)
            else
                self.msgbox:Hide()
            end
        end

    end, cc.Handler.EVENT_KEYBOARD_RELEASED)
    self.origin_event_dispatcher:addEventListenerWithSceneGraphPriority(key_listener, self)

    --点击动画
    local touch_listener = cc.EventListenerTouchOneByOne:create()
    touch_listener:registerScriptHandler(function(touch, event)
        if self.novice_manager:IsVisbile() and self.novice_manager:CanSwallowTouchEvent() then
            self.novice_manager:OnTouchBegan(touch)
            event:stopPropagation()
        end

        --[[
        local location = touch:getLocation()

        self.touch_spine_node:setVisible(true)
        self.touch_spine_node:setPosition(location.x, location.y)
        self.touch_spine_node:setAnimation(0, "animation", false)
        --]]

        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    touch_listener:registerScriptHandler(function(touch, event)

        if self.novice_manager:IsVisbile() and self.novice_manager:CanSwallowTouchEvent() then
            self.novice_manager:OnTouchEned(touch)
            event:stopPropagation()
        end

    end, cc.Handler.EVENT_TOUCH_ENDED)

    touch_listener:registerScriptHandler(function(touch, event)
        if self.novice_manager:IsVisbile() and self.novice_manager:CanSwallowTouchEvent() then
            event:stopPropagation()
        end

    end, cc.Handler.EVENT_TOUCH_MOVED)
    self.touch_listener = touch_listener

    self.origin_event_dispatcher:addEventListenerWithFixedPriority(touch_listener, -1)

    --[[
    self.mask_node:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if not self.novice_manager:IsVisbile() and self.sub_panel_stack_index > 0 then
                local top_panel = self.sub_panel_stack[self.sub_panel_stack_index]
                hide_world_sub_panel(top_panel:GetName())
            end
        end
    end)
    --]]
end

return world_scene
