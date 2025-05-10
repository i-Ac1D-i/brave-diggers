local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local audio_manager = require"util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local time_logic = require "logic.time"
local campaign_logic = require "logic.campaign"
local vip_logic = require "logic.vip"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local mercenary_template_panel = require "ui.mercenary_template_panel"
local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local mercenary_preview_sub_panel = require "ui.mercenary_preview_panel"
local spine_manager = require "util.spine_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_RANGE = client_constants["SORT_RANGE"]

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local MERCENARY_MSGBOX = client_constants["MERCENARY_MSGBOX"] --佣兵弹窗

local MERCENARY_TEMPLATE_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["list"]
local MAX_MERCENARY_NUM_PER_ROW = 5

local MAX_PANEL_ROW = 6        --最大row
local MAX_MERCENARY_NUM = 40   --最大佣兵个数
local MERCENARY_BEGIN_X = 72   --佣兵显示的初始位置x
local MERCENARY_BEGIN_Y = 700  --佣兵显示的初始位置y
local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -70

--选中动画
local select_spine_tracker = {}
select_spine_tracker.__index = select_spine_tracker

function select_spine_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node

    t.root_node:registerSpineEventHandler(function(event)
        t.finish_choose = true
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, select_spine_tracker)
end

function select_spine_tracker:Bind(animation, x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.animation = animation

    self.offset_x = x

    self.offset_y = y

    self.widget = widget

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)

    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, self.animation, false)
    self.finish_choose = false
end

function select_spine_tracker:Update()
    if not self.finish_choose then
        if self.root_node:isVisible() and self.widget then
            local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
            self.widget:setScale(scale_x, scale_y)
        end
    end
end

local mercenary_list_panel = panel_prototype.New()

function mercenary_list_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_list_panel.csb")
    local root_node = self.root_node
    self.sort_btn = root_node:getChildByName("sort_btn")
    self.sort_desc_text = self.sort_btn:getChildByName("desc")
    self.back_btn = root_node:getChildByName("back_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template"):getChildByName("mercenary_template")
    self.mercenary_template:setVisible(false)

    self.select_img = self.scroll_view:getChildByName("select")
    self.select_img:setLocalZOrder(100)
    self.select_img:setVisible(false)

    self.preview_sub_panel = mercenary_preview_sub_panel.New(self.root_node:getChildByName("preview_node"))
    self.preview_sub_panel:Init(MERCENARY_PREVIEW_SHOW_MOD["list"])
    self.top_bg_img = self.root_node:getChildByName("top_bg")
    self.border_bg_img = self.root_node:getChildByName("border_top")
    self.shadow_img = self.root_node:getChildByName("shadow")
    self.shadow_img:setTouchEnabled(true)

    self.cur_mercenary_num_text = root_node:getChildByName("mercenary_num")

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width

    --选择佣兵动画
    local cur_choose_spine_node = spine_manager:GetNode("choose_bg")
    cur_choose_spine_node:setAnchorPoint(0.5, 0.5)

    self.scroll_view:addChild(cur_choose_spine_node, 0)

    local last_choose_spine_node = spine_manager:GetNode("choose_bg")
    last_choose_spine_node:setAnchorPoint(0.5, 0.5)
    self.scroll_view:addChild(last_choose_spine_node, 0)

    self.cur_choose_spine_tracker = select_spine_tracker.New(cur_choose_spine_node, "herobg")
    self.last_choose_spine_tracker = select_spine_tracker.New(last_choose_spine_node, "herobg")

    self.head_sub_panel_y = 0
    self.tail_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.mercenary_offset = 0
    self.sub_panel_row = 0

    self.mercenary_sub_panels = {}
    self.mercenary_list = {}
    self.mercenary_num = 0

    self.cur_sub_panel_index = 1
    self.last_sub_panel_index = 1

    self.show_detail_panel = false
    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_list_panel:CreateMercenarySubPanels()

    local cur_row = math.min(MAX_PANEL_ROW, self.cur_mercenary_row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local source = MERCENARY_TEMPLATE_SOURCE

    local begin_y = self.height + FIRST_SUB_PANEL_OFFSET

    --绑定事件
    for row = self.sub_panel_row + 1, cur_row do
        local y = begin_y - (row - 1) * 124
        local sub_panels  = mercenary_template_panel.Create(source, self.scroll_view, self.mercenary_template, 5, MERCENARY_BEGIN_X, y, row, self.view_mercenary_method)
        self.mercenary_sub_panels[row] = sub_panels
    end

    self.sub_panel_row = cur_row
end

function mercenary_list_panel:Show()

    self.cur_choose_spine_tracker.root_node:setVisible(false)
    self.last_choose_spine_tracker.root_node:setVisible(false)

    self.sort_type = self.sort_type or SORT_TYPE["quality"]
    self.sort_range = self.sort_range or SORT_RANGE["all"]

    self:RefreshListPanel(self.sort_type, self.sort_range)

    self.cur_mercenary_num_text:setString(troop_logic:GetCurMercenaryNum() .. "/" .. troop_logic:GetCampCapacity())

    self.root_node:setVisible(true)
end

--因为显示要排序，所以要对mercenary_list做一次生拷贝
function mercenary_list_panel:CopyMercenaryList()
    local mercenary_num = 0
    local list = {}
    local mercenary_list = troop_logic:GetMercenaryList()

    --todo 每次都要操作一次
    for mercenary_id, mercenary in pairs(mercenary_list) do
        if self.sort_range  <= SORT_RANGE["quality6"] then
            if mercenary.template_info.quality == self.sort_range then
                mercenary_num = mercenary_num + 1
                list[mercenary_num] = mercenary
            end

        elseif self.sort_range == SORT_RANGE["all"] then --全体佣兵排序
            mercenary_num = mercenary_num + 1
            list[mercenary_num] = mercenary

        elseif self.sort_range == SORT_RANGE["campaign"] then --合战佣兵排序
            if campaign_logic:CheckSpecialMercenary(mercenary) then
                mercenary_num = mercenary_num + 1
                list[mercenary_num] = mercenary
            end
        end
    end

    self.mercenary_list = list
    self.mercenary_num = mercenary_num
end

function mercenary_list_panel:SetHeadSubPanel(index)

    if index > self.sub_panel_row then
        self.head_sub_panel_index = 1

    elseif index < 1 then
        self.head_sub_panel_index = self.sub_panel_row

    else
        self.head_sub_panel_index = index
    end

    if self.sub_panel_row == 0 then
        return
    end

    self.head_sub_panel_y = self.sview_height - self.mercenary_sub_panels[self.head_sub_panel_index][1].root_node:getPositionY()
end

-- 刷新整个列表
function mercenary_list_panel:RefreshListPanel(sort_type, sort_range)
    self.sort_type = sort_type
    self.sort_range = sort_range

    self:CopyMercenaryList()
    --排序
    panel_util:SortMercenary(self.sort_type, self.mercenary_list)

    self.mercenary_offset = 0
    self.cur_mercenary_row = math.ceil(self.mercenary_num / 5) -- 当前页数

    local height = math.max(self.cur_mercenary_row * SUB_PANEL_HEIGHT, self.sview_height)
    self.height = height

    self:CreateMercenarySubPanels()

    self.scroll_view:getInnerContainer():setPositionY(0)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self:LoadMercenaryInfo()

    self:ClearChoose(self.last_sub_panel_index ~= 1)

    self.cur_sub_panel_index = 1
    self.last_sub_panel_index = 1
    self.cur_sub_panel = self.mercenary_sub_panels[self.cur_sub_panel_index][1]
    self.cur_mercenary_id = self.cur_sub_panel .mercenary_id or 0

    self:ShowCurMerceanryInfo()

    self.sort_desc_text:setString(lang_constants:Get("mercenary_sort_type" .. sort_type))
end

function mercenary_list_panel:LoadMercenaryInfo()
    self.mercenary_offset = 0
    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - self.height)

    local begin_y = self.height + FIRST_SUB_PANEL_OFFSET
    for row = 1, self.sub_panel_row do
        if row <= self.cur_mercenary_row then
            --设定位置和加载信息
            local y = begin_y - (row - 1) * 124
            self:ShowSingleRowMercenary(row, row, y)
        else
            --隐藏
            for col = 1, 5 do
                self.mercenary_sub_panels[row][col]:Hide()
            end
        end
    end

    self:SetHeadSubPanel(1)
end

--根据row, col 返回index
function mercenary_list_panel:CalcMercenaryIndex(row, col)
    return (row - 1) * 5 + col
end

--根据索引值返回row , index
function mercenary_list_panel:CalcRowAndCol(index)
    local row = math.ceil(index / 5)
    local col = index  - (row - 1) * 5
    return row, col
end

function mercenary_list_panel:ShowCurMerceanryInfo()
    self.preview_sub_panel:Show(self.cur_mercenary_id)

    --撤销之前的选择
    self:ClearChoose(self.last_sub_panel_index ~= self.cur_sub_panel_index)

    --选中
    local cur_ref_node = self.cur_sub_panel.root_node
    cur_ref_node:setLocalZOrder(cur_ref_node:getLocalZOrder() + 1)
    local x, y = cur_ref_node:getPositionX(), cur_ref_node:getPositionY()

    self.cur_choose_spine_tracker:Bind("choose", x, y, cur_ref_node)

    self.cur_choose_spine_tracker.root_node:setVisible(self.mercenary_num ~= 0)
end

function mercenary_list_panel:ClearChoose(is_clear)
    if is_clear then
        local row, col = self:CalcRowAndCol(self.last_sub_panel_index)
        local last_ref_node = self.mercenary_sub_panels[row][col].root_node
        last_ref_node:setLocalZOrder(last_ref_node:getLocalZOrder() - 1)
        local x, y = last_ref_node:getPositionX(), last_ref_node:getPositionY()

        self.last_choose_spine_tracker:Bind("unchosen", x, y, last_ref_node)
    end
end

function mercenary_list_panel:ShowSingleRowMercenary(mercenary_row, sub_panel_row, pos_y)
    local begin_x = MERCENARY_BEGIN_X
    for col = 1, 5 do

        local tag = self:CalcMercenaryIndex(mercenary_row, col)
        local mercenary = self.mercenary_list[tag]
        local sub_panel = self.mercenary_sub_panels[sub_panel_row][col]
        sub_panel.root_node:setVisible(true)

        if tag <= self.mercenary_num then
            sub_panel:Load(mercenary, self.sort_type)

        else
            sub_panel:Clear(true)
            sub_panel.root_node:setVisible(false)

        end
        sub_panel.root_node:setPositionY(pos_y)
    end
end

function mercenary_list_panel:Update(elapsed_time)
    if self.show_detail_panel then
        self.detail_duration = self.detail_duration + elapsed_time
        if self.detail_duration > 0.5 then
            self.detail_duration = 0
            self.show_detail_panel = false

            local is_leader = troop_logic:GetMercenaryInfo(self.cur_mercenary_id).is_leader
            local mode = client_constants["MERCENARY_DETAIL_MODE"]["list"]
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", mode, self.cur_mercenary_id)
        end
    end

    self.cur_choose_spine_tracker:Update(elapsed_time)
    self.last_choose_spine_tracker:Update(elapsed_time)
end

--更新信息
function mercenary_list_panel:UpdateMercenarySubPanelInfo(mercenary_id)
    if self.cur_mercenary_id == mercenary_id then
        self.cur_sub_panel:ShowStatus(self.sort_type)
    else
        local mercenary = self.mercenary_list[self.cur_sub_panel_index]
        self.cur_sub_panel:Load(mercenary, self.sort_type)
    end
end

function mercenary_list_panel:RegisterWidgetEvent()

    --查看某一佣兵信息
    self.view_mercenary_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local index = widget:getTag()

            if index > self.mercenary_num then
                return
            end

            local row, col = self:CalcRowAndCol(index)

            self.cur_sub_panel = self.mercenary_sub_panels[row][col]
            self.cur_mercenary_id =  self.cur_sub_panel.mercenary_id
            if self.cur_mercenary_id == 0 then
                return
            end

            self.cur_sub_panel_index = index

            self:ShowCurMerceanryInfo()

            self.last_sub_panel_index = self.cur_sub_panel_index

            self.touch_start_location = widget:getTouchBeganPosition()

            self.detail_duration = 0
            self.show_detail_panel = true
        elseif event_type == ccui.TouchEventType.moved then

            --进详情的时间和位置判断
            if self.show_detail_panel then
                local move_location = widget:getTouchMovePosition()
                local start_pos = self.touch_start_location

                if (start_pos.x < move_location.x - 20) or (start_pos.x > move_location.x + 20) then
                    self.show_detail_panel = false
                    self.detail_duration = 0
                end

                if (start_pos.y <  move_location.y - 20) or (start_pos.y > move_location.y + 20) then
                    self.show_detail_panel = false
                    self.detail_duration = 0
                end

            end
        elseif event_type == ccui.TouchEventType.ended then
            self.detail_duration = 0
            self.show_detail_panel = false

        elseif event_type == ccui.TouchEventType.canceled then
            self.detail_duration = 0
            self.show_detail_panel = false

        end

    end

    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then

            local y = self.scroll_view:getInnerContainer():getPositionY()

            if y >= self.head_sub_panel_y + SUB_PANEL_HEIGHT * 0.5 then
                if self.mercenary_offset + self.sub_panel_row >= self.cur_mercenary_row then

                else
                    self.mercenary_offset = self.mercenary_offset + 1
                    local last_sub_panel_index = self.sub_panel_row
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end

                    --重新设定位置
                    local y = self.mercenary_sub_panels[last_sub_panel_index][1].root_node:getPositionY() - SUB_PANEL_HEIGHT

                    --重新load info
                    self:ShowSingleRowMercenary(self.mercenary_offset + self.sub_panel_row, self.head_sub_panel_index, y)

                    self:SetHeadSubPanel(self.head_sub_panel_index + 1)
                end

            elseif y <= self.head_sub_panel_y - SUB_PANEL_HEIGHT * 0.5 then

                if self.mercenary_offset == 0 then

                else
                    self.mercenary_offset = self.mercenary_offset - 1

                    local last_sub_panel_index = self.sub_panel_row
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end

                    --重新设定位置
                    local y = self.mercenary_sub_panels[self.head_sub_panel_index][1].root_node:getPositionY() + SUB_PANEL_HEIGHT
                    --重新load info
                    self:ShowSingleRowMercenary(self.mercenary_offset + 1, last_sub_panel_index, y)
                    self:SetHeadSubPanel(self.head_sub_panel_index - 1)
                end
            end

        end
    end)

    --显示排序面板
    self.sort_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_floating_panel")
            local source = client_constants["SORT_PANEL_SOURCE"]["list"]

            graphic:DispatchEvent("show_world_sub_panel", "mercenary_sort_panel", source, self.sort_type, self.sort_range, function(sort_type, sort_range)
                self:RefreshListPanel(sort_type, sort_range)
            end)
        end
    end)

    self.shadow_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
                 --月卡购买提示
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("buy_vip_title"),
                    lang_constants:Get("mercenary_capacity_not_enough_desc"),
                    lang_constants:Get("common_confirm"),
                    lang_constants:Get("common_cancel"),
                    function()
                        graphic:DispatchEvent("show_world_sub_panel", "vip_panel")
                end)

            end
        end
    end)

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_floating_panel")

            graphic:DispatchEvent("show_world_sub_scene", "mercenary_sub_scene")
        end
    end)
end

function mercenary_list_panel:RegisterEvent()

    graphic:RegisterEvent("fire_mercenary", function(mercenary_id)
        --解雇成功
        if not self.root_node:isVisible() then
            return
        end
        self:Show()
    end)

    graphic:RegisterEvent("update_mercenary_info", function(mercenary_id)
        --更新佣兵信息
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenarySubPanelInfo(mercenary_id)
    end)

    graphic:RegisterEvent("open_artifact", function(mercenary_id)
        --开启宝具成功
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenarySubPanelInfo(mercenary_id)
    end)

    graphic:RegisterEvent("update_force_panel", function(mercenary_id)
        --觉醒突破
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenarySubPanelInfo(mercenary_id)
    end)

    graphic:RegisterEvent("update_leader_weapon", function()
        --装备武器
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenarySubPanelInfo(self.cur_mercenary_id)
        --self.preview_sub_panel:Show(self.cur_mercenary_id)
        self:ShowCurMerceanryInfo()

    end)

    graphic:RegisterEvent("upgrade_leader_weapon_lv", function()
        --主角武器强化
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMercenarySubPanelInfo(self.cur_mercenary_id)
        --self.preview_sub_panel:Show(self.cur_mercenary_id)
        self:ShowCurMerceanryInfo()

    end)
end

return mercenary_list_panel
