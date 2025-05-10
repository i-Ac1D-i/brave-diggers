local configuration = require "util.configuration"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"

local account = {}
account.__index = account

function account:Init()

    self.channel_info = platform_manager:GetChannelInfo()

end

function account:Clear()
    self.username, self.password = configuration:GetAccountAndPwd()
    self.is_admin = false
    self.is_guest_mode = false
    self.is_user_login = false
end

function account:CheckString(name, pwd)
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

function account:SignIn()

end

function account:SignUp()

end

function account:SignInAsGuest()

end

function account:UserLogin(is)
    self.is_user_login = is
end

function account:UpdateLeaderName()

end

function account:LoginThird()

end

return account
