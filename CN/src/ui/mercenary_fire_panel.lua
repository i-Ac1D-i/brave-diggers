local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local audio_manager = require"util.audio_manager"
local platform_manager = require "logic.platform_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local time_logic = require "logic.time"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local mercenary_template_panel = require "ui.mercenary_template_panel"
local MERCENARY_PREVIEW_SHOW_MOD = client_constants["MERCENARY_PREVIEW_SHOW_MOD"]  --preview 面板显示mod
local mercenary_preview_sub_panel = require "ui.mercenary_preview_panel"
local spine_manager = require "util.spine_manager"
local mercenary_contract_config = config_manager.mercenary_contract_config

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local SORT_TYPE = client_constants["SORT_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local MERCENARY_TEMPLATE_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["list"]

local MAX_PANEL_ROW = 8        --最大row
local MERCENARY_BEGIN_X = 72   --佣兵显示的初始位置x
local MERCENARY_BEGIN_Y = 700  --佣兵显示的初始位置y
local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -70

local MAX_FIRE_NUM = constants.MAX_FIRE_NUM_ONCE

local select_sub_panel = panel_prototype.New()
select_sub_panel.__index = select_sub_panel

function select_sub_panel.New()
    return setmetatable({}, select_sub_panel)
end

function select_sub_panel:Init(root_node)
    self.root_node = root_node
end

function select_sub_panel:Show(x, y)
    self.root_node:setVisible(true)
    x = x or self.root_node:getPositionX()
    y = y or self.root_node:getPositionY()

    self.root_node:setPosition(x, y)
end

local mercenary_fire_panel = panel_prototype.New()
function mercenary_fire_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_fire_panel.csb")
    local root_node = self.root_node

    self.filter_btn = root_node:getChildByName("settlement_btn")
    -- self.sort_desc_text = self.sort_btn:getChildByName("desc")
    self.back_btn = root_node:getChildByName("back_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template"):getChildByName("mercenary_template")
    self.mercenary_template:setVisible(false)

    self.select_img = self.scroll_view:getChildByName("select")
    self.select_img:setLocalZOrder(100)

    self.preview_sub_panel = mercenary_preview_sub_panel.New(self.root_node:getChildByName("preview_node"))
    self.preview_sub_panel:Init(MERCENARY_PREVIEW_SHOW_MOD["fire"])
    self.preview_sub_panel:SetSkillImgPositionX(130)
    self.preview_sub_panel:SetSkillNodePosY(186)
    self.preview_sub_panel:SetCanShowFloatPanel(true)

    self.top_bg_img = self.root_node:getChildByName("top_bg")
    self.border_bg_img = self.root_node:getChildByName("border_top")

    self.show_confirm_msgbox_btn = self.root_node:getChildByName("settlement_batch_btn")
    self.fire_num_text = self.show_confirm_msgbox_btn:getChildByName("num")

    self.personal_soul_chip_num_text = self.root_node:getChildByName("recovery_price"):getChildByName("value")

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width

    self.cur_mercenary_num_text = self.root_node:getChildByName("coordinate")

    self.select_template = self.scroll_view:getChildByName("select")
    self.select_sub_panels ={}

    local sub_panel = select_sub_panel.New()
    sub_panel:Init(self.select_template)
    sub_panel.root_node:setLocalZOrder(100)
    sub_panel:Hide(i)
    table.insert(self.select_sub_panels, sub_panel)

    self:CreateSelectPanels()

    self.head_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.mercenary_offset = 0
    self.sub_panel_row = 0

    self.mercenary_sub_panels = {}
    self.mercenary_list = {}
    self.mercenary_num = 0

    --将要被解雇的佣兵数量和id列表
    self.selected_id_list = {}

    --佣兵选中之后instance_id 对应的select_sub_panel的index
    self.mercenary_select_panels = {}
    self.height = 0

    --契约经验
    self.contract_exp = 0

    self.show_detail_panel = fals
    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

--创建select_panel
function mercenary_fire_panel:CreateSelectPanels()
    for i = 1, 10 do
        local sub_panel = select_sub_panel.New()
        sub_panel:Init(self.select_template:clone())
        self.scroll_view:addChild(sub_panel.root_node, 100)
        sub_panel:Hide(i)
        table.insert(self.select_sub_panels, sub_panel)
    end
end

function mercenary_fire_panel:CreateMercenarySubPanels()
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

--根据row, col 返回index
function mercenary_fire_panel:CalcMercenaryIndex(row, col)
    return (row - 1) * 5 + col
end

--根据索引值返回row , index
function mercenary_fire_panel:CalcRowAndCol(index)
    local row = math.ceil(index / 5)
    local col = index  - (row - 1) * 5
    return row, col
end

function mercenary_fire_panel:Show()
    self.root_node:setVisible(true)

    self:CloneMercenaryList()

    self.cur_mercenary_row = math.ceil(self.mercenary_num / 5)
    local height = math.max(self.cur_mercenary_row * SUB_PANEL_HEIGHT, self.sview_height)
    self.height = height

    self:CreateMercenarySubPanels()

    self.mercenary_offset = 0
    self:SetHeadSubPanel(1)

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self:RefreshFiredPanel()

    self:FilterMercenary(6)

    self.personal_soul_chip_num_text:setString("0")
    self.cur_mercenary_num_text:setString(troop_logic:GetCurMercenaryNum() .. "/" .. troop_logic:GetCampCapacity())
end

function mercenary_fire_panel:CanFire(mercenary)
    local cannot_fire_reason

    if mercenary.is_open_artifact then
        cannot_fire_reason = "artifact"    
    elseif mercenary.force_lv == 35 then
        cannot_fire_reason = "force_level"
    elseif mercenary.formation_info ~= 0 then
        if troop_logic:IsMercenaryInFormation(mercenary, constants["GUILD_WAR_TROOP_ID"]) then 
            cannot_fire_reason = "formation_info2"
        else 
            cannot_fire_reason = "formation_info"
        end
    end

    return cannot_fire_reason
end

--因为要排序，所以要拷贝一份可以被解雇的佣兵列表
function mercenary_fire_panel:CloneMercenaryList()
    local list = {}
    local not_fire_list = {}
    local mercenary_list = troop_logic:GetMercenaryList()

    for mercenary_id, mercenary in pairs(mercenary_list) do
        if not mercenary.is_leader then
            mercenary.cannot_fire_reason = self:CanFire(mercenary)

            if mercenary.cannot_fire_reason then
                table.insert(not_fire_list, mercenary)
            else
                table.insert(list, mercenary)
            end
        end
    end

    self.mercenary_list = list

    self.sort_type = SORT_TYPE["quality"]
    panel_util:SortMercenary(self.sort_type, self.mercenary_list)
    panel_util:SortMercenary(self.sort_type, not_fire_list)    

    for _, mercenary in pairs(not_fire_list) do
        table.insert(self.mercenary_list, mercenary)
    end
    
    self.mercenary_num = #self.mercenary_list
end

function mercenary_fire_panel:SetHeadSubPanel(index)

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

--重新显示佣兵sub_panel
function mercenary_fire_panel:RefreshFiredPanel()
    self.mercenary_offset = 0
    --回到最顶端
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

    self.cur_sub_panel_index = 1

    self.preview_sub_panel:Show(0)
end

--
function mercenary_fire_panel:FilterMercenary(quality)
    --重置
    for i = #self.selected_id_list, 1, -1 do
        self:RemoveTobeFiredInstanceId(self.selected_id_list[i], i)
    end

    if quality == 6 then
        self.fire_num_text:setString("0")
        self.soul_chip = 0
        self.sum_exp = 0
        return
    end

    local fire_num = 0
    --当前选中为空
    for i = self.mercenary_num, 1, -1  do
        local mercenary = self.mercenary_list[i]
        if mercenary.template_info.quality <= quality then
            if mercenary.level == 1 and mercenary.weapon_lv == 0 and mercenary.wakeup == 1 and mercenary.contract_lv == 0 then
                --金将以下的品质，解雇的碎片在500以下才会筛选
                local can_fire = false

                if mercenary.cannot_fire_reason then
                    can_fire = false
                elseif mercenary.template_info.quality == 5 then
                    can_fire = true
                elseif mercenary.template_info.quality < 5 and mercenary.template_info.soul_chip <= 500 then
                    can_fire = true
                end

                if can_fire then
                    fire_num = fire_num + 1
                    table.insert(self.selected_id_list, mercenary.instance_id)

                    self.mercenary_select_panels[mercenary.instance_id] = fire_num

                    if fire_num > #self.select_sub_panels then
                        self:CreateSelectPanels()
                    end

                    if mercenary.pos_x then
                        self.select_sub_panels[fire_num]:Show(mercenary.pos_x, mercenary.pos_y)
                    end
                end
            end
        end
    end

    self.fire_num_text:setString(fire_num)

    self:UpdateFireIncome()
end

--更新解雇后获得的收益
function mercenary_fire_panel:UpdateFireIncome()
    local sum_soul_chip = 0
    local sum_exp = 0
    local soul_bone = {0,0,0,0,0,0}
    local quality = 0;
    for i, id in ipairs(self.selected_id_list) do
        local mercenary = troop_logic:GetMercenaryInfo(id)
        if mercenary then
            if mercenary.wakeup > 1 or mercenary.level >= 30 then
                sum_exp = sum_exp + math.ceil(mercenary.exp * 0.7)
            end
            sum_soul_chip = sum_soul_chip + mercenary.template_info.soul_chip
            soul_bone[mercenary.template_info.quality] = soul_bone[mercenary.template_info.quality] + (mercenary.template_info.soul_bone or 0)
            quality = mercenary.template_info.quality
        end
    end

    self.sum_soul_chip = sum_soul_chip
    self.sum_exp = sum_exp
    self.soul_bone = soul_bone
    self.quality = quality
end

--显示一行佣兵信息
function mercenary_fire_panel:ShowSingleRowMercenary(mercenary_row, sub_panel_row, pos_y)
    for col = 1, 5 do
        local tag = self:CalcMercenaryIndex(mercenary_row, col)

        local mercenary = self.mercenary_list[tag]
        local sub_panel = self.mercenary_sub_panels[sub_panel_row][col]
        if tag <= self.mercenary_num then
            sub_panel:Load(mercenary, self.sort_type)
            if mercenary.cannot_fire_reason then            
                sub_panel.root_node:setColor(panel_util:GetColor4B(0x9A9A9A))            
            end
            mercenary.pos_x = sub_panel.root_node:getPositionX()
            mercenary.pos_y = pos_y

            local select_index = self.mercenary_select_panels[mercenary.instance_id]
            if mercenary and select_index then
                self.select_sub_panels[select_index]:Show(sub_panel.root_node:getPositionX(), pos_y)
            end
        else
            sub_panel:Clear(true)
            sub_panel.root_node:setVisible(false)
        end
        sub_panel.root_node:setPositionY(pos_y)
    end
end

function mercenary_fire_panel:Update(elapsed_time)
    if self.show_detail_panel then
        self.detail_duration = self.detail_duration + elapsed_time
        if self.detail_duration > 0.5 then
            self.detail_duration = 0
            self.show_detail_panel = false

            local mercenary = troop_logic:GetMercenaryInfo(self.cur_mercenary_id)
            if mercenary then
                local mode = client_constants["MERCENARY_DETAIL_MODE"]["fire"]
                graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", mode, self.cur_mercenary_id)
            end
        end
    end
end

--该佣兵是否已经在被解雇的id_list
function mercenary_fire_panel:AlreadyInTobeFiredList(mercenary_id)
    for i, id in ipairs(self.selected_id_list) do
        if id == mercenary_id then
            return true, i
        end
    end
    return false, 0
end

--
function mercenary_fire_panel:SetMerceanrySelectIndex(instance_id, index)
    self.mercenary_select_panels[instance_id] = index
end

function mercenary_fire_panel:RemoveTobeFiredInstanceId(instance_id, id_index)
    local index = self.mercenary_select_panels[instance_id]
    self.select_sub_panels[index]:Hide()

    if self.selected_id_list[id_index] then
        table.remove(self.selected_id_list, id_index)
    end

    self.mercenary_select_panels[instance_id] = nil
end

--返回第一个没有使用的select_sub_panel
--todo
function mercenary_fire_panel:GetNotVisibleSelectPanel()
    for i = 1, #self.select_sub_panels do
        if not self.select_sub_panels[i].root_node:isVisible() then
           return i
        end
    end
end

--选中佣兵 若已经被选中，则移出来;若未选中，则添加进来
function mercenary_fire_panel:ChooseMercenary()
    local mercenary = troop_logic:GetMercenaryInfo(self.cur_mercenary_id)
    if not mercenary then
        return
    end

    if mercenary.cannot_fire_reason then
        graphic:DispatchEvent("show_prompt_panel", "cannot_fire_reason_"..mercenary.cannot_fire_reason)
        return
    end

    local contract_exp_fix = 0
    if mercenary.contract_lv == constants.MAX_CONTRACT_LV then
        local stone_nums = mercenary_contract_config[2][mercenary.template_id].contract_stone or 0
        if stone_nums == 0 then
            contract_exp_fix = 1
        end
    end

    local is_already_select, id_index = self:AlreadyInTobeFiredList(self.cur_mercenary_id)
    if is_already_select then
        self:RemoveTobeFiredInstanceId(self.cur_mercenary_id, id_index)
        self.contract_exp = self.contract_exp + contract_exp_fix
    else

        --选择
        table.insert(self.selected_id_list, self.cur_mercenary_id)

        if #self.selected_id_list > #self.select_sub_panels then
            self:CreateSelectPanels()
        end

        local select_panel_index = self:GetNotVisibleSelectPanel()
        self:SetMerceanrySelectIndex(self.cur_mercenary_id, select_panel_index)
        self.select_sub_panels[select_panel_index]:Show(self.cur_sub_panel.root_node:getPositionX(), self.cur_sub_panel.root_node:getPositionY())

        -- 如果二阶契约不消耗契约石
        self.contract_exp = self.contract_exp - contract_exp_fix
    end

    self.fire_num_text:setString(#self.selected_id_list)
    --r2 
    --r2修改右对齐
    local no_select_hide = platform_manager:GetChannelInfo().mercenary_fire_panel_is_already_select_hide
    if no_select_hide and is_already_select then
        self.preview_sub_panel:Show(0)
        self.personal_soul_chip_num_text:setString("0")
    else
        self.preview_sub_panel:Show(self.cur_mercenary_id)
        self.personal_soul_chip_num_text:setString(mercenary.template_info.soul_chip)
    end
end

function mercenary_fire_panel:RegisterWidgetEvent()
    --查看某一佣兵信息
    self.view_mercenary_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            local index = widget:getTag()

            if index > self.mercenary_num then
                return
            end

            local row, col = self:CalcRowAndCol(index)

            self.cur_sub_panel = self.mercenary_sub_panels[row][col]
            self.cur_mercenary_id = self.cur_sub_panel.mercenary_id

            if self.cur_mercenary_id == 0 then
                return
            end

            self.cur_sub_panel_index = index

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

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.detail_duration = 0
            self.show_detail_panel = false

            if math.abs(widget:getTouchEndPosition().y - self.touch_start_location.y) < 20 then
                self:ChooseMercenary()
            end

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

    --显示筛选面板
    self.filter_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_fire_batch_panel", function(quality)
                self:FilterMercenary(quality)
            end)
        end
    end)

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --显示 确认解雇 界面
    self.show_confirm_msgbox_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:UpdateFireIncome()

            local fire_num = #self.selected_id_list
            if fire_num > constants.MAX_FIRE_NUM_ONCE then
                for i = fire_num, (constants.MAX_FIRE_NUM_ONCE + 1), -1 do
                    self:RemoveTobeFiredInstanceId(self.selected_id_list[i], i)
                end
            end

            graphic:DispatchEvent("show_world_sub_panel", "mercenary_confirm_fire_panel", #self.selected_id_list, self.sum_soul_chip, self.sum_exp, self.selected_id_list, self.contract_exp, self.soul_bone, self.quality)
        end
    end)

end

function mercenary_fire_panel:RegisterEvent()
    graphic:RegisterEvent("fire_mercenary", function(mercenary_id)

        --解雇
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)
end

return mercenary_fire_panel
