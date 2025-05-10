

local meta_info = {
    meta_channel = "shouyou",
    region = "shouyou",
    locale = "zh-CN",
    signin = { "shouyou" },
    
    develop_btn_visible = false,
    comp_text_visible = false,
    center_login_btn = true,
    product_flag = 1,
    
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}

    if channel_name == "shouyou_appstore" then
        channel_info = {
            auth_name = "auth_version", 
            pay = { "appstore", "shouyou" },
            currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",
            not_change_name = true,
            enable_payment_callback = true,
            force_update = true;
            force_update = "force_update_ios";
        }
    end

    return setmetatable(channel_info, meta_info)
end
