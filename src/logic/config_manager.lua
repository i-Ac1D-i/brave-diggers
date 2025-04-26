local constants = require "util.constants"
local platform_manager = require "logic.platform_manager"
local csv = require "util.csv"

local mt = {}
mt.__index = function(t, key)
    local val = rawget(t, key .. "_config")
    return val
end

local config_manager = {}
setmetatable(config_manager, mt)

function config_manager:Init()

    local platform_manager = require "logic.platform_manager"
    local locale = platform_manager:GetLocale()

    if not self.cur_locale then
        self:LoadFromCSV(locale, platform_manager:NeedTranslate())

    elseif self.cur_locale ~= locale then
        self:ChangeLocale(locale)
    end
    
    self.cur_locale = locale
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
-- function config_manager:CsvLoad(file_name)
--     local res
--     local platform_manager = require "logic.platform_manager"
--     local file_path = string.format("res/language/%s/data/%s.csv", platform_manager:GetLocale(), file_name)
--     if not cc.FileUtils:getInstance():isFileExist(file_path) then
--         res = csv.Load(file_name)
--     else
--         res = csv.Load(file_name)
--     end
-- end

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

function config_manager:LoadFromCSV(locale, need_translate)
    if need_translate then
        csv.Init("res/data/", locale)
    else
        csv.Init("res/data/")
    end

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

    self.mercenary_contract_config = {}

    self:ParseContractConifg(1, csv.Load("mercenary_contract1"))
    self:ParseContractConifg(2, csv.Load("mercenary_contract2"))
    self.merchant_ref_config = csv.Load("merchant_ref")
    self.leader_contract_config = csv.Load("leader_contract")

    self.alchemy_prayer_config = csv.Load("daily_alchemy_prayer")

    self:ParseFundConfig(csv.Load("fund"))

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

    self.adventure_buy_config = csv.Load("adventure_buy")
end

function config_manager:ChangeLocale(locale)

    local succ, map = pcall(require, ("locale.csv_" .. locale))

    local changeId = platform_manager:GetChannelInfo().config_manager_change_locale_achievement_id_use

    function do_reload(config_name, conf_list, field_list)
        local m = map[config_name]
        if not m then
           return 
        end
        local index=1;
        for ID, conf in pairs(conf_list) do
            for i, field in ipairs(field_list) do
                
                local content = m[ID .. "_" .. field]

                --r2多语言修改后会造成ID对不上，而应该使用conf中的ID
                if changeId and "achievement" == config_name then
                    content = m[conf["ID"] .. "_" .. field]
                end

                if content then
                    conf[field] = content
                end
            end
            index = index + 1
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
end

do
    config_manager:Init()
end

return config_manager
