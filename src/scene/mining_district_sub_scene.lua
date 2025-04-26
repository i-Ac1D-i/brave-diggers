local config_manager = require "logic.config_manager"
local mining_logic = require "logic.mining"
local graphic = require "logic.graphic"
local sub_scene = require "scene.sub_scene"
local audio_manager = require "util.audio_manager"

local panel_util = require "ui.panel_util"
local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local CONST_BLOCK_TYPE = constants.BLOCK_TYPE

local CONFIRM_MSGBOX_MODE = client_constants.CONFIRM_MSGBOX_MODE

local BLOCK_SPRITE = "res/ui/block.png"

local BLOCK_EFFECT_SIZE = 52
local BLOCK_EFFECT_FRAME_TIME = 0.2

local screen_size = cc.Director:getInstance():getVisibleSize()
local VISIBLE_SIZE_WIDTH = screen_size.width
local VISIBLE_SIZE_HEIGHT = screen_size.height

local DESIGN_SIZE_WIDTH = cc.Director:getInstance():getOpenGLView():getDesignResolutionSize().width
local DESIGN_SIZE_HEIGHT = cc.Director:getInstance():getOpenGLView():getDesignResolutionSize().height

local BLOCK_SIZE = 56 * VISIBLE_SIZE_HEIGHT / DESIGN_SIZE_HEIGHT
local HALF_BLOCK_SIZE = BLOCK_SIZE * 0.5

local BLOCK_ORIGIN_X = VISIBLE_SIZE_WIDTH / 2
local BLOCK_ORIGIN_Y = VISIBLE_SIZE_HEIGHT - 3 * BLOCK_SIZE - HALF_BLOCK_SIZE

local MAX_BLOCK_SCALE = 2.0
local MIN_BLOCK_SCALE = 0.6
local BLOCK_SCALE_DELTA = 0.05

local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()

local RANDOM_BLOCK_SPRITE = client_constants.RANDOM_BLOCK_SPRITE
local FIX_BLOCK_SPRITE = client_constants.FIX_BLOCK_SPRITE

local STERLING_BLOCK = client_constants.STERLING_BLOCK
local BETTER_BLOCK = client_constants.BETTER_BLOCK
local PLIST_TYPE = ccui.TextureResType.plistType

local mining_dig_info_config

local math_random = math.random

local dig_effect_node = {}

function dig_effect_node:Init()
    self.root_node = cc.CSLoader:createNode("ui/mining_dig_effect_node.csb")

    self.use_tnt_btn = self.root_node:getChildByName("use_tnt")

    self.time_bg_img = self.root_node:getChildByName("time_bg")
    self.time_lbar = self.root_node:getChildByName("time_lbar")
    self.time_text = self.root_node:getChildByName("time_text")

    self.select_box_img = self.root_node:getChildByName("selection_box")
    self.dig_spine_node = spine_manager:GetNode("dig")
    self.root_node:addChild(self.dig_spine_node, 1)

    self.reward_spine_node = spine_manager:GetNode("maze_txt")
    self.reward_spine_node:setVisible(false)
    self.root_node:addChild(self.reward_spine_node, 1)

    self.reward_spine_tracker = spine_node_tracker.New(self.reward_spine_node, "txt")

    self.reward_node = cc.Node:create()
    self.root_node:addChild(self.reward_node, 1)

    self.resource_num_text = ccui.Text:create("", client_constants["FONT_FACE"], 28)
    self.resource_icon_img = ccui.ImageView:create()
    self.resource_icon_img:setScale(0.75, 0.75)
    self.resource_icon_img:setPositionX(-40)

    self.reward_node:addChild(self.resource_icon_img)
    self.reward_node:addChild(self.resource_num_text)

    self.dig_remain_time = 0
    self.dig_total_time = 1

    --使用雷管
    self.use_tnt_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local block_info = mining_dig_info_config[mining_logic.cur_block_type]
            if block_info and block_info.tnt_count > 0 then
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants["CONFIRM_MSGBOX_MODE"]["use_tnt"])
            end
        end
    end)
end

function dig_effect_node:IsVisbile()
    return self.root_node:isVisible()
end

function dig_effect_node:ShowDigEffect()
    self.dig_spine_node:setAnimation(0, "animation", true)
    self.dig_spine_node:setVisible(true)
    audio_manager:PlayEffect("dig_block", true)
end

function dig_effect_node:HideDigEffect()
    self.dig_spine_node:clearTrack(0)
    self.dig_spine_node:setVisible(false)
    audio_manager:StopEffect("dig_block")
end

function dig_effect_node:Show(x, y)
    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)

    self.reward_node:setVisible(false)
    self.reward_spine_node:setVisible(false)

    local remain_time, total_time = mining_logic:GetDigTime()
    if remain_time > 0 then
        --总时间从配置表中读取
        if remain_time > total_time then
            --remain_time = total_time
        end

        self.dig_total_time = total_time
        self.dig_remain_time = remain_time

        self.use_tnt_btn:setVisible(total_time >= 600)
        self.time_bg_img:setVisible(true)
        self.time_text:setVisible(true)
        self.time_lbar:setVisible(true)
        self.select_box_img:setVisible(true)

        self:ShowDigEffect()

        self.time_lbar:setPercent(self.dig_remain_time / self.dig_total_time * 100)
        self.time_text:setString(panel_util:GetTimeStr(self.dig_remain_time))

    else
        self.dig_total_time = 1
        self.dig_remain_time = 0

        --有资源可收集
        if mining_logic.cur_block_type ~= CONST_BLOCK_TYPE["empty"] then
            self:CheckAutoCollect()

        else
            self.root_node:setVisible(false)
        end

        self:HideDigEffect()
    end
end

function dig_effect_node:SetPosition(x, y)
    self.root_node:setPosition(x, y)
end

function dig_effect_node:ShowResourceNum(resource_type, resource_num)
    self.resource_num_text:setString("+" .. tostring(resource_num))
    self.resource_icon_img:loadTexture(config_manager.resource_config[resource_type].icon, PLIST_TYPE)

    self.reward_spine_node:setVisible(true)
    self.reward_spine_tracker:Bind("txt", "txt_alpha", 0, 0, self.reward_node)

    self.select_box_img:setVisible(false)
end

function dig_effect_node:CheckAutoCollect()
    local block_info = mining_dig_info_config[mining_logic.cur_block_type]

    --有资源可以采集
    if block_info.output_resource_id ~= 0 then
        self.use_tnt_btn:setVisible(false)
        self.time_bg_img:setVisible(false)
        self.time_lbar:setVisible(false)
        self.time_text:setVisible(false)

        --自动收矿
        local cur_block_pos = mining_logic.cur_position
        mining_logic:DigOrCollectBlock(cur_block_pos.x, cur_block_pos.y)

    else
        self.root_node:setVisible(false)
    end
end

function dig_effect_node:Update(elapsed_time)
    if self.dig_remain_time > 0 then
        self.dig_remain_time = self.dig_remain_time - elapsed_time

        if self.dig_remain_time <= 0 then
            self.dig_remain_time = 0

            self:CheckAutoCollect()
            self:HideDigEffect()

            graphic:DispatchEvent("finish_dig_block", mining_logic.cur_block_type)

        else
            self.time_lbar:setPercent(self.dig_remain_time / self.dig_total_time * 100)
            self.time_text:setString(panel_util:GetTimeStr(self.dig_remain_time))
        end
    end

    if self.reward_node:isVisible() then
        self.reward_spine_tracker:Update(elapsed_time)
    end
end

function dig_effect_node:Hide()
    self.root_node:setVisible(false)
    audio_manager:StopEffect("dig_block")
end

local BATCH_NODE_MAP =
{

}

local mining_district_sub_scene = sub_scene.New()

function mining_district_sub_scene:Init()
    mining_dig_info_config = config_manager.mining_dig_info_config
    self.root_node = cc.Node:create()

    self:SetRememberFromScene(true)

    self.block_batch_nodes = {}

    local n1 = mining_logic:GetBlockCount(CONST_BLOCK_TYPE["empty"])
    local n2 = mining_logic:GetBlockCount(CONST_BLOCK_TYPE["rock"])
    local n3 = mining_logic:GetBlockCount(CONST_BLOCK_TYPE["rock_purple_gold"])
    local n4 = mining_logic:GetBlockCount(CONST_BLOCK_TYPE["hard_rock"]) + mining_logic:GetBlockCount(CONST_BLOCK_TYPE["harder_rock"])
    
    self.block_batch_nodes[1] = cc.SpriteBatchNode:create(BLOCK_SPRITE, n1)
    self.block_batch_nodes[2] = cc.SpriteBatchNode:create(BLOCK_SPRITE, n2)
    self.block_batch_nodes[3] = cc.SpriteBatchNode:create(BLOCK_SPRITE, n3)
    self.block_batch_nodes[4] = cc.SpriteBatchNode:create(BLOCK_SPRITE, n4)
    self.block_batch_nodes[5] = cc.SpriteBatchNode:create(BLOCK_SPRITE, mining_logic.block_count-n1-n2-n3-n4)

    BATCH_NODE_MAP[CONST_BLOCK_TYPE["empty"]] = 1
    BATCH_NODE_MAP[CONST_BLOCK_TYPE["rock"]] = 2
    BATCH_NODE_MAP[CONST_BLOCK_TYPE["rock_purple_gold"]] = 3
    BATCH_NODE_MAP[CONST_BLOCK_TYPE["hard_rock"]] = 4
    BATCH_NODE_MAP[CONST_BLOCK_TYPE["harder_rock"]] = 4

    self.block_scale = 1.0
    self.touch_offset = 0

    self.mini_scene_node = cc.Node:create()

    for i = 1, #self.block_batch_nodes do
        self.mini_scene_node:addChild(self.block_batch_nodes[i], 2)
    end

    dig_effect_node:Init()
    self.mini_scene_node:addChild(dig_effect_node.root_node, 3)

    self.resource_sprite = cc.Sprite:create()
    self.mini_scene_node:addChild(self.resource_sprite, 4)

    --矿石
    self.ore_spine_nodes = {}

    self.ore_spine_root_node = cc.Node:create()
    self.mini_scene_node:addChild(self.ore_spine_root_node, 5)

    self.root_node:addChild(self.mini_scene_node)

    self.ui_root = require "ui.mining_district_panel"
    self.ui_root:Init()

    self.root_node:addChild(self.ui_root:GetRootNode(), 1)

    self.is_moving_camera = false
    self.has_created_block = false

    self.cur_golem_index = 1
    self.cur_chest_index = 1

    self:RegisterSpriteFrame()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function mining_district_sub_scene:GetBlockBatchNode(block_type)
    local index = BATCH_NODE_MAP[block_type]
    local cur_block_batch_node

    if index then
        cur_block_batch_node = self.block_batch_nodes[index]

    else
        cur_block_batch_node = self.block_batch_nodes[5]
    end

    return cur_block_batch_node
end

function mining_district_sub_scene:RegisterSpriteFrame()

    self.block_texture = cc.Director:getInstance():getTextureCache():addImage("ui/block.png")
    self.frame_map = {}

    for k, v in pairs(RANDOM_BLOCK_SPRITE) do
        for i = 1, 3 do
            self.frame_map[v .. i] = cc.SpriteFrameCache:getInstance():getSpriteFrame(v .. i .. ".png"):getRectInPixels()
        end
    end

    for k, v in pairs(FIX_BLOCK_SPRITE) do
        self.frame_map[v] = cc.SpriteFrameCache:getInstance():getSpriteFrame(v .. ".png"):getRectInPixels()
    end

    self.frame_map["block/torch"] = cc.SpriteFrameCache:getInstance():getSpriteFrame("block/torch.png"):getRectInPixels()

    for i = 1, 3 do
        self.frame_map["block/grass" .. i] = cc.SpriteFrameCache:getInstance():getSpriteFrame("block/grass" .. i .. ".png"):getRectInPixels()
        self.frame_map["block/grass_dark" .. i] = cc.SpriteFrameCache:getInstance():getSpriteFrame("block/grass_dark" .. i .. ".png"):getRectInPixels()
    end
end

--创建 高矿和富矿特效
function mining_district_sub_scene:GetOreSpineNode(animation_name)
    for i, node in ipairs(self.ore_spine_nodes) do
        if not node:isVisible() then
            node:setName(animation_name)
            return node, i
        end
    end

    local node = spine_manager:GetNode("mining_specialore")

    table.insert(self.ore_spine_nodes, node)
    self.ore_spine_root_node:addChild(node)
    node:setName(animation_name)

    return node, #self.ore_spine_nodes
end

function mining_district_sub_scene:Show()
    self.root_node:setVisible(true)

    if not self.has_created_block then
        local block_list = mining_logic:GetBlockList()

        for y, row_block_list in pairs(block_list) do
            for x, block_type in pairs(row_block_list) do
                self:CreateMiningBlock(x, y, block_type)
            end
        end

        local first_row_block = block_list[0]
        local block_y = -1
        for block_x = -19, 12 do
            local block_type = first_row_block[block_x]
            local sprite_name = self:GetGrassBlockSpriteName(block_type)
            local block_sprite = cc.Sprite:create()

            block_sprite:setTexture(self.block_texture)
            block_sprite:setTextureRect(self.frame_map[sprite_name])

            block_sprite:setName("block" .. block_x .. ":" .. block_y)

            local x = block_x * BLOCK_SIZE
            local y = 1 * BLOCK_SIZE

            block_sprite:setPosition(x, y)
            self.block_batch_nodes[1]:addChild(block_sprite, 1)
        end

        self.has_created_block = true
    end

    self.resource_sprite:setVisible(false)

    self:MoveTo(mining_logic.cur_position)

    --修正图片显示
    local remain_time = mining_logic:GetDigTime()
    if remain_time <= 0 and mining_logic.cur_block_type ~= CONST_BLOCK_TYPE["empty"] then
        self:UpdateCurBlock()
    end

    --更新时间
    local cur_block_x = mining_logic.cur_position.x
    local cur_block_y = mining_logic.cur_position.y

    self.ui_root:Show()

    local ui_x, ui_y = self:ConvertToMiniSpace(cur_block_x, cur_block_y)
    dig_effect_node:Show(ui_x, ui_y)

    self.touch_num = 0
    self.is_moving_camera = false
    self.is_scaling_camera = false

    self.old_music = audio_manager:GetCurrentMusic()
    audio_manager:PlayMusic("mining", true)

    for i, node in ipairs(self.ore_spine_nodes) do
        if node:getTag() ~= -1 then
            node:setAnimation(0, node:getName(), true)
            node:setVisible(true)
        end
    end

    self.listener:setEnabled(true)
end

function mining_district_sub_scene:Hide()
    self.root_node:setVisible(false)

    self.listener:setEnabled(false)

    for i, node in ipairs(self.ore_spine_nodes) do
        if node:getTag() ~= -1 then
            node:setVisible(false)
            node:clearTrack(0)
        end
    end

    self.ui_root:Hide()

    dig_effect_node:Hide()
end

function mining_district_sub_scene:ShowQuick()
    self.root_node:setVisible(true)
    self.listener:setEnabled(true)

    audio_manager:PlayMusic("mining", true)
end

function mining_district_sub_scene:HideQuick()
    self.root_node:setVisible(false)
    self.listener:setEnabled(false)

    dig_effect_node:Hide()
end

function mining_district_sub_scene:ConvertToUISpace(block_x, block_y)
    local x, y = self.mini_scene_node:getPosition()
    local ui_x = block_x * BLOCK_SIZE * self.block_scale + x
    local ui_y = -(block_y * BLOCK_SIZE * self.block_scale) + y

    return ui_x, ui_y
end

function mining_district_sub_scene:ConvertToBlockSpace(ui_x, ui_y, fix)
    local x, y = self.mini_scene_node:getPositionX(), self.mini_scene_node:getPositionY()

    local real_x = ui_x - x
    --y 轴正方向为 从上到下
    local real_y = -(ui_y - y)

    local block_x = math.ceil((real_x - HALF_BLOCK_SIZE * self.block_scale) / (BLOCK_SIZE * self.block_scale))
    local block_y = math.floor((real_y + HALF_BLOCK_SIZE * self.block_scale) / (BLOCK_SIZE * self.block_scale))

    if fix then
        block_x = math.ceil(block_x)
        block_y = math.floor(block_y)
    end

    return block_x, block_y
end

function mining_district_sub_scene:ConvertToMiniSpace(block_x, block_y)
    local x = block_x * BLOCK_SIZE
    local y = -(block_y * BLOCK_SIZE)

    return x, y
end

function mining_district_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
    --self:ScaleCamera(elapsed_time)

    dig_effect_node:Update(elapsed_time)
end

function mining_district_sub_scene:MoveTo(position)
    local x = position.x * -BLOCK_SIZE * self.block_scale + BLOCK_ORIGIN_X
    --y方向偏移一定距离
    local y = (position.y-2) * BLOCK_SIZE * self.block_scale + BLOCK_ORIGIN_Y

    self.mini_scene_node:setPosition(x, y)
end

--获取块的图片名称
function mining_district_sub_scene:GetBlockSpriteName(block_type)
    if block_type == CONST_BLOCK_TYPE["empty"] then
        return self:GetEmptyBlockSpriteName()
    end

    if FIX_BLOCK_SPRITE[block_type] then
        return FIX_BLOCK_SPRITE[block_type]

    elseif RANDOM_BLOCK_SPRITE[block_type] then
        local index =  math_random(1, 3)
        return RANDOM_BLOCK_SPRITE[block_type] .. index
    end
end

function mining_district_sub_scene:GetEmptyBlockSpriteName()
    local rand = math_random(1, 100)
    if mining_logic:GetDepth() >= 100 then
        if rand == 1 then
            return "block/torch"

        elseif rand <= 5 then
            return "block/empty1"

        elseif rand <= 20 then
            return "block/empty2"
        end
    else
        if rand <= 5 then
            return "block/empty1"
        elseif rand <= 20 then
            return "block/empty2"
        end
    end

    return "block/empty3"
end

function mining_district_sub_scene:GetGrassBlockSpriteName(block_type)
    local index = math.random(1, 3)

    if block_type == CONST_BLOCK_TYPE["empty"] then
        return "block/grass_dark" .. index
    else
        return "block/grass" .. index
    end
end

function mining_district_sub_scene:CreateMiningBlock(block_x, block_y, block_type)
    local sprite_name = self:GetBlockSpriteName(block_type)

    if not sprite_name then
        print(block_x, block_y, block_type)
        return
    end

    local block_sprite = cc.Sprite:create()
    block_sprite:setTexture(self.block_texture)

    if not self.frame_map[sprite_name] then
        print(' not found ', sprite_name)
        return
    end

    block_sprite:setTextureRect(self.frame_map[sprite_name])
    block_sprite:setName("block" .. block_x .. ":" .. block_y)

    local cur_block_batch_node = self:GetBlockBatchNode(block_type)

    cur_block_batch_node:addChild(block_sprite)

    local x = block_x * BLOCK_SIZE
    local y = -block_y * BLOCK_SIZE

    block_sprite:setPosition(x, y)

    if STERLING_BLOCK[block_type] then
        --富矿
        local node, index = self:GetOreSpineNode("sterling")
        node:setPosition(x, y)
        block_sprite:setTag(index)
        node:setTag(index)

        node:setAnimation(0, "sterling", true)
        node:setVisible(true)

    elseif BETTER_BLOCK[block_type] then
        --高矿
        local node, index = self:GetOreSpineNode("better")
        node:setPosition(x, y)
        block_sprite:setTag(index)
        node:setTag(index)

        node:setAnimation(0, "better", true)
        node:setVisible(true)
    end
end

function mining_district_sub_scene:UpdateCurBlock(block_type)
    local cur_block_x = mining_logic.cur_position.x
    local cur_block_y = mining_logic.cur_position.y

    block_type = block_type or mining_logic.cur_block_type

    local cur_block_batch_node = self:GetBlockBatchNode(block_type)

    local cur_block_sprite = cur_block_batch_node:getChildByName("block" .. cur_block_x .. ":" .. cur_block_y)

    if cur_block_sprite then
        local sprite_name = self:GetEmptyBlockSpriteName()

        cur_block_sprite:retain()

        cur_block_batch_node:removeChild(cur_block_sprite)

        cur_block_sprite:setTextureRect(self.frame_map[sprite_name])

        self.block_batch_nodes[1]:addChild(cur_block_sprite)
        cur_block_sprite:release()

        --替换草的状态
        if cur_block_y == 0 and cur_block_x >= -19 and cur_block_x <= 12 then
            local grass_block = self.block_batch_nodes[1]:getChildByName("block" .. cur_block_x .. ":" .. -1)

            local sprite_name = self:GetGrassBlockSpriteName(CONST_BLOCK_TYPE["empty"])
            grass_block:setTextureRect(self.frame_map[sprite_name])
        end

        --删除高矿和富矿特效
        if STERLING_BLOCK[mining_logic.cur_block_type] or BETTER_BLOCK[mining_logic.cur_block_type] then
            local node = self.ore_spine_nodes[cur_block_sprite:getTag()]
            if node then
                node:setTag(-1)
                node:setVisible(false)
                node:clearTrack(0)
            end

            cur_block_sprite:setTag(-1)
        end
    end

    if mining_logic.cur_block_type ~= CONST_BLOCK_TYPE["empty"] then
        local block_info = mining_dig_info_config[mining_logic.cur_block_type]

        if block_info.output_resource_id == 0 then
            return
        end

        local conf = config_manager.resource_config[block_info.output_resource_id]
        local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(conf.icon)

        self.resource_sprite:setTexture(frame:getTexture())
        self.resource_sprite:setTextureRect(frame:getRectInPixels())

        local ui_x, ui_y = self:ConvertToMiniSpace(cur_block_x, cur_block_y)
        self.resource_sprite:setPosition(ui_x, ui_y)

        self.resource_sprite:setVisible(true)
    end
end

--移动相机
function mining_district_sub_scene:MoveCamera(touch)
    if self.is_scaling_camera then
        return
    end

    local location = touch:getLocation()
    if not self.is_moving_camera then
        --某些移动设备检测过于灵敏
        if not self.single_touch_location_x or not self.single_touch_location_y then
            self.single_touch_location_x = location.x
            self.single_touch_location_y = location.y
        end

        local x_offset = math.abs(self.single_touch_location_x - location.x)
        local y_offset = math.abs(self.single_touch_location_y - location.y)
        if x_offset >= 4 or y_offset >= 4 then
            self.single_touch_location_x = location.x
            self.single_touch_location_y = location.y

            self.is_moving_camera = true
        end

    elseif not self.is_scaling_camera then
        local offset_x = location.x - self.single_touch_location_x
        local offset_y = location.y - self.single_touch_location_y

        self.single_touch_location_x = location.x
        self.single_touch_location_y = location.y

        local x, y = self.mini_scene_node:getPositionX() + offset_x, self.mini_scene_node:getPositionY() + offset_y
        if y < BLOCK_ORIGIN_Y then
            y = BLOCK_ORIGIN_Y
        end

        self.mini_scene_node:setPosition(x, y)

        if dig_effect_node:IsVisbile() then
            local ui_x, ui_y = self:ConvertToMiniSpace(mining_logic.cur_position.x, mining_logic.cur_position.y)
            dig_effect_node:SetPosition(ui_x, ui_y)

            if self.resource_sprite:isVisible() then
                self.resource_sprite:setPosition(ui_x, ui_y)
            end
        end
    end
end

function mining_district_sub_scene:RegisterWidgetEvent()
    local event_dispatcher = self.root_node:getEventDispatcher()

    self.listener = cc.EventListenerTouchAllAtOnce:create()

    if TARGET_PLATFORM == cc.PLATFORM_OS_ANDROID or TARGET_PLATFORM == cc.PLATFORM_OS_WINDOWS or TARGET_PLATFORM == cc.PLATFORM_OS_MAC or TARGET_PLATFORM == cc.PLATFORM_OS_LINUX then
        self.listener:registerScriptHandler(function(touches, event)
            local touch_num = #touches

            self.touch_num = self.touch_num + touch_num

            if self.touch_num == 1 then
                local location = touches[1]:getLocation()
                self.single_touch_location_x = location.x
                self.single_touch_location_y = location.y

                self.touch_offset = 0

                local x, y = self:ConvertToBlockSpace(location.x, location.y, true)
                self.ui_root.coordinate_text:setString("X:" .. x .. " Y:" .. y)

            elseif self.touch_num >= 2 then
                --苹果设备可以捕获到多个触摸点，但是安卓同时只能捕获一个触摸点
                local location1 = touches[1]:getLocationInView()
                self.touch_offset = math.abs(location1.x - self.single_touch_location_x) + math.abs(location1.y - self.single_touch_location_y)
            end

            return true
        end, cc.Handler.EVENT_TOUCHES_BEGAN)


    elseif TARGET_PLATFORM == cc.PLATFORM_OS_IPHONE or TARGET_PLATFORM == cc.PLATFORM_OS_IPAD then
        self.listener:registerScriptHandler(function(touches, event)
            local touch_num = #touches
            self.touch_num = self.touch_num + touch_num

            if self.touch_num == 1 then
                local location = touches[1]:getLocation()
                self.single_touch_location_x = location.x
                self.single_touch_location_y = location.y

                self.touch_offset = 0

                local x, y = self:ConvertToBlockSpace(location.x, location.y, true)
                self.ui_root.coordinate_text:setString("X:" .. x .. "Y:" .. y)

            elseif touch_num >= 2 then
                --苹果设备可以捕获到多个触摸点，但是安卓同时只能捕获一个触摸点
                local location1 = touches[1]:getLocation()
                local location2 = touches[2]:getLocation()
                self.touch_offset = math.abs(location1.x - location2.x) + math.abs(location1.y - location2.y)
            end

            return true
        end, cc.Handler.EVENT_TOUCHES_BEGAN)
    end

    self.listener:registerScriptHandler(function(touches, event)
        local touch_num = #touches

        if touch_num == 1 then
            --移动相机
            self:MoveCamera(touches[1])

        elseif touch_num == 2 then
            local location1 = touches[1]:getLocation()
            local location2 = touches[2]:getLocation()

            if not self.is_scaling_camera then
                --先计算出开始缩放时的中心点
                local center_x = (location1.x + location2.x) / 2
                local center_y = (location1.y + location2.y) / 2

                self.clicked_ui_x, self.clicked_ui_y = center_x, center_y
                self.center_block_x, self.center_block_y = self:ConvertToBlockSpace(center_x, center_y)
            end

            self.is_scaling_camera = true
            self.is_moving_camera = false

            local touch_offset = math.abs(location1.x - location2.x) + math.abs(location1.y - location2.y)
            local x, y = self.mini_scene_node:getPositionX(), self.mini_scene_node:getPositionY()

            if touch_offset > self.touch_offset then
                --zoom in
                self.block_scale = self.block_scale + BLOCK_SCALE_DELTA
                if self.block_scale > MAX_BLOCK_SCALE then
                    self.block_scale = MAX_BLOCK_SCALE
                end

            elseif touch_offset < self.touch_offset then
                --zoom out
                self.block_scale = self.block_scale - BLOCK_SCALE_DELTA
                if self.block_scale < MIN_BLOCK_SCALE then
                    self.block_scale = MIN_BLOCK_SCALE
                end
            end

            self.mini_scene_node:setScale(self.block_scale, self.block_scale)

            local ui_x, ui_y = self:ConvertToUISpace(self.center_block_x, self.center_block_y)

            local cur_x, cur_y = self.mini_scene_node:getPositionX(), self.mini_scene_node:getPositionY()
            self.mini_scene_node:setPosition(cur_x + self.clicked_ui_x - ui_x, cur_y + self.clicked_ui_y - ui_y)

            self.touch_offset = touch_offset

            if dig_effect_node:IsVisbile() then
                local ui_x, ui_y = self:ConvertToMiniSpace(mining_logic.cur_position.x, mining_logic.cur_position.y)
                dig_effect_node:SetPosition(ui_x, ui_y)

                if self.resource_sprite:isVisible() then
                    self.resource_sprite:setPosition(ui_x, ui_y)
                end
            end
        end

    end, cc.Handler.EVENT_TOUCHES_MOVED)

    self.listener:registerScriptHandler(function(touches, event)
        local touch_num = #touches

        self.touch_num = self.touch_num - touch_num

        if not self.is_moving_camera and not self.is_scaling_camera and touch_num == 1 then
            local p = touches[1]:getLocation()

            --忽略矿区之外的点击操作
            if p.y > BLOCK_ORIGIN_Y + HALF_BLOCK_SIZE then
                return
            end
            local block_x, block_y = self:ConvertToBlockSpace(p.x, p.y, true)

            self.clicked_ui_x, self.clicked_ui_y = p.x, p.y
            self.clicked_block_x, self.clicked_block_y = block_x, block_y

            self.single_touch_location_x = 0
            self.single_touch_location_y = 0

            local block_type = mining_logic:GetBlockType(block_x, block_y)
            if not block_type then
                return
            end

            --紫金岩石
            local block_info = mining_dig_info_config[block_type]
            if block_type == CONST_BLOCK_TYPE["rock_purple_gold"] then
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", CONFIRM_MSGBOX_MODE["destroy_rock_purple"], block_x, block_y)
                return
            end

            -- 挖掘时间
            if block_info.need_time1 > 1 and block_info.need_time1 < 999999 and not mining_logic:IsCollect(block_x, block_y) then
                local title = lang_constants:Get("mining_dig_time_title")
                local desc = string.format(lang_constants:Get("mining_dig_time"), block_info.name, block_info.need_time1 / 60)
                local confirm = lang_constants:Get("common_confirm")
                local cancel  = lang_constants:Get("common_cancel")

                graphic:DispatchEvent("show_simple_msgbox", title, desc, confirm, cancel, function()
                    if mining_logic:DigOrCollectBlock(block_x, block_y) then
                        self.ui_root:CheckGolem()
                    end
                end)

                return
            end

            --坐标转换存在误差
            local result = mining_logic:DigOrCollectBlock(block_x, block_y)
            if result == "success" then
                self.ui_root:CheckGolem()

            elseif result == "lack_count" then
                self.ui_root:CheckDigCount()
            end
        end

        if self.touch_num == 0 then
            self.is_moving_camera = false
            self.is_scaling_camera = false
        end
    end, cc.Handler.EVENT_TOUCHES_ENDED)

    self.listener:setEnabled(true)
    event_dispatcher:addEventListenerWithSceneGraphPriority(self.listener, self.root_node)

    --定位矿区魔像
    self.ui_root.golem_tip_img:setTouchEnabled(true)
    self.ui_root.golem_tip_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local golem_num = mining_logic.golem_num
            if golem_num <= 0 then
                return
            end

            if self.cur_golem_index > golem_num then
                self.cur_golem_index = 1
            end

            local position = mining_logic.golem_coordinates[self.cur_golem_index]
            self:MoveTo(position)

            self.cur_golem_index = self.cur_golem_index + 1
        end
    end)

    --定位宝箱
    self.ui_root.chest_tip_img:setTouchEnabled(true)
    self.ui_root.chest_tip_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local chest_num = #mining_logic.chest_coordinates
            if chest_num <= 0 then
                return
            end

            if self.cur_chest_index > chest_num then
                self.cur_chest_index = 1
            end

            local position = mining_logic.chest_coordinates[self.cur_chest_index]
            self:MoveTo(position)

            self.cur_chest_index = self.cur_chest_index + 1
        end
    end)
end

function mining_district_sub_scene:ScaleCamera(elapsed_time)
    if self.is_zoom_in then
        --zoom in
        self.block_scale = self.block_scale + BLOCK_SCALE_DELTA
        if self.block_scale > MAX_BLOCK_SCALE then
            self.block_scale = MAX_BLOCK_SCALE
            self.is_zoom_in = false
        end

        self.mini_scene_node:setScale(self.block_scale, self.block_scale)

        local ui_x, ui_y = self:ConvertToUISpace(self.clicked_block_x, self.clicked_block_y)

        local cur_x, cur_y = self.mini_scene_node:getPositionX(), self.mini_scene_node:getPositionY()
        self.mini_scene_node:setPosition(cur_x + self.clicked_ui_x - ui_x, cur_y + self.clicked_ui_y - ui_y)

    elseif self.is_zoom_out then
        --zoom out
        self.block_scale = self.block_scale - BLOCK_SCALE_DELTA
        if self.block_scale < MIN_BLOCK_SCALE then
            self.block_scale = MIN_BLOCK_SCALE
            self.is_zoom_in = false
        end

        self.mini_scene_node:setScale(self.block_scale, self.block_scale)
        local ui_x, ui_y = self:ConvertToUISpace(self.clicked_block_x, self.clicked_block_y)

        local cur_x, cur_y = self.mini_scene_node:getPositionX(), self.mini_scene_node:getPositionY()
        self.mini_scene_node:setPosition(cur_x + self.clicked_ui_x - ui_x, cur_y + self.clicked_ui_y - ui_y)
    end
end

function mining_district_sub_scene:RegisterEvent()
    --开始挖掘
    graphic:RegisterEvent("show_new_mining_block", function(block_str)
        for x, y, block_type in string.gmatch(block_str, "(-?%d+),(%d+),(%d+)|") do
            x = tonumber(x)
            y = tonumber(y)
            block_type = tonumber(block_type)
            self:CreateMiningBlock(x, y, block_type)
        end

        local cur_block_x = mining_logic.cur_position.x
        local cur_block_y = mining_logic.cur_position.y

        local ui_x, ui_y = self:ConvertToMiniSpace(cur_block_x, cur_block_y)
        dig_effect_node:Show(ui_x, ui_y)

        if mining_logic.is_discover_golem then
            graphic:DispatchEvent("trigger_novice_guide", client_constants.NOVICE_TRIGGER_TYPE["first_discover_golem"])
            mining_logic.is_discover_golem = false
        end
    end)

    graphic:RegisterEvent("finish_dig_block", function(block_type)
        self:UpdateCurBlock(block_type)
    end)

    graphic:RegisterEvent("finish_use_tnt", function()
        local ui_x, ui_y = self:ConvertToMiniSpace(mining_logic.cur_position.x, mining_logic.cur_position.y)
        dig_effect_node:Show(ui_x, ui_y)
        self:UpdateCurBlock()
    end)

    graphic:RegisterEvent("finish_collect_mine", function(resource_type, resource_num)
        self.resource_sprite:setVisible(false)
        dig_effect_node:ShowResourceNum(resource_type, resource_num)

        audio_manager:PlayEffect("collect_mine")
    end)

    --刷新矿区
    graphic:RegisterEvent("refresh_mining_area", function()
        self.has_created_block = false
        self.cur_golem_index = 1
        self.cur_chest_index = 1

        for i = 1, #self.block_batch_nodes do
            self.block_batch_nodes[i]:removeAllChildren()
        end

        for i, node in ipairs(self.ore_spine_nodes) do
            if node:getTag() ~= -1 then
                node:setTag(-1)
                node:clearTrack(0)
                node:setVisible(false)
            end
        end

        if self.root_node:isVisible() then
            self:Show()
        end
    end)

    --更新boss坐标
    graphic:RegisterEvent("update_mining_boss_info", function(boss_x, boss_y, boss_type)
        if boss_type == 0 then
            local block_type = mining_logic:GetBlockType(boss_x, boss_y)
            if not block_type then
                return
            end
            
            local cur_block_batch_node = self:GetBlockBatchNode(block_type)

            local sprite_name = self:GetBlockSpriteName(block_type)
            local cur_block_sprite = cur_block_batch_node:getChildByName("block" .. boss_x .. ":" .. boss_y)

            if cur_block_sprite then
                cur_block_sprite:setTextureRect(self.frame_map[sprite_name])
            end
        end
    end)
end

return mining_district_sub_scene
