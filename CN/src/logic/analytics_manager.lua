local json = require "util.json"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"
local analytics_manager = {}

local ADJUST_TOKEN =
{
    ["alogin"] = "qzbsuh",
    ["acreate_role"] = "epuxg5",
    ["apurchase_page_close"] = "v5ar73",
    ["apay_any"] = "wyh0m5",

    ["ilogin"] = "tdzmdd",
    ["icreate_role"] = "c494le",
    ["ipurchase_page_close"] = "drn0v7",
    ["ipay_any"] = "qrp608",

    ["a100001"] = "1g83xs",
    ["a100002"] = "mwg3vf",
    ["a100003"] = "cnkaaw",
    ["a100004"] = "hfrbp5",
    ["a100005"] = "on2ib6",
    ["a100006"] = "qzkvdn",
    ["a100007"] = "3bsva7",
    ["a100008"] = "90fkaa",
    ["a100009"] = "bfh4v9",
    ["a100010"] = "uv0t87",
    ["a100011"] = "6uj6nn",
    ["a100012"] = "c6w6j7",
    ["a100013"] = "6g0u9b",
    ["a100014"] = "p9yth4",
    ["a100015"] = "l2uwbw",
    ["a100016"] = "pxs6s8",
    ["a100019"] = "auz75d",
    ["a100021"] = "z8wz87",
    ["a100026"] = "cslbx8",
    ["a100031"] = "twb6ud",
    ["a100061"] = "pa6bq0",
    ["a100136"] = "kokw7o",
    ["a100211"] = "haulma",

    ["i100001"] = "n2o99k",
    ["i100002"] = "9nwkmh",
    ["i100003"] = "i0pmqp",
    ["i100004"] = "7kzlji",
    ["i100005"] = "ch0wb9",
    ["i100006"] = "h02ewp",
    ["i100007"] = "c2482p",
    ["i100008"] = "x2dbb3",
    ["i100009"] = "h3dzac",
    ["i100010"] = "qzq991",
    ["i100011"] = "j523yy",
    ["i100012"] = "brpjxt",
    ["i100013"] = "ez84d8",
    ["i100014"] = "84qy2q",
    ["i100015"] = "p50z8t",
    ["i100016"] = "bbx2ua",
    ["i100019"] = "s4n1vy",
    ["i100021"] = "8qytc4",
    ["i100026"] = "7zv8py",
    ["i100031"] = "a6sx0c",
    ["i100061"] = "fxdjiv",
    ["i100136"] = "5diwou",
    ["i100211"] = "vozt5y",

    ["i100"] = "cvxv6f",
    ["i1"] = "mfkj9a",
    ["i2"] = "ty9pqk",
    ["i3"] = "yanzvn",
    ["i4"] = "r14pah",
    ["i5"] = "bpyev6",
    ["i6"] = "i3v36h",
    ["i11"] = "hmmweq",
    ["i12"] = "xi1q6b",
    ["i13"] = "49d8w2",
    ["i14"] = "u50c2z",
    ["i15"] = "n0xkod",
    ["i16"] = "pm11il",
    ["i17"] = "rx8wcg",

    ["a100"] = "m0a2lb",
    ["a1"] = "fy1zbr",
    ["a2"] = "jgyubq",
    ["a3"] = "sgl15b",
    ["a4"] = "tngt4p",
    ["a5"] = "ienvce",
    ["a6"] = "cn5ksc",
    ["a11"] = "fqim32",
    ["a12"] = "wifbbg",
    ["a13"] = "ajww36",
    ["a14"] = "h20ni6",
    ["a15"] = "kvcjf0",
    ["a16"] = "pay3fq",
    ["a17"] = "cibofr",
}
--追踪类型
local ANALYTICS_INFO =
{
    APP_TOKEN_IOS = "h5ofpeh7pvk0",
    APP_TOKEN_ANDROID = "q7gw9q42rqps",

    MAT_ADVERTISER_ID = "163748",
    MAT_CONVERSION_KEY = "26e44e6ac461c2faeb2c9faeef7a2062",
    MAT_SENDER_ID = "916746765271",
    GA_PROPERTY_ID = "UA-56745847-15",
    GA_PROPERTY_ID_ANDROID = "UA-56745847-16",
    APPSFLYER_DEV_KEY = "kqpEe88qwDPjcr5zEYPMKU",
    APPSFLYER_APP_ID = "1094580863",

    -- 天下网游
    APPTW_APP_ID_IOS = "155813",
    APPTW_FUID_IOS = "ios_tw_mxywk",
    APPTW_APP_ID_ANDROID = "155814",
    APPTW_FUID_ANDROID = "android_tw_mxywk",
    APPTW_APP_KEY = "52dd8aec1f8107d316392dc73d26327f",

    -- 天下网游 东南亚
    APPTW_DNY_APP_ID_IOS = "156613",
    APPTW_DNY_FUID_IOS = "ios_mxywk",
    APPTW_DNY_APP_ID_ANDROID = "156614",
    APPTW_DNY_FUID_ANDROID = "android_mxywk",
    APPTW_DNY_APP_KEY = "52dd8aec1f8107d316392dc73d26327f",

    --新手引导结束关ID
    FINISH_TUTORIAL = 100320,
}

function analytics_manager:Init(channel_info, locale)
    locale = lang_constants["CONVERT_LANG"][locale]   --FYD

    self.channel_info = channel_info
    
    if self.channel_info.name == "r2games_android" then
        Analytics.startAnalytics(ANALYTICS_INFO.APP_TOKEN_ANDROID)

    elseif self.channel_info.name == "r2games_appstore" then
        Analytics.startAnalytics(ANALYTICS_INFO.APP_TOKEN_IOS)

    elseif self.channel_info.name == "qikujp_appstore" then
        Analytics.startAnalytics(ANALYTICS_INFO.MAT_ADVERTISER_ID.."|"..ANALYTICS_INFO.MAT_CONVERSION_KEY..
            "%"..ANALYTICS_INFO.GA_PROPERTY_ID..
            "%"..ANALYTICS_INFO.APPSFLYER_DEV_KEY.."|"..ANALYTICS_INFO.APPSFLYER_APP_ID,
            "")
    elseif self.channel_info.name == "qikujp_android" then
        Analytics.startAnalytics(ANALYTICS_INFO.MAT_ADVERTISER_ID.."|"..ANALYTICS_INFO.MAT_SENDER_ID.."|"..ANALYTICS_INFO.MAT_CONVERSION_KEY..
            "%"..ANALYTICS_INFO.GA_PROPERTY_ID_ANDROID..
            "%"..ANALYTICS_INFO.APPSFLYER_DEV_KEY,
            "")  
    elseif self.channel_info.name == "txwy_appstore" then
        Analytics.startAnalytics(ANALYTICS_INFO.APPTW_APP_ID_IOS..
            "|"..ANALYTICS_INFO.APPTW_APP_KEY..
            "|"..ANALYTICS_INFO.APPTW_FUID_IOS);
    elseif self.channel_info.name == "txwy_android" then
        Analytics.startAnalytics(ANALYTICS_INFO.APPTW_APP_ID_ANDROID..
            "|"..ANALYTICS_INFO.APPTW_APP_KEY..
            "|"..ANALYTICS_INFO.APPTW_FUID_ANDROID);
    elseif self.channel_info.name == "txwy_dny_appstore"  then
        Analytics.startAnalytics(ANALYTICS_INFO.APPTW_DNY_APP_ID_IOS..
            "|"..ANALYTICS_INFO.APPTW_DNY_APP_KEY..
            "|"..ANALYTICS_INFO.APPTW_DNY_FUID_IOS..","..locale); --传入sdk   FYD
    elseif self.channel_info.name == "txwy_dny_android" then
        Analytics.startAnalytics(ANALYTICS_INFO.APPTW_DNY_APP_ID_ANDROID..
            "|"..ANALYTICS_INFO.APPTW_DNY_APP_KEY..
            "|"..ANALYTICS_INFO.APPTW_DNY_FUID_ANDROID..","..locale);  --传入sdk   FYD
    end
end

--adtype广告追踪的类型 adinfo广告追踪的数据
function analytics_manager:TriggerEvent(event_type, data)
    
    if self.channel_info.meta_channel == "r2games" then
        local t = self.channel_info.name == "r2games_android" and "a" or "i"

        --广告追踪令牌
        local token
        local event_name = "adjustEvent"

        if event_type == "finish_fight" then
            token = ADJUST_TOKEN[t..data]

        elseif event_type == "pay" then
            Analytics.triggerEvent("adjustEvent", ADJUST_TOKEN[t.."pay_any"])
            --最后一个数据是app_purchase_name
            
            local product_name = data[#data]

            token = ADJUST_TOKEN[t..product_name]

            local price = 0

            for i = 1, #data, 2 do
                if data[i] == "price" then
                    price = data[i+1]
                    break
                end
            end

            token = token..":".. price

            event_name = "adjustEvent_pay"

        else
            token = ADJUST_TOKEN[t..event_type]
        end

        if token then
            Analytics.triggerEvent(event_name, token)
        end

    elseif self.channel_info.meta_channel == "qikujp" then
        if event_type == "finish_fight" then
            if data == ANALYTICS_INFO.FINISH_TUTORIAL then
                Analytics.triggerEvent("tutorialFinish", tostring(data))
            end
        elseif event_type == "login" then
            Analytics.triggerEvent(event_type, data)

        elseif event_type == "pay" then
            Analytics.triggerEvent(event_type, data)
        end
    elseif self.channel_info.meta_channel == "txwy" then
        if event_type == "login" then
            local server_info = configuration:GetServerInfo()
            Analytics.triggerEvent(event_type, tostring(server_info.id))
        end
    elseif self.channel_info.meta_channel == "txwy_dny" then
        if event_type == "login" then
            local server_info = configuration:GetServerInfo()
            Analytics.triggerEvent(event_type, tostring(server_info.id))
        end
    else
       Analytics.triggerEvent(event_type, data)
    end
end

function analytics_manager:GetAdjustToken(app_purchase_name)

    if self.channel_info.meta_channel == "r2games" then
        local t = self.channel_info.name == "r2games_android" and "a" or "i"
        return ADJUST_TOKEN[t .. app_purchase_name]
    end

end

return analytics_manager

