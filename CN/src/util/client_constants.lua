local constants = require "util.constants"
local lang_constants = require "util.language_constants"

--TAG:MASTER_MERGE BEG
--返回channel_constants，client_constants作为前者的元表进行访问，形如默认值。
--client_constants中为大陆使用的值，各渠道不同的值定义在channel_constants中，以覆盖client_constants

local platform_manager = require "logic.platform_manager"

local channel_constants = {}
if platform_manager:GetChannelInfo().region == "r2games" then
    --Loading界面菊花动画的皮肤数量
    channel_constants["LOADING_SPINE_SKIN_NUM"] = 6

    channel_constants["MINING_MINE_ANIMATION_POS_Y"] = 1800
elseif platform_manager:GetChannelInfo().region == "qikujp" then

    channel_constants["MINING_MINE_ANIMATION_POS_Y"] = 1800
elseif platform_manager:GetChannelInfo().region == "txwy" then
    --Loading界面菊花动画的皮肤数量
    channel_constants["LOADING_SPINE_SKIN_NUM"] = 6

    --bbs字数限制
    channel_constants["BBS_MAX_WORD_NUM"] = 45

    --竞技界面间隔
    channel_constants["PVP_MAIN_SUB_PANEL_OFFSET_POS_Y"] = 90

    channel_constants["MINING_BOSS_RULE"] = {
        [1] = {level = "Lv1-4",  reward_type = "2|2|1", reward_id = "3|4|10000002"},
        [2] = {level = "Lv5-7",  reward_type = "2|2|2", reward_id = "12|13|28"},
        [3] = {level = "Lv8-10",  reward_type = "2|2|2|1", reward_id = "3|4|18|11000002"},
        [4] = {level = "Lv11-13",  reward_type = "2|2|2|1", reward_id = "3|4|28|10000006"},
        [5] = {level = "Lv14-16",  reward_type = "2|2|2|1", reward_id = "12|13|23|10000009"},
        [6] = {level = "Lv17-25",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
        [7] = {level = "Lv26-28",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
        [8] = {level = "Lv29-31",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
    }

    channel_constants["RANDOM_KEY_ICON"] = "icon/festival/chest.png"
    
    channel_constants["MINING_MINE_ANIMATION_POS_Y"] = 2106
elseif platform_manager:GetChannelInfo().region == "txwy_dny" then
    --Loading界面菊花动画的皮肤数量
    channel_constants["LOADING_SPINE_SKIN_NUM"] = 6

    --bbs字数限制
    channel_constants["BBS_MAX_WORD_NUM"] = 45

    --竞技界面间隔
    channel_constants["PVP_MAIN_SUB_PANEL_OFFSET_POS_Y"] = 90

    channel_constants["MINING_BOSS_RULE"] = {
        [1] = {level = "Lv1-4",  reward_type = "2|2|1", reward_id = "3|4|10000002"},
        [2] = {level = "Lv5-7",  reward_type = "2|2|2", reward_id = "12|13|28"},
        [3] = {level = "Lv8-10",  reward_type = "2|2|2|1", reward_id = "3|4|18|11000002"},
        [4] = {level = "Lv11-13",  reward_type = "2|2|2|1", reward_id = "3|4|28|10000006"},
        [5] = {level = "Lv14-16",  reward_type = "2|2|2|1", reward_id = "12|13|23|10000009"},
        [6] = {level = "Lv17-25",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
        [7] = {level = "Lv26-28",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
        [8] = {level = "Lv29-31",  reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|24|3|4|29"},
    }

    channel_constants["RANDOM_KEY_ICON"] = "icon/festival/chest.png"
    
    channel_constants["MINING_MINE_ANIMATION_POS_Y"] = 2186
end

local client_constants = {}
setmetatable(channel_constants, { __index = client_constants })
--TAG:MASTER_MERGE END

client_constants["MAZE_POSITION"] =
{
    [1] =
    {
        112, 802,
        220, 896,
        320, 782,
        382, 926,
        552, 874,

        x = 330, y = 856,

        scale_x = -1,
        scale_y = -1,
    },

    [2] =
    {
        88, 856,
        220, 784,
        346, 922,
        440, 810,
        554, 852,

        x = 330, y = 862,

        scale_x = 1,
        scale_y = -1,
    },

    [3] =
    {
        85, 846,
        256, 922,
        322, 768,
        450, 896,
        552, 832,

        x = 330, y = 856,

        scale_x = 1,
        scale_y = 1,
    },
}

client_constants["MAZE_TYPE"] =
{
    ["exp"] = 1,
    ["gold_coin"] = 2,
    ["etc"] = 3,
    ["item"] = 4,
    ["boss"] = 5,
}

--活动面板类型
client_constants["CARNIVAL_TEMPLATE_TYPE"] =
{
    ["rank"] = 1, --排名
    ["stage"] = 2, --阶段
    ["display"] = 3, --展示(道具，资源，代币或者佣兵)，首充展示奖励啊，收集道具展示道具的收集进度啊等， 代币兑换等
    ["text"] = 4, --纯文本展示
    ["discount"] = 5, --优惠信息
    ["multi_token"] = 6, --多种兑换多种奖励
    ["evolution"] = 7, --合成佣兵
    ["fund"] = 8, --基金
    ["mercenary_exchange"] = 9, --佣兵兑换
    ['limite_package'] = 88,
    ['sns_invitation'] = 89,
    ["scroll_intro"] = 90, --卷轴样式的功能介绍
    ["spring_lottery"] = 91, --新春红包
    ["christmas"] = 92,
    ["version_update"] = 93, --更新
    ["first_payment"] = 94,
    ["time_limit_store"] = 95,
    ["friendship"] = 96,
    ["transmigrate"] = 97,
    ["magic_door"] = 98,
    ["cdkey"] = 99, --礼包码
}

--活动奖励显示类型
client_constants["CARNIVAL_REWARD_TYPE"] =
{
    ["permanent"] = 1, --永久性 只能领取一次
    ["single"] = 2, --活动只有一个奖励
    ["multi"] = 3, --多个奖励
    ["token"] = 4, --代币活动奖励
    ["multi_token"] = 5, --搜集多个代币
    ["vote"] = 6, --投票
}

--carnival_reward_panel 类型
client_constants["CARNIVAL_REWARD_PANEL_TYPE"] =
{
    ["rank"] = 1, --佣兵排名
    ["collect"] = 2, --兑换
    ["vote"] = 3, --投票
}

client_constants["CARNIVAL_STEP_STATUS"] =
{
    ["cant_take"]  = 1,
    ["can_take"] = 2,
    ["already_taken"] = 3,
}

client_constants["CARNIVAL_VISIBLE_TYPE"] =
{
    ["common"] = 1,
    ["item_info"] = 2,
    ["cdkey"] = 3,
    ["friendship"] = 4,
    ["collect_token"] = 5,
    ["union"] = 6, --数据是全服的，每次打开必须像服务器请求数据
    ["mining"] = 7, --非洲矿洞活动
    ["eternal_temple"] = 8, --永恒神殿
    ["magic_door"] = 9, --秘书之门
    ["another_panel"] = 10,
}

--冒险场景中 渲染层级
client_constants["ADVENTURE_MAZE_ZORDER"] =
{
    ["maze_farest"]           = 1,        --最远的背景图
    ["maze_far"]              = 2,        --远景
    ["maze_mid"]              = 3,        --中景
    ["shadow"]                = 4,        --阴影
    ["mercenary_and_monster"] = 5,        --佣兵和怪物
    ["maze_near"]             = 6,        --近景
    ["sword"]                 = 7,        --刀光
    ["tip"]                   = 8,        --提示

    ["maze_panel"]            = 99,        --maze panel
}

--mercenary_template_panel 实例的来源
client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"] =
{
    ["formation"] = 1,        --阵容
    ["list"] = 2,             --列表
    ["choose_to_battle"] = 3, --选择佣兵上阵
    ["transmigration"] = 4,   --转生
    ["contract"] = 5, --契约
    ["vanity_adventure_formation"] = 6, --虚空阵容
    ["vanity_adventure_list"] = 7, --虚空英雄列表
}
-- 资源跳转
client_constants["JUMP_CONST"] = 
{
----------一级界面---------------
    ["main"] = 1,  -- 主界面
    ["adventure"] = 2, --冒险界面
    ["mining"] = 3, --挖矿界面
    ["pvp"] = 4, --PVP界面
    ["summon"] = 5, --召唤界面
    ["mercenary"] = 6, --佣兵界面
    ["mining_shop"] = 7, -- 挖矿仓库界面
    ["pay"] = 8, --支付界面
    ["rune"] = 9, --符文界面
    ["friends"] = 10, --好友界面
    ["carnival"] = 11, --活动界面
    ["achievement"] = 12, --成就界面
    ["market"] = 13, --集市界面
    ["check_daily"] = 14, --签到界面
    ["mercenary_levelup_panel"] = 15, --佣兵经验分配界面
    ["guild_main"] = 16, --工会界面
    ["blood_diamond_shop"] = 17, -- 血钻商店界面 
-----------公会二级界面-----------------------------
    ["guild_boss"] = 18, --公会boss界面
----------公会三级界面-----------------
    ["guild_boss_shop"] = 19, --公会boss兑换商店界面
---------挖矿二级界面-----------------
    ["mining_area"] = 20,  --挖矿_矿区
    ["mining_work_shop"] = 21, --挖矿_工坊
    ["mining_Tub"] = 22, --挖矿_矿车
    ["mining_exploration"] = 23, --挖矿_地下探险
    ["mining_troll_lair"] = 24, --挖矿_巨魔巢穴
    ["mining_area_boss"] = 25, --挖矿_矿区BOSS
    ["mine_main"] = 26, --矿山
-----------符文二级界面--------------------
    ["rune_crystal"] = 30, --符文水晶获取界面(矿车拦截的界面)  
    ["rune_installation"] = 31, --符文安装界面
------------佣兵二级界面--------------------
    ["mercenary_dismissal"] = 40, --佣兵解雇界面
-----------PVP二级界面--------------------
    ["pvp_arena"] = 50,  --竞技场界面   
    ["pvp_qualifying"] = 51,   --排位赛   
    ["pvp_war"] = 52,   --合战兑换
    ["pvp_campaign"] = 53, --合战  
----------签到二级界面--------------------
    ["daily_prayer"] = 61, --每日祈祷   
    ["daily_lchemy"] = 62, --每日炼金   
----------佣兵经验分配界面二级界面--------
    ["mercenary_levelup_forge"] = 63, --佣兵经验界面   强化
    
----------PVP三级界面-----------------
    ["pvp_arena_exchange"] = 71, --竞技场兑换 

-----------------花费血钻替换材料------------------------
    ["blood_replace"] = 100, --血钻替换材料
}
client_constants.JUMP_CONST_TYPE = {}
for k,v in pairs(client_constants["JUMP_CONST"]) do 
    client_constants.JUMP_CONST_TYPE[v] = k  
end

client_constants["TITLE_STATE"] =
{
    ["can_active"] = 1, --可激活状态
    ["actived"] = 2,    --激活状态
    ["wear"] = 3,      --佩戴状态
}

client_constants ["WORLD_TAB_TYPE"] =
{
    ["main"]  = 1,
    ["adventure"]  = 2,
    ["mining"]  = 3,
    ["arena"]  = 4,
    ["recruit"]  = 5,
    ["mercenary"]  = 6,
}

client_constants["MAZE_TYPE_ICON"] =
{
    [1] = "icon/resource/exp_header.png",
    [2] = "icon/explore/mission_icon_gold.png",
    [3] = "icon/explore/mission_icon_item.png",
    [4] = "icon/explore/mission_icon_role.png",
    [5] = "icon/global/breaklimit.png",
}

client_constants["LIGHT_STAR"] = "icon/global/breaklimit.png"
client_constants["DARK_STAR"] = "icon/global/breaklimit_dark.png"

client_constants["BATTLE"] =
{
    ["left_troop_id"] = 1,
    ["right_troop_id"] = 2,

    ["background_x"] = 320,             --战斗场景的中心点
    ["background_y"] = 568,

    ["left_rune_x"] = 200,             --符文动画
    ["right_rune_x"] = 440,
    ["rune_y_init"] = 880,
    ["rune_y_offset"] = -140,

    ["background_width"] = 640,
    ["background_height"] = 1136,

    ["row_gap"]      = 78,
    ["col_gap"]      = 62,

    ["troop_offset_x"] = 31,

    ["left_troop_x"] = 236,
    ["left_troop_y"] = 389,

    ["right_troop_x"] = 404,
    ["right_troop_y"] = 389,

    ["role_shadow_offset"] = 34,

    ["role_shadow_scale"] = 0.4,

    ["death_action"] = 30000001,
    ["victory_action"] = 40000001,

    ["left_skill_name_x"] = 169,
    ["left_skill_name_y"] = 738,

    ["right_skill_name_x"] = 471,
    ["right_skill_name_y"] = 738,
}

client_constants["BATTLE_BACKGROUND"] =
{
    [1] = "res/battle_background/aircity.png",
    [2] = "res/battle_background/angel.png",
    [3] = "res/battle_background/cave.png",
    [4] = "res/battle_background/ether.png",
    [5] = "res/battle_background/fort.png",
    [6] = "res/battle_background/fight.png",
    [7] = "res/battle_background/forest.png",
    [8] = "res/battle_background/iceberg.png",
    [9] = "res/battle_background/mountain.png",
    [10] = "res/battle_background/ruins.png",
    [11] = "res/battle_background/oasis.png",
    [12] = "res/battle_background/path.png",
    [13] = "res/battle_background/plain.png",
    [14] = "res/battle_background/relic.png",
    [15] = "res/battle_background/spring.png",
    [16] = "res/battle_background/temple.png",
    [17] = "res/battle_background/time.png",
    [18] = "res/battle_background/volcano.png",

    ["fight_bg"] = 6
}

client_constants["BATTLE_STATUS"] =
{
    ["win"] = 1,
    ["lose"] = 2,
    ["draw"] = 3,
}

client_constants["BATTLE_TYPE"] =
{
    ["vs_monster"] = 1,
    ["vs_friend"] = 2,
    ["vs_ladder_player"] = 3,
    ["vs_arena_player"] = 4,
    ["vs_golem"]        = 5,
    ["vs_campaign"] = 6,
    ["vs_guild_player"] = 7,
    ["vs_escort_target"] = 8,
    ["vs_server_pvp"] = 9,
    ["vs_guild_boss"] = 10,
    ["vs_mine_rob_target"] = 11,
    ["vs_vanity"] = 12, --虚空大冒险
    ["vs_vanity_play_back"] = 13, --虚空大冒险回放
}

--混色
client_constants["LIGHT_BLEND_COLOR"] = 0xffffff
client_constants["DARK_BLEND_COLOR"]  = 0x7f7f7f

client_constants["SMALL_QUALITY_BG"] = "bg/activity_herobg.png"

--socail 面板类型
client_constants["SOCIAL_MSGBOX_TYPE"] =
{
    ["search_player_msgbox"] = 1,
    ["invite_player_msgbox"] = 2,
    ["deal_invitation_msgbox"] = 3,
}

client_constants["MERCENARY_CHOOSE_SHOW_MODE"] =
{
    ["formation"] = 1, --阵容
    ["material"] = 2,  --灵源
    ["acceptor"] = 3,  --灵主
    ["contract"] = 4,  --契约
    ["evolution"] = 5, --佣兵进化
    ["vanity_adventure"] = 6, --虚空进化
}

--mercenary_preview_panel 显示mod
client_constants["MERCENARY_PREVIEW_SHOW_MOD"] =
{
    ["formation"] = 1, --佣兵列表和阵容头部显示信息，一致
    ["mercenary_detail"] = 2,   --佣兵详情
    ["leader_detail"] = 3,      --主角详情
    ["compare"] = 4,            --佣兵对比框
    ["fire"] = 5,               --解雇
    ["list"] = 6,               --列表
}

--佣兵排序类型
client_constants["SORT_TYPE"] =
{
    ["bp"] = 1,
    ["wakeup"] = 2,
    ["quality"] = 3,
    ["level"] = 4,
    ["contract"] = 5,
    ["genre"] = 6,
    ["recommend"] = 7,           -- 上阵排序1
    ["recommend_by_skill"] = 8,  -- 上阵排序2
    ["strength"] = 9,  -- 强度
    ["passive_strength"] = 10, -- 被动强度
}

-- 佣兵排序范围
client_constants["SORT_RANGE"] = {
    ["quality1"] = 1,
    ["quality2"] = 2,
    ["quality3"] = 3,
    ["quality4"] = 4,
    ["quality5"] = 5,
    ["quality6"] = 6,
    ["all"] = 7,                -- 全部排序
    ["campaign"] = 8,           -- 合战特权排序
}


--世界面板显示模式
client_constants["WORLD_PANEL_SHOW_MODE"] =
{
    ["show_top"] = 1,
    ["show_bottom"] = 2,
    ["show_both"] = 3,
    ["hide_both"] = 4,
}

client_constants["MERCENARY_MSGBOX"] =
{
    ["weapon"] = 1,
    ["wakeup"] = 2,
    ["fire"]   = 3,
    ["upgrade_force"] = 4,
}
--佣兵角色icon路径
client_constants["MERCENARY_ROLE_IMG_PATH"] = "mercenary/"

--汉子字体
client_constants["FONT_FACE"] = "fonts/general.ttf"


--宝具icon
client_constants["ARTIFACT_ICON_PATH"] = "artifact/"
--技能为空时的背景
client_constants["SKILL_BG_IMG_PATH"] = "bg/skill/skill_20.png"

local ACTIVE_SKILL_EFFECT_TYPE = constants["ACTIVE_SKILL_EFFECT_TYPE"]
client_constants["ACTIVE_SKILL_ICON_PATH"] =
{
    [ACTIVE_SKILL_EFFECT_TYPE["melee_damage"]] = "bg/skill/skill_1.png",
    [ACTIVE_SKILL_EFFECT_TYPE["critical_damage"]] ="bg/skill/skill_2.png",
    [ACTIVE_SKILL_EFFECT_TYPE["increase_damage"]] ="bg/skill/skill_3.png",
    [ACTIVE_SKILL_EFFECT_TYPE["rage_damage"]] = "bg/skill/skill_4.png",
    [ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_bp"]] ="bg/skill/skill_5.png",
    [ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_init_bp"]] ="bg/skill/skill_6.png",
    [ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_loss_bp"]] ="bg/skill/skill_7.png",
    [ACTIVE_SKILL_EFFECT_TYPE["bp_steal"]] ="bg/skill/skill_8.png",
    [ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_bp"]] ="bg/skill/skill_9.png",
    [ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_init_bp"]] ="bg/skill/skill_10.png",
    [ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_bp"]] ="bg/skill/skill_11.png",
    [ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_init_bp"]] ="bg/skill/skill_12.png",
    [ACTIVE_SKILL_EFFECT_TYPE["true_damage"]] ="bg/skill/skill_13.png",
    [ACTIVE_SKILL_EFFECT_TYPE["copy_skill"]] ="bg/skill/skill_18.png",

    [ACTIVE_SKILL_EFFECT_TYPE["armageddon_a"]] ="bg/skill/skill_18.png",
    [ACTIVE_SKILL_EFFECT_TYPE["armageddon_b"]] ="bg/skill/skill_18.png",
    [ACTIVE_SKILL_EFFECT_TYPE["swap_bp_percent"]] ="bg/skill/skill_18.png",
}

local PASSIVE_SKILL_EFFECT_TYPE = constants["PASSIVE_SKILL_EFFECT_TYPE"]
client_constants["PASSIVE_SKILL_ICON_PATH"] =
{
    [PASSIVE_SKILL_EFFECT_TYPE["increase_speed"]] = "bg/skill/skill_14.png",
    [PASSIVE_SKILL_EFFECT_TYPE["increase_defense"]] = "bg/skill/skill_15.png",
    [PASSIVE_SKILL_EFFECT_TYPE["increase_dodge"]] = "bg/skill/skill_16.png",
    [PASSIVE_SKILL_EFFECT_TYPE["increase_authority"]] ="bg/skill/skill_17.png",
    [PASSIVE_SKILL_EFFECT_TYPE["convert_property"]] ="bg/skill/skill_17.png",
}
client_constants["NO_SKILL_BG_IMG_PATH"] = "icon/mercenarylist/skill_empty.png"

--宿命武器icon的路径
client_constants["DESTINY_WEAPON_IMG"] = "icon/destiny/weapon"
--宿命武器已装备的icon  对号
client_constants["EQUIPED_ICON_PATH"] = "icon/global/equipped.png"

client_constants["CONFIRM_MSGBOX_MODE"] =
{
    ["upgrade_bag"]             = 1, --解锁背包
    ["fire_mercenary"]          = 2, --解雇佣兵
    ["scout_guild_rival"]       = 3, --刺探公会对手
    ["recruit_mercenary"]       = 4, --招募()
    ["revive_mercenary"]        = 5, --复活英灵（即神殿招募）
    ["refresh_arena"]           = 6, --刷新竞技场
    ["refresh_order"]           = 7, --刷新订单
    ["exchange_reward"]         = 8, --竞技场内兑换奖品
    ["destroy_rock_purple"]     = 9, --紫金岩
    ["unlock_mining_project"]   = 10, --解锁工坊工程
    ["transmigration"]          = 11, --灵力转移
    ["use_tnt"]                 = 12, --使用雷管
    ["use_item"]                = 13, --使用特殊道具
    ["open_chest"]              = 14, --打开矿区宝箱
    ["buy_campaign_challenge"]  = 15, --增加合战次数
    ["revive_campaign"]         = 16, --复活合战战斗
    ["buy_campaign_buff"]       = 17, --兑换BUFF确认
    ["convert_campaign_reward"] = 18, --兑换奖励确认
    ["reset_golem_level"]       = 19, --重置巨魔等级
    ["carnival_token_exchange_reward"] = 20, --代币兑换奖品
    ["open_cave_boss"]          = 21, --恶魔勋章开启矿区BOSS
    ["buy_cave_challenge"]      = 22, --购买矿区战斗次数
    ["buy_guild_buff"]          = 23, --购买公会战buff
    ["buy_rune_bag_cell"]       = 24, --购买符文背包
    ["draw_rune_go_to_area_4"]  = 25, --抽取符文后直接跳至第四层
    ["refresh_rob_target_immediately"]  = 26, --运送矿车立刻刷新可拦截目标
    ["buy_escort_times"]        = 27, --购买运送次数
    ["refresh_tramcar"]         = 28, --刷新选择的矿车
    ["mine_unlock"]             = 29, --解锁矿山
    ["mine_refresh_use_blood_tips"] = 30, --矿山刷新是否使用血钻提示
    ["merchant_exchange"]       = 31, --黑市兑换提示
    ["mine_sure_unlock_tips"]   = 32, --矿山解锁提示
    ["draw_rune_use_blood_tips"]= 33, --自动消耗血钻提示
    ["buy_limite_use_blood_tips"]=34, --用血钻购买限时礼包提示
    ["rune_exchange_cost_msgbox"]=35, --符文转换消耗血钻提示
    ["clear_call_mercenary_tips"]=36, --使用血钻解除冷却时间
}

client_constants["CAMPAIGN_MSGBOX_MODE"] =
{
    ["campaign"] = 1,
    ["boss_cave"] = 2, --恶魔勋章挑战矿区BOSS
    ["normal_cave"] = 3 , --矿区副本挑战
    ["guild_boss"] = 4, --公会boss
}

client_constants["BATCH_MSGBOX_MODE"] =
{
    ["convert_campaign_reward"] = 1, -- 批量奖励兑换(赛点)
    ["blood_store"] = 2, -- 血钻商店
    ["exchange_reward"] = 3, -- 王者兑换
    ["guild_exchange_reward"] = 4, -- 公会兑换
    ["escort_buy_rob_times"] = 5, -- 运送：购买拦截次数
    ["server_pvp_buy_times"] = 6, -- 跨服PVP：购买挑战次数
    ["guild_boss_exchange_reward"] = 7, --公会贡献度兑换
    ["guild_boss_tickets_reward"] = 8,  --公会boss门票兑换
    ["rune_bag_numbers"] = 9, --符文背包格子购买
    ["mine_buy_rob_times"] = 10, --矿山掠夺次数
    ["mine_buy_refresh_times"] = 11, --矿山刷新次数
    ["ladder_tower_buy_refresh_times"] = 12, --天梯赛刷新次数
    ["ladder_tower_fighting_times"] = 13,   --天梯赛战斗次数
    ["vanity_adventure_Exchange_reward"] = 14, --虚空积分兑换
}

client_constants["MERCENARY_DETAIL_MODE"] =
{
    ["formation"] = 1,
    ["list"]      = 2,
    ["fire"]      = 3,
    ["temple"]    = 4,
    ["exchange_reward"] = 5,
    ["recruit"] = 6,
    ["library"] = 7,
    ["icon_template"] = 8,
    ["loot_preview"] = 9,
}

client_constants["REWARD_PANEL_TYPE"] =
{
    ["no_reward"]           = 0,     --没有奖励
    ["get_item"]            = 1,     --给予资源或者道具
    ["special"]             = 2,     --非资源奖励，比如开启新地图，增加饱腹度，升级十字镐，战力提升，出战位提升
    ["mercenary"]           = 3,     --给予mercenary
    ["use_item"]            = 4,     --使用道具
    ["unlock_new_features"] = 5,     --开启新的功能
}

client_constants["SPECIAL_REWARD_TYPE_IMG_PATH"] =
{
    ["add_bp"] = "icon/explore/specialreward_fight.png",
    ["pickaxe"] = "icon/explore/specialreward_pick.png",
    ["add_max_explorer"] = "icon/explore/specialreward_array.png",
}

--佣兵角色背景图片 对应佣兵品质
client_constants["MERCENARY_BG_SPRITE"] =
{
    ["cancel"] = "bg/herolist_cancelbg.png",
    ["empty"]  = "bg/herolist_bgempty_d.png",
    ["formation_vacant"] = "bg/heroformation_bgempty_d.png",

    [1] = "bg/herolist_bg1.png",
    [2] = "bg/herolist_bg2.png",
    [3] = "bg/herolist_bg3.png",
    [4] = "bg/herolist_bg4.png",
    [5] = "bg/herolist_bg5.png",
    [6] = "bg/herolist_bg6.png",
    [7] = "bg/herolist_bg7.png",
    [8] = "bg/herolist_bg8.png",
    [9] = "bg/herolist_bg9.png",
    [10] = "bg/herolist_bg10.png",
    [11] = "bg/herolist_bg11.png",
    [12] = "bg/herolist_bg12.png",

    [99] = "bg/herolist_bg1.png",
}

client_constants["SOUL_BONE_SPRITE"] =
{

    [1] = "icon/resource/soul01.png",
    [2] = "icon/resource/soul02.png",
    [3] = "icon/resource/soul03.png",
    [4] = "icon/resource/soul04.png",
    [5] = "icon/resource/soul05.png",
    [6] = "icon/resource/soul06.png",
}

local PROPERTY_TYPE = constants["PROPERTY_TYPE"]
client_constants["MERCENARY_PROPERTY_ICON"] =
{
    [PROPERTY_TYPE["speed"]] = "icon/mercenarylist/fightnumber_4.png",
    [PROPERTY_TYPE["dodge"]] = "icon/mercenarylist/fightnumber_2.png",
    [PROPERTY_TYPE["defense"]] = "icon/mercenarylist/fightnumber_3.png",
    [PROPERTY_TYPE["authority"]] = "icon/mercenarylist/fightnumber_1.png",
}

client_constants["MERCENARY_FIGHTING_ICON"] = "icon/mercenarylist/fighting_capacity.png"

client_constants["TEXT_QUALITY_COLOR"] =
{
    [1] = 0xe5e5e5,
    [2] = 0xcceb0c,
    [3] = 0x69a6f9,
    [4] = 0xb274ff,
    [5] = 0xecc800,
    [6] = 0xffde00,
    [7] = 0x7d7344,
    [99] = 0xe5e5e5,
}

client_constants["BG_QUALITY_COLOR"] =
{
    [1] = 0xffffff,
    [2] = 0xbdec4d,
    [3] = 0x4daaec,
    [4] = 0xcc86ec,
    [5] = 0xecc800,
    [6] = 0xffde00,
    [99] = 0xffffff,
}
client_constants["GIFT_ICON_PATH"] = "icon/global/gift.png"
client_constants["PAYMENT_ICON_PATH"] = "icon/resource/rmb.png"

client_constants["UNIT"] =
{
    ["K"] = 1000,
    ["M"] = 1000000,
    ["B"] = 1000000000,
}

client_constants["MERCENARY_TO_FORMATION"] =
{
    ["rest"]        = 1,
    ["replace"]     = 2,
    ["add"]         = 3,
    ["moving"]      = 4,
    ["recommend"]   = 5,
}

client_constants["NOVICE_TRIGGER_TYPE"] =
{
    ["solve_event"] = 1,
    ["create_leader"] = 2,
    ["first_use_feature"] = 3,
    ["first_discover_golem"] = 4,
    ["first_battle_failure"] = 5,
    ["first_open_panel"] = 6,
}

client_constants["NOVICE_TYPE"] =
{
    ["animation"] = 1,--动画
    ["text"] = 2,--文本
    ["dialogue"] = 3,--对话
    ["talker"] = 4,--对话头像
    ["open_panel"] = 5,--打开界面
    ["open_sub_scene"] = 6,--场景
    ["sim_levelup"] = 7,--模拟升级
    ["sim_dig_block"] = 8,--模拟升级
    ["sim_battle"] = 9,--模拟战斗
    ["sim_enter_maze"] = 10,--模拟进入下一关
    ["sim_touch"] = 11,--模拟点击
    ["network_sync"] = 12,--网路同步
}

client_constants["MERCENARY_MAX_PANEL_ROW"] = 8   --最大row
client_constants["MERCENARY_MAX_PAGE_NUM"] = 40   --一屏显示的最大佣兵个数
client_constants["MERCENARY_SUB_PANEL_BEGIN_X"] = 72   --佣兵显示的初始位置x
client_constants["MERCENARY_SUB_PANEL_BEGIN_Y"] = 700  --佣兵显示的初始位置y
client_constants["MERCENARY_SUB_PANEL_HEIGHT"] = 124
client_constants["MERCENARY_FIRST_SUB_PANEL_OFFSET"] = -70

--解锁阵容中空位置的关卡id
client_constants["UNLOCAK_FOTMATION_CAPACITY_MAZE"] =
{
    [5]  = 100012,
    [8]  = 100022,
    [11] = 100033,
    [14] = 100045,
    [17] = 100061,

    [20] = 100301,
    [21] = 100331,
    [22] = 100361,
    [23] = 100391,
    [24] = 100421,
}

client_constants["FORMATION_PANEL_MODE"] =
{
    ["multi"] = 1,
    ["quest"] = 2,
    ["guild"] = 3,
    ["server_pvp"] = 4,
    ["mine"] = 5, --矿山防守整容
}

--显示在背包里的资源
client_constants["RESOURCE_SHOW_BAG"] =
{
    ["soul_chip"] = 1,  --灵魂碎片
    ["king_medal"] = 2, --王者之章
    ["saint_cross"] = 3,--圣十字
    ["blue_skull"] = 4,--幽蓝头颅
    ["lava_heart"] = 5,--熔岩之心
    ["icha_paradise"] = 6,--亲热天堂
    ["vital_essence"] = 7,--生命精华

    ["chest_key1"] = 8,--黏土钥匙
    ["chest_key2"] = 9,--白银钥匙
    ["chest_key3"] = 10,--恶魔钥匙
    ["contract_stone"] = 11, --契约石
    ["forge_ticket"] = 12, --宝具券

    ["senior_soul_crystal1"] = 13,
    ["senior_soul_crystal2"] = 14,

    ["mine_stone1"] = 15,
    ["mine_stone2"] = 16,
    ["mine_stone3"] = 17,
    ["mine_stone4"] = 18,
    ["mine_stone5"] = 19,
    ["mine_stone6"] = 20,
    ["mine_stone7"] = 21,
    ["mine_stone8"] = 22,
    ["mine_stone9"] = 23,
    ["mine_stone10"] = 24,
    ["mine_stone11"] = 25,
    ["mine_stone12"] = 26,
    ["mine_stone13"] = 27,
    ["mine_stone14"] = 28,
    ["mine_stone15"] = 29,
    ["mine_stone16"] = 30,
    ["mine_stone17"] = 31,
    ["mine_stone18"] = 32,
    ["mine_stone19"] = 33,
    ["mine_stone20"] = 34,
    ["mine_stone21"] = 35,
    ["mine_stone22"] = 36,
    ["mine_stone23"] = 37,
    ["mine_stone24"] = 38,
    ["mine_stone25"] = 39,
    ["mine_stone26"] = 40,
    ["mine_stone27"] = 41,
    ["mine_stone28"] = 42,
    ["mine_stone29"] = 43,
    ["mine_stone30"] = 44,
    ["mine_stone31"] = 45,
    ["share_integral"] = 46,
    ["purple_soul"]  = 47,          --紫色灵魂碎片
    ["gold_soul"]  = 48,            --金色灵魂碎片
    ["flash_gold_soul"]  = 49,      --闪金灵魂碎片
}

client_constants["RESOURCE_SHOW_BAG_TYPE_NAME"] = {}
for k, v in pairs(channel_constants["RESOURCE_SHOW_BAG"]) do
    client_constants["RESOURCE_SHOW_BAG_TYPE_NAME"][v] = k
end

client_constants["DEFAULT_QUALITY"] = 99
client_constants["RESOURCE_SHOW_BAG_MAX_NUM"] = 60

client_constants["CRAFT_COST_RESOURCE"] =
{
    "saint_cross",
    "blue_skull",
    "lava_heart",
    "vital_essence",
    "icha_paradise",
    "gold_coin",
    "soul_chip",
    "purple_soul",
    "gold_soul",
    "flash_gold_soul"
}

--冒险中事件状态
client_constants["ADVENTURE_MAZE_EVENT_STATUS"] = {
    ["not_exist"]                   = 0, --没有此事件
    ["not_start_explore"]           = 1, --未开始探索的事件
    ["is_exploring"]                = 2, --正在探索的事件
    ["explored_but_not_solve"]      = 3, --探索完毕的事件，但未解决的事件
    ["solved"]                      = 4, --解决完毕的事件
}
-- 合战特权属性图标
client_constants["CAMPAIGN_PROPERTY_ICON"] = {
    [1] = "icon/mercenarylist/fighting_capacity.png", --战力图标
    [2] = "icon/mercenarylist/fightnumber_4.png", --速度图标
    [3] = "icon/mercenarylist/fightnumber_3.png", --防御图标
    [4] = "icon/mercenarylist/fightnumber_2.png", --闪避图标
    [5] = "icon/mercenarylist/fightnumber_1.png", --王者图标
}

client_constants["CAMPAIGN_RESOURCE_ICON"] = {
    ["exp"] = "icon/resource/gassen_exp.png",

    ["rank"] = "icon/global/ladder_numicon.png",
    ["score"] = "icon/resource/gassen_point.png",
    ["battle"] = "icon/global/fight_globalicon.png",
    ["boss_tick"] = "icon/resource/demon_medal2.png"
}

client_constants["CAMPAIGN_TOWER_POSITION"] = {
    [1] = {63,65},
    [2] = {163,105},
    [3] = {258,145},
    [4] = {353,185},
    [5] = {448,225},
}

client_constants["MAIL_LIST_TYPE"] = {
    ["system_not_read"] = 1,
    ["system_already_read"] = 2,
    ["friend_not_read"] = 3,
    ["friend_already_read"] = 4,
}

client_constants["MAIL_PANEL_TYPE"] =
{
    ["system"] = 1,
    ["friend"] = 2,
}

-- 公会通知文本索引
client_constants["MAIL_TYPE_TEXT"] = {
    [1] = "guild_dismiss_notify",
    [2] = "guild_fire_notify",
}

client_constants["MAIL_SOURCE_TEXT"] = {
    [1] = "mail_gm_system_maintenance",
    [2] = "mail_ladder_reward",
    [3] = "mail_gm_payment_notify",
    [4] = "campaign_mail_werite",
    [5] = "guild_notice_title",
    [6] = "mail_bag_full",
    [7] = "rune_bag_full",
    [8] = "mail_guild_war_reward",
    [9] = "kf_pvp",
    [10] = "kf_pvp_top_server",
    [11] = "kf_pvp_daily",
    [12] = "guild_boss",
    [13] = "expedition_rank",
    [14] = "expedition_fight",
}

client_constants["MINING_REFRESH_ICON"] =
{
    golem = "icon/resource/golem.png"
}

--icon 模板
client_constants["ICON_TEMPLATE_MODE"] =
{
    ["with_text1"] = 1,    --带文本 1
    ["with_text2"] = 2,    --带文本 2
    ["no_text"] = 3,       --不带文本
}

client_constants["MERCENARY_GENRE_TEXT"] =
{
    [1] = "mercenary_genre1",
    [2] = "mercenary_genre2",
    [3] = "mercenary_genre3",
    [4] = "mercenary_genre4",
}

client_constants["MERCENARY_GENRE_COLOR"] =
{
    [1] = 0xE5512E,
    [2] = 0xBAD633,
    [3] = 0x5BD8F4,
    [4] = 0xFFFFFF,
}

client_constants["SORT_PANEL_SOURCE"] = {
    ["list"] = 1,
    ["choose"] = 2,
    ["library"] = 3,
}

client_constants["DAILY_PANEL_TRANSLATE_TIME"] = 0.3
client_constants["DAILY_PANEL_LOADING_TIME"] = 0.3

client_constants["DAILY_TYPE"] =
{
    ["check_in"] = 1,   -- 签到
    ["prayer"] = 2,     -- 祈祷
    ["alchemy"] = 3,    -- 炼金
    ["activity"] = 4,   -- 活跃度
}

client_constants["MINING_NORMAL_CAVES"] = {
    ["ether_cave"] = 1,
    ["monster_cave"] = 2,
}

client_constants["FEATURE_TYPE"] =
{
    ["alloc_exp"] = 1, --升级
    ["mercenary"] = 2, --佣兵按钮
    ["fire"] = 3,      --解雇
    ["explore_box"] = 4, --探索宝箱
    ["recruit"] = 5,    --招募按钮
    ["destiny_weapon"] = 6, --宿命武器
    ["mining"] = 7,   --矿区按钮
    ["forge"] = 8,   --强化
    ["arena"] = 9,   --竞技场
    ["wakeup"] = 10,   --觉醒按钮
    ["temple"] = 11,   --神殿
    ["ladder"] = 12,   --天梯
    ["merchant"] = 13, --商会
    ["quarry"] = 14,   --工坊
    ["bbs"] = 15,      --发帖
    ["guild"] = 16,    --公会
    ["campaign"] = 17, --合战
    ["magic"] = 18,    --秘术
    ["mining_explore"] = 19, --地下探险
    ["mining_golem"] = 20,   --巨魔巢穴
    ["mining_boss"] = 21,    --巨魔BOSS
    ["quick_adventure"] = 22,    --快速战斗
    ["escort_and_rune"] = 23,    --符文
    ["mining_random_event"] = 24, --矿区随机事件
    ["mine_and_cultivation"] = 25, --矿山和修炼
    ["chat_world"] = 26, --聊天系统
    ["title"] = 27, --称号系统
    ["vanity_adventure"] = 28, --虚空大冒险
}

client_constants["NOVICE_MARK"] = {
    ["mercenary_formation_panel"] = 1,     -- 推荐上阵
    ["transmigration_sub_scene"] = 2,      -- 灵力转移
    ["mercenary_contract_sub_scene"]  = 3, -- 契约进化
    ["mercenary_library_sub_scene"] = 4,   -- 图鉴
    ["pvp_sub_scene"] = 5,                 -- pvp
    ["first_wakeup"] = 6,                  --第一次觉醒
    ["first_forge"]  = 7,                  --第一次锻造
    ["first_discover_golem"] = 8,          --第一次发现巨魔
    ["first_battle_failure"] = 9,          --第一次战斗失败
    ["first_recruit"] = 10,                --第一次招募
}

--修改名字
client_constants["RENAME_PANEL_MODE"] = {
    ["user"] = 1,
    ["formation"] = 2,
}

client_constants["NOTICE_PANEL_MODE"] = {
    ["notice"] = 1,
    ["invitation"] = 2,
}

-- 合战特权属性图标
client_constants["GUILDWAR_GENRE_ICON"] = {
    [1] = "icon/guildwar/sente_crit_icon.png", --先攻暴击
    [2] = "icon/guildwar/recovery_icon.png", --回复
    [3] = "icon/guildwar/king_pure_icon.png", --王者纯粹
    [4] = "icon/guildwar/fiddle_icon.png",  --其他
}

client_constants["NO_WAR_FIELD"] = 0

client_constants["SOCIAL_EVENT_SHOW_TYPE"] = {
    ["friend"] = 1,
    ["guild_member"] = 2,
    ["ladder_tower_member"] = 3, --天梯赛敌人信息
}

client_constants["MEMBER_SORT_TYPE"] = {
    ["login_time"] = 1,
    ["score"] = 2,
}

client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"] = 
{
    ["view"] = 1,
    ["buy_buff"] = 2,
}

client_constants["GUILDWAR_TIP_STATUS"] = {
    ["none"] = 1,
    ["ready"] = 2,
    ["enter"] = 3,
    ["wait_troop"] = 4,
    ["matching"] = 5,
    ["wait_finish"] = 6,
}

client_constants["CLIENT_GUILDWAR_STATUS_TIME_NAME"] = {
    [1] = "start_time",
    [2] = "ready_end_time",
    [3] = "enter_end_time",
    [4] = "set_troop_end_time",
    [5] = "match_end_time",
    [6] = "fight_end_time",
}

client_constants["CLIENT_GUILDWAR_STATUS"] = {
    ["NONE"] = 1,           --休战
    ["READY"] = 2,          --准备
    ["WAIT_ENTER"] = 3,     --报名
    ["WAIT_TROOP"] = 4,     --上阵
    ["MATCHING"] = 5,       --匹配
    ["WAIT_FINISH"] = 6,    --等待结束
}

client_constants["MAX_GUILD_BATTLE_ROLE_NUM"] = 8

client_constants["SCOUT_TROOP_SHOW_TYPE"] = {
    ["VIEW"] = 0,
    ["ARM"] = 1,
}

--符文抽取平台图片
client_constants["DRAW_PLATFORM_SPRITE"] = {
    [1] = "entrust/stone001.png",
    [2] = "entrust/stone002.png",
    [3] = "entrust/stone003.png",
    [4] = "entrust/stone004.png",
    [5] = "entrust/stone005.png",
}

--符文背包类型
client_constants["RUNE_BAG_SHOW_TYPE"] = {
    ["PACKAGE"] = 1,
    ["EQUIP"] = 2,
    ["SELECT_ONE"] = 3,
    ["SELECT_MUILT"] = 4,
    ["EXCHANGE"] = 5,
}

client_constants["TEXT_COLOR"] = {
    ["write"] = 0xffffff,
    ["green"] = 0xa7c71e,
    ["orange"] = 0xd3a70d,
    ["red"] = 0xc45d1d,
    ["brown"] = 0xae8b12,
    ["gray"] = 0x7f7f7f,
    ["yellow"] = 0xffda1b,
}

client_constants["RUNE_TEXT_QUALITY_COLOR"] = {
    [1] = 0xffffff,
    [2] = 0xc7ef5a,
    [3] = 0x82dbff,
    [4] = 0xd381ff,
    [5] = 0xe7d432,
    [6] = 0xffce39,
}

--跨服PVP图片缩放比例
client_constants["SERVER_PVP_TOWER_SCALE"] = 2

--跨服PVP塔图片
client_constants["SERVER_PVP_TOWER_SPRITE"] = {
    ["bottom"] = "tower/tower_01.png",
    ["middle"] = "tower/tower_02.png",
    ["cloud"] = "tower/tower_04.png",
    ["space"] = "tower/space02.png",
    ["line"] = "tower/suolian.png",

    ["space_bg_top"] = "tower/color_high.png",
    ["space_bg_middle"] = "tower/color_middle.png",
    ["space_bg_bottom"] = "tower/color_low.png",
}

client_constants["SERVER_PVP_TOWER_PRICK_SPRITE"] = {
    [1] = "tower/tower_09.png",
    [2] = "tower/tower_10.png",
}

client_constants["SERVER_PVP_TOWER_PART_SPRITE_INFO"] = {
    [1] =   {
                sprite = "tower/tower_05.png",
                pos_x = -5,
                pos_y = 28,
            },
    [2] =   {
                sprite = "tower/tower_06.png",
                pos_x = -127,
                pos_y = 35,
            },
    [3] =   {
                sprite = "tower/tower_07.png",
                pos_x = -112,
                pos_y = 19,
            },
    [4] =   {
                sprite = "tower/tower_08.png",
                pos_x = -125,
                pos_y = 25,
            },
}

client_constants["SERVER_PVP_TOWER_HEIGHT"] = {
    ["top_1"] = 270,
    ["top_2"] = 50,
    ["top_3"] = 245,
    ["top_4"] = 120,
    ["top_5"] = 120,
    ["top_6"] = 120,
    ["top_7"] = 120,
    ["top_8"] = 120,
    ["top_9"] = 120,
    ["top_10"] = 120,
    ["top_11"] = 350,

    ["bottom"] = 376,
    ["middle"] = 141,
    ["top"] = 450,
    ["cloud"] = 300,
}

client_constants["JUMP_CONSTANCE"] = {
    ["jump_list_margin"] = 20, 
}

--TAG:MASTER_MERGE BEG
--主界面邮箱动画的位置
client_constants["MAIN_SUB_SCENE_MAIL_BOX_POS"] = { x = 550, y = 618 }

--Loading界面菊花动画的皮肤数量
client_constants["LOADING_SPINE_SKIN_NUM"] = 8

--bbs字数限制
client_constants["BBS_MAX_WORD_NUM"] = 90

--竞技界面间隔
client_constants["PVP_MAIN_SUB_PANEL_OFFSET_POS_Y"] = 113

client_constants["MINING_BOSS_RULE"] = {
    [1] = {level = "1-4",  reward_type = "2|2|1", reward_id = "3|4|10000002"},
    [2] = {level = "5-7",  reward_type = "2|2|2", reward_id = "12|13|28"},
    [3] = {level = "8-10", reward_type = "2|2|2|1", reward_id = "3|4|18|11000002"},
    [4] = {level = "11-13", reward_type = "2|2|2|1", reward_id = "3|4|28|10000006"},
    [5] = {level = "14-16", reward_type = "2|2|2|1", reward_id = "12|13|23|10000009"},
    [6] = {level = "17-25", reward_type = "2|2|2|2|2|2|2", reward_id = "12|13|23|30|31|32|33"},
    [7] = {level = "26-28", reward_type = "2|2|2|2|2|2|2",reward_id = "30 |31|32|33|3|4|24"},
    [8] = {level = "29-31", reward_type = "2|2|2|2|2|2|2|2|2|2",reward_id = "30|31|32|33|3|4|12|13|23|24"},
}

client_constants["RANDOM_KEY_ICON"] = "icon/resource/key4.png"

client_constants["QUICK_STORE_MSGBOX_TYPE"] = {
    ["rune_more_ten"] = 1,  --多次十连抽
}

client_constants["MINE_STATE"] = {
    ["lock"] = 0,       --//未解锁
    ["ready"] = 1,        --//待开采（空闲）
    ["mining"] = 2,       --//开采中
    ["finish"] = 3,       --//完成（待领奖）
}

client_constants["TIMES_TYPE"] = {
    ["rob_times"] = "remain_rob",   --掠夺次数
    ["refresh_target_times"] = "remain_refresh_target",  --刷新玩家次数
    ["ladder_tower_fighting_times"] = "ladder_tower_fighting_times", --天梯赛战斗次数
    ["ladder_tower_buy_refresh_times"] = "ladder_tower_buy_refresh_times", --天梯赛刷新次数
}

client_constants["ROB_TYPE"] = {
    ["rob"] = "rob",        --//掠夺
    ["steal"] = "steal",      --//偷窃
    ["revenge"] = "revenge",    --//复仇
}

client_constants["ReportType"] = {
    ["start_mine"] = "start_mine",        --//开始开采
    ["receive_reward"] = "receive_reward",      --//守缺奖励
    ["be_rob"] = "be_rob",    --//被掠夺
    ["be_steal"] = "be_steal",    --//被偷窃
    ["be_revenge"] = "be_revenge",    --//被复仇
    ["additional_reward"] = "additional_reward",  --特殊奖励
    ["cancel_mine"] = "cancel_mine", --取消开采
}

client_constants["MINE_TYPE_IMG_PATH"] = {
    "entrust/mine_002.png",
    "entrust/mine_003.png",
    "entrust/mine_004.png",
    "entrust/mine_005.png",
    "entrust/mine_006.png"
}

client_constants["QUALITY_TYPE"] = {
    ["quality1"] = 1,
    ["quality2"] = 2,
    ["quality3"] = 3,
    ["quality4"] = 4,
    ["quality5"] = 5,
    ["quality6"] = 6,
}

client_constants["EVOLUTION_UNLOCK_TYPE"] = {
    use = 1,
    unlock = 2,
}

client_constants["MINE_ICON_IMG_PATH"] = "icon/global/ore_picks.png"

client_constants["MINING_MINE_ANIMATION_POS_Y"] = 2777

client_constants["LADDER_LEVEL_L_IMG_TYPE"] = {
    "entrust/lv1_L.png",
    "entrust/lv2_L.png",
    "entrust/lv3_L.png",
    "entrust/lv4_L.png",
    "entrust/lv5_L.png",
    "entrust/lv6_L.png",
}

client_constants["LADDER_LEVEL_S_IMG_TYPE"] = {
    "entrust/lv1_S.png",
    "entrust/lv2_S.png",
    "entrust/lv3_S.png",
    "entrust/lv4_S.png",
    "entrust/lv5_S.png",
    "entrust/lv6_S.png",
}

client_constants["LADDER_LEVEL_REWARD_BG_COLOR"] = {
    0x49AF60,
    0xBCCFF0,
    0xE5CD54,
    0x73C4C3,
    0xF29652,
    0xFF8282, 
}

client_constants["CHAT_IMG_PATH"] = {
    ["微笑"] = "expression/15.png",
    ["睡觉"] = "expression/11.png",
    ["大哭"] = "expression/03.png",
    ["发怒"] = "expression/05.png",
    ["呲牙"] = "expression/04.png",
    ["偷笑"] = "expression/09.png",
    ["悠闲"] = "expression/08.png",
    ["擦汗"] = "expression/10.png",
    ["抠鼻"] = "expression/14.png",
    ["坏笑"] = "expression/20.png",
    ["哼哼"] = "expression/01.png",
    ["鄙视"] = "expression/02.png",
    ["委屈"] = "expression/16.png",
    ["阴险"] = "expression/19.png",
    ["惊讶"] = "expression/07.png",
    ["旁观"] = "expression/13.png",
    ["滑稽"] = "expression/06.png",
    ["吐血"] = "expression/12.png",
    ["忍笑"] = "expression/17.png",
    ["捂脸"] = "expression/18.png",
}

return channel_constants
--TAG:MASTER_MERGE END