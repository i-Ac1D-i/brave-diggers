local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local icon_template = require "ui.icon_panel"

local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local payment_logic = require "logic.payment"
local user_logic = require "logic.user"
local analytics_manager = require "logic.analytics_manager"

local configuration = require "util.configuration"

local PLIST_TYPE = ccui.TextureResType.plistType

local goods_info_sub_panel = panel_prototype.New()
goods_info_sub_panel.__index = goods_info_sub_panel

function goods_info_sub_panel.New()
    return setmetatable({}, goods_info_sub_panel)
end
 
function goods_info_sub_panel:Init(root_node, product, index)
    self.root_node = root_node
    self.index = index

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node, true)
    self.icon_panel:SetPosition(-130, 85)

    self.buy_btn = root_node:getChildByName("buy_btn")
    self.buy_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            payment_logic:TryBuy(product)
        end
    end)

    self.desc_text = root_node:getChildByName("desc")

    self.desc_text:ignoreContentAdaptWithSize(true)
    self.name_text = root_node:getChildByName("name")

    self.price_text = self.buy_btn:getChildByName("price")

    self.limit_img = root_node:getChildByName("limit_gift_img")
    self.limit_text = root_node:getChildByName("time")

    self.limit_text:setRotation(33)

    if platform_manager:GetChannelInfo().meta_channel == "r2games" then
        self.desc_text:setColor(panel_util:GetColor4B(0x221506))

    else
        self.desc_text:setColor(panel_util:GetColor4B(client_constants.TEXT_QUALITY_COLOR[5]))
        panel_util:SetTextOutline(self.desc_text)
    end

    self.desc_text:setVisible(true)
end

function goods_info_sub_panel:Show(product)
    self.name_text:setString(product.name)

    local value = product.price
    -- 根据语言调整小数点格式
    local language = platform_manager:GetLocale()
    if language == "de" or language == "fr" or language == "es-MX" or language == "ru" and platform_manager:GetChannelInfo().panel_util_change_language_dot_format then
        value = panel_util:SetFormatWithPoint(value)
    end

    self.price_text:setString(value) 

    local desc = ""

    if product.type == constants.PAYMENT_PRODUCT_TYPE["adventure_vip"] then
        self.icon_panel:Show(nil, "", "icon/global/primary_card.png", 5, true)

        self.limit_img:setVisible(false)
        self.limit_text:setVisible(false)

    else
        self.icon_panel:Show(constants.REWARD_TYPE["resource"], constants["RESOURCE_TYPE"]["blood_diamond"], product.num, false, true)

        if payment_logic:GetPurchasedMark(product.product_id) == 0 and product.gift > 0 then
            desc = string.format(lang_constants:Get("payment_first_gift"), product.gift)

            self.limit_img:setVisible(true)
            self.limit_text:setVisible(true)
        else

            if product.gift2 > 0 then
                desc = string.format(lang_constants:Get("payment_gift"), product.gift2)
            else
                desc = product.desc
            end
            self.limit_img:setVisible(false)
            self.limit_text:setVisible(false)
        end
    end

    self.desc_text:setString(desc)
    self.root_node:setVisible(true)
end

local payment_panel = panel_prototype.New(true)

function payment_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/payment_panel.csb")

    self.goods_info_sub_panels = {}
    self.goods_sub_panel_num = 0

    self.goods_list = self.root_node:getChildByName("goods_list")

    self.goods_template = self.root_node:getChildByName("order_panel")
    self.goods_template:setVisible(false)

    self.goods_template:getChildByName("time"):setRotation(0)

    self.list_boader = self.goods_list:getChildByName("list_boader")

    self.back_btn = self.root_node:getChildByName("back_btn")

    --天下网游的充值平台按钮
    self.recharge_btn = self.root_node:getChildByName("more_btn")

    if self.recharge_btn then
        if platform_manager:GetChannelInfo().has_recharge_btn then
            self.recharge_btn:setTitleText(lang_constants:Get("more_pey_btn_name"))
            self.recharge_btn:setVisible(PlatformSDK.showThirdPartyRecharge())
        else
            self.recharge_btn:setVisible(false)
        end
    end

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function payment_panel:Show()
    self.root_node:setVisible(true)
    -- 商店配置信息
    local products_list= payment_logic.products_list
    if #products_list then
        self:UpdatePanel(products_list)
    end
end

function payment_panel:UpdatePanel(products_list)
    local purchased_num = 0
    local goods_num = 0
    local sub_panel = nil
    local flag = true

    if self.goods_sub_panel_num == 0 and #products_list > 0 then
        for index, product in ipairs(products_list) do
            flag = true

            if not product.product_id or not product.on_sale or product.is_hide then
                flag = false
            end

            if flag then
                goods_num = goods_num + 1

                sub_panel = goods_info_sub_panel.New()
                sub_panel:Init(self.goods_template:clone(), product, index)

                self.goods_list:insertCustomItem(sub_panel.root_node, goods_num)
                self.goods_info_sub_panels[goods_num] = sub_panel
            end
        end

        local list_boader = self.list_boader:clone()
        self.goods_list:insertCustomItem(list_boader, goods_num)
        self.goods_sub_panel_num = goods_num
    end

    for i = 1, self.goods_sub_panel_num do
        local sub_panel = self.goods_info_sub_panels[i]
        if sub_panel then
            local product = payment_logic.products_list[sub_panel.index]
            sub_panel:Show(product)
        end
    end
end


function payment_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
            analytics_manager:TriggerEvent("purchase_page_close", "")
        end
    end)

    if platform_manager:GetChannelInfo().has_recharge_btn then
        self.recharge_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                local server_info = configuration:GetServerInfo()
                local more_pay_data = server_info.id.."|"..configuration:GetVersion()
                PlatformSDK.thirdPartyRecharge(more_pay_data)
            end
        end)
    end
end

function payment_panel:RegisterEvent()
    graphic:RegisterEvent("update_payment_panel", function()
        if not self.root_node:isVisible() then
            return
        end
        -- 商店配置信息
        local products_list= payment_logic.products_list
        if #products_list then
            self:UpdatePanel(products_list)
        end
    end)
end

return payment_panel
