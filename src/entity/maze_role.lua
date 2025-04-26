local cc = cc
local maze_role = {
}

local platform_manager = require "logic.platform_manager"

maze_role.__index = maze_role

function maze_role.New()
    local t = {
        frames = {},
        turn_frames = {},
        speed = 0,
        direction = 1,

        position = cc.p(0, 0),
    }

    setmetatable(t, maze_role)

    return t
end

function maze_role:Init(sprite, image_name, shadow)
    --在texture文件中 去获取图片纹理缓存
    self.sprite = sprite
    local sprite_path = string.format("language/%s/role/%s.png", platform_manager:GetLocale(), image_name)
    if not cc.FileUtils:getInstance():isFileExist(sprite_path) then
        sprite_path = "role/" .. image_name .. ".png"
    end

    self.texture = cc.Director:getInstance():getTextureCache():addImage(sprite_path)

    if not self.texture then
        print(self.sprite)
    end

    self.texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    self.frame_width = self.texture:getPixelsWide() / 3
    self.frame_height = self.texture:getPixelsHigh() / 4

    self.sprite:setTexture(self.texture)
    self.sprite:setTextureRect(cc.rect(0, 0, self.frame_width, self.frame_height))
    self.sprite:setScale(2, 2)

    if shadow then
        self.shadow = shadow
    end

    self:SetVisible(true)

    self.cur_animation = nil
    self:CreateSpriteFrame()
end

--return sprite object
function maze_role:GetSprite()
    return self.sprite
end

function maze_role:Clear()
    if not self.sprite then
        return
    end

    self.sprite:removeFromParent()

    self.sprite = nil
end

--create sprite frames
function maze_role:CreateSpriteFrame()
    --未做精灵帧缓存
    for i = 1, 4 do
        self.frames[i] = {} or self.frames[i]

        for j = 1, 4 do
            local old_rect = self.frames[i][j]
            if not old_rect then
                rect = cc.rect(0, 0, self.frame_width, self.frame_height)

            else
                rect = old_rect
            end

            if j == 4 then
                rect.x = (2 - 1) * self.frame_width
            else
                rect.x = (j - 1) * self.frame_width
            end

            rect.y = (i - 1) * self.frame_height
            rect.height = self.frame_height
            rect.width = self.frame_width

            self.frames[i][j] = rect
        end
    end

    self.turn_frames = {
        [1] = self.frames[3][1],
        [2] = self.frames[1][1],
        [3] = self.frames[2][1],
        [4] = self.frames[4][1],
    }
end

--play frames animation ,direction represent sprite's direction
function maze_role:WalkAnimation(direction, time)
    self.time_delta = 0

    self.cur_frame_index = 0
    self.max_animation_frame = #self.frames[direction]
    self.cur_animation = self.frames[direction]
    self.time_per_frame = time or 0.2
    self.is_loop_animation = true

    self.turn_around_callback = nil
end

--turn around
function maze_role:TurnAroundAnimation(time, is_loop, call_back)
    self.is_loop_animation = is_loop

    self.time_delta = 0

    self.cur_frame_index = 0
    self.max_animation_frame = #self.turn_frames
    self.cur_animation = self.turn_frames
    self.time_per_frame = time or 0.2

    self.turn_around_callback = call_back
end

function maze_role:Update(elapsed_time)
    if self.cur_animation then
        self.time_delta = self.time_delta + elapsed_time

        if self.time_delta > self.time_per_frame then
            self.time_delta = 0
            local is_complete = self:ChangeToNextFrame()

            if self.turn_around_callback and is_complete then
                self.turn_around_callback()
                self.turn_around_callback = nil
            end
        end
    end
end

function maze_role:ChangeToNextFrame()
    local is_animation_complete = false

    self.cur_frame_index = self.cur_frame_index + 1
    if self.cur_frame_index > self.max_animation_frame then
        self.cur_frame_index = 1
        is_animation_complete = true

    end

    self.sprite:setTextureRect(self.cur_animation[self.cur_frame_index])

    return is_animation_complete
end

--set position
function maze_role:SetPosition(x, y)
    self.position.x = x
    self.position.y = y

    self.sprite:setPosition(self.position)
end

--
function maze_role:GetPosition()
    return self.sprite:getPositionX(), self.sprite:getPositionY()
end

function maze_role:GetPositionX()
    return self.sprite:getPositionX()
end

function maze_role:GetPositionY()
    return self.sprite:GetPositionY()
end

--set scale
function maze_role:SetScale(x, y)
    self.sprite:setScale(x, y)
end
--set speed
function maze_role:SetSpeed(speed)
    self.speed = speed
end

function maze_role:SetOpacity(opacity)
    self.sprite:setOpacity(opacity * 255)
end

function maze_role:GetOpacity()
    return self.sprite:getOpacity()
end

function maze_role:SetVisible(is_visible)
    if self.sprite then
        self.sprite:setVisible(is_visible)
    end

    if self.shadow then
        self.shadow:setVisible(is_visible)
    end
end

function maze_role:SetShadowPosition(x, y)
    self.shadow:setPosition(x, y)
end

function maze_role:SetShadowScale(x, y)
    self.shadow:setScale(x, y)
end

return maze_role
