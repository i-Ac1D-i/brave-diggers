local config_manager = require "logic.config_manager"
local constants = require "util.constants"

local mercenary_config = config_manager.mercenary_config
local mercenary_exp_config = config_manager.mercenary_exp_config
local active_skill_config  = config_manager.active_skill_config
local passive_skill_config = config_manager.passive_skill_config
local cooperative_skill_config = config_manager.cooperative_skill_config

local PASSIVE_SKILL_EFFECT_TYPE = constants.PASSIVE_SKILL_EFFECT_TYPE
local PROPERTY_TYPE_NAME = constants.PROPERTY_TYPE_NAME

--每点先攻值增加%0.5的暴击伤害
local SPEED_FACTOR = 0.005

--每点闪避值增加%0.5的治疗量
local DODGE_FACTOR = 0.005

--每点王者值增加%1的最终伤害
local AUTHORITY_FACTOR = 0.01

local math_ceil = math.ceil
local math_floor = math.floor

local skill_manager = 
{
    active_effects = {},
    passive_effects = {},
}

function skill_manager:Init()

    local ACTIVE_SKILL_EFFECT_TYPE = constants.ACTIVE_SKILL_EFFECT_TYPE
    local SKILL_CULTIVATION = constants.SKILL_CULTIVATION
    self.SPEED_FACTOR = SPEED_FACTOR
    self.DODGE_FACTOR = DODGE_FACTOR
    self.AUTHORITY_FACTOR = AUTHORITY_FACTOR

    local effects = self.active_effects

    local CalcDamageBp = function (receiver, damage)

        if receiver.cur_shield_bp > 0 then
            if receiver.cur_shield_bp > damage then
                receiver.cur_shield_bp = receiver.cur_shield_bp - damage
                damage = 0
            else
                damage = damage - receiver.cur_shield_bp
                receiver.cur_shield_bp = 0
            end

        end

        receiver.cur_bp = receiver.cur_bp - damage
        --FYD  如果当前被施法方战力等于或低于0 同时存在抵御致死攻击的效果
        receiver.is_resist_lethal = false  --是否抵御致死
        if receiver.cur_bp <= 0 and receiver.resist_lethal_num and receiver.resist_lethal_num > 0 then
            receiver.resist_lethal_num = receiver.resist_lethal_num -1
            receiver.is_resist_lethal = true
            receiver.resist_lethal_damage = receiver.cur_bp
            receiver.cur_bp = 1
        end
    end
    --修炼的计算方法
    local CaculateCultivation = function(receiver,caster,cur_type,damage)

         --施法方的当前修炼技能伤害加成
         local coefficient1 = 0
         local coefficient2 = 0
        if caster.cultivation_property[cur_type] and caster.cultivation_property[cur_type].coefficient1 then
            coefficient1 = caster.cultivation_property[cur_type].coefficient1
        end
        if receiver.cultivation_property[cur_type] and receiver.cultivation_property[cur_type].coefficient2 then
            coefficient2 = receiver.cultivation_property[cur_type].coefficient2
        end
        damage = math.ceil( damage * (1 + coefficient1/100 + coefficient2/100) ) 

        return damage
    end
    local ReplyProcess = function(caster, receiver,reply,cur_type)
        --施法方的当前修炼技能伤害加成
        local coefficient1 = 0
        local coefficient2 = 0
        if caster.cultivation_property[cur_type] and caster.cultivation_property[cur_type].coefficient1 then
            coefficient1 = caster.cultivation_property[cur_type].coefficient1
        end
        if receiver.cultivation_property[cur_type] and receiver.cultivation_property[cur_type].coefficient2 then
            coefficient2 = receiver.cultivation_property[cur_type].coefficient2
        end
        --回血量处理
        reply = math.ceil(reply * (1+ coefficient1/100 + coefficient2/100))
        return reply
    end

    --普通攻击
    effects[ACTIVE_SKILL_EFFECT_TYPE["melee_damage"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil((caster.max_bp / 5 + caster.cur_bp / 10) * receiver.damage_reduction_factor * caster.final_damage_modifier)
        if caster.exhaust_turn > 0 then
            damage = 1
        end
        CalcDamageBp(receiver,damage)
    end

    --暴击
    effects[ACTIVE_SKILL_EFFECT_TYPE["critical_damage"]] = function(caster, receiver, skill, is_dodge)
        local damage = math_ceil((caster.max_bp / 5 + caster.cur_bp / 10) * (skill.param/100 + SPEED_FACTOR * caster.speed) * receiver.damage_reduction_factor * caster.final_damage_modifier)
        local cur_type = SKILL_CULTIVATION["critical_damage"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)
        if caster.exhaust_turn > 0 then
            damage = 1
        end
        CalcDamageBp(receiver,damage)
    end

    --伤害加深
    effects[ACTIVE_SKILL_EFFECT_TYPE["increase_damage"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil((caster.max_bp / 5 + caster.cur_bp / 10) * skill.param/100 * receiver.damage_reduction_factor * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["increase_damage"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end
    
    --怒气攻击
    effects[ACTIVE_SKILL_EFFECT_TYPE["rage_damage"]]= function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil((caster.max_bp - caster.cur_bp) * skill.param/100 * receiver.damage_reduction_factor * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["rage_damage"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)
        if caster.exhaust_turn > 0 then
            damage = 1
        end

        damage = damage > 0 and damage or 1
        CalcDamageBp(receiver,damage)

    end

    --反噬敌当
    effects[ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_bp"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil(receiver.cur_bp * skill.param/100 * receiver.damage_reduction_factor * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["damage_by_enemy_bp"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)
        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end

    --反噬敌初
    effects[ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_init_bp"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil(receiver.max_bp * skill.param/100 * receiver.damage_reduction_factor * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["damage_by_enemy_init_bp"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end

    --反噬敌损
    effects[ACTIVE_SKILL_EFFECT_TYPE["damage_by_enemy_loss_bp"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil((receiver.max_bp - receiver.cur_bp) * skill.param/100 * receiver.damage_reduction_factor * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["damage_by_enemy_loss_bp"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        damage = damage > 0 and damage or 1
        CalcDamageBp(receiver,damage)
    end

    --战力吸收
    effects[ACTIVE_SKILL_EFFECT_TYPE["bp_steal"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local damage = math_ceil((caster.max_bp / 5 + caster.cur_bp / 10) * receiver.damage_reduction_factor * caster.final_damage_modifier * (skill.param2 and (skill.param2 / 100) or 1))

        local cur_type = SKILL_CULTIVATION["bp_steal"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        caster.cur_bp = math_ceil(caster.cur_bp + damage * skill.param/100 * caster.bp_increase_factor)
        
        CalcDamageBp(receiver,damage)
    end

    --战力提升己当
    effects[ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_bp"]] = function(caster, receiver, skill, is_dodge)
        local cur_type = SKILL_CULTIVATION["increase_by_self_bp"]

        --当前回复量
        local reply = math_ceil(caster.cur_bp * skill.param/100 * caster.bp_increase_factor)
        local cur_type = SKILL_CULTIVATION["increase_by_self_bp"]
        reply = ReplyProcess(caster, receiver,reply,cur_type)
        caster.cur_bp = caster.cur_bp + reply 

        if is_dodge then
            return
        end

        local damage = (caster.max_bp * 0.2 + caster.cur_bp * 0.1) * receiver.damage_reduction_factor * caster.final_damage_modifier
        local ratio = (skill.param2 and skill.param2 ~= 0) and skill.param2 or 100
        damage = math_ceil(damage * ratio/100)
        
        if caster.exhaust_turn > 0 then
            damage = 1
        end
        CalcDamageBp(receiver,damage)
    end

    --战力提升己初
    effects[ACTIVE_SKILL_EFFECT_TYPE["increase_by_self_init_bp"]] = function(caster, receiver, skill, is_dodge)
        local reply = math_ceil(caster.max_bp * skill.param/100 * caster.bp_increase_factor)
        local cur_type = SKILL_CULTIVATION["increase_by_self_init_bp"]
        reply = ReplyProcess(caster, receiver,reply,cur_type)
        caster.cur_bp = caster.cur_bp + reply

        if is_dodge then
            return
        end

        local damage = (caster.max_bp * 0.2 + caster.cur_bp * 0.1) * receiver.damage_reduction_factor * caster.final_damage_modifier
        local ratio = (skill.param2 and skill.param2 ~= 0) and skill.param2 or 100
        damage = math_ceil(damage * ratio/100)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end

    --战力提升敌当
    effects[ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_bp"]] = function(caster, receiver, skill, is_dodge)
        local reply = math_ceil(receiver.cur_bp * skill.param/100 * caster.bp_increase_factor)
        local cur_type = SKILL_CULTIVATION["increase_by_enemy_bp"]
        reply = ReplyProcess(caster, receiver,reply,cur_type)
        caster.cur_bp = caster.cur_bp + reply

        if is_dodge then
            return
        end

        local damage = (caster.max_bp * 0.2 + caster.cur_bp * 0.1) * receiver.damage_reduction_factor * caster.final_damage_modifier
        local ratio = (skill.param2 and skill.param2 ~= 0) and skill.param2 or 100
        damage = math_ceil(damage * ratio/100)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end

    --战力提升敌初
    effects[ACTIVE_SKILL_EFFECT_TYPE["increase_by_enemy_init_bp"]] = function(caster, receiver, skill, is_dodge)
        local reply = math_ceil(receiver.max_bp * skill.param/100 * caster.bp_increase_factor)
        local cur_type = SKILL_CULTIVATION["increase_by_enemy_init_bp"]
        reply = ReplyProcess(caster, receiver,reply,cur_type)
        caster.cur_bp = caster.cur_bp + reply
        if is_dodge then
            return
        end

        local damage = (caster.max_bp * 0.2 + caster.cur_bp * 0.1) * receiver.damage_reduction_factor * caster.final_damage_modifier
        local ratio = (skill.param2 and skill.param2 ~= 0) and skill.param2 or 100
        damage = math_ceil(damage * ratio/100)

        if caster.exhaust_turn > 0 then
            damage = 1
        end

        CalcDamageBp(receiver,damage)
    end

    --纯粹攻击 不用计算防御值
    effects[ACTIVE_SKILL_EFFECT_TYPE["true_damage"]]  = function(caster, receiver, skill, is_dodge)
        local damage = math_ceil((caster.max_bp / 5 + caster.cur_bp / 10) * skill.param/100 * caster.final_damage_modifier)

        local cur_type = SKILL_CULTIVATION["true_damage"]
        damage = CaculateCultivation(receiver,caster,cur_type,damage)

        if caster.exhaust_turn > 0 then
            damage = 1
        end
        
        CalcDamageBp(receiver,damage)
    end

    --复制技能
    effects[ACTIVE_SKILL_EFFECT_TYPE["copy_skill"]] = function(caster, receiver, skill, is_dodge)
        skill = receiver.last_turn_skill or self:GetMeleeSkill()
        if skill then
            receiver.damage_reduction_factor = skill.ignore_defense and 1.0 or (100 / (100 + receiver.defense))
            local effect_method = self:GetEffect(skill.effect_type)
            effect_method(caster, receiver, skill, is_dodge)

            return skill
        end
    end

    effects[ACTIVE_SKILL_EFFECT_TYPE["armageddon_a"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local caster_damage = math_ceil(caster.cur_bp * skill.param * 0.01)
        local receiver_damage = math_ceil(receiver.cur_bp * skill.param * 0.01 * receiver.damage_reduction_factor)

        if caster.exhaust_turn > 0 then
            receiver_damage = 1
        end

        caster.cur_bp = caster.cur_bp - caster_damage
        CalcDamageBp(receiver,receiver_damage)
    end

    effects[ACTIVE_SKILL_EFFECT_TYPE["armageddon_b"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        caster.damage_reduction_factor = (100 / (100 + caster.defense))

        local caster_damage = math_ceil(caster.cur_bp * (skill.param * 0.01) * caster.damage_reduction_factor)
        local receiver_damage = math_ceil(receiver.cur_bp * (skill.param * 0.01) * receiver.damage_reduction_factor)

        if caster.exhaust_turn > 0 then
            receiver_damage = 1
        end

        caster.cur_bp = caster.cur_bp - caster_damage
        CalcDamageBp(receiver,receiver_damage)
    end

    --战力百分比互换
    effects[ACTIVE_SKILL_EFFECT_TYPE["swap_bp_percent"]] = function(caster, receiver, skill, is_dodge)
        if is_dodge then
            return
        end

        local caster_bp_percent = caster.cur_bp / caster.max_bp
        local receiver_bp_percent = receiver.cur_bp / receiver.max_bp

        caster.cur_bp = math.ceil(receiver_bp_percent * caster.max_bp)
        receiver.cur_bp = math.ceil(caster_bp_percent * receiver.max_bp)
    end
end

function skill_manager:GetEffect(effect_id)
    return self.active_effects[effect_id]
end

function skill_manager:GetMeleeSkill()
    return config_manager.active_skill_config[1000001]
end

function skill_manager:IsCanUseSkill(skill_id, turn, bp_pecent)
    if skill_id < constants["ACTIVE_SKILL_ID_OFFSET"] then
        return false
    end

    local turn = turn or 1
    local skill = skill_manager:GetSkill(skill_id)
    if turn <= skill.turn_cond1 then
       return false

    elseif skill.turn_cond2 ~= 0 and turn >= skill.turn_cond2 then
        return false
    end

    if bp_pecent <= skill.self_bp_cond1 then
        return false

    elseif skill.self_bp_cond2 ~= 0 and bp_pecent >= skill.self_bp_cond2 then
        return false
    end

    if bp_pecent <= skill.enemy_bp_cond1 then
        return false

    elseif skill.enemy_bp_cond2 ~= 0 and bp_pecent >= skill.enemy_bp_cond2 then
        return false
    end

    return true
end

function skill_manager:CheckCoopSkillCanUse(troop, coop_skill_id)
    --检测合体技能
    local can_use = true
    --存在合体技
    local coop_skill = cooperative_skill_config[coop_skill_id]

    if coop_skill then
        for mercenary_template_id, need_num in pairs(coop_skill.mercenary_ids) do
            local cur_num = troop.all_mercenary_template_ids[mercenary_template_id]

            if not cur_num or cur_num < need_num then
                can_use = false
                break
            end
        end
    end

    return can_use
end

function skill_manager:GetSkill(skill_id)
    if skill_id >= 1000001 then
        return active_skill_config[skill_id]
    else
        return passive_skill_config[skill_id]
    end
end

function skill_manager:FixPropertyNum(troop, skill, add_num)
    if skill.stack_limit ~= 0 then
        local skill_index = troop.special_skill_index
        local cur_num = troop.stack_list[skill_index] or 0

        if cur_num + add_num > skill.stack_limit then
            add_num = skill.stack_limit - cur_num
        end

        troop.stack_list[skill_index] = cur_num + add_num
    end

    return add_num
end

function skill_manager:AddPassiveSkill(troop, skill_id, take_special)
    local skill_info = self:GetSkill(skill_id)
    troop.speed = troop.speed + (skill_info.speed or 0)
    troop.defense = troop.defense + (skill_info.defense or 0)
    troop.dodge = troop.dodge + (skill_info.dodge or 0)
    troop.authority = troop.authority + (skill_info.authority or 0)

    if skill_id >= constants["ACTIVE_SKILL_ID_OFFSET"] then
        return
    end
    
    local skill = config_manager.passive_skill_config[skill_id]
    if not skill then
        return
    end

    if skill.is_special and not take_special then
        if skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["convert_property"] then
            table.insert(troop.special_skill_list, skill_id)

        else
            table.insert(troop.special_skill_list, 1, skill_id)
        end

        return
    end

    --被动技能立即生效
    local num = 0

    --只能是合体技
    if skill.job ~= 0 or skill.sex ~= 0 or skill.race ~= 0 then
        for template_id, mercenary_num in pairs(troop.all_mercenary_template_ids) do
            local mercenary_template_info = config_manager.mercenary_config[template_id]
            local check_job = skill.job == 0 or skill.job == mercenary_template_info.job
            local check_sex = skill.sex == 0 or skill.sex == mercenary_template_info.sex
            local check_race = skill.race == 0 or skill.race == mercenary_template_info.race

            if check_job and check_sex and check_race then
                num = num + mercenary_num
            end
        end

    else
        num = 1
    end

    local add_num = skill.param1 * num
    if skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["increase_speed"] then
        troop.speed = troop.speed + self:FixPropertyNum(troop, skill, add_num)

    elseif skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["increase_defense"] then
        troop.defense = troop.defense + self:FixPropertyNum(troop, skill, add_num)

    elseif skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["increase_dodge"] then
        troop.dodge = troop.dodge + self:FixPropertyNum(troop, skill, add_num)

    elseif skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["increase_authority"] then
        troop.authority = troop.authority + self:FixPropertyNum(troop, skill, add_num)

    elseif skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["convert_property"] then
        if skill.param1 == 0 or skill.param2 == 0 or skill.param3 == 0 then
            return
        end

        local src_property = PROPERTY_TYPE_NAME[skill.param1]
        local dst_property = "extra_" .. PROPERTY_TYPE_NAME[skill.param2]

        local src_num = troop[src_property] >= 0 and troop[src_property] or 0

        troop[dst_property] = troop[dst_property] + self:FixPropertyNum(troop, skill, math.floor(src_num / skill.param3 * num))
    elseif skill.effect_type == PASSIVE_SKILL_EFFECT_TYPE["resist_lethal"] then
        troop.resist_lethal_num = skill.param1 or 0
    end
end

do
    skill_manager:Init()
end

return skill_manager
