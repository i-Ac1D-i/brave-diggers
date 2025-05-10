local network = require "util.network"
local reward_logic
local resource_logic
local user_logic
local time_logic
local carnival_logic

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"
local ChALLENGE_MAX_CD = 5

local ladder = {}
function ladder:Init()

    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    user_logic = require "logic.user"
    time_logic = require "logic.time"
    carnival_logic = require "logic.carnival"

    self.cur_rank = 0
    self.rival_list = {}
    self.top_ten_rival_list = {}

    self:RegisterMsgHandler()
end

--请求排名赛对手
function ladder:Query()
    network:Send({query_ladder_info = {}})
end

function ladder:SetCurrentRank(rank)
    self.cur_rank = rank or 0
end

--挑战
function ladder:ChallengeRival(pos)
    local t_now = time_logic:Now()
    --cd
    if self.challenge_cd > t_now then
        graphic:DispatchEvent("show_prompt_panel", "ladder_chanllenge_time_limit")
        return
    end

    --挑战次数是否够
    if self.challenge_num <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "ladder_not_enough_count")
        return
    end

    if self.rival_list[pos].rank then
        network:Send( {challenge_ladder = { rank = self.rival_list[pos].rank }} )
    else
        graphic:DispatchEvent("show_prompt_panel", "ladder_rival_out_of_date")
    end
end

function ladder:GetCurRank()
    return self.cur_rank
end

function ladder:GetRivalList()
    return self.rival_list
end

function ladder:GetSingleRivalInfo(pos)
    return self.rival_list[pos]
end


function ladder:TopTenQuery()
    network:Send({ladder_top_ten = {}})
end

--排名前十的玩家
function ladder:GetTopTenPlayerInfo(pos)
    return self.top_ten_rival_list[pos]
end

--正在挑战的对手
function ladder:GetChallengingRivalInfo()
    return self.challenging_rival_info
end

function ladder:GetCurrentRank()
    return self.cur_rank
end

function ladder:RegisterMsgHandler()
    network:RegisterEvent("query_ladder_info_ret", function(recv_msg)
        print("query_ladder_info_ret")
        if recv_msg.rival then
            for i, rival in pairs(recv_msg.rival) do
                rival.template_id = rival.template_id_list[1]
                self.rival_list[i] = rival
            end

            self.challenge_num = recv_msg.challenge_num
            self.challenge_cd = recv_msg.challenge_cd
            self.cur_rank = recv_msg.cur_rank

            graphic:DispatchEvent("show_world_sub_scene", "ladder_sub_scene")

        else
            print("not receive server data")
        end
    end)

    network:RegisterEvent("challenge_ladder_ret", function(recv_msg)

        if recv_msg.result == "success" then
            if not recv_msg.battle_record or #recv_msg.battle_record == 0 then
                return
            end

            self.is_winner = recv_msg.is_winner
            self.challenging_rival_info = recv_msg.rival_info
            self.challenge_num = recv_msg.challenge_num
            self.challenge_cd = recv_msg.challenge_cd

            graphic:DispatchEvent("show_battle_room", client_constants.BATTLE_TYPE["vs_ladder_player"], 1, recv_msg.battle_property, recv_msg.battle_record, self.is_winner, function()
                graphic:DispatchEvent("ladder_update_rival", recv_msg.is_winner)
            end)

        elseif recv_msg.result == "give_reward" then
            graphic:DispatchEvent("show_prompt_panel", "ladder_is_giving_reward")
        end
    end)

    network:RegisterEvent("update_ladder_rival_ret", function(recv_msg)
        for i, rival in pairs(recv_msg.rival) do
            rival.template_id = rival.template_id_list[1]
            self.rival_list[i] = rival
        end

        self.cur_rank = recv_msg.cur_rank

        if recv_msg.result == "out_of_date" then
            --对手信息已经过期，需要刷新界面
            graphic:DispatchEvent("show_prompt_panel", "ladder_rival_out_of_date")
            graphic:DispatchEvent("ladder_update_rival")
        end
    end)

    network:RegisterEvent("ladder_top_ten_ret", function(recv_msg)
        print("ladder_top_ten_ret")
        for i, rival in pairs(recv_msg.rival) do
            rival.template_id = rival.template_id_list[1]
            self.top_ten_rival_list[i] = rival
        end

        --获取ladder基本信息之后，显示ladder 场景
        graphic:DispatchEvent("show_world_sub_panel", "ladder_top_ten_msgbox")
    end)
end


return ladder
