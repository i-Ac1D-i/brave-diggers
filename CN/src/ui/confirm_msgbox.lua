local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local resource_template = require "ui.icon_panel"

local merchant_logic = require "logic.merchant"
local arena_logic = require "logic.arena"
local time_logic = require "logic.time"
local bag_logic = require "logic.bag"
local mining_logic = require "logic.mining"
local user_logic = require "logic.user"
local temple_logic = require "logic.temple"
local campaign_logic = require "logic.campaign"
local daily_logic = require "logic.daily"
local guild_logic = require "logic.guild"
local rune_logic = require "logic.rune"
local escort_logic = require "logic.escort"
local server_pvp_logic = require "logic.server_pvp"
local mine_logic = require "logic.mine"
local resource_logic = require "logic.resource"
local limite_logic = require "logic.limite"

local resource_config = config_manager.resource_config

local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]
local CONFIRM_MSGBOX_MODE = client_constants["CONFIRM_MSGBOX_MODE"]
local MAX_SUB_PANEL_NUM = 5
local SUB_PANEL_Y = 545

local TRANSMIGRATION_COST = constants.TRANSMIGRATION_COST

local panel_util = require "ui.panel_util"

local confirm_msgbox = panel_prototype.New(true)
confirm_msgbox.__index = confirm_msgbox
confirm_msgbox.sub_msgboxes = {}

function confirm_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/confirm_msgbox.csb")
    local root_node = self.root_node

    self.confirm_btn = root_node:getChildByName("confirm_btn")

    self.title_text = root_node:getChildByName("title")
    self.cost_title_text = root_node:getChildByName("cost_title")
    self.desc_text = root_node:getChildByName("desc")

    self.refresh_node = root_node:getChildByName("refresh")
    self.refresh_desc_text = self.refresh_node:getChildByName("desc2")
    self.refresh_time_text = self.refresh_node:getChildByName("time")

    self.check_box_bg = root_node:getChildByName("choose_bg")
    self.check_box_select_img = root_node:getChildByName("yes_icon")
    self.check_box_text = root_node:getChildByName("gogo")
    self.check_box_btn = root_node:getChildByName("choose_btn")

    self.desc1_text = self.refresh_node:getChildByName("desc1")

    self.item_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = resource_template.New()
        sub_panel:Init(root_node)
        self.item_sub_panels[i] = sub_panel
        self.item_sub_panels[i].root_node:setPositionY(SUB_PANEL_Y)
    end

    local title = ""
    local desc = ""
    local cost_title = ""
    self.time_str = ""

    self:RegisterWidgetEvent()
end

function confirm_msgbox.NewSubMsgBox(mode)
    local msgbox = setmetatable({}, confirm_msgbox)
    confirm_msgbox.sub_msgboxes[mode] = msgbox

    return msgbox
end

function confirm_msgbox:Show(mode, data1, data2, data3)
    self.duration = 0
    self.mode = mode or 0
    self.data1 = data1
    self.data2 = data2
 
    self:ShowCheckBox(false)

    self.refresh_time_text:setVisible(true)
    self.desc1_text:setVisible(true)
    
    local sub_msgbox = self.sub_msgboxes[mode]
    sub_msgbox:Show(data1, data2, data3)

    self.root_node:setVisible(true)
end

function confirm_msgbox:ShowCheckBox(is_show)
    self.check_box_bg:setVisible(is_show)
    self.check_box_select_img:setVisible(is_show)
    self.check_box_text:setVisible(is_show)
    self.check_box_btn:setVisible(is_show)
end

function confirm_msgbox:Update(elapsed_time)
    self.sub_msgboxes[self.mode]:DoUpdate(elapsed_time)
end

function confirm_msgbox:DoUpdate(elapsed_time)
    if not self.refresh_time_text:isVisible() then
        return
    end

    self.duration = self.duration - elapsed_time

    --时间到了则重新请求数据
    if self.duration <= 0 then
        self.duration = 0
    end

    self.refresh_time_text:setString(panel_util:GetTimeStr(self.duration))
end

function confirm_msgbox:RegisterWidgetEvent()
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            audio_manager:PlayEffect("click")

            local sub_msgbox = self.sub_msgboxes[self.mode]
            sub_msgbox:Confirm()
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("canel_btn"), self:GetName())
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

--刷新竞技场
local RefreshArenaMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["refresh_arena"])
function RefreshArenaMsgBox:Show()
    local title = lang_constants:Get("msgbox_use_bd_refresh_title")
    local cost_title = lang_constants:Get("msgbox_use_bd_refresh_cost")
    local desc = lang_constants:Get("msgbox_refresh_arena_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.duration = time_logic:GetDurationToFixedTime(arena_logic.refresh_time)

    local template_id = RESOURCE_TYPE["blood_diamond"]
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], template_id, constants["ARENA_REFRESH_COST_BLOOD_DIAMOND"], false, false)

    self.item_sub_panels[1].root_node:setPositionX(320)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function RefreshArenaMsgBox:Confirm()
    --检查血钻消耗
    local cost_blood_diamand = constants.ARENA_REFRESH_COST_BLOOD_DIAMOND
    if not panel_util:CheckBloodDiamond(cost_blood_diamand) then
        return
    end
    arena_logic:RefreshRival()
end

--刷新商会
local RefreshMerchantMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["refresh_order"])
function RefreshMerchantMsgBox:Show()
    local title = lang_constants:Get("msgbox_use_bd_refresh_title")
    local cost_title = lang_constants:Get("msgbox_use_bd_refresh_cost")
    local desc = lang_constants:Get("msgbox_refresh_merchant_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.duration = time_logic:GetDurationToFixedTime(merchant_logic:GetResetTime(self.data1))

    local template_id = RESOURCE_TYPE["blood_diamond"]
    local price = merchant_logic:GetResetPrice(self.data1)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], template_id, price, false, false)

    self.item_sub_panels[1].root_node:setPositionX(320)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function RefreshMerchantMsgBox:Confirm()
    merchant_logic:Reset(self.data1)
end

--解锁背包
local UpgradeBagMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["upgrade_bag"])
function UpgradeBagMsgBox:Show()
    local capacity, level = bag_logic:GetCapacity()
    local next_config = config_manager.bag_info_config[level+1]
    if not next_config then
       return
    end

    local config = config_manager.bag_info_config[level]
    --Tag:
    --显示的时候不显示跳转界面
    panel_util:LoadCostResourceInfo(config, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM, nil,true)

    local title = lang_constants:Get("msgbox_upgrade_bag_title")
    local cost_title = lang_constants:Get("msgbox_upgrade_bag_cost")
    local desc = string.format(lang_constants:Get("msgbox_upgrade_bag_desc"), next_config.capacity - capacity)

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function UpgradeBagMsgBox:Confirm()
    bag_logic:UpgradeBag()
end

--兑换奖励
local ExchangeRewardMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["exchange_reward"])
function ExchangeRewardMsgBox:Show(prize_id)
    self.prize_id = prize_id

    local title = lang_constants:Get("msgbox_buy_goods_title")
    local cost_title = lang_constants:Get("msgbox_buy_goods_cost")
    local desc = lang_constants:Get("msgbox_buy_goods_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)

    local medal_exchange_config = config_manager.medal_exchange_config

    local medal_exchange_info = medal_exchange_config[prize_id]

    local resoure_name1 = RESOURCE_TYPE_NAME[medal_exchange_info.need_resource1]
    local resoure_name2 = RESOURCE_TYPE_NAME[medal_exchange_info.need_resource2]

    local config = {}
    if resoure_name2 == "soul_chip" then
        config["soul_chip"] = medal_exchange_info.need_count2
    else
        config["gold_coin"] = medal_exchange_info.need_count2
    end

    config["king_medal"] = medal_exchange_info.need_count1

    panel_util:LoadCostResourceInfo(config, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function ExchangeRewardMsgBox:Confirm()
    arena_logic:MedalPrize(self.prize_id)
end


local recruit_param = {}
local RecruitMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["recruit_mercenary"])
--招募(普通招募，英雄招募， 十连招募，神殿招募)
function RecruitMsgBox:Show(recruit_type)

    local title = lang_constants:Get("msgbox_recruiting_door_title")
    local cost_title = ""
    local desc = ""

    if recruit_type == "ten_mercenary_door" then
        --十连
        recruit_param["blood_diamond"] = constants["RECRUIT_COST"]["ten_mercenary_door"]
        recruit_param["gold_coin"] = 0
        recruit_param["friendship_pt"] = 0

        cost_title = lang_constants:Get("msgbox_recruiting_door_title")
        desc = lang_constants:Get("msgbox_ten_mercenary_door_cost")

        panel_util:LoadCostResourceInfo(recruit_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转

    elseif recruit_type == "recruiting_door" then
        --金币
        recruit_param["gold_coin"] = daily_logic:GetRecruitCost()
        recruit_param["blood_diamond"] = 0
        recruit_param["friendship_pt"] = 0
        cost_title = lang_constants:Get("msgbox_recruiting_door_title")
        desc = lang_constants:Get("msgbox_recruiting_door_cost")

        panel_util:LoadCostResourceInfo(recruit_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转
    elseif recruit_type == "hero_door" then
        --普通
        recruit_param["blood_diamond"] = constants["RECRUIT_COST"]["hero_door"]
        recruit_param["gold_coin"] = 0
        recruit_param["friendship_pt"] = 0
        cost_title = lang_constants:Get("msgbox_recruiting_door_title")
        desc = lang_constants:Get("msgbox_hero_door_cost")

        panel_util:LoadCostResourceInfo(recruit_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转

    elseif recruit_type == "friendship_door" then
        --友情招募
        recruit_param["friendship_pt"] = constants["RECRUIT_COST"]["friendship_door"]
        recruit_param["gold_coin"] = 0
        recruit_param["blood_diamond"] = 0

        cost_title = lang_constants:Get("msgbox_recruiting_door_title")
        desc = lang_constants:Get("msgbox_friendship_door_cost")

        panel_util:LoadCostResourceInfo(recruit_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转
    end

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)

    self.recruit_type = recruit_type
end

function RecruitMsgBox:Confirm()
    troop_logic:RecruitMercenary(self.recruit_type)
end

local revive_param = {}
local TempleMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["revive_mercenary"])
function TempleMsgBox:Show(mercenary_id)
    local title = lang_constants:Get("msgbox_revive_mercenary_title")
    local cost_title = lang_constants:Get("msgbox_revive_mercenary_title")

    local conf = config_manager.mercenary_config[mercenary_id]

    local desc = string.format(lang_constants:Get("msgbox_revive_mercenary_cost"), conf.name)

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)

    self.mercenary_id = mercenary_id

    revive_param["soul_chip"] = temple_logic:GetTempleMercenaryPrice(mercenary_id)

    panel_util:LoadCostResourceInfo(revive_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function TempleMsgBox:Confirm()
    temple_logic:RecruitMercenary(self.mercenary_id)
end

local tnt_param = { }

local DestroyRockPurpleMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["destroy_rock_purple"])
function DestroyRockPurpleMsgBox:Show(x, y)
    self.block_x, self.block_y = x, y

    local block_type = mining_logic:GetBlockType(x, y)
    local block_info = config_manager.mining_dig_info_config[block_type]

    self.title_text:setString(lang_constants:Get("msgbox_destroy_rock_purple_title"))
    self.desc_text:setString(string.format(lang_constants:Get("msgbox_destroy_rock_purple_desc"), block_info.tnt_count))

    tnt_param["tnt"] = block_info.tnt_count

    panel_util:LoadCostResourceInfo(tnt_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self.refresh_node:setVisible(false)
    self.cost_title_text:setString("")
end

function DestroyRockPurpleMsgBox:Confirm()
    mining_logic:DigOrCollectBlock(self.block_x, self.block_y)
end

local UseTNTMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["use_tnt"])
function UseTNTMsgBox:Show()
    local block_type = mining_logic:GetBlockType(mining_logic.cur_position.x, mining_logic.cur_position.y)
    local block_info = config_manager.mining_dig_info_config[block_type]

    self.title_text:setString(lang_constants:Get("msgbox_destroy_rock_purple_title"))
    self.desc_text:setString(string.format(lang_constants:Get("msgbox_use_tnt_desc"), block_info.tnt_count))

    tnt_param["tnt"] = block_info.tnt_count

    panel_util:LoadCostResourceInfo(tnt_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self.refresh_node:setVisible(false)
    self.cost_title_text:setString("")
end

function UseTNTMsgBox:Confirm()
    mining_logic:UseTNT()
end

local unlock_project_param = {}
local UnlockProjectSlotMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["unlock_mining_project"])

function UnlockProjectSlotMsgBox:Show()
    local title = lang_constants:Get("msgbox_general_title")
    local cost_title = lang_constants:Get("msgbox_unlock_mining_project_cost")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString("")

    self.refresh_node:setVisible(false)

    unlock_project_param["soul_chip"] = 600

    panel_util:LoadCostResourceInfo(unlock_project_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM,nil,true) -- 资源跳转
end

function UnlockProjectSlotMsgBox:Confirm()
    mining_logic:UnlockProjectSlot()
end

local transmigration_param = {}
local TransmigrationMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["transmigration"])
function TransmigrationMsgBox:Show(src_instance_id, target_instance_id)
    self.title_text:setString(lang_constants:Get("msgbox_transmigration_title"))
    self.cost_title_text:setString(lang_constants:Get("msgbox_transmigration_cost"))
    self.desc_text:setString(lang_constants:Get("msgbox_transmigration_desc"))

    self.refresh_node:setVisible(false)

    transmigration_param["blood_diamond"] = troop_logic:GetTransmigrationPrice(src_instance_id, target_instance_id)

    panel_util:LoadCostResourceInfo(transmigration_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function TransmigrationMsgBox:Confirm()
    -- 检查血钻消耗
    local price = troop_logic:GetTransmigrationPrice(self.data1, self.data2)

    if not panel_util:CheckBloodDiamond(price) then
        return
    end
    troop_logic:TransmigrateMercenary(self.data1, self.data2)
end

--使用物品
local UseItemMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["use_item"])
function UseItemMsgBox:Show(item_id)
    local item_info = bag_logic:GetItemInfo(item_id)

    self.title_text:setString(lang_constants:Get("msgbox_use_item_title"))
    self.cost_title_text:setString(lang_constants:Get("msgbox_use_item_cost"))
    self.desc_text:setString(string.format("%s", item_info.template_info.desc))

    self.refresh_node:setVisible(false)

    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["item"], item_info.template_info.ID, 1, false, false)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end

    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, 1, SUB_PANEL_Y)
end

function UseItemMsgBox:Confirm()
    local item = bag_logic:GetItemInfo(self.data1)
    if not item then
        graphic:DispatchEvent("show_prompt_panel", "bag_item_not_exist")
        return
    end

    bag_logic:UseItem(self.data1)
end

--开宝箱
local OpenChestMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["open_chest"])
function OpenChestMsgBox:Show(event_id)
    self.event_id = event_id

    local conf = config_manager.event_config[event_id]

    self.title_text:setString(conf.name)
    self.desc_text:setString(conf.desc)
    self.cost_title_text:setString(lang_constants:Get("msgbox_open_chest_cost"))

    local open_chest_param = {}

    local need_num_iter = string.gmatch(conf.need_num, "(%d+)")

    for resource_type in string.gmatch(conf.need_resource_id, "(%d+)") do
        local need_num = need_num_iter()

        if need_num then
            resource_type = tonumber(resource_type)
            open_chest_param[RESOURCE_TYPE_NAME[resource_type]] = tonumber(need_num)
        end
    end

    panel_util:LoadCostResourceInfo(open_chest_param, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self.refresh_node:setVisible(false)
end

function OpenChestMsgBox:Confirm()
    mining_logic:SolveEvent(self.event_id)
end

local BuyCampaignChallengeMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_campaign_challenge"])
function BuyCampaignChallengeMsgBox:Show(req_num, reward_value, limit_count)
    local title = lang_constants:Get("campaign_msgbox_buy_title")
    local cost_title = lang_constants:Get("campaign_msgbox_buy_cost")
    local desc = string.format(lang_constants:Get("campaign_msgbox_buy_desc"),reward_value,limit_count)

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    panel_util:LoadCostResourceInfo({["blood_diamond"] = req_num}, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function BuyCampaignChallengeMsgBox:Confirm()
    campaign_logic:BuyOverTimeCount()
end

local ReviveCampaignMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["revive_campaign"])
function ReviveCampaignMsgBox:Show(revive_value)
    local title = lang_constants:Get("campaign_msgbox_revive_title")
    local cost_title = lang_constants:Get("campaign_msgbox_buy_cost")
    local desc = lang_constants:Get("campaign_msgbox_revive_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    panel_util:LoadCostResourceInfo({["blood_diamond"] = revive_value}, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function ReviveCampaignMsgBox:Confirm()
    campaign_logic:ReviveCampaignBattle()
end

local BuyCampaignBuffMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_campaign_buff"])

function BuyCampaignBuffMsgBox:Show(buff_info)
    self.buff_info = buff_info

    local title = ""
    local cost_title = ""
    local desc = ""

    if buff_info.type == constants.CAMPAIGN_CONVERT_SCORE then
        title = lang_constants:Get("campaign_msgbox_buff_title2")
        cost_title = lang_constants:Get("campaign_msgbox_buff_cost2")
        desc = lang_constants:Get("campaign_msgbox_buff_desc2")
    else
        title = lang_constants:Get("campaign_msgbox_buff_title1")
        cost_title = lang_constants:Get("campaign_msgbox_buff_cost1")
        desc = lang_constants:Get("campaign_msgbox_buff_desc1")
    end

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    local template_id = constants.CAMPAIGN_RESOURCE.exp
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["campaign"], template_id, buff_info.req_exp, false, false)

    self.item_sub_panels[1].root_node:setPositionX(320)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function BuyCampaignBuffMsgBox:Confirm()
    campaign_logic:BuyBuff(self.buff_info)
end

local ExchangeCampaignRewardMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["convert_campaign_reward"])
function ExchangeCampaignRewardMsgBox:Show(reward_info)
    self.reward_info = reward_info

    local title = lang_constants:Get("campaign_msgbox_reward_title")
    local cost_title = lang_constants:Get("campaign_msgbox_buff_cost2")
    local desc = lang_constants:Get("campaign_msgbox_reward_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    local template_id = constants.CAMPAIGN_RESOURCE.score
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["campaign"], template_id, reward_info.req_value[1], false, false)
    self.item_sub_panels[1].root_node:setPositionX(320)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function ExchangeCampaignRewardMsgBox:Confirm()
    campaign_logic:ConvertReward(self.reward_info)
end

local RefreshMiningMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["reset_golem_level"])
function RefreshMiningMsgBox:Show(conf)
    local title = lang_constants:Get("mining_reset_confirm_title")
    local cost_title = lang_constants:Get("mining_reset_confirm_cost")
    local desc = lang_constants:Get("mining_reset_confirm_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    panel_util:LoadCostResourceInfo(conf, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function RefreshMiningMsgBox:Confirm()
    local conf = self.data1
    local item_id = self.data2

    if item_id and item_id ~= 0 then
        bag_logic:UseItem(item_id, conf.golem_lv)

    else
        mining_logic:RefreshArea(conf.golem_lv)
    end
end

local UnlockMineBossMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["open_cave_boss"])
function UnlockMineBossMsgBox:Show()
    local title = lang_constants:Get("mining_unlock_cave_boss_title")
    local cost_title = lang_constants:Get("mining_unlock_cave_boss_cost")
    local desc = lang_constants:Get("mining_unlock_cave_boss_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)
    
    panel_util:LoadCostResourceInfo({["demon_medal"] = constants["OPEN_CAVE_BOSS_DEMON_MEDAL"]}, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function UnlockMineBossMsgBox:Confirm()
    mining_logic:UnlockMineCaveBoss()
end

local BuyCaveChallengeMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_cave_challenge"])
function BuyCaveChallengeMsgBox:Show()
    local title = lang_constants:Get("mining_buy_cave_challenge_title")
    local cost_title = lang_constants:Get("mining_buy_cave_challenge_cost")

    local current_counts = mining_logic.cave_buy_challenge_nums[self.data1]
    local max_counts = constants["CAVE_DAILY_BUY_CHALLENGE_NUM"][self.data1]
    local desc = string.format(lang_constants:Get("mining_buy_cave_challenge_desc"), current_counts)

    local price_index = max_counts - current_counts + 1
    local price 

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.item_sub_panels[1].root_node:setVisible(true)
    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)

    if constants["CAVE_DAILY_BUY_PRICE"][self.data1][price_index] then 
       price = constants["CAVE_DAILY_BUY_PRICE"][self.data1][price_index]
       panel_util:LoadCostResourceInfo({["blood_diamond"] = price }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
    else
       for i = 1, MAX_SUB_PANEL_NUM do
          self.item_sub_panels[i].root_node:setVisible(false)
       end
    end
end

function BuyCaveChallengeMsgBox:Confirm()
    mining_logic:BuyCaveChallengeCounts(self.data1)
end

--购买公会buff
local BuyGuildBuffMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_guild_buff"])
function BuyGuildBuffMsgBox:Show()
    local title = lang_constants:Get("guild_war_buy_buff_title")
    local cost_title = lang_constants:Get("guild_war_buy_buff_cost")
    local desc = ""

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)
    
    local bd_num = constants.GUILDWAR_BUFF_COST[self.data2]
    panel_util:LoadCostResourceInfo({["blood_diamond"] = bd_num }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function BuyGuildBuffMsgBox:Confirm()
    guild_logic:BuyBuff(self.data1, self.data2)
end

--刺探公会对手
local ScoutGuildRivalMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["scout_guild_rival"])
function ScoutGuildRivalMsgBox:Show(scout_level)
    self.scout_level = scout_level

    local title = lang_constants:Get("guild_war_scout_title")
    local cost_title = lang_constants:Get("guild_war_scout_cost")
    local desc = ""

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
    self.desc_text:setVisible(true)
    
    local _, bd_num = guild_logic:GetScoutInfo(self.scout_level)
    panel_util:LoadCostResourceInfo({["blood_diamond"] = bd_num }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
end

function ScoutGuildRivalMsgBox:Confirm()
    guild_logic:ScoutRival(self.scout_level)
end

--符文抽取直接跳至第四层
local DrawRuneGoToArea4MsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["draw_rune_go_to_area_4"])
function DrawRuneGoToArea4MsgBox:Show()

    panel_util:LoadCostResourceInfo({["blood_diamond"] = constants["RUNE_GO_TU_AREA_4_COST"] }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self:ShowCheckBox(true)

    self.check_box_select_img:setVisible(rune_logic:IsIgnoreGoToArea4Tip())

    self.check_box_btn:setTouchEnabled(true)
    self.check_box_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.check_box_select_img:setVisible(not self.check_box_select_img:isVisible())
        end
    end)

    local title = lang_constants:Get("msgbox_draw_rune_go_to_area_4_title")
    local cost_title = lang_constants:Get("msgbox_draw_rune_go_to_area_4_cost")
    local desc = lang_constants:Get("msgbox_draw_rune_go_to_area_4_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function DrawRuneGoToArea4MsgBox:Confirm()
    rune_logic:SetIgnoreGoToArea4Tip(self.check_box_select_img:isVisible())
    rune_logic:DrawRune( "once", true )
end

--解锁背包
local BuyRuneBagCellMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_rune_bag_cell"])
function BuyRuneBagCellMsgBox:Show()
    local is_can_buy_flag, next_rune_bag_conf = rune_logic:IsCanBuyRuneBugCell(false)

    if not is_can_buy_flag then
        return
    end

    panel_util:LoadCostResourceInfo({["blood_diamond"] = next_rune_bag_conf.cost_num }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    local title = lang_constants:Get("msgbox_buy_rune_bag_title")
    local cost_title = lang_constants:Get("msgbox_buy_rune_bag_cost")
    local desc = string.format(lang_constants:Get("msgbox_buy_rune_bag_desc"), next_rune_bag_conf["capacity"] - rune_logic:GetRuneBagCapacity())

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function BuyRuneBagCellMsgBox:Confirm()
    rune_logic:BuyRuneBugCell()
end

--立即刷新可拦截目标
local RefreshRobTargetImmediatelyMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["refresh_rob_target_immediately"])
function RefreshRobTargetImmediatelyMsgBox:Show()

    panel_util:LoadCostResourceInfo({["blood_diamond"] = constants["ESCORT_REFRESH_ROB_TARGET_LIST_IMMEDIATELY_COST"] }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    local title = lang_constants:Get("msgbox_refresh_rob_target_immediately_title")
    local cost_title = lang_constants:Get("msgbox_refresh_rob_target_immediately_cost")
    local desc = lang_constants:Get("msgbox_refresh_rob_target_immediately_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function RefreshRobTargetImmediatelyMsgBox:Confirm()
    escort_logic:RefreshRobTarget("immediately")
end

--购买拦截次数
local BuyEscortTimesMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_escort_times"])
function BuyEscortTimesMsgBox:Show()
    local could_buy, cost = escort_logic:GetBuyEscortCost(1)
    if not could_buy then
        graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_escort_times")
        return
    end
        
    panel_util:LoadCostResourceInfo({["blood_diamond"] = cost }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    local title = lang_constants:Get("msgbox_buy_escort_times_title")
    local cost_title = lang_constants:Get("msgbox_buy_escort_times_cost")
    local desc = lang_constants:Get("msgbox_buy_escort_times_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function BuyEscortTimesMsgBox:Confirm()
    escort_logic:BuyEscortTimes(1)
end

--购买拦截次数
local RefreshTramcarMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["refresh_tramcar"])
function RefreshTramcarMsgBox:Show(refresh_type)
    if refresh_type == "random" then
        panel_util:LoadCostResourceInfo({["blood_diamond"] = constants["ESCORT_REFRESH_TRAMCAR_RANDOM_COST"] }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
    elseif refresh_type == "specify" then
        panel_util:LoadCostResourceInfo({["blood_diamond"] = constants["ESCORT_REFRESH_TRAMCAR_SPECIFY_COST"] }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)
    else
        return
    end

    local title = lang_constants:Get("msgbox_refresh_tramcar_" .. refresh_type .. "_title")
    local cost_title = lang_constants:Get("msgbox_refresh_tramcar_" .. refresh_type .. "_cost")
    local desc = lang_constants:Get("msgbox_refresh_tramcar_" .. refresh_type .. "_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function RefreshTramcarMsgBox:Confirm()
    escort_logic:RefreshTramcar(self.data1)
end

--刷新解锁矿山
local MineUnlockMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["mine_unlock"])
function MineUnlockMsgBox:Show()
    local title = lang_constants:Get("mine_use_bd_unlock_title")
    local cost_title = lang_constants:Get("mine_use_bd_unlock_cost")
    local desc = lang_constants:Get("msgbox_unlock_mine_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.refresh_time_text:setVisible(false)
    self.desc1_text:setVisible(false)

    local template_id = RESOURCE_TYPE[constants["MINE_UNLOCK_COST"][self.data1][1]]
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], template_id, math.abs(constants["MINE_UNLOCK_COST"][self.data1][2]), false, false)

    self.item_sub_panels[1].root_node:setPositionX(320)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function MineUnlockMsgBox:Confirm()
    local mode = client_constants.CONFIRM_MSGBOX_MODE["mine_sure_unlock_tips"]
    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.data1, self.data2)

end

--矿山刷新使用血钻提示
local MineRefreshUseBloodTips = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["mine_refresh_use_blood_tips"])
function MineRefreshUseBloodTips:Show()

    panel_util:LoadCostResourceInfo({["blood_diamond"] = constants["MINE_REFRESH_REWARD_COST"] }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self:ShowCheckBox(true)

    self.check_box_select_img:setVisible(mine_logic:IsUseBloodTipState())

    self.check_box_btn:setTouchEnabled(true)
    self.check_box_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.check_box_select_img:setVisible(not self.check_box_select_img:isVisible())
        end
    end)

    local title = lang_constants:Get("msgbox_mine_refresh_use_blood_title")
    local cost_title = lang_constants:Get("msgbox_mine_refresh_use_blood_cost_desc")
    local desc = lang_constants:Get("msgbox_mine_refresh_use_blood_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function MineRefreshUseBloodTips:Confirm()
    mine_logic:SetUseBloodTipState(self.check_box_select_img:isVisible())
    mine_logic:RefreshMineAllRewardList( self.data1, self.data2)
end

--黑市使用血钻兑换
local MerchantExchange = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["merchant_exchange"])
function MerchantExchange:Show()
    panel_util:LoadCostResourceInfo({["blood_diamond"] = self.data2[1].costNum }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self:ShowCheckBox(false)


    local title = lang_constants:Get("msgbox_merchant_exchange_use_blood_title")
    local cost_title = lang_constants:Get("msgbox_merchant_exchange_use_blood_cost_desc")
    local desc = lang_constants:Get("msgbox_merchant_exchange_use_blood_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString(desc)

    self.refresh_node:setVisible(false)
end

function MerchantExchange:Confirm()
    merchant_logic:Exchange(self.data1, constants.MERCHANT_TYPE["WHITE"], self.data2)
end

--矿山确认解锁二次弹框
local MineSureUnlockMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["mine_sure_unlock_tips"])
function MineSureUnlockMsgBox:Show()

    self:ShowCheckBox(false)
    

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.refresh_time_text:setVisible(false)
    self.desc1_text:setVisible(false)


    local template_id = RESOURCE_TYPE[constants["MINE_UNLOCK_COST"][self.data1][1]]
    self.item_sub_panels[1]:Show(constants.REWARD_TYPE["resource"], template_id, math.abs(constants["MINE_UNLOCK_COST"][self.data1][2]), false, false)
    self.item_sub_panels[1].root_node:setPositionX(320)
    
    local title = lang_constants:Get("msgbox_sure_mine_unlock_use_blood_title")
    local cost_title = lang_constants:Get("msgbox_sure_mine_unlock_use_blood_cost_desc")
    local desc = string.format(lang_constants:Get("msgbox_sure_mine_unlock_use_blood_desc"), resource_config[template_id].name)

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function MineSureUnlockMsgBox:Confirm()
     --检查血钻消耗
    local cost_num = math.abs(constants["MINE_UNLOCK_COST"][self.data1][2])
    local resource_type = constants.RESOURCE_TYPE[constants["MINE_UNLOCK_COST"][self.data1][1]]
    if not resource_logic:CheckResourceNum(resource_type, cost_num, true) then
        return
    end
    if self.data1 then
        mine_logic:MineUnlock(self.data1)
    end
end

local DrawRuneUseBloodTips = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["draw_rune_use_blood_tips"])
function DrawRuneUseBloodTips:Show()
    local title = lang_constants:Get("msgbox_auto_use_blood_title")
    local cost_title = lang_constants:Get("msgbox_merchant_exchange_use_blood_cost_desc")
    local desc = lang_constants:Get("msgbox_auto_use_blood_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.cost_title_text:setVisible(false)
    self.desc_text:setString(desc)

    self.refresh_time_text:setVisible(false)
    self.desc1_text:setVisible(false)

    self.refresh_node:setVisible(false)

    self:ShowCheckBox(true)

    self.check_box_select_img:setVisible(false)

    self.check_box_btn:setTouchEnabled(true)
    self.check_box_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.check_box_select_img:setVisible(not self.check_box_select_img:isVisible())
        end
    end)

    --隐藏所有的消耗   
    for i = 1, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function DrawRuneUseBloodTips:Confirm()
    if self.data1 then
        self.data1:setVisible(true)
        rune_logic:SetSelectedAutoGo(true)
        rune_logic:SetSelectedAutoGoTips(self.check_box_select_img:isVisible())
    end
end

--限时礼包确认解锁二次弹框
local BuyLimiteUseBloodMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["buy_limite_use_blood_tips"])
function BuyLimiteUseBloodMsgBox:Show()

    self:ShowCheckBox(false)
    

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.refresh_time_text:setVisible(false)
    self.desc1_text:setVisible(false)


    panel_util:LoadCostResourceInfo({["blood_diamond"] = self.data1 }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    
    local title = lang_constants:Get("buy_limite_use_blood_tips_title")
    local cost_title = lang_constants:Get("buy_limite_use_blood_tips_cost_desc")
    local desc = lang_constants:Get("buy_limite_use_blood_tips_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function BuyLimiteUseBloodMsgBox:Confirm()
     --检查血钻消耗
    local resource_type = constants.RESOURCE_TYPE["blood_diamond"]
    if not resource_logic:CheckResourceNum(resource_type, self.data1, true) then
        return
    end
    limite_logic:BuyLimiteByBlood()
end

-- 符文转换消耗血钻确认解锁二次弹框
local RuneExchangeCostMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["rune_exchange_cost_msgbox"])
function RuneExchangeCostMsgBox:Show()

    self:ShowCheckBox(false)
    

    self.refresh_node:setVisible(true)
    self.desc_text:setString("")

    self.refresh_time_text:setVisible(false)
    self.desc1_text:setVisible(false)


    panel_util:LoadCostResourceInfo({["blood_diamond"] = self.data1 }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    
    local title = lang_constants:Get("rune_exchange_cost_msgbox_title")
    local cost_title = lang_constants:Get("buy_limite_use_blood_tips_cost_desc")
    local desc = lang_constants:Get("rune_exchange_cost_msgbox_desc")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.refresh_desc_text:setString(desc)

    for i = 2, MAX_SUB_PANEL_NUM do
        self.item_sub_panels[i].root_node:setVisible(false)
    end
end

function RuneExchangeCostMsgBox:Confirm()
     --检查血钻消耗
    local resource_type = constants.RESOURCE_TYPE["blood_diamond"]
    if not resource_logic:CheckResourceNum(resource_type, self.data1, true) then
        return
    end
    local data2 = self.data2 
    rune_logic:ExchangeRuneProperty(data2[1].rune_id, data2[2].rune_id)
end

--清除冷却时间使用血钻提示
local ClearCallMercenaryMsgBox = confirm_msgbox.NewSubMsgBox(CONFIRM_MSGBOX_MODE["clear_call_mercenary_tips"])
function ClearCallMercenaryMsgBox:Show()
    self.duration = self.data1 or 0

    self.need_cost = math.ceil(self.duration/(60  * constants["RECURIT_LIBRAY_TIME_SETTING"].cost))
    panel_util:LoadCostResourceInfo({["blood_diamond"] = self.need_cost }, self.item_sub_panels, SUB_PANEL_Y, MAX_SUB_PANEL_NUM)

    self:ShowCheckBox(false)


    local title = lang_constants:Get("msgbox_use_bd_refresh_title")
    local cost_title = lang_constants:Get("msgbox_use_bd_refresh_cost")
    local refresh_desc2 = lang_constants:Get("msgbox_clear_call_mercenary_desc2")

    self.title_text:setString(title)
    self.cost_title_text:setString(cost_title)
    self.desc_text:setString("")

    

    self.refresh_node:setVisible(true)
    self.refresh_desc_text:setString(refresh_desc2)
end

function ClearCallMercenaryMsgBox:Confirm()
     --检查血钻消耗
    local resource_type = constants.RESOURCE_TYPE["blood_diamond"]
    if not resource_logic:CheckResourceNum(resource_type, self.need_cost, true) then
        return
    end
    if self.data2 then
        troop_logic:UseBloodClearCutDownTime(self.data2)
    end
    
    
end

return confirm_msgbox
