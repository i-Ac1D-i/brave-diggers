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
    "finish_dig_block",
    "finish_use_tnt",
    "finish_collect_mine",
    "update_dig_recover_time",

    "update_exploring_merceanry_position",
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
    "update_buff_msgbox_item", --合战BUFFitem更新
    "update_campaign_main_exp", --更新合战主界面经验
    "update_campaign_main_score", -- 更新合战主界面赛点
    "update_campaign_reward_time", -- 自更新奖励时间
    "update_campaign_main_rank",    --  更新合战主界面排行
    "update_campaign_main",         -- 更新合战主界面
    "update_campaign_level",        -- 更新合战关卡信息
    "update_campaign_reward_score",  -- 更新合战奖励积分
    "update_campaign_reward_info",      --- 更新奖励对象
    "update_campaign_event",        --更新合战事件界面
    "update_carnival_union_data",   --全服活动数据
    "remind_daily_mark",        -- 标签绿点

    -- 公会
    "run_guild_animation", -- 播放公会动画
    "search_guild_result", --搜索公会结果
    "join_guild", -- 加入公会
    "exit_guild", --退出公会
    "refresh_member_tips", -- 刷新会员提醒
    "refresh_notice_tips", -- 刷新通知提醒
    "update_guild_member", -- 刷新公会成员列表
    "refresh_guild_chairman", -- 刷新公会会长设置

    -- 矿区副本
    "cave_event_update", --通关更新
    "cave_boss_update",  --矿区BOSS更新
    "cave_boss_bp_animation", --矿区BOSS血量动画

    --活动
    "carnival_vote", --投票

    "hide_all_sub_panel",--隐藏所有界面

    "reload_campaign_cave_event", --刷新矿区副本弹窗

    "update_lottery_panel", -- 红包界面刷新
    "choose_mercenary_evolution", --选完要进化的佣兵
    "mercenary_evolution_success", --进化成功

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

    "buy_limite_success", --限时礼包购买成功
    "update_limite_state", --刷新限时礼包状态 
    
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
