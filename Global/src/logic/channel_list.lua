local TEST_SERVER = 0

-- TEST_SERVER 1代表连接测试服  0代表连接正式服  2代表连接内网服
local SERVER_LIST_HOST = 
{
    ["china"] = 
    {
        "120.132.84.198",
        "123.59.14.201",
        "115.29.225.89"
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

-----------------test服务器列表-------------------------
    ["txwy_test"] = "list.mxwk.txwy.tw",
    ["r2games_test"] = "52.71.107.205",
    ["qikujp_test"] = "52.196.39.124",


------------------------内网服-----------------------------
    ["internal"] = "192.168.199.46",

}

local SERVER_LIST_URL =
{
    ["china"] =
    {
        [1] = "http://%s/server_list_test",
        [2] = "http://%s/server_list_apple",
        [3] = "http://%s/server_list_mu77",
        [4] = "http://%s/server_list",
        [5] = "http://%s/server_list_tencent",
    },

    ["txwy"] = "http://%s/server_list",
    ["r2games"] = "http://%s/server_list",

    ["qikujp"] = "http://%s/server_list",
-----------------test服务器列表-------------------------
    ["txwy_test"] = "http://%s/server_list_staging",
    ["r2games_test"] = "http://%s/server_list_staging",
    ["qikujp_test"] = "http://%s/server_list_staging",

------------------------内网服务器列表-----------------------------
    ["internal"] = "http://%s/server_list",

}

local SKYMOONS_CHANNEL =
{
    meta_channel = "skymoons", switch_account = true, has_signout = true, has_exit = true, update_user_info = true, delay_check_order_time = 1.0, locale ='zh-CN',
    signin = { "skymoons" }, pay = { "skymoons" },
    group_id = 4, region = "china",
}
SKYMOONS_CHANNEL.__index = SKYMOONS_CHANNEL

local function GenServerConfig(channel, group_id)
    if group_id == 1 then
        channel.account_server = "http://test.mu77.com/"
    else
        channel.account_server = "http://account.mu77.com/"
    end

    channel.group_id = group_id

    return channel
end

local CHANNEL_INFO =
{
    --group_id == 1 只能连接测试服
    --group_id == 2 只能连接苹果服
    --group_id == 3 只能连接安卓和越狱服
    --group_id == 4 只能连接英雄互娱的服务器
    --group_id == 5 只能连接腾讯的服务器
    mu77_dev = GenServerConfig({
        meta_channel = "r2games",
        switch_account = true, locale = { "en-US", "zh-CN" }, is_debug = true, has_sns_share = true,
        signin = {"mu77" }, pay = {"wechat"}, account_type = "mu77", center_login_btn = true,
        region = "r2games",
    }, 1),
 

    mu77_test =
    {
        meta_channel = "mu77", switch_account = true, locale = "zh-CN",
        signin = { "mu77", "wechat" }, pay = {}, account_type = "mu77",
        group_id = 1, region = "china",
        account_server = "http://test.mu77.com/",
    },

    appstore =
    {
        meta_channel = "mu77", switch_account = true, locale = "zh-CN", has_guest = true, auth_name = "auth_version",
        signin = { "mu77", "wechat", }, pay = { "appstore" }, account_type = "mu77", currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",
        group_id = 2, region = "china",
    },

    mu77_appstore =
    {
        meta_channel = "mu77", switch_account = true, locale = "zh-CN", has_guest = true, auth_name = "auth_version",
        signin = { "mu77", "wechat", }, pay = { "appstore" }, account_type = "mu77", currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",
        group_id = 2, region = "china",
    },

    snda_android =
    {
        meta_channel = "snda", switch_account = true, has_signout = true, locale = "zh-CN",
        signin = { "snda" }, pay = { "snda" },
        group_id = 3, region = "china",
    },

    buka_android =
    {
        meta_channel = "buka", switch_account = true,
        signin = { "buka" }, pay = { "buka" },
        group_id = 3, region = "china",
    },

    yayawan_android =
    {
        meta_channel = "yayawan", switch_account = false, has_logo = true, update_user_info = true,
        signin = { "yayawan" }, pay = { "yayawan" },
        group_id = 3, region = "china",
    },

    yayawan1_android =
    {
        meta_channel = "yayawan", switch_account = false, has_logo = true, update_user_info = true,
        signin = { "yayawan1" }, pay = { "yayawan1" },
        group_id = 3, region = "china",
    },

    r2games_android =
    {
        meta_channel = "r2games", locale = {"en-US", "de", "fr", "ru", "es-MX"}, switch_account = false, enable_error_folder = true, enable_sns = true,
        signin = { "r2games"}, pay = { "r2games" }, third_party_account = "2", currency_type = "USD", enable_payment_callback = true,
        auth_name = "auth_version_google", auth_code = "auth_code_google", center_login_btn = true, has_customer_btn = true, 
        region = "r2games", enable_query_products = true, disable_bbs_limit = true, enable_sns_bind_panel = true, enable_sns_share_panel = true,
        carnival_desc_font_height = 30, has_sns_share = true, need_refresh_setting_bind = true, cord_origin_pos = {x = -1,y = -1},
        coop_skill_mercenary_list_name_font_height = 20, mercenary_lineup_detail_panel_height = 80,coop_skill_mercenary_list_name_height = 70,
        app_link_url = "https://www.facebook.com/bravediggers/",  enable_sns_og_share = true,
        fb_like_url = "https://www.facebook.com/Brave-Diggers-470385973160601", game_request_title = "Join us now!", sns_platform = "facebook",
        game_request_message = "Come with me! Do some diggin', recruit badass heroes, and fight you some bad guys.",
        fb_like_url = "https://www.facebook.com/bravediggers",
        force_update = "force_update_android", facebook_share_not_get_reward = true, get_device_locale = true, login_has_feedback = true, login_has_change_loacle = true,
        use_locale_notic = true, show_achievement_btn = true,
        mercenary_detail_panel_change_comment_size = true, exchange_reward_msgbox_change_desc_size = true, 
        ladder_top_ten_msgbox_change_desc_size = true, ore_bag_panel_change_pickaxe_name_pos_x = true,
        ore_bag_panel_change_desc_size = true, novice_change_text_size = true, transmigration_panel_change_artifact_value1_x = true,
        ore_sub_panel_change_name_pos_x = true, mining_district_panel_change_refresh_btn_size = true,
        achievement_panel_change_process_text_pos_x = true, carnival_panel_change_title_text_size = true,
        panel_util_change_language_dot_format = true, mercenary_levelup_panel_change_desc1_font_size = true,
        quest_panel_change_new_mail_tip_size = true, daily_panel_enable_switch_tab_animation = false,
        bbs_main_panel_change_discuss_btn_text_pos_x = true,
        down_load_version_move_x = 50,
        exploring_panel_exp_icon_move_x=20,  --x坐标偏移
        mercenary_detail_panel_coop_and_artifact_text_pos_x=true, --x坐标偏移
        ad_bp_width_move3 = 35, --x坐标偏移
        weapon_panel_success_chance_text_add_air=true, --是否有空格
        mercenary_confirm_fire_panel_title_pos_y=20, --x坐标偏移
        mercenary_levelup_panel_force_btn_text_anchor=true, --卯点居中
        force_panel_ex_prop_val_text_add_air=true, --是否有空格
        quarry_panel_project_sub_panel_soul_chip_cost_text_pos_y=4, --y坐标偏移
        append_height_arena_rule_msgbox_desc4_fix = 7,
        append_height_arena_rule_msgbox_desc5_fix = {x = 12,y=18},
        confirm_msgbox_refresh_node_all_left=true,--左对齐
        achievement_sub_panel_icon_panel_hide=true, --隐藏
        weapon_sub_panel_msgbox_pos_y = 10, --y轴坐标偏移
        quarry_panel_project_sub_panels_need_clone=true, --需要克隆
        mercenary_info_sub_panel_all_right=true, --右对齐
        magic_recruit_msgbox_template_desc2_pos=true, --右对齐
        setting_panel_feedback_desc_text_pos_y=10, --y轴坐标偏移
        vip_panel_good_1_desc_all_left=true, --左对齐
        detail_info_sub_panel_use_btn_offset_x=10, --x轴坐标偏移
        quarry_panel_project_sub_panel_waiting_text_pos_y=-20, --x轴坐标偏移
        weapon_sub_panel_text_clone_open=true, --是否开启text Clone
        mercenary_lineup_details_panel_hide_icon=true, --隐藏icon
        add_destiny_desc_two_line = true, --两行开启
        mercenary_fire_panel_is_already_select_hide = true, --没有选中时隐藏
        mercenary_sub_panel_hide_main_name = true, --隐藏主角名字，显示自己的名字
        exploring_panel_max_area_num_show_animation = true, --所有关卡都解锁了之后显示动画
        carnival_panel_title_text_offset_x = -15,  --活动界面标题位置偏移
        mercenary_sub_panel_bp_text_offset_x = 15,  --战力提升界面战力标签和图标位置偏移
        config_manager_change_locale_achievement_id_use = true, --更换语言后成就id是否使用table中的ID 
        novice_scene_skip_btn_show = true, --是否显示跳过按钮
        carnival_init_carnival_time_format = true, --活动界面时间格式化
        locale_panel_touch_all = true, --切换语言是否整行都能触摸
        hide_vip_can_talk = true, --隐藏月卡评论限制
        exploring_panel_difficulty_text_offset_x = 7, --获得经验界面难度等级标签x轴偏移量
        campaign_main_panel_level_widget_new_text_ap_center = true, --合战界面关卡new字锚点居中
        campaign_rank_msgbox_rank_info_exp_desc_ap_right = true, --合战-排名-每日奖励文字锚点在右边
        mining_cave_event_panel_convert_event_open_change = true, --从星期一开始排序
        main_panel_mailbox_btn_offset_x = -17,  --主界面邮箱位置图标偏移x
        main_panel_mailbox_btn_offset_y = 122,  --主界面邮箱位置图标偏移y
        pvp_main_panel_campaign_child_show_two_line = true, --pvp界面合战按钮显示描述为两行
        mercenary_confirm_fire_panel_algin_left = true, --解雇结算界面文字左对齐
        merchant_panel_hide_button_icon = true, --黑市界面要隐藏按钮上的图标
        mining_boss_rule_panel_scrollview_inner_setsize = true, --矿区boss规则的scrollview大小改变
        carnival_ladder_time_format = true, --荣誉之战提示时间格式化
        mercenary_sub_panel_force_btn_text_ap_center = true, --武将升级界面的的转换文字锚点居中
        mining_main_badge_desc_offset_x = -8, --矿区boss恶魔徽章文字偏移
        rune_draw_panel_desc_space = true, --符文界面描述文字空格
        remain_be_robbed_times_desc_before = true, --矿车运输界面剩余次数文字超框
        rule_panel_rest_view = true, --规则面板是否重新排版
        time_limit_buy_btn_desc_offset_x = 15, --限时礼包立即购买按钮文字向右的偏移量
        escort_rob_target_panel_rob_btn_desc_offset_x = 87, -- 拦截按钮文字偏移

        -----聊天设置-------
        is_open_chat = true,
        is_debug = false,
        chat_font_size = 25,  
        font_color = '#ffffff',
        other_size = 15,
        is_open_qi2 = true,
        font_file = "ui/fonts/general.ttf",
        role_font_size = 30,
        union_font_size = 25,
        input_font_size = 35,
        tip_size = 30,
    },

    r2games_appstore =
    {
        meta_channel = "r2games", locale = {"en-US", "de", "fr", "ru", "es-MX"}, switch_account = false, enable_error_folder = true, enable_sns = true,
        signin = { "r2games"}, pay = { "r2games" }, third_party_account = "2", currency_type = "USD", enable_payment_callback = true,
        auth_name = "auth_version", auth_code = "auth_code", center_login_btn = true, has_customer_btn = true, 
        region = "r2games", enable_query_products = true, disable_bbs_limit = true, enable_sns_bind_panel = true, enable_sns_share_panel = true,
        carnival_desc_font_height = 30, has_sns_share = true, need_refresh_setting_bind = true, cord_origin_pos = {x = -1,y = -1},
		coop_skill_mercenary_list_name_font_height = 20, mercenary_lineup_detail_panel_height = 80,coop_skill_mercenary_list_name_height = 70,
        app_link_url = "https://www.facebook.com/bravediggers/",  enable_sns_og_share = true,
        fb_like_url = "https://www.facebook.com/Brave-Diggers-470385973160601", game_request_title = "Join us now!", sns_platform = "facebook",
        game_request_message = "Come with me! Do some diggin', recruit badass heroes, and fight you some bad guys.",
        fb_like_url = "https://www.facebook.com/bravediggers",
        force_update = "force_update_ios", facebook_share_not_get_reward = true, get_device_locale = true, login_has_feedback = true, login_has_change_loacle = true,
        use_locale_notic = true, show_achievement_btn = true,
        mercenary_detail_panel_change_comment_size = true, exchange_reward_msgbox_change_desc_size = true, 
        ladder_top_ten_msgbox_change_desc_size = true, ore_bag_panel_change_pickaxe_name_pos_x = true,
        ore_bag_panel_change_desc_size = true, novice_change_text_size = true, transmigration_panel_change_artifact_value1_x = true,
        ore_sub_panel_change_name_pos_x = true, mining_district_panel_change_refresh_btn_size = true,
        achievement_panel_change_process_text_pos_x = true, carnival_panel_change_title_text_size = true,
        panel_util_change_language_dot_format = true, mercenary_levelup_panel_change_desc1_font_size = true,
        quest_panel_change_new_mail_tip_size = true, daily_panel_enable_switch_tab_animation = false,
        bbs_main_panel_change_discuss_btn_text_pos_x = true,
        down_load_version_move_x = 50,
        exploring_panel_exp_icon_move_x=20,
        mercenary_detail_panel_coop_and_artifact_text_pos_x=true,
        ad_bp_width_move3 = 35,
        weapon_panel_success_chance_text_add_air=true,
        mercenary_confirm_fire_panel_title_pos_y=20,
        mercenary_levelup_panel_force_btn_text_anchor=true, --卯点居中
        force_panel_ex_prop_val_text_add_air=true, --是否有空格
        quarry_panel_project_sub_panel_soul_chip_cost_text_pos_y=4, --y坐标偏移
        append_height_arena_rule_msgbox_desc4_fix = 7,
        append_height_arena_rule_msgbox_desc5_fix = {x = 12,y=18},
        confirm_msgbox_refresh_node_all_left=true,--左对齐
        achievement_sub_panel_icon_panel_hide=true, --隐藏
        weapon_sub_panel_msgbox_pos_y = 10, --y轴坐标偏移
        quarry_panel_project_sub_panels_need_clone=true, --需要克隆
        mercenary_info_sub_panel_all_right=true, --右对齐
        magic_recruit_msgbox_template_desc2_pos=true, --右对齐
        setting_panel_feedback_desc_text_pos_y=10, --y轴坐标偏移
        vip_panel_good_1_desc_all_left=true, --左对齐
        detail_info_sub_panel_use_btn_offset_x=10, --x轴坐标偏移
        quarry_panel_project_sub_panel_waiting_text_pos_y=-20, --x轴坐标偏移
        weapon_sub_panel_text_clone_open=true, --是否开启text Clone
        mercenary_lineup_details_panel_hide_icon=true, --隐藏icon
        add_destiny_desc_two_line = true, --两行开启
        mercenary_fire_panel_is_already_select_hide = true, --没有选中时隐藏 
        mercenary_sub_panel_hide_main_name = true, --隐藏主角名字，显示自己的名字
        exploring_panel_max_area_num_show_animation = true, --所有关卡都解锁了之后显示动画
        carnival_panel_title_text_offset_x = -15,  --活动界面标题位置偏移
        mercenary_sub_panel_bp_text_offset_x = 15,  --战力提升界面战力标签和图标位置偏移
        config_manager_change_locale_achievement_id_use = true, --更换语言后成就id是否使用table中的ID 
        novice_scene_skip_btn_show = true, --是否显示跳过按钮 
        carnival_init_carnival_time_format = true, --活动界面时间格式化
        locale_panel_touch_all = true, --切换语言是否整行都能触摸
        hide_vip_can_talk = true, --隐藏月卡评论限制
        exploring_panel_difficulty_text_offset_x = 7, --获得经验界面难度等级标签x轴偏移量
        campaign_main_panel_level_widget_new_text_ap_center = true, --合战界面关卡new字锚点居中
        campaign_rank_msgbox_rank_info_exp_desc_ap_right = true, --合战-排名-每日奖励文字锚点在右边
        mining_cave_event_panel_convert_event_open_change = true, --从星期一开始排序
        main_panel_mailbox_btn_offset_x = -17,  --主界面邮箱位置图标偏移x
        main_panel_mailbox_btn_offset_y = 122,  --主界面邮箱位置图标偏移y
        pvp_main_panel_campaign_child_show_two_line = true, --pvp界面合战按钮显示描述为两行
        mercenary_confirm_fire_panel_algin_left = true, --解雇结算界面文字左对齐
        merchant_panel_hide_button_icon = true, --黑市界面要隐藏按钮上的图标
        mining_boss_rule_panel_scrollview_inner_setsize = true, --矿区boss规则的scrollview大小改变
        carnival_ladder_time_format = true, --荣誉之战提示时间格式化
        mercenary_sub_panel_force_btn_text_ap_center = true, --武将升级界面的的转换文字锚点居中
        mining_main_badge_desc_offset_x = -8, --矿区boss恶魔徽章文字偏移
        rune_draw_panel_desc_space = true, --符文界面描述文字空格
        remain_be_robbed_times_desc_before = true, --矿车运输界面剩余次数文字超框
        rule_panel_rest_view = true, --规则面板是否重新排版
        time_limit_buy_btn_desc_offset_x = 15, --限时礼包立即购买按钮文字向右的偏移量
        escort_rob_target_panel_rob_btn_desc_offset_x = 87, -- 拦截按钮文字偏移
        
        -----聊天设置-------
        is_open_chat = true,
        is_debug = false, 
        chat_font_size = 25,  
        font_color = '#ffffff',
        other_size = 15,
        is_open_qi2 = true,
        font_file = "ui/fonts/general.ttf",
        role_font_size = 30,
        union_font_size = 25,
        input_font_size = 35,
        tip_size = 30,
    },

    qikujp_appstore = 
    {
        FYD_MODE = true,--将逻辑迁出来整理(执行统一的逻辑) 
        meta_channel = "qikujp", locale = {"jp"}, is_debug = false, account_type = "mu77", has_guest = true, auth_name = "auth_version", auth_code = "auth_code",
        signin = { "mu77", "gamecenter", "facebook"}, pay = { "appstore" }, show_agreement = true,
        region = "qikujp", auto_signin = true, account_server = "https://qiku.account.mu77.com/",
        appraise_url = "itms-apps://itunes.apple.com/app/id1094580863", 
        notice_url = "http://qikucommon.s3.amazonaws.com/dig/ios/ios.html",
        other_url = {"http://battleship.coolfactory.jp/rm/contactUs?gameUid="}, 
        enable_error_folder = true,
        coop_skill_mercenary_list_name_font_height = 20, coop_skill_mercenary_list_name_height = 70,
        gloabal_floating_res_detail_min_height = 160,
        leader_weapon_skill_desc_height = 80,
        transmigration_explain_desc2_change_height = -10,
        transmigration_scale_msgbox_time_change_x = -10,
        enable_appstore_pay = true,      --开启app内购
        currency_whitelist = "CNY;USD;EUR;TWD;AUD;GBP;JPY;CAD;HKD;SGD",   --白名单
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
        append_height_arena_rule_msgbox_desc5_fix = {x = 12,y=18},
        down_load_version_move_x = 50,  
        magic_recruit_msgbox_template_desc2_pos = true, --右对齐
        change_recruit_msgbox_template_desc_append_height = 80,
        change_recruit_msgbox_template_desc_append_height2 = 100,
        text_pannel_appending = 50,
    },

    qikujp_android = 
    {
        FYD_MODE = true,--将逻辑迁出来整理(执行统一的逻辑)   
        meta_channel = "qikujp", locale = {"jp"}, is_debug = false, account_type = "mu77", has_guest = true, auth_name = "auth_version_google", auth_code = "auth_code_google",
        signin = { "mu77", "facebook"}, pay = { "google" }, show_agreement = true, has_signout = true,
        region = "qikujp", auto_signin = false, account_server = "https://qiku.account.mu77.com/",
        appraise_url = "https://itunes.apple.com/cn/app/ying-xiong-yu-wang-guan/id1061850866?mt=8",
        notice_url = "http://qikucommon.s3.amazonaws.com/dig/ios/ios.html",
        other_url = {"http://battleship.qikuyx.com/rm/contactUs?gameUid="},
        enable_error_folder = true,
        coop_skill_mercenary_list_name_font_height = 20, coop_skill_mercenary_list_name_height = 70,
        gloabal_floating_res_detail_min_height = 160,
        leader_weapon_skill_desc_height = 80,
        transmigration_explain_desc2_change_height = -10,
        transmigration_scale_msgbox_time_change_x = -10,
        cord_origin_pos = {x = -1,y = -1},
        ad_bp_width_move = 110,
        coop_and_artifact_text_font_height = 20,
        is_hide_google_btn = true,
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
        focus_one_font_height = 20,
        extern_height = 100,
        append_height_arena_rule_msgbox_desc4_fix = 7,
        append_height_arena_rule_msgbox_desc5_fix = {x = 12,y=18}, 
        down_load_version_move_x = 50, 
        magic_recruit_msgbox_template_desc2_pos = true, --右对齐
        change_recruit_msgbox_template_desc_append_height = 80,
        change_recruit_msgbox_template_desc_append_height2 = 100,
        text_pannel_appending = 50,
    },

    txwy_appstore = 
    {
        meta_channel = "txwy", locale = {"zh-TW"},
        signin = { "txwy" }, pay = { "txwy"}, auth_name = "auth_version", auth_code = "auth_code",
        region = "txwy", enable_error_folder = true, enable_payment_callback = true,
        auto_signin_after_signout = false, has_user_center_ex = true, auto_signin = true,
        disable_signin_btn = true, has_customer_btn = true,
        login_has_change_user = true, has_recharge_btn = true,login_has_user_center_ex = true,
        cdkey_panel_has_like_btn = true,
        coop_skill_mercenary_list_name_font_height = 20, 
        coop_skill_mercenary_list_name_height = 70,
        enable_sns = true,
        enable_query_products = true,
        app_link_url = "http://userdb.txwy.tw/s/wk/txwy/",
        share_message = "台灣NO.1戰爭手遊!!挑戰成為送最多的手機遊戲!!快來幫我集氣!!",
        get_invite_list_url = "http://userdb.txwy.tw/s/wk?ip=%s&activeid=%s",
        mining_reset_panel_condition_text = 18,
        carnival_desc_font_height = 50,
        bbs_detail_panel_discuss_detail_text_font_size = 40,
        mining_lock_tip = "暫未開放、敬請期待",
        app_pre_link_url = "http://userdb.txwy.tw/a/shorten?url=",
        sns_copy_str = "複製成功",
    },

    txwy_android = 
    {
        meta_channel = "txwy", locale = {"zh-TW"},
        signin = { "txwy" }, pay = { "txwy"}, auth_name = "auth_version", auth_code = "auth_code_google",
        region = "txwy", enable_error_folder = true, enable_payment_callback = true,
        auto_signin_after_signout = false, has_user_center_ex = true, auto_signin = true,
        disable_signin_btn = true, has_customer_btn = true,
        login_has_change_user = true, has_recharge_btn = true, login_has_user_center_ex = true,
        cdkey_panel_has_like_btn = true,
        coop_skill_mercenary_list_name_font_height = 20, 
        coop_skill_mercenary_list_name_height = 70,
        enable_sns = true,
        enable_query_products = true,
        app_link_url = "http://userdb.txwy.tw/s/wk/txwy/",
        share_message = "台灣NO.1戰爭手遊!!挑戰成為送最多的手機遊戲!!快來幫我集氣!!",
        get_invite_list_url = "http://userdb.txwy.tw/s/wk?ip=%s&activeid=%s",
        mining_reset_panel_condition_text = 18,   --雜兵等級顯示不出來，縮小字體
        carnival_desc_font_height = 50,  --解決活動描述不換行的問題
        bbs_detail_panel_discuss_detail_text_font_size = 40,  --討論群不換行問題
        mining_lock_tip = "暫未開放、敬請期待",
        app_pre_link_url = "http://userdb.txwy.tw/a/shorten?url=",
        sns_copy_str = "複製成功",
    },

    --天象互动
    skymoons_android = setmetatable({has_user_center = true}, SKYMOONS_CHANNEL),

    --英雄互娱
    yxhy_android = setmetatable({signin = { "yxhy" }}, SKYMOONS_CHANNEL),

    --360奇虎
    qihoo_android = setmetatable({signin = { "qihoo" }}, SKYMOONS_CHANNEL),

    --百度多酷
    baidu_android = setmetatable({signin = { "baidu" }}, SKYMOONS_CHANNEL),

    uc_android = setmetatable({signin = { "uc" }}, SKYMOONS_CHANNEL),

    --小米
    mi_android = setmetatable({signin = { "mi" }}, SKYMOONS_CHANNEL),

    --魅族
    meizu_android = setmetatable({signin = { "meizu" }}, SKYMOONS_CHANNEL),

    oppo_android = setmetatable({signin = { "oppo" }}, SKYMOONS_CHANNEL),

    --联想
    lenovo_android = setmetatable({signin = { "lenovo" }}, SKYMOONS_CHANNEL),

    --vivo
    vivo_android = setmetatable({signin = { "vivo" }}, SKYMOONS_CHANNEL),

    --酷派
    coolpad_android = setmetatable({signin = { "coolpad" }}, SKYMOONS_CHANNEL),

    huawei_android = setmetatable({signin = { "huawei" }}, SKYMOONS_CHANNEL),

    ["4399_android"] = setmetatable({signin = { "m4399" }}, SKYMOONS_CHANNEL),

    anzhi_android = setmetatable({signin = { "anzhi" }}, SKYMOONS_CHANNEL),
    pptv_android = setmetatable({signin = { "pptv" }}, SKYMOONS_CHANNEL),
    pps_android = setmetatable({signin = { "pps" }}, SKYMOONS_CHANNEL),
    youku_android = setmetatable({signin = { "youku" }}, SKYMOONS_CHANNEL),

    sogou_android = setmetatable({signin = { "sogou" }}, SKYMOONS_CHANNEL),
    wogame_android = setmetatable({signin = { "wogame" }}, SKYMOONS_CHANNEL),

    sina_android = setmetatable({signin = { "sina" }}, SKYMOONS_CHANNEL),
    --益玩
    ewan_android = setmetatable({signin = { "ewan" }, delay_check_order_time = 1.0 }, SKYMOONS_CHANNEL),
    downjoy_android = setmetatable({signin = { "downjoy" }}, SKYMOONS_CHANNEL),
    wandoujia_android = setmetatable({signin = { "wandoujia" }}, SKYMOONS_CHANNEL),
    mzw_android = setmetatable({signin = { "mzw" }}, SKYMOONS_CHANNEL),

    --爱游戏
    egame_android = setmetatable({signin = { "egame" }}, SKYMOONS_CHANNEL),
    --今日头条
    toutiao_android = setmetatable({signin = { "toutiao" }}, SKYMOONS_CHANNEL),
    kugou_android = setmetatable({signin = { "kugou" }}, SKYMOONS_CHANNEL),
    gfan_android = setmetatable({signin = { "gfan" }}, SKYMOONS_CHANNEL),
    meitu_android = setmetatable({signin = { "meitu" }, has_user_center = true }, SKYMOONS_CHANNEL),
    mumayi_android = setmetatable({signin = { "mumayi" }}, SKYMOONS_CHANNEL),

    --应用汇
    appchina_android = setmetatable({signin = { "appchina" }}, SKYMOONS_CHANNEL),

    --37wan
    ["5gwan_android"] = setmetatable({signin = { "m5gwan" }}, SKYMOONS_CHANNEL),
    --xx助手
    guopan_android = setmetatable({signin = { "guopan" }}, SKYMOONS_CHANNEL),

    kaopu_android = setmetatable({signin = { "kaopu" }}, SKYMOONS_CHANNEL),
    letv_android = setmetatable({signin = { "letv" }}, SKYMOONS_CHANNEL),
    paojiao_android = setmetatable({signin = { "paojiao" },has_user_center = true}, SKYMOONS_CHANNEL),

    --电信
    ct_android = setmetatable({signin = { "ct" }}, SKYMOONS_CHANNEL),
    --金立
    gionee_android = setmetatable({signin = { "gionee" }}, SKYMOONS_CHANNEL),

    --桌易
    zhuoyi_android = setmetatable({signin = { "zhuoyi" }, has_signout = false }, SKYMOONS_CHANNEL),

    --腾讯应用宝
    tencent_android = setmetatable({signin = { "tencent" }, group_id = 5}, SKYMOONS_CHANNEL),

    --唱吧
    changba_android = setmetatable({signin = { "changba" }}, SKYMOONS_CHANNEL),

    --游艺春秋
    iccgame_android = setmetatable({signin = { "iccgame" }}, SKYMOONS_CHANNEL),

    --拇指游玩
    mzyw_android = setmetatable({signin = { "mzyw" }}, SKYMOONS_CHANNEL),
    --草花
    caohua_android = setmetatable({signin = { "caohua" }}, SKYMOONS_CHANNEL),
    --同步
    tongbu_android = setmetatable({signin = { "tongbu" }}, SKYMOONS_CHANNEL),

    --松果游戏
    sguo_android = setmetatable({signin = { "sguo" }}, SKYMOONS_CHANNEL),

    --尖游
    jianyou_android = setmetatable({signin = { "jianyou" }}, SKYMOONS_CHANNEL),

    --星游
    stargame_android = setmetatable({signin = { "stargame" }}, SKYMOONS_CHANNEL),

    --九玩
    ["910app_android"] = setmetatable({signin = { "910app" }}, SKYMOONS_CHANNEL),

    --快用
    kuaiyong_android = setmetatable({signin = { "kuaiyong" }}, SKYMOONS_CHANNEL),

    baiduml_android = setmetatable({signin = { "baiduml" }}, SKYMOONS_CHANNEL),

    tencentml_android = setmetatable({signin = { "tencentml" }, group_id = 5}, SKYMOONS_CHANNEL),

    --盟宝
    memberv_android = setmetatable({signin = { "memberv" }}, SKYMOONS_CHANNEL),

    --广点通
    guangdian_android = setmetatable({signin = { "tencentml" }, group_id = 5}, SKYMOONS_CHANNEL),

    --米迪
    miidi_android = setmetatable({signin = { "tencentml" }, group_id = 5}, SKYMOONS_CHANNEL),

    --朋友玩
    pyw_android = setmetatable({signin = { "pyw" }}, SKYMOONS_CHANNEL),
}


local FREE_CHANNEL_INFO =
{
    ["meta"] =
    {
        meta_channel = "mu77", switch_account = true, locale = "zh-CN",
        signin = { "mu77", "wechat" }, pay = { "wechat", "alipay" }, account_type = "mu77",
        group_id = 3, region = "china",
    },

    ["mu77_android"] = true,
    ["mu77_ios"] = true,

    ["u77_android"] = true,
    ["u77_ios"] = true,

    --扑家汉化
    ["pujia_android"] = true,
    ["pujia_ios"] = true,

    --蒹葭汉化
    ["jianjia_android"] = true,
    ["jianjia_ios"] = true,

    --
    ["3dm_android"] = true,
    ["3dm_ios"] = true,

    --宽带山
    ["kdslife_android"] = true,
    ["kdslife_ios"] = true,

    ["17173_android"] = true,
    ["17173_ios"] = true,

    --布鲁潘达
    ["bluepanda_android"] = true,
    --好世界
    ["hsjsns_android"] = true,
    --轻之国度
    ["lightnovel_android"] = true,
    --天使二次元
    ["tianshi2_android"] = true,

    --拼命玩
    ["wanga_android"] = true,

    --灵动游戏
    ["mhhf_android"] = true,

    --星游
    ["de518_android"] = true,

    --易游
    ["gamexz_android"] = true,

    --魔方
    ["mofang_android"] = true,

    --有得
    ["youtak_1_android"] = "youtak",
    ["youtak_2_android"] = "youtak",
    ["youtak_3_android"] = "youtak",
    --
    ["baoruan_android"] = true,
}

local channel_list = {}

function channel_list:Init(channel_name)
    
    local channel_info = CHANNEL_INFO[channel_name]
    
    print("服务器地址");
    
    if not channel_info then
        local free_channel_info = FREE_CHANNEL_INFO[channel_name]
        if free_channel_info then
            channel_info = FREE_CHANNEL_INFO["meta"]
           
            if type(free_channel_info) == "string" then
                channel_info.meta_channel = free_channel_info
                
            else
                channel_info.meta_channel = string.match(channel_name, "(%w+)_")
            end

            channel_info.name = channel_name
        else
            channel_info = CHANNEL_INFO["mu77_dev"]
            channel_info.name = "mu77_dev"
        end

    else
        channel_info.name = channel_name
    end
    
    -----------------test服务配置
    if TEST_SERVER == 1 then
        channel_info.region = channel_info.region.."_test"
    elseif TEST_SERVER == 2 then
        channel_info.region = "internal" --所有的内部服用的都是这个
    end

    channel_info.server_list_host = SERVER_LIST_HOST[channel_info.region]
 
    channel_info.server_list_url = SERVER_LIST_URL[channel_info.region]
    print("服务器地址是"..channel_info.server_list_url);
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
                print("FYD"..channel_info.name)
            end
           

        elseif v == "google" then
            channel_info.enable_google_pay = true
        end
    end

    return channel_info
end

return channel_list
