local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local guild_logic = require "logic.guild"
local vip_logic = require "logic.vip"
local chat_logic = require "logic.chat"
local carnival_logic = require "logic.carnival"
local troop_logic = require "logic.troop"

local spine_manager = require "util.spine_manager"
local animation_manager = require "util.animation_manager"
local feature_config = require "logic.feature_config"

local panel_util = require "ui.panel_util"
local JUMP_CONST = client_constants["JUMP_CONST"] 
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local CLIENT_GUILDWAR_STATUS = client_constants["CLIENT_GUILDWAR_STATUS"]

local PLIST_TYPE = ccui.TextureResType.plistType

local math_max = math.max
local main_panel = panel_prototype.New()
function main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guild_panel.csb")
    local root_node = self.root_node

    self.back_btn = root_node:getChildByName("back_btn")
    self.search_btn = root_node:getChildByName("search_btn")
    self.invitation_btn = root_node:getChildByName("invitation_btn")
    self.invitation_tip = self.invitation_btn:getChildByName("num_bg")
    self.invitation_tip_value_txt = self.invitation_btn:getChildByName("num")

    self.guild_desc_text = root_node:getChildByName("guild_desc")

    self.list_btn = root_node:getChildByName("list_btn")

    self.discuss_btn = root_node:getChildByName("discuss_btn")
    self.discuss_tip = root_node:getChildByName("discuss_tip")
    self.discuss_tip_value = self.discuss_tip:getChildByName("value")
    self.found_btn = root_node:getChildByName("found_btn")

    self.guild_id_bg = root_node:getChildByName("guild_id_bg")
    self.guild_id_text = self.guild_id_bg:getChildByName("guild_desc_1")

    self.setting_btn = root_node:getChildByName("setting_btn")
    self.guild_carnival_btn = root_node:getChildByName("guild_carnival_btn")

    self.war_tip_img = root_node:getChildByName("guild_war_bg")
    self.war_tip_img:setVisible(false)

    self.war_desc_text = self.war_tip_img:getChildByName("guild_war_desc")
    self.war_time_text = self.war_tip_img:getChildByName("guild_war_time")

    self.rank_btn = self.root_node:getChildByName("rank_btn")

    self.reward_allot_btn = root_node:getChildByName("reward_allot_btn")

    self.enterfor_war_btn = root_node:getChildByName("enter_war_btn")
    self.team_btn = self.root_node:getChildByName("team_btn")
    self.team_img = self.root_node:getChildByName("adjust_lineup_bg")
    self.team_text = self.root_node:getChildByName("adjust_lineup")

    self.chat_img = self.root_node:getChildByName("chat_bg")
    self.chat_text = self.root_node:getChildByName("chat_txt")

    self.boss_node = cc.CSLoader:createNode("ui/guild_boss_enter.csb")
    self.boss_enter = self.root_node:getChildByName("boss_enter")
    self.boss_enter:addChild(self.boss_node)

    self.time_line_action = animation_manager:GetTimeLine("guild_boss_enter_timeline")
    self.boss_node:runAction(self.time_line_action)
    self.time_line_action:play("animation_stop", false)
        
    self.boss_btn = self.boss_node:getChildByName("boss_btn")
    self.boss_spine_node = self.boss_node:getChildByName("Panel_1"):getChildByName("Node_3")

    self.list_txt_label = self.root_node:getChildByName("list_txt")
    self.list_bg = self.root_node:getChildByName("list_bg")
    self.guild_bg = self.root_node:getChildByName("guild_bg")
    self.guild_txt = self.root_node:getChildByName("guild_txt")

    self.guild_boss_txt = self.root_node:getChildByName("boss_txt")
    self.boss_remind_icon = self.guild_boss_txt:getChildByName("discuss_tip_0")
    self.boss_remind_icon:setVisible(false)
    self.guild_boss_bg = self.root_node:getChildByName("boss_bg")

    self:ShowTeamButton(false)

    self.spine_node = spine_manager:GetNode("box_all", 1.0, true)
    self.spine_node:setPosition(148, 825)
    self.spine_node:setVisible(false)
    self.spine_node:setTimeScale(1.0)
    self.spine_ani_name = ""
    self.root_node:addChild(self.spine_node)

    self.guild_boss_enter_spine_node = spine_manager:GetNode("glass_hole", 1.0, true)
    self.guild_boss_enter_spine_node:setScale(2)
    self.guild_boss_enter_spine_node:setAnimation(0, "glass_hole", true)
    self.guild_boss_enter_spine_node:setTimeScale(0.7)
    self.boss_spine_node:addChild(self.guild_boss_enter_spine_node)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--显示公会功能
function main_panel:ShowGuildBoss(flag)
    local status = guild_logic:IsOpenGuildBoss() and flag
    self.guild_boss_txt:setVisible(status)
    self.boss_remind_icon:setVisible(status)
    self.guild_boss_bg:setVisible(status)
    self.boss_enter:setVisible(status)
end

function main_panel:Update(elapsed_time)
    self:UpdateWarTip(elapsed_time)
end

function main_panel:PlayGuildWarAnimation()
    if feature_config:IsFeatureOpen("guild_war") then
        local spine_ani_name = ""
        
        local cur_status = guild_logic:GetCurStatus()
        if cur_status == CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] then
            if guild_logic:IsEnterForCurrentWar() then
                spine_ani_name = "ani_message_2"
            else
                spine_ani_name = "ani_message_1"
            end
        elseif cur_status == CLIENT_GUILDWAR_STATUS["WAIT_TROOP"] then 
            spine_ani_name = "ani_message_2"
        elseif cur_status == CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then 
            spine_ani_name = "ani_message_3"
        else
            self.spine_node:setVisible(false)
        end 
        
        if self.war_spine_ani_name ~= spine_ani_name and spine_ani_name ~= "" then 
           self.war_spine_ani_name = spine_ani_name
           self.spine_node:setAnimation(0, self.war_spine_ani_name, true)
           self.spine_node:setVisible(true)
        end
    end
end

function main_panel:UpdateWarTip(elapsed_time)
    if feature_config:IsFeatureOpen("guild_war") then
        if self.war_tip_countdown == 0 then 
            local deadline
            self.display_status, deadline = panel_util:GetGuildWarStatus()
            self.war_tip_countdown = math_max(0, deadline - time_logic:Now())
        else
            self.war_tip_countdown = math_max(0, self.war_tip_countdown - elapsed_time)
        end
        if guild_logic:IsGuildMember() then
            self.war_tip_img:setVisible(true)
            
            if not guild_logic:GetCurSeasonConf() then
                self.war_time_text:setVisible(false)
                self.war_desc_text:setString(lang_constants:GetFormattedStr("guild_war_tip_0", ""))
            else
                self.war_time_text:setVisible(true)
                self.war_time_text:setString(panel_util:GetTimeStr(self.war_tip_countdown))
                self.war_desc_text:setString(lang_constants:GetFormattedStr("guild_war_tip_" .. self.display_status, ""))
            end

            if guild_logic:GetCurStatus() >= CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then
                guild_logic:QueryWarResult()
            end
        else
            self.war_tip_img:setVisible(false)
        end
    end
end

function main_panel:ShowTeamButton(flag)
    flag = flag and feature_config:IsFeatureOpen("guild_war")
    
    self.team_btn:setVisible(flag) 
    self.team_img:setVisible(flag) 
    self.team_text:setVisible(flag) 
    self.chat_img:setVisible(flag)
    self.chat_text:setVisible(flag)
end

function main_panel:ShowGuildWarButton(flag)
    flag = flag and feature_config:IsFeatureOpen("guild_war")

    self.guild_bg:setVisible(flag)
    self.guild_txt:setVisible(flag)
    self.war_tip_img:setVisible(flag)
    
    self.rank_btn:setVisible(flag)
    self.reward_allot_btn:setVisible(flag)
    self.enterfor_war_btn:setVisible(flag)
end

--公会boss绿点
function main_panel:UpdateGuildBossRemind()
    self.boss_remind_icon:setVisible(guild_logic:IsShowBossRemid())
end

--播放动画
function main_panel:PlayBossAnimation()
    self.time_line_action:play("animation_in", false)
end

function main_panel:CheckUiVisible()
    if guild_logic:IsGuildMember() then
        self.guild_desc_text:setString(guild_logic.guild_name)
        self.guild_id_text:setString(string.format(lang_constants:Get("guild_title"), guild_logic.guild_id))
        self.found_btn:setVisible(false)
        self.list_btn:setVisible(true)
        self.discuss_btn:setVisible(true)
        self:RefreshNoticeTips()
        self.guild_id_bg:setVisible(true)
        self.setting_btn:setVisible( guild_logic:IsGuildChairman() or guild_logic:IsGuildManager() )
        self.list_txt_label:setString(lang_constants:Get("guild_member_list_desc"))
        self:ShowTeamButton(true)
        self:ShowGuildWarButton(true)
        self:ShowGuildBoss(true)
    else
        self.guild_desc_text:setString(lang_constants:Get("guild_none"))
        self.list_btn:setVisible(false)
        self.discuss_btn:setVisible(false)
        self.discuss_tip:setVisible(false)
        self.found_btn:setVisible(true)
        self.guild_id_bg:setVisible(false)
        self.setting_btn:setVisible(false)
        self.list_txt_label:setString(lang_constants:Get("join_guild_desc"))
        self:ShowTeamButton(false)
        self:ShowGuildWarButton(false)
        self:ShowGuildBoss(false)
    end
    self.list_bg:setContentSize(cc.size(self.list_txt_label:getContentSize().width+40,self.list_bg:getContentSize().height))
end

function main_panel:Show()
    graphic:DispatchEvent("jump_finish",JUMP_CONST["guild_main"]) 
    
    self.root_node:setVisible(true)

    self.display_status = panel_util:GetGuildWarStatus()

    self.war_tip_countdown = 0
    self:PlayGuildWarAnimation()

    self:CheckUiVisible()

    self.war_tip_img:setVisible(guild_logic:GetCurSeasonConf() ~= nil)

    self:RefreshBbsTips()
    self:UpdateGuildBossRemind()
end

function main_panel:RefreshBbsTips()
    local num = chat_logic.new_mine_guild
    if num > 0 then
        self.discuss_tip:setVisible(true)
        self.discuss_tip_value:setString(num)
    else
        self.discuss_tip:setVisible(false)
    end
end

function main_panel:RefreshNoticeTips()
    local num = guild_logic:GetNoticeUnReadNum()
    if num > 0 and not guild_logic.is_notice_notify then
        self.invitation_tip:setVisible(true)
        self.invitation_tip_value_txt:setVisible(true)
        self.invitation_tip_value_txt:setString(num)
    else
        self.invitation_tip:setVisible(false)
        self.invitation_tip_value_txt:setVisible(false)
    end
end

function main_panel:RegisterEvent()
    graphic:RegisterEvent("join_guild", function(is_creator)
        if not self.root_node:isVisible() then
            return
        end

        if is_creator then
            audio_manager:PlayEffect("guild_build_success")
        end

        self:PlayBossAnimation()
        self:Show()
    end)

    graphic:RegisterEvent("exit_guild", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("refresh_notice_tips", function(num)
        if not self.root_node:isVisible() then
            return
        end

        audio_manager:PlayEffect("guild_notice")
        self:RefreshNoticeTips()
    end)

    graphic:RegisterEvent("update_guild_member_grade", function()
        if not self.root_node:isVisible() then
            return
        end

        self.setting_btn:setVisible( guild_logic:IsGuildChairman() or guild_logic:IsGuildManager() )
    end)

    graphic:RegisterEvent("update_guild_war_status", function()
        if not self.root_node:isVisible() then
            return
        end

        self:PlayGuildWarAnimation()
    end)

    graphic:RegisterEvent("guild_boss_info_update", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateGuildBossRemind()
    end)

    graphic:RegisterEvent("boss_change_refsh", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateGuildBossRemind()
    end)
    
end

function main_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    -- 创建公会
    self.found_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if vip_logic:IsActivated(constants["VIP_TYPE"]["adventure"]) then
                graphic:DispatchEvent("show_world_sub_panel", "guild.create_msgbox")
            else
                graphic:DispatchEvent("show_prompt_panel", "guild_create_error")
            end
        end
    end)

    -- 搜索公会
    self.search_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.search_panel")
        end
    end)

    -- 设置公会
    self.setting_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.setting_msgbox")
        end
    end)

    -- 查看公会成员
    self.list_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "guild_member_sub_scene")
        end
    end)

    -- 查看公会讨论区
    self.discuss_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "bbs_sub_scene", false, "guild")
        end
    end)

    -- 查看通知
    self.invitation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            guild_logic:ReadNoticeList()
        end
    end)

    --公会活动
    self.guild_carnival_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if guild_logic:IsGuildMember() then
                local spec_type, config = carnival_logic:GetSpecialVisibleStyle()
                if spec_type and spec_type == 1 and carnival_logic:GetCanDoTaskIndex(config) ~= 0 then
                    graphic:DispatchEvent("show_world_sub_panel", "carnival.christmas_panel", config)
                end
            end
        end
    end)

    --报名入口
    self.enterfor_war_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
       
            if not guild_logic:IsGuildMember() then
               return 
            end

            if guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["NONE"] then 
                graphic:DispatchEvent("show_prompt_panel", "guild_war_not_in_season")
                graphic:DispatchEvent("show_world_sub_scene", "guildwar_sub_scene")
                return 
            end

            if guild_logic:GetCurStatus() <= CLIENT_GUILDWAR_STATUS["READY"] then 
               graphic:DispatchEvent("show_world_sub_scene", "guildwar_sub_scene") 
            else
               graphic:DispatchEvent("show_world_sub_panel", "guild.enlist_panel")
            end
        end
    end)

    --分配奖励、奖励日志
    self.reward_allot_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
       
            if not guild_logic:IsGuildMember() then
               graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
               return 
            end

            if guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["NONE"] or (guild_logic:GetCurrentRound() == 1 and guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["READY"]) then 
               graphic:DispatchEvent("show_world_sub_panel", "guild.bonus_allocation_panel")
            end
        end
    end)

    self.team_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            if guild_logic:IsGuildMember() then
                local back_panel = "guild.main_panel"
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["guild"], back_panel)
                graphic:DispatchEvent("update_battle_point", troop_logic:GetTroopBP(constants["GUILD_WAR_TROOP_ID"]))
            end
        end
    end)

    self.rank_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            guild_logic:QueryGuildRank()
        end
    end)

    self.boss_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            --判断是否是公会成员
            if not guild_logic:IsGuildMember() then
               -- graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
               return 
            end

            if guild_logic.guild_cur_boss_id == nil then
                guild_logic.query_boss_info = true
                guild_logic:QueryGuildBossInfo() 
                return
            end

            graphic:DispatchEvent("show_world_sub_scene", "guild_boss_sub_scene")
        end
    end)
    
end

return main_panel
