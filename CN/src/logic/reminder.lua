--[[
    @file    reminder.lua
    @date    2015.12.16
    @author  xiaoting.huang 
--]]

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local graphic = require "logic.graphic"
local common_function_util = require "util.common_function"
local config_manager = require "logic.config_manager"
local configuration = require "util.configuration"
local time_logic = require "logic.time"

local troop_logic
local user_logic
local destiny_logic
local guild_logic

local reminder = {}

function reminder:Init()
    troop_logic = require "logic.troop"
    user_logic = require "logic.user"
    destiny_logic = require "logic.destiny_weapon"
    guild_logic = require "logic.guild"

    -- forge 
    self.reminder_list = {}
    self.reminder_list["forge_reminder"] = false

    self.show_forge_notify = true
    self.show_guild_war_notify = true
end

--强化检测
function reminder:NeedRemindToForge()

    -- 提醒关闭
    local remind_msg = false
    if configuration:GetRemindClosedSwitch("closed_remind_forge_switch") then
       return remind_msg
    end

    --强化未解锁
    if not user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["forge"], false) then
        return remind_msg
    end

    -- 按武器强化等级排序
    local current_formation = troop_logic:GetFormationMercenaryList()
    local clone_formation = common_function_util.Clone(current_formation)
    table.sort(clone_formation, function(a, b) 
            if a.weapon_lv == b.weapon_lv then 
                return a.instance_id < b.instance_id 
            else
                return a.weapon_lv < b.weapon_lv 
            end 
        end)
 
    for index = 1, #clone_formation do
        local mercenary = clone_formation[index]
        if mercenary and mercenary.is_leader then
            -- 判断主角武器
            local destiny_weapon_lv, destiny_weapon_num = destiny_logic:GetCurWeaponInfo()
            if not (destiny_weapon_lv >= constants["MAX_DESTINY_WEAPON_LV"]) then
               if (destiny_weapon_num > destiny_weapon_lv) and destiny_logic:CheckForgeResource() then 
                  remind_msg = true 
                  break
               end
            end
        elseif mercenary then
           local min_forge_level = mercenary.weapon_lv
           local artifact_level = mercenary.artifact_lv or 1
           if min_forge_level == constants["CAN_OPEN_ARTIFACT_WEAPON_LV"] and not mercenary.is_open_artifact then 

           else 
                if min_forge_level < constants["MAX_WEAPON_LV"] and troop_logic:CheckForgeWeaponResource(min_forge_level, false) then 
                    remind_msg = true
                    break
                elseif troop_logic:CheckArtifactReminder(mercenary) then
                    remind_msg = true
                    break
                end
           end
        end
    end
   
    return remind_msg
end

--检测是否需要强化
function reminder:CheckForgeReminder()
    local forge_flag = self:NeedRemindToForge()

    graphic:DispatchEvent("remind_forge", forge_flag)
end

--出战阵容有空位 并且 还有佣兵可以上阵 的提醒
function reminder:CheckFormationReminder()
    local num = troop_logic:GetExploringMercenaryNum()
    if num < troop_logic:GetFormationCapacity() and num < troop_logic:GetCurMercenaryNum() then
        graphic:DispatchEvent("remind_world_sub_scene", 6, true)
    else
        graphic:DispatchEvent("remind_world_sub_scene", 6, false)
    end
end

function reminder:IsShowForgeNotify()
    return self.show_forge_notify
end

function reminder:SetShowForgeNotify(show)
    self.show_forge_notify = show
end

function reminder:IsShowGuildWarNotify()
    local status = guild_logic:GetCurStatus()

    if guild_logic:IsEnterForCurrentWar() and status < client_constants.CLIENT_GUILDWAR_STATUS["MATCHING"] and guild_logic.own_member_info.war_field == 0 then
        --已经报名,但未上阵
        return time_logic:Now() >= configuration:GetVal("ignore_guild_war_notify_time")
    end

    return false
end

function reminder:SetShowGuildWarNotify(show)
    if not show then
        configuration:SetVal("ignore_guild_war_notify_time", time_logic:GetDurationToNextDay() + time_logic:Now())
    else
        configuration:SetVal("ignore_guild_war_notify_time", time_logic:Now())
    end

    configuration:Save()
end

return reminder
