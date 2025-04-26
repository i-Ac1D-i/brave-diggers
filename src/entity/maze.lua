local config_manager = require "logic.config_manager"
local adventure_logic = require "logic.adventure"
local troop_logic = require "logic.troop"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local shader_manager = require "util.shader_manager"

local VISIBLE_SIZE_WIDTH = cc.Director:getInstance():getVisibleSize().width
local VISIBLE_SIZE_HIGHT =  cc.Director:getInstance():getVisibleSize().height

local math_random = math.random

local MAZE_ZORDER = client_constants.ADVENTURE_MAZE_ZORDER

local EXP_SPINE_NODE_NUM = 3
local MONSTER_NUM = 10
local SHOW_MERCENARY_MAX_NUM = 5
local MAZE_BG_NUM = 4
local MERCENARY_INTERVAL = 60

local MERCENARY_BEGIN_X = 280
local MERCENARY_BEGIN_Y = 52

local MONSTER_END_X = MERCENARY_BEGIN_X + MERCENARY_INTERVAL * 1.5
local MONSTER_END_Y = 52

local MAZE_BG_SCALE = 2

local MAZE_BG_POSITION =
{
    ["layer1"] = 1,
    ["layer21"] = 297,
    ["layer22"] = 117,
    ["layer3"] = 336,
    ["layer4"] = 1,
    ["layer5"] = 336,
}

local MAZE_BG_ANCHOR =
{
    0,
    1,
    1,
    0,
    1
}

--maze bg velocity
local MAZE_BG_VELOCITY = {
    [1] = 2,
    [2] = 1,
    [3] = 1,
    [4] = 1,
}

local MAZE_BG_START_X = 610
local MAZE_BG_WIDTH =
{
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
}

--monster start pos
local RANDOM_MONSTER_START_MAX_POS_X = 800

--monster walk velocity
local RANDOM_MONSTER_WALK_MIN_VELOCITY_X = 60
local RANDOM_MONSTER_WALK_MIN_VELOCITY_Y = 100

--monster fly velocity
local RANDOM_MONSTER_FLY_MIN_VELOCITY_X = 50
local RANDOM_MONSTER_FLY_MAX_VELOCITY_X = 100

local RANDOM_MONSTER_FLY_MIN_VELOCITY_Y = 50
local RANDOM_MONSTER_FLY_MAX_VELOCITY_Y = 320

--monster fly accelerated
local MONSTER_FLY_ACCELERATED_Y = -200

--monster shake offset
local MONSTER_SHAKE_OFFSET_X = 5
--monster shake time
local MONSTER_SHAKE_TIME = 0.8

--turn around time
local TURN_AROUNG_TIME = 0.2

--mercenary 动作
local MERCENARY_ACTION = {
    ["walk"]  = 1,
    ["jump"]  = 2,
    ["grossip"] = 3,
    ["change_role"] = 4,
    ["turn_around"] = 5,
}
--mercenary 动作时间
local RANDOM_MERCENARY_ACTION_MIN_TIME = 3
local RANDOM_MERCENARY_ACTION_MAX_TIME = 8

local SHADOW_PATH = "bg/maze_role_shadow_d.png"

local maze_component = {}
maze_component.__index = maze_component

--setmetatable
function maze_component.New()
    return setmetatable({}, maze_component)
end

function maze_component:Init(root_node)
    self.root_node = root_node

    self.maze_bg_sprites = {}

    self.maze_layer1_sprites = {}

    self.monster_roles = {}
    self.mercenary_roles = {}

    --保存mercenary的image
    self.mercenary_images = {}

    self.monsters_images = {}

    --阴影
    self.shadow_batch_node = cc.SpriteBatchNode:create("res/ui/ui.png", SHOW_MERCENARY_MAX_NUM + MONSTER_NUM)
    self.root_node:addChild(self.shadow_batch_node, MAZE_ZORDER["shadow"])

    self.shadow_nodes = {}

    local n = SHOW_MERCENARY_MAX_NUM + MONSTER_NUM
    for i = 1, n do
        local node = cc.Sprite:createWithSpriteFrameName(SHADOW_PATH)
        node:setScale(2.0, 2.0)
        node:setAnchorPoint(cc.p(0.5, 0.4))
        self.shadow_nodes[i] = node
        self.shadow_batch_node:addChild(node)
    end

    self.mercenary_shadow_index = 0
    self.monster_shadow_index = SHOW_MERCENARY_MAX_NUM

    self:CreateMazeBgSprite()
    self:CreateMonsterSprites()
    self:CreateMercenarySprites()

    self.has_load_mercenary = false
    self.start_random_mercenary_action_flag = false
end

--创建5个mercenary sprite
function maze_component:CreateMercenarySprites()
    local MERCENARY_ZORDER = MAZE_ZORDER["mercenary_and_monster"]

    self.mercenary_sprites = {}

    local p = cc.p(0.5, 0)

    for i = 1, SHOW_MERCENARY_MAX_NUM  do
        local mercenary_sprite = cc.Sprite:create()
        mercenary_sprite:setAnchorPoint(p)

        local mercenary_pos_x = MERCENARY_BEGIN_X - (i - 1) * MERCENARY_INTERVAL
        local mercenary_pos_y = MERCENARY_BEGIN_Y

        mercenary_sprite:setPosition(mercenary_pos_x, mercenary_pos_y)
        self.root_node:addChild(mercenary_sprite, MERCENARY_ZORDER)

        self.mercenary_sprites[i] = mercenary_sprite
    end
end

function maze_component:SetLoadMercenaryflag(flag)
    self.has_load_mercenary = flag
end

--创建mercenary role
function maze_component:LoadAllMercenaryRoles()
    if self.has_load_mercenary then
        return
    end

    self.exploring_mercenary_list = troop_logic:GetFormationMercenaryList(troop_logic:GetClientFormationId())
    self.exploring_mercenary_num = #self.exploring_mercenary_list

    --保存出站队员的image
    for i = 1, self.exploring_mercenary_num do
        local mercenary_info = self.exploring_mercenary_list[i]
        self.mercenary_images[i] = mercenary_info.template_info.sprite
    end

    for i = self.exploring_mercenary_num + 1, #self.mercenary_images do
        self.mercenary_images[i] = nil
        if self.mercenary_roles[i] then
            self.mercenary_roles[i]:SetVisible(false)
        end
    end

    --只显示5个
    self.show_exploring_mercenary_num = self.exploring_mercenary_num

    if self.exploring_mercenary_num > SHOW_MERCENARY_MAX_NUM then
        self.show_exploring_mercenary_num = SHOW_MERCENARY_MAX_NUM
    end

    self.mercenary_shadow_index = 0
    for i = 1, self.show_exploring_mercenary_num do
        self:LoadSingleMercenaryRole(i, i)
    end

    for i = self.mercenary_shadow_index + 1, SHOW_MERCENARY_MAX_NUM do
        self.shadow_nodes[i]:setVisible(false)
    end

    --mercenary 随机动作
    self.start_random_mercenary_action_flag = true
    self.action_time = math.random(RANDOM_MERCENARY_ACTION_MIN_TIME, RANDOM_MERCENARY_ACTION_MAX_TIME)

    self.has_load_mercenary = true
end

--创建一个mercenary形象并给sprite设定图片
function maze_component:LoadSingleMercenaryRole(role_index, image_index)
    local mercenary_image = self.mercenary_images[image_index]
    local mercenary_role

    if self.mercenary_roles[role_index] then
        mercenary_role = self.mercenary_roles[role_index]
    else
        mercenary_role = require("entity.maze_role").New()
        self.mercenary_roles[role_index] = mercenary_role
    end

    local shadow_nodes = self.shadow_nodes
    self.mercenary_shadow_index = self.mercenary_shadow_index + 1
    mercenary_role:Init(self.mercenary_sprites[role_index], mercenary_image, shadow_nodes[self.mercenary_shadow_index])

    mercenary_role:SetShadowPosition(mercenary_role:GetPosition())

    mercenary_role:WalkAnimation(3)
end

--创建一个mercenary action
function maze_component:CreateMercenaryAction()
    self.action_time = math.random(RANDOM_MERCENARY_ACTION_MIN_TIME, RANDOM_MERCENARY_ACTION_MAX_TIME)
    local role_index = math.random(1, self.show_exploring_mercenary_num)

    local role = self.mercenary_roles[role_index]

    local action_index = MERCENARY_ACTION["change_role"]

    if action_index == MERCENARY_ACTION["walk"] then

    elseif action_index == MERCENARY_ACTION["jump"] then
        role:Jump()

    elseif action_index == MERCENARY_ACTION["grossip"] then
        --self.mercenary_roles[self.action_index]:Grossip()

    elseif action_index == MERCENARY_ACTION["change_role"] then
        --随机一个形象
        if self.exploring_mercenary_num > SHOW_MERCENARY_MAX_NUM then
            local image_index = math.random(SHOW_MERCENARY_MAX_NUM+1, self.exploring_mercenary_num)

            --转身之后替换图片
            role:TurnAroundAnimation(TURN_AROUNG_TIME, false, function()
                if image_index ~= role_index then
                    self:LoadSingleMercenaryRole(role_index, image_index)
                    --交换 替换的图片引用
                    local mercenary_images = self.mercenary_images
                    mercenary_images[role_index], mercenary_images[image_index] = mercenary_images[image_index], mercenary_images[role_index]
                end
            end)
        end

    elseif action_index == MERCENARY_ACTION["turn_around"] then
        role:TurnAroundAnimation(TURN_AROUNG_TIME, false)
    end
end

--创建10个monster sprite 对象
function maze_component:CreateMonsterSprites()
    local MONSTER_ZORDER = MAZE_ZORDER["mercenary_and_monster"]

    self.monster_sprites = {}

    for i = 1, MONSTER_NUM do
        local monster_sprite =  cc.Sprite:create()
        monster_sprite:setAnchorPoint(cc.p(0.5, 0))
        monster_sprite:setPosition(cc.p(VISIBLE_SIZE_WIDTH, MERCENARY_BEGIN_Y))
        self.root_node:addChild(monster_sprite, MONSTER_ZORDER)

        self.monster_sprites[i] = monster_sprite
    end
end

--创建 monster role
function maze_component:LoadAllMonsterRoles()
    self.monster_num = 0
    for sprite in string.gmatch(self.cur_maze_template_info["monster_sprites"], "%d+") do
        self.monster_num = self.monster_num + 1
        self.monsters_images[self.monster_num] = sprite
    end

    for i = 1, MONSTER_NUM do
        self:LoadSingleMonsterRole(i)
    end

    self.load_monster_flag = true
end

function maze_component:LoadSingleMonsterRole(role_index)
    local monster_role
    if self.monster_roles[role_index] then
        monster_role = self.monster_roles[role_index]
    else
        monster_role = require("entity.maze_role").New()
    end

    --怪物形象和位置
    local monster_image_index = math.random(1, self.monster_num)
    local monster_start_pos_x = VISIBLE_SIZE_WIDTH + math.random(1, RANDOM_MONSTER_START_MAX_POS_X)

    if not self.monsters_images[monster_image_index] then
        return
    end

    local monster_shadow_index = role_index + SHOW_MERCENARY_MAX_NUM

    monster_role:Init(self.monster_sprites[role_index], self.monsters_images[monster_image_index], self.shadow_nodes[monster_shadow_index])
    monster_role:SetShadowPosition(monster_role:GetPosition())

    --每秒30-50个像素 走动速度
    monster_role.walk_velocity = math.random(RANDOM_MONSTER_WALK_MIN_VELOCITY_X, RANDOM_MONSTER_WALK_MIN_VELOCITY_Y)

    --飞行速度
    monster_role.fly_velocity_x = math.random(RANDOM_MONSTER_FLY_MIN_VELOCITY_X, RANDOM_MONSTER_FLY_MAX_VELOCITY_X)
    monster_role.fly_velocity_y = math.random(RANDOM_MONSTER_FLY_MIN_VELOCITY_Y, RANDOM_MONSTER_FLY_MAX_VELOCITY_Y)

    monster_role.initial_fly_velocity_y = monster_role.fly_velocity_y

    --飞行加速度，向上飞行，加速度方向向下
    monster_role.fly_acc_y = MONSTER_FLY_ACCELERATED_Y

    --位置
    monster_role:SetPosition(monster_start_pos_x, MONSTER_END_Y)

    monster_role:WalkAnimation(2)

    monster_role.shake_time = 0 --抖动时间

    monster_role.part_index = 1 --1、走动状态， 2、抖动状态， 3、飞行状态

    self.monster_roles[role_index] = monster_role
end

--创建四个bg sprite
function maze_component:CreateMazeBgSprite()
    local maze_bg_zorder = MAZE_ZORDER["maze_mid"]

    for i = 1, 3 do
        local p = cc.p(0, MAZE_BG_ANCHOR[1])
        local scale = MAZE_BG_SCALE

        local bg = cc.Sprite:create()
        bg:setAnchorPoint(p)
        bg:setScale(scale, scale)
        self.root_node:addChild(bg, MAZE_ZORDER["maze_near"])

        self.maze_layer1_sprites[i] = bg
    end

    local tile_shader = shader_manager:GetProgram("tile")
    for i = 2, MAZE_BG_NUM do
        local p = cc.p(0, MAZE_BG_ANCHOR[i])
        local scale = MAZE_BG_SCALE

        maze_bg_zorder = MAZE_ZORDER["maze_mid"] - i + 1

        local bg = cc.Sprite:create()
        bg:setAnchorPoint(p)
        bg:setScale(scale, scale)
        self.root_node:addChild(bg, maze_bg_zorder)

        bg:setGLProgram(tile_shader)
        self.maze_bg_sprites[i] = bg
    end

    self.farest_maze_bg_sprite = cc.Sprite:create()
    self.farest_maze_bg_sprite:setAnchorPoint(cc.p(0, MAZE_BG_ANCHOR[5]))
    self.farest_maze_bg_sprite:setScale(MAZE_BG_SCALE, MAZE_BG_SCALE)

    self.farest_maze_bg_sprite:setGLProgram(tile_shader)
    self.farest_maze_bg_sprite:setPosition(0, MAZE_BG_POSITION["layer5"])

    self.root_node:addChild(self.farest_maze_bg_sprite, maze_bg_zorder - 1)
end

--加载maze 背景图片
function maze_component:LoadMazeBgImages()
    local maze_bg_type = adventure_logic.cur_maze_template_info.maze_bg_type

    local conf = config_manager.maze_background_config[maze_bg_type]

    if conf.layer1 ~= "" then
        local image_name = "res/adventure/" .. conf.layer1.. ".png"
        local texture = cc.Director:getInstance():getTextureCache():addImage(image_name)

        local frame_width = texture:getPixelsWide()
        local frame_height = texture:getPixelsHigh()

        MAZE_BG_WIDTH[1] = frame_width * MAZE_BG_SCALE
        texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

        local y = MAZE_BG_POSITION["layer1"]

        local only_show_first = conf.layer1 == "layer1_dark"
        for i = 1, 3 do
            local bg = self.maze_layer1_sprites[i]
            bg:setVisible(not only_show_first or i ~= 1)

            bg:setTexture(texture)
            bg:setTextureRect(cc.rect(0, 0, frame_width, frame_height))

            bg:setPosition(MAZE_BG_START_X + 300 * (i - 1), y)
        end

        if only_show_first then
            self.maze_layer1_sprites[1]:setPosition(0, y)
            self.maze_layer1_sprites[1]:setVisible(true)
        end

        self.is_layer1_moving = not only_show_first
    else
        self.is_layer1_moving = false
        for i = 1, 3 do
            self.maze_layer1_sprites[i]:setVisible(false)
        end
    end

    for i = 2, MAZE_BG_NUM do
        local bg1 = self.maze_bg_sprites[i]
        local bg2 = self.maze_bg_sprites[i + MAZE_BG_NUM]

        if conf['layer' .. i] ~= "" then
            local layer_key = "layer" .. i

            local image_name = "res/adventure/" .. conf[layer_key] .. ".png"
            local texture = cc.Director:getInstance():getTextureCache():addImage(image_name)

            local frame_width = texture:getPixelsWide()
            local frame_height = texture:getPixelsHigh()

            local y = 0
            if i == 2 then
                y = MAZE_BG_POSITION[layer_key .. conf.layer2_type]
            else
                y = MAZE_BG_POSITION[layer_key]
            end

            MAZE_BG_WIDTH[i] = frame_width * MAZE_BG_SCALE

            texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

            local bg = self.maze_bg_sprites[i]
            bg:setTexture(texture)
            bg:setTextureRect(cc.rect(0, 0, MAZE_BG_START_X, frame_height))

            bg:setPosition(0, y)
            bg:setVisible(true)

        else
            self.maze_bg_sprites[i]:setVisible(false)
        end
    end

    if conf["layer5"] ~= "" then
        local image_name = "res/adventure/" .. conf["layer5"] .. ".png"
        local texture = cc.Director:getInstance():getTextureCache():addImage(image_name)
        texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

        self.farest_maze_bg_sprite:setTexture(texture)
        self.farest_maze_bg_sprite:setTextureRect(cc.rect(0, 0, MAZE_BG_START_X, texture:getPixelsHigh()))

        self.farest_maze_bg_sprite:setVisible(true)
    else
        self.farest_maze_bg_sprite:setVisible(false)
    end

    self.load_bg_flag = true
end

function maze_component:UpdateMonsterPos(elapsed_time)
    if not self.load_monster_flag then
        return
    end

    for i = 1, MONSTER_NUM do
        local monster_role = self.monster_roles[i]
        local monster_sprite = monster_role:GetSprite()

        monster_role:Update(elapsed_time)

        if monster_role.part_index == 1 then
            --走动状态
            local monster_x = monster_sprite:getPositionX() - monster_role.walk_velocity * elapsed_time
            monster_x = math.max(monster_x, MONSTER_END_X)

            monster_sprite:setPositionX(monster_x)

            --怪物走到被击飞的地点
            if monster_x <= MONSTER_END_X then
                --播放刀光动画
                self:PlaySwordAnimation()
                monster_role.part_index = 2
            end

            monster_role:SetShadowPosition(monster_role:GetPosition())

        elseif monster_role.part_index == 2 then
            --抖动状态
            monster_role.shake_time = monster_role.shake_time + elapsed_time
            if monster_role.shake_time <= MONSTER_SHAKE_TIME then
                --抖动位移范围为 -5 ~ 5 ,暂时用 -5 ~ 5
                local shake_offset = math.random(0, MONSTER_SHAKE_OFFSET_X * 2) - MONSTER_SHAKE_OFFSET_X
                monster_sprite:setPositionX(monster_sprite:getPositionX() + shake_offset)
            else
                monster_role.shake_time = 0
                monster_role.part_index = 3

                monster_role:TurnAroundAnimation(0.2, true)
            end

            monster_role:SetShadowPosition(monster_role:GetPosition())

        elseif monster_role.part_index == 3 then
            --飞行状态
            --x 偏移
            monster_role:SetShadowPosition(monster_role:GetPositionX(), MONSTER_END_Y)
            if monster_sprite:getPositionX() >= VISIBLE_SIZE_WIDTH then
                monster_role.part_index = 4
            else
                local offset_x = monster_role.fly_velocity_x * elapsed_time

                --y 偏移
                local velocity_y = monster_role.fly_velocity_y
                local acc_y = monster_role.fly_acc_y
                local offset_y = velocity_y * elapsed_time + 0.5 * acc_y * math.pow(elapsed_time, 2)

                monster_sprite:setPosition(monster_sprite:getPositionX() + offset_x, monster_sprite:getPositionY() +  offset_y)

                --重设y 速度
                monster_role.fly_velocity_y = velocity_y + acc_y * elapsed_time

                --判断是否到地面
                if monster_sprite:getPositionY() <= MONSTER_END_Y then
                    monster_role.fly_velocity_y = monster_role.initial_fly_velocity_y
                end
            end

        elseif monster_role.part_index == 4 then
            monster_role:SetShadowPosition(monster_role:GetPosition())
            --飞到屏幕外，则重新生成怪物
            monster_role.part_index = 1
            self:LoadSingleMonsterRole(i)
        end
    end
end

function maze_component:UpdateMazeBgPos(elapsed_time)
    if not self.load_bg_flag then
        return
    end

    if self.is_layer1_moving then
        for i = 1, 3 do
            local velocity = MAZE_BG_VELOCITY[1]
            local end_x = MAZE_BG_WIDTH[1]

            local bg = self.maze_layer1_sprites[i]
            local x = bg:getPositionX() - velocity
            if x <= -end_x then
                x = MAZE_BG_START_X + 300 * (i - 1)
            end

            bg:setPositionX(x)
        end
    end

    for i = 2, MAZE_BG_NUM do
        local velocity = MAZE_BG_VELOCITY[i]
        local end_x = MAZE_BG_WIDTH[i]

        local bg = self.maze_bg_sprites[i]
        local x = bg:getPositionX() - velocity
        if x <= -end_x then
            x = 0
        end

        bg:setPositionX(x)
    end
end

local calc_mercenary_action_time = 0
function maze_component:Update(elapsed_time)
    self:UpdateMazeBgPos(elapsed_time)
    self:UpdateMonsterPos(elapsed_time)

    for i = 1, self.show_exploring_mercenary_num do
        self.mercenary_roles[i]:Update(elapsed_time)
    end

    if self.start_random_mercenary_action_flag then
        calc_mercenary_action_time = calc_mercenary_action_time + elapsed_time

        if calc_mercenary_action_time >= self.action_time then
            calc_mercenary_action_time = 0
            self:CreateMercenaryAction()
        end
    end
end

function maze_component:PlaySwordAnimation()
    if not self.sword_sprite then
        self.sword_sprite = cc.Sprite:createWithTexture(self.sword_image, cc.rect(0, 0, self.sword_image_width, self.sword_image_height))
        self.sword_sprite:setAnchorPoint(cc.p(0.5, 0.5))

        self.sword_sprite:setPosition(MERCENARY_BEGIN_X + MERCENARY_INTERVAL, MERCENARY_BEGIN_Y + 30)
        self.root_node:addChild(self.sword_sprite, MAZE_ZORDER["sword"])
    end

    self.sword_animation = cc.Animation:createWithSpriteFrames(self.sword_frames, 0.06)
    self.sword_animate = cc.Animate:create(self.sword_animation)

    self.sword_sprite:runAction(self.sword_animate)
end

function maze_component:LoadInfo()

    self.cur_maze_template_info = adventure_logic.cur_maze_template_info
    audio_manager:PlayMusic(self.cur_maze_template_info.music, true)

    self:LoadMazeBgImages()
    self:LoadAllMonsterRoles()

    self:LoadAllMercenaryRoles()

    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end

function maze_component:InitMeta()
    local sprite_path = "adventure/blade_gif.png"

    self.sword_image = cc.Director:getInstance():getTextureCache():addImage(sprite_path)

    self.sword_image_width = self.sword_image:getPixelsWide() / 5
    self.sword_image_height = self.sword_image:getPixelsHigh() / 3

    local rect = cc.rect(0, 0, self.sword_image_width, self.sword_image_height)
    self.sword_frames = {}
    local counter = 0
    for i = 1, 3 do  --行
        for j = 1, 5 do  -- 列
            counter = counter + 1
            rect.x = (j - 1) * self.sword_image_width
            rect.y = (i - 1) * self.sword_image_height

            --创建SpriteFrame类
            self.sword_frames[counter] = cc.SpriteFrame:createWithTexture(self.sword_image, rect)
            self.sword_frames[counter]:retain()
        end
    end
end

do
    maze_component:InitMeta()
end

return maze_component
