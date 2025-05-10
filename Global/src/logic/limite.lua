local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local client_constants = require "util.client_constants"

local PRODUCT_TYPE = constants.PAYMENT_PRODUCT_TYPE
local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE
local CARNIVAL_TYPE = constants.CARNIVAL_TYPE

local user_logic
local time_logic
local resource_logic
local troop_logic
local arena_logic
local payment_logic

local limite = {}
local LIMITE_STATE = {
    CAN_BUY = 0, --可以购买
    BUYING = 1, --正在购买
    NO_SHOP = 2, --没有商品可以购买
}


function limite:Init()
    user_logic =  require "logic.user"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"
    troop_logic = require "logic.troop"
    arena_logic = require "logic.arena"
    payment_logic = require "logic.payment"

    self.limites = nil --这里的5测试，要用配置记住了

    self.over_time = 0

    self.is_come_in = 0 --是否打开过这个界面

    self.show_index = 1

    self.limite_state = LIMITE_STATE.CAN_BUY --购买状态
 
    self.config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["limite_package"], CARNIVAL_TYPE["limite_package"])

    self:RegisterMsgHandler()
end

function limite:GetLimites()
    -- body
    if self.limites == nil or #self.limites <= 0 then
        self.limites = payment_logic:GetProductsInfoByType(5) --这里的5测试，要用配置记住了 
    end

    return #self.limites
end

--得到当前的礼包
function limite:GetNowLimite()
    -- body
    if self:GetLimites() > 0 then
        for k,limite in pairs(self.limites) do
            if k == self.show_index then
                return limite
            end
        end
    else
        self.limites = payment_logic:GetProductsInfoByType(5) --这里的5测试，要用配置记住了 
        for k,limite in pairs(self.limites) do
            if k == self.show_index then
                return limite
            end
        end
    end
    return {}

end

function limite:GetBuyIndex()
    return self.show_index
end

function limite:GetLimiteState()
    return self.limite_state
end

--得到结束时间
function limite:GetOverTime()
    if self.config == nil then
       self.config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["limite_package"], CARNIVAL_TYPE["limite_package"]) 
    end
    if self.config then
        self.overTime = self.config.end_time
        return self.overTime
    end
    return 
end

function limite:GetConfig()
    if self.config == nil then
       self.config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["limite_package"], CARNIVAL_TYPE["limite_package"]) 
    end
    return self.config
end

--当前礼包原价
function limite:GetOldPrice()
    if self.config.mult_num1 then
        return self.config.mult_num1[self.show_index] or 0
    end
    return 0
end

--当前礼包现价
function limite:GetNowPrice()
    if self.config.mult_num2 then
        return self.config.mult_num2[self.show_index] or 0
    end
    return 0
end

--买礼包
function limite:BuyLimite()
    if self.limite_state == LIMITE_STATE.CAN_BUY then
        self.limite_state = LIMITE_STATE.BUYING
        local productInfo =  self:GetNowLimite()
        payment_logic:TryBuy(productInfo)
    end
end

--设置来过这个界面了
function limite:SetComeHere(comeState)
    network:Send({ update_limite_package_info = {key = self:GetConfig().key,is_come_in = 1} })
end

--
function limite:IsCanShow()
   local t = math.max(self.over_time - time_logic:Now(),0) 
   -- print("剩余时间："..t)
   if t > 0 then
        return true
   end 
    return false
end


function limite:RegisterMsgHandler()

    network:RegisterEvent("buy_limite_package_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.limite_state = LIMITE_STATE.CAN_BUY

            self.show_index = recv_msg.show_index or 1--下次下标
            -- self.is_come_in = recv_msg.is_come_in or 0
            self.over_time = recv_msg.over_time or 0
            -- self.next_show_time = recv_msg.next_show_time

            -- self.canShow = false --买完一个后不用马上显示

            graphic:DispatchEvent("update_limite_state")
            graphic:DispatchEvent("buy_limite_success")
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
        end

    end)

    network:RegisterEvent("query_limite_package_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.show_index = recv_msg.show_index --下次下标
            self.over_time = recv_msg.over_time
            self.is_come_in = recv_msg.is_come_in

            graphic:DispatchEvent("update_limite_state")
        end

    end)

    network:RegisterEvent("update_limite_package_info_ret", function(recv_msg)
        if recv_msg.is_come_in then
            self.is_come_in = recv_msg.is_come_in
        end

        if recv_msg.show_index then
            self.show_index = recv_msg.show_index
        end

        if recv_msg.over_time then
            self.over_time = recv_msg.over_time
        end

        graphic:DispatchEvent("update_limite_state")
    end)

end

return limite
