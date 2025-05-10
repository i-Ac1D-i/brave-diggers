local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"

local PRODUCT_TYPE = constants.PAYMENT_PRODUCT_TYPE

local user_logic
local time_logic
local resource_logic
local troop_logic
local arena_logic
local payment_logic

local vip = {}

function vip:Init()
    user_logic =  require "logic.user"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"
    troop_logic = require "logic.troop"
    arena_logic = require "logic.arena"
    payment_logic = require "logic.payment"

    self.vip_list = {}

    --初始化
    for k, v in pairs(constants.VIP_TYPE_NAME) do
        self.vip_list[k] = {}
        self.vip_list[k].end_time = 0
        self.vip_list[k].reward_mark = 0
    end

    self:RegisterMsgHandler()
end

function vip:GetVipList()
    return self.vip_list
end

function vip:GetVipInfo(vip_type)
    return self.vip_list[vip_type]
end

function vip:IsActivated(vip_type)
    local vip_info = self.vip_list[vip_type]

    if not vip_info then
        return false
    end

    return vip_info.end_time >= time_logic:Now()
end

function vip:VipStatus(vip_type)

    local vip_info = self.vip_list[vip_type]
    if not vip_info then
        return false
    end

    if vip_info.reward_mark == constants.VIP_STATE["daily_reward"] then
        return false
    else
        return true
    end
end

function vip:GetRewardDay(vip_type)
    local vip_info = self.vip_list[vip_type]
    local cur_day = math.floor(vip_info.end_time / 86400) - math.floor(time_logic:Now() / 86400)

    if cur_day < 0 then
        cur_day = 0
    end

    return cur_day
end

--购买vip ticket
function vip:BuyVip(vip_type)
    local cur_time = time_logic:Now()
    local vip_info = self.vip_list[vip_type]
    if vip_info.reward_mark ~= constants.VIP_STATE["unbuy"] and cur_time < vip_info.end_time then
        graphic:DispatchEvent("show_prompt_panel", "already_bought_vip")
        return
    end

    if vip_type == constants.VIP_TYPE["adventure"] then
        local product_info = payment_logic:GetVipProduct(constants.PAYMENT_PRODUCT_TYPE["adventure_vip"])
        payment_logic:TryBuy(product_info)
    end
end

function vip:TakeReward(vip_type)

    local vip_info = self.vip_list[vip_type]
    if vip_info.reward_mark == constants.VIP_STATE["unbuy"] then
        graphic:DispatchEvent("show_prompt_panel","not_buy_vip")
        return
    end

    if vip_info.reward_mark == constants.VIP_STATE["daily_reward"] then
        graphic:DispatchEvent("show_prompt_panel", "already_taken_the_reward")
        return
    end

    local cur_time = time_logic:Now()
    if cur_time > vip_info.end_time then
        graphic:DispatchEvent("show_prompt_panel", "vip_out_of_date")
        return
    end

    network:Send({take_vip_reward = {vip_type = vip_type}} )
end

--激活冒险月卡
function vip:ActivateAdventurer(duration)
    if not duration then
        duration = 30 * 86400
    end
    local vip_info = self.vip_list[constants.VIP_TYPE["adventure"]]
    local now = time_logic:Now()
    if vip_info.end_time and vip_info.end_time < now then
        vip_info.end_time = now + duration
        vip_info.reward_mark = constants.VIP_STATE["buy"]

        troop_logic:SetCampCapacity(troop_logic:GetCampCapacity() + constants.VIP_PRIVILEGE["add_camp_capacity"])
        arena_logic:AddChallengeNum(2)
    else
        vip_info.end_time = vip_info.end_time + duration
    end

    graphic:DispatchEvent("buy_vip_success")
    graphic:DispatchEvent("refresh_quick_battle")
end

function vip:GetMonthCardPrice()
    return payment_logic:GetProductInfo(100).price
end

function vip:RegisterMsgHandler()

    network:RegisterEvent("query_vip_ret", function(recv_msg)
        print("query_vip_ret")

        if not recv_msg.vip_list then
            return
        end

        for k, v in pairs(recv_msg.vip_list) do
            self.vip_list[k].end_time = v.end_time
            self.vip_list[k].reward_mark = v.reward_mark
        end
    end)

    network:RegisterEvent("buy_vip_ret", function(recv_msg)
        print("buy_vip_ret = ", recv_msg.result)
        if recv_msg.result == "success" then
            self:ActivateAdventurer()

        end
    end)

    network:RegisterEvent("take_vip_reward_ret", function(recv_msg)
        print("take_vip_reward_ret = ", recv_msg.result)
        if recv_msg.result == "success" then

            self.vip_list[recv_msg.vip_type].reward_mark = constants.VIP_STATE["daily_reward"]
            graphic:DispatchEvent("take_vip_reward_success")

        end
    end)

end

return vip
