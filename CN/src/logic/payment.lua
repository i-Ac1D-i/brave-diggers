local graphic = require "logic.graphic"
local network = require "util.network"
local platform_manager = require "logic.platform_manager"
local constants = require "util.constants"
local bit_extension = require "util.bit_extension"
local json = require "util.json"
local configuration = require "util.configuration"
local analytics_manager = require "logic.analytics_manager"
local login_logic = require("logic.login")
local feature_config = require "logic.feature_config"
local lang_constants = require "util.language_constants"
local PRODUCT_TYPE = constants.PAYMENT_PRODUCT_TYPE

local vip_logic
local achievement_logic
local time_logic
local carnival_logic

local PAYMENT_STAUTS =
{
    ["purchase_not_available"] = 0,
    ["recv_product_list"] = 1,
    ["product_list_empty"] = 2,
    ["purchase_start"] = 3,
    ["purchase_success"] = 4,
    ["purchase_error"] = 5,
    ["purchase_canceled"] = 6,
    ["purchase_retstored"] = 7,
    ["purchase_error_uid"] = 8,
}

local payment = {}

function payment:Init(user_id)

    vip_logic = require "logic.vip"
    achievement_logic = require "logic.achievement"
    time_logic = require "logic.time"
    carnival_logic = require "logic.carnival"

    self.user_id = user_id

    self.channel = platform_manager:GetChannelInfo()
    -- 血钻列表
    self.products_list = {}

    self.raw_products = ""
    -- 支付平台 (appstore, wechat, alipay)
    self.purchase_platform = nil

    -- 购买记录
    self.purchased_mark = 0

    -- 购买数量
    self.quantity = 1

    self.enable_pay = self.channel.enable_pay

    if self.channel.enable_appstore_pay then
        self.purchase_platform = "appstore"
    end

    self.try_check_order_time = 0

    platform_manager:RegisterEvent("payment_result", function(status, arg1, arg2, arg3, arg4)
        print("payment ", status)

        if status == PAYMENT_STAUTS["purchase_not_available"] then
            graphic:DispatchEvent("show_prompt_panel", "payment_purchase_not_available")

        elseif status == PAYMENT_STAUTS["product_list_empty"] then
            graphic:DispatchEvent("show_prompt_panel", "payment_product_list_empty")

        elseif status == PAYMENT_STAUTS["recv_product_list"] then
            PlatformSDK.removeTransactionObserver()
            PlatformSDK.addTransactionObserver()

            local list = {}
            local str = arg1
            for app_purchase_name, price in string.gmatch(str, "([^,^|]+),([^,^|]+)") do
                list[app_purchase_name] = price
            end

            for i, product in ipairs(self.products_list) do
                local real_price = tonumber(list[product.app_purchase_name])
                if real_price and real_price > 0 then
                    local price = product.price
                    product.price = real_price
                    product.real_price = price
                    product.on_sale = true
                end
            end

            -- 刷新面板
            graphic:DispatchEvent("update_payment_panel")

        elseif status == PAYMENT_STAUTS["purchase_success"] then

            if self.purchase_platform == "appstore" or self.channel.enable_appstore_pay then
                -- appstore 验证回执
                for i, product in ipairs(self.products_list) do
                    if product.app_purchase_name == arg3 then
                        self.product_id = product.product_id
                        network:Send({ finish_apple_order = { trade_no = arg1, receipt = arg2, product_id = product.product_id, quantity = arg4 } } )
                        break
                    end
                end

            elseif self.purchase_platform == "google" or self.channel.enable_google_pay then
                -- google 验证签名
                local purchase_data = json:decode(arg1)
                -- 返回的数据信息
                local original_json = purchase_data.mOriginalJson
                -- 签名
                local signature = purchase_data.mSignature

                local order_info = json:decode(original_json)
                local order_id = order_info.orderId
                local product_id = order_info.productId

                local dev_info = json:decode(order_info.developerPayload)
                if dev_info.user_id ~= self.user_id then
                    graphic:DispatchEvent("show_prompt_panel", "payment_uid_error", dev_info.user_id or "")
                    return
                end

                network:Send({ finish_google_order = { original_json = original_json, signature = signature} } )
            else
                -- 通知服务器
                if self.try_check_order_time ~= 0 then
                    return
                end

                graphic:DispatchEvent("finish_purchase")
                if self.channel.delay_check_order_time and self.channel.delay_check_order_time > 0 then
                    --益玩延时发包
                    graphic:DispatchEvent("show_prompt_panel", "payment_check_order_in_progress")
                    self.try_check_order_time = time_logic:Now() + self.channel.delay_check_order_time
                else
                    self:CheckOrder()
                end
            end

        elseif status == PAYMENT_STAUTS["purchase_error"] then
            if self.purchase_platform == "appstore" or self.channel.enable_appstore_pay or self.purchase_platform == "google" then
                graphic:DispatchEvent("finish_waiting", "canceled")

            else
                --通知服务器支付失败
                graphic:DispatchEvent("finish_purchase")
                self:CheckOrder()
            end

        elseif status == PAYMENT_STAUTS["purchase_canceled"] then
            if self.purchase_platform == "appstore" or self.channel.enable_appstore_pay then
                graphic:DispatchEvent("finish_waiting", "canceled")

            elseif self.purchase_platform == "google" then
                graphic:DispatchEvent("finish_waiting", "canceled")

            else
                print("close_payment_order")
                --通知服务器支付取消
                graphic:DispatchEvent("finish_purchase")
                self:CheckOrder()
            end

        elseif status == PAYMENT_STAUTS["purchase_error_uid"] then
            graphic:DispatchEvent("finish_waiting", "finished")
            graphic:DispatchEvent("show_prompt_panel", "payment_uid_error", arg1 or "")
        end
    end)

    self:RegisterEvent()
end

function payment:Update(elapsed_time)
    if self.try_check_order_time ~= 0 and time_logic:Now() > self.try_check_order_time then
        self.try_check_order_time = 0
        graphic:DispatchEvent("finish_purchase")
        if not self.channel.enable_payment_callback then
            network:Send({ check_payment_order = {} })
        end
    end
end

function payment:GetProductInfo(product_id)
    for _, product in ipairs(self.products_list) do
        if product.product_id == product_id then
            return product
        end
    end
end

function payment:GetVipProduct(product_type)
    for _, product in ipairs(self.products_list) do
        if product.type == product_type then
            return product
        end
    end
end

--根据类型得到充值产品
function payment:GetProductsInfoByType(product_type)
    local products = {}
    for _, product in ipairs(self.products_list) do
        print("product.type = "..product.type.." product.id = "..product.product_id)
        if product.type == product_type then
            table.insert(products,product) 
        end
    end

    return products
end

-- 血钻购买记录
function payment:GetPurchasedMark(product_id)
    return bit_extension:GetBitNum(self.purchased_mark, product_id - 1)
end

function payment:SetPurchasedMark(product_id)
    self.purchased_mark = bit_extension:SetBitNum(self.purchased_mark, product_id - 1, true)
end

function payment:TryBuy(product_info)
    if platform_manager:IsGuestMode() and not _G["AUTH_MODE"] then
        graphic:DispatchEvent("show_prompt_panel", "account_cant_buy_before_bind")
        graphic:DispatchEvent("show_world_sub_panel", "account_bind_panel")
        return
    end

    if self.try_check_order_time ~= 0 then
        graphic:DispatchEvent("show_prompt_panel", "payment_check_order_in_progress")
    end

    local channel_info = platform_manager:GetChannelInfo()

    if #channel_info.pay == 1 then
        self:Buy(product_info.app_purchase_name, product_info.product_id, channel_info.pay[1])

    elseif #channel_info.pay == 2 and channel_info.meta_channel ~= "shouyou" then
        -- 选择微信或支付宝
        graphic:DispatchEvent("show_world_sub_panel", "payment_msgbox_panel", product_info.product_id, product_info.price, product_info.name)
    elseif channel_info.meta_channel == "shouyou" then
        if feature_config:IsFeatureOpen("third_party_payment") then
            -- 第三方支付 支付宝
            graphic:DispatchEvent("show_world_sub_panel", "payment_msgbox_panel", product_info.product_id, product_info.price, product_info.name, channel_info.pay[2])
        else
            self:Buy(product_info.app_purchase_name, product_info.product_id, channel_info.pay[1])
        end
    end
end

-- 开始购买
function payment:Buy(product_name, product_id, purchase_platform)

    local channel_info = platform_manager:GetChannelInfo()
    if not channel_info.enable_pay then
        return
    end

    -- 当前有处理中的订单
    self.purchase_platform = purchase_platform
    self.product_id = product_id
    self.quantity = 1

    if self.purchase_platform == "appstore" then
        graphic:DispatchEvent("start_waiting")

        local platform = platform_manager:GetPayPlatformType(self.purchase_platform)
        local success = PlatformSDK.buyProduct(platform, self.quantity, product_name, self.user_id)
        if type(success) ~= "nil" and not success then
            graphic:DispatchEvent("finish_waiting", "finished")
            graphic:DispatchEvent("show_prompt_panel", "payment_new_app_order_failure")
        end

    elseif self.purchase_platform == "google" then
        graphic:DispatchEvent("start_waiting")
        local platform = platform_manager:GetPayPlatformType(self.purchase_platform)

        local dev_info = {product_id = product_id, channel = self.channel.name, user_id = self.user_id }
        local order_info = { product_name = product_name, dev_info = json:encode(dev_info) }
        PlatformSDK.buyProduct(platform, self.quantity, json:encode(order_info))

    else
        -- 服务端下单
        network:Send({ new_payment_order = { platform = self.purchase_platform, product_id = self.product_id, quantity = self.quantity, channel = channel_info.name } })
    end

    self.is_buying = true
end

function payment:CanQuery()
    return self.enable_pay
end

function payment:CheckOrder()
    if not self.channel.enable_payment_callback then
        network:Send({ check_payment_order = {} })
    end
end

function payment:CancelOrder()
    if not self.channel.enable_payment_callback then
        network:Send({ close_payment_order = {} })
    end
end

function payment:BuySuccess(recv_msg)
    local product_id = recv_msg.product_id or self.product_id
    local product = self:GetProductInfo(product_id)

    if not product then
        return
    end

    if product.gift > 0 then
        self:SetPurchasedMark(product_id)
    end

    if product.type == PRODUCT_TYPE["adventure_vip"] then
        local extern = product.gift2 or 0
        vip_logic:ActivateAdventurer(nil,extern) 
    else
        graphic:DispatchEvent("update_payment_panel")
    end

    if self.purchase_platform == "appstore" or self.purchase_platform == "google" then
        graphic:DispatchEvent("finish_waiting", "finished")
    end

    graphic:DispatchEvent("show_prompt_panel", "payment_finish_order_success")

    --更新运营活动数据
    local price = product.real_price or product.price

    local platform = platform_manager:GetPayPlatformType(self.purchase_platform) or -1

    local app_purchase_name = product.product_id
    if self.purchase_platform == "appstore" or self.purchase_platform == "google" then
        app_purchase_name = product.app_purchase_name
    end

    local event = { "user_id", self.user_id,
                    "trade_no", recv_msg.trade_no,
                    "platform", self.purchase_platform,
                    "price", tostring(price),
                    "product_name", product.name,
                    "currency_type", self.channel.currency_type, "app_purchase_name", tostring(app_purchase_name)}


    if TalkingDataGA then
        TalkingDataGA:onEvent("pay", event)
        local td_order_id = platform .. recv_msg.trade_no

        TDGAVirtualCurrency:onChargeRequest(td_order_id, product_id, price, self.channel.currency_type, product.num, platform)
        TDGAVirtualCurrency:onChargeSuccess(td_order_id)
    end

    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["all_payment"], price)

    if product.type == PRODUCT_TYPE["speical_reward"] then
        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
    end

    analytics_manager:TriggerEvent("pay", event)
end

function payment:OnFinishAllQuery()
    -- App内购产品列表
    if self.channel.enable_appstore_pay and string.len(self.raw_products) > 0 then
        local CURRENCY_WHITELIST = self.channel.currency_whitelist or ""
        PlatformSDK.queryProductList(self.raw_products, CURRENCY_WHITELIST,"")   --增加一个参数

    elseif self.channel.enable_google_pay then
        PlatformSDK.addTransactionObserver(platform_manager:GetPayPlatformType("google"))

    elseif self.channel.enable_query_products then
        local server_id = login_logic.server_id
        PlatformSDK.queryProductList(self.raw_products, "",server_id)
        
    end
end

function payment:RegisterEvent()

    -- 交易的订单 & 购买记录
    network:RegisterEvent("query_payment_info_ret", function(recv_msg)
        print("query_payment_info_ret")

        -- 购买记录
        self.purchased_mark = recv_msg.purchased_mark
    end)

    -- 服务器返回订单
    network:RegisterEvent("new_payment_order_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local platform = platform_manager:GetPayPlatformType(recv_msg.platform)

            if recv_msg.platform == "r2games" then
                local product = self:GetProductInfo(recv_msg.product_id)

                local s = json:decode(recv_msg.post_info)
                local app_purchase_name = s.platform_product_id or product.app_purchase_name

                local order_info = { product_name = app_purchase_name, user_id = self.user_id, server_id = s.server_id, 
                                    adjust_token = analytics_manager:GetAdjustToken(app_purchase_name), trade_no = recv_msg.trade_no,
                                    product_price = product.price }

                local s = json:encode(order_info)
                PlatformSDK.buyProduct(platform, 1, s, self.user_id)
            elseif recv_msg.platform == "txwy" then
                local product = self:GetProductInfo(recv_msg.product_id)
                local s = json:decode(recv_msg.post_info)
                local app_purchase_name = s.platform_product_id or product.app_purchase_name
                local order_info = app_purchase_name.."|"..configuration:GetServerId().."|"..recv_msg.trade_no

                PlatformSDK.buyProduct(platform, 1, order_info, self.user_id)
            elseif recv_msg.platform == "txwy_dny" then
                local product = self:GetProductInfo(recv_msg.product_id)
                local s = json:decode(recv_msg.post_info)
                local app_purchase_name = s.platform_product_id or product.app_purchase_name
                local order_info = app_purchase_name.."|"..configuration:GetServerId().."|"..recv_msg.trade_no

                PlatformSDK.buyProduct(platform, 1, order_info, self.user_id)
            elseif recv_msg.platform == "shouyou" then
                local product = self:GetProductInfo(recv_msg.product_id)
                print("WLM ",json:encode(product))
                local s = json:decode(recv_msg.post_info)
                local app_purchase_name = s.platform_product_id or product.app_purchase_name
                local product_desc = string.format(lang_constants:Get("shouyou_third_party_product_desc"), product.num)
                local order_info = recv_msg.trade_no.."|"..product.price.."|"..product.name.."|"..product_desc.."|"..recv_msg.trade_no

                PlatformSDK.buyProduct(platform, 1, order_info, self.user_id)
            else
                graphic:DispatchEvent("show_prompt_panel", "payment_new_order_success")
                PlatformSDK.buyProduct(platform, self.quantity, recv_msg.post_info, self.user_id)
            end

            if not self.channel.enable_payment_callback then
                graphic:DispatchEvent("start_purchase", recv_msg.product_id)
            end

        elseif recv_msg.result == "repeat" then
            graphic:DispatchEvent("show_prompt_panel", "payment_new_order_repeat")

        elseif recv_msg.result == "overload" then
            graphic:DispatchEvent("show_prompt_panel", "payment_new_order_overload")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "payment_new_order_failure")
        end
    end)

    -- 服务器返回支付成功
    network:RegisterEvent("check_payment_order_ret", function(recv_msg)
        print("check_payment_order_ret", recv_msg.result)

        if recv_msg.result == "success" then
            self:BuySuccess(recv_msg)

        elseif recv_msg.result == "retry" then
            graphic:DispatchEvent("show_prompt_panel", "payment_check_order_in_progress")
        end
    end)

    network:RegisterEvent("close_payment_order_ret", function(recv_msg)
    end)

    --服务器返回 appstore 验证回执
    network:RegisterEvent("finish_apple_order_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self:BuySuccess(recv_msg)

        elseif recv_msg.result == "timeout" or recv_msg.result == "invalid" then
            graphic:DispatchEvent("show_prompt_panel", "payment_finish_order_" .. recv_msg.result)
            graphic:DispatchEvent("finish_waiting", "finished")
        end

        PlatformSDK.finishTransaction(recv_msg.trade_no)
    end)

    -- 服务器返回 googlepay 验证回执
    network:RegisterEvent("finish_google_order_ret", function (recv_msg)

        -- 注意product_id 是内购商品ID，不是游戏服务器的商品ID
        if recv_msg.trade_no then
            local product = self:GetProductInfo(recv_msg.product_id)
            PlatformSDK.notifyOrderComplete(platform_manager:GetPayPlatformType(self.purchase_platform), product.app_purchase_name)
        end

        if recv_msg.result == "success" then
            self:BuySuccess(recv_msg)
            graphic:DispatchEvent("finish_waiting", "finished")

        elseif recv_msg.result == "timeout" or recv_msg.result == "invalid" then
            graphic:DispatchEvent("show_prompt_panel", "payment_finish_order_" .. recv_msg.result)
            graphic:DispatchEvent("finish_waiting", "finished")
        end
    end)

    -- 服务器返回 血钻商店列表
    network:RegisterEvent("query_payment_products_list_ret", function(recv_msg)
        self.has_queried = true

        if not recv_msg.products_list then
            return
        end

        -- 配置列表
        local tmp_products = {}
        local sale = self.enable_pay

        for i, product in ipairs(recv_msg.products_list) do
            if product.price >= 0 then
                product.on_sale = sale
                product.is_hide = not product.is_visible

                self.products_list[i] = product

                if not tmp_products[product.app_purchase_name] then
                    tmp_products[product.app_purchase_name] = true

                    if string.len(self.raw_products) <= 0 then
                        self.raw_products = product.app_purchase_name
                    else
                        self.raw_products = self.raw_products .. ";" .. product.app_purchase_name
                    end
                end
            end
        end
    end)
end

return payment
