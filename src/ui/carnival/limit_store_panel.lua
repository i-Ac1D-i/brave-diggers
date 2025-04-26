local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local carnival_logic = require "logic.carnival"
local payment_logic = require "logic.payment"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local time_logic = require "logic.time"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local REWARD_TYPE = constants.REWARD_TYPE
local MAX_SUB_PANEL_NUM = 6
local SUB_PANEL_Y = 540

local FIRST_PAYEMNT_PROMPT =
{
    [1] = lang_constants:Get("carnival_payment_first_gift"),
    [2] = lang_constants:Get("take_vip_reward"),
    [3] = lang_constants:Get("ladder_already_get_reward"),
}

local carnival_limit_panel = panel_prototype.New(true)
function carnival_limit_panel:Init(root_node)
    self.root_node =  cc.CSLoader:createNode("ui/carnival_limit_buy_panel.csb")
 
    self.title_text = self.root_node:getChildByName("title_text")
    local template = self.root_node:getChildByName("template")
    self.name_text = template:getChildByName("name")
    self.desc_text = template:getChildByName("desc_1") 
    local font_size = platform_manager:GetChannelInfo().carnival_limit_buy_panel_desc1_font
    if font_size then
         self.desc_text:setFontSize(font_size) 
    end

    self.gift_icon_img = template:getChildByName("icon1")
    self.gift_icon2_img = self.gift_icon_img:getChildByName("icon2")

    self.origin_price_text = template:getChildByName("price_value")
    self.delete_line_text = template:getChildByName("deleteline")

    self.buy_btn = self.root_node:getChildByName("buy_btn")
    self.first_payment_text = self.buy_btn:getChildByName("firstbuy_desc")
    self.limit_node = self.buy_btn:getChildByName("shadow")

    self.cur_price_text = self.limit_node:getChildByName("price_value2")
    self.origin_price2_text = self.limit_node:getChildByName("price_value")

    self.limit_duration_text = self.limit_node:getChildByName("time")

    self.reward_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        self.reward_sub_panels[i] = sub_panel
        self.reward_sub_panels[i].root_node:setPositionY(SUB_PANEL_Y)
    end

    --初始化为首充显示
    self:SetWigdetVisible(false)
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function carnival_limit_panel:SetWigdetVisible(is_visible)
    self.first_payment_text:setVisible(not is_visible)
    self.limit_node:setVisible(is_visible)
    self.origin_price_text:setVisible(is_visible)
    self.delete_line_text:setVisible(is_visible)
    self.gift_icon2_img:setVisible(is_visible)
end

function carnival_limit_panel:Show(config)
    self.config  = config or self.config
    self.cur_index = 1

    if not self.config then
        return
    end

    if self.config.carnival_type == constants.CARNIVAL_TYPE["time_limit_store"] then
        self:SetWigdetVisible(true)
        self.gift_icon_img:loadTexture("icon/item/herobag_bg.png", PLIST_TYPE)
        self.duration = time_logic:GetDurationToFixedTime(self.config.end_time)
        self.update_time = true

        self.cur_index = carnival_logic:GetValueAndReward(self.config, 1, 1)
        self:SetLimitStoreInfo()

    elseif self.config.carnival_type == constants.CARNIVAL_TYPE["first_payment"] then
        self:SetWigdetVisible(false)
        self.update_time = false
        self.gift_icon_img:loadTexture("carnival/rewardgif_1.png", PLIST_TYPE)

        local status = carnival_logic:GetStageRewardIndex(self.config.key, 1)
        local text_str = ""
        if status == 1 then
            text_str = lang_constants:Get("carnival_payment_first_gift")
        elseif status == 2 then
            text_str = lang_constants:Get("take_vip_reward")
        elseif status == 3 then
            text_str = lang_constants:Get("ladder_already_get_reward")
        end

        self.first_payment_text:setString(text_str)

    end

    local locale = platform_manager:GetLocale()
    local result = self.config["name"]
    if self.config["name".."_"..locale] then
        result = self.config["name".."_"..locale]
    end
    self.title_text:setString(result)
    self.name_text:setString(self:GetLocaleInfoString(self.config, "mult_str1", self.cur_index))
    self.desc_text:setString(self:GetLocaleInfoString(self.config, "mult_str2", self.cur_index))

    self:LoadRewardSub(self.cur_index)
    self.root_node:setVisible(true)
end

function carnival_limit_panel:GetLocaleInfoString( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

function carnival_limit_panel:SetLimitStoreInfo()
    local product_id = self.config.mult_num1[self.cur_index]
    local products_list= payment_logic.products_list

    for i = 1, #products_list do
        local product = products_list[i]
        if product.product_id == product_id then
            self.origin_price_text:setString(product.fake_price)
            self.origin_price2_text:setString(product.fake_price)
            self.cur_price_text:setString(product.price)
            self.product = product
            break
        end
    end
end

function carnival_limit_panel:LoadRewardSub()
    local reward_list = self.config.reward_list[1].reward_info

    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = self.reward_sub_panels[i]
        if i <= #reward_list then
            local re = reward_list[i]
            sub_panel:Show(re.reward_type, re.param1, re.param2,  false, false)
        else
            sub_panel.root_node:setVisible(false)
        end
    end

    panel_util:SetIconSubPanelsPosition(self.reward_sub_panels, MAX_SUB_PANEL_NUM, #reward_list, SUB_PANEL_Y)
end

function carnival_limit_panel:Update(elapsed_time)
    if self.update_time then
        self.duration = self.duration - elapsed_time
        if self.duration < 0 then
            self.update_time = false
            self.duration = 0
        end
        self.limit_duration_text:setString(panel_util:GetTimeStr(self.duration))
    end
end

function carnival_limit_panel:RegisterWidgetEvent()

    self.buy_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --领取首冲
            if self.config.carnival_type == constants.CARNIVAL_TYPE["first_payment"] then
                local status = carnival_logic:GetStageRewardIndex(self.config.key, 1)
                if status == STEP_STATUS["cant_take"] then
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())

                    if not payment_logic.enable_pay then
                        graphic:DispatchEvent("show_prompt_panel", "payment_purchase_not_available")
                    else
                        graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene")
                    end

                else
                    carnival_logic:TakeReward(self.config, 1)
                end

            elseif self.config.carnival_type == constants.CARNIVAL_TYPE["time_limit_store"] then
                --限时礼包购买
                audio_manager:PlayEffect("click")
                payment_logic:TryBuy(self.product)
            end
        end
    end)

    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())

end

function carnival_limit_panel:RegisterEvent()
    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key)
        if not self.root_node:isVisible() then
            return
        end

        if self.config.key ~= key then
            return
        end

        self:Show()

    end)
end

return carnival_limit_panel
