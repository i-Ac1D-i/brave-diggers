local network = require "util.network"
local constants = require "util.constants"

local config_manager = require "logic.config_manager"

local REWARD_SOURCE = constants.REWARD_SOURCE
local REWARD_TYPE = constants.REWARD_TYPE

local user_logic
local resource_logic
local troop_logic
local destiny_logic
local mining_logic
local adventure_logic
local bag_logic
local carnival_logic
local rune_logic

local graphic = require "logic.graphic"

local reward = {}

function reward:Init()
    user_logic = require "logic.user"
    adventure_logic = require "logic.adventure"
    troop_logic = require "logic.troop"
    resource_logic = require "logic.resource"
    destiny_logic = require "logic.destiny_weapon"
    mining_logic = require "logic.mining"
    bag_logic = require "logic.bag"
    carnival_logic = require "logic.carnival"
    rune_logic = require "logic.rune"

    self.max_reward_num = 0

    self.reward_info_list = nil

    self.reward_info_list_head = nil
    self.reward_info_list_tail = nil

    self:RegisterMsgHandler()
end

function reward:GetRewardInfoList()
    return self.reward_info_list
end

function reward:PushRewardInfoList(source, reward_info_list)
    reward_info_list.source = source

    if self.reward_info_list_tail then
        self.reward_info_list_tail.next = reward_info_list
    else
        self.reward_info_list_tail = reward_info_list
        self.reward_info_list_head = reward_info_list
    end
end

function reward:PopRewardInfoList()
    local cur_reward_info_list = self.reward_info_list_head
    if self.reward_info_list_head then
        self.reward_info_list_head = self.reward_info_list_head.next
    end

    if not self.reward_info_list_tail.next then

    end

    return cur_reward_info_list
end

--客户端为了显示而虚拟奖励数据
function reward:AddRewardInfo(source, reward_info_list)
    reward_info_list.source = source
    self.reward_info_list = reward_info_list
end

function reward:RegisterMsgHandler()
    network:RegisterEvent("reward_info_list", function(recv_msg)
        local need_remove_reward = false
        local reward_index = 0

        for i, reward_info in ipairs(recv_msg.reward_info_list) do

            local reward_type = reward_info.id
            reward_info.reward_type = reward_type

            if reward_type == REWARD_TYPE["feature"] then
                user_logic:SetPermanentMark(reward_info.param1, true)

            elseif reward_type == REWARD_TYPE["resource"] then
                --资源
                update_resource = true
                resource_logic:UpdateResource(reward_info.param1, reward_info.param2)

            elseif reward_type == REWARD_TYPE["mercenary"] then
                --佣兵
                local mercenary = troop_logic:CreateMercenary(reward_info.param1, reward_info.param2, reward_info.param3)
                reward_info["mercenary_id"] = mercenary.instance_id

            elseif reward_type == REWARD_TYPE["item"] then
                --物品
                for i = 1, reward_info.param2 do
                    bag_logic:NewItem(reward_info.param1)
                end

            elseif reward_type == REWARD_TYPE["leader_bp"] then
                --主角战力
                troop_logic:SetLeaderBP(troop_logic.leader_bp + reward_info.param1)

            elseif reward_type == REWARD_TYPE["formation_capacity"] then
                --最大探索人数
                if troop_logic:GetFormationCapacity() <reward_info.param1 then
                    troop_logic:SetFormationCapacity(reward_info.param1)
                else
                    need_remove_reward = true
                    reward_index = i
                end

            elseif reward_type == REWARD_TYPE["destiny_weapon"] then
                --宿命武器
                destiny_logic:AddNewWeapon(reward_info.param1)

            elseif reward_type == REWARD_TYPE["pickaxe_count"] then
                --挖掘次数
                mining_logic:AddDigCount(reward_info.param1)

            elseif reward_type == REWARD_TYPE["maze"] or reward_type == REWARD_TYPE["area"] then
                adventure_logic:UnlockMaze(reward_info.param1, reward_type == REWARD_TYPE["area"])

            elseif reward_type == REWARD_TYPE["camp_capacity"] then
                --营帐容量
                troop_logic:SetCampCapacity(troop_logic:GetCampCapacity() + reward_info.param1)

            elseif reward_type == REWARD_TYPE["rune"] then
                rune_logic:NewRune(reward_info.param1, reward_info.param2, reward_info.param3, reward_info.param4)
            end
        end

        if need_remove_reward then
            table.remove(recv_msg.reward_info_list, reward_index)
        end

        self.reward_info_list = recv_msg.reward_info_list
        self.reward_info_list.source = recv_msg.source

        if update_resource then
            graphic:DispatchEvent("update_resource_list", recv_msg.source)
            resource_logic:ClearDirtyFlags()
        end
    end)
end

return reward
