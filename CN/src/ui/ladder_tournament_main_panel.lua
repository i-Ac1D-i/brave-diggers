local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local ladder_tower_logic = require "logic.ladder_tower"
local troop_logic = require "logic.troop"
local icon_panel = require "ui.icon_panel"
local lang_constants = require "util.language_constants"
local maze_role_prototype = require "entity.ui_role"
local animation_manager = require "util.animation_manager"
local title_panel = require "ui.title_panel"
local feature_config = require "logic.feature_config"
local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local TIME_INDEX = {0.1,0.2,0.3}
local PANEL_STATE = 0   --因为刷新敌人要执行动画，所以要一个当前panel的状态
--
local player_target_panel = panel_prototype.New()
player_target_panel.__index = player_target_panel

function player_target_panel.New()
    return setmetatable({}, player_target_panel)
end

function player_target_panel:Init(root_node)
    self.root_node = root_node
    --头像
    self.head_icon_img = self.root_node:getChildByName("hero")
    self.head_icon_img:setVisible(false)
    self.role_shadow = self.root_node:getChildByName("role_shadow")
    self.name_text = self.root_node:getChildByName("name")

    self.attack_text = self.root_node:getChildByName("attack")

    --等级图标
    self.level_img = self.root_node:getChildByName("bg_0")

    self.role_sprite = cc.Sprite:create()
    self.role_sprite:setAnchorPoint(0.5, 0)

    self.role_sprite:setPosition(self.role_shadow:getPosition())
    self.role_sprite:setScale(2)
    self.root_node:addChild(self.role_sprite, 100)

    self.role = maze_role_prototype.New()

    self.animation_node = cc.CSLoader:createNode("ui/node_mine_change.csb")
    self.animation_node:setScale(2)
    self.root_node:addChild(self.animation_node, 100)
    self.animation_node:setPosition(self.role_shadow:getPosition())

    self.time_line_action = animation_manager:GetTimeLine("mine_rob_enter_timeline")
    self.animation_node:runAction(self.time_line_action)

    self.old_animation_img = self.animation_node:getChildByName("mine_icon_1")
    self.now_animation_img = self.animation_node:getChildByName("mine_icon_2")

    --刷新动画监听
    local event_frame_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "mine_icon_end" then
            if self.delay_time == TIME_INDEX[#TIME_INDEX] then
                PANEL_STATE = 0
            end

            self.conf = config_manager.mercenary_config[self.template_id]
            self.role:Init(self.role_sprite, self.conf.sprite)
            self.role:WalkAnimation(1)
            self.role:SetScale(2.5,2.5)
            self.animation_node:setVisible(false)
        end
    end
    self.time_line_action:clearFrameEventCallFunc()
    self.time_line_action:setFrameEventCallFunc(event_frame_call_function)

    if feature_config:IsFeatureOpen("title") then
        self.title_icon = self.root_node:getChildByName("title_icon")
        self.title = title_panel.New()
        self.title:Init(self.title_icon)
        self.title:Hide()
    else
        self.title_icon = self.root_node:getChildByName("title_icon")
        if self.title_icon then
            self.title_icon:setVisible(false) 
        end
    end

    self:RegisterWidgetEvent()
end

function player_target_panel:Show(info_conf, delay_time)
    self.root_node:setVisible(true)

    if info_conf then
        self.info_conf = info_conf
        self.name_text:setString(info_conf.leader_name)
        self.attack_text:setString(info_conf.battle_point)
        self.delay_time = delay_time
        if self.delay_time  then
            self.root_node:stopAllActions()
            self.root_node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), 
                                    cc.CallFunc:create(function()
                                        self.animation_node:setVisible(true)
                                        self.now_animation_img:setVisible(true)
                                        self.role_sprite:setVisible(false)
                                        self:PlayAnimation()
                                        self.template_id = info_conf.template_id_list[1]
                                        end)))
            
        else
            self.animation_node:setVisible(false)
            --动画
            self.template_id = info_conf.template_id_list[1]
            self.conf = config_manager.mercenary_config[self.template_id]
            self.role:Init(self.role_sprite, self.conf.sprite)
            self.role:WalkAnimation(1)
            self.role:SetScale(2.5,2.5)
        end

        self.level_img:loadTexture(client_constants["LADDER_LEVEL_S_IMG_TYPE"][info_conf.cur_group], PLIST_TYPE)
    end
    if feature_config:IsFeatureOpen("title") then
        if info_conf.title_id and info_conf.title_id ~= 0 then
            self.title:Show()
            self.title:Load(info_conf.title_id)
        else
            self.title:Hide() 
        end
    end
end

function player_target_panel:PlayAnimation()

    local conf1 = config_manager.mercenary_config[self.template_id]
    local icon1 = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf1.sprite .. ".png"

    local conf2 = config_manager.mercenary_config[self.info_conf.template_id_list[1]]
    local icon2 = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf2.sprite .. ".png"

    self.now_animation_img:loadTexture(icon2, PLIST_TYPE)
    self.old_animation_img:loadTexture(icon1, PLIST_TYPE)
    self.time_line_action:gotoFrameAndPlay(0, 60, false)

    self.animation_node:setVisible(true)
end

function player_target_panel:RegisterWidgetEvent()
    --按钮点击监听
    self.root_node:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local SOCIAL_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]["ladder_tower_member"]
            graphic:DispatchEvent("show_world_sub_panel", "social_event_panel", self.info_conf.enemy_id, SOCIAL_SHOW_TYPE)
        end
    end)
end

local ladder_tournament_main_panel = panel_prototype.New(true)
function ladder_tournament_main_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/ladder_tournament_main_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")

    --规则按钮
    self.rule_btn = self.root_node:getChildByName("view_info_btn")
    --排行榜按钮
    self.rank_btn = self.root_node:getChildByName("report_btn")
    --阵容
    self.formation_btn = self.root_node:getChildByName("arrange_mercenary_pos_btn")
    --刷新按钮
    self.refresh_btn = self.root_node:getChildByName("ext_exchange_btn")

    --
    local level_node = self.root_node:getChildByName("Node_15")
    self.level_percent_bar = level_node:getChildByName("percent_bar_skill")
    self.level_text = level_node:getChildByName("percent_value_skill")
    panel_util:SetTextOutline(self.level_text)

    self.level_img = self.root_node:getChildByName("Image_94")
    self.next_level_img = self.root_node:getChildByName("Image_94_0")

    self.level_name_text = self.root_node:getChildByName("name_0")
    
    --赛季时间
    self.time_text = self.root_node:getChildByName("title_0")

    self.player_templent = self.root_node:getChildByName("Button_mine")
    self.player_templent:setPosition(cc.p(0,0))
    self.player_templent:setVisible(false)

    local bottom_bar = self.root_node:getChildByName("bottom_bar")
     --增加战斗次数按钮
    self.add_fighting_count_btn = bottom_bar:getChildByName("times_buy_btn_0")
    self.add_fighting_count_desc = bottom_bar:getChildByName("times_desc_0")
    self.add_fighting_count_label = bottom_bar:getChildByName("times_number_0")
    --增加刷新次数
    self.add_refresh_count_btn = bottom_bar:getChildByName("times_buy_btn")
    self.add_refresh_count_desc = bottom_bar:getChildByName("times_desc")
    self.add_refresh_count_label = bottom_bar:getChildByName("times_number")

    --绿点隐藏
    local remind_icon = self.root_node:getChildByName("remind_icon")
    if remind_icon then
        remind_icon:setVisible(false)
    end

    --玩家节点
    self.temp_node_list = {}
    self.node1 = self.root_node:getChildByName("Node_2")
    self.temp_node_list[1] = self.node1
    self.node2 = self.root_node:getChildByName("Node_4")
    self.temp_node_list[2] = self.node2
    self.node3 = self.root_node:getChildByName("Node_5")
    self.temp_node_list[3] = self.node3

    self.player_templent_list = {}

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function ladder_tournament_main_panel:Show()
    self:InitPlayer()
    self:SetTimeText()
    self:InitLevelInfo()
    
    PANEL_STATE = 0

    --显示公告
    self:ShowNotice()

    self.add_fighting_count_desc:setString(lang_constants:Get("fighting_btn_text"))
    self.add_refresh_count_desc:setString(lang_constants:Get("search_btn_text"))

    local time_str = ""
    local start_data = time_logic:GetDateInfo(ladder_tower_logic.countdown)
    local end_data = time_logic:GetDateInfo(ladder_tower_logic.duration)
    if start_data and end_data then
        time_str = string.format(lang_constants:Get("ladder_time_format"), start_data.month, start_data.day, start_data.hour, end_data.month, end_data.day, end_data.hour)
    end

    self.time_text:setString(lang_constants:Get("ladder_time_text_desc")..time_str)

    self.root_node:setVisible(true)
end

function ladder_tournament_main_panel:ShowNotice()
    graphic:DispatchEvent("show_world_sub_panel", "ladder_tournament_report_msgbox")
end

function ladder_tournament_main_panel:InitLevelInfo()
    if ladder_tower_logic:GetNowNeedAllSocre() == 0 then
        --这里是达到最大等级值了
        self.level_text:setString(ladder_tower_logic.integral_num)
        self.level_percent_bar:setPercent(100)
        self.next_level_img:setVisible(false)
    else
        --下一级图标
        self.next_level_img:setVisible(true)
        self.next_level_img:loadTexture(client_constants["LADDER_LEVEL_S_IMG_TYPE"][ladder_tower_logic.ladder_level + 1], PLIST_TYPE)

        self.level_text:setString(ladder_tower_logic.integral_num.."/"..ladder_tower_logic:GetNowNeedAllSocre())
        self.level_percent_bar:setPercent(ladder_tower_logic.integral_num / ladder_tower_logic:GetNowNeedAllSocre() * 100)
    end
    --当前等级图标
    self.level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][ladder_tower_logic.ladder_level], PLIST_TYPE)
    --当前等级文字
    self.level_name_text:setString(lang_constants:Get("ladder_level_"..ladder_tower_logic.ladder_level))
end

function ladder_tournament_main_panel:SetTimeText()
    self.add_fighting_count_label:setString(ladder_tower_logic.figthing_count)
    self.add_refresh_count_label:setString(ladder_tower_logic.search_count)
end

function ladder_tournament_main_panel:InitPlayer(show_animation)
    local player_list = ladder_tower_logic:GetPlayers()
    
    local indexs = {}
    if show_animation then
        --复制时间间隔列表
        for k,v in pairs(TIME_INDEX) do
            indexs[k] = v
        end
    end

    if player_list then
        for k,player_info in pairs(player_list) do
            if self.player_templent_list[k] == nil then
                self.player_templent_list[k] = player_target_panel.New()
                local temp_node = self.player_templent:clone()
                self.temp_node_list[k]:addChild(temp_node)
                self.player_templent_list[k]:Init(temp_node)
            end
            local delay_time = nil
            if show_animation then
                local select_ind = math.floor(math.random(1,#indexs))
                delay_time = indexs[select_ind]
                table.remove(indexs,select_ind)
            end
            self.player_templent_list[k]:Show(player_info, delay_time)
        end
    end
end

function ladder_tournament_main_panel:RegisterEvent()
    --
    graphic:RegisterEvent("ladder_refresh_success", function()
        if not self.root_node:isVisible() then
            return
        end
        PANEL_STATE = 1
        self:InitPlayer(true)
        self:SetTimeText()
    end)

    graphic:RegisterEvent("ladder_buy_times_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:SetTimeText()
    end)

    graphic:RegisterEvent("ladder_fighting_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:InitPlayer()
        self:SetTimeText()
        self:InitLevelInfo()
    end)
    
end

function ladder_tournament_main_panel:RegisterWidgetEvent()
	--关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --规则按钮
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "ladder_tournament_rule_msgbox")
        end
    end)

    --排行
    self.rank_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            ladder_tower_logic:QueryRank()
            graphic:DispatchEvent("show_world_sub_panel", "ladder_tournament_ranklist_panel")
        end
    end)

    --阵容
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
             if not troop_logic:CheckMercenaryLimiteOverTime() then
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["multi"], self:GetName(), {self.index})
            end
        end
    end)

    --购买刷新次数
    self.add_refresh_count_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["BATCH_MSGBOX_MODE"]["ladder_tower_buy_refresh_times"]
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
        end
    end)

    --购买战斗次数
    self.add_fighting_count_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["BATCH_MSGBOX_MODE"]["ladder_tower_fighting_times"]
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
        end
    end)

    --刷新敌人按钮
    self.refresh_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if ladder_tower_logic.search_count <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "top_search_times")
                local mode = client_constants["BATCH_MSGBOX_MODE"]["ladder_tower_buy_refresh_times"]
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
            else
                if PANEL_STATE == 0 then
                    ladder_tower_logic:RefreshPlayer()
                end
            end
            
        end
    end)
end

return ladder_tournament_main_panel

