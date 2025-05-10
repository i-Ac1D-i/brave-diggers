local config_manager = require "logic.config_manager"
local network = require "util.network"
local graphic = require "logic.graphic"

local client_constants = require "util.client_constants"
local constants = require "util.constants"

local time_logic
local user_logic
local rune_config

local escort = {}

-- 初始化
function escort:Init()
    user_logic = require "logic.user"
    time_logic = require "logic.time"

    self.has_query_target = false
    self.waiting_refresh_tramcar_ret = false

    self.escort_times = {}
    self.escort_info = {}
    self.tramcar_list = {}
    self.rob_target_list = {}

    self:RegisterMsgHandler()
end

--剩余运送次数
function escort:GetRemainEscortTimes()
    return self.escort_times.remain_escort
end

--购买运送次数的次数
function escort:GetBuyEscortTimes()
    return self.escort_times.buy_escort
end

--最多还可以购买的运送次数
function escort:GetCouldBuyEscortTimes()
    local could_buy_times = 0
    local cur_buy_escort_times = self.escort_times.buy_escort

    for times = cur_buy_escort_times + 1, #config_manager.tramcar_buy_escort_config do
        if times > constants["MAX_BUY_ESCORT_TIMES"] then
            break
        end

        could_buy_times = could_buy_times + 1
    end

    return could_buy_times
end

--购买times次运送次数的消耗
function escort:GetBuyEscortCost(times)
    times = times or 1
    
    local cur_buy_escort_times = self.escort_times.buy_escort
    if cur_buy_escort_times + times > constants["MAX_BUY_ESCORT_TIMES"] then
        return false
    end

    local cost = 0
    for i=1,times do
        local next_buy_escort_config = config_manager.tramcar_buy_escort_config[cur_buy_escort_times + i]
        if next_buy_escort_config then
            cost = cost + next_buy_escort_config.cost
        else
            return false
        end
    end

    return true, cost
end

--剩余拦截次数
function escort:GetRemainRobTimes()
    return self.escort_times.remain_rob
end

--购买拦截次数的次数
function escort:GetBuyRobTimes()
    return self.escort_times.buy_rob
end

--最多还可以购买的拦截次数
function escort:GetCouldBuyRobTimes()
    local could_buy_times = 0
    local cur_buy_rob_times = self.escort_times.buy_rob

    for times = cur_buy_rob_times + 1, #config_manager.tramcar_buy_rob_config do
        if times > constants["MAX_BUY_ROB_TIMES"] then
            break
        end

        could_buy_times = could_buy_times + 1
    end

    return could_buy_times
end

--购买times次拦截次数的消耗
function escort:GetBuyRobCost(times)
    times = times or 1
    
    local cur_buy_rob_times = self.escort_times.buy_rob
    if cur_buy_rob_times + times > constants["MAX_BUY_ROB_TIMES"] then
        return false
    end

    local cost = 0
    for i=1,times do
        local next_buy_rob_config = config_manager.tramcar_buy_rob_config[cur_buy_rob_times + i]
        if next_buy_rob_config then
            cost = cost + next_buy_rob_config.cost
        else
            return false
        end
    end

    return true, cost
end

--刷新矿车次数
function escort:GetRefreshTramcarTimes()
    return self.escort_times.refresh_tramcar
end

--是否需要自动刷新矿车
function escort:IsAutoRefreshTramcar()
    return self.escort_info.auto_refresh_tramcar == constants["ESCORT_AUTO_REFRESH_TRAMCAR"]["TRUE"]
end

--获取运送数据
function escort:GetEscortInfo()
    return self.escort_info
end

--获取矿车配置列表
function escort:GetTramcarList()
    return self.tramcar_list or {}
end

--获取可拦截目标列表
function escort:GetRobTargetList()
    return self.rob_target_list or {}
end

--获取可拦截目标列表
function escort:GetBeRobbedList()
    return self.escort_info.be_robbed_list or {}
end

--获取被拦截次数
function escort:GetBeRobbedTimes()
    return self.escort_info.be_robbed_list and #self.escort_info.be_robbed_list or 0
end

--获取被拦截列表
function escort:GetCurBeRobbedList(escort_beg_time, be_robbed_list)
    local cur_be_robbed_list = {}

    --只返回拦截时间在本次运送开始时间之后的（本次运送内拦截自己的记录）
    if escort_beg_time and be_robbed_list then
        for index,be_robbed_info in ipairs(be_robbed_list) do
            if be_robbed_info.be_robbed_time >= escort_beg_time then
                table.insert(cur_be_robbed_list, be_robbed_info)
            end
        end

        --根据拦截时间排序
        table.sort(cur_be_robbed_list,  function(a,b)
                                        return a.be_robbed_time < b.be_robbed_time
                                    end)
    end

    return cur_be_robbed_list
end

function escort:GetBeRobbedSuccessNum(be_robbed_list)
    local be_robbed_success_num = 0
    if be_robbed_list then
        for index,be_robbed_info in ipairs(be_robbed_list) do
            if be_robbed_info.result == constants["ROB_RESULT"]["SUCCESS"] then
                be_robbed_success_num = be_robbed_success_num + 1
            end
        end
    end
    return be_robbed_success_num
end

--根据被拦截列表和矿车ID获取矿车spine动画的名称
function escort:GetTramcarSpineName(tramcar_id, be_robbed_list)
    local be_robbed_success_num = self:GetBeRobbedSuccessNum(be_robbed_list)
    local spine_name = string.format("kuangche_lv%d_3", tramcar_id)
    if be_robbed_success_num >= 4 then
        spine_name = string.format("kuangche_lv%d_1", tramcar_id)
    elseif be_robbed_success_num >= 2 then
        spine_name = string.format("kuangche_lv%d_2", tramcar_id)
    end
    return spine_name
end

function escort:DailyClear()
    local escort_times = self.escort_times
    escort_times.remain_escort = constants["DEFAULT_ESCORT_TIMES"]
    escort_times.remain_rob = constants["DEFAULT_ROB_TIMES"]
    escort_times.refresh_tramcar = 0
    escort_times.buy_specify_tramcar = 0
    escort_times.buy_escort = 0
    escort_times.buy_rob = 0
end

--回包处理
function escort:RegisterMsgHandler()
    --查询玩家运送信息
    network:RegisterEvent("query_escort_info_ret", function(recv_msg)
        self.escort_info = recv_msg.escort_info or {}
    end)

    --查询玩家运送相关次数信息
    network:RegisterEvent("query_escort_times_ret", function(recv_msg)
        self.escort_times = recv_msg.escort_times
        graphic:DispatchEvent("update_escort_times")
    end)

    --查询矿车配置
    network:RegisterEvent("query_tramcar_list_ret", function(recv_msg)
        self.tramcar_list = recv_msg.tramcar_list
        for index,tramcar_conf in ipairs(self.tramcar_list) do
            if config_manager.tramcar_config[index] then
                tramcar_conf.name = config_manager.tramcar_config[index].name
            else
                tramcar_conf.name = ""
            end
        end
    end)

    --查询玩家可拦截目标列表
    network:RegisterEvent("query_rob_target_list_ret", function(recv_msg)
        self.has_query_target = true
        
        self.rob_target_list = recv_msg.rob_target_list
        graphic:DispatchEvent("show_world_sub_scene", "escort_sub_scene")
    end)

    --刷新可拦截目标
    network:RegisterEvent("escort_refresh_rob_target_list_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.escort_info.refresh_rob_target_time = recv_msg.refresh_rob_target_time
            self.rob_target_list = recv_msg.rob_target_list
            
            graphic:DispatchEvent("update_rob_target_list", true)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --刷新可拦截目标
    network:RegisterEvent("escort_update_rob_target_list_ret", function(recv_msg)
        for _,new_rob_target_info in ipairs(recv_msg.rob_target_list) do
            for _,rob_target_info in ipairs(self.rob_target_list) do
                if rob_target_info.pos == new_rob_target_info.pos then
                    for key,_ in pairs(rob_target_info) do
                        rob_target_info[key] = new_rob_target_info[key]
                    end
                    rob_target_info.is_update = true
                    break
                end
            end
        end
        
        graphic:DispatchEvent("update_rob_target_list", false)
    end)

    --购买拦截次数
    network:RegisterEvent("escort_buy_rob_times_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.escort_times.remain_rob = recv_msg.remain_rob
            self.escort_times.buy_rob = recv_msg.buy_rob
            
            graphic:DispatchEvent("refresh_remain_rob_times")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --购买运送次数
    network:RegisterEvent("escort_buy_escort_times_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.escort_times.remain_escort = recv_msg.remain_escort
            self.escort_times.buy_escort = recv_msg.buy_escort
            
            graphic:DispatchEvent("refresh_remain_escort_times")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --刷新矿车
    network:RegisterEvent("escort_refresh_tramcar_ret", function(recv_msg)
        self.waiting_refresh_tramcar_ret = false
        if recv_msg.result == "success" then
            if recv_msg.refresh_type == "random" then
                self.escort_times.refresh_tramcar = self.escort_times.refresh_tramcar + 1
            end
            self.escort_info.auto_refresh_tramcar = constants["ESCORT_AUTO_REFRESH_TRAMCAR"]["FALSE"]
            self.escort_info.tramcar_id = recv_msg.tramcar_id

            graphic:DispatchEvent("refresh_select_tramcar", recv_msg.refresh_type)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --开始运送
    network:RegisterEvent("escort_start_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.escort_times.remain_escort = self.escort_times.remain_escort - 1
            self.escort_info = recv_msg.escort_info

            graphic:DispatchEvent("refresh_remain_escort_times")
            graphic:DispatchEvent("start_escort", recv_msg.refresh_type)
        elseif recv_msg.result == "need_refresh_tramcar" then
            self:RefreshTramcar("auto")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --拦截
    network:RegisterEvent("escort_rob_target_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local target_user_id = recv_msg.target_user_id
            for index,rob_target_info in ipairs(self.rob_target_list or {}) do
                if rob_target_info.user_id == target_user_id then
                    graphic:DispatchEvent("show_world_sub_panel", "escort_start_rob_panel", rob_target_info, recv_msg.target_info, recv_msg.battle_property, recv_msg.battle_record, recv_msg.is_winner)
                end
            end

            self.escort_times.remain_rob = self.escort_times.remain_rob - 1
            graphic:DispatchEvent("refresh_remain_rob_times")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --被拦截次数的变化
    network:RegisterEvent("escort_update_be_robbed_list_ret", function(recv_msg)
        if user_logic.user_id == recv_msg.rob_target_user_id then
            self.escort_info.be_robbed_list = recv_msg.be_robbed_list

            graphic:DispatchEvent("update_be_robbed_list")
        else
            for _,rob_target_info in ipairs(self.rob_target_list) do
                if rob_target_info.user_id == recv_msg.rob_target_user_id then
                    rob_target_info.be_robbed_list = recv_msg.be_robbed_list
                    break
                end
            end
            
            graphic:DispatchEvent("update_rob_target_list", false)
        end
    end)

    --运送完成
    network:RegisterEvent("escort_finish_ret", function(recv_msg)
        self.escort_info = recv_msg.escort_info
        
        graphic:DispatchEvent("finish_escort")
    end)

    --领取奖励
    network:RegisterEvent("escort_receive_reward_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.escort_info = recv_msg.escort_info
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("receive_reward_success")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

end

--查询可拦截目标
function escort:QueryRobTargetList()
    if self.has_query_target then 
        graphic:DispatchEvent("show_world_sub_scene", "escort_sub_scene")
    else
        network:Send({ query_rob_target_list = {} })
    end
end

--开始运送
function escort:StartEscort()
    if self:IsAutoRefreshTramcar() then
        self:RefreshTramcar("auto")
    else
        network:Send({ escort_start = {} })
    end
end

--刷新可拦截目标
function escort:RefreshRobTarget(refresh_type)
    if refresh_type == "immediately" then
        --检测资源是否充足
        if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], constants["ESCORT_REFRESH_ROB_TARGET_LIST_IMMEDIATELY_COST"], true) then
            return
        end
    end
    network:Send({ escort_refresh_rob_target_list = {refresh_type = refresh_type} })
end

--购买拦截次数
function escort:BuyRobTimes(times)
    local could_buy, cost = self:GetBuyRobCost(times)
    if not could_buy then
        graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_rob_times")
        return
    end
    --检测资源是否充足
    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], cost, true) then
        return
    end
    network:Send({ escort_buy_rob_times = { times = times } })
end

--购买运送次数
function escort:BuyEscortTimes(times)
    local could_buy, cost = self:GetBuyEscortCost(times)
    if not could_buy then
        graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_escort_times")
        return
    end
    --检测资源是否充足
    if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], cost, true) then
        return
    end
    network:Send({ escort_buy_escort_times = { times = times } })
end

--刷新矿车
function escort:RefreshTramcar(refresh_type)
    --检测资源是否充足
    if refresh_type == "random" then
        if self.escort_times.refresh_tramcar >= constants["FREE_REFRESH_TRAMCAR_TIMES"] then
            if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], constants["ESCORT_REFRESH_TRAMCAR_RANDOM_COST"], true) then
                return
            end
        end
    elseif refresh_type == "specify" then
        if not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], constants["ESCORT_REFRESH_TRAMCAR_SPECIFY_COST"], true) then
            return
        end
    end

    if not self.waiting_refresh_tramcar_ret then
        self.waiting_refresh_tramcar_ret = true
        network:Send({ escort_refresh_tramcar = {refresh_type = refresh_type} })
    end
end

--拦截目标
function escort:RobTarget(target_user_id)
    network:Send({ escort_rob_target = {target_user_id = target_user_id}})
end

--领取奖励
function escort:ReceiveEscortReward()
    network:Send({ escort_receive_reward = {}})
end

return escort
