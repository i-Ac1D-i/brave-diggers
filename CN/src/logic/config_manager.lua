local constants = require "util.constants"
local platform_manager = require "logic.platform_manager"
local csv = require "util.csv"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local mt = {}
mt.__index = function(t, key)
    local val = rawget(t, key .. "_config")
    return val
end
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local REWARD_TYPE = constants["REWARD_TYPE"]

local platform_manager

local config_manager = {}
setmetatable(config_manager, mt)

function config_manager:Init()
    platform_manager = require "logic.platform_manager"
    
    local locale = platform_manager:GetLocale()
    if not self.cur_locale then
        self:LoadFromCSV(locale, platform_manager:NeedTranslate())
    elseif self.cur_locale ~= locale then
        self:ChangeLocale(locale)
    end
    
    self.cur_locale = locale
end

function config_manager:ParseServerConfig(server_list)
    local server_config = {}
    for _, server_info in pairs(server_list) do
        server_config[server_info.server_id] = server_info
    end

    return server_config
end

function config_manager:ParsePassiveSkill()
    local CONVERT_PROPERTY = constants.PASSIVE_SKILL_EFFECT_TYPE["convert_property"]
    for ID, conf in pairs(self.passive_skill_config) do
        if conf.effect_type == CONVERT_PROPERTY or conf.sex ~= 0 or conf.job ~= 0 or conf.race ~= 0 then
            conf.is_special = true
        end
    end
end

function config_manager:ParseCoopSkill()
    for ID, conf in pairs(self.cooperative_skill_config) do
        local mercenary_ids = {}
        for mercenary_template_id in string.gmatch(conf.condition, "(%d+)") do
            mercenary_template_id = tonumber(mercenary_template_id)
            local n = mercenary_ids[mercenary_template_id] or 0
            mercenary_ids[mercenary_template_id] = n + 1
        end

        conf.mercenary_ids = mercenary_ids

        local mercenary_type_num = 0
        for mercenary_id, num in pairs(mercenary_ids) do
            mercenary_type_num = mercenary_type_num + 1
        end

        conf.mercenary_type_num = mercenary_type_num
    end
end

function config_manager:ParseMaze()
    local income_config = self.adventure_income_config
    for k, maze_conf in pairs(self.adventure_maze_config) do
        local conf = income_config[maze_conf.income_id]
        if conf then
            local maze_list_map = self.area_info_config[conf.area_id].maze_list_map
            if not maze_list_map then
                maze_list_map = {}
                self.area_info_config[conf.area_id].maze_list_map = maze_list_map
            end

            local maze_list = maze_list_map[conf.difficulty]
            if not maze_list then
                maze_list = {}
                maze_list_map[conf.difficulty] = maze_list
            end

            maze_list[maze_conf.type] = maze_conf
        end
    end
end

function config_manager:ParseAchievement(file)
    local achievement_config = {}

    for k, v in pairs(file) do
        local single_achievement_group = achievement_config[v.type]
        if not single_achievement_group then
            single_achievement_group = {}
            achievement_config[v.type] = single_achievement_group
        end
        table.insert(single_achievement_group, v)
    end

    for k, v in pairs(achievement_config) do
        table.sort(v, function(a, b) return a.step < b.step end)
    end

    return achievement_config
end

function config_manager:ParseMercenaryLibrary()

    self.mercenary_library_config = {}
    for template_id, mercenary in pairs(self.mercenary_config) do
        if mercenary.library_mark then
            table.insert(self.mercenary_library_config, mercenary)
        end
    end

    --默认品质排序
    table.sort(self.mercenary_library_config, function(a, b)
        return a.quality > b.quality
    end)
end

function config_manager:ParseContractConifg(level, file)
    local contract_config = self.mercenary_contract_config

    local t = {}
    contract_config[level] = t

    for k, v in pairs(file) do
        if v.contract_level ~= 0 then
            t[v.ID] = v
        end
    end
end

--返回佣兵介绍 (品质，性别，种族，工作)
function config_manager:GetMercenaryIntroduction(mercenary)
    return string.format(lang_constants:Get("mercenary_job_desc"), lang_constants:Get("mercenary_quality" .. mercenary.quality),
        lang_constants:GetSex(mercenary.sex),
        lang_constants:GetRace(mercenary.race),
        lang_constants:GetJob(mercenary.job)
    )
end

--[[
    parma1 资源类型
    parma2 资源id
    根据资源id得到资源config
]]
function config_manager:GetSourceByID(source_type,template_id)
    local conf = {}
    if source_type == REWARD_TYPE["item"] then
        conf = self.item_config[template_id]
    elseif source_type == REWARD_TYPE["mercenary"] then
        conf = self.mercenary_config[template_id]
        conf.icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png"
        conf.desc = self:GetMercenaryIntroduction(conf)

    elseif source_type == REWARD_TYPE["soul_stone"] then
        conf = self.mercenary_config[template_id]
        conf.icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png"
        conf.desc = self:GetMercenaryIntroduction(conf)

    elseif source_type == REWARD_TYPE["resource"] then
        conf = self.resource_config[template_id]
    
    elseif source_type == REWARD_TYPE["carnival_token"] then
        conf = config_manager.carnival_token_config[template_id]

    elseif source_type == REWARD_TYPE["destiny_weapon"] then
        conf = self.destiny_skill_config[template_id]
        conf.quality = 6

    elseif source_type == REWARD_TYPE["rune"] then
        conf = self.rune_config[template_id]

    end
    return conf
end

function config_manager:ParseLeaderContractConfig(file)
    local leader_config = {}
    for k, v in pairs(file) do
        leader_config[v.num] = v
    end
    return leader_config
end

function config_manager:ParseMineEvent(file)
    local mining_event_config = {}
    for k,v in pairs(file) do
        local t_key = v.cave_type
        if not mining_event_config[t_key] then
            mining_event_config[t_key] = {}
        end
        mining_event_config[t_key][v.level] = v
    end

    return mining_event_config
end

function config_manager:ParseWakeUpConfig(file)
    local RESOURCE_TYPE_NAME = constants.RESOURCE_TYPE_NAME

    for k, v in pairs(file) do
        local resource_name = RESOURCE_TYPE_NAME[v.resource_id]
        if resource_name then
            v[resource_name] = v.resource_num
        end
    end

    return file
end

function config_manager:ParseSceneEffect()
    for k, conf in pairs(self.scene_effect_config) do
        --时间单位从毫秒转换为秒
        conf.color_fade_in_time = conf.color_fade_in_time / 1000
        conf.color_fade_out_time = conf.color_fade_out_time / 1000

        conf.pic_fade_in_time = conf.pic_fade_in_time / 1000
        conf.pic_fade_out_time = conf.pic_fade_out_time / 1000
        conf.pic_wait_time = conf.pic_wait_time / 1000
    end
end

function config_manager:ParseFundConfig(file)
    local fund_config = {}

    for k, v in pairs(file) do
        local fund_type = v.type
        if not fund_config[fund_type] then
            fund_config[fund_type] = {}
        end

        local iter1 = string.gmatch(v.param1, "(%d+)")
        local iter2 = string.gmatch(v.param2, "(%d+)")
        
        v.reward_list = {}

        for reward_type in string.gmatch(v.reward_type, "(%d+)") do
            local param1, param2 = tonumber(iter1()), tonumber(iter2())
            reward_type = tonumber(reward_type)

            if reward_type == constants.REWARD_TYPE["mercenary"] then
                param2 = 1
            end
        
            table.insert(v.reward_list, { reward_type = reward_type, param1 = param1 or 0, param2 = param2 or 1 })
        end

        table.insert(fund_config[fund_type], v)
    end

    for _, conf in pairs(fund_config) do
        conf.profit_duration = #conf
    end

    self.fund_config = fund_config
end

function config_manager:ParseActiveSkill()
    local config = csv.Load("active_skill")
    local GetPropertyArr = function(str)
        local iter = string.gmatch(str, '(-?%d+)')
        local speed, defense, dodge, anthority = iter() or 0, iter() or 0,iter() or 0,iter() or 0
        if speed == 0 and  defense == 0 and  dodge == 0 and  anthority == 0 then
            return {}
        else
            return {tonumber(speed), tonumber(defense), tonumber(dodge), tonumber(anthority)}
        end
    end

    for ID, conf in pairs(config) do
        if conf.self_property then
            conf.self_property_map = GetPropertyArr(conf.self_property)
        end

        if conf.enemy_property then
            conf.enemy_property_map = GetPropertyArr(conf.enemy_property)
        end
    end
    return config
end

function config_manager:CreateRunePropertyConfig()
    local rune_property_config = {}
    for template_id,rune_conf in pairs(self.rune_config) do
        rune_property_config[template_id] = {}
        for _,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
            local property_list = {}
            for level=1,rune_conf.level_limit do
                property_list[level] = {}
                for k,property_name in pairs(constants["PROPERTY_TYPE_NAME"]) do
                    property_list[level][property_name] = 0
                end
            end
            for property_str in string.gmatch(rune_conf[key] .. "|", "([%d%-%.,#]+)|") do
                local property_ids, property_grows = string.match(property_str, "([%d,]+)#([%d%-%.,]+)")

                for property_type in string.gmatch(property_ids .. ",", "(%d+),") do
                    local property_name = constants["PROPERTY_TYPE_NAME"][tonumber(property_type)]
                    if property_name then
                        local beg_level = 1
                        for end_level, grow_value in string.gmatch(property_grows, "(%d+),([%d%-%.]+)") do
                            end_level = tonumber(end_level) or 0
                            grow_value = tonumber(grow_value) or 0
                            if end_level > rune_conf.level_limit then
                                end_level = rune_conf.level_limit
                            end
                            for level=beg_level,end_level do
                                property_list[level][property_name] = (property_list[level - 1] and property_list[level - 1][property_name] or 0) + grow_value
                            end
                            beg_level = end_level + 1
                        end
                        for level=beg_level,rune_conf.level_limit do
                            property_list[level][property_name] = (property_list[level - 1] and property_list[level - 1][property_name] or 0)
                        end
                    end
                end
            end
            rune_conf[key] = nil
            rune_property_config[template_id][key] = property_list
        end
    end

    return rune_property_config
end

function config_manager:CreateMercenaryExchangeConfig()
    local mercenary_exchange_config = {}

    local config = csv.Load("mercenary_exchange")
    for id, conf in pairs(config) do
        mercenary_exchange_config[conf.group_id] = mercenary_exchange_config[conf.group_id] or {}
        table.insert(mercenary_exchange_config[conf.group_id], { id = id, mercenary_id = conf.mercenary_id, times = conf.times, cost_num = conf.cost_num})
    end

    for _, mercenary_list in pairs(mercenary_exchange_config) do
        table.sort( mercenary_list, function(a,b) return a.mercenary_id > b.mercenary_id end )
    end

    return mercenary_exchange_config
end

--宝具等级表
function config_manager:CreateMercenaryArtifactConfig()
    local mercenary_artifact_config = {}

    local config_data = csv.Load("mercenary_artifact")

    for _,conf_info in ipairs(config_data) do
        if not mercenary_artifact_config[conf_info.template_id] then
            mercenary_artifact_config[conf_info.template_id] = {}
        end


        conf_info.cost_list = {}
        local cost_id_iter = string.gmatch(conf_info.cost_id .. "|", "(%d+)|")
        local cost_num_iter = string.gmatch(conf_info.cost_num .. "|", "(%d+)|")

        local cost_id, cost_num = cost_id_iter(), cost_num_iter()
        while cost_id and cost_num do
            conf_info.cost_list[tonumber(cost_id)] = tonumber(cost_num)
            cost_id, cost_num = cost_id_iter(), cost_num_iter()
        end

        local last_artifact_conf = mercenary_artifact_config[conf_info.template_id][conf_info.artifact_level - 1] or {}
        conf_info.sum_bp        = conf_info.bp          + (last_artifact_conf.sum_bp or 0)
        conf_info.sum_speed     = conf_info.speed       + (last_artifact_conf.sum_speed or 0)
        conf_info.sum_defense   = conf_info.defense     + (last_artifact_conf.sum_defense or 0)
        conf_info.sum_dodge     = conf_info.dodge       + (last_artifact_conf.sum_dodge or 0)
        conf_info.sum_authority = conf_info.authority   + (last_artifact_conf.sum_authority or 0)

        mercenary_artifact_config[conf_info.template_id][conf_info.artifact_level] = conf_info
    end

    return mercenary_artifact_config
end

function config_manager:CreatePriceConfig() 
    local file = csv.Load("pvp_ladder_num")
    local temp = {}
    for i,data in ipairs(file) do 
        if not temp[data.type] then
            temp[data.type] = {}
        end
        table.insert(temp[data.type],data)  
    end
    return temp 
end

function config_manager:CreateCultivationConfig()
    local cultivation_file = csv.Load("cultivation")
    local config = {}
    for idx,item in pairs(cultivation_file) do 
         if not config[item.cultivation_type] then
            config[item.cultivation_type] = {} 
         end

         table.insert(config[item.cultivation_type],item) 
    end
    return config
end

--解析宿命武器升星表
function config_manager:CreateWeaponStarUpgradeConfig()
    local config = csv.Load("weapon_star_upgrade")
    local weapon_star_upgrade_config = {}
    local skill_weapon_config = {}
    for _,weapon_star_conf in ipairs(config) do
        skill_weapon_config[weapon_star_conf.skill_id] = {weapon_id = weapon_star_conf.weapon_id, star_level = weapon_star_conf.level}
        if not weapon_star_upgrade_config[weapon_star_conf.weapon_id] then
            weapon_star_upgrade_config[weapon_star_conf.weapon_id] = {}
        end
        weapon_star_upgrade_config[weapon_star_conf.weapon_id][weapon_star_conf.level] = weapon_star_conf
    end
    return weapon_star_upgrade_config, skill_weapon_config
end

function config_manager:CreateEvolutionConfig()
    local evolution_file = csv.Load("evolution")
    local config = {}
    for k,conf_info in pairs(evolution_file) do
        local template_id_conf = conf_info
        template_id_conf.template_id = conf_info.template_id
        --需要成就条件
        template_id_conf.achievement_conf = {}
        local achievement_id_iter = string.gmatch(conf_info.type .. "|", "(%d+)|")
        local achievement_num_iter = string.gmatch(conf_info.need_num .. "|", "(%d+)|")
        local achievement_id, achievement_num = achievement_id_iter(), achievement_num_iter()
        while achievement_id and achievement_num do
            template_id_conf.achievement_conf[tonumber(achievement_id)] = tonumber(achievement_num)
            achievement_id, achievement_num = achievement_id_iter(), achievement_num_iter()
        end
        --需要消耗
        template_id_conf.cost_conf = {}
        local cost_id_iter = string.gmatch(conf_info.resouce_ids .. "|", "(%d+)|")
        local cost_num_iter = string.gmatch(conf_info.resouce_nums .. "|", "(%d+)|")
        local cost_id, cost_num = cost_id_iter(), cost_num_iter()
        while cost_id and cost_num do
            template_id_conf.cost_conf[tonumber(cost_id)] = tonumber(cost_num)
            cost_id, cost_num = cost_id_iter(), cost_num_iter()
        end

        config[tonumber(conf_info.template_id)] = template_id_conf
    end
    return config
end

function config_manager:CreateResourceRecycleConfig()
    local recycle_name_config = csv.Load("resource_recycle_random_text")
    local config = {}
    for k,conf_info in pairs(recycle_name_config) do
        config[tonumber(conf_info.ID)] = conf_info
    end
    return config
end

function config_manager:CreateVanityMazeConfig()
    local vanity_maze_config = csv.Load("vanity_maze")
    local config = {}
    for k,conf_info in pairs(vanity_maze_config) do
        if config[conf_info.week] == nil then
            config[conf_info.week] = {}
        end
        config[conf_info.week][conf_info.map_id] = conf_info
    end
    return config
end

function config_manager:LoadFromCSV(locale, need_translate)
    local need_change = platform_manager:GetChannelInfo().change_language_dir

    if need_translate then
        csv.Init("res/data/", locale,need_change)
    else
        csv.Init("res/data/") 
    end

    self.server_config = self:ParseServerConfig(csv.Load("server"))

    self.resource_config = csv.Load("resource")

    self.adventure_maze_config = csv.Load("adventure_maze")

    self.event_config = csv.Load("event")

    self.mercenary_config = csv.Load("mercenary")

    self.active_skill_config = self:ParseActiveSkill()
    self.passive_skill_config = csv.Load("passive_skill")
    self.cooperative_skill_config = csv.Load("cooperative_skill")
    self.skill_animation_config = csv.Load("skill_animation")

    self.monster_config = csv.Load("monster")
    self.mercenary_exp_config = csv.Load("mercenary_exp")

    self.scene_effect_config = csv.Load("scene_effect")
    self.scene_action_config = csv.Load("scene_action")
    self.role_effect_config  = csv.Load("role_effect")
    self.role_action_config = csv.Load("role_action")

    self.wakeup_info_config = self:ParseWakeUpConfig(csv.Load("wakeup_info"))

    self.mining_dig_info_config = csv.Load("mining_dig_info")
    self.mining_pickaxe_config = csv.Load("mining_pickaxe")
    self.mining_quarry_config = csv.Load("mining_quarry")
    self.mining_refresh_config = csv.Load("mining_refresh_info")
    self.mining_event_config = self:ParseMineEvent(csv.Load("cave_event"))
    self.mining_random_event_occupy_config = csv.Load("mining_random_occupy")
    self.mining_random_event_random_config = csv.Load("mining_random")
    self.mining_random_event_hunt_config = csv.Load("mining_random_treasure_hunt")
    self.mining_random_activity_config = csv.Load("mining_random_activity")
    

    self.item_config = csv.Load("item")
    self.bag_info_config = csv.Load("bag_info")
    self.weapon_forge_config = csv.Load("weapon_forge")
    self.weapon_forge_extra_config = csv.Load("weapon_forge_extra")

    self.destiny_skill_config = csv.Load("destiny_skill")
    self.destiny_forge_config = csv.Load("destiny_forge")

    self.area_info_config = csv.Load("area_info")

    self.adventure_income_config = csv.Load("adventure_income")

    self.maze_background_config = csv.Load("maze_background")

    self.achievement_config = self:ParseAchievement(csv.Load("achievement"))

    self.carnival_token_config = csv.Load("carnival_token")

    self.quest_mail_config = csv.Load("quest_mail")

    self.quest_random_mail_config = csv.Load("quest_random_mail")

    self.mercenary_soul_stone_config = csv.Load("mercenary_soul")

    self.mercenary_evolution_config = csv.Load("mercenary_evolution")
    self.activity_config = csv.Load("liveness")
    self.liveness_value_reward_config = csv.Load("liveness_value_reward")

    self.mercenary_contract_config = {}

    self:ParseContractConifg(1, csv.Load("mercenary_contract1"))
    self:ParseContractConifg(2, csv.Load("mercenary_contract2"))

    self.leader_contract_config = csv.Load("leader_contract")

    self.alchemy_prayer_config = csv.Load("daily_alchemy_prayer")

    self.guild_boss_info_list_config = csv.Load("guild_boss_info")
    self.guild_boss_cost_list_config = csv.Load("guild_boss_ticket")

    self:ParseFundConfig(csv.Load("fund"))

    self.pvp_buy_times_config = csv.Load("pvp_buy_times")

    -- 符文
    self.rune_config = csv.Load("rune")
    self.rune_exp_config = csv.Load("rune_exp")
    self.rune_draw_config = csv.Load("rune_draw")
    self.rune_bag_config = csv.Load("rune_bag_buy")
    self.rune_property_config = self:CreateRunePropertyConfig()

    --矿车
    self.tramcar_config = csv.Load("tramcar")
    self.tramcar_buy_rob_config = csv.Load("tramcar_buy_rob")
    self.tramcar_buy_escort_config = csv.Load("tramcar_buy_escort")

    --佣兵兑换
    self.mercenary_exchange_config = self:CreateMercenaryExchangeConfig()

    self:ParseSceneEffect()

    self:ParsePassiveSkill()

    --解析出合体技中需要存在的佣兵
    self:ParseCoopSkill()

    self:ParseMercenaryLibrary()

    self:ParseMaze()

    -- 合战配置
    self.campaign_level_config = csv.Load("campaign_level")
    -- 功能开启配置
    self.open_permanent_config = csv.Load("open_permanent")

    --TAG:MASTER_MERGE
    self.merchant_ref_config = csv.Load("merchant_ref")
    self.daily_additional_config = csv.Load("daily_additional")
    self.adventure_buy_config = csv.Load("adventure_buy")

    --宝具等级配置表
    self.mercenary_artifact_config = self:CreateMercenaryArtifactConfig()

    --矿山配表
    self.mine_info_config = csv.Load("mine")
    self.mine_buy_rob_config = csv.Load("mine_buy_rob")
    self.mine_buy_refresh_config = csv.Load("mine_buy_refresh")

    self.mine_buy_rob_config = csv.Load("mine_buy_rob")
    self.mine_buy_refresh_config = csv.Load("mine_buy_refresh")
    self.weapon_star_upgrade_config, self.skill_weapon_config = self:CreateWeaponStarUpgradeConfig()
    self.weapon_total_star_config = csv.Load("weapon_total_star")

    --修炼配置表
    self.cultivation_config = self:CreateCultivationConfig()

    --天梯赛购买配表
    self.ladder_buy_config = self:CreatePriceConfig() 
    --称号配表
    self.title_config = csv.Load("title") 
    self.ladder_level_config = csv.Load("pvp_ladder_grouping")

    --主角换装配置表
    self.evolution_config = self:CreateEvolutionConfig()

    --炼化材料奖励配表
    self.resource_recycle_reward_config = csv.Load("recycle_reward")
    self.resource_recycle_random_name = self:CreateResourceRecycleConfig()

    --虚空冒险关卡表
    self.vanity_maze_config = self:CreateVanityMazeConfig()
    self.vanity_buy_other_pay_config = csv.Load("vanity_pay")
end

function config_manager:ChangeLocale(locale)
    local default = "locale.csv_" .. locale
    local dir = platform_manager:GetChannelInfo().change_language_dir
    if dir then
        default = string.format("locale.%s.csv_",dir) .. locale 
    end
    local succ, map = pcall(require, (default)) 
    
    function do_reload(config_name, conf_list, field_list)
        local m = map[config_name]
        if not m then
           return 
        end


        for ID, conf in pairs(conf_list) do
            for i, field in ipairs(field_list) do
                local content = m[ID .. "_" .. field]

                if "achievement" == config_name then
                    content = m[conf["ID"] .. "_" .. field]
                end

                if "cave_event" == config_name then
                    content = m[conf["ID"] .. "_" .. field]
                end

                if content then
                    conf[field] = content
                end
            end
        end
    end

    do_reload("resource", self.resource_config, {"name", "desc"})

    do_reload("active_skill", self.active_skill_config, {"name", "desc"})
    do_reload("passive_skill", self.passive_skill_config, {"name", "desc"})
    do_reload("carnival_token", self.carnival_token_config, {"name", "desc"})
    do_reload("cooperative_skill", self.cooperative_skill_config, {"name", "desc"})
    do_reload("destiny_skill", self.destiny_skill_config, {"name", "desc", "lock_desc"})
    do_reload("event", self.event_config, {"name", "desc"})
    do_reload("item", self.item_config, {"name", "desc"})
    do_reload("mercenary", self.mercenary_config, {"name", "introduction", "slogan", "artifact_name" })
    do_reload("monster", self.monster_config, {"name"})
    do_reload("leader_contract", self.leader_contract_config, {"desc"})
    do_reload("mining_quarry", self.mining_quarry_config, {"name"})
    do_reload("mining_dig_info",self.mining_dig_info_config ,{"name"})
    do_reload("rune", self.rune_config, {"name", "desc"})
    do_reload("tramcar", self.tramcar_config, {"name"})
    
    do_reload("quest_mail", self.quest_mail_config, {"title", "content", "writer"})
    do_reload("quest_random_mail", self.quest_random_mail_config, {"title", "content", "writer"})

    do_reload("campaign_level", self.campaign_level_config, {"title", "desc"})

    for _, conf_list in pairs(self.achievement_config) do
        do_reload("achievement", conf_list, {"desc"})
    end
 
    for _, conf_list in pairs(self.mining_event_config) do
        do_reload("cave_event", conf_list, {"name", "desc"})
    end
    
    do_reload("area_info", self.area_info_config, {"name", "desc"})

    do_reload("liveness", self.activity_config, {"active_des", "active_title"})
end

do
    config_manager:Init()
end

return config_manager
