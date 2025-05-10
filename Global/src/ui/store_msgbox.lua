local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local panel_util = require "ui.panel_util"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local time_logic = require "logic.time"
local campaign_logic = require "logic.campaign"
local store_logic = require "logic.store"
local arena_logic = require "logic.arena"
local escort_logic = require "logic.escort"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"
local lang_constants = require "util.language_constants"

local BATCH_MSGBOX_MODE = client_constants["BATCH_MSGBOX_MODE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]

local PLIST_TYPE = ccui.TextureResType.plistType

local MAX_SUB_PANEL_NUM = 5
local SUB_PANEL_Y = 490
local DEFAULT_MAX_NUM = 100
local DEFAULT_MERCENARY_MAX_NUM = 10 

local store_msgbox = panel_prototype.New(true)
function store_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/store_msgbox.csb")

    self.title_text = self.root_node:getChildByName("title")
    self.name_text = self.root_node:getChildByName("desc")
    self.name_text_origin = cc.p(self.name_text:getPosition())
    local buy_num_bg = self.root_node:getChildByName("buy_num_bg")
    self.num_text = buy_num_bg:getChildByName("buy_num")
    self.increase_btn = buy_num_bg:getChildByName("add_btn")
    self.decrease_btn = buy_num_bg:getChildByName("sub_btn")

    self.cancel_btn = self.root_node:getChildByName("cancel_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.item_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        self.item_sub_panels[i] = sub_panel
        self.item_sub_panels[i].root_node:setPositionY(SUB_PANEL_Y)
    end

    self.min_num = 1
    self.max_num = DEFAULT_MAX_NUM

    self:RegisterWidgetEvent()
end

function store_msgbox:Show(mode, ...)   

    self.mode = mode or 0
    self.num = 1
    self.delta = 0
    self.touch_time = 0
    self.max_num = DEFAULT_MAX_NUM

    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:ConvertCampaignReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:ShowBloodStore(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:ShowArenaReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
        self:ShowEscortBuyRobTimes()
    end

    self:UpdateCost()

    self.root_node:setVisible(true)
end

function store_msgbox:ConvertCampaignReward(reward_name,data)
    if data.limit > 0 then
        self.max_num = data.limit - data.count
    else
        self.max_num = DEFAULT_MAX_NUM
    end

    self.data = data
    self.title_text:setString(lang_constants:Get("campaign_msgbox_batch_title"))
    self.name_text:setString(lang_constants:Get("campaign_msgbox_batch_title") .. reward_name)

    local convert_type = constants.CAMPAIGN_RESOURCE.score
    self.item_sub_panels[1]:Show(constants["REWARD_TYPE"]["campaign"], convert_type, 0, false, false)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:ShowBloodStore(goods_index)
    self.goods_index = goods_index
    self.goods_info = store_logic:GetGoodsInfo(goods_index)
    self.title_text:setString(lang_constants:Get("blood_store_title"))

    self.name_text:setPosition(self.name_text_origin)  --恢复原始位置
    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.is_store_desc_change_and_center then  --FYD
        self.name_text:setString(self.goods_info.name..lang_constants:Get("blood_store_title"))
        self.name_text:setPositionX(self.name_text_origin.x+channel_info.store_desc_mv_dx) 
        self.name_text:setTextHorizontalAlignment(1)
    else
        self.name_text:setString(lang_constants:Get("blood_store_title") .. self.goods_info.name)
    end
    -- 上一次计算出的总价格, 用于当 '用户购买的的血钻' 大于 '拥有的血钻',
    -- 则回滚上一次计算出的总价格, 避免重复计算
    self.last_total_cost = store_logic:QueryTrendPrice(self.goods_info, self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], 0, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:ShowArenaReward(prize_id, name)
    self.prize_id = prize_id

    self.title_text:setString(lang_constants:Get("campaign_msgbox_batch_title"))

    if platform_manager:GetChannelInfo().is_text_change_front_to_back then
        self.name_text:setString(name.."を"..lang_constants:Get("campaign_msgbox_batch_title"))
    else
        self.name_text:setString(lang_constants:Get("campaign_msgbox_batch_title") .. name)
    end
    

    local medal_exchange_config = config_manager.medal_exchange_config
    self.medal_exchange_info = medal_exchange_config[prize_id]

    if self.medal_exchange_info.reward_type == constants.REWARD_TYPE["mercenary"] then
       self.max_num = DEFAULT_MERCENARY_MAX_NUM
    else
       self.max_num = DEFAULT_MAX_NUM
    end  

    panel_util:LoadCostResourceInfo(self:GetArenaRewardCostConfig(), self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function store_msgbox:ShowEscortBuyRobTimes()

    self.title_text:setString(lang_constants:Get("msgbox_buy_rob_times_title"))
    self.name_text:setString(lang_constants:Get("msgbox_buy_rob_times_desc"))
    self.name_text:ignoreContentAdaptWithSize(true)
    self.max_num = escort_logic:GetCouldBuyRobTimes()

    local could_buy, cost = escort_logic:GetBuyRobCost(1)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:GetArenaRewardCostConfig()
    local resoure_name1 = RESOURCE_TYPE_NAME[self.medal_exchange_info.need_resource1]
    local resoure_name2 = RESOURCE_TYPE_NAME[self.medal_exchange_info.need_resource2]
    local config = {}
    
    if resoure_name2 == "soul_chip" then
        config["soul_chip"] = self.medal_exchange_info.need_count2 * self.num
    else
        config["gold_coin"] = self.medal_exchange_info.need_count2 * self.num
    end

    config["king_medal"] = self.medal_exchange_info.need_count1 * self.num

    return config
end

function store_msgbox:Update(elapsed_time)
    if not self.is_update_cost then
        return
    end

    self.touch_time = self.touch_time + elapsed_time
    if self.touch_time >= 0.5 then
        self.update_freq = self.update_freq + elapsed_time
        if self.update_freq >= 0.1 then
            self.update_freq = self.update_freq - 0.1
            self:UpdateCost()
        end
    end
end

function store_msgbox:UpdateCost()
    self.num = self.num + self.delta

    if self.num < self.min_num then
        self.num = self.min_num
        self.is_update_cost = false

    elseif self.num > self.max_num then
        self.num = self.max_num
        self.is_update_cost = false
    end

    if self.num <= self.min_num then
        self.decrease_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.decrease_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    if self.num >= self.max_num then
        self.increase_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.increase_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:UpdateCampaignReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:UpdateBloodStore()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:UpdateArenaReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
       self:UpdateEscortBuyRobTimes()
    end 

    self.num_text:setString(tostring(self.num))    
end

function store_msgbox:UpdateBloodStore()
    local total_cost = store_logic:QueryTrendPrice(self.goods_info, self.num)
    local blood_diamond_num = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["blood_diamond"])
    
    if self.goods_info.max_buy_count and self.goods_info.already_buy_count + self.num > self.goods_info.max_buy_count then
    
        self.num = self.num - 1
        if self.num == 0 then
            self.num = 1
        end

        total_cost = self.last_total_cost
        self.is_update_cost = false

    elseif total_cost > blood_diamond_num then
        self.num = self.num - 1
        if self.num == 0 then
            self.num = 1
        end

        total_cost = self.last_total_cost
        self.is_update_cost = false
    end

    self.last_total_cost = total_cost
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], total_cost, true, false)
end

function store_msgbox:UpdateCampaignReward()
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["campaign_score"], self.data.req_value[1] * self.num, true, false)
end

function store_msgbox:UpdateArenaReward()
    panel_util:LoadCostResourceInfo(self:GetArenaRewardCostConfig(), self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function store_msgbox:UpdateEscortBuyRobTimes()
    local could_buy, cost = escort_logic:GetBuyRobCost(self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:Buy()
    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:CampaignRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:BloodStoreBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:ArenaRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
       self:EscortBuyRobTimes()
    end 
end

function store_msgbox:BloodStoreBuy()
    -- 检查血钻
    local goods_info = store_logic:GetGoodsInfo(self.goods_index)

    if not goods_info or self.num > 100 then
        return
    end

    local price = store_logic:QueryTrendPrice(goods_info, self.num)
    if not panel_util:CheckBloodDiamond(price) then
        return
    end

    store_logic:BuyGoods(self.goods_index, self.num)
end

function store_msgbox:CampaignRewardExchange()
    campaign_logic:ConvertReward(self.data, self.num)
end

function store_msgbox:ArenaRewardExchange()
    arena_logic:MedalPrize(self.prize_id, self.num)
end

function store_msgbox:EscortBuyRobTimes()
    escort_logic:BuyRobTimes(self.num)
end


function store_msgbox:RegisterWidgetEvent()

    self.cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --点击购买按钮
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            if self.num > 0 then
               self:Buy()
            end
        end
    end)

    self.increase_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = 1
            self.touch_time = 0
            self.update_freq = 0
            self.is_update_cost = true

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.is_update_cost = false
            if self.touch_time <= 1 then
                self:UpdateCost()
            end
        end
    end)

    self.decrease_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = -1
            self.touch_time = 0
            self.update_freq = 0
            self.is_update_cost = true

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.is_update_cost = false
            if self.touch_time <= 1 then
                self:UpdateCost()
            end
        end
    end)
end

return store_msgbox
