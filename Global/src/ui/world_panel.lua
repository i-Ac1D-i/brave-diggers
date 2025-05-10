local user_logic = require "logic.user"
local resource_logic = require "logic.resource"
local troop_logic = require "logic.troop"
local mining_logic = require "logic.mining"
local payment_logic = require "logic.payment"
local time_logic = require "logic.time"
local graphic = require "logic.graphic"
local config_manager = require "logic.config_manager"
local platform_manager = require "logic.platform_manager"
local constants = require "util.constants"
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local audio_manager = require "util.audio_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local RESOURCE_TYPE = constants.RESOURCE_TYPE
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local spine_manager = require "util.spine_manager"

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local TAB_TYPE = client_constants["WORLD_TAB_TYPE"]
local TEXT_BORDER_WIDTH = 3
local BUTTOM_TEXT_ZORDER = 1

local CHECKIN_TIME = constants["CHECKIN_TIME"]

local WORLD_PANEL_SHOW_MODE = client_constants.WORLD_PANEL_SHOW_MODE
local WORLD_PANEL_SHOW_MODE_LIST =
{
    ["exploring_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["maze_choose_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["adventure_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["mercenary_detail_sub_scene"] = WORLD_PANEL_SHOW_MODE["hide_both"],
    ["leader_sub_scene"] = WORLD_PANEL_SHOW_MODE["hide_both"],
    ["formation_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["mercenary_list_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["temple_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["arena_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["ladder_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["achievement_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["pvp_sub_scene"] = WORLD_PANEL_SHOW_MODE["show_both"],
    ["mercenary_choose_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["quest_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["carnival_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["rune_bag_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["rune_draw_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["rune_equip_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["rune_upgrade_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
    ["escort_sub_scene"] =  WORLD_PANEL_SHOW_MODE["show_both"],
}

local POSITION =
{
    { x = 53, y = 50 },
    { x = 160, y = 50 },
    { x = 267, y = 50 },
    { x = 374, y = 50 },
    { x = 481, y = 50 },
    { x = 588, y = 50 },
}

local BACK_TO_MAIN_PANEL =
{
    ["exploring_sub_scene"] = 1,
    ["mining_sub_scene"] = 1,
    ["pvp_sub_scene"] = 1,
    ["recruit_sub_scene"] = 1,
    ["mercenary_sub_scene"] = 1,
}

local BACK_TO_CHOOSE_UI_BTN = 
{
    ["exploring_sub_scene"] = TAB_TYPE["adventure"],
    ["mining_sub_scene"] = TAB_TYPE["mining"],
    ["pvp_sub_scene"] = TAB_TYPE["arena"],
    ["recruit_sub_scene"] = TAB_TYPE["recruit"],
    ["mercenary_sub_scene"] = TAB_TYPE["mercenary"],
    
    ["mining_district_sub_scene"] = {},
    ["formation_sub_scene"] = {},
    ["mercenary_list_sub_scene"] = {},
    ["temple_sub_scene"] = {},
    ["arena_sub_scene"] = {},
    ["ladder_sub_scene"] = {},
    ["mercenary_choose_sub_scene"] =  {},
    ["transmigration_sub_scene"] = {},
    ["leader_weapon_sub_scene"] = {},
    ["mercenary_fire_sub_scene"] = {},
    ["mercenary_library_sub_scene"] = {},
    ["mercenary_contract_sub_scene"] = {},
    ["mercenary_levelup_sub_scene"] = {},
    ["area_choose_sub_scene"] = {},
    ["uarry_sub_scene"] = {},
    ["cave_event_sub_scene"] = {},
    ["payment_sub_scene"] = {},
    ["campaign_sub_scene"] = {},
}

local EVENT_ID_WORLD_TAB = {}

local world_panel = panel_prototype.New()
function world_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/world_panel.csb")

    local top_node = self.root_node:getChildByName("top")
    self.maze_icon_img = top_node:getChildByName("maze_icon")
    self.exp_img = top_node:getChildByName("exp")

    self.bp_text = top_node:getChildByName("bp_value")
    self.gold_coin_text = top_node:getChildByName("coin_value")
    self.exp_text = top_node:getChildByName("exp_value")

    self.bp_unit_text = top_node:getChildByName("bp_unit")
    self.gold_coin_unit_text = top_node:getChildByName("coin_unit")
    self.exp_unit_text = top_node:getChildByName("exp_unit")

    self.blood_diamond_text = top_node:getChildByName("blood_diamond_value")

    self.buy_btn = top_node:getChildByName("buy_btn")

    self.time_text = self.root_node:getChildByName("time")

    self.top_node = top_node

    self.bottom_node = self.root_node:getChildByName("bottom")

    self.tab_spine_nodes = {}
    self.remind_imgs = {}

    for i = 1, 6 do
        local spine_node = spine_manager:GetNode("tab", 1.0, true)

        local position = POSITION[i]
        spine_node:setPosition(position.x, position.y)

        spine_node:setSkin("tab" .. i)
        spine_node:setToSetupPose()

        local animation_name = "normal"

        if i == TAB_TYPE["arena"] then
            animation_name = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"]) and "normal" or "lock"

        elseif i == TAB_TYPE["recruit"] then
            animation_name = user_logic:IsFeatureUnlock(FEATURE_TYPE["recruit"]) and "normal" or "lock"

        elseif i == TAB_TYPE["mercenary"] then
            animation_name = user_logic:IsFeatureUnlock(FEATURE_TYPE["mercenary"]) and "normal" or "lock"

        elseif i == TAB_TYPE["mining"] then
            animation_name = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"]) and "normal" or "lock"
        end

        spine_node:setAnimation(0, animation_name, false)

        self.tab_spine_nodes[i] = spine_node
        self.bottom_node:addChild(spine_node)

        local img = self.bottom_node:getChildByName("remind_icon" .. i)

        if img then
            self.remind_imgs[i] = img
            img:setLocalZOrder(1)
            img:setVisible(false)
        end

        local name_text = self.bottom_node:getChildByName("name" .. i )
        panel_util:SetTextOutline(name_text, 0x000000, TEXT_BORDER_WIDTH)
        name_text:setLocalZOrder(BUTTOM_TEXT_ZORDER)
    end

    self.tab_spine_nodes[TAB_TYPE["main"]]:setAnimation(0, "enter", false)

    self.panel_desc_node = self.root_node:getChildByName("panel_desc")

    self.tip_text = self.panel_desc_node:getChildByName("desc_list"):getChildByName("desc")

    self.cur_tab_index = 1

    -- 计时器 1秒
    self.loop_time = 0
    self.root_node:setVisible(true)

    -- 生成event_id 到 world_tab 的关系表
    for k, v in pairs(client_constants.WORLD_TAB_TYPE) do
        EVENT_ID_WORLD_TAB[v] = self:GetEventID(k)
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function world_panel:Show(cur_sub_scene_name)

    local mode = WORLD_PANEL_SHOW_MODE_LIST[cur_sub_scene_name] or WORLD_PANEL_SHOW_MODE["show_both"]
    self.cur_sub_scene_name = cur_sub_scene_name

    if mode == WORLD_PANEL_SHOW_MODE["show_top"] then
        self.top_node:setVisible(true)
        self.bottom_node:setVisible(false)
        self.panel_desc_node:setVisible(false)

    elseif mode == WORLD_PANEL_SHOW_MODE["show_bottom"] then
        self.top_node:setVisible(false)
        self.bottom_node:setVisible(true)
        self.panel_desc_node:setVisible(true)

        local tip_str = lang_constants:GetTip(cur_sub_scene_name)
        if tip_str ~= "" then
            self.tip_text:setString(tip_str)
            self.tip_text:setPositionX(700)
        end

    elseif mode == WORLD_PANEL_SHOW_MODE["show_both"] then
        self.top_node:setVisible(true)
        self.bottom_node:setVisible(true)
        self.panel_desc_node:setVisible(true)

        local tip_str = lang_constants:GetTip(cur_sub_scene_name)
        if tip_str ~= "" then
            self.tip_text:setString(tip_str)
            self.tip_text:setPositionX(700)
        end

    elseif mode == WORLD_PANEL_SHOW_MODE["hide_both"] then
        self.top_node:setVisible(false)
        self.bottom_node:setVisible(false)
        self.panel_desc_node:setVisible(false)
    end

    local resource_list = resource_logic:GetResourceList()
    panel_util:ConvertUnit(troop_logic.battle_point, self.bp_text, self.bp_unit_text)
    panel_util:ConvertUnit(resource_list.gold_coin, self.gold_coin_text, self.gold_coin_unit_text)

    self.blood_diamond_text:setString(resource_list.blood_diamond)

    self.root_node:setVisible(true)
    
    print("****",cur_sub_scene_name)
    self.return_to_main = false
    if BACK_TO_MAIN_PANEL[cur_sub_scene_name] then
        self.return_to_main = true
    end

    if BACK_TO_CHOOSE_UI_BTN[cur_sub_scene_name] then
        if type(BACK_TO_CHOOSE_UI_BTN[cur_sub_scene_name]) ~= "table" then
            self:UpdateTabStatus(BACK_TO_CHOOSE_UI_BTN[cur_sub_scene_name])
        end
    else
        self:UpdateTabStatus(TAB_TYPE["main"])
    end
    
end

function world_panel:Update(elapsed_time)
    if self.panel_desc_node:isVisible() then
        local cur_x = self.tip_text:getPositionX()
        if cur_x < -700 then
            cur_x = 700

            local tip_str = lang_constants:GetTip(self.cur_sub_scene_name)
            if tip_str ~= "" then
                self.tip_text:setString(tip_str)
                self.tip_text:setPositionX(700)
            end
        else
            cur_x = cur_x - 100 * elapsed_time
        end

        self.tip_text:setPositionX(cur_x)
    end

    self.loop_time = self.loop_time + elapsed_time
    if self.loop_time >= 1 then
        local t_now = time_logic:Now()
        local t = time_logic:GetDateInfo(t_now)

        for k, hour in pairs(CHECKIN_TIME) do
            if hour == t.hour then
                graphic:DispatchEvent("remind_check_in")
                break
            end
        end

        self.loop_time = 0
    end

    local date_info = time_logic:GetDateInfo(time_logic:Now())
    local locale = platform_manager:GetLocale()
    if locale == "zh-CN" or locale == "zh-TW" then 
        self.time_text:setString(string.format("%02d/%02d %02d:%02d", date_info.month, date_info.day, date_info.hour, date_info.min))
    elseif locale == "en-US" or locale == "de" or locale == "ru" or locale == "es-MX"  then
        self.time_text:setString(string.format("%02d/%02d %02d:%02d", date_info.day, date_info.month, date_info.hour, date_info.min))
    elseif  locale == "fr" then
        self.time_text:setString(string.format("%02d/%02d %02dh%02d", date_info.day, date_info.month, date_info.hour, date_info.min))    
    end

end

--更新底部按钮状态
function world_panel:UpdateTabStatus(index, animation_type)
    if self.cur_tab_index == index then
        return
    end

    if not animation_type then
        self.tab_spine_nodes[self.cur_tab_index]:setAnimation(0, "exit", false)
        self.tab_spine_nodes[self.cur_tab_index]:addAnimation(0, "normal", false)

        self.cur_tab_index = index

        self.tab_spine_nodes[self.cur_tab_index]:setAnimation(0, "enter", false)
    else
        if animation_type ~= "exit" and animation_type ~= "normal" and animation_type ~= "enter" then
            return
        end

        self.tab_spine_nodes[index]:setAnimation(0, animation_type, false)
    end

end

--刷新冒险REMIND提示
function world_panel:UpdateExploringRemind(flag)
   if self.remind_imgs[2] then
      self.remind_imgs[2]:setVisible(flag)
   end
end

function world_panel:GetEventID(feature_str)
    if not feature_str then
        return
    end
    local open_config = config_manager.open_permanent_config
    local maze_config = config_manager.adventure_maze_config
    local feature_type = client_constants.FEATURE_TYPE[feature_str]

    if not feature_type then
        return
    end

    local maze_id = open_config[feature_type]["value"]
    return maze_config[maze_id].event_id
end

function world_panel:RegisterWidgetEvent()
    local change_sub_scene = function(touch, event)
        local pos = touch:getLocation()
        event:stopPropagation()

        if pos.y > 100 or pos.x > 640 or pos.x < 0 then
            return
        end

        local tab_index = math.ceil(pos.x / 107)
        audio_manager:PlayEffect("click")

        if tab_index == TAB_TYPE["main"] then
            graphic:DispatchEvent("show_world_sub_scene", "main_sub_scene")

        elseif tab_index == TAB_TYPE["adventure"] then
            graphic:DispatchEvent("show_world_sub_scene", "exploring_sub_scene")

        elseif tab_index == TAB_TYPE["mining"] then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"]) then
                mining_logic:QueryCaveEventConfigInfo()
            else
                return
            end

        elseif tab_index == TAB_TYPE["arena"] then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"]) then
                graphic:DispatchEvent("show_world_sub_scene", "pvp_sub_scene")
            else
                return
            end

        elseif tab_index == TAB_TYPE["recruit"] then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["recruit"]) then
                graphic:DispatchEvent("show_world_sub_scene", "recruit_sub_scene", SCENE_TRANSITION_TYPE["none"])
            else
                return
            end

        elseif tab_index == TAB_TYPE["mercenary"] then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["mercenary"]) then
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_sub_scene")
            else
                return
            end
        end

        self:UpdateTabStatus(tab_index)
    end

    local touch_listener = cc.EventListenerTouchOneByOne:create()
    touch_listener:registerScriptHandler(function(touch, event)
        local pos = touch:getLocation()
        if pos.y > 100 or pos.x > 640 or pos.x < 0 then
            return false
        end

        event:stopPropagation()
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    touch_listener:registerScriptHandler(change_sub_scene, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touch_listener, self.bottom_node)

    self.buy_btn:setTouchEnabled(true)
    self.buy_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if not payment_logic.enable_pay then
                graphic:DispatchEvent("show_prompt_panel", "payment_purchase_not_available")
            else
                graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene")
            end
        end
    end)
end

function world_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        local resource_list = resource_logic:GetResourceList()

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["gold_coin"]) then
            panel_util:ConvertUnit(resource_list.gold_coin, self.gold_coin_text, self.gold_coin_unit_text)
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["blood_diamond"]) then
            self.blood_diamond_text:setString(resource_list.blood_diamond)
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["exp"]) then
            panel_util:ConvertUnit(resource_list.exp, self.exp_text, self.exp_unit_text)
        end

    end)

    graphic:RegisterEvent("update_battle_point", function(bp)
        if not self.root_node:isVisible() then
            return
        end

        panel_util:ConvertUnit(bp, self.bp_text, self.bp_unit_text)

    end)

    graphic:RegisterEvent("update_world_tab_status", function(tab_index, animation)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateTabStatus(tab_index, animation)
    end)

    -- 大地图标签：当主界面有任务、好友、讨论区、活动其中至少一个提醒时出现
    graphic:RegisterEvent("remind_world_sub_scene", function(tab_index, visible)
        local remind_img = self.remind_imgs[tab_index]
        if not remind_img then
            return
        end

        -- 出战阵容有空位的提醒
        if tab_index == TAB_TYPE["mercenary"] and visible and not user_logic:IsFeatureUnlock(FEATURE_TYPE["mercenary"], false) then
            visible = false
        end

        remind_img:setVisible(visible)
    end)

    -- 冒险界面提醒
    graphic:RegisterEvent("remind_forge", function(flag)
        self:UpdateExploringRemind(flag)
    end)

    graphic:RegisterEvent("solve_event_result", function(event_id, is_winner)

        if not is_winner then
            return
        end

        for tab_index, v in pairs(EVENT_ID_WORLD_TAB) do
            if v == event_id then
                self:UpdateTabStatus(tab_index, "normal")
                break
            end
        end
    end)
end

return world_panel
