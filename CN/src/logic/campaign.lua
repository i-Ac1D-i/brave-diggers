local config_manager = require "logic.config_manager"
local network = require "util.network"
local time_logic = require "logic.time"
local graphic = require "logic.graphic"

local bag_logic
local resource_logic

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local mercenary_config = config_manager.mercenary_config

local campaign = {}
function campaign:Init()
    resource_logic = require "logic.resource"
    bag_logic = require "logic.bag"

    self.cur_campaign_id = 0
    self.status = 0
    self.score = 0
    self.exp = 0
    self.title = ""
    self.info = ""
    self.end_time = 0
    self.challenge_num = 0
    self.limit_count = 0
    self.level_info_list = nil
    self.buff_info_map = nil
    self.reward_list = nil
    self.top_score_list = nil
    self.rule_info = nil
    self.has_view_rule = false
    self.special_cond_list = {} -- 特权条件

    self.cur_exe_level_id = 0

    self:RegisterMsgHandler()
end

-- 是否查询过规则信息
function campaign:IsQueryRuleInfo()
    if not self.rule_info then
        return false
    end

    return true
end

-- 是否需要查询奖励信息
function campaign:IsQueryRewardInfo()
    if self.reward_list then
        return false
    end
    return true
end

-- 是否需要查询关卡信息
function campaign:IsQueryLevelInfo()
    if self.level_info_list then
        return false
    end
    return true
end

-- 活动是否开启
function campaign:IsOpen()
    if not self.status or self.status == constants.CAMPAIGN_STATUS.unknown then
        return false
    end
    if time_logic:GetDurationToFixedTime(self.end_time) > 0 then
        return true
    end
    return false
end

function campaign:SetExeLevelId(level_id)
    self.cur_exe_level_id = level_id
    local level_info = self.level_info_list[level_id]
    if level_info.status == "limit" then
        return false
    end
    return true
end

-- 执行战斗事件
function campaign:SolveEvent()
    if self.challenge_num <= 0 then
        if self.limit_count <= 0 then
            -- 如果不能购买
            graphic:DispatchEvent("show_prompt_panel", "campaign_challenge_not_enough")
        else
            -- 弹出购买界面
            self:QueryOverTimeInfo()
        end
        return
    end
    network:Send({battle_campaign = { level_id = self.cur_exe_level_id}})
end

-- 查询合战活动信息
function campaign:Query()
    -- network:Send({ campaign_query_info = {} })
end

-- 查询合战关卡信息
function campaign:QueryLevelInfo()
    network:Send({ query_campaign_level = { campaign_id = self.cur_campaign_id} })
end

function campaign:QueryBuffInfo()
    network:Send({ query_campaign_buff = { campaign_id = self.cur_campaign_id} })
end

function campaign:QueryRuleInfo()
    network:Send({ query_campaign_rule = { campaign_id = self.cur_campaign_id} })
end

function campaign:QueryRankInfo()
    network:Send({ query_campaign_rank = { campaign_id = self.cur_campaign_id} })
end

function campaign:QueryRewardInfo()
    network:Send({ query_campaign_reward = { campaign_id = self.cur_campaign_id} })
end

function campaign:QueryOverTimeInfo()
    network:Send({ query_campaign_overtime = { campaign_id = self.cur_campaign_id} })
end

function campaign:BuyOverTimeCount()
    network:Send({ buy_campaign_overtime = {} })
end

-- 购买BUFF
function campaign:BuyBuff(buff_data)
    -- 检查经验值
    if buff_data.req_exp > self.exp then
        graphic:DispatchEvent("show_prompt_panel", "campaign_exp_not_enough")
        return
    end

    -- 发送兑换请求
    network:Send({convert_campaign_exp = {convert_id = buff_data.type}})
end

-- 兑换奖励
function campaign:ConvertReward(data, num)
    if self.status ~= constants.CAMPAIGN_STATUS.reward then
        graphic:DispatchEvent("show_prompt_panel", "campaign_reward_over_enough")
        return
    end
    local num = num or 1

    if data.type == constants.CAMPAIGN_REWARD_TYPE.rank then  -- 排行奖励要检查排行
        if #data.req_value == 1 and self.rank ~= data.req_value[1] then
            -- 条件是1个，那排名不相等
            graphic:DispatchEvent("show_prompt_panel", "campaign_rank_not_enough")
            return
        elseif #data.req_value == 2 and (self.rank < data.req_value[1] or self.rank > data.req_value[2]) then
            -- 条件是2个。那么<>
            graphic:DispatchEvent("show_prompt_panel", "campaign_rank_not_enough")
            return
        elseif #data.req_value > 2 then
            graphic:DispatchEvent("show_prompt_panel", "campaign_rank_not_enough")
            return
        end
        if data.count >0 then
            graphic:DispatchEvent("show_prompt_panel", "campaign_reward_rank_convert")
            return
        end

    elseif data.type == constants.CAMPAIGN_REWARD_TYPE.score then
        --赛点奖励要检查赛点
        if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["campaign_score"], num * data.req_value[1], true) then
            return
        end
    end

    local free_count = bag_logic:GetSpaceCount()
    free_count = free_count - data.bag_capacity * num
    if free_count < 0 then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return
    end

    network:Send({convert_campaign_reward = {convert_id = data.id, convert_num = num}})
end

-- 复活战斗
function campaign:ReviveCampaignBattle()

    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], constants.CAMPAIGN_REVIVE_VALUE, true) then
        return
    end

    if self.level_info_list[self.cur_exe_level_id].next_battle_time <= time_logic:Now() then
        graphic:DispatchEvent("show_prompt_panel", "campaign_revive_failure")
        return
    end

    network:Send({revive_campaign_battle = {level_id = self.cur_exe_level_id}})
end

-- 比较符
local function CompareCondOperator(q1,operator,q2)
    if not q1 or not operator or not q2 then
        return false
    end

    if operator == 1 then
        return q1 > q2
    elseif operator == 2 then
        return q1 < q2
    elseif operator == 3 then
        return q1 == q2
    elseif operator == 4 then
        return q1 >= q2
    elseif operator == 5 then
        return q1 <= q2
    end
    return false
end

-- 检查合战特权佣兵条件
function campaign:CheckSpecialMercenary(mercenary_info, not_have)
    local config = not_have and mercenary_info or mercenary_config[mercenary_info.template_id]
    local cond_type_list = {config.race,config.sex,config.job}

    local is_or = 0
    for _, or_list in pairs(self.special_cond_list) do
        local is_and = 1
        local and_list = or_list.and_list
        for i = 1, #and_list do
            local cond_config = and_list[i]
            if CompareCondOperator(cond_type_list[cond_config.type], cond_config.oper,cond_config.value) == false then
                is_and = 0
            end
        end
        
        if is_and == 1 then
           is_or = 1
        end
    end

    return is_or > 0
end

-- 自更新
function campaign:Update(elapsed_time)
    if self.status == constants.CAMPAIGN_STATUS.reward then
        graphic:DispatchEvent("update_campaign_reward_time", elapsed_time)
    end
end

--注册服务端回调
function campaign:RegisterMsgHandler()
    network:RegisterEvent("query_campaign_info_ret", function(recv_msg)
        print("query_campaign_info_ret")
        self.cur_campaign_id = recv_msg.cur_campaign_id
        self.status = recv_msg.status
        self.title = recv_msg.title
        self.info = recv_msg.info
        self.end_time = recv_msg.end_time                       
        self.challenge_num = recv_msg.challenge_num 		
        self.score = recv_msg.score
        self.exp = recv_msg.exp
        self.rank = recv_msg.rank
        self.top_score_list = recv_msg.top_score_list
        self.limit_count = recv_msg.limit_count
        self.has_view_rule = recv_msg.has_view_rule
        self.special_cond_list = recv_msg.special_cond_list or {}
    end)

    network:RegisterEvent("query_campaign_level_ret",function (recv_msg)
        print("query_campaign_level_ret")
        self.level_info_list = recv_msg.level_info_list
        self.status = recv_msg.status
        graphic:DispatchEvent("show_world_sub_scene", "campaign_sub_scene")
    end)

    network:RegisterEvent("query_campaign_buff_ret",function (recv_msg)
        print("query_campaign_buff_ret")
        self.buff_info_map = {}
        for k,v in pairs(recv_msg.buff_info_list) do
            self.buff_info_map[v.type] = v
        end
        self.evo_info_list = recv_msg.evo_info_list
        graphic:DispatchEvent("show_world_sub_panel", "campaign_buff_msgbox")
    end)

    network:RegisterEvent("query_campaign_rule_ret",function (recv_msg)
        print("query_campaign_rule_ret")
        self.rule_info = recv_msg
        self.has_view_rule = true
        graphic:DispatchEvent("show_world_sub_panel", "campaign_rule_msgbox")
    end)

    network:RegisterEvent("query_campaign_reward_ret",function (recv_msg)
        print("query_campaign_reward_ret")
        self.reward_list = recv_msg.reward_list
        graphic:DispatchEvent("show_world_sub_panel", "campaign_reward_msgbox")
    end)

    network:RegisterEvent("query_campaign_rank_ret",function (recv_msg)
        print("query_campaign_rank_ret")
        self.rank = recv_msg.rank
        self.top_rank_list = recv_msg.top_rank_list
        graphic:DispatchEvent("update_campaign_main")
        graphic:DispatchEvent("show_world_sub_panel", "campaign_rank_msgbox")
    end)

    network:RegisterEvent("convert_campaign_exp_ret",function (recv_msg)
        print("convert_campaign_exp_ret")
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end

        self.exp = recv_msg.exp
        local v = recv_msg.buff_info
        self.buff_info_map[v.type] = v
        local score = recv_msg.score
        if score then
            --如果赛点有更新，就弹出赛点获得界面
            self.score = score
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            local type_str = lang_constants:GetCampaignBuffType(v.type)
            graphic:DispatchEvent("show_prompt_panel", "campaign_buff_levelup", type_str, v.level)
        end
        if recv_msg.rank then
            self.rank = recv_msg.rank
        end
        graphic:DispatchEvent("update_campaign_main")
        graphic:DispatchEvent("update_buff_msgbox_item", v)
    end)

    network:RegisterEvent("convert_campaign_reward_ret",function (recv_msg)
        print("convert_campaign_reward_ret")
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end
        self.reward_list[recv_msg.update_reward_id].count = recv_msg.update_reward_value

        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        graphic:DispatchEvent("update_campaign_reward_info",self.reward_list[recv_msg.update_reward_id])
        if recv_msg.score then
            self.score = recv_msg.score
            graphic:DispatchEvent("update_campaign_reward_score", recv_msg.score)
        end
    end)

    network:RegisterEvent("battle_campaign_ret",function (recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end

        self.exp = recv_msg.exp
        self.score = recv_msg.score
        self.rank = recv_msg.rank
        self.challenge_num = recv_msg.challenge_num

        local list = recv_msg.update_level_list
        for k, v in pairs(list) do
            self.level_info_list[v.level_id] = v
            graphic:DispatchEvent("update_campaign_level", v)
        end
        graphic:DispatchEvent("update_campaign_main")

        if recv_msg.battle_record then
            local is_winner = recv_msg.is_winner
            local battle_type = client_constants.BATTLE_TYPE["vs_campaign"]

            graphic:DispatchEvent("show_battle_room", battle_type, recv_msg.monster_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                if not is_winner then
                    --如果战斗失败
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["revive_campaign"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, constants["CAMPAIGN_REVIVE_VALUE"])
                end
            end)
        end
    end)

    network:RegisterEvent("query_campaign_overtime_ret",function (recv_msg)
        local mode = client_constants.CONFIRM_MSGBOX_MODE["buy_campaign_challenge"]
        local req_value = recv_msg.req_value
        local reward_value = recv_msg.reward_value
        local limit_count = recv_msg.limit_count
        graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode,req_value,reward_value,limit_count)
    end)

    network:RegisterEvent("campaign_overtime_ret", function(recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            return
        end

        self.challenge_num = recv_msg.challenge_num
        if recv_msg.limit_count then
            self.limit_count = recv_msg.limit_count
        end

        local level_id = recv_msg.level_id
        if level_id then
            self.level_info_list[level_id].next_battle_time = time_logic:Now()
        end

        graphic:DispatchEvent("update_campaign_main")
        graphic:DispatchEvent("update_campaign_event")
    end)

    network:RegisterEvent("update_campaign_property",function (recv_msg)
        if recv_msg.exp then
            self.exp = recv_msg.exp
        end

        graphic:DispatchEvent("update_campaign_main")
    end)

    network:RegisterEvent("revive_campaign_battle_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.level_info_list[recv_msg.level_id].next_battle_time = time_logic:Now()
            self.challenge_num = self.challenge_num + 1

            graphic:DispatchEvent("update_campaign_main")
            graphic:DispatchEvent("update_campaign_event")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)
end

return campaign
