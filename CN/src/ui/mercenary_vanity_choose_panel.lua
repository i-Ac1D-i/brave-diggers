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
    [6] = lang_constants:Get("mercenary_trans"),
}

--本文件用到的常数
local MAX_MERCENARY_NUM_PER_ROW = 5

local MAX_PANEL_ROW = 20        --最大row
local MERCENARY_BEGIN_X = 11   --佣兵显示的初始位置x
local MERCENARY_BEGIN_Y = 700  --佣兵显示的初始位置y
local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -122

local mercenary_vanity_choose_panel = panel_prototype.New()
function mercenary_vanity_choose_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_choose_panel.csb")
    local root_node = self.root_node

    self.title_text = root_node:getChildByName("title_bg"):getChildByName("name")

    self.back_btn = root_node:getChildByName("back_btn")
    self.sort_btn = root_node:getChildByName("sort_btn")
    self.sort_btn:setVisible(false)
    self.sort_desc_text = self.sort_btn:getChildByName("desc")
    self.sort_desc2_text = self.sort_btn:getChildByName("txt")
    self.sort_shadow_img = self.sort_btn:getChildByName("shadow")

    self.scroll_view = root_node:getChildByName("scroll_view")

    self.mercenary_template = self.scroll_view:getChildByName("mercenary_template"):getChildByName("mercenary_template_0")
    self.mercenary_template:setVisible(false)

    self.cur_bg_img = root_node:getChildByName("cur_mer_bg")
    self.cur_mercenary_name_text = self.cur_bg_img:getChildByName("value")
    self.cur_bg_img:setVisible(false)

    self.evolution_desc_text = self.sort_btn:getChildByName("evolution_desc")
    self.evolution_desc_text:setVisible(false)

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width


    self.head_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.mercenary_offset = 0
    self.sub_panel_row = 0

    self.mercenary_sub_panels = {}
    self.mercenary_list = {}
    self.mercenary_num = 0

    self:RegisterWidgetEvent()
end

--src_position  --替换佣兵位置
function mercenary_vanity_choose_panel:Show(replace_pos)
    self.replace_pos = replace_pos
    self.root_node:setVisible(true)
    self:ShowSortResult()
    troop_logic:CalcVanityTroopBP(true)
end

function mercenary_vanity_choose_panel:ShowSortResult()
    
    self:CopyMercenaryList()

    self.cur_mercenary_row = math.ceil(self.mercenary_num / 5)
    local height = math.max(self.cur_mercenary_row * SUB_PANEL_HEIGHT, self.sview_height)
    self.height = height

    self:CreateMercenarySubPanels()

    self.mercenary_offset = 0

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self:LoadMercenaryInfo()
end

--创建sub_panel
function mercenary_vanity_choose_panel:CreateMercenarySubPanels()

    local cur_row = math.min(MAX_PANEL_ROW, self.cur_mercenary_row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local source = client_constants.MERCENARY_TEMPLATE_PANEL_SOURCE["vanity_adventure_list"]

    local begin_y = self.height + FIRST_SUB_PANEL_OFFSET

    --绑定事件
    for row = self.sub_panel_row + 1, cur_row do
        local y = begin_y - (row - 1) * 124
        local sub_panels = mercenary_template_panel.Create(source, self.scroll_view, self.mercenary_template, 5, MERCENARY_BEGIN_X, y, row, self.view_mercenary_method)
        self.mercenary_sub_panels[row] = sub_panels
    end

    self.sub_panel_row = cur_row
end

function mercenary_vanity_choose_panel:SetHeadSubPanel(index)

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

function mercenary_vanity_choose_panel:CopyMercenaryList()
    self.mercenary_num = 0
    local list = {}
    for k,mercenary in pairs(troop_logic.vanity_mercenarys_list) do
        local is_troop  = false
        for k1,instance_id in pairs(troop_logic.vanity_troop) do
            if mercenary.instance_id == instance_id then
                is_troop = true
                break
            end
        end
        if not is_troop then
            self.mercenary_num = self.mercenary_num + 1
            table.insert(list, troop_logic:InitMercenaryInfoByConfig(mercenary))
        end
    end

    table.sort(list,function (a, b)
        local template_front = a.template_info
        local template_back = b.template_info
        if a.battle_num ~= b.battle_num then
            return a.battle_num > b.battle_num
        else
            if template_front.genre ~= template_back.genre then
            --流派
                return template_front.genre < template_back.genre
            else
                if template_front.quality ~= template_back.quality then
                    return template_front.quality > template_back.quality
                else
                    return template_front.ID > template_back.ID
                end
            end
        end
    end)

    self.mercenary_list = list
end

function mercenary_vanity_choose_panel:LoadMercenaryInfo()
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
function mercenary_vanity_choose_panel:ChooseMercenary(index)
    local cur_ref_node = self.cur_sub_panel.root_node
    cur_ref_node:setLocalZOrder(cur_ref_node:getLocalZOrder() + 1)
    local x, y = cur_ref_node:getPositionX(), cur_ref_node:getPositionY()
    self.choose_spine_trackers[index]:Bind("choose", x, y, cur_ref_node, self.cur_mercenary_id)
    self.choose_spine_trackers[index].root_node:setVisible(true)
end

--清掉选中
function mercenary_vanity_choose_panel:ClearChoose(index)
    local last_ref_node = self.cur_sub_panel.root_node
    last_ref_node:setLocalZOrder(last_ref_node:getLocalZOrder() - 1)
    local x, y = last_ref_node:getPositionX(), last_ref_node:getPositionY()
    self.choose_spine_trackers[index]:Bind("unchosen", x, y, last_ref_node, 0)
end

--重置
function mercenary_vanity_choose_panel:ClearAllChooseMercenary()
    for i = 1, 3 do
        self.choose_spine_trackers[i].root_node:setVisible(false)
        self.choose_spine_trackers[i].mercenary_id = 0
        if self.choose_spine_trackers[i].widget then
            self.choose_spine_trackers[i].widget:setScale(1, 1)
        end
    end
end

function mercenary_vanity_choose_panel:Update(elapsed_time)

end

function mercenary_vanity_choose_panel:ShowSingleRowMercenary(mercenary_row, sub_panel_row, pos_y)
    for col = 1, 5 do
        local tag = (mercenary_row - 1) * 5 + col
        local mercenary = self.mercenary_list[tag]
        local sub_panel = self.mercenary_sub_panels[sub_panel_row][col]
        sub_panel.root_node:setVisible(true)
        if tag <= self.mercenary_num then
            sub_panel:Load(mercenary)
        else
            sub_panel:Clear(true)
            sub_panel.root_node:setVisible(false)
        end
        sub_panel.root_node:setPositionY(pos_y)
    end
end

function mercenary_vanity_choose_panel:RegisterWidgetEvent()

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
            
            graphic:DispatchEvent("show_world_sub_panel", "vanity_mercenary_compare_panel", self.replace_pos, self.cur_mercenary_id, self.cur_sub_panel.cant_touch)
            
        end
    end

    --返回
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
            troop_logic:CalcVanityTroopBP(true)
        end
    end)

    -- --排序
    -- self.sort_btn:addTouchEventListener(function(widget, event_type)
    --     if event_type == ccui.TouchEventType.ended then
    --         audio_manager:PlayEffect("click")
    --         if self.mode == CHOOSE_SHOW_MODE["evolution"] then
    --             if self.choose_num < 3 then
    --                 graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_not_enough2")
    --             else
    --                 local select_list = {}
    --                 for i = 1, 3 do
    --                     local mercenary_id = self.choose_spine_trackers[i].mercenary_id
    --                     if mercenary_id ~= 0 then
    --                         select_list[i] = mercenary_id
    --                     end
    --                 end

    --                 self:ClearAllChooseMercenary()
    --                 graphic:DispatchEvent("hide_world_sub_scene")
    --                 --src_position = config.key, formarion_id = step_index
    --                 graphic:DispatchEvent("choose_mercenary_evolution", self.src_position, self.formation_id, select_list)
    --             end
    --         elseif self.mode == CHOOSE_SHOW_MODE["vanity_adventure"] then
    --            print("虚空阵容排序")
    --         else
    --             local source = client_constants["SORT_PANEL_SOURCE"]["choose"]
    --             graphic:DispatchEvent("show_world_sub_panel", "mercenary_sort_panel", source,  self.sort_type, self.sort_range, function(sort_type,sort_range)
    --                 self:ShowSortResult(sort_type, sort_range)
    --             end )
    --         end
    --     end
    -- end)

end

return mercenary_vanity_choose_panel
