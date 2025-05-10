local meta_info = {
    meta_channel = "txwy_dny",
    region = "txwy_dny",
    locale = {"en-US","zh-CN","zh-TW","vi","th"},
    
    signin = { "txwy_dny" },
    pay = { "txwy_dny"},
    auth_name = "auth_version",
    
    enable_error_folder = true,
    enable_payment_callback = true,
    auto_signin_after_signout = false,
    has_user_center_ex = true,
    auto_signin = true,
    disable_signin_btn = true,
    has_customer_btn = true,
    login_has_change_user = true,
    login_has_user_center_ex = true,
    has_recharge_btn = true,
    cdkey_panel_has_like_btn = true,
    coop_skill_mercenary_list_name_font_height = 20, 
    coop_skill_mercenary_list_name_height = 70,
    enable_sns = true,
    enable_query_products = true,
    app_link_url = "http://wyx.com/s/wkus/",
    share_message = "台灣NO.1戰爭手遊!!挑戰成為送最多的手機遊戲!!快來幫我集氣!!",
    get_invite_list_url = "http://userdb.txwy.tw/s/wk?ip=%s&activeid=%s",
    mining_reset_panel_condition_text = 18,
    carnival_desc_font_height = 50,
    bbs_detail_panel_discuss_detail_text_font_size = 40,
    app_pre_link_url = "http://wyx.com/a/shorten?url=",
    fb_link_url = "http://goo.gl/bU2enL",
    sns_copy_str = "複製成功",
    is_create_leader_state = false,
    change_mail_box_pos_dy = 110,
    mercenary_preview_panel_desc_txt_height = 300,  --佣兵描述改成scrollview
    mercenary_preview_panel_desc_txt_font_height = 40,
    magic_recruit_msgbox_template_desc2_pos = true, --右对齐
    change_recruit_msgbox_template_desc_append_height = 80,
    change_recruit_msgbox_template_desc_append_height2 = 100,
    text_pannel_appending = 50,
    desc_pannel_appending = 25,
    reward_pannel_item_text_width_append = 100,
    mercenary_detail_panel_coop_and_artifact_text_pos_x = true,
    merchant_panel_hide_button_icon = true,
    down_load_version_move_x = 50,
    
    -----聊天设置-------
    is_open_chat = false,
    chat_font_size = 25,  
    font_color = '#ffffff',
    font_file = "ui/fonts/general.ttf",
    role_font_size = 30,
    union_font_size = 25,
    input_font_size = 35,
    tip_size = 30,

    talkingdata_store_sub_type = true,

    --TAG:MASTER_MERGE
    --佣兵契约使用魂骨
    mercenary_contract_use_soul_bone = true,
    merchant_show_reward_box = true,
    is_open_system = true,
    chars_width = {["en-US"] = 14,["zh-CN"] = 30,["zh-TW"] = 30,["vi"] = 17,["th"] = 18}, 
    event_panel_msg_bg_defult_height = 120,
    fixd_mining_boss_reward_height = 50,
    change_language_dir = "dny",
    achievement_sub_panel_icon_panel_hide = true,
    ore_bag_panel_name_font = 22,
    reward_special_desc_center = true,
    prompt_color = {r = 185, g = 165, b = 62, a = 255},
    get_device_locale = true,
    hide_rune_exchange_btn = true,  --隐藏符文交换按钮
    carnival_ladder_time_format = true,
    not_need_sort = true,  --公会boss奖励不用排序
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}

    if channel_name == "txwy_dny_appstore" then
        channel_info = {
            auth_code = "auth_code",
            fb_channel = "888002/",
        }
    elseif channel_name == "txwy_dny_android" then
        channel_info = {
            auth_code = "auth_code_google",
            fb_channel = "888001/",
        }
    end

    return setmetatable(channel_info, meta_info)
end
