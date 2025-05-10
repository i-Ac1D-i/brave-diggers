local event_listener = require "util.event_listener"
local lang_constants = require "util.language_constants"
local channel_list = require "logic.channel_list"
local configuration = require "util.configuration"
local analytics_manager
local feedback_manager
local language_logic = require "logic.language"

local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()

local ACCOUNT_PLATFORM =
{
    ["mu77"] = 0,
    ["wechat"] = 1,
    ["qq"] = 2,
    ["snda"] = 3,
    ["baidu"] = 4,
    ["mi"] = 5,
    ["uc"] = 6,
    ["buka"] = 7,
    ["yayawan"] = 8,
    ["guest"] = 9,
    ["skymoons"] = 10,
    ["yxhy"] = 11,
    ["qihoo"] = 12,
    ["meizu"] = 13,
    ["oppo"] = 14,
    ["lenovo"] = 15,
    ["vivo"] = 16,
    ["coolpad"] = 17,
    ["huawei"] = 18,
    ["m4399"] = 19,
    ["anzhi"] = 20,
    ["pptv"] = 21,
    ["pps"] = 22,
    ["youku"] = 23,
    ["sogou"] = 24,
    ["wogame"] = 25,
    ["sina"] = 26,
    ["downjoy"] = 27,
    ["wandoujia"] = 28,
    ["ewan"] = 29,
    ["mzw"] = 30,
    ["egame"] = 31,
    ["toutiao"] = 32,
    ["kugou"] = 33,
    ["gfan"] = 34,
    ["meitu"] = 35,
    ["mumayi"] = 36,
    ["appchina"] = 37,
    ["m5gwan"] = 38,
    ["guopan"] = 39,
    ["kaopu"] = 40,
    ["letv"] = 41,
    ["paojiao"] = 42,
    ["ct"] = 43,
    ["gionee"] = 44,
    ["zhuoyi"] = 45,
    ["yayawan1"] = 46,
    ["tencent"] = 47,
    ["changba"] = 48,
    ["iccgame"] = 49,

    ["mzyw"] = 50,
    ["caohua"] = 51,
    ["tongbu"] = 52,
    ["sguo"] = 53,
    ["jianyou"] = 54,
    ["stargame"] = 55,
    ["910app"] = 56,
    ["kuaiyong"] = 57,
    ["baiduml"] = 58,
    ["tencentml"] = 59,
    ["memberv"] = 60,
    ["pyw"] = 61,
    ["facebook"] = 71,

    ["r2games"] = 72,
    ["gamecenter"] = 73,
    ["txwy"] = 74,
    ["google"] = 75,
}

local ACCOUNT_PLATFORM_NAME = {}
for k, v in pairs(ACCOUNT_PLATFORM) do
    ACCOUNT_PLATFORM_NAME[v] = k
end

local PAY_PLATFORM =
{
    ["appstore"] = 0,
    ["wechat"] = 1,
    ["alipay"] = 2,
    ["baidu"] = 3,
    ["yayawan_new"] = 4,
    ["snda"] = 5,
    ["buka"] = 6,
    ["yayawan"] = 7,
    ["skymoons"] = 8,
    ["yayawan1"] = 9,
    ["google"] = 10,
    ["r2games"] = 11,
    ["txwy"] = 12,
}

local PAY_PLATFORM_NAME = {}
for k, v in pairs(PAY_PLATFORM) do
    PAY_PLATFORM_NAME[v] = k
end


local platform_manager = {}

function platform_manager:Init()
    if not _G["LOAD_CHANNEL_FILE"] then
        if TARGET_PLATFORM == cc.PLATFORM_OS_IPHONE or TARGET_PLATFORM == cc.PLATFORM_OS_IPAD or TARGET_PLATFORM == cc.PLATFORM_OS_ANDROID then
            local str = aandm.getDataFromFile("channel.txt")
            local str_iter = string.gmatch(str, "[^%s]+=([^%s]+)")

            local app_key = str_iter()
            local channel = str_iter()

            local adsensor_key = str_iter()
            local adsensor_channel = str_iter()

            local adtracking_key = str_iter()
            local adtracking_channel = str_iter()

            if PlatformSDK.getExtrasConfig then
                local extra_channel = PlatformSDK.getExtrasConfig("channel")
                if extra_channel and extra_channel ~= "" then
                    channel = extra_channel
                end
            end
            if app_key and channel then
                if TalkingDataGA then
                    PlatformSDK.setChannel(app_key, channel)
                else
                    Analytics.startWithAppkey(app_key, channel)
                end
            end

            if adsensor_key and adsensor_channel and Analytics.startAdSensor then
                Analytics.startAdSensor(adsensor_key, adsensor_channel)
            end

            if adtracking_key and adtracking_channel and Analytics.startAdTracking then
                Analytics.startAdTracking(adtracking_key, adtracking_channel)
            end

            _G["CHANNEL"] = channel
            _G["LOAD_CHANNEL_FILE"] = true
        end
    end

    self.channel_info = channel_list:Init(_G["CHANNEL"])

    --analytics_manager和feedback_manager初始化
    package.loaded["logic.analytics_manager"] = nil
    package.loaded["logic.feedback_manager"] = nil
    analytics_manager = require "logic.analytics_manager"
    feedback_manager = require "logic.feedback_manager"
    analytics_manager:Init(self.channel_info)
    feedback_manager:Init(self.channel_info)

    self.server_host_index = 1

    self.event_listener = event_listener.New()

    package.loaded["logic.account.prototype"] = nil

    local locale = self:GetLocale()

    if self.channel_info.account_type == "mu77" then
        package.loaded["logic.account.mu77_account"] = nil
        self.account = require "logic.account.mu77_account"

    else
        self.account = require "logic.account.prototype"
    end

    lang_constants:Init(locale)
    language_logic:Init(self.channel_info.locale, locale)

    self.channel_info.need_translate = self.channel_info.locale ~= "zh-CN" 

    if aandm.createNode and self.channel_info.need_translate then
        local origin_loader = cc.CSLoader.createNode

        cc.CSLoader.createNode = function(self, filename)
            return aandm.createNode(filename, lang_constants.CSD_STRINGS, lang_constants.FONT_SIZE_MAP)
        end
    end

    self.account:Init()

    PlatformSDK.registerLuaHandler(function(event_type, ...)
        self.event_listener:Dispatch(event_type, ...)
    end)
end

function platform_manager:GetChannelInfo()
    return self.channel_info
end

function platform_manager:GetLocale()

    if configuration:GetLocale() then
        return configuration:GetLocale()
    end

    local locale = "zh-CN"

    if type(self.channel_info.locale) == "string" then
        locale = self.channel_info.locale

    elseif type(self.channel_info.locale) == "table" then

        --获取持续化文件种的语言
        local config_locale = configuration:GetLocale()
        if config_locale == nil then

            --获取设备默认语言
            local device_locale = nil
            if self.channel_info.get_device_locale then
                device_locale = PlatformSDK.getLocale()
            end

            -- 匹配地区语言
            device_locale = lang_constants.LOCALE_TRANSFORM[device_locale]
            --  检查设备语言是否在支持语言列表中
            local find_device_locale = false

            if device_locale then
                for k, v in pairs(self.channel_info.locale) do
                    if device_locale == v then
                        find_device_locale = true
                        break
                    end
                end
            end

            if not find_device_locale then
                device_locale = nil
            end
            
            if device_locale == nil then
                --获取语言列表中第一个语言
                locale = self.channel_info.locale[1]
            else
                locale = device_locale
            end
        else
            locale = config_locale
        end
    end
    
    configuration:SetLocale(locale)
    configuration:Save()

    return locale
end

function platform_manager:GetAccountPlatformType(platform_name)
    return ACCOUNT_PLATFORM[platform_name]
end

function platform_manager:GetAccountPlatformName(platform)
    return ACCOUNT_PLATFORM_NAME[platform]
end

function platform_manager:GetPayPlatformType(platform_name)
    return PAY_PLATFORM[platform_name]
end

function platform_manager:GetPayPlatformName(platform)
    return PAY_PLATFORM_NAME[platform]
end

function platform_manager:HasAccountPlatform(platform_name)
    return PlatformSDK.hasAccountPlatform(ACCOUNT_PLATFORM[platform_name])
end

function platform_manager:HasPayPlatform(platform_name)
    return PlatformSDK.hasPayPlatform(PAY_PLATFORM[platform_name])
end

function platform_manager:SetUserInfo(info)
    if PlatformSDK.setUserInfo then
        PlatformSDK.setUserInfo(info)
    end
end

function platform_manager:GetClipboardText()
    if PlatformSDK.getClipboardText then
        return PlatformSDK.getClipboardText()
    else
        return
    end
end

function platform_manager:RegisterEvent(event_type, handler)
    self.event_listener:Register(event_type, handler)
end

function platform_manager:DispatchEvent(event_type, ...)
    self.event_listener:Dispatch(event_type, ...)
end

function platform_manager:ShowUserCenter()
    if not self.channel_info.has_user_center then
        return
    end

    if not PlatformSDK.isFunctionSupported then
        return
    end

    if not PlatformSDK.callFunction then
        return
    end

    if PlatformSDK.isFunctionSupported(102) then
        PlatformSDK.callFunction(102)
    end
end

--台湾版本需要有个按钮打开usercenter
function platform_manager:ShowUserCenterEx()
    local user_center_data = "";
    if self.channel_info.meta_channel == "txwy" then

        local user_logic = require "logic.user"
        local server_info = configuration:GetServerInfo()
        if server_info then
            user_center_data = server_info.id.."|"..user_logic:GetUserLeaderName().."|"..configuration:GetVersion()
        else
            user_center_data = "1|未登入|"..configuration:GetVersion()
        end
    end

    PlatformSDK.showUserCenterEx(user_center_data)
end

function platform_manager:GetServerListUrl()
    local url = ""

    local channel = self.channel_info

    if type(channel.server_list_host) == "table" then
        if self.server_host_index > #channel.server_list_host then
            self.server_host_index = 1
        end

        url = string.format(channel.server_list_url, channel.server_list_host[self.server_host_index])
        self.server_host_index = self.server_host_index + 1

    elseif type(channel.server_list_host) == "string" then
        url = string.format(channel.server_list_url, channel.server_list_host)
    end

    return url
end

function platform_manager:GetAccountDelegate()
    return self.account
end

function platform_manager:IsAdmin()
    return self.account.is_admin
end

function platform_manager:IsGuestMode()
    return self.account.is_guest_mode
end

function platform_manager:NeedTranslate()
    return self.channel_info.need_translate
end

function platform_manager:GetRegion()
    return self.channel_info.region
end

function platform_manager:IsUpdateToDate()

    if not PlatformSDK.getOriginVersion then
        return false
    end

    local origin_version = PlatformSDK.getOriginVersion()

    local major_ver, minor_ver, fix_ver = string.match(origin_version, "(%d+).(%d+).(%d+)")

    major_ver, minor_ver, fix_ver = tonumber(major_ver), tonumber(minor_ver), tonumber(fix_ver)

    if not major_ver or not minor_ver or not fix_ver then
        return false
    end

    if major_ver > 0 then
        return true
    end

    if minor_ver > 70 then
        return true
    end

    if minor_ver == 70 and fix_ver >= 1 then
        return true
    end

    return false
end

--台湾服需要网页第三方充值
function platform_manager:ThirdPartyRecharge()
    local channel = self.channel_info
    if channel.meta_channel == "txwy" then
        local server_info = configuration:GetServerInfo()
        PlatformSDK.thirdPartyRecharge(server_info.id.."|".."1")
    end
end

return platform_manager
