local network = require "util.network"
local constants = require "util.constants"

local configuration = require "util.configuration"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"

local lang_constants = require "util.language_constants"
local client_constants = require "util.client_constants"
local platform_manager = require "logic.platform_manager"
local TEMPLATE_TYPE = client_constants["CARNIVAL_TEMPLATE_TYPE"]
local user_logic
local bag_logic
local achievement_logic
local ladder_logic
local time_logic
local adveture_logic
local troop_logic

local CARNIVAL_TYPE = constants.CARNIVAL_TYPE
local ACHIEVEMENT_TYPE = constants.ACHIEVEMENT_TYPE
local ACHIEVEMENT_DURATION = 5

local CDKEY_PROMPT =
{
    ["already_taken"] = "already_taken_by_myself",
    ["cant_use_this_key"] = "cant_use_this_key",
    ["this_key_not_exist"] = "this_key_not_exist",
    ["other_player_taken"] = "other_player_taken",
    ["out_of_date"] = "cdkey_out_of_date",
    ["bag_full"] = "bag_full",
    ["server_error"] = "cdkey_server_error",
    ["channel_error"] = "cdkey_channel_error",
    ["time_error"] = "cdkey_time_error",
    ["failure"] = "cdkey_failure",
}

local REWAED_PROMPT =
{
    ["failure"] = "take_reward_failure",
    ["not_in_carnival"] = "take_carnival_reward_time_is_not",
    ["cant_meet_condition"] = "cant_take_reward_because_cant_meet_condition",
    ["already_taken"] = "already_taken_the_reward",
    ["bag_full"] = "bag_full",
    ["not_enough_soul"] = "mercenary_soul_stone_not_enough",
    ["show_prompt_panel"] = "carnival_exchange_limit",
    ["not_enough_blood_diamond"] = "blood_diamond_not_enough",
}

local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

local carnival = {}
function carnival:Init()
    user_logic = require "logic.user"
    bag_logic = require "logic.bag"
    achievement_logic = require "logic.achievement"
    ladder_logic = require "logic.ladder"
    time_logic = require "logic.time"
    adveture_logic = require "logic.adventure"
    troop_logic = require "logic.troop"

    --所有活动，包括不在活动中界面显示的, hash
    self.all_config ={}
    --只在活动界面中显示的活动， 数组
    self.config_list = {}
    --通过索引找到活动的key
    self.key_to_congfig_list = {}
    --不在活动界面中显示的活动
    self.special_config = {}
    --活动数据
    self.info_map = {}

    self.carnival_num = 0

    self.achievement_time = 0
    --保存每个活动的每个阶段的奖励状态，二维数组，key，和pos
    self.stages_reward_mark = {}

    self.entire_reward_mark = false

    self:RegisterMsgHandler()
end

--初始化默认值
function carnival:InitConfig(config)
    if not config.mult_num1 then
        config.mult_num1 = {}
    end

    self:InitCarnivalTime(config)
    self:InitCarnivalVisibleStyle(config)
    self:InitCarnivalStage(config)
end

--初始化活动时间
function carnival:InitCarnivalTime(config)

    local cur_time = time_logic:Now()

    if config.carnival_type == CARNIVAL_TYPE["time_limit_store"] and not config.end_time then
        config.end_time = 0
    end

    if not config.begin_time then
        config.begin_time = cur_time
    end

    if not config.end_time then
        config.end_time = cur_time + 31536000
        config.duration = lang_constants:Get("carnival_for_ever_duration")
    else
        --活动起止时间
        local begin_time = time_logic:GetDateInfo(config.begin_time)
        local end_time = time_logic:GetDateInfo(config.end_time - 1)
        
        
        if platform_manager:GetChannelInfo().carnival_init_carnival_time_format then
            --小语种日期格式
            config.duration = string.format("%02d/%02d~%02d/%02d", begin_time.day, begin_time.month, end_time.day, end_time.month)
        else
            config.duration = begin_time.month .. "." .. begin_time.day .. "~" .. end_time.month .. "." .. end_time.day
        end

        --r2荣誉之战活动日期格式
        if config.desc and string.match(config.desc, "%%d") then
            if platform_manager:GetChannelInfo().carnival_ladder_time_format and config.carnival_type == constants.CARNIVAL_TYPE["ladder"] then
                local begin_time = time_logic:GetDateInfo(config.end_time + 1)
                local locale = platform_manager:GetLocale()
                if locale == "zh-TW" then
                    config.desc = string.format(config.desc, end_time.month, end_time.day, begin_time.month, begin_time.day)
                else
                    config.desc = string.format(config.desc, end_time.day, end_time.month, begin_time.day, begin_time.month)
                end
                
            elseif platform_manager:GetChannelInfo().carnival_init_carnival_time_format then
                --小语种日期格式
                config.desc = string.format(config.desc, begin_time.day, begin_time.month, end_time.day, end_time.month)
            else
                config.desc = string.format(config.desc, begin_time.month, begin_time.day, end_time.month, end_time.day)
            end
        end
    end
end

--解析活动的显示类型
function carnival:InitCarnivalVisibleStyle(config)
    local template_type, reward_type, reward_panel_type = 0, 0, 0
    if config.visible_style then
        template_type = config.visible_style[1]
        reward_type = config.visible_style[2]
        reward_panel_type = config.visible_style[3]
    end

    config.template_type = template_type
    config.reward_type = reward_type
    config.reward_panel_type = reward_panel_type
end

--初始化活动的显示 数量
function carnival:InitCarnivalStage(config)

    if config.template_type == TEMPLATE_TYPE["rank"] then
        config.stages = #config.mult_num1

    elseif config.template_type == TEMPLATE_TYPE["stage"] then
        config.stages = #config.mult_num1

    elseif config.template_type == TEMPLATE_TYPE["display"] then

        if config.carnival_type == CARNIVAL_TYPE["first_payment"] then
            config.stages = #config.reward_list[1].reward_info

        else
            if config.reward_panel_type == 0 then
                config.stages = #config.mult_num1
            else
                config.stages = #config.collect_step
            end
        end

    elseif config.template_type == TEMPLATE_TYPE["text"] then
        config.stages = #config.mult_str1

    elseif config.template_type == TEMPLATE_TYPE["discount"] then
        config.stages = #config.mult_num1

    elseif config.template_type == TEMPLATE_TYPE["multi_token"] then
        config.stages = #config.collect_step

    elseif config.template_type == TEMPLATE_TYPE["evolution"] then
        config.stages = #config.mult_num1

    elseif config.template_type == TEMPLATE_TYPE["fund"] then
        config.stages = #config.mult_num1
        
    elseif config.template_type == TEMPLATE_TYPE["mercenary_exchange"] then
        config.stages = #config.reward_list
    end
end

function carnival:GetLocaleInfoString(config, key, index)
    local locale = platform_manager:GetLocale()
    local result = config[key]
    if config[key.."_"..locale] then
        result = config[key.."_"..locale]
    end

    if index and type(result) == "table" then
        result = result[index]
    end

    return result
end

function carnival:GetCarnivalNum()
    return self.carnival_num
end

--获取配置表信息
function carnival:GetConfigList()
    return self.config_list
end

--获取活动的当前值 和奖励状态
function carnival:GetValueAndReward(config, value_index, reward_index)
    local info = self.info_map[config.key]
    if not info then return 0, 0 end

    value_index = value_index or 1
    reward_index = reward_index or 1

    local carnival_type = config.carnival_type

    if carnival_type == CARNIVAL_TYPE["tmp_achievement"] then
        return info.cur_value, info.step_reward[reward_index]

    elseif carnival_type == CARNIVAL_TYPE["achievement_value"] then
        return achievement_logic:GetStatisticValue(config.need_type), info.step_reward[reward_index]

    elseif carnival_type == CARNIVAL_TYPE["multi_achievement"] then
        if info.cur_value_multi then
            return info.cur_value_multi[value_index], info.step_reward[reward_index]
        else
            return 0, 0
        end

    elseif carnival_type == CARNIVAL_TYPE["collect_item"] then
        return info.collect_info[value_index], info.step_reward[reward_index]

    elseif carnival_type == CARNIVAL_TYPE["ladder"] then
        return ladder_logic:GetCurRank(), 0

    elseif carnival_type == CARNIVAL_TYPE["first_payment"] then
        --首冲
        return 0, info.step_reward[1]

    elseif carnival_type == CARNIVAL_TYPE["single_equal"] then
        --单笔充值不重复领取
        if info.step_reward[reward_index] > 0 and info.step_flag[reward_index] > 0 then
            return 0, 1
        else
            return 0, 0
        end
    elseif carnival_type == CARNIVAL_TYPE["time_limit_store"] then
        return info.cur_value, info.step_reward[reward_index]

    elseif carnival_type == CARNIVAL_TYPE["vote"] then
        return info.cur_value_multi[1], 0

    elseif carnival_type == CARNIVAL_TYPE["fund"] then
        return info.cur_value, info.step_reward[reward_index]

    elseif carnival_type == CARNIVAL_TYPE["sns_invitation"] then
        if info.cur_value_multi then
            return info.cur_value_multi[value_index], info.step_reward[reward_index]
        else
            return 0, 0
        end

    else
        return 0, 0
    end
end

--返回第一个在满足条件的活动
function carnival:GetSpecialCarnival(template_type)
    local special_list = self.special_config[template_type]
    if not special_list then return end

    for i = 1, #special_list do
        local conf = special_list[i]
        if template_type == TEMPLATE_TYPE["first_payment"] then
           if self.stages_reward_mark[conf.key][1] ~= STEP_STATUS["already_taken"] then
              return conf
           end

        elseif template_type == TEMPLATE_TYPE["spring_lottery"] then
            if self:GetSpringLotteryTimeValid(conf) then
               return conf
            end
        else
            if self:GetTimeValid(conf) then
                if template_type == TEMPLATE_TYPE["magic_door"] then
                    constants.RECRUIT_COST["magic_door"] = conf.extra_num1
                end
                return conf
            end
        end
    end
end

-- 获取特殊的visible_style
function carnival:GetSpecialVisibleStyle()
    local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE
    local CARNIVAL_TYPE = constants.CARNIVAL_TYPE
    local config = self:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["christmas"])
    if config and config.visible_style[4] then
        return config.visible_style[4], config
    else
        return false, false
    end
end

--返回首充的标记, 这个有没有必要，还是放在user_logic里
function carnival:GetFirstPaymentMark()
    return user_logic:GetPermanentMark(constants.PERMANENT_MARK["first_payment_reward"])
end

--判断春节红包活动
function carnival:GetSpringLotteryTimeValid(conf)
    local now_time = time_logic:Now()
    local valid_flag = false
    if conf and now_time <= conf.end_time then
       valid_flag = true
    end
    return valid_flag
end

--判断活动是否在有效期内
function carnival:GetTimeValid(conf)
    local cur_time = time_logic:Now()
    if conf and cur_time >= conf.begin_time and cur_time <= conf.end_time then
        return true
    end
    return false
end

--获取当前排名佣兵的初始位置
function carnival:GetMercenaryIdInitIndex(config, template_id)
    local template_index =  0
    for i = 1, #config.mult_num1 do
        if template_id == config.mult_num1[i] then
            template_index =  i
            break
        end
    end
    return template_index
end

--获取某任务中可以做的index
function carnival:GetCanDoTaskIndex(config)
    local step = 0
    local reward_stage = self.stages_reward_mark[config.key]
    for i = 1, #reward_stage do
        if reward_stage[i] ~= STEP_STATUS["already_taken"] then
            step = i
            break
        end
    end

    return step
end

--通过cdkey 领取奖励
function carnival:TakeRewardByCdkey(cdkey)

    if not cdkey or cdkey == "" then
        graphic:DispatchEvent("show_prompt_panel", "ticket_can_not_null")
        return
    end

    --去掉空格
    if not string.match(cdkey, "%w+") then
        return
    end

    network:Send({take_reward_by_cdkey = { cdkey = cdkey}} )
end

function carnival:CanTakeReward(config, step_index, cant_check_status)
    if not self:GetTimeValid(config) then
        return
    end

    local key = config.key
    local info = self.info_map[key]
    if  not info then
        return
    end

    if not cant_check_status then
        --重新更新下 有些数据在成就中要重新获取
        self:UpdateStageRewardMark(key, true)
        if self.stages_reward_mark[key][step_index] == STEP_STATUS["cant_take"] then
            graphic:DispatchEvent("show_prompt_panel", "cant_take_reward_because_cant_meet_condition")
            return

        elseif self.stages_reward_mark[key][step_index] == STEP_STATUS["already_taken"] then
            graphic:DispatchEvent("show_prompt_panel", "already_taken_the_reward")
            return
        end
    end

    --检测背包
    local total_num = self:GetItemNum(config, step_index)
    if total_num > bag_logic:GetSpaceCount() then
        graphic:DispatchEvent("show_prompt_panel","bag_full")
        return
    end

    return true
end

--领取奖励, 最后一个参数为忽略检测状态
function carnival:TakeReward(config, step_index, cant_check_status, exchange_id)
    if not self:CanTakeReward(config, step_index, cant_check_status) then
        return
    end
    
    network:Send({take_carnival_reward = {key = config.key, step = step_index, exchange_id = exchange_id }} )
end

--检测背包
function carnival:GetItemNum(config, step_index)
    local total_num = 0
    if config.reward_list and config.reward_list[step_index].reward_info then
        for k, v in pairs(config.reward_list[step_index].reward_info) do
            if v.reward_type == constants.REWARD_TYPE["item"] then
                total_num = total_num + v.param2
            end
        end
    end

    return total_num
end

--佣兵排名
function carnival:GetUnionData(config)
    network:Send({query_carnival_union_data = {key = config.key}} )
end

--投票
function carnival:VoteCarnival(key, index)
    local vote_info = self.info_map[key].cur_value_multi
    local config = self.all_config[key]

    if index > #vote_info then
        return
    end

    --vote_info 1:代币数量，2:以投票数  3:所投index
    --没有代币
    if vote_info[1] <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "carnival_vote_not_enough")
        return
    end

    --不能投这个佣兵
    if vote_info[3] ~= index and vote_info[3] ~= 0 then
        graphic:DispatchEvent("show_prompt_panel", "carnival_vote_not_mercenary")
        return
    end

    --检测背包
    local total_num = 0
    local after_vote_num = vote_info[1] +  vote_info[2]
    for i = 1, #config.mult_num2 do
        if vote_info[2] < config.mult_num2[i] and after_vote_num >= config.mult_num2[i] then
            --检测背包
            total_num = total_num + self:GetItemNum(config, i)
        end
    end

    if total_num > bag_logic:GetSpaceCount() then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return
    end
    network:Send({vote_carnival = {index = index, key = key}} )
end

--进化
function carnival:EvolutionMercenary(key, evolution_id, evolution_list)
    local mercenary_list = troop_logic:GetMercenaryList()
    local tmp = {}

    for i = 1, #evolution_list do
        local instance_id = evolution_list[i]

        if not mercenary_list[instance_id] then
            --没有这个佣兵
            return
        end

        if tmp[instance_id] then
            return
        end

        tmp[instance_id] = true
    end

    if troop_logic:GetCurMercenaryNum() - #evolution_list >= troop_logic:GetCampCapacity() then
        graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", troop_logic:GetCampCapacity())
        return
    end

    network:Send({take_evolution = {key = key, formula_id = evolution_id, mercenary_id_list = evolution_list}} )
end

--活动是否有新的可以领取的奖励
function carnival:SetEntireRewardMark()
    self.entire_reward_mark = false
    for k, v in pairs(self.stages_reward_mark) do
        if self.key_to_congfig_list[k] then
            self.entire_reward_mark =  self:CheckReward(k)
            if self.entire_reward_mark then
                break
            end
        end
    end
end

function carnival:GetEntireRewardMark()
    return self.entire_reward_mark
end

--检测是否有可以领取的奖励
function carnival:CheckReward(key)
    if not self.stages_reward_mark[key] then
        return false
    end

    local flag = false
    for i = 1, #self.stages_reward_mark[key] do
        if self.stages_reward_mark[key][i] == STEP_STATUS["can_take"] then
            flag = true
            break
        end
    end
    return flag
end

--返回某个阶段的状态
function carnival:GetStageRewardIndex(key, index)
    if not self.stages_reward_mark[key] then
        return STEP_STATUS["already_taken"]
    end

    index = index or 1
    return self.stages_reward_mark[key][index]
end

--设定收集类活动的状态
function carnival:SetCollectStatus(config, info, key)
    local flag = false
    if config.collect_step then
        for i = 1, #config["collect_step"] do
            self.stages_reward_mark[key][i] = STEP_STATUS["can_take"]
            local need_values = config["collect_step"][i]["step_info"]
            for j = 1, #config.mult_num1 do
                local cur_value, reward_mark = self:GetValueAndReward(config, j, i)

                if reward_mark > 0 then
                    if cur_value < need_values[j] then
                        self.stages_reward_mark[key][i] = STEP_STATUS["cant_take"]
                    end
                else
                    self.stages_reward_mark[key][i] = STEP_STATUS["already_taken"]
                    break
                end
            end
        end

        --todo 这个循环能不能放到上面那个去
        for i = 1, #config["collect_step"] do
            if self.stages_reward_mark[key][i] == STEP_STATUS["can_take"] then
                flag = true
                break
            end
        end
    else
        --佣兵排名也是这个类型的活动
        for j = 1, #config.mult_num1 do
            self.stages_reward_mark[key][j] = STEP_STATUS["cant_take"]
        end
    end
    return flag
end

function carnival:SetStepStatus(key, pos, param1, param2)
    local flag = false
    if param1 then
        if param2 then
            self.stages_reward_mark[key][pos] = STEP_STATUS["can_take"]
            flag = true
        else
            self.stages_reward_mark[key][pos] = STEP_STATUS["cant_take"]
        end
    else
        self.stages_reward_mark[key][pos] = STEP_STATUS["already_taken"]
    end
    return flag
end

--获取vote信息
function carnival:GetCarnivalInfo(key)
    local info = self.info_map[key]
    if info then
        return info
    end
end

--更新数据奖励状态  状态为，不能领取， 可以领取，已经领取
function carnival:UpdateStageRewardMark(key, trigger_event)
    local config = self.all_config[key]
    local info = self.info_map[key]

    if not config or not key then
        return
    end

    if not self.stages_reward_mark[key] then self.stages_reward_mark[key] = {} end

    local flag = false

    if config.carnival_type == CARNIVAL_TYPE["ladder"] then
        self.stages_reward_mark[key][1] = STEP_STATUS["cant_take"]

    elseif config.carnival_type == CARNIVAL_TYPE["collect_item"] then
        flag = self:SetCollectStatus(config, info, key)

    elseif config.carnival_type == CARNIVAL_TYPE["first_payment"] then
        local all_payment = achievement_logic:GetStatisticValue(constants.ACHIEVEMENT_TYPE["all_payment"])
        flag = self:SetStepStatus(key, 1, not self:GetFirstPaymentMark(), all_payment > 0) or flag

    elseif config.carnival_type == CARNIVAL_TYPE["single_equal"] then
        for i = 1, #config.mult_num1 do
            flag = self:SetStepStatus(key, i, info.step_reward[i] > 0, info.step_flag[i] > 0) or flag
        end

    elseif config.carnival_type == CARNIVAL_TYPE["time_limit_store"] then
        self.stages_reward_mark[key][1] = config.end_time > 0 and STEP_STATUS["can_take"] or STEP_STATUS["already_taken"]

    elseif config.carnival_type == CARNIVAL_TYPE["vote"] then
        self.stages_reward_mark[key][1] = STEP_STATUS["cant_take"]

    elseif config.carnival_type == CARNIVAL_TYPE["lottery"] then
        self.stages_reward_mark[key][1] = info.step_reward[1]

    elseif config.carnival_type == CARNIVAL_TYPE["fund"] then
        local info = self.info_map[config.key]
        local t1 = os.date("*t", time_logic:Now())
        local now_day = tonumber(t1.yday)

        if time_logic:Now() < config.reward_time then
            for i = 1, #config.mult_num1 do
                local take_time = info.cur_value_multi[i]
                if take_time == 0 then
                    --未购买，并且额度足够
                    local can_take = info.cur_value >= config.mult_num2[i]
                    flag = flag or can_take
                    self:SetStepStatus(key, i, can_take, can_take)
                else
                    --已购买，还有剩余领取次数
                    local t2 = os.date("*t", take_time)
                    local can_take = info.step_reward[i] > 0 and now_day > tonumber(t2.yday)
                    flag = flag or can_take
                    self:SetStepStatus(key, i, can_take, can_take)
                end
            end

        else
            for i = 1, #config.mult_num1 do
                local take_time = info.cur_value_multi[i]
                local t2 = os.date("*t", take_time)
                local can_take = info.step_reward[i] > 0 and take_time > 0 and now_day > tonumber(t2.yday)
                flag = flag or can_take
                self:SetStepStatus(key, i, can_take, can_take)
            end
        end

    elseif config.carnival_type == CARNIVAL_TYPE["sns_invitation"] then
        for i = 1, #config.mult_num2 do
            local cur_value, reward_mark = self:GetValueAndReward(config, i, i)
            flag = self:SetStepStatus(key, i, reward_mark > 0, cur_value >= config.mult_num2[i]) or flag
        end
    else
        for i = 1, #config.mult_num1 do
            local cur_value, reward_mark = self:GetValueAndReward(config, i, i)
            flag = self:SetStepStatus(key, i, reward_mark > 0, cur_value >= config.mult_num1[i]) or flag
        end
    end

    if trigger_event then
        local pos = self.key_to_congfig_list[key] or 0
        graphic:DispatchEvent("remind_carnival", pos, flag)
    end
end

--每5秒更新一次从成就中取得数据的活动 状态
function carnival:Update(elapsed_time)
    self.achievement_time = self.achievement_time + elapsed_time
    if self.achievement_time >= ACHIEVEMENT_DURATION then
        self.achievement_time = self.achievement_time - ACHIEVEMENT_DURATION
        for key, config in pairs(self.all_config) do
            if config.carnival_type == CARNIVAL_TYPE["achievement_value"] or config.carnival_type == CARNIVAL_TYPE["first_payment"] then
                self:UpdateStageRewardMark(config.key, true)
            end
        end
    end
end

function carnival:OpenLottery(key)
    network:Send({ take_lottery_reward = { key = key } })
end

function carnival:TakeFundProfit(key, step)
    local info = self:GetCarnivalInfo(key)

    local total_num = 2
    if total_num > bag_logic:GetSpaceCount() then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return
    end
    network:Send({ take_fund_profit = { key = key, step = step} })
end
--发送邀请人列表
function carnival:QueryInviteeProgress(inviter_list, sns_uid, sns_platform)
    local config = self:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["sns_invitation"])
    network:Send({ query_sns_invitee_progress = { key = config.key, inviter_list = inviter_list, sns_uid = sns_uid, sns_platform = sns_platform}})
end

function carnival:TakeInvitationReward(config, step_index)

    if config.carnival_type ~= CARNIVAL_TYPE["sns_invitation"] then
        return
    end

    local info = self.info_map[config.key]

    if info.step_reward[step_index] <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "already_taken_the_reward")
        return
    end

    if info.cur_value_multi[step_index] < config.mult_num2[step_index] then
        return
    end

    local total_num = self:GetItemNum(config, step_index)
    if total_num > bag_logic:GetSpaceCount() then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return
    end

    network:Send({ take_sns_invitation_reward = { key = config.key, step = step_index} })
end

function carnival:RegisterMsgHandler()
    network:RegisterEvent("query_carnival_config_ret", function(recv_msg)
        print("query_carnival_config_ret")
        for k, v in pairs(recv_msg.config) do
            self:InitConfig(v)
            self.all_config[v.key] = v

            --不在carnival_panel中显示的活动
            if not v.pos or v.pos == 0 then
                if not self.special_config[v.template_type] then
                    self.special_config[v.template_type] = {} 
                end
                table.insert(self.special_config[v.template_type], v)

                if v.carnival_type == CARNIVAL_TYPE["transmigrate"] then
                    local time = configuration:GetViewTransmigrationTime()
                    local cur_time = time_logic:Now()
                    if time < v.begin_time and cur_time >= v.begin_time and cur_time <= v.end_time then
                        configuration:SetViewedTransmigration(false)
                        configuration:SetCarnivalTransmigrationEndTime(v.end_time)
                    end
                end
            else
                table.insert(self.config_list, v)
            end

            if self.special_config[TEMPLATE_TYPE["spring_lottery"]] then
                table.sort(self.special_config[TEMPLATE_TYPE["spring_lottery"]], function(a, b)
                    return a.begin_time < b.begin_time
                end)
            end
        end

        table.sort(self.config_list, function(a, b)
            return a.pos < b.pos
        end)

        self.carnival_num = #self.config_list

        for i = 1, self.carnival_num do
            self.key_to_congfig_list[self.config_list[i].key] = i
        end

    end)

    network:RegisterEvent("query_carnival_info_ret", function(recv_msg)
        print("carnival_query_ret")

        if recv_msg.carnival_info then
            for i, v in pairs(recv_msg.carnival_info) do
                self.info_map[v.key] = v

                local config = self.all_config[v.key]
                if config and config.carnival_type == CARNIVAL_TYPE["vote"] then
                    --排名
                    v.rank = {}
                    for index = 1, #config.mult_num1 do
                        rank = {}
                        rank.vote_index = index --init_index 为佣兵的默认index
                        rank.votes = v.collect_info[index]
                        table.insert(v.rank, rank)
                    end

                    table.sort(v.rank, function(a, b)
                        return a.votes > b.votes
                    end)
                end

                self:UpdateStageRewardMark(v.key, true)
            end

            self:SetEntireRewardMark()
        end
    end)

    network:RegisterEvent("update_carnival_info_ret", function(recv_msg)
        for k, v in pairs(recv_msg.carnival_info) do
            local config = self.all_config[v.key]
            local info = self.info_map[v.key]

            if config then
                local carnival_type = config.carnival_type

                if carnival_type == CARNIVAL_TYPE["tmp_achievement"] then
                    info.cur_value = v.new_value

                elseif carnival_type == CARNIVAL_TYPE["achievement_value"] then
                    info.cur_value = v.new_value

                elseif carnival_type == CARNIVAL_TYPE["multi_achievement"] then
                    for index, need_type in pairs(config.mult_num2) do
                        if v.need_type == need_type then
                            info.cur_value_multi[index] = v.new_value
                        end
                    end

                elseif carnival_type == CARNIVAL_TYPE["collect_item"] then
                    for index, item_id in pairs(config.mult_num1) do
                        if item_id == v.need_type then
                            info.collect_info[index] = v.new_value
                        end
                    end

                elseif carnival_type == CARNIVAL_TYPE["single_equal"] then
                    local cur_value = info.step_reward[v.need_type]

                    if config.need_type == ACHIEVEMENT_TYPE["maze"] then
                        info.step_reward[v.need_type] = v.new_value
                        info.step_flag[v.need_type] = 1

                    elseif cur_value > 10 then
                        info.step_reward[v.need_type] = cur_value - v.new_value
                        info.step_flag[v.need_type] = info.step_flag[v.need_type] + 1

                    elseif cur_value > 0 then
                        --todo  太恶心的代码
                        info.step_reward[v.need_type] = 1
                        info.step_flag[v.need_type] = 1
                    end

                elseif carnival_type == CARNIVAL_TYPE["time_limit_store"] then
                    if v.end_time then
                        config.end_time = v.end_time or 0
                        info.cur_value = v.new_value or info.cur_value
                        if config.end_time == 0 then
                            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                            graphic:DispatchEvent("update_sub_carnival_reward_status")
                        end
                    end

                elseif carnival_type == CARNIVAL_TYPE["vote"] then
                    info.cur_value_multi[1] = v.new_value

                elseif carnival_type == CARNIVAL_TYPE["fund"] then
                    info.cur_value = v.new_value
                end

                self:UpdateStageRewardMark(v.key, true)
            else
                print("config error = ", v.key)
            end
        end

        self:SetEntireRewardMark()
    end)

    network:RegisterEvent("take_carnival_reward_ret", function(recv_msg)
        print("take_carnival_reward_ret = ", recv_msg.result)

        if recv_msg.result == "success" then
            --领完奖励的则置为0
            local info = self.info_map[recv_msg.key]
            if info then
                if info.step_flag then
                    info.step_flag[recv_msg.step] = info.step_flag[recv_msg.step] <= 1 and 0 or info.step_flag[recv_msg.step] -1
                end

                if info.step_reward then
                    info.step_reward[recv_msg.step] = info.step_reward[recv_msg.step] <= 1 and 0 or info.step_reward[recv_msg.step] -1
                end
            end

            local config = self.all_config[recv_msg.key]
            if config and config.carnival_type == CARNIVAL_TYPE["first_payment"] then
                user_logic:SetPermanentMark(constants["PERMANENT_MARK"]["first_payment_reward"], true)
            end

            self:UpdateStageRewardMark(recv_msg.key, true)
            self:SetEntireRewardMark()

            if config and recv_msg.exchange_id and config.carnival_type == CARNIVAL_TYPE["mercenary_exchange"] then
                info.exchange_record = info.exchange_record or {}
                info.exchange_record[recv_msg.exchange_id] = (info.exchange_record[recv_msg.exchange_id] or 0) + 1

                troop_logic:UpdateSoulStone(recv_msg.exchange_mercenary_id, -recv_msg.exchange_soul_stone_num)
            end

            graphic:DispatchEvent("update_sub_carnival_reward_status", recv_msg.key, recv_msg.step, recv_msg.exchange_id)
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            graphic:DispatchEvent("show_prompt_panel", REWAED_PROMPT[recv_msg.result])
        end
    end)

    network:RegisterEvent("take_reward_by_cdkey_ret", function(recv_msg)
        print("take_reward_by_cdkey_ret = ", recv_msg.result)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            graphic:DispatchEvent("show_prompt_panel",CDKEY_PROMPT[recv_msg.result])
        end
    end)

    --获取全服数据
    network:RegisterEvent("query_carnival_union_data_ret", function(recv_msg)
        for i, v in pairs(self.config_list) do
            if not v.order_ids then v.order_ids = {} end
            if v.key == recv_msg.key then
                for k = 1, #recv_msg.ids do
                    v.order_ids[k] = recv_msg.ids[k]
                end
            end
        end

        graphic:DispatchEvent("update_carnival_union_data", recv_msg.ids, recv_msg.num)
    end)

    --投票返回数据
    network:RegisterEvent("vote_carnival_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local vote_info = self.info_map[recv_msg.key]

            local last_status = vote_info.cur_value_multi[3]
            vote_info.cur_value_multi = recv_msg.cur_value_multi

            local show_reward_panel = false

            if last_status == 0 then
                show_reward_panel = true
            end

            local my_vote_num = vote_info.cur_value_multi[2]
            local step_reward = vote_info.step_reward

            local config = self.all_config[recv_msg.key]
            for i = 1, #config.mult_num2 do
                local reward_state = step_reward[i]
                if reward_state > 0 then
                    if my_vote_num >= config.mult_num2[i] then
                        step_reward[i] = reward_state - 1
                        show_reward_panel = true
                    else
                        break
                    end
                end
            end

            if show_reward_panel then
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            end

            graphic:DispatchEvent("show_prompt_panel", "carnival_vote_success")
            graphic:DispatchEvent("carnival_vote")
        end
    end)

    --抢红包
    network:RegisterEvent("take_lottery_reward_ret", function(recv_msg)
        --print("get_lottery_reward_ret = ", recv_msg.result)
        local play_animation_flag = true
        if recv_msg.result == "success" then
          if self.stages_reward_mark[recv_msg.key][1] <= 0 then
             play_animation_flag = false
          end

          local get_value
          if not recv_msg.bd_num then
              get_value = 0
          else
              get_value = recv_msg.bd_num
          end

          if not recv_msg.log then
             recv_msg.log = {}
          end

          self.stages_reward_mark[recv_msg.key][1] = 0
          graphic:DispatchEvent("update_lottery_panel", get_value, recv_msg.log, play_animation_flag)

        end
    end)

    --佣兵进化
    network:RegisterEvent("take_evolution_ret", function(recv_msg)
        print("take_evolution_ret = ", recv_msg.result)
        if recv_msg.result == "success" then
            --解雇
            local mercenary_list = troop_logic:GetMercenaryList()
            for i = 1, #recv_msg.mercenary_id_list do
                local instance_id = recv_msg.mercenary_id_list[i]
                if mercenary_list[instance_id] then
                    mercenary_list[instance_id] = nil
                end
            end

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("mercenary_evolution_success", recv_msg.formula_id)

        else
            graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_not_enough2")
        end
    end)

    network:RegisterEvent("take_fund_profit_ret", function(recv_msg)
        print("take_fund_profit_ret = ", recv_msg.result)
        local result = recv_msg.result

        if result == "success" then
            local info = self.info_map[recv_msg.key]
            local config = self.all_config[recv_msg.key]

            local step = recv_msg.step

            local fund_type = config.mult_num1[recv_msg.step]
            local fund_conf = config_manager.fund_config[fund_type]

            if info.cur_value_multi[step] == 0 then
                info.step_reward[step] = fund_conf.profit_duration - 1
                info.cur_value = info.cur_value - config.mult_num2[step]

            else
                local t1 = os.date("*t", time_logic:Now())
                local t2 = os.date("*t", info.cur_value_multi[step])
                day = tonumber(t1.yday) - tonumber(t2.yday)
                info.step_reward[step] = info.step_reward[step] - day
            end

            info.cur_value_multi[step] = time_logic:Now()
            self:UpdateStageRewardMark(recv_msg.key, true)
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("update_sub_carnival_reward_status", recv_msg.key, recv_msg.step)

        elseif result == "not_enough_credit" then
            graphic:DispatchEvent("show_prompt_panel","not_enough_credit")

        elseif result == "out_of_date" then
            graphic:DispatchEvent("show_prompt_panel", "buy_fund_out_of_date")

        elseif result == "already_taken" then
            graphic:DispatchEvent("show_prompt_panel", "already_taken_the_reward")

        elseif result == "not_enough_blood_diamond" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])
        end
    end)

    --FYD5 sns邀请事件回调
    network:RegisterEvent("query_sns_invitee_progress_ret", function(recv_msg)
        local create_leader_state = platform_manager:GetChannelInfo().is_create_leader_state 

        if create_leader_state then   --如果是创建角色，那么不需要显示分享面板
            platform_manager:GetChannelInfo().is_create_leader_state = nil
            return 
        end   
        local json = require "util.json"
        print("query_sns_invitee_progress_ret", json:encode(recv_msg))
        if recv_msg.result == "success" then
            local info = self.info_map[recv_msg.key]
            local config = self.all_config[recv_msg.key]

            info.cur_value_multi = recv_msg.cur_value_multi
            self:UpdateStageRewardMark(recv_msg.key)
            graphic:DispatchEvent("show_world_sub_scene", "sns_sub_scene")

        else
            graphic:DispatchEvent("show_world_sub_scene", "sns_sub_scene")
        
        end
    end)
    --FYD6邀请奖励领取回调
    network:RegisterEvent("take_sns_invitation_reward_ret", function(recv_msg)
        print("take_sns_invitation_reward_ret", recv_msg.result)

        if recv_msg.result == "success" then
            local info = self.info_map[recv_msg.key]
            info.step_reward[recv_msg.step] = info.step_reward[recv_msg.step] <= 1 and 0 or info.step_reward[recv_msg.step] -1

            self:UpdateStageRewardMark(recv_msg.key)

            graphic:DispatchEvent("update_sns_panel")
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        else
            graphic:DispatchEvent("show_prompt_panel", REWAED_PROMPT[recv_msg.result])
        end
    end)
end

return carnival
