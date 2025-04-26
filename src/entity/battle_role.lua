local cc = cc

local math_random = math.random
local shader_manager = require "util.shader_manager"
local platform_manager = require "logic.platform_manager"

local battle_role = {
}

battle_role.__index = battle_role

function battle_role.New()
    local t = {
        frames = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
        },
        turn_frames = {},

        color = {},
        origin_opacity = 0,
        origin_color = nil,

        speed_x = 0,
        speed_y = 0,
    }

    setmetatable(t, battle_role)

    return t
end

local BLEND_FUNC = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA }

function battle_role:Init(sprite, image_name, shadow)

    self.sprite = sprite
    local texture_path = string.format("language/%s/role/%s.png", platform_manager:GetLocale(), image_name)
    if not cc.FileUtils:getInstance():isFileExist(texture_path) then
        texture_path = "role/" .. image_name .. ".png"
    end

    self.texture = cc.Director:getInstance():getTextureCache():addImage(texture_path)

    self.texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    self.frame_width = self.texture:getPixelsWide() / 3
    self.frame_height = self.texture:getPixelsHigh() / 4

    self.sprite:setTexture(self.texture)
    self.sprite:setTextureRect(cc.rect(0, 0, self.frame_width, self.frame_height))
    
    local battle_shader = shader_manager:GetProgram("battle_role")
    self.sprite:setGLProgram(battle_shader)
    self.sprite:setBlendFunc(BLEND_FUNC)
    self.sprite:setOpacityModifyRGB(false)

    self.origin_color = self.sprite:getDisplayedColor()
    self.origin_color.r = 0
    self.origin_color.g = 0
    self.origin_color.b = 0

    self.position_x = 0
    self.position_y = 0

    self.color.r = 0
    self.color.g = 0
    self.color.b = 0

    self.origin_opacity = 255

    self.sprite:setColor(self.color)
    self.sprite:setOpacity(self.origin_opacity)
    self.sprite:setScale(2, 2)

    self.sprite:setVisible(true)
    if shadow then
        self.shadow = shadow
        shadow:setOpacity(255)
        shadow:setVisible(true)
    end

    self.cur_animation = nil
    self.vibration_freq = 0
end

function battle_role:GetSprite()
    return self.sprite
end

function battle_role:Clear()
    if not self.sprite then
        return
    end

    self.sprite:removeFromParent()

    self.sprite = nil
end

--create sprite frames
function battle_role:CreateSpriteFrame(flip)
    for i = 1, 4 do
        --行
        for j = 1, 3 do
            local rect

            local old_rect = self.frames[i][j]
            if not old_rect then
                rect = cc.rect(0, 0, self.frame_width, self.frame_height)

            else
                rect = old_rect
            end

            -- 列
            rect.x = (j - 1) * self.frame_width
            rect.y = (i - 1) * self.frame_height
            rect.height = self.frame_height
            rect.width = self.frame_width

            self.frames[i][j] = rect
        end
    end

    if flip then
        self.turn_frames[1] = self.frames[2][1]
        self.turn_frames[2] = self.frames[1][1]
        self.turn_frames[3] = self.frames[3][1]
        self.turn_frames[4] = self.frames[4][1]

    else
        self.turn_frames[1] = self.frames[3][1]
        self.turn_frames[2] = self.frames[1][1]
        self.turn_frames[3] = self.frames[2][1]
        self.turn_frames[4] = self.frames[4][1]
    end
end

function battle_role:ChangeToNextFrame()
    self.cur_frame_index = self.cur_frame_index + 1
    if self.cur_frame_index > self.max_animation_frame then
        self.cur_frame_index = 1
    end

    self.sprite:setTextureRect(self.cur_animation[self.cur_frame_index])
end

function battle_role:WalkAnimation(direction, time)
    self.time_delta = 0

    self.cur_frame_index = 0
    self.max_animation_frame = #self.frames[direction]
    self.cur_animation = self.frames[direction]
    self.time_per_frame = time or 0.2
end

--turn around
function battle_role:TurnAroundAnimation(time)
    self.time_delta = 0

    self.cur_frame_index = 0
    self.max_animation_frame = #self.turn_frames
    self.cur_animation = self.turn_frames
    self.time_per_frame = time or 0.2
end

function battle_role:Update(elapsed_time)
    if self.cur_animation then
        self.time_delta = self.time_delta + elapsed_time

        if self.time_delta > self.time_per_frame then
            self.time_delta = 0
            self:ChangeToNextFrame()
        end
    end

    --振动
    if self.vibration_freq > 0 then
        self.vibration_duration = self.vibration_duration + elapsed_time
        if self.vibration_duration >= self.vibration_freq then
            self.vibration_duration = 0

            self.vx = (math_random(1, 100) / 100 - 0.5) * self.vibration_x
            self.vy = (math_random(1, 100) / 100 - 0.5) * self.vibration_y
        end
    end
end

--set position
function battle_role:SetPosition(x, y)
    self.position_x = x
    self.position_y = y

    self.sprite:setPosition(x, y)
end

--带振动
function battle_role:SetPositionEx(x, y, vx, vy)
    self.position_x = x
    self.position_y = y

    self.sprite:setPosition(x + vx, y + vy)
end

--
function battle_role:GetPosition()
    return self.position_x, self.position_y
end

--set scale
function battle_role:SetScale(x, y)
    self.sprite:setScale(x, y)
end

--set speed
function battle_role:SetSpeed(speed)
    self.speed = speed
end

function battle_role:SetOpacity(opacity)
    self.sprite:setOpacity(opacity * 255)

    if self.shadow then
        self.shadow:setOpacity(opacity * 255)
    end
end

function battle_role:GetOpacity()
    return self.sprite:getOpacity()
end

function battle_role:SetColor(r, g, b)
    self.color.r = r
    self.color.g = g
    self.color.b = b

    self.sprite:setColor(self.color)
end

function battle_role:ResetColorAndOpacity()
    self.sprite:setColor(self.origin_color)
    self.sprite:setOpacity(self.origin_opacity)

    if self.shadow then
        self.shadow:setOpacity(self.origin_opacity)
    end
end

function battle_role:SetShadowPosition(x, y)
    self.shadow:setPosition(x, y)
end

function battle_role:SetVibration(action)
    --振动频率
    self.vibration_freq = action.vibration_freq / 1000
    self.vibration_duration = 0
    self.vx = 0
    self.vy = 0

    self.vibration_x = action.vibration_x
    self.vibration_y = action.vibration_y
end

function battle_role:GetVibrationOffset()
    local vx, vy = self.vx, self.vy
    self.vx, self.vy = 0, 0

    return vx, vy
end

return battle_role

