local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local icon_panel = require "ui.icon_panel"

local item_config = config_manager.item_config
local resource_config = config_manager.resource_config

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_util = require "ui.panel_util"
local mine_logic = require "logic.mine"

local SMALL_QUALITY_BG = client_constants["SMALL_QUALITY_BG"]
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local REWARD_TYPE = constants["REWARD_TYPE"]
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local BG_COLOR_MAP = client_constants["BG_QUALITY_COLOR"]

local SELECT_LEVEl = 1

local MAX_LEVEL = 5

local DESC_LOCAL_ZORDER = 99999

local POSITION = {
    {["x"] = 128, ["y"] = 670 },
    {["x"] = 228, ["y"] = 790 },
    {["x"] = 318, ["y"] = 650 },
    {["x"] = 438, ["y"] = 770 },
    {["x"] = 550, ["y"] = 630 },
}
local LIGHT_SCALE = {1.67,1.75,1.84,1.9,2.04}

local need_time_label
--难度panel
local mine_sub_panel = panel_prototype.New()
mine_sub_panel.__index = mine_sub_panel

function mine_sub_panel.New()
    return setmetatable({}, mine_sub_panel)
end

function mine_sub_panel:Init(root_node)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(true)

    self.need_battle_text = self.root_node:getChildByName("Text_3")
    self.level_img = self.root_node:getChildByName("icon")

    self.select_light = self.root_node:getChildByName("light")

    self.lock_tip = self.root_node:getChildByName("lock_tip")
    self.lock_tip:setVisible(false)

    self.scales = {}
    local mine_light1 = self.select_light:getChildByName("mine_light1")
    self.scales[1] = mine_light1:getScale()
    local mine_light2 = self.select_light:getChildByName("mine_light2")
    self.scales[2] = mine_light2:getScale()
    local mine_light3 = self.select_light:getChildByName("mine_light3")
    self.scales[3] = mine_light3:getScale()
    local mine_light4 = self.select_light:getChildByName("mine_light4")
    self.scales[4] = mine_light4:getScale()
    

    root_node:setLocalZOrder(1)
end

function mine_sub_panel:Show(mine_index)
    self.root_node:setVisible(true)
    self.mine_index = mine_index
    local config = mine_logic:GetMineInfoConfig()
    local mine_config = config[self.level]
    
    self.need_battle_text:setString(lang_constants:Get("mine_need_battle_point_desc")..panel_util:ConvertUnit(mine_config.battle_point))
end

function mine_sub_panel:RunLightAnimation()
    local three_delay_time = 1  --这个是第三层和第四层公用一个随机时间
    for i=1, 4 do
        local mine_light = self.select_light:getChildByName("mine_light"..i)
        mine_light:stopAllActions()
        local delay_time = math.random(2,4) --随机一个时间
        if i == 3 then 
            three_delay_time = delay_time
        elseif i == 4 then
            delay_time = three_delay_time
        end
        mine_light:runAction(self:GetAnimation(i, delay_time, 0.1))
    end
end

function mine_sub_panel:GetAnimation(index, delay_time, scale)
    local sequence = cc.Sequence:create(cc.ScaleTo:create(delay_time,self.scales[index]+scale), cc.ScaleTo:create(delay_time,self.scales[index]-0.2))
    local action1 = cc.RepeatForever:create(sequence)
    return action1
end

function mine_sub_panel:ShowState()
    if SELECT_LEVEl == self.level then
        self.root_node:setScale(1.0, 1.0)
        self.select_light:setVisible(true)
        self:RunLightAnimation()
    else
        self.root_node:setScale(0.8, 0.8)
        self.select_light:setVisible(false)
    end
    if mine_logic:BattlePointIsFull(self.mine_index, self.level, false) then
        self.root_node:setColor(panel_util:GetColor4B("0xffffff"))
        self.lock_tip:setVisible(false)
    else
        self.root_node:setColor(panel_util:GetColor4B("0x7f7f7f"))
        self.lock_tip:setVisible(true)
    end
end


function mine_sub_panel:Load(level,x, y)
    self.root_node:setPosition(x, y)
    self.level = level
    self.root_node:setTag(self.level)
    self.select_light:setScale(LIGHT_SCALE[self.level])
    self.level_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][self.level], PLIST_TYPE)

end

local mine_select_msgbox_panel = panel_prototype.New(true)
function mine_select_msgbox_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/mine_select_msgbox.csb")
    
    --免费刷新按钮
    self.free_refresh_btn = self.root_node:getChildByName("confirm_btn_0")
    self.free_refresh_btn_txt1 = self.free_refresh_btn:getChildByName("free")
    self.free_refresh_btn_txt2 = self.free_refresh_btn:getChildByName("go_to_area4_txt")
    self.free_refresh_btn_need_blood_icon = self.free_refresh_btn:getChildByName("Image_252")
    self.need_blood_text = self.free_refresh_btn_need_blood_icon:getChildByName("Text_70")
    panel_util:SetTextOutline(self.need_blood_text)

    --开采阵容按钮
    self.set_formation_btn = self.root_node:getChildByName("confirm_btn_0_0")
    
    --开始开采
    self.start_mine_btn = self.root_node:getChildByName("confirm_btn")

    --预计开采时间label 
    self.need_time_label = self.root_node:getChildByName("Text_3_0")

    --当前描述按钮
    self.info_btn = self.root_node:getChildByName("view_info_btn")
    
    self.desc_info_panel = self.root_node:getChildByName("rule")
    self.desc_info_panel:setLocalZOrder(DESC_LOCAL_ZORDER)

    self.cost_title = self.root_node:getChildByName("cost_title")
    self.reward_bg = self.root_node:getChildByName("cost_bg")

    --等级难度按钮初始化
    local mine_template = self.root_node:getChildByName("maze_template")
    
    self.mine_templates = {}
    self.cost_sub_panels = {}

    self.mine_templates[1] = mine_sub_panel.New()
    self.mine_templates[1]:Init(mine_template)
    
    for i=2,MAX_LEVEL do
        local mine_sub_panel = mine_sub_panel.New()
        local mine_temp = mine_template:clone()
        mine_sub_panel:Init(mine_temp)
        self.root_node:addChild(mine_temp)
        self.mine_templates[i] = mine_sub_panel
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mine_select_msgbox_panel:Show(mine_index)
    self.root_node:setVisible(true)
    self.desc_info_panel:setVisible(false)
    self.mine_index = mine_index or mine_logic:GetCurSelectMineIndex()
    mine_logic:SetCurSelectMineIndex(self.mine_index)

    self.cost_title:setString(lang_constants:Get("mine_get_reward_desc"))

    self:LoadMineSubPanel()
    


    for i=1,MAX_LEVEL do
        self.mine_templates[i]:Show(self.mine_index)
    end
    
    self:LoadMineInfo(1)

    self:SetRefreshBtnState()
end

--免费刷新
function mine_select_msgbox_panel:SetRefreshBtnState()
    if mine_logic.refresh_reward and mine_logic.refresh_reward < constants["MINE_REFRESH_REWARD_FREE_TIMES"] then
        self.free_refresh_btn_txt1:setVisible(true)
        self.free_refresh_btn_txt2:setVisible(false)
        self.free_refresh_btn_need_blood_icon:setVisible(false)
        self.free_refresh_btn_txt1:setString(lang_constants:Get("mine_refresh_free_desc")..(constants["MINE_REFRESH_REWARD_FREE_TIMES"]-mine_logic.refresh_reward).."/"..constants["MINE_REFRESH_REWARD_FREE_TIMES"])
    else
        self.free_refresh_btn_txt1:setVisible(false)
        self.free_refresh_btn_txt2:setVisible(true)
        self.free_refresh_btn_need_blood_icon:setVisible(true)
        self.need_blood_text:setString(constants["MINE_REFRESH_REWARD_COST"])
    end
end

--加载奖励
function mine_select_msgbox_panel:LoadReward()
    local reward_config,reward_num = mine_logic:GetAllRewardsByIndexAndLevel(self.mine_index, SELECT_LEVEl)
    for i = 1, reward_num do
        if self.cost_sub_panels[i] == nil then
            local cost_sub_panel = icon_panel.New()
            cost_sub_panel:Init(self.reward_bg)
            self.cost_sub_panels[i] = cost_sub_panel
        end
    end

    panel_util:LoadCostResourceInfo(reward_config, self.cost_sub_panels, self.reward_bg:getContentSize().height*2/5, reward_num, self.reward_bg:getContentSize().width/2, false) 

end

--加载难度选择按钮
function mine_select_msgbox_panel:LoadMineSubPanel()
    for i=1,MAX_LEVEL do
        self.mine_templates[i]:Load(i, POSITION[i].x, POSITION[i].y)
    end
end

--加载当前选择的难度信息
function mine_select_msgbox_panel:LoadMineInfo(level)
    SELECT_LEVEl = level

    for i=1,MAX_LEVEL do
        self.mine_templates[i]:ShowState()
    end

    self:SetNeedTime(level)
    --加载当前奖励
    self:LoadReward()
end

function mine_select_msgbox_panel:SetNeedTime(level)
    --开采需要时间
    local config = mine_logic:GetMineInfoConfig()
    local mine_config = config[level]
    self.need_time_label:setString(lang_constants:Get("mine_need_time_desc")..panel_util:GetTimeStr(mine_config.full_time * 60))
end

function mine_select_msgbox_panel:Update(elapsed_time)
    
end

function mine_select_msgbox_panel:RegisterEvent()

    --奖励刷新成功
    graphic:RegisterEvent("mine_refresh_rewards_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:LoadReward()
        self:SetRefreshBtnState()
    end)
end

function mine_select_msgbox_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("back_btn"), "mine_select_msgbox_panel")
    
    --免费刷新
    self.free_refresh_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if mine_logic.refresh_reward and mine_logic.refresh_reward < constants["MINE_REFRESH_REWARD_FREE_TIMES"] then
                --直接刷新
                mine_logic:RefreshMineAllRewardList(self.mine_index, SELECT_LEVEl)
            else
                --血钻消耗刷新
                if mine_logic:IsUseBloodTipState() then
                    mine_logic:RefreshMineAllRewardList(self.mine_index, SELECT_LEVEl)
                else
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["mine_refresh_use_blood_tips"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.mine_index, SELECT_LEVEl)
                end 
            end
        end
    end)

    --开采整容
    self.set_formation_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            local back_panel = self:GetName()
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["mine"], back_panel)

        end
    end)

    --开始开采
    self.start_mine_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if mine_logic:CheckFormation(self.mine_index) then
                mine_logic:StartMine(self.mine_index, SELECT_LEVEl)
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            else
                --阵容没有配置
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("mine_formation_is_no_other_mercenary_title"),
                            lang_constants:Get("mine_formation_is_no_other_mercenary_desc"),
                            lang_constants:Get("common_confirm"),
                            lang_constants:Get("common_cancel"),
                function()
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                    local back_panel = self:GetName()
                    graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["mine"], back_panel)

                end)
            end
        end
    end)

    --描述信息按钮
    self.info_btn:addTouchEventListener(function(widiget, event_type)
        if event_type == ccui.TouchEventType.began then
            self.desc_info_panel:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.desc_info_panel:setVisible(false)
        end
    end)

    --难度选择按钮监听
    local select_function = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local index = widget:getTag()
            if index ~= SELECT_LEVEl then
                if mine_logic:BattlePointIsFull(self.mine_index, index, true) then
                    self:LoadMineInfo(index)
                end
            end
        end
    end

    for i = 1, MAX_LEVEL do
        local sub_panel = self.mine_templates[i]
        sub_panel.root_node:addTouchEventListener(select_function)
    end

end

return mine_select_msgbox_panel
