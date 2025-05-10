local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local achievement_const = require "util.achievement_const"

local ACHIEVEMENT_TYPE = constants.ACHIEVEMENT_TYPE

local user_logic
local bag_logic
local adventure_logic

local achievement = {}

function achievement:Init()
    user_logic = require "logic.user"
    bag_logic = require "logic.bag"
    adventure_logic = require "logic.adventure"

    self.step_list = {}

    self.statistic_list = {}

    for k, v in pairs(ACHIEVEMENT_TYPE) do
        self.statistic_list[v] = 0
    end

    --未完成的任务队列
    self.uncomplete_list = {}

    -- 任务可完成队列
    self.can_complete_list = {}

    self:RegisterMsgHandler()
end

function achievement:GetUnCompleteList()
    return self.uncomplete_list
end

--获取可以完成的任务列表
function achievement:GetCompleteList()
    return self.can_complete_list
end

function achievement:GetCurStep(type)
    return self.step_list[type]
end

function achievement:GetStatisticValue(achievement_type)
    return self.statistic_list[achievement_type]
end

function achievement:CheckAchievementStatus(achievement_type)
    -- 更新完成任务队列
    local can_complete = false
    local cur_step = self.step_list[achievement_type]

    if not cur_step then
        return
    end

    if not config_manager.achievement_config[achievement_type] then
        return
    end

    local next_step_config = config_manager.achievement_config[achievement_type][cur_step + 1]

    if next_step_config then
        local need_value = next_step_config["need_value"]
        if achievement_type == ACHIEVEMENT_TYPE["maze"] then
            can_complete = adventure_logic:IsMazeClear(need_value)
        else
            local cur_value = self.statistic_list[achievement_type]
            if cur_value >= need_value then
                can_complete = true
            end
        end
    end

    --可完成列表
    if platform_manager:GetChannelInfo().show_achievement_btn then
        for i = cur_step, 1, -1 do
            self:UnlockAchievement(tostring(achievement_type).."_"..tostring(i))
        end
    end

    local list_update = self:UpdateCompleteList(achievement_type, can_complete)
    -- 更新主界面任务提醒icon
    if list_update then
        graphic:DispatchEvent("remind_achievement")
    end
end

-- 更新任务完成队列 achievement_type 任务id, flag (任务完成 true，领取完任务奖励 false)
-- return true or false 队列是否有更新
function achievement:UpdateCompleteList(achievement_type, can_complete)
    -- 这个任务在已完成的任务队列里的idx
    local complete_idx, uncomplete_idx = 0, 0
    for i, _achievement_type in pairs(self.can_complete_list) do
        if _achievement_type == achievement_type then
            complete_idx = i
            break
        end
    end

    for i, _achievement_type in pairs(self.uncomplete_list) do
        if _achievement_type == achievement_type then
            uncomplete_idx = i
        end
    end

    -- 从完成队列删除
    if complete_idx > 0 and not can_complete then
        --更新任务的
        table.insert(self.uncomplete_list, achievement_type)
        table.remove(self.can_complete_list, complete_idx)
        return true
    end

    -- 添加到完成队列
    if complete_idx == 0 and can_complete then
        if uncomplete_idx ~= 0 then
            table.remove(self.uncomplete_list, uncomplete_idx)
        end

        table.insert(self.can_complete_list, achievement_type)
        return true
    end

    return false
end

--更新任务value
function achievement:UpdateStatisticValue(achievement_type, value)
    if achievement_type == constants.ACHIEVEMENT_TYPE["max_bp"] then
        if self.statistic_list[achievement_type] < value then
            self.statistic_list[achievement_type] = value
        end

    elseif achievement_type == constants.ACHIEVEMENT_TYPE["maze"] then

    else
        self.statistic_list[achievement_type] = self.statistic_list[achievement_type] + value
    end

    -- 是否达到目标阶段领取条件
    self:CheckAchievementStatus(achievement_type)
    graphic:DispatchEvent("update_achievement_progress", achievement_type)
end

function achievement:Complete(achievement_type)
    --检测背包
    local cur_step = self.step_list[achievement_type]
    local reward_type = tonumber(config_manager.achievement_config[cur_step + 1]["reward_type"])
    local sub_id = tonumber(config_manager.achievement_config[cur_step + 1]["param1"])
    local num = tonumber(config_manager.achievement_config[cur_step + 1]["param2"])

    if reward_type == constants.REWARD_TYPE["item"] then
        if num > bag_logic:GetSpaceCount() then
            graphic:DispatchEvent("show_prompt_panel", "bag_full")
            return
        end
    end

    --检测是否可以完成
    local can_complete = false
    for k, v in pairs(self.can_complete_list) do
        if v == achievement_type then
            can_complete = true
            break
        end
    end

    if not can_complete then
        graphic:DispatchEvent("show_prompt_panel","cant_take_reward_because_cant_meet_condition")
        return
    end

    network:Send({complete_achievement = {type = achievement_type}})
end

function achievement:ShowAchievement()
    if PlatformSDK.isAchievementLogin() then
        PlatformSDK.showAchievements()
    end
end

function achievement:UnlockAchievement(achieve_id)
    if not platform_manager:GetChannelInfo().show_achievement_btn then    
        return
    end

    if PlatformSDK.isAchievementLogin() then
        PlatformSDK.unlockAchievement(achievement_const["ACHIEVEMENT_KEY_"..platform_manager:GetChannelInfo().meta_channel][achieve_id])
    end
end

function achievement:RegisterMsgHandler()
    network:RegisterEvent("query_achievement_list_ret", function(recv_msg)
        print("query_achievement_list_ret")

        self.step_list = recv_msg.step_list or self.step_list
        self.statistic_list = recv_msg.statistic_list or self.statistic_list

        for achievement_type, info in pairs(self.step_list) do
            if config_manager.achievement_config[achievement_type] then
                table.insert(self.uncomplete_list, achievement_type)
            end
        end

        for achievement_type, info in pairs(self.step_list) do
            self:CheckAchievementStatus(achievement_type)
        end

    end)

    network:RegisterEvent("complete_achievement_ret", function(recv_msg)
        print("complete_achievement_ret", recv_msg.result)
        if recv_msg.result == "success" then

            local achievement_type = recv_msg.type

            self.step_list[achievement_type] = recv_msg.step

            self.statistic_list[achievement_type] = recv_msg.statistic_val

            self:CheckAchievementStatus(achievement_type)

            graphic:DispatchEvent("complete_achievement", achievement_type)
            graphic:DispatchEvent("show_prompt_panel","take_reward_success")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel","take_reward_failure")

        elseif recv_msg.result == "bag_full" then
            graphic:DispatchEvent("show_prompt_panel","bag_full")

        end
    end)

end

return achievement
