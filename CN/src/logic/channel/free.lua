local meta_info = {
    meta_channel = "mu77",
    account_type = "mu77",
    region = "china",
    locale = "zh-CN",

    signin = { "mu77", "wechat" },
    pay = { "wechat", "alipay" },

    switch_account = true, 
    show_copyright = true,

    group_id = 3, 
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}
    if channel_name == "mu77_android" then
        channel_info = {
            --分享url
            is_split_emoji = true,
            share_url = "http://192.168.199.160/mu77pass77/test.php",
        }
    end

    channel_info.meta_channel = string.match(channel_name, "(%w+)_")
     

    return setmetatable(channel_info, meta_info)
end
