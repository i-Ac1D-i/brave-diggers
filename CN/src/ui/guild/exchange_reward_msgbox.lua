local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local guild_logic = require "logic.guild"
local graphic = require "logic.graphic"

local lang_constants = require "util.language_constants"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local reuse_scrollview = require "widget.reuse_scrollview"

local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config

local PLIST_TYPE = ccui.TextureResType.plistType

local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local SUB_PANEL_HEIGHT = 163
local FIRST_SUB_PANEL_OFFSET = -85
local MAX_SUB_PANEL_NUM = 5

--兑换奖励的详细信息panel
local reward_sub_panel = panel_prototype.New()
reward_sub_panel.__index = reward_sub_panel

function reward_sub_panel.New()
    local t = {}
    return setmetatable(t, reward_sub_panel)
end

function reward_sub_panel:Init(root_node)
    self.root_node = root_node

    local root_node = self.root_node
    self.name_text = root_node:getChildByName("name")
    panel_util:SetTextOutline(self.name_text)

    self.desc_text = root_node:getChildByName("desc")
    self.remain_text = root_node:getChildByName("remain_num")

    self.exchange_btn = root_node:getChildByName("exchange_btn")
    self.cost_resource_text = self.exchange_btn:getChildByName("cost_resource_num")

    self.cant_exchange_img = root_node:getChildByName("cant_exchange")
    self.need_tier_text = self.cant_exchange_img:getChildByName("tier")


    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_panel:Init(root_node, false)
    self.icon_panel:SetPosition(77, 83)
end

function reward_sub_panel:Show(reward_config)
    self.id = reward_config.id
    local rewards = reward_config.rewards
    
    self.template_id = rewards[1].param1

    local conf = self.icon_panel:Show(rewards[1].reward_type, rewards[1].param1, rewards[1].param2, false, true)
    self.exchange_btn.reward_name = conf.name

    self.name_text:setString(conf.name)
    self.desc_text:setString(conf.desc)

    self.name_text:setColor(panel_util:GetColor4B(client_constants["TEXT_QUALITY_COLOR"][conf.quality]))

    if guild_logic:GetMyGuildTier() <= reward_config.need_tier then
        self.cant_exchange_img:setVisible(false)
        self.exchange_btn:setVisible(true)
        self.cost_resource_text:setString(reward_config.need_num)
    else
        self.exchange_btn:setVisible(false)
        self.cant_exchange_img:setVisible(true)
        self.need_tier_text:setString(tostring(reward_config.need_tier))
    end

    if reward_config.limit > 0 then
        self.remain_text:setVisible(true)
        self.remain_text:setString(reward_config.count .. "/" .. reward_config.limit)
    else
        self.remain_text:setVisible(false)
    end

    self.exchange_btn:setTag(self.id)
    
    self.root_node:setVisible(true)
end

local exchange_reward_msgbox = panel_prototype.New(true)

function exchange_reward_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/guildwar_exchange_reward_panel.csb")
    local root_node = self.root_node
    local top_node = root_node:getChildByName("top")
    self.point_coin_num = top_node:getChildByName("point_coin_num")

    self.scroll_view = root_node:getChildByName("scrollview")
    self.template = root_node:getChildByName("template")
    self.template:setVisible(false)

    local my_guild_tier = guild_logic:GetMyGuildTier()
    local exchange_reward_config = guild_logic:GetExchangeRewardConifg()
    self.reward_num = #exchange_reward_config

    self.sub_panel_num = 0
    self.reward_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.reward_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.reward_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(exchange_reward_config[index])
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()
    
    self:CreateSubPanels()
end

function exchange_reward_msgbox:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.reward_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = reward_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.exchange_btn:addTouchEventListener(self.exchange_method)

        self.reward_sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function exchange_reward_msgbox:RefreshScore()
    local guild_war_point = resource_logic:GetResourceNum(RESOURCE_TYPE["guild_war_point"])
    -- panel_util:ConvertUnit(guild_war_point, self.point_coin_num)
    self.point_coin_num:setString(guild_war_point)
end

function exchange_reward_msgbox:Show()
    self:RefreshScore()

    local height = math.max(self.reward_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    local exchange_reward_config = guild_logic:GetExchangeRewardConifg()
    for i = 1, self.sub_panel_num do
        local sub_panel = self.reward_sub_panels[i]

        sub_panel:Show(exchange_reward_config[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)

    self.root_node:setVisible(true)
end


function exchange_reward_msgbox:RegisterEvent()

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["guild_war_point"]) then
            self:RefreshScore()
        end
    end)

    graphic:RegisterEvent("update_guild_exchange_count", function(reward_id)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_num do
            local sub_panel = self.reward_sub_panels[i]
            if sub_panel.id == reward_id then
                local exchange_reward_config = guild_logic:GetExchangeRewardConifg()

                local reward
                for _,reward_config in pairs(exchange_reward_config) do
                    if reward_config.id == reward_id then
                        reward = reward_config
                        break
                    end
                end
            
                sub_panel:Show(reward)
                break
            end
        end
    end)
end

function exchange_reward_msgbox:RegisterWidgetEvent()

    local exchange_reward_config = guild_logic:GetExchangeRewardConifg()

    self.exchange_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local index = widget:getTag()
            local mode = client_constants["BATCH_MSGBOX_MODE"]["guild_exchange_reward"]

            local reward
            for _,reward_config in pairs(exchange_reward_config) do
                if reward_config.id == index then
                    reward = reward_config
                    break
                end
            end

            if reward then
                if reward.limit < 0 or reward.limit > reward.count then
                    graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, reward, widget.reward_name)
                else
                    graphic:DispatchEvent("show_prompt_panel", "guild_war_exchange_limit")
                end
            end
        end
    end

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return exchange_reward_msgbox
