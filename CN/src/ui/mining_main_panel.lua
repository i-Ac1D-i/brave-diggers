local feature_config = require "logic.feature_config"
local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local adventure_logic = require "logic.adventure"
local resource_logic = require "logic.resource"
local mining_logic = require "logic.mining"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local escort_logic = require "logic.escort"
local mine_logic = require "logic.mine"
local resource_recycle_logic = require "logic.resource_recycle"

local open_permanent_config = config_manager.open_permanent_config
local panel_util = require "ui.panel_util"
local common_function_util = require "util.common_function"
local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local animation_manager = require "util.animation_manager"
local platform_manager = require "logic.platform_manager"

local adventure_maze_config = config_manager.adventure_maze_config

local CHOOSE_ETHER_CAVE = client_constants["MINING_NORMAL_CAVES"]["ether_cave"]
local CHOOSE_MONSTER_CAVE = client_constants["MINING_NORMAL_CAVES"]["monster_cave"]
local JUMP_CONST = client_constants["JUMP_CONST"] 

local ANIMATE_FPS = 20 
local BACK_PROGRESS_PANEL_DEFAULT_OPACITY = 50
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local BOSS_BP_PROGRESS_NUM = 5
local BOSS_BP_PROGRESS_SHOW_NUM = 2
local PROGRESS_ZORDER =
{
    ["front"] = 2,
    ["back"] = 1,
}
-- 栈结构
local BOSS_BP_PROGRESS_COLORS = 
{
    [1] = 0xD72323,
    [2] = 0xF1C629,
    [3] = 0xD72323,
    [4] = 0xF1C629,
    [5] = 0xD72323,
}

local HIGH_ZORDER = 20  
local TOUCH_ZORDER = 10

local bp_progress_panel = panel_prototype.New()
bp_progress_panel.__index = bp_progress_panel
function bp_progress_panel.New()
    return setmetatable({}, bp_progress_panel)
end

function bp_progress_panel:Init(root_node, index)
    self.root_node = root_node
    self.index = index
    self.percent_value = 100
    self.opacity = 100
    self.color_value = 0
    self.order_value = 0
    self.root_node:setCascadeColorEnabled(true)
    -- self.root_node:setColor((panel_util:GetColor4B(BOSS_BP_PROGRESS_COLORS[index])))
    -- self.root_node:setCascadeColorEnabled(true)
    -- self:SetProgressPercent()
    
    self.root_node:setVisible(false)
end

function bp_progress_panel:SetProgressPercent(percent_value)
    local percent_value = percent_value or self.percent_value
    if percent_value < 0 then 
        percent_value = 0 
    end
    if percent_value > 100 then 
        percent_value = 100
    end
    self.percent_value = percent_value 
    self.root_node:setPercent(self.percent_value)
end

function bp_progress_panel:UpdateProgressColor(index)
    if BOSS_BP_PROGRESS_COLORS[index] then 
        self.color_value = BOSS_BP_PROGRESS_COLORS[index]
        self.root_node:setVisible(true)
    else
        self.color_value = 0xffffff
        self.root_node:setVisible(false)
    end
    self.root_node:setColor(panel_util:GetColor4B(self.color_value))
end

function bp_progress_panel:SetProgressOpacity(value)
    local value = value or self.opacity
    if value < 0 then 
        value = 0
    end
    if value > 100 then 
        value = 100
    end
    self.opacity = value 
    self.root_node:setOpacity(self.opacity)
end

function bp_progress_panel:SetRenderOrder(order_value)
    local value = order_value or self.order_value
    self.order_value = value 
    self.root_node:setLocalZOrder(self.order_value)
end

local mining_main_panel = panel_prototype.New()
function mining_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mining_main_panel.csb") 

    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/ui/mining.plist")
    local tex = cc.Director:getInstance():getTextureCache():getTextureForKey("res/ui/mining.png")
    if tex then
        tex:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    end

    self.load_animation = false
    --animation_manager:LoadAnimation("mining")

    local title_img = self.root_node:getChildByName("title_bg")
    title_img:setLocalZOrder(HIGH_ZORDER)

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.scroll_view:setClippingEnabled(true)
    
    self.mining_animation_bg_node = cc.Node:create()
    
    self.scroll_view:addChild(self.mining_animation_bg_node)

    self.mining_img = self.scroll_view:getChildByName("mining")
    self.mining_img:setLocalZOrder(TOUCH_ZORDER)

    --挖掘系统按钮入口
    self.resource_recycle_btn = self.scroll_view:getChildByName("add_mine_btn_0")
    if self.resource_recycle_btn then
        self.resource_recycle_btn:setLocalZOrder(TOUCH_ZORDER)
    end

    local resource_recycle_temperature_img = self.scroll_view:getChildByName("shadow2_7_0_0")
    if resource_recycle_temperature_img and feature_config:IsFeatureOpen("resource_recycle") then
        resource_recycle_temperature_img:setLocalZOrder(HIGH_ZORDER)
        self.temperature_value = resource_recycle_temperature_img:getChildByName("value1")
    end

    local resource_recycle_process_img = self.scroll_view:getChildByName("shadow2_7_0")
    if resource_recycle_process_img and feature_config:IsFeatureOpen("resource_recycle") then
        resource_recycle_process_img:setLocalZOrder(HIGH_ZORDER)
        self.process_value = resource_recycle_process_img:getChildByName("value1")
    end

    --矿山系统按钮入口
    self.mine_btn = self.scroll_view:getChildByName("add_mine_btn")
    if self.mine_btn then
        self.mine_btn:setLocalZOrder(TOUCH_ZORDER)
    end
    
    --矿山系统的开采
    local mine_shadow_img = self.scroll_view:getChildByName("shadow_mine")
    if mine_shadow_img then
        mine_shadow_img:setVisible(feature_config:IsFeatureOpen("mine_and_cultivation"))

        mine_shadow_img:setLocalZOrder(HIGH_ZORDER)
        self.mine_plunder_text = mine_shadow_img:getChildByName("value1")  --掠夺次数
        self.mine_extract_text = mine_shadow_img:getChildByName("value2")  --开采中
    end

    self.vanity_btn = self.scroll_view:getChildByName("add_xingqiu")
    if self.vanity_btn then
        self.vanity_btn:setLocalZOrder(TOUCH_ZORDER)
    end

    local shadow_xingqiu_img = self.scroll_view:getChildByName("shadow_xingqiu")
    if shadow_xingqiu_img then
        shadow_xingqiu_img:setLocalZOrder(HIGH_ZORDER)
    end

    local shadow_xukong_img = self.scroll_view:getChildByName("shadow_xukong")
    if shadow_xukong_img then
        shadow_xukong_img:setLocalZOrder(HIGH_ZORDER)
    end

    self.escort_btn = self.scroll_view:getChildByName("add_tramcar_btn")
    if self.escort_btn then 
        self.escort_btn:setLocalZOrder(TOUCH_ZORDER)
    end

    local pickaxe_shadow = self.scroll_view:getChildByName("shadow1") 
    pickaxe_shadow:setLocalZOrder(HIGH_ZORDER)

    self.pickaxe_count_text = pickaxe_shadow:getChildByName("value1")

    local shadow2_img = self.scroll_view:getChildByName("shadow2")
    shadow2_img:setLocalZOrder(HIGH_ZORDER)

    self.quarry_btn = self.mining_img:getChildByName("quarry")
    self.event_ether_mission_img = self.scroll_view:getChildByName("mission1")
    self.event_ether_mission_img:setLocalZOrder(TOUCH_ZORDER)
    self.event_monster_mission_img = self.scroll_view:getChildByName("mission2")
    self.event_monster_mission_img:setLocalZOrder(TOUCH_ZORDER)
    
    local shadow3_img = self.scroll_view:getChildByName("shadow3")
    shadow3_img:setLocalZOrder(HIGH_ZORDER)

    self.event_counts_text = {}

    self.event_counts_text[1] = shadow3_img:getChildByName("value1")
    self.event_counts_text[2] = shadow3_img:getChildByName("value2")

    local shadow4_img = self.scroll_view:getChildByName("shadow4")
    shadow4_img:setLocalZOrder(HIGH_ZORDER)

    self.event_counts_text[3] = shadow4_img:getChildByName("value1")
    self.event_counts_text[4] = shadow4_img:getChildByName("value2")
    self.event_counts_text[5] = shadow4_img:getChildByName("value3")


    self.escorting_node = self.scroll_view:getChildByName("shadow2_6")
    self.escort_carnival_node = self.scroll_view:getChildByName("shadow2_7")
    self.escort_finish_node = self.scroll_view:getChildByName("shadow2_8")
    if self.escorting_node then
        self.escorting_node:setLocalZOrder(HIGH_ZORDER)
        self.escorting_node:setVisible(false)
        self.escorting_cool_down_text = self.escorting_node:getChildByName("value1")
    end
    if self.escort_carnival_node then
        self.escort_carnival_node:setLocalZOrder(HIGH_ZORDER)
        self.escort_carnival_node:setVisible(false)
    end

    if self.escort_finish_node then
        self.escort_finish_node:setLocalZOrder(HIGH_ZORDER)
        self.escort_finish_node:setVisible(false)
    end
    self.escorting_cool_down_text = self.escorting_node:getChildByName("value1")

    

    local shadow5_img = self.scroll_view:getChildByName("shadow2_5")
    if shadow5_img then
        shadow5_img:setLocalZOrder(HIGH_ZORDER)
        self.escort_counts_text = shadow5_img:getChildByName("value1")

        shadow5_img:setVisible(feature_config:IsFeatureOpen("rune_and_tramcar"))
    end
    self.bottom_bar_img = self.root_node:getChildByName("bottom_bar")
    self.demon_medal = self.bottom_bar_img:getChildByName("badge_number")
    self.bottom_pickaxe_count_text = self.bottom_bar_img:getChildByName("dig_number")
    self.bottom_pickaxe_add_img = self.bottom_bar_img:getChildByName("shadow1")
    self.bottom_pickaxe_add_img:setTouchEnabled(true)
    self.bottom_dig_btn = self.bottom_bar_img:getChildByName("dig_btn")
    self.bottom_dig_btn:setTouchEnabled(true)

    self.bottom_demon_img = self.bottom_bar_img:getChildByName("shadow2")
    self.bottom_demon_img:setTouchEnabled(true)

    self.boss_img = self.scroll_view:getChildByName("boss")
    self.boss_img:setTouchEnabled(true)
    self.boss_img:setLocalZOrder(TOUCH_ZORDER)

    self.unlock_node = self.boss_img:getChildByName("unlock")
    self.unlock_node:setVisible(false)
    
    self.boss_bp_percent_template = self.unlock_node:getChildByName("hp_bar")
    
    self.boss_bp_percent_template:setVisible(false)
    self.boss_bp_text = self.unlock_node:getChildByName("value")
    self.boss_bp_text:setLocalZOrder(100)

    self.boss_bp_progresses = {}
    for index = 1, BOSS_BP_PROGRESS_SHOW_NUM do 
       local progress_panel = bp_progress_panel.New()
       progress_panel:Init(self.boss_bp_percent_template:clone(), index)
       self.unlock_node:addChild(progress_panel.root_node)
       self.boss_bp_progresses[index] = progress_panel
    end
    self.back_progress = self.boss_bp_progresses[1]
    self.front_progress = self.boss_bp_progresses[2]
   
    self.lock_node = self.boss_img:getChildByName("lock")
    self.lock_node:setVisible(true)

    self.unlock_boss_resource_value_text = self.lock_node:getChildByName("value")
    self.unlock_boss_resource_value_text:setString(constants["OPEN_CAVE_BOSS_DEMON_MEDAL"])
    
    self.shadow_img = self.boss_img:getChildByName("shadow")

    self:SaveOriginalUI(self.shadow_img)
    self:SaveOriginalUI(self.unlock_node)

    self.rule_img = self.boss_img:getChildByName("rule_img")

    self.boss_reborn_img = self.scroll_view:getChildByName("shadow5")
    self.boss_reborn_img:setLocalZOrder(HIGH_ZORDER)

    self.boss_reborn_lv_text = self.boss_reborn_img:getChildByName("name5")
    self.boss_reborn_cd_text = self.boss_reborn_img:getChildByName("value1")

    self.boss_genre_tip_img = self.scroll_view:getChildByName("shadow6")
    self.boss_genre_tip_img:setLocalZOrder(HIGH_ZORDER)

    self.boss_genre_tip_text = self.boss_genre_tip_img:getChildByName("value1")
    self.boss_genre_tip_img:setVisible(false)

    self.boss_genre_tip_floating_img = self.scroll_view:getChildByName("floating_explain")
    self.boss_genre_tip_floating_img:setLocalZOrder(HIGH_ZORDER)

    self.boss_genre_tip_floating_desc_text = self.boss_genre_tip_floating_img:getChildByName("desc")
    self.boss_genre_tip_floating_desc_text:setString(lang_constants:Get("mining_boss_genre_addition_text"))

    self.boss_genre_tip_floating_img:setVisible(false)

    self.boss_max_bp = 0
    self.math_ceil = math.ceil

    --r2界面多语调整
    local badge_desc_offset_x = platform_manager:GetChannelInfo().mining_main_badge_desc_offset_x
    if badge_desc_offset_x then
        local badge_desc = self.bottom_bar_img:getChildByName("badge_desc")
        badge_desc:setPositionX(badge_desc:getPositionX() + badge_desc_offset_x)
    end

    self:UpdateBossMaxBp()
    self.boss_bp = mining_logic.cave_boss_bp 

    self:ResetBossBpData()

    self:InitEventOpenData()
    self:HandleBossTimeData()
    self:UpdateBossGenreAddition()

    self:RegisterEvent()
    self:RegiserWidgetEvent()
end

function mining_main_panel:LoadAnimation()
    if not self.load_animation then 
        self.mining_animation_node = animation_manager:GetAnimationNode("mining")
        self.mining_animation_node:setAnchorPoint(cc.p(0, 1))
        self.mining_animation_node:setPosition(cc.p(0, client_constants["MINING_MINE_ANIMATION_POS_Y"])) 
        self.mining_animation_bg_node:addChild(self.mining_animation_node)

        self.animation_boss_img = self.mining_animation_node:getChildByName("Panel_1"):getChildByName("Panel_game_4"):getChildByName("Image_boss")
        self.animation_boss_img:setVisible(false)

        self.mining_action = animation_manager:GetTimeLine("mining_timeline")
        self.mining_animation_node:runAction(self.mining_action)
        self.mining_action:gotoFrameAndPlay(0, 885, true)

        self.load_animation = true 
    end
end

function mining_main_panel:RemoveAnimation()
    if self.load_animation then 
        animation_manager:RemoveTimeLine("mining_timeline")
        self.mining_action = nil

        self.mining_animation_node:removeFromParent()
        animation_manager:RemoveAnimation("mining")
        self.mining_animation_node = nil
        self.animation_boss_img = nil

        self.load_animation = false
    end
end

function mining_main_panel:SaveOriginalUI(node)
    node.position_x = node:getPositionX()
    node.position_y = node:getPositionY()
    node.rotation_value = node:getRotation()
    node.scale_x = node:getScaleX()
    node.scale_y = node:getScaleY()
end

function mining_main_panel:ResetUI(node)
    node:setPosition(node.position_x, node.position_y)
    node:setScale(node.scale_x, node.scale_y)
    node:setRotation(node.rotation_value)
end

function mining_main_panel:PlayBossShakeAnimation(node)
    -- 队列
    self:ResetUI(node)

    local c_scale_x = node:getScaleX()
    local c_scale_y = node:getScaleY()
    node:setAnchorPoint(cc.p(0.5,0.5))
    local seq_shake = cc.Sequence:create(cc.MoveBy:create(0.05, cc.p(-12,0)),
                                         cc.MoveBy:create(0.05, cc.p(12,0)),
                                         cc.MoveBy:create(0.07, cc.p(-5,0)),
                                         cc.MoveBy:create(0.07, cc.p(5,0)),
                                         cc.MoveBy:create(0.1, cc.p(-2.5,0)),
                                         cc.MoveBy:create(0.1, cc.p(2.5,0))) 

    local seq_rotation = cc.Sequence:create(cc.RotateBy:create(0.05,-20),
                                         cc.RotateBy:create(0.05,20),
                                         cc.RotateBy:create(0.07,-10),
                                         cc.RotateBy:create(0.07,10),
                                         cc.RotateBy:create(0.1,-5),
                                         cc.RotateBy:create(0.1,5))

    local sequence = cc.Sequence:create(--cc.DelayTime:create(0.1),
                     cc.ScaleTo:create(0.05, c_scale_x + 0.03),
                     cc.Spawn:create({seq_shake,seq_rotation}),
                     -- cc.Spawn:create({   --cc.MoveTo:create(0.18, cc.p(c_x-5,c_y))
                     -- seq_shake}),
                     cc.ScaleTo:create(0.05, c_scale_x)
                     -- cc.DelayTime:create(0.06),
                     -- cc.MoveTo:create(0.12, cc.p(c_x+3,c_y)), -- cc.MoveTo:create(0.12, cc.p(c_x,c_y))
                     --cc.Spawn:create({ seq_shake}),
                     --cc.MoveTo:create(0.05, cc.p(c_x,c_y))
                     )

    --local action = cc.RepeatForever:create(sequence)
    node:runAction(sequence)
end

function mining_main_panel:AdjustProgressColor()
    self.back_progress:UpdateProgressColor(self.current_progress - 1)
    self.front_progress:UpdateProgressColor(self.current_progress)
end

function mining_main_panel:UpdateProgressData(current_boss_bp)
    local max_bp, min_bp, index = self:ComputeBpBoundary(current_boss_bp)    

    self.current_progress = index 
    self.current_progress_max_bp = max_bp
    self.current_progress_min_bp = min_bp
end

function mining_main_panel:ComputeBpBoundary(current_boss_bp)
    local current_boss_bp = current_boss_bp
    local last_one_max_bp = self.boss_max_bp - self.bp_per_allprogresses * (BOSS_BP_PROGRESS_NUM - 1)
    local max_bp 
    local min_bp = 0
    local progress_index = BOSS_BP_PROGRESS_NUM
    for index = 1, BOSS_BP_PROGRESS_NUM do 
        max_bp = last_one_max_bp + self.bp_per_allprogresses * (index - 1)
        if current_boss_bp <= max_bp then 
            progress_index = index 
            break
        end
        min_bp = max_bp
    end

    return max_bp, min_bp, progress_index
end

function mining_main_panel:SwitchProgressPanel()
    local t_panel = self.front_progress 
    self.front_progress = self.back_progress
    self.back_progress = t_panel
end 

function mining_main_panel:FixProgressAttribute()
    self.front_progress:SetProgressOpacity(100)
    self.front_progress:SetProgressPercent(100)
    self.back_progress:SetProgressPercent(100)
    self.back_progress:SetProgressOpacity(BACK_PROGRESS_PANEL_DEFAULT_OPACITY)
    self.back_progress:SetRenderOrder(PROGRESS_ZORDER["back"])
    self.front_progress:SetRenderOrder(PROGRESS_ZORDER["front"])
end

function mining_main_panel:ResetBossBpData()
    self.bp_per_allprogresses = math.floor(self.boss_max_bp / BOSS_BP_PROGRESS_NUM)
    self.current_progress = BOSS_BP_PROGRESS_NUM 
    
    self:FixProgressAttribute()
    self:UpdateProgressData(self.boss_bp)
    self:AdjustProgressColor()
    self.back_progress:Show()
    self.front_progress:Show()
    self.front_progress:SetProgressPercent(math.floor((self.boss_bp - self.current_progress_min_bp) / (self.current_progress_max_bp - self.current_progress_min_bp) * 100))

end

function mining_main_panel:CaculateProgressPercent(demage_value, old_boss_bp)
    local demage_value = demage_value or 0
    local math_floor = math.floor 
    local old_boss_bp = old_boss_bp or 0 

    if demage_value > 0 then 
       local function UpdateProgressBar(command_data)
          if #command_data > 0 then 
             local t_command_data = command_data[1]
             local t_boss_bp_value = t_command_data.boss_bp_value
             local t_percent = t_command_data.percent
             self.boss_bp_text:setString(string.format(lang_constants:Get("mining_cave_boss_bp_desc"), panel_util:ConvertUnit(t_boss_bp_value), panel_util:ConvertUnit(self.boss_max_bp)))
             
             if t_command_data.switch_flag then 
                self.front_progress:SetProgressPercent(0)
                --self:PlayBossShakeAnimation() 
                self:UpdateProgressData(t_command_data.switch_bp_value)
                self:SwitchProgressPanel()
                self:FixProgressAttribute()
                self:AdjustProgressColor() 
             end
             
             self.front_progress:SetProgressPercent(self.front_progress.percent_value - t_percent)
            
             local add_opacity = math_floor((100 - self.front_progress.percent_value) / 2)
             if self.current_progress ~= 1 then
                self.back_progress:SetProgressOpacity(self.back_progress.opacity + add_opacity)
             end
             
            if t_command_data.end_flag then 
                if t_boss_bp_value == 0 then 
                    self:HandleBossTimeData()
                    self:UpdateBossMaxBp()
                    self:UpdateBossGenreAddition()
                    self:ResetBossBpData()
                end
                self.play_boss_bp_animation = false
             end
             
             table.remove(command_data, 1)
             performWithDelay(self.unlock_node, function() UpdateProgressBar(command_data) end, 0.5 / ANIMATE_FPS)
          end
       end
       
       local command_data = {}
       local compute_old_bp_value = old_boss_bp
       local real_demage_value = math.min(demage_value, old_boss_bp)
       local compute_bp_max = self.current_progress_max_bp
       local compute_bp_min = self.current_progress_min_bp
       local compute_index = self.current_progress
       local current_progress_max_bp = compute_bp_max - compute_bp_min
       local all_percent
       local remain_all_percent = 0
       if compute_old_bp_value - real_demage_value < compute_bp_min and compute_index > 1 then 
          local part_value = compute_old_bp_value - compute_bp_min
          all_percent = math.ceil(part_value / current_progress_max_bp * 100)
          local remain_bp_max, remain_bp_min, remain_index = self:ComputeBpBoundary(compute_old_bp_value - real_demage_value)
          remain_all_percent =  math.ceil((real_demage_value - part_value) / (remain_bp_max - remain_bp_min) * 100)
       else
          all_percent = math.ceil(real_demage_value / current_progress_max_bp * 100)
       end

       local per_bp_value = math_floor(real_demage_value / ANIMATE_FPS)
       local accu_percent = 0
       for index = 1, ANIMATE_FPS do 
           local t = {}
           t.switch_flag = false
           if index == ANIMATE_FPS then 
              compute_old_bp_value = old_boss_bp - real_demage_value
              t.end_flag = true
              per_bp_value = real_demage_value - per_bp_value * (ANIMATE_FPS - 1)
           else
              compute_old_bp_value = compute_old_bp_value - per_bp_value
           end
           
           t.boss_bp_value = compute_old_bp_value
           if compute_old_bp_value <= compute_bp_min and compute_index > 1 then
              t.switch_flag = true
              t.switch_bp_value = compute_old_bp_value
              local balance = compute_bp_min - compute_old_bp_value
              compute_bp_max, compute_bp_min, compute_index = self:ComputeBpBoundary(compute_old_bp_value)   
              current_progress_max_bp = compute_bp_max - compute_bp_min
              t.percent = math_floor((per_bp_value - balance) / current_progress_max_bp * 100)
              all_percent = remain_all_percent
              accu_percent = 0
           else
              t.percent = math_floor(per_bp_value / current_progress_max_bp * 100)
           end

           if index == ANIMATE_FPS then 
              t.percent = all_percent - accu_percent
           else
              accu_percent = t.percent + accu_percent
           end

           table.insert(command_data,t)
       end 
       self:PlayBossShakeAnimation(self.shadow_img)
       self:PlayBossShakeAnimation(self.unlock_node)
       performWithDelay(self.unlock_node, function() UpdateProgressBar(command_data) end, 0.5/ANIMATE_FPS)
    else
        self.play_boss_bp_animation = false
        if demage_value < 0 then 
           self:UpdateBossMaxBp()
           self:ResetBossBpData()
        end
    end
end

function mining_main_panel:Show()
    animation_manager:LoadAnimation("mining")
    self:LoadAnimation()
    self.play_boss_bp_animation = false
    self:ResetUI(self.unlock_node)
    self:ResetUI(self.shadow_img)
    self.root_node:setVisible(true)
    self:QueryInfo()
    --  挖矿界面已经完整的显示出来了
    graphic:DispatchEvent("jump_finish",JUMP_CONST["mining"])   
end

function mining_main_panel:Hide()
    self.play_boss_bp_animation = false
    self.root_node:setVisible(false)
    self:RemoveAnimation()
end

function mining_main_panel:QueryInfo()
    if feature_config:IsFeatureOpen("resource_recycle") then
        self.can_into_resource_recycle = false
        resource_recycle_logic:Query()
    end
end

function mining_main_panel:HandleBossTimeData()
    local time = mining_logic.cave_boss_end_time - time_logic:Now()
    if time <= 0 then 
        time = 0
    end
    self.boss_reborn_time_cd = time
end

function mining_main_panel:InitEventOpenData()
    self.today = -1
    self.today_cave_event_open = {
        [1] = false,
        [2] = false,
        [3] = false,
        [4] = false,
        [5] = false
    }
end

function mining_main_panel:UpdatePickaxeCount()
    self.pickaxe_count_text:setString(panel_util:ConvertUnit(mining_logic.dig_count))
    --居中显示
    self.pickaxe_count_text:setAnchorPoint({x=0.5,y=0.5})
    self.pickaxe_count_text:setPosition({x=67,y=27})

    self.bottom_pickaxe_count_text:setString(mining_logic.dig_count .. "/" .. mining_logic.dig_max_count)
end

function mining_main_panel:UpdateBossBadge()
    local demon_medal = resource_logic:GetResourcenNumByName("demon_medal")
    local color_value 
    if demon_medal < 5 then 
        color_value = 0xff0000
    else
        color_value = 0xffffff
    end

    self.demon_medal:setColor(panel_util:GetColor4B(color_value))
    self.demon_medal:setString(panel_util:ConvertUnit(demon_medal))
end

function mining_main_panel:UpdateEventOpenData()
    local time_now = time_logic:Now()
    local date_now = time_logic:GetDateInfo(time_now)
    if self.today ~= date_now.wday then 
        self.today = date_now.wday
        local open_event_data = mining_logic.cave_config_info[self.today] 
        for cave_type = 1, 5 do
            local find_flag = false
            for kk,vv in pairs(open_event_data) do
               if cave_type == vv then 
                  find_flag = true
                  break
               end
            end
            self.today_cave_event_open[cave_type] = find_flag
        end
    end
end

function mining_main_panel:UpdateBossRebornCdTime(time)
    self.boss_reborn_time_cd = self.boss_reborn_time_cd - time 
    if self.boss_reborn_time_cd <= 0 then 
        self.boss_reborn_time_cd = 0
    end
    self.boss_reborn_cd_text:setString(panel_util:GetTimeStr(self.boss_reborn_time_cd))
    self.boss_reborn_lv_text:setString(string.format(lang_constants:Get("mining_cave_boss_level"), mining_logic.cave_boss_lv))
end

function mining_main_panel:UpdateBossMaxBp()
    local boss_lv 
    if not mining_logic.cave_boss_lv or mining_logic.cave_boss_lv == 0 then 
       boss_lv = 1
    else
       boss_lv = mining_logic.cave_boss_lv
    end
    
    local data = mining_logic:GetCaveEventData(constants["CAVE_BOSS_EVENT_TYPE"], boss_lv)

    if not data then
        return
    end

    self.boss_max_bp = math.max(data.max_bp, mining_logic.cave_boss_bp)
    if mining_logic.cave_boss_bp <= 0 then 
       mining_logic.cave_boss_bp = data.max_bp 
    end
end

function mining_main_panel:UpdateBossGenreAddition()
    local boss_lv 
    if not mining_logic.cave_boss_lv or mining_logic.cave_boss_lv == 0 then 
       boss_lv = 1
    else
       boss_lv = mining_logic.cave_boss_lv
    end

    local boss_config = mining_logic:GetCaveEventData(constants["CAVE_BOSS_EVENT_TYPE"], boss_lv)
    local genre_table = common_function_util.Split(boss_config.genre_addition, '|')
    local genre_text = ""
    if #genre_table > 0 then 
       for k, v in ipairs(genre_table) do
          local temp_name = lang_constants:Get("mercenary_genre" .. tostring(v))
          genre_text = genre_text .. temp_name
       end
    end
    self.boss_genre_tip_text:setString(genre_text)
end

function mining_main_panel:UpdateBossBp(flag)
    if not flag then
       self.play_boss_bp_animation = true
    end
    self.boss_bp = mining_logic.cave_boss_bp 
end

function mining_main_panel:Update(elapsed_time)
 
    self:UpdateEventOpenData() 
    self:UpdateBossBadge()
    
    self:UpdatePickaxeCount()
    self:UpdateBattleCounts()

    self:UpdateBossRebornCdTime(elapsed_time)
    self:CheckBossOpen()
    self:UpdateBossHpText()
    --矿山信息
    self:UpdateMineCounts()

    --刷新钻地进度和过热度
    self:UpdateResourceRecycle()

    self:UpdateEscortText()
end

function mining_main_panel:UpdateBossHpText()
    if self.play_boss_bp_animation then 
        return
    end
    self.boss_bp_text:setString(string.format(lang_constants:Get("mining_cave_boss_bp_desc"), panel_util:ConvertUnit(self.boss_bp), panel_util:ConvertUnit(self.boss_max_bp)))
end

function mining_main_panel:CheckEventOpen(cave_type)
    return self.today_cave_event_open[cave_type]
end

function mining_main_panel:UpdateBattleCounts()
    local not_open_text = lang_constants:Get("mining_cave_event_not_open")
    local display_text
    local color_value
    for cave_type = 1, 5 do 
        local daily_counts = constants["CAVE_DAILY_CHALLENGE_NUM"][cave_type]
        color_value = 0xffe08a
        display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), mining_logic.cave_challenge_nums[cave_type], daily_counts)
        if not self:CheckEventOpen(cave_type) then
           display_text = not_open_text
           color_value = 0x887646
        end
        self.event_counts_text[cave_type]:setColor(panel_util:GetColor4B(color_value))
        self.event_counts_text[cave_type]:setString(display_text)
    end

    display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), escort_logic:GetRemainEscortTimes(), constants["DEFAULT_ESCORT_TIMES"])
    color_value = 0xffe08a
    if not user_logic:IsFeatureUnlock(client_constants["FEATURE_TYPE"]["escort_and_rune"], false) then
        display_text = not_open_text
        color_value = 0x887646
    end
    if self.escort_counts_text then
        self.escort_counts_text:setColor(panel_util:GetColor4B(color_value))
        self.escort_counts_text:setString(display_text)
    end
end

function mining_main_panel:UpdateEscortText()
    if feature_config:IsFeatureOpen("rune_and_tramcar") then
        local escort_info = escort_logic:GetEscortInfo()
        if escort_info.status == constants["ESCORT_STATUS"]["FINISH"] then
            self.escorting_node:setVisible(false)
            if self.escort_finish_node then
                self.escort_finish_node:setVisible(true)
            end
        elseif escort_info.status == constants["ESCORT_STATUS"]["ESCORTING"] then
            self.escorting_node:setVisible(true)
            if self.escort_finish_node then
                self.escort_finish_node:setVisible(false)
            end
            self.escorting_cool_down_text:setString(panel_util:GetTimeStr(math.max(escort_info.escort_end_time - time_logic:Now(), 0)))
        else
            self.escorting_node:setVisible(false)
            if self.escort_finish_node then
                self.escort_finish_node:setVisible(false)
            end
        end
    end
end

function mining_main_panel:UpdateMineCounts()
    if feature_config:IsFeatureOpen("mine_and_cultivation") then
        --矿山掠夺次数
        self.mine_plunder_text:setString(mine_logic.remain_rob)
        --矿山开采队列
        self.mine_extract_text:setString(mine_logic:GetMinesCurrent().."/"..3)
    end
end

function mining_main_panel:UpdateResourceRecycle()
    if not feature_config:IsFeatureOpen("resource_recycle") then
        return
    end

    if self.temperature_value then
        local per = resource_recycle_logic.temperature / 100
        self.temperature_value:setString(per .. "%")
    end

    if self.process_value then
        self.process_value:setString((resource_recycle_logic.process/100) .. "%")
    end
end

function mining_main_panel:SwitchAnimationBoss(flag)
    if self.animation_boss_img then 
       self.animation_boss_img:setVisible(flag)
    end
end

function mining_main_panel:CheckBossOpen()
    if feature_config:IsFeatureOpen("cave_boss") then
        self.boss_img:setVisible(true)
        if mining_logic.cave_boss_lv == 0 then 
            self.boss_img:setTouchEnabled(true)
            self.boss_reborn_img:setVisible(false)
            self.unlock_node:setVisible(false)
            self.boss_genre_tip_img:setVisible(false)
            self.lock_node:setVisible(true)
            self:SwitchAnimationBoss(false)
        else
            self.boss_img:setTouchEnabled(true)
            self.boss_reborn_img:setVisible(true)
            self.unlock_node:setVisible(true)
            self.boss_genre_tip_img:setVisible(true)
            self.lock_node:setVisible(false)
            self:SwitchAnimationBoss(true)
        end
    else
        self.boss_img:setVisible(false)
        self.boss_reborn_img:setVisible(false)
        self.unlock_node:setVisible(false)
        self.boss_genre_tip_img:setVisible(false)
        self.lock_node:setVisible(false)
        self:SwitchAnimationBoss(false)
    end
end

function mining_main_panel:RegisterEvent()

    graphic:RegisterEvent("cave_boss_update", function(unlock_flag)
        if not self.root_node:isVisible() then
            return
        end
        if unlock_flag then 
           self:HandleBossTimeData()
           self:UpdateBossMaxBp()
           self:UpdateBossGenreAddition()
        end
        self:UpdateBossBp(unlock_flag)
    end)

    graphic:RegisterEvent("guide_open", function()
        if self.root_node:isVisible() and self.scroll_view ~= nil then
            -- print("引导开启了，这里要将scrollView jumpTotop ")
            self.scroll_view:jumpToTop()
        end
    end)

    graphic:RegisterEvent("cave_boss_bp_animation", function(demage_value, old_boss_bp)
        if not self.root_node:isVisible() then
            return
        end

        performWithDelay(self.unlock_node, function() self:CaculateProgressPercent(demage_value, old_boss_bp) end, 1.1)
    end)
    -- 跳入BOOS界面
    graphic:RegisterEvent("to_mining_boos", function()
           self:boos_process() 
           self.scroll_view:scrollToBottom(0.01,false) --boos界面要跳转到最下面 
        end)
    --查询冗余资源信息成功
    graphic:RegisterEvent("query_resource_recycle_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self.can_into_resource_recycle = true
    end)
    
end
--处理boos区域
function mining_main_panel:boos_process()
    if not feature_config:IsFeatureOpen("cave_boss") then
        graphic:DispatchEvent("show_prompt_panel", "feature_is_opening_soon")
        return
    end
    
    if not user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_boss"], true) then
        return
    end

    if self.unlock_node:isVisible() then 
        local event_config = mining_logic:GetCaveEventData(constants["CAVE_BOSS_EVENT_TYPE"], mining_logic.cave_boss_lv)
        graphic:DispatchEvent("show_world_sub_panel", "campaign_event_msgbox", client_constants["CAMPAIGN_MSGBOX_MODE"]["boss_cave"], event_config)
    elseif self.lock_node:isVisible() then 
        local mode = client_constants["CONFIRM_MSGBOX_MODE"]["open_cave_boss"]
        graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
    end
end

function mining_main_panel:RegiserWidgetEvent()
    
    self.mining_img:addTouchEventListener(function(widget, event_type)

        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            mining_logic:QueryBlockInfo()
        end
    end)

    if self.escort_btn then 
        self.escort_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if feature_config:IsFeatureOpen("rune_and_tramcar") then
                    if user_logic:IsFeatureUnlock(client_constants["FEATURE_TYPE"]["escort_and_rune"], true) then
                        escort_logic:QueryRobTargetList()
                    else
                        graphic:DispatchEvent("show_prompt_panel", "feature_is_opening_soon")
                    end
                end
            end
        end)
    end
    if self.vanity_btn then
        self.vanity_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
                local vanity_open_permanent_config = open_permanent_config[FEATURE_TYPE["vanity_adventure"]]
                if not vanity_open_permanent_config then
                    print("没有找到相应的配置")
                    return
                end
                local open_value = vanity_open_permanent_config.value  
                local is_unlock = adventure_logic:IsMazeClear(open_value)

                --判断是否开启条件
                if not is_unlock then
                    graphic:DispatchEvent("show_prompt_panel", "vanity_adventure_need_condition_desc", adventure_maze_config[open_value]["name"])
                    return
                end

                
                if feature_config:IsFeatureOpen("vanity_adventure") then
                    graphic:DispatchEvent("show_world_sub_scene", "vanity_main_sub_scene")
                else
                    graphic:DispatchEvent("show_prompt_panel", "feature_is_opening_soon")
                end
            end
        end)
    end

    if self.mine_btn then
        self.mine_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                if feature_config:IsFeatureOpen("mine_and_cultivation") then
                    if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mine_and_cultivation"], true) then
                        audio_manager:PlayEffect("click")
                        if mine_logic:GetMineAllRewardsList() then
                            graphic:DispatchEvent("show_world_sub_scene", "mine_sub_scene")
                        end
                    end
                end
            end
        end)
    end

    if self.resource_recycle_btn then
        self.resource_recycle_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                if not feature_config:IsFeatureOpen("resource_recycle") or not self.can_into_resource_recycle then
                    return
                end
                if feature_config:IsFeatureOpen("mine_and_cultivation") or true then
                    audio_manager:PlayEffect("click")
                    graphic:DispatchEvent("show_world_sub_scene", "resource_recycle_sub_scene")
                end
            end
        end)
    end

    self.quarry_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["quarry"]) then
               graphic:DispatchEvent("show_world_sub_scene", "quarry_sub_scene")
            else
                return
            end
        end
    end)

    self.event_ether_mission_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_explore"], true) then
                return
            end

            graphic:DispatchEvent("show_world_sub_scene", "cave_event_sub_scene", nil, CHOOSE_ETHER_CAVE)
        end
    end)

    self.event_monster_mission_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_golem"], true) then
                return
            end

            graphic:DispatchEvent("show_world_sub_scene", "cave_event_sub_scene", nil, CHOOSE_MONSTER_CAVE)
        end

    end)

    self.boss_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:boos_process()
        end
    end)
   
    self.rule_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if feature_config:IsFeatureOpen("cave_boss") then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("show_world_sub_panel", "mining_boss_rule_panel", mode)
            end
        end
    end)

    self.boss_genre_tip_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
           audio_manager:PlayEffect("click")
           self.boss_genre_tip_floating_img:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
           self.boss_genre_tip_floating_img:setVisible(false)
        end
    end)
    self.boss_genre_tip_img:setTouchEnabled(true)

    local add_pickaxe_touch_event = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel", 2)
        end
    end

    self.bottom_pickaxe_add_img:addTouchEventListener(add_pickaxe_touch_event)
    self.bottom_dig_btn:addTouchEventListener(add_pickaxe_touch_event)
end

return mining_main_panel
