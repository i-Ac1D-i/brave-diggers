local network = require "util.network"
local config_manager = require "logic.config_manager"
local skill_manager = require "logic.skill_manager"
local title_logic = require "logic.title"
local common_function = require "util.common_function"
local lang_constants = require "util.language_constants"
local utils = require "util.utils"
local mercenary_config = config_manager.mercenary_config
local mercenary_exp_config = config_manager.mercenary_exp_config
local passive_skill_config = config_manager.passive_skill_config
local cooperative_skill_config = config_manager.cooperative_skill_config
local mercenary_soul_stone_config = config_manager.mercenary_soul_stone_config
local mercenary_contract_config = config_manager.mercenary_contract_config
local leader_contract_config = config_manager.leader_contract_config
local feature_config = require "logic.feature_config"
local user_logic
local adventure_logic
local resource_logic
local destiny_logic
local time_logic
local reward_logic
local achievement_logic
local carnival_logic
local daily_logic
local reminder_logic
local sns_logic
local guild_logic
local mine_logic 

local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local platform_manager = require "logic.platform_manager"

local bit_extension = require "util.bit_extension"
local configuration = require "util.configuration"
local common_function_util = require "util.common_function"

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local MERCENARY_REPLACE_MODE = constants.MERCENARY_REPLACE_MODE
local PASSIVE_EFFECT_TYPE = constants.PASSIVE_SKILL_EFFECT_TYPE
local MAX_FORMATION_NUM = constants.MAX_FORMATION_NUM
local PROPERTY_TYPE =  constants.PROPERTY_TYPE

local FORCE_LV_COST_RESOURCE_NUM = constants["FORCE_LV_COST_RESOURCE_NUM"]
local MERCENARY_AETIFACT_STATUS = constants["MERCENARY_AETIFACT_STATUS"]

local CRAFT_COST_RESOURCE = client_constants["CRAFT_COST_RESOURCE"]
local CLIENT_GUILDWAR_STATUS = client_constants["CLIENT_GUILDWAR_STATUS"]

local PROMPT_MAP =
{
    ["failure"] = "unknown_error",

    ["already_in_exploring_list"] = "mercenary_already_in_formation",
    ["cant_select_self"] = "mercenary_cant_select_self",
    ["exploring_list_is_full"] = "mercenary_formation_list_is_full",

    ["cant_forge_weapon"] = "mercenary_cant_forge_weapon",
    ["weapon_lv_reach_max"] = "mercenary_weapon_lv_reach_max",
    ["forge_failure"]   = "mercenary_weapon_forge_failure",

    ["wakeup_reach_max"] = "mercenary_wakeup_reach_max",

    ["force_lv_reach_max"] = "mercenary_force_lv_reach_max",

    ["is_not_in_exploring_list"] = "mercenary_not_in_formation",
    ["must_have_a_mercenary_in_exploring_list"] = "must_have_a_mercenary_in_formation",

    ["cant_fire"] = "mercenary_cant_fire",
    ["cant_fire_a_exploring_mercenary"] = "mercenary_cant_fire_in_formation",
    ["illegal_operation"] = "mercenary_illegal_operation",
    ["mercenary_num_limit"] = "mercenary_num_limit",
}

local PROPERTY_TYPE_NAME = constants.PROPERTY_TYPE_NAME
local troop = {}

function troop:Init()

    user_logic = require "logic.user"
    adventure_logic = require "logic.adventure"
    resource_logic = require "logic.resource"
    destiny_logic = require "logic.destiny_weapon"
    time_logic = require "logic.time"
    reward_logic = require "logic.reward"
    achievement_logic = require "logic.achievement"
    carnival_logic = require "logic.carnival"
    daily_logic = require "logic.daily"
    reminder_logic = require "logic.reminder"
    sns_logic = require "logic.sns"
    guild_logic = require "logic.guild"
    mine_logic = require "logic.mine"

    self.leader_name = ""

    self.leader = nil

    self.leader_bp = 0

    self.mercenary_list = {}

    self.extra_dodge = 0
    self.extra_speed = 0
    self.extra_authority = 0
    self.extra_defense = 0

    self.mercenary_num = 0
    self.contract_bp = 0

    self.cooperative_skill_list = {}
    self.all_mercenary_template_ids = {}
    self.stack_list = {}
    self.skin_template_ids = {}
    
    self.mercenary_library = {}
    self.weapon_list = {}
    self.formation_name_list = {}

    self.forge_info = {}
    self.forge_info.mercenary_id = 0
    self.forge_info.lucky_num = 0

    self.formations = {}
    for i = 1, #constants["ALL_FORMATIONS"] do
        local id = constants["ALL_FORMATIONS"][i]

        local formation = {}
        self.formations[id] = formation
        formation.battle_point = 0 
        formation.property_changed = true

        formation.dodge = 0
        formation.speed = 0
        formation.authority = 0
        formation.defense = 0

        self.weapon_list[id] = 0
    end

    self.mercenarys_cut_down_time = {}

    --此formation_id 和服务端保持一致
    self.cur_formation_id = 0

    --仅用于客户端显示用，在更换完阵容后，也要重置
    self.client_formation_id = 0

    --是否有限时英雄到期
    self.have_end_mercenary = false

    self.reduce_search_times = 0

    --虚空大冒险阵容和可用英雄列表
    self.vanity_good_list = nil
    self.is_query_vanity_maze = false
    self.vanity_mercenarys_list = {}
    self.vanity_troop = {}
    self.vanity_maze_battle_number_list = {}
    self.vanity_exp_get_mercenary_list = {}

    self:RegisterMsgHandler()
end

--刷新 随机事件次数
function troop:DailyClear()
    if self.vanity_maze_state_list then
        self.vanity_maze_state_list = nil
    end
    if self.vanity_good_list then
        self.vanity_good_list = nil
    end
    --请求查询阵容信息
    self:QueryVantiyToopInfo()
end

function troop:SetLeaderName(leader_name, leader_bp)
    if leader_name then
        self.leader_name = leader_name
    end

    if leader_bp then
        self.leader_bp = leader_bp
    end
end

function troop:SetLeaderBP(bp)
    self.leader_bp = bp

    if self:IsMercenaryInFormation(self.leader, self.cur_formation_id) then
        self:CalcTroopBP(self.cur_formation_id)
    end
end

function troop:GetLeaderName()
    return self.leader_name
end

function troop:GetLeader()
    return self.leader
end

function troop:GetLeaderTempateId()
    return self.leader.template_id
end

function troop:GetFormationNameList()
    return self.formation_name_list
end

function troop:MercenaryIsInLibrary(template_id)
    if not self.mercenary_library[template_id] then
        self.mercenary_library[template_id]  = 0
        return true
    else
        return false
    end
end

--设定客户端用于显示的id
function troop:SetClientFormationId(formation_id)
    self.client_formation_id = formation_id
end

function troop:GetClientFormationId()
    return self.client_formation_id
end

--获得佣兵可以在图书馆中招募的次数
function troop:GetMercenaryLibraryCount(template_id)
    return self.mercenary_library[template_id]
end

function troop:Update(elapsed_time)
end

function troop:GetCurFormationId()
    return self.cur_formation_id
end

--设定默认阵容id
function troop:SetCurFormationId(formation_id)
    self.cur_formation_id = formation_id
end

function troop:GetMercenaryList()
    return self.mercenary_list
end

--获取某个阵容中的佣兵列表
function troop:GetFormationMercenaryList(formation_id)
    formation_id = formation_id or self.cur_formation_id
    self:CheckMercenaryLimiteOverTime()
    return self.formations[formation_id]
end

--返回正在探索的佣兵个数
function troop:GetExploringMercenaryNum(formation_id)
    if formation_id then
        return #self.formations[formation_id]
    else
        return #self.formations[self.cur_formation_id]
    end
end

function troop:SetFormationCapacity(num)
    self.formation_capacity = num

    reminder_logic:CheckFormationReminder()
end

function troop:GetFormationCapacity()
    return self.formation_capacity
end

function troop:GetCampCapacity()
    return self.camp_capacity
end

function troop:SetCampCapacity(num)
    self.camp_capacity = num
end

function troop:UpdateSoulStone(soul_type, num)
    if not self.mercenary_library[soul_type] then
        self.mercenary_library[soul_type] = num

    else
        self.mercenary_library[soul_type] = self.mercenary_library[soul_type] + num
    end
end

--获取佣兵数量
function troop:GetCurMercenaryNum()
    return self.mercenary_num
end

--获取佣兵信息
function troop:GetMercenaryInfo(mercenary_id)
    return self.mercenary_list[mercenary_id]
end

function troop:GetFormationWeaponId(formation_id)
    return self.weapon_list[formation_id]
end

function troop:SetFormationWeaponId(formation_id, weapon_id)
    self.weapon_list[formation_id] = weapon_id

    if self.client_formation_id == formation_id then
        self.formations[formation_id].property_changed = true
    end
end

function troop:SetFormationPropertyChanged(formation_id)
    self.formations[formation_id].property_changed = true
end

function troop:IsWeaponEquipped(formation_id, weapon_id)
    formation_id = formation_id or self.cur_formation_id 
    return self.weapon_list[formation_id] == weapon_id
end

function troop:GetCurWeaponId()
    return self.weapon_list[self.cur_formation_id]
end

--检测佣兵是否在营帐中
function troop:MercenaryIsInMercenaryList(template_id)
    for instance_id, mercenary in pairs(self.mercenary_list) do
        if mercenary.template_info.ID == template_id then
            return true
        end
    end

    return false
end

--初始化一个mercenary info
function troop:InitMercenaryInfo(mercenary)
    self.mercenary_list[mercenary.instance_id] = mercenary

    self.mercenary_num = self.mercenary_num + 1

    local template_info = mercenary_config[mercenary.template_id]
    mercenary.template_info = template_info

    self:CalcMercenaryProperty(mercenary)

    --主角得先计算契约提供的战力
    if mercenary.is_leader then
        self:CalcLeaderContract()
    end
    self:CalcMercenaryBP(mercenary)
end

function troop:InitMercenaryInfoByConfig(mercenary)

    mercenary.exp = 0
    mercenary.weapon_lv = 0
    mercenary.is_open_artifact = false
    mercenary.force_lv = 0
    mercenary.wakeup = 1
    mercenary.level = 1
    mercenary.formation_info = 0
    mercenary.contract_lv = 0
    mercenary.expire_time = 0

    local template_info = mercenary_config[mercenary.template_id]
    if template_info then
        mercenary.template_info = template_info
    else
        return nil
    end

    self:CalcMercenaryProperty(mercenary)

    self:CalcMercenaryBP(mercenary)

    return mercenary
end

function troop:GetVanityMercenarys(instance_id)
    for k,vanity_mercenary in pairs(self.vanity_mercenarys_list) do
        if vanity_mercenary.instance_id == instance_id then
            return self:InitMercenaryInfoByConfig(vanity_mercenary)
        end
    end
    return nil
end

function troop:GetVanityTroop()
    if self.vanity_formation then
        return self.vanity_formation
    end
    return {}
end

function troop:GetVanityBackPlayTroop()
    if self.vanity_back_play_formation then
        return self.vanity_back_play_formation
    end
    return {}
end

function troop:InitVanityTroop()

    --进行排序为零的放到最后面
    local temp = {}
    local temp1 = {}
    for k,v in pairs(self.vanity_troop) do
        if v == 0 then
            table.insert(temp, 0)
        else
            table.insert(temp1, v)
        end
    end

    for k,v in pairs(temp) do
        table.insert(temp1, v)
    end

    self.vanity_troop = temp1

    local formation = {}
    for k,v in pairs(self.vanity_troop) do
        if v ~= 0 then
            local mercenary = self:GetVanityMercenarys(v)
            table.insert(formation,mercenary)
        end
    end
    self.vanity_formation = formation
end

--虚空阵容初始化
function troop:InitVanityBackPlayTroop(troop)
    print("虚空阵容初始化  ")
    local formation = {}
    for k,v in pairs(troop) do
        if v ~= 0 then
            print("init_back mercenary id ==", v)
            local mercenary = self:GetVanityMercenarys(tonumber(v))
            table.insert(formation,mercenary)
        end
    end
    self.vanity_back_play_formation = formation
end


--初始化阵容信息
function troop:InitFormationsInfo(formation_info, formation_id)
    if formation_info then
        self.formations[formation_id] = {}
        for i = 1, #formation_info do
            local mercenary = self.mercenary_list[formation_info[i]]
            self.formations[formation_id][i] = mercenary
        end

        self.formations[formation_id].property_changed = true
    end
end

--计算佣兵属性
function troop:CalcMercenaryProperty(mercenary)
    local template_info = mercenary.template_info
    --加载宝具信息
    if mercenary.is_open_artifact then
        mercenary.dodge = template_info.artifact_dodge
        mercenary.speed = template_info.artifact_speed
        mercenary.authority = template_info.artifact_authority
        mercenary.defense = template_info.artifact_defense
        --根据宝具等级加载四维加成
        local config = config_manager.mercenary_artifact_config[mercenary.template_id]
        if config and config[mercenary.artifact_lv] then
            config = config[mercenary.artifact_lv]
            mercenary.defense = mercenary.defense + config["sum_defense"]   --防御
            mercenary.speed = mercenary.speed + config["sum_speed"]   --先攻
            mercenary.authority  = mercenary.authority  + config["sum_authority"]  --王者
            mercenary.dodge = mercenary.dodge + config["sum_dodge"]   --闪避
        end
    else
        mercenary.dodge = 0
        mercenary.speed = 0
        mercenary.authority = 0
        mercenary.defense = 0
    end

    if mercenary.force_lv == constants["MAX_FORCE_LEVEL"] and not mercenary.is_leader then
        local prop_name = PROPERTY_TYPE_NAME[mercenary.ex_prop_type]
        mercenary[prop_name] = mercenary[prop_name] + mercenary.ex_prop_val * constants["CONTRACT_FORCE_UP"][mercenary.contract_lv]
    end

    local contract_level_config = mercenary_contract_config[mercenary.contract_lv]
    if contract_level_config and contract_level_config[template_info.ID] then
        local contract_config = contract_level_config[template_info.ID]
        mercenary.speed = mercenary.speed + contract_config.speed
        mercenary.defense = mercenary.defense + contract_config.defense
        mercenary.dodge = mercenary.dodge + contract_config.dodge
        mercenary.authority = mercenary.authority + contract_config.authority
    end
end

function troop:GetTroopInfo(formation_id)
    local troop_info
    
    troop_info = common_function_util.Clone(self:GetFormationMercenaryList(formation_id))
    troop_info.speed, troop_info.authority, troop_info.dodge, troop_info.defense = self:GetTroopProperty(formation_id)

    if formation_id == constants["GUILD_WAR_TROOP_ID"] then 
        for i = 1, 5 do
           guild_logic:CalcMemberBuffInfo(guild_logic.own_member_info, troop_info, i)
        end
    end
    troop_info.template_id_list = {}
    for i = 1, #troop_info do
      troop_info.template_id_list[i] = troop_info[i].template_id 
    end

    return troop_info
end
--更新称号属性
function troop:UpdateTitleProperty()
    for formation_id,cur_formation in pairs(self.formations) do
        cur_formation.property_changed = true
        self:CalcTroopBP(formation_id)
        self:GetTroopProperty(formation_id) 
    end
end

--TODO
--计算军团的战斗力(默认更新军团战斗力的显示)
function troop:CalcTroopBP(formation_id, update_battle_point)
    local _, battle_point = destiny_logic:GetWeaponTotalStarInfo()
    local property = title_logic:GetProperty()
    battle_point = battle_point + property.bp
    formation_id = formation_id or self.client_formation_id
    local cur_formation = self.formations[formation_id]
    
    for i = 1, #cur_formation do
        local mercenary = cur_formation[i]
        battle_point = mercenary.battle_point + battle_point
    end

    cur_formation.battle_point = battle_point

    --更新最高战力 任务中
    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["max_bp"], cur_formation.battle_point)
   
    if self.client_formation_id == formation_id or update_battle_point then
        graphic:DispatchEvent("update_battle_point", cur_formation.battle_point)
    end
end

--计算虚空阵容战斗力
function troop:CalcVanityTroopBP(update_battle_point)
    local battle_point = 0
    
    for i = 1, #self.vanity_formation do
        local mercenary = self.vanity_formation[i]
        battle_point = mercenary.battle_point + battle_point
    end
    
    self.vanity_formation.battle_point = battle_point

    if update_battle_point then
        graphic:DispatchEvent("update_battle_point", battle_point)
    end
end

--获取当前战力
function troop:GetTroopBP(formation_id)
    local cur_formation_id = formation_id or self.client_formation_id
    return self.formations[cur_formation_id].battle_point
end

function troop:GetVanityTroopProperty()

    local cur_formation = self:GetVanityTroop()

    cur_formation.special_skill_list = {}

    local cooperative_skill_list = {}
    local all_mercenary_template_ids = {}

    cur_formation.stack_list = {}
    cur_formation.all_mercenary_template_ids = {}

    cur_formation.dodge = 0
    cur_formation.speed = 0
    cur_formation.authority = 0
    cur_formation.defense = 0


    cur_formation.extra_speed, cur_formation.extra_dodge, cur_formation.extra_authority, cur_formation.extra_defense = 0, 0, 0, 0

    for i = 1, #cur_formation do
        local mercenary = cur_formation[i]
        local template_info = mercenary.template_info
        local template_id = mercenary.template_id

        cur_formation.dodge = mercenary.dodge + cur_formation.dodge
        cur_formation.speed = mercenary.speed + cur_formation.speed
        cur_formation.authority = mercenary.authority + cur_formation.authority
        cur_formation.defense = mercenary.defense + cur_formation.defense

        all_mercenary_template_ids[template_id] = all_mercenary_template_ids[template_id] and all_mercenary_template_ids[template_id] + 1 or 1

        for i = 1, 3 do
            local skill_id = template_info["skill"..i]
            if skill_id ~= 0 then
                cur_formation.special_skill_index = 0
                skill_manager:AddPassiveSkill(cur_formation, skill_id)
            end
        end

        for i = 1, 2 do
            local ex_skill = template_info["ex_skill" .. i]
            if ex_skill ~= 0 then
                cooperative_skill_list[ex_skill] = true
            end
        end
        
    end

    if cur_formation.special_skill_list then
        for i, skill_id in ipairs(cur_formation.special_skill_list) do
            cur_formation.special_skill_index = i
            skill_manager:AddPassiveSkill(cur_formation, skill_id, true)
        end

        cur_formation.dodge = cur_formation.dodge + cur_formation.extra_dodge
        cur_formation.authority = cur_formation.authority + cur_formation.extra_authority
        cur_formation.defense = cur_formation.defense + cur_formation.extra_defense
        cur_formation.speed = cur_formation.speed + cur_formation.extra_speed
    end

    cur_formation.property_changed = false

    return cur_formation.speed, cur_formation.authority, cur_formation.dodge, cur_formation.defense
end

--计算军团的基础属性
function troop:GetTroopProperty(formation_id)
    formation_id = formation_id or self.client_formation_id

    local cur_formation = self.formations[formation_id]

    if not cur_formation.property_changed then
        return cur_formation.speed, cur_formation.authority, cur_formation.dodge, cur_formation.defense
    end

    for k, v in pairs(self.cooperative_skill_list) do
        self.cooperative_skill_list[k] = nil
    end

    for id, _ in pairs(self.all_mercenary_template_ids) do
        self.all_mercenary_template_ids[id] = 0
    end

    for id, _ in pairs(self.stack_list) do
        self.stack_list[id] = 0
    end

    cur_formation.special_skill_list = {}

    local cooperative_skill_list = self.cooperative_skill_list
    local all_mercenary_template_ids = self.all_mercenary_template_ids

    cur_formation.stack_list = self.stack_list
    cur_formation.all_mercenary_template_ids = self.all_mercenary_template_ids

    local total_star, total_add_bp, total_star_conf = destiny_logic:GetWeaponTotalStarInfo()
    cur_formation.speed = total_star_conf.speed or 0
    cur_formation.dodge = total_star_conf.dodge or 0
    cur_formation.authority = total_star_conf.authority or 0
    cur_formation.defense = total_star_conf.defense or 0
    --TODO
    local property = title_logic:GetProperty()
    cur_formation.dodge = property.dodge + cur_formation.dodge
    cur_formation.speed = property.speed + cur_formation.speed
    cur_formation.authority = property.authority + cur_formation.authority
    cur_formation.defense = property.defense + cur_formation.defense

    cur_formation.extra_speed, cur_formation.extra_dodge, cur_formation.extra_authority, cur_formation.extra_defense = 0, 0, 0, 0

    local cur_weapon_id = self.weapon_list[formation_id]

    for i = 1, #cur_formation do
        local mercenary = cur_formation[i]
        local template_info = mercenary.template_info
        local template_id = mercenary.template_id

        cur_formation.dodge = mercenary.dodge + cur_formation.dodge
        cur_formation.speed = mercenary.speed + cur_formation.speed
        cur_formation.authority = mercenary.authority + cur_formation.authority
        cur_formation.defense = mercenary.defense + cur_formation.defense

        all_mercenary_template_ids[template_id] = all_mercenary_template_ids[template_id] and all_mercenary_template_ids[template_id] + 1 or 1

        if mercenary.is_leader and cur_weapon_id ~= 0 then
            cur_formation.special_skill_index = 0
            local leader_skill_id = destiny_logic:GetCurWeaponSkillId(cur_weapon_id)
            skill_manager:AddPassiveSkill(cur_formation, leader_skill_id)
        else
            for i = 1, 3 do
                local skill_id = template_info["skill"..i]
                if skill_id ~= 0 then
                    cur_formation.special_skill_index = 0
                    skill_manager:AddPassiveSkill(cur_formation, skill_id)
                end
            end

            for i = 1, 2 do
                local ex_skill = template_info["ex_skill" .. i]
                if ex_skill ~= 0 then
                    cooperative_skill_list[ex_skill] = true
                end
            end
        end
    end

    --检测合体技能
    for skill_id, _ in pairs(self.cooperative_skill_list) do
        local can_use = skill_manager:CheckCoopSkillCanUse(self, skill_id)

        local coop_skill = cooperative_skill_config[skill_id]

        if can_use and coop_skill then
            --只用检测被动技能
            for i = 1, 3 do
                local skill_id = coop_skill["real_skill" .. i]
                if skill_id ~= 0 then
                    cur_formation.special_skill_index = 0
                    skill_manager:AddPassiveSkill(cur_formation, skill_id)
                end
            end
        end
    end

    if cur_formation.special_skill_list then
        for i, skill_id in ipairs(cur_formation.special_skill_list) do
            cur_formation.special_skill_index = i
            skill_manager:AddPassiveSkill(cur_formation, skill_id, true)
        end

        cur_formation.dodge = cur_formation.dodge + cur_formation.extra_dodge
        cur_formation.authority = cur_formation.authority + cur_formation.extra_authority
        cur_formation.defense = cur_formation.defense + cur_formation.extra_defense
        cur_formation.speed = cur_formation.speed + cur_formation.extra_speed
    end

    cur_formation.property_changed = false

    return cur_formation.speed, cur_formation.authority, cur_formation.dodge, cur_formation.defense
end

--计算佣兵战斗力
function troop:CalcMercenaryBP(mercenary, template_info)
    local template_info = template_info or mercenary.template_info

    local mlevel = mercenary.level
    local mwakeup = mercenary.wakeup
    if mwakeup > template_info.max_wakeup then
        mwakeup = template_info.max_wakeup
    end

    local wakeup_config = config_manager.wakeup_info_config[mwakeup]

    local delta = 0

    for i = 1, 3 do
        local l = wakeup_config["damping_level" .. i]
        if mlevel > l then
            delta = delta + l * wakeup_config["damping_factor" .. i]
        else
            delta = delta + mlevel * wakeup_config["damping_factor" .. i]
        end
    end

    delta = (delta + mlevel * wakeup_config["damping_factor4"]) * wakeup_config["accumulated_value"] + wakeup_config["basic_value"]

    if mercenary.is_leader then
        local weapon_bp_factor = config_manager.destiny_forge_config[destiny_logic:GetWeaponLevel() + 1].bp_factor * 0.01

        delta = (delta * template_info.bp_factor + template_info.init_bp + self.leader_bp + self.contract_bp) * (1 + weapon_bp_factor)

    else
        local weapon_bp_factor = config_manager.weapon_forge_config[mercenary.weapon_lv + 1].bp_factor * 0.01
        --武器强化
        --根据宝具等级计算战力系数加成
        if mercenary.is_open_artifact and template_info.have_artifact_upgrade then
            local config = config_manager.mercenary_artifact_config[template_info.ID]
            if mercenary.artifact_lv == nil then
                --防止宝具等级为nil
                mercenary.artifact_lv = 0
            elseif config and mercenary.artifact_lv > #config then
                --超过了最大等级
                mercenary.artifact_lv = #config
            end
            
            if config and config[mercenary.artifact_lv] then
                local level_config = config[mercenary.artifact_lv]
                local quotiety = level_config["sum_bp"] or 0
                weapon_bp_factor = weapon_bp_factor + quotiety / 100 --重新计算战斗力
            end
        end
        delta = (delta * template_info.bp_factor + template_info.init_bp) * (1 + weapon_bp_factor) *(1 + mercenary.force_lv * 0.01)
    end

    mercenary.battle_point = math.ceil(delta)
end

--计算等级
function troop:CalcMercenaryLevel(mercenary)
    local cur_exp = mercenary.exp
    local wakeup_field = "wakeup_factor" .. mercenary.wakeup
    for i, conf in ipairs(mercenary_exp_config) do
        if cur_exp < conf[wakeup_field] then
            mercenary.level = conf.level
            mercenary.upgrade_need_exp = conf[wakeup_field]
            break
        end
    end
end

--获取佣兵经验
function troop:GetMercenaryExp(mercenary)
    local next_exp = mercenary_exp_config[mercenary.level]['wakeup_factor'..mercenary.wakeup]

    local start_exp = 0

    if mercenary.level > 1 then
        start_exp = mercenary_exp_config[mercenary.level-1]['wakeup_factor'..mercenary.wakeup]
    end

    return start_exp, next_exp
end

--分配经验
function troop:AllocMercenaryExp(instance_id, level_delta)
    local mercenary = self.mercenary_list[instance_id]

    if not mercenary then
        return
    end

    level_delta = level_delta or 1

    if mercenary.level + level_delta <= 1 then
        return
    end

    --升级值是否超过可以觉醒的等级，如果当前值 + 增量值 > 觉醒值 则重置增量值
    if mercenary.wakeup < mercenary.template_info.max_wakeup then
        if mercenary.level + level_delta > constants['CAN_WAKEUP_LEVEL'] then
            level_delta = constants['CAN_WAKEUP_LEVEL'] - mercenary.level
        end
    end

    local level = math.min(mercenary.level + level_delta, constants["MAX_LEVEL"])
    local need_exp = mercenary_exp_config[level-1]['wakeup_factor'..mercenary.wakeup] - mercenary.exp

    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["exp"], need_exp, true) then
        return
    end

    network:Send({alloc_mercenary_exp = { mercenary_id = instance_id, target_level = mercenary.level + level_delta }})
end

function troop:IsFirstOperation(formation_id)
    local ret = false
    if self.formations[formation_id] then 
        if #self.formations[formation_id] == 1 and self:IsMercenaryInFormation(self.leader, formation_id) then 
            ret = true 
        end  
    end

    return ret  
end

function troop:ResetFormation(formation_id)
    for index = #self.formations[formation_id] , 1 , -1 do
        local mercenary = self.formations[formation_id][index]
        mercenary.formation_info = bit_extension:SetBitNum(mercenary.formation_info, (formation_id - 1), false)
        table.remove(self.formations[formation_id], index)
    end

    self.leader.formation_info = bit_extension:SetBitNum(self.leader.formation_info, (formation_id - 1), true)
    table.insert(self.formations[formation_id], self.leader)
    
    self:CalcTroopBP(formation_id, false)
    self.formations[formation_id].property_changed = true
end

function troop:CheckGuildWarStatus(formation_id)
    local can_use_flag = true 

    if formation_id == constants["GUILD_WAR_TROOP_ID"] and guild_logic:IsEnterForCurrentWar() and guild_logic:GetCurStatus() >= CLIENT_GUILDWAR_STATUS["MATCHING"] then 
        can_use_flag = false
    end

    return can_use_flag
end

--添加佣兵到探索队列中, 空位上阵
function troop:InsertMercenaryToFormation(formation_id, instance_id, target_position)
    local mercenary = self.mercenary_list[instance_id]

    if #self.formations[formation_id] >= self.formation_capacity then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["exploring_list_is_full"])
        return
    end

    --佣兵已经在阵容中
    if self:IsMercenaryInFormation(mercenary, formation_id) then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["already_in_exploring_list"])
        return
    end

    if not self:CheckGuildWarStatus(formation_id) then 
        graphic:DispatchEvent("show_prompt_panel", "guild_formation_cant_use")
        return
    end

    if self:CheckMercenaryNumOverLimit(mercenary.template_id, formation_id, true) then
        return
    end

    network:Send({insert_formation = { formation_id = formation_id, instance_id = instance_id, position = target_position }})
end

--检测是否有限时英雄到期了
function troop:CheckMercenaryLimiteOverTime()
    local over_time = false
    for k,mercenary in pairs(self.mercenary_list) do
        if mercenary and mercenary.expire_time and mercenary.expire_time > 0 then
           local expire_time = math.max(0, mercenary.expire_time - time_logic:Now()) 
           if expire_time <= 0 then
                over_time = true
                self.mercenary_list[k] = nil
           end 
        end
    end

    if over_time then             
        self:Query_toop_info()
    end

    return over_time
end

function troop:Query_toop_info()
    self.have_end_mercenary = true
    network:Send({query_troop_info = {}})
end

--检测佣兵是否在阵容中
function troop:IsMercenaryInFormation(mercenary, formation_id)
    local bit_value = bit_extension:GetBitNum(mercenary.formation_info, (formation_id - 1))
    return bit_value == 1
end

--检查佣兵是否在矿山阵容中  
--[[
    return param1  -->是否在矿山阵容中
            param2 -->是矿山的状态是否在挖矿
]]
function troop:IsMercenaryInMineFormation(mercenary)
    for k,formation_id in pairs(constants["MINE_TROOP_ID"]) do
        if not mercenary.is_leader and self:IsMercenaryInFormation(mercenary, formation_id) then
            local status2 = true
            if mine_logic:GetMinesStatus(k) == client_constants.MINE_STATE.mining then
                status2 = false
            end
            return true, status2 ,formation_id
        end
    end
    return false, true , 0
end

--检查佣兵数量限制
function troop:CheckMercenaryNumOverLimit(template_id, formation_id, is_show_prompt)
    local num_limit = mercenary_config[template_id]["num_limit"]

    if num_limit and num_limit > 0 then
        local cur_num = 0
        local formation_mercenary_list = self:GetFormationMercenaryList(formation_id)
        for _,formation_mercenary_info in ipairs(formation_mercenary_list) do
            if formation_mercenary_info.template_id == template_id then
                cur_num = cur_num + 1
                if cur_num >= num_limit then
                    if is_show_prompt then
                        graphic:DispatchEvent("show_prompt_panel", "mercenary_num_limit", num_limit)
                    end
                    return true
                end
            end
        end
    end

    return false
end

function troop:SetMercenaryFormationStatus(instance_id, formation_id, status)
    local mercenary = self.mercenary_list[instance_id]
    mercenary.formation_info = bit_extension:SetBitNum(mercenary.formation_info, (formation_id - 1), status)
end

--推荐佣兵阵容
function troop:RecommendMercenaryFormation(formation_id, mercenary_list)
    --验证是否和当前推荐一致 暂时不验证
    local check_send_flag = true
    local mercenary_counts = #mercenary_list
    local formation_mercenary = self.formations[formation_id]

    if #formation_mercenary == mercenary_counts then
        for index_number = 1, mercenary_counts do
            if mercenary_list[index_number] ~= formation_mercenary[index_number].instance_id then
               check_send_flag = true
               break
            else
               check_send_flag = false
            end
        end
    end

    if not self:CheckGuildWarStatus(formation_id) then 
        graphic:DispatchEvent("show_prompt_panel", "guild_formation_cant_use")
        return
    end

    if check_send_flag then
        network:Send({adjust_mercenary_position = { formation_id = formation_id, mercenary_id_list = mercenary_list, recommend_flag = true}})
    end
end

--调整佣兵在阵容中的位置
function troop:AdjustMercenaryPosition(formation_id, mercenary_id_list)

    local temp_num = #mercenary_id_list
    if temp_num ~= #self.formations[formation_id] then
        return
    end

    --检测是否有重复的
    local temp_id_list = {}
    for i, instance_id in ipairs(mercenary_id_list) do
        if not temp_id_list[instance_id] then
            temp_id_list[instance_id] = true
        else
            --重复
            return
        end

        --验证是否在阵容中
        if not self:IsMercenaryInFormation(self.mercenary_list[instance_id], formation_id) then
            return
        end
    end

    if not self:CheckGuildWarStatus(formation_id) then 
        graphic:DispatchEvent("show_prompt_panel", "guild_formation_cant_use")
        return
    end

    network:Send({adjust_mercenary_position = { formation_id = formation_id, mercenary_id_list = mercenary_id_list, recommend_flag = false }})
end

--未上阵的佣兵替换下已经上阵的佣兵
function troop:ReplaceMercenaryFromFormation(formation_id, src_id, dest_id)
    if dest_id == src_id then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["cant_select_self"])
        return
    end

    local src_mercenary = self:GetMercenaryInfo(src_id)
    local dest_mercenary = self:GetMercenaryInfo(dest_id)

    --被替换的佣兵不存在或者不在阵容中
    if not src_mercenary or (not self:IsMercenaryInFormation(src_mercenary, formation_id)) then
        return
    end

    --上阵的佣兵不存在或者在阵容中
    if not dest_mercenary or (self:IsMercenaryInFormation(dest_mercenary, formation_id)) then
        return
    end

    if not self:CheckGuildWarStatus(formation_id) then 
        graphic:DispatchEvent("show_prompt_panel", "guild_formation_cant_use")
        return
    end

    --只有替换佣兵的ID不同时，才检查数量上限
    if src_id ~= dest_id then
        if self:CheckMercenaryNumOverLimit(dest_mercenary.template_id, formation_id, true) then
            return
        end
    end

    network:Send({exchange_formation_pos = { formation_id = formation_id, src_id = src_id, dest_id = dest_id}})
end

--休息
function troop:RestMercenary(formation_id, instance_id)

    local mercenary = self:GetMercenaryInfo(instance_id)
    --佣兵不在阵容中
    if (not mercenary) or (not self:IsMercenaryInFormation(mercenary, formation_id)) then
        return
    end

    if not self:CheckGuildWarStatus(formation_id) then 
        graphic:DispatchEvent("show_prompt_panel", "guild_formation_cant_use")
        return
    end

    network:Send({rest_mercenary = { formation_id = formation_id, instance_id = instance_id }})
end

--解雇
function troop:FireMercenary(mercenary_id_list)
    if type(mercenary_id_list) == "number" then
        mercenary_id_list = { [1] = mercenary_id_list }
    end

    local fire_num = #mercenary_id_list
    if fire_num == 0 or fire_num > constants["MAX_FIRE_NUM_ONCE"] then
        return
    end

    --检测有无重复
    for i = 1, fire_num - 1 do
        for j = i + 1, fire_num do
            if mercenary_id_list[i] == mercenary_id_list[j] then
                return
            end
        end
    end

    for i, id in ipairs(mercenary_id_list) do
        local mercenary = self.mercenary_list[id]
        if not mercenary or mercenary.formation_info ~= 0 then
            graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["cant_fire_a_exploring_mercenary"])
            return
        end

        if mercenary.is_leader then
            graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["cant_fire"])
            return
        end
    end

    network:Send({fire_mercenary = { mercenary_id_list = mercenary_id_list }})
end

--觉醒等级提升
function troop:UpgradeMercenaryWakeup(mercenary_id)
    local mercenary = self.mercenary_list[mercenary_id]
    if not mercenary then
        return
    end

    --已经提升值满级
    if mercenary.wakeup >= mercenary.template_info.max_wakeup then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["wakeup_reach_max"])
        return
    end

    --等级不足
    if mercenary.level < 30 then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_level_too_low_for_wakeup")
        return
    end

    --检测资源
    local config = config_manager.wakeup_info_config[mercenary.wakeup]
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["gold_coin"], config.gold_coin, true) then
        return
    end

    if not resource_logic:CheckResourceNum(config.resource_id, config.resource_num, true) then
        return
    end

    network:Send({ upgrade_mercenary_wakeup = { mercenary_id = mercenary_id }})
end

--突破
function troop:UpgradeMercenaryForcelv(mercenary_id)
    local mercenary = self.mercenary_list[mercenary_id]
    if not mercenary then
        return
    end

    --佣兵不能界限突破
    if not mercenary.template_info.can_upgrade_force then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_upgrade_force_prompt1")
        return
    end

    --觉醒未到满级
    if mercenary.wakeup < 5 then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_wakeup_not_enough_for_force")
        return
    end

    --突破已到满级
    if mercenary.force_lv == constants["MAX_FORCE_LEVEL"] then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["force_lv_reach_max"])
        return
    end

    --消耗500灵魂碎片， 5个巨魔雕像
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["golem"], FORCE_LV_COST_RESOURCE_NUM["golem"], true) then
        return
    end

    if not resource_logic:GetResourceNum(RESOURCE_TYPE["soul_chip"],FORCE_LV_COST_RESOURCE_NUM["soul_chip"], true) then
        return
    end

    network:Send({ upgrade_mercenary_force = { mercenary_id = mercenary_id }})
end

--招募
function troop:RecruitMercenary(recruit_type)
    if not self:CheckMercenaryNum() then
        return
    end

    local resource_type, num

    if recruit_type == "recruiting_door" then
        resource_type = constants.RESOURCE_TYPE["gold_coin"]
        num = daily_logic:GetRecruitCost()

    elseif recruit_type == "ten_mercenary_door" then
        resource_type = constants.RESOURCE_TYPE["blood_diamond"]
        num = constants.RECRUIT_COST["ten_mercenary_door"]

    elseif recruit_type == "hero_door" then
        resource_type = constants.RESOURCE_TYPE["blood_diamond"]
        num = constants.RECRUIT_COST["hero_door"]

    elseif recruit_type == "friendship_door" then
        resource_type = constants.RESOURCE_TYPE["friendship_pt"]  -- 资源跳转
        num = constants.RECRUIT_COST["friendship_door"]   --150
    elseif recruit_type == "ten_friendship_door" then
        resource_type = constants.RESOURCE_TYPE["friendship_pt"]
        num = constants.RECRUIT_COST["ten_friendship_door"]
    elseif recruit_type == "magic_door" then
        resource_type = constants.RESOURCE_TYPE["blood_diamond"]
        num = constants.RECRUIT_COST["magic_door"]
    end

    if not resource_logic:CheckResourceNum(resource_type, num, true) then
        return
    end

    network:Send({ recruit_mercenary = { door_type = recruit_type }})
end

--图鉴招募
function troop:LibraryRecruit(template_id)

    if not self.mercenary_library[template_id] or self.mercenary_library[template_id] <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_library_recruit_not_enough")
        return
    end

    local cost_soul_chip = math.ceil(config_manager.mercenary_config[template_id]["soul_chip"] * constants["LIBRARY_COST_SOUL_CHIP_MULTI"])
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["soul_chip"], cost_soul_chip, true) then  -- 资源跳转
        return
    end

    if not feature_config:IsFeatureOpen("contract_soul_bone") then
        local res_name  = "soul_bone" .. config_manager.mercenary_config[template_id].quality
        local cost_soul_bone = math.ceil(config_manager.mercenary_config[template_id]["soul_bone"]* constants["COST_SOUL_BONE_MULTI"])
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[res_name],cost_soul_bone,true) then
            return 
        end
    end

    if not self:CheckMercenaryNum() then
        return
    end

    network:Send({ library_recruit = { template_id = template_id } })
end

--合成灵魂石
function troop:CraftSoulStone(template_id)
    if mercenary_config[template_id].is_unique then
        graphic:DispatchEvent("show_prompt_panel", "cant_craft")
        return
    end

    for i = 1, #CRAFT_COST_RESOURCE do
        local resource_name = CRAFT_COST_RESOURCE[i]
        local soul_stone_conf = mercenary_soul_stone_config[template_id]
        if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE[resource_name], soul_stone_conf[resource_name], true) then
           return
        end
    end

    network:Send({ craft_soul_stone = { template_id = template_id } })
end

--锻造
local forge_resource_list = {
    "blood_diamond", 0, "copper", 0, "tin", 0, "iron", 0, "silver", 0, "gold", 0,
    "diamond", 0, "titan_iron", 0, "ruby", 0, "purple_gem", 0, "emerald", 0, "topaz", 0,
    "inferno_brimstone", 0, "time_sand", 0, "forge_pt", 0
}

--检测强化缺少的资源
function troop:CheckForgeWeaponResource(weapon_lv, show_prompt)
    local default = true 
    if self.is_open then
        default = not self.is_open
        self.is_open = nil 
    end  -- 资源跳转
    --检测资源
    local forge_config = config_manager.weapon_forge_config[weapon_lv + 1]
    for i = 3, #forge_resource_list - 2, 2 do
        local resource_name = forge_resource_list[i]
        local num = forge_config[resource_name]
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, show_prompt,default) then   -- 资源跳转
            return false
        end
    end

    return true
end

function troop:GetForgeWeaponBloodDiamond(extra_chance)
    local num = 0
    if extra_chance > 0 then
        local extra_config = config_manager.weapon_forge_extra_config[extra_chance]
        if not extra_config then
            return -1
        end

        num = extra_config.blood_diamond
    end

    return num
end

--强化
function troop:ForgeWeapon(mercenary_id, extra_chance)
    local mercenary = self.mercenary_list[mercenary_id]

    if mercenary.is_leader then
        --主角是不能锻造武器的
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["cant_forge_weapon"])
        return
    end

    if mercenary.weapon_lv >= constants["MAX_WEAPON_LV"] then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["weapon_lv_reach_max"])
        return
    end

    --当前武器等级已经超过或等于20，却没有开启宝具,则不能继续强化
    if mercenary.template_info.have_artifact then
        if mercenary.weapon_lv >= constants["CAN_OPEN_ARTIFACT_WEAPON_LV"] and not mercenary.is_open_artifact then
            graphic:DispatchEvent("show_prompt_panel", "not_open_artifact_cant_forge")
            return
        end
    end

    forge_resource_list[2] = self:GetForgeWeaponBloodDiamond(extra_chance)

    if forge_resource_list[2] < 0 then
        return
    end

    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], forge_resource_list[2], true) then
        return
    end

    if not self:CheckForgeWeaponResource(mercenary.weapon_lv, true) then
        return
    end

    network:Send({ forge_mercenary_weapon = { mercenary_id = mercenary_id, extra_chance = extra_chance } })
end

--开启宝具
local open_artifact_list = {
    "gold_coin", 95000000,
    "red_soul_crystal", 6,
    "green_soul_crystal", 6,
    "light_soul_crystal", 6,
    "dark_soul_crystal", 6
}
local open_artifact_list2 = {
    "forge_ticket", 1,
}

--检测宝具缺少的资源
function troop:CheckOpenArtifactResource(open_type, show_prompt)
    local cost_list = open_artifact_list
    if open_type == "ticket" then
        cost_list = open_artifact_list2
    end
    for i = 1, #cost_list , 2 do
        local resource_name = cost_list[i]
        local num = cost_list[i + 1]
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, show_prompt) then
            return false
        end
    end

    return true
end

--检测升级宝具缺少的资源
function troop:CheckUpdateArtifactResource(mercenary_id)
    local mercenary = self:GetMercenaryInfo(mercenary_id)
    local level = mercenary.artifact_lv or 1
    local config = config_manager.mercenary_artifact_config[mercenary.template_id][level]
    local cost_list = config.cost_list
    if cost_list then 
        for k,v in pairs(cost_list) do
            if not resource_logic:CheckResourceNum(k, v, true) then
                return false
            end
        end
    end
    return true
end

--开启宝具
function troop:UpdateArtifact(instance_id, open_type)
    local mercenary = self.mercenary_list[instance_id]

    local artifact_status = self:GetArtifactStatus(instance_id)

    if artifact_status == MERCENARY_AETIFACT_STATUS["not_have_artifact"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_not_has_artifact")

    elseif artifact_status == MERCENARY_AETIFACT_STATUS["weapon_lv_not_enough"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_open_artifact_weapon_lv_not_enough")

    elseif artifact_status == MERCENARY_AETIFACT_STATUS["not_open_artifact"] then
        if not self:CheckOpenArtifactResource(open_type, true) then
            return
        end
        network:Send({ open_mercenary_artifact = { mercenary_id = instance_id, open_type = open_type } })
    elseif artifact_status == MERCENARY_AETIFACT_STATUS["already_open_artifact"] then 
        --升级宝具
        if open_type == "update" then
            if self:IsArtifactUpgrade(instance_id) then
                if self:CheckUpdateArtifactResource(instance_id) then
                    self:UpdateArtifactGrade(instance_id)
                    return true
                end
            else
                graphic:DispatchEvent("show_prompt_panel", "mercenary_not_can_artifact_upgrade")
            end
        else
            graphic:DispatchEvent("show_prompt_panel", "mercenary_open_artifact")
        end
    end

    return false
end

--是否可以宝具升级
function troop:IsArtifactUpgrade(instance_id)
    local mercenary = self.mercenary_list[instance_id]
    local artifact_status = self:GetArtifactStatus(instance_id)
    if artifact_status == MERCENARY_AETIFACT_STATUS["already_open_artifact"] then 
        if mercenary.template_info.have_artifact_upgrade then
            return true
        else
            return false
        end
    else
        return false
    end
end

--获取宝具状态 1：没有宝具，2：等级不足无法开启，3：可以开启 4：已经开启
function troop:GetArtifactStatus(instance_id)
    local mercenary = self.mercenary_list[instance_id]

    if not mercenary.template_info.have_artifact then
        return MERCENARY_AETIFACT_STATUS["not_have_artifact"]
    else
        if mercenary.weapon_lv < constants["CAN_OPEN_ARTIFACT_WEAPON_LV"] then
            return MERCENARY_AETIFACT_STATUS["weapon_lv_not_enough"]
        else
            if  not mercenary.is_open_artifact then
                return MERCENARY_AETIFACT_STATUS["not_open_artifact"]
            end

            return MERCENARY_AETIFACT_STATUS["already_open_artifact"]
        end
    end
end

--宝具等级信息，return 宝具的四维加成
function troop:GetArtifactUpdageInfo(mercenary_id)
    local mercenary = self.mercenary_list[mercenary_id]
    if mercenary and mercenary.template_info.have_artifact_upgrade then
        if  not mercenary.is_open_artifact then
            --可以升级，但是未锻造
            return lang_constants:Get("mercenary_not_open_artifact")
        else
            return self:GetArtifactUpdageInfoDesc(mercenary.template_id, mercenary.artifact_lv) 
        end
    end
    --不可以升级
    return lang_constants:Get("mercenary_not_artifact_updage_desc")
end

--获得等级对应的加成属性描述
function troop:GetArtifactUpdageInfoDesc(template_id, level) 
    local config = config_manager.mercenary_artifact_config[template_id]
    local str = ""
    local is_max = false
    if level == nil and config then
        --如果没有传入等级则显示最大等级信息
        level = #config
        is_max = true
    end

    if config and config[level] then
        local level_conf = config[level]
        if level_conf.sum_speed and level_conf.sum_speed > 0 then
            str = str .. lang_constants:Get("mercenary_property1") .. "+" .. level_conf.sum_speed .. ","
        end

        if level_conf.sum_defense and level_conf.sum_defense > 0 then
            str = str .. lang_constants:Get("mercenary_property2") .. "+" .. level_conf.sum_defense .. ","
        end

        if level_conf.sum_dodge and level_conf.sum_dodge > 0 then
            str = str .. lang_constants:Get("mercenary_property3") .. "+" .. level_conf.sum_dodge .. ","
        end

        if level_conf.sum_authority and level_conf.sum_authority > 0 then
            str = str .. lang_constants:Get("mercenary_property4") .. "+" .. level_conf.sum_authority .. ","
        end

        if is_max and level_conf.sum_bp and level_conf.sum_bp > 0 then
            str = str .. lang_constants:Get("mercenary_property5") .. "+" .. level_conf.sum_bp .. "%,"
        end
    end
    if str ~= "" then
        str = string.sub(str,1,-2)
        return str
    end
    --暂时无四维加成属性
    return lang_constants:Get("mercenary_not_artifact_updage_property_desc")
end



function troop:GetTransmigrationPrice(src_mercenary_id, dest_mercenary_id)
    local src_mercenary = self.mercenary_list[src_mercenary_id]
    local dest_mercenary = self.mercenary_list[dest_mercenary_id]

    local quality = math.max(dest_mercenary.template_info.quality, src_mercenary.template_info.quality)
    local price = constants["TRANSMIGRATION_COST"][quality]

    --检测是否是新手期间
    local free_time_limit = user_logic.base_info.create_time + time_logic:GetSecondsFromDays(constants['NOVICE_DAYS'])
    local now_time = time_logic:Now()
    if now_time < free_time_limit then
        return 0
    end
    --检测是否
    local carnival_conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["transmigrate"], constants.CARNIVAL_TYPE["transmigrate"])

    if carnival_conf then
        if #carnival_conf.mult_num1 > 0 then
            local src_template_id = src_mercenary.template_info.ID

            for i, template_id in ipairs(carnival_conf.mult_num1) do
                if template_id == src_template_id then
                    price = 0
                    break
                end
            end
        elseif carnival_conf.mult_num2 then
            price = carnival_conf.mult_num2[quality]
        end
    end

    return price
end

--转生， src_mercenary_id 灵源， dest_mercenary_id 灵主
function troop:TransmigrateMercenary(src_mercenary_id, dest_mercenary_id)

    local src_mercenary = self.mercenary_list[src_mercenary_id]
    local price = self:GetTransmigrationPrice(src_mercenary_id, dest_mercenary_id)
    local resource_type = constants.RESOURCE_TYPE["blood_diamond"]

    if not resource_logic:CheckResourceNum(resource_type, price, true) then
        return
    end

    network:Send({transmigrate_mercenary = { src_mercenary_id = src_mercenary_id, dest_mercenary_id = dest_mercenary_id }})
end

function troop:CreateMercenary(template_id, ex_prop_type, ex_prop_val,mercenary_att)
    mercenary_att = mercenary_att or {}

    local mercenary = {
        template_id = template_id,
        exp = mercenary_att.exp or 0,
        weapon_lv = mercenary_att.weapon_lv or 0,
        is_open_artifact = mercenary_att.is_open_artifact or false,
        force_lv = 0,
        wakeup = mercenary_att.wakeup or 1,
        level = 1,
        formation_info = 0,
        ex_prop_type = ex_prop_type,
        ex_prop_val = ex_prop_val,
        contract_lv = 0,
        expire_time = mercenary_att.expire_time or 0,
    }

    local instance_id = self.mercenary_id_generator + 1
    self.mercenary_id_generator = instance_id

    mercenary.instance_id = instance_id
        
    self:CalcMercenaryLevel(mercenary)
    self:InitMercenaryInfo(mercenary)

    if not self.mercenary_library[template_id] then
        mercenary.is_new = true
        self.mercenary_library[template_id] = 0

        achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["library"], 1)

        graphic:DispatchEvent("library_new_mercenary", mercenary.template_info)

    else
        mercenary.is_new = false
    end

    return mercenary
end

--佣兵数量
function troop:CheckMercenaryNum()
    if self.mercenary_num >= self.camp_capacity then
        graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", self.camp_capacity)
        return false
    end

    return true
end

--切换阵容
function troop:ChangeFormation(formation_id)
    if not formation_id or formation_id == 0 or formation_id > MAX_FORMATION_NUM or self.cur_formation_id == formation_id then
        return
    end

    network:Send({change_formation = { formation_id = formation_id }})
end

function troop:CheckSoulStone(template_id, num)
    local cur_num = self:GetMercenaryLibraryCount(template_id) or 0

    return cur_num >= num
end

--佣兵是否可以签订契约
function troop:CanContractLv(template_id, level)
    level = level or 1
    local contract_level_config = mercenary_contract_config[level]
    if not contract_level_config then
        return false
    end

    local conf = contract_level_config[template_id]

    return conf and true or false
end

function troop:CheckContractResource(instance_id, contract_lv)
    local conf = self:GetContractConf(instance_id, contract_lv)
    if not conf then
        return false
    end

    local mercenary_library = self.mercenary_library
    for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
        local soul_type = conf["soul_type" .. i]
        local soul_num = conf["soul_num" .. i]

        if soul_type ~= 0 then
            local n = mercenary_library[soul_type]
            if not n then
                return false
            end

            if n < soul_num then
                return false
            end
        end
    end

    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["soul_chip"], conf.soul_chip, false) then
        return false
    end
    
    --TAG:MASTER_MERGE
    if platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then
        if contract_lv then
            local resource_type =0
            local res_type = 44

            for i = 1, contract_lv do
                local res_name = ""
                local need_num = 0
                local template_id = conf["soul_bone_num" .. i]

                if template_id ~= 0 and template_id~="" then
                    for type_id, num in string.gmatch(conf["soul_bone_num" .. i], "(%d+)|(%d+)") do
                        resource_type = tonumber(type_id)
                        need_num= tonumber(num)
                        res_name = "soul_bone" .. (resource_type -res_type)    
                    end
                    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"][res_name], need_num, false) then
                        return false
                    end
                end
            end
        end
    end

    return resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["contract_stone"], conf.contract_stone, false)
end

function troop:GetContractConf(instance_id, level_delta)
    --默认是获取下一级契约信息
    level_delta = level_delta or 1
    local mercenary = self.mercenary_list[instance_id]

    local contract_level_config = mercenary_contract_config[level_delta]

    if not contract_level_config then
        return false
    end

    local conf = contract_level_config[mercenary.template_info.ID]

    return conf
end

function troop:IsContractUnlock()
    if _G["AUTH_MODE"] then
        return true
    end

    if achievement_logic:GetStatisticValue(constants.ACHIEVEMENT_TYPE["recruit"]) < constants["CONTRACT_UNLOCK_RECRUIT_NUM"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_contract_unlock_desc", constants["CONTRACT_UNLOCK_RECRUIT_NUM"])
        return false
    end

    return true
end

--签订契约sl
function troop:SignContract(mercenary_id, contract_lv)

    if not self:IsContractUnlock() then
        return
    end

    local conf = self:GetContractConf(mercenary_id, contract_lv)
    if not conf then
        return
    end

    for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
        local soul_type = conf["soul_type" .. i]
        local soul_num = conf["soul_num" .. i]

        if soul_type ~= 0 and not self:CheckSoulStone(soul_type, soul_num) then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_soul_stone_not_enough")
            return
        end
    end

    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["soul_chip"], conf.soul_chip, true) then
        return
    end

    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["contract_stone"], conf.contract_stone, true) then
        return
    end
    
    --TAG:MASTER_MERGE
    if platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then
        local resource_type =0
        local res_type = 44

        for i = 1, contract_lv do
            local res_name = ""
            local need_num = 0
            local template_id = conf["soul_bone_num" .. i]

            if template_id ~= 0 and template_id~="" then
                for type_id, num in string.gmatch(conf["soul_bone_num" .. i], "(%d+)|(%d+)") do
                    resource_type = tonumber(type_id)
                    need_num= tonumber(num)
                    res_name = "soul_bone" .. (resource_type -res_type)                
                end
                if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"][res_name], need_num, true) then
                    return
                end
            end
        end
    end

    network:Send({sign_contract = { mercenary_id = mercenary_id }})
end

--属性转化消耗检测
function troop:CheckPropertyChange(mercenary_id)
    local mercenary = self.mercenary_list[mercenary_id]
    if not mercenary then
        return false
    end

    -- 突破未到满级
    if mercenary.force_lv < constants["MAX_FORCE_LEVEL"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_force_lv_not_enough_for_change_property")
        return false
    end

    local consume_config = constants.CHANGE_EX_PROPERTY_RESOURCE

    --金币
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["gold_coin"], consume_config.gold_coin, true) then
        return false
    end

    --巨魔雕像
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["golem"], consume_config.golem, true) then
        return false
    end

    --灵魂碎片 ＝ 佣兵解雇获得数量
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["soul_chip"], mercenary.template_info.soul_chip * consume_config.scale, true) then
        return false
    end
    return true
end

--属性转化
function troop:ChangeExProperty(mercenary_id)
    network:Send({ change_mercenary_exproperty = { mercenary_id = mercenary_id }})
end

-- 属性替换
function troop:ReplaceExProperty(mercenary_id, is_replace)
    network:Send({ change_mercenary_exproperty = { mercenary_id = mercenary_id, is_replace = true}})
end

function troop:CalcLeaderContract()
    if user_logic.base_info.contract_lv == 0 then
        return 0
    end

    local conf
    for i = 1, #leader_contract_config do
        if leader_contract_config[i].num > user_logic.base_info.contract_lv then
            conf = leader_contract_config[i - 1]
            break
        end
    end

    if not conf then
        conf = leader_contract_config[#leader_contract_config]
    end

    self.leader.speed = conf.speed
    self.leader.defense = conf.defense
    self.leader.dodge =  conf.dodge
    self.leader.authority = conf.authority
    self.contract_bp = conf.bp

    for i = 1, #constants["ALL_FORMATIONS"] do
        local id = constants["ALL_FORMATIONS"][i]
        local formation = self.formations[id]

        if self:IsMercenaryInFormation(self.leader, id) then
            formation.property_changed = true
        end
    end
end

--获取主角的契约表
function troop:GetLeaderContractConfIndex()
    if user_logic.base_info.contract_lv == 0 then
        return 0
    end

    for i = 1, #leader_contract_config do
        if leader_contract_config[i].num > user_logic.base_info.contract_lv then
            return i-1
        end
    end

    return #leader_contract_config
end

function troop:FormationPropertyChanged(mercenary)
    --需要同时更新当前查看的阵容和服务器正在使用的阵容
    if self:IsMercenaryInFormation(mercenary, constants["GUILD_WAR_TROOP_ID"]) then
        self:CalcTroopBP(constants["GUILD_WAR_TROOP_ID"])
        self.formations[self.client_formation_id].property_changed = true
    end

    if self:IsMercenaryInFormation(mercenary, self.cur_formation_id) then
        self:CalcTroopBP(self.cur_formation_id)
        self.formations[self.cur_formation_id].property_changed = true
    end
end

function troop:SwapMercenaryInfo(src_mercenary, dest_mercenary)
    dest_mercenary.exp = src_mercenary.exp
    dest_mercenary.weapon_lv = src_mercenary.weapon_lv
    dest_mercenary.wakeup = math.min(src_mercenary.wakeup, dest_mercenary.template_info.max_wakeup)

    if dest_mercenary.template_info.can_upgrade_force then
       dest_mercenary.force_lv = src_mercenary.force_lv
    end

    if dest_mercenary.template_info.have_artifact then
        dest_mercenary.is_open_artifact = src_mercenary.is_open_artifact
        --宝具等级交换
        if dest_mercenary.is_open_artifact and dest_mercenary.template_info.have_artifact_upgrade then
            dest_mercenary.artifact_lv = src_mercenary.artifact_lv or 1
        else
            dest_mercenary.artifact_lv = 1
        end
    end
    
    self:CalcMercenaryLevel(dest_mercenary)
    self:CalcMercenaryBP(dest_mercenary)
    self:CalcMercenaryProperty(dest_mercenary)
end

function troop:GetFormationName(formation_id)

    formation_id = formation_id or self.cur_formation_id
    
    if formation_id == constants["GUILD_WAR_TROOP_ID"] then
        return lang_constants:Get("mercenary_cur_formation_guild")
    end

    if formation_id == constants["KF_PVP_TROOP_ID"] then
        return lang_constants:Get("mercenary_cur_formation_server_pvp")
    end

    local name = ""
    if self.formation_name_list[formation_id] and self.formation_name_list[formation_id] ~= ""  then
        name = self.formation_name_list[formation_id]
    elseif self:IsMineFormation(formation_id) then
        name = lang_constants:Get("mercenary_mine_formation_name")
    else
        name = string.format(lang_constants:Get("mercenary_cur_formation"), tostring(formation_id))
    end

    return name
end

--修改阵容名字
function troop:ChangeFormationName(formation_id, name)
    if formation_id > MAX_FORMATION_NUM then
        graphic:DispatchEvent("show_prompt_panel", "change_formation_name_failure")
        return
    end

    local result = common_function.ValidName(name, constants["FORMATION_NAME_LENGTH"])
    if result == "invalid_char" then
        graphic:DispatchEvent("show_prompt_panel", "formation_name_invalid_char")
        return
    elseif result == "exceed_max_length" then
        graphic:DispatchEvent("show_prompt_panel", "formation_name_too_long", constants["FORMATION_NAME_LENGTH"])
        return
    end

    if self.formation_name_list[formation_id] == name then
        graphic:DispatchEvent("show_prompt_panel", "change_formation_name_failure")
        return
    end

    network:Send({ change_formation_name = { formation_id = formation_id, name = name }})
end

function troop:UpdateGuildFormation(formation_id)
    if formation_id ~= constants["GUILD_WAR_TROOP_ID"] then
        return
    end

    guild_logic:UpdateTroopBP(self:GetTroopBP(constants["GUILD_WAR_TROOP_ID"]))
end

--升级宝具请求
--pram mercenary_id --->角色id
function troop:UpdateArtifactGrade(mercenary_id)
    network:Send({upgrade_mercenary_artifact = { mercenary_id = mercenary_id}})
end

--判断是否可以升级
function troop:CheckArtifactReminder(mercenary)
    if mercenary.template_info.have_artifact_upgrade and mercenary.is_open_artifact then
        local config = config_manager.mercenary_artifact_config[mercenary.template_id]
        
        if config and config[mercenary.artifact_lv] and  mercenary.artifact_lv < #config then
            config = config[mercenary.artifact_lv]
            local cost_list = config.cost_list
            if cost_list then 
                for k,v in pairs(cost_list) do
                    if not resource_logic:CheckResourceNum(k, v) then
                        return false
                    end
                end
            end
            return true
        end
    end
    return false
end

--判断是否是矿山整容
function troop:IsMineFormation(formation_id)
    local is_mine_formation = false
    for k,v in pairs(constants["MINE_TROOP_ID"]) do
        if v == formation_id then
            is_mine_formation = true
            break
        end
    end
    return is_mine_formation
end

--判断是否是矿山阵容上阵或者替换，如果是要进行判断
function troop:ChangeMineFormation(mercenary, formation_id)
    if self:IsMineFormation(formation_id) then
        local mine_status1, mine_status2, mine_formation_id = self:IsMercenaryInMineFormation(mercenary)
        if mine_status1 and mine_status2 then
            --这个佣兵之前在其他矿山阵容中，要下阵
            for k,v in pairs(self.formations[mine_formation_id]) do
                if type(v) == "table" and v.instance_id == mercenary.instance_id then
                    self:SetMercenaryFormationStatus(mercenary.instance_id, mine_formation_id, false)
                    table.remove(self.formations[mine_formation_id], k)
                    break
                end
            end
            
        end
    end
end

--皮肤换装功能
--主角闪金化
function troop:FlashGoldLader()
    network:Send({evolution_flash_gold_ladder = {}})
end

--更换或者解锁皮肤
function troop:UnLockOrUseSkin(target_template_id, type)
    if type == client_constants["EVOLUTION_UNLOCK_TYPE"].unlock then
        --判断资源是否充足
        local unlock_conf = config_manager.evolution_config[target_template_id]
        for k,v in pairs(unlock_conf.cost_conf) do
            if not resource_logic:CheckResourceNum(RESOURCE_TYPE[constants["RESOURCE_TYPE_NAME"][k]], v, true) then
                return
            end
        end
    end
    network:Send({evolution_dressing = {target_template_id = target_template_id, type = type}})
end

--是否已经闪金过了
function troop:IsLadderFlashGold()
    local unlock_conf = config_manager.evolution_config[tonumber(self.leader.template_id)]

    if unlock_conf then
        return true
    end
    return false
end

--皮肤是否已解锁了
function troop:UnLockSkin(template_id)
    if template_id == self.leader.template_id then
        return true
    end
    for k,v in pairs(self.skin_template_ids) do
        if template_id == v then
            return true
        end
    end
    return false
end

---------------------------------------虚空大冒险功能 start --------------------------------------
--根据关卡获取对应的奖励 下一关卡能用的英雄
function troop:GetVanityMercenaryByMazeId(maze_id)
    -- get_vanity_mercenary
    network:Send({get_vanity_mercenary = {maze_id = maze_id}})
end

--虚空阵容上阵
function troop:GoToBattle(instance_id)
    network:Send({vanity_pitched_in = {instance_id = instance_id}})
end

--空虚阵容下阵
function troop:RestToBattle(instance_id, position)
    network:Send({vanity_pitched_out = {instance_id = instance_id, position = position}})
end

--空虚阵容下阵
function troop:ReplaceToBattle(instance_id, position)
    network:Send({vanity_replace_mercenary = {instance_id = instance_id, position = position}})
end

--战斗
function troop:FightingByMazeId(maze_id)
    -- 
    network:Send({vanity_challenge = {maze_id = maze_id}})
end

--商品兑换
function troop:VanityExchangeReward(good_id, num)
    -- 
    network:Send({vanity_exchange_goods = {good_id = good_id, num = num}})
end

--获取商品列表
function troop:GetVanityStoreList()
    if self.vanity_good_list == nil  then
        network:Send({query_vanity_goods = {}})
    else
        return self.vanity_good_list
    end
    return nil
end

--展示已经获得的佣兵每次最大十个，
function troop:ShowGetVanityMercenary()
    if #self.get_mercenary_list > 0  then
        local now_show_list = {}
        for i=1,10 do
            local mercenary = self.get_mercenary_list[1]
            if mercenary then
                table.insert(now_show_list,mercenary)
                table.remove(self.get_mercenary_list,1)
            else
                break
            end
        end
        if #now_show_list > 0 then
            graphic:DispatchEvent("show_world_sub_panel", "show_mercenarys_list_panel", now_show_list)
        end
    elseif self.is_show_vantiy_animation then
        self.is_show_vantiy_animation = false
        graphic:DispatchEvent("show_vanity_animation")
    end
end

--获得当前可以上阵的佣兵数量
function troop:GetVanityCanUseNumber()
    local can_use_num = 0
    for k,v in pairs(self.vanity_mercenarys_list) do
        if v.battle_num > 0 then
            can_use_num = can_use_num + 1
        end
    end

    for k,v in pairs(self.vanity_troop) do
        if v ~= 0 then
            can_use_num = can_use_num - 1
        end
    end

    return can_use_num
end

function troop:GetVanityMazeList()
    if self.vanity_maze_state_list == nil then
        self.is_query_vanity_maze = true
        network:Send({query_vanity_maze_states = {}})
    end
    return self.vanity_maze_state_list or {}
end

function troop:VanityBattlePlayBack(maze_id)
    network:Send({vanity_play_back = {maze_id = maze_id}})
end

--请求查询阵容信息
function troop:QueryVantiyToopInfo()
    network:Send({query_vanity_troop = {}})
end

--招募一次
function troop:GetVanityOtherMercenary()
    --
    network:Send({vanity_buy_recruit = {}})
end

    
--交换位置
function troop:ChangePosition(pos1, pos2)
    if pos1 == pos2 then
        return
    end
    self.change_troop = {}
    if self.vanity_troop_change == nil then
        for k,v in pairs(self.vanity_troop) do
            self.change_troop[k] = v
        end
    end
    local mercenary_id1 = self.change_troop[pos1]
    local mercenary_id2 = self.change_troop[pos2]
    self.change_troop[pos1] = mercenary_id2
    self.change_troop[pos2] = mercenary_id1

    network:Send({vanity_sync_troop = {troop = self.change_troop}})
end
---------------------------------------虚空大冒险功能  end  --------------------------------------


--查询召唤佣兵是否有冷却时间
function troop:CheckMercenarycCutDownTime(template_id)
    if self.mercenarys_cut_down_time[template_id] then
        graphic:DispatchEvent("show_world_sub_panel", "mercenary_soul_stone_panel", template_id, "recruit")
        return 
    end
    network:Send({recurit_library_time = {template_id = template_id}})
end

--消除冷却时间
function troop:UseBloodClearCutDownTime(template_id)
    network:Send({clear_recurit_library_time = {template_id = template_id}})
end

--得到召唤冷却时间
function troop:GetMercenaryRecruitTime(template_id)
    if self.mercenarys_cut_down_time[template_id] then
        return self.mercenarys_cut_down_time[template_id]
    end
    return 0
end

function troop:RegisterMsgHandler()

    network:RegisterEvent("query_troop_info_ret", function(recv_msg)
        print("query_troop_info_ret")

        for i, mercenary in ipairs(recv_msg.mercenary_list) do
            if mercenary.instance_id == 1 then
                mercenary.is_leader = true
                self.leader = mercenary
            end

            self:InitMercenaryInfo(mercenary)
        end

        if recv_msg.library_type_list and recv_msg.library_num_list then
            local library_type_list = recv_msg.library_type_list
            local library_num_list = recv_msg.library_num_list

            for i = 1, #library_type_list do
                self.mercenary_library[library_type_list[i]] = library_num_list[i]
            end
        end

        self.formation_capacity = recv_msg.formation_capacity

        self.camp_capacity = recv_msg.camp_capacity

        self.cur_formation_id = recv_msg.cur_formation_id
        self.client_formation_id = self.cur_formation_id

        self.mercenary_id_generator = recv_msg.mercenary_id_generator

        if recv_msg.weapon_list then
            for i = 1, #constants["ALL_FORMATIONS"] do
                self.weapon_list[constants["ALL_FORMATIONS"][i]] = recv_msg.weapon_list["weapon" .. constants["ALL_FORMATIONS"][i]]
            end
        end

        if recv_msg.formation_name_list then
            for i = 1, MAX_FORMATION_NUM do
                self.formation_name_list[i] = recv_msg.formation_name_list[i]
            end
        end

        if recv_msg.formation_info then
            local formation_info = recv_msg.formation_info
            for formation_id = 1, #constants["ALL_FORMATIONS"] do
                local f = formation_info["formation" .. constants["ALL_FORMATIONS"][formation_id]]
                self:InitFormationsInfo(f, constants["ALL_FORMATIONS"][formation_id])
                self:CalcTroopBP(constants["ALL_FORMATIONS"][formation_id], true)
            end
        end

        self.forge_info.mercenary_id = recv_msg.forge_info.mercenary_id
        self.forge_info.lucky_num = recv_msg.forge_info.lucky_num

        if self.have_end_mercenary then
            self.have_end_mercenary = false
            graphic:DispatchEvent("update_exploring_merceanry")
        end
    end)

    --给佣兵分配经验
    network:RegisterEvent("alloc_mercenary_exp_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]

            mercenary.exp = recv_msg.exp

            local origin_level = mercenary.level

            self:CalcMercenaryLevel(mercenary)
            self:CalcMercenaryBP(mercenary)
            self:FormationPropertyChanged(mercenary)

            if mercenary.instance_id == self.leader.instance_id then
                user_logic:UpdateUserInfo(false)
            end

            graphic:DispatchEvent("update_mercenary_level", recv_msg.mercenary_id, mercenary.level - origin_level)

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["exp"])
        elseif recv_msg.result == "illegal_operation" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_illegal_operation")
        end
    end)

    --空位上阵
    network:RegisterEvent("insert_formation_ret", function(recv_msg)
        local mercenary = self.mercenary_list[recv_msg.instance_id]

        if recv_msg.result == "success" then
            --判断是否是矿山阵容
            self:ChangeMineFormation(mercenary, recv_msg.formation_id)

            --空位上阵
            self:SetMercenaryFormationStatus(mercenary.instance_id, recv_msg.formation_id, true)

            table.insert(self.formations[recv_msg.formation_id], mercenary)

            self:CalcTroopBP(recv_msg.formation_id, true)
            self.formations[recv_msg.formation_id].property_changed = true

            self:UpdateGuildFormation(recv_msg.formation_id)

            local mode = client_constants["MERCENARY_TO_FORMATION"]["add"]
            local pos = #self.formations[recv_msg.formation_id]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, pos, mercenary.instance_id, nil, recv_msg.formation_id)
            reminder_logic:CheckFormationReminder()
            reminder_logic:CheckForgeReminder()
        elseif recv_msg.result == "illegal_operation" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_illegal_operation")
        elseif recv_msg.result == "mercenary_num_limit" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_num_limit", mercenary_config[mercenary.template_id]["num_limit"])
        end
    end)

    --替换佣兵(不在阵容中的佣兵替换下已经在阵容中的佣兵)
    network:RegisterEvent("exchange_formation_pos_ret", function(recv_msg)
        local src_mercenary = self.mercenary_list[recv_msg.src_id]
        local dest_mercenary = self.mercenary_list[recv_msg.dest_id]
        
        if recv_msg.result == "success" then

            --判断是否是矿山阵容
            self:ChangeMineFormation(dest_mercenary, recv_msg.formation_id)
            
            self:SetMercenaryFormationStatus(recv_msg.src_id, recv_msg.formation_id, false)
            self:SetMercenaryFormationStatus(recv_msg.dest_id, recv_msg.formation_id, true)

            self.formations[recv_msg.formation_id][recv_msg.src_pos] = dest_mercenary

            if recv_msg.dest_pos ~= 0 then
                self.formations[recv_msg.formation_id][recv_msg.dest_pos] = src_mercenary
            else
                self:CalcTroopBP(recv_msg.formation_id, true)
                self.formations[recv_msg.formation_id].property_changed = true
            end

            self:UpdateGuildFormation(recv_msg.formation_id)

            local mode = client_constants["MERCENARY_TO_FORMATION"]["replace"]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, recv_msg.src_pos, recv_msg.src_id, recv_msg.dest_id, recv_msg.formation_id)
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        elseif recv_msg.result == "mercenary_num_limit" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_num_limit", mercenary_config[dest_mercenary.template_id]["num_limit"])
        end
    end)

    --拖动调整佣兵位置
    network:RegisterEvent("adjust_mercenary_position_ret", function(recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.recommend_flag then
                local formation_id = recv_msg.formation_id

                for index = #self.formations[recv_msg.formation_id] , 1 , -1 do
                    local mercenary = self.formations[recv_msg.formation_id][index]
                    mercenary.formation_info = bit_extension:SetBitNum(mercenary.formation_info, (formation_id - 1), false)
                    table.remove(self.formations[recv_msg.formation_id], index)
                end

                for i , instance_id in ipairs(recv_msg.mercenary_id_list) do
                    local mercenary = self.mercenary_list[instance_id]
                    mercenary.formation_info = bit_extension:SetBitNum(mercenary.formation_info, (formation_id - 1), true)
                    table.insert(self.formations[recv_msg.formation_id], mercenary)
                end

                self:CalcTroopBP(recv_msg.formation_id, true)
                self.formations[recv_msg.formation_id].property_changed = true

                self:UpdateGuildFormation(recv_msg.formation_id)

                local mode_recommend = client_constants["MERCENARY_TO_FORMATION"]["recommend"]
                graphic:DispatchEvent("update_exploring_merceanry_position", mode_recommend, nil, nil, nil, recv_msg.formation_id)

            else
                for i, instance_id in pairs(recv_msg.mercenary_id_list) do
                    local mercenary = self.mercenary_list[instance_id]
                    self.formations[recv_msg.formation_id][i] = mercenary
                end

                local mode = client_constants["MERCENARY_TO_FORMATION"]["moving"]
                graphic:DispatchEvent("update_exploring_merceanry_position", mode, nil, nil, nil, recv_msg.formation_id)
                graphic:DispatchEvent("update_maze_mercenary")
            end
        end
    end)

    --佣兵下阵
    network:RegisterEvent("rest_mercenary_ret", function(recv_msg)
        if recv_msg.result == "success" then

            self:SetMercenaryFormationStatus(recv_msg.instance_id, recv_msg.formation_id, false)

            table.remove(self.formations[recv_msg.formation_id], recv_msg.position)

            self:CalcTroopBP(recv_msg.formation_id, true)
            self.formations[recv_msg.formation_id].property_changed = true

            self:UpdateGuildFormation(recv_msg.formation_id)

            local pos = math.min(recv_msg.position, #self.formations[recv_msg.formation_id])
            local mode = client_constants["MERCENARY_TO_FORMATION"]["rest"]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, pos, recv_msg.instance_id, nil, recv_msg.formation_id)

            reminder_logic:CheckFormationReminder()
            reminder_logic:CheckForgeReminder()
            graphic:DispatchEvent("rest_mercenary_success")
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end

    end)

    --解雇佣兵
    network:RegisterEvent("fire_mercenary_ret", function(recv_msg)
        if recv_msg.mercenary_id_list then
            local soul_chip_num = 0
            local leader_contract_lv_diff = 0
            
            local mercenary_library =  self.mercenary_library
            local fire_number = 0
            for i, id in pairs(recv_msg.mercenary_id_list) do
                local mercenary = self.mercenary_list[id]
                local template_id = mercenary.template_id
                soul_chip_num = soul_chip_num + mercenary_config[template_id]["soul_chip"]
                mercenary_library[template_id] = mercenary_library[template_id] + 1

                self.mercenary_list[id] = nil
                fire_number = fire_number + 1
                --返回灵魂石
                for j = 1, mercenary.contract_lv do
                    local cur_contract_config = mercenary_contract_config[j][template_id]
                    if cur_contract_config then
                        for index = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
                            local mer_type = cur_contract_config["soul_type" .. index]
                            local mer_num = cur_contract_config["soul_num" .. index]

                            if mer_type ~= 0 and mer_num > 0 then
                                local n = mercenary_library[mer_type]
                                if n then
                                    mercenary_library[mer_type] = n + mer_num
                                end
                            end
                        end
                    end
                end

                -- 如果二阶契约不消耗契约石
                if mercenary.contract_lv == constants.MAX_CONTRACT_LV then
                    local stone_nums = mercenary_contract_config[2][template_id].contract_stone or 0
                    if stone_nums == 0 then
                        leader_contract_lv_diff = leader_contract_lv_diff - 1
                    end
                end
            end

            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["fire_mercenary"], fire_number)

            if leader_contract_lv_diff < 0 then
                user_logic.base_info.contract_lv = user_logic.base_info.contract_lv + leader_contract_lv_diff
                self:CalcLeaderContract()
                self:CalcMercenaryBP(self.leader)
            end

            self.mercenary_num = self.mercenary_num - #recv_msg.mercenary_id_list
            graphic:DispatchEvent("fire_mercenary", recv_msg.mercenary_id_list[1])

            graphic:DispatchEvent("show_prompt_panel", "fire_mercenary_prompt", soul_chip_num)
        end

        if recv_msg.result == "success" then

        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end

        reminder_logic:CheckFormationReminder()
    end)

    --招募佣兵
    network:RegisterEvent("recruit_mercenary_ret", function(recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.recruit_cost then
                daily_logic:SetRecruitCost(recv_msg.recruit_cost)
            end

            local recruit_num = 1

            if recv_msg.door_type == "ten_mercenary_door" or recv_msg.door_type == "ten_friendship_door" then
                recruit_num = 10
            end

            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["recruit"], recruit_num)

            graphic:DispatchEvent("recruit_mercenary", recv_msg.door_type)
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")

        elseif recv_msg.result == "not_enough_gold_coin" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["gold_coin"])

        elseif recv_msg.result == "not_enough_blood_diamond" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["blood_diamond"])

        elseif recv_msg.result == "not_enough_mercenary_space" then
            --graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", self.camp_capacity)  --前端已做过检查 
        end
    end)

    --觉醒
    network:RegisterEvent("upgrade_mercenary_wakeup_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]
            mercenary.wakeup = mercenary.wakeup + 1

            self:CalcMercenaryLevel(mercenary)
            self:CalcMercenaryBP(mercenary)

            self:FormationPropertyChanged(mercenary)

            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["wakeup"], 1)
            user_logic:SetNoviceMark(client_constants["NOVICE_MARK"]["first_wakeup"], true)

            if mercenary.instance_id == self.leader.instance_id then
                user_logic:UpdateUserInfo(false)
            end

            graphic:DispatchEvent("update_mercenary_wakeup", recv_msg.mercenary_id)

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --界限突破
    network:RegisterEvent("upgrade_mercenary_force_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]
            mercenary.force_lv = recv_msg.force_lv
            self:CalcMercenaryProperty(mercenary)
            self:CalcMercenaryBP(mercenary)
            self:FormationPropertyChanged(mercenary)

            graphic:DispatchEvent("update_force_panel", recv_msg.mercenary_id)
            --直接更新数据
            graphic:DispatchEvent("update_mercenary_info", recv_msg.mercenary_id)

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --强化
    network:RegisterEvent("forge_mercenary_weapon_ret", function(recv_msg)
        if recv_msg.result == "success" or recv_msg.result == "forge_failure" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]
            if mercenary and recv_msg.result == "success" then
                mercenary.weapon_lv = mercenary.weapon_lv + 1

                user_logic:SetNoviceMark(client_constants["NOVICE_MARK"]["first_forge"], true)

                self:CalcMercenaryBP(mercenary)
                self:FormationPropertyChanged(mercenary)

                --统计强化点数
                local config = config_manager.weapon_forge_config[mercenary.weapon_lv]
                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["forge_pt"], config["forge_point"])

                self.forge_info.mercenary_id = 0
                self.forge_info.lucky_num = 0
            else
                local mercenary_id = self.forge_info.mercenary_id
                local lucky_num = self.forge_info.lucky_num     

                self.forge_info.mercenary_id = recv_msg.mercenary_id
                if mercenary_id == recv_msg.mercenary_id then
                    self.forge_info.lucky_num = lucky_num + constants["FORGE_WEAPON_LUCKY_NUM"]
                else
                    self.forge_info.lucky_num =  constants["FORGE_WEAPON_LUCKY_NUM"]
                end
            end

            --触发强化动画，动画播放完毕再更新界面显示数据
            graphic:DispatchEvent("update_mercenary_weapon_lv", recv_msg.mercenary_id, recv_msg.result)
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()

        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --转生
    network:RegisterEvent("transmigrate_mercenary_ret", function(recv_msg)
        if recv_msg.result == "success" then

            --src 灵源  dest 灵主
            local src_mercenary = self.mercenary_list[recv_msg.src_mercenary_id]
            local dest_mercenary = self.mercenary_list[recv_msg.dest_mercenary_id]

            if not src_mercenary or not dest_mercenary then
                return
            end

            local temp_mercenary = {}
            temp_mercenary.exp = dest_mercenary.exp
            temp_mercenary.weapon_lv = dest_mercenary.weapon_lv
            temp_mercenary.wakeup = dest_mercenary.wakeup
            temp_mercenary.is_open_artifact = dest_mercenary.is_open_artifact
            temp_mercenary.force_lv = dest_mercenary.force_lv
            temp_mercenary.template_info = dest_mercenary.template_info
            temp_mercenary.artifact_lv = dest_mercenary.artifact_lv

            self:SwapMercenaryInfo(src_mercenary, dest_mercenary)
            self:SwapMercenaryInfo(temp_mercenary, src_mercenary)

            self:FormationPropertyChanged(src_mercenary)
            self:FormationPropertyChanged(dest_mercenary)

            graphic:DispatchEvent("transmigrate_mercenary")
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["blood_diamond"])

        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --开启宝具
    network:RegisterEvent("open_mercenary_artifact_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]

            mercenary.is_open_artifact = true
            mercenary.artifact_lv = 1  -- 默认为一级

            self:CalcMercenaryProperty(mercenary)
            self:CalcMercenaryBP(mercenary)

            --在阵容中，则重新计算阵容属性
            self:FormationPropertyChanged(mercenary)

            graphic:DispatchEvent("open_artifact", recv_msg.mercenary_id)
            graphic:DispatchEvent("update_mercenary_info", recv_msg.mercenary_id)
            reminder_logic:CheckForgeReminder()
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()

        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --图鉴招募
    network:RegisterEvent("library_recruit_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.mercenary_library[recv_msg.template_id] = recv_msg.soul_count
    
            graphic:DispatchEvent("library_recruit_success", recv_msg.template_id)

            local name = mercenary_config[recv_msg.template_id]["name"]
            graphic:DispatchEvent("show_prompt_panel", "mercenary_library_recruit_success", name)

        elseif recv_msg.result == "not_enough_resource" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_library_recruit_not_enough")

        else

        end
    end)

    --切换阵容
    network:RegisterEvent("change_formation_ret", function(recv_msg)
        if recv_msg.result == "success" then
            
            self.cur_formation_id = recv_msg.formation_id
            self.client_formation_id = self.cur_formation_id

            self:CalcTroopBP()
            self.formations[recv_msg.formation_id].property_changed = true

            reminder_logic:CheckFormationReminder()
            graphic:DispatchEvent("change_troop_formation")
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        else
            graphic:DispatchEvent("show_prompt_panel", "unknown_error")
        end
    end)

    --合成灵魂石
    network:RegisterEvent("craft_soul_stone_ret", function(recv_msg)
        if recv_msg.result == "success" then

            if not self.mercenary_library[recv_msg.template_id] then
                self.mercenary_library[recv_msg.template_id] = 0

                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["library"], 1)

            end

            self.mercenary_library[recv_msg.template_id] = recv_msg.soul_count

            if recv_msg.count_down_time then
                self.mercenarys_cut_down_time[recv_msg.template_id] = recv_msg.count_down_time 
            end

            graphic:DispatchEvent("craft_soul_stone_success", recv_msg.template_id)

            local mercenary = mercenary_config[recv_msg.template_id]

            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["craft_soul_stone_quality"], 1)
            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["craft_soul_stone_quality" .. mercenary.quality], 1)

        elseif recv_msg.result == "not_enough_resource" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_library_recruit_not_enough")

        elseif recv_msg.result == "cant_craft_soul" then
            graphic:DispatchEvent("show_prompt_panel", "cant_craft")

        end
    end)

    --签订契约
    network:RegisterEvent("sign_contract_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]

            mercenary.contract_lv = mercenary.contract_lv + 1
            local conf = self:GetContractConf(recv_msg.mercenary_id, mercenary.contract_lv)

            if conf then
                for i = 1, constants["MAX_CONTRACT_SOUL_TYPE"] do
                    local soul_type = conf["soul_type" .. i]
                    local soul_num = conf["soul_num" .. i]

                    if soul_type ~= 0 and soul_num > 0 then
                        self.mercenary_library[soul_type] = self.mercenary_library[soul_type] - soul_num
                    end
                end
            end

            if mercenary.contract_lv == constants["MAX_CONTRACT_LV"] then
                user_logic.base_info.contract_lv = user_logic.base_info.contract_lv + 1
                self:CalcLeaderContract()
                self:CalcMercenaryBP(self.leader)
            end

            self:CalcMercenaryProperty(mercenary)
            self:FormationPropertyChanged(mercenary)

            graphic:DispatchEvent("sign_mercenary_contract", recv_msg.mercenary_id)

        elseif recv_msg.result == "not_enough_soul" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_soul_stone_not_enough")

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()

        elseif recv_msg.result == "contract_unlock_first" then
            graphic:DispatchEvent("show_prompt_panel", "mercenary_contract_unlock_desc", constants["CONTRACT_UNLOCK_RECRUIT_NUM"])

        else
            graphic:DispatchEvent("show_prompt_panel", "mercenary_cant_sign_contract")
        end
    end)

    --属性转换
    network:RegisterEvent("change_mercenary_exproperty_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]
            mercenary.ex_prop_type = recv_msg.ex_prop_type
            mercenary.ex_prop_val = recv_msg.ex_prop_val
            if recv_msg.ex_prop_type_temp and recv_msg.ex_prop_val_temp then
                mercenary.ex_prop_type_temp = recv_msg.ex_prop_type_temp
                mercenary.ex_prop_val_temp = recv_msg.ex_prop_val_temp
            else
                mercenary.ex_prop_type_temp = nil
                mercenary.ex_prop_val_temp = nil
            end

            self:CalcMercenaryProperty(mercenary)
            self.formations[self.cur_formation_id].property_changed = true

            --直接更新数据
            graphic:DispatchEvent("update_force_panel", recv_msg.mercenary_id)

            graphic:DispatchEvent("update_mercenary_info", recv_msg.mercenary_id)

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --修改阵容名字
    network:RegisterEvent("change_formation_name_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.formation_name_list[recv_msg.formation_id] = recv_msg.name
            graphic:DispatchEvent("show_prompt_panel", "change_formation_name_success")

        else
            graphic:DispatchEvent("show_prompt_panel", "change_formation_name_failure")

        end
    end)

    --宝具升级
    network:RegisterEvent("upgrade_mercenary_artifact_ret", function(recv_msg)
        -- print("mercenary_artifact_upgrade_ret",recv_msg.result,recv_msg.artifact_lv,recv_msg.mercenary_id)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]

            mercenary.artifact_lv = recv_msg.artifact_lv

            self:CalcMercenaryProperty(mercenary)

            --在阵容中，则重新计算阵容属性
            self:FormationPropertyChanged(mercenary)

            --重新计算战斗力
            self:CalcMercenaryBP(mercenary)
            self:CalcTroopBP()
            reminder_logic:CheckForgeReminder() 
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

        graphic:DispatchEvent("mercenary_artifact_upgrade", recv_msg.result, recv_msg.mercenary_id)

    end)

    --主角闪金化
    
    network:RegisterEvent("evolution_flash_gold_ladder_ret", function(recv_msg)
        -- print("evolution_flash_gold_ladder_ret", recv_msg.result)
        if recv_msg.result == "success" then
            self.leader.template_id = recv_msg.target_template_id
            self:InitMercenaryInfo(self.leader)
            self:CalcMercenaryBP(self.leader)
            self:CalcTroopBP()
            self.skin_template_ids = {}
            table.insert(self.skin_template_ids, recv_msg.target_template_id)
            --最开始的皮肤记录，因为界面显示要用闪金时候的皮肤
            self.origin_skin_template_id = self.skin_template_ids[1]
            graphic:DispatchEvent("ladder_flash_success")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --查询解锁皮肤
    network:RegisterEvent("query_evolution_ret", function(recv_msg)
        if recv_msg.template_ids then
            self.skin_template_ids = recv_msg.template_ids
            --最开始的皮肤记录，因为界面显示要用闪金时候的皮肤
            self.origin_skin_template_id = self.skin_template_ids[1]  
        else
            self.skin_template_ids = {}
        end
    end)

    --更换或者解锁皮肤
    network:RegisterEvent("evolution_dressing_ret", function(recv_msg)
        -- print("evolution_dressing_ret", recv_msg.result,recv_msg.type)
        if recv_msg.result == "success" then
            if recv_msg.type == 1 then
                 self.leader.template_id = recv_msg.target_template_id
                 self:InitMercenaryInfo(self.leader)
                 --在阵容中，则重新计算阵容属性
                 self:FormationPropertyChanged(self.leader)
                 graphic:DispatchEvent("change_ladder_skin_success")
                 graphic:DispatchEvent("change_troop_formation")
            elseif recv_msg.type == 2 then
                table.insert(self.skin_template_ids, recv_msg.target_template_id)
                graphic:DispatchEvent("unlock_ladder_success")
            end
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

---------------------------------------虚空大冒险功能 start --------------------------------------

    --查询阵容
    network:RegisterEvent("query_vanity_troop_ret", function(recv_msg)
        self.vanity_mercenarys_list = recv_msg.mercenarys or {}

        self.vanity_troop = recv_msg.troop or {}

        self.reduce_search_times = recv_msg.reduce_search_times or 0

        self:InitVanityTroop()

    end)

    --查询冒险关卡信息
    network:RegisterEvent("query_vanity_maze_states_ret", function(recv_msg)
        if recv_msg.states then
            self.vanity_maze_state_list = recv_msg.states or {}
            graphic:DispatchEvent("update_vanity_maze_info_success", self.is_query_vanity_maze)
        else
            self.vanity_maze_state_list = {}
        end
        self.is_query_vanity_maze = false
    end)

     --查询商品列表
     network:RegisterEvent("query_vanity_goods_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.vanity_good_list = {}
            for k,item in pairs(recv_msg.items) do
                table.insert(self.vanity_good_list, item)
            end
            graphic:DispatchEvent("query_vanity_goods_success")
        else
            self.vanity_maze_state_list = {}
        end
    end)

     --查詢戰鬥記錄
     network:RegisterEvent("query_vanity_play_back_info_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.vanity_maze_battle_number_list = recv_msg.troop_nums or {}
            self.vanity_exp_get_mercenary_list = recv_msg.battle_nums or {}
        else
            self.vanity_maze_battle_number_list = {}
        end
    end)

    --商品兑换
    network:RegisterEvent("vanity_exchange_goods_ret", function (recv_msg)
        if recv_msg.result == "success" then
            local reward_info 
            if recv_msg.good_id and recv_msg.num then
                for k,good_info in pairs(self.vanity_good_list) do
                    if good_info.good_id == recv_msg.good_id then
                        self.vanity_good_list[k].cur_count = self.vanity_good_list[k].cur_count + recv_msg.num
                        reward_info = self.vanity_good_list[k]
                        break
                    end
                end
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                graphic:DispatchEvent("vanity_exchange_goods_success", reward_info)
            end
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --获得关卡所的的英雄列表
    network:RegisterEvent("get_vanity_mercenary_ret", function (recv_msg)
        if recv_msg.result == "success" then
            self.vanity_maze_state_list[recv_msg.maze_id] = recv_msg.maze_state
            if self.vanity_maze_state_list[recv_msg.maze_id + 1] then 
                self.vanity_maze_state_list[recv_msg.maze_id + 1] = constants["VANITY_MAZE_STATE"].challenge_able
                --检测下关是否有新的阵容扩展
                local week = utils:getWDay(time_logic:Now())
                local vanity_maze_conf = config_manager.vanity_maze_config[week]
                for k,v in pairs(vanity_maze_conf) do
                    if v.map_id == recv_msg.maze_id + 1 then
                        local add_troop = v.debut_num - #self.vanity_troop
                        if add_troop > 0 then
                            for i=1,add_troop do
                                table.insert(self.vanity_troop,0)
                            end
                        end
                        break
                    end
                end
            end

            if recv_msg.mercenary_list then
                local get_number = 0
                for k,mercenary in pairs(recv_msg.mercenary_list) do
                    get_number = get_number + 1
                    table.insert(self.vanity_mercenarys_list, mercenary)
                end
                self.get_mercenary_list = recv_msg.mercenary_list 
                self.is_show_vantiy_animation = true
                self:ShowGetVanityMercenary()
                --额外获取到的英雄记录
                local before_number = self.vanity_exp_get_mercenary_list[recv_msg.maze_id] or 0
                self.vanity_exp_get_mercenary_list[recv_msg.maze_id] = before_number + get_number
            end

            

            graphic:DispatchEvent("get_vanity_mercenary_success")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("vanity_buy_recruit_ret", function (recv_msg)
        if recv_msg.result == "success" then
            self.reduce_search_times = recv_msg.reduce_search_times or 0
            local get_number = 0
            if recv_msg.mercenary_list then
                for k,mercenary in pairs(recv_msg.mercenary_list) do
                    get_number = get_number + 1
                    table.insert(self.vanity_mercenarys_list, mercenary)
                end
                self.get_mercenary_list = recv_msg.mercenary_list 
                self.is_show_vantiy_animation = true
                self:ShowGetVanityMercenary()
            end

            local now_maze_id = 1
            for k,v in pairs(self.vanity_maze_state_list) do
                if v == 0 then
                    now_maze_id = k - 1
                    break
                end
            end
            --额外获取到的英雄记录
            local before_number = self.vanity_exp_get_mercenary_list[now_maze_id] or 0
            self.vanity_exp_get_mercenary_list[now_maze_id] = before_number + get_number
            
            graphic:DispatchEvent("get_vanity_reduce_mercenary_success")
            
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --上阵
    network:RegisterEvent("vanity_pitched_in_ret", function (recv_msg)
        if recv_msg.result == "success" then
            local insert_index = 1
            for k,v in pairs(self.vanity_troop) do
                if v == 0 then
                    insert_index = k
                    self.vanity_troop[k] = recv_msg.instance_id
                    break
                end
            end

            self:InitVanityTroop()
            
            graphic:DispatchEvent("update_vainty_formation_success", 1, insert_index)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    -- --下阵
    network:RegisterEvent("vanity_pitched_out_ret", function (recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.instance_id and recv_msg.position then
                local pos = recv_msg.position
                while true do 
                    local value = self.vanity_troop[pos + 1]
                    if not value or value == -1 then
                        self.vanity_troop[pos] = 0
                        break
                    end

                    self.vanity_troop[pos] = value
                    pos = pos + 1
                end

                self:InitVanityTroop()
                local select_pos = recv_msg.position
                if self.vanity_troop[recv_msg.position] == 0 then
                    select_pos = recv_msg.position - 1
                end

                graphic:DispatchEvent("update_vainty_formation_success", 2, select_pos)
            end
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --替换
    network:RegisterEvent("vanity_replace_mercenary_ret", function (recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.instance_id and recv_msg.position then
                local pos = recv_msg.position
                self.vanity_troop[pos] = recv_msg.instance_id

                self:InitVanityTroop()

                graphic:DispatchEvent("update_vainty_formation_success")
            end
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("vanity_sync_troop_ret", function (recv_msg)
        if recv_msg.result == "success" then
            self.vanity_troop = self.change_troop

            self:InitVanityTroop()

            graphic:DispatchEvent("update_vainty_formation_success")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --战斗回放
    network:RegisterEvent("vanity_play_back_ret", function (recv_msg)
        
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end 

        local battle_type = client_constants.BATTLE_TYPE["vs_vanity_play_back"]
        local fight_data = recv_msg.fight_data
        local is_winner = false
        
        if fight_data.result == "success" then
            is_winner = true
        end

        self:InitVanityBackPlayTroop(fight_data.troop)

        graphic:DispatchEvent("show_battle_room", battle_type, fight_data.boss_id, fight_data.battle_property, fight_data.battle_record, is_winner, function()

        end)
    end)
    
    

    --战斗
    network:RegisterEvent("vanity_challenge_ret", function (recv_msg)
        local battle_type = client_constants.BATTLE_TYPE["vs_vanity"]

        local is_winner = false
        if recv_msg.result == "success" then
            is_winner = true
        elseif recv_msg.result == "battle_failure" then
            is_winner = false
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end 

        graphic:DispatchEvent("show_battle_room", battle_type, recv_msg.boss_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
            
            --战斗完成消耗战斗次数
            local fromation_change = false
            local battle_mercenary_num = 0
            for k,v in pairs(self.vanity_troop) do
                for k1,mercenary in pairs(self.vanity_mercenarys_list) do
                    if mercenary.instance_id == v then
                        battle_mercenary_num = battle_mercenary_num + 1
                        self.vanity_mercenarys_list[k1].battle_num = self.vanity_mercenarys_list[k1].battle_num - 1
                        if self.vanity_mercenarys_list[k1].battle_num <= 0 then
                            --没有可用次数
                            fromation_change = true
                            self.vanity_troop[k] = 0
                        end
                        break
                    end
                end
            end

            --统计战斗人数量
            local before_number = self.vanity_maze_battle_number_list[recv_msg.maze_id] or 0
            self.vanity_maze_battle_number_list[recv_msg.maze_id] = before_number + battle_mercenary_num

            if fromation_change then
                self:InitVanityTroop()
            end

            if is_winner then
                --战斗胜利
                local reward_info_list = {{id = constants["REWARD_TYPE"].resource, param1 = constants["RESOURCE_TYPE"].vanity_adventure, param2 = recv_msg.win_resource_num}}
                reward_logic:AddRewardInfo(0, reward_info_list)
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel",function ()
                    if recv_msg.sattle_resource_num and recv_msg.sattle_resource_num > 0 then
                        graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_reward", recv_msg.sattle_resource_num)
                    end
                end)

                if recv_msg.maze_id == constants["VANITY_MAX_MAZE_ID"] or (recv_msg.sattle_resource_num and recv_msg.sattle_resource_num > 0) then
                    self.vanity_maze_state_list[recv_msg.maze_id] = constants["VANITY_MAZE_STATE"].maze_finish
                else
                    self.vanity_maze_state_list[recv_msg.maze_id] = constants["VANITY_MAZE_STATE"].challenge_success 
                end
                
                graphic:DispatchEvent("vanity_battle_success")
                graphic:DispatchEvent("update_vanity_maze_info_success")
            end

        end)
    end)
    
    

---------------------------------------虚空大冒险功能  end  --------------------------------------

    network:RegisterEvent("recurit_library_time_ret", function(recv_msg)
        -- print("evolution_dressing_ret", recv_msg.result,recv_msg.type)
        if recv_msg.result == "success" then
            if recv_msg.count_down_time then
                self.mercenarys_cut_down_time[recv_msg.template_id] = recv_msg.count_down_time 
            else
               self.mercenarys_cut_down_time[recv_msg.template_id] = 0 
            end
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_soul_stone_panel", recv_msg.template_id, "recruit")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("clear_recurit_library_time_ret", function(recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.count_down_time then
                self.mercenarys_cut_down_time[recv_msg.template_id] = recv_msg.count_down_time 
            else
               self.mercenarys_cut_down_time[recv_msg.template_id] = 0 
            end
            graphic:DispatchEvent("clear_recurit_library_time_success")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

end

return troop

