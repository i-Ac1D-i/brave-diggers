local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local panel_util = require "ui.panel_util"
local troop_logic = require "logic.troop"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local time_logic = require "logic.time"
local campaign_logic = require "logic.campaign"
local store_logic = require "logic.store"
local arena_logic = require "logic.arena"
local guild_logic = require "logic.guild"
local escort_logic = require "logic.escort"
local server_pvp_logic = require "logic.server_pvp"
local rune_logic = require "logic.rune"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"
local mine_logic = require "logic.mine"
local ladder_tower_logic = require "logic.ladder_tower"

local lang_constants = require "util.language_constants"

local BATCH_MSGBOX_MODE = client_constants["BATCH_MSGBOX_MODE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]

local PLIST_TYPE = ccui.TextureResType.plistType

local MAX_SUB_PANEL_NUM = 5
local SUB_PANEL_Y = 490
local DEFAULT_MAX_NUM = 500
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
    self.increase_ten_btn = buy_num_bg:getChildByName("add_btn_0")
    self.decrease_ten_btn = buy_num_bg:getChildByName("add_btn_0_0")
    

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
    self.min_num = 1
    -- [""] = 11, --

    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:ConvertCampaignReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:ShowBloodStore(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:ShowArenaReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_exchange_reward"] then
       self:ShowGuildExchangeReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
        self:ShowEscortBuyRobTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["server_pvp_buy_times"] then
       self:ShowServerPvpBuyTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_exchange_reward"] then
        self:GuildBossExchangeReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_tickets_reward"] then
        self:GuildBossTicketExchangeReward(...)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["rune_bag_numbers"] then
        self:ShowRuneBagBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_rob_times"] then
        --矿山掠夺次数
        self.min_num = 0
        self:ShowMineBuy(client_constants.TIMES_TYPE.rob_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_refresh_times"] then
        --矿山刷新次数
        self.min_num = 0
        self:ShowMineBuy(client_constants.TIMES_TYPE.refresh_target_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_fighting_times"] then
        --天梯赛战斗次数
        self.min_num = 0
        self:ShowLadderBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_buy_refresh_times"] then
        --天梯赛刷新次数
        self.min_num = 0
        self:ShowLadderBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["vanity_adventure_Exchange_reward"] then
        self.min_num = 0
        self:VanityExchangeReward(...)
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
    self.name_text:setString(lang_constants:Get("campaign_msgbox_batch_title") .. " " .. reward_name)

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
        self.name_text:setString(lang_constants:Get("campaign_msgbox_batch_title") .. " " .. name)
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

function store_msgbox:ShowGuildExchangeReward(reward_config, name)
    self.prize_id = reward_config.id

    self.title_text:setString(lang_constants:Get("campaign_msgbox_batch_title"))
    self.name_text:setString(lang_constants:Get("campaign_msgbox_batch_title") .. " " .. name)

    self.reward_config = reward_config
    if reward_config.limit > 0 then
        self.max_num = reward_config.limit - reward_config.count
    else
        self.max_num = DEFAULT_MAX_NUM
    end

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["guild_war_point"], self.reward_config.need_num, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:ShowEscortBuyRobTimes()

    self.title_text:setString(lang_constants:Get("msgbox_buy_rob_times_title"))
    self.name_text:setString(lang_constants:Get("msgbox_buy_rob_times_desc"))

    self.max_num = escort_logic:GetCouldBuyRobTimes()

    local could_buy, cost = escort_logic:GetBuyRobCost(1)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:ShowServerPvpBuyTimes()

    self.title_text:setString(lang_constants:Get("msgbox_server_pvp_buy_times_title"))
    self.name_text:setString(lang_constants:Get("msgbox_server_pvp_buy_times_desc"))

    self.max_num = server_pvp_logic:GetCouldBuyTimes()

    local could_buy, cost = server_pvp_logic:GetBuyCost(1)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:GuildBossExchangeReward(reward_config, name)

    self.title_text:setString(lang_constants:Get("msgbox_boss_exchange_reward_title"))
    self.name_text:setString(lang_constants:Get("msgbox_boss_exchange_reward_desc"))

    self.prize_id = reward_config.good_id

    self.reward_config = reward_config
    if reward_config.buy_limit > 0 then
        self.max_num = reward_config.buy_limit - reward_config.count
    else
        self.max_num = DEFAULT_MAX_NUM
    end

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["guild_boss_contribution"], self.reward_config.need_num, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function store_msgbox:GuildBossTicketExchangeReward()
    self.max_num = guild_logic:GetBuyTicketMax()
    
    self.title_text:setString(lang_constants:Get("blood_store_title"))
    self.name_text:setString(lang_constants:Get("guild_boss_ticket_buy_desc"))
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], 0, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

--符文兑换
function store_msgbox:ShowRuneBagBuy()
    self.title_text:setString(lang_constants:Get("blood_store_title"))
    self.name_text:setString(string.format(lang_constants:Get("rune_bag_buy_desc"),0))
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], 0, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
    --计算最大购买
   self.max_num = rune_logic:GetRuneBagCanUpadge()    
end

function store_msgbox:ShowMineBuy(buy_type)
    local title_str = ""
    if buy_type == client_constants.TIMES_TYPE.rob_times then
        --矿山掠夺次数
        title_str = lang_constants:Get("mine_buy_rob_times_title")
    elseif buy_type == client_constants.TIMES_TYPE.refresh_target_times then
        --矿山刷新次数
        title_str = lang_constants:Get("mine_buy_refresh_times_title")
    end
    self.title_text:setString(title_str)
    self.name_text:setString(lang_constants:Get("msgbox_buy_rob_times_desc"))

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], 0, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)

    self.max_num = mine_logic:GetBuyMaxTimes(buy_type)

end

function store_msgbox:ShowLadderBuy()
    local title_str = ""
    local buy_type
    if self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_fighting_times"] then
        --天梯赛战斗次数
        buy_type = client_constants.TIMES_TYPE.ladder_tower_fighting_times
        title_str = lang_constants:Get("ladder_buy_fighting_times_title")
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_buy_refresh_times"] then
        --天梯赛刷新次数
        buy_type = client_constants.TIMES_TYPE.ladder_tower_buy_refresh_times
        title_str = lang_constants:Get("ladder_buy_refresh_times_title")
    end
    self.title_text:setString(title_str)
    self.name_text:setString(lang_constants:Get("msgbox_buy_ladder_times_desc"))

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], 0, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)

    self.max_num = ladder_tower_logic:GetBuyMaxTimes(buy_type)

end

function store_msgbox:VanityExchangeReward(reward_config, name)

    self.title_text:setString(lang_constants:Get("msgbox_vanity_exchange_reward_title"))
    self.name_text:setString(lang_constants:Get("msgbox_vnaity_exchange_reward_desc"))

    self.prize_id = reward_config.good_id

    self.reward_config = reward_config
    if reward_config.max_count > 0 then
        self.max_num = reward_config.max_count - reward_config.cur_count
    else
        self.max_num = DEFAULT_MAX_NUM
    end

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["vanity_adventure"], self.reward_config.price, true)
    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end


function store_msgbox:GetArenaRewardCostConfig()
    local resoure_name1 = RESOURCE_TYPE_NAME[self.medal_exchange_info.need_resource1]
    local resoure_name2 = RESOURCE_TYPE_NAME[self.medal_exchange_info.need_resource2]
    local config = {}
    
    if resoure_name2 == "soul_chip" then
        config["soul_chip"] = self.medal_exchange_info.need_count2 * self.num
    elseif resoure_name2 == "golem3" then
        config["golem3"] = self.medal_exchange_info.need_count2 * self.num
    elseif resoure_name2 == "golem4" then
        config["golem4"] = self.medal_exchange_info.need_count2 * self.num
    elseif resoure_name2 == "golem1" then
        config["golem1"] = self.medal_exchange_info.need_count2 * self.num
    elseif resoure_name2 == "golem2" then
        config["golem2"] = self.medal_exchange_info.need_count2 * self.num
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
        self.decrease_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.decrease_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.decrease_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    if self.num >= self.max_num then
        self.increase_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.increase_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.increase_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.increase_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:UpdateCampaignReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:UpdateBloodStore()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:UpdateArenaReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_exchange_reward"] then
       self:UpdateGuildExchangeReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
       self:UpdateEscortBuyRobTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["server_pvp_buy_times"] then
       self:UpdateServerPvpBuyTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_exchange_reward"] then
       self:UpdateGuildBossExchangeReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_tickets_reward"] then
        self:UpdateGuildBossTicketExchangeReward()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["rune_bag_numbers"] then
        self:UpdateRuneBagBuyConst()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_rob_times"] then
        --矿山掠夺次数
        self:UpdateMineBuyTimes(client_constants.TIMES_TYPE.rob_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_refresh_times"] then
        --矿山刷新次数
        self:UpdateMineBuyTimes(client_constants.TIMES_TYPE.refresh_target_times)
   elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_fighting_times"] then
        --天梯赛战斗次数
        self:UpdateLadderBuyTimes(client_constants.TIMES_TYPE.ladder_tower_fighting_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_buy_refresh_times"] then
        --天梯赛刷新次数
        self:UpdateLadderBuyTimes(client_constants.TIMES_TYPE.ladder_tower_buy_refresh_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["vanity_adventure_Exchange_reward"] then
       self:UpdateVanityExchangeReward()
    end 

    self.num_text:setString(tostring(self.num))    
end

function store_msgbox:UpdateBloodStore()
    local total_cost = store_logic:QueryTrendPrice(self.goods_info, self.num)
    local blood_diamond_num = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["blood_diamond"])
    
    if self.goods_info.max_buy_count and self.goods_info.already_buy_count + self.num > self.goods_info.max_buy_count then
    
        self.num = self.num - math.abs(self.delta)
        if self.num <= 0 then
            self.num = 1
        end

        total_cost = self.last_total_cost
        self.is_update_cost = false

    elseif total_cost > blood_diamond_num then
        self.num = self.num - math.abs(self.delta)
        if self.num <= 0 then
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
    panel_util:LoadCostResourceInfo(self:GetArenaRewardCostConfig(), self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转
end

function store_msgbox:UpdateGuildExchangeReward()
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["guild_war_point"], self.reward_config.need_num * self.num, true)
end

function store_msgbox:UpdateEscortBuyRobTimes()
    local could_buy, cost = escort_logic:GetBuyRobCost(self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateServerPvpBuyTimes()
    local could_buy, cost = server_pvp_logic:GetBuyCost(self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateGuildBossExchangeReward()
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["guild_boss_contribution"], self.reward_config.use_list[1].count * self.num, true)
end

function store_msgbox:UpdateGuildBossTicketExchangeReward()
    local cost = guild_logic:BuyTicketCost(self.num)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateRuneBagBuyConst()
    local cost,cell = rune_logic:GetBuyIndexCost(self.num)
    self.name_text:setString(string.format(lang_constants:Get("rune_bag_buy_desc"),cell))
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateMineBuyTimes(buy_type)
    local cost = mine_logic:GetNeedCostBloodWithType(buy_type, self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateLadderBuyTimes(buy_type)
    local cost = ladder_tower_logic:GetNeedCostBloodWithType(buy_type, self.num)
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["blood_diamond"], cost, true)
end

function store_msgbox:UpdateVanityExchangeReward()
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], constants.RESOURCE_TYPE["vanity_adventure"], self.reward_config.price * self.num, true)
end


function store_msgbox:Buy()
    if self.mode == client_constants.BATCH_MSGBOX_MODE["convert_campaign_reward"] then
       self:CampaignRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["blood_store"] then
       self:BloodStoreBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["exchange_reward"] then
       self:ArenaRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_exchange_reward"] then
       self:GuildRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["escort_buy_rob_times"] then
       self:EscortBuyRobTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["server_pvp_buy_times"] then
       self:ServerPvpBuyTimes()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_exchange_reward"] then
       self:GuildBossRewardExchange()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["guild_boss_tickets_reward"] then
       self:GuildBossBuyTicket()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["rune_bag_numbers"] then
        self:RuneBagBuy()
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_rob_times"] then
        --矿山掠夺次数
        self:MineBuyTimes(client_constants.TIMES_TYPE.rob_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["mine_buy_refresh_times"] then
        --矿山刷新次数
        self:MineBuyTimes(client_constants.TIMES_TYPE.refresh_target_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_fighting_times"] then
        --天梯赛战斗次数
        self:LadderBuyTimes(client_constants.TIMES_TYPE.ladder_tower_fighting_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["ladder_tower_buy_refresh_times"] then
        --天梯赛刷新次数
        self:LadderBuyTimes(client_constants.TIMES_TYPE.ladder_tower_buy_refresh_times)
    elseif self.mode == client_constants.BATCH_MSGBOX_MODE["vanity_adventure_Exchange_reward"] then
       self:VanityRewardExchange()
    end 
end

function store_msgbox:BloodStoreBuy()
    -- 检查血钻
    local goods_info = store_logic:GetGoodsInfo(self.goods_index)

    if not goods_info or self.num > 500 then
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

function store_msgbox:GuildRewardExchange()
    guild_logic:ExchangeReward(self.prize_id, self.num)
end

function store_msgbox:GuildBossRewardExchange()
    guild_logic:GuildBossExchangeReward(self.prize_id, self.num)
end

function store_msgbox:EscortBuyRobTimes()
    escort_logic:BuyRobTimes(self.num)
end

function store_msgbox:ServerPvpBuyTimes()
    server_pvp_logic:BuyChallengeTimes(self.num)
end

function store_msgbox:GuildBossBuyTicket()
    local cost = guild_logic:BuyTicketCost(self.num)
    if self.num <= 0 or not panel_util:CheckBloodDiamond(cost) then
        return
    end
    guild_logic:GuildBossBuyTicket(self.num)
end

function store_msgbox:VanityRewardExchange()
    troop_logic:VanityExchangeReward(self.prize_id, self.num)
end


--符文背包购买
function store_msgbox:RuneBagBuy()
    local cost = rune_logic:GetBuyIndexCost(self.num)
    if not panel_util:CheckBloodDiamond(cost) then
        return
    end
    rune_logic:BuyRuneBugCell(self.num)
end

--矿山消耗购买
function store_msgbox:MineBuyTimes(buy_type)
    local cost = mine_logic:GetNeedCostBloodWithType(buy_type, self.num)
    if not panel_util:CheckBloodDiamond(cost) then
        return
    end
    mine_logic:MineBuyTimes(buy_type, self.num)
end

--天梯赛消耗购买
function store_msgbox:LadderBuyTimes(buy_type)
    local cost = ladder_tower_logic:GetNeedCostBloodWithType(buy_type, self.num)
    if not panel_util:CheckBloodDiamond(cost) then
        return
    end
    ladder_tower_logic:BuyTimes(buy_type, self.num)
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

    --自动增加10次按钮监听
    self.increase_ten_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = 10
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

    --自动减10次
    self.decrease_ten_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = -10
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
