local meta_info = {
    FYD_MODE = true,--将逻辑迁出来整理(执行统一的逻辑)

    meta_channel = "qikujp",
    account_type = "mu77",
    region = "qikujp",
    locale = {"jp"}, 

    is_debug = false,
    has_guest = true, 
    show_agreement = true,

    account_server = "https://qiku.account.mu77.com/",
    notice_url = "http://qikucommon.s3.amazonaws.com/dig/ios/ios.html",

    enable_error_folder = true,
    coop_skill_mercenary_list_name_font_height = 20,
    coop_skill_mercenary_list_name_height = 70,
    gloabal_floating_res_detail_min_height = 160,
    leader_weapon_skill_desc_height = 80,
    transmigration_explain_desc2_change_height = -10,
    transmigration_scale_msgbox_time_change_x = -10,
    cord_origin_pos = {x = -1,y = -1},
    ad_bp_width_move = 110,
    coop_and_artifact_text_font_height = 20,
    skill_desc_text_font = 20,
    agreement_scrollview_append_content = 600,
    ad_bp_width_move2 = 70,
    carnival_desc_font_height = 50,
    is_store_desc_change_and_center = true,
    store_desc_mv_dx = 20,
    carnival_limit_buy_panel_desc1_font = 14,
    append_height_arena_rule_msgbox = 20,
    append_height_ladder_rule_desc = 20,
    is_text_change_front_to_back = true,
    mining_buy_cave_challenge_desc_append_height = 20,
    event_panel_msg_bg_defult_height = 100,   
    not_change_name = true,
    focus_one_font_height = 20,
    extern_height = 100,
    append_height_arena_rule_msgbox_desc4_fix = 7,
    append_height_arena_rule_msgbox_desc5_fix = {x = 12, y=18},
    down_load_version_move_x = 50,  
    magic_recruit_msgbox_template_desc2_pos = true, --右对齐
    change_recruit_msgbox_template_desc_append_height = 80,
    change_recruit_msgbox_template_desc_append_height2 = 100,
    text_pannel_appending = 50,
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}

    if channel_name == "qikujp_appstore" then
        channel_info = {
            signin = { "mu77", "gamecenter", "facebook"},
            pay = { "appstore" },
            auth_name = "auth_version",
            auth_code = "auth_code",
            auto_signin = true,
            enable_appstore_pay = true,      --开启app内购
            currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",   --白名单
            not_change_name = true,

            appraise_url = "itms-apps://itunes.apple.com/app/id1094580863", 
            other_url = {"http://battleship.coolfactory.jp/rm/contactUs?gameUid="}, 
        }

    elseif channel_name == "qikujp_android" then
        channel_info = {
            signin = { "mu77", "facebook"},
            pay = { "google" },
            auth_name = "auth_version_google",
            auth_code = "auth_code_google",
            auto_signin = false,
            has_signout = true,
            is_hide_google_btn = true,

            appraise_url = "https://itunes.apple.com/cn/app/ying-xiong-yu-wang-guan/id1061850866?mt=8",
            other_url = {"http://battleship.qikuyx.com/rm/contactUs?gameUid="},
        }
    end

    return setmetatable(channel_info, meta_info)
end
