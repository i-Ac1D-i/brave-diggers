local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"
local time_logic = require "logic.time"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local common_function_util = require "util.common_function"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"

local config_manager = require "logic.config_manager"
local ui_role_prototype = require "entity.ui_role"

local PLIST_TYPE = ccui.TextureResType.plistType

local math_max = math.max

local CLIENT_GUILDWAR_STATUS = client_constants["CLIENT_GUILDWAR_STATUS"]
local WAR_BATTLE_RESULT = client_constants["BATTLE_STATUS"]

local TIP_STATUS = {
    ["no_status"] = 0,
    ["before_match"] = 1,
    ["match_ready"] = 2,
    ["before_war"] = 3,
    ["after_war"] = 4,
}

local DIRECTION = {
    ["left"] = 1,
    ["right"] = 2,
}

local ANI_DUR = 0.5

local WAR_FIELD_NUM = constants.MAX_WAR_FIELDS
local WARRING_NODE = 2
local TEMPLATE_CONFIG = {
    [1] = 768,
    [2] = 548,  
    [3] = 310
}

local ROLE_POS = {
    [1] = {260, 20},
    [2] = {200, 20},
    [3] = {140, 20},
    [4] = {80, 20},
    [5] = {230, 40},
    [6] = {170, 40},
    [7] = {110, 40},
    [8] = {50, 40},
}

local LEVEL_BTN_TAG = {
    ["my"] = 1,
    ["enemy"] = 2,
}

local war_place_panel = panel_prototype.New()
war_place_panel.__index = war_place_panel

function war_place_panel.New()
    local t = {}
    return setmetatable(t, war_place_panel)
end

function war_place_panel:Init(root_node, index, main_panel)
    self.index = index
    self.root_node = root_node
    self.main_panel = main_panel

    self.root_node:setPosition(cc.p(self.root_node:getPositionX(), TEMPLATE_CONFIG[index]))
    self.root_node:setVisible(true)

    self.join_mini_icon = self.root_node:getChildByName("join_btn")
    self.join_mini_icon:setVisible(false)

    self.joined_tip_icon = self.root_node:getChildByName("mine_btn")
    self.joined_tip_icon:setVisible(false)

    self.joined_bg_btn = self.root_node:getChildByName("join_a_btn")
    self.joined_bg_btn:setTouchEnabled(true)

    self.balance_btn = self.root_node:getChildByName("balance_btn")
    self.balance_btn:setTouchEnabled(true)
    self.balance_btn:setVisible(false)

    self.genre_desc_text_bg = self.root_node:getChildByName("genre_desc_bg")
    self.genre_desc_text_bg:setVisible(true)
    self.genre_desc_text_bg:setOpacity(120)

    self.genre_desc_text = self.root_node:getChildByName("genre_desc")
    self.genre_desc_text:setVisible(true)

    self.genre_bg = self.root_node:getChildByName("genre_bg")
    self.genre_bg:setVisible(false)

    self.detail_node = self.root_node:getChildByName("detial01")
    self.detail_shadow_node = self.root_node:getChildByName("detial_shadow")

    self.detail_node:setScale(1.1)
    self.detail_shadow_node:setScale(1.1)

    self.detail_node:setVisible(false)
    self.detail_shadow_node:setVisible(false)

    self.detail_node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(2),cc.FadeIn:create(2))))
    self.detail_shadow_node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(2),cc.FadeTo:create(2, self.detail_shadow_node:getOpacity()))))

    self.team_node = self.root_node:getChildByName("our_team")
    self.team_num_text = self.team_node:getChildByName("team_num")
    self.team_desc_text = self.team_node:getChildByName("team_desc")
    self.team_desc_text:setVisible(true)
    self.team_desc_text:setOpacity(0)

    self.enemy_team = self.root_node:getChildByName("enemy_team")
    self.enemy_team_num = self.enemy_team:getChildByName("team_num")
    self.enemy_team_unknown = self.enemy_team:getChildByName("team_icon")
    self.enemy_team_unknown:setVisible(true)
    self.enemy_team_desc_text = self.enemy_team:getChildByName("team_desc")
    self.enemy_team_num:setVisible(false)
    self.enemy_team_desc_text:setVisible(true)
    self.enemy_team_desc_text:setOpacity(0)

    self.team_node_scale = self.team_node:getScale()

        --阴影
    self.shadow_nodes = {}
    self.role_nodes = {}

    local n = constants["MAX_FORMATION_CAPACITY"] * 2
    for i = 1, n do
        local shadow_node = cc.Sprite:create("res/role/shadow.png")
        shadow_node:setVisible(false)
        self.root_node:addChild(shadow_node)
        table.insert(self.shadow_nodes, 1, shadow_node)

        local role_node = cc.Node:create()
        shadow_node:addChild(role_node)
        table.insert(self.role_nodes, 1, role_node)
    end

    self.roles = {}
    local max_role_num = client_constants["MAX_GUILD_BATTLE_ROLE_NUM"]
    for i=1, max_role_num do
        local role = ui_role_prototype.New()
        table.insert(self.roles, i, role)
    end
    self.last_team_num = 0

    self.time_delta = 0
    self.time_per_frame = 0.1
    self.cur_team_num = 0
    self.des_team_num = 0
    self.cur_enemy_team_num = 0
    self.des_enemy_team_num = 0

    --self:LoadAnimation()
    self:RegisterWidgetEvent()
end

function war_place_panel:LoadAnimation()
    self.spine_node = spine_manager:GetNode("team_fight", 1.0, true)
    self.spine_node:setPosition(320, 60)
    self.root_node:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)
    self.spine_node:setVisible(false)
    self.spine_node:setAnimation(0, "ready_team_" .. tostring(math.random(1,2)), true)
end

function war_place_panel:SetGenreVisible(flag)
    self.genre_bg:setVisible(flag)
    self.genre_desc_text:setVisible(flag)
    self.genre_desc_text_bg:setVisible(flag)
end

function war_place_panel:PlayRoleReadyAnimation(index)
    local role_node = self.role_nodes[index]
    local shadow_node = self.shadow_nodes[index]

    --人物的跳跃
    local function JumpAnimation()

        role_node:setPosition(0,0)
        
        --概率
        if math.random(1,10) < 3 then
            --跳跃动作：随机延迟一会，跳起，落地后有一个收缩的动作
            local seq_jump = cc.Sequence:create(cc.DelayTime:create(math.random(10,20) / 10),
                                                cc.JumpBy:create(0.5, {}, 20, 1),
                                                cc.ScaleTo:create(0.05, 1, 0.85),
                                                cc.ScaleTo:create(0.05, 1, 1))
            role_node:runAction(seq_jump)
        end
    end

    --阴影＋人物的横向位移
    local shadow_node = self.shadow_nodes[index]
    local seq_move = cc.Sequence:create(cc.CallFunc:create(JumpAnimation),
                                        cc.MoveBy:create(math.random(25,30) / 10, cc.p(-12,0)),
                                        cc.CallFunc:create(JumpAnimation),
                                        cc.MoveBy:create(math.random(25,30) / 10, cc.p(12,0)),
                                        cc.CallFunc:create(function()
                                            self:PlayRoleReadyAnimation(index)
                                        end))
    shadow_node:runAction(seq_move)
end

function war_place_panel:UpdateWarfieldNum(result_flag)
    local result_flag = result_flag or false

    self:SetGenreVisible(not result_flag)
    self.enemy_team_num:setVisible(result_flag)
    self.enemy_team_unknown:setVisible(not result_flag)
    if result_flag then 
        --self.spine_node:setVisible(false)
        self.join_mini_icon:setVisible(false)
        self.joined_tip_icon:setVisible(false)

        for i=1,client_constants["MAX_GUILD_BATTLE_ROLE_NUM"] do
            local role = self.roles[i]
            role:Clear()
            
            self.shadow_nodes[i]:setVisible(false)
            self.shadow_nodes[i]:stopAllActions()
        end

    else
        local team_num = guild_logic:GetMembersInWarField(self.index)
        
        self.cur_team_num = team_num
        self.des_team_num = team_num
        self.team_num_text:setString(tostring(team_num))
        --self.spine_node:setVisible( team_num > 0 )
        self:CheckJoin()

        if self.last_team_num ~= team_num then
            local max_role_num = client_constants["MAX_GUILD_BATTLE_ROLE_NUM"]

            --隐藏无用的人物
            for i=team_num + 1, max_role_num do
                local role = self.roles[i]
                role:Clear()
                
                self.shadow_nodes[i]:setVisible(false)
                self.shadow_nodes[i]:stopAllActions()
                self.role_nodes[i]:stopAllActions()
            end

            local members = guild_logic:GetFieldMembersByField(self.index)
            table.sort(members, function(a, b) return a.bp > b.bp end)

            --根据据点成员的战力排序后重设人物形象位置等
            for i=1, team_num > max_role_num and max_role_num or team_num do
                local conf = config_manager.mercenary_config[members[i].template_id]

                local role = self.roles[i]
                local sprite = role:GetSprite()
                if not sprite then
                    sprite = cc.Sprite:create()
                    self.role_nodes[i]:addChild(sprite)
                end

                self.shadow_nodes[i]:stopAllActions()
                self.role_nodes[i]:stopAllActions()
                
                sprite:setPosition(self.shadow_nodes[i]:getContentSize().width / 2, self.shadow_nodes[i]:getContentSize().height / 2 + 30)
                self.shadow_nodes[i]:setPosition(unpack(ROLE_POS[i]))

                role:Init(sprite, conf.sprite)
                role:WalkAnimation(3)

                self:PlayRoleReadyAnimation(i)
                
                self.shadow_nodes[i]:setVisible(true)
            end
            self.last_team_num = team_num
        end
    end
end

function war_place_panel:SetEnemyNum(nums)
    local nums = nums or guild_logic:GetVsTroopNum(self.index)

    self.cur_enemy_team_num = nums
    self.des_enemy_team_num = nums
    self.enemy_team_num:setString(tostring(nums))
end

function war_place_panel:Update(elapsed_time)

    self.time_delta = self.time_delta + elapsed_time

    if self.time_delta > self.time_per_frame then
        self.time_delta = 0

        if self.cur_team_num > self.des_team_num then
            self.cur_team_num = self.cur_team_num - 1
            self.team_num_text:setString(tostring(self.cur_team_num))

            local seq_scale = cc.Sequence:create(cc.ScaleTo:create(0.05, self.team_node_scale * 1.5, self.team_node_scale * 1.5),
                                                cc.ScaleTo:create(0.05, self.team_node_scale, self.team_node_scale))
            self.team_node:runAction(seq_scale)

        end
        
        if self.cur_enemy_team_num > self.des_enemy_team_num then
            self.cur_enemy_team_num = self.cur_enemy_team_num - 1
            self.enemy_team_num:setString(tostring(self.cur_enemy_team_num))

            local seq_scale = cc.Sequence:create(cc.ScaleTo:create(0.05, self.team_node_scale * 1.5, self.team_node_scale * 1.5),
                                                cc.ScaleTo:create(0.05, self.team_node_scale, self.team_node_scale))
            self.enemy_team:runAction(seq_scale)
        end
    
    end

end

function war_place_panel:SetVisible(flag)
    local flag = flag or false
    if flag then 
        self:Show()
    else
        self:Hide()
    end
end

function war_place_panel:SetBalanceBtnVisible( isVisible )
    self.balance_btn:setVisible(isVisible)

    self.detail_node:setVisible(isVisible)
    self.detail_shadow_node:setVisible(isVisible)
end

function war_place_panel:CheckJoin()
    if self.index == guild_logic:GetWarField() then 
       self.join_mini_icon:setVisible(false)
       self.joined_tip_icon:setVisible(true)
    else       
       self.join_mini_icon:setVisible(true)
       self.joined_tip_icon:setVisible(false)
    end
end

function war_place_panel:SetGenreText(cur_genre)
    if cur_genre == 0 then 
        self.genre_bg:setVisible(false)
        self.genre_desc_text:setString(lang_constants:Get("guild_war_warfield_no_bonus"))
    else
        local bg_name = client_constants["GUILDWAR_GENRE_ICON"][cur_genre]
        self.genre_bg:loadTexture(bg_name, PLIST_TYPE)
        self.genre_bg:setVisible(true)
        local temp_name = lang_constants:Get("guild_war_genre_add" .. cur_genre)
        self.genre_desc_text:setString(lang_constants:GetFormattedStr("guild_war_field_bonus_genre_desc", temp_name))
    end

    self.genre_desc_text_bg:setVisible(true)
    self.genre_desc_text:setVisible(true)
    
end

function war_place_panel:RegisterWidgetEvent()

    local join_war_place = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if guild_logic:GetCurStatus() <= CLIENT_GUILDWAR_STATUS["MATCHING"] then 
                graphic:DispatchEvent("show_world_sub_panel", "guild.formation_panel", self.index) 
            end
        end
    end
    
    self.joined_tip_icon:addTouchEventListener(join_war_place)
    self.join_mini_icon:addTouchEventListener(join_war_place) 
    self.joined_bg_btn:addTouchEventListener(join_war_place)

    self.balance_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if guild_logic.has_query_war_result then 
               audio_manager:PlayEffect("click")
               graphic:DispatchEvent("show_world_sub_panel", "guild.battle_summary_msgbox", self.index)
            end   
        end
    end)
end

--选中动画
local war_spine_tracker = {}
war_spine_tracker.__index = war_spine_tracker

function war_spine_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node
    t.mercenary_id = 0

    t.root_node:registerSpineEventHandler(function(event)
        t.finish_choose = true
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, war_spine_tracker)
end

function war_spine_tracker:Bind(animation, x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.animation = animation

    self.offset_x = x
    self.offset_y = y

    self.widget = widget

    self.mercenary_id = mercenary_id

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)

    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, self.animation, false)
    --self.finish_choose = false
end

function war_spine_tracker:Update()
    -- if not self.finish_choose then
    if self.root_node:isVisible() and self.widget then
        local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
        self.widget:setScale(scale_x, scale_y)
        self.widget:setPosition(self.offset_x + x, self.offset_y + y)
    end
    -- end
end


local war_main_panel = panel_prototype.New()
war_main_panel.__index = war_main_panel

local war_main_panel = panel_prototype.New(true)
function war_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guildwar_battle_panel.csb")

    self.info_node = self.root_node:getChildByName("info")

    self.vs_img = self.root_node:getChildByName("vs_bg")

    self.my_guild_name_text = self.info_node:getChildByName("our_name")

    self.rival_name_text = self.info_node:getChildByName("enemy_name")

    self.desc_text = self.info_node:getChildByName("pvp_desc")
    self.time_desc = self.info_node:getChildByName("time_desc")
    panel_util:SetTextOutline(self.desc_text, 0x000, 2)

    self.prompt_desc_text = self.root_node:getChildByName("prompt_desc")
    panel_util:SetTextOutline(self.prompt_desc_text, 0x000, 2)
    self.prompt_desc_text:setVisible(false)
    self.prompt_desc_text:setLocalZOrder(2)

    self.member_num_text = self.root_node:getChildByName("member_num")

    self.my_info_node = self.root_node:getChildByName("our_tier_bg")
    self.my_score_text = self.my_info_node:getChildByName("score")
    self.my_tier_text = self.my_info_node:getChildByName("tier")

    self.rival_info_node = self.root_node:getChildByName("enemy_tier_bg")
    self.rival_score_text = self.rival_info_node:getChildByName("score")
    self.rival_tier_text = self.rival_info_node:getChildByName("tier")

    self.my_level_btn = self.root_node:getChildByName("me_level_btn")
    self.my_level_bg = self.root_node:getChildByName("level_me")
    self.my_level_text = self.root_node:getChildByName("level1")

    self.my_level_btn:setTag(LEVEL_BTN_TAG["my"])
    self.my_level_bg:setVisible(false)
    self.my_level_text:setVisible(false)

    self.enemy_level_btn = self.root_node:getChildByName("enemy_level_btn")
    self.enemy_level_bg = self.root_node:getChildByName("level_enemy")
    self.enemy_level_text = self.root_node:getChildByName("level2")

    self.enemy_level_btn:setTag(LEVEL_BTN_TAG["enemy"])
    self.enemy_level_text:setVisible(false)
    self.enemy_level_bg:setVisible(false)

    self.scout_tips_bg = self.root_node:getChildByName("scout")
    self.scout_tips_desc = self.root_node:getChildByName("Text_127")

    self.scout_tips_bg:setVisible(false)
    self.scout_tips_desc:setVisible(false)

    self.war_pos_template = self.root_node:getChildByName("template")
    self.war_pos_template:setVisible(false)
    self.war_field_animation = false
    self.war_field_play_time = 0
    
    self.play_result_animation = false
    self.war_result_spine_nodes = {}
    self.warring_spine_nodes = {}
    self.warring_extra_spine_nodes = {}

    self.warring_end_counts = 0
    self.play_index = 1
    self.play_rounds = {}
    self.war_pos_panels = {}

    for i = 1, WAR_FIELD_NUM do
        self.war_pos_panels[i] = war_place_panel.New()
        self.war_pos_panels[i]:Init(self.war_pos_template:clone(), i, self)
        self.root_node:addChild(self.war_pos_panels[i].root_node, 2)
    end

    self.not_in_warfield_text = self.root_node:getChildByName("member_num")
    self.not_in_warfield_text:setLocalZOrder(2)
    panel_util:SetTextOutline(self.not_in_warfield_text, 0x000, 2)
    
    self.not_in_warfield_text:setVisible(false)

    self.load_spine = false
    self.war_field_animation = true
    self.team_num_text_visi = true
    self.switch_flag = false

    self.rule_btn = self.root_node:getChildByName("rule_btn")
    self.camp_btn = self.root_node:getChildByName("our_place_btn")
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.camp_btn:setTouchEnabled(true)
    
    self.rival_camp_btn = self.root_node:getChildByName("enemy_place_btn")

    self.exchange_reward_btn = self.root_node:getChildByName("exchange_reward_btn")
    self.exchange_reward_btn:setVisible(true)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function war_main_panel:UpdateRivalInfo()
    self.rival_info = guild_logic:GetRivalInfo()

    if self.rival_info and guild_logic:GetCurStatus() >= CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then
        self.rival_name_text:setString(self.rival_info.vs_guild_name)
        self:SetTierInfo(self.rival_score_text, self.rival_tier_text, self.enemy_level_text, self.rival_info.vs_war_score)
        self.rival_info_node:setVisible(true)
        self.enemy_level_btn:setVisible(true)

        self.rival_camp_spine_node:setVisible(false)
    else
        self.rival_name_text:setString(lang_constants:Get("guild_war_unknown_rival"))
        self:SetTierInfo(self.rival_score_text, self.rival_tier_text, self.enemy_level_text, 1500)
        self.rival_info_node:setVisible(false)
        self.enemy_level_btn:setVisible(false)

        self.rival_camp_spine_node:setVisible(false)
    end
end

function war_main_panel:SetTierInfo(score_text, tier_text, level_text, score)
    score_text:setString(tostring(score))
    tier_text:setString(tostring(guild_logic:GetGuildTier(score)))
    level_text:setString(string.format(lang_constants:Get("guild_current_tier_desc"), guild_logic:GetGuildTier(score)))
    panel_util:SetTextOutline(tier_text, 0x000, 2)
end

function war_main_panel:Update(elapsed_time)
    self:UpdateWarStatus(elapsed_time)
    self:WarFieldAnimation(elapsed_time)
    self.not_in_warfield_text:setString(lang_constants:GetFormattedStr("guild_war_member_not_in_warfield", guild_logic:GetMembersInWarField(client_constants["NO_WAR_FIELD"])))


    for i = 1, WAR_FIELD_NUM do
        self.war_pos_panels[i]:Update(elapsed_time)
    end
end

function war_main_panel:WarFieldAnimation(elapsed_time)
    if self.war_field_animation then 
        self.war_field_play_time = self.war_field_play_time + elapsed_time
        local alpha_value 
        if self.war_field_play_time <= 1 then 
            alpha_value = 255 * (1 - self.war_field_play_time/1)
        elseif self.war_field_play_time <= 2 then 
            if not self.switch_flag then 
                self.switch_flag = true
                self.team_num_text_visi = not self.team_num_text_visi 
            end
            alpha_value = 255 * (self.war_field_play_time/2)

        elseif self.war_field_play_time <= 5 then
            alpha_value = 255

        elseif self.war_field_play_time > 5 then
            alpha_value = 255
            self.war_field_play_time = 0 
            self.switch_flag = false
        end  

        for field, sub_panel in ipairs(self.war_pos_panels) do 
            sub_panel.team_desc_text:setVisible(not self.play_result_animation)
            sub_panel.enemy_team_desc_text:setVisible(not self.play_result_animation)
            sub_panel.enemy_team_unknown:setVisible(not self.play_result_animation)
            if self.play_result_animation then
                sub_panel.team_num_text:setOpacity(255)
                sub_panel.enemy_team_num:setOpacity(255)
            else 
                if self.team_num_text_visi then 
                    sub_panel.team_desc_text:setOpacity(0)
                    sub_panel.team_num_text:setOpacity(alpha_value)
                    sub_panel.enemy_team_desc_text:setOpacity(0)
                    if self.play_result_animation then 
                       sub_panel.enemy_team_num:setOpacity(alpha_value)
                    else
                       sub_panel.enemy_team_unknown:setOpacity(alpha_value)
                    end
                else
                    sub_panel.team_num_text:setOpacity(0)
                    sub_panel.team_desc_text:setOpacity(alpha_value)
                    if self.play_result_animation then 
                       sub_panel.enemy_team_num:setOpacity(0)
                    else
                       sub_panel.enemy_team_unknown:setOpacity(0)
                    end
                    sub_panel.enemy_team_desc_text:setOpacity(alpha_value)
                end
            end
            sub_panel:UpdateWarfieldNum(self.play_result_animation)
        end
    end
end

function war_main_panel:UpdateWarDesc()
    local prompt_flag = false
    if not guild_logic:IsEnterForCurrentWar() then 
        prompt_flag = true

        local tip_default = ""
        if guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["NONE"] then
            if guild_logic:GetCurSeasonConf() then
                tip_default = "guild_war_prompt_desc1"
            else
                tip_default = "guild_war_prompt_desc0"
            end
        elseif guild_logic:GetCurStatus() < CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] then
           tip_default = "guild_war_prompt_desc2"
        elseif guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] then
           tip_default = "guild_war_prompt_desc3"
        elseif guild_logic:GetCurStatus() > CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] then 
           tip_default = "guild_war_prompt_desc4"
        end

        self.prompt_desc_text:setString(lang_constants:Get(tip_default))
    end

    for i = 1, WAR_FIELD_NUM do 
        self.war_pos_panels[i]:SetVisible(not prompt_flag)
    end
    
    self.desc_text:setVisible(not prompt_flag)
    self.time_desc:setVisible(not prompt_flag)
    
    self.camp_btn:setVisible(not prompt_flag)
    self.prompt_desc_text:setVisible(prompt_flag)
end

function war_main_panel:UpdateWarStatus(elapsed_time)
    if self.war_countdown == 0 then 
        local deadline
        self.display_status, deadline = panel_util:GetGuildWarStatus()
        self.war_countdown = math_max(0, deadline - time_logic:Now())
    else
        self.war_countdown = math_max(0, self.war_countdown - elapsed_time)
    end

    if guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["NONE"] then 
        --休战
        self.desc_text:setVisible(false)
        self.time_desc:setVisible(false)
        
        self.play_result_animation = false
    else
        self.desc_text:setVisible(true)
        self.time_desc:setVisible(true)

        self.desc_text:setString(lang_constants:GetFormattedStr("guild_war_tip_" .. self.display_status, ""))
        self.time_desc:setString(panel_util:GetTimeStr(self.war_countdown))
    end
    
    if guild_logic:GetCurStatus() == CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then
        self:PlayWarResultAnimation()
    else
        self.play_result_animation = false
        for i = 1, WAR_FIELD_NUM do 
            if self.war_result_spine_nodes[i] then 
                self.war_result_spine_nodes[i]:setVisible(false)
                self.war_pos_panels[i]:SetBalanceBtnVisible(false)
            end
        end

        for i = 1, WARRING_NODE do 
            if self.warring_spine_nodes[i] then 
                self.warring_spine_nodes[i]:setVisible(false)
            end
        end
    end
end

function war_main_panel:PlayWarResultAnimation()
    if self.play_result_animation or not guild_logic.has_query_war_result then
        return 
    end

    self:SetTierInfo(self.my_score_text, self.my_tier_text, self.my_level_text, guild_logic:GetScore())

    for i = 1, WAR_FIELD_NUM do 
        self.war_pos_panels[i]:SetEnemyNum() 
        self.war_result_spine_nodes[i]:clearTracks()
        self.war_result_spine_nodes[i]:setToSetupPose()
        self.war_result_spine_nodes[i]:setVisible(false)
        self.war_pos_panels[i]:SetBalanceBtnVisible(false)
    end

    self.play_result_animation = true
    self.play_index = 1
    self.play_rounds = {}
    self.cur_play_round_index = 1
    self.warring_end_counts = 0

    self:PlayWarringAnimation()
end

function war_main_panel:PlayFieldAnimation()
    if self.play_index <= #self.war_result_spine_nodes then 
        local result = guild_logic:GetWarFieldResult(self.play_index)
        if result > 0 then 
            local ani_name = ""
            if result == WAR_BATTLE_RESULT["win"] then 
                ani_name = "ani_win"
            elseif result == WAR_BATTLE_RESULT["lose"] then 
                ani_name = "ani_lose"
            elseif result == WAR_BATTLE_RESULT["draw"] then 
                ani_name = "ani_draw"
            end
            
            self.war_result_spine_nodes[self.play_index].ended = false
            self.war_result_spine_nodes[self.play_index]:setToSetupPose()
            self.war_result_spine_nodes[self.play_index]:setVisible(true)
            self.war_result_spine_nodes[self.play_index]:setAnimation(0, ani_name, false)
            self.war_result_spine_nodes[self.play_index]:addAnimation(0, ani_name .. "_end", true)

            self.war_pos_panels[self.play_index]:SetBalanceBtnVisible(true)
        end
    else
        graphic:DispatchEvent("show_world_sub_panel", "guild.settlement_step1_panel")
    end
end

function war_main_panel:GenerateWarringAni(spine_node, ani_name)
    local ani_random_num

    if not self.ani_random_num then
        ani_random_num = math.random(1, 7)
    else
        ani_random_num = math.random(1, 6)
        if self.ani_random_num == ani_random_num then
            ani_random_num = ani_random_num + 1
        end
    end

    local ani_name = ani_name or "ani_team_" .. tostring(ani_random_num)
    spine_node:setToSetupPose()
    spine_node:clearTracks()
    spine_node:setAnimation(0, ani_name, false)

    self.ani_random_num = ani_random_num
end

function war_main_panel:FixWarringNodePos(index)
    self.warring_spine_nodes[index]:setPositionY(self.warring_spine_nodes[index]:getPositionY() + 18)
    self.warring_extra_spine_nodes[index]:setPositionY(self.warring_extra_spine_nodes[index]:getPositionY() - 12)
    self.warring_extra_spine_nodes[index]:setVisible(true)
end

function war_main_panel:PlayWarringAnimation()
    if self.play_index <= #self.war_result_spine_nodes then
        self:SetWarringNodesVisible(true)
        self:SetWarringNodesPos()
        local vs_num = guild_logic:GetVsTroopNum(self.play_index) 
        local our_num = guild_logic:GetMembersInWarField(self.play_index)
        local result = guild_logic:GetWarFieldResult(self.play_index)

        if result == WAR_BATTLE_RESULT["draw"] and vs_num + our_num == 0 then  
           self:PlayFieldAnimation() 

        else
            local do_play = function(member_num, enemy_member_num, direction)
                if member_num == 0 then 
                   self.warring_end_counts = self.warring_end_counts + 1

                else
                   local ani_name = nil 
                   if enemy_member_num == 0 then 
                      ani_name = "ani_team_rush_" .. tostring(direction) 
                   end

                   if member_num >= 10 then 
                     self:FixWarringNodePos(direction)
                     self:GenerateWarringAni(self.warring_extra_spine_nodes[direction], ani_name)
                   end

                   self:GenerateWarringAni(self.warring_spine_nodes[direction], ani_name)
                end
            end

            local vs_reamin_num = guild_logic:GetVsRemainTroopNum(self.play_index) 
            local our_reamin_num = guild_logic:GetRemainTroopNum(self.play_index)


            local function calcPlayRound( num, remain_num, index )
                while num and num > remain_num do
                    if (num - remain_num) > 10 then
                        num = num - math.random(5,10)
                    else
                        num = remain_num
                    end

                    self.play_rounds[#self.play_rounds + 1] = {}
                    self.play_rounds[#self.play_rounds][index] = num
                end

                return #self.play_rounds
            end

            local function calcOtherPlayRound( num, remain_num, index )
                local round = #self.play_rounds
                local avgNum = (num - remain_num) / round
                for i=1,round do
                    if i == round then
                        self.play_rounds[i][index] = remain_num
                    else
                        local tmp = math.random( avgNum - 2, avgNum + 2)
                        if tmp > 0 then
                            num = math.max( num - tmp, remain_num )
                        end
                        self.play_rounds[i][index] = num
                    end
                end
            end

            if (our_num - our_reamin_num) > (vs_num - vs_reamin_num) then
                calcPlayRound(our_num, our_reamin_num, 1)
                calcOtherPlayRound(vs_num, vs_reamin_num, 2)
            else
                calcPlayRound(vs_num, vs_reamin_num, 2)
                calcOtherPlayRound(our_num, our_reamin_num, 1)
            end

            if #self.play_rounds  == 0 then
                self.play_rounds[1] = {our_reamin_num, vs_reamin_num}
            end

            do_play(our_num, vs_num, DIRECTION["left"])
            do_play(vs_num, our_num, DIRECTION["right"])
        end
    else
        graphic:DispatchEvent("show_world_sub_panel", "guild.settlement_step1_panel")
    end
end

function war_main_panel:SetWarringNodesVisible(flag)
    self.warring_spine_nodes[1]:setVisible(flag)
    self.warring_spine_nodes[2]:setVisible(flag)         
end 

function war_main_panel:SetWarringNodesPos()
    local x = 320
    local y = TEMPLATE_CONFIG[self.play_index] - 22

    for i = 1, WARRING_NODE do
        self.warring_spine_nodes[i]:setPosition(x, y)
        self.warring_extra_spine_nodes[i]:setPosition(x - 10, y)
    end

    self.light_spine_node:setPosition(x, y) 
end

function war_main_panel:CreateCampSpine(animation_name, pos_x, pos_y)
    local camp_spine_node = spine_manager:GetNode("spy", 1.0, true)
    camp_spine_node:setPosition(pos_x, pos_y - 20)
    camp_spine_node:setTimeScale(1.0)
    camp_spine_node:setAnimation(0, animation_name, true)

    self.root_node:addChild(camp_spine_node)

    return camp_spine_node
end

function war_main_panel:LoadAnimation()
    if self.load_spine then 
        return
    end

    self.load_spine = true 

    self:LoadFieldAnimation()
    self:LoadWarringAnimation()
    
    self.camp_spine_node = self:CreateCampSpine("spy_left", self.camp_btn:getPosition())
    self.rival_camp_spine_node = self:CreateCampSpine("spy_right", self.rival_camp_btn:getPosition())
end

function war_main_panel:LoadFieldAnimation()
    if not self.war_result_spine_nodes[1] then 
        for i = 1, WAR_FIELD_NUM do 
            self.war_result_spine_nodes[i] = spine_manager:GetNode("result", 1.0, true)
            self.war_result_spine_nodes[i]:setPosition(320, TEMPLATE_CONFIG[i] + 28)
            self.root_node:addChild(self.war_result_spine_nodes[i])
            self.war_result_spine_nodes[i]:setTimeScale(1.0)
            self.war_result_spine_nodes[i]:setVisible(false)
            self.war_result_spine_nodes[i]:registerSpineEventHandler(function(event)
                if not self.war_result_spine_nodes[i].ended then 
                    self.war_result_spine_nodes[i].ended = true 
                    self.play_index = self.play_index + 1
                    self.play_rounds = {}
                    self.cur_play_round_index = 1
                    self:PlayWarringAnimation()
                end             
            end, sp.EventType.ANIMATION_COMPLETE)

            self.war_pos_panels[i]:SetBalanceBtnVisible(false)
        end
    end

end

function war_main_panel:LoadWarringAnimation()
    self.warring_spine_nodes = {}
    if not self.warring_spine_nodes[1] then 
        for i = 1, WARRING_NODE do 
            self.warring_spine_nodes[i] = spine_manager:GetNode("team_fight", 1.0, true)
            self.root_node:addChild(self.warring_spine_nodes[i])
            self.warring_spine_nodes[i]:setTimeScale(1.0)
            self.warring_spine_nodes[i]:setVisible(false)
            self.warring_spine_nodes[i]:registerSpineEventHandler(function(event)
                if self.warring_spine_nodes[i] then 
                   self.warring_end_counts = self.warring_end_counts + 1
                   if self.warring_end_counts == #self.warring_spine_nodes then 
                        self.warring_end_counts = 0

                        if self.cur_play_round_index == #self.play_rounds then
                            self:PlayFieldAnimation() 
                            self.warring_extra_spine_nodes[1]:setVisible(false)
                            self.warring_extra_spine_nodes[2]:setVisible(false)
                            self.cur_play_round_index = 0
                        else
                            self:GenerateWarringAni(self.warring_spine_nodes[1])
                            self:GenerateWarringAni(self.warring_spine_nodes[2])
                            if self.war_pos_panels[self.play_index].cur_team_num > 10 then
                                self:GenerateWarringAni(self.warring_extra_spine_nodes[1])
                            end
                            if self.war_pos_panels[self.play_index].cur_enemy_team_num > 10 then
                                self:GenerateWarringAni(self.warring_extra_spine_nodes[2])
                            end
                            self.cur_play_round_index = self.cur_play_round_index + 1
                        end
                   end
                end
            end, sp.EventType.ANIMATION_COMPLETE)

            self.warring_extra_spine_nodes[i] = spine_manager:GetNode("team_fight", 1.0, true)
            self.root_node:addChild(self.warring_extra_spine_nodes[i])
            self.warring_extra_spine_nodes[i]:setTimeScale(1.0)
            self.warring_extra_spine_nodes[i]:setVisible(false)
            -- self.warring_extra_spine_nodes[i]:registerSpineEventHandler(function(event)
            --     if self.warring_extra_spine_nodes[i] then 
                   
            --     end
            -- end, sp.EventType.ANIMATION_COMPLETE)

        end
        self.warring_spine_nodes[2]:setRotationSkewY(180)
        self.warring_extra_spine_nodes[2]:setRotationSkewY(180)

        self.light_spine_node = spine_manager:GetNode("team_fight", 1.0, true)
        self.root_node:addChild(self.light_spine_node)
        self.light_spine_node:setTimeScale(1.0)
        self.light_spine_node:setVisible(false)
        self.light_spine_node:registerSpineEventHandler(function(event)
                if self.light_spine_node then 
                   self.light_spine_node:clearTracks()
                   self.light_spine_node:setVisible(false)
                end
            end, sp.EventType.ANIMATION_COMPLETE)

        self.warring_spine_nodes[1]:registerSpineEventHandler(function(event)
            local animation_name = event.animation
            local b_exist = string.find(animation_name, "ani_team_rush_")
            if not b_exist then
                if event.eventData.name == "attack_touch" then 
                    if self.light_spine_node then 
                        self.light_spine_node:setVisible(true)
                        self.light_spine_node:setToSetupPose()
                        self.light_spine_node:setAnimation(0, "attack_light", false)
                    end

                    self.war_pos_panels[self.play_index].des_team_num = self.play_rounds[self.cur_play_round_index][1]
                    self.war_pos_panels[self.play_index].des_enemy_team_num = self.play_rounds[self.cur_play_round_index][2]
                end
            end
        end, sp.EventType.ANIMATION_EVENT)
    end
end

function war_main_panel:RemoveAnimation()
    -- if self.load_spine then 
    --    self.camp_spine_node:removeFromParent()
    --    self.camp_spine_node:removeFromParent()

    --    self.war_result_spine_node[i]:removeFromParent()

    --    self.camp_spine_node:removeFromParent()
    --    self.camp_spine_node:removeFromParent()

    --    self.mining_animation_node:removeFromParent()
      
       
    --    self.load_spine = false
    -- end
end

function war_main_panel:Hide()
    self.root_node:setVisible(false)
    self:RemoveAnimation()
end

function war_main_panel:Show()
    self.display_status = panel_util:GetGuildWarStatus()

    self.war_countdown = 0

    self.my_guild_name_text:setString(guild_logic.guild_name)
    self:SetTierInfo(self.my_score_text, self.my_tier_text, self.my_level_text, guild_logic:GetScore())

    self:LoadAnimation()

    self:RefreshGenreText()
    self:UpdateRivalInfo()

    for field, sub_panel in ipairs(self.war_pos_panels) do 
        sub_panel:UpdateWarfieldNum(self.play_result_animation)
    end

    self:UpdateWarDesc()
    self:QueryWarInfomation()

    self.root_node:setVisible(true)
end

function war_main_panel:QueryWarInfomation()
    if guild_logic:GetCurStatus() >= CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then
        guild_logic:QueryWarResult()
    end
end

function war_main_panel:RefreshGenreText()
    local genre_table = guild_logic:GetGenreData()

    for i = 1, WAR_FIELD_NUM do
        local panel = self.war_pos_panels[i]
        panel:SetGenreText(genre_table[i])
    end
end

function war_main_panel:UpdateEnterForStatus()
    self.enter_for_btn:setVisible(false)
    self.un_enter_for_btn:setVisible(false)
    if guild_logic:IsEnterForCurrentWar() then 
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
    end
end

function war_main_panel:RegisterEvent()
    graphic:RegisterEvent("refresh_war_rival_info", function()
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateRivalInfo()
    end)

    graphic:RegisterEvent("guildwar_formation_refresh", function(user_id, new_field, old_field)
        if not self.root_node:isVisible() then
            return
        end

        for field, sub_panel in ipairs(self.war_pos_panels) do 
            if new_field == field or old_field == field then
                sub_panel:UpdateWarfieldNum(self.play_result_animation)
            end
        end
    end)

    graphic:RegisterEvent("update_guild_war_status", function()
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateWarDesc()
        self:QueryWarInfomation()
    end)
end

function war_main_panel:RegisterWidgetEvent()
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.rule_panel") 
        end
    end)

    self.camp_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")

            graphic:DispatchEvent("show_world_sub_panel", "guild.camp_panel") 
        end
    end)

    self.exchange_reward_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            guild_logic:QueryExchangeConfig()
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene") 
        end
    end)

    local function show_level_func(widget, event_type)
        -- body
        local tag = widget:getTag()
        local level_text
        local level_bg
        if tag == LEVEL_BTN_TAG["my"] then
            level_text = self.my_level_text
            level_bg = self.my_level_bg
        else
            level_text = self.enemy_level_text
            level_bg = self.enemy_level_bg
        end

        if event_type == ccui.TouchEventType.began then
            level_text:setVisible(true)
            level_bg:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            level_text:setVisible(false)
            level_bg:setVisible(false)
        end
    end

    self.my_level_btn:addTouchEventListener(show_level_func)
    self.enemy_level_btn:addTouchEventListener(show_level_func)
end

return war_main_panel

