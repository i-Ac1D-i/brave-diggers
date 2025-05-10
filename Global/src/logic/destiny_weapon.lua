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
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE[resource_name], num, false) then
            return false
        end
    end

    return true
end

--锻造
function destiny_weapon:ForgeWeapon()
    if self.weapon_lv >= constants["MAX_DESTINY_WEAPON_LV"] then
        return
    end

    --
    if self.weapon_lv >= self.weapon_num then
        graphic:DispatchEvent("show_prompt_panel", "destiny_lack_weapon", self.weapon_lv+1)
        return
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
            if troop_logic:MercenaryIsInFormation(leader, formation_id) then
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
            resource_logic:ShowLackResourcePrompt()
        end
    end)

    network:RegisterEvent("choose_destiny_weapon_ret", function(recv_msg)
        if recv_msg.result == "success" then
            troop_logic:SetFormationWeaponId(recv_msg.formation_id, recv_msg.weapon_id)
            graphic:DispatchEvent("update_leader_weapon", recv_msg.weapon_id, recv_msg.formation_id)
        end
    end)
end

return destiny_weapon
