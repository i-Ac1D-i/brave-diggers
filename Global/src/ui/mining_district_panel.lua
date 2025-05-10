local panel_prototype = require "ui.panel"
local feature_config = require "logic.feature_config"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local resource_logic = require "logic.resource"
local mining_logic = require "logic.mining"
local time_logic = require "logic.time"
local user_logic = require "logic.user"

local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local spine_manager = require "util.spine_manager"
local platform_manager = require "logic.platform_manager"

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local RESOURCE_TYPE_NAME = constants.RESOURCE_TYPE_NAME
local CONST_BLOCK_TYPE = constants.BLOCK_TYPE
local FIX_BLOCK_SPRITE = client_constants.FIX_BLOCK_SPRITE

local PLIST_TYPE = ccui.TextureResType.plistType
local BOSS_MAP = constants.MINING_BOSS_MAP

local CHEST_LIST
if feature_config:IsFeatureOpen("open_chest") then
    CHEST_LIST =
    {
        { CONST_BLOCK_TYPE["chest1"], 1 },
        { CONST_BLOCK_TYPE["chest2"], 60 },
        { CONST_BLOCK_TYPE["chest3"], 120 },
        { CONST_BLOCK_TYPE["chest4"], 180 },
        { CONST_BLOCK_TYPE["chest5"], 240 },
        { CONST_BLOCK_TYPE["chest6"], 240 },
    }
else
    CHEST_LIST = {}
end

local block_info_sub_panel = panel_prototype.New()
block_info_sub_panel.__index = block_info_sub_panel
function block_info_sub_panel.New()
    return setmetatable({}, block_info_sub_panel)
end

function block_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.name_text = root_node:getChildByName("name")
    self.condition_text = root_node:getChildByName("condition")
end

function block_info_sub_panel:Load(block_type, level)
    local conf = config_manager.mining_dig_info_config[block_type]

    local cur_golem_lv = mining_logic.golem_lv

    if block_type >= CONST_BLOCK_TYPE["chest1"] and block_type <= CONST_BLOCK_TYPE["chest6"] then
        if cur_golem_lv >= level then
            self.name_text:setString(string.format(lang_constants:Get("mining_chest_tooltip1"), conf.name))
            self.name_text:setColor(panel_util:GetColor4B(0xBCDD19))
        else
            self.name_text:setString(string.format(lang_constants:Get("mining_chest_tooltip2"), conf.name))
            self.name_text:setColor(panel_util:GetColor4B(0xFFD002))
        end

        self.condition_text:setString(string.format(lang_constants:Get("mining_chest_tooltip3"), cur_golem_lv, level, level-1))

    else
        --boss
        self.name_text:setString(string.format(conf.name))
        self.name_text:setColor(panel_util:GetColor4B(0xFFD002))
        self.condition_text:setString(string.format(lang_constants:Get("mining_chest_tooltip3"), cur_golem_lv, level, level-1))
    end

    self.root_node:loadTexture(FIX_BLOCK_SPRITE[block_type] .. ".png", PLIST_TYPE)
end

local golem_tooltip_panel = panel_prototype.New()
function golem_tooltip_panel:Init(root_node)
    self.root_node = root_node

    self.level_text = root_node:getChildByName("level")
    self.arrow_img = root_node:getChildByName("arrow")

    self.tooltip_img = root_node:getChildByName("tooltip")

    self.template = self.tooltip_img:getChildByName("template")

    local size = self.tooltip_img:getContentSize()

    self.width = size.width

    self.desc_text = self.tooltip_img:getChildByName("desc")

    local sub_panel = block_info_sub_panel.New()
    sub_panel:Init(self.template)

    self.block_info_sub_panels = {sub_panel}
    self.sub_panel_num = 1

    self.need_reload = true
    self:RegisterWidgetEvent()
end

function golem_tooltip_panel:Show()
    self.level_text:setString(lang_constants:Get("level_shot_string") .. mining_logic.golem_lv)

    self.tooltip_img:setVisible(false)
    --默认朝上
    self.arrow_img:setRotation(90)
end

function golem_tooltip_panel:Load()
    if not self.need_reload then
        return
    end

    local valid_sub_panel_num = 1
    local golem_lv = mining_logic.golem_lv

    --没有BOSS可以击杀
    if mining_logic.boss_id == 0 then
        local sub_panel = self.block_info_sub_panels[1]
        local block_type = CONST_BLOCK_TYPE["seven_doom"]
        local conf = config_manager.mining_dig_info_config[block_type]

        sub_panel.root_node:loadTexture(FIX_BLOCK_SPRITE[block_type] .. ".png", PLIST_TYPE)
        sub_panel.name_text:setString(string.format(conf.name))
        sub_panel.condition_text:setString(lang_constants:Get("mining_no_more_boss"))

    else
        self.block_info_sub_panels[1]:Load(mining_logic.boss_id, BOSS_MAP[mining_logic.boss_id])
    end

    --梦魇
    if mining_logic.next_boss_id  then
        valid_sub_panel_num = valid_sub_panel_num + 1
    end
    for i = 1, #CHEST_LIST do
        local block_info = CHEST_LIST[i]

        local block_type, lv = block_info[1], block_info[2]
        valid_sub_panel_num = valid_sub_panel_num + 1

        if golem_lv < lv then
            break
        end
    end
    
    local index = 2

    for i = self.sub_panel_num + 1, valid_sub_panel_num do
        local sub_panel = block_info_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.tooltip_img:addChild(sub_panel.root_node)
        table.insert(self.block_info_sub_panels, sub_panel)
    end

    if valid_sub_panel_num > self.sub_panel_num then
        self.sub_panel_num = valid_sub_panel_num
    end

    if mining_logic.next_boss_id then
        self.block_info_sub_panels[2]:Load(mining_logic.next_boss_id, BOSS_MAP[mining_logic.next_boss_id])
        index = 3
    end

    for i = index, valid_sub_panel_num do
        local block_info = CHEST_LIST[i-index+1]

        local block_type, lv = block_info[1], block_info[2]
        self.block_info_sub_panels[i]:Load(block_type, lv)

        if golem_lv < lv then
            break
        end
    end

    local height = 160 + (valid_sub_panel_num-1) * 60
    self.tooltip_img:setContentSize(self.width, height)

    self.desc_text:setPositionY(height - 26)
    height = height - 112

    for i = 1, self.sub_panel_num do
        local node = self.block_info_sub_panels[i].root_node
        if i <= valid_sub_panel_num then
            node:setVisible(true)
            node:setPositionY(height - (i-1) * 60)

        else
            node:setVisible(false)
        end
    end

    self.need_reload = false
end

function golem_tooltip_panel:RegisterWidgetEvent()
    self.root_node:addTouchEventListener(function(widget, event_type)

        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            self.tooltip_img:setVisible(true)
            self.arrow_img:setRotation(270)
            self:Load()

        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.tooltip_img:setVisible(false)
            self.arrow_img:setRotation(90)
        end
    end)
end

local mining_district_panel = panel_prototype.New()
function mining_district_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mining_ore_district_panel.csb")

    self.tnt_num_text = self.root_node:getChildByName("tnt_bg"):getChildByName("num")
    self.coordinate_text = self.root_node:getChildByName("coordinate")

    self.quarry_btn = self.root_node:getChildByName("quarry_btn")
    self.quarry_remind_img = self.quarry_btn:getChildByName("remind_icon")

    self.ore_bag_btn = self.root_node:getChildByName("ore_bag_btn")

    local pickaxe_bg = self.root_node:getChildByName("pickaxe_bg")
    self.recover_time_lbar = pickaxe_bg:getChildByName("recover_lbar")
    self.pickaxe_lv_text = pickaxe_bg:getChildByName("lv")
    self.pickaxe_count_text = pickaxe_bg:getChildByName("count")
    self.golem_tip_img = pickaxe_bg:getChildByName("golem_tip")
    self.golem_tip_img:setVisible(true)

    self.golem_num_text = self.golem_tip_img:getChildByName("value")

    self.chest_tip_img = self.root_node:getChildByName("chest_tip")
    self.chest_num_text = self.chest_tip_img:getChildByName("value")

    self.spine_node = spine_manager:GetNode("golem_tip")
    self.spine_node:setVisible(false)
    pickaxe_bg:addChild(self.spine_node)

    self.spine_node:registerSpineEventHandler(function(event)
        self.spine_node:setVisible(false)
    end, sp.EventType.ANIMATION_END)

    self.refresh_time_btn = self.root_node:getChildByName("refresh_btn")
    local language = platform_manager:GetLocale()
    if language == "fr" or language == "es-MX" or language == "de" and platform_manager:GetChannelInfo().mining_district_panel_change_refresh_btn_size then
        self.refresh_time_btn:setContentSize(self.refresh_time_btn:getContentSize().width + 26, self.refresh_time_btn:getContentSize().height)
    end

    self.add_pickaxe_count_btn = pickaxe_bg:getChildByName("add")
    self.pickaxe_bg = pickaxe_bg

    golem_tooltip_panel:Init(self.root_node:getChildByName("golem_info"))

    self.back_btn = self.root_node:getChildByName("back_btn")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mining_district_panel:Show()
    self.root_node:setVisible(true)

    self.pickaxe_lv_text:setString(lang_constants:Get("level_shot_string") .. mining_logic.pickaxe_id)
    self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)

    self.tnt_num_text:setString("x " .. resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"]))

    self.quarry_remind_img:setVisible(mining_logic:IsProjectCompleted())

    self.recover_time_lbar:setPercent(mining_logic.dig_recover_time / mining_logic.max_recover_time)
    if mining_logic.golem_num > 0 then
        self.golem_tip_img:setVisible(true)
        self.golem_num_text:setString(tostring(mining_logic.golem_num))
    else
        self.golem_tip_img:setVisible(false)
    end

    self:CheckGolem()
    golem_tooltip_panel:Show()

    local chest_num = #mining_logic.chest_coordinates

    if chest_num > 0 then
        self.chest_tip_img:setVisible(true)
        self.chest_num_text:setString(tostring(chest_num))

    else
        self.chest_tip_img:setVisible(false)
    end
end

function mining_district_panel:Hide()
    self.root_node:setVisible(false)
end

local color = { r = 0, g = 0, b = 0 }

local time_delta = 0
function mining_district_panel:Update(elapsed_time)
    time_delta = time_delta + elapsed_time
    if time_delta >= 1 then
        self.quarry_remind_img:setVisible(mining_logic:IsProjectCompleted())
        time_delta = 0
    end

    local need_animation = mining_logic.golem_num > 0 or mining_logic.dig_count < mining_logic.golem_num + 1
    if need_animation and self.spine_node:isVisible() then
        local _, _, _, _, _, rotation, r, g, b = self.spine_node:getSlotTransform("alpha")

        self.pickaxe_bg:setRotation(rotation)
        color.r = r
        color.g = g
        color.b = b

        self.pickaxe_bg:setColor(color)
    end
end

function mining_district_panel:CheckDigCount()
    -- 矿镐不足时
    if mining_logic.dig_count < (mining_logic.golem_num + 1) and not self.spine_node:isVisible() then
        self.spine_node:setVisible(true)
        self.spine_node:setAnimation(0, "animation", false)
    end
end

function mining_district_panel:CheckGolem()
    local golem_num = mining_logic.golem_num

    if golem_num == 0 and self.spine_node:isVisible() then
        self.spine_node:clearTrack(0)
        self.spine_node:setVisible(false)

    elseif golem_num > 0 and not self.spine_node:isVisible() then
        self.spine_node:setToSetupPose()
        self.spine_node:setVisible(true)
        self.spine_node:setAnimation(0, "animation", false)
    end
end

function mining_district_panel:RegisterEvent()
    graphic:RegisterEvent("update_dig_recover_time", function(is_increased)
        if not self.root_node:isVisible() then
            return
        end

        local percent = math.min(mining_logic.dig_recover_time / mining_logic.max_recover_time * 100, 100)
        self.recover_time_lbar:setPercent(percent)

        if is_increased then
            self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
        end
    end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["tnt"]) then
            self.tnt_num_text:setString("x " .. resource_logic:GetResourceNum(RESOURCE_TYPE["tnt"]))
        end
    end)

    graphic:RegisterEvent("use_mining_tool", function()
        if not self.root_node:isVisible() then
            return
        end

        self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
    end)

    graphic:RegisterEvent("show_new_mining_block", function(block_str)
        self.pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
        local chest_num = #mining_logic.chest_coordinates
        local golem_num = mining_logic.golem_num

        if golem_num > 0 then
            self.golem_num_text:setString(tostring(golem_num))
            self.golem_tip_img:setVisible(true)
            self:CheckGolem()
        end

        if chest_num > 0 then
            self.chest_tip_img:setVisible(true)
            self.chest_num_text:setString(tostring(chest_num))
        end
    end)

    graphic:RegisterEvent("finish_dig_block", function(block_type)
        if not block_type then
            return
        end

        if block_type == CONST_BLOCK_TYPE["golem"] then
            self.golem_num_text:setString(tostring(mining_logic.golem_num))

            if mining_logic.golem_num == 0 then
                self.golem_tip_img:setVisible(false)
                self:CheckGolem()
            end

            golem_tooltip_panel.need_reload = true
            golem_tooltip_panel.level_text:setString(lang_constants:Get("level_shot_string") .. mining_logic.golem_lv)

        elseif block_type >= CONST_BLOCK_TYPE["chest1"] and block_type <= CONST_BLOCK_TYPE["chest6"] then
            local chest_num = #mining_logic.chest_coordinates
            self.chest_num_text:setString(tostring(chest_num))

            if chest_num == 0 then
                self.chest_tip_img:setVisible(false)
            end

        elseif block_type >= CONST_BLOCK_TYPE["red_king"] and block_type <= CONST_BLOCK_TYPE["seven_doom"] then
            --击杀BOSS后
            golem_tooltip_panel.need_reload = true
        end
    end)

    graphic:RegisterEvent("refresh_mining_area", function()
        golem_tooltip_panel.need_reload = true

        if not self.root_node:isVisible() then
            return
        end
    end)

    graphic:RegisterEvent("update_mining_boss_info", function(boss_x, boss_y, boss_type)
        golem_tooltip_panel.need_reload = true
    end)
end

function mining_district_panel:RegisterWidgetEvent()

    --打开工坊
    self.quarry_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["quarry"]) then
                graphic:DispatchEvent("show_world_sub_scene", "quarry_sub_scene")
            else
                return
            end
        end
    end)

    --打开仓库
    self.ore_bag_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel")
        end
    end)

    self.refresh_time_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "mining_reset_panel")
        end
    end)

    self.pickaxe_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel", 2)
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    self.spine_node:registerSpineEventHandler(function(event)
        self.spine_node:setVisible(false)
    end, sp.EventType.ANIMATION_END)
end

return mining_district_panel
