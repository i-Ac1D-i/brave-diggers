local network = require "util.network"
local user_logic
local time_logic
local resource_logic

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"

local PROMPT_MSG = {
    ["cd_limit"] = "server_pvp_chanllenge_time_limit",
    ["challenge_limit"] = "server_pvp_not_enough_count",
    ["times_limit"] = "has_buy_too_much_server_pvp_times",
    ["buy_limit"] = "server_pvp_times_could_not_buy",
    ["challenge_rank_limit"] = "server_pvp_challenge_rank_limit",
    ["not_in_challenge_time"] = "server_pvp_not_in_challenge_time",
    ["target_limit"] = "server_pvp_target_limit",
}

local server_pvp = {}
function server_pvp:Init()

    user_logic = require "logic.user"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"

    self.cur_season_end_time = 0
    self.next_season_beg_time = 0

    self.cur_rank = 0
    self.rank_list = {}
    self.world_rank_list = {}
    self.reward_list = {}

    self.challenge_times = 0
    self.challenge_cd_end_time = 0
    self.challenge_buy_times = 0

    self.query_pvp_season_time = 0
    self.query_world_rank_time = 0

    self:RegisterMsgHandler()
end

--请求跨服PVP赛程表
function server_pvp:QueryServerPvpSeason()
    if time_logic:Now() - self.query_pvp_season_time < 5 then
        return
    end
    
    self.query_pvp_season_time = time_logic:Now()
    network:Send({query_server_pvp_season = {}})
end

--请求跨服PVP信息
function server_pvp:QueryServerPvpInfo()
    network:Send({query_server_pvp_info = {}})
end

function server_pvp:UpdateServerPvpRank()
    network:Send({update_server_pvp_rank = {}})
end

--请求跨服PVP世界排行榜
function server_pvp:QueryServerPvpWorldRank()
    if time_logic:Now() - self.query_world_rank_time < 5 then
        graphic:DispatchEvent("show_world_sub_panel", "server_pvp_rank_panel")
    else
        self.query_world_rank_time = time_logic:Now()
        network:Send({query_server_pvp_world_rank = {}})
    end
end

--购买挑战次数
function server_pvp:BuyChallengeTimes(buy_times)
    --检测资源是否充足
    local could_buy, cost = self:GetBuyCost(buy_times)

    if not could_buy or not resource_logic:CheckResourceNum(constants["RESOURCE_TYPE"]["blood_diamond"], cost, true) then
        return
    end
    network:Send({ buy_server_pvp_times = {buy_times = buy_times} })
end

function server_pvp:DailyClear()
    self.challenge_buy_times = 0
    self.challenge_times = constants["PVP_MAX_NUM"]
    
    graphic:DispatchEvent("update_server_pvp_times")
end

--最多还可以购买的运送次数
function server_pvp:GetCouldBuyTimes()
    local could_buy_times = 0
    local cur_buy_challenge_times = self.challenge_buy_times

    for times = cur_buy_challenge_times + 1, #config_manager.pvp_buy_times_config do
        if times > constants["PVP_MAX_BUY_TIMES"] then
            break
        end

        could_buy_times = could_buy_times + 1
    end

    return could_buy_times
end

--购买times次运送次数的消耗
function server_pvp:GetBuyCost(times)
    times = times or 1
    
    local cur_buy_challenge_times = self.challenge_buy_times
    if cur_buy_challenge_times + times > constants["PVP_MAX_BUY_TIMES"] then
        return false
    end

    local cost = 0
    for i=1,times do
        local next_buy_config = config_manager.pvp_buy_times_config[cur_buy_challenge_times + i]
        if next_buy_config then
            cost = cost + next_buy_config.blood_diamond
        else
            return false
        end
    end

    return true, cost
end

function server_pvp:GetCurRank()
    return self.cur_rank
end

function server_pvp:GetRankList()
    return self.rank_list
end

--挑战
function server_pvp:ChallengeRival(rank)
    local t_now = time_logic:Now()
    --cd
    if self.challenge_cd_end_time > t_now then
        graphic:DispatchEvent("show_prompt_panel", "server_pvp_chanllenge_time_limit")
        return
    end

    --挑战次数是否够
    if self.challenge_times <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "server_pvp_not_enough_count")
        return
    end

    network:Send( {challenge_server_pvp = { challenge_rank = rank }} )
end

function server_pvp:RegisterMsgHandler()
    network:RegisterEvent("query_server_pvp_season_ret", function(recv_msg)
        print("query_server_pvp_season_ret")

        self.cur_season_end_time = recv_msg.cur_season_end_time
        self.next_season_beg_time = recv_msg.next_season_beg_time
        self.reward_list = recv_msg.reward_list or {}
        self.top_reward_list = recv_msg.top_reward_list or {}
        self.daily_reward_list = recv_msg.daily_reward_list or {}
        
        table.sort(self.reward_list, function(a,b) return a.id < b.id end)
    end)

    network:RegisterEvent("query_server_pvp_info_ret", function(recv_msg)
        print("query_server_pvp_info_ret")
        self.cur_rank = recv_msg.cur_rank
        self.challenge_times = recv_msg.challenge_times
        self.challenge_cd_end_time = recv_msg.challenge_cd_end_time
        self.challenge_buy_times = recv_msg.challenge_buy_times
        self.rank_list = recv_msg.rank_list or {}

        table.sort(self.rank_list, function(a,b) return a.rank > b.rank end)

        graphic:DispatchEvent("show_world_sub_scene", "server_pvp_sub_scene")
    end)

    network:RegisterEvent("query_server_pvp_world_rank_ret", function(recv_msg)
        print("query_server_pvp_world_rank_ret")
        self.world_rank_list = recv_msg.rank_list or {}
        table.sort(self.world_rank_list, function(a,b) return a.rank < b.rank end)

        graphic:DispatchEvent("show_world_sub_panel", "server_pvp_rank_panel")
    end)

    network:RegisterEvent("update_server_pvp_rank_ret", function(recv_msg)
        print("update_server_pvp_rank_ret")
        self.cur_rank = recv_msg.cur_rank
        self.rank_list = recv_msg.rank_list or {}
        table.sort(self.rank_list, function(a,b) return a.rank > b.rank end)

        graphic:DispatchEvent("update_server_pvp_rank")
    end)

    network:RegisterEvent("buy_server_pvp_times_ret", function(recv_msg)
        print("buy_server_pvp_times_ret")
        if recv_msg.result == "success" then
            self.challenge_times = recv_msg.challenge_times
            self.challenge_buy_times = recv_msg.challenge_buy_times
            graphic:DispatchEvent("update_server_pvp_times")
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])
        elseif PROMPT_MSG[recv_msg.result] then
            graphic:DispatchEvent("show_prompt_panel", PROMPT_MSG[recv_msg.result])
        end
    end)

    network:RegisterEvent("challenge_server_pvp_ret", function(recv_msg)
        print("challenge_server_pvp_ret")
        if recv_msg.result == "success" then
            self.challenge_times = recv_msg.challenge_times
            self.challenge_cd_end_time = recv_msg.challenge_cd_end_time

            graphic:DispatchEvent("update_server_pvp_times")
            
            local battle_type = client_constants.BATTLE_TYPE["vs_server_pvp"]
            graphic:DispatchEvent("show_battle_room", battle_type, recv_msg.challenge_user_info, recv_msg.battle_property, recv_msg.battle_record, recv_msg.is_winner, function() end)
        elseif PROMPT_MSG[recv_msg.result] then
            if recv_msg.result == "target_limit" then
                self:UpdateServerPvpRank()
            end
            graphic:DispatchEvent("show_prompt_panel", PROMPT_MSG[recv_msg.result])
        end
    end)
end

return server_pvp