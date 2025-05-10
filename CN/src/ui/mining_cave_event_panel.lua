local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local troop_logic = require "logic.troop"
local mining_logic = require "logic.mining" 
local platform_manager = require "logic.platform_manager"

local CHOOSE_ETHER_CAVE = client_constants["MINING_NORMAL_CAVES"]["ether_cave"]
local CHOOSE_MONSTER_CAVE = client_constants["MINING_NORMAL_CAVES"]["monster_cave"]

local CAVE_TYPE = constants.CAVE_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local CAVE_DESC_ARROW_POSITION_X =
{
    [1] =
    { 
        [1] = 219,   
        [2] = 422 

    },

    [2] =
    { 
        [1] = 116,   
        [2] = 320,
        [3] = 523
    },

}

local ETHER_CAVE_TYPE = 
{ 
    [1] = CAVE_TYPE["cave1"],
    [2] = CAVE_TYPE["cave2"],
}

local MONSTER_CAVE_TYPE = 
{
    [1] = CAVE_TYPE["cave3"],
    [2] = CAVE_TYPE["cave4"],
    [3] = CAVE_TYPE["cave5"],
}

local CAVE_EVENT_CAVE_ICON = 
{
    [1] = "icon/resource/coin_res.png",
    [2] = "icon/resource/exp_resource.png",
    [3] = "icon/resource/golem.png",
    [4] = "icon/resource/iron.png",
    [5] = "icon/resource/emerald.png",
}

local PLIST_TYPE = ccui.TextureResType.plistType

local cave_event_list_cell_panel = panel_prototype.New()
cave_event_list_cell_panel.__index = cave_event_list_cell_panel

function cave_event_list_cell_panel.New()
    local t = {}
    return setmetatable(t, cave_event_list_cell_panel)
end

function cave_event_list_cell_panel:Init(root_node, index, data)
    self.root_node = root_node
    self.index = index
    self.config_data = data 

    self.root_node:setColor((panel_util:GetColor4B(0x7F7F7F)))
    self.root_node:setCascadeColorEnabled(true)
    self.name_text = root_node:getChildByName("levels_desc")
    self.level_number_text = root_node:getChildByName("level")
    self.bp_text = root_node:getChildByName("bp_value")
    self.lock_img = root_node:getChildByName("lock_tip")
    self.lock_img:setCascadeColorEnabled(true)
    self.lock_img:setVisible(true)

    self.battle_btn = root_node:getChildByName("challenge_btn")
    self.battle_btn:setCascadeColorEnabled(true)
   
    self:SetData()
    self:RegisterWidgetEvent()
end

function cave_event_list_cell_panel:SetData()
    self.level_number_text:setString(tostring(self.config_data.level))
    self.bp_text:setString(string.format(lang_constants:Get("mining_cave_need_condition"), self.config_data.bp_limit))
    self:UpdateBpTextColor()
    self.name_text:setString(self.config_data.name)
end

function cave_event_list_cell_panel:UpdateBpTextColor()
    local default_color = 0x9C5F4B
    if self.config_data.bp_limit <= troop_logic:GetTroopBP() then 
        default_color = 0x5a6e16
    end
    self.bp_text:setColor(panel_util:GetColor4B(default_color))
end

function cave_event_list_cell_panel:SetOpenStatus(flag)
    if flag then 
        self.root_node:setColor((panel_util:GetColor4B(0xFFFFFF)))
       -- self.battle_btn:setColor((panel_util:GetColor4B(0xFFFFFF)))
        self.lock_img:setVisible(false)
        self.battle_btn:setTouchEnabled(true)
    else
        self.root_node:setColor((panel_util:GetColor4B(0x7F7F7F)))
        --self.battle_btn:setColor((panel_util:GetColor4B(0x7F7F7F)))
        self.lock_img:setVisible(true)
        self.battle_btn:setTouchEnabled(false)
    end
end

function cave_event_list_cell_panel:RegisterWidgetEvent()
    self.battle_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "campaign_event_msgbox", client_constants["CAMPAIGN_MSGBOX_MODE"]["normal_cave"], self.config_data)
        end
    end)
end

local mining_sub_cave_panel = panel_prototype.New()
mining_sub_cave_panel.__index = mining_sub_cave_panel

function mining_sub_cave_panel.New()
    return setmetatable({}, mining_sub_cave_panel)
end

function mining_sub_cave_panel:Init(parent_node,index,sub_type)

    local cave_name 
    self.cave_type = ""

    if sub_type == CHOOSE_ETHER_CAVE then 
       cave_name = "mission1_"
       self.cave_type = ETHER_CAVE_TYPE[index]
    elseif sub_type == CHOOSE_MONSTER_CAVE then 
       cave_name = "mission2_"
       self.cave_type = MONSTER_CAVE_TYPE[index] 
    end 

    local counts = mining_logic.cave_challenge_nums[self.cave_type]

    self.root_node = parent_node:getChildByName(cave_name .. tostring(index))
   
    self.icon_img = self.root_node:getChildByName("icon")
    self.lock_tip_img = self.root_node:getChildByName("lock_tip")
    self.times_img = self.root_node:getChildByName("times")
    self.times_text = self.times_img:getChildByName("value")
    self.times_text:setString(tostring(counts))

    self.times_img:setCascadeColorEnabled(false)
    self.times_text:setCascadeColorEnabled(false)
    self.times_img:setVisible(false)

    self.touch_node = self.root_node:getChildByName("spec_roundbg")
    self.touch_node.position_index = index

    self.root_node:setColor((panel_util:GetColor4B(0x7F7F7F)))
    self.root_node:setVisible(false)

end

function mining_sub_cave_panel:GetTouchNode()
    return self.touch_node
end

function mining_sub_cave_panel:SetColor(color_value)
    self.root_node:setColor((panel_util:GetColor4B(color_value)))
end

function mining_sub_cave_panel:LoadIcon(resource)
    self.icon_img:loadTexture(resource, PLIST_TYPE)
end

function mining_sub_cave_panel:SetUnLocked(flag)
    self.lock_tip_img:setVisible(not flag)
end

function mining_sub_cave_panel:SetChallengeCountsVisible(flag)
    self.times_img:setVisible(flag)
end

function mining_sub_cave_panel:SetChallengeCountsString(str)
    self.times_text:setString(str)
end

function mining_sub_cave_panel:SetTouchEnabled(flag)
    self.touch_node:setTouchEnabled(flag)
end

function mining_sub_cave_panel:AddTouchEventListener(listener)
    self.touch_node:addTouchEventListener(listener)
end

local mining_cave_event_panel = panel_prototype.New(true)

function mining_cave_event_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mining_choose_level_panel.csb")

    self.list_view_cell = self.root_node:getChildByName("template")
    self.list_view_cell:setVisible(false)
    self.root_node:getChildByName("template")
    self.title_bg_img = self.root_node:getChildByName("title_bg")
    self.title_text = self.title_bg_img:getChildByName("title")

    self.cave_sub_panels = {}
    
    self.ether_sub_panels = {}

    self.monster_sub_panels = {}
    
    for i = 1, #ETHER_CAVE_TYPE do
        self.ether_sub_panels[i] = mining_sub_cave_panel.New()
        self.ether_sub_panels[i]:Init(self.root_node, i, CHOOSE_ETHER_CAVE)
    end

    for i = 1, #MONSTER_CAVE_TYPE do
        self.monster_sub_panels[i] = mining_sub_cave_panel.New()
        self.monster_sub_panels[i]:Init(self.root_node, i, CHOOSE_MONSTER_CAVE)
    end

    self.mission_desc_node = self.root_node:getChildByName("mission_desc")
    self.mission_desc_name_text = self.mission_desc_node:getChildByName("name")
    self.mission_desc_time_text = self.mission_desc_node:getChildByName("time")
    self.mission_desc_text = self.mission_desc_node:getChildByName("desc")
    self.mission_desc_arrow_img = self.mission_desc_node:getChildByName("arrow")
    self.mission_desc_node:setVisible(false)

    self.list_view = self.root_node:getChildByName("list_view")
    self.list_view:setVisible(true)
    self.list_view:setClippingEnabled(true)
    self.list_view_items = 0

    self.bottom_img = self.root_node:getChildByName("bottom_bar")
    self.bottom_times_desc_text = self.bottom_img:getChildByName("times_desc")
    self.bottom_times_text = self.bottom_img:getChildByName("times_number")
    self.bottom_times_add_btn = self.bottom_img:getChildByName("times_buy_btn")

    self.bottom_demon_img = self.bottom_img:getChildByName("demon_badge_icon")
    self.bottom_demon_img:loadTexture(config_manager.resource_config[RESOURCE_TYPE["demon_medal"]].icon, PLIST_TYPE)
    self.bottom_boss_counts_text = self.bottom_img:getChildByName("badge_number")

    self.back_btn = self.root_node:getChildByName("back_btn")

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mining_cave_event_panel:ClearListView()
    if self.list_view_items > 0 then 
       self.list_view:removeAllChildren()
       self.list_view_items = 0
    end
end

function mining_cave_event_panel:ResetView()
    self.current_mission_tab_index = 0
    self.current_cave_type = 0
    for _, v in pairs(self.cave_sub_panels) do
        v:Hide()
    end
end

function mining_cave_event_panel:ShowMissionNode()
    local max_show_number
    if self.mission_mode == CHOOSE_ETHER_CAVE then
       max_show_number = #ETHER_CAVE_TYPE
    else
        max_show_number = #MONSTER_CAVE_TYPE
    end

    for i = 1, max_show_number do 
        self.cave_sub_panels[i]:SetColor(0x7F7F7F)
        self.cave_sub_panels[i]:Show()
    end
    self:UpdateTodayMissionNode()
end

function mining_cave_event_panel:UpdateTodayMissionNode()
    local time_now = time_logic:Now()
    local date_now = time_logic:GetDateInfo(time_now)

    local open_event_data = mining_logic.cave_config_info[date_now.wday] 
    local init_flag = false
    for k, v in ipairs(self.cave_types) do 
        local find_flag = false
        for kk, vv in pairs(open_event_data) do
           if v == vv then 
              find_flag = true
              break
           end
        end

        local mission_node = self:GetMissionNode(k)
        self:SetMissionOpenFlag(k,find_flag)

        if find_flag then 
           mission_node:SetUnLocked(true)
           mission_node:SetChallengeCountsVisible(true)
           if not init_flag then 
              self:UpdateMissionTabIndex(k)
              init_flag = true 
           end

        else
            mission_node:SetUnLocked(false)
            mission_node:SetChallengeCountsVisible(false)
        end
    end

end

function mining_cave_event_panel:InitMissionData()
    self.missions = {}
    for k, v in ipairs(self.cave_types) do
        local touch_img = self.cave_sub_panels[k]:GetTouchNode()
        local sub_panel = self.cave_sub_panels[k]
        local mission_index = k
        touch_img.mission_index = mission_index
        sub_panel.cave_type = v
        local t_mission = {node = sub_panel, open_flag = false}
        table.insert(self.missions, t_mission)
    end
end

function mining_cave_event_panel:LoadEtherView()
    self.mission_mode = CHOOSE_ETHER_CAVE
    self.cave_sub_panels = self.ether_sub_panels
    self.cave_types = ETHER_CAVE_TYPE
end

function mining_cave_event_panel:LoadMonsterView()
    self.mission_mode = CHOOSE_MONSTER_CAVE
    self.cave_sub_panels = self.monster_sub_panels
    self.cave_types = MONSTER_CAVE_TYPE
end

function mining_cave_event_panel:Show(mission_mode)

    self:ResetView()

    if mission_mode == CHOOSE_ETHER_CAVE then 
       self:LoadEtherView()
       
    elseif mission_mode == CHOOSE_MONSTER_CAVE then 
       self:LoadMonsterView()
    end

    self:InitMissionData()
    self:SetTitle(0)
    self:ShowMissionNode()
    self:LoadMissionIcon()

    self.bottom_boss_counts_text:setString(panel_util:ConvertUnit(resource_logic:GetResourcenNumByName("demon_medal")))
    
    self.root_node:setVisible(true)
end

function mining_cave_event_panel:SetEventCounts(open_flag)
    local cave_type = self.current_cave_type
    local counts = mining_logic.cave_challenge_nums[cave_type]
    local counts_desc = lang_constants:Get("mining_cave_open_tip")
    --local color_value = 0xFBE494
    if not open_flag then 
       counts_desc = lang_constants:Get("mining_cave_not_open_tip")
      -- color_value = 0xffe08a 
    else
        self.bottom_times_text:setString(counts)
        local mission_node = self:GetMissionNode(self.current_mission_tab_index)
        mission_node:SetChallengeCountsString(counts)
    end
    self.bottom_times_desc_text:setString(counts_desc)
    --self.bottom_times_desc_text:setColor(panel_util:GetColor4B(color_value))
    self.bottom_times_text:setVisible(open_flag)
    self.bottom_times_add_btn:setVisible(open_flag)
end

function mining_cave_event_panel:SetTitle(cave_type)
    local cave_type = cave_type or self.current_cave_type 
    local sub_name_text = ""
    local title_text = lang_constants:Get("mining_cave_event_name" .. tostring(self.mission_mode))
    if cave_type > 0 then 
        sub_name_text = lang_constants:Get("mining_cave_event_type_name" .. tostring(cave_type))
        sub_name_text = string.format(lang_constants:Get("mining_cave_event_sub_name"),sub_name_text)
    end

    if string.len(sub_name_text) > 0 then 
        title_text = title_text .. sub_name_text
    end

    self.title_text:setString(title_text)
end

function mining_cave_event_panel:GetMissionNode(index)
    return self.missions[index].node
end

function mining_cave_event_panel:SetMissionOpenFlag(index, flag)
    self.missions[index].open_flag = flag
end

function mining_cave_event_panel:CheckMissionOpen(index)
    return self.missions[index].open_flag
end

function mining_cave_event_panel:LoadMissionIcon()
    for k,v in ipairs(self.cave_types) do
        local mission_node = self:GetMissionNode(k)
        mission_node:LoadIcon(CAVE_EVENT_CAVE_ICON[v])
    end
end

function mining_cave_event_panel:UpdateMissionTabIndex(new_index)
    if self.current_mission_tab_index ~= new_index then
       if self.current_mission_tab_index > 0 then 
           local mission_node = self:GetMissionNode(self.current_mission_tab_index)
           mission_node:SetColor(0x7F7F7F)
       end 

       self.current_mission_tab_index = new_index
       local mission_node = self:GetMissionNode(self.current_mission_tab_index)
       mission_node:SetColor(0xFFFFFF)
       self:ShowMissionDescTip(mission_node:GetTouchNode(), true)
       self.current_cave_type = mission_node.cave_type
       self:SetTitle()
       local open_flag = self:CheckMissionOpen(new_index)
       self:UpdateListView(open_flag)
       self:SetEventCounts(open_flag)
    end
end

function mining_cave_event_panel:UpdateScrollViewScrollStatus()
    local touch_flag = false
    self.list_view:refreshView()
    if self.show_cells > 4 then
       touch_flag = true 
       self.list_view:jumpToBottom()
    end
    self.list_view:setTouchEnabled(touch_flag)
end

function mining_cave_event_panel:UpdateListView(open_flag)
    local cave_type = self.current_cave_type
    self:ClearListView()
    --load
    self.event_config = {}
    for _, v in ipairs(config_manager.mining_event_config[cave_type]) do 
        table.insert(self.event_config, v)
    end

    self.cell_panels = {}
    self.show_cells = 0
    local finish_level = mining_logic.cave_levels[cave_type]
    for k,v in ipairs(self.event_config) do 
        self:UpdateCells(open_flag,false)
        if not open_flag then 
            break
        else
            if k > finish_level then 
                break
            end
        end
    end

    self:AddMarginNode()
    self.list_view:refreshView()
    self.list_view:jumpToTop()
end 

function mining_cave_event_panel:AddMarginNode()
    local margin_node = ccui.Widget:create()
    local size = self.list_view_cell:getContentSize()
    size.height = size.height / 2
    margin_node:setContentSize(size)
    self.list_view:addChild(margin_node)
end

function mining_cave_event_panel:OpenPanelCell(index)
    if self.cell_panels[index] then 
       self.cell_panels[index]:SetOpenStatus(true)
    end
end

function mining_cave_event_panel:UpdateCells(open_flag, remove_last_flag)
    local event_data = self.event_config[self.show_cells + 1]
    if not event_data then 
        return
    end
    
    if remove_last_flag then 
        self:HandleLastItem()
    end
    local cave_type = self.current_cave_type
    local finish_level = mining_logic.cave_levels[cave_type]
   
    self.show_cells = self.show_cells + 1

    local cell_panel = cave_event_list_cell_panel.New()
    cell_panel:Init(self.list_view_cell:clone(), self.show_cells, event_data)
    self.cell_panels[self.show_cells] = cell_panel
    cell_panel:Show()
    --self.list_view:insertCustomItem(cell_panel.root_node,self.show_cells)
    self.list_view:addChild(cell_panel.root_node, self.show_cells + 1)

    
    if not open_flag then 
       self.cell_panels[self.show_cells]:SetOpenStatus(false)
    else
        if self.show_cells <= finish_level then 
            self.cell_panels[self.show_cells]:SetOpenStatus(true)
        else
            self.cell_panels[self.show_cells]:SetOpenStatus(false)
        end
    end
    self.list_view_items = #self.cell_panels
    
    if remove_last_flag then 
        self:AddMarginNode()
    end

    self:UpdateScrollViewScrollStatus()
end

function mining_cave_event_panel:HandleLastItem()
    if self.show_cells > 0 then 
       self.list_view:removeLastItem()
    end
end 

function mining_cave_event_panel:Hide()
   self.root_node:setVisible(false)
end

function mining_cave_event_panel:ConvertEventOpenText(cave_type)
    local text
    local text_sign = lang_constants:Get("week_day_sign")
    
    if #mining_logic.cave_event_open_day_data[cave_type] == 7 then
        text = lang_constants:Get("week_day_each")
    else
        --r2要把星期一放在第一个位置星期天放最后
        local sun_day_name = ""
        local change_monday = platform_manager:GetChannelInfo().mining_cave_event_panel_convert_event_open_change
        for k,v in ipairs(mining_logic.cave_event_open_day_data[cave_type]) do 

            local day_name = lang_constants:Get("week_day" .. tostring(v))
            --这里2是星期一
            if change_monday then
                if v == 1 then
                    sun_day_name = day_name
                else
                    if text == nil then 
                        text = day_name
                    else
                        text = text .. text_sign .. day_name
                    end
                end            
            else
                if k == 1 then 
                    text = day_name
                else
                    text = text .. text_sign .. day_name
                end
            end
        end
    
        if sun_day_name ~= "" then
            text = text .. text_sign .. sun_day_name
        end
    end

    return text
end

function mining_cave_event_panel:ShowMissionDescTip(widget,show_flag)
    local arrow_pos_x = CAVE_DESC_ARROW_POSITION_X[self.mission_mode][widget.position_index]

    local mission_node = self:GetMissionNode(widget.mission_index)
    local cave_type = mission_node.cave_type
    local point_text = lang_constants:Get("mining_cave_event_point")
    local name_text, desc_text, open_time_text

    if show_flag then 
       self.mission_desc_name_text:setString(lang_constants:Get("mining_cave_event_type_name" .. tostring(cave_type)) .. point_text)
       self.mission_desc_text:setString(lang_constants:Get("mining_cave_event_type_desc" .. tostring(cave_type)))
       open_time_text = self:ConvertEventOpenText(cave_type)
       if open_time_text then 
          self.mission_desc_time_text:setString(open_time_text)
       end
       self.mission_desc_arrow_img:setPositionX(arrow_pos_x)
    end
    self.mission_desc_node:setVisible(show_flag)
end

function mining_cave_event_panel:RegisterEvent()

    graphic:RegisterEvent("cave_event_update", function(cave_type,refresh_flag)
        if not self.root_node:isVisible() then
            return
        end

        self.bottom_boss_counts_text:setString(panel_util:ConvertUnit(resource_logic:GetResourcenNumByName("demon_medal")))

        if self.current_cave_type ~= cave_type then 
            return 
        end

        self:SetEventCounts(true)
        
        if refresh_flag then 
           self:OpenPanelCell(self.show_cells)
           self:UpdateCells(true, true)
        end
    end)
end

function mining_cave_event_panel:RegisterWidgetEvent()

    local TouchMissionStageListener = function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
           audio_manager:PlayEffect("click")
           self.touch_start_location = widget:getTouchBeganPosition()

        elseif event_type == ccui.TouchEventType.ended then
            local mission_index = widget.mission_index
            self:UpdateMissionTabIndex(mission_index)
            --self:ShowMissionDescTip(widget,true)
        end
    end

    for i = 1, #ETHER_CAVE_TYPE do
        self.ether_sub_panels[i]:SetTouchEnabled(true)
        self.ether_sub_panels[i]:AddTouchEventListener(TouchMissionStageListener)
    end

    for i = 1, #MONSTER_CAVE_TYPE do 
        self.monster_sub_panels[i]:SetTouchEnabled(true)
        self.monster_sub_panels[i]:AddTouchEventListener(TouchMissionStageListener)
    end

    self.bottom_times_add_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            if mining_logic.cave_buy_challenge_nums[self.current_cave_type] <= 0 then
               graphic:DispatchEvent("show_prompt_panel", "mining_not_enough_buy_challenge", true)
               return 
            end 
            local mode = client_constants["CONFIRM_MSGBOX_MODE"]["buy_cave_challenge"]
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.current_cave_type)
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return mining_cave_event_panel
