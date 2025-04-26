local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local client_constants = {}

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
    ['rank'] = 1, --排名
    ['stage'] = 2, --阶段
    ['display'] = 3, --展示(道具，资源，代币或者佣兵)，首充展示奖励啊，收集道具展示道具的收集进度啊等， 代币兑换等
    ['text'] = 4, --纯文本展示
    ['discount'] = 5, --优惠信息
    ['multi_token'] = 6, --多种兑换多种奖励
    ['evolution'] = 7, --合成佣兵
    ['fund'] = 8,

    ['limite_package'] = 88,
    ['sns_invitation'] = 89,
    ["evolution_intro"] = 90,
    ["spring_lottery"] = 91, --新春红包
    ["christmas"] = 92,
    ["version_update"] = 93, --更新
    ['first_payment'] = 94,
    ['time_limit_store'] = 95,
    ['friendship'] = 96,
    ['transmigrate'] = 97,
    ['magic_door'] = 98,
    ['cdkey'] = 99, --礼包码
}

--活动奖励显示类型
client_constants["CARNIVAL_REWARD_TYPE"] =
{
    ["permanent"] = 1, --永久性 只能领取一次
    ['single'] = 2, --活动只有一个奖励
    ['multi'] = 3, --多个奖励
    ['token'] = 4, --代币活动奖励
    ['multi_token'] = 5, --搜集多个代币
    ['vote'] = 6, --投票
}

--carnival_reward_panel 类型
client_constants["CARNIVAL_REWARD_PANEL_TYPE"] =
{
    ["rank"] = 1, --佣兵排名
    ['collect'] = 2, --兑换
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
}

--mercenary_preview_panel 显示mod
client_constants["MERCENARY_PREVIEW_SHOW_MOD"] =
{
    ["formation"] = 1, --佣兵列表和阵容头部显示信息，一致
    ["mercenary_detail"] = 2,   --佣兵详情
    ["leader_detail"] = 3,      --主角详情
    ["compare"] = 4,            --佣兵对比框
    ['fire'] = 5,               --解雇
    ['list'] = 6,               --列表
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
    ["passive_strength"] = 10 -- 被动强度
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

local ACTIVE_SKILL_EFFECT_TYPE = constants.ACTIVE_SKILL_EFFECT_TYPE
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

local PASSIVE_SKILL_EFFECT_TYPE = constants.PASSIVE_SKILL_EFFECT_TYPE
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
    ["open_cave_boss"] = 21, --恶魔勋章开启矿区BOSS
    ["buy_cave_challenge"] = 22, --购买矿区战斗次数
    ["buy_guild_buff"]          = 23, --购买公会战buff
    ["buy_rune_bag_cell"]       = 24, --购买符文背包
    ["draw_rune_go_to_area_4"]  = 25, --抽取符文后直接跳至第四层
    ["refresh_rob_target_immediately"]  = 26, --运送矿车立刻刷新可拦截目标
    ["buy_escort_times"]        = 27, --购买运送次数
    ["refresh_tramcar"]         = 28, --刷新选择的矿车
}

client_constants["CAMPAIGN_MSGBOX_MODE"] =
{
    ["campaign"] = 1,
    ["boss_cave"] = 2, --恶魔勋章挑战矿区BOSS
    ["normal_cave"] = 3 , --矿区副本挑战
}

client_constants["BATCH_MSGBOX_MODE"] =
{
    ["convert_campaign_reward"] = 1, -- 批量奖励兑换(赛点)
    ["blood_store"] = 2, -- 血钻商店
    ["exchange_reward"] = 3, -- 王者兑换
    ["guild_exchange_reward"] = 4, -- 公会兑换
    ["escort_buy_rob_times"] = 5, -- 运送：购买拦截次数
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

local BLOCK_TYPE = constants["BLOCK_TYPE"]
local BLOCK_SPRITE_PATH = "block/"

local t2 = {}
local t3 = {}

local t = {}
for i, v in ipairs({"empty", "soil", "soil_hard",  "lava_crust", "harder_rock"}) do
    local block_type = BLOCK_TYPE[v]
    t[block_type] = BLOCK_SPRITE_PATH .. v
end
client_constants["RANDOM_BLOCK_SPRITE"] =  t

t = {}
for i, v in ipairs({"gem_red", "gem_purple", "gem_green", "gem_yellow", "rock_purple_gold", "titan_iron", "diamond", "diamond_sterling", "copper", "tin", "tin_better", "tin_sterling",
    "iron", "iron_better", "iron_sterling", "silver", "silver_better", "silver_sterling", "gold", "gold_better", "gold_sterling",
    "golem", "golem_nightmare", "red_king", "green_king", "light_king", "dark_king", "golem_dark", "ether_hunting_group",
    "earth_angel", "time_emissary", "doom_lord", "chest1", "chest2", "chest3", "chest4", "chest5", "chest6", "seven_doom", "fountain_god", "hard_rock", "rock", }) do

    local b = string.find(v, "_better")
    local block_type = BLOCK_TYPE[v]
    if b then
        t[block_type] = BLOCK_SPRITE_PATH .. string.sub(v, 1, b-1)
        t3[block_type] = true

    else
        local b = string.find(v, "_sterling")
        if b then
            t[block_type] = BLOCK_SPRITE_PATH .. string.sub(v, 1, b-1)
            t2[block_type] = true

        else
            t[block_type] = BLOCK_SPRITE_PATH .. v
        end
    end
end

client_constants["FIX_BLOCK_SPRITE"] = t

client_constants["STERLING_BLOCK"] = t2
client_constants["BETTER_BLOCK"] = t3

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
}

client_constants["RESOURCE_SHOW_BAG_TYPE_NAME"] = {}
for k, v in pairs(client_constants["RESOURCE_SHOW_BAG"]) do
    client_constants["RESOURCE_SHOW_BAG_TYPE_NAME"][v] = k
end

client_constants["DEFAULT_QUALITY"] = 99
client_constants["RESOURCE_SHOW_BAG_MAX_NUM"] = 30

client_constants["CRAFT_COST_RESOURCE"] =
{
    "saint_cross",
    "blue_skull",
    "lava_heart",
    "vital_essence",
    "icha_paradise",
    "gold_coin",
    "soul_chip",
    "contract_stone",
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
    [1] = lang_constants:Get("mercenary_genre1"),
    [2] = lang_constants:Get("mercenary_genre2"),
    [3] = lang_constants:Get("mercenary_genre3"),
    [4] = lang_constants:Get("mercenary_genre4"),
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

--符文抽取平台图片
client_constants["DRAW_PLATFORM_SPRITE"] = {
    [1] = "rune/stone001.png",
    [2] = "rune/stone002.png",
    [3] = "rune/stone003.png",
    [4] = "rune/stone004.png",
    [5] = "rune/stone005.png",
}

--符文背包类型
client_constants["RUNE_BAG_SHOW_TYPE"] = {
    ["PACKAGE"] = 1,
    ["EQUIP"] = 2,
    ["SELECT_ONE"] = 3,
    ["SELECT_MUILT"] = 4,
}

client_constants["TEXT_COLOR"] = {
    ["write"] = 0xffffff,
    ["green"] = 0xa7c71e,
    ["orange"] = 0xd3a70d,
    ["red"] = 0xc45d1d,
    ["brown"] = 0xae8b12,
    ["gray"] = 0x7f7f7f,
}

client_constants["RUNE_TEXT_QUALITY_COLOR"] = {
    [1] = 0xffffff,
    [2] = 0xc7ef5a,
    [3] = 0x82dbff,
    [4] = 0xd381ff,
    [5] = 0xe7d432,
    [6] = 0xffce39,
}

return client_constants
