local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local user_logic = require "logic.user"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"
local http_client = require "logic.http_client"
local json = require "util.json"
local share_logic = require "logic.share"
local constants = require "util.constants"
local resource_logic = require "logic.resource"
local lang_constants = require "util.language_constants"
local animation_manager = require "util.animation_manager"
local troop_logic = require "logic.troop"
local config_manager = require "logic.config_manager"
local maze_role_prototype = require "entity.ui_role"
local utils = require "util.utils"
local client_constants = require "util.client_constants"
local time_logic = require "logic.time"
local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local STAR_BALL_ROAD_Y = 250  --圆的纵轴半径
local STAR_BALL_ROAD_X = 450  --圆的横轴半径
local START_ANGLE_OFFSET = 255   --第一个星球偏移量
local STAR_ANGLE_OFFSET = 45   --每个星球间隔角度
local STAR_NUM = 8  --星球个数
local MAX_STAR_TYPE = constants["VANITY_MAX_MAZE_ID"] --最多星球类型
local TOUCH_MOVING = false
local BUY_CONF = config_manager.vanity_buy_other_pay_config
local TOUCH_OFFSET = 5


local star_ball_panel = panel_prototype.New()
star_ball_panel.__index = star_ball_panel

function star_ball_panel.New()
    return setmetatable({}, star_ball_panel)
end

function star_ball_panel:Init(root_node,index)
    self.root_node = root_node
    self.pos = index  --用来识别当前是哪一个星球，每次移动都会改变这个pos
    self.star_type = index%(MAX_STAR_TYPE + 1)   --星球类型 

    --锁的图片
    self.lock_img = cc.Sprite:createWithSpriteFrameName("icon/global/lock.png")
    self.lock_img:setVisible(false)
    self.lock_img:setPosition(cc.p(self.root_node:getContentSize().width/2,self.root_node:getContentSize().height/2))
    self.root_node:addChild(self.lock_img, 100)

    --设置星球类型加载星球动画
    self:SetStarType(self.star_type)

    self.angle = 0  --当前旋转角度
    self.offset_angle = 0  --当前偏移角度
    self.last_offset_angle = 0   --当前剩余偏移的角度
    self.move_num = 1 --移动次数，默认为1次
    self:addTouchEventListener()
end

function star_ball_panel:Show(max_maze)
    self.root_node:setVisible(true)
    
    self.max_maze = max_maze  --最大关卡数量
    if self.star_type == 0 then
        self.pos = self.max_maze + 1
    end

    local angle = START_ANGLE_OFFSET - (self.pos - 1) * STAR_ANGLE_OFFSET 
    self.angle = angle  --设置角度
    --改变角度
    self:ChangeRadius()  
    --改变状态
    self:ChangeState()   
end

function star_ball_panel:SetStarType(star_type)
    self.star_type = star_type

    --得到当前关卡配置信息
    local week = utils:getWDay(time_logic:Now())
    local vanity_maze_conf = config_manager.vanity_maze_config[week]
    self.maze_conf = nil
    for k,v in pairs(vanity_maze_conf) do
        if v.map_id == self.star_type then
            self.maze_conf = v
            break
        end
    end

    --根据类型调整星球
    --星球动画节点名字
    local animation_name = string.format("ui/node_planet_%d.csb", star_type)
    if self.star_animation then
        --移除之前的星球
        self.star_animation:removeFromParent()
    end

    --灰色星球图片名字
    local sp_name = string.format("planet/xingqiu_%d_grey.png", star_type)
    if self.gary_sp then
        --移除之前的图片
        self.gary_sp:removeFromParent()
    end

    if star_type == 0 then
        self.star_animation = cc.CSLoader:createNode("ui/node_planet_blackhole.csb")
        self.star_animation:setPosition(cc.p(self.root_node:getContentSize().width/2,self.root_node:getContentSize().height/2))
        self.root_node:addChild(self.star_animation)

        self.star_timeline = animation_manager:GetTimeLine("vanity_star_animation_end_timeline")
        self.star_animation:runAction(self.star_timeline)
        self.star_timeline:play("loop", true)
        return
    end

    --创建灰色星球图片（未开启显示的）
    self.gary_sp = cc.Sprite:createWithSpriteFrameName(sp_name)
    self.gary_sp:setVisible(false)
    self.gary_sp:setPosition(cc.p(self.root_node:getContentSize().width/2,self.root_node:getContentSize().height/2))
    self.root_node:addChild(self.gary_sp)

    --星球动画
    self.star_animation = cc.CSLoader:createNode(animation_name)
    self.star_animation:setPosition(cc.p(self.root_node:getContentSize().width/2,self.root_node:getContentSize().height/2))
    self.root_node:addChild(self.star_animation)

    self.star_timeline = animation_manager:GetTimeLine(string.format("vanity_star_animation%d_timeline", star_type))
    self.star_animation:runAction(self.star_timeline)
    self.star_timeline:play("loop", true)

    --刷新星球状态
    self:RefreshMazeIdState()
end

function star_ball_panel:RefreshMazeIdState()
    if self.star_type == 0 then
        return 
    end
    self.maze_state = constants["VANITY_MAZE_STATE"].unlock

    for k,v in pairs(troop_logic:GetVanityMazeList()) do
        if k == self.star_type then
            self.maze_state = v
            break
        end
    end

    if self.maze_state == constants["VANITY_MAZE_STATE"].unlock then
        --锁住状态
        self.gary_sp:setVisible(true)
        self.star_animation:setVisible(false)
    else
        --没有锁住状态
        if self.lock_img then
            self.lock_img:setVisible(false)
        end
        self.gary_sp:setVisible(false)
        --显示动画
        self.star_animation:setVisible(true)
    end

    if self.pos > MAX_STAR_TYPE then
        --超过当前最大类型的图片设置为不显示
        self.gary_sp:setVisible(false)
    end
end

--变化当前的角度到达旋转
function star_ball_panel:ChangeRadius(angle_offset, touch_end)
    local now_angle = self.angle
    if angle_offset then
        now_angle = self.angle + angle_offset
    end 
    if touch_end then
        --如果是触摸结束，计算一下要自动偏移的量
        if math.abs(angle_offset) < TOUCH_OFFSET then
            if angle_offset < 0 then
                --向右边偏移
                self.move_dir = 1
                self.last_offset_angle = self.last_offset_angle - angle_offset 
            elseif angle_offset > 0 then
                --向左边偏移
                self.move_dir = 2
                self.last_offset_angle = self.last_offset_angle - angle_offset
            end
            self.move_num = 0
        else
            if angle_offset > 0 then
                --向右边偏移
                self.move_dir = 1
                self.last_offset_angle = self.last_offset_angle + (STAR_ANGLE_OFFSET - angle_offset) 
            elseif angle_offset < 0 then
                --向左边偏移
                self.move_dir = 2
                self.last_offset_angle = self.last_offset_angle + (-STAR_ANGLE_OFFSET - angle_offset)
            end
            self.move_num = 1
        end

        self.donot_move = false
       

        if angle_offset ~= 0 and math.abs(self.last_offset_angle) == 0 then
            --位置刚刚好不用自动偏移
            self.move_num = 1
            self:ChangeState()
            self:MoveEndRestPos()
        end
        self.angle = self.angle + angle_offset
        return
    end
    --将当前角度转换为0-360
    now_angle = now_angle%360 
    --算出当前角度对应的x,y
    local x = STAR_BALL_ROAD_X * math.cos(now_angle *3.14/180)
    local y = STAR_BALL_ROAD_Y * math.sin(now_angle *3.14/180)
    --设置位置
    self.root_node:setPosition(cc.p(x, y))
    -- --改变星球透明度
    if self.pos == 1 then
        --这个星期向右边移动时进行透明度变化
        local opacity = 1
        if angle_offset and angle_offset > 0 then
           opacity = (1 - (math.abs(START_ANGLE_OFFSET - now_angle))/STAR_ANGLE_OFFSET)
        end
        self.root_node:setOpacity(opacity * 255)
        self.star_animation:setOpacity(opacity * 255)
    elseif self.pos == 8  then
        self.root_node:setVisible(true)
        local opacity = 0
        if angle_offset and angle_offset < 0 then
            opacity = (1 - (math.abs(START_ANGLE_OFFSET - now_angle))/STAR_ANGLE_OFFSET)
        end
        opacity = math.max(opacity, 0)
        self.root_node:setOpacity(opacity * 255)
        self.star_animation:setOpacity(opacity * 255)
    elseif self.pos == 4 then
        local opacity = 1
        if angle_offset and angle_offset < 0 then
            opacity = math.max((1 - (math.abs(START_ANGLE_OFFSET - (STAR_ANGLE_OFFSET * 3)  - now_angle))/STAR_ANGLE_OFFSET),0.5)
        end
        self.root_node:setOpacity(opacity * 255)
        self.star_animation:setOpacity(opacity * 255)
    elseif self.pos == 5 then
        local opacity = 0.5
        if angle_offset and angle_offset < 0 then
            opacity = math.min((1 - (math.abs(START_ANGLE_OFFSET - (STAR_ANGLE_OFFSET * 4)  - now_angle))/STAR_ANGLE_OFFSET), 0.5)
        elseif angle_offset and angle_offset > 0 then
            opacity = math.max((1 - (math.abs(START_ANGLE_OFFSET - (STAR_ANGLE_OFFSET * 3)  - now_angle))/STAR_ANGLE_OFFSET),0.5)
        end
        self.root_node:setOpacity(opacity * 255)
        self.star_animation:setOpacity(opacity * 255)
    elseif self.pos == 6 then 
        if self.star_type == 0 then
            self.root_node:setVisible(true)
        end
        local opacity = 0.5
        self.root_node:setOpacity(opacity * 255)
        self.star_animation:setOpacity(opacity * 255)
    elseif self.pos == 7 then
        self.root_node:setVisible(false)
        self.root_node:setOpacity(0)
        self.star_animation:setOpacity(0)
    end

    if self.star_type > self.max_maze then
        self.root_node:setVisible(false)
    elseif self.star_type == 0 and self.pos < 6 then
        self.root_node:setVisible(true)
    end

    --星球的大小改变
    local scale = (now_angle) / START_ANGLE_OFFSET
    local scale_c = ((scale*2)^2) / 2
    if self.star_type == 0 then
        scale_c = math.min(scale_c, 2) * 2
    end
    self.root_node:setScale(scale_c)
end

function star_ball_panel:RoationByPos(move_pos)
    if move_pos == 0 then
        return 
    end

    self.move_num = math.abs(move_pos)

    self.last_offset_angle = move_pos * STAR_ANGLE_OFFSET
    
    if move_pos > 0 then
        self.move_dir = 1
    else
        self.move_dir = 2
    end
end

function star_ball_panel:addTouchEventListener()
    self.root_node:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if TOUCH_MOVING then
                return
            end
            audio_manager:PlayEffect("click")
            if self.maze_state == constants["VANITY_MAZE_STATE"].unlock then
                --被锁住的状态
                graphic:DispatchEvent("show_prompt_panel", "vanity_maze_state_unlock")
            elseif self.maze_state == constants["VANITY_MAZE_STATE"].challenge_able then
                --可以战斗状态
                graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_stagestart", self.star_type)
            elseif self.maze_state == constants["VANITY_MAZE_STATE"].challenge_success then
                --可以领取佣兵的状态
                graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_mercenary", self.star_type)
            elseif self.maze_state == constants["VANITY_MAZE_STATE"].maze_finish then
                --完成该关卡
                graphic:DispatchEvent("show_prompt_panel", "vanity_maze_state_maze_finish")
            end
        end
    end)
end

function star_ball_panel:Update(delt)
    if math.abs(self.last_offset_angle) ~= 0 then
        if self.move_dir == 2 then
            self.offset_angle = self.offset_angle - (delt*100)
        elseif self.move_dir == 1 then
            self.offset_angle = self.offset_angle + (delt*100)
        end

        if math.abs(self.offset_angle) >= math.abs(self.last_offset_angle) then
            --自动滚动完成
            self:ChangeRadius(self.last_offset_angle)
            self.angle = self.angle + self.last_offset_angle
            self:MoveEndRestPos()
            self.offset_angle = 0
            self.last_offset_angle = 0
            self:ChangeState()
        else
            self:ChangeRadius(self.offset_angle)
        end
    end
end

function star_ball_panel:MoveEndRestPos()
    if self.move_dir == 1 then
        --位置调整
        self.pos = self.pos - self.move_num
    else
        --移动后的位置调整
        self.pos = self.pos + self.move_num
    end

    self.pos = self.pos % STAR_NUM

    if self.pos == 0 then
        self.pos = STAR_NUM
    end
end

--改变状态
function star_ball_panel:ChangeState()
    if self.star_type == 0 then
        self.root_node:setTouchEnabled(false)
        return
    end

    self:RefreshMazeIdState()

    if self.pos == 1 then
        --如是位置是1，则是在最前面，要执行星球动画和可以触摸 其他星球都不能触摸和动画
        self.star_timeline:play("loop", true)
        self.root_node:setTouchEnabled(true)
    elseif self.pos == 2 then
        --下一个星球可能是锁住状态要先锁
        if self.gary_sp:isVisible() then
            self.lock_img:setVisible(true)
        else
            self.lock_img:setVisible(false)
        end
        self.star_timeline:play("stop", false)
        self.root_node:setTouchEnabled(false)
    else
        self.lock_img:setVisible(false)
        self.star_timeline:play("stop", false)
        self.root_node:setTouchEnabled(false)
    end
end

local vanity_main_panel = panel_prototype.New(true)

function vanity_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/vanity_adventure_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")
    --规则按钮
    self.rule_btn = self.root_node:getChildByName("view_info_btn")
    self.rule_btn:setLocalZOrder(9999)
    --战斗结算按钮
    self.battle_result_btn = self.root_node:getChildByName("formation_btn")
    --商店按钮
    self.store_btn = self.root_node:getChildByName("exchange_reward_btn")
    
    --背景动画
    self.bg_sp = self.root_node:getChildByName("node_planet_beijing")
    self.bg_timeline = animation_manager:GetTimeLine("vanity_main_bg_timeline")
    self.bg_sp:runAction(self.bg_timeline)
    self.bg_timeline:gotoFrameAndPlay(1, 161, true)

    --触摸区域
    self.touch_panel = self.root_node:getChildByName("touch_move_panel")
    self.touch_panel:setLocalZOrder(999)
    self.touch_panel:setSwallowTouches(false) 

    --星球所在的节点
    self.roate_node = self.root_node:getChildByName("roate_node")
    self.roate_node:setScale(0.9)
    self.roate_node:setPositionX(self.roate_node:getPositionX() - 150)
    self.roate_node:setPositionY(self.roate_node:getPositionY() + 50)
    --星球模板
    self.start_ball1 = self.roate_node:getChildByName("start_ball1")
    self.start_ball1:setVisible(false)

    --显示信息节点
    self.star_info_node = self.roate_node:getChildByName("maze_state_node")
    self.star_info_node:setLocalZOrder(999)

    --当前星球战斗过了可以领取时显示的小佣兵动画
    local role_node = self.star_info_node:getChildByName("role_node")

    self.role_sprite1 = cc.Sprite:create()
    self.role_sprite1:setAnchorPoint(0.5, 0.5)
    self.role_sprite1:setPosition(cc.p(role_node:getPositionX(), role_node:getPositionY()-15))
    self.star_info_node:addChild(self.role_sprite1)

    --星球名字
    self.star_name_text_panel = self.star_info_node:getChildByName("Panel_5")
    self.star_name_text = self.star_name_text_panel:getChildByName("name_planet")
    self.max_star_name_width = 218
    self.star_name_length = self.max_star_name_width
    
    local role1 = maze_role_prototype.New()
    --现在自己的英雄
    local conf = config_manager.mercenary_config[11000017]
    role1:Init(self.role_sprite1, conf.sprite)
    role1:WalkAnimation(1)

    --额外招募次数
    local recruit_mercenary_node = self.root_node:getChildByName("shadow_times")
    self.recruit_mercenary_btn = recruit_mercenary_node:getChildByName("Button_15")
    self.recruit_mercenary_text = recruit_mercenary_node:getChildByName("tansuocishu")
    self.recruit_remind_icon = self.root_node:getChildByName("remind_icon")

    self.star_ball_nodes = {}

    --创建星球
    self:CreateStarBall()

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function vanity_main_panel:Show()
    self.root_node:setVisible(true)
    --显示当前选择的星球
    self:ShowStarInfo()
    self:JumpNowIndex(true)
    self:ReduceSearchTimes()
end

function vanity_main_panel:ReduceSearchTimes()
    local week = utils:getWDay(time_logic:Now())

    local conf = BUY_CONF[week]
    self.recruit_mercenary_text:setString(string.format(lang_constants:Get("recruit_mercenary_text"),troop_logic.reduce_search_times,conf.recruit_num)) 

    if troop_logic.reduce_search_times <= 0 then
        self.recruit_remind_icon:setVisible(false)
    else
        self.recruit_remind_icon:setVisible(true)
    end
end

function vanity_main_panel:JumpNowIndex(auto_one)
    local now_index = 0
    
    for k,v in pairs(troop_logic:GetVanityMazeList()) do
        if v == 1 then
            break
        elseif k == MAX_STAR_TYPE and v == constants["VANITY_MAZE_STATE"].maze_finish and auto_one then
            --通关了，要跑到第一个
            now_index = 0
        end
        now_index = now_index + 1
    end
    self:AutoJumpIndex(now_index)
end

function vanity_main_panel:Update(delt)
    local star_moving = false
    for k,star_ball_node in pairs(self.star_ball_nodes) do
        --星球update
        star_ball_node:Update(delt)
        if math.abs(star_ball_node.last_offset_angle) ~= 0 then
            star_moving = true
        end
    end
    
    if not star_moving and self.is_hide_star_info and self.touch_end then
        --如果是自动移动结束刷新显示信息
        self.touch_end = false
        self:ShowStarInfo()
    elseif not star_moving and self.is_hide_star_info and self.auto_move_index then
        self:JumpOneIndex()
    end


    if self.star_name_length < self.max_star_name_width then
        self.star_name_length = self.star_name_length + 5
        self.star_name_text_panel:setContentSize(cc.size(self.star_name_length,self.star_name_text_panel:getContentSize().height))
    end

end

--创建所用到的星球
function vanity_main_panel:CreateStarBall()
    --先移除当前场景中有的星球
    for i=1,STAR_NUM do
        --星球所在角度
        if self.star_ball_nodes[i] then
            self.star_ball_nodes[i].root_node:removeFromParent()
        end
    end

    for i=1,STAR_NUM do
        --星球所在角度
        local star = self.start_ball1:clone()
        self.roate_node:addChild(star)
        local star_panel = star_ball_panel.New()
        self.star_ball_nodes[i] = star_panel
        star_panel:Init(star,i)
    end
    self:ShowAllStar()
end

--显示所有的星球
function vanity_main_panel:ShowAllStar()
    local week = utils:getWDay(time_logic:Now())
    local vanity_maze_conf = config_manager.vanity_maze_config[week] or {}
    local max_maze = #vanity_maze_conf
    for i=1,STAR_NUM do
        --星球所在角度
        if self.star_ball_nodes[i] then
            self.star_ball_nodes[i]:Show(max_maze)
        end 
    end
end

--隐藏星球信息
function vanity_main_panel:HideStarInfo()
    self.is_hide_star_info = true
    self.star_info_node:stopAllActions()
    self.star_info_node:runAction(cc.FadeOut:create(0.2))
end

--显示星球信息
function vanity_main_panel:ShowStarInfo()
    self.is_hide_star_info = false
    self.star_info_node:stopAllActions()
    self.star_info_node:runAction(cc.FadeIn:create(0.2))
    self.star_name_length = 0
    for k,star_panel in pairs(self.star_ball_nodes) do
        if star_panel.pos == 1 then
            self.star_name_text:setString(star_panel.maze_conf.name)
            
            --隐藏所有元素
            local gou_img = self.star_info_node:getChildByName("Image_circle")
            gou_img:setVisible(false)

            local role_node = self.star_info_node:getChildByName("role_node")
            role_node:stopAllActions()
            role_node:setVisible(false)

            local battle_img = self.star_info_node:getChildByName("icon_sword")
            battle_img:stopAllActions()
            battle_img:setVisible(false)

            self.role_sprite1:setVisible(false)
            --根据不同的状态显示不同的内容
            if star_panel.maze_state == constants["VANITY_MAZE_STATE"].unlock then
            elseif star_panel.maze_state == constants["VANITY_MAZE_STATE"].challenge_able then
                battle_img:setVisible(true)
                battle_img:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),cc.DelayTime:create(1),cc.FadeOut:create(0.5))))
            elseif star_panel.maze_state == constants["VANITY_MAZE_STATE"].challenge_success then
                role_node:setVisible(true)
                role_node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.5),cc.DelayTime:create(1),cc.FadeOut:create(0.5))))
                self.role_sprite1:setVisible(true)
            elseif star_panel.maze_state == constants["VANITY_MAZE_STATE"].maze_finish then
                gou_img:setVisible(true)
            end
            --设置信息位置
            self.star_info_node:setPosition(cc.p(star_panel.root_node:getPositionX()-11,star_panel.root_node:getPositionY()+11))
            break
        end
    end
end

--当前触摸移动星球旋转
function vanity_main_panel:RoationMoveSelfStarBall(touch_move_offset)
    for i=1, STAR_NUM do
        local star_ball_node = self.star_ball_nodes[i]
        if star_ball_node.pos == 1 and star_ball_node.star_type == 1 and touch_move_offset < 0 then
            --这个球是第一个球了不能进行移动
            return
        elseif star_ball_node.pos == 1 and star_ball_node.star_type == 6 and touch_move_offset > 0 then
            --这个球是最后个球了不能进行移动
            return
        elseif star_ball_node.pos == 2 and star_ball_node.maze_state == constants["VANITY_MAZE_STATE"].unlock and touch_move_offset > 0 then
            ----这个球是没有解锁个球了不能进行移动
            return
        end
    end
    --移动旋转星球
    for i=1, STAR_NUM do
        local star_ball_node = self.star_ball_nodes[i]
        star_ball_node:ChangeRadius(touch_move_offset)
    end
end

--触摸结束移动星球
function vanity_main_panel:RoationEndSelfStarBall(touch_move_offset)
    for i=1, STAR_NUM do
        local star_ball_node = self.star_ball_nodes[i]
        if star_ball_node.pos == 1 and star_ball_node.star_type == 1 and touch_move_offset < 0 then
            --这个球是第一个球了不能进行移动
            return
        elseif star_ball_node.pos == 1 and star_ball_node.star_type == 6 and touch_move_offset > 0 then
            --这个球是最后个球了不能进行移动
            return
        elseif star_ball_node.pos == 2 and star_ball_node.maze_state == constants["VANITY_MAZE_STATE"].unlock and touch_move_offset > 0 then
            --这个球是没有解锁个球了不能进行移动
            return
        end
    end

    --触摸结束移动星球
    for i=1, STAR_NUM do
        local star_ball_node = self.star_ball_nodes[i]
        star_ball_node:ChangeRadius(touch_move_offset,true)
    end
end

--跳转到第几个星球
function vanity_main_panel:AutoJumpIndex(star_type)
    
    if not self:IsCanTouchMove() or star_type == 0 then
        return
    end

    --隐藏星球信息
    self:HideStarInfo()

    local offset = 0
    for k,ball in pairs(self.star_ball_nodes) do
        if ball.pos == 1 then
            if ball.star_type ~= star_type then
                offset = star_type - ball.star_type
            end
            break
        end
    end

    if offset == 0 then
        
        if self.is_hide_star_info then
            self:ShowStarInfo()
        end
        return 
    end

    self.jump_index = offset
    self.auto_move_index = true
    self:JumpOneIndex()
end

function vanity_main_panel:JumpOneIndex()
    if self.jump_index and math.abs(self.jump_index) > 0 then
        local dir = -1
        if self.jump_index > 0 then
            dir = 1
            self.jump_index = self.jump_index - 1
        else
            self.jump_index = self.jump_index + 1
        end
        for i=1, STAR_NUM do
            local star_ball_node = self.star_ball_nodes[i]
            star_ball_node:RoationByPos(dir)
        end
    else
        if self.is_hide_star_info then
            self:ShowStarInfo()
        end
        self.auto_move_index = false
    end
end

--是否可以触摸移动
function vanity_main_panel:IsCanTouchMove()
    local is_can = true
    for i=1, STAR_NUM do
        local star_ball_node = self.star_ball_nodes[i]
        if math.abs(star_ball_node.last_offset_angle) ~= 0 then
            --是否有星球还在执行自动移动偏移量
            is_can = false
        end
    end
    return is_can 
end

function vanity_main_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --返回
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --规则按钮
    self.rule_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_rule_msgbox")
        end
    end)

    --商店按钮
    self.store_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local store_list = troop_logic:GetVanityStoreList()
            if store_list ~= nil then
                --如果商品列表为空请求服务器
                graphic:DispatchEvent("show_world_sub_panel", "vanity_store_panel")
            end
        end
    end)

    self.recruit_mercenary_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if troop_logic.reduce_search_times <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "not_recruit_mercenary_times")
                return
            end
            graphic:DispatchEvent("show_world_sub_panel", "vanity_recruit_mercenary_panel")
        end
    end)

    --战斗结算按钮
    self.battle_result_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("show_world_sub_panel", "vanity_adventure_result")
        end
    end)

    --触摸面板触摸
    self.touch_panel:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            if not self:IsCanTouchMove() then
                self.touch_began = false
                return 
            end
            TOUCH_MOVING = false
            self.touch_end = false
            --隐藏星球信息
            self:HideStarInfo()
            --开始触摸标志
            self.touch_began = true
            --开始触摸位置
            local start_location = widget:getTouchBeganPosition()
            self.start_touch_pos_x = start_location.x
            
        elseif event_type == ccui.TouchEventType.moved then
            --触摸移动
            if not self.touch_began then
                return 
            end
            --触摸移动位置点
            local move_location = widget:getTouchMovePosition()
            local touch_move_offset = math.floor(self.start_touch_pos_x - move_location.x)
            if math.abs(touch_move_offset) <= 360 then
                --最大触摸移动像素
                touch_move_offset = 36 * touch_move_offset / 360
                self:RoationMoveSelfStarBall(-touch_move_offset)
            end
        elseif event_type == ccui.TouchEventType.ended then
            --触摸结束
            if not self.touch_began then
                return 
            end
            local end_location = widget:getTouchEndPosition()
            local touch_end_offset = math.floor(self.start_touch_pos_x - end_location.x)
            if math.abs(touch_end_offset) > 360 then
                if touch_end_offset > 0 then
                    touch_end_offset = 360
                else
                    touch_end_offset = -360
                end
            end
            touch_end_offset = 36 * touch_end_offset / 360
            if math.abs(touch_end_offset) > TOUCH_OFFSET then
                TOUCH_MOVING = true
            end
            self:RoationEndSelfStarBall(-touch_end_offset)
            self.touch_end = true
        elseif event_type == ccui.TouchEventType.canceled then
            --触摸取消
            if not self.touch_began then
                return 
            end
            local end_location = widget:getTouchEndPosition()
            local touch_end_offset = math.floor(self.start_touch_pos_x - end_location.x)
            if math.abs(touch_end_offset) > 360 then
                if touch_end_offset > 0 then
                    touch_end_offset = 360
                else
                    touch_end_offset = -360
                end
            end
            touch_end_offset = 36 * touch_end_offset / 360
            if math.abs(touch_end_offset) > TOUCH_OFFSET then
                TOUCH_MOVING = true
            end
            self:RoationEndSelfStarBall(-touch_end_offset)
            self.touch_end = true
        end
    end)
end

function vanity_main_panel:RegisterEvent()
    --获得佣兵成功刷新星球状态
    graphic:RegisterEvent("get_vanity_mercenary_success", function()
        if not self.root_node:isVisible() then
            return
        end
        for k,v in pairs(self.star_ball_nodes) do
            v:RefreshMazeIdState()
        end
        self:ShowStarInfo()
    end)

    --获得额外佣兵成功
    graphic:RegisterEvent("get_vanity_reduce_mercenary_success", function()
        if not self.root_node:isVisible() then
            return
        end
        
        self:ReduceSearchTimes()
    end)
    

    graphic:RegisterEvent("show_vanity_animation", function ()
        if not self.root_node:isVisible() then
            return
        end
        
        self:JumpNowIndex()
    end)

    --刷新星球状态
    graphic:RegisterEvent("update_vanity_maze_info_success", function(is_fresh_star)
        if not self.root_node:isVisible() then
            return
        end
        
        for k,v in pairs(self.star_ball_nodes) do
            v:RefreshMazeIdState()
        end
        
        self:ShowStarInfo()
        
        if is_fresh_star then
            --请求新的数据
            self:CreateStarBall()
            self:ShowStarInfo()
            self:JumpNowIndex(true)
            self:ReduceSearchTimes()
        else
            self:JumpNowIndex()
        end
    end)

    --查询商品成功弹出商品框
    graphic:RegisterEvent("query_vanity_goods_success", function()
        if not self.root_node:isVisible() then
            return
        end
        graphic:DispatchEvent("show_world_sub_panel", "vanity_store_panel")
    end)
    
end

return vanity_main_panel
