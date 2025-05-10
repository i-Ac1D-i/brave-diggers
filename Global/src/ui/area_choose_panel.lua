local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local adventure_logic = require 'logic.adventure'
local troop_logic = require "logic.troop"

local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local panel_prototype = require "ui.panel"
local reuse_scrollview = require "widget.reuse_scrollview"

local PLIST_TYPE = ccui.TextureResType.plistType
local MAX_AREA_NUM = constants["MAX_AREA_NUM"]

local GRAY = { r = 177, g = 177, b = 177 }
local WHITE = { r = 255, g = 255, b = 255 }
local PINK = { r = 255, g = 189, b = 189 }

local LIGHT_STAR = client_constants["LIGHT_STAR"]
local DARK_STAR = client_constants["DARK_STAR"]

local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -80

local MAX_SUB_PANEL_NUM = 8

local area_info_sub_panel = panel_prototype.New()
area_info_sub_panel.__index = area_info_sub_panel

function area_info_sub_panel.New()
    return setmetatable({}, area_info_sub_panel)
end

function area_info_sub_panel:Init(root_node, area_id)
    self.root_node = root_node

    root_node:setCascadeColorEnabled(false)

    self.ared_id_text = root_node:getChildByName("id")
    self.name_text = root_node:getChildByName("area_name")
    self.icon_img = root_node:getChildByName("area_icon")

    self.bp_img = self.root_node:getChildByName("bp_icon")
    local diff_icon_img = self.root_node:getChildByName("difficulty_icon_template")
    local begin_x = diff_icon_img:getPositionX()

    self.diff_icon_imgs = {}
    for i = 1, 3 do
        if i == 1 then
            self.diff_icon_imgs[i] = diff_icon_img
        else
            self.diff_icon_imgs[i] = diff_icon_img:clone()
            self.root_node:addChild(self.diff_icon_imgs[i])
        end

        self.diff_icon_imgs[i]:setPositionX(begin_x - 40 * (3 - i))
    end
end

function area_info_sub_panel:Load(area_id)
    self.root_node:setTag(area_id)

    local cur_area_id = adventure_logic.cur_area_id
    local cur_bp = troop_logic:GetTroopBP()

    local area_conf = config_manager.area_info_config[area_id]

    self.ared_id_text:setString(tostring(area_id))
    self.bp_img:getChildByName("value"):setString(tostring(area_conf.bp_limit))
    self.icon_img:loadTexture(area_conf.icon, PLIST_TYPE)

    --每个区域的简单难度的第一个关卡
    local first_maze_id = area_conf.maze_list_map[1][1].ID

    local first_maze_info = adventure_logic.maze_list[first_maze_id]

    local difficulty_num = #area_conf.maze_list_map

    if first_maze_info and (first_maze_info.event_time ~= 0 or cur_bp >= area_conf.bp_limit) then
        self.root_node:setColor(area_id == cur_area_id and PINK or WHITE)
        self.bp_img:setVisible(false)
        self.icon_img:setVisible(true)

        for i = 1, 3 do
            if i <= difficulty_num then
                self.diff_icon_imgs[i]:setVisible(true)

                local map_list = area_conf.maze_list_map[i]
                self.diff_icon_imgs[i]:loadTexture(adventure_logic:IsMazeClear(map_list[#map_list].ID) and LIGHT_STAR or DARK_STAR, PLIST_TYPE)
            else
                self.diff_icon_imgs[i]:setVisible(false)
            end
        end

        self.name_text:setString(area_conf.name)
    else
        self.root_node:setColor(GRAY)
        self.bp_img:setVisible(true)
        self.icon_img:setVisible(false)

        for i = 1, 3 do
            self.diff_icon_imgs[i]:setVisible(false)
        end

        self.name_text:setString(lang_constants:Get("adventure_unknown_area_name"))
    end
end

local area_choose_panel = panel_prototype.New()

function area_choose_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/area_choose_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")

    local area_info_template = self.root_node:getChildByName("area_template")

    self.area_list_sview = self.root_node:getChildByName("area_list")

    self.area_info_sub_panels = {}

    self.cur_area_name_text = self.root_node:getChildByName("explore_area"):getChildByName("area_name")

    for i = 1, MAX_SUB_PANEL_NUM do
        local new_area_root_node = area_info_template:clone()

        local sub_panel = area_info_sub_panel.New()
        sub_panel:Init(new_area_root_node, i)

        self.area_info_sub_panels[i] = sub_panel

        self.area_list_sview:addChild(sub_panel.root_node)
    end
    self.sub_panel_num = MAX_SUB_PANEL_NUM
    area_info_template:setVisible(false)

    self.reuse_scrollview = reuse_scrollview.New(self, self.area_list_sview, self.area_info_sub_panels, SUB_PANEL_HEIGHT)

    self.reuse_scrollview:RegisterMethod(
        function(self)
            return MAX_AREA_NUM
        end,

        function(self, sub_panel, is_up)
            if is_up then
                sub_panel:Load(self.data_offset + self.sub_panel_num)
            else
                sub_panel:Load(self.data_offset + 1)
            end
        end
    )

    self:RegisterWidgetEvent()
end

function area_choose_panel:Show()
    self.root_node:setVisible(true)

    local data_offset = math.min(adventure_logic.cur_area_id, constants.MAX_AREA_NUM - MAX_SUB_PANEL_NUM) - 1
    local height = math.max((MAX_AREA_NUM + 1) * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = self.area_info_sub_panels[i]
        sub_panel:Load(data_offset + i)
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (data_offset + i-1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, data_offset)

    self.cur_area_name_text:setString(config_manager.area_info_config[adventure_logic.cur_area_id].name)
end

function area_choose_panel:RegisterWidgetEvent()
    local enter_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local area_id = widget:getTag()
            --已经解锁
            if not adventure_logic:IsAreaUnlocked(area_id) then
                return
            end

            local difficulty = 1
            local area_conf = config_manager.area_info_config[area_id]
            --简单难度
            local map_list = area_conf.maze_list_map[1]
            if adventure_logic:IsMazeNew(map_list[1].ID) then
                graphic:DispatchEvent("show_world_sub_panel", "bp_limit_msgbox", area_conf, map_list[1].ID)
            else
                graphic:DispatchEvent("show_world_sub_scene", "exploring_sub_scene", "", area_id, difficulty)
            end
        end
    end

    for i = 1, MAX_SUB_PANEL_NUM do
        self.area_info_sub_panels[i].root_node:addTouchEventListener(enter_method)
    end

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return area_choose_panel
