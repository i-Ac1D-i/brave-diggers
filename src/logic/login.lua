local network = require "util.network"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local json = require "util.json"
local platform_manager = require "logic.platform_manager"
local configuration = require "util.configuration"
local http_client = require "logic.http_client"
local analytics_manager = require "logic.analytics_manager"
local constants = require "util.constants"
local scene_manager = require "scene.scene_manager"

local APPSTORE_SERVER_LIST =
{
    { ip = "192.168.199.117", name = "苹果服务器", id = 1, status = 1 },
}

local MIN_PASSWORD_LEN = 6

_G["AUTH_MODE"] = false

local COMMON_SALT = "AANDM"
local PORT = "8888"

local login = {}

function login:Init(is_switch_account)
    if not is_switch_account then
        self.openid, self.access_token = "", ""
    end

    self.is_user_login = false

    self.channel_info = platform_manager:GetChannelInfo()

    if PlatformSDK.getOriginVersion then
        self.origin_version = PlatformSDK.getOriginVersion()
    else
        self.origin_version = nil
    end

    if PlatformSDK.getCodeVersion then
        self.code_version = PlatformSDK.getCodeVersion()
    else
        self.code_version = nil
    end

    local server_id = configuration:GetServerId()
    self.server_id = server_id

    self.account_delegate = platform_manager:GetAccountDelegate()
    self.account_delegate:Clear()

    if self.channel_info.is_debug then
        function login:SignIn(openid, pwd)
            self.openid = openid
            self.access_token = pwd
            self.platform = "mu77"

            configuration:SetAccountInfo(openid, pwd)
            configuration:Save()

            self:FilterServerList(self.account_delegate.is_admin)

            graphic:DispatchEvent("show_auth_result", "platform_auth_success")
        end
        --[[
        --登录
        function login:ParseServerList()
            if self.has_parsed_server_list then
                return
            end

            local platform = cc.Application:getInstance():getTargetPlatform()
            local path = "src/server_list_debug.json"

            local content = aandm.getDataFromFile(path)
            local json_obj 

            if content == "" then
                json_obj = {
                    game_server = {
                        { ip = "192.168.199.44", name = "xiaor", name_de = "de", name_fr = "fr", id = 1, status = 1, 
                        author = "i", author_de = "i_de", author_fr = "i_fr"}
                    },
                    notice = {notice = "test1", notice_de = "test2", notice_fr = "test3"}
                }

            else
                json_obj = json:decode(content)
            end

            self.origin_server_list = json_obj.game_server
            self.server_list = json_obj.game_server

            self.bbs_server = json_obj.bbs_server or ""
            self.comment_server = json_obj.comment_server or ""

            self.global_notice = json_obj.notice

            self.has_parsed_server_list = true
        end
        --]]
    end

    self:ParseServerList()

    self:RegisterMsgHandler()
end

function login:IsInAuthMode(origin_version, remote_version)
    if not origin_version then
        return false
    end

    if not remote_version then
        return false
    end

    local major_ver1, minor_ver1, fix_ver1 = string.match(origin_version, "(%d+).(%d+).(%d+)")
    local major_ver2, minor_ver2, fix_ver2 = string.match(remote_version, "(%d+).(%d+).(%d+)")

    major_ver1, minor_ver1, fix_ver1 = tonumber(major_ver1), tonumber(minor_ver1), tonumber(fix_ver1)
    major_ver2, minor_ver2, fix_ver2 = tonumber(major_ver2), tonumber(minor_ver2), tonumber(fix_ver2)

    if not major_ver1 or not major_ver2 then
        return false
    end

    if not minor_ver1 or not minor_ver2 then
        return false
    end

    if not fix_ver1 or not fix_ver2 then
        return false
    end


    if major_ver1 > major_ver2 then
        return true
    end

    if major_ver1 == major_ver2 and minor_ver1 > minor_ver2 then
        return true
    end

    if major_ver1 == major_ver2 and minor_ver1 == minor_ver2 and fix_ver1 > fix_ver2 then
        return true
    end

    return false
end

function login:IsInAuthMode2(code_version, remote_version)
    if not code_version then
        return false
    end

    if not remote_version then
        return false
    end

    if tonumber(code_version) > tonumber(remote_version) then
        return true
    end

    return false
end

function login:IsNeedUpdateApp(code_version, remote_version)
    if not code_version then
        return false
    end

    if not remote_version then
        return false
    end

    if tonumber(code_version) < tonumber(remote_version) then
        return true
    end

    return false
end

function login:ParseServerList()
    if self.has_parsed_server_list then
        return
    end

    local url = platform_manager:GetServerListUrl()

    http_client:Get(url, function(status_code, content)

        if status_code == 200 and string.len(content) ~= 0 then
            local json_obj = json:decode(content)

            self.comment_server = json_obj.comment_server or ""
            self.bbs_server = json_obj.bbs_server or ""
            self.global_notice = json_obj.notice or ""

            local auth_name = self.channel_info.auth_name
            local force_update = self.channel_info.force_update
            local auth_code = self.channel_info.auth_code

            if (auth_name and self:IsInAuthMode(self.origin_version, json_obj[auth_name])) or (auth_code and self:IsInAuthMode2(self.code_version, json_obj[auth_code])) then
                _G["AUTH_MODE"] = true

                self.server_id = 1
                self.server_list = json_obj.auth_server or APPSTORE_SERVER_LIST
                local info = platform_manager:GetChannelInfo()
                self.bbs_server = json_obj.auth_bbs_server or "120.26.161.100:8128"
                self.comment_server = json_obj.auth_comment_server or "120.26.126.44.:8136"

                self.origin_server_list = self.server_list
            elseif self.channel_info.force_update and json_obj.update_url and self:IsNeedUpdateApp(self.code_version, json_obj[force_update]) then
                graphic:DispatchEvent("update_app_msgbox", json_obj.update_url)
                return
            else
                local found = false

                self.origin_server_list = json_obj.game_server
                self.server_list = self.origin_server_list

                for i = 1, #self.origin_server_list do
                    if self.origin_server_list[i].id == self.server_id then
                        found = true
                    end
                end

                if not found then
                    self.server_id = self.origin_server_list[1].id
                end
            end

            self.has_parsed_server_list = true
            graphic:DispatchEvent("fetch_server_list", true)

        else
            graphic:DispatchEvent("fetch_server_list", false)
        end
    end)
end

function login:GetServerList()
    return self.server_id, self.server_list
end

function login:GetServerInfo(server_id)
    for i = 1, #self.server_list do
        if self.server_list[i].id == server_id then
            return self.server_list[i]
        end
    end
end

function login:FilterServerList(is_admin)
    self.server_list = {}
    for i = 1, #self.origin_server_list do
        local server_info = self.origin_server_list[i]
        server_info.port = server_info.port or PORT

        if not server_info.is_test or is_admin then
            table.insert(self.server_list, server_info)
        end
    end
end

function login:GetGlobalNotice()
    local relust = ""
    if type(self.global_notice) == "string" then
        relust = self.global_notice
    elseif type(self.global_notice) == "table" then
        if self.global_notice["notice_"..platform_manager:GetLocale()] then
            relust = self.global_notice["notice_"..platform_manager:GetLocale()]
        else
            relust = self.global_notice.notice
        end
    end

    return relust
end

function login:CheckString(name, pwd)
    if string.match(name, '[^a-zA-Z0-9%@%_%.%-]') then
        graphic:DispatchEvent("show_prompt_panel", "account_leader_name_invalid_char")
        return false
    end

    if string.len(name) < MIN_PASSWORD_LEN or string.len(pwd) < MIN_PASSWORD_LEN then
        graphic:DispatchEvent("show_prompt_panel", "account_password_not_enough", MIN_PASSWORD_LEN)
        return false
    end

    return true
end

function login:UserLoginSuccess(user_id, server_time, time_zone)
    self.is_user_login = true

    self.account_delegate:UserLogin(true)

    local server_info = self:GetServerInfo(self.server_id)

    configuration:SetServerInfo(server_info)

    time_logic:SyncTime(server_time, time_zone)

    if PlatformSDK.setUserId then
        PlatformSDK.setUserId(user_id)
    end
end

--注册
function login:SignUp(name, pwd)
    if self.account_delegate.is_authorizing then
        graphic:DispatchEvent("show_prompt_panel", "platform_auth_in_progress")
        return
    end

    if not self:CheckString(name, pwd) then
        return
    end

    self.account_delegate:SignUp(name, pwd)
end

--登录
function login:SignIn(name, pwd)
    if self.account_delegate.is_authorizing then
        graphic:DispatchEvent("show_prompt_panel", "platform_auth_in_progress")
        return
    end

    if not self:CheckString(name, pwd) then
        return
    end

    self.account_delegate:SignIn(name, pwd)
end

function login:BindAccount()
    if self.account_delegate.is_guest_mode then
        network:Send({bind_account = { user = self.openid, password = self.access_token, guest_account = configuration:GetGuestAccount(), platform = self.platform}} )
    end
end

--角色登录
function login:UserLogin(server_id)
    local server_info = self:GetServerInfo(server_id)

    if not network:IsConnected() then
        local err = network:Connect(server_info.ip, server_info.port or 8888)
        if err then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

    elseif self.server_id ~= server_id then
        --重新连接
        network:Disconnect()
        local err = network:Connect(server_info.ip, server_info.port)
        if err then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

    end

    self.server_id = server_id

    local device_id = ""
    if PlatformSDK.getUUID then
        device_id = PlatformSDK.getUUID()
    end

    network:Send({login = { user = self.openid, 
                            password = self.access_token,
                            platform = self.platform,
                            server_id = server_id, 
                            device_id = device_id,
                            version = configuration:GetVersion(),
                            channel = self.channel_info.name,
                            locale = platform_manager:GetLocale(),
                            }}, true)

    return true
end

function login:GetUsernameAndPwd()
    return self.account_delegate.username, self.account_delegate.password
end

--游客登陆
function login:SignInAsGuest()
    self.account_delegate:SignInAsGuest()
end

function login:RegisterMsgHandler()
    network:RegisterEvent("login_ret", function(recv_msg)
        --角色登录成功
        if recv_msg.result == "success" then
            self:UserLoginSuccess(recv_msg.user_id, recv_msg.server_time, recv_msg.time_zone)
            graphic:DispatchEvent("user_finish_login", recv_msg.user_id, recv_msg.reconnect_token, false)
        elseif recv_msg.result == "create_leader" then
            self:UserLoginSuccess(recv_msg.user_id, recv_msg.server_time, recv_msg.time_zone)
            if TalkingDataGA then
                TalkingDataGA:onEvent("register")
            end
            analytics_manager:TriggerEvent("register", recv_msg.user_id)

            graphic:DispatchEvent("user_finish_login", recv_msg.user_id, recv_msg.reconnect_token, true)

        else
            graphic:DispatchEvent("show_login_result", recv_msg.result, recv_msg.forbidden_time)
        end
    end)
--FYD  平台id
    platform_manager:RegisterEvent("signin_result", function(status_code, arg2)
        if status_code == 1 then
            if scene_manager:GetCurrentSceneName() == "loading" then
                graphic:DispatchEvent("loading_scene_signout")
                return
            end

            if type(arg2.platform) == "string" then
                self.platform = arg2.platform
            else
                self.platform = platform_manager:GetAccountPlatformName(arg2.platform)
            end

            self.account_delegate.is_authorizing = false
            --FYD  OC代码中在sid中拼接了一个fbaccesstoken 这里添加解析 
             if self.channel_info.meta_channel == "txwy" then  
                local tempArg2 = arg2.access_token      --FYD 如果有 ’|‘,那么证明需要解析
                local index = string.find(tempArg2, '|')   --查询’|‘,如果有，那么就解析
                if index then
                    arg2.access_token = string.sub(tempArg2,1,index-1) -- 
                    self.fb_access_token = string.sub(tempArg2,index+1, string.len(tempArg2))
                end     
            end

            self.openid = arg2.openid
            self.access_token = arg2.access_token
            
            if self.platform == "gamecenter" then
                self.access_token = crypt.base64encode(crypt.sha1(arg2.openid .. COMMON_SALT))

            else
                local super_user_list = constants.SUPER_USER[self.platform]
                if super_user_list and super_user_list[self.openid] then
                    self.account_delegate.is_admin = true
                end
            end

            if self.channel_info.need_refresh_setting_bind then
                graphic:DispatchEvent("update_setting_bind_state")
            end

            self:FilterServerList(self.account_delegate.is_admin)
            graphic:DispatchEvent("show_auth_result", "platform_auth_success")
            
            if self.channel_info.enable_sns_bind_panel then 
                graphic:DispatchEvent("update_bind_sub_panel")
                graphic:DispatchEvent("remind_sns_reward")
            end

        elseif status_code == 0 then
            self.account_delegate.is_authorizing = true
            self.account_delegate.is_admin = false

            graphic:DispatchEvent("show_auth_result", "platform_auth_start")

        elseif status_code == 2 then
            self.account_delegate.is_authorizing = false
            graphic:DispatchEvent("show_auth_result", "platform_auth_failed")

        elseif status_code == 3 then
            self.account_delegate.is_authorizing = false
            graphic:DispatchEvent("show_auth_result", "platform_auth_cancel")

        elseif status_code == 4 then
            graphic:DispatchEvent("show_auth_result", "platform_auth_in_progress")

        elseif status_code == 5 then
            --绑定第三方失败
            if self.channel_info.meta_channel == "r2games" then
                -- local err = arg2.err
                -- if err == "1008" or err == "1009" or err == "1010" then
                --     graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("account_r2game_change_fb"),
                --     lang_constants:Get("account_r2game_change_fb_desc"),
                --     lang_constants:Get("common_confirm"),
                --     lang_constants:Get("common_cancel"),
                --     function()
                --         PlatformSDK.signInWithThirdPartyAccount(self.channel_info.third_party_account)
                --     end) 
                -- end
                --SDK流程已更改 这里就是单纯的绑定错误 飘字？
            end
        elseif status_code == 6 then
            --绑定第三方账号成功
            if self.channel_info.meta_channel == "r2games" then
                --飘字？
                graphic:DispatchEvent("show_auth_result", "platform_auth_fb_band_success");
            end

            if self.channel_info.need_refresh_setting_bind then
                graphic:DispatchEvent("update_setting_bind_state")
            end

            if self.channel_info.enable_sns_bind_panel then 
                graphic:DispatchEvent("update_bind_sub_panel")
                graphic:DispatchEvent("remind_sns_reward")
            end
        end
    end)

    platform_manager:RegisterEvent("signout_result", function(status_code)
        if type(status_code) ~= nil and status_code == 1 then
            return
        end

        if not self.is_user_login then
            --还未完成角色登陆
            graphic:DispatchEvent("show_login_panel")

            if self.channel_info.auto_signin_after_signout then
               PlatformSDK.showSignIn(platform_manager:GetAccountPlatformType(self.channel_info.signin[1]))
            end
        else
            graphic:DispatchEvent("user_logout", false)
        end
    end)
end

return login
