local network = require "util.network"
local time_logic = require "logic.time"

local bit = require "bit"

local reward_logic
local resource_logic
local achievement_logic
local bag_logic
local troop_logic

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local REWARD_SOURCE = constants.REWARD_SOURCE

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"

local PROMPT_MAP = {
    ["cant_meet_the_conditions"] = 200500,
    ["resource_num_is_not_enough"] = 100021,
    ["refresh_failure"] = 200300,
    ["not_enough_count"] = 200301,
    ["already_challenge_rival"] = 200302,
    ["rival_info_missing"] = 200303,
    ["reward_already_take"] = 200507,
}

local arena = {}
function arena:Init()
    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    achievement_logic = require "logic.achievement"
    bag_logic = require "logic.bag"
    troop_logic = require "logic.troop"

    self.refresh_time = 0
    self.is_first_query = false
    self.win_num = 0
    self.challenge_num = 0
    self.has_query_exchange_config = false

    self.rival_list = {}
    self:RegisterMsgHandler()
end

function arena:AddChallengeNum(add_num)
    self.challenge_num = self.challenge_num + add_num
end

--请求竞技场对手
function arena:Query()
    if not self.is_first_query then
        network:Send({query_arena_rival = {}})
    else
        --当前时间是否 大于更新时间
        if time_logic:Now() > self.refresh_time then
            network:Send({query_arena_rival = {}})
        else
            graphic:DispatchEvent("show_world_sub_scene", "arena_sub_scene")
        end
    end
end

function arena:QueryExchangeConfig()
    if not self.has_query_exchange_config then
        network:Send({query_medal_exchange_config = {}})
    else
        graphic:DispatchEvent("show_world_sub_panel", "exchange_reward_msgbox")
    end
end

function arena:SetRefreshTime(refresh_time)
    self.refresh_time = refresh_time
end

--挑战对手
function arena:ChallengeRival(rival_pos)
    if self.challenge_num == 0 then
        graphic:DispatchEvent("show_prompt_panel", "ladder_not_enough_count")
        return
    end

    if rival_pos >= 1 and rival_pos <= 9 then
        if not self.rival_list[rival_pos].state then
            network:Send( {challenge_arena_rival = { rival_pos = rival_pos }} )
        else
            graphic:DispatchEvent("show_prompt_panel", "ladder_rival_already_chanllenge")
        end
    else
        graphic:DispatchEvent("show_prompt_panel", "ladder_rival_out_of_date")
    end
end

function arena:RefreshRival()
    local cost_blood_diamand = constants.ARENA_REFRESH_COST_BLOOD_DIAMOND
    local resource_type = constants.RESOURCE_TYPE["blood_diamond"]
    
    if not resource_logic:CheckResourceNum(resource_type, cost_blood_diamand, true) then
        return
    end

    network:Send( {refresh_arena_rival = { }} )
end


function arena:MedalPrize(exchange_prize_id, num)
    local medal_exchange_info = config_manager.medal_exchange_config[exchange_prize_id]
    local num = num or 1
    
    if medal_exchange_info.reward_type == constants.REWARD_TYPE["item"] and bag_logic:GetSpaceCount() < num then
       graphic:DispatchEvent("show_prompt_panel","bag_full")
       return

    elseif medal_exchange_info.reward_type == constants.REWARD_TYPE["mercenary"] then 
       if num > 10 then 
          graphic:DispatchEvent("show_prompt_panel","exchange_mercenary_max_tip")
          return
       end

       if troop_logic:GetCurMercenaryNum() + num > troop_logic:GetCampCapacity() then 
          graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", troop_logic.camp_capacity)
          return
       end 
    end

    local cost_resource_num1 = medal_exchange_info.need_count1 * num
    local cost_resource_num2 = medal_exchange_info.need_count2 * num

    if resource_logic:CheckResourceNum(medal_exchange_info.need_resource1, cost_resource_num1, true) and
        resource_logic:CheckResourceNum(medal_exchange_info.need_resource2, cost_resource_num2, true) then
        network:Send({ medal_exchange = { prize_id = exchange_prize_id, exchange_num = num}})
    end
end

function arena:GetRivalList()
    return self.rival_list
end

function arena:GetSingleRivalInfo(rival_pos)
    return self.rival_list[rival_pos]
end

function arena:GetAlreadyTakeReward(index)
    return bit.band(self.prize_status, bit.lshift(1, index-1)) ~= 0
end

function arena:RegisterMsgHandler()
    network:RegisterEvent("query_arena_rival_ret", function(recv_msg)
        print("query_arena_rival_ret")
        if recv_msg then
            self.is_first_query = true
            for i, rival in pairs(recv_msg.rival) do
                rival.template_id = rival.template_id_list[1]
                self.rival_list[i] = rival
            end

            self.challenge_num = recv_msg.challenge_num
            self.win_num = recv_msg.win_num
            self.refresh_time = recv_msg.refresh_time

            --是否领取了奖励，true代表已经领取，false代表未领取
            self.prize_status  = recv_msg.prize_status

            --获取arena基本信息之后，显示arena 场景
            graphic:DispatchEvent("show_world_sub_scene", "arena_sub_scene")
        end
    end)

    network:RegisterEvent("query_medal_exchange_config_ret", function(recv_msg)
        self.has_query_exchange_config = true
        config_manager.medal_exchange_config = {}

        if recv_msg.config_list then
            for _, conf in ipairs(recv_msg.config_list) do
                config_manager.medal_exchange_config[conf.ID] = conf

                local r = conf.reward_info

                conf.reward_type = r[1].reward_type
                conf.param1 = r[1].param1
                conf.param2 = r[1].param2
            end

            config_manager.medal_exchange_config.MAX_CONF_NUM = #recv_msg.config_list
        end
        
        graphic:DispatchEvent("show_world_sub_panel", "exchange_reward_msgbox")
    end)

    network:RegisterEvent("challenge_arena_rival_ret", function(recv_msg)
        print("challenge_arena_rival_ret")

        if recv_msg.result == "not_enough_count" then
            graphic:DispatchEvent("show_prompt_panel", "ladder_not_enough_count")

        elseif recv_msg.result == "rival_info_missing" then
            graphic:DispatchEvent("show_prompt_panel", "ladder_rival_out_of_date")

        elseif recv_msg.result =="already_challenge_rival" then
            graphic:DispatchEvent("show_prompt_panel", "ladder_rival_already_chanllenge")

        else
            self.challenge_rival_pos = recv_msg.rival_pos
            self.challenge_num = recv_msg.challenge_num
            local is_winner = false

            if recv_msg.result == "success" then
                is_winner = true

                self.rival_list[recv_msg.rival_pos].state = true

                self.win_num = recv_msg.win_num or (self.win_num + 1)

                if self.win_num > 9 then
                    self.win_num = 9
                end

                --统计竞技场1胜和4胜次数
                if self.win_num == 1 then
                    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["arena_win1"], 1)
                elseif self.win_num == 4 then
                    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["arena_win4"], 1)
                end

                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["arena_win"], 1)
            end

            if not recv_msg.battle_record or #recv_msg.battle_record == 0 then
                graphic:DispatchEvent("arena_challenge_result", recv_msg.result)
                return
            end

            local battle_type = client_constants.BATTLE_TYPE["vs_arena_player"]

            graphic:DispatchEvent("show_battle_room", battle_type, self.challenge_rival_pos, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                graphic:DispatchEvent("arena_challenge_result", recv_msg.result)

                --战斗播放完毕 自动弹出奖励`
                if is_winner then
                    if self.win_num == 1 or self.win_num == 4 or self.win_num == 9 then
                        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                    end

                end
             end)
        end
    end)

    network:RegisterEvent("refresh_arena_rival_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("arena_refresh_rival")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "ladder_refresh_failure")

        elseif recv_msg.result == "not_enough_blood_diamond" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])
        end
    end)


    network:RegisterEvent("medal_exchange_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")

        elseif recv_msg.result == "failure" then
        end
    end)


end



return arena
