local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local client_constants = require "util.client_constants"
local time_logic = require "logic.time"

local PRODUCT_TYPE = constants.PAYMENT_PRODUCT_TYPE
local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE
local CARNIVAL_TYPE = constants.CARNIVAL_TYPE

local resource_logic = require "logic.resource"
local BUY_TYPE = constants.EXPEDITION_TYPE

local buy_search_config = config_manager.ladder_buy_config[BUY_TYPE.search]
local buy_figthing_config = config_manager.ladder_buy_config[BUY_TYPE.challenge]

local utils = require "util.utils"

local ladder_tower = {}
function ladder_tower:Init()
    --开始时间
    self.start_time = 0  

    --结束时间
    self.end_time = 0

    --开始之前时间
    self.countdown = 0

    --开始战斗时间
    self.duration = 0

    --当前段位
    self.ladder_level = 0

    --搜索次数
    self.search_count = 0

    --购买搜索次数
    self.buy_search_count = 0

    --挑战次数
    self.figthing_count = 0

    --购买挑战次数
    self.buy_figthing_count = 0

    --当前积分
    self.integral_num = 0

    --是否看过新赛季公告
    self.is_open_start_new_notice = false

    --胜率
    self.winner_percent = 0

    --自己的排行
    self.my_rank_info = nil

    --当前玩家
    self.players = {}

    --排行榜列表
    self.rank_list = {}

    self.reward_list = {}

    self.is_close_tab = false

    self:RegisterMsgHandler()
end

--得到当前玩家
function ladder_tower:GetPlayers()
    return self.players
end

--得到结束时间
function ladder_tower:GetEndTime()
    return  self.end_time
end

--获得排行榜列表
function ladder_tower:GetRankList()
    return self.rank_list
end

--获得自己的排行榜信息
function ladder_tower:GetSelfRankInfo()
    
    if self.my_rank_info == nil then
        self:QueryRank()
    end
    return self.my_rank_info
end

function ladder_tower:CheckNewSeason()
    local t_now = time_logic:Now()
    if self.end_time < t_now then
        self:QueryExpedition()
    end
end

--获得可以购买的最大次数
function ladder_tower:GetBuyMaxTimes(buy_type)
    if buy_type == client_constants.TIMES_TYPE.ladder_tower_fighting_times then
        --战斗次数
        return #buy_figthing_config - self.buy_figthing_count
    elseif buy_type == client_constants.TIMES_TYPE.ladder_tower_buy_refresh_times then
        --搜索次数
        return #buy_search_config - self.buy_search_count
    end
    return 0
end

--当前购买要消耗多少
function ladder_tower:GetNeedCostBloodWithType(buy_type, count)
    local all_cost = 0
    if buy_type == client_constants.TIMES_TYPE.ladder_tower_fighting_times then
        --战斗次数
        for i=1,count do
            local data = buy_figthing_config[i + self.buy_figthing_count]
            if data then
                all_cost = all_cost + data.price
            end
        end

    elseif buy_type == client_constants.TIMES_TYPE.ladder_tower_buy_refresh_times then
        --搜索次数
        for i=1,count do
            local data = buy_search_config[i + self.buy_search_count]
            if data then
                all_cost = all_cost + data.price
            end
        end
    end
    return all_cost
end

--获取当前玩家的信息
function ladder_tower:GetMemberTroopInfo(enemy_id)
    local player = {}
    if self.players then
        for k,v in pairs(self.players) do
            if v.enemy_id == enemy_id then
                player = v
            end
        end
    end
    player.name = player.leader_name
    return player
end

--得到当前升级需要的积分
function ladder_tower:GetNowNeedAllSocre(level)
    local level = level or self.ladder_level
    local config = config_manager.ladder_level_config[level]
    if config then
        return config.lvup_need_score
    end
    return 0
end

------------------------------网络请求

function ladder_tower:QueryExpedition()
    network:Send({ query_expedition = {} })
end

--挑战
function ladder_tower:Figthing(enemy_id)
    network:Send({ expedition_fight = { enemy_id = enemy_id} })
end

--刷新玩家
function ladder_tower:RefreshPlayer()
    network:Send({ refresh_expedition_search = {} })
end

--购买次数
function ladder_tower:BuyTimes(buy_type, buy_num)
    local types = BUY_TYPE.search
    if buy_type == client_constants.TIMES_TYPE.ladder_tower_fighting_times then
        --战斗次数
        types = BUY_TYPE.challenge
    end
    network:Send({ expedition_apend_times = { type = types, num = buy_num} })
end

--查询排行榜
function ladder_tower:QueryRank()
    network:Send({ get_expedition_rank = {} })
end

--查看过新赛季公告了
function ladder_tower:IsOpenStartNotice()
    network:Send({ player_click_tab = {} })
end

function ladder_tower:RegisterMsgHandler()

    --查询返回
    network:RegisterEvent("query_expedition_ret", function(recv_msg)
        print("query_expedition_ret")
        --当前玩家
        self.players = recv_msg.enemys  
        --当前刷新次数
        self.search_count = recv_msg.reduce_search_times 
        -- 当前挑战次数
        self.figthing_count = recv_msg.reduce_challenge_times 
        --购买次数
        self.buy_search_count = recv_msg.buy_search_times
        self.buy_figthing_count = recv_msg.buy_challenge_times
        --当前积分
        self.integral_num = recv_msg.ladder_core 
        --//当前组         
        self.ladder_level = recv_msg.group   
        -- //胜率 小数               
        self.winner_percent = recv_msg.winner_percent   
        -- //总共战斗次数     
        self.fight_times = recv_msg.fight_times 
        -- //赛季开始时间(格林威治时间)        
        self.start_time =  recv_msg.season_begin_time 
        -- //倒计时时间(间隔/小时)  
        if recv_msg.countdown then
            self.countdown = self.start_time + recv_msg.countdown * 3600 
        end   
        -- //战斗时间(间隔/小时) 
        if recv_msg.duration then         
            self.duration = self.countdown + recv_msg.duration * 3600    
        end
        -- //休战时间(间隔/小时)
        if recv_msg.truce then            
            self.end_time = self.duration + recv_msg.truce * 3600  
        end
        --赛季奖励
        self.reward_list = recv_msg.reward_list

        --是否看过开始公告
        self.is_close_tab = recv_msg.is_close_tab

        self.pre_group = recv_msg.pre_group 
        self.pre_rank = recv_msg.pre_rank 
    end)

    --挑战结果
    network:RegisterEvent("expedition_fight_ret", function(recv_msg)
        if recv_msg.result == "success" then

            --当前积分
            --记录之前分数和等级
            local old_integral_num = self.integral_num 
            self.integral_num = recv_msg.ladder_core 
            local old_level = self.ladder_level
            self.ladder_level = recv_msg.group

            --挑战返回进入战斗
            local is_winner = recv_msg.is_winner

            --战斗属性
            local battle_property = recv_msg.battle_property
            local battle_record = recv_msg.battle_record
            --战斗类型
            local battle_type = client_constants.BATTLE_TYPE["vs_mine_rob_target"]
            graphic:DispatchEvent("show_battle_room", battle_type, recv_msg.target_info, battle_property, battle_record, is_winner, function()
                --战斗播放完毕 自动弹出奖励`
                graphic:DispatchEvent("show_world_sub_panel", "ladder_tournament_settlement_msgbox", recv_msg.reward_list, old_integral_num, old_level)
             end)

            --新的玩家
            if recv_msg.enemys then
                self.players = recv_msg.enemys
            end

            -- 当前剩余挑战次数
            self.figthing_count = recv_msg.reduce_challenge_times 
            
            graphic:DispatchEvent("ladder_fighting_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --刷新玩家
    network:RegisterEvent("refresh_expedition_search_ret", function(recv_msg)
        if recv_msg.result == "success" then 
            --当前玩家
            self.players = recv_msg.enemys  
            --当前刷新次数
            self.search_count = recv_msg.reduce_search_times
            graphic:DispatchEvent("ladder_refresh_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --购买次数
    network:RegisterEvent("expedition_apend_times_ret", function(recv_msg)
        if recv_msg.result == "success" then 
            if recv_msg.type == BUY_TYPE.search then
                --当前刷新次数
                self.search_count = self.search_count + recv_msg.num 
                self.buy_search_count = self.buy_search_count + recv_msg.num
            else
                self.figthing_count = self.figthing_count + recv_msg.num 
                self.buy_figthing_count = self.buy_figthing_count + recv_msg.num 
            end 
            graphic:DispatchEvent("ladder_buy_times_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --获取排行
    network:RegisterEvent("get_expedition_rank_ret", function(recv_msg)
        self.rank_list = recv_msg.rank_info or {}
        self.my_rank_info = recv_msg.my_rank  
 
        graphic:DispatchEvent("rank_refresh_success")

    end)

    --阅读了公告
    network:RegisterEvent("player_click_tab_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.is_close_tab = true
            graphic:DispatchEvent("ladder_show_start_season_success")
        end
    end)
    
    
    
end

return ladder_tower
