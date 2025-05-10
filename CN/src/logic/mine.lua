local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"

local user_logic
local time_logic
local resource_logic
local troop_logic

local mine = {}

function mine:Init()
    user_logic =  require "logic.user"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"
    troop_logic = require "logic.troop"

    self.remain_rob = 0                 --剩余掠夺次数
    self.remain_refresh_target = 0      --刷新掠夺目标次数
    self.refresh_reward = 0             --刷新奖励总额次数
    self.buy_rob = 0                    --购买掠夺次数
    self.buy_refresh_target = 0         --购买掠夺目标次数
    self.query_mine_report_time = 0     --请求战报间隔时间
    self.check_mine_report_time = 0     --请求战报绿点时间

    self.user_blood_tips_state = false  --是否使用血钻刷新提示

    self.mine_info_list = nil
    self.rob_target_list = nil
    self.all_mine_rewards = nil
    self.report_list = nil
    self.has_new_report = false

    self.mine_reward_list = {}
    self.mine_reward_list[1] = {}
    self.mine_reward_list[2] = {}
    self.mine_reward_list[3] = {}

    self:RegisterMsgHandler()
end

--零点重置
function mine:DailyClear()
    self.remain_rob = constants["DEFAULT_MINE_ROB_TIMES"]                            --剩余掠夺次数
    self.remain_refresh_target = constants["DEFAULT_MINE_REFRESH_TARGET_TIMES"]      --刷新掠夺目标次数
    self.refresh_reward = 0                                                          --刷新奖励总额次数
    self.buy_rob = 0                                                                 --购买掠夺次数
    self.buy_refresh_target = 0                                                      --购买掠夺目标次数
end

--得到配置文件
function mine:GetMineInfoConfig()
    if self.mine_info_config == nil then
        self.mine_info_config = config_manager.mine_info_config
    end
    return self.mine_info_config
end

--购买剩余的最大
function mine:GetBuyMaxTimes(buy_type)
    if buy_type == client_constants.TIMES_TYPE.rob_times then
        --矿山掠夺次数
        return #config_manager.mine_buy_rob_config - self.buy_rob
    elseif buy_type == client_constants.TIMES_TYPE.refresh_target_times then
        --矿山刷新次数
        return #config_manager.mine_buy_refresh_config - self.buy_refresh_target
    end
    return 0
end

--判断是否有奖励列表,然后请求奖励列表
function mine:GetMineAllRewardsList()
    if self.all_mine_rewards == nil then
        network:Send({ query_all_mine_rewards = {} })
    end
    return self.all_mine_rewards
end

--得到当前可以z总共获得的奖励
function mine:GetAllRewardsByIndexAndLevel(mine_index, mine_level)
    local reward_config = {}
    local reward_num = 0
    if self.all_mine_rewards then
        for k,v in pairs(self.all_mine_rewards) do
            if v.mine_index == mine_index and v.mine_level == mine_level then
                --取出每个奖励
                local part =  v.all_resource_list[#v.all_resource_list]
                if part then
                    
                    table.sort(part.part_resource_list, function (a, b)
                        return a.resource_id > b.resource_id
                    end)

                    for k3,reward in pairs(part.part_resource_list) do
                        if reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] == nil then
                            reward_num = reward_num + 1
                            reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward.resource_num
                        else
                            reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] + reward.resource_num
                        end
                    end
                end
                break
            end
        end
    end
    return reward_config, reward_num
end

--得到当前可以获得的奖励
function mine:GetCurrentRewardsByIndexAndLevel(mine_index, mine_level)
    local reward_config = {}
    local reward_num = 0
    if self.all_mine_rewards then
        for k,v in pairs(self.all_mine_rewards) do
            if v.mine_index == mine_index and v.mine_level == mine_level then
                --取出每个奖励
                local index = 0
                for k,mine_info in ipairs(self.mine_info_list) do
                    if mine_info.mine_index == mine_index and mine_info.status == client_constants.MINE_STATE.mining then
                        local all_delay_time = mine_info.end_time - mine_info.beg_time  --60
                        local now_delay_time = time_logic:Now() - mine_info.beg_time  --到现在的间隔时间

                        --是否在保护期内
                        local mine_conf = self:GetMineInfoConfig()
                        local guard_time = mine_conf[mine_level].guard_time * 60
                        if now_delay_time > guard_time then
                            --过了保护期
                            local part_time = mine_conf[mine_level].part_time * 60
                           index =  math.floor(now_delay_time/part_time)
                        end
                        
                        break
                    end
                end
                
                if index >= #v.all_resource_list then
                    index = #v.all_resource_list
                end

                if index > 0 then
                    local part = v.all_resource_list[index]
                    for k3,reward in pairs(part.part_resource_list) do
                        if reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] == nil then
                            reward_num = reward_num + 1
                            reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward.resource_num
                        else
                            reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] + reward.resource_num
                        end
                    end
                end
                break
            end
        end
    end
    return reward_config, reward_num
end

--得到当前开采中的队列
function mine:GetMinesCurrent()
    local num = 0
    for k,mine_info in pairs(self.mine_info_list) do
        if mine_info.status == client_constants.MINE_STATE.mining then
            if mine_info.end_time > time_logic:Now() then
                num = num + 1
            end
        end
    end
    return num
end

--判断当前矿山的状态
function mine:GetMinesStatus(mine_index)
    for k,mine_info in pairs(self.mine_info_list) do
        if mine_info.mine_index == mine_index then
            if mine_info.status == client_constants.MINE_STATE.mining then
                if mine_info.end_time > 0 and  mine_info.end_time <= time_logic:Now() then
                    return client_constants.MINE_STATE.finish
                end
            end
            return mine_info.status
        end
    end
    return client_constants.MINE_STATE.lock
end

--获得当前矿山的阵容战斗力是否足够开启
function mine:BattlePointIsFull(mine_index, mine_level, is_tips)
    local formation_id = constants["MINE_TROOP_ID"][mine_index]
    troop_logic:CalcTroopBP(formation_id)
    local bp = troop_logic:GetTroopBP(formation_id)
    local config = self:GetMineInfoConfig()
    local mine_config = config[mine_level]
    if mine_config.battle_point <= bp then
        return true
    elseif is_tips then
        graphic:DispatchEvent("show_prompt_panel", "battle_point_not_enough_tips")
    end
    return false
end

--是否提示使用血钻刷新
function mine:IsUseBloodTipState()
    return self.user_blood_tips_state
end

--设置使用血钻提示的状态
function mine:SetUseBloodTipState(state)
    self.user_blood_tips_state = state
end

--当前选择的矿山index
function mine:GetCurSelectMineIndex()
    return self.select_mine_index or 1
end

function mine:SetCurSelectMineIndex(mine_index)
    self.select_mine_index = mine_index
end

--得到要购买的消耗多少
function mine:GetNeedCostBloodWithType(times_type, buy_times)
    local cost_num = 0
    if times_type == client_constants.TIMES_TYPE.rob_times then
        --掠夺次数
        for i=1,buy_times do
            local cost_conf = config_manager.mine_buy_rob_config[self.buy_rob + i]
            if cost_conf then
                cost_num = cost_num + cost_conf.cost
            end
        end

    elseif times_type == client_constants.TIMES_TYPE.refresh_target_times then
        --刷新掠夺目标次数
        for i=1,buy_times do
            local cost_conf = config_manager.mine_buy_refresh_config[self.buy_refresh_target + i]
            if cost_conf then
                cost_num = cost_num + cost_conf.cost
            end
        end
    end
    return cost_num
end

--获得战报列表
function mine:GetReportRecord()
    local delay = time_logic:Now() - self.query_mine_report_time  
    if self.report_list == nil or delay > constants["MINE_REFRESH_REPORT_TIMES"] then 
        self:QueryMineReport()
        return nil
    end

    return self.report_list
end

--
function mine:CheckFormation(mine_index)
    -- body
    local formation_id = constants["MINE_TROOP_ID"][mine_index]
    local mercenary_list = troop_logic:GetFormationMercenaryList(formation_id)
    if #mercenary_list == 1 then
        for k,mercenary in pairs(mercenary_list) do
            if type(mercenary) == "table" and mercenary.is_leader then
                return false
            end
        end
    elseif #mercenary_list <= 0 then
        return false
    end
   
    return true
end

--------------------------------------网络请求
--刷新玩家
function mine:RefreshPalyer()
    network:Send({ refresh_mine_rob_target_list = {} })
end

--检查战报状态
function mine:CheckMineReport()
    local delay_time = time_logic:Now() - self.check_mine_report_time
    if delay_time >= constants["CHECK_MINE_REPORT_DELAY_TIME"] then 
        network:Send({ check_mine_report = {} })
    end
end


--刷新指定奖励列表
function mine:RefreshMineAllRewardList(mine_index, mine_level)
    network:Send({ refresh_mine_rewards = {mine_index = mine_index, mine_level = mine_level} })
end

--查询指定矿山当前可以获得的奖励
function mine:QueryMineNowRewardList(target_user_id, mine_index, mine_level)
    -- network:Send({ query_mine_cur_reward_list = {mine_index = mine_index, mine_level = mine_level} })
end

--查询战报
function mine:QueryMineReport()
   network:Send({ query_mine_report = {} }) 
end

--开始开采请求
function mine:StartMine(mine_index, mine_level)
    network:Send({ mine_start = {mine_index = mine_index, mine_level = mine_level} }) 
end

--收取矿山开采
function mine:MineReceiveReward(mine_index)
    network:Send({ mine_receive_reward = {mine_index = mine_index} })
end

--抢夺，偷取
--[[parma : rob_type   -->类型 :0; //掠夺  1; //偷窃  2  //复仇 
    target_user_id --》目标id
    mine_index  --> 矿山标
]]
function mine:MineRobTarget(rob_type, target_user_id, mine_index, report_id)
    network:Send({ mine_rob_target = {rob_type = rob_type, target_user_id = target_user_id, mine_index = mine_index, report_id = report_id} })
end

--购买矿山相关次数（刷新掠夺目标、掠夺）
--[[
    times_type   --> TIMES_TYPE
    times   --- >times 次数
]]
function mine:MineBuyTimes(times_type,times)
    network:Send({ mine_buy_times = {times_type = times_type, buy_times = times} })
end

--解锁矿山
function mine:MineUnlock(mine_index)
    network:Send({ mine_unlock = {mine_index = mine_index} })
end

--查询用户信息id
function mine:QueryMineOtherState(revenge_user_id, report_id)
    network:Send({ query_revenge_info = {revenge_user_id = revenge_user_id, report_id = report_id} })
end

--获取特殊奖励
function mine:MinReceiveAdditionalReward(additional_id)
    network:Send({ mine_receive_additional_reward = {additional_id = additional_id } })
end

--取消开采
function mine:MineCancel(mine_index)
    -- mine_cancel
    network:Send({ mine_cancel = {mine_index = mine_index } })
end

--注册监听事件
function mine:RegisterMsgHandler()

    --查询开采矿山信息
    network:RegisterEvent("query_mine_info_ret", function(recv_msg)
        self.mine_info_list = recv_msg.mine_info_list
    end)

    --当前次数查询
    network:RegisterEvent("query_mine_times_ret", function(recv_msg)
        if recv_msg.mine_times then
            self.remain_rob = recv_msg.mine_times.remain_rob                         --剩余掠夺次数
            self.remain_refresh_target = recv_msg.mine_times.remain_refresh_target   --刷新掠夺目标次数
            self.refresh_reward = recv_msg.mine_times.refresh_reward                 --刷新奖励总额次数
            self.buy_rob = recv_msg.mine_times.buy_rob                               --购买掠夺次数
            self.buy_refresh_target = recv_msg.mine_times.buy_refresh_target         --购买掠夺目标次数
        end
    end)
    
    --查询玩家信息
    network:RegisterEvent("query_mine_rob_target_list_ret", function(recv_msg)
        if recv_msg.rob_target_list then
            self.rob_target_list = recv_msg.rob_target_list
        end
    end)

    --刷新玩家信息
    network:RegisterEvent("refresh_mine_rob_target_list_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.rob_target_list = recv_msg.rob_target_list
            self.remain_refresh_target = self.remain_refresh_target - 1  --刷新次数减一
            graphic:DispatchEvent("mine_refresh_rob_target_list_success")
        else
            --其他错误
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --查询所有矿山奖励
    network:RegisterEvent("query_all_mine_rewards_ret", function (recv_msg)
        if recv_msg.all_mine_rewards then
            self.all_mine_rewards = recv_msg.all_mine_rewards
            --因为在打开矿山面板时请求的，所以打开矿山面板
            graphic:DispatchEvent("show_world_sub_scene", "mine_sub_scene")
        end
    end)

    --刷新指定矿山指定类型的奖励 刷新奖励列表
    network:RegisterEvent("refresh_mine_rewards_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            if recv_msg.mine_reward and self.all_mine_rewards then
                for k,rewards in pairs(self.all_mine_rewards) do
                    if rewards.mine_index == recv_msg.mine_reward.mine_index and rewards.mine_level == recv_msg.mine_reward.mine_level then
                        rewards.all_resource_list = recv_msg.mine_reward.all_resource_list
                        self.refresh_reward = self.refresh_reward + 1
                        graphic:DispatchEvent("mine_refresh_rewards_success")
                        break
                    end
                end
            end
        else
            --其他错误
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

    end)

    --查询战报状态
    network:RegisterEvent("check_mine_report_ret", function(recv_msg)
        self.check_mine_report_time = time_logic:Now()
        self.has_new_report = recv_msg.has_new_report
        graphic:DispatchEvent("check_mine_report_success")
    end)
    
    --开始采集
    network:RegisterEvent("mine_start_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            if self.mine_info_list then
                for k,mine_info in pairs(self.mine_info_list) do
                    if mine_info.mine_index == recv_msg.mine_info.mine_index then
                        self.mine_info_list[k] = recv_msg.mine_info
                        graphic:DispatchEvent("mine_start_success", mine_info.mine_index)
                        break
                    end
                end
            end
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

    end)

    --收取奖励
    network:RegisterEvent("mine_receive_reward_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            if self.mine_info_list then
                for k,mine_info in pairs(self.mine_info_list) do
                    if mine_info.mine_index == recv_msg.mine_index then
                        mine_info.status = client_constants.MINE_STATE.ready
                        mine_info.beg_time = 0
                        mine_info.mine_level = 0
                        mine_info.end_time = 0
                        break
                    end
                end
            end

            graphic:DispatchEvent("mine_receive_reward_success", recv_msg.resource_list, recv_msg.be_robbed_list, recv_msg.mine_index)
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

    end)

    --掠夺返回
    network:RegisterEvent("mine_rob_target_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            local user_id = recv_msg.target_user_id  --被掠夺的id
            self.remain_rob = self.remain_rob - 1
            local is_winner = recv_msg.is_winner
            if recv_msg.rob_type == client_constants.ROB_TYPE.rob or recv_msg.rob_type == client_constants.ROB_TYPE.revenge then
                --掠夺成功，或者复仇成功有战斗记录

                local battle_property =recv_msg.battle_property
                local battle_record = recv_msg.battle_record

                local battle_type = client_constants.BATTLE_TYPE["vs_mine_rob_target"]
                graphic:DispatchEvent("show_battle_room", battle_type, recv_msg.target_info, battle_property, battle_record, is_winner, function()
                    --战斗播放完毕 自动弹出奖励`
                    if is_winner then
                        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                    end
                 end)

                --复仇有战报状态设置
                if recv_msg.rob_type == client_constants.ROB_TYPE.revenge and recv_msg.report_id and self.report_list then
                    for k,rep in pairs(self.report_list) do
                        if rep.id == recv_msg.report_id then
                            self.report_list[k].status = 1
                            break
                        end
                    end
                    --刷新战报绿点时间
                    self.check_mine_report_time = 0
                    
                    graphic:DispatchEvent("report_state_success")
                end

            elseif recv_msg.rob_type == client_constants.ROB_TYPE.steal then
                --偷窃成功
                if is_winner then
                    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                else
                    graphic:DispatchEvent("show_prompt_panel", "mine_steal_failure_tips")
                end
            end
            --刷新掠夺目标的次数信息
            if self.rob_target_list then
                for k,rob_info in pairs(self.rob_target_list) do
                    if rob_info.user_id == recv_msg.target_user_id then
                        --被掠夺或者偷窃的次数加一
                        self.rob_target_list[k].be_robbed_times = self.rob_target_list[k].be_robbed_times + 1
                        break
                    end
                end
            end
            graphic:DispatchEvent("mine_rob_target_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

    end)

    --购买掠夺次数,刷新次数等返回
    network:RegisterEvent("mine_buy_times_ret", function(recv_msg)
        if  recv_msg.result == "success" then

            if recv_msg.times_type == client_constants.TIMES_TYPE.rob_times then
                --掠夺次数
                self.remain_rob = recv_msg.remain_times
                self.buy_rob = self.buy_rob + recv_msg.buy_times

            elseif recv_msg.times_type == client_constants.TIMES_TYPE.refresh_target_times then
                --刷新掠夺目标次数
                self.remain_refresh_target = recv_msg.remain_times
                self.buy_refresh_target = self.buy_refresh_target +  recv_msg.buy_times
            end
            graphic:DispatchEvent("mine_buy_times_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end

    end)

    --解锁矿山返回
    network:RegisterEvent("mine_unlock_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            for k,mine_info in pairs(self.mine_info_list) do
                if mine_info.mine_index == recv_msg.mine_index then
                    mine_info.status = client_constants.MINE_STATE.ready
                    mine_info.beg_time = 0
                    mine_info.mine_level = 0
                    mine_info.end_time = 0
                    graphic:DispatchEvent("mine_unlock_success", recv_msg.mine_index)
                    break
                end
            end
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --查询战报返回
    network:RegisterEvent("query_mine_report_ret", function(recv_msg)
        if  recv_msg.report_list then
            self.report_list = recv_msg.report_list
            --战报排序
            table.sort(self.report_list, function (report1,report2)
                return report1.report_time > report2.report_time
            end)
            
            graphic:DispatchEvent("query_mine_report_success")
        else
            self.report_list = {}
        end
        
        self.query_mine_report_time = time_logic:Now()
        graphic:DispatchEvent("show_world_sub_scene", "mine_report_sub_scene")
    end)

    --查询复仇信息返回
    network:RegisterEvent("query_revenge_info_ret", function(recv_msg)
        self.query_mine_report_time = 0
        if  recv_msg.revenge_info_list then
            if #recv_msg.revenge_info_list > 0 then
                graphic:DispatchEvent("have_revenge_info", recv_msg.revenge_info_list, recv_msg.report_id)
            else
                graphic:DispatchEvent("show_prompt_panel", "mine_no_revenge_tips")
            end
        else
            graphic:DispatchEvent("show_prompt_panel", "mine_no_revenge_tips")
        end
    end)
    
    --获取特殊奖励
    network:RegisterEvent("mine_receive_additional_reward_ret", function(recv_msg)
        if  recv_msg.result == "success" then
            --复仇有战报状态设置
            if recv_msg.additional_id and self.report_list then
                for k,rep in pairs(self.report_list) do
                    if rep.id == recv_msg.additional_id then
                        self.report_list[k].status = 1
                        break
                    end
                end
                graphic:DispatchEvent("report_state_success")
            end
            --刷新战报绿点时间
            self.check_mine_report_time = 0

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --奖励刷新
    network:RegisterEvent("update_mine_rewards_ret", function (recv_msg)
        if recv_msg.mine_reward and self.all_mine_rewards then
            for k,rewards in pairs(self.all_mine_rewards) do
                if rewards.mine_index == recv_msg.mine_reward.mine_index and rewards.mine_level == recv_msg.mine_reward.mine_level then
                    rewards.all_resource_list = recv_msg.mine_reward.all_resource_list
                    graphic:DispatchEvent("mine_refresh_rewards_success")
                    break
                end
            end
        end
    end)

    --取消开采返回
    network:RegisterEvent("mine_cancel_ret", function (recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.mine_index then
                if self.mine_info_list then
                    for k,mine_info in pairs(self.mine_info_list) do
                        if mine_info.mine_index == recv_msg.mine_index then
                            mine_info.status = client_constants.MINE_STATE.ready
                            mine_info.beg_time = 0
                            mine_info.mine_level = 0
                            mine_info.end_time = 0
                            break
                        end
                    end
                end
                graphic:DispatchEvent("mine_cancel_success", recv_msg.mine_index)
            end
        end
    end)
    
end

return mine
