local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local icon_panel = require "ui.icon_panel"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"
local resource_recycle_logic = require "logic.resource_recycle"

local resource_config = config_manager.resource_config
local PLIST_TYPE = ccui.TextureResType.plistType
local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()
local TOUCH_TIME = 30
local special_effects_number = 5
local RECYCLE_ANIMATION_TYPE = {
    ["STOP"] = 1,
    ["STOPING"] = 2,
    ["RUNING"] = 3,
} 

local special_effects_panel = panel_prototype.New()
special_effects_panel.__index = special_effects_panel

function special_effects_panel.New()
    return setmetatable({}, special_effects_panel)
end

function special_effects_panel:Init(root_node)
    self.root_node = root_node
    self.animation_node = cc.CSLoader:createNode("ui/recover_touch_yun.csb")
    self.root_node:addChild(self.animation_node)
    self.animation_node_timeline = animation_manager:GetTimeLine("recover_touch_yun_timeline")
    self.animation_node:runAction(self.animation_node_timeline)
    local event_frame_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "over" then
            self.can_play = true
            self:Hide()
        end
    end
    self.can_play = true
    self.animation_node_timeline:clearFrameEventCallFunc()
    self.animation_node_timeline:setFrameEventCallFunc(event_frame_call_function)
end

function special_effects_panel:Show()
    self.root_node:setVisible(true)
    if self.can_play then
        self.can_play = false
        local roat = math.random(360)
        self.animation_node:setRotation(roat)
        self.animation_node_timeline:gotoFrameAndPlay(1, 31, false)
    end
end

function special_effects_panel:SetTimeLineSpeed(speed)
    self.animation_node_timeline:setTimeSpeed(speed)
end


local resource_recycle_panel = panel_prototype.New(true)
function resource_recycle_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/resource_recycle_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn") 

    self.touch_tips_node = self.root_node:getChildByName("me_0")
    self.touch_tips_node_pos_y = self.touch_tips_node:getPositionY()
    self.touch_tips_node:setVisible(false)
    
    self.touch_times = self.root_node:getChildByName("hit_times"):getChildByName("turn_text")
    self.touch_times:setVisible(false)

    self.touch_time_text = self.root_node:getChildByName("bp_minus")
    self.touch_time_text:setVisible(false)
    
    self.bottom_node = self.root_node:getChildByName("me")
    self.bottom_node_pos_y = self.bottom_node:getPositionY()

    --添加材料按钮
    self.bag_btn = self.bottom_node:getChildByName("rune_box")
    self.bag_btn:setTouchEnabled(true)

    --选中的材料
    self.select_resource_node = self.bottom_node:getChildByName("bag_template")
    self.select_img = self.select_resource_node:getChildByName("item_icon")
    local text_bg = self.select_resource_node:getChildByName("text_bg") 
    text_bg:setVisible(true)
    self.select_num = text_bg:getChildByName("num")
    self.select_resource_node:setVisible(false)

    --增加按钮
    self.add_ten_btn = self.bottom_node:getChildByName("buy_num_bg"):getChildByName("add_btn_0")
    self.add_one_btn = self.bottom_node:getChildByName("buy_num_bg"):getChildByName("add_btn")
    self.sub_ten_btn = self.bottom_node:getChildByName("buy_num_bg"):getChildByName("add_btn_0_0")
    self.sub_one_btn = self.bottom_node:getChildByName("buy_num_bg"):getChildByName("sub_btn")

    self.now_use_numbet_text = self.bottom_node:getChildByName("buy_num_bg"):getChildByName("buy_num")

    --拖动条
    self.slider = self.bottom_node:getChildByName("Slider_1")

    --过热度
    local now_percent_node = self.bottom_node:getChildByName("temperature") 
    self.now_percent_text = now_percent_node:getChildByName("rune_number_0")

    --炼化进度
    self.loding_bar = self.root_node:getChildByName("depth"):getChildByName("lbar")

    --宝箱
    self.reward_box = self.root_node:getChildByName("depth"):getChildByName("bouns01_btn")
    self.reward_box:setVisible(false)

    --炼化按钮
    self.use_btn = self.root_node:getChildByName("formation_btn")

    --规则按钮
    self.rule_btn = self.root_node:getChildByName("view_info_btn")

    --动画节点
    self.animation_node =  self.root_node:getChildByName("ScrollView_4"):getChildByName("tower")

    self.animation_sp = cc.CSLoader:createNode("ui/recover.csb")
    self.animation_sp:setPosition(cc.p(self.animation_node:getContentSize().width/2,self.animation_node:getContentSize().height/2))
    self.animation_node:addChild(self.animation_sp)
    self.recover_timeline = animation_manager:GetTimeLine("recover_timeline")
    self.animation_sp:runAction(self.recover_timeline)
    self.recover_timeline:play("loop", true)

    local event_frame_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "over" then
            self.recover_timeline:play("stop_loop", true)
            if self.click_play then 
                resource_recycle_logic:Query()
                self.click_play = false
            end
            if self.random_text_id and self.root_node:isVisible() then
                graphic:DispatchEvent("show_world_sub_panel", "resource_recycle_bouns_msgbox", self.up_temperature, self.up_process, self.reward_list, self.random_text_id)
            end
        end
    end
    self.recover_timeline:clearFrameEventCallFunc()
    self.recover_timeline:setFrameEventCallFunc(event_frame_call_function)

    --手指动画
    self.finger_touch_node = self.root_node:getChildByName("touch")
    self.finger_touch_node:setVisible(false)
    self.finger_touch_sp = cc.CSLoader:createNode("ui/recover_touch.csb")
    self.finger_touch_node:addChild(self.finger_touch_sp)
    self.finger_touch_timeline = animation_manager:GetTimeLine("finger_touch_timeline")
    self.finger_touch_sp:runAction(self.finger_touch_timeline)
    self.finger_touch_timeline:gotoFrameAndPlay(1, 16, true)

    self.use_num = 0
    self.select_resource_template_id = 0
    self.boxs = {}
    self.touche_numbers = 0
    self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.RUNING

    self:AddMoreSpecialEffects()
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--显示界面
function resource_recycle_panel:Show()
    self.root_node:setVisible(true)
    self.select_resource_node:setVisible(false)

    local per = resource_recycle_logic.temperature / 100
    self.now_percent_text:setString(per .. "%")

    self:RestLoadUI()

    if self.click_play then 
        resource_recycle_logic:ClickPlayEnd(self.touche_numbers)
    else
        if per >= 100 then
            if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.STOP then
                self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.STOP
                self.recover_timeline:play("stop_loop", true)
            end
        else
            if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.RUNING then
                self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.RUNING
                self.recover_timeline:play("loop", true)
            end
        end

        self.loding_bar:setPercent(resource_recycle_logic.process/100)
        
        self:AddUseResource(0)
        self:RewardProgressShow()
        

        --设置动画速度
        self.animation_speed = 1
        self.recover_timeline:setTimeSpeed(self.animation_speed)

        
        --查询最新的
        resource_recycle_logic:Query()
    end

end

--隐藏该隐藏的按钮
function resource_recycle_panel:RestLoadUI()
    self.touch_tips_node:stopAllActions()
    self.bottom_node:stopAllActions()
    
    self.use_num = 0
    self.max_num = 0
    self.touch_time = 0
    self.touches_time = 0
    self.select_resource_template_id = 0
    self.select_resource_name = nil
    self.fresh_time = constants["RESOURCE_RECYCLE_FRESH_TIME"]    

    self.touch_add_btn = false
    self.start_click = false
    self.listener:setEnabled(false)
    self.touch_layer:setTouchEnabled(false)
    self.finger_touch_node:setVisible(false)
    self.touch_tips_node:setVisible(false)
    self.touch_times:setVisible(false)
    self.touch_time_text:setVisible(false)

    self.bottom_node:setPositionY(self.bottom_node_pos_y)
end

--加载宝箱
function resource_recycle_panel:RewardProgressShow()
   local resource_recycle_reward_config = config_manager.resource_recycle_reward_config or {}
   local i = 1 
   local all_height = self.loding_bar:getContentSize().width
   local all_width = self.loding_bar:getContentSize().height
   for k,conf in pairs(resource_recycle_reward_config) do
       if conf.type == 1 then
            if self.boxs[i] == nil then
                local box_node = self.reward_box:clone()
                self.boxs[i] = box_node
                self.root_node:getChildByName("depth"):addChild(box_node)
            end
            self.boxs[i]:setVisible(true)
            self.boxs[i]:setPositionY(-(all_height * conf.process / 10000) + 10)
            i = i + 1
       end
   end

   --最后一个宝箱位置在100%
   if self.boxs[i] == nil then
        local box_node = self.reward_box:clone()
        self.boxs[i] = box_node
        self.root_node:getChildByName("depth"):addChild(box_node)
    end
    self.boxs[i]:setVisible(true)
    self.boxs[i]:setPositionY(-all_height + 10)

end

--点击时多余的爆炸特效
function resource_recycle_panel:AddMoreSpecialEffects()
    self.special_effects_panels = {}
    for i=1,special_effects_number do
        local node = self.animation_sp:getChildByName("touch_" .. i)
        self.special_effects_panels[i] = special_effects_panel.New()
        self.special_effects_panels[i]:Init(node)
        self.special_effects_panels[i]:Hide()
    end
    
end

--Update定时器
function resource_recycle_panel:Update(elapsed_time)
    if self.touch_add_btn then
        self.touch_time = self.touch_time + elapsed_time
        if self.touch_time >= 0.5 then
            self.update_freq = self.update_freq + elapsed_time
            if self.update_freq >= 0.1 then
                self.update_freq = self.update_freq - 0.1
                self:AddUseResource(self.delta)
            end
        end
    end
    self.fresh_time = self.fresh_time - elapsed_time
    if self.fresh_time <= 0 and not self.click_play then
        self.fresh_time = constants["RESOURCE_RECYCLE_FRESH_TIME"]
        resource_recycle_logic:Query()
    end

    --点击倒计时
    self.touches_time = self.touches_time - elapsed_time
    if self.touches_time > 0 then
        self.touch_times:setVisible(true)
        self.touch_layer:setTouchEnabled(true)
        self.touch_time_text:setString(math.ceil(self.touches_time))
    else
        if self.touch_layer:isTouchEnabled() and self.start_click then 
            self.start_click = false
            self.listener:setEnabled(false)
            self.touch_time_text:setString("0")
            resource_recycle_logic:ClickPlayEnd(self.touche_numbers)
            self.touche_numbers = 0
            self.animation_speed = 1
            self.recover_timeline:setTimeSpeed(self.animation_speed)
        end
    end

    if self.animation_speed > 1 then
        self.animation_speed = self.animation_speed - elapsed_time
        self.recover_timeline:setTimeSpeed(self.animation_speed)
    end
    
end

function resource_recycle_panel:AddUseResource(add_num)
    if self.click_play then
        return
    end

    local add_end_num = self.use_num + add_num
    if add_end_num <= 0 then
        add_end_num = 0
    elseif add_end_num > self.max_num then
        add_end_num = self.max_num
    end

    self.use_num = add_end_num
    self.now_use_numbet_text:setString(self.use_num)
    if self.select_resource_name then
        local resource_max_num = resource_logic:GetResourcenNumByName(self.select_resource_name)
        self.slider:setPercent(self.use_num / resource_max_num * 100)
    else
        self.slider:setPercent(self.use_num / self.max_num * 100)
    end
    

    self:UpdateButtonState()

    self:UpdatePercent()
end

--刷新按钮状态
function resource_recycle_panel:UpdateButtonState()
    if self.use_num >= self.max_num then
        self.add_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.add_one_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.add_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.add_one_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end 

    if self.use_num <= 0 then
        self.use_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.sub_ten_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
        self.sub_one_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.use_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.sub_ten_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
        self.sub_one_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
    end 

    if self.max_num <= 0 then
        self.slider:setEnabled(false)
        self.slider:setColor(panel_util:GetColor4B(0x7F7F7F))
    else
        self.slider:setEnabled(true)
        self.slider:setColor(panel_util:GetColor4B(0xFFFFFF))
    end 
end

--刷新界面按钮属性值
function resource_recycle_panel:UpdateMaxUse()
    if not self.select_resource_name or self.select_resource_name == "" then
        --没有选择材料
        return 
    end
    local resource_template = resource_config[self.select_resource_template_id]
    self.max_num = resource_logic:GetResourcenNumByName(self.select_resource_name)
    --计算最大值
    local now_max_num = math.floor((10000 - resource_recycle_logic.temperature) / resource_template.temperature)    
    if now_max_num < self.max_num then
        self.max_num = now_max_num
    end
    self.use_num = 0
end

function resource_recycle_panel:UpdatePercent()
    if self.use_num <= 0 then
        local per = resource_recycle_logic.temperature / 100
        self.now_percent_text:setString(per.."%")
        if per >= 100 then
            if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.STOP then
                self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.STOP
                self.recover_timeline:play("stop_loop", true)
            end
        end
    else
        if self.select_resource_template_id >= 0 then
            local resource_template = resource_config[self.select_resource_template_id]
            local add_per = (resource_recycle_logic.temperature + resource_template.temperature * self.use_num ) /100
            self.now_percent_text:setString(add_per .. "%")
        end
    end 
end

function resource_recycle_panel:TouchEventLayer()
    local move_to = cc.MoveTo:create(0.5, cc.p(self.bottom_node:getPositionX(),self.bottom_node_pos_y - 200))
    self.bottom_node:stopAllActions()
    self.bottom_node:runAction(cc.Sequence:create(move_to,
        cc.CallFunc:create(function()
            self.touch_tips_node:setPositionY(self.touch_tips_node_pos_y - 200)
            self.touch_tips_node:stopAllActions()
            self.touch_tips_node:setVisible(true)
            self.touch_tips_node:runAction(cc.Sequence:create(cc.MoveTo:create(0.5, cc.p(self.touch_tips_node:getPositionX(), self.touch_tips_node_pos_y)),
                    cc.CallFunc:create(function()
                        self.touch_time_text:setString(TOUCH_TIME)
                        self.touche_numbers = 0
                        self.listener:setEnabled(true)
                        self.touch_layer:setTouchEnabled(true)
                        self.finger_touch_node:setVisible(true)
                        self.touch_times:setVisible(false)
                        self.touch_times:setString(self.touche_numbers)
                        self.touch_time_text:setVisible(true)
                    end)
            ))
    end)))
end

--每次点击播放动画
function resource_recycle_panel:PlaySpecialEffects()
    local can_play_index = {}
    for i=1,special_effects_number do
        if self.special_effects_panels[i] and self.special_effects_panels[i].can_play then
            table.insert(can_play_index, i)
        end
    end
    if #can_play_index > 0 then
        local random_index = math.random(1,#can_play_index)
        self.special_effects_panels[can_play_index[random_index]]:Show()
    end
end

--点击抖动动画
function resource_recycle_panel:PlayChatterAction()
    if not self.is_play_chatter then
        self.is_play_chatter = true
        local move1 = cc.MoveBy:create(0.06,cc.p(-5,0))
        local move2 = cc.MoveBy:create(0.06,cc.p(5,0))
        local move3 = cc.MoveBy:create(0.06,cc.p(0,4)) 
        local move4 = cc.MoveBy:create(0.06,cc.p(0,-4))
        self.root_node:runAction(cc.Sequence:create(move1,move2,move3,move4,cc.CallFunc:create(function()
                        self.is_play_chatter = false
                    end)))
    end
end

--检查过热度
function resource_recycle_panel:CheckTemperature()
    local per = resource_recycle_logic.temperature / 100
    if per >= 100 then
        if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.STOPING then
            self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.STOPING
            self.recover_timeline:play("stop", false)
        end
    else
        if self.random_text_id then
            if self.click_play then 
                resource_recycle_logic:Query()
                self.click_play = false
            end
            graphic:DispatchEvent("show_world_sub_panel", "resource_recycle_bouns_msgbox", self.up_temperature, self.up_process, self.reward_list, self.random_text_id)
        end
    end
end

function resource_recycle_panel:RegisterEvent()

    --炼化成功成功
    graphic:RegisterEvent("add_material_success", function(recv_msg, up_temperature, up_process)
        if not self.root_node:isVisible() then
            return
        end
        self.select_resource_node:setVisible(false)
        self.max_num = 0
        self.use_num = 0
        self.select_resource_name = nil
        
        self.loding_bar:setPercent(resource_recycle_logic.process/100)
        local now_process_number = resource_recycle_logic.process/100

        self.up_temperature = up_temperature
        self.up_process = up_process
        self.random_text_id = recv_msg.random_text_id
        self.reward_list = recv_msg.reward_list

        if now_process_number >= 100 then
            self.click_play = true
            self.touche_numbers = 0
            self:TouchEventLayer()
            return
        end

        self:AddUseResource(0)
        self:CheckTemperature()
        
    end)

    graphic:RegisterEvent("query_resource_recycle_success", function()
        if not self.root_node:isVisible() and not self.click_play then
            return
        end
        local per = resource_recycle_logic.temperature / 100
        self.now_percent_text:setString(per .. "%")

        if per >= 100 then
            if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.STOP then
                self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.STOP
                self.recover_timeline:play("stop_loop", true)
            end
        else
            if self.recover_timeline_type ~= RECYCLE_ANIMATION_TYPE.RUNING then
                self.recover_timeline_type = RECYCLE_ANIMATION_TYPE.RUNING
                self.recover_timeline:play("loop", true)
            end
        end

        self:UpdateMaxUse()
        self:AddUseResource(0)

        self.loding_bar:setPercent(resource_recycle_logic.process/100)
    end)

    graphic:RegisterEvent("resource_recycle_click_finish_success", function(reward_list)
        if not self.root_node:isVisible() then
            return
        end
        self.fresh_time = constants["RESOURCE_RECYCLE_FRESH_TIME"]
        
        self.touch_times:setVisible(false)
        self.touch_time_text:setVisible(false)
        self.listener:setEnabled(false)
        self.touch_layer:setTouchEnabled(false)
        self.bottom_node:setPositionY(self.bottom_node_pos_y)

        self.reward_list = reward_list

        self:CheckTemperature()
        self:UpdateButtonState()
    end)

    
end

function resource_recycle_panel:Hide()
    self.root_node:setVisible(false)
    self.listener:setEnabled(false)
end


function resource_recycle_panel:RegisterWidgetEvent()

    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.click_play then
                return
            end
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    local ok_func = function (resource_name)
        local template_id = constants['RESOURCE_TYPE'][resource_name]
        local resource_template = resource_config[template_id]
        self.select_resource_template_id = template_id
        self.select_resource_name = resource_name
        self.select_img:loadTexture(resource_template.icon, PLIST_TYPE)
        self.select_resource_node:setVisible(true)
        self.select_num:setString(resource_logic:GetResourcenNumByName(resource_name))

        self:UpdateMaxUse()
        self:AddUseResource(0)
    end

    self.bag_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.click_play then
                return
            end
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "resource_recycle_bag_msgbox", ok_func)
        end
    end)

    --增加或减少材料按钮
    self.add_ten_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local now_temperature = resource_recycle_logic.temperature / 100
            if now_temperature >= 100 then 
                graphic:DispatchEvent("show_prompt_panel", "this_is_full_of_use_resource")
                return false
            elseif self.max_num <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "not_select_resource")
                return false
            end

            self.touch_add_btn = true
            self.delta = 10
            self.touch_time = 0
            self.update_freq = 0
            
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.touch_add_btn = false
            if self.touch_time <= 1 then
                self:AddUseResource(10)
            end
        end
    end)

    self.add_one_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local now_temperature = resource_recycle_logic.temperature / 100
            if now_temperature >= 100 then 
                graphic:DispatchEvent("show_prompt_panel", "this_is_full_of_use_resource")
                return false
            elseif self.max_num <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "not_select_resource")
                return false
            end

            self.touch_add_btn = true
            self.delta = 1
            self.touch_time = 0
            self.update_freq = 0
            
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.touch_add_btn = false
            if self.touch_time <= 1 then
                self:AddUseResource(1)
            end
        end
    end)

    self.sub_ten_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local now_temperature = resource_recycle_logic.temperature / 100
            if now_temperature >= 100 then 
                graphic:DispatchEvent("show_prompt_panel", "this_is_full_of_use_resource")
                return false
            elseif self.max_num <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "not_select_resource")
                return false
            end
            
            self.touch_add_btn = true
            self.delta = -10
            self.touch_time = 0
            self.update_freq = 0
            
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.touch_add_btn = false
            if self.touch_time <= 1 then
                self:AddUseResource(-10)
            end
        end
    end)

    self.sub_one_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local now_temperature = resource_recycle_logic.temperature / 100
            if now_temperature >= 100 then 
                graphic:DispatchEvent("show_prompt_panel", "this_is_full_of_use_resource")
                return false
            elseif self.max_num <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "not_select_resource")
                return false
            end

            self.touch_add_btn = true
            self.delta = -1
            self.touch_time = 0
            self.update_freq = 0
            
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.touch_add_btn = false
            if self.touch_time <= 1 then
                self:AddUseResource(-1)
            end
        end
    end)

    --拖动条监听
    self.slider:addEventListener(function (widget, event_type)
        if event_type == 0 then
            if self.select_resource_name then
                local resource_max_num = resource_logic:GetResourcenNumByName(self.select_resource_name)

                local now_num = math.floor(widget:getPercent() / 100 * resource_max_num)
                if now_num > self.max_num then
                    self.slider:setPercent(self.max_num / resource_max_num * 100)
                    return
                end
                self.use_num = now_num
                self.now_use_numbet_text:setString(self.use_num)
                self:UpdateButtonState()
                self:UpdatePercent()
            end
        end
    end)

    --炼化按钮
    self.use_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.click_play then
                return
            end
            audio_manager:PlayEffect("click")
            if self.use_num > 0 then
                resource_recycle_logic:AddMaterial(self.select_resource_template_id, self.use_num)
            else
                local now_temperature = resource_recycle_logic.temperature / 100
                if now_temperature >= 100 then 
                    graphic:DispatchEvent("show_prompt_panel", "this_is_full_of_use_resource")
                else
                    graphic:DispatchEvent("show_prompt_panel", "not_select_resource")
                end
            end 
        end
    end)

    --规则按钮
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.click_play then
                return
            end
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "resource_recycle_rule_msgbox")
        end
    end) 

     self.touche_numbers = 0

    --屏幕触摸
    self.touch_layer = cc.Layer:create()
    self.touch_layer:setTouchEnabled(false)
    self.root_node:addChild(self.touch_layer)
    local event_dispatcher = self.touch_layer:getEventDispatcher()
    self.listener = cc.EventListenerTouchAllAtOnce:create()

    self.listener:registerScriptHandler(function(touches, event)
        local touch_num = #touches
        if self.touches_time <= 0 then
            self.touches_time = TOUCH_TIME
            self.start_click = true
            self.finger_touch_node:setVisible(false)
        end
        audio_manager:PlayEffect("click")
        return true
    end, cc.Handler.EVENT_TOUCHES_BEGAN)

    self.listener:registerScriptHandler(function(touches, event)
        local touch_num = #touches

    end, cc.Handler.EVENT_TOUCHES_MOVED)

    self.listener:registerScriptHandler(function(touches, event)
        if self.animation_speed <= 4 then
            self.animation_speed = self.animation_speed + 0.5
        end
        self.touche_numbers = self.touche_numbers + #touches
        self.touch_times:setString(self.touche_numbers)
        self:PlaySpecialEffects()
        self:PlayChatterAction()
    end, cc.Handler.EVENT_TOUCHES_ENDED)

    self.listener:setEnabled(false)
    event_dispatcher:addEventListenerWithSceneGraphPriority(self.listener, self.touch_layer)
    
end

return resource_recycle_panel

