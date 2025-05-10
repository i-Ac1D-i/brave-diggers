local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"

local lang_constants = require "util.language_constants"

local MSGBOX_MODE = client_constants["QUICK_STORE_MSGBOX_TYPE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]

local PLIST_TYPE = ccui.TextureResType.plistType

local DEFAULT_MAX_NUM = 100

local quick_store_msgbox = panel_prototype.New(true)
function quick_store_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/quick_store_msgbox.csb")
    --关闭按钮
    self.close_btn = self.root_node:getChildByName("close_btn")
    --取消按钮
    self.cancel_btn = self.root_node:getChildByName("cancel_btn")
    --确定按钮
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    local buy_num_bg = self.root_node:getChildByName("buy_num_bg")
    -- +10按钮
    self.increase_btn = buy_num_bg:getChildByName("add_btn_0")
    -- -10按钮
    self.decrease_btn = buy_num_bg:getChildByName("sub_btn")
    --当前数量
    self.buy_num_label = buy_num_bg:getChildByName("buy_num")

    --title
    self.title_label = self.root_node:getChildByName("title")

    --desc 
    self.desc_label = self.root_node:getChildByName("desc")

    self.min_num = 1  -- 默认最小
    self.max_num = DEFAULT_MAX_NUM
    self.increment = 1 --增加量
    self.ok_btn_hide_self = true --确定按钮是否隐藏当前panel

    self:RegisterWidgetEvent()
end

function quick_store_msgbox:Show(callback, model) 
    if callback == nil then
        return
    end  
    self.root_node:setVisible(true)
    self.callback = callback
    self.delta = 0
    self.increment = 1
    self.ok_btn_hide_self = true
    self.model = model

    if MSGBOX_MODE["rune_more_ten"] == self.model then
        --十连抽提示框
        self:RuneDrawMoreTenType()
    end

    self:UpdateCost()
end

--十连抽类型填充界面
function quick_store_msgbox:RuneDrawMoreTenType()
    self.min_num = 10  -- 最小
    self.num = 10   --当前值
    self.increment = 10  --增量值
    self.ok_btn_hide_self = false
    self.desc_label:setString(lang_constants:Get("rune_draw_more_ten_tips"))
    self.title_label:setString(lang_constants:Get("rune_draw_more_ten_title"))
end

--十连抽回调
function quick_store_msgbox:RuneDrawMoreTenCall()
    if self.num > 0 then
        --提示是否要连抽，连续抽取一旦开始，无法中途暂停，请问是否确认开始抽取?
        graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("rune_draw_more_ten_title"),
        lang_constants:Get("rune_draw_more_ten_desc"),
        lang_constants:Get("common_confirm"),
        lang_constants:Get("common_cancel"),
        function()
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            self.callback(self.num)
        end) 
       
    end
end

function quick_store_msgbox:Update(elapsed_time)
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

function quick_store_msgbox:UpdateCost()
    self.num = self.num + self.delta
    if self.num <= self.min_num then
        self.num = self.min_num
        self.decrease_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.decrease_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    if self.num >= self.max_num then
        self.num = self.max_num
        self.increase_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.increase_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end

    self.buy_num_label:setString(self.num)
end

function quick_store_msgbox:RegisterWidgetEvent()

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
            
            if MSGBOX_MODE["rune_more_ten"] == self.model then
                --十连抽提示框
                self:RuneDrawMoreTenCall()
            end
            if self.ok_btn_hide_self then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
        end
    end)

    --自动增加n次按钮监听
    self.increase_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = self.increment
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

    --自动减少n次按钮监听
    self.decrease_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")

            self.delta = -self.increment
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

return quick_store_msgbox
