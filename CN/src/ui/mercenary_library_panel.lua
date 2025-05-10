local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local audio_manager = require"util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local campaign_logic = require "logic.campaign"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local config_manager = require "logic.config_manager"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_RANGE = client_constants["SORT_RANGE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local mercenary_library_config = config_manager.mercenary_library_config

local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]
local SUB_PANEL_HEIGHT = 124   --佣兵显示的初始位置x
local MERCENARY_GENRE_TEXT = client_constants["MERCENARY_GENRE_TEXT"]
local MERCENARY_GENRE_COLOR = client_constants["MERCENARY_GENRE_COLOR"]
local MERCENARY_TEMPLATE_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]["list"]

local MERCENARY_FILETER_DESC = {
    [1] = lang_constants:Get("mercenary_library_quality1"),
    [2] = lang_constants:Get("mercenary_library_quality2"),
    [3] = lang_constants:Get("mercenary_library_quality3"),
    [4] = lang_constants:Get("mercenary_library_quality4"),
    [5] = lang_constants:Get("mercenary_library_quality5"),
    [6] = lang_constants:Get("mercenary_library_quality6"),
    [7] = lang_constants:Get("mercenary_library_quality7"),
}

--佣兵子面板
local mercenary_sub_panel = panel_prototype.New()
mercenary_sub_panel.__index = mercenary_sub_panel

function mercenary_sub_panel.New()
    return setmetatable({}, mercenary_sub_panel)
end

function mercenary_sub_panel:Init(root_node)
    self.root_node = root_node
    self.role_img = self.root_node:getChildByName("icon")
    self.fire_num_text = self.root_node:getChildByName("value")
    self.txt_bg_img = self.root_node:getChildByName("txtbg")
    self.genre_text = self.root_node:getChildByName("genre_desc")
    panel_util:SetTextOutline(self.genre_text)

    self.root_node:setCascadeColorEnabled(true)
    self.role_img:ignoreContentAdaptWithSize(true)
    self.role_img:setScale(2, 2)
end

--加载佣兵信息
function mercenary_sub_panel:Show(template_info)
    self.root_node:loadTexture(MERCENARY_BG_SPRITE[template_info.quality], PLIST_TYPE)
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)
    self.genre_text:setString(lang_constants:Get(MERCENARY_GENRE_TEXT[template_info.genre]))
    self.genre_text:setColor(panel_util:GetColor4B(MERCENARY_GENRE_COLOR[template_info.genre]))

    local count = troop_logic:GetMercenaryLibraryCount(template_info.ID)

    if count then
        self.txt_bg_img:setVisible(true)
        self.fire_num_text:setVisible(true)

        self.fire_num_text:setString(count)
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.txt_bg_img:setVisible(false)
        self.fire_num_text:setVisible(false)
        self.root_node:setColor(panel_util:GetColor4B(0x9A9A9A))
    end

    self.template_id = template_info.ID
    self.root_node:setVisible(true)
end

local mercenary_library_panel = panel_prototype.New()
function mercenary_library_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_library_panel.csb")
    local root_node = self.root_node

    --底部
    local bottom_bar = root_node:getChildByName("bottom_bar")
    self.cur_mercenary_num_text = bottom_bar:getChildByName("value")
    self.cur_mercenary_num_desc_text = bottom_bar:getChildByName("num_desc")
    self.cur_mercenary_num_desc_text:setAnchorPoint(0, 0.5)

    self.back_btn = root_node:getChildByName("back_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.mercenary_template = self.scroll_view:getChildByName("rolebg")
    self.mercenary_template:setVisible(false)

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width

    self.sort_btn = bottom_bar:getChildByName("sort_btn")
    self.sort_desc_text = self.sort_btn:getChildByName("desc")

    self.head_sub_panel_y = 0
    self.tail_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.mercenary_offset = 0
    self.sub_panel_row = 0

    self.mercenary_sub_panels = {}
    self.mercenary_num = 0

    self.already_filter_merceanrys = false
    self.mercenary_filters = { {}, {}, {}, {}, {}, {}, {}}
    self.collect_mercenary_num = 0

    self.show_detail_panel = false
    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function mercenary_library_panel:CreateMercenarySubPanels()

    local cur_row = math.min(client_constants["MERCENARY_MAX_PANEL_ROW"], self.cur_mercenary_row)
    if self.sub_panel_row >= cur_row then
        return
    end

    local source = MERCENARY_TEMPLATE_SOURCE
    local begin_x = client_constants["MERCENARY_SUB_PANEL_BEGIN_X"]
    local begin_y = self.height + client_constants["MERCENARY_FIRST_SUB_PANEL_OFFSET"]
    --绑定事件
    for row = self.sub_panel_row + 1, cur_row do
        self.mercenary_sub_panels[row] = {}

        local y = begin_y - (row - 1) * 124
        for col = 1, 5 do
            local sub_panel = mercenary_sub_panel.New()
            sub_panel:Init(self.mercenary_template:clone())
            local tag = (row - 1) * 5 + col

            local x = begin_x + (col - 1) * 124

            sub_panel.root_node:setPosition(x, y)
            sub_panel.root_node:setTag(tag)
            sub_panel.root_node:setVisible(true)
            sub_panel.root_node:setTouchEnabled(true)
            sub_panel.root_node:addTouchEventListener(self.view_mercenary_method)

            self.scroll_view:addChild(sub_panel.root_node)

            self.mercenary_sub_panels[row][col] = sub_panel
        end
    end

    self.sub_panel_row = cur_row
end

function mercenary_library_panel:Show()

    local sort_type = self.sort_type or SORT_TYPE["quality"]
    local sort_range = self.sort_range or SORT_RANGE["all"]

    self:ResetScrollViewAndContent(sort_type, sort_range)
    self.root_node:setVisible(true)

end

function mercenary_library_panel:CalcCollectNum(template_id)
    if  troop_logic:GetMercenaryLibraryCount(template_id) then
        self.collect_mercenary_num = self.collect_mercenary_num + 1
    end
end

--将佣兵根据品质不同，筛选
function mercenary_library_panel:FilterMercenary()
    local mercenary_num = 0
    local list = {}
    self.collect_mercenary_num = 0

    for i, mercenary in pairs(mercenary_library_config) do
        if self.sort_range  <= SORT_RANGE["quality6"] then
            if mercenary.quality == self.sort_range then
                mercenary_num = mercenary_num + 1
                list[mercenary_num] = mercenary
                self:CalcCollectNum(mercenary.ID)
            end

        elseif self.sort_range == SORT_RANGE["all"] then --全体佣兵排序
            mercenary_num = mercenary_num + 1
            list[mercenary_num] = mercenary
            self:CalcCollectNum(mercenary.ID)

        elseif self.sort_range == SORT_RANGE["campaign"] then --合战佣兵排序
            if campaign_logic:CheckSpecialMercenary(mercenary, true) then
                mercenary_num = mercenary_num + 1
                list[mercenary_num] = mercenary
                self:CalcCollectNum(mercenary.ID)
            end
        end
    end

    self.mercenary_list = list
    self.mercenary_num = mercenary_num
end

function mercenary_library_panel:ResetScrollViewAndContent(sort_type, sort_range)
    self.sort_type = sort_type
    self.sort_range = sort_range

    self:FilterMercenary()

    if sort_type == SORT_TYPE["quality"] then
        table.sort(self.mercenary_list, function(mercenary1, mercenary2)
            if mercenary1.quality == mercenary2.quality then
                return mercenary1.ID > mercenary2.ID
            else
                return mercenary1.quality > mercenary2.quality
            end
        end)
    elseif sort_type == SORT_TYPE["genre"] then
        table.sort(self.mercenary_list, function(mercenary1, mercenary2)
            if mercenary1.genre == mercenary2.genre then
                if mercenary1.quality == mercenary2.quality then
                    return mercenary1.ID > mercenary2.ID
                else
                    return mercenary1.quality > mercenary2.quality
                end
            else
                return mercenary1.genre < mercenary2.genre
            end
        end)
    end

    self.cur_mercenary_row = math.ceil(self.mercenary_num / 5)

    local height = math.max(self.cur_mercenary_row * SUB_PANEL_HEIGHT, self.sview_height)
    self.height = height

    self:CreateMercenarySubPanels()

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self:LoadMercenaryInfo()

    self.sort_desc_text:setString(lang_constants:Get("mercenary_sort_type" .. sort_type))

    self.cur_mercenary_num_text:setString(self.collect_mercenary_num .. "/" .. self.mercenary_num)
end

function mercenary_library_panel:SetHeadSubPanel(index)

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

function mercenary_library_panel:LoadMercenaryInfo()
    self.mercenary_offset = 0
    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - self.height)

    local begin_y = self.height + client_constants["MERCENARY_FIRST_SUB_PANEL_OFFSET"]
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

function mercenary_library_panel:ShowSingleRowMercenary(mercenary_row, sub_panel_row, pos_y)
    for col = 1, 5 do

        local tag = self:CalcMercenaryIndex(mercenary_row, col)

        local sub_panel = self.mercenary_sub_panels[sub_panel_row][col]
        local mercenary = self.mercenary_list[tag]

        if tag <= self.mercenary_num then
            sub_panel:Show(mercenary)

        else
            sub_panel.root_node:setVisible(false)
        end

        if pos_y then
            sub_panel.root_node:setPositionY(pos_y)
        end
    end
end

--根据row, col 返回index
function mercenary_library_panel:CalcMercenaryIndex(row, col)
    return (row - 1) * 5 + col
end

--根据索引值返回row , index
function mercenary_library_panel:CalcRowAndCol(index)
    local row = math.ceil(index / 5)
    local col = index  - (row - 1) * 5
    return row, col
end

function mercenary_library_panel:RegisterWidgetEvent()

    --查看某一佣兵信息
    self.view_mercenary_method = function(widget, event_type)

        if event_type == ccui.TouchEventType.ended then
            local index = widget:getTag()

            if index > self.mercenary_num then
                return
            end

            local row, col = self:CalcRowAndCol(index)
            self.cur_sub_panel = self.mercenary_sub_panels[row][col]
            self.cur_template_id =  self.cur_sub_panel.template_id

            if not self.cur_template_id then
                return
            end

            local mode = client_constants["MERCENARY_DETAIL_MODE"]["library"]
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", mode, self.cur_template_id)

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

            elseif y < self.head_sub_panel_y - SUB_PANEL_HEIGHT * 0.5 then

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
            local source = client_constants["SORT_PANEL_SOURCE"]["library"]
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_sort_panel", source, self.sort_type, self.sort_range, function(sort_type, sort_range)
                self:ResetScrollViewAndContent(sort_type, sort_range)
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
end

function mercenary_library_panel:RegisterEvent()

    --图书馆招募成功
    graphic:RegisterEvent("library_recruit_success", function(template_id)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_row do
            local item_row = 0
            if i < self.head_sub_panel_index then
                item_row = self.mercenary_offset + (self.sub_panel_row - self.head_sub_panel_index) + i + 1
            else
                item_row = self.mercenary_offset + i - self.head_sub_panel_index + 1
            end

            self:ShowSingleRowMercenary(item_row, i)
        end
    end)

    --图书馆中有新的佣兵
    graphic:RegisterEvent("library_new_mercenary", function(mercenary)
        if not self.root_node:isVisible() then
            return
        end

        self.collect_mercenary_num = self.collect_mercenary_num + 1
    end)

end

return mercenary_library_panel
