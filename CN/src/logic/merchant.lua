local network = require "util.network"
local graphic = require "logic.graphic"
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local merchant_ref_config = config_manager.merchant_ref_config

local time_logic
local resource_logic
local reward_logic

local DARK_MERCHANT1 = constants.MERCHANT_TYPE["dark1"]
local DARK_MERCHANT2 = constants.MERCHANT_TYPE["dark2"]
local DARK_MERCHANT3 = constants.MERCHANT_TYPE["dark3"]


local DARK_MERCHANT = constants.MERCHANT_TYPE["DARK"]
local WHITE_MERCHANT = constants.MERCHANT_TYPE["WHITE"]

local merchant = {}

function merchant:Init()
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"
    reward_logic = require "logic.reward"
    self.merchant_order_info = {}
    self.has_queried = false

    self.orders = {[DARK_MERCHANT] = {}, [WHITE_MERCHANT] = {}}
    self.order_num = {[DARK_MERCHANT] = 0, [WHITE_MERCHANT] = 0}

    self.reset_time = 0

    self.extra_soul_chip_num = 0
    self.has_collected_soul_chip = false

    self.buy_refresh_times = 0
    self.drak_merchant_refresh_time = 0

    self:RegisterMsgHandler()
end

function merchant:LoadInfo(recv_msg)
    self.has_collected_soul_chip = recv_msg.ext_soul_chip_flag

    self.can_collect_soul_chip = not self.has_collected_soul_chip

    self.chest_key_id = recv_msg.chest_key_id
    self.chest_key_num = recv_msg.chest_key_num
    self.extra_soul_chip_num = recv_msg.ext_soul_chip
    self.buy_refresh_times = recv_msg.buy_refresh_times

    self.drak_merchant_refresh_time = recv_msg.drak_merchant_refresh_time
    self.reset_time = recv_msg.reset_time

    local n1, n2 = 0, 0

    table.sort(recv_msg.order_list, function(a, b) return a.order_id < b.order_id end)
    for i, order_info in ipairs(recv_msg.order_list) do
        if order_info.merchant_type == WHITE_MERCHANT then
            n1 = n1 + 1
            self.orders[WHITE_MERCHANT][n1] = order_info
        elseif order_info.merchant_type == DARK_MERCHANT then -- 老的黑市
            n2 = n2 + 1
            self.orders[DARK_MERCHANT][n2] = order_info
            self.can_collect_soul_chip = self.can_collect_soul_chip and order_info.is_done

        elseif order_info.merchant_type == DARK_MERCHANT1 then --黑市 第一栏任务
            self.orders[DARK_MERCHANT][1] = order_info
            self.can_collect_soul_chip = self.can_collect_soul_chip and order_info.is_done
        elseif order_info.merchant_type == DARK_MERCHANT2 then  -- 二
            self.orders[DARK_MERCHANT][2] = order_info      
            self.can_collect_soul_chip = self.can_collect_soul_chip and order_info.is_done
        elseif order_info.merchant_type == DARK_MERCHANT3 then  -- 三
            self.orders[DARK_MERCHANT][3] = order_info
            self.can_collect_soul_chip = self.can_collect_soul_chip and order_info.is_done
        end

        table.insert(self.merchant_order_info, order_info)
    end

    self.order_num[DARK_MERCHANT] = #self.orders[DARK_MERCHANT]
    self.order_num[WHITE_MERCHANT] = #self.orders[WHITE_MERCHANT]
end

function merchant:GetOrderNum(merchant_type)
    return self.order_num[merchant_type]
end

function merchant:GetOrderInfo(i, merchant_type)
    return self.orders[merchant_type][i]
end

function merchant:GetResetTime(merchant_type)
    return self.reset_time
end

--请求
function merchant:Query()
    if time_logic:Now() > self.reset_time then
        network:Send( { query_merchant = { } })
    else
        graphic:DispatchEvent("show_world_sub_scene", "merchant_sub_scene")
    end
end

--交易
function merchant:Exchange(order_id, merchant_type,cost_info)
    if #cost_info > 0 then
        for k,v in pairs(cost_info) do
            if not resource_logic:CheckResourceNum(v.resourceId, v.costNum, true) then
                return
            end
        end
    end
    network:Send({merchant_exchange = {merchant_type = merchant_type, order_id = order_id} })
end

function merchant:IsExchange(order_id, merchant_type)
    for i = 1, self.order_num[merchant_type] do
        if self.orders[merchant_type][i].order_id == order_id then
            if self.orders[merchant_type][i].is_done then
                graphic:DispatchEvent("show_prompt_panel", "merchant_order_is_already_finish")
                return
            end
            return true
        end
    end
    return false
end

--获取额外奖励
function merchant:CollectSoulChip()
    if not self.can_collect_soul_chip then
        graphic:DispatchEvent("show_prompt_panel", "merchant_finish_all_order_first")
        return
    end

    network:Send({ merchant_soul_chip = {} })
end

--是否可以获取额外奖励
function merchant:CanCollectSoulChip()
    return self.can_collect_soul_chip
end

function merchant:GetResetPrice(merchant_type)
    --TAG:MASTER_MERGE
    if feature_config:IsFeatureOpen("merchant_refresh_limit") then
        local cost_config_index = #merchant_ref_config
        if merchant_type == constants.MERCHANT_TYPE["WHITE"] then  --神秘商店
            cost_config_index = self.buy_refresh_times + 1
        else
            cost_config_index = self.drak_merchant_refresh_time + 1
        end

        if merchant_ref_config[cost_config_index] then
            price = merchant_ref_config[cost_config_index]["group_id"]
        else
            price = merchant_ref_config[#merchant_ref_config]["group_id"]
        end
    else
        price = constants["MERCHANT_WHITE_FIXED_PRICE"]
    end

    return price
end

--重置订单
function merchant:Reset(merchant_type)
    local price = self:GetResetPrice(merchant_type)

    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], price, true) then
        return 
    end
    
    network:Send( { merchant_reset = { merchant_type = merchant_type  } })
end

function merchant:RegisterMsgHandler()

    network:RegisterEvent("query_merchant_ret", function(recv_msg)
        if not recv_msg.order_list then
            self.order_num[DARK_MERCHANT] = 0
            self.order_num[WHITE_MERCHANT] = 0
            return
        end

        self:LoadInfo(recv_msg)

        graphic:DispatchEvent("show_world_sub_scene", "merchant_sub_scene")
    end)

    network:RegisterEvent("merchant_exchange_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local merchant_type = recv_msg.merchant_type

            local found = false
            self.can_collect_soul_chip = not self.has_collected_soul_chip

            if merchant_type == DARK_MERCHANT1 or merchant_type == DARK_MERCHANT2 or merchant_type == DARK_MERCHANT3 then
                merchant_type = DARK_MERCHANT
            end

            for i = 1, self.order_num[merchant_type] do
                if self.orders[merchant_type][i].order_id == recv_msg.order_id then
                    self.orders[merchant_type][i].is_done = true
                    found = true
                end
                if merchant_type == DARK_MERCHANT then 
                   self.can_collect_soul_chip = self.can_collect_soul_chip and self.orders[DARK_MERCHANT][i].is_done
                end
            end

            if found then
                graphic:DispatchEvent("update_merchant_info", "order", recv_msg.order_id, merchant_type)
            end

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")

        elseif recv_msg.result == "not_enough_resource" then

        end
    end)

    network:RegisterEvent("merchant_soul_chip_ret", function(recv_msg)
        --成功领取额外奖励
        if recv_msg.result == "success" then
            self.has_collected_soul_chip = true
            self.can_collect_soul_chip = false

            if recv_msg.chest_key_id then
                self.chest_key_id = recv_msg.chest_key_id
                self.chest_key_num = recv_msg.chest_key_num
            end

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("update_merchant_info", "extra")

        elseif recv_msg.result == "order_not_finish" then
            graphic:DispatchEvent("show_prompt_panel", "merchant_finish_all_order_first")
        end
    end)

    network:RegisterEvent("merchant_reset_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self:LoadInfo(recv_msg)
            graphic:DispatchEvent("update_merchant_info", "all")
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])
        elseif recv_msg.result == "not_enough_all_num" then
            graphic:DispatchEvent("show_prompt_panel", "quick_battle_not_enough_all_num")
        end
    end)
end

return merchant
