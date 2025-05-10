local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local resource_logic

local STORE_GOODS_TYPE = constants["STORE_GOODS_TYPE"]

local store = {}

function store:Init()
    resource_logic = require "logic.resource"

    self.goods_list = {}
    self.goods_num = 0
    self.time_stamp = 0

    self:RegisterMsgHandler()
end

local STORE_GOODS_TREND_PRICE = {
    [STORE_GOODS_TYPE["camp_capacity"]] = function(goods_info, num)
        local already_buy_count = goods_info.already_buy_count
        local buy_num = already_buy_count + num

        local total_price = 0
        local cur_price = 0
        for cur_buy_count = already_buy_count + 1, buy_num do
            
            if cur_buy_count > 50 then
                cur_price = 800
            else
                local formula_a = math.ceil(cur_buy_count/5)
                local formula_b = 7*math.pow(formula_a,2)-12*formula_a+26
                cur_price = formula_b-(formula_b%10)
            end
            total_price = total_price + cur_price
        end

        return total_price
    end
}

function store:Query()
    network:Send({ query_store_info = { time_stamp = self.time_stamp } })
end

function store:QueryTrendPrice(goods_info, num)
    local price_method = STORE_GOODS_TREND_PRICE[goods_info.type]

    if price_method then
        return price_method(goods_info, num)
    else
        return goods_info.price * num
    end
end

--购买商品
function store:BuyGoods(index, num)
    local goods_info = self.goods_list[index]

    if not goods_info then
        return
    end

    if num <= 0 or num > 500 then
        return
    end

    local price = self:QueryTrendPrice(goods_info, num)
    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], price, true) then
        return
    end

    network:Send( {buy_store_goods = {goods_id = goods_info.id, num = num}} )
end

function store:GetGoodsNum()
    return self.goods_num
end

function store:GetGoodsInfo(index)
    return self.goods_list[index]
end

function store:GetGoodsInfoById(goods_id)
    for i, goods_info in ipairs(self.goods_list) do
        if goods_info.id == goods_id then
            return goods_info
        end
    end
end

function store:GetResourceGoodsIndex(resource_type)
    for i, goods_info in ipairs(self.goods_list) do
        if goods_info.type == STORE_GOODS_TYPE["resource"] and goods_info.data == resource_type then
            return i
        end
    end
end

function store:GetPickaxeGoodsIndex()
    for i, goods_info in ipairs(self.goods_list) do
        if goods_info.type == STORE_GOODS_TYPE["max_pickaxe_count"] then
            return i
        end
    end
end

function store:GetExploreGoodsIndex()
    for i, goods_info in ipairs(self.goods_list) do
        if goods_info.type == STORE_GOODS_TYPE["max_box_num"] then
            return i
        end
    end
end

function store:RegisterMsgHandler()
    network:RegisterEvent("query_store_info_ret", function(recv_msg)
        if recv_msg.time_stamp == self.time_stamp then
            --数据没有更新
            graphic:DispatchEvent("show_world_sub_scene", "store_sub_scene")

        else
            self.time_stamp = recv_msg.time_stamp
            if not recv_msg.goods_list then
                self.goods_num = 0
                return
            end

            self.goods_list = recv_msg.goods_list

            for i, goods_info in ipairs(self.goods_list) do
                if goods_info.type == STORE_GOODS_TYPE["resource"] then
                    local config = config_manager.resource_config[goods_info.data]
                    goods_info.name = config.name
                    goods_info.desc = config.desc
                    goods_info.icon = config.icon
                end
            end

            self.goods_num = #recv_msg.goods_list

            graphic:DispatchEvent("show_world_sub_scene", "store_sub_scene")
        end
    end)

    network:RegisterEvent("buy_store_goods_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local goods_info = self:GetGoodsInfoById(recv_msg.goods_id)
            if goods_info.already_buy_count then
                goods_info.already_buy_count = goods_info.already_buy_count + recv_msg.num
            end

            graphic:DispatchEvent("show_prompt_panel", "store_buy_success")
            graphic:DispatchEvent("store_buy_success", recv_msg.goods_id)        

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])

        elseif recv_msg.result == "not_enough_buy_count" then
            graphic:DispatchEvent("show_prompt_panel", "store_goods_not_count")

        elseif recv_msg.result == "not_sale" then
            graphic:DispatchEvent("show_prompt_panel", "store_goods_not_sale")
        end
    end)
end

return store

