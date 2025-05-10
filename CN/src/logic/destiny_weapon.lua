local network = require "util.network"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local user_logic
local reminder_logic  
local troop_logic
local resource_logic
local achievement_logic

local destiny_weapon = {}
local RESOURCE_TYPE = constants.RESOURCE_TYPE

function destiny_weapon:Init()

    user_logic = require "logic.user"
    troop_logic = require "logic.troop"
    resource_logic = require "logic.resource"
    achievement_logic = require "logic.achievement"
    reminder_logic =  require "logic.reminder"

    self.weapon_lv = 0
    self.weapon_num = 0

    self.weapon_ids = {}
    self.weapon_star_can_upgrade = false
    self.weapon_star_info_list = {}

    self:RegisterMsgHandler()
end

function destiny_weapon:GetWeaponLevel()
    return self.weapon_lv
end

function destiny_weapon:IsWeaponActived(weapon_id)
    for i, id in pairs(self.weapon_ids) do
        if id == weapon_id then
            return true, i
        end
    end

    return false
end

function destiny_weapon:GetWeaponIds()
    return self.weapon_ids
end

function destiny_weapon:GetWeaponNum()
    return self.weapon_num
end

function destiny_weapon:GetCurWeaponInfo()
    return self.weapon_lv, self.weapon_num
end

function destiny_weapon:GetWeaponStarConf(weapon_id, star_level)
    return config_manager.weapon_star_upgrade_config[weapon_id][star_level]
end

function destiny_weapon:GetWeaponTotalStarInfo()
    local total_star = 0
    local total_add_bp = 0
    for i,weapon_star_info in ipairs(self.weapon_star_info_list) do
        local cur_conf = self:GetWeaponStarConf(weapon_star_info.weapon_id, weapon_star_info.star_level)

        total_add_bp = total_add_bp + (cur_conf.add_bp or 0)
        total_star = total_star + weapon_star_info.star_level
    end

    local cur_weapon_total_star_conf = {}
    local next_weapon_total_star_conf = {}
    for _,weapon_total_star_conf in ipairs(config_manager.weapon_total_star_config) do
        if weapon_total_star_conf.star_num <= total_star then
            cur_weapon_total_star_conf = weapon_total_star_conf
        else
            next_weapon_total_star_conf = weapon_total_star_conf
            break
        end
    end

    return total_star, total_add_bp, cur_weapon_total_star_conf, next_weapon_total_star_conf
end

function destiny_weapon:GetWeaponStarInfo(weapon_id)
    return self.weapon_star_info_list[weapon_id]
end

function destiny_weapon:GetCurWeaponSkillId(weapon_id)
    local skill_id = config_manager.destiny_skill_config[weapon_id]["skill_id"]
    local weapon_star_info = self.weapon_star_info_list[weapon_id]
    local cur_conf = self:GetWeaponStarConf(weapon_star_info.weapon_id, weapon_star_info.star_level)
    skill_id = cur_conf.skill_id

    return skill_id
end

function destiny_weapon:CanUpgradeStar()
    return self:IsWeaponActived(constants["MAX_DESTINY_WEAPON_ID"])
end

function destiny_weapon:UpgradeStar(weapon_id, upgrade_type)
    if self.weapon_star_can_upgrade and not self.show_animation then
        self.show_animation = true
        network:Send({ weapon_star_upgrade = {weapon_id = weapon_id, upgrade_type = upgrade_type} })
    end
end

function destiny_weapon:UnlockDestinyWeaponStar()
    if self.weapon_num < constants["MAX_DESTINY_WEAPON_ID"] then
        graphic:DispatchEvent("show_prompt_panel", "not_enough_weapon_num")
    else
        network:Send({ unlock_destiny_weapon_star = {} })
    end
end

function destiny_weapon:GetFinalDestinyWeapon()
    network:Send({ get_final_destiny_weapon = {} })
end

function destiny_weapon:AddNewWeapon(new_weapon_id)
    table.insert(self.weapon_ids, new_weapon_id)

    self.weapon_num = self.weapon_num + 1
    -- 强化材料检测
    reminder_logic:CheckForgeReminder()
end

--锻造
local forge_resource_list = {
    "copper", 0, "tin", 0, "iron", 0, "silver", 0, "gold", 0,
    "diamond", 0, "titan_iron", 0, "ruby", 0, "purple_gem", 0, "emerald", 0, "topaz", 0
}

--检测强化所需资源
function destiny_weapon:CheckForgeResource()
    local forge_config = config_manager.destiny_forge_config[self.weapon_lv + 1]
    for i = 1, #forge_resource_list - 2, 2 do
        local resource_name = forge_resource_list[i]
        local num = forge_config[resource_name] or 0
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, false, true) then --
            return false
        end
    end

    return true
end

--锻造
function destiny_weapon:ForgeWeapon(costInfo)
    if self.weapon_lv >= constants["MAX_DESTINY_WEAPON_LV"] then
        return
    end

    if self.weapon_lv >= self.weapon_num then
        graphic:DispatchEvent("show_prompt_panel", "destiny_lack_weapon", self.weapon_lv+1)
        return
    end
    if #costInfo > 0 then
        for k,v in pairs(costInfo) do
            if not resource_logic:CheckResourceNum(v.resourceId, v.costNum, true) then
                return
            end
        end
    end
    network:Send({ forge_destiny_weapon = {} })
end

--装备
function destiny_weapon:Equip(formation_id, weapon_id)

    if troop_logic:GetFormationWeaponId(formation_id) == weapon_id then
        return
    end

    local flag = false
    for i, id in pairs(self.weapon_ids) do
        if id == weapon_id then
            flag = true
            break
        end
    end

    if not flag then
        return
    end

    network:Send({choose_destiny_weapon = { weapon_id = weapon_id, formation_id = formation_id}})
end

--检测是否有宿命武器，若没有则给出提示
function destiny_weapon:HasDestinyWeapon()
    if self.weapon_num ~= 0 then
        return true
    else
        return user_logic:IsFeatureUnlock(client_constants["FEATURE_TYPE"]["destiny_weapon"])
    end
end

function destiny_weapon:RegisterMsgHandler()
    network:RegisterEvent("query_destiny_weapon_ret", function(recv_msg)
        print("query_destiny_weapon_ret")
        self.weapon_lv = recv_msg.weapon_level

        if recv_msg.weapon_ids then
            self.weapon_num = #recv_msg.weapon_ids
            for i, id in ipairs(recv_msg.weapon_ids) do
                table.insert(self.weapon_ids, id)
            end
        end
    end)

    network:RegisterEvent("forge_destiny_weapon_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.weapon_lv = self.weapon_lv + 1
            local leader = troop_logic:GetLeader()
            troop_logic:CalcMercenaryBP(leader)

            local formation_id = troop_logic:GetCurFormationId() 
            if troop_logic:IsMercenaryInFormation(leader, formation_id) then
                troop_logic:CalcTroopBP(formation_id)
            end

            -- 强化材料检测
            reminder_logic:CheckForgeReminder()
            --统计宿命武器强化个数
            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["destiny"], 1)
            graphic:DispatchEvent("upgrade_leader_weapon_lv")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "destiny_lack_weapon", self.weapon_lv+1)

        elseif recv_msg.result == "not_enough_resource" then

        end
    end)

    network:RegisterEvent("choose_destiny_weapon_ret", function(recv_msg)
        if recv_msg.result == "success" then
            troop_logic:SetFormationWeaponId(recv_msg.formation_id, recv_msg.weapon_id)
            graphic:DispatchEvent("update_leader_weapon", recv_msg.weapon_id, recv_msg.formation_id)
        end
    end)

    network:RegisterEvent("query_weapon_star_info_ret", function(recv_msg)
        self.weapon_star_can_upgrade = recv_msg.weapon_star_can_upgrade
        self.weapon_star_info_list = recv_msg.weapon_star_info_list
    end)

    network:RegisterEvent("weapon_star_upgrade_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local weapon_star_info = self:GetWeaponStarInfo(recv_msg.weapon_id)
            recv_msg.upgrade_exp = recv_msg.exp - weapon_star_info.exp
            if recv_msg.is_upgrade then
                weapon_star_info.star_level = recv_msg.star_level + 1
                weapon_star_info.exp = 0
                troop_logic:CalcTroopBP(troop_logic:GetCurFormationId(), true)
            else
                weapon_star_info.star_level = recv_msg.star_level
                weapon_star_info.exp = recv_msg.exp
            end

            for _,formation_id in ipairs(constants["ALL_FORMATIONS"]) do
                if troop_logic:IsWeaponEquipped(formation_id, recv_msg.weapon_id) then
                    troop_logic:SetFormationPropertyChanged(formation_id)
                end
            end

            graphic:DispatchEvent("weapon_upgrade_star_success", recv_msg)
        else
            self.show_animation = false
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("get_final_destiny_weapon_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("get_final_destiny_weapon")
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("unlock_destiny_weapon_star_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.weapon_star_can_upgrade = true
            graphic:DispatchEvent("unlock_destiny_weapon_star")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

end

return destiny_weapon
