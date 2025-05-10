local platform_manager = require "logic.platform_manager"

local cc = cc
local ui_role = {
}

ui_role.__index = ui_role

function ui_role.New()
    local t = {
        frames = {},
        turn_frames = {},
        speed = 0,
        direction = 1,

        speed_x = 0,
        speed_y = 0,
    }

    setmetatable(t, ui_role)

    return t
end

function ui_role:Init(sprite, image_name)
    self.sprite = sprite
    local sprite_path = string.format("language/%s/role/%s.png", platform_manager:GetLocale(), image_name)
    if not cc.FileUtils:getInstance():isFileExist(sprite_path) then
        sprite_path = "role/" .. image_name .. ".png"
    end

    self.texture_cache = cc.Director:getInstance():getTextureCache():addImage(sprite_path)

    self.texture_cache:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

    self.frame_width = self.texture_cache:getPixelsWide() / 3
    self.frame_height = self.texture_cache:getPixelsHigh() / 4

    self.sprite:setTexture(self.texture_cache)
    self.sprite:setTextureRect(cc.rect(0, 0, self.frame_width, self.frame_height))

    self.sprite:setScale(2, 2)

    self.sprite:setVisible(true)

    self:CreateSpriteFrame()
end

--return sprite object
function ui_role:GetSprite()
    return self.sprite
end

function ui_role:Clear()
    if not self.sprite then
        return
    end

    self.sprite:removeFromParent()

    self.sprite = nil
end

--create sprite frames
function ui_role:CreateSpriteFrame()
    --未做精灵帧缓存
    local rect = cc.rect(0, 0, self.frame_width, self.frame_height)
    for i = 1, 4 do  --行
        self.frames[i] = {}
        for j = 1, 4 do  -- 列

            if j == 4 then
                rect.x = (2 - 1) * self.frame_width
            else
                rect.x = (j - 1) * self.frame_width
            end
            rect.y = (i - 1) * self.frame_height

            local old_frame = self.frames[i][j]
            if old_frame then
                old_frame:release()
            end

            --创建SpriteFrame类
            self.frames[i][j]= cc.SpriteFrame:createWithTexture(self.texture_cache, rect)
            self.frames[i][j]:retain()
        end
    end
end

--play frames animation ,direction represent sprite's direction
function ui_role:WalkAnimation(direction, time)
    --the animation cache was not done
    self.walk_animation = cc.Animation:createWithSpriteFrames(self.frames[direction], time or 0.2)
    self.walk_animate = cc.Animate:create(self.walk_animation)

    if self.walk_animate_forever then
       self.sprite:stopAction(self.walk_animate_forever)
    end

    self.walk_animate_forever = cc.RepeatForever:create(self.walk_animate)
    self.sprite:runAction(self.walk_animate_forever)

    return self.walk_animate_forever
end

--set position
function ui_role:SetPosition(x, y)
    self.sprite:setPosition(x, y)
end

function ui_role:GetPosition()
    return self.sprite:getPosition()
end

--set scale
function ui_role:SetScale(x, y)
    self.sprite:setScale(x, y)
end

function ui_role:SetOpacity(opacity)
    self.sprite:setOpacity(opacity * 255)
end

function ui_role:GetOpacity()
    return self.sprite:getOpacity()
end

function ui_role:SetColor(r, g, b)
    --self.sprite:setColor(self.color)
end

return ui_role

