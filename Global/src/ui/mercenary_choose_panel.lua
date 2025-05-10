--选择佣兵上阵panel
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local evolution_config = config_manager.mercenary_evolution_config
local spine_manager = require "util.spine_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local campaign_logic = require "logic.campaign"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local mercenary_template_panel = require "ui.mercenary_template_panel"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]

local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_RANGE = client_constants["SORT_RANGE"]

local TITLE =
{
    [1] = lang_constants:Get("mercenary_formation_do_switch"),
    [2] = lang_constants:Get("mercenary_trans"),
    [3] = lang_constants:Get("mercenary_trans"),
    [4] = lang_constants:Get("mercenary_contract"),
    [5] = lang_constants:Get("mercenary_evolution_title"),
}

--本文件用到的常数
local MAX_MERCENARY_NUM_PER_ROW = 5

local MAX_PANEL_ROW = 8        --最大row
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
    t.mercenary_id = 0

    t.root_node:registerSpineEventHandler(function(event)
        t.finish_choose = true
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, select_spine_tracker)
end

function select_spine_tracker:Bind(animation, x, y, widget, mercenary_id)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.animation = animation

    self.offset_x = x

    self.offset_y = y

    self.widget = widget

    self.mercenary_id = mercenary_id

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


local mercenary_choose_panel = panel_prototype.New()
function mercenary_choose_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_choose_panel.csb")
    local root_node = self.root_node

    self.title_text = root_node:getChildByName("title_bg"):getChildByName("name")

    self.back_btn = root_node:getChildByName("back_btn")
    self.sort_btn = root_node:getChildByName("sort_btn")
    self.sort_desc_text = self.sort_btn:getChildByName("desc")
    self.sort_desc2_text = self.sort_btn:getChildByName("txt")
    self.sort_shadow_img = self.sort_btn:getChildByName("shadow")
    self.evolution_desc_text = self.sort_btn:getChildByName("evolution_desc")

    self.scroll_view = root_node:getChildByName("scroll_view")

    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template"):getChildByName("mercenary_template")
    self.mercenary_template:setVisible(false)

    self.cur_bg_img = root_node:getChildByName("cur_mer_bg")
    self.cur_mercenary_name_text = self.cur_bg_img:getChildByName("value")

    self.evolution_desc_text = self.sort_btn:getChildByName("evolution_desc")
    self.evolution_desc_text:setVisible(false)

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width

    self.choose_spine_trackers = {}

    --选择佣兵动画
    for i = 1, 3 do
        local spine_node = spine_manager:GetNode("choose_bg")
        spine_node:setAnchorPoint(0.5, 0.5)
        self.scroll_view:addChild(spine_node, 0)
        self.choose_spine_trackers[i] = select_spine_tracker.New(spine_node, "herobg")
    end

    self.head_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.mercenary_offset = 0
    self.sub_panel_row = 0

    self.mercenary_sub_panels = {}
    self.mercenary_list = {}
    self.mercenary_num = 0

    self:RegisterWidgetEvent()
end

function mercenary_choose_panel:CreateMercenarySubPanels()

    local cur_row = math.min(MAX_PANEL_ROW, self.cur_mercenary_row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local source = client_constants.MERCENARY_TEMPLATE_PANEL_SOURCE["choose_to_battle"]

    local begin_y = self.height + FIRST_SUB_PANEL_OFFSET

    --绑定事件
    for row = self.sub_panel_row + 1, cur_row do
        local y = begin_y - (row - 1) * 124
        local sub_panels  = mercenary_template_panel.Create(source, self.scroll_view, self.mercenary_template, 5, MERCENARY_BEGIN_X, y, row, self.view_mercenary_method)
        self.mercenary_sub_panels[row] = sub_panels
    end

    self.sub_panel_row = cur_row
end

--mode == "evolution", src_instance_id = evolution_id, src_position = config.key, formarion_id = step_index
function mercenary_choose_panel:Show(mode, src_instance_id, src_position, formation_id)
    self.root_node:setVisible(true)
    self.src_instance_id = src_instance_id
    self.src_position = src_position
    self.formation_id = formation_id or 1
    self.mode = mode
    self.choose_num = 0
    self:ClearAllChooseMercenary()

    self.title_text:setString(TITLE[mode])

    self.source = client_constants.MERCENARY_TEMPLATE_PANEL_SOURCE["choose_to_battle"]

    if self.mode == CHOOSE_SHOW_MODE["evolution"] then

        self:ShowSortResult(SORT_TYPE["quality"], SORT_RANGE.all)
        self:SetBtnStatus(true)
    else
        self:SetBtnStatus(false)
        if self.mode == CHOOSE_SHOW_MODE["contract"] then
            self.source = client_constants.MERCENARY_TEMPLATE_PANEL_SOURCE["contract"]
            self.sort_type = SORT_TYPE["contract"]
        else
            if self.sort_type == SORT_TYPE["contract"] then
                self.sort_type = SORT_TYPE["quality"]
            else
                self.sort_type = self.sort_type or SORT_TYPE["quality"]
            end
        end

        self.sort_range = self.sort_range or SORT_RANGE.all
        --排序
        self:ShowSortResult(self.sort_type, self.sort_range)

        if self.mode == CHOOSE_SHOW_MODE["formation"] then
            self.cur_bg_img:setVisible(true)
            if src_instance_id and src_instance_id ~= 0 then
                local mercenary = troop_logic:GetMercenaryInfo(src_instance_id)
                self.cur_mercenary_name_text:setString(mercenary.template_info.name)
            else
                self.cur_mercenary_name_text:setString(lang_constants:Get("mercenary_empty"))
            end
        else
            self.cur_bg_img:setVisible(false)
        end
    end
end

function mercenary_choose_panel:SetBtnStatus(is_evolution)
    self.sort_desc_text:setVisible(not is_evolution)
    self.sort_desc2_text:setVisible(not is_evolution)
    self.sort_shadow_img:setVisible(not is_evolution)
    self.evolution_desc_text:setVisible(is_evolution)
end

function mercenary_choose_panel:SetHeadSubPanel(index)

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

--因为显示要排序，所以要对mercenary_list做一次生拷贝
function mercenary_choose_panel:CopyMercenaryList()
    self.mercenary_num = 0
    local list = {}
    local mercenary_list = troop_logic:GetMercenaryList()

    for id, mercenary in pairs(mercenary_list) do
        if self.mode == CHOOSE_SHOW_MODE["formation"] then
            if not troop_logic:MercenaryIsInFormation(mercenary, self.formation_id) then
                self:FilterMercenary(mercenary, list)
            end
        else
            if not mercenary.is_leader then
                self:FilterMercenary(mercenary, list)
            end
        end
    end

    self.mercenary_list = list
end

--获取合成佣兵
function mercenary_choose_panel:FilterEvolutionMercenary(evolution_id)
    local need_id = evolution_config[evolution_id]["mercenary_id"]
    self.need_num = evolution_config[evolution_id]["mercenary_num"]
    local list = {}
    local mercenary_list = troop_logic:GetMercenaryList()
    local mercenary_num = 0
    for id, mercenary in pairs(mercenary_list) do
        if need_id == mercenary.template_info.ID then
            mercenary_num = mercenary_num + 1
            list[mercenary_num] = mercenary
        end
    end

    self.cur_mercenary_name_text:setString("0/" .. tostring(self.need_num))
    self.mercenary_num = mercenary_num
    self.mercenary_list = list
end

function mercenary_choose_panel:FilterMercenary(mercenary, list)
    local mercenary_num = self.mercenary_num
    if self.sort_range <= SORT_RANGE["quality6"] then
        if self.sort_range == mercenary.template_info.quality then
            mercenary_num = mercenary_num + 1
            list[mercenary_num] = mercenary
        end

    elseif self.sort_range == SORT_RANGE["all"] then --全体佣兵排序
        mercenary_num = mercenary_num + 1
        list[mercenary_num] = mercenary

    elseif self.sort_range == SORT_RANGE["campaign"] then
        if campaign_logic:CheckSpecialMercenary(mercenary) then
            mercenary_num = mercenary_num + 1
            list[mercenary_num] = mercenary
        end
    end

    self.mercenary_num = mercenary_num
end

function mercenary_choose_panel:ShowSortResult(sort_type, sort_range)
    self.sort_type = sort_type
    self.sort_range = sort_range

    if self.mode == CHOOSE_SHOW_MODE["evolution"] then
        self:FilterEvolutionMercenary(self.src_instance_id)
    else
        self:CopyMercenaryList()
    end

    panel_util:SortMercenary(self.sort_type, self.mercenary_list)

    self.cur_mercenary_row = math.ceil(self.mercenary_num / 5)
    local height = math.max(self.cur_mercenary_row * SUB_PANEL_HEIGHT, self.sview_height)
    self.height = height

    self:CreateMercenarySubPanels()

    self.mercenary_offset = 0

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self:LoadMercenaryInfo()
    self.sort_desc_text:setString(lang_constants:Get("mercenary_sort_type" .. sort_type))
end

function mercenary_choose_panel:LoadMercenaryInfo()
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

--选中
function mercenary_choose_panel:ChooseMercenary(index)
    local cur_ref_node = self.cur_sub_panel.root_node
    cur_ref_node:setLocalZOrder(cur_ref_node:getLocalZOrder() + 1)
    local x, y = cur_ref_node:getPositionX(), cur_ref_node:getPositionY()
    self.choose_spine_trackers[index]:Bind("choose", x, y, cur_ref_node, self.cur_mercenary_id)
    self.choose_spine_trackers[index].root_node:setVisible(true)
end

--清掉选中
function mercenary_choose_panel:ClearChoose(index)
    local last_ref_node = self.cur_sub_panel.root_node
    last_ref_node:setLocalZOrder(last_ref_node:getLocalZOrder() - 1)
    local x, y = last_ref_node:getPositionX(), last_ref_node:getPositionY()
    self.choose_spine_trackers[index]:Bind("unchosen", x, y, last_ref_node, 0)
end

--重置
function mercenary_choose_panel:ClearAllChooseMercenary()
    for i = 1, 3 do
        self.choose_spine_trackers[i].root_node:setVisible(false)
        self.choose_spine_trackers[i].mercenary_id = 0
        if self.choose_spine_trackers[i].widget then
            self.choose_spine_trackers[i].widget:setScale(1, 1)
        end
    end
end

function mercenary_choose_panel:Update(elapsed_time)
    for i = 1, 3 do
        self.choose_spine_trackers[i]:Update(elapsed_time)
    end
end

function mercenary_choose_panel:ShowSingleRowMercenary(mercenary_row, sub_panel_row, pos_y)
    for col = 1, 5 do
        local tag = (mercenary_row - 1) * 5 + col
        local mercenary = self.mercenary_list[tag]
        local sub_panel = self.mercenary_sub_panels[sub_panel_row][col]
        sub_panel.root_node:setVisible(true)
        if tag <= self.mercenary_num then
            sub_panel:Load(mercenary)
            sub_panel:SetSource(self.source)
            sub_panel:ShowStatus(self.sort_type)

            if self.mode == CHOOSE_SHOW_MODE["evolution"] then
                local is_in_formation = mercenary.formation_info ~= 0
                sub_panel.position_img:setVisible(is_in_formation)
                if is_in_formation then
                    sub_panel.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
                else
                    sub_panel.root_node:setColor(panel_util:GetColor4B(0xffffff))
                end
            end
        else
            sub_panel:Clear(true)
            sub_panel.root_node:setVisible(false)
        end
        sub_panel.root_node:setPositionY(pos_y)
    end
end

function mercenary_choose_panel:RegisterWidgetEvent()

    self.view_mercenary_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.sub_panel_index = widget:getTag()

            if self.sub_panel_index > self.mercenary_num then
                return
            end

            local row = math.ceil(self.sub_panel_index / 5)
            local col = self.sub_panel_index - (row - 1) * 5

            self.cur_sub_panel = self.mercenary_sub_panels[row][col]
            self.cur_mercenary_id = self.mercenary_sub_panels[row][col].mercenary_id
            local mercenary = troop_logic:GetMercenaryInfo(self.cur_mercenary_id)

            if self.mode == CHOOSE_SHOW_MODE["formation"] then

            elseif self.mode == CHOOSE_SHOW_MODE["contract"] then
                if mercenary.is_leader then
                    return
                end

                if not config_manager.mercenary_contract_config[1][mercenary.template_info.ID] then
                    graphic:DispatchEvent("show_prompt_panel", "mercenary_cant_sign_contract")
                    return
                end

                -- graphic:DispatchEvent("show_world_sub_scene", "mercenary_contract_sub_scene", nil, self.cur_mercenary_id)
                -- return

            elseif self.mode == CHOOSE_SHOW_MODE["evolution"] then

                local mercenary = troop_logic:GetMercenaryInfo(self.cur_mercenary_id)
                if mercenary.formation_info ~= 0 then
                    graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_in_formation")
                    return
                end

                local already_choose = false
                for i = 1, 3 do
                    if self.choose_spine_trackers[i].mercenary_id == self.cur_mercenary_id then
                        self.choose_num = self.choose_num - 1
                        self:ClearChoose(i)
                        already_choose = true
                        break
                    end
                end

                if not already_choose and self.choose_num < 3 then
                    self.choose_num = self.choose_num + 1
                    for i = 1, 3 do
                        if self.choose_spine_trackers[i].mercenary_id == 0 then
                            self:ChooseMercenary(i)
                            break
                        end
                    end
                end

                self.cur_mercenary_name_text:setString(tostring(self.choose_num) .. "/" .. tostring(self.need_num))
                if self.choose_num < 3 then
                    self.sort_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
                else
                    self.sort_btn:setColor(panel_util:GetColor4B(0xffffff))
                end

                return
            else
                --主角不能参与转生
                if mercenary.is_leader then
                    graphic:DispatchEvent("show_prompt_panel", "leader_cant_trans")
                    return
                end

                --灵主和灵源不能为同一人
                if self.cur_mercenary_id == self.src_instance_id then
                    graphic:DispatchEvent("show_prompt_panel", "mercenary_material_acceptor_are_same")
                    return
                end
            end

            --显示对比panel
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_compare_panel", self.mode, self.src_instance_id, self.src_position, self.cur_mercenary_id, self.formation_id)
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
                    local sub_panels = self.mercenary_sub_panels[self.head_sub_panel_index]
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
                    local sub_panels = self.mercenary_sub_panels[last_sub_panel_index]
                    local y = self.mercenary_sub_panels[self.head_sub_panel_index][1].root_node:getPositionY() + SUB_PANEL_HEIGHT
                    --重新load info
                    self:ShowSingleRowMercenary(self.mercenary_offset + 1, last_sub_panel_index, y)

                    self:SetHeadSubPanel(self.head_sub_panel_index - 1)
                end
            end

        end
    end)

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")

            if self.mode == CHOOSE_SHOW_MODE["evolution"] then
                self:ClearAllChooseMercenary()
                graphic:DispatchEvent("choose_mercenary_evolution", self.src_position, self.formation_id, nil)
            end
        end
    end)

    --排序
    self.sort_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.mode == CHOOSE_SHOW_MODE["evolution"] then
                if self.choose_num < 3 then
                    graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_not_enough2")
                else
                    local select_list = {}
                    for i = 1, 3 do
                        local mercenary_id = self.choose_spine_trackers[i].mercenary_id
                        if mercenary_id ~= 0 then
                            select_list[i] = mercenary_id
                        end
                    end

                    self:ClearAllChooseMercenary()
                    graphic:DispatchEvent("hide_world_sub_scene")
                    --src_position = config.key, formarion_id = step_index
                    graphic:DispatchEvent("choose_mercenary_evolution", self.src_position, self.formation_id, select_list)
                end
            else
                local source = client_constants["SORT_PANEL_SOURCE"]["choose"]
                graphic:DispatchEvent("show_world_sub_panel", "mercenary_sort_panel", source,  self.sort_type, self.sort_range, function(sort_type,sort_range)
                    self:ShowSortResult(sort_type, sort_range)
                end )
            end
        end
    end)

end

return mercenary_choose_panel
