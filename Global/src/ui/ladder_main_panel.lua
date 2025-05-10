local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local troop_logic = require "logic.troop"
local arena_logic = require "logic.arena"

local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"

local MAX_RIVAL_NUM = 10
local MAX_CHALLEDGE_CD = 5 * 60

--对手信息的子panel
local rival_info_sub_panel = panel_prototype.New()
rival_info_sub_panel.__index = rival_info_sub_panel

function rival_info_sub_panel.New()
    local t = {}
    return setmetatable(t, rival_info_sub_panel)
end

function rival_info_sub_panel:Init(root_node)
    self.is_rival = is_rival
    self.root_node = root_node

    self.rank_num_text = root_node:getChildByName("rank_value")

    self.bp_text = root_node:getChildByName("bp_value")

    self.name_text = root_node:getChildByName("name")
    self.challenge_btn = root_node:getChildByName("challenge_btn")
    self.challenge_num_text = root_node:getChildByName("challenge_num")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node)
end

function rival_info_sub_panel:ReLoadInfo(pos)
    local rival_info = ladder_logic:GetSingleRivalInfo(pos)

    --  多语言名字
    local loacle = platform_manager:GetLocale()
    if rival_info["leader_name_"..loacle] then
        self.name_text:setString(rival_info["leader_name_"..loacle])
    else
        self.name_text:setString(rival_info.leader_name)
    end
    
    self.rank_num_text:setString(rival_info.rank)
    self.bp_text:setString(rival_info.battle_point)

    local template_id = rival_info.template_id
    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, false)
    self.icon_panel:SetPosition(60, 60)
end

local ladder_main_panel = panel_prototype.New()
function ladder_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/ladder_main_panel.csb")
    local root_node = self.root_node

    --reward
    local reward_bg_img = root_node:getChildByName("reward_bg")
    self.reward_num_text = reward_bg_img:getChildByName("num")

    --top
    local top_node = root_node:getChildByName("top")

    self.rank_num_text = top_node:getChildByName("rank_value")
    self.challenge_num_text = top_node:getChildByName("challenge_num")
    self.challenge_cd_text = top_node:getChildByName("cd")

    --rival
    self.list_view = root_node:getChildByName("list_view")
    local rival_template = root_node:getChildByName("template")

    self.rival_items = {}
    for i = 1, MAX_RIVAL_NUM do
        local rival_sub_panel = rival_info_sub_panel.New()
        rival_sub_panel:Init(rival_template:clone(), true)
        rival_sub_panel.challenge_btn:setTag(i)

        rival_sub_panel:Show()
        self.list_view:addChild(rival_sub_panel.root_node)
        self.rival_items[i] = rival_sub_panel
    end

    local margin_node = ccui.Widget:create()
    local size = rival_template:getContentSize()
    size.height = size.height / 2
    margin_node:setContentSize(size)
    self.list_view:addChild(margin_node)

    self.list_view:refreshView()
    rival_template:setVisible(false)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function ladder_main_panel:Show()
    self:ReLoadInfo()
    self.list_view:getInnerContainer():setPosition(0, 0)
    self.root_node:setVisible(true)
end

function ladder_main_panel:ReLoadInfo()

    self.duration = time_logic:GetDurationToFixedTime(ladder_logic.challenge_cd)
    self.rank_num_text:setString(ladder_logic.cur_rank)
    self.challenge_num_text:setString(ladder_logic.challenge_num)

    for i = 1, MAX_RIVAL_NUM do
        self.rival_items[i]:ReLoadInfo(i)
    end

    local cur_rank_reward_num = 0
    local cur_rank = ladder_logic.cur_rank

    local reward_rank = constants.LADDER_REWARD_RANK

    for i = 1, #reward_rank do
        if cur_rank >= reward_rank[i] then
            cur_rank_reward_num = constants.LADDER_REWARD[reward_rank[i]]
        else
            break
        end
    end

    self.reward_num_text:setString(cur_rank_reward_num)
end

function ladder_main_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time
    if self.duration > 0 then
        self.challenge_cd_text:setString(panel_util:GetTimeStr(self.duration, true))
    else
        self.challenge_cd_text:setString("0:00")
    end
end

function ladder_main_panel:RegisterEvent()
    --挑战
    graphic:RegisterEvent("ladder_update_rival", function(is_winner)
        if not self.root_node:isVisible() then
            return
        end

        self:ReLoadInfo()
    end)
end


function ladder_main_panel:RegisterWidgetEvent()

    --返回
    self.root_node:getChildByName("back_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "pvp_sub_scene")
        end
    end)

    --查看排名赛奖品规则
    self.root_node:getChildByName("look_rule_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "ladder_rule_msgbox")
        end
    end)

    --查看大陆前十名玩家信息
    self.root_node:getChildByName("top_ten_rank_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            ladder_logic:TopTenQuery()
        end
    end)

    --兑换奖励
    self.root_node:getChildByName("exchange_reward_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            arena_logic:QueryExchangeConfig()

            --graphic:DispatchEvent("show_world_sub_panel", "exchange_reward_msgbox")
        end
    end)

    --阵容
    self.root_node:getChildByName("formation_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local trans_type = constants["SCENE_TRANSITION_TYPE"]["none"]
            local mode = client_constants["FORMATION_PANEL_MODE"]["multi"]
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, true, mode)
        end
    end)

    --挑战
    local challenge_rival = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local tag = widget:getTag()
            ladder_logic:ChallengeRival(tag)
        end
    end

    for i = 1, MAX_RIVAL_NUM do
        local challenge_btn = self.rival_items[i].challenge_btn
        if challenge_btn then
            challenge_btn:addTouchEventListener(challenge_rival)
        end
    end
end

return ladder_main_panel
