local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"
local utils = require "util.utils"
local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local time_logic = require "logic.time"

local OFFSET_X = 10

local maze_sub_panel = panel_prototype.New()
maze_sub_panel.__index = maze_sub_panel

function maze_sub_panel.New()
    return setmetatable({}, maze_sub_panel)
end

function maze_sub_panel:Init(root_node)
    self.root_node = root_node

    self.save_mercenary_text =self.root_node:getChildByName("mercenary__value") 
    self.name = self.root_node:getChildByName("mission_name")
    self.id_text = self.root_node:getChildByName("mission_number")
    self.battle_num_text = self.root_node:getChildByName("mercenary_members")
    self.play_back_btn = self.root_node:getChildByName("replay_btn")
    local buff_icon = self.root_node:getChildByName("buff_icon")

    if buff_icon then
        buff_icon:setVisible(false)
    end
    self:addTouchEventListener()
end

function maze_sub_panel:Show(conf)
    self.root_node:setVisible(true)

    self.id_text:setString(conf.map_id)
    self.name:setString(conf.name)
    local exp_num = troop_logic.vanity_exp_get_mercenary_list[conf.map_id] or 0
    self.save_mercenary_text:setString(exp_num)

    local battle_num = troop_logic.vanity_maze_battle_number_list[conf.map_id] or 0

    self.battle_num_text:setString(battle_num)

    self.maze_id = conf.map_id
    if self.maze_id == 1 then
        self.play_back_btn:setVisible(false)
    end
end

function maze_sub_panel:addTouchEventListener()
    self.play_back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.maze_id and self.maze_id ~= 0 then
                troop_logic:VanityBattlePlayBack(self.maze_id)
            end
        end
    end)
end

local vanity_adventure_result = panel_prototype.New(true)

function vanity_adventure_result:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_result.csb")
    self.score_view = self.root_node:getChildByName("scrollview")
    self.template_node = cc.Node:create()
    self.score_view:addChild(self.template_node)
    self.template = self.score_view:getChildByName("template")
    self.template:setVisible(false)

    local extra_node = self.root_node:getChildByName("shadow_result")
    self.have_merenary_number_text = extra_node:getChildByName("name5_1")
    self.have_extra_score_text = extra_node:getChildByName("name5_1_0")
    self.have_extra_score_text:setString(0)

    local no_enemy_txt = self.score_view:getChildByName("no_enemy_txt")
    if no_enemy_txt then
        no_enemy_txt:setVisible(false)
    end

    self.temp_height = self.template:getContentSize().height
    self.maze_sub_panels = {}
    self:RegisterWidgetEvent()
end

--获得通关所获得佣兵提示面板
function vanity_adventure_result:Show(maze_id)
    --要领取关卡的id
    self.root_node:setVisible(true)
    self:LoadScoreView()
end

function vanity_adventure_result:LoadScoreView()
    local num = 0
    --得到当前关卡配置信息
    local week = utils:getWDay(time_logic:Now())
    local vanity_maze_conf = config_manager.vanity_maze_config[week]
    local mercenary_integral = 0
    for k,v in pairs(vanity_maze_conf) do
        mercenary_integral = v.mercenary_integral or mercenary_integral
        local maze_state = constants["VANITY_MAZE_STATE"].unlock
        for k1,v1 in pairs(troop_logic:GetVanityMazeList()) do
            if k1 == v.map_id then
                maze_state = v1
                break
            end
        end

        if self.maze_sub_panels[v.map_id] == nil then
            self.maze_sub_panels[v.map_id] = maze_sub_panel.New()
            local temp = self.template:clone()
            self.template_node:addChild(temp)
            temp:setPosition(cc.p(OFFSET_X,- (v.map_id - 0.5) * temp:getContentSize().height))
            self.maze_sub_panels[v.map_id]:Init(temp)
        end

        if maze_state == constants["VANITY_MAZE_STATE"].challenge_success or maze_state == constants["VANITY_MAZE_STATE"].maze_finish then
            num = num + 1
            self.maze_sub_panels[v.map_id]:Show(v)
        else
            self.maze_sub_panels[v.map_id]:Hide()
        end
    end

    local heigh_height = math.max(self.score_view:getContentSize().height, self.temp_height * num)

    self.score_view:setInnerContainerSize(cc.size(self.score_view:getContentSize().width, heigh_height))

    self.template_node:setPositionY(heigh_height)

    local can_use_num = troop_logic:GetVanityCanUseNumber()
    self.have_merenary_number_text:setString(can_use_num)
    self.have_extra_score_text:setString(mercenary_integral * can_use_num)
    
end

function vanity_adventure_result:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return vanity_adventure_result