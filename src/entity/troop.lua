local config_manager = require "logic.config_manager"
local skill_manager = require "logic.skill_manager"
local client_constants = require "util.client_constants"
local constants = require "util.constants"

local CONST_BATTLE = client_constants.BATTLE

local DEATH_ACTION = CONST_BATTLE["death_action"]
local VICTORY_ACTION = CONST_BATTLE["victory_action"]

local LEFT_TROOP_ID = CONST_BATTLE["left_troop_id"]
local RIGHT_TROOP_ID = CONST_BATTLE["right_troop_id"]

local ROW_GAP, COL_GAP = CONST_BATTLE["row_gap"], CONST_BATTLE["col_gap"]

local ROLE_SHADOW_SCALE = CONST_BATTLE["role_shadow_scale"]
local ROLE_SHADOW_OFFSET = CONST_BATTLE["role_shadow_offset"]

local WALK_ANIMATION_TIME = 0.1

local SPEED_FACTOR = skill_manager.SPEED_FACTOR
local DODGE_FACTOR = skill_manager.DODGE_FACTOR
local AUTHORITY_FACTOR = skill_manager.AUTHORITY_FACTOR

local math = math
local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil
local bit_rshift = bit.rshift
local bit_band = bit.band

--方向朝向
local DIRECTION =
{
    ["none"] = 0,
    ["front"] = 1,
    ["down"] = 2,
    ["back"] = 3,
    ["up"] = 4,
    ["center"] = 5,
}

local troop = {}
troop.__index = troop

function troop.New(id)
    local t = {
        id = id,

        battle_point = 0,

        speed = 0,
        dodge = 0,
        defense = 0,
        authority = 0,

        original_speed = 0,
        original_dodge = 0,
        original_defense = 0,
        original_authority = 0,

        cur_bp = 0,
        max_bp = 0,

        roles = {},
        role_num = 0,

        init_position_xs = {},--初始坐标x
        init_position_ys = {},--初始坐标y

        is_play_action = false,

        center_x = 0,
        center_y = 0,

        effect_x = 0, --特效播放坐标
        effect_y = 0,

        role_num_per_col = {0, 0, 0, 0}
    }

    return setmetatable(t, troop)
end

function troop:SetProperty(max_bp, cur_bp, enemy, speed, defense, dodge, authority, original_speed, original_defense, original_dodge, original_authority)
    self.speed = tonumber(speed)
    self.defense = tonumber(defense)
    self.dodge = tonumber(dodge)
    self.authority = tonumber(authority)

    self.original_speed = tonumber(original_speed)
    self.original_defense = tonumber(original_defense)
    self.original_dodge = tonumber(original_dodge)
    self.original_authority = tonumber(original_authority)

    self.cur_bp = cur_bp
    self.max_bp = max_bp

    self.enemy = enemy

    self.exhaust_turn = 0

    self.last_turn_skill = nil
end

function troop:CalcDamageFactor()
    self.defense = math.max(self.defense, -50)
    self.dodge = math.max(self.dodge, -50)
    self.speed = math.max(self.speed, -50)

    self.damage_reduction_factor = 100 / (100 + self.defense)
    self.dodge_chance = math.ceil(self.dodge / (100 + self.dodge) * 100)
    
    self.final_damage_modifier = self.authority > self.enemy.authority and 1 + (self.authority - self.enemy.authority) * AUTHORITY_FACTOR or 1.0

    self.bp_increase_factor = 1 + DODGE_FACTOR * self.dodge
end

function troop:SetRolePosition(i, x, y)
    local role = self.roles[i]

    role:SetPosition(x, y)
    role:SetShadowPosition(x, y - ROLE_SHADOW_OFFSET)
    role.shadow:setScaleX(1.0)

    self.init_position_xs[i] = x
    self.init_position_ys[i] = y
end

local POSITION_MAP = 
{
    { 1 },
    { 2, 3, 14, 15, 20, 21, 24, 25 },
    { 4, 5, 6, 7, 16, 17, 22, 23 },
    { 8, 9, 10, 11, 12, 13, 18, 19 },
}

--更新阵型
function troop:UpdateFormation()
    local col_num = 0
    if self.role_num == 1 then
        col_num = 1
    elseif self.role_num <= 3 then
        col_num = 2

    elseif self.role_num <= 7 then
        col_num = 3
    else
        col_num = 4
    end

    local init_x, init_y = 0, 0
    if self.id == LEFT_TROOP_ID then
        init_x = CONST_BATTLE["left_troop_x"] + (col_num - 4) * CONST_BATTLE["troop_offset_x"]
        init_y = CONST_BATTLE["left_troop_y"]
        --军团中心点
        self.center_x = init_x - COL_GAP * 1.5
        --特效播放点
        self.effect_x = init_x - COL_GAP * 0.5
    else
        init_x = CONST_BATTLE["right_troop_x"] + (4 - col_num) * CONST_BATTLE["troop_offset_x"]
        init_y = CONST_BATTLE["right_troop_y"]
        --军团中心点
        self.center_x = init_x + COL_GAP * 1.5
        --特效播放点
        self.effect_x = init_x + COL_GAP * 0.5
    end

    self.center_y = init_y
    self.effect_y = init_y

    --统计每排的人数
    for col = 1, col_num do
        self.role_num_per_col[col] = 0
        local map = POSITION_MAP[col]
        
        for j = 1, #map do
            if map[j] <= self.role_num then
                self.role_num_per_col[col] = self.role_num_per_col[col] + 1
            else
                break
            end
        end
    end

    local roles = self.roles
    for col = 1, col_num do
        local map = POSITION_MAP[col]
        local role_num = self.role_num_per_col[col]

        local x, y = init_x, init_y
        if role_num % 2 == 0 then
            for i = 1, role_num do
                local role_index = map[i]
                local role = roles[role_index]

                if i % 2 == 0 then
                    --偶数站上面
                    self:SetRolePosition(role_index, x, y + ROW_GAP * ( math_floor(i/2) - 0.5))
                    role.sprite:setLocalZOrder(150 - i)
                    role.shadow:setLocalZOrder(150 - i)
                else
                    self:SetRolePosition(role_index, x, y - ROW_GAP * ( math_floor(i/2) + 0.5))
                    role.sprite:setLocalZOrder(150 + i)
                    role.shadow:setLocalZOrder(150 + i)
                end
            end

        else

            self:SetRolePosition(map[1], x, y)
            for i = 2, role_num do
                local role_index = map[i]
                local role = roles[role_index]

                if i % 2 == 0 then
                    --偶数站上面
                    self:SetRolePosition(role_index, x, y + ROW_GAP * math_floor(i/2))
                    role.sprite:setLocalZOrder(150 - i)
                    role.shadow:setLocalZOrder(150 - i)
                else
                    self:SetRolePosition(role_index, x, y - ROW_GAP * math_floor(i/2))
                    role.sprite:setLocalZOrder(150 + i)
                    role.shadow:setLocalZOrder(150 + i)
                end
            end
        end

        if self.id == LEFT_TROOP_ID then
            init_x = init_x - COL_GAP
        else
            init_x = init_x + COL_GAP
        end
    end
   
    self.is_play_final_action = false
    self:StopPlayAction()
end

function troop:SetAction(action)
    self.cur_action = action

    --剩余时间, 单位秒
    self.remain_time = (action.time + math_random(0, action.time_offset * 2) - action.time_offset) / 1000

    self.total_time = self.remain_time

    --已运行过的时间
    self.action_duration = 0

    self.action_end_time = action.end_time / 1000

    --转身频率
    self.turn_around_freq = action.turn_around_freq / 1000

    --颜色
    self.init_r = bit_band(bit_rshift(action.init_color, 16), 0xff) * action.init_color_alpha
    self.init_g = bit_band(bit_rshift(action.init_color, 8), 0xff) * action.init_color_alpha
    self.init_b = bit_band(action.init_color, 0xff) * action.init_color_alpha

    self.end_r = bit_band(bit_rshift(action.end_color, 16), 0xff) * action.end_color_alpha
    self.end_g = bit_band(bit_rshift(action.end_color, 8), 0xff) * action.end_color_alpha
    self.end_b = bit_band(action.end_color, 0xff) * action.end_color_alpha

    --归位操作
    if action.is_reset_pos then
        local init_position_xs, init_position_ys = self.init_position_xs, self.init_position_ys
        for i = 1, self.role_num do
            local role = self.roles[i]

            role.speed_x = (init_position_xs[i] - role.position_x ) / self.total_time
            role.speed_y = (init_position_ys[i] - role.position_y) / self.total_time

            if self.cur_action.is_turn_around then
                role:TurnAroundAnimation(self.turn_around_freq)
            else
                role:WalkAnimation(1, WALK_ANIMATION_TIME)
            end

            role:SetVibration(action)
        end
    else

        for i = 1, self.role_num do
            local delta = 0
            local speed_x, speed_y = 0, 0

            --计算x轴和y轴方向上的速度
            if action.move_distance ~= 0 then
                delta = (action.move_distance + math_random(0, action.move_offset * 2) - action.move_offset) / self.remain_time
            end

            if action.move_direction == DIRECTION["up"] then
                speed_y = delta

            elseif action.move_direction == DIRECTION["down"] then
                speed_y = -delta

            elseif action.move_direction == DIRECTION["front"] then
                speed_x = self.id == LEFT_TROOP_ID and delta or -delta

            elseif action.move_direction == DIRECTION["back"] then
                speed_x = self.id == LEFT_TROOP_ID and -delta or delta

            elseif action.move_direction == DIRECTION["center"] then
                speed_x = delta
                speed_y = delta
            end

            local role = self.roles[i]
            role.speed_x = speed_x
            role.speed_y = speed_y

            if self.cur_action.is_turn_around then
                role:TurnAroundAnimation(self.turn_around_freq)

            elseif action.move_direction == DIRECTION["front"] then
                role:WalkAnimation(self.id == LEFT_TROOP_ID and 3 or 2, WALK_ANIMATION_TIME)
            end
            role:SetVibration(action)
        end
    end
end

function troop:GetVibrationOffset(elapsed_time)
    local vx, vy = 0, 0
    if self.vibration_freq > 0 then

        self.vibration_duration = self.vibration_duration + elapsed_time
        if self.vibration_duration >= self.vibration_freq then
            self.vibration_duration = 0

            vx = (math_random(1, 100) / 100 - 0.5) * self.cur_action.vibration_x
            vy = (math_random(1, 100) / 100 - 0.5) * self.cur_action.vibration_y
        end
    end

    return vx, vy
end

function troop:Update(elapsed_time)
    for i = 1, self.role_num do
        self.roles[i]:Update(elapsed_time)
    end

    if not self.is_play_action then
        return
    end

    if self.remain_time > 0 then
        self.remain_time = math.max(0, self.remain_time - elapsed_time)
        self.action_duration = math.min(self.action_duration + elapsed_time, self.total_time)

        --颜色混合
        local duration_percent = self.action_duration / self.total_time
        local blend_mode = self.cur_action.blend_mode
        local r, g, b = 255, 255, 255

        if blend_mode == 2 then
            --缓慢变色
            if self.cur_action.init_color ~= 0 then
                r = math.max(self.init_r + (self.end_r - self.init_r) * duration_percent, 0)
                g = math.max(self.init_g + (self.end_g - self.init_g) * duration_percent, 0)
                b = math.max(self.init_b + (self.end_b - self.init_b) * duration_percent, 0)

            else
                r = self.end_r * duration_percent
                g = self.end_g * duration_percent
                b = self.end_b * duration_percent
            end

        elseif blend_mode == 1 then
            --立即变色
            r, g, b = self.end_r, self.end_g, self.end_b
        end

        --透明度
        local alpha = 1
        if self.cur_action.seq_action_id == 0 then
            alpha = 1 - (1 - self.cur_action.end_role_alpha) * self.action_duration / self.total_time

        elseif blend_mode ~= 0 then
            alpha = self.cur_action.init_role_alpha + (self.cur_action.end_role_alpha - self.cur_action.init_role_alpha) * (blend_mode == 1 and 1 or self.action_duration / self.total_time)
        end

        --2dx 在存储透值时用的byte, 为了避免溢出，必须检测是否小于0
        if alpha < 0 then
            alpha = 0
        end

        --跳跃高度
        local jump_height = self:GetJumpHeight()
        local max_jump_height = self.cur_action.jump_height

        --更新位置
        if self.cur_action.move_direction == DIRECTION["center"] then
            --围绕中心移动
            local center_x, center_y = self.center_x, self.center_y
            local move_damping = self.cur_action.move_damping
            local random_angle = self.cur_action.random_angle

            for i = 1, self.role_num do
                local role = self.roles[i]
                local x, y = role:GetPosition()

                local sx = math.abs(x - center_x) / COL_GAP * move_damping
                local sy = math.abs(y - center_y) / ROW_GAP * move_damping

                sx = math.max(1 - sx, 0)
                sy = math.max(1 - sy, 0)

                local align = math.atan2(y - center_y, x - center_x)
                align = align + (math_random(1, 100) / 100 - 0.5) * random_angle / 180 * 3.1415926

                local ax = role.speed_x * elapsed_time * math.cos(align) * sx
                local ay = role.speed_y * elapsed_time * math.sin(align) * sy

                if self.id == RIGHT_TROOP_ID then
                    ax = -ax
                end

                local vx, vy = role:GetVibrationOffset()
                role:SetPositionEx(x + ax, y + ay, vx, vy + jump_height)

                --调整阴影大小和位置
                if max_jump_height > 0 then
                    local shadow_scale = 1 - (jump_height / max_jump_height * ROLE_SHADOW_SCALE)
                    role.shadow:setScaleX(shadow_scale)
                end
                role:SetShadowPosition(x + ax + vx, y + ay + vy - ROLE_SHADOW_OFFSET)

                if blend_mode ~= 0 then
                    role:SetOpacity(alpha)
                    role:SetColor(r, g, b)
                end
            end

        else
            for i = 1, self.role_num do
                local role = self.roles[i]
                local x, y = role:GetPosition()
                local vx, vy = role:GetVibrationOffset()

                x = x + role.speed_x * elapsed_time
                y = y + role.speed_y * elapsed_time

                role:SetPositionEx(x, y, vx, vy + jump_height)

                --调整阴影大小和位置
                if max_jump_height > 0 then
                    local shadow_scale = 1 - (jump_height / max_jump_height * ROLE_SHADOW_SCALE)
                    role.shadow:setScaleX(shadow_scale)
                end
                role:SetShadowPosition(x + vx, y + vy - ROLE_SHADOW_OFFSET)

                if blend_mode ~= 0 then
                    role:SetOpacity(alpha)
                    role:SetColor(r, g, b)
                end
            end
        end

    else
        if self.action_end_time > 0 then
            self.action_end_time = self.action_end_time - elapsed_time

        else
            --切换到下一个动作
            self:ChangeToSequentAction()

            if not self.cur_action then
                if not self.is_play_final_action then
                    --终结动作不需要重置颜色
                    for i = 1, self.role_num do
                        self.roles[i]:ResetColorAndOpacity()
                    end
                else

                end
                self.is_play_action = false
                self.is_play_final_action = false
            end
        end
    end
end

function troop:ResetColorAndOpacity()
    for i = 1, self.role_num do
        self.roles[i]:ResetColorAndOpacity()
    end
end

function troop:GetJumpHeight()
    local jump_type = self.cur_action.jump_type
    local jump_height = self.cur_action.jump_height
    local total_time = self.total_time
    if jump_type == 1 then
        --浮起
        return self.action_duration / total_time * jump_height

    elseif jump_type == 2 then
        --跳起降落
        if self.action_duration * 2 <= total_time then
            return 2 * self.action_duration / total_time * jump_height
        else
            return jump_height - (self.action_duration - total_time * 0.5) * 2 / total_time * jump_height
        end

    elseif jump_type == 3 then
        --降落
        return -(jump_height - jump_height / total_time * jump_height)
    end

    return 0
end

function troop:ChangeToSequentAction()
    if self.cur_action.seq_action_id == 0 then
        self.cur_action = nil
        return
    end

    local seq_action = config_manager.role_action[self.cur_action.seq_action_id]
    self:SetAction(seq_action)
end

function troop:PlayDeathAction()
    self.is_play_action = true
    self.is_play_final_action = true
    self:SetAction(config_manager.role_action[DEATH_ACTION])
end

function troop:PlayVictoryAction()
    self.is_play_action = true
    self.is_play_final_action = true
    self:SetAction(config_manager.role_action[VICTORY_ACTION])
end

function troop:IsPlayAction()
    return self.is_play_action
end

function troop:StartPlayAction(action)
    self.is_play_action = true
end

function troop:StopPlayAction()
    self.is_play_action = false

    for i = 1, self.role_num do
        self.roles[i]:WalkAnimation(1, WALK_ANIMATION_TIME)
    end
end

function troop:UseSkill(skill, is_dodge)

    local turn_fixed = 0

    self.enemy.damage_reduction_factor = skill.ignore_defense and 1.0 or (100 / (100 + self.enemy.defense))

    local effect_method = skill_manager:GetEffect(skill.effect_type)
    local real_skill = effect_method(self, self.enemy, skill, is_dodge)

    --需要考虑复制技能
    real_skill = real_skill or skill

    -- 触发附加技能效果
    local trigger_addon_effect = true
    if real_skill.need_hit == 1 and is_dodge then
        trigger_addon_effect = false
    end

    if trigger_addon_effect then
        if real_skill.exhaust_turn > 0 then
            self.enemy.exhaust_turn = math.max(self.enemy.exhaust_turn, real_skill.exhaust_turn)
        end

        if real_skill.turn_fixed then
            turn_fixed = real_skill.turn_fixed
        end

        -- 敌方四维变化
        if #real_skill.enemy_property_map > 0 then
            local map = real_skill.enemy_property_map
            self.enemy.speed = self.enemy.speed + map[1]
            self.enemy.defense = self.enemy.defense + map[2]
            self.enemy.dodge = self.enemy.dodge + map[3]
            self.enemy.authority = self.enemy.authority + map[4]
            self.enemy:CalcDamageFactor()
        end

        -- 我方四维变化
        if #real_skill.self_property_map > 0 then
            local map = real_skill.self_property_map
            self.speed = self.speed + map[1]
            self.defense = self.defense + map[2]
            self.dodge = self.dodge + map[3]
            self.authority = self.authority + map[4]
            self:CalcDamageFactor()
        end
    end

    self.exhaust_turn = math.max(0, self.exhaust_turn - 1)
    self.last_turn_skill = real_skill

    return turn_fixed
end

return troop
