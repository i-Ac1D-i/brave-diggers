local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"

local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local store_logic = require "logic.store"
local payment_logic = require "logic.payment"

local PLIST_TYPE = ccui.TextureResType.plistType

local goods_info_sub_panel = panel_prototype.New()
goods_info_sub_panel.__index = goods_info_sub_panel


function goods_info_sub_panel.New()
    return setmetatable({}, goods_info_sub_panel)
end

function goods_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node)
    self.icon_panel:SetPosition(-130, 85)
    self.buy_btn = root_node:getChildByName("buy_btn")
    self.tip_bg = root_node:getChildByName("tip_bg")
    self.tip_bg:setLocalZOrder(100)
    self.tip_desc = self.tip_bg:getChildByName("desc")    

    self.desc_text = root_node:getChildByName("desc")
    self.name_text = root_node:getChildByName("name")
    self.price_text = self.buy_btn:getChildByName("price")
end

function goods_info_sub_panel:Show(goods_info)
    local quality = goods_info.quality
    self.icon_panel:Show(constants.REWARD_TYPE["reward_group"], 0, goods_info.icon, quality, true)

    local goods_name
    if goods_info["max_buy_count"] then
        goods_name = string.format(lang_constants:Get("store_already_buy_count"), goods_info.name, goods_info.already_buy_count)
        self.tip_desc:setString(string.format(lang_constants:Get("store_max_buy_count"), goods_info.max_buy_count))
        self.tip_bg:setVisible(true)
    else
        goods_name = goods_info.name
    end

    local goods_price = store_logic:QueryTrendPrice(goods_info, 1)

    self.name_text:setString(goods_name)
    self.desc_text:setString(goods_info.desc)
    self.price_text:setString(goods_price)

    self.root_node:setVisible(true)
end

local store_panel = panel_prototype.New()
function store_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/store_panel.csb")

    self.goods_info_sub_panels = {}
    self.goods_sub_panel_num = 0

    self.goods_list = self.root_node:getChildByName("goods_list")

    self.goods_template = self.root_node:getChildByName("order_panel")
    self.goods_template:setVisible(false)
    self.list_boader = self.goods_list:getChildByName("list_boader")

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.payment_btn = self.root_node:getChildByName("payment_btn")
    self.buy_txt = self.payment_btn:getChildByName("buy_txt")

    local channel = platform_manager:GetChannelInfo()
    if channel.meta_channel ~= "txwy_dny" then
        --东南亚渠道不加描边
        panel_util:SetTextOutline(self.buy_txt)
    end
    

    --on_scale
    if feature_config:IsFeatureOpen("store_double_reward") then
        self.buy_txt:setString(lang_constants:Get("store_on_scale_text"))
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function store_panel:Show()
    self.root_node:setVisible(true)

    local goods_num = store_logic:GetGoodsNum()
    if self.goods_sub_panel_num < goods_num then

        for i = self.goods_sub_panel_num + 1, goods_num do
            local sub_panel = goods_info_sub_panel.New()

            sub_panel:Init(self.goods_template:clone())
            sub_panel.buy_btn:setTag(i)
            sub_panel.buy_btn:addTouchEventListener(self.buy_method)

            self.goods_list:insertCustomItem(sub_panel.root_node, i)
            self.goods_info_sub_panels[i] = sub_panel
        end

        local list_boader = self.list_boader:clone()
        self.goods_list:insertCustomItem(list_boader, #self.goods_info_sub_panels+1)

        self.goods_sub_panel_num = goods_num
    end

    for i = 1, self.goods_sub_panel_num do
        local sub_panel = self.goods_info_sub_panels[i]
        if i <= goods_num then
            sub_panel:Show(store_logic:GetGoodsInfo(i))
        else
            sub_panel:Hide()
        end
    end
end

function store_panel:RegisterEvent()
    graphic:RegisterEvent("store_buy_success", function(goods_id)
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)
end

function store_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    self.payment_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not payment_logic.enable_pay then
                graphic:DispatchEvent("show_prompt_panel", "payment_purchase_not_available")
            else
                graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene")
            end
        end
    end)

    self.buy_method =  function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local goods_index = widget:getTag()
            local mode = client_constants.BATCH_MSGBOX_MODE.blood_store
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
        end
    end

end

return store_panel
