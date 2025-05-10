local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"

local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local merchant_logic = require "logic.merchant"
local time_logic = require "logic.time"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local REWARD_TYPE = constants["REWARD_TYPE"]
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local jump_logic = require 'logic.jump'
local JUMP_CONST = client_constants["JUMP_CONST"] 

local PLIST_TYPE = ccui.TextureResType.plistType

local RANDOM_KEY_ICON = client_constants["RANDOM_KEY_ICON"]
local RANDOM_KEY_QUALITY = 5
local RANDOM_KEY_NAME = lang_constants:Get("random_key_name")
local RANDOM_KEY_DESC = lang_constants:Get("random_key_desc")

local DARK_TAB_SHOW = constants.MERCHANT_TYPE["DARK"]
local WHITE_TAB_SHOW = constants.MERCHANT_TYPE["WHITE"]

local TAB_NOT_CLICKED_COLOR = 0x7F7F7F
local TAB_CLICKED_COLOR = 0xFFFFFF

local order_sub_panel = panel_prototype.New()
order_sub_panel.__index = order_sub_panel

function order_sub_panel.New()
    return setmetatable({}, order_sub_panel)
end

function order_sub_panel:Init(root_node, merchant_type)
    self.root_node = root_node
    self.merchant_type = merchant_type
    self.need_icon_panels = {}
    self.order_id = nil 

    for i = 1, 2 do
        local icon_panel = icon_template.New()
        icon_panel:Init(root_node)
        self.need_icon_panels[i] = icon_panel
        self.need_icon_panels[i].root_node:setScale(0.5, 0.5)
    end
    self.need_icon_panels[1].root_node:setPosition(50, 34)
    self.need_icon_panels[2].root_node:setPosition(90, 34)

    self.reward_icon_panel = icon_template.New()
    self.reward_icon_panel:Init(root_node)
    self.reward_icon_panel.root_node:setScale(0.5, 0.5)
    self.reward_icon_panel.root_node:setPosition(176, 34)

    self.exchange_btn = root_node:getChildByName("exchange_btn")
    self:RegisterWidgetEvent()
end

function order_sub_panel:Show(order_info)
    -- 每个订单有一个列表记录该订单缺少的资源 
    self.less_resources = {} 
    self.cost_list = {}
    for i = 1, 2 do
        local resource_type = order_info["need_type" .. i]

        if resource_type and resource_type ~= 0 then
            -- 资源跳转
            if not resource_logic:CheckResourceNum(resource_type, order_info["need_num" .. i], false,true) then
                local less_cost = {}
                less_cost["resourceId"] = resource_type
                less_cost["costNum"] = order_info["need_num" .. i]
                table.insert(self.less_resources,less_cost)  
            end
            
            local cost = {}
            cost["resourceId"] = resource_type
            cost["costNum"] = order_info["need_num" .. i]
            table.insert(self.cost_list,cost)

            self.need_icon_panels[i]:Show(REWARD_TYPE["resource"], resource_type, order_info["need_num" .. i], true)
        else
            self.need_icon_panels[i].root_node:setVisible(false)
        end
    end

    local reward_info = order_info.reward_info[1]
    self.reward_icon_panel:Show(reward_info.reward_type , reward_info.param1, reward_info.param2)

    self.root_node:setVisible(true)
end

function order_sub_panel:GetOrderId()
    return self.order_id 
end

function order_sub_panel:SetOrderId(id)
    self.order_id = id
end

function order_sub_panel:SetVisible(flag)
    self.root_node:setVisible(flag)
end

function order_sub_panel:SetAnchorPoint(point)
    self.root_node:setAnchorPoint(point)
end  

function order_sub_panel:SetPosition(x, y)
    self.root_node:setPosition(x, y)
end

function order_sub_panel:SetButtonColor(color)
    self.exchange_btn:setColor(panel_util:GetColor4B(color))
end

function order_sub_panel:SetButtonTitle(title_name)
    self.exchange_btn:setTitleText(title_name)
end

function order_sub_panel:RegisterWidgetEvent()
    self.exchange_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local merchant_types = self.merchant_type
            if self.merchant_type == constants.MERCHANT_TYPE["dark1"] or self.merchant_type == constants.MERCHANT_TYPE["dark2"] or self.merchant_type == constants.MERCHANT_TYPE["dark3"] then
                 merchant_types = constants.MERCHANT_TYPE["DARK"]
            end

            --  如果资源缺失列表中元素大于0 而且开关打开  还有必须是在表中配置过的,如果没有配置过的话,则走原来的流程
            -- if feature_config:IsFeatureOpen("resource_jump") and #self.less_resources > 0 and jump_logic:GetJumpResources()[self.less_resources[1]] then  
            --     graphic:DispatchEvent("show_jump_panel",self.less_resources[1])  
            -- else
            if merchant_logic:IsExchange(self.order_id, self.merchant_type) then
                if self.merchant_type == constants.MERCHANT_TYPE["WHITE"] then
                    --血钻兑换
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["merchant_exchange"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.order_id, self.cost_list)
                else
                    merchant_logic:Exchange(self.order_id, self.merchant_type, self.less_resources)
                end
            end
                
            -- end
        end
    end)
end

local merchant_tab = panel_prototype.New()
merchant_tab.__index = merchant_tab

function merchant_tab.New()
    return setmetatable({}, merchant_tab)
end

function merchant_tab:Init(parent_node, merchant_type)
    self.merchant_type = merchant_type
    self.exchange_btn = nil
    self.duration = 0
    if self.merchant_type == DARK_TAB_SHOW then 
       self.root_node = parent_node:getChildByName("black_tab")
       self.bottom_node = parent_node:getChildByName("bonus_node_b")
       self.exchange_btn = self.bottom_node:getChildByName("ext_exchange_btn")
       self.bottom_node:getChildByName("bonus_icon_a"):setVisible(false)
       self.bottom_node:getChildByName("bonus_icon_b"):setVisible(false)
       self.exchange_btn:setTouchEnabled(true)
    elseif self.merchant_type == WHITE_TAB_SHOW then 
       self.root_node = parent_node:getChildByName("white_tab")
       self.bottom_node = parent_node:getChildByName("bonus_node_w")
    end

    self.root_node:setTag(self.merchant_type)
    self.root_node:setTouchEnabled(true)
    self.root_node:setCascadeColorEnabled(true)

    self.tab_text = self.root_node:getChildByName("name")
    self.tab_text:setCascadeColorEnabled(true)
    self.back_btn = self.bottom_node:getChildByName("back_btn")
    self.back_btn:setTouchEnabled(true)
    self.refresh_btn = self.bottom_node:getChildByName("refresh_btn")
    self.reset_time_text = self.refresh_btn:getChildByName("refresh_time")
    self.refresh_btn:setTouchEnabled(true)

    self:RegisterWidgetEvent()
end

function merchant_tab:Update(time)
    self.duration = self.duration - time
    self:SetTimeText()
end

function merchant_tab:SetDurationTime(time)
    self.duration = time
end

function merchant_tab:SetTimeText()
    self.reset_time_text:setString(panel_util:GetTimeStr(self.duration))
end

function merchant_tab:SetTabColor(color)
    self.root_node:setColor(panel_util:GetColor4B(color))
    self.tab_text:setColor(panel_util:GetColor4B(color))
end

function merchant_tab:Show()
    self.root_node:setVisible(true)
    self.bottom_node:setVisible(true)
end
        
function merchant_tab:SetBottomVisible(flag)
    self.bottom_node:setVisible(flag)
end

function merchant_tab:GetBottomNode()
    return self.bottom_node
end

function merchant_tab:SetExchangeButtonVisible(flag)
    if self.exchange_btn then
       self.exchange_btn:setVisible(flag)
    end
end

function merchant_tab:SetExchangeButtonColor(color)
    if self.exchange_btn then
       self.exchange_btn:setColor(panel_util:GetColor4B(color))
    end
end

function merchant_tab:Clear()
    self.root_node:removeAllChildren()
    self.bottom_node:removeAllChildren()
end

function merchant_tab:Hide()
    self.root_node:setVisible(false)
    self.bottom_node:setVisible(false)
end

function merchant_tab:RegisterWidgetEvent()
    --重置时间
    self.refresh_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["CONFIRM_MSGBOX_MODE"]["refresh_order"]
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.merchant_type)
        end
    end)

    if self.exchange_btn then
        --获取额外奖励
        self.exchange_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if not merchant_logic:CanCollectSoulChip() then
                    graphic:DispatchEvent("show_prompt_panel", "merchant_finish_all_order_first")
                else
                    merchant_logic:CollectSoulChip()
                end
            end
        end)
    end

    -- 返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

end

local merchant_panel = panel_prototype.New()

function merchant_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/merchant_panel.csb")
    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.dark_bonus_panels = {}
    self.tab_node = { [DARK_TAB_SHOW] = {}, [WHITE_TAB_SHOW] = {}}
    self.order_sub_panels = {[DARK_TAB_SHOW] = {}, [WHITE_TAB_SHOW] = {}}
   
    for i = 1, #self.tab_node do 
        self.tab_node[i] = merchant_tab.New()
        self.tab_node[i]:Init(self.root_node, i)
    end
    
    self.tab_node[DARK_TAB_SHOW]:SetTabColor(TAB_CLICKED_COLOR)

    self.tab_node[WHITE_TAB_SHOW]:SetTabColor(TAB_NOT_CLICKED_COLOR)
    self.tab_node[WHITE_TAB_SHOW]:SetBottomVisible(false)
    self.scroll_view:setVisible(false)

    self.show_tab = DARK_TAB_SHOW

    local begin_x = 492
    for i = 1, 2 do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.tab_node[DARK_TAB_SHOW]:GetBottomNode())
        sub_panel.root_node:setPosition(begin_x + (i - 1) * 83, 536)
        self.dark_bonus_panels[i] = sub_panel
    end

    local order_panel = self.root_node:getChildByName("order_bg")
    local order_panel_init_x, order_panel_init_y = order_panel:getPosition()
    order_panel:setVisible(false)
    local scroll_view_size = self.scroll_view:getContentSize()
    local scroll_view_half_width = scroll_view_size.width/2

    for tab_i = 1, #self.tab_node do 
       for i = 1, 3 do
          self.order_sub_panels[tab_i][i] = order_sub_panel.New()
          self.order_sub_panels[tab_i][i]:Init(order_panel:clone(), tab_i)

          if tab_i == DARK_TAB_SHOW then
            self.order_sub_panels[tab_i][i]:SetPosition(order_panel_init_x, order_panel_init_y - (i-1) * 188)
            self.root_node:addChild(self.order_sub_panels[tab_i][i]:GetRootNode())

          elseif tab_i == WHITE_TAB_SHOW then
            self.order_sub_panels[tab_i][i]:SetAnchorPoint(cc.p(0.5, 1))
            self.order_sub_panels[tab_i][i]:SetPosition(scroll_view_half_width, scroll_view_size.height - (i-1) * 188)
            self.scroll_view:addChild(self.order_sub_panels[tab_i][i]:GetRootNode())
          end
       end
    end

    --r2界面要隐藏按钮上的bonus图标
    local merchant_panel_hide_button_icon=platform_manager:GetChannelInfo().merchant_panel_hide_button_icon
    if merchant_panel_hide_button_icon then
        local get_btn_icon = self.root_node:getChildByName("bonus_node_b"):getChildByName("ext_exchange_btn"):getChildByName("bonus_1")
        get_btn_icon:setVisible(false)
        local bonus_icon = self.root_node:getChildByName("bonus_node_b"):getChildByName("bonus")
        bonus_icon:setVisible(false)
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function merchant_panel:SetDarkOrdersVisible(flag)
    for i = 1, #self.order_sub_panels[DARK_TAB_SHOW] do 
        self.order_sub_panels[DARK_TAB_SHOW][i]:SetVisible(flag)
    end
end

function merchant_panel:LoadTab(new_tab)
    local new_tab = new_tab or 0

    if new_tab > 0 then 
       self:SwitchTabShow(false)
       self.show_tab = new_tab
    end

    self:LoadInfo()
    self:SwitchTabShow(true)
end

function merchant_panel:SwitchTabShow(flag)
    local tab_color = TAB_NOT_CLICKED_COLOR
    if flag then 
        tab_color = TAB_CLICKED_COLOR
    end

    if self.show_tab == DARK_TAB_SHOW then 
        self:SetDarkOrdersVisible(flag)

    elseif self.show_tab == WHITE_TAB_SHOW then 
        self.scroll_view:setVisible(flag)
    end

    self.tab_node[self.show_tab]:SetTabColor(tab_color)
    self.tab_node[self.show_tab]:SetBottomVisible(flag)
end

function merchant_panel:Show()
    self:LoadTab()
    self.root_node:setVisible(true)
end

function merchant_panel:LoadInfo()
    local order_num = merchant_logic:GetOrderNum(self.show_tab)

    --订单
    for i = 1, 3 do
        local sub_panel = self.order_sub_panels[self.show_tab][i]
        if i <= order_num then
            local order_info = merchant_logic:GetOrderInfo(i, self.show_tab)
            sub_panel:Show(order_info)
            sub_panel:SetOrderId(order_info.order_id)
        
            if order_info.is_done then
                sub_panel:SetButtonColor(0x7f7f7f)
                sub_panel:SetButtonTitle(lang_constants:Get("merchant_order_btn2"))
            else
                sub_panel:SetButtonColor(0xffffff)
                sub_panel:SetButtonTitle(lang_constants:Get("merchant_order_btn1"))
            end
        else
            sub_panel:Hide()
        end
    end

    if self.show_tab == DARK_TAB_SHOW then 
        --额外奖励
        if platform_manager:GetChannelInfo().merchant_show_reward_box then
            self.dark_bonus_panels[1]:Load(REWARD_TYPE["resource"], 'icon/festival/chest.png', RANDOM_KEY_QUALITY, 1,RANDOM_KEY_NAME, RANDOM_KEY_DESC, false)
        else
            if merchant_logic.chest_key_id == 0 then
                self.dark_bonus_panels[1]:Load(REWARD_TYPE["resource"], RANDOM_KEY_ICON, RANDOM_KEY_QUALITY, 1,RANDOM_KEY_NAME, RANDOM_KEY_DESC, false)
            else
                self.dark_bonus_panels[1]:Show(REWARD_TYPE["resource"], merchant_logic.chest_key_id, merchant_logic.chest_key_num, false, false)
            end
        end

        if merchant_logic.extra_soul_chip_num > 0 then
            self.dark_bonus_panels[2]:Show(REWARD_TYPE["resource"], RESOURCE_TYPE["soul_chip"], merchant_logic.extra_soul_chip_num, false, false)
        else
            self.dark_bonus_panels[2].root_node:setVisible(false)
        end
        self.tab_node[DARK_TAB_SHOW]:SetExchangeButtonVisible(true) 

        self:UpdateExtra()
    end

    --更新刷新时间
    self.tab_node[self.show_tab]:SetDurationTime(merchant_logic:GetResetTime(self.show_tab) - time_logic:Now())
    self.tab_node[self.show_tab]:SetTimeText()
end

function merchant_panel:UpdateExtra()
    if merchant_logic.has_collected_soul_chip then
        self.tab_node[DARK_TAB_SHOW]:SetExchangeButtonVisible(false)
        self.tab_node[DARK_TAB_SHOW]:SetExchangeButtonColor(0x7f7f7f)  
    else
        self.tab_node[DARK_TAB_SHOW]:SetExchangeButtonVisible(true) 
        self.tab_node[DARK_TAB_SHOW]:SetExchangeButtonColor(0xffffff) 
    end
end

function merchant_panel:Update(elapsed_time)
    self.tab_node[self.show_tab]:Update(elapsed_time)
end

function merchant_panel:RegisterWidgetEvent()
    -- tab
    local tab_touch_event = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local tab_type = widget:getTag()
            self:LoadTab(tab_type)
        end
    end
    
    for i = 1, #self.tab_node do 
        self.tab_node[i]:GetRootNode():addTouchEventListener(tab_touch_event)
    end
end

function merchant_panel:RegisterEvent()
    graphic:RegisterEvent("update_merchant_info", function(update_type, order_id, merchant_type)
        if not self.root_node:isVisible() then
            return
        end

        self:LoadInfo()

        if update_type == "order" then
            for i = 1, 3 do
                if self.order_sub_panels[merchant_type][i]:GetOrderId() == order_id then
                    self.order_sub_panels[merchant_type][i]:SetButtonColor(0x7f7f7f) 
                    self.order_sub_panels[merchant_type][i]:SetButtonTitle(lang_constants:Get("merchant_order_btn2"))
                end
            end

            self:UpdateExtra()
        elseif update_type == "extra" then
            --已经领取完额外奖励
            self:UpdateExtra()
        end
    end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function merchant_panel:RefreshResource()
    if self.order_sub_panels then
        for _index,order in pairs(self.order_sub_panels[DARK_TAB_SHOW]) do
            if order.need_icon_panels then
                for k,v in pairs(order.need_icon_panels) do
                    local resourceType = v:GetIconResourceType()
                    if resource_logic:IsResourceUpdated(resourceType) then
                        v:SetTextStatus(resourceType)
                    end
                end
            end
        end
    end
end

return merchant_panel
