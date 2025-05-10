local event_listener = require "util.event_listener"
local graphic = {}

local _EVENT_TYPE =
{
    "lost_connection",
    "user_finish_login",
    "user_finish_create_leader",
    "user_finish_query_info",

    "trigger_novice_guide",
    "enter_maze", --

    "show_battle_room",
    "hide_battle_room",
    "play_battle_record",
    "show_login_panel",
    "fetch_server_list",
    "show_bind_account_result",

    "solve_event_result",
    "show_event_info",
    "unlock_new_adventure_maze",--有解锁的新地图，则冒险场景下的 进入新地图按钮可以点击
    "show_maze_box",
    "update_explore_event_progress",
 
    "show_new_mining_block",
    "is_digging",
    "finish_dig_block",
    "refresh_random_event",
    "finish_use_tnt",
    "finish_collect_mine",
    "update_dig_recover_time",
    "update_dig_count",
    "finish_random_event",
    "refresh_event_count",
    "accept_random_event",
    "update_exploring_merceanry_position",
    "update_exploring_merceanry",
    "fire_mercenary",
    "update_mercenary_wakeup",
    "update_mercenary_weapon_lv",
    "transmigrate_mercenary",
    "recruit_mercenary",
    "update_battle_point",
    "update_mercenary_level",
    "sign_mercenary_contract",

    "update_bag",
    "store_buy_success",

    "use_mining_tool",
    "unlock_mining_project",
    "update_mining_project_list",

    "upgrade_leader_weapon_lv",
    "update_leader_weapon",
    "complete_achievement",
    "update_achievement_progress",
    "remind_achievement",


    "update_resource_list",
    "update_merchant_info",

    "arena_challenge_result",
    "arena_refresh_rival",
    "arena_take_prize",
    "ladder_update_rival",
    "ladder_top_ten",
    "temple_recruit_success",
    "open_artifact",

    "refresh_mining_area",
    "update_mining_boss_info",
    "insert_exploring_mercenary_position",

    "start_waiting",
    "finish_waiting",

    "use_item_which_in_bag",
    "get_new_mercenary",
    "update_world_tab_status",
    "new_mail",
    "open_mail",
    "take_daily_reward",

    "update_payment_panel",
    "update_mercenary_info",
    "hide_alert_panel",
    "sim_touch",

    "update_bbs_main_panel",
    "update_bbs_detail_panel",

    "accept_invitation",
    "refuse_invitation",
    "new_friend",
    "remove_friend",

    "update_force_panel",

    "remind_forge",       -- 主界面强化提醒事件

    "send_friend_gift",
    "search_player_result",
    "invite_player",
    "new_invite",

    "new_bbs",
    "bag_is_full", --背包满了

    "start_purchase",
    "finish_purchase",
    "show_simple_msgbox",

    "show_world_sub_scene",
    "hide_world_sub_scene",

    "show_world_sub_panel",
    "hide_world_sub_panel",

    "show_prompt_panel",
    "user_logout",

    "show_login_result",
    "show_auth_result",

    "update_account_info",
    "update_sub_carnival_reward_status";
    "buy_vip_success",
    "take_vip_reward_success",
    "remind_world_sub_scene",
    "remind_check_in", --签到提醒
    "remind_carnival", --活动提醒
    "library_recruit_success",
    "library_new_mercenary",
    "update_comment_panel",
    "update_mailbox_animate",
    "change_troop_formation", --更新迷宫中的佣兵
    "update_comment_num",
    "update_quest_panel",
    "show_floating_panel",
    "hide_floating_panel",
    "craft_soul_stone_success",
    "craft_soul_stone_success2",
    "update_panel_leader_name",

    -- 合战
    "update_buff_msgbox_item",      --合战BUFFitem更新
    "update_campaign_main_exp",     --更新合战主界面经验
    "update_campaign_main_score",   --更新合战主界面赛点
    "update_campaign_reward_time",  --自更新奖励时间
    "update_campaign_main_rank",    --更新合战主界面排行
    "update_campaign_main",         --更新合战主界面
    "update_campaign_level",        --更新合战关卡信息
    "update_campaign_reward_score", --更新合战奖励积分
    "update_campaign_reward_info",  --更新奖励对象
    "update_campaign_event",        --更新合战事件界面
    "update_carnival_union_data",   --全服活动数据
    "remind_daily_mark",            --标签绿点

    -- 公会
    "run_guild_animation",      --播放公会动画
    "search_guild_result",      --搜索公会结果
    "join_guild",               --加入公会
    "exit_guild",               --退出公会
    "get_guild_list_result",    --获得工会列表 100个 结果
    "refresh_member_tips",      --刷新会员提醒
    "refresh_notice_tips",      --刷新通知提醒
    "update_guild_member",      --刷新公会成员列表
    "refresh_guild_chairman",   --刷新公会会长设置
    
    -- 矿区副本
    "cave_event_update",        --通关更新
    "cave_boss_update",         --矿区BOSS更新
    "cave_boss_bp_animation",   --矿区BOSS血量动画

    --活动
    "carnival_vote",                --投票

    "hide_all_sub_panel",           --隐藏所有界面

    "reload_campaign_cave_event",   --刷新矿区副本弹窗

    "update_lottery_panel",         --红包界面刷新
    "choose_mercenary_evolution",   --选完要进化的佣兵
    "mercenary_evolution_success",  --进化成功

    "show_new_notice", --显示公告

    "update_sns_panel",

    "hide_achieve_panel_fb_node",
    "hide_new_mercenary_fb_node",
    "hide_battle_panel_fb_node",

    "update_setting_bind_state",
    "update_share_sub_panel",
    "update_bind_sub_panel",

    "remind_sns_reward", --提醒领取SNS奖励
    "update_app_msgbox", --强更提醒

    "guide_open", --引导开启
    "guide_close", -- 引导关闭
    "loading_scene_signout", --loading场景要切换账号

    "refresh_quick_battle", --刷新冒险界面的快速战斗信息
    
    "show_difficulty_tips",         --选择难度提示

    "guildwar_enlist_refresh",      --进入公会战主界面
    "guildwar_formation_refresh",   --刷新据点列表
    "refresh_war_rival_info",       --刷新敌人信息
    "update_guild_member_buff",
    "update_guild_member_grade",
    "guildwar_join_warfield",       --加入据点

    "update_guild_scout_info",      --更新刺探的情报
    "update_guild_war_status",      --更新公会战的时间状态

    "update_guild_exchange_count",  --更新公会兑换奖励次数
    "update_guild_alloc_bonus",     --更新公会可分配奖励点
    "update_guild_alloc_info",      --更新公会分配后信息

    "new_rune_in_bag",              --背包中有新符文
    "new_rune_in_temporary_bag",    --临时背包中有新符文
    "receive_rune_to_bag",          --收取符文
    "refresh_rune_bag",             --刷新符文背包
    "rune_bag_select_confirm",      --符文背包选择确认
    "refresh_rune_equipment",       --刷新符文安装位置
    "rune_upgrade_success",
    
    "update_rob_target_list",       --更新运送可拦截目标
    "update_escort_times",          --更新运送相关次数
    "update_be_robbed_list",        --更新被拦截列表
    "refresh_remain_escort_times",  --刷新剩余运送次数
    "refresh_remain_rob_times",     --刷新剩余可拦截次数
    "refresh_select_tramcar",       --刷新选择的矿车
    "start_escort",                 --开始运送矿车
    "finish_escort",                --运送矿车完成
    "receive_reward_success",       --领取运送奖励

    "update_feature_config",    --功能开关刷新

    "get_mercenary",            --兑换佣兵
    "update_magic_gold",        --更新积分  --
    "hide_magic_shop_pannel",   --關閉當前打開的積分商城的界面
    
    "update_server_pvp_rank", --刷新跨服PVP排行榜
    "update_server_pvp_times", --更新挑战次数
    "expire_time_over", --佣兵倒计时结束

    "boss_hp_refsh" , --bos血量刷新
    "boss_deid_refsh" , --boss被打死后
    "update_guild_boss_exchange_count", --boss兑换刷新
    "guild_boss_info_update", --bossinfo刷新
    "guild_ranking_refsh", --排行刷新
    "guild_boss_info_rest", --boss重置
    "boss_change_refsh", --boss更换

    "update_server_pvp_rank",   --刷新跨服PVP排行榜
    "update_server_pvp_times",  --更新挑战次数
    "expire_time_over",         --佣兵倒计时结束
    "show_jump_panel",          --显示资源不足，跳转的弹框
    "hide_jump_panel",
    "update_world_tab",         --更新资源跳转时，下边的栏目切换问题
    "to_mining_boos",           --进入矿区boos界面
    "jump_finish",              --跳转结束
    "change_to_sub_pvp",        --跳转到Pvp子界面
    "change_daily_tab",         --切换签到子标签
    "show_mask_node",           --显示遮罩层
    "hide_mask_node",           --隐藏遮罩层
    
    "change_to_forge",          --切换到佣兵强化页面
    "activity_info_update",     --活跃度信息刷新

    "buy_limite_success",       --限时礼包购买成功
    "update_limite_state",      --刷新限时礼包状态 
    
    "mercenary_artifact_upgrade", --宝具升级成功
    "update_blood_diamond",     --更新血钻显示

    "mine_start_success",       --矿山开采
    "mine_buy_times_success",   --矿山购买消耗次数成功
    "mine_unlock_success",      --矿山解锁成功
    "mine_refresh_rewards_success", --矿山刷新奖励成功
    "mine_refresh_rob_target_list_success", -- 刷新玩家成功
    "mine_rob_target_success",  --掠夺成功
    "mine_receive_reward_success", -- 领取奖励成功
    "rest_mercenary_success",   --下阵成功
    "query_mine_report_success", --查询战报成功
    "have_revenge_info",        --有可以复仇的列表
    "report_state_success",          --战报状态刷新过了
    "check_mine_report_success", --检查绿点状态返回

    "update_cultivation",       --更新修炼主界面 
    "show_blood_replace_panel",  --显示血钻替代材料
    "hide_blood_replace_panel",  --关闭血钻替代材料
    "mine_cancel_success",      --取消开采成功
    "update_share_info_state",       --分享信息刷新
    "share_callback",           --分享回调

    "ladder_refresh_success",   --天梯赛刷新玩家成功
    "ladder_buy_times_success", --购买成功
    "ladder_fighting_success",  --挑战成功
    "rank_refresh_success",     --排行榜查询成功
    "ladder_show_start_season_success", -- 查看过公告了

    "weapon_upgrade_star_success", --宿命武器升星
    "get_final_destiny_weapon",
    "unlock_destiny_weapon_star",
    "ladder_flash_success",     --主角闪金化成功
    "change_ladder_skin_success",--换装成功
    "unlock_ladder_success",    --解锁成功 
    "have_a_new_message",       --有新的消息
    "select_connect_success",   --选择房间成功
    "select_connect_failed",   --选择房间失败
    "update_title_btn_title",   --更新称号系统 按钮的文本
    "update_title_limit_time",  --更新称号的剩余时间
    "add_material_success",     --添加炼化资源成功
    "query_resource_recycle_success", --查询资源成功
    "resource_recycle_click_finish_success", -- 点击完成
    "rune_exchange_success",    --交换成功
    "get_vanity_mercenary_success", --获取一批新的佣兵
    "update_vainty_formation_success", --阵容信息改变  
    "query_vanity_goods_success",    --查询商品列表成功 
    "vanity_battle_success",     --挑战boss成功
    "update_vanity_maze_info_success", -- 更新关卡状态
    "vanity_exchange_goods_success", --商品兑换成功
    "show_vanity_animation",     --领取成功播放动画
    "clear_recurit_library_time_success",  --清除冷却时间成功
    "get_vanity_reduce_mercenary_success", --虚空额外召唤佣兵成功
}

graphic.EVENT_TYPE = {}
for i, v in ipairs(_EVENT_TYPE) do
    graphic.EVENT_TYPE[v] = i
end

function graphic:Init()
    self.event_listener = event_listener.New("multi")
end

function graphic:RegisterEvent(event_name, handler)
    if type(event_name) == "string" then
        event_name = graphic.EVENT_TYPE[event_name]
    end

    self.event_listener:Register(event_name, handler)
end

function graphic:DispatchEvent(event_name, ...)
    if type(event_name) == "string" then
        event_name = graphic.EVENT_TYPE[event_name]
    end
    self.event_listener:Dispatch(event_name, ...)
end

function graphic:BindEventListener(name)
    self.event_listener = event_listener.New("multi")
end

return graphic
