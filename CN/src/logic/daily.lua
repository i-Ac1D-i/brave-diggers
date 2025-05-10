local network = require "util.network"
local time_logic = require "logic.time"
local graphic = require "logic.graphic"
local json = require "util.json"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local bit_extension = require "util.bit_extension"

local REWARD_SOURCE = constants.REWARD_SOURCE
local DAILY_TYPE = client_constants["DAILY_TYPE"]
local config_manager = require "logic.config_manager"

local activity_config = config_manager.activity_config
local liveness_value_reward_config = config_manager.liveness_value_reward_config

local reward_logic
local resource_logic
local bag_logic

local daily = {}
function daily:Init()
    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    bag_logic = require "logic.bag"

    self.daily_list = {}
    self.weekly_list = {}
    self.alchemy_list = {}
    self.prayer_list = {}
    self.accu_list = {}
    self.next_reward = {}
    self.daily_data = {}
    self.check_in_count = 0
    self.check_in_mark = 0
    self.check_in_count_next = 0

    self.already_request_daily = false
    self.already_request_weekly = false

    self.gold_recruit_cost = 0
    self.liveness_list = nil

    self:RegisterMsgHandler()
end

function daily:GetDailyList()
    return self.daily_list
end

function daily:GetWeeklyList()
    return self.weekly_list
end

function daily:GetAccumulateList()
    return self.accu_list
end

function daily:RequestDaily()
    if not self.already_request_daily then
        network:Send({ query_daily = {} })
    else
        graphic:DispatchEvent("show_world_sub_panel", "daily_panel")
    end
end

function daily:DailyClear()
    self.already_request_weekly = false
    self.already_request_daily = false
    self.liveness_list = nil
end

function daily:RequestWeekly()
    if not self.already_request_weekly then
        network:Send({ query_check_in_weekly_list = {} })
    else
        graphic:DispatchEvent("show_world_sub_panel", "check_in_weekly_panel")
    end
end

--签到 领取奖励
function daily:TakeCheckIn()

    -- 背包空间至少多于 2 个
    if bag_logic:GetSpaceCount() <= 1 then
        graphic:DispatchEvent("show_prompt_panel", "adventure_open_box_not_enough_space")
        return
    end

    if self:AlreadyCheckin() then
        graphic:DispatchEvent("show_prompt_panel", "checkin_is_complated")
        return
    end

    --背包空间至少多于 2 个
    if bag_logic:GetSpaceCount() <= 1 then
        graphic:DispatchEvent("show_prompt_panel", "adventure_open_box_not_enough_space")
        return
    end

    network:Send({ take_check_in_reward = {} })
end

--祈祷 领取奖励
function daily:TakePrayer(index)
    if self.prayer_info.mark ~= 0 then
        graphic:DispatchEvent("show_prompt_panel", "daily_prayer_unused")
        return
    end

    --检查血钻
    local cost_blood_diamand = constants["PRAYER_CONFIG"][index].req_value
    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], cost_blood_diamand, true) then
        return 
    end

    network:Send({ take_daily_prayer = { index = index } })
end

--炼金 领取奖励
function daily:TakeAlchemy(index)

    if self.alchemy_info.mark ~= 0 then
        graphic:DispatchEvent("show_prompt_panel", "daily_alchemy_unused")
        return
    end

    --检查血钻
    local cost_blood_diamand = constants["ALCHEMY_CONFIG"][index].req_value
    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], cost_blood_diamand, true) then
        return
    end

    network:Send({ take_daily_alchemy = { index = index } })
end

function daily:GetCheckInMark(mark)
    local flag = bit_extension:GetBitNum(self.check_in_mark, mark)
    return flag == 1
end

--是否已经签到过
function daily:AlreadyCheckin()
    local time_info = time_logic:GetDateInfo(time_logic:Now())
    local mark = 0

    if time_info.hour < constants["CHECKIN_TIME"]["first"] then
        mark = 0
    elseif time_info.hour < constants["CHECKIN_TIME"]["second"] then
        mark = 1
    else
        mark = 2
    end

    return self:GetCheckInMark(mark)
end

function daily:AlreadyAlchemy()
    return self.alchemy_info.mark ~= 0
end

function daily:AlreadyPrayer()
    return self.prayer_info.mark ~= 0
end

-- 是否需要显示tip
function daily:NeedShowTip()
    local visible = true
    if self:AlreadyAlchemy() and self:AlreadyCheckin() and self:AlreadyPrayer() and not self:CheckGreenShow() then
        visible = false
    end

    return visible
end

--某天的奖励领取次数
function daily:GetTheDayCheckInCount()
    local num = 0
    for i = 1, 3 do
        local is_take = self:GetCheckInMark(i - 1)
        if is_take then
            num = num + 1
        end
    end

    return num
end

function daily:GetDurationToNextCheckin()
    local first_time = constants["CHECKIN_TIME"]["first"]
    local second_time = constants["CHECKIN_TIME"]["second"]
    local third_time = constants["CHECKIN_TIME"]["third"]

    local time_now = time_logic:Now()
    local time_info = time_logic:GetDateInfo(time_now)

    if time_info.hour < first_time then
        time_info.hour = first_time
    elseif time_info.hour < second_time then
        time_info.hour = second_time
    elseif time_info.hour < third_time then
        return time_logic:GetDurationToNextDay()
    end

    time_info.min = 0
    time_info.sec = 0

    return (os.time(time_info) - time_now)
end

function daily:GetRecruitCost()
    return self.gold_recruit_cost
end

function daily:SetRecruitCost(cost)
    self.gold_recruit_cost = cost
end

function daily:GetDailyTag(tag)
    local flag = bit_extension:GetBitNum(self.daily_num, tag)
    return flag == 1
end

function daily:SetDailyTag(tag, flag)
    self.daily_num = bit_extension:SetBitNum(self.daily_num, tag, flag)
end

-- 获取当前祈祷或炼金等级 获得的金币/经验和碎片
function daily:GetScore(tab_type, index, param)
    local alchemy_prayer_config = config_manager.alchemy_prayer_config
    local level = self:getLevel(tab_type)

    if not (param and level) then
        return 0, 0
    end

    local info = (tab_type == DAILY_TYPE.alchemy) and constants.ALCHEMY_CONFIG[index] or constants.PRAYER_CONFIG[index]
    local score = (param * info.value + info.fixed)
    local config = alchemy_prayer_config[level]
    local score_req = config["soul_chip_"..index] or 0

    return score, score_req
end

-- 获取祈祷/炼金 系数
function daily:GetDailyParam(tab_type)
    local param = (tab_type == DAILY_TYPE.alchemy) and self.alchemy_info.param or self.prayer_info.param
    return param
end

-- 获取当前祈祷或炼金等级
function daily:getLevel(tab_type)
    if tab_type == DAILY_TYPE.alchemy then
        return self.alchemy_info.level
    elseif tab_type == DAILY_TYPE.prayer then
        return self.prayer_info.level
    else
        return nil
    end
end

--------------------------------------------SYY --------------------------------

function daily:GetActivityList()
    if self.liveness_list == nil then
        network:Send({ query_liveness_info = {} })
    end
    return self.liveness_list or {}
end

function daily:GetCompleteNumber()
    return self.current_activity or 0
end

function daily:GetActivityReceiveList()
    return self.activity_receive_list or {}
end

function daily:GetActivityReward(liveness_id)
    network:Send({ get_liveness_reward = {liveness_id = liveness_id} })
end

function daily:CheckActivityComplet(liveness_id,completion_count)
    for k,v in pairs(activity_config) do
        if v.liveness_id == liveness_id then
            if completion_count >= v.condition_count then
                return true,v.active_value
            end
            break 
        end
    end
    return false,0
end

--检查活跃度是否开启
function daily:LivenessOpen(event_id)
    for k,v in pairs(activity_config) do
        if v.condition == event_id then
            network:Send({ query_liveness_info = {} })
            break 
        end
    end
end

function daily:CheckActivityRevied(current_activity)
    local check_key = {}
    for k,v in pairs(liveness_value_reward_config) do
        if v.activity_value > self.current_activity and  v.activity_value <= current_activity then
            table.insert(check_key,k)
        end
    end 
    return check_key
end

function daily:CheckGreenShow()

    local liveness_list = self:GetActivityList()
    if #liveness_list > 0 then
        for k,v in pairs(liveness_list) do
            local comp = self:CheckActivityComplet(v.liveness_id,v.completion_count)
            if comp and not v.is_reward then
                return true
            end
        end
    end
    if self.activity_receive_list then
        for k,v in pairs(self.activity_receive_list) do
            if v ~= nil  then
                return true
            end
        end
    end
    if self:GetCompleteNumber() == 0 then
        return true
    end
    return false
end


function daily:GetActivityAllReward(index)
    network:Send({ get_activity_reward = {index = index} })
end


--------------------------------------------------------------------------------

function daily:RegisterMsgHandler()

    network:RegisterEvent("query_daily_ret", function(recv_msg)
        --清空daily_list
        if #self.daily_list > 0 then
            for i = 1, #self.daily_list do
                self.daily_list[i] = nil
            end
        end
        
        self.daily_data = {}

        --默认是有顺序的
        for i, reward_info in ipairs(recv_msg.daily_list) do
            table.insert(self.daily_list, reward_info)
        end

        self.already_request_daily = true
        self.alchemy_info = recv_msg.alchemy_info
        self.prayer_info = recv_msg.prayer_info

        --签到状态
        self.check_in_mark = recv_msg.check_in_mark
        --签到总天数
        self.check_in_count = recv_msg.check_in_count or self.check_in_count
        --
        self.check_in_count_next = recv_msg.check_in_count_next or self.check_in_count_next
        if recv_msg.check_in_count_reward then
            self.next_reward = recv_msg.check_in_count_reward[1]

        else
            self.next_reward = nil
        end

        self.daily_num = recv_msg.daily_num
        self.daily_clear_time = recv_msg.daily_clear_time
        self.gold_recruit_cost = recv_msg.gold_recruit_cost
        if recv_msg.daily_data then
            for i, daily_info in ipairs(recv_msg.daily_data) do
                table.insert(self.daily_data, daily_info)
            end
        end
    end)

    network:RegisterEvent("take_daily_prayer_ret", function(recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end

        local old_param = self.prayer_info.param
        
        self.prayer_info = recv_msg.prayer_info
        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        graphic:DispatchEvent("take_daily_reward", DAILY_TYPE.prayer, old_param)
    end)

    network:RegisterEvent("take_daily_alchemy_ret", function(recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end

        local old_param = self.alchemy_info.param

        self.alchemy_info = recv_msg.alchemy_info
        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        graphic:DispatchEvent("take_daily_reward", DAILY_TYPE.alchemy, old_param)

    end)

    network:RegisterEvent("query_check_in_daily_list_ret", function(recv_msg)
        --清空daily_list
        if #self.daily_list > 0 then
            for i = 1, #self.daily_list do
                self.daily_list[i] = nil
            end
        end

        --默认是有顺序的
        for i, reward_info in ipairs(recv_msg.daily_list) do
            table.insert(self.daily_list, reward_info)
        end
        self.already_request_daily = true
        graphic:DispatchEvent("show_world_sub_panel", "check_in_daily_panel")
    end)

    network:RegisterEvent("query_check_in_weekly_list_ret", function(recv_msg)
        -- print("recv_msg = ", json:encode(recv_msg))

        if recv_msg.weekly_list then
            --清空weekly_list
            if #self.weekly_list > 0 then
                for i = 1, #self.weekly_list do
                    self.weekly_list[i] = nil
                end
            end
            for i, daily_info in ipairs(recv_msg.weekly_list) do
                table.insert(self.weekly_list, daily_info)
            end
        end

        if recv_msg.count_reward_list then
            --清空accu_list
            if #self.accu_list > 0 then
                for i = 1, #self.accu_list do
                    self.accu_list[i] = nil
                end
            end
            self.check_in_weekly_mark = recv_msg.count_reward_list[1].mark
            self.check_in_weekly_number = recv_msg.count_reward_list[1].number

            local list = recv_msg.count_reward_list
            for i, accu_info in ipairs(list) do
                accu_info.reward_type = list[i].rewards[1].reward_type
                accu_info.reward_id = list[i].rewards[1].param1
                accu_info.reward_num = list[i].rewards[1].param2
                accu_info.check_in_num = list[i].number
                accu_info.mark = list[i].mark
                table.insert(self.accu_list, accu_info)
            end
        end

        self.already_request_weekly = true

        if #self.weekly_list ~= 0 then
            graphic:DispatchEvent("show_world_sub_panel", "check_in_weekly_panel")
        end

    end)

    network:RegisterEvent("take_check_in_reward_ret", function(recv_msg)
        print("take_check_in_reward_ret = ", recv_msg.result)
        if recv_msg.result == "success" then

            self.check_in_mark = recv_msg.mark or 0
            self.check_in_count = recv_msg.check_in_count or self.check_in_count
            self.check_in_count_next = recv_msg.check_in_count_next or self.check_in_count_next

            if recv_msg.check_in_count_reward then
                self.next_reward = recv_msg.check_in_count_reward[1]
            end

            -- 播放奖励动画
            graphic:DispatchEvent("take_daily_reward", DAILY_TYPE.check_in)

        elseif recv_msg.result == "time_is_not" then
            graphic:DispatchEvent("show_prompt_panel", "checkin_time_is_not")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "checkin_is_complated")
        end
    end)

    --活跃度信息请求返回
    network:RegisterEvent("query_liveness_info_ret", function(recv_msg)
        -- print("query_liveness_info_ret")
        self.liveness_list = recv_msg.liveness_list or {}
        self.current_activity = recv_msg.current_activity or 0
        self.activity_receive_list = recv_msg.receive_list or {}
        graphic:DispatchEvent("activity_info_update")
    end)

    --活跃度更新
    network:RegisterEvent("update_liveness_ret", function(recv_msg)
        -- print("update_liveness÷_ret")
        if recv_msg.liveness_id and self.liveness_list then
            for k,v in pairs(self.liveness_list) do
                if v.liveness_id == recv_msg.liveness_id then
                    v.completion_count = recv_msg.completion_count
                    local complet,activity_value = self:CheckActivityComplet(v.liveness_id,v.completion_count)
                    if complet then
                        local current_activity = self.current_activity + activity_value
                        local insert_key = self:CheckActivityRevied(current_activity)
                        for k,v in pairs(insert_key) do
                            table.insert(self.activity_receive_list,v)
                        end
                        self.current_activity = self.current_activity + activity_value

                    end
                    break
                end
            end
            graphic:DispatchEvent("activity_info_update")
        end
    end)

    --活跃度完成领取奖励
    network:RegisterEvent("get_liveness_reward_ret", function(recv_msg)
        -- print("get_liveness_reward_ret"..recv_msg.result.."  recv_msg.liveness_id ="..recv_msg.liveness_id)
        if recv_msg.result == "success" then
            for k,v in pairs(self.liveness_list) do
                if v.liveness_id == recv_msg.liveness_id then
                    v.is_reward = true
                    break
                end
            end
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("activity_info_update")
        end
    end)

    --活跃度达到领取奖励
    network:RegisterEvent("get_activity_reward_ret", function(recv_msg)
        -- print("get_activity_reward_ret")
        if recv_msg.result == "success" then
            for k,v in pairs(self.activity_receive_list) do
                if v == recv_msg.index then
                    self.activity_receive_list[k]= nil
                    break
                end
            end
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("activity_info_update")
        end
    end)

end

return daily
