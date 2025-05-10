local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local campaign_logic = require "logic.campaign"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local resource_logic = require "logic.resource"
local lang_constants = require "util.language_constants"
local client_constants = require "util.client_constants"

local icon_text_panel = require "ui.icon_panel"
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local json = require "util.json"

local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config
local item_config = config_manager.item_config

local PLIST_TYPE = ccui.TextureResType.plistType
local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local CAMPAIGN_REWARD_TYPE = constants["CAMPAIGN_REWARD_TYPE"]

local TAB_TYPE =
{
    ["rank"] = 1,
    ["score"] = 2,
}

-- 设置列表控件内容
local function SetItemInfo(root, data)
    if data.type == CAMPAIGN_REWARD_TYPE["score"] then
        --赛点兑换
        local tip_bg = root:getChildByName("tip_bg")
        local get_btn = root:getChildByName("get_btn")

        if data.limit == -1 then
            tip_bg:setVisible(false)
        else
            local value = data.limit - data.count
            local desc = tip_bg:getChildByName("desc")
            if value > 0 then
                get_btn:setVisible(true)
                desc:setString(string.format(lang_constants:Get("campaign_reward_limit_desc"),value))
            else
                get_btn:setVisible(false)
                desc:setString(lang_constants:Get("campaign_reward_limit_full"))
            end
        end

        local reward = data.rewards[1]
        local conf = root.icon_panel:Show(reward.reward_type, reward.param1, reward.param2, false, true)

        local name_text = root:getChildByName("name")
        name_text:setString(conf.name)
        name_text:setColor(panel_util:GetColor4B(client_constants["TEXT_QUALITY_COLOR"][conf.quality]))

        local desc_text = root:getChildByName("desc")
        desc_text:setString(conf.desc)

        local cost_resource_num1 = get_btn:getChildByName("cost_resource_num1")
        cost_resource_num1:setString(data.req_value[1])

        return conf.name

    elseif data.type == CAMPAIGN_REWARD_TYPE["rank"] then
        --排名奖励兑换

        for k,v in pairs(data.rewards) do
            local icon_panel = root.reward_icon_panel[k]
            icon_panel:Show(v.reward_type, v.param1, v.param2, false, false)
        end

        local rank_min_text = root:getChildByName("rank")
        local rank_max_text = root:getChildByName("rank_2")

        if data.req_value[1] then
            rank_min_text:setString(data.req_value[1])
        end

        if data.req_value[2] then
            rank_max_text:setString(data.req_value[2])
        end


        local exchange_btn = root:getChildByName("exchange_btn")
        if campaign_logic.status ~= constants.CAMPAIGN_STATUS.reward then
            exchange_btn:setTitleText(lang_constants:Get("campaign_reward_date"))
            exchange_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        else
            exchange_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
            if #data.req_value == 1 and campaign_logic.rank ~= data.req_value[1] then
                -- 条件是1个，那排名不相等
                exchange_btn:setTitleText(lang_constants:Get("campaign_reward_rank_not_enought"))
                return
            elseif #data.req_value == 2 and (campaign_logic.rank < data.req_value[1] or campaign_logic.rank > data.req_value[2]) then
                -- 条件是2个。那么<>
                exchange_btn:setTitleText(lang_constants:Get("campaign_reward_rank_not_enought"))
                return
            elseif #data.req_value > 2 then
                exchange_btn:setTitleText(lang_constants:Get("campaign_reward_rank_not_enought"))
                return
            end
            if data.count > 0 then
                exchange_btn:setTitleText(lang_constants:Get("campaign_reward_rank_convert"))
            else
                exchange_btn:setTitleText(lang_constants:Get("campaign_reward_rank_tips"))
                exchange_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
            end
        end
    end
end

local campaign_reward_msgbox = panel_prototype.New(true)
function campaign_reward_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_exchange_panel.csb")

    self.res_tab = self.root_node:getChildByName("res_tab")
    self.res_tab:setTouchEnabled(true)

    self.item_tab = self.root_node:getChildByName("item_tab")
    self.item_tab:setTouchEnabled(true)

    local top = self.root_node:getChildByName("top")

    self.time1 = top:getChildByName("time1")
    self.time2 = top:getChildByName("time2")
    self.last_time = self.time1:getChildByName("time_num")
    self.ladder_icon = top:getChildByName("ladder_icon")
    self.ladder_desc = top:getChildByName("ladder_desc")
    self.ladder_num = top:getChildByName("ladder_num")
    self.top_desc_text = top:getChildByName("desc")

    self.cur_tab_type = nil

    self.rank_reward_list = self.root_node:getChildByName("rank_list_view")
    self.rank_reward_list:setVisible(false)

    self.score_reward_list = self.root_node:getChildByName("integral_list_view")
    self.score_reward_list:setVisible(false)

    local score_temp = self.root_node:getChildByName("point_template")
    score_temp:setVisible(false)

    self.item_list = {}
    self.item_list[TAB_TYPE.rank] = {}
    self.item_list[TAB_TYPE.score] = {}

    self:RegisterWidgetEvent()
    self:RegisterEvent()

    local rank_temp = self.rank_reward_list:getChildByName("template4")
    local rank_reward_index = 1
    for k,v in pairs(campaign_logic.reward_list) do
        if v.type == CAMPAIGN_REWARD_TYPE["score"] then
            local item = score_temp:clone()
            item:setVisible(true)
            self.score_reward_list:addChild(item)
            local get_btn = item:getChildByName("get_btn")
            get_btn.data = v
            get_btn:addTouchEventListener(self.take_reward_method)

            item.icon_panel = icon_text_panel.New(nil, 2)
            item.icon_panel:Init(item:getChildByName("iconbg"))
            item.icon_panel:SetPosition(55, 55)

            self.item_list[v.type][v.id] = item

        elseif v.type == CAMPAIGN_REWARD_TYPE["rank"] then
            local item = self.rank_reward_list:getChildByName("template"..rank_reward_index)
            if not item then
                item = rank_temp:clone()
                self.rank_reward_list:addChild(item)
            end
            item:setVisible(true)

            local exchange_btn = item:getChildByName("exchange_btn")
            exchange_btn.data = v
            exchange_btn:addTouchEventListener(self.take_reward_method)
            item.reward_icon_panel = {}

            for kk,vv in pairs(v.rewards) do
                local icon_panel = icon_text_panel.New()
                icon_panel:Init(item)
                icon_panel:SetPosition(125 + kk * 88, 78)
                item.reward_icon_panel[kk] = icon_panel
            end
            self.item_list[v.type][v.id] = item
            rank_reward_index = rank_reward_index + 1
        end
    end
end

function campaign_reward_msgbox:Show()
    self.root_node:setVisible(true)
    self:UpdateTabStatus(TAB_TYPE["score"])

    if campaign_logic.status == constants.CAMPAIGN_STATUS.reward then
        self.time1:setVisible(true)
        self.time2:setVisible(false)
    else
        self.time1:setVisible(false)
        self.time2:setVisible(true)
    end

    self.names = {}
    for k,v in pairs(campaign_logic.reward_list) do
        local reward_item = self.item_list[v.type][v.id]
        self.names[v.id] = SetItemInfo(reward_item, v)
    end
end

-- 更新标签状态
function campaign_reward_msgbox:UpdateTabStatus(tab_type)
    self.cur_tab_type = tab_type

    if tab_type == TAB_TYPE["rank"] then
        self.item_tab:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.res_tab:setColor(panel_util:GetColor4B(0x7F7F7F))

        self.ladder_icon:loadTexture(client_constants["CAMPAIGN_RESOURCE_ICON"].rank,PLIST_TYPE)
        self.ladder_icon:ignoreContentAdaptWithSize(false)
        self.ladder_desc:setString(lang_constants:Get("campaign_res_rank"))
        self.top_desc_text:setString(lang_constants:Get("campaign_reward_rank_desc"))
        if campaign_logic.rank == 0  then
            self.ladder_num:setString("---")
        else
            self.ladder_num:setString(campaign_logic.rank)
        end

        self.rank_reward_list:setVisible(true)
        self.score_reward_list:setVisible(false)

    elseif tab_type == TAB_TYPE["score"] then
        self.res_tab:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.item_tab:setColor(panel_util:GetColor4B(0x7F7F7F))

        self.ladder_num:setString(campaign_logic.score)

        self.ladder_icon:loadTexture(client_constants["CAMPAIGN_RESOURCE_ICON"].score,PLIST_TYPE)
        self.ladder_icon:ignoreContentAdaptWithSize(true)
        self.ladder_desc:setString(lang_constants:Get("campaign_res_total_score"))
        self.top_desc_text:setString(lang_constants:Get("campaign_reward_score_desc"))
        self.ladder_num:setString(resource_logic:GetResourceNum(constants.RESOURCE_TYPE.campaign_score))


        self.rank_reward_list:setVisible(false)
        self.score_reward_list:setVisible(true)
    end
end

function campaign_reward_msgbox:RegisterEvent()
    graphic:RegisterEvent("update_campaign_reward_time", function(elapsed_time)
        if self.root_node:isVisible() then
            local duration = time_logic:GetDurationToFixedTime(campaign_logic.end_time)
            self.last_time:setString(panel_util:GetTimeStr(duration - elapsed_time))
        end
    end)

    graphic:RegisterEvent("update_campaign_reward_score",function (score)
        audio_manager:PlayEffect("campaign_exchange_success")
        self.ladder_num:setString(score)
    end)

    graphic:RegisterEvent("update_campaign_reward_info",function (reward)
        local reward_item = self.item_list[reward.type][reward.id]
        SetItemInfo(self.item_list[reward.type][reward.id], reward)
    end)
end

function campaign_reward_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "campaign_reward_msgbox")

    self.item_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.cur_tab_type ~= TAB_TYPE.rank then
                self:UpdateTabStatus(TAB_TYPE.rank)
            end

        end
    end)

    self.res_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.cur_tab_type ~= TAB_TYPE.score then
                self:UpdateTabStatus(TAB_TYPE.score)
            end
        end
    end)

    self.take_reward_method = function (widget,event_type)
        if event_type == ccui.TouchEventType.ended then
            local data = widget.data
            if data.type == CAMPAIGN_REWARD_TYPE["score"] then
                local mode = client_constants.BATCH_MSGBOX_MODE.convert_campaign_reward
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, self.names[data.id], data)
            elseif data.type == CAMPAIGN_REWARD_TYPE["rank"] then
                campaign_logic:ConvertReward(data)
            end
        end
    end
end

return campaign_reward_msgbox
