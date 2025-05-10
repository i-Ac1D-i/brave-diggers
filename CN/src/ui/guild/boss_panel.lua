local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local guild_logic = require "logic.guild"
local spine_manager = require "util.spine_manager"
local role_prototype = require "entity.ui_role"
local common_function_util = require "util.common_function"
local time_logic = require "logic.time"
local shader_manager = require "util.shader_manager"
local JUMP_CONST = client_constants["JUMP_CONST"] 
local PLIST_TYPE = ccui.TextureResType.plistType
local BG_QUALITY_COLOR = client_constants["BG_QUALITY_COLOR"]

local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local TOWER_OFFSET_Y = 90
local BG_OFFSET_Y = 140
local BACK_ZORDER = 30000

local BLEND_FUNC = { src = gl.SRC_ALPHA, dst = gl.ONE_MINUS_SRC_ALPHA }

local tower_panel = panel_prototype.New()
tower_panel.__index = tower_panel

function tower_panel.New()
    return setmetatable({}, tower_panel)
end

function tower_panel:Init(root_node,parent,data,index,tower_type,is_top,ground,is_start_ground)
    self.parent_panel = parent
    self.root_node = root_node
    self.root_node:setScale(1)
    self.root_node:setPositionX(self.parent_panel:getContentSize().width/2)
    self.parent_panel:addChild(root_node)

    self.door_right = self.root_node:getChildByName("door_right")
    self.door_left = self.root_node:getChildByName("door_left")

    self.tower_type = tower_type
    local tower02 = self.root_node:getChildByName("tower02")
    self.door = nil
    if self.tower_type == 2 then
        self.door_right:setVisible(false)
        self.door_left:setVisible(true)
        self.door = self.door_left
    else
        self.door_right:setVisible(true)
        self.door_left:setVisible(false)
        self.door = self.door_right
    end
        


    self.platform01 = self.root_node:getChildByName("platform01")
    self.platform01:setVisible(false)
    self.platform02 = self.root_node:getChildByName("platform02")
    self.platform02:setVisible(false)
    self.platform03 = self.root_node:getChildByName("platform03")
    self.platform03:setVisible(false)

    local ran_p = math.random(1, 100)
    if ran_p >= 1 and ran_p < 30 then
        self.platform01:setVisible(true)
        self.platform = self.platform01
    elseif ran_p >= 30 and ran_p < 60 then
        self.platform02:setVisible(true)
        self.platform = self.platform02
    else
        self.platform03:setVisible(true)
        self.platform = self.platform03
    end
    self.platform04 = self.root_node:getChildByName("platform04")
    self.platform04:setVisible(false)
   
    
    self.hp_0 = self.root_node:getChildByName("hp_0")
    self.hp_0:getChildByName("hp_barbg"):setColor(cc.c3b(45,36,36))
    self.hp_0:getChildByName("hp_barbg"):setOpacity(255*0.75)
    self.hp_0:setVisible(false)
    self.hp_bar = self.hp_0:getChildByName("hp_bar")
    self.hp_value = self.hp_0:getChildByName("value")

    self.click_btn = self.root_node:getChildByName("attack_btn")
    self.click_btn:setOpacity(0)
    self.click_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if guild_logic.guild_boss_over then
                graphic:DispatchEvent("show_prompt_panel", "guild_boss_over")
                return
            end

            if self.data.ID > guild_logic.guild_cur_boss_id then
                graphic:DispatchEvent("show_prompt_panel", "is_not_cur_boss_id")
            elseif self.data.ID  == guild_logic.guild_cur_boss_id then
                if self.data and self.data.ID ~= 0 then
                    graphic:DispatchEvent("show_world_sub_panel", "campaign_event_msgbox", client_constants["CAMPAIGN_MSGBOX_MODE"]["guild_boss"], self.data)
                end
            else
                if not self.is_open then
                    guild_logic:GuildBossReward(self.data.ID)
                else
                    graphic:DispatchEvent("show_prompt_panel", "guild_boss_reward_reviced")
                end
            end
            
        end
    end)

    local top_sp = self.root_node:getChildByName("top")
    if top_sp ~= nil then
        if is_top then
            top_sp:setVisible(true)
        else
            top_sp:setVisible(false)
        end
    else
        top_sp = self.root_node:getChildByName("top_0")
        if is_top then
            top_sp:setVisible(true)
        else
            top_sp:setVisible(false)
        end
    end

    --地面上一上的
    if ground then
        self.ground = ground
        local tower02 = self.root_node:getChildByName("tower02")
        if tower02 then
            tower02:loadTexture("guild_boss/boss_tower08.png", PLIST_TYPE)
        end
        if self.tower_type == 2 then
            self.door_left:loadTexture("guild_boss/boss_tower09.png", PLIST_TYPE)
        else
            self.door_right:loadTexture("guild_boss/boss_tower09.png", PLIST_TYPE)
        end
    end

    if is_start_ground then
        --地面起始层，不用填充数据
        if self.tower_type == 2 then
            self.door_left:loadTexture("guild_boss/boss_tower14.png", PLIST_TYPE)
        else
            self.door_right:loadTexture("guild_boss/boss_tower14.png", PLIST_TYPE)
        end
        self.platform:setVisible(false)
    end

    local platform01_02 = self.platform01:getChildByName("boss_platform02")
    local platform02_04 = self.platform02:getChildByName("boss_platform04")
    local platform03_06 = self.platform03:getChildByName("boss_platform06")
    if ground then
        platform01_02:loadTexture("guild_boss/boss_platform07.png", PLIST_TYPE)
        platform02_04:loadTexture("guild_boss/boss_platform08.png", PLIST_TYPE)
        platform03_06:loadTexture("guild_boss/boss_platform09.png", PLIST_TYPE)
        self.platform01:loadTexture("guild_boss/boss_platform10.png", PLIST_TYPE)
        self.platform02:loadTexture("guild_boss/boss_platform10.png", PLIST_TYPE)
        self.platform03:loadTexture("guild_boss/boss_platform10.png", PLIST_TYPE)
    end

    --创建怪物
    if data ~= nil then
        local boss_node =  self.platform:getChildByName("boss")
        boss_node:setOpacity(0)

        self.box_sp = cc.Sprite:createWithSpriteFrameName("guild_boss/boss_bouns02.png")
        self.box_sp:setPosition(cc.p(boss_node:getContentSize().width/2,boss_node:getContentSize().height/2))
        boss_node:addChild(self.box_sp)

        self.role = role_prototype.New()
        self.shadow_node = cc.Sprite:create("res/role/shadow.png")
        
        boss_node:addChild(self.shadow_node)
        self.boss_sp = cc.Sprite:create()
        boss_node:addChild(self.boss_sp)

        --宝箱动画
        self.spine_node1 = spine_manager:GetNode("boss_box", 1.0, true) 
        self.spine_node1:setScale(0.8)
        boss_node:addChild(self.spine_node1,10)
        self.spine_node1:setTimeScale(1.0)
        self.spine_node1:setVisible(false)

        --云城动画
        self.spine_node = spine_manager:GetNode("black_attack", 1.0, true) 
        self.spine_node:setScale(0.8)
        boss_node:addChild(self.spine_node,10)
        self.spine_node:setTimeScale(1.0)
        self.spine_node:setVisible(false)

        

        local monster_config = config_manager.monster_config[data.master_id]

        local monster_sprites = common_function_util.Split(monster_config.monster_sprites, '|')

        self.role:Init(self.boss_sp, monster_sprites[1],self.shadow_node)
        self.role.sprite:setScale(0.8)
        self.role.sprite:setAnchorPoint(cc.p(0.5,0))
        --设置元素位置
        local boss_center_x = boss_node:getContentSize().width/2-4
        local boss_center_y = self.role.sprite:getContentSize().height/2*0.8-8
        self.shadow_node:setPosition(cc.p(boss_center_x,self.shadow_node:getContentSize().height/4-4))
        self.spine_node:setPosition(cc.p(boss_center_x, 20))
        self.spine_node1:setPosition(cc.p(boss_center_x, 20))

        self.role.sprite:setPosition(cc.p(boss_node:getContentSize().width/2-4,-4))

        boss_node:setVisible(true)

        self.role:CreateSpriteFrame()
        self.data = data
        self.ID =self.data.ID
        self.Boss_id =self.data.master_id
        self.spine_node:registerSpineEventHandler(function (event)
          if event.eventData.name == "change" then
                self.hp_0:setVisible(false)
                self.shadow_node:setVisible(false)
                self.role.sprite:setVisible(false)
                self.is_open = false
                self.spine_node1:setVisible(true)
                self.spine_node1:setAnimation(0, "boss_box", true)
          end 
      end, sp.EventType.ANIMATION_EVENT)

    else
        self.ID = 0
    end

    self.root_node:setPositionY(-165+(index-1)*TOWER_OFFSET_Y*2)
end

function tower_panel:Show()

    self.root_node:setVisible(true)

    if self.data ~= nil  then
        self.hp_0:setVisible(false)
        self.shadow_node:setVisible(true)
        self.box_sp:setVisible(false)
        self.door:setVisible(false)

        if self.data.ID > guild_logic.guild_cur_boss_id then
            self.spine_node:setVisible(true)
            self.spine_node1:setVisible(false)
            --判断怪物是否在执行动画
            if self.role and self.walk_animate_forever then
                self.role.sprite:stopAllActions()
                self.role.walk_animate_forever = nil
                self.walk_animate_forever = false
            end
            if self.ground then
                self.spine_node:setAnimation(0, "smoke_loop1", true)
            else
                self.spine_node:setAnimation(0, "smoke_loop2", true)
            end
        elseif self.data.ID < guild_logic.guild_cur_boss_id then
            --print("是宝箱了")
            self.shadow_node:setVisible(false)
            self.role.sprite:setVisible(false)
            self.door:setVisible(true)
            --判断怪物是否在执行动画
            if self.role and self.walk_animate_forever then
                self.role.sprite:stopAllActions()
                self.role.walk_animate_forever = nil
                self.walk_animate_forever = false
            end

            local is_open = false
            for k,v in pairs(guild_logic.guild_boss_reward_state_list) do
                if v == self.data.ID then
                    is_open = true
                    break
                end
            end
            if is_open then
                self.spine_node:setVisible(false)
                self.spine_node1:setVisible(false)
                self.is_open = true
                self.box_sp:setVisible(true)
            else
                self.is_open = false
                self.spine_node:setVisible(false)
                self.spine_node1:setVisible(true)
                self.spine_node1:setAnimation(0, "boss_box", true)
            end

        elseif self.data.ID == guild_logic.guild_cur_boss_id then
            self.hp_0:setVisible(true)
            self.spine_node:setVisible(false)
            self.spine_node1:setVisible(false)
            self.role.sprite:setVisible(true)
            if self.role and not self.walk_animate_forever then
                self.walk_animate_forever = true
                self.role:WalkAnimation(1)
            end
            local bar_val = math.max(math.min(guild_logic.guild_cur_boss_hp/guild_logic.sum_boss_hp,100),0)*100
            self.hp_bar:setPercent(bar_val)
            self.hp_value:setString(panel_util:ConvertUnit(guild_logic.guild_cur_boss_hp).."/"..panel_util:ConvertUnit(guild_logic.sum_boss_hp))
        end

    else
        self.is_open = true
    end

end

--播放杀死的动画
function tower_panel:PlayKillAnimation()
    self.spine_node:setVisible(true)
    self.spine_node:setAnimation(0, "attack_boss", false)
    self.spine_node:registerSpineEventHandler(function(event)
        local animation_name = event.animation
        if animation_name == "attack_boss" then
            self:Show()
        end
    end, sp.EventType.ANIMATION_COMPLETE)
end

--播放可以打的动画
function tower_panel:CanPlayAnimation()
    self.spine_node:setVisible(true)
    if self.ground then
        self.spine_node:setAnimation(0, "smoke_loop1_over", false)
        self.spine_node:registerSpineEventHandler(function(event)
            local animation_name = event.animation
            if animation_name == "smoke_loop1_over" then
                self:Show()
            end
        end, sp.EventType.ANIMATION_COMPLETE)
    else
        self.spine_node:setAnimation(0, "smoke_loop2_over2", false)
        self.spine_node:registerSpineEventHandler(function(event)
            local animation_name = event.animation
            if animation_name == "smoke_loop2_over2" then
                self:Show()
            end
        end, sp.EventType.ANIMATION_COMPLETE)
    end
end

local bg_panel = panel_prototype.New()
bg_panel.__index = bg_panel

function bg_panel.New()
    return setmetatable({}, bg_panel)
end

function bg_panel:Init(root_node,parent,index,endIndex,max_bg_list)
    self.parent_panel = parent
    self.root_node = root_node
    local offset_x = math.random(1, 300)
    self.root_node:setPositionX(self.parent_panel:getContentSize().width/2+offset_x)
    self.parent_panel:addChild(root_node)
    local flow = self.root_node:getChildByName("flow")
    flow:setScaleX(2)
    flow:setPositionY(flow:getPositionY()+(index-1)*20)
    if endIndex then
        self.root_node:getChildByName("bg1"):loadTexture("guild_boss/boss_tower03.png", PLIST_TYPE)
        self.root_node:getChildByName("bg2"):loadTexture("guild_boss/boss_tower03.png", PLIST_TYPE)
    end

    self.root_node:setPositionY((index-1)*BG_OFFSET_Y*2)


end

function bg_panel:Show()
    
    self.root_node:setVisible(true)
end

local boss_panel = panel_prototype.New(true)
function boss_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/guild_boss_panel.csb")
    local root_node = self.root_node

    self.scrollview = root_node:getChildByName("ScrollView_5")
    -- self.scrollview:setSwallowTouches(false);

    self.root_node:getChildByName("back_btn"):setLocalZOrder(BACK_ZORDER)

    self.tower_node = self.scrollview:getChildByName("Node_3")
    self.bottom_tower_sp = self.scrollview:getChildByName("tower01")

    self.buy_tick_btn = self.root_node:getChildByName("btn")

    self.bg_node = self.scrollview:getChildByName("bg")
    self.bg_node:setPositionX(self.scrollview:getContentSize().width/2)

    self.tower_templent = root_node:getChildByName("template1")
    self.tower_templent:setVisible(false)

    self.tower_templent2 = root_node:getChildByName("template2")
    self.tower_templent2:setVisible(false)
    
    self.tower_templent3 = root_node:getChildByName("template3")
    self.tower_templent3:setVisible(false)

    self.bg_templent = root_node:getChildByName("template4")
    self.bg_templent:setVisible(false)

    self.rule_btn = root_node:getChildByName("Button_6")

    self.rest_time_title_label = self.root_node:getChildByName("dig_desc")
    self.rest_time_label = self.root_node:getChildByName("dig_number")

    self.exchange_reward_btn = self.root_node:getChildByName("exchange_reward_btn")

    self.tick_label = self.root_node:getChildByName("badge_number")

    self.ground_sp = cc.Sprite:createWithSpriteFrameName("guild_boss/boss_tower07.png")
    self.ground_sp:setScale(1)
    self.ground_sp:setAnchorPoint(cc.p(0.5,0.5))
    self.ground_sp:setPositionX(self.bg_node:getContentSize().width/2)
    self.bg_node:addChild(self.ground_sp,3)
    self.sky_sp = cc.Sprite:createWithSpriteFrameName("guild_boss/boss_tower10.png")
    self.bg_node:addChild(self.sky_sp,2)
    self.sky_sp:setAnchorPoint(cc.p(0.5,0))
    self.sky_sp:setScaleX(720/self.sky_sp:getContentSize().width)
    self.sky_sp:setPositionX(self.bg_node:getContentSize().width/2)


    --动画区域
    self.bottom_spine_node = self.scrollview:getChildByName("Node_1")
    local spine_node1 = spine_manager:GetNode("black_hole", 1.0, true) --底部的云雾
    spine_node1:setScale(2)
    spine_node1:setPosition(cc.p(self.bottom_spine_node:getContentSize().width / 2, self.bottom_spine_node:getContentSize().height / 2))
    self.bottom_spine_node:addChild(spine_node1)
    spine_node1:setTimeScale(1.0)
    spine_node1:setAnimation(0, "black_smoke", true)

    local spine_node2 = spine_manager:GetNode("black_hole", 1.0, true) --底部的云雾2
    spine_node2:setScale(2)
    spine_node2:setPosition(cc.p(self.bottom_spine_node:getContentSize().width / 2, self.bottom_spine_node:getContentSize().height / 2+900))
    self.bottom_spine_node:addChild(spine_node2)
    spine_node2:setTimeScale(1.0)
    spine_node2:setAnimation(0, "black_smoke", true)

    -- self.top_spine_node = self.scrollview:getChildByName("Node_5")
    self.top_spine_node = spine_manager:GetNode("black_hole", 1.0, true) --顶部的
    self.top_spine_node:setPositionX(25)
    
    self.top_spine_node:setScale(2)
    self.bg_node:addChild(self.top_spine_node,4)
    self.top_spine_node:setTimeScale(1.0)
    self.top_spine_node:setAnimation(0, "black_hole", true)

    --中间部分动画
    -- self.middle_spine_node1 = self.scrollview:getChildByName("Node_2")
    local spine_node3 = spine_manager:GetNode("rock_magma", 1.0, true) --中间底部
    spine_node3:setScale(2)
    spine_node3:setPosition(cc.p(self.ground_sp:getContentSize().width / 2, self.ground_sp:getContentSize().height / 2))
    self.ground_sp:addChild(spine_node3)
    spine_node3:setTimeScale(1.0)
    spine_node3:setAnimation(0, "rock_2", true)

    self.middle_spine_node2 = self.scrollview:getChildByName("Node_4")
    self.middle_spine_node2:setPositionX(self.scrollview:getContentSize().width/2)
    local spine_node4 = spine_manager:GetNode("rock_magma", 1.0, true) --中间上面
    spine_node4:setScale(2)
    spine_node4:setPosition(cc.p(self.middle_spine_node2:getContentSize().width / 2, self.middle_spine_node2:getContentSize().height / 2))
    self.middle_spine_node2:addChild(spine_node4)
    spine_node4:setTimeScale(1.0)
    spine_node4:setAnimation(0, "rock_1", true)

    self.tower_panels = {}
    self.bg_panels = {}
    self.time_recod = 0 --计时器

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function boss_panel:Show()
    graphic:DispatchEvent("jump_finish",JUMP_CONST["guild_boss"]) 
    self.root_node:setVisible(true)
    self:InitTower()
    self:RefreshScore()
end

function boss_panel:RefreshScore()
    local guild_contribution_point = resource_logic:GetResourceNum(RESOURCE_TYPE["guild_boss_ticket"])
    self.tick_label:setString(guild_contribution_point)
end

function boss_panel:Update(elapsed_time)
    local times = math.max(guild_logic.guild_boss_reset_time - time_logic:Now(),0)
    if times > 0 then
        if not self.rest_time_label:isVisible() then
            self.rest_time_label:setVisible(true)
            self.rest_time_title_label:setString(lang_constants:Get("guild_boss_time_desc"))
        end
        self.rest_time_label:setString(panel_util:GetTimeStr(times))
    else
        if guild_logic.guild_boss_over then
            self.rest_time_label:setVisible(false)
            self.rest_time_title_label:setString(lang_constants:Get("please_hold_on_next_guild_boss"))
        else
            self.rest_time_label:setString(panel_util:GetTimeStr(times))
        end
    end
end


function boss_panel:InitTower()
    self.guild_boss_list = guild_logic:GetGuildBossList()
    local ground = false
    local ground_pos_y = 0
    local ground_two = false
    local max_list = #self.guild_boss_list + 2
    for k=1,max_list do
        local is_top = false
        if k >= #self.guild_boss_list then
            is_top = true
            
        end
        local start_ground = false
        if k >= #self.guild_boss_list/2 and not ground  then
            ground = true
            start_ground = true
            ground_pos_y =k*TOWER_OFFSET_Y*2
        elseif k >= #self.guild_boss_list/2 + 1 and not ground_two then
            ground_two = true
            start_ground = true
        end

        local data = nil
        if ground then
            if not start_ground  then
                data = self.guild_boss_list[k - 2]
            end
        else
            data = self.guild_boss_list[k]
        end

        if self.tower_panels[k] == nil then
            self.tower_panels[k] = tower_panel.New()
            if k%2 ~= 0 then
                self.tower_panels[k]:Init(self.tower_templent:clone(),self.tower_node,data,k,1,is_top,ground,start_ground)
            else
                self.tower_panels[k]:Init(self.tower_templent2:clone(),self.tower_node,data,k,2,is_top,ground,start_ground)
            end
        end
        
        if self.fresh_boss then
           self.tower_panels[k].data = data 
        end
        
        self.tower_panels[k]:Show() 
           
    end

    --判断是否到地面后的背景
    local bg_max = math.floor(ground_pos_y/(BG_OFFSET_Y*2))
    for i=1,bg_max+1 do
        if self.bg_panels[i] == nil then
            self.bg_panels[i] = bg_panel.New()
            if i == bg_max+1 then
                self.bg_panels[i]:Init(self.bg_templent:clone(),self.bg_node,i,true)
            else
                self.bg_panels[i]:Init(self.bg_templent:clone(),self.bg_node,i,false)
            end
            self.bg_panels[i]:Show()
        end
        
    end
    for i=bg_max+2,#self.bg_panels do
        if self.bg_panels[i] ~= nil then
            self.bg_panels[i]:Hide()
        end
    end

    --地面上的背景
    local now_height = self.scrollview:getInnerContainer():getContentSize().height
    local offset_top = 500
    local need_height = self.bottom_tower_sp:getContentSize().height*2+max_list*TOWER_OFFSET_Y*2+offset_top
    local surplus_height = need_height - ground_pos_y --剩余高度
    self.sky_sp:setPositionY((bg_max+1)*BG_OFFSET_Y*2+25)
    self.ground_sp:setPositionY((bg_max+1)*BG_OFFSET_Y*2+115)
    self.middle_spine_node2:setPositionY((bg_max+1)*BG_OFFSET_Y*2-15)
    self.sky_sp:setScaleY(surplus_height/self.sky_sp:getContentSize().height)
    
    if now_height ~= need_height then
        self.top_spine_node:setPositionY(need_height-offset_top+150)
        self.scrollview:setInnerContainerSize(cc.size(self.scrollview:getContentSize().width,need_height ))
        self.scrollview:jumpToBottom()
        self:UpdateDrawPlatformSacle()
    end

end

function boss_panel:PlayKillAnimation()
    local play_index = guild_logic.guild_cur_boss_id - 1
    if play_index >= 1 then
        for k,v in pairs(self.tower_panels) do
            if v.data ~= nil and v.data.ID == play_index  then
                v:PlayKillAnimation()
            elseif v.data ~= nil and v.data.ID == guild_logic.guild_cur_boss_id then
                v:CanPlayAnimation()
            end
        end
    end
end


function boss_panel:UpdateDrawPlatformSacle()
    local offsetY = self.scrollview:getInnerContainer():getPositionY()
    local height = self.scrollview:getInnerContainer():getContentSize().height-self.scrollview:getContentSize().height
    self.bg_node:setPositionY((offsetY / height* (-100)-50)*3)
end


function boss_panel:RegisterWidgetEvent()

    self.scrollview:addEventListener(function(widget, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            self:UpdateDrawPlatformSacle()
        end
    end)

    self.rule_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "guild.boss_rule_msgbox") 
        end
    end)
    
    self.root_node:getChildByName("back_btn"):addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene") 
        end
    end)
    if self.buy_tick_btn then
        self.buy_tick_btn:addTouchEventListener(function (widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                local mode = client_constants["BATCH_MSGBOX_MODE"]["guild_boss_tickets_reward"]
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, prize_id, widget.reward_name)
            end
        end)
    end
    --公会boss兑换按钮监听
    if self.exchange_reward_btn then
        self.exchange_reward_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                if guild_logic:GetGuildBossExchangeRewardInfo() ~= nil then
                    graphic:DispatchEvent("show_world_sub_panel", "guild.boss_exchange_reward_msgbox")
                end
            end
        end)
    end
end

function boss_panel:RegisterEvent()
    graphic:RegisterEvent("boss_hp_refsh", function()
        if not self.root_node:isVisible() or guild_logic:GetFrightBossState() ~= 0 then
            return
        end
        self:InitTower()
    end)

    graphic:RegisterEvent("boss_deid_refsh", function()
        if not self.root_node:isVisible() then
            return
        end
        self:PlayKillAnimation()
    end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["guild_boss_ticket"]) then
            self:RefreshScore()
        end
    end)

    graphic:RegisterEvent("guild_boss_info_update", function()
        if not self.root_node:isVisible() then
            return
        end
        self:InitTower()
    end)

    
end

return boss_panel
