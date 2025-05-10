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
local troop_logic = require "logic.troop"
local mine_logic = require "logic.mine"

local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local mine_nodes = {}
local RULE_LOCAL_ZORDER = 9999
local PLAYER_NUMBER = 6
local PLAYER_LOCAL_ZORDER = 10 
local PANEL_STATE = 0

local TIME_INDEX = {0.1,0.2,0.3,0.4,0.5,0.6}

--采矿按钮node
local mine_node_panel = panel_prototype.New()
mine_node_panel.__index = mine_node_panel

function mine_node_panel.New()
    return setmetatable({}, mine_node_panel)
end

function mine_node_panel:Init(root_node)
    self.root_node = root_node
    self.lock_img = self.root_node:getChildByName("lock_tip")

    local times_bg = self.root_node:getChildByName("times_bg_0")
    self.time_label = times_bg:getChildByName("Text_47")
    self.bg_img = self.root_node:getChildByName("floatstone_top")

    self.have_mine_reward_img = self.root_node:getChildByName("Image_370")

    --解锁动画
    self.unlock_animation_node = cc.CSLoader:createNode("ui/node_unlock.csb")
    self.root_node:addChild(self.unlock_animation_node,100)
    self.unlock_animation_node:setPosition(self.lock_img:getPosition())

    self.unlock_time_line_action = animation_manager:GetTimeLine("mine_unlock_timeline")
    self.unlock_animation_node:runAction(self.unlock_time_line_action)
    self.unlock_animation_node:setVisible(false)

    --小车动画
    self.car_animation_node = cc.CSLoader:createNode("ui/Node_xiaokuangche.csb")
    self.bg_img:addChild(self.car_animation_node,1)
    self.car_animation_node:setPosition(cc.p(self.bg_img:getContentSize().width/2+3, self.bg_img:getContentSize().height/2+1))

    self.car_time_line_action = animation_manager:GetTimeLine("mine_car_enter_out_timeline")
    self.car_animation_node:runAction(self.car_time_line_action)
    self.car_animation_node:setVisible(false)

    self.click_btn = self.root_node:getChildByName("Button_19")
    
    self:RegisterWidgetEvent()
end

function mine_node_panel:UpdateTime(elapsed_time)
    if self.info_conf and self.info_conf.status == client_constants.MINE_STATE.mining then 
        -- 开采中
        if self.duration > 0  then 
            self.duration = math.max(self.duration - elapsed_time, 0)
            self.time_label:setString(panel_util:GetTimeStr(self.duration))
            if self.duration == 0 then
                self.time_label:setString(lang_constants:Get("mine_is_fishing"))
                self.info_conf.status = client_constants.MINE_STATE.finish
            end
            self:UpdateRewardState()
        end
    end
end

function mine_node_panel:UpdateRewardState(is_run_animation)
    local rewards, num = mine_logic:GetCurrentRewardsByIndexAndLevel(self.info_conf.mine_index, self.info_conf.mine_level)
    if num > 0 or self.info_conf.status == client_constants.MINE_STATE.finish then
        if is_run_animation then
            self.have_mine_reward_img:stopAllActions()
            self.have_mine_reward_img:setScale(0.1)
            self.have_mine_reward_img:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,0.8),cc.ScaleTo:create(0.1,0.5),cc.ScaleTo:create(0.06,0.6)))
            self.have_mine_reward_img:setOpacity(0)
            self.have_mine_reward_img:runAction(cc.FadeIn:create(0.1))
        end
        self.have_mine_reward_img:setVisible(true)
    else
        self.have_mine_reward_img:setVisible(false)
    end
end

function mine_node_panel:Show(index, info_conf, show_animation, show_unlock_animation)
    self.root_node:setVisible(true)
    self.index = index
    self.info_conf = info_conf  --当前按钮的info

    if self.info_conf then
        self.lock_img:setVisible(false)
        self.unlock_animation_node:setVisible(false)
        
        self.duration = 0
        self.bg_img:setColor(cc.c3b(255,255,255))
        --判断是否解锁
        if self.info_conf.status == client_constants.MINE_STATE.lock then
            self.lock_img:setVisible(true)
            self.bg_img:setColor(cc.c3b(127,127,127))
            self.time_label:setString(lang_constants:Get("mine_is_lock"))
            self.car_animation_node:setVisible(false)
        elseif self.info_conf.status == client_constants.MINE_STATE.ready then
            -- 可以开采
            self.time_label:setString(lang_constants:Get("mine_is_ready"))
            self.car_animation_node:setVisible(false)
        elseif self.info_conf.status == client_constants.MINE_STATE.mining then 
            -- "开采中"  --设置时间
            local config = mine_logic:GetMineInfoConfig()
            local mine_config = config[self.info_conf.mine_level]
            self.duration = self.info_conf.beg_time + mine_config.full_time * 60 - time_logic:Now()
            
            if self.duration  <= 0 then
                --时间结束到达完成条件
                self.info_conf.status = client_constants.MINE_STATE.finish
                self.time_label:setString(lang_constants:Get("mine_is_fishing"))
            end
            if not self.car_animation_node:isVisible() then
                self.car_animation_node:setVisible(true)
                self.car_time_line_action:gotoFrameAndPlay(241, 242, false)
                local delay = cc.DelayTime:create(math.random(2,5))
                local sequence = cc.Sequence:create(delay, cc.CallFunc:create(function ()
                    self.car_time_line_action:gotoFrameAndPlay(0, 242, true)
                end))
                self.root_node:runAction(sequence)
            end 
            
        elseif self.info_conf.status == client_constants.MINE_STATE.finish then 
            -- print("开采完成")
            self.time_label:setString(lang_constants:Get("mine_is_fishing"))
            self.car_animation_node:setVisible(false)
        end
        self:UpdateRewardState(show_animation)
        self:ShowUnlockAnimation(show_unlock_animation)
    end
end

function mine_node_panel:ShowUnlockAnimation(show_unlock_animation)
    if show_unlock_animation then
        self.unlock_animation_node:setVisible(true)
        self.unlock_time_line_action:gotoFrameAndPlay(0, 60, false)
    end
end

function mine_node_panel:ShowkAnimation()
    self.unlock_animation_node:setVisible(true)
    self.unlock_time_line_action:gotoFrameAndPlay(0, 60, false)
end



--设置按钮状态
function mine_node_panel:RegisterWidgetEvent()

    --采矿按钮
    self.click_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --判断是否解锁
            if self.info_conf.status == client_constants.MINE_STATE.lock then
                -- print("未解锁")
                local mode = client_constants["CONFIRM_MSGBOX_MODE"]["mine_unlock"]
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.index)
            elseif self.info_conf.status == client_constants.MINE_STATE.ready then
                graphic:DispatchEvent("show_world_sub_panel", "mine_select_msgbox_panel", self.index)
            elseif self.info_conf.status == client_constants.MINE_STATE.mining  then 
                -- print("开采中")  -- print("开采完成")
                local rewards, num = mine_logic:GetCurrentRewardsByIndexAndLevel(self.info_conf.mine_index, self.info_conf.mine_level)
                if num > 0 then
                    graphic:DispatchEvent("show_world_sub_panel", "reward_mine_msgbox", rewards, num, self.info_conf.mine_index)
                else
                    graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("mining_now_title"),
                                lang_constants:Get("mining_now_desc"),
                                lang_constants:Get("mining_now_yes_btn"),
                                lang_constants:Get("mining_now_no_btn"),
                    function()
                         -- mine_logic:MineCancel(self.info_conf.mine_index)
                    end,
                    function()
                         mine_logic:MineCancel(self.info_conf.mine_index)
                    end)
                end
            elseif self.info_conf.status == client_constants.MINE_STATE.finish then
                local rewards, num = mine_logic:GetAllRewardsByIndexAndLevel(self.info_conf.mine_index, self.info_conf.mine_level)
                graphic:DispatchEvent("show_world_sub_panel", "reward_mine_msgbox", rewards, num, self.info_conf.mine_index)
            end
        end
    end)
end

--
local rob_target_panel = panel_prototype.New()
rob_target_panel.__index = rob_target_panel

function rob_target_panel.New()
    return setmetatable({}, rob_target_panel)
end

function rob_target_panel:Init(root_node)
    self.root_node = root_node
    self.name_text = self.root_node:getChildByName("name")
    self.name_text:setAnchorPoint(cc.p(0.5, 0.5))
    self.mine_type_img = self.root_node:getChildByName("mine") 
    self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node)
    self.head_icon_img = self.root_node:getChildByName("hero")
    self.head_icon_img:setVisible(false)
    self.icon_panel.root_node:setScale(0.65)
    self.old_level = 0
    self.icon_panel:SetPosition(self.head_icon_img:getPositionX(), self.head_icon_img:getPositionY())
    self.name_bg = self.root_node:getChildByName("bg")

    self.animation_node = cc.CSLoader:createNode("ui/node_mine_change.csb")
    self.animation_node:setScale(3)
    self.root_node:addChild(self.animation_node,-1)
    self.animation_node:setPositionX(self.root_node:getContentSize().width/2)

    self.time_line_action = animation_manager:GetTimeLine("mine_rob_enter_timeline")
    self.animation_node:runAction(self.time_line_action)
    self.animation_node:setVisible(false)

    self.old_animation_img = self.animation_node:getChildByName("mine_icon_1")
    self.now_animation_img = self.animation_node:getChildByName("mine_icon_2")
    
    local event_frame_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "mine_icon_end" then
            if self.delay_time == TIME_INDEX[#TIME_INDEX] then
                PANEL_STATE = 0
            end
            self.name_text:setVisible(true)
            self.name_bg:setVisible(true)
            self.name_text:setString(self.info_conf.leader_name)

            --玩家文字居中
            local width = math.max(self.name_text:getVirtualRendererSize().width,130)
            self.name_text:setPositionX(self.name_bg:getPositionX()+width/2+15)
            self.name_bg:setContentSize(cc.size(width+15,self.name_bg:getContentSize().height))

            local template_id = self.info_conf.troop_info.template_id_list[1]
            self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], template_id, nil, nil, false)
        end
    end
    self.time_line_action:clearFrameEventCallFunc()
    self.time_line_action:setFrameEventCallFunc(event_frame_call_function)

end

function rob_target_panel:Show(info_conf, delay_time)
    self.root_node:setVisible(true)
    if info_conf then
        self.info_conf = info_conf
        self.delay_time = delay_time

        self.now_level = info_conf.mine_level
        if self.old_level == 0 then
            self.old_level = info_conf.mine_level
        end

        if delay_time and delay_time > 0 then
            self.root_node:stopAllActions()
            self.root_node:runAction(cc.Sequence:create(cc.DelayTime:create(delay_time), 
                                    cc.CallFunc:create(function()
                                        self:PlayAnimation()
                                        end)))
        else
            self.name_text:setString(info_conf.leader_name)

            --玩家文字居中
            local width = math.max(self.name_text:getVirtualRendererSize().width,120)
            self.name_text:setPositionX(self.name_bg:getPositionX()+width/2+15)
            self.name_bg:setContentSize(cc.size(width+15,self.name_bg:getContentSize().height))

            local template_id = info_conf.troop_info.template_id_list[1]
            self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], template_id, nil, nil, false)
            self.mine_type_img:setVisible(false) --loadTexture(client_constants["MINE_TYPE_IMG_PATH"][info_conf.mine_level], PLIST_TYPE)
            self.animation_node:setVisible(true)
            self.name_bg:setVisible(true)
            self.now_animation_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][info_conf.mine_level], PLIST_TYPE)
        end
    end
end

function rob_target_panel:PlayAnimation()
    self.now_animation_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][self.info_conf.mine_level], PLIST_TYPE)
    self.old_animation_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][self.old_level], PLIST_TYPE)
    self.time_line_action:gotoFrameAndPlay(0, 60, false)
    self.icon_panel:Hide()
    self.name_text:setVisible(false)
    self.name_bg:setVisible(false)
    self.old_level = self.now_level
end

local mine_main_panel = panel_prototype.New(true)
function mine_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mine_main_panel.csb")

    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/ui/entrust.plist")

    self.back_btn = self.root_node:getChildByName("back_btn")

    local bottom_bar = self.root_node:getChildByName("bottom_bar")

    --增加掠夺次数按钮
    self.add_plunder_count_btn = bottom_bar:getChildByName("times_buy_btn_0")
    self.add_plunder_count_desc = bottom_bar:getChildByName("times_desc_0")
    self.add_plunder_count_label = bottom_bar:getChildByName("times_number_0")
    --增加刷新次数
    self.add_refresh_count_btn = bottom_bar:getChildByName("times_buy_btn")
    self.add_refresh_count_desc = bottom_bar:getChildByName("times_desc")
    self.add_refresh_count_label = bottom_bar:getChildByName("times_number")

    --战报按钮
    self.report_btn = self.root_node:getChildByName("report_btn")
    self.report_btn_name = self.root_node:getChildByName("name")   --战报按钮名字

    --规则按钮
    self.rule_btn = self.root_node:getChildByName("view_info_btn")

    --搜索按钮
    self.refresh_btn = self.root_node:getChildByName("ext_exchange_btn")

    --战报绿点
    self.remind_icon = self.root_node:getChildByName("remind_icon")
    self.remind_icon:setVisible(false)

    local mine_node1 = mine_node_panel.New()
    mine_node1:Init(self.root_node:getChildByName("mine02"))
    mine_nodes[1] = mine_node1
    local mine_node2 = mine_node_panel.New()
    mine_node2:Init(self.root_node:getChildByName("mine01"))
    mine_nodes[2] = mine_node2
    local mine_node3 = mine_node_panel.New()
    mine_node3:Init(self.root_node:getChildByName("mine03"))
    mine_nodes[3] = mine_node3
    
    --玩家templent
    local rob_templent = self.root_node:getChildByName("Button_mine")
    self.rob_target_mines = {}
    for i=1, PLAYER_NUMBER do
        local rob_target = rob_target_panel.New()
        local rob_node = rob_templent:clone()
        self.root_node:addChild(rob_node, PLAYER_LOCAL_ZORDER)
        local rob_node_pos_node = self.root_node:getChildByName("Node_"..i)
        if rob_node_pos_node then
            rob_node:setPosition(rob_node_pos_node:getPosition())
        end
        rob_target:Init(rob_node)
        self.rob_target_mines[i] = rob_target
    end
    rob_templent:setVisible(false)

    self.is_run_animation = false
    self.add_elapsed_time = 0

    --掠夺阵容按钮
    self.plunder_formation_btn =  self.root_node:getChildByName("arrange_mercenary_pos_btn")


    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--显示界面
function mine_main_panel:Show()
    PANEL_STATE = 0
    self.add_plunder_count_desc:setString(lang_constants:Get("mine_plunder_count_desc"))
    self.add_refresh_count_desc:setString(lang_constants:Get("mine_add_refresh_count_desc"))
    self.report_btn_name:setString(lang_constants:Get("mine_report_btn_name"))
    self:LoadMineNode(true)
    self:LoadRobTargetList()
    self:RefreshTimes()
    self.root_node:setVisible(true)

    mine_logic:CheckMineReport()
end

--
function mine_main_panel:LoadRobTargetList(is_fresh)

    local rob_target_info = mine_logic.rob_target_list
    local indexs = {}
    if is_fresh then
        --复制时间间隔列表
        for k,v in pairs(TIME_INDEX) do
            indexs[k] = v
        end
    end
    for i=1,PLAYER_NUMBER do
        local delay_time = 0
        if is_fresh then
            --刷新动画
            local select_ind = math.floor(math.random(1,#indexs))
            delay_time = indexs[select_ind]
            table.remove(indexs,select_ind)
        end

        local rob_target = self.rob_target_mines[i]
        rob_target:Show(rob_target_info[i], delay_time)
    end
end

--刷新次数掠夺
function mine_main_panel:RefreshTimes()
    --掠夺次数
    self.add_plunder_count_label:setString(mine_logic.remain_rob)
    --搜说次数
    self.add_refresh_count_label:setString(mine_logic.remain_refresh_target)
end

function mine_main_panel:LoadMineNode(show_animation, unlock_index)
    local mine_info_config = mine_logic.mine_info_list
    if mine_info_config then
        for i=1,3 do
            local mine_node = mine_nodes[i]
            if unlock_index  then
                if unlock_index == i then
                    mine_node:Show(i, mine_info_config[i], show_animation, true)
                end
            else
                --不是解锁过来的
                mine_node:Show(i, mine_info_config[i], show_animation, false)
            end
            
        end
    end
end

--Update定时器
function mine_main_panel:Update(elapsed_time)
    --路线图上玩家标记的位置
    for i=1,3 do
        local mine_node = mine_nodes[i]
        mine_node:UpdateTime(elapsed_time)
    end

end

--绿点战报状态
function mine_main_panel:RefreshReportState()
    if mine_logic.has_new_report then
        self.remind_icon:setVisible(true)
    else
        self.remind_icon:setVisible(false)
    end
end

function mine_main_panel:RegisterEvent()

    --开始开采
    graphic:RegisterEvent("mine_start_success", function(mine_index)
        if not self.root_node:isVisible() then
            return
        end
        local mine_info_config = mine_logic.mine_info_list
        if mine_info_config then
            mine_nodes[mine_index]:Show(mine_index, mine_info_config[mine_index])
        end
    end)

    --购买次数成功
    graphic:RegisterEvent("mine_buy_times_success", function()
        if not self.root_node:isVisible() then
            return
        end

        self:RefreshTimes()
    end)

    --解锁成功
    graphic:RegisterEvent("mine_unlock_success", function(mine_index)
        if not self.root_node:isVisible() then
            return
        end
        self:LoadMineNode(false,mine_index)
    end)

    --刷新玩家成功
    graphic:RegisterEvent("mine_refresh_rob_target_list_success", function()
        if not self.root_node:isVisible() then
            return
        end
        PANEL_STATE = 1
        self:RefreshTimes()
        self:LoadRobTargetList(true)
    end)

    --掠夺成功
    graphic:RegisterEvent("mine_rob_target_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshTimes()
        
    end)

    ----收取奖励成功成功刷新界面
    graphic:RegisterEvent("mine_receive_reward_success", function()
        if not self.root_node:isVisible() then
            return
        end

        self:LoadMineNode()
    end)

    --战报绿点状态查询成功
    graphic:RegisterEvent("check_mine_report_success", function()
        if not self.root_node:isVisible() then
            return
        end
        
        self:RefreshReportState()
    end)

    --取消开采成功返回
    graphic:RegisterEvent("mine_cancel_success", function(mine_index)
        if not self.root_node:isVisible() then
            return
        end
        local mine_info_config = mine_logic.mine_info_list
        if mine_info_config then
            mine_nodes[mine_index]:Show(mine_index, mine_info_config[mine_index])
        end
    end)
    
end

function mine_main_panel:RegisterWidgetEvent()

    --购买掠夺次数
    self.add_plunder_count_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["BATCH_MSGBOX_MODE"]["mine_buy_rob_times"]
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
        end
    end)

    --购买刷新次数
    self.add_refresh_count_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["BATCH_MSGBOX_MODE"]["mine_buy_refresh_times"]
            graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
        end
    end)
    
    --刷新敌人按钮
    self.refresh_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if PANEL_STATE == 0 then
                mine_logic:RefreshPalyer()
            end
        end
    end)

    --战报按钮
    self.report_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if mine_logic:GetReportRecord() ~= nil then
                graphic:DispatchEvent("show_world_sub_scene", "mine_report_sub_scene")
            end
        end
    end)

    --规则说明
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "mine_rule_msgbox")
        end
    end)

    --修炼研究按钮
    self.plunder_formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mine_and_cultivation"], true) then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_cultivation_sub_scene",SCENE_TRANSITION_TYPE["none"])
            end
        end
    end)

    --玩家点击
    for i=1,PLAYER_NUMBER do
        self.rob_target_mines[i].root_node:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("show_world_sub_panel", "mine_plunder_panel", i)
            end
        end)
    end

    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return mine_main_panel

