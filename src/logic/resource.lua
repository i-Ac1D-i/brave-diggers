local network = require "util.network"
local config_manager = require "logic.config_manager"
local resource_config = config_manager.resource_config

local constants = require "util.constants"

local graphic = require "logic.graphic"
local reminder_logic = require "logic.reminder"
local user_logic
local mining_logic
local achievement_logic
local carnival_logic
local troop_logic
local social_logic

local RESOURCE_TYPE_NAME = constants.RESOURCE_TYPE_NAME
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local CONST_REWARD_SOURCE = constants.REWARD_SOURCE
local EXP_LIMIT = constants.EXP_LIMIT

local resource = {}

function resource:Init()
    user_logic = require "logic.user"
    mining_logic = require "logic.mining"
    achievement_logic = require "logic.achievement"
    carnival_logic = require "logic.carnival"
    troop_logic = require "logic.troop"
    social_logic = require "logic.social"

    self.resource_list = {}

    for k, v in pairs(constants["RESOURCE_TYPE"]) do
        self.resource_list[k] = 0
    end

    self.dirty_flags = {}

    self:RegisterMsgHandler()
end

function resource:IncreaseGoldCoinAndExp(increase_coin, increase_exp)
    self.resource_list["gold_coin"] = math.min(self.resource_list["gold_coin"] + increase_coin, EXP_LIMIT)
    self.resource_list["exp"] = math.min(self.resource_list["exp"] + increase_exp, EXP_LIMIT)

    self.dirty_flags["gold_coin"] = true
    self.dirty_flags["exp"] = true
end

function resource:GetResourceList()
    return self.resource_list
end

function resource:GetResourcenNumByName(name)
    return self.resource_list[name]
end

function resource:GetResourceNum(resource_type)
    local name = RESOURCE_TYPE_NAME[resource_type]
    return self.resource_list[name]
end

function resource:IsResourceUpdated(resource_type)
    local name = RESOURCE_TYPE_NAME[resource_type]
    return self.dirty_flags[name]
end

function resource:UpdateResource(resource_type, num)
    local name = RESOURCE_TYPE_NAME[resource_type]

    if num > 0 then
        if name == "soul_chip" then
            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["soul_chip"], num)

        elseif name == "friendship_pt" then
            social_logic:SetFriendshipPoint(num)
            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["friendship_pt"], num)
        end
    end

    self.resource_list[name] = self.resource_list[name] + num

    if resource_type == RESOURCE_TYPE["blood_diamond"] then
        user_logic:UpdateUserInfo(troop_logic.leader.wakeup, false)

    elseif constants["MINING_RESOURCE_TYPE"][resource_type] then
        mining_logic:UpdateFoundResourceType(resource_type)
    end

    self.dirty_flags[name] = true
end

function resource:ClearDirtyFlags()
    for k, v in pairs(self.dirty_flags) do
        self.dirty_flags[k] = false
    end
end

--检测资源是否充足
function resource:CheckResourceNum(resource_type, need_num, is_show_prompt)
    local resource_name = RESOURCE_TYPE_NAME[resource_type]
    if self.resource_list[resource_name] < need_num then
        if is_show_prompt then
            graphic:DispatchEvent("show_prompt_panel", "resource_specific_not_enough", resource_config[resource_type].name)
        end
        return false
   end

    return true
end

--显示缺少资源提示
function resource:ShowLackResourcePrompt(resource_type)
    if resource_type then
        graphic:DispatchEvent("show_prompt_panel", "resource_specific_not_enough", resource_config[resource_type].name)
    else
        graphic:DispatchEvent("show_prompt_panel", "resource_general_not_enough")
    end
end

function resource:RegisterMsgHandler()

    network:RegisterEvent("query_resource_list_ret", function(recv_msg)
        for k, v in pairs(recv_msg) do
            self.resource_list[k] = v
        end
    end)
    
    network:RegisterEvent("update_resource_list", function(recv_msg)

        self:ClearDirtyFlags()
        local old_blood_diamond = self.resource_list["blood_diamond"]
        for i, v in ipairs(recv_msg.update_resource_list) do
            --统计
            local cur_value = self.resource_list[v.resource_type]
            local update_value = v.resource_value
            local value = update_value - cur_value
            self:UpdateResource(RESOURCE_TYPE[v.resource_type], value)
        end

        --统计血钻消耗
        local diff = self.resource_list["blood_diamond"] - old_blood_diamond
        local source = recv_msg.source

        source = tostring(source)
        if source == CONST_REWARD_SOURCE["store"] then
                amount = recv_msg.sub_count
                price = price / amount

                source = source .. "_" .. recv_msg.sub_type
        else
                source = tostring(source)
        end
        
        if diff < 0 then

            if recv_msg.source ~= CONST_REWARD_SOURCE["fund"] then
                achievement_logic:UpdateStatisticValue(constants["ACHIEVEMENT_TYPE"]["all_consume"], -diff)
                user_logic:UpdateUserInfo(troop_logic.leader.wakeup, false)
                if TalkingDataGA and recv_msg.source ~= CONST_REWARD_SOURCE["store"] then
                    TDGAItem:onPurchase(source, 1, math.abs(diff))
                end
            end

            -- local amount = 1
            -- local price = -diff
            -- local source = recv_msg.source

            

           -- achievement_logic:UpdateStatisticValue(constants["ACHIEVEMENT_TYPE"]["all_consume"], -diff)

           -- user_logic:UpdateUserInfo(troop_logic.leader.wakeup, false)

            -- if TalkingDataGA then
            --     TDGAItem:onPurchase(source, 1, math.abs(diff))
            -- end

        elseif diff > 0 then
            if TalkingDataGA then
                TDGAVirtualCurrency:onReward(math.abs(diff), source)
            end
        end
        graphic:DispatchEvent("update_resource_list", recv_msg.source)
        -- 强化材料检测
        reminder_logic:CheckForgeReminder()

    end)
end

return resource
