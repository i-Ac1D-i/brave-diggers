local config_manager = require "logic.config_manager"
local medal_exchange_config = config_manager.medal_exchange_config
local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config

local lang_constants = require "util.language_constants"

local resource_logic = require "logic.resource"
local arena_logic = require "logic.arena"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local icon_template = require "ui.icon_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

--兑换奖励的详细信息panel
local reward_sub_panel = panel_prototype.New()
reward_sub_panel.__index = reward_sub_panel

function reward_sub_panel.New()
    local t = {}
    return setmetatable(t, reward_sub_panel)
end

function reward_sub_panel:Init(root_node, exchange_prize_id)
    self.root_node = root_node
    self.exchange_prize_id = exchange_prize_id

    local root_node = self.root_node
    self.name_text = root_node:getChildByName("name")
    panel_util:SetTextOutline(self.name_text)
    self.desc_text = root_node:getChildByName("desc")
    -- 多语言调整文本大小
    if platform_manager:GetChannelInfo().exchange_reward_msgbox_change_desc_size then
        self.name_text:setPositionY(self.name_text:getPositionY() + 10)
        self.desc_text:setFontSize(self.desc_text:getFontSize() - 2)
        self.desc_text:setContentSize(self.desc_text:getContentSize().width, self.desc_text:getContentSize().height + 40)
    end

    self.exchange_btn = root_node:getChildByName("exchange_btn")

    self.cost_resource_text1  = root_node:getChildByName("cost_resource_num1")
    self.cost_resource_img1 = root_node:getChildByName("cost_resource_icon1")

    self.cost_resource_text2  = root_node:getChildByName("cost_resource_num2")

    self.cost_resource_img2 = root_node:getChildByName("cost_resource_icon2")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_panel:Init(root_node, false)
    self.icon_panel:SetPosition(80, 90)

    self.cost_resource_img1:ignoreContentAdaptWithSize(true)
    self.cost_resource_img2:ignoreContentAdaptWithSize(true)

    self.exchange_btn:setTag(self.exchange_prize_id)
end

function reward_sub_panel:Show()
    local config = medal_exchange_config[self.exchange_prize_id]

    self.template_id = config.param1

    local conf = self.icon_panel:Show(config.reward_type, config.param1, config.param2, false, true)
    self.exchange_btn.reward_name = conf.name

    self.name_text:setString(conf.name)
    self.desc_text:setString(conf.desc)

    self.name_text:setColor(panel_util:GetColor4B(client_constants["TEXT_QUALITY_COLOR"][conf.quality]))

    self.cost_resource_img1:loadTexture(resource_config[config.need_resource1].icon, PLIST_TYPE)
    self.cost_resource_text1:setString(config.need_count1)

    self.cost_resource_img2:loadTexture(resource_config[config.need_resource2].icon, PLIST_TYPE)
    panel_util:ConvertUnit(config.need_count2, self.cost_resource_text2)

    self:RegisterWidgetEvent()
end

function reward_sub_panel:RegisterWidgetEvent()

end

local exchange_reward_msgbox = panel_prototype.New(true)

function exchange_reward_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/exchange_reward_msgbox.csb")
    local root_node = self.root_node

    local top_node = root_node:getChildByName("top")
    self.soul_chip_num_text = top_node:getChildByName("soul_chip_num")

    self.gold_coin_num_text = top_node:getChildByName("gold_coin_num")
    self.king_medal_num_text = top_node:getChildByName("king_medal_num")

    self.list_view = root_node:getChildByName("list_view")
    local template = root_node:getChildByName("template")

    self.reward_sub_panels = {}
    for i = 1, config_manager.medal_exchange_config.MAX_CONF_NUM do
        local sub_panel = reward_sub_panel.New()
        sub_panel:Init(template:clone(), i)
        sub_panel:Show()

        self.reward_sub_panels[i] = sub_panel
        self.list_view:addChild(sub_panel.root_node)
    end

    template:setVisible(false)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function exchange_reward_msgbox:Show(msgbox_type)
    self.root_node:setVisible(true)
    local gold_coin_num = resource_logic:GetResourceNum(RESOURCE_TYPE["gold_coin"])
    local soul_chip_num = resource_logic:GetResourceNum(RESOURCE_TYPE["soul_chip"])
    local king_medal_num = resource_logic:GetResourceNum(RESOURCE_TYPE["king_medal"])

    panel_util:ConvertUnit(gold_coin_num, self.gold_coin_num_text)
    panel_util:ConvertUnit(soul_chip_num, self.soul_chip_num_text)
    panel_util:ConvertUnit(king_medal_num, self.king_medal_num_text)
end

function exchange_reward_msgbox:RegisterEvent()

    graphic:RegisterEvent("update_resource_list", function()

        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["gold_coin"]) then
            local gold_coin_num = resource_logic:GetResourceNum(RESOURCE_TYPE["gold_coin"])
            panel_util:ConvertUnit(gold_coin_num, self.gold_coin_num_text)
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["soul_chip"]) then
            local soul_chip_num = resource_logic:GetResourceNum(RESOURCE_TYPE["soul_chip"])
            panel_util:ConvertUnit(soul_chip_num, self.soul_chip_num_text)
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["king_medal"]) then
            local king_medal_num = resource_logic:GetResourceNum(RESOURCE_TYPE["king_medal"])
            panel_util:ConvertUnit(king_medal_num, self.king_medal_num_text)
        end
    end)
end

function exchange_reward_msgbox:RegisterWidgetEvent()

    local exchange_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local prize_id = widget:getTag()
            local mode = client_constants["BATCH_MSGBOX_MODE"]["exchange_reward"]
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, prize_id, widget.reward_name)
        end
    end

    for i = 1, config_manager.medal_exchange_config.MAX_CONF_NUM do
        self.reward_sub_panels[i].exchange_btn:addTouchEventListener(exchange_method)
    end

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "exchange_reward_msgbox")
end

return exchange_reward_msgbox
