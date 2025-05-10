local constants = {}

constants["RESOURCE_TYPE"] =
{

    ["gold_coin"] = 1,--金币
    ["blood_diamond"] = 2,--血钻
    ["soul_chip"] = 3,  --灵魂碎片
    ["king_medal"] = 4, --王者之章
    ["demon_medal"] = 5, --恶魔徽章
    ["adventure_medal"] = 6, --冒险徽章

    ["copper"] = 7,--铜
    ["iron"] = 8,--铁
    ["silver"] = 9,--银
    ["tin"] = 10, --锡
    ["gold"] = 11,--黄金
    ["diamond"] = 12, --钻石
    ["titan_iron"] = 13, --泰坦铁
    ["ruby"] = 14, --红宝石
    ["purple_gem"] = 15,--紫宝石
    ["emerald"] = 16, --绿宝石
    ["topaz"] = 17,--黄宝石
    ["golem"] = 18, --巨魔雕像

    ["red_soul_crystal"] = 19,--赤魂晶
    ["green_soul_crystal"] = 20,--碧魂晶
    ["light_soul_crystal"] = 21,--光魂晶
    ["dark_soul_crystal"] = 22,--影魂晶
    ["inferno_brimstone"] = 23,--地狱硫磺
    ["time_sand"] = 24,--时间之砂

    ["junior_tool"] = 25,--初级矿工包
    ["intermediate_tool"] = 26,--中级矿工包
    ["senior_tool"] = 27,--高级矿工包
    ["tnt"] = 28,--雷管
    ["ultimate_tool"] = 29,--神力矿工包

    ["saint_cross"] = 30,--圣十字
    ["blue_skull"] = 31,--幽蓝头颅
    ["lava_heart"] = 32,--熔岩之心
    ["icha_paradise"] = 33,--亲热天堂
    ["vital_essence"] = 34,--生命精华
    ["contract_stone"] = 35, --契约石

    ["exp"]     = 36,    --经验
    ["friendship_pt"] = 37,--友情点数

    ["chest_key1"] = 38,--黏土钥匙
    ["chest_key2"] = 39,--白银钥匙
    ["chest_key3"] = 40,--恶魔钥匙

    ["campaign_score"] = 41, --合战累计赛点
    
    ["golem2"] = 42,
    ["golem3"] = 43,
    ["golem4"] = 44,
    ["soul_bone1"] = 45,--白色魂骨
    ["soul_bone2"] = 46,--绿色魂骨
    ["soul_bone3"] = 47,--蓝色魂骨
    ["soul_bone4"] = 48,--紫色魂骨
    ["soul_bone5"] = 49,--金色魂骨
    ["soul_bone6"] = 50,--闪金魂骨
    ["something1"] = 51,
    ["something2"] = 52,

    ["guild_war_point"] = 53,

    ["crystal"] = 54,       --水晶
    ["crystal_bag"] = 55,   --水晶包
}

constants["RESOURCE_TYPE_NAME"] = {}
for k, v in pairs(constants["RESOURCE_TYPE"]) do
    constants["RESOURCE_TYPE_NAME"][v] = k
end

constants["ACHIEVEMENT_TYPE"] =
{
    ["arena_win1"] = 1,  --勇气(竞技场 1胜)
    ["strength_pt"] = 2, --力量(挖矿)
    ["arena_win4"] = 3, --冠军(竞技场 4胜)
    ["send_gift"] = 4,   --羁绊(送礼次数)
    ["forge_pt"] = 5,    --锻造(强化)
    ["destiny"] = 6,     --宿命武器

    --新加的必定完成的
    ["max_bp"] = 7,        --最高战力
    ["mining_boss_kill"] = 8, --矿区boss挑战次数
    ["soul_chip"] = 9,     --碎片总数量
    ["recruit"] = 10,         --招募次数
    ["wakeup"] = 11,          --觉醒次数
    ["maze"] = 12,                  --关卡
    ["arena_win"] = 13,       --竞技场获胜次数
    ["friendship_pt"] = 14, --友情点数数量

    ["login_days"] = 15,
    ["all_consume"] = 16,
    ["all_payment"] = 17,

    ["battle_round"] = 18,  --最高战斗回合数
    ["mercenary_quality4"] = 19, --紫色数量
    ["mercenary_quality5"] = 20, --金将数量
    ["mercenary_quality6"] = 21, --闪金将数量
    ["arena_win9"] = 22, --竞技场9胜次数
    ["temple_recruit"] = 23,--神殿招募次数
    ["golem_kill"] = 24, --打败巨魔次数
    ["fire_mercenary"] = 25, --解雇次数
    ["battle_fail"] = 26, --战败次数
    ["merchant_complete"] = 27,--黑市任务完成次数
    ["blood_recruit"] = 28, --血钻招募佣兵
    ["library"] = 29, --图鉴
    ["maze_difficulty1"] = 30,--关卡简单难度
    ["maze_difficulty2"] = 31,--关卡普通难度
    ["maze_difficulty3"] = 32,--关卡困难难度
    ["open_chest"] = 33, --打开矿区宝箱次数
    ["craft_soul_stone_quality"] = 34, --合成佣兵灵魂石的次数（不分品质）
    ["craft_soul_stone_quality1"] = 35, --合成佣兵灵魂石的次数（品质1）
    ["craft_soul_stone_quality2"] = 36, --合成佣兵灵魂石的次数（品质2）
    ["craft_soul_stone_quality3"] = 37, --合成佣兵灵魂石的次数（品质3）
    ["craft_soul_stone_quality4"] = 38, --合成佣兵灵魂石的次数（品质4）
    ["craft_soul_stone_quality5"] = 39, --合成佣兵灵魂石的次数（品质5）
    ["craft_soul_stone_quality6"] = 40, --合成佣兵灵魂石的次数（品质6）
    ["payment_orders"] = 41, --
    ["chest1"] = 42, --开口宝箱
    ["chest2"] = 43, --尘封宝箱
    ["chest3"] = 44, --秘密钥匙宝箱
    ["chest4"] = 45, --秘银宝箱
    ["chest5"] = 46, --烈焰金宝箱
    ["chest6"] = 47, --特殊机关宝箱
    ["open_rare_chest"] = 48, --稀有宝箱数量
    ["chest_key1"] = 49,--黏土钥匙
    ["chest_key2"] = 50,--白银钥匙
    ["chest_key3"] = 51,--恶魔钥匙
    ["alchemy_level"] = 52, --炼金等级
    ["prayer_level"] = 53, --祈祷等级
    ["check_in_count"] = 54, -- 累计签到次数
    ["merchant_white"] = 55,--黑市任务完成次数
    ["recharge_bd"] = 56,--充值血钻收益
    ["rune_quality1"] = 57, --获得符文数（品质1）
    ["rune_quality2"] = 58, --获得符文数（品质2）
    ["rune_quality3"] = 59, --获得符文数（品质3）
    ["rune_quality4"] = 60, --获得符文数（品质4）
    ["rune_quality5"] = 61, --获得符文数（品质5）
    ["rune_quality6"] = 62, --获得符文数（品质6）
    ["crystal_consume"] = 63, --消耗符文水晶
    ["crystal"] = 64, --获得符文水晶
    ["escort_rob"] = 65, --矿车拦截目标
}

--开启
constants["PERMANENT_MARK"] =
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
    ["quary"] = 14,    --工坊
    ["first_wakeup"] = 15, --第一次觉醒
    ["first_forge"]  = 16, --第一次锻造
    ["first_discover_golem"] = 17, --第一次发现巨魔
    ["first_battle_failure"] = 18, --第一次战斗失败
    ["first_recruit"] = 19,--第一次招募
    ["first_payment_reward"] = 20,--首冲
    ["bind_third_account"] = 21,
}

constants["OPEN_PERMANENT_TYPE"] =
{
    ["troop_bp"] = 1,    -- 战力
    ["maze_level"] = 2,  -- 关卡
}

constants["ADVENTURE_EVENT_TYPE"] =
{
    ["battle"] = 1, --战斗
    ["item"]    = 2,--道具
    ["resource"] = 3,--资源
    ["gossip"] = 4,--对话
    ["campaign"] = 5, --合战
}

--BP = Battle Point
constants["ACTIVE_SKILL_EFFECT_TYPE"] =
{
    ["melee_damage"]                    = 1,--普通攻击
    ["critical_damage"]                 = 2,--暴击
    ["increase_damage"]                 = 3,--伤害加深
    ["rage_damage"]                     = 4,--怒气攻击
    ["damage_by_enemy_bp"]              = 5,--反噬敌当
    ["damage_by_enemy_init_bp"]         = 6,--反噬敌初
    ["damage_by_enemy_loss_bp"]         = 7,--反噬敌损
    ["bp_steal"]                        = 8,--战力吸收
    ["increase_by_self_bp"]             = 9,--战力提升己当
    ["increase_by_self_init_bp"]        = 10,--战力提升己初
    ["increase_by_enemy_bp"]            = 11,--战力提升敌当
    ["increase_by_enemy_init_bp"]       = 12,--战力提升敌初
    ["true_damage"]                     = 13,--纯粹攻击
    ["copy_skill"]                      = 14,--复制技能
    ["armageddon_a"]                    = 15,--末日风暴A, 无视防御，当前战力
    ["armageddon_b"]                    = 16,--末日风暴B, 当前战力
    ["swap_bp_percent"]                 = 17,--战力互换
}

constants["PASSIVE_SKILL_EFFECT_TYPE"] =
{
    ["increase_speed"]                  = 1,
    ["increase_defense"]                = 2,
    ["increase_dodge"]                  = 3,
    ["increase_authority"]              = 4,
    ["convert_property"]                = 5,
}

constants["PROPERTY_TYPE"] =
{
    ["speed"] = 1,
    ["defense"] = 2,
    ["dodge"] = 3,
    ["authority"] = 4,
}

constants["PROPERTY_TYPE_NAME"] = {}

for k, v in pairs(constants["PROPERTY_TYPE"]) do
    constants["PROPERTY_TYPE_NAME"][v] = k
end

constants["BLOCK_TYPE"] =
{
    ["empty"] = 1,--已挖
    ["soil"] = 2,--土
    ["copper"] = 3,--铜矿
    ["soil_hard"] = 4,--硬质土
    ["tin"] = 5,--锡矿
    ["tin_better"] = 6,--高锡矿
    ["tin_sterling"] = 7,--富锡矿
    ["gem_red"] = 8,--红宝石
    ["rock"] = 9,--岩层
    ["iron"] = 10,--铁矿
    ["iron_better"] = 11,--高铁矿
    ["iron_sterling"] = 12,--富铁矿
    ["silver"] = 13,--银矿
    ["silver_better"] = 14,--高银矿
    ["silver_sterling"] = 15,--富银矿
    ["gold"] = 16,--金矿
    ["gold_better"] = 17,--高金矿
    ["gold_sterling"] = 18,--富金矿
    ["gem_purple"] = 19,--紫宝石
    ["rock_purple_gold"] = 20,--紫金岩
    ["gem_green"] = 21,--绿宝石
    ["gem_yellow"] = 22,--黄宝石
    ["diamond"] = 23,--钻石
    ["diamond_sterling"] = 24,--富钻石
    ["titan_iron"] = 25,--泰坦铁
    ["lava_crust"] = 26,--熔岩地壳
    ["golem"] = 27,--巨魔
    ["golem_nightmare"] = 28,--魇魔

    ["red_king"] = 29, --赤之王
    ["green_king"] = 30, --碧之王
    ["light_king"] = 31, --光之王
    ["dark_king"] = 32, --影之王
    ["golem_dark"] = 33, --漆黑魔铁巨像
    ["ether_hunting_group"] = 34, --真以太狩猎团
    ["earth_angel"] = 35, --大地天使
    ["time_emissary"] = 36, --时间使者
    ["doom_lord"] = 37, --末日之王
    ["fountain_god"] = 38, --烬之泉神
    ["seven_doom"] = 39, --森文督姆
    ["chest1"] = 40, --开口宝箱
    ["chest2"] = 41, --尘封宝箱
    ["chest3"] = 42, --秘密钥匙宝箱
    ["chest4"] = 43, --秘银宝箱
    ["chest5"] = 44, --烈焰金宝箱
    ["chest6"] = 45, --特殊机关宝箱
    ["hard_rock"] = 46,
    ["harder_rock"] = 47,
}

local BLOCK_TYPE = constants.BLOCK_TYPE
constants["MINING_BOSS_MAP"] = {
    [BLOCK_TYPE["golem_dark"]] = 40, --漆黑魔铁巨像
    [BLOCK_TYPE["ether_hunting_group"]] = 60, --真以太狩猎团
    [BLOCK_TYPE["red_king"]] = 80, --赤之王
    [BLOCK_TYPE["green_king"]] = 100, --碧之王
    [BLOCK_TYPE["light_king"]] = 120, --光之王
    [BLOCK_TYPE["dark_king"]] = 140, --影之王
    [BLOCK_TYPE["earth_angel"]] = 180, --大地天使
    [BLOCK_TYPE["time_emissary"]] = 210, --时间使者
    [BLOCK_TYPE["doom_lord"]] = 260, --末日之王
    [BLOCK_TYPE["fountain_god"]] = 340, --烬之泉神
    [BLOCK_TYPE["seven_doom"]] = 400, --森文督姆
}

constants["BLOCK_COLLECT_TYPE"] =
{
    ["nothing"] = 0,--不可收集
    ["resource"] = 1,
    ["golem"] = 2,
    ["golem_nightmare"] = 3,
    ["boss"] = 4,
    ["chest"] = 5,
}

constants["QUARRY_BOSS_ITERATE"] = {
    [BLOCK_TYPE["golem_dark"]] = BLOCK_TYPE["ether_hunting_group"],
    [BLOCK_TYPE["ether_hunting_group"]] = BLOCK_TYPE["red_king"],
    [BLOCK_TYPE["red_king"]] = BLOCK_TYPE["green_king"],
    [BLOCK_TYPE["green_king"]] = BLOCK_TYPE["light_king"],
    [BLOCK_TYPE["light_king"]] = BLOCK_TYPE["dark_king"],
    [BLOCK_TYPE["dark_king"]] = BLOCK_TYPE["earth_angel"],
    [BLOCK_TYPE["earth_angel"]] = BLOCK_TYPE["time_emissary"],
    [BLOCK_TYPE["time_emissary"]] = BLOCK_TYPE["doom_lord"],
    [BLOCK_TYPE["doom_lord"]] = BLOCK_TYPE["fountain_god"],
    [BLOCK_TYPE["fountain_god"]] = BLOCK_TYPE["seven_doom"],
    [BLOCK_TYPE["seven_doom"]] = 0,--最后一个BOSS
}

local RESOURCE_TYPE = constants.RESOURCE_TYPE
constants["MINING_RESOURCE_TYPE"] =
{
    [RESOURCE_TYPE["copper"]] = true,
    [RESOURCE_TYPE["iron"]] = true,
    [RESOURCE_TYPE["silver"]] = true,
    [RESOURCE_TYPE["tin"]] = true,
    [RESOURCE_TYPE["gold"]] = true,
    [RESOURCE_TYPE["diamond"]] = true,
    [RESOURCE_TYPE["titan_iron"]] = true,
    [RESOURCE_TYPE["ruby"]] = true,
    [RESOURCE_TYPE["purple_gem"]] = true,
    [RESOURCE_TYPE["emerald"]] = true,
    [RESOURCE_TYPE["topaz"]] = true,
    [RESOURCE_TYPE["golem"]] = true,

    [RESOURCE_TYPE["red_soul_crystal"]] = true,
    [RESOURCE_TYPE["green_soul_crystal"]] = true,
    [RESOURCE_TYPE["light_soul_crystal"]] = true,
    [RESOURCE_TYPE["dark_soul_crystal"]] = true,
    [RESOURCE_TYPE["inferno_brimstone"]] = true,
    [RESOURCE_TYPE["time_sand"]] = true,

    [RESOURCE_TYPE["golem2"]] = true,
    [RESOURCE_TYPE["golem3"]] = true,
    [RESOURCE_TYPE["golem4"]] = true,
}

constants["CAVE_TYPE"] = {
    ["cave1"] = 1,
    ["cave2"] = 2,
    ["cave3"] = 3,
    ["cave4"] = 4,
    ["cave5"] = 5,
}

local CAVE_TYPE = constants.CAVE_TYPE

constants["CAVE_BOSS_EVENT_TYPE"] = 99
constants["CAVE_TYPE_NUM"] = 6

--矿区的地下探险购买价格
constants["CAVE_DAILY_BUY_PRICE"] =  {
    [CAVE_TYPE["cave1"]] = {20,40,60,80},
    [CAVE_TYPE["cave2"]] = {20,40,60,80},
    [CAVE_TYPE["cave3"]] = {20,40,60,80},
    [CAVE_TYPE["cave4"]] = {20,40,60,80},
    [CAVE_TYPE["cave5"]] = {20,40,60,80},
}

constants["CAVE_DAILY_CHALLENGE_NUM"] = {
    [CAVE_TYPE["cave1"]] = 3,
    [CAVE_TYPE["cave2"]] = 3,
    [CAVE_TYPE["cave3"]] = 3,
    [CAVE_TYPE["cave4"]] = 3,
    [CAVE_TYPE["cave5"]] = 3,
}

--矿区的地下探险购买次数
constants["CAVE_DAILY_BUY_CHALLENGE_NUM"] = {
    [CAVE_TYPE["cave1"]] = 4,
    [CAVE_TYPE["cave2"]] = 4,
    [CAVE_TYPE["cave3"]] = 4,
    [CAVE_TYPE["cave4"]] = 4,
    [CAVE_TYPE["cave5"]] = 4,
}

constants["OPEN_CAVE_BOSS_DEMON_MEDAL"] = 150
constants["CAVE_BOSS_CHALLANGE_SUB"] = 2
constants["CAVE_BOSS_CHALLANGE_DAY"] = 7 * 86400

--界限突破消耗
constants["FORCE_LV_COST_RESOURCE_NUM"] =
{
    ["soul_chip"] = 500,
    ["golem"] = 5,
}

--属性转化消耗
constants["CHANGE_EX_PROPERTY_RESOURCE"] =
{
    ["soul_chip"] = 0, -- 佣兵解雇获得数量
    ["golem"] = 5,
    ["gold_coin"] = 10000000,

    ["scale"] = 0.8,
}

--宝箱获取状态
constants["EXPLORE_BOX_TYPE"] =
{
    ["never_get"] = 1,
    ["already_get"] = 2,
    ["already_open"] = 3,
}

--区域困难等级
constants["AREA_DIFFICULTY_LEVEL"] =
{
    ["easy"] = 1,
    ["normal"] = 2,
    ["hard"] = 3,
}

--招募消耗
constants["RECRUIT_COST"] = {
    ["ten_mercenary_door"] = 580,  --消耗血钻
    ["recruiting_door"] = 3000,    --消耗金币
    ["hero_door"] = 60,           --消耗血钻
    ["friendship_door"] = 150,    --消耗友情点数
    ["ten_friendship_door"] = 1500, --友情点数10连抽
    ["magic_door"] = 0,
}

--转生血钻消耗
constants["TRANSMIGRATION_COST"] = {
    [1] = 10,
    [2] = 35,
    [3] = 70,
    [4] = 140,
    [5] = 240,
    [6] = 240,
}

constants["MERCHANT_TYPE"] =
{
    ["DARK"] = 1,
    ["WHITE"] = 2,
    ["dark1"] = 3,
    ["dark2"] = 4,
    ["dark3"] = 5,
}
constants["MERCHANT_WHITE_BASE_PRICE"] = 10

--场景过度
constants["SCENE_TRANSITION_TYPE"] =
{
    ["none"] = 0,
    ["right_to_left"] = 1,--新的场景从右到左进入
}


--佣兵等级
constants["MERCENARY_QUALITY"] ={
    ["ordianry"]    = 1, -- 平凡级
    ["elite"]       = 2, --精英级
    ["hero"]        = 3, --英雄级
    ["legend"]      = 4,   --传奇级
    ["leader"]      = 5,   --领袖级
    ["king_leader"] = 6,   --领袖级
}

--每日标记
constants["DAILY_TAG"] =
{
    ["share_event1"] = 0, --社交分享事件
    ["item_5000001"] = 1, --巨人药水
    ["item_5000002"] = 2, --东方秘药
    ["item_5000003"] = 3, --以太蘑菇
    ["item_5000004"] = 4, --大物语之汤
    ["item_5000005"] = 5, --泰坦之神

    ["temple_recruit"] = 6, --神殿招募
    ["quest_random_mail"] = 10, --每日随机邮件
}

constants["REWARD_SOURCE"] =
{
    ["adventure_event"] = 1,
    ["use_tnt"] = 2,
    ["finish_mining_project"] = 3,
    ["merchant_exchange"] = 4,
    ["use_item"] = 5,
    ["eat_food"] = 6,
    ["open_box"] = 7,
    ["store"]    = 8,
    ["take_badge"] = 9,
    ["arena_winner"] = 10,
    ["medal_exchange"] = 11,
    ["mining_use_tool"] = 12,
    ["game_master"] = 13,
    ["refresh_arena_rival"] = 14,
    ["upgrade_bag"] = 15,
    ["forge_destiny_weapon"] = 16,
    ["fire_mercenary"] = 17,
    ["forge"] = 18,
    ["wakeup"] = 19,
    ["transmigration"] = 20,
    ["recruit_normal"] = 21,
    ["recruit_blood"] = 22,
    ["recruit_ten_blood"] = 23,
    ["merchant_reset"] = 24,
    ["dig_mining"] = 25,
    ["collect_mine"] = 26,
    ["add_mining_project"] = 27,
    ["unlock_new_project"] = 28,
    ["temple"] = 29,
    ["refresh_mining"] = 30,
    ["open_artifact"] = 31,
    ["upgrade_force_lv"] = 32,
    ["payment"] = 33,
    ["alloc_exp"] = 34,
    ["mail"] = 35,
    ["send_gift"] = 36,
    ["recruit_friendship"] = 37,
    ["achievement"] = 38,
    ["cdkey"] = 39,

    ["recruit_magic"] = 40,
    ["craft_soul_stone"] = 41,
    ["rename"] = 42,
    ["sign_contract"] = 43,

    ["change_exproperty"] = 44,
    ["campaign_refresh_num"] = 45,
    ["campaign_convert"] = 46,
    ["campaign_revive"] = 47,

    ["carnival"] = 50,
    ["check_in"] = 51,
    ["vip"] = 52,
    ["library"] = 53,
    ["prayer"] = 54,
    ["alchemy"] = 55,
    ["cave_event"] = 56,
    ["cave_boss"] = 57,
    ["buy_cave_challenge"] = 58,
    ["recruit_ten_friendship"] = 59,
    ["merchant_white_reset"] = 60,
    ["mercenary_evolution"] = 61,
    ["fund"] = 62,
    ["sns_share"] = 63,
    ["buy_adventure_event"] = 64,
    ["guild_war_buff"] = 65,
    ["guild_war_exchange"] = 66,    --公会战兑换
    ["guild_war_settlement"] = 67,  --公会战结算
    ["guild_war_scout"] = 68,       --公会战刺探
    ["draw_rune"] = 69,             --抽符文
    ["buy_rune_bag"] = 70,          --购买符文背包
    ["escort_buy_rob_times"] = 71,              --运送：购买拦截次数
    ["escort_buy_escort_times"] = 72,           --运送：购买运送次数
    ["escort_refresh_tramcar"] = 73,            --运送：刷新矿车
    ["escort_refresh_rob_target_list"] = 74,    --运送：立即刷新可拦截目标
    ["escort_rob_success"] = 75,                --运送：拦截成功后奖励
    ["escort_finish"] = 76,                     --运送：运送完成后奖励
}

constants["REWARD_TYPE"] =
{
    ["item"]                = 1,      --道具
    ["resource"]            = 2,      --资源
    ["pickaxe_count"]       = 3,      --十字镐次数
    ["area"]                = 4,      --区域开启
    ["destiny_weapon"]      = 5,      --给予宿命武具
    ["leader_bp"]           = 6,      --提升战斗力
    ["camp_capacity"]       = 7,      --佣兵营帐容量
    ["mercenary"]           = 8,      --给予英雄
    ["maze"]                = 9,      --地图开启
    ["feature"]             = 10,     --功能开启
    ["pickaxe_level"]       = 11,     --十字镐品质升级
    ["formation_capacity"]  = 12,     --增加出战人数
    ["carnival_token"]      = 13,     --活动奖券
    ["campaign"]            = 14,     --合战产出
    ["soul_stone"]          = 15,     --佣兵灵魂石
    ["rune"]                = 16,     --符文

    ["reward_group"]        = 17, --只有前端用
}

constants["REWARD_GROUP_ID"] =
{
    ["recruiting_group"]    = 1500148, --招募所
    ["hero_group"]          = 1500217, --英雄之门
    ["legend_group"]        = 1500360,  --传奇之门
    ["rock_purple_gold"]    = 39000001, --紫金岩
    ["superficial_layer"]   = 40000001, --浅层矿物
    ["middle_layer"]        = 40000005, --中层矿物
    ["deep_layer"]          = 40000010, --深层矿物
    ["core_layer"]          = 40000014, --地心矿物
    ["arena_one"]           = 1400001,  --竞技场一胜
    ["arena_four"]          = 1400002,
    ["arena_nine"]          = 1400004,
    ["arena_first_four"]    = 1400006,
    ["arena_first_nine"]    = 1400007,
}

constants["STORE_GOODS_TYPE"] =
{
    ["resource"] = 1,          --资源
    ["max_box_num"] = 2,       --迷宫宝箱上限
    ["max_pickaxe_count"] = 3, --矿镐耐久上限
    ["camp_capacity"] = 4,     --佣兵列表上限
}

--事件编号
constants["MINING_EVENT_TYPE_ID"] =
{
    ["golem"] = 2000000, --巨魔起始
    ["golem_nightmare"] = 5000000, --魇魔
    ["red_king"] = 4000001, --赤之王
    ["green_king"] = 4000002, --碧之王
    ["light_king"] = 4000003, --光之王
    ["dark_king"] = 4000004, --影之王
    ["golem_dark"] = 4000005, --漆黑魔铁巨像
    ["ether_hunting_group"] = 4000006, --真以太狩猎团
    ["earth_angel"] = 4000007, --大地天使
    ["time_emissary"] = 4000008, --时间使者
    ["doom_lord"] = 4000009, --末日之王
    ["fountain_god"] = 4000010,
    ["seven_doom"] = 4000011,
}

--宝具状态
constants["MERCENARY_AETIFACT_STATUS"] =
{
    ["not_have_artifact"] = 1,
    ["weapon_lv_not_enough"] = 2,
    ["not_open_artifact"] = 3,
    ["already_open_artifact"] = 4,
}

--邮件类型
constants["MAIL_TYPE"] =
{
    ["reward_group"] = 1,
    ["item"] = 2,
    ["resource"] = 3,
    ["payment"] = 4,
    ["campaign"] = 5,
    ["mercenary"] = 6,
    ["rune"] = 7,
}

constants["MAIL_PANEL_TYPE"] =
{
    ["system"] = 1,
    ["friend"] = 2,
}

constants["MAIL_SOURCE"] =
{
    ["player"] = 0,
    ["gm_system_maintenance"] = 1,
    ["gm_ladder_reward"] = 2,
    ["gm_payment_notify"] = 3,
    ["gm_campaign_reward"] = 4,
    ["gm_guild_notify"] = 5,
    ["gm_bag_full"] = 6,
}

-- constants["MAIL_TEXT"] = {
--     ["guild_dismiss"] = 1,
--     ["guild_fire"] = 2,
-- }


constants["LADDER_CHALLENGE_NUM"] = 10
--签到时间
constants["CHECKIN_TIME"] =
{
    ["first"] = 12,
    ["second"] = 18,
    ["third"] = 24,
}

--竞技场刷新对手消耗血钻
constants["ARENA_REFRESH_COST_BLOOD_DIAMOND"] = 60

constants["RENAME_COST"] = 300

--最大区域数量
constants["MAX_AREA_NUM"] = 45

--最大探索人数
constants["MAX_FORMATION_CAPACITY"] = 25

--最大武器等级
constants["MAX_WEAPON_LV"] = 30
--可以开启宝具的武器等级
constants["CAN_OPEN_ARTIFACT_WEAPON_LV"] = 20

--可以觉醒的等级
constants["CAN_WAKEUP_LEVEL"] = 30

--最大宿命武器等级
constants["MAX_DESTINY_WEAPON_LV"] = 10

constants["MAX_DESTINY_WEAPON_ID"] = 11

--宿命武器强化 消耗消耗 最大资源类型个数
constants["MAX_DESTINY_FORGE_COST_RESOURCE_TYPE"] = 5

--最大工程数量
constants["MAX_PROJECT_COUNT"] = 5

--主动技能起始
constants["ACTIVE_SKILL_ID_OFFSET"] = 1000001

constants["MAX_FORCE_LEVEL"] = 35

constants["EXP_LIMIT"] = 10000000000

constants["FORCE_LEVEL_PROPERTY"] =
{
    ["speed"] = 5,
    ["dodge"] = 5,
    ["defense"] = 5,
    ["authority"] = 2,
}

constants["MAX_FORMATION_NUM"] = 5
constants["MAX_LEVEL"] = 100

constants["MAX_FIRE_NUM_ONCE"] = 400 --一次最多解雇的佣兵个数
constants["MAX_BAG_CAPACITY"] = 102

constants["ITEM_RULE"] =
{
    ["normal"] = 0,
    ["hero_biography"] = 1,
    ["random_exp"] = 2,
    ["random_coin"] = 3,
    ["refresh_mining"] = 4, --刷新矿区
    ["refresh_temple"] = 5, --刷新神殿
    ["refresh_merchant"] = 6, --刷新商会
    ["refresh_arena_rival"] = 7, --竞技场对手
    ["vip"] = 8,
}

--开启宝具消耗资源数目
constants["OPEN_ARTIFACT_CONSUME_RESOURCE"] = {
    ["gold_coin"] = 95000000,
    ["red_soul_crystal"] = 6,
    ["green_soul_crystal"] = 6,
    ["light_soul_crystal"] = 6,
    ["dark_soul_crystal"] = 6,
}

constants["SEND_GITF_PT"] = 10
constants["MAX_INVITATION"] = 10
constants["MAX_DAILY_FRIENDSHIP_PT"] = 200
constants["MAX_FRIEND_NUM"] = 20

constants.SUPER_USER =
{
    ["yxhy"] = {
        ["27625820"] = true
    },

    ["r2games"] = {
        ["307403780"] = true,
        ["305461212"] = true,
        ["307376276"] = true,
        ["307262362"] = true,

        ["307662574"] = true,   -- 王山
        ["308205854"] = true,   -- 王山
        ["307937260"] = true,   -- android 测试机
        ["309035378"] = true,
        ["308410892"] = true,
        ["309286550"] = true,
        ["308944872"] = true,
    },

    ["txwy"] = {
        ["28370876"] = true,
        ["28370879"] = true,
        ["28370881"] = true,
        ["28370883"] = true,
        ["28370885"] = true,
        ["28370886"] = true,
        ["28370891"] = true,
        ["28370898"] = true,
        ["28370899"] = true,
        ["28370901"] = true,
    },--FYD
    ["mu77"] = {
        ["Mu77Admin011"] = true,
        ["Mu77Admin012"] = true,
        ["Mu77Admin013"] = true,
        ["Mu77Admin014"] = true,
        ["Mu77Admin015"] = true,
        ["Mu77Admin016"] = true,
        ["Mu77Admin017"] = true,
        ["Mu77Admin018"] = true,
        ["Mu77Admin019"] = true,
        ["Mu77Admin020"] = true,
    }
}

--冒险月卡 增加佣兵上限30, 竞技场挑战次数 + 2, 宝箱探索时间减少25%, 每天领取血钻30, 巨魔1个
constants["VIP_TYPE"] =
{   --membership
    ["adventure"] = 1, --冒险月卡
    ["mining"] = 2, --挖矿月卡
}

constants["VIP_TYPE_NAME"] = {}
for k, v in pairs(constants["VIP_TYPE"]) do
    constants["VIP_TYPE_NAME"][v] = k
end

constants["VIP_PRIVILEGE"] =
{
    ["daily_blood_diamond"] = 60, --每天送血钻60
    ["daily_soul_chip"] = 200,    --每天送荣誉碎片
    ["add_camp_capacity"] = 50, --增加佣兵上限 50
    ["add_arena_challange_num"] = 2, --竞技场挑战次数+2
    ["box_time"] = 0.75, --宝箱探索时间变为75%
}

constants["VIP_STATE"] =
{
    ["unbuy"] = 0,
    ["buy"] = 1,
    ["daily_reward"] = 2,
}

constants["PAYMENT_PRODUCT_TYPE"] =
{
    ["blood_diamond"] = 1,
    ["adventure_vip"] = 2,
    ["special_reward"] = 3,
}

constants["LADDER_REWARD_RANK"] = { 1,2,4,11,101,301,1001,2501 }

constants["LADDER_REWARD"] =
{
    [1] = 10,
    [2] = 8,
    [4] = 6,
    [11] = 5,
    [101] = 4,
    [301] = 3,
    [1001] = 2,
    [2501] = 1,
}

constants["CARNIVAL_TYPE"] =
{
    ["tmp_achievement"] = 1,
    ["achievement_value"] = 2,
    ["multi_achievement"] = 3,
    ["collect_item"] = 4,
    ["single_payment"] = 5,
    ["ladder"] = 6,
    ["first_payment"] = 7,
    ["magic_door"] = 8,
    ["transmigrate"] = 9,
    ["single_equal"] = 10,
    ["time_limit_store"] = 11,
    ["vote"] = 12,
    ["lottery"] = 13,
    ["evolution"] = 14,
    ["fund"] = 15,
    ["sns_invitation"] = 16,
    ["limite_package"] = 17,
}

--图鉴招募消耗灵魂碎片的倍数
constants["LIBRARY_COST_SOUL_CHIP_MULTI"] =  2.0

--招募消耗魂骨的倍数
constants["COST_SOUL_BONE_MULTI"] =  1.5

--触发冒险和挖矿战斗事件 背包中最大的空间
constants["EVENT_MAX_BAG_SPACE_COUNT"] = 5

constants["COMMENT_TYPE"] =
{
    ["mercenary"] = 1, --佣兵
    ["maze"] = 2,
}

--契约消耗灵魂石
constants["MAX_CONTRACT_SOUL_TYPE"] = 3

--契约解锁所需要的招募次数
constants["CONTRACT_UNLOCK_RECRUIT_NUM"] = 150

constants["LEADER_NAME_LENGTH"] = 16

constants["MAX_CONTRACT_LV"] = 2

constants["CONTRACT_FORCE_UP"] = {
    [0] = 1,
    [1] = 1,
    [2] = 2,
}

-- 合战排名每日奖励
constants["CAMPAIGN_RANK_REWARD"] = {
    [1] = {min=1,max=1},
    [2] = {min=2,max=2},
    [3] = {min=3,max=3},
    [4] = {min=4,max=5},
    [5] = {min=6,max=10},
    [6] = {min=11,max=20},
    [7] = {min=21,max=50},
}

constants["CAMPAIGN_REWARD_TYPE"] = {
    ["score"] = 1,
    ["rank"] = 2,
}

-- 合战奖励资源ID
constants["CAMPAIGN_RESOURCE"] = {
    ["exp"] = 1,
    ["score"] = 2,
}

constants["CAMPAIGN_STATUS"] = { -- 合战状态
    ["unknown"] = 1,         -- 合战尚未开始
    ["game"] = 2,           -- 合战进行中
    ["reward"] = 3,             -- 合战奖励兑换中
}

constants["CAMPAIGN_CONVERT_SCORE"] = 6 -- 赛点类型
constants["FORGE_WEAPON_LUCKY_NUM"] = 5 -- 佣兵强化失败 额外增加的概率

-- 日常系统
constants["ALCHEMY_CONFIG"] = {
    {lv = 1, value = 5000, fixed = 0 , req_value = 0},
    {lv = 1, value = 9500, fixed = 15000, req_value = 20},
    {lv = 2, value = 13500, fixed = 55000, req_value = 90},
}

constants["PRAYER_CONFIG"] = {
    {lv = 1, value = 5000, fixed = 0 , req_value = 0},
    {lv = 1, value = 10000, fixed = 10000, req_value = 20},
    {lv = 2, value = 15000, fixed = 40000, req_value = 90},
}

-- 新手血钻召唤英雄次数阀值
constants["NOVICE_BLOOD_RECRUIT_THRESHOLD"] = 60


constants["NOVICE_DAYS"] = 3

constants["SNS_EVENT_TYPE"] = 
{
    ["share_link"] = 1,
    ["share_mercenary"] = 2,
    ["share_ladder"] = 3,
    ["share_achievement"] = 4,
    ["share_mining"] = 5,
    ["bind_account"] = 6,
}

constants["SNS_SHARE_LADDER"] = 
{
    [1] = 100,
    [2] = 50,
    [3] = 20,
    [4] = 10,
    [5] = 9,
    [6] = 8,
    [7] = 7,
    [8] = 6,
    [9] = 5,
    [10] = 4,
    [11] = 3,
    [12] = 2,
    [13] = 1,
}

constants["SNS_SHARE_MINING"] =
{
    [BLOCK_TYPE["golem_dark"]] = 0, --漆黑魔铁巨像
    [BLOCK_TYPE["ether_hunting_group"]] = 1, --真以太狩猎团
    [BLOCK_TYPE["red_king"]] = 2, --赤之王
    [BLOCK_TYPE["green_king"]] = 3, --碧之王
    [BLOCK_TYPE["light_king"]] = 4, --光之王
    [BLOCK_TYPE["dark_king"]] = 5, --影之王
    [BLOCK_TYPE["earth_angel"]] = 6, --大地天使
    [BLOCK_TYPE["time_emissary"]] = 7, --时间使者
    [BLOCK_TYPE["doom_lord"]] = 8, --末日之王
    [BLOCK_TYPE["fountain_god"]] = 9, --烬之泉神
    [BLOCK_TYPE["seven_doom"]] = 10, --森文督姆
}

-- OG分享奖励
constants["SNS_SHARE_REWARD"] =
{
    ["share_mercenary"] = 10,
    ["share_ladder"] = 50,
    ["share_achievement"] = 10, 
    ["share_mining"] = 5,    
}

-- 公会系统
constants["GUILD_GRADE"] = {
    ["chairman"] = 99,  --公会会长
    ["staff"] = 1,      --最底层-会员
}
-- 公会通知类型
constants["GUILD_NOTICE"] = {
    ["notice_join"] = 1, -- 加入公会
    ["notice_exit"] = 2, -- 退出公会
    ["notice_fire"] = 3, -- 开除公会
    ["notice_dismiss"] = 4, -- 解散公会
    ["notice_create"] = 5, -- 创建公会
    ["notice_transfer"] = 6, -- 转让公会
}
-- 公会最大会员
constants["GUILD_MAX_MEMBER"] = 51

-- 公会加入门槛 战力门槛>=
constants["GUILD_JOIN_THRESHOLD"] = {
    0,500000,2000000
}

-- 每天加入公会次数
constants["GUILD_JOIN_LIMIT"] = 4

-- BBS的频道
constants["BBS_CHANNEL"] = {
    ["common"] = 1,
    ["guild"] = 2,
}

constants["CAMPAIGN_REVIVE_VALUE"] = 100

--符文背包初始等级
constants["RUNE_BAG_LEVEL_INIT"] = 1

--符文背包最大容量
constants["MAX_RUNE_BAG_CAPACITY"] = 40

--符文临时背包最大容量
constants["MAX_RUNE_TEMPORARY_BAG_CAPACITY"] = 10

--符文背包类型
constants["RUNE_BAG_TYPE"] = {
    ["BAG"] = 1,
    ["TEMPORARY_BAG"] = 2,
}

--符文抽取平台最大ID
constants["MAX_RUNE_PLATFORM_ID"] = 5

--直接跳至第四层消耗
constants["RUNE_GO_TU_AREA_4_COST"] = 20

--符文可装备数量
constants["MAX_RUNE_EQUIPMENT_NUM"] = 5

--符文最大品阶
constants["MAX_RUNE_QUALITY"] = 6

--符文敌我属性key值
constants["RUNE_PROPERTY_KEYS"] = {
    [1] = "mine_property", 
    [2] = "enemy_property",
}

--符文背包多选时最大选择数量
constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"] = 10

--符文类型
constants["RUNE_TYPE"] = {
    ["EXP"] = 1,
    ["PROPERTY"] = 2,
    ["SKILL"] = 3,
}

--自动选择材料符文的最大品质
constants["MAX_AUTO_SELECT_EXP_RUNE_QUALITY"] = 3
--自动选择材料符文的最大品质(包含紫色)
constants["MAX_AUTO_SELECT_EXP_RUNE_MORE_QUALITY"] = 4

--购买矿车ID
constants["SPECITY_TRAMCAR_ID"] = 4

--默认运送相关次数
constants["DEFAULT_ESCORT_TIMES"] = 3           --可运送次数
constants["DEFAULT_ROB_TIMES"] = 10             --可拦截次数
constants["FREE_REFRESH_TRAMCAR_TIMES"] = 3    --免费刷新矿车次数
constants["FREE_REFRESH_ROB_TARGET_TIMES"] = 2  --免费刷新拦截对象次数

constants["MAX_BE_ROBBED_TIMES"] = 6       --可被拦截次数

constants["MAX_BUY_ROB_TIMES"] = 15         --拦截次数的最多购买次数
constants["MAX_BUY_ESCORT_TIMES"] = 15      --运送次数的最多购买次数

constants["REFRESH_ROB_TARGET_CD"] = 600  --刷新拦截对象CD时间

--运送矿车状态
constants["ESCORT_STATUS"] = {
    ["READY"] = 1,
    ["ESCORTING"] = 2,
    ["FINISH"] = 3,
}

constants["ESCORT_ESCORTING_IGNORE_TIME"] = 0.25 * 60   --获取拦截目标时，如果剩余运送时间小于这个值，则不会被选中作为目标，单位秒

constants["ESCORT_ROB_TARGET_NUM"] = 6  --可拦截目标人数
constants["ROBOT_USER_ID"] = "ROBOT-"   --可拦截目标机器人ID前缀
constants["DEFAULT_TRAMCAR_ID"] = 1       --机器人的运送矿车等级

constants["ESCORT_REFRESH_ROB_TARGET_LIST_IMMEDIATELY_COST"] = 200      --立即刷新可拦截目标消耗
constants["ESCORT_REFRESH_TRAMCAR_RANDOM_COST"] = 200                   --随机刷新矿车消耗
constants["ESCORT_REFRESH_TRAMCAR_SPECIFY_COST"] = 500                  --刷新指定矿车消耗

--拦截是否成功
constants["ROB_RESULT"] = {
    ["SUCCESS"] = 1,
    ["FAILURE"] = 2,
}

--是否需要自动刷新矿车
constants["ESCORT_AUTO_REFRESH_TRAMCAR"] = {
    ["TRUE"] = 1,
    ["FALSE"] = 2,
}

constants["ROB_REWARD_PERCENT"] = 5 --拦截成功后获得奖励比例（%）

return constants
