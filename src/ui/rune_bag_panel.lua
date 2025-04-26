local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local rune_logic = require "logic.rune"

local rune_config = config_manager.rune_config

local PLIST_TYPE = ccui.TextureResType.plistType

local BAG_CELL_COL = 5
local BAG_CELL_ROW = 7
local SUB_PANEL_HEIGHT = 125
local FIRST_SUB_PANEL_OFFSET = -75

local RUNE_BAG_CELL_STATUS = {
    ["have_rune"] = 1,
    ["no_rune"] = 2,
    ["lock"] = 3,
}

local rune_sub_panel = panel_prototype.New()
rune_sub_panel.__index = rune_sub_panel

function rune_sub_panel.New()
    return setmetatable({}, rune_sub_panel)
end

function rune_sub_panel:Init(root_node)
    self.root_node = root_node
    self.is_selected = false

    self.icon_img = self.root_node:getChildByName("rune_icon")
    self.bg_img = self.root_node:getChildByName("graph")
    self.name_txt = self.root_node:getChildByName("rune_name_txt")
    self.level_text = self.root_node:getChildByName("level")
    self.select_img = self.root_node:getChildByName("select")
    self.level_text:setLocalZOrder(1)
    panel_util:SetTextOutline(self.level_text, 0x000, 2)

    self.lock_img = self.root_node:getChildByName("rune_lock")
    self.top_quality_icon = self.root_node:getChildByName("top_quality")
    self.equipped_icon = self.root_node:getChildByName("equipped_icon")

    self.top_quality_icon:setVisible(false)
    self.equipped_icon:setVisible(false)
    self.name_txt:setVisible(false)
    self.level_text:setVisible(false)
    self.select_img:setVisible(false)
end

function rune_sub_panel:Show(rune_info, cell_type)
    self.rune_info = rune_info
    self.cell_type = cell_type
    
    if self.cell_type == RUNE_BAG_CELL_STATUS["have_rune"] then
        self.level_text:setVisible(true)
        self.level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))
        self.icon_img:loadTexture(self.rune_info.template_info.icon, PLIST_TYPE)
        self.bg_img:setVisible(true)
        self.icon_img:setVisible(true)
        self.top_quality_icon:setVisible(self.rune_info.template_info.quality == constants["MAX_RUNE_QUALITY"])
        self.equipped_icon:setVisible(self.rune_info.equip_pos > 0)
        self.lock_img:setVisible(false)
    elseif self.cell_type == RUNE_BAG_CELL_STATUS["no_rune"] then
        self.level_text:setVisible(false)
        self.bg_img:setVisible(false)
        self.icon_img:setVisible(false)
        self.top_quality_icon:setVisible(false)
        self.equipped_icon:setVisible(false)
        self.lock_img:setVisible(false)
    elseif self.cell_type == RUNE_BAG_CELL_STATUS["lock"] then
        self.level_text:setVisible(false)
        self.bg_img:setVisible(false)
        self.icon_img:setVisible(false)
        self.top_quality_icon:setVisible(false)
        self.equipped_icon:setVisible(false)
        self.lock_img:setVisible(true)
    end

    self.root_node:setVisible(true)
end

function rune_sub_panel:ShowSelectImg(is_selected)
    self.is_selected = is_selected
    self.select_img:setVisible(is_selected)
end

local rune_bag_panel = panel_prototype.New(true)
function rune_bag_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/rune_package_panel.csb")

    local title_node = self.root_node:getChildByName("title_bg")
    self.rune_name_text = title_node:getChildByName("rune_name")
    self.rune_desc_text = self.root_node:getChildByName("rune_desc")
    self.rune_level_text = title_node:getChildByName("level")
    panel_util:SetTextOutline(self.rune_level_text, 0x000, 2)

    self.bag_num_desc_text = self.root_node:getChildByName("rune_number_txt")
    self.bag_num_value_text = self.root_node:getChildByName("rune_number")

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.confirm_text = self.confirm_btn:getChildByName("confirm_txt")
    
    self.rune_template = self.root_node:getChildByName("rune_panel")
    self.rune_template:setVisible(false)

    self.scroll_view = self.root_node:getChildByName("ScrollView")
    self.scroll_view:setTouchEnabled(true)

    self.select_list = {}
    self.select_num = 0
    self.rune_sub_panels = {}
    self.row_num = 0
    self.sub_panel_row = 0

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.rune_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.row_num
        end,

        function(self, sub_panel, is_up)
            local offset = is_up and self.parent_panel.sub_panel_row or 1
            local pos_y = sub_panel.root_node:getPositionY()
            self.parent_panel:ShowSingleRowRune(self.data_offset + offset, sub_panel, pos_y)
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function rune_bag_panel:Show(show_type, select_list, target_rune_id)
    self.show_type = show_type
    self.target_rune_id = nil

    if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"] then
        self.rune_list = rune_logic:GetSortRuneList(true, false, false)
    elseif self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["EQUIP"] then
        self.rune_list = rune_logic:GetSortRuneList(true, false, false)
    elseif self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_ONE"] then
        self.rune_list = rune_logic:GetSortRuneList(true, false, false)
    elseif self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_MUILT"] then
        self.target_rune_id = target_rune_id
        self.rune_list = rune_logic:GetSortRuneList(false, true, true)
    else
        self.rune_list = rune_logic:GetRuneList()
    end
    self:ShowRunes()

    self:SelectRune()
    self:ResetAllBagCell(select_list)
    self:ShowConfirmText()
    self:ShowBagNumText()

    self.root_node:setVisible(true)
end

function rune_bag_panel:ShowConfirmText()
    if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"] then
        self.confirm_text:setString(lang_constants:Get("rune_bag_level_up"))
    else
        self.confirm_text:setString(lang_constants:Get("rune_bag_confirm"))
    end
end

function rune_bag_panel:ShowBagNumText()
    if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"] then
        self.bag_num_desc_text:setString(lang_constants:Get("rune_bag_rune_num"))
        self.bag_num_value_text:setString(string.format("%d/%d", #self.rune_list, rune_logic:GetRuneBagCapacity()))
    elseif self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_MUILT"] then
        self.bag_num_desc_text:setString(lang_constants:Get("rune_bag_selected_num"))
        self.bag_num_value_text:setString(string.format("%d/%d", self.select_num, constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"]))
    else
        self.bag_num_desc_text:setString("")
        self.bag_num_value_text:setString("")
    end
end

function rune_bag_panel:ResetAllBagCell(select_list)
    for rune_id,selected_sub_panel in pairs(self.select_list) do
        selected_sub_panel.is_selected = false
        selected_sub_panel.select_img:setVisible(false)
    end
    self.select_list = {}
    self.select_num = 0
    if select_list then
        for i,rune_info in ipairs(select_list) do
            for row,col_info in ipairs(self.rune_sub_panels) do
                for col,sub_panel in ipairs(col_info) do
                    if sub_panel.rune_info and sub_panel.rune_info.rune_id == rune_info.rune_id then
                        self:SelectRune(sub_panel)
                        if i == 1 and row > 5 then
                            self.scroll_view:jumpToPercentVertical(100 * (row - 1) / self.row_num)
                        end
                    end
                end
            end
        end
    end
end

function rune_bag_panel:ShowRunes()
    local bag_cell_num = rune_logic:GetRuneBagCapacity()
    local row_num = 0
    if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"] and bag_cell_num < rune_logic:GetMaxRuneBagCapacity() then
        row_num = math.ceil((bag_cell_num + 1) / BAG_CELL_COL)
    else
        row_num = math.ceil(bag_cell_num / BAG_CELL_COL)
    end

    self.row_num = row_num
    self:CreateRuneBag(self.row_num)

    local height = math.max(self.row_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)
    local begin_y = height + FIRST_SUB_PANEL_OFFSET
    for rune_row = 1, self.sub_panel_row do
        self:ShowSingleRowRune(rune_row, self.rune_sub_panels[rune_row], begin_y - (rune_row - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)
end

function rune_bag_panel:ShowSingleRowRune(rune_row, sub_row_panel, pos_y)
    for col = 1, BAG_CELL_COL do
        local data_index = (rune_row - 1) * BAG_CELL_COL + col
        local sub_panel = sub_row_panel[col]

        sub_panel.root_node:setVisible(true)
        sub_panel:ShowSelectImg(false)

        if data_index <= #self.rune_list then
            sub_panel:Show(self.rune_list[data_index], RUNE_BAG_CELL_STATUS["have_rune"])
            if self.select_list[self.rune_list[data_index].rune_id] then
                sub_panel:ShowSelectImg(true)
            end
        elseif data_index <= rune_logic:GetRuneBagCapacity() then
            sub_panel:Show(nil, RUNE_BAG_CELL_STATUS["no_rune"])
        elseif data_index == (rune_logic:GetRuneBagCapacity() + 1) then
            sub_panel:Show(nil, RUNE_BAG_CELL_STATUS["lock"])
        else
            sub_panel:Hide()
        end

        if pos_y then
            sub_panel.root_node:setPositionY(pos_y)
        end
    end
end

function rune_bag_panel:CreateRuneBag(row)
    local cur_row = math.min(BAG_CELL_ROW, row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local bag_init_x = self.rune_template:getPositionX()
    local bag_offset_x = 120

    for row = self.sub_panel_row + 1, cur_row do
        self.rune_sub_panels[row] = {}

        for col = 1, BAG_CELL_COL do
            local x = bag_init_x + (col - 1) * bag_offset_x
            local tag = (row - 1) * BAG_CELL_COL + col

            local sub_panel = rune_sub_panel.New()
            sub_panel:Init(self.rune_template:clone())
            sub_panel.root_node:setTag(tag)
            sub_panel.root_node:setPositionX(x)

            sub_panel.root_node:setTouchEnabled(true)
            sub_panel.root_node:addTouchEventListener(self.select_rune_method)
            self.scroll_view:addChild(sub_panel.root_node)

            self.rune_sub_panels[row][col] = sub_panel
            sub_panel.root_node:setVisible(true)
        end
        self.rune_sub_panels[row].root_node = self.rune_sub_panels[row][1].root_node
    end

    self.sub_panel_row = cur_row
end

function rune_bag_panel:SelectRune(sub_panel)
    if sub_panel then
        local rune_info = sub_panel.rune_info
        local cell_type = sub_panel.cell_type
        if rune_info and cell_type == RUNE_BAG_CELL_STATUS["have_rune"] then

            if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["SELECT_MUILT"] then
                if not sub_panel.is_selected and self.select_num >= constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"] then
                    graphic:DispatchEvent("show_prompt_panel", "could_not_select_more_rune", constants["MAX_RUNE_BAG_MUILT_SELECT_NUM"])
                    return
                end
                if self.target_rune_id and self.target_rune_id == sub_panel.rune_info.rune_id then 
                    graphic:DispatchEvent("show_prompt_panel", "the_rune_is_upgrade_target")
                    return
                end
                if sub_panel.rune_info.equip_pos > 0 then
                    graphic:DispatchEvent("show_prompt_panel", "the_rune_has_equipped")
                    return
                end
                sub_panel:ShowSelectImg(not sub_panel.is_selected)
                self.select_list[rune_info.rune_id] = sub_panel.is_selected and sub_panel or nil
                self.select_num = self.select_num + (sub_panel.is_selected and 1 or -1)
            else
                for rune_id,selected_sub_panel in pairs(self.select_list) do
                    selected_sub_panel:ShowSelectImg(false)
                end
                self.select_list = {}

                sub_panel:ShowSelectImg(true)
                self.select_list[rune_info.rune_id] = sub_panel
                self.select_num = 1
            end

            self.rune_name_text:setString(rune_info.template_info.name)
            self.rune_level_text:setString(string.format(lang_constants:Get("rune_level"), rune_info.level))
            local desc_str = rune_logic:GetRunePropertysDesc(rune_info.template_id, rune_info.level)
            if desc_str ~= "" then
                desc_str = desc_str .. lang_constants:Get("comma")
            end
            self.rune_desc_text:setString(desc_str .. rune_info.template_info.desc)

        elseif cell_type == RUNE_BAG_CELL_STATUS["lock"] then
            if rune_logic:IsCanBuyRuneBugCell(true) then
                local mode = client_constants.CONFIRM_MSGBOX_MODE["buy_rune_bag_cell"]
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
            end
        end

    else
        self.rune_name_text:setString("")
        self.rune_level_text:setString("")
        self.rune_desc_text:setString("")
    end
end

function rune_bag_panel:RegisterEvent()
    graphic:RegisterEvent("refresh_rune_bag", function()
        if not self.root_node:isVisible() then
            return
        end

        self:ShowRunes()
        self:ShowBagNumText()
    end)
end

function rune_bag_panel:RegisterWidgetEvent()

    self.select_rune_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()

            local row = math.ceil(index / BAG_CELL_COL)
            local col = index - (row - 1) * BAG_CELL_COL
            local sub_panel = self.rune_sub_panels[row][col]

            self:SelectRune(sub_panel)
            self:ShowBagNumText()
        end
    end

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
            
            local select_rune_list = {}
            for rune_id,selected_sub_panel in pairs(self.select_list) do
                if selected_sub_panel.rune_info then
                    table.insert(select_rune_list, selected_sub_panel.rune_info)
                end
            end
            
            if #select_rune_list > 0 then
                if self.show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"] then
                    graphic:DispatchEvent("show_world_sub_scene", "rune_upgrade_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], select_rune_list[1])
                end
                graphic:DispatchEvent("rune_bag_select_confirm", self.show_type, select_rune_list)
            end
        end
    end)
    
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return rune_bag_panel

