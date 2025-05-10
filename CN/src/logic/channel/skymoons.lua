local meta_info = {
    meta_channel = "skymoons",
    region = "china",
    locale ='zh-CN',

    pay = { "skymoons" }, 

    switch_account = true, 
    has_signout = true, 
    has_exit = true, 
    update_user_info = true, 
    delay_check_order_time = 1.0, 
    show_copyright = true,

    group_id = 4,
    
    need_device_info = true,
    upload_device_info = 'https://dc.mu77.com/webservice/request.php', 
    --去掉官方维修群QQ描述文字
    clean_setting_feedback_desc = true, 
    is_split_emoji = true,
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}

    if channel_name == "skymoons_android" then
        channel_info = {
            has_user_center = true,
        }
    elseif channel_name == "4399_android" then
        channel_info = {
            signin = { "m4399" },
        }
    elseif channel_name == "ewan_android" then
        channel_info = {
            delay_check_order_time = 1.0,
        }
    elseif channel_name == "meitu_android" then
        channel_info = {
            has_user_center = true,
        }
    elseif channel_name == "5gwan_android" then
        channel_info = {
            signin = { "m5gwan" },
        }
    elseif channel_name == "paojiao_android" then
        channel_info = {
            has_user_center = true,
        }
    elseif channel_name == "zhuoyi_android" then
        channel_info = {
            has_signout = false,
        }
    elseif channel_name == "tencent_android" then
        channel_info = {
            group_id = 5,
        }
    elseif channel_name == "tencentml_android" then
        channel_info = {
            signin = { "tencentml" },
            group_id = 5,
        }
    elseif channel_name == "guangdian_android" then
        channel_info = {
            signin = { "tencentml" },
            group_id = 5,
        }
    elseif channel_name == "miidi_android" then
        channel_info = {
            signin = { "tencentml" },
            group_id = 5,
        }
    end

    if channel_info.signin == nil then
        channel_info.signin = {}
        table.insert(channel_info.signin, string.match(channel_name, "(%w+)_"))
    end

    return setmetatable(channel_info, meta_info)
end
