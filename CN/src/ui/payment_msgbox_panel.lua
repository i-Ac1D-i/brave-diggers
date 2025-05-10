local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local payment_logic = require "logic.payment"
local platform_manager = require "logic.platform_manager"

local payment_msgbox_panel = panel_prototype.New(true)

function payment_msgbox_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/payment_msgbox.csb")
    self.close_btn = self.root_node:getChildByName("close_btn")

    -- wechat
    self.wechat_btn = self.root_node:getChildByName("wechat_btn")
    -- alipay
    self.alipay_btn = self.root_node:getChildByName("alipay_btn")

    self.info_bg = self.root_node:getChildByName("info_bg")
    self.product_name_text = self.info_bg:getChildByName("product_name")
    self.price_text = self.info_bg:getChildByName("price")
    self.third_party = "alipay"

    self:RegisterWidgetEvent()
end

function payment_msgbox_panel:Show(product_id, price, name, one_option)
    self.root_node:setVisible(true)

    self.product_id = product_id

    self.product_name_text:setString(name)
    self.price_text:setString("¥ " .. tostring(price))

    if one_option then
        self.wechat_btn:setVisible(false)
        self.alipay_btn:setPositionX(320)
        self.third_party = one_option
    end
end

function payment_msgbox_panel:RegisterWidgetEvent()
    -- 微信
    self.wechat_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            -- 是否安装 微信
            local flag = platform_manager:HasPayPlatform("wechat")
            if not flag then
                -- 飘字
                graphic:DispatchEvent("show_prompt_panel", "social_platform_auth_not_installed_wechat")
            else
                graphic:DispatchEvent("hide_world_sub_panel", "payment_msgbox_panel")
                -- 开始购买
                payment_logic:Buy("", self.product_id, "wechat")
            end
        end
    end)

    -- 支付宝
    self.alipay_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", "payment_msgbox_panel")
            -- alipay
            payment_logic:Buy("", self.product_id, self.third_party)
        end
    end)

    -- 关闭按钮
    panel_util:RegisterCloseMsgbox(self.close_btn, "payment_msgbox_panel")
end

return payment_msgbox_panel
