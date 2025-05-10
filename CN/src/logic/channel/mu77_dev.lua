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
    --[[国服测试
    local channel_info = GenServerConfig({
        meta_channel = "mu77",
        region = "china",
        account_type = "mu77",
        switch_account = true, 
        signin = {"mu77" },
        pay = { "wechat"},
        product_flag = 1,
        is_debug = true,
    }, 1)
    --]]

    --[[txwy
    local channel_info = GenServerConfig({
        meta_channel = "txwy",
        region = "txwy",
        locale = {"zh-TW"},
        auth_code = "auth_code",
        signin = { "mu77" },
        pay = { "wechat"},
        account_type = "mu77",
        switch_account = true,
        is_debug = true,

        mercenary_contract_use_soul_bone = true,
        merchant_show_reward_box = true,
    }, 1)
    --]]

    ---[[txwy_dny
    local channel_info = GenServerConfig({
        meta_channel = "txwy_dny",
        region = "txwy_dny",
        locale = {"en-US","zh-CN","zh-TW","vi","th"},
        auth_code = "auth_code",
        signin = { "txwy_dny" },
        pay = { "wechat"},
        account_type = "mu77",
        switch_account = true,
        is_debug = true,
        change_language_dir = "dny",
        mercenary_contract_use_soul_bone = true,
        merchant_show_reward_box = true,
    }, 1)
    --]]

    --[[r2games
    local channel_info = GenServerConfig({
        meta_channel = "r2games",
        region = "r2games",
        locale = {"en-US","zh-CN","zh-TW","vi","th"},
        auth_code = "auth_code",
        signin = { "r2games" },
        pay = { "wechat"},
        account_type = "mu77",
        switch_account = true,
        is_debug = true,

        mercenary_contract_use_soul_bone = true,
        merchant_show_reward_box = true,
    }, 1)
    --]]

    return channel_info
end
