local TEST_SERVER = 0 

-- TEST_SERVER 1代表连接测试服  0代表连接正式服  2代表连接内网服
local SERVER_LIST_HOST = 
{
    ["china"] = 
    {
        "serverlist.mu77.com",
    },

    ["txwy"] = "list.mxwk.txwy.tw",
    ["r2games"] = {
        "52.71.107.205",
        "server_list.r2games.aam.mu77.com",
    },

    ["qikujp"] = {
        "52.196.39.124",
        "server_list.qiku.aam.mu77.com",
    },
    ["txwy_dny"] = "g.txwy.tw/games/mxywk", 
    ["shouyou"] = "mx-payment.leyonb.com/server_list", 
    ["shouyou2"] = "mx-payment.leyonb.com/server_list", 
-----------------test服务器列表-------------------------
    ["china_internal"] = "192.168.199.63",
    ["txwy_test"] = "list.mxwk.txwy.tw",
    ["txwy_dny_test"] = "g.txwy.tw/games/mxywk",
    ["r2games_test"] = "52.71.107.205",
    ["qikujp_test"] = "52.196.39.124",


------------------------内网服-----------------------------
    ["internal"] = "192.168.199.63",

}

local SERVER_LIST_URL =
{
    ["china"] =
    {
        [1] = "http://%s/server_list_test",     --测试服
        [2] = "http://%s/server_list_apple",    --苹果服
        [3] = "http://%s/server_list_mu77",     --安卓和越狱服
        [4] = "http://%s/server_list",          --英雄互娱的服务器
        [5] = "http://%s/server_list_tencent",  --腾讯的服务器
    },

    ["txwy"] = "http://%s/server_list",
    ["txwy_dny"] = "http://%s/server_list",
    ["r2games"] = "http://%s/server_list",

    ["qikujp"] = "http://%s/server_list",
    ["shouyou"] = "https://%s/server_list",
    ["shouyou2"] = "https://%s/server_list",
-----------------test服务器列表-------------------------
    ["china_internal"] = "http://%s/server_list_internal",
    ["txwy_test"] = "http://%s/server_list_staging",
    ["txwy_dny_test"] = "http://%s/server_list_staging",
    ["r2games_test"] = "http://%s/server_list_staging",
    ["qikujp_test"] = "http://%s/server_list_staging",

------------------------内网服务器列表-----------------------------
    ["internal"] = "http://%s/server_list",
}

local CHAT_SERVER_LIST_URL = 
{
    ["china"] = "http://%s/chat_server_list",   --聊天服务器列表
    ["internal"] = "http://%s/chat_server_list",   --聊天服务器列表
}

local channel_meta_map = {
    --develop
    ["mu77_dev"] = "mu77_dev",
    ["mu77_internal_test"] = "mu77",

    --mu77
    ["mu77_test"] = "mu77",
    ["appstore"] = "mu77",
    ["mu77_appstore"] = "mu77",
    ["snda_android"] = "mu77",
    ["buka_android"] = "mu77",
    ["yayawan_android"] = "mu77",
    ["yayawan1_android"] = "mu77",

    --r2games
    ["r2games_appstore"] = "r2games",
    ["r2games_android"] = "r2games",

    --qikujp
    ["qikujp_appstore"] = "qikujp",
    ["qikujp_android"] = "qikujp",

    --txwy
    ["txwy_appstore"] = "txwy",
    ["txwy_android"] = "txwy",

    --txwy_dny
    ["txwy_dny_appstore"] = "txwy_dny",
    ["txwy_dny_android"] = "txwy_dny",
    
    --skymoons
    ["skymoons_android"] = "skymoons",
    ["yxhy_android"] = "skymoons",
    ["qihoo_android"] = "skymoons",
    ["baidu_android"] = "skymoons",
    ["uc_android"] = "skymoons",
    ["mi_android"] = "skymoons",
    ["meizu_android"] = "skymoons",
    ["oppo_android"] = "skymoons",
    ["lenovo_android"] = "skymoons",
    ["vivo_android"] = "skymoons",
    ["coolpad_android"] = "skymoons",
    ["huawei_android"] = "skymoons",
    ["4399_android"] = "skymoons",
    ["anzhi_android"] = "skymoons",
    ["pptv_android"] = "skymoons",
    ["pps_android"] = "skymoons",
    ["youku_android"] = "skymoons",
    ["sogou_android"] = "skymoons",
    ["wogame_android"] = "skymoons",
    ["sina_android"] = "skymoons",
    ["ewan_android"] = "skymoons",
    ["downjoy_android"] = "skymoons",
    ["wandoujia_android"] = "skymoons",
    ["mzw_android"] = "skymoons",
    ["egame_android"] = "skymoons",
    ["toutiao_android"] = "skymoons",
    ["kugou_android"] = "skymoons",
    ["gfan_android"] = "skymoons",
    ["meitu_android"] = "skymoons",
    ["mumayi_android"] = "skymoons",
    ["appchina_android"] = "skymoons",
    ["5gwan_android"] = "skymoons",
    ["guopan_android"] = "skymoons",
    ["kaopu_android"] = "skymoons",
    ["letv_android"] = "skymoons",
    ["paojiao_android"] = "skymoons",
    ["ct_android"] = "skymoons",
    ["gionee_android"] = "skymoons",
    ["zhuoyi_android"] = "skymoons",
    ["tencent_android"] = "skymoons",
    ["changba_android"] = "skymoons",
    ["iccgame_android"] = "skymoons",
    ["mzyw_android"] = "skymoons",
    ["caohua_android"] = "skymoons",
    ["tongbu_android"] = "skymoons",
    ["sguo_android"] = "skymoons",
    ["jianyou_android"] = "skymoons",
    ["stargame_android"] = "skymoons",
    ["910app_android"] = "skymoons",
    ["kuaiyong_android"] = "skymoons",
    ["baiduml_android"] = "skymoons",
    ["tencentml_android"] = "skymoons",
    ["memberv_android"] = "skymoons",
    ["guangdian_android"] = "skymoons",
    ["miidi_android"] = "skymoons",
    ["pyw_android"] = "skymoons",
    ["yxgames_android"] = "skymoons",

    --free
    ["mu77_android"] = "free",
    ["mu772_android"] = "free",
    ["mu77_ios"] = "free",
    ["u77_android"] = "free",
    ["u77_ios"] = "free",
    ["pujia_android"] = "free",     --扑家汉化
    ["pujia_ios"] = "free",         --扑家汉化
    ["jianjia_android"] = "free",   --蒹葭汉化
    ["jianjia_ios"] = "free",       --蒹葭汉化
    ["3dm_android"] = "free",
    ["3dm_ios"] = "free",
    ["kdslife_android"] = "free",   --宽带山
    ["kdslife_ios"] = "free",       --宽带山
    ["17173_android"] = "free",
    ["17173_ios"] = "free",
    ["bluepanda_android"] = "free", --布鲁潘达
    ["hsjsns_android"] = "free",    --好世界
    ["lightnovel_android"] = "free",--轻之国度
    ["tianshi2_android"] = "free",  --天使二次元
    ["wanga_android"] = "free",     --拼命玩
    ["mhhf_android"] = "free",      --灵动游戏
    ["de518_android"] = "free",     --星游
    ["gamexz_android"] = "free",    --易游
    ["mofang_android"] = "free",    --魔方
    ["youtak_1_android"] = "free",  --有得
    ["youtak_2_android"] = "free",  --有得
    ["youtak_3_android"] = "free",  --有得
    ["baoruan_android"] = "free",
    ["wifi8_android"] = "free",     --花生游戏
    ["3dmzb_android"] = "free",

    ["shouyou_appstore"] = "shouyou",   --首游
    ["shouyou2_appstore"] = "shouyou2",   --首游
}

local channel_list = {}

function channel_list:Init(channel_name)

    channel_name = channel_name or "mu77_dev"
    
    local creater = require(string.format("logic.channel.%s", channel_meta_map[channel_name]))
    local channel_info = creater(channel_name)
    channel_info.name = channel_name

    if channel_info.is_debug then
        require "logic.debug_switch"
    end
    
    if channel_info.internal_server then
        channel_info.server_list_url = SERVER_LIST_URL[channel_info.region .. "_internal"]
        channel_info.server_list_host = SERVER_LIST_HOST[channel_info.region .. "_internal"]
    elseif channel_info.test_server then
        channel_info.server_list_url = SERVER_LIST_URL[channel_info.region .. "_test"]
        channel_info.server_list_host = SERVER_LIST_HOST[channel_info.region .. "_test"]
    else
        channel_info.server_list_url = SERVER_LIST_URL[channel_info.region]
        channel_info.server_list_host = SERVER_LIST_HOST[channel_info.region]
        --聊天url
        channel_info.chat_server_url = CHAT_SERVER_LIST_URL[channel_info.region]
        channel_info.chat_server_host = SERVER_LIST_HOST[channel_info.region]
    end

    if channel_info.group_id and type(channel_info.server_list_url) == "table" then
        channel_info.server_list_url = channel_info.server_list_url[channel_info.group_id]
    end
    
    --url加随机数,破解isp缓存问题
    channel_info.server_list_url = channel_info.server_list_url.."?random="..os.time()

    if not channel_info.currency_type then
        channel_info.currency_type = "CNY"
    end

    channel_info.enable_pay = #channel_info.pay ~= 0
    channel_info.enable_appstore_pay = false
    channel_info.enable_google_pay = false

    for k, v in pairs(channel_info.pay) do
        if v == "appstore" then
            channel_info.enable_appstore_pay = true
            if not channel_info.not_change_name then
                channel_info.name = "appstore"
            end

        elseif v == "google" then
            channel_info.enable_google_pay = true
        end
    end

    return channel_info
end

return channel_list
