local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local vip_logic = require "logic.vip"
local time_logic = require "logic.time"
local user_logic = require "logic.user"

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_util = require "ui.panel_util"

local vip_panel = panel_prototype.New(true)
function vip_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/vip_panel.csb")

    self.maze_tab_img = self.root_node:getChildByName("maze_tab")

    self.mining_tab_img = self.root_node:getChildByName("mining_tab")
    self.mining_tab_img:setVisible(false)

    self.maze_vip_img = self.root_node:getChildByName("maze_vip")

    self.not_buy_node = self.maze_vip_img:getChildByName("not_buy")
    self.already_buy_node = self.maze_vip_img:getChildByName("buy")
    self.price_value_text = self.not_buy_node:getChildByName("price_value")

    self.count_down_text = self.already_buy_node:getChildByName("countdown")

    self.not_buy_node:setVisible(true)
    self.already_buy_node:setVisible(false)

    self.buy_ticket_btn = self.root_node:getChildByName("buy_btn")

    self:SetPriceDynamic()
    self:RegisterEvent()
    self:RegisterWidgetEvent()

    local scroll_view=self.root_node:getChildByName("scroll_view")
    --r2位置修改
    local all_left=platform_manager:GetChannelInfo().vip_panel_good_1_desc_all_left
    if all_left then
        --左对齐
        local good1_desc=scroll_view:getChildByName("good_1"):getChildByName("desc")
        good1_desc:setAnchorPoint({x=0,y=1})
        good1_desc:setPosition({x=101,y=68})
    end

    --隐藏可以评论的功能提示信息
    if platform_manager:GetChannelInfo().hide_vip_can_talk then
        scroll_view:getChildByName("halo_3"):setVisible(false)

        local inner = scroll_view:getInnerContainer()

        inner:setContentSize({width = scroll_view:getContentSize().width, height = inner:getContentSize().height-100})
        
        for i,v in pairs(scroll_view:getChildren()) do
            if v:getName() ~= "Text_30"  then
                v:setPositionY(v:getPositionY()-100)
            end
        end

        scroll_view:jumpToTop()
    end
end

function vip_panel:SetPriceDynamic()
    local value = vip_logic:GetMonthCardPrice()
    -- 根据语言调整小数点格式
    local language = platform_manager:GetLocale()
    if language == "de" or language == "fr" or language == "es-MX" or language == "ru" and platform_manager:GetChannelInfo().panel_util_change_language_dot_format then
        value = panel_util:SetFormatWithPoint(value)
    end
    self.price_value_text:setString(value)
end

function vip_panel:Show()
    self.root_node:setVisible(true)

    self.vip_list = vip_logic:GetVipList()
    self.cur_vip_type = 1
    local vip_info = self.vip_list[self.cur_vip_type]

    local cur_time = time_logic:Now()

    if vip_info.reward_mark == constants.VIP_STATE["unbuy"] or cur_time > vip_info.end_time then
        self.buy_ticket_btn:getTitleRenderer():setString(lang_constants:Get("buy_vip_ticket"))
        self.not_buy_node:setVisible(true)
        self.already_buy_node:setVisible(false)
    else
        self.buy_ticket_btn:getTitleRenderer():setString(lang_constants:Get("take_vip_reward"))
        self.not_buy_node:setVisible(false)
        self.already_buy_node:setVisible(true)

        local cur_day = vip_logic:GetRewardDay(self.cur_vip_type)
        local countdown_str = string.format(lang_constants:Get("vip_remain_days"), cur_day)
        self.count_down_text:setString(countdown_str)

        if vip_info.reward_mark == constants.VIP_STATE["daily_reward"] then
            self.buy_ticket_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        else
            self.buy_ticket_btn:setColor(panel_util:GetColor4B(0xffffff))
        end
    end

end

function vip_panel:RegisterEvent()
    graphic:RegisterEvent("buy_vip_success", function()
        if not self.root_node:isVisible() then
            return
        end

        self.buy_ticket_btn:getTitleRenderer():setString(lang_constants:Get("take_vip_reward"))
        self.not_buy_node:setVisible(false)
        self.already_buy_node:setVisible(true)

        local cur_day = vip_logic:GetRewardDay(self.cur_vip_type)
        local countdown_str = string.format(lang_constants:Get("vip_remain_days"), cur_day)
        self.count_down_text:setString(countdown_str)

    end)

    graphic:RegisterEvent("take_vip_reward_success", function()
        if not self.root_node:isVisible() then
            return
        end

        self.buy_ticket_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
    end)

end

function vip_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "vip_panel")

    self.buy_ticket_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local vip_info = self.vip_list[self.cur_vip_type]
            if vip_info.reward_mark == constants.VIP_STATE["unbuy"] or time_logic:Now() > vip_info.end_time then
                vip_logic:BuyVip(self.cur_vip_type)
            else
                vip_logic:TakeReward(self.cur_vip_type)
            end
        end
    end)
end

return vip_panel
