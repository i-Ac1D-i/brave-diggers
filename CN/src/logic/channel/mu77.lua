local meta_info = {
    region = "china",
    locale = "zh-CN",
}
meta_info.__index = meta_info

local function GenServerConfig(channel, group_id)
    if group_id == 1 then
        channel.account_server = "http://test.mu77.com/"
    else
        channel.account_server = "http://account.mu77.com/"
    end

    channel.group_id = group_id

    return channel
end

return function(channel_name)
    local channel_info = {}

    if channel_name == "mu77_dev" then
        channel_info = GenServerConfig({
            meta_channel = "mu77",
            is_debug = _G["T_DEBUG_MODE"],
            account_type = "mu77",
            switch_account = true, 
            signin = {"mu77" },
            pay = {},
        }, 2)
    elseif channel_name == "mu77_internal_test" then
        channel_info = {
            internal_server = true,
            meta_channel = "mu77",
            account_type = "mu77",
            switch_account = true,
            signin = { "mu77", "wechat" },
            pay = {}, 
            account_server = "http://test.mu77.com/",
            group_id = 1,
            need_device_info = true,
            upload_device_info = 'https://dc.mu77.com/webservice/request.php', 
        }
    elseif channel_name == "mu77_test" then
        channel_info = {
            meta_channel = "mu77",
            account_type = "mu77",
            switch_account = true,
            signin = { "mu77", "wechat" },
            pay = {}, 
            account_server = "http://test.mu77.com/",
            group_id = 1,
            is_split_emoji = true,
        }
    elseif channel_name == "appstore" then
        channel_info = {
            meta_channel = "mu77",
            account_type = "mu77",
            switch_account = true,
            signin = { "mu77", "wechat", },
            pay = { "appstore" }, 
            auth_name = "auth_version",
            currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",
            group_id = 2,
            is_split_emoji = true,
            has_guest = true, 
        }
    elseif channel_name == "mu77_appstore" then
        channel_info = {
            meta_channel = "mu77",
            account_type = "mu77",
            switch_account = true,
            signin = { "mu77", "wechat", },
            pay = { "appstore" }, 
            auth_name = "auth_version",
            currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",
            group_id = 2,
            is_split_emoji = true,
            has_guest = true, 
            --分享url
            share_url = "http://192.168.199.160/mu77pass77/test.php",
        }
    elseif channel_name == "snda_android" then
        channel_info = {
            meta_channel = "snda",
            switch_account = true,
            has_signout = true,
            signin = { "snda" },
            pay = { "snda" },
            show_copyright = true,
            group_id = 3,
        }
    elseif channel_name == "buka_android" then
        channel_info = {
            meta_channel = "buka",
            switch_account = true,
            signin = { "buka" }, 
            pay = { "buka" },
            show_copyright = false,
            group_id = 3, 
        }
    elseif channel_name == "yayawan_android" then
        channel_info = {
            meta_channel = "yayawan",
            switch_account = false,
            has_logo = true,
            update_user_info = true,
            signin = { "yayawan" },
            pay = { "yayawan" },
            show_copyright = true,
            group_id = 3,
        }
    elseif channel_name == "yayawan1_android" then
        channel_info = {
            meta_channel = "yayawan",
            switch_account = false,
            has_logo = true,
            update_user_info = true,
            signin = { "yayawan1" },
            pay = { "yayawan1" },
            show_copyright = true,
            group_id = 3,
            --去掉官方维修群QQ描述文字
            clean_setting_feedback_desc = true,
        }
    end

    return setmetatable(channel_info, meta_info)
end
