local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType
local ENTERFOR_STATUS ={
    ["UNENTER"] = 1,
    ["ENTERED"] = 2,
}

local CLIENT_GUILDWAR_STATUS = client_constants["CLIENT_GUILDWAR_STATUS"]

local CUP_START_X = 138
local CUP_ADD_X = 36 
local CUP_Y = 139
local FPS_SEC = 1/60
local ALL_CUPS = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false,
        [6] = false,
        [7] = false,
        [8] = false
}

local enlist_panel = panel_prototype.New(true)
function enlist_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_enlist_panel.csb")
    self.title_text = self.root_node:getChildByName("title")

    self.tier_text = self.root_node:getChildByName("dan_number")
    panel_util:SetTextOutline(self.tier_text, 0x000, 2)

    self.score_num_text = self.root_node:getChildByName("points_number")

    self.enter_for_btn = self.root_node:getChildByName("sign_up_btn")
    self.un_enter_for_btn = self.root_node:getChildByName("unsign_up_btn")
    
    self.cup_root = self.root_node:getChildByName("battle_info")

    self.battle_info_text = self.cup_root:getChildByName("title")

    self.enterfor_cup = self.cup_root:getChildByName("cup_in_icon")
    self.enterfor_cup:setVisible(false)
    self.miss_cup = self.cup_root:getChildByName("cup_out_icon")
    self.miss_cup:setVisible(false)
    self.prompt_cup = self.cup_root:getChildByName("cup_prompt_icon")
    self.prompt_cup:setVisible(false)
    self.prompt_cup:setOpacity(127)
    self.prompt_cup_animation = false
    self.prompt_cup_play_time = 0

    self.cups = {}

    self.enter_for_btn:setVisible(false)
    self.un_enter_for_btn:setVisible(false)

    self.rule_btn = self.root_node:getChildByName("rule_icon")
    self.close_btn = self.root_node:getChildByName("close_btn")
    
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function enlist_panel:ShowCup()
    for k, v in ipairs(self.cups) do 
        v:removeFromParent()
    end
    
    self.prompt_cup:setVisible(false)
    self.cups = {}
    local current_round = guild_logic:GetCurrentRound()
    local season_info = guild_logic:GetSeasonInfo()

    for k, v in ipairs(season_info) do 
        ALL_CUPS[v] = true 
    end
    
    for i = 1, current_round do 
        local cup_img = nil
        if i ~= current_round or guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["NONE"] then 
            if ALL_CUPS[i] then 
                cup_img = self.enterfor_cup:clone()
            else
                cup_img = self.miss_cup:clone()
            end
        end
        if cup_img then 
            cup_img:setPosition(cc.p(CUP_START_X + (i - 1) * CUP_ADD_X, CUP_Y))
            cup_img:setVisible(true)
            self.cup_root:addChild(cup_img)
            table.insert(self.cups, cup_img)
        end

        if i == current_round and guild_logic:GetCurStatus() ~= CLIENT_GUILDWAR_STATUS["NONE"] then 
            self.prompt_cup:setPosition(cc.p(CUP_START_X + (current_round - 1) * CUP_ADD_X, CUP_Y))
            self.prompt_cup:setLocalZOrder(2)
            self.prompt_cup:setVisible(true)
            self.prompt_cup_animation = true
        end
    end
end

function enlist_panel:Show()
    self.prompt_cup_animation = false
    self.score_num_text:setString(tostring(guild_logic:GetScore()))
    self.tier_text:setString(tostring(guild_logic:GetGuildTier(guild_logic:GetScore())))
    self:ShowCup()
    self:UpdateEnterForStatus()
    self.root_node:setVisible(true)
end

function enlist_panel:PlayCupPromptAnimation(elapsed_time)
    if self.prompt_cup_animation then 
        self.prompt_cup_play_time = self.prompt_cup_play_time + elapsed_time
        if self.prompt_cup_play_time >= 48 * FPS_SEC then 
            self.prompt_cup:setScale(1.0)
            self.prompt_cup_play_time = 0
        elseif self.prompt_cup_play_time >= 40 * FPS_SEC then 
            self.prompt_cup:setScale(1.1)
        elseif self.prompt_cup_play_time >= 32 * FPS_SEC then
            self.prompt_cup:setScale(1.2)
        elseif self.prompt_cup_play_time >= 24 * FPS_SEC then
            self.prompt_cup:setScale(1.3)
        elseif self.prompt_cup_play_time >= 16 * FPS_SEC then
            self.prompt_cup:setScale(1.2)
        elseif self.prompt_cup_play_time >= 8 * FPS_SEC then
            self.prompt_cup:setScale(1.1)
        end
    end
end

function enlist_panel:Update(elapsed_time)
    self:PlayCupPromptAnimation(elapsed_time)
end

function enlist_panel:Hide()
    self.prompt_cup_animation = false
    self.root_node:setVisible(false)
end

function enlist_panel:UpdateEnterForStatus()
    self.enter_for_btn:setVisible(false)
    self.un_enter_for_btn:setVisible(false)
    if guild_logic:IsEnterForCurrentWar() then 
        self.title_text:setString(lang_constants:Get("guild_war_enterfor_title2"))
        self.battle_info_text:setString(lang_constants:Get("guild_war_enterfor_sub_title1"))
        self.enter_for_btn:setTitleText(lang_constants:Get("guild_war_enterfor_tip2"))
        self.enter_for_btn:setTag(ENTERFOR_STATUS["ENTERED"])
        self.enter_for_btn:setVisible(true)
    else
        if guild_logic:IsGuildChairman() or guild_logic:IsGuildManager() then 
            self.enter_for_btn:setTitleText(lang_constants:Get("guild_war_enterfor_tip1"))
            self.enter_for_btn:setTag(ENTERFOR_STATUS["UNENTER"])
            self.enter_for_btn:setVisible(true)
        else
            self.un_enter_for_btn:setVisible(true)
        end
        -- local next_war_data = guild_logic:GetNextRoundData()
        -- if not next_war_data then 
        --     self.battle_info_text:setString(lang_constants:Get("guild_war_enterfor_sub_title3"))
        -- else
        --     local t_date = panel_util:GetDateByUtf(next_war_data.enterfor_begin_time)
        --     self.battle_info_text:setString(lang_constants:GetFormattedStr("guild_war_enterfor_sub_title2", tostring(t_date.month), tostring(t_date.day), tostring(t_date.hour)))
        -- end

        self.title_text:setString(lang_constants:Get("guild_war_enterfor_title1"))
    end
end

function enlist_panel:RegisterEvent()

    graphic:RegisterEvent("guildwar_enlist_refresh", function()
        if not self.root_node:isVisible() then
            return
        end
        self:Show()
    end)
end


function enlist_panel:RegisterWidgetEvent()
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.rank_rule_msgbox") 
        end
    end)

    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.enter_for_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local status = widget:getTag()
            if status == ENTERFOR_STATUS["ENTERED"] then 
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                graphic:DispatchEvent("show_world_sub_scene", "guildwar_sub_scene")

            elseif status == ENTERFOR_STATUS["UNENTER"] then
                guild_logic:EnterForGuildWar()
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
        end
    end)

    self.un_enter_for_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            graphic:DispatchEvent("show_world_sub_scene", "guildwar_sub_scene")
            graphic:DispatchEvent("show_prompt_panel", "guild_enterfor_no_permission")
        end
    end)
end

return enlist_panel

