local json = require "util.json"

local configuration = {}
function configuration:Init()
    self.json_obj = {
        effect_mute = false,
        music_mute = false,
        remind_list = {
            ["closed_remind_forge_switch"] = false,
        },
        account = "",
        password = "",
        server_id = 0,
        version = "",

        notice_publish_time = {},
        flush_bbs_time = {},
        logined_server_list = {},
        guild_info_list = {},

        view_transmigration_time = 0,
        guest_account = "",
        accept_agreement = false,
        ignore_guild_war_notify_time = 0,
    }

    self.cur_server_name = ""
    self.has_viewed_transmigration = true
    self.carnival_transmigration_end_time = 0
    self.has_viewed_transmigration_free = false

    self.path = self:GetConfigPath()

    local fp = io.open(self.path, "r")
    if not fp then
        fp = io.open(self.path, "w")
        fp:close()
        return
    end

    local content = fp:read("*a")
    fp:close()

    if string.len(content) ~= 0 then
        self.json_obj = json:decode(content)

        local json_obj = self.json_obj
        json_obj["version"] = json_obj["version"] or ""
        json_obj["music_mute"] = json_obj["music_mute"] or false
        json_obj["effect_mute"] = json_obj["effect_mute"] or false
        json_obj["server_id"] = json_obj["server_id"] or 0
        json_obj["accept_agreement"] = json_obj["accept_agreement"] or false
        json_obj["ignore_guild_war_notify_time"] = json_obj["ignore_guild_war_notify_time"] or 0

        --r2games1.0.5强制调整服务器ID
        if not json_obj["server_id_fixed"] then
            json_obj["server_id"] = 0
            json_obj["server_id_fixed"] = true
        end

        if type(json_obj["notice_publish_time"]) ~= "table" then
            json_obj["notice_publish_time"] = {}

        else
            local is_reset = false
            for k, v in pairs(json_obj["notice_publish_time"]) do
                if type(k) == "number" then
                    is_reset = true
                    break
                end
            end

            if is_reset then
                json_obj["notice_publish_time"] = {}
            end
        end

        if type(json_obj["flush_bbs_time"]) ~= "table" then
            json_obj["flush_bbs_time"] = {}

        else
            local is_reset = false
            for k, v in pairs(json_obj["flush_bbs_time"]) do
                if type(k) == "number" then
                    is_reset = true
                    break
                end
            end

            if is_reset then
                json_obj["flush_bbs_time"] = {}
            end
        end

        --曾经登录过的服务器, 最大5个
        if type(json_obj["logined_server_list"]) ~= "table" then
            json_obj["logined_server_list"] = {}
        end

        --提醒开关
        if type(json_obj["remind_list"]) ~= "table" then
            json_obj["remind_list"] = {}
            -- 重置提醒开关
            self:ResetRemindList()
        end

        --公会信息
        if type(json_obj["guild_info_list"]) ~= "table" then
            json_obj["guild_info_list"] = {}
        end

        json_obj["guest_account"] = json_obj["guest_account"] or ""
        json_obj["view_transmigration_time"] = json_obj["view_transmigration_time"] or 0
    end
end

function configuration:SetAccountInfo(account, pwd)
    self.json_obj["account"] = account
    self.json_obj["password"] = pwd
end

function configuration:SetServerId(server_id)
    self.json_obj["server_id"] = server_id
end

function configuration:SetServerInfo(server_info)
    self.server_info = server_info

    self.json_obj["server_id"] = server_info.id
    self.json_obj["new_id"] = server_info.new_id
    
    self.cur_server_name = server_info.name

    local server_id = server_info.id

    local server_list = self.json_obj["logined_server_list"]
    for i = 1, #server_list do
        if server_list[i] == server_id then
            return
        end
    end

    if #server_list == 5 then
        server_list[5] = server_id
        return
    end

    table.insert(server_list, server_id)
end

function configuration:GetServerInfo()
    return self.server_info
end

function configuration:SetEffectMute(effect_mute)
    self.json_obj["effect_mute"] = effect_mute
end

function configuration:SetMusicMute(music_mute)
    self.json_obj["music_mute"] = music_mute
end

function configuration:GetAccountAndPwd()
    return self.json_obj["account"], self.json_obj["password"]
end

function configuration:GetServerId()
    return self.json_obj["server_id"]
end

function configuration:GetMergeId()
    local new_id = self.json_obj["new_id"]
    if not new_id then
        new_id = self.json_obj["server_id"]
    end
    return new_id
end

function configuration:GetEffectMute()
    return self.json_obj["effect_mute"]
end

function configuration:GetMusicMute()
    return self.json_obj["music_mute"]
end

function configuration:SetVersion(v)
    self.json_obj["version"] = v
end

function configuration:GetVersion()
    return self.json_obj["version"]
end

-- 公告发布时间
function configuration:SetNoticePublishTime(time)
    local server_id = tostring(self.json_obj["server_id"])

    self.json_obj["notice_publish_time"][server_id] = time
end

function configuration:GetNoticePublishTime()
    local server_id = tostring(self.json_obj["server_id"])

    return self.json_obj["notice_publish_time"][server_id] or 0
end

function configuration:GetLoginedServerList()
    return self.json_obj["logined_server_list"]
end

-- 刷新bbs时间
function configuration:SetFlushBBSTime(time)
    local server_id = tostring(self.json_obj["server_id"])

    self.json_obj["flush_bbs_time"][server_id] = time
end

function configuration:GetFlushBBSTime()
    local server_id = tostring(self.json_obj["server_id"])

    return self.json_obj["flush_bbs_time"][server_id] or 0
end

-- 获取强化提醒开关
function configuration:GetRemindClosedSwitch(switch_name)
    local closed_switch = false
    if type(self.json_obj["remind_list"][switch_name]) == 'boolean' then
       closed_switch = self.json_obj["remind_list"][switch_name]
    end
    
    return closed_switch
end
-- 设置提醒开关
function configuration:SetRemindClosedSwitch(switch_name, switch_flag)
    if type(switch_flag) == 'boolean' then
       self.json_obj["remind_list"][switch_name] = switch_flag
    end
end
-- 重置提醒开关
function configuration:ResetRemindList()
    self.json_obj["remind_list"]["closed_remind_forge_switch"] = false
end

function configuration:GetGuildInfoList()
    return self.json_obj["guild_info_list"]
end

function configuration:Save()
    --r2games1.0.5强制调整服务器ID
    if not self.json_obj["server_id_fixed"] then
        self.json_obj["server_id"] = 0
        self.json_obj["server_id_fixed"] = true
    end

    --清空文件，然后重新写入
    local str = json:encode(self.json_obj)
    if str then
        local fp = io.open(self.path, "w+")

        if fp then
            fp:write(str)
            fp:close()
        end
    end
end

function configuration:GetGuestAccount()

    if self.json_obj["guest_account"] ~= "" then
        return self.json_obj["guest_account"]
    end

    if PlatformSDK.getUUID then
        self.json_obj["guest_account"] = PlatformSDK.getUUID()
    end

    return self.json_obj["guest_account"]
end

function configuration:SetGuestAccount(acc)
    self.json_obj["guest_account"] = acc
end

function configuration:HasViewedTransmigration()
    return self.has_viewed_transmigration
end

function configuration:SetViewedTransmigration(is_viewed)
    self.has_viewed_transmigration = is_viewed
end

function configuration:GetViewedFreeTransmigration()
    return self.has_viewed_transmigration_free 
end

function configuration:SetViewedFreeTransmigration(flag)
    self.has_viewed_transmigration_free = flag
end

function configuration:SetViewTransmigrationTime(time)
    self.json_obj["view_transmigration_time"] = time
    self.has_viewed_transmigration = true
end

function configuration:SetCarnivalTransmigrationEndTime(time)
    self.carnival_transmigration_end_time = time
end

function configuration:GetCarnivalTransmigrationEndTime()
    return self.carnival_transmigration_end_time 
end

function configuration:GetViewTransmigrationTime()
    return self.json_obj["view_transmigration_time"]
end

function configuration:GetConfigPath()

    local platform = cc.Application:getInstance():getTargetPlatform()

    local path = ""

    if platform == cc.PLATFORM_OS_WINDOWS then
        path = "src/conf"

    elseif platform == cc.PLATFORM_OS_LINUX then
        path = "./conf"

    else
        path = cc.FileUtils:getInstance():getWritablePath()
        path = path  .. "conf"
    end

    return path
end

function configuration:SetServerName(name)
    self.cur_server_name = name
end

function configuration:GetServerName()
    return self.cur_server_name
end

function configuration:GetLocale()
    return self.json_obj["locale"]
end

function configuration:SetLocale(locale)
    self.json_obj["locale"] = locale
end

function configuration:SetAcceptAgreement(accept)
    self.json_obj["accept_agreement"] = accept
end

function configuration:GetAcceptAgreement()
    return self.json_obj["accept_agreement"]
end

function configuration:SetVal(key, val)
    self.json_obj[key] = val
end

function configuration:GetVal(key)
    return self.json_obj[key]
end

function configuration:SetAutoFire(autofire) --自动解雇
    self.json_obj["auto_fire"] = autofire
end

function configuration:GetAutoFire()
    return self.json_obj["auto_fire"]
end

return configuration
