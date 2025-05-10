local graphic = require "logic.graphic"
local user_logic = require "logic.user"

local prompt_panel = require "ui.prompt_panel"
local scene_manager = require "scene.scene_manager"

local network = require "util.network"

local error_tracer = require "util.error_tracer"
local configuration = require "util.configuration"

local create_leader_scene = class("create_leader_scene", function()
    return cc.Scene:create()
end)

function create_leader_scene:ctor()
    self:registerScriptHandler(function(event)
        if event == "enter" then

            if user_logic.user_id and user_logic.user_id ~= "" then
                error_tracer:Init(user_logic.user_id, 2)
            else
                local acc = configuration:GetAccoutAndPwd()
                error_tracer:SetUserId(acc or "unknown", 2)
            end

            self.ui_root = require "ui.create_leader_panel"
            self.ui_root:Init()
            self.ui_root:Show()

            self:addChild(self.ui_root:GetRootNode())

            self.remain_time_to_hide = 0

            self.prompt_panel = prompt_panel.New()
            self.prompt_panel:Init()
            self:addChild(self.prompt_panel:GetRootNode())

            self:RegisterEvent()

            self.is_init = true

        elseif event == "exit" then
            self.ui_root:Clear()
            self:removeAllChildren()
        end
    end)
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

function create_leader_scene:Update(elapsed_time)
    local success, err = pcall(error_tracer.Update, error_tracer, elapsed_time)

    if not self.is_init then
        return
    end

    if self.remain_time_to_hide > 0 then
        self.remain_time_to_hide = self.remain_time_to_hide - elapsed_time
        if self.remain_time_to_hide <= 0 then
            self.ui_root.prompt_text:setVisible(false)
        end
    end
    
    self.prompt_panel:Update(elapsed_time)

    if network:HasLostConnection() then
        network:Clear()
        scene_manager:ChangeScene("login")
    end

    self.ui_root:Update(elapsed_time)
end

--注册逻辑事件
function create_leader_scene:RegisterEvent()
    graphic:RegisterEvent("show_prompt_panel", function(prompt_id, ...)
        if scene_manager:GetCurrentSceneName() == "create_leader" then
            self.prompt_panel:Show(prompt_id, ...)
        end
    end)

    graphic:RegisterEvent("user_finish_create_leader", function(result)
        if result == "success" then
            local scene = scene_manager:ChangeScene("loading", "world")
            user_logic:Query()

        elseif result == "invalid_name" then
            self.prompt_panel:Show("account_leader_name_invalid_char")

        elseif result == "repeat_name" then
            self.prompt_panel:Show("account_repeat_leader_name")
        end
    end)

    graphic:RegisterEvent("user_logout", function(prompt_id, ...)
        if scene_manager:GetCurrentSceneName() == "create_leader" then
            scene_manager:ChangeScene("login")
        end
    end)
end

return create_leader_scene
