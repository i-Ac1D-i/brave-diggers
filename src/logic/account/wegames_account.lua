local account = require "logic.account.prototype"
local configuration = require "util.configuration"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local http_client = require "logic.http_client"
local json = require "util.json"
local md5 = require "md5"

local GAME_CODE = "AAAFAA"
local SERVER_CODE = "AS1000"

local API_SECRET = "e3d2706ae44f56507c2ee8c362c88fc6"

local PLATFORM_SERVER = "http://api.wegames.com.tw/api/"

local wegames_account = setmetatable({}, account)

function wegames_account:Init()
    account.Init(self)

    GAME_CODE = self.channel_info.GAME_CODE
end

local function GetHexDiegest(md5)
    local result = ""

    for i = 1, 4 do
        local offset = (i - 1) * 4
        result = result .. string.format("%08x", md5:byte(offset+1) * 16777216 + md5:byte(offset+2) * 65536 + md5:byte(offset+3) * 256 + md5:byte(offset+4))
    end

    return result
end

function wegames_account:GenerateSignature(data)
    return GetHexDiegest(md5.sum(data .. API_SECRET))
end

function wegames_account:SignIn(acc, pwd)
    if self.channel_info.signin[1] ~= "wegames" then
        print("配置错误，应将wegames配置在signin首位")
        return
    end

    self.is_authorizing = true
    self.username = acc
    self.password = pwd

    local url = PLATFORM_SERVER

    local post_data = string.format("wg_game_code=%s&wg_method=%s&wg_password=%s&wg_time=%s&wg_username=%s&wg_version=1",
                                    GAME_CODE, "user.login", GetHexDiegest(md5.sum(pwd)), tostring(os.time()), acc)

    local sig = self:GenerateSignature(post_data)
    post_data = post_data .. "&wg_sign=" .. sig

    http_client:Post(url, post_data, function(status_code, content)
        self.is_authorizing = false
        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)

        if ret_msg.status == 1 then
            self:AuthSuccess(ret_msg)
        else
            graphic:DispatchEvent("show_prompt_panel", "account_error_wegames", ret_msg.msg)
        end
    end)
end

function wegames_account:SignUp(acc, pwd)
    if self.channel_info.signin[1] ~= "wegames" then
        print("配置错误，应将wegames配置在signin首位")
        return
    end

    self.is_authorizing = true
    self.username = acc
    self.password = pwd

    local url = PLATFORM_SERVER
    local post_data = string.format("wg_game_code=%s&wg_method=%s&wg_password=%s&wg_time=%s&wg_username=%s&wg_version=1",
                                    GAME_CODE, "user.register",GetHexDiegest(md5.sum(pwd)), tostring(os.time()), acc)

    local sig = self:GenerateSignature(post_data)
    post_data = post_data .. "&wg_sign=" .. sig

    http_client:Post(url, post_data, function(status_code, content)
        self.is_authorizing = false

        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)

        if ret_msg.status == 1 then
            if TalkingDataGA then
                TalkingDataGA:onEvent("register_account")
            end
            self:AuthSuccess(ret_msg)

        else
            graphic:DispatchEvent("show_prompt_panel", "account_error_wegames", ret_msg.msg)
        end
    end)
end

function wegames_account:AuthSuccess(ret_msg)
    ret_msg.platform = "wegames"
    ret_msg.openid = ret_msg.data.platform_uid
    ret_msg.access_token = ""

    self.platform_uid = ret_msg.data.platform_uid

    configuration:SetAccountInfo(self.username, self.password)
    configuration:Save()

    --账号登录成功，显示服务器列表
    platform_manager:DispatchEvent("signin_result", 1, ret_msg)
end

function wegames_account:UpdateLeaderName(leader_name, user_id)
    local url = PLATFORM_SERVER
    local post_data = string.format("wg_game_code=%s&wg_game_uid=%s&wg_method=%s&wg_platform_uid=%s&wg_role_name=%s&wg_server_code=%s&wg_time=%s&wg_version=1",
                                    GAME_CODE, user_id, "user.setrole", self.platform_uid, leader_name, SERVER_CODE, tostring(os.time()))

    local sig = self:GenerateSignature(post_data)
    post_data = post_data .. "&wg_sign=" .. sig

    http_client:Post(url, post_data, function(status_code, content)

        if status_code ~= 200 then
            return
        end

        local ret_msg = json:decode(content)

        if ret_msg.status == 1 then
        else
            graphic:DispatchEvent("show_prompt_panel", "account_error_wegames", ret_msg.msg)
        end
    end)
end

function wegames_account:SignInAsGuest()
    self.is_guest_mode = true
    self.platform_uid = 0

    local openid = configuration:GetGuestAccount()
    local ret = { platform = "guest", openid = openid, access_token = "adventure" }

    configuration:SetGuestAccount(openid)

    platform_manager:DispatchEvent("signin_result", 1, ret)
end

function wegames_account:NotifyWegamesThird(platform, facebook_user_id, token_for_business)
    local url = PLATFORM_SERVER
    local post_data = string.format("wg_game_code=%s&wg_method=%s&wg_open_id=%s&wg_source=%s&wg_time=%s&wg_unique_id=%s",
                                    GAME_CODE, "user.third", facebook_user_id, platform, tostring(os.time()), token_for_business)


    local sig = self:GenerateSignature(post_data)
    post_data = post_data .. "&wg_sign=" .. sig
    http_client:Post(url, post_data, function(status_code, content)
        self.is_authorizing = false
        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)

        if ret_msg.status == 1 then
            self:AuthSuccess(ret_msg)

        else
            graphic:DispatchEvent("show_prompt_panel", "account_error_wegames", ret_msg.msg)
        end
    end)
end

function wegames_account:LoginThird(platform, app_id, access_token)
    local facebook_url = "https://graph.facebook.com/me?fields=token_for_business&access_token="..access_token

    http_client:Get(facebook_url, function (status_code, content)
        if status_code == 200 then
            local data = json:decode(content)
            if data.id and data.token_for_business then
                self:NotifyWegamesThird(platform, data.id, data.token_for_business)
                return
            end
        end

        self.is_authorizing = false
        graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
    end)
end

return wegames_account
