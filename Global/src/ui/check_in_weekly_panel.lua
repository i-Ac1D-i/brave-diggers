local resource_logic = require "logic.resource"
local arena_logic = require "logic.arena"
local graphic = require "logic.graphic"
local daily_logic = require "logic.daily"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local icon_tempalte = require "ui.icon_panel"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local HIGH_ZORDER = 2
local LOW_ZORDER = 1
local INNER_HEIGHT = 118
local TAB_TYPE =
{
    ["weekly"] = 1,
    ["accumulated"] = 2,        --累计
}

local QUALITY_TEMPLATE_TYPE = client_constants["QUALITY_TEMPLATE_TYPE"]

local check_in_weekly_panel = panel_prototype.New(true)

function check_in_weekly_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/check_in_weekly_panel.csb")

    self.weekly_node = self.root_node:getChildByName("weekly_node")
    self.accu_node = self.root_node:getChildByName("metallurgy_node")

    self:InitWeekly()
    self:InitAccumulate()

    self.curr_tab_type = TAB_TYPE.accumulated
    self:UpdateTabStatus(self.curr_tab_type)
    self.root_node:getChildByName("close_btn"):setLocalZOrder(HIGH_ZORDER + 1)

    self:RegisterWidgetEvent()
end

function check_in_weekly_panel:InitWeekly()

    self.weekly_node:setVisible(false)
    self.template = self.weekly_node:getChildByName("template")
    local date_text = self.weekly_node:getChildByName("date")
    local date_text_x = date_text:getPositionX()
    self.reward_items = {}
    self.date_texts = {}
    self.date_texts[1] = date_text

    local begin_x, begin_y, interval_x, interval_y  = 245, 825, 120, 85
    for row = 1, 7 do
        self.reward_items[row] = {}
        local y = begin_y - (row - 1) * interval_y

        for col = 1, 3 do
            local x = begin_x + (col - 1) * interval_x

            local sub_panel = icon_tempalte.New(self.template:clone())
            sub_panel:Init()
            --TODO 这个地方的take_img 有浪费
            sub_panel.take_img = sub_panel.root_node:getChildByName("finish")
            sub_panel.root_node:setPosition(x, y)

            self.weekly_node:addChild(sub_panel.root_node)
            self.reward_items[row][col] = sub_panel
        end

        if row >= 2 then
            self.date_texts[row] = date_text:clone()
            self.date_texts[row]:setPosition(date_text_x, y)
            self.weekly_node:addChild(self.date_texts[row])
        end
    end
    self.template:setVisible(false)
    self.weekly_btn = self.root_node:getChildByName("weekly_tab")
    self.weekly_btn.tag = TAB_TYPE.weekly
end

function check_in_weekly_panel:InitAccumulate()
    self.accu_node:setVisible(false)
    self.accu_btn = self.root_node:getChildByName("metallurgy_tab")
    self.accu_btn.tag = TAB_TYPE.accumulated

    self.list_view = self.accu_node:getChildByName("listview")
    self.template_accu = self.list_view:getChildByName("template1")
    self.list_view:removeChild(self.template_accu, false)
    self.accu_node:addChild(self.template_accu)
    self.accu_items = {}
    self:CreateAccumulateItem(10)
    self.template_accu:setVisible(false)
end

function check_in_weekly_panel:CreateAccumulateItem(create_num)
    local curr_num = #self.accu_items or 0
    if not create_num then
        create_num = 0
    end

    if curr_num == create_num or create_num == 0 then
        return
    end

    if curr_num > create_num then
        for index = create_num + 1, curr_num do
            self.list_view:removeChild(self.accu_items[create_num + 1])
            table.remove(self.accu_items, create_num + 1)
        end
    elseif curr_num < create_num then
        for index = curr_num + 1, create_num do
            local item = self.template_accu:clone()
            item.icon = icon_tempalte.New(item:getChildByName("bg"):getChildByName("icon_location"))
            item.icon:Init(item:getChildByName("bg"), false)
            item.bg = item:getChildByName("bg")
            item.tip = item:getChildByName("get")
            item.value = item:getChildByName("value")
            item.reward_desc = item:getChildByName("bg"):getChildByName("reward_desc")
            item.condition_desc = item:getChildByName("bg"):getChildByName("condition_desc")
            table.insert(self.accu_items, index, item)
            self.list_view:addChild(item)
            item.icon.root_node:setRotation(-90)
            item.icon.root_node:setPosition(56, 82)
        end
    end

    -- 重设listview的大小
    local inner_height = #self.accu_items * INNER_HEIGHT
    self.list_view:setInnerContainerSize(cc.size(541, inner_height))
end

function check_in_weekly_panel:SwitchTab(new_tab_type)

    self.weekly_node:setVisible(false)
    self.accu_node:setVisible(false)
    self.curr_tab_type = new_tab_type
    self:UpdateTabStatus(self.curr_tab_type)

    if self.curr_tab_type == TAB_TYPE.weekly then
        self:ShowWeekly()

    elseif self.curr_tab_type == TAB_TYPE.accumulated then
        self:ShowAccumulated()
    end
end

function check_in_weekly_panel:Show(tab_type)
    local new_tab_type = tab_type or self.curr_tab_type
    self.root_node:setVisible(true)
    self:SwitchTab(new_tab_type)
end

function check_in_weekly_panel:ShowWeekly()
    self.weekly_node:setVisible(true)
    local weekly_list = daily_logic:GetWeeklyList()
    local t_now = time_logic:Now()
    local str = lang_constants:Get("checkin_date")
    local language = platform_manager:GetLocale()
    local language_change = language == "en-US" or language == "de" or language == "fr" or language == "ru" or language == "es-MX"

    for row = 1, 7 do
        local daily_list = weekly_list[row].daily_list
        local current_day_check_in_count = daily_logic:GetTheDayCheckInCount()

        local t = t_now + 86400 * (row - 1)
        local time_info = time_logic:GetDateInfo(t)
        if language_change then 
            self.date_texts[row]:setString(string.format(str, tonumber(time_info.day), tonumber(time_info.month)))
        else
            self.date_texts[row]:setString(string.format(str, tonumber(time_info.month), tonumber(time_info.day)))
        end

        for col = 1, 3 do
            local daily_info = daily_list[col]
            local reward_type = daily_info.reward_type
            local template_id = daily_info.param1
            local num = daily_info.param2

            local sub_panel = self.reward_items[row][col]
            sub_panel:Show(reward_type, template_id, num, false, false)

            if row ~= 1 then
                sub_panel.take_img:setVisible(false)
            else
                if col <= current_day_check_in_count then
                    sub_panel.take_img:setVisible(true)
                else
                    sub_panel.take_img:setVisible(false)
                end
            end
        end
    end
end


function check_in_weekly_panel:ShowAccumulated()
    self.accu_node:setVisible(true)
    local accu_list = daily_logic:GetAccumulateList()
    self:CreateAccumulateItem(#accu_list)
    for index, item in ipairs(self.accu_items) do
        local sub_panel = self.accu_items[index].icon
        local reward_type = accu_list[index].reward_type
        local template_id = accu_list[index].reward_id
        local need_num = accu_list[index].reward_num
        local check_in_num = accu_list[index].check_in_num

        local conf = sub_panel:Show(reward_type, template_id, need_num, false, false)
        item:setVisible(true)
        item.value:setString(check_in_num)
        item.reward_desc:setString(conf.name)
        item.condition_desc:setString(string.format(lang_constants:Get("daily_check_in_accmulate"), check_in_num))
        self:UpdateItemStatus(item, check_in_num)
    end
end

function check_in_weekly_panel:UpdateItemStatus(item, check_in_num)

    -- mark  1：已经领取奖励，显示tip，颜色变暗
    local reward_color = (daily_logic.check_in_count >= check_in_num) and 0x7F7F7F or 0xFFFFFF
    local show_tip = (daily_logic.check_in_count >= check_in_num) and true or false

    item.bg:setCascadeColorEnabled(true)
    item.bg:setCascadeOpacityEnabled(true)
    item.bg:setColor(panel_util:GetColor4B(reward_color))
    item.tip:setVisible(show_tip)
end

function check_in_weekly_panel:UpdateTabStatus(tab_type)
    local week_status = (tab_type == TAB_TYPE.weekly) and  0xFFFFFF or 0x7F7F7F
    local accu_status = (tab_type == TAB_TYPE.accumulated) and  0xFFFFFF or 0x7F7F7F
    self.weekly_btn:setColor(panel_util:GetColor4B(week_status))
    self.accu_btn:setColor(panel_util:GetColor4B(accu_status))

    if tab_type == TAB_TYPE.weekly then
        self.weekly_btn:setLocalZOrder(HIGH_ZORDER)
        self.accu_btn:setLocalZOrder(LOW_ZORDER)

    elseif tab_type == TAB_TYPE.accumulated then
        self.weekly_btn:setLocalZOrder(LOW_ZORDER)
        self.accu_btn:setLocalZOrder(HIGH_ZORDER)
    end
end

function check_in_weekly_panel:RegisterWidgetEvent()

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "check_in_weekly_panel")

    --标签切换
    local tab_listener = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self:SwitchTab(widget.tag)
        end
    end
    self.weekly_btn:addTouchEventListener(tab_listener)
    self.accu_btn:addTouchEventListener(tab_listener)
end

return check_in_weekly_panel
