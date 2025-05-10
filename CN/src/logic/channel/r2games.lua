local meta_info = {
    meta_channel = "r2games",
    region = "r2games",
    locale = {"en-US", "de", "fr", "ru", "es-MX"}, 
    currency_type = "USD",
    third_party_account = "2",

    signin = { "r2games"},
    pay = { "r2games" },
    switch_account = false,
    enable_error_folder = true,
    enable_sns = true,

    app_link_url = "https://www.facebook.com/bravediggers/",
    fb_like_url = "https://www.facebook.com/Brave-Diggers-470385973160601",
    fb_like_url = "https://www.facebook.com/bravediggers",
        
    enable_payment_callback = true,
    center_login_btn = true,
    has_customer_btn = true, 
    enable_query_products = true,
    disable_bbs_limit = true,
    enable_sns_bind_panel = true,
    enable_sns_share_panel = true,
    carnival_desc_font_height = 30,
    has_sns_share = true,
    need_refresh_setting_bind = true,
    cord_origin_pos = {x = -1,y = -1},
    coop_skill_mercenary_list_name_font_height = 20,
    mercenary_lineup_detail_panel_height = 80,
    coop_skill_mercenary_list_name_height = 70,
    enable_sns_og_share = true,
    sns_platform = "facebook",
    game_request_title = "Join us now!",
    game_request_message = "Come with me! Do some diggin', recruit badass heroes, and fight you some bad guys.",
    
    facebook_share_not_get_reward = true,
    get_device_locale = true,
    login_has_feedback = true,
    login_has_change_loacle = true,
    use_locale_notic = true,
    show_achievement_btn = true,
    mercenary_detail_panel_change_comment_size = true,
    exchange_reward_msgbox_change_desc_size = true, 
    ladder_top_ten_msgbox_change_desc_size = true,
    ore_bag_panel_change_pickaxe_name_pos_x = true,
    ore_bag_panel_change_desc_size = true,
    novice_change_text_size = true,
    transmigration_panel_change_artifact_value1_x = true,
    ore_sub_panel_change_name_pos_x = true,
    mining_district_panel_change_refresh_btn_size = true,
    achievement_panel_change_process_text_pos_x = true,
    carnival_panel_change_title_text_size = true,
    panel_util_change_language_dot_format = true,
    mercenary_levelup_panel_change_desc1_font_size = true,
    quest_panel_change_new_mail_tip_size = true,
    daily_panel_enable_switch_tab_animation = false,
    bbs_main_panel_change_discuss_btn_text_pos_x = true,
    down_load_version_move_x = 50,
    exploring_panel_exp_icon_move_x = 10,
    mercenary_detail_panel_coop_and_artifact_text_pos_x=true,
    ad_bp_width_move3 = 35,
    weapon_panel_success_chance_text_add_air = true,
    mercenary_confirm_fire_panel_title_pos_y = 20,
    mercenary_levelup_panel_force_btn_text_anchor = true, --卯点居中
    quarry_panel_project_sub_panel_soul_chip_cost_text_pos_y = 4, --y坐标偏移
    append_height_arena_rule_msgbox_desc4_fix = 7,
    append_height_arena_rule_msgbox_desc5_fix = {x = 12, y = 18},
    confirm_msgbox_refresh_node_all_left = true,--左对齐
    achievement_sub_panel_icon_panel_hide = true, --隐藏
    weapon_sub_panel_msgbox_pos_y = 10, --y轴坐标偏移
    quarry_panel_project_sub_panels_need_clone = true, --需要克隆
    mercenary_info_sub_panel_all_right = true, --右对齐
    magic_recruit_msgbox_template_desc2_pos = true, --右对齐
    setting_panel_feedback_desc_text_pos_y = 10, --y轴坐标偏移
    vip_panel_good_1_desc_all_left = true, --左对齐
    detail_info_sub_panel_use_btn_offset_x = 10, --x轴坐标偏移
    quarry_panel_project_sub_panel_waiting_text_pos_y = -20, --x轴坐标偏移
    weapon_sub_panel_text_clone_open=true, --是否开启text Clone
    mercenary_lineup_details_panel_hide_icon=true, --隐藏icon
    add_destiny_desc_two_line = true, --两行开启
    mercenary_fire_panel_is_already_select_hide = true, --没有选中时隐藏
    mercenary_sub_panel_hide_main_name = true, --隐藏主角名字，显示自己的名字
    exploring_panel_max_area_num_show_animation = true, --所有关卡都解锁了之后显示动画
    carnival_panel_title_text_offset_x = -15,  --活动界面标题位置偏移
    mercenary_sub_panel_bp_text_offset_x = 15,  --战力提升界面战力标签和图标位置偏移
    config_manager_change_locale_achievement_id_use = true, --更换语言后成就id是否使用table中的ID 
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
    
    --TAG:MASTER_MERGE
    update_img_task_list = true,
    mercenary_contract_use_soul_bone = true,
    merchant_show_reward_box = true,
}
meta_info.__index = meta_info

return function(channel_name)
    local channel_info = {}

    if channel_name == "r2games_appstore" then
        channel_info = {
            auth_name = "auth_version",
            auth_code = "auth_code",
            force_update = "force_update_ios",
        }

    elseif channel_name == "r2games_android" then
        channel_info = {
            auth_name = "auth_version_google",
            auth_code = "auth_code_google",
            force_update = "force_update_android",
        }
    end

    return setmetatable(channel_info, meta_info)
end
