local network = require "util.network"
local config_manager = require "logic.config_manager"
local skill_manager = require "logic.skill_manager"

local common_function_util = require "util.common_function"

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

local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local bit_extension = require "util.bit_extension"
local configuration = require "util.configuration"

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local MERCENARY_REPLACE_MODE = constants.MERCENARY_REPLACE_MODE
local PASSIVE_EFFECT_TYPE = constants.PASSIVE_SKILL_EFFECT_TYPE
local MAX_FORMATION_NUM = constants.MAX_FORMATION_NUM

local FORCE_LV_COST_RESOURCE_NUM = constants["FORCE_LV_COST_RESOURCE_NUM"]
local MERCENARY_AETIFACT_STATUS = constants["MERCENARY_AETIFACT_STATUS"]

local CRAFT_COST_RESOURCE = client_constants["CRAFT_COST_RESOURCE"]

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

    self.leader_name = ""

    self.leader = nil

    self.leader_bp = 0

    self.mercenary_list = {}

    self.dodge = 0
    self.speed = 0
    self.authority = 0
    self.defense = 0

    self.extra_dodge = 0
    self.extra_speed = 0
    self.extra_authority = 0
    self.extra_defense = 0

    self.battle_point = 0
    self.exp = 0
    
    self.mercenary_num = 0
    self.contract_bp = 0

    self.cooperative_skill_list = {}
    self.all_mercenary_template_ids = {}
    self.stack_list = {}

    self.mercenary_library = {}
    self.weapon_list = {}

    self.formations = {}
    for i = 1, MAX_FORMATION_NUM do
        self.formations[i] = {}
        self.weapon_list[i] = 0
    end

    --此formation_id 和服务端保持一致
    self.cur_formation_id = 0

    --仅用于客户端显示用，在更换完阵容后，也要重置
    self.client_formation_id = 0

    self.troop_property_changed = false

    self:RegisterMsgHandler()
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

    if self:MercenaryIsInFormation(self.leader, self.cur_formation_id) then
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

function troop:MercenaryIsInLibrary(template_id)
    if not self.mercenary_library[template_id] then
        self.mercenary_library[template_id]  = 0
        return true
    else
        return false
    end
end

function troop:CheckGenreLimit(genre_table)
    local limit_flag = false
    for _, v in ipairs(genre_table) do 
        local use_formation_id = self.cur_formation_id
        --以客户端阵容优先
        if self.client_formation_id ~= use_formation_id then 
            use_formation_id = self.client_formation_id
        end
        local formation = self.formations[use_formation_id]

        for i = 1, #formation do
            local mercenary = formation[i]
            local template_info = mercenary.template_info
            if template_info.genre == tonumber(v) then 
                limit_flag = true
                break
            end
        end

        if limit_flag then 
            break
        end
    end

    return limit_flag
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
        self.troop_property_changed = true
    end
end

function troop:IsWeaponEquipped(formation_id, weapon_id)
    formation_id = self.cur_formation_id or formation_id
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

--设置阵容中的属性
function troop:SetPropertyFlag()
    self.troop_property_changed = true
end

--初始化一个mercenary info
function troop:InitMercenaryInfo(mercenary)
    self.mercenary_list[mercenary.instance_id] = mercenary

    self.mercenary_num = self.mercenary_num + 1

    local template_info = mercenary_config[mercenary.template_id]

    
    mercenary.template_info = template_info

    self:CalcMercenaryProperty(mercenary)

    self:CalcMercenaryBP(mercenary)

    if mercenary.is_leader then
        self:CalcLeaderContract()
    end
end

--初始化阵容信息
function troop:InitFormationsInfo(formation_info, formation_id)
    for i = 1, #formation_info do
        local mercenary = self.mercenary_list[formation_info[i]]
        self.formations[formation_id][i] = mercenary
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

--计算军团的战斗力(默认更新军团战斗力的显示)
function troop:CalcTroopBP(formation_id, update_battle_point)
    local battle_point = 0

    formation_id = formation_id or self.cur_formation_id

    for i = 1, #self.formations[formation_id] do
        local mercenary = self.formations[formation_id][i]

        local template_info = mercenary.template_info

        mercenary.battle_point = template_info.init_bp
        --计算战斗力
        self:CalcMercenaryBP(mercenary)

        battle_point = mercenary.battle_point + battle_point
    end

    self.battle_point = battle_point

    --更新最高战力 任务中
    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["max_bp"], self.battle_point)

    if self.cur_formation_id == formation_id or update_battle_point then
        graphic:DispatchEvent("update_battle_point", self.battle_point)
    end
end

--获取当前战力
function troop:GetTroopBP()
    return self.battle_point
end

--计算军团的基础属性
function troop:GetTroopProperty(formation_id)
    if not self.troop_property_changed then
        return self.speed, self.authority, self.dodge, self.defense
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

    self.special_skill_list = {}

    local cooperative_skill_list = self.cooperative_skill_list
    local all_mercenary_template_ids = self.all_mercenary_template_ids

    self.speed, self.dodge, self.authority, self.defense = 0, 0, 0, 0
    self.extra_speed, self.extra_dodge, self.extra_authority, self.extra_defense = 0, 0, 0, 0

    formation_id = formation_id or self.cur_formation_id

    local cur_weapon_id = self.weapon_list[formation_id]
    for i = 1, #self.formations[formation_id] do

        local mercenary = self.formations[formation_id][i]
        local template_info = mercenary.template_info
        local template_id = mercenary.template_id

        self.dodge = mercenary.dodge + self.dodge
        self.speed = mercenary.speed + self.speed
        self.authority = mercenary.authority + self.authority
        self.defense = mercenary.defense + self.defense

        all_mercenary_template_ids[template_id] = all_mercenary_template_ids[template_id] and all_mercenary_template_ids[template_id] + 1 or 1

        if mercenary.is_leader and cur_weapon_id ~= 0 then
            self.special_skill_index = 0
            skill_manager:AddPassiveSkill(self, config_manager.destiny_skill_config[cur_weapon_id].skill_id)

        else
            for i = 1, 3 do
                local skill_id = template_info["skill"..i]
                if skill_id ~= 0 then
                    self.special_skill_index = 0
                    skill_manager:AddPassiveSkill(self, skill_id)
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
                    self.special_skill_index = 0
                    skill_manager:AddPassiveSkill(self, skill_id)
                end
            end
        end
    end

    if self.special_skill_list then
        for i, skill_id in ipairs(self.special_skill_list) do
            self.special_skill_index = i
            skill_manager:AddPassiveSkill(self, skill_id, true)
        end

        self.dodge = self.dodge + self.extra_dodge
        self.authority = self.authority + self.extra_authority
        self.defense = self.defense + self.extra_defense
        self.speed = self.speed + self.extra_speed
    end

    self.troop_property_changed = false

    return self.speed, self.authority, self.dodge, self.defense
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

--添加佣兵到探索队列中, 空位上阵
function troop:InsertMercenaryToFormation(formation_id, instance_id, src_position, target_position)
    local mercenary = self.mercenary_list[instance_id]

    if #self.formations[formation_id] >= self.formation_capacity then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["exploring_list_is_full"])
        return
    end

    --佣兵已经在阵容中
    if self:MercenaryIsInFormation(mercenary, formation_id) then
        graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP["already_in_exploring_list"])
        return
    end
    network:Send({insert_formation = { formation_id = formation_id, instance_id = instance_id, position = target_position }})
end

--检测佣兵是否在阵容中
function troop:MercenaryIsInFormation(mercenary, formation_id)
    local bit_value = bit_extension:GetBitNum(mercenary.formation_info, (formation_id - 1))
    return bit_value == 1
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
        if not self:MercenaryIsInFormation(self.mercenary_list[instance_id], formation_id) then
            return
        end
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
    if not src_mercenary or (not self:MercenaryIsInFormation(src_mercenary, formation_id)) then
        return
    end

    --上阵的佣兵不存在或者在阵容中
    if not dest_mercenary or (self:MercenaryIsInFormation(dest_mercenary, formation_id)) then
        return
    end

    network:Send({exchange_formation_pos = { formation_id = formation_id, src_id = src_id, dest_id = dest_id}})
end

--休息
function troop:RestMercenary(formation_id, instance_id)

    local mercenary = self:GetMercenaryInfo(instance_id)
    --佣兵不在阵容中
    if (not mercenary) or (not self:MercenaryIsInFormation(mercenary, formation_id)) then
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
        resource_type = constants.RESOURCE_TYPE["friendship_pt"]
        num = constants.RECRUIT_COST["friendship_door"]
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
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["soul_chip"], cost_soul_chip, true) then
        return
    end

    if not feature_config:IsFeatureOpen("sign_contract") then
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

    if not self.mercenary_library[template_id] then
        graphic:DispatchEvent("show_prompt_panel", "not_craft")
        return
    end

    for i = 1, 7 do
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
    --检测资源
    local forge_config = config_manager.weapon_forge_config[weapon_lv + 1]
    for i = 3, #forge_resource_list - 2, 2 do
        local resource_name = forge_resource_list[i]
        local num = forge_config[resource_name]
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, show_prompt) then
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

--检测宝具缺少的资源
function troop:CheckOpenArtifactResource(show_prompt)
    for i = 1, #open_artifact_list , 2 do
        local resource_name = open_artifact_list[i]
        local num = open_artifact_list[i + 1]
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, show_prompt) then
            return false
        end
    end

    return true
end

--开启宝具
function troop:OpenArtifact(instance_id)
    local mercenary = self.mercenary_list[instance_id]

    local artifact_status = self:GetArtifactStatus(instance_id)

    if artifact_status == MERCENARY_AETIFACT_STATUS["not_have_artifact"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_not_has_artifact")

    elseif artifact_status == MERCENARY_AETIFACT_STATUS["weapon_lv_not_enough"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_open_artifact_weapon_lv_not_enough")

    elseif artifact_status == MERCENARY_AETIFACT_STATUS["not_open_artifact"] then
        if not self:CheckOpenArtifactResource(true) then
            return
        end

        network:Send({ open_mercenary_artifact = { mercenary_id = instance_id } })
    else
        graphic:DispatchEvent("show_prompt_panel", "mercenary_already_open_artifact")
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

function troop:CreateMercenary(template_id, ex_prop_type, ex_prop_val)
    local mercenary = {
        template_id = template_id,
        exp = 0,
        weapon_lv = 0,
        is_open_artifact = false,
        force_lv = 0,
        wakeup = 1,
        level = 1,
        formation_info = 0,
        ex_prop_type = ex_prop_type,
        ex_prop_val = ex_prop_val,
        contract_lv = 0,
        soul_bone = 0,
    }
    
    local instance_id = self.mercenary_id_generator + 1
    self.mercenary_id_generator = instance_id

    mercenary.instance_id = instance_id
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

    network:Send({sign_contract = { mercenary_id = mercenary_id }})

end

--属性转化
function troop:ChangeExProperty(mercenary_id)
    local mercenary = self.mercenary_list[mercenary_id]
    if not mercenary then
        return
    end

    -- 突破未到满级
    if mercenary.force_lv < constants["MAX_FORCE_LEVEL"] then
        graphic:DispatchEvent("show_prompt_panel", "mercenary_force_lv_not_enough_for_change_property")
        return
    end

    local consume_config = constants.CHANGE_EX_PROPERTY_RESOURCE

    --巨魔雕像
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["golem"], consume_config.golem, true) then
        return
    end

    --灵魂碎片 ＝ 佣兵解雇获得数量
    if not resource_logic:GetResourceNum(RESOURCE_TYPE["soul_chip"], mercenary.template_info.soul_chip * consume_config.scale, true) then
        return
    end

    network:Send({ change_mercenary_exproperty = { mercenary_id = mercenary_id }})
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
    self.troop_property_changed = true
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
    if self:MercenaryIsInFormation(mercenary, self.cur_formation_id) then
        self:CalcTroopBP(self.cur_formation_id)
        self.troop_property_changed = true
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
    end

    self:CalcMercenaryLevel(dest_mercenary)
    self:CalcMercenaryBP(dest_mercenary)
    self:CalcMercenaryProperty(dest_mercenary)
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

        self.troop_property_changed = true

        if recv_msg.weapon_list then
            for i = 1, MAX_FORMATION_NUM do
                self.weapon_list[i] = recv_msg.weapon_list[i]
            end
        end

        if recv_msg.formation_info then
            local formation_info = recv_msg.formation_info
            for formation_id = 1, MAX_FORMATION_NUM do
                local f = formation_info["formation" .. formation_id]
                self:InitFormationsInfo(f, formation_id)
            end
        end

        self:CalcTroopBP(self.cur_formation_id, true)
    end)

    --给佣兵分配经验
    network:RegisterEvent("alloc_mercenary_exp_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]

            mercenary.exp = recv_msg.exp

            local origin_level = mercenary.level

            self:CalcMercenaryLevel(mercenary)
            self:CalcMercenaryBP(mercenary)

            self:CalcTroopBP()

            if mercenary.instance_id == self.leader.instance_id then
                user_logic:UpdateUserInfo(false)
            end

            graphic:DispatchEvent("update_mercenary_level", recv_msg.mercenary_id, mercenary.level - origin_level)

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["exp"])
        end
    end)

    --空位上阵
    network:RegisterEvent("insert_formation_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.instance_id]
            --空位上阵
            self:SetMercenaryFormationStatus(mercenary.instance_id, recv_msg.formation_id, true)

            table.insert(self.formations[recv_msg.formation_id], mercenary)

            self:CalcTroopBP(recv_msg.formation_id, true)

            self.troop_property_changed = true

            local mode = client_constants["MERCENARY_TO_FORMATION"]["add"]
            local pos = #self.formations[recv_msg.formation_id]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, pos, mercenary.instance_id, nil, recv_msg.formation_id)
            reminder_logic:CheckFormationReminder()
            reminder_logic:CheckForgeReminder()
        end
    end)

    --替换佣兵(不在阵容中的佣兵替换下已经在阵容中的佣兵)
    network:RegisterEvent("exchange_formation_pos_ret", function(recv_msg)
        if recv_msg.result == "success" then

            local src_mercenary = self.mercenary_list[recv_msg.src_id]
            local dest_mercenary = self.mercenary_list[recv_msg.dest_id]

            self:SetMercenaryFormationStatus(recv_msg.src_id, recv_msg.formation_id, false)
            self:SetMercenaryFormationStatus(recv_msg.dest_id, recv_msg.formation_id, true)

            self.formations[recv_msg.formation_id][recv_msg.src_pos] = dest_mercenary

            if recv_msg.dest_pos ~= 0 then
                self.formations[recv_msg.formation_id][recv_msg.dest_pos] = src_mercenary
            else
                self:CalcTroopBP(recv_msg.formation_id, true)
                self.troop_property_changed = true
            end

            local mode = client_constants["MERCENARY_TO_FORMATION"]["replace"]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, recv_msg.src_pos, recv_msg.src_id, recv_msg.dest_id, recv_msg.formation_id)
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        end
    end)

    --拖动调整佣兵位置
    network:RegisterEvent("adjust_mercenary_position_ret", function(recv_msg)
        print("adjust_mercenary_position_ret = ", recv_msg.result)

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
                self.troop_property_changed = true

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

    --佣兵休息
    network:RegisterEvent("rest_mercenary_ret", function(recv_msg)
        if recv_msg.result == "success" then

            self:SetMercenaryFormationStatus(recv_msg.instance_id, recv_msg.formation_id, false)

            table.remove(self.formations[recv_msg.formation_id], recv_msg.position)

            self:CalcTroopBP(recv_msg.formation_id, true)
            self.troop_property_changed = true

            local pos = math.min(recv_msg.position, #self.formations[recv_msg.formation_id])
            local mode = client_constants["MERCENARY_TO_FORMATION"]["rest"]
            graphic:DispatchEvent("update_exploring_merceanry_position", mode, pos, recv_msg.instance_id, nil, recv_msg.formation_id)

            reminder_logic:CheckFormationReminder()
            reminder_logic:CheckForgeReminder()
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
            local mercenary_library =  self.mercenary_library
            for i, id in pairs(recv_msg.mercenary_id_list) do
                local mercenary = self.mercenary_list[id]
                local template_id = mercenary.template_id
                soul_chip_num = soul_chip_num + mercenary_config[template_id]["soul_chip"]
                mercenary_library[template_id] = mercenary_library[template_id] + 1

                self.mercenary_list[id] = nil
                local bone_type = "soul_bone" .. mercenary_config[template_id].quality
                
                local bone_num  = mercenary_config[template_id]["soul_bone"]       
                local resource_list  = resource_logic:GetResourceList()

                --返回灵魂石
                for j = 1, mercenary.contract_lv do--契约 
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

            print(recv_msg.recruit_cost)
            if recv_msg.recruit_cost then
                daily_logic:SetRecruitCost(recv_msg.recruit_cost)
            end
            
            local recruit_num = 1
            if recv_msg.door_type == "ten_mercenary_door" or recv_msg.door_type == "ten_friendship_door" or recv_msg.door_type == "magic_door" then
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
            graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", self.camp_capacity)
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

            self:CalcMercenaryProperty(mercenary)

            --在阵容中，则重新计算阵容属性
            self:FormationPropertyChanged(mercenary)

            graphic:DispatchEvent("open_artifact", recv_msg.mercenary_id)

            --graphic:DispatchEvent("update_mercenary_info", recv_msg.mercenary_id)

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
            self.troop_property_changed = true

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
            self.mercenary_library[recv_msg.template_id] = recv_msg.soul_count

            graphic:DispatchEvent("craft_soul_stone_success", recv_msg.template_id)

            local mercenary = mercenary_config[recv_msg.template_id]
            -- graphic:DispatchEvent("show_prompt_panel", "craft_success")

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

    -- 属性转换
    network:RegisterEvent("change_mercenary_exproperty_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mercenary = self.mercenary_list[recv_msg.mercenary_id]
            mercenary.ex_prop_type = recv_msg.ex_prop_type
            mercenary.ex_prop_val = recv_msg.ex_prop_val

            self:CalcMercenaryProperty(mercenary)
            self:CalcMercenaryBP(mercenary)

            if self:MercenaryIsInFormation(mercenary, self.cur_formation_id) then
                self:CalcTroopBP(self.cur_formation_id)
                self.troop_property_changed = true
            end

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
end

return troop

