local platform_manager = require "logic.platform_manager"
local FONT_SIZE_EN = 30
local FONT_SIZE_ZH = 40
local TEXT_WIDTH = 300
local TEXT_HEIGHT = 200
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local skill_manager = require "logic.skill_manager"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local sub_scene = require "scene.sub_scene"

local adventure_logic = require "logic.adventure"
local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"
local arena_logic = require "logic.arena"
local ladder_logic = require "logic.ladder"
local social_logic = require "logic.social"
local vip_logic = require "logic.vip"
local guild_logic = require "logic.guild"
local rune_logic = require "logic.rune"
local utils = require "util.utils"
local GR_EVENT_TYPE = graphic.EVENT_TYPE
local PLIST_TYPE = ccui.TextureResType.plistType

local role_prototype = require "entity.battle_role"
local troop_entity = require "entity.troop"

local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"

local bit_rshift = bit.rshift
local bit_band = bit.band

local active_skill_config = config_manager.active_skill_config
local role_action_config = config_manager.role_action_config
local role_effect_config = config_manager.role_effect_config
local scene_effect_config = config_manager.scene_effect_config
local mercenary_config = config_manager.mercenary_config

local BATTLE_TYPE = client_constants.BATTLE_TYPE

local LEFT_TROOP_ID = client_constants.BATTLE["left_troop_id"]
local RIGHT_TROOP_ID = client_constants.BATTLE["right_troop_id"]

local SCENE_ORIGIN_X = client_constants.BATTLE["background_x"]
local SCENE_ORIGIN_Y = client_constants.BATTLE["background_y"]

local SCENE_WIDTH = client_constants.BATTLE["background_width"]
local SCENE_HEIGHT = client_constants.BATTLE["background_height"]

local SCENE_EFFECT_ORIGIN = { x = -SCENE_WIDTH / 2, y = -SCENE_HEIGHT / 2 }
local SCENE_EFFECT_DEST = { x = SCENE_WIDTH / 2, y = SCENE_HEIGHT / 2 }

local LEFT_BUFF_NODE_X = -250
local RIGHT_BUFF_NODE_X = 707

local BUFF_NODE_MOVE_X = 280

local spine_node_tracker = {}
spine_node_tracker.__index = spine_node_tracker

function spine_node_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node

    t.root_node:registerSpineEventHandler(function(event)
        t.root_node:setVisible(false)
        t.widget:setVisible(false)
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, spine_node_tracker)
end

function spine_node_tracker:Bind(animation, x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    self.offset_x = x
    self.offset_y = y

    self.widget = widget

    widget:setPosition(x, y)
    widget:setVisible(true)

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)

    self.root_node:setAnimation(0, animation, false)
end

function spine_node_tracker:Update()
    if self.root_node:isVisible() and self.widget then
        local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
        self.widget:setPosition(self.offset_x + x, self.offset_y + y)
        self.widget:setScale(scale_x, scale_y)
        self.widget:setOpacity(alpha)
    end
end

local FRAGMENT_PART =
{
    ["none"] = 0,
    ["battle_begin"] = 1,
    ["show_rune"] = 2,
    ["hide_rune"] = 3,
    ["play_battle_start_animation"] = 4,
    ["load_scene_effect"] = 5,
    ["play_scene_effect"] = 6,
    ["cast_effect"] = 7,
    ["cast_action"] = 8,
    ["receiver_effect_and_action"] = 9,
    ["end_effect"] = 10,
    ["battle_end"] = 11,
}

local battle_fragment =
{
    caster_troop_id = 0,

    vibration_duration = 0,

    effect_time = 0,
    scene_color = { r = 1, g = 1, b = 1, a = 1 },
}

function battle_fragment:Init()
    local update_methods = {}

    update_methods[FRAGMENT_PART["battle_begin"]] = function(elapsed_time, battle_room)
        self.part_index = FRAGMENT_PART["show_rune"]
        battle_room.start_spine_node:setToSetupPose()
        battle_room.start_spine_node:setAnimation(0, "start", false)
        battle_room.start_spine_node:setVisible(true)
        
        battle_room.left_rune_spine_node:setVisible(false)
        battle_room.right_rune_spine_node:setVisible(false)
        battle_room.mask_node:setOpacity(0)

        for i,rune_spine_node in ipairs(battle_room.rune_node_list) do
            rune_spine_node:setVisible(false)
        end
    end

    update_methods[FRAGMENT_PART["show_rune"]] = function(elapsed_time, battle_room)
        if not battle_room.start_spine_node:isVisible() then
            self.show_rune_num = 0
            self.has_left_rune = false
            self.has_right_rune = false

            self.time_line_action_list = {}
            local delay_time = 0
            for index=1,constants["MAX_RUNE_EQUIPMENT_NUM"] * 2 do
                local rune_info
                if index <= constants["MAX_RUNE_EQUIPMENT_NUM"] then
                    rune_info = battle_room.left_rune_list[index]
                else
                    rune_info = battle_room.right_rune_list[index - constants["MAX_RUNE_EQUIPMENT_NUM"]]
                end

                if rune_info then
                    local rune_spine_node = battle_room.rune_node_list[index]
                    rune_spine_node:setVisible(true)

                    local rune_icon_img = rune_spine_node:getChildByName("rune")
                    rune_icon_img:setOpacity(0)
                    local conf = config_manager.rune_config[tonumber(rune_info.template_id)]
                    if conf then
                        rune_icon_img:loadTexture(conf.icon, PLIST_TYPE)
                    end

                    rune_spine_node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), 
                                                                cc.CallFunc:create(function()
                                                                    local time_line_action = animation_manager:GetTimeLine("battle_rune_timeline")
                                                                    rune_spine_node:runAction(time_line_action)
                                                                    time_line_action:play("ani_in", false)
                                                                    self.time_line_action_list[index] = time_line_action
                                                                end),
                                                                cc.DelayTime:create(1), 
                                                                cc.CallFunc:create(function()
                                                                    self.show_rune_num = self.show_rune_num - 1
                                                                end)))
                    self.show_rune_num = self.show_rune_num + 1

                    if index <= constants["MAX_RUNE_EQUIPMENT_NUM"] then
                        self.has_left_rune = true 
                    else
                        self.has_right_rune = true
                    end
                end
                
                if index % 2 == 0 then
                    delay_time = delay_time + 0.2
                end
            end

            if self.has_left_rune or self.has_right_rune then
                battle_room.show_rune_finish = false
                self.part_index = FRAGMENT_PART["hide_rune"]
                battle_room.mask_node:runAction(cc.FadeTo:create(0.2, 155))
            else
                battle_room.show_rune_finish = true
                self.part_index = FRAGMENT_PART["play_battle_start_animation"]

                battle_room.left_rune_spine_node:setVisible(true)
                battle_room.right_rune_spine_node:setVisible(true)
                battle_room.ui_root:ShowBuff()
                battle_room.ui_root:ShowWeapon()

                local left_troop = battle_room.left_troop
                battle_room.ui_root.troop1_sub_panel:ShowBuff(left_troop)
                local right_troop = battle_room.right_troop
                battle_room.ui_root.troop2_sub_panel:ShowBuff(right_troop)
            end
        end
    end

    update_methods[FRAGMENT_PART["hide_rune"]] = function(elapsed_time, battle_room)
        if self.show_rune_num == 0 then
            for index=1,constants["MAX_RUNE_EQUIPMENT_NUM"] * 2 do
                if self.time_line_action_list[index] then
                    self.time_line_action_list[index]:play("ani_out", false)
                end
            end

            battle_room.left_rune_spine_node:setVisible(true)
            battle_room.right_rune_spine_node:setVisible(true)

            if self.has_left_rune then
                battle_room.left_rune_spine_node:setToSetupPose()
                battle_room.left_rune_spine_node:setAnimation(0, "fuwen_in", false)
                battle_room.left_rune_spine_node:addAnimation(0, "fuwen_loop", true)
            end
            if self.has_right_rune then
                battle_room.right_rune_spine_node:setToSetupPose()
                battle_room.right_rune_spine_node:setAnimation(0, "fuwen_in", false)
                battle_room.right_rune_spine_node:addAnimation(0, "fuwen_loop", true)
            end
            
            self.part_index = FRAGMENT_PART["play_battle_start_animation"]
            battle_room.mask_node:runAction(cc.FadeTo:create(0.2, 0))
            battle_room.ui_root:ShowBuff()
            battle_room.ui_root:ShowWeapon()

            local left_troop = battle_room.left_troop
            battle_room.ui_root.troop1_sub_panel:ShowBuff(left_troop)
            local right_troop = battle_room.right_troop
            battle_room.ui_root.troop2_sub_panel:ShowBuff(right_troop)
        end
    end

    update_methods[FRAGMENT_PART["play_battle_start_animation"]] = function(elapsed_time, battle_room)
        if battle_room.show_rune_finish then
            self.fetch_next_fragment = true
        end
    end

    update_methods[FRAGMENT_PART["load_scene_effect"]] = function(elapsed_time, battle_room)
        if self.scene_effect_id ~= 0 then
            local scene_effect = scene_effect_config[self.scene_effect_id]

            self.scene_color.r = bit_band(bit_rshift(scene_effect.target_color, 16), 0xff) / 255
            self.scene_color.g = bit_band(bit_rshift(scene_effect.target_color, 8), 0xff) / 255
            self.scene_color.b = bit_band(scene_effect.target_color, 0xff) / 255
            self.scene_color.a = 1

            self.color_fade_in_remain_time = scene_effect.color_fade_in_time
            self.color_fade_out_remain_time = scene_effect.color_fade_out_time

            self.pic_fade_in_remain_time = scene_effect.pic_fade_in_time
            self.pic_fade_out_remain_time = scene_effect.pic_fade_out_time
            self.pic_wait_remain_time = scene_effect.pic_wait_time

            --创建场景特效图片
            if scene_effect.center_pic ~= "" then
                local sprite_path = "res/effect/" .. scene_effect.center_pic .. ".png"
                battle_room:AdjustSpriteSize(battle_room.scene_effect_sprite, sprite_path, cc.rect(0, 0, 580, 444))

                battle_room.scene_effect_sprite:setOpacity(0)

                battle_room.scene_effect_sprite:setVisible(true)
            end

            self.scene_effect = scene_effect
        else

            self.color_fade_in_remain_time = 0
            self.color_fade_out_remain_time = 0

            self.pic_fade_in_remain_time = 0
            self.pic_fade_out_remain_time = 0
            self.pic_wait_remain_time = 0

            battle_room.scene_effect_sprite:setVisible(false)
        end

        battle_room:ShowSkillName(self.caster_troop_id, self.skill_name)
        --切到下一步
        self.part_index = FRAGMENT_PART["play_scene_effect"]
    end

    update_methods[FRAGMENT_PART["play_scene_effect"]] = function(elapsed_time, battle_room)
        --场景特效

        if self.color_fade_in_remain_time > 0 then
            --颜色渐入
            local scene_effect = self.scene_effect
            self.color_fade_in_remain_time = self.color_fade_in_remain_time - elapsed_time

            self.scene_color.a = scene_effect.color_alpha * (1 - self.color_fade_in_remain_time / scene_effect.color_fade_in_time)
            if self.scene_color.a > 1 then
                self.scene_color.a = 1
            end

            battle_room.scene_color_node:clear()
            battle_room.scene_color_node:drawSolidRect(SCENE_EFFECT_ORIGIN, SCENE_EFFECT_DEST, self.scene_color)

        elseif self.color_fade_out_remain_time > 0 then

        end

        if self.pic_fade_in_remain_time > 0 then
            --图片渐入
            local scene_effect = self.scene_effect
            self.pic_fade_in_remain_time = self.pic_fade_in_remain_time - elapsed_time
            local alpha = scene_effect.pic_alpha * (1 - self.pic_fade_in_remain_time / scene_effect.pic_fade_in_time)

            if alpha > 1 then
                alpha = 1
            end

            battle_room.scene_effect_sprite:setOpacity(alpha * 255)

        elseif self.pic_wait_remain_time > 0 then
            --图片等待
            self.pic_wait_remain_time = self.pic_wait_remain_time - elapsed_time

        elseif self.pic_fade_out_remain_time > 0 then

            --图片渐出
            local scene_effect = self.scene_effect
            self.pic_fade_out_remain_time = self.pic_fade_out_remain_time - elapsed_time
            local alpha = scene_effect.pic_alpha * self.pic_fade_out_remain_time / scene_effect.pic_fade_out_time

            if alpha < 0 then
                alpha = 0
            end

            battle_room.scene_effect_sprite:setOpacity(alpha * 255)
        end

        if self.pic_fade_out_remain_time <= 0 and self.color_fade_in_remain_time <= 0 then

            battle_room.scene_effect_sprite:setVisible(false)

            if self.cast_effect_id ~= 0 then
                self.role_effect_time = self:CreateRoleEffect(battle_room.role_effect_sprite, self.cast_effect_id, self.caster.effect_x, self.caster.effect_y)
            else
                self.role_effect_time = 0
            end

            --切到下一步
            self.part_index = FRAGMENT_PART["cast_effect"]
        end
    end

    update_methods[FRAGMENT_PART["cast_effect"]] = function(elapsed_time, battle_room)
        --施放特效
        self:UpdateRoleEffect(elapsed_time, battle_room)

        if self.role_effect_time <= 0 then

            --切到下一步
            self.part_index = FRAGMENT_PART["cast_action"]

            self.caster:SetAction(role_action_config[self.skill_animation.cast_action])
            self.caster:StartPlayAction()

            battle_room.role_effect_sprite:setVisible(false)
        end
    end

    update_methods[FRAGMENT_PART["cast_action"]] = function(elapsed_time, battle_room)

        if self.color_fade_out_remain_time > 0 then
            --颜色渐出
            local scene_effect = self.scene_effect
            self.color_fade_out_remain_time = self.color_fade_out_remain_time - elapsed_time

            self.scene_color.a = scene_effect.color_alpha * self.color_fade_out_remain_time / scene_effect.color_fade_out_time
            if self.scene_color.a < 0 then
                self.scene_color.a = 0
            end
            battle_room.scene_color_node:clear()
            battle_room.scene_color_node:drawSolidRect(SCENE_EFFECT_ORIGIN, SCENE_EFFECT_DEST, self.scene_color)
        end

        --施放者动作
        if not self.caster:IsPlayAction() and self.pic_fade_out_remain_time <= 0 then

            battle_room.scene_color_node:clear()

            if self.be_hitted_effect_id ~= 0 and not self.is_dodge then
                self.role_effect_time = self:CreateRoleEffect(battle_room.role_effect_sprite, self.be_hitted_effect_id, self.receiver.effect_x, self.receiver.effect_y)
            else
                battle_room.role_effect_sprite:setVisible(false)
                self.role_effect_time = 0
            end

            if self.is_dodge then
                local troop_id = self.caster_troop_id == LEFT_TROOP_ID and RIGHT_TROOP_ID or LEFT_TROOP_ID
                battle_room:ShowSkillName(troop_id, lang_constants:Get("battle_dodge"))
            end

            if self.caster_troop_id == LEFT_TROOP_ID then
                local bp1_text, x, y = battle_room.ui_root:UpdateBattlePoint(RIGHT_TROOP_ID, self.receiver.cur_bp, self.receiver.cur_shield_bp, self.receiver.resist_lethal_damage)
                battle_room.skill_bp1_tracker:Bind("hp", x, y, bp1_text)
                
                if self.receiver.is_resist_lethal then
                    --提示   抵御致死
                    battle_room:ShowSkillName(RIGHT_TROOP_ID, lang_constants:Get("battle_skill_resist_lethal"))
                    self.receiver.is_resist_lethal = false
                    self.receiver.resist_lethal_damage = nil
                end
            else
                local bp1_text, x, y = battle_room.ui_root:UpdateBattlePoint(LEFT_TROOP_ID, self.receiver.cur_bp, self.receiver.cur_shield_bp, self.receiver.resist_lethal_damage)
                battle_room.skill_bp1_tracker:Bind("hp", x, y, bp1_text)
                
                if self.receiver.is_resist_lethal then
                    --提示   抵御致死
                    battle_room:ShowSkillName(LEFT_TROOP_ID, lang_constants:Get("battle_skill_resist_lethal"))
                    self.receiver.is_resist_lethal = false
                    self.receiver.resist_lethal_damage = nil
                end
            end

            -- 回合数变化
            if self.turn_fixed ~= 0 then
                self.turn_num  = math.max(1, self.turn_num + self.turn_fixed)
                battle_room.ui_root:UpdateTurn(self.turn_num)
                self.turn_fixed = 0
            end

            --切到下一步
            self.part_index = FRAGMENT_PART["receiver_effect_and_action"]
            self.receiver:SetAction(self.is_dodge and role_action_config[self.skill_animation.dodge_action] or role_action_config[self.skill_animation.be_hitted_action])
            self.receiver:StartPlayAction()
        end
    end

    update_methods[FRAGMENT_PART["receiver_effect_and_action"]] = function(elapsed_time, battle_room)
        --场景动作 振动
        local scene_action = self.scene_action

        if not self.is_dodge and scene_action and self.vibration_freq > 0 then

            self.vibration_duration = self.vibration_duration + elapsed_time
            if self.vibration_duration >= self.vibration_freq then
                self.vibration_duration = 0

                local vx = (math.random(1, 100) / 100 - 0.5) * scene_action.vibration_x
                local vy = (math.random(1, 100) / 100 - 0.5) * scene_action.vibration_y

                battle_room.background_sprite:setPosition(SCENE_ORIGIN_X + vx, SCENE_ORIGIN_Y + vy)
            end
        end

        self:UpdateRoleEffect(elapsed_time, battle_room)

        if not self.receiver:IsPlayAction() and self.role_effect_time <= 0 then
            --切到下一步
            self.part_index = FRAGMENT_PART["end_effect"]

            if self.end_effect_id ~= 0 then
                --结束时特效不要考虑闪避
                self.role_effect_time = self:CreateRoleEffect(battle_room.role_effect_sprite, self.end_effect_id, self.caster.effect_x, self.caster.effect_y)
            else
                battle_room.role_effect_sprite:setVisible(false)
                self.role_effect_time = 0
            end

            if self.caster_troop_id == LEFT_TROOP_ID then
               local bp2_text, x, y = battle_room.ui_root:UpdateBattlePoint(LEFT_TROOP_ID, self.caster.cur_bp, self.caster.cur_shield_bp)
                battle_room.skill_bp2_tracker:Bind("hp", x, y, bp2_text)

            else
                local bp2_text, x, y = battle_room.ui_root:UpdateBattlePoint(RIGHT_TROOP_ID, self.caster.cur_bp, self.caster.cur_shield_bp)
                battle_room.skill_bp2_tracker:Bind("hp", x, y, bp2_text)
            end

            -- 更新四维
            local left_troop = battle_room.left_troop
            local right_troop = battle_room.right_troop
            battle_room.ui_root.troop1_sub_panel:UpdateProperty(left_troop)
            battle_room.ui_root.troop2_sub_panel:UpdateProperty(right_troop)
        end
    end

    update_methods[FRAGMENT_PART["end_effect"]] = function(elapsed_time, battle_room)
        --动作结束时更新界面
        battle_room.background_sprite:setPosition(SCENE_ORIGIN_X, SCENE_ORIGIN_Y)

        self:UpdateRoleEffect(elapsed_time, battle_room)

        if self.role_effect_time <= 0 then
            --检测战斗是否结束
            if self.receiver.cur_bp <= 0 then
                self:End(battle_room)

            else
                self.fetch_next_fragment = true
                self.part_index = FRAGMENT_PART["none"]
            end
        end
   end

   update_methods[FRAGMENT_PART["battle_end"]] = function(elapsed_time, battle_room)
        --显示离开战斗按钮
        if not battle_room.left_troop:IsPlayAction() and not battle_room.right_troop:IsPlayAction() then
            --切到下一步
            self.part_index = FRAGMENT_PART["none"]
        end
   end

    self.part_index = FRAGMENT_PART["none"]
    self.update_methods = update_methods
    self.cur_method = nil
end

function battle_fragment:Start(record)
    self.record = record
    self.caster_troop_id = nil
    self.part_index = FRAGMENT_PART["battle_begin"]
    self.real_turn = 0
    self.turn_num = 0
    self.max_turn = #record / 2
end

function battle_fragment:LeftTroopWin(battle_room)
    battle_room.left_troop:PlayVictoryAction()
    battle_room.right_troop:PlayDeathAction()
    audio_manager:PlayMusic("battle_win")
    battle_room.start_spine_node:setVisible(true)
    battle_room.start_spine_node:setAnimation(0, "win", false)

    self.part_index = FRAGMENT_PART["battle_end"]
end

function battle_fragment:RightTroopWin(battle_room)
    battle_room.right_troop:PlayVictoryAction()
    battle_room.left_troop:PlayDeathAction()
    audio_manager:PlayMusic("battle_lose")
    battle_room.start_spine_node:setVisible(true)
    battle_room.start_spine_node:setAnimation(0, "lose", false)

    self.part_index = FRAGMENT_PART["battle_end"]
end

function battle_fragment:Draw(battle_room)
    battle_room.right_troop:PlayDeathAction()
    battle_room.left_troop:PlayDeathAction()

    --audio_manager:PlayMusic("battle_lose")
    battle_room.start_spine_node:setVisible(true)
    battle_room.start_spine_node:setAnimation(0, "draw", false)

    self.part_index = FRAGMENT_PART["battle_end"]
end

function battle_fragment:Update(elapsed_time, battle_room)
    if self.part_index ~= FRAGMENT_PART["none"] then
        self.update_methods[self.part_index](elapsed_time, battle_room)
    end

    battle_room.left_troop:Update(elapsed_time)
    battle_room.right_troop:Update(elapsed_time)

    battle_room.skill_name_tracker:Update(elapsed_time)
    battle_room.skill_bp1_tracker:Update(elapsed_time)
    battle_room.skill_bp2_tracker:Update(elapsed_time)
end

--创建角色特效
function battle_fragment:CreateRoleEffect(sprite, effect_id, pos_x, pos_y)
    local config = role_effect_config[effect_id]
    if not config then
        return 0
    end

    local sprite_path = "res/effect/" .. config.sprite .. ".png"

    local texture = cc.Director:getInstance():getTextureCache():addImage(sprite_path)
    texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    local texture_width = texture:getPixelsWide() / config.frame_col
    local texture_height = texture:getPixelsHigh() / config.frame_row

    sprite:setTexture(texture)
    sprite:setTextureRect(cc.rect(0, 0, texture_width, texture_height))

    self.effect_frame_index = 1
    self.effect_time_per_frame = config.frame_speed / 1000
    self.role_effect_time_delta = 0

    self.frames = {}
    for i = 1, config.frame_row do
        for j = 1, config.frame_col do

            local rect = cc.rect{}
            rect.x = (j - 1) * texture_width
            rect.y = (i - 1) * texture_height
            rect.width = texture_width
            rect.height = texture_height

            self.frames[(i - 1) * config.frame_col + j] = rect
        end
    end

    sprite:setPosition(pos_x, pos_y)

    sprite:setVisible(true)

    audio_manager:PlayEffect(config.sound_effect)

    return config.frame_speed * config.frame_num / 1000
end

function battle_fragment:UpdateRoleEffect(elapsed_time, battle_room)

    if self.role_effect_time <= 0 then
        return
    end

    self.role_effect_time = self.role_effect_time - elapsed_time
    self.role_effect_time_delta = self.role_effect_time_delta + elapsed_time


    if self.role_effect_time <= 0 then
        battle_room.role_effect_sprite:setVisible(false)

    elseif self.role_effect_time_delta > self.effect_time_per_frame then
        self.role_effect_time_delta = 0
        self.effect_frame_index = self.effect_frame_index + 1
        battle_room.role_effect_sprite:setTextureRect(self.frames[self.effect_frame_index])
    end
end

function battle_fragment:End(battle_room)
    if battle_room.battle_status == client_constants.BATTLE_STATUS["win"] then
        self:LeftTroopWin(battle_room)

    elseif battle_room.battle_status == client_constants.BATTLE_STATUS["lose"] then
        self:RightTroopWin(battle_room)

    else
        self:Draw(battle_room)
    end
end

function battle_fragment:LoadNextFragment(battle_room)
    --获取下一条战斗片段
    if not self.fetch_next_fragment then
        return
    end

    local skill_id, is_dodge = self.record[self.real_turn * 2 + 1], self.record[self.real_turn * 2 + 2]
    self.fetch_next_fragment = false

    if not skill_id then
        self:End(battle_room)
        return
    end

    self.real_turn = self.real_turn + 1
    self.turn_num = self.turn_num + 1

    if self.real_turn == 1 then
        if battle_room.left_troop.speed == battle_room.right_troop.speed then
            self.caster_troop_id = battle_room.change_side and RIGHT_TROOP_ID or LEFT_TROOP_ID
        elseif battle_room.left_troop.speed > battle_room.right_troop.speed then
            self.caster_troop_id = LEFT_TROOP_ID
        else
            self.caster_troop_id = RIGHT_TROOP_ID
        end
    else
        self.caster_troop_id = self.caster_troop_id == LEFT_TROOP_ID and RIGHT_TROOP_ID or LEFT_TROOP_ID
    end

    self.is_dodge = is_dodge == 1

    battle_room.ui_root:UpdateTurn(self.turn_num)

    --先设置需要播放的动作
    local skill = active_skill_config[tonumber(skill_id)]

    if self.caster_troop_id == LEFT_TROOP_ID then
        self.caster = battle_room.left_troop
        self.receiver = battle_room.right_troop

    else
        self.caster = battle_room.right_troop
        self.receiver = battle_room.left_troop
    end

    self.turn_fixed = self.caster:UseSkill(skill, self.is_dodge)

    self.skill = skill
    self.skill_name = skill.name

    if skill.effect_type == constants.ACTIVE_SKILL_EFFECT_TYPE["copy_skill"] and self.receiver.last_turn_skill then
        self.skill = self.receiver.last_turn_skill
    end

    local skill_animation = config_manager.skill_animation[self.skill.animation_id]
    self.skill_animation = skill_animation

    self.end_effect_id = skill_animation.end_effect
    self.cast_effect_id = skill_animation.cast_effect
    self.be_hitted_effect_id = skill_animation.be_hitted_effect

    -- 场景动作
    self.scene_action = config_manager.scene_action[skill_animation.scene_action]
    self.vibration_duration = 0
    self.vibration_freq = self.scene_action and self.scene_action.vibration_freq / 1000 or 0

    --场景特效
    self.scene_effect_id = skill_animation.scene_effect

    self.part_index = FRAGMENT_PART["load_scene_effect"]
end

local battle_room = sub_scene.New()
function battle_room:Init()
    self.__origin_event_dispatcher = nil
    self.__event_dispatcher = cc.EventDispatcher:new()
    self.__event_dispatcher:setEnabled(true)
    self:PushEventDispatcher()

    self.root_node = cc.Node:create()

    self.ui_root = require "ui.battle_panel"
    self.ui_root:Init()

    self.is_in_battle = false

    self.left_troop = troop_entity.New(1)
    self.right_troop = troop_entity.New(2)

    --场景颜色
    self.scene_color_node = cc.DrawNode:create()
    self.root_node:addChild(self.scene_color_node, 1)

    self.scene_color_node:setPosition(SCENE_ORIGIN_X, SCENE_ORIGIN_Y)

    --场景特效图
    self.scene_effect_sprite = cc.Sprite:create()
    self.scene_effect_sprite:setPosition(SCENE_ORIGIN_X, SCENE_ORIGIN_Y)

    self.root_node:addChild(self.scene_effect_sprite, 2)
    --添加ui节点
    self.root_node:addChild(self.ui_root:GetRootNode(), 300)

    --阴影
    self.shadow_batch_node = cc.SpriteBatchNode:create("res/role/shadow.png",  constants["MAX_FORMATION_CAPACITY"] * 2)

    self.root_node:addChild(self.shadow_batch_node, 100)

    self.shadow_nodes = {}

    local n = constants["MAX_FORMATION_CAPACITY"] * 2
    for i = 1, n do
        local node = cc.Sprite:create("res/role/shadow.png")
        self.shadow_nodes[i] = node
        self.shadow_batch_node:addChild(node)
    end

    for i = 1, 2 do
        local text = ccui.Text:create("", client_constants["FONT_FACE"], platform_manager:GetLocale() == "en-US" and FONT_SIZE_EN or FONT_SIZE_ZH)
        text:ignoreContentAdaptWithSize(false)
        text:setContentSize(cc.size(TEXT_WIDTH, TEXT_HEIGHT))
        text:setTextVerticalAlignment(1)
        text:setTextHorizontalAlignment(1)

        panel_util:SetTextOutline(text)
        self.root_node:addChild(text, 299)

        self["skill_name" .. i .. "_text"] = text
    end

    self.monster_sprite_list = {}

    battle_fragment:Init()

    self.callback = nil

    self.root_node:setVisible(false)

    self.ui_root.left_buff_btn:addTouchEventListener(function(widget, event_type)
        local cur_x = self.ui_root.left_buff_node:getPositionX()
         
        if event_type == ccui.TouchEventType.began then
            local move_x = BUFF_NODE_MOVE_X - (cur_x - LEFT_BUFF_NODE_X)
            self.ui_root.left_buff_node:stopAllActions()
            self.ui_root.left_buff_node:runAction(cc.MoveBy:create(0.1 * move_x / BUFF_NODE_MOVE_X, cc.p(move_x, 0)))
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            local move_x = cur_x - LEFT_BUFF_NODE_X
            self.ui_root.left_buff_node:stopAllActions()
            self.ui_root.left_buff_node:runAction(cc.MoveBy:create(0.1 * move_x / BUFF_NODE_MOVE_X, cc.p(-move_x, 0)))
        end
    end)

    self.ui_root.right_buff_btn:addTouchEventListener(function(widget, event_type)
        local cur_x = self.ui_root.right_buff_node:getPositionX()
         
        if event_type == ccui.TouchEventType.began then
            local move_x = BUFF_NODE_MOVE_X - (RIGHT_BUFF_NODE_X - cur_x)
            self.ui_root.right_buff_node:stopAllActions()
            self.ui_root.right_buff_node:runAction(cc.MoveBy:create(0.1 * move_x / BUFF_NODE_MOVE_X, cc.p(-move_x, 0)))
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            local move_x = BUFF_NODE_MOVE_X - (cur_x - RIGHT_BUFF_NODE_X)
            self.ui_root.right_buff_node:stopAllActions()
            self.ui_root.right_buff_node:runAction(cc.MoveBy:create(0.1 * move_x / BUFF_NODE_MOVE_X, cc.p(move_x, 0)))
        end
    end)

    --跳过战斗
    self.ui_root.skip_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            -- 非月卡用户显示漂浮文字
            if not _G["AUTH_MODE"] and battle_fragment.real_turn < 5 and not vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
                graphic:DispatchEvent("show_prompt_panel", "vip_can_skip")
                return
            end

            self.scene_color_node:clear()
            self.role_effect_sprite:setVisible(false)

            if battle_fragment.part_index == FRAGMENT_PART["battle_end"] then
                graphic:DispatchEvent("hide_battle_room")

            else
                battle_fragment:End(self)
            end
        end
    end)

    self:PopEventDispatcher()
end

function battle_room:Clear()
    sub_scene.Clear(self)
end

function battle_room:CreateSprites()
    --角色特效图
    self.role_effect_sprite = cc.Sprite:create()
    self.root_node:addChild(self.role_effect_sprite, 297)
    self.role_effect_sprite:setScale(2.0, 2.0)

    self.background_sprite = cc.Sprite:create()
    self.background_sprite:setPosition(SCENE_ORIGIN_X, SCENE_ORIGIN_Y)
    self.background_sprite:setScale(2.05, 2.05)
    self.root_node:addChild(self.background_sprite)

    local background_size = self.background_sprite:getContentSize()
    self.mask_node = cc.LayerColor:create({r = 0, g = 0, b = 0, a = 255})
    self.mask_node:setPosition(0,0)
    self.mask_node:changeWidthAndHeight(self.mask_node:getContentSize().width, self.mask_node:getContentSize().height)
    --self.mask_node:setScale(2.05, 2.05)
    self.background_sprite:addChild(self.mask_node)
end

function battle_room:DestroySprites()
    for i = 1, self.left_troop.role_num do
        self.left_troop.roles[i]:Clear()
    end

    for i = 1, self.right_troop.role_num do
        self.right_troop.roles[i]:Clear()
    end

    self.role_effect_sprite:removeFromParent()

    self.background_sprite:removeFromParent()
end

function battle_room:CreateSpineNodes()
    --战斗开始动画节点
    self.start_spine_node = spine_manager:GetNode("battle", 1.0, true)

    self.start_spine_node:registerSpineEventHandler(function(event)
        --TAG:MASTER_MERGE
        local animation_name = event.animation
        if animation_name == "start" then
            self.start_spine_node:setVisible(false)
            self.start_spine_node:setToSetupPose()
        elseif animation_name == "win" then
            if platform_manager:GetChannelInfo().meta_channel == "txwy_dny" or platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "r2games" then
                self.ui_root:ShowTapQuitText()
                self.ui_root:SetLeave(true)
                self.ui_root:ShowLeaveBtn()
            else
                self.start_spine_node:setAnimation(1, "win_end", true)
            end
        elseif animation_name == "lose" then
            if platform_manager:GetChannelInfo().meta_channel == "txwy_dny" or platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "r2games" then
                self.ui_root:ShowTapQuitText()
                self.ui_root:SetLeave(true)
                self.ui_root:ShowLeaveBtn()
                self.ui_root:ShowBalanceDescText()
            else
                self.start_spine_node:setAnimation(1, "lose_end", true)
            end
        elseif animation_name == "draw" then
            if platform_manager:GetChannelInfo().meta_channel == "txwy_dny" or platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "r2games" then
            
            else
                self.start_spine_node:setAnimation(1, "draw_end", true)
            end
        elseif animation_name== "win_end" or animation_name == "lose_end" or animation_name == "draw_end" and event.loopCount == 1 then
            if platform_manager:GetChannelInfo().meta_channel == "txwy_dny" or platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "r2games" then
            
            else
                self.ui_root:SetLeave(true)
                self.ui_root:ShowLeaveBtn()
            end
        end
    end, sp.EventType.ANIMATION_COMPLETE)

    self.start_spine_node:registerSpineEventHandler(function(event)
        if event.eventData.name == "sound_win" then 
           audio_manager:PlayEffect("battle_win")
        elseif event.eventData.name == "sound_lose" then 
           audio_manager:PlayEffect("battle_lose")
        elseif event.eventData.name == "touch" then 
           self.ui_root:SetLeave(true)
        end
    end, sp.EventType.ANIMATION_EVENT)

    local SPINE_Z_ORDER = 298

    self.start_spine_node:setPosition(SCENE_ORIGIN_X, SCENE_ORIGIN_Y)
    self.root_node:addChild(self.start_spine_node, SPINE_Z_ORDER)

    --技能节点
    self.skill_bp1_spine_node = spine_manager:GetNode("battle_skill", 1.0, true)
    self.skill_bp2_spine_node = spine_manager:GetNode("battle_skill")
    self.skill_name_spine_node = spine_manager:GetNode("battle_skill")

    self.root_node:addChild(self.skill_bp1_spine_node, SPINE_Z_ORDER)
    self.root_node:addChild(self.skill_bp2_spine_node, SPINE_Z_ORDER)
    self.root_node:addChild(self.skill_name_spine_node, SPINE_Z_ORDER)

    self.skill_name_tracker = spine_node_tracker.New(self.skill_name_spine_node, "skill_name")
    self.skill_bp1_tracker = spine_node_tracker.New(self.skill_bp1_spine_node, "hp")
    self.skill_bp2_tracker = spine_node_tracker.New(self.skill_bp2_spine_node, "hp")

    self.rune_node_list = {}
    self.show_rune_icon_num = 0

    for index=1,constants["MAX_RUNE_EQUIPMENT_NUM"] * 2 do
        self.rune_node_list[index] = cc.CSLoader:createNode("ui/battle_rune.csb")
        self.rune_node_list[index]:setScale(2.5)

        if index <= constants["MAX_RUNE_EQUIPMENT_NUM"] then
            self.rune_node_list[index]:setPosition(client_constants.BATTLE["left_rune_x"], client_constants.BATTLE["rune_y_init"] + client_constants.BATTLE["rune_y_offset"] * index)
        else
            self.rune_node_list[index]:setPosition(client_constants.BATTLE["right_rune_x"], client_constants.BATTLE["rune_y_init"] + client_constants.BATTLE["rune_y_offset"] * (index - constants["MAX_RUNE_EQUIPMENT_NUM"]))
        end

        self.root_node:addChild(self.rune_node_list[index], SPINE_Z_ORDER)
    end

    self.show_rune_finish = true
    self.left_rune_spine_node = spine_manager:GetNode("battle_rune", 1.0, true) 
    self.right_rune_spine_node = spine_manager:GetNode("battle_rune", 1.0, true)

    self.left_rune_spine_node:setAnimation(0, "fuwen_black", false)
    self.right_rune_spine_node:setAnimation(0, "fuwen_black", false)

    self.left_rune_spine_node:setVisible(false)
    self.right_rune_spine_node:setVisible(false)

    self.left_rune_spine_node:setScale(1.2)
    self.right_rune_spine_node:setScale(1.2)
        
    self.left_rune_spine_node:setPosition(45, 820)
    self.right_rune_spine_node:setPosition(595, 820)

    rune_spine_method = function(event)
        local animation_name = event.animation
        if animation_name == "fuwen_in" then
            self.show_rune_finish = true
        end
    end
    self.left_rune_spine_node:registerSpineEventHandler(rune_spine_method, sp.EventType.ANIMATION_COMPLETE)
    self.right_rune_spine_node:registerSpineEventHandler(rune_spine_method, sp.EventType.ANIMATION_COMPLETE)

    self.ui_root:GetRootNode():addChild(self.left_rune_spine_node)
    self.ui_root:GetRootNode():addChild(self.right_rune_spine_node)
end

function battle_room:DestroySpineNodes()
    self.start_spine_node:removeFromParent()
    self.skill_bp1_spine_node:removeFromParent()
    self.skill_bp2_spine_node:removeFromParent()
    self.skill_name_spine_node:removeFromParent()

    self.left_rune_spine_node:removeFromParent()
    self.right_rune_spine_node:removeFromParent()

    for i,rune_spine_node in ipairs(self.rune_node_list) do
        rune_spine_node:removeFromParent()
    end

    spine_manager:DestroyNode("battle")
    spine_manager:DestroyNode("battle_skill")
    spine_manager:DestroyNode("battle_rune")
end

function battle_room:AdjustSpriteSize(sprite, sprite_path, rect)
    local texture = cc.Director:getInstance():getTextureCache():addImage(sprite_path)

    sprite:setTexture(texture)
    sprite:setTextureRect(rect)
end

--显示战斗窗口
function battle_room:Show(battle_type, data, property, record, result, callback)
    self.root_node:setVisible(true)

    self.callback = callback

    self:CreateSprites()
    self:CreateSpineNodes()

    self.change_side = false
    --setTextureRect 会更新uv坐标， uv wrap mode 默认为 GL_CLAMP_TO_EDGE,会导致局部区域严重走样
    --最操蛋的是setTextureRect里rect参数会同时作用于纹理坐标的计算和顶点坐标的计算
    --所以应该设置顶点的缩放值
    --texture:setTexParameters(0x2600, 0x2600, 0x812F, 0x812F)
    self.shadow_index = 1

    local function CreateTroopRole(troop, sprite_list)
        local shadow_nodes = self.shadow_nodes

        local roles = troop.roles
        local role_index = 1
        local free_role_num = #roles

        for i = 1, troop.role_num do
            local sprite_name = sprite_list[i]

            local role
            if i > free_role_num then
                role = role_prototype.New()
                table.insert(roles, role)

            else
                role = roles[role_index]
            end

            local sprite = cc.Sprite:create()
            self.root_node:addChild(sprite, 100)

            role:Init(sprite, sprite_name, shadow_nodes[self.shadow_index])

            role_index = role_index + 1
            self.shadow_index = self.shadow_index + 1

            role:CreateSpriteFrame()
        end

        troop:UpdateFormation()
    end

    self.left_troop.have_leader = false
    self.right_troop.have_leader = false
    local mercenary_list = {}
    if battle_type == BATTLE_TYPE["vs_vanity"] then
        for i, mercenary in ipairs(troop_logic:GetVanityTroop()) do
            if mercenary then
                mercenary_list[i] = mercenary.template_info.sprite
            end
        end
    elseif battle_type == BATTLE_TYPE["vs_vanity_play_back"] then
        for i, mercenary in ipairs(troop_logic:GetVanityBackPlayTroop()) do
            if mercenary then
                mercenary_list[i] = mercenary.template_info.sprite
            end
        end
    else
        for i, mercenary in ipairs(troop_logic:GetFormationMercenaryList()) do
            if mercenary then
                if mercenary.is_leader then
                    self.left_troop.have_leader = true
                end
                mercenary_list[i] = mercenary.template_info.sprite
            end
        end
    end

    self.left_troop.role_num = #mercenary_list

    local cur_music_name = ""

    local num
    local sprite_path = ""
    self.left_troop.name = troop_logic:GetLeaderName()

    local left_max_bp, right_max_bp, left_cur_bp, right_cur_bp, left_shield_bp, right_shield_bp = string.match(property, "(%d+):(%d+)#(%d+):(%d+)#(%d+):(%d+)#")

    local iter = string.gmatch(property, "(-?%d+):(-?%d+):(-?%d+):(-?%d+);")
    local speed1, defense1, dodge1, authority1 = iter()
    local speed2, defense2, dodge2, authority2 = iter()
    local original_speed1, original_defense1, original_dodge1, original_authority1 = iter()
    local original_speed2, original_defense2, original_dodge2, original_authority2 = iter()

    self.left_rune_list = {}
    local rune_iter = string.gmatch(property, "|([%d,]*)")
    for rune_template_id, rune_level in string.gmatch(rune_iter() .. ",", "(%d+),(%d+),") do 
        table.insert(self.left_rune_list, { template_id = tonumber(rune_template_id), level = tonumber(rune_level) })
    end
    self.right_rune_list = {}
    for rune_template_id, rune_level in string.gmatch(rune_iter() .. ",", "(%d+),(%d+),") do 
        table.insert(self.right_rune_list, { template_id = tonumber(rune_template_id), level = tonumber(rune_level) })
    end

    self.left_rune_property = rune_logic:GenerateRuneListPropertys( self.left_rune_list )
    self.right_rune_property = rune_logic:GenerateRuneListPropertys( self.right_rune_list )
 
    local left_cultivation_property = {}
    local cultiv_type = 1
    local cultiv_iter = string.gmatch(property, "^([%d,-]*)")
    for coefficient1, coefficient2 in string.gmatch(cultiv_iter() .. ",", "([%d-]+),([%d-]+),") do 
        left_cultivation_property[cultiv_type] = {["coefficient1"] = coefficient1, ["coefficient2"] = coefficient2}
        cultiv_type = cultiv_type + 1
    end

    local right_cultivation_property = {}
    cultiv_type = 1
    for coefficient1, coefficient2 in string.gmatch(cultiv_iter() .. ",", "([%d-]+),([%d-]+),") do 
        right_cultivation_property[cultiv_type] = {["coefficient1"] = coefficient1, ["coefficient2"] = coefficient2}
        cultiv_type = cultiv_type + 1
    end

    local weapon_iter = string.gmatch(property, "&([%d]*)")
    local left_weapon_info = {}
    local right_weapon_info = {}
    left_weapon_info.weapon_id = tonumber(weapon_iter())
    left_weapon_info.star_level = tonumber(weapon_iter())
    right_weapon_info.weapon_id = tonumber(weapon_iter())
    right_weapon_info.star_level = tonumber(weapon_iter())

    local lethal_iter = string.gmatch(property, "$([%d]*)")
    local left_resist_lethal_num = lethal_iter()
    if left_resist_lethal_num  then
        left_resist_lethal_num = tonumber(left_resist_lethal_num)
    end
    local right_resist_lethal_num = lethal_iter()
    if right_resist_lethal_num then
      right_resist_lethal_num  = tonumber(right_resist_lethal_num)
    end


    local title_iter = string.gmatch(property, "~([%d]*)")
    local left_title_property = {}
    local right_title_property = {}
    left_title_property.title_id = tonumber(title_iter())
    right_title_property.title_id = tonumber(title_iter())

    if battle_type == BATTLE_TYPE["vs_monster"] or 
        battle_type == BATTLE_TYPE["vs_golem"] or 
        battle_type == BATTLE_TYPE["vs_campaign"] or 
        battle_type == BATTLE_TYPE["vs_vanity"] or
        battle_type == BATTLE_TYPE["vs_vanity_play_back"] or
        battle_type == BATTLE_TYPE["vs_guild_boss"] then
        local monster_config = config_manager.monster_config[data]

        num = 0
        for template_id in string.gmatch(monster_config.monster_sprites, "%d+") do
            num = num + 1
            self.monster_sprite_list[num] = tonumber(template_id)
        end

        if battle_type == BATTLE_TYPE["vs_monster"] then
            sprite_path = "res/battle_background/" .. adventure_logic.cur_maze_template_info.scene .. ".png"
            cur_music_name = "maze_battle"

        else
            sprite_path = "res/battle_background/cave.png"
            cur_music_name = "mining_battle"
        end

        self.right_troop.name = monster_config.name

        CreateTroopRole(self.left_troop, mercenary_list)

    elseif battle_type == BATTLE_TYPE["vs_arena_player"] or battle_type == BATTLE_TYPE["vs_ladder_player"] then
        local rival_info = battle_type == BATTLE_TYPE["vs_arena_player"] and arena_logic:GetSingleRivalInfo(data) or ladder_logic:GetChallengingRivalInfo()

        num = #rival_info.template_id_list

        for i = 1, num do
            local rival_info_template_id = rival_info.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"

        self.right_troop.name = rival_info.leader_name

        CreateTroopRole(self.left_troop, mercenary_list)

    elseif battle_type == BATTLE_TYPE["vs_friend"] then
        local rival_info = social_logic:GetRivalInfo()
        num = #rival_info.template_id_list

        for i = 1, num do
            local rival_info_template_id = rival_info.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"

        self.right_troop.name = rival_info.leader_name

        CreateTroopRole(self.left_troop, mercenary_list)

    elseif battle_type == BATTLE_TYPE["vs_guild_player"] then
        local record = guild_logic:GetSingleBattleRecord(data)

        local player1, player2 = record.player1, record.player2

        --我方成员永远显示在左边
        if not guild_logic:IsMyGuildMember(record.player1.user_id) then
            player1, player2 = record.player2, record.player1

            left_max_bp, right_max_bp = right_max_bp, left_max_bp
            left_cur_bp, right_cur_bp = right_cur_bp, left_cur_bp
            left_shield_bp, right_shield_bp =  right_shield_bp, left_shield_bp

            speed1, speed2 = speed2, speed1
            defense1, defense2 = defense2, defense1
            dodge1, dodge2 = dodge2, dodge1
            authority1, authority2 = authority2, authority1

            original_speed1, original_speed2 = original_speed2, original_speed1
            original_defense1, original_defense2 = original_defense2, original_defense1
            original_dodge1, original_dodge2 = original_dodge2, original_dodge1
            original_authority1, original_authority2 = original_authority2, original_authority1

            self.left_rune_list, self.right_rune_list = self.right_rune_list, self.left_rune_list
            self.left_rune_property, self.right_rune_property = self.right_rune_property, self.left_rune_property
            left_cultivation_property, right_cultivation_property = right_cultivation_property, left_cultivation_property
            left_weapon_info, right_weapon_info = right_weapon_info, left_weapon_info
            left_title_property,right_title_property = right_title_property,left_title_property

            left_resist_lethal_num, right_resist_lethal_num = right_resist_lethal_num, left_resist_lethal_num

            self.change_side = true
        end

        self.left_troop.name = player1.leader_name
        self.right_troop.name = player2.leader_name
        if not left_title_property.title_id then
            left_title_property.title_id = 0
        end
        if not right_title_property.title_id then
            right_title_property.title_id = 0
        end

        for i = 1, #player1.template_id_list do
            local template_info = mercenary_config[player1.template_id_list[i]]
            self.monster_sprite_list[i] = template_info.sprite
        end

        self.left_troop.role_num = #player1.template_id_list
        CreateTroopRole(self.left_troop, self.monster_sprite_list)

        for i = 1, #player2.template_id_list do
            local rival_info_template_id = player2.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        num = #player2.template_id_list

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"
    elseif battle_type == BATTLE_TYPE["vs_escort_target"] then
        local rival_info = data

        num = #rival_info.template_id_list

        for i = 1, num do
            local rival_info_template_id = rival_info.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"

        self.right_troop.name = rival_info.leader_name

        CreateTroopRole(self.left_troop, mercenary_list)
    elseif battle_type == BATTLE_TYPE["vs_server_pvp"] then
        local rival_info = data

        num = #rival_info.template_id_list

        for i = 1, num do
            local rival_info_template_id = rival_info.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"

        self.right_troop.name = rival_info.leader_name

        CreateTroopRole(self.left_troop, mercenary_list)
    elseif battle_type == BATTLE_TYPE["vs_mine_rob_target"] then
        local rival_info = data

        num = #rival_info.template_id_list

        for i = 1, num do
            local rival_info_template_id = rival_info.template_id_list[i]
            local template_info = mercenary_config[rival_info_template_id]
            if rival_info_template_id >= 99000001 and rival_info_template_id <= 99999999 then
                self.right_troop.have_leader = true
            end
            self.monster_sprite_list[i] = template_info.sprite
        end

        local r = math.random(1, #client_constants["BATTLE_BACKGROUND"])
        sprite_path = client_constants["BATTLE_BACKGROUND"][r]
        cur_music_name = "arena_battle"

        self.right_troop.name = rival_info.leader_name

        CreateTroopRole(self.left_troop, mercenary_list)
    end

    self.right_troop.role_num = num
    CreateTroopRole(self.right_troop, self.monster_sprite_list)

    for i = self.shadow_index, constants["MAX_FORMATION_CAPACITY"] * 2 do
        self.shadow_nodes[i]:setVisible(false)
    end

    self.skill_name1_text:setVisible(false)
    self.skill_name2_text:setVisible(false)

    self:AdjustSpriteSize(self.background_sprite, sprite_path, cc.rect(0, 0, 320, 578))
    self.background_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    self.old_music = audio_manager:GetCurrentMusic()
    audio_manager:PlayMusic(cur_music_name, true)

    self.battle_type = battle_type
    self.data = data

    self.left_troop:SetProperty(tonumber(left_max_bp), tonumber(left_cur_bp), tonumber(left_shield_bp), self.right_troop, speed1, defense1, dodge1, authority1, original_speed1, original_defense1, original_dodge1, original_authority1)
    self.right_troop:SetProperty(tonumber(right_max_bp), tonumber(right_cur_bp), tonumber(right_shield_bp), self.left_troop, speed2, defense2, dodge2, authority2, original_speed2, original_defense2, original_dodge2, original_authority2)

    self.left_troop:SetCultivation(left_cultivation_property)
    self.right_troop:SetCultivation(right_cultivation_property)

    self.right_troop.title_id = right_title_property.title_id
    self.left_troop.title_id = left_title_property.title_id

    self.left_troop:SetWeaponInfo(left_weapon_info)
    self.right_troop:SetWeaponInfo(right_weapon_info) 

    self.left_troop:CalcDamageFactor()
    self.right_troop:CalcDamageFactor()

    --被动技能免疫死亡
    self.left_troop.resist_lethal_num = left_resist_lethal_num
    self.right_troop.resist_lethal_num = right_resist_lethal_num

    self.scene_action = nil
    self.scene_color_node:clear()

    battle_fragment:Start(record)
    
    self.start_spine_node:setVisible(false)

    self.skill_bp1_spine_node:setVisible(false)
    self.skill_bp2_spine_node:setVisible(false)
    self.skill_name_spine_node:setVisible(false)

    if type(result) == "boolean" then
        self.battle_status = result and client_constants.BATTLE_STATUS["win"] or client_constants.BATTLE_STATUS["lose"]
    else
        self.battle_status = result
    end

    self.ui_root:Show(self.battle_type, self.data, self.left_troop, self.right_troop, self.left_rune_property, self.right_rune_property)
end

function battle_room:Hide()
    self.root_node:setVisible(false)

    if self.old_music then
        audio_manager:PlayMusic(self.old_music, true)
    end

    self.start_spine_node:clearTrack(1)

    self:DestroySprites()
    self:DestroySpineNodes()

    --回收无用贴图
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

function battle_room:Update(elapsed_time)
    if not self.root_node:isVisible() or not battle_fragment.record then
        return
    end

    --不能超过一帧
    elapsed_time = math.min(0.0166667, elapsed_time)

    battle_fragment:LoadNextFragment(self)
    battle_fragment:Update(elapsed_time, self)
end

function battle_room:ShowSkillName(troop_id, skill_name)
    local skill_name_text
    local x, y
    local animation

    if troop_id == LEFT_TROOP_ID then
        skill_name_text = self.skill_name1_text
        skill_name_text:setRotation(15/180 * 3.1415)
        animation = "left"
        x, y = client_constants.BATTLE["left_skill_name_x"], client_constants.BATTLE["left_skill_name_y"]
    else
        skill_name_text = self.skill_name2_text
        animation = "right"
        skill_name_text:setRotation(345/180 * 3.1415)
        x, y = client_constants.BATTLE["right_skill_name_x"], client_constants.BATTLE["right_skill_name_y"]
    end

    self.skill_name_tracker:Bind(animation, x, y, skill_name_text)
    skill_name_text:setString(skill_name)
end

return battle_room
