local account = require "logic.account.prototype"
local configuration = require "util.configuration"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local http_client = require "logic.http_client"
local json = require "util.json"

local COMMON_SALT = "AANDM"

local MIN_PASSWORD_LEN = 6

local mu77_account = setmetatable({}, account)

function mu77_account:Init()
    account.Init(self)

    self.account_server = self.channel_info.account_server or "http://account.mu77.com/"
end

function mu77_account:SignUp(name, pwd)
    if self.channel_info.signin[1] ~= "mu77" then
        return
    end

    self.username = name
    self.password = pwd

    self.is_authorizing = true

    local base64_digest = crypt.base64encode(crypt.sha1(self.password .. COMMON_SALT))
    local seed = crypt.base64encode(crypt.dhexchange(crypt.randomkey()))
    base64_digest = crypt.base64encode(crypt.sha1(base64_digest .. seed))

    local url = string.format("%s/v1/signup.json", self.account_server)

    local post_data = {account=name, passwd=base64_digest, seed=seed}
    http_client:Post(url, json:encode(post_data), function(status_code, content)
        self.is_authorizing = false
        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)
        self:AuthSuccess(ret_msg, true)
    end)
end

function mu77_account:SignIn(name, pwd)
    if self.channel_info.signin[1] ~= "mu77" then
        return
    end

    self.username = name
    self.password = pwd
    self.is_authorizing = true

    local url = string.format("%sv1/signinsalt.json", self.account_server)
    local post_data = {account=self.username}
    http_client:Post(url, json:encode(post_data), function(status_code, content)
        if status_code ~= 200 then
            self.is_authorizing = false
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)
        if not ret_msg.salt or ret_msg.errcode then
            self.is_authorizing = false
            self:AuthSuccess(ret_msg)
            return
        end

        if ret_msg.is_new then
            self:DoSignIn(ret_msg.salt)
        else
            self:ResetPassword(ret_msg.salt, ret_msg.access_token)
        end
    end)
end

function mu77_account:SignInAsGuest()
    self.is_guest_mode = true

    local openid = configuration:GetGuestAccount()
    local ret = { platform = "guest", openid = openid, access_token = "adventure" }

    configuration:SetGuestAccount(openid)

    platform_manager:DispatchEvent("signin_result", 1, ret)
end

function mu77_account:DoSignIn(salt)
    local base64_digest = crypt.base64encode(crypt.sha1(self.password .. COMMON_SALT))

    local url = string.format("%sv1/signin.json", self.account_server)
    local post_data = {account=self.username, passwd=base64_digest, salt=salt}
    http_client:Post(url, json:encode(post_data), function(status_code, content)
        self.is_authorizing = false

        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)
        self:AuthSuccess(ret_msg)
    end)
end

function mu77_account:ResetPassword(salt, access_token)
    local base64_digest = crypt.base64encode(crypt.sha1(self.password .. COMMON_SALT))
    local seed = crypt.base64encode(crypt.dhexchange(crypt.randomkey()))
    base64_digest = crypt.base64encode(crypt.sha1(base64_digest .. seed))

    local url = string.format("%sv1/resetpwd.json", self.account_server)
    local post_data = {account=self.username, passwd=base64_digest, seed=seed, salt=salt, token=access_token, originpwd=crypt.base64encode(self.password)}
    http_client:Post(url, json:encode(post_data), function(status_code, content)
        self.is_authorizing = false

        if status_code ~= 200 then
            graphic:DispatchEvent("show_prompt_panel", "account_connect_failure")
            return
        end

        local ret_msg = json:decode(content)
        self:AuthSuccess(ret_msg)
    end)
end

function mu77_account:AuthSuccess(ret_msg, is_register)
    if not ret_msg.errcode then
        ret_msg.platform = "mu77"

        self.is_admin = ret_msg.is_admin

        if not self.is_user_login then
            self.is_guest_mode = false
        end

        --mu77的账号才需要记录
        configuration:SetAccountInfo(self.username, self.password)
        configuration:Save()

        --账号登录成功，显示服务器列表
        platform_manager:DispatchEvent("signin_result", 1, ret_msg)
    else
        graphic:DispatchEvent("show_prompt_panel", "account_error_" .. ret_msg.errcode)
    end
end

return mu77_account
