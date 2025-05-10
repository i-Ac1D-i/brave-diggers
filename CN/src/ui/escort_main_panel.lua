local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"
local escort_logic = require "logic.escort"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local LOCATION_POS_X_BEG = 100
local LOCATION_POS_X_END = 570

local BG_UP_ITEM_NUM = 2
local BG_MID_ITEM_NUM = 1
local BG_OTHER_ITEM_NUM = 2

local BG_UP_ITEM_IMG = {
    [1] = "bg/up001.png",
    [2] = "bg/up002.png",
    [2] = "bg/up003.png",
}

local BG_MID_ITEM_IMG = {
    [1] = "bg/part006.png",
    [2] = "bg/part007.png",
}

local BG_OTHER_ITEM_IMG = {
    [1] = "bg/part001.png",
    [2] = "bg/part002.png",
}

local ROB_RESULT_ICON = {
    [1] = "bg/cry.png",
    [2] = "bg/smile.png",
}

local PLIST_TYPE = ccui.TextureResType.plistType

--单个矿车节点
local tramcar_sub_panel = panel_prototype.New()
tramcar_sub_panel.__index = tramcar_sub_panel
function tramcar_sub_panel.New()
    return setmetatable({}, tramcar_sub_panel)
end

function tramcar_sub_panel:Init(root_node, is_self)
    self.root_node = root_node

    self.rob_btn = self.root_node:getChildByName("select_btn")
    self.name_text = self.root_node:getChildByName("name")

    --矿车动画
    self.tramcar_spine_node = spine_manager:GetNode("kuangche", 1.0, true)
    self.tramcar_spine_node:setPosition(cc.p(self.root_node:getContentSize().width / 2, self.root_node:getContentSize().height / 2 + 20))
    self.root_node:addChild(self.tramcar_spine_node)
    self.tramcar_spine_node:setTimeScale(1.0)
    self.tramcar_spine_node:setScale(2.0)

    --刷新动画
    self.light_spine_node = spine_manager:GetNode("kuangche", 1.0, true)
    self.light_spine_node:setPosition(cc.p(self.root_node:getContentSize().width / 2, self.root_node:getContentSize().height / 2 + 20))
    self.root_node:addChild(self.light_spine_node)
    self.light_spine_node:setTimeScale(1.0)
    self.light_spine_node:setScale(2.0)

    self.rob_btn:setOpacity(0)
    self.name_text:setString("")

    if is_self then
        self.cool_down_bg = self.root_node:getChildByName("time_bg")
        self.cool_down_icon = self.root_node:getChildByName("time_icon_2")
        self.cool_down_time = self.root_node:getChildByName("time_txt")
        
        self.cool_down_bg:setVisible(false)
        self.cool_down_icon:setVisible(false)
        self.cool_down_time:setVisible(false)
    end

    self.init_pos_x, self.init_pos_y = self.root_node:getPosition()
    self:StartMoveTramcar(is_self)
end

--开始随机在范围内上下左右移动，移动完成后停顿随机时间后自调用
function tramcar_sub_panel:StartMoveTramcar(is_self)
    local sequence = cc.Sequence:create(cc.DelayTime:create(math.random(20) / 10), cc.MoveTo:create(3, {x = self.init_pos_x + math.random(-40, 40), y = is_self and self.init_pos_y or (self.init_pos_y + math.random(-20, 20))}), cc.CallFunc:create(function() self:StartMoveTramcar(is_self) end))
    self.root_node:runAction(sequence)
end

--显示自己的矿车
function tramcar_sub_panel:ShowMineTramcar(is_show)
    self.escort_info = escort_logic:GetEscortInfo()
    if is_show then
        local spine_name = escort_logic:GetTramcarSpineName(self.escort_info.tramcar_id, escort_logic:GetCurBeRobbedList(self.escort_info.escort_beg_time, escort_logic:GetBeRobbedList()))
        self.tramcar_spine_node:setToSetupPose()
        self.tramcar_spine_node:setAnimation(0, spine_name, true)
        self.tramcar_spine_node:setVisible(true)

        self.cool_down_bg:setVisible(true)
        self.cool_down_icon:setVisible(true)
        self.cool_down_time:setVisible(true)
        
        self.name_text:setString(user_logic:GetUserLeaderName())
    else
        self.tramcar_spine_node:setVisible(false)

        self.cool_down_bg:setVisible(false)
        self.cool_down_icon:setVisible(false)
        self.cool_down_time:setVisible(false)

        self.name_text:setString("")
    end
end

--显示运送完成倒计时
function tramcar_sub_panel:ShowRemainTime(remain_time)
    self.cool_down_time:setString(panel_util:GetTimeStr(remain_time))
end

--显示拦截目标，show_animation：是否显示刷新动画
function tramcar_sub_panel:ShowRobTarget(rob_target_info, show_animation)
    self.rob_target_info = rob_target_info

    if self.rob_target_info then
        local show_target_info = function()
            local spine_name = escort_logic:GetTramcarSpineName(self.rob_target_info.tramcar_id, escort_logic:GetCurBeRobbedList(self.rob_target_info.escort_beg_time, self.rob_target_info.be_robbed_list))
            self.tramcar_spine_node:setToSetupPose()
            self.tramcar_spine_node:setAnimation(0, spine_name, true)
            self.name_text:setString(rob_target_info.leader_name)
        end

        if show_animation then
            self.light_spine_node:registerSpineEventHandler(function(event)
                if event.eventData.name == "show" then 
                   show_target_info()
                end
            end, sp.EventType.ANIMATION_EVENT)
            self.light_spine_node:setAnimation(0, "kuangche_light", false)
        else
            show_target_info()
        end
    else
        self.name_text:setString("")
    end
end

--显示完成动画
function tramcar_sub_panel:ShowFinishAnimation(call_back)
    if self.escort_info then

        self.light_spine_node:registerSpineEventHandler(function(event)
            if event.eventData.name == "show" then 
                self.tramcar_spine_node:setVisible(false)

                self.cool_down_bg:setVisible(false)
                self.cool_down_icon:setVisible(false)
                self.cool_down_time:setVisible(false)

                self.name_text:setString("")
            end
        end, sp.EventType.ANIMATION_EVENT)

        self.light_spine_node:registerSpineEventHandler(function(event)
            if call_back then 
                call_back()
            end
        end, sp.EventType.ANIMATION_COMPLETE)
        self.light_spine_node:setAnimation(0, "kuangche_light", false)
    end
end

local escort_main_panel = panel_prototype.New(true)
function escort_main_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/tramcar_convoy_panel.csb")

    self.location_img = self.root_node:getChildByName("Image_314")

    local escort_times_node = self.root_node:getChildByName("convoy_times")
    self.remain_escort_times_text = escort_times_node:getChildByName("value1")

    self.rob_times_node = self.root_node:getChildByName("intercept_times")
    self.remain_rob_times_text = self.rob_times_node:getChildByName("value1")
    self.add_rob_times_btn = self.rob_times_node:getChildByName("add_area_btn")
    
    self.start_btn = self.root_node:getChildByName("arrange_mercenary_pos_btn_0")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.refresh_rob_target_btn = self.root_node:getChildByName("refresh_btn")
    self.rule_btn = self.root_node:getChildByName("rule_btn")

    self.refresh_cool_down_text = self.refresh_rob_target_btn:getChildByName("Text_9")
    self.refresh_cool_down_bg = self.refresh_rob_target_btn:getChildByName("Image_61")
    self.refresh_cool_down_icon = self.refresh_rob_target_btn:getChildByName("time_icon")
    self.refresh_cool_down_time = self.refresh_rob_target_btn:getChildByName("refresh_time")

    self.refresh_immediately_text = self.refresh_rob_target_btn:getChildByName("refresh_txt")

    self.remain_be_robbed_times_text = self.root_node:getChildByName("Text_88")

    --r2剩余次数多语言文字bug
    local remain_be_robbed_times_desc_before = platform_manager:GetChannelInfo().remain_be_robbed_times_desc_before
    if remain_be_robbed_times_desc_before then
        self.remain_be_robbed_times_desc_text = self.root_node:getChildByName("Text_87")
        local remain_be_robbed_times_text_pos_x = self.remain_be_robbed_times_text:getPositionX()
        local remain_be_robbed_times_text_width = self.remain_be_robbed_times_text:getContentSize().width/2
        self.remain_be_robbed_times_desc_text:setPositionX(remain_be_robbed_times_text_pos_x-remain_be_robbed_times_text_width-self.remain_be_robbed_times_desc_text:getContentSize().width/2)
    end
    self.rob_result_template = self.root_node:getChildByName("Image_373")
    self.rob_result_template:setVisible(false)
    self.rob_result_icon_list = {}
    
    local bg_node = self.root_node:getChildByName("bg_node")
    
    animation_manager:LoadAnimation("tramcar_bg")
    animation_manager:LoadAnimation("tramcar_bg2")
    self.bg_animation = animation_manager:GetAnimationNode("tramcar_bg")
    self.bg_animation2 = animation_manager:GetAnimationNode("tramcar_bg2")
    self.bg_animation2:setPosition(0, -360)

    bg_node:addChild(self.bg_animation, -1)
    bg_node:addChild(self.bg_animation2, 1)

    local bg_item_node = self.bg_animation:getChildByName("Image_1")

    self.bg_up_item_list = {}
    for index = 1, BG_UP_ITEM_NUM do
        self.bg_up_item_list[index] = bg_item_node:getChildByName(string.format("Node_image_up_%d", index))
    end

    self.bg_mid_item = bg_item_node:getChildByName("Node_image_3")

    self.bg_other_item_list = {}
    for index = 1, BG_OTHER_ITEM_NUM do
        self.bg_other_item_list[index] = bg_item_node:getChildByName(string.format("Node_image_%d", index))
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self.mine_tramcar_sub_panel = tramcar_sub_panel.New()
    self.mine_tramcar_sub_panel:Init(bg_node:getChildByName("Node_1"), true)
    
    self.target_tramcar_sub_panel_list = {}
    for index=1,constants["ESCORT_ROB_TARGET_NUM"] do
        self.target_tramcar_sub_panel_list[index] = tramcar_sub_panel.New()
        self.target_tramcar_sub_panel_list[index]:Init(bg_node:getChildByName("Node_" .. (index + 1)))
        self.target_tramcar_sub_panel_list[index].rob_btn:setTag(index)
        self.target_tramcar_sub_panel_list[index].rob_btn:addTouchEventListener(self.click_rob_target)
    end
    
    self:StartMoveBg()
    self:ShowRobTimesNode()

    local time_line_action = animation_manager:GetTimeLine("tramcar_bg2_timeline")
    self.bg_animation2:runAction(time_line_action)
    time_line_action:play("ani_loop", true)
end

function escort_main_panel:ShowRobTimesNode()
    --拦截次数开关要通过gm开关控制
    if feature_config:IsFeatureOpen("review") then
        self.add_rob_times_btn:setVisible(false)
        self.rob_times_node:getChildByName("add_time"):setVisible(false)
        self.refresh_rob_target_btn_can_buy = false
    else
        self.add_rob_times_btn:setVisible(true)
        self.rob_times_node:getChildByName("add_time"):setVisible(true)
        self.refresh_rob_target_btn_can_buy = true
    end
end

--开始滚动背景层
function escort_main_panel:StartMoveBg()
    local time_line_action = animation_manager:GetTimeLine("tramcar_bg_timeline")
    self.bg_animation:stopAllActions()
    self.bg_animation:runAction(time_line_action)

    local event_frame_call_function 
    event_frame_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "start" then
            self:ChangeBgImg()
        end
    end

    time_line_action:clearFrameEventCallFunc()
    time_line_action:setFrameEventCallFunc(event_frame_call_function)
    time_line_action:gotoFrameAndPlay(0, 500, true)
end

--替换背景滚动层上物件的图片
function escort_main_panel:ChangeBgImg()
    --每个节点依靠随机值确定是否显示、显示哪张图片

    for _,bg_up_item in ipairs(self.bg_up_item_list) do
        bg_up_item:removeAllChildren()

        local random_value = math.random(#BG_UP_ITEM_IMG * 2)
        if random_value <= #BG_UP_ITEM_IMG then
            local item_img = cc.Sprite:createWithSpriteFrameName(BG_UP_ITEM_IMG[random_value])
            item_img:setAnchorPoint(cc.p(0, 1))
            bg_up_item:addChild(item_img)
        end
    end

    self.bg_mid_item:removeAllChildren()
    local random_value = math.random(#BG_MID_ITEM_IMG * 2)
    if random_value <= #BG_MID_ITEM_IMG then
        local item_img = cc.Sprite:createWithSpriteFrameName(BG_MID_ITEM_IMG[random_value])
        item_img:setAnchorPoint(cc.p(0.5, 0))
        self.bg_mid_item:addChild(item_img)
    end

    for _,bg_other_item in ipairs(self.bg_other_item_list) do
        bg_other_item:removeAllChildren()

        local random_value = math.random(#BG_OTHER_ITEM_IMG * 2)
        if random_value <= #BG_OTHER_ITEM_IMG then
            local item_img = cc.Sprite:createWithSpriteFrameName(BG_OTHER_ITEM_IMG[random_value])
            bg_other_item:addChild(item_img)
        end
    end
end

--显示界面
function escort_main_panel:Show()
    self:RefreshRemainEscortTimes()
    self:RefreshRemainRobTimes()
    self:RefreshMineTramcar()
    self:RefreshTargetTramcar(false)
    self:RefreshEscortBtn()
    self:RefreshRemainBeRobbedTimes()

    self:ShowFinishAnimation()

    self.root_node:setVisible(true)
end

--Update定时器
function escort_main_panel:Update(elapsed_time)
    --路线图上玩家标记的位置
    local escort_info = escort_logic:GetEscortInfo()
    if escort_info.status == constants["ESCORT_STATUS"]["READY"] then
        for _,rob_result_icon in ipairs(self.rob_result_icon_list) do
            rob_result_icon:removeFromParent()
        end
        self.rob_result_icon_list = {}
        self.location_img:setVisible(false)
    elseif escort_info.status == constants["ESCORT_STATUS"]["FINISH"] then
        self.location_img:setPositionX(LOCATION_POS_X_END)
        self.location_img:setVisible(true)
    else
        local percent = 1 - (escort_info.escort_end_time - time_logic:Now()) / (escort_info.escort_end_time - escort_info.escort_beg_time)
        self.location_img:setPositionX(LOCATION_POS_X_BEG + (LOCATION_POS_X_END - LOCATION_POS_X_BEG) * math.min(percent, 1))
        self.location_img:setVisible(true)

        self.mine_tramcar_sub_panel:ShowRemainTime(math.max(escort_info.escort_end_time - time_logic:Now(), 0))
    end

    --刷新可拦截目标的倒计时
    if escort_info.refresh_rob_target_time > time_logic:Now() then
        self.refresh_immediately_text:setVisible(false)
        self.refresh_cool_down_text:setVisible(true)
        self.refresh_cool_down_bg:setVisible(true)
        self.refresh_cool_down_icon:setVisible(true)
        self.refresh_cool_down_time:setVisible(true)

        self.refresh_cool_down_time:setString(panel_util:GetTimeStr(escort_info.refresh_rob_target_time - time_logic:Now()))
    else
        self.refresh_immediately_text:setVisible(true)
        self.refresh_cool_down_text:setVisible(false)
        self.refresh_cool_down_bg:setVisible(false)
        self.refresh_cool_down_icon:setVisible(false)
        self.refresh_cool_down_time:setVisible(false)
    end
end

--刷新自己的矿车
function escort_main_panel:RefreshMineTramcar()
    local escort_info = escort_logic:GetEscortInfo()

    if escort_info.status == constants["ESCORT_STATUS"]["ESCORTING"] then
        self.mine_tramcar_sub_panel:ShowMineTramcar(true)
    else
        self.mine_tramcar_sub_panel:ShowMineTramcar(false)
    end
end

--刷新可拦截目标，show_animation：是否显示刷新动画
function escort_main_panel:RefreshTargetTramcar(show_animation)
    local rob_target_list = escort_logic:GetRobTargetList()
    for index,rob_target_info in ipairs(rob_target_list) do
        self.target_tramcar_sub_panel_list[rob_target_info.pos]:ShowRobTarget(rob_target_info, show_animation or rob_target_info.is_update)
        rob_target_info.is_update = false
    end
end

--刷新剩余运送次数
function escort_main_panel:RefreshRemainEscortTimes()
    local display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), escort_logic:GetRemainEscortTimes(), constants["DEFAULT_ESCORT_TIMES"])
    self.remain_escort_times_text:setString(display_text)
    if escort_logic:GetRemainEscortTimes() > 0 then
        self.remain_escort_times_text:setColor(panel_util:GetColor4B(0xffe08a))
    else
        self.remain_escort_times_text:setColor(panel_util:GetColor4B(0xc45d1d))
    end
end

--刷新剩余可拦截次数
function escort_main_panel:RefreshRemainRobTimes()
    local display_text = string.format(lang_constants:Get("mining_cave_battle_counts"), escort_logic:GetRemainRobTimes(), constants["DEFAULT_ROB_TIMES"])
    self.remain_rob_times_text:setColor(panel_util:GetColor4B(0xffe08a))
    self.remain_rob_times_text:setString(display_text)
end

--刷新被拦截列表
function escort_main_panel:RefreshRemainBeRobbedTimes()
    local escort_info = escort_logic:GetEscortInfo()
    local be_robbed_list = escort_logic:GetCurBeRobbedList(escort_info.escort_beg_time, escort_logic:GetBeRobbedList())

    for _,rob_result_icon in ipairs(self.rob_result_icon_list) do
        rob_result_icon:removeFromParent()
    end
    self.rob_result_icon_list = {}
    for _,be_robbed_info in ipairs(be_robbed_list) do
        local rob_result_icon = self.rob_result_template:clone()
        local percent = 1 - (escort_info.escort_end_time - be_robbed_info.be_robbed_time) / (escort_info.escort_end_time - escort_info.escort_beg_time)
        rob_result_icon:setPosition(LOCATION_POS_X_BEG + (LOCATION_POS_X_END - LOCATION_POS_X_BEG) * math.min(percent, 1), self.location_img:getPositionY())
        rob_result_icon:loadTexture(ROB_RESULT_ICON[be_robbed_info.result], PLIST_TYPE)
        rob_result_icon:setVisible(true)
        self.root_node:addChild(rob_result_icon)
        table.insert(self.rob_result_icon_list, rob_result_icon)
    end
    self.remain_be_robbed_times_text:setString(string.format(lang_constants:Get("mining_cave_battle_counts"), constants["MAX_BE_ROBBED_TIMES"] - escort_logic:GetBeRobbedTimes(), constants["MAX_BE_ROBBED_TIMES"]))
end

--刷新开始运送按钮的显示文本
function escort_main_panel:RefreshEscortBtn()
    local escort_info = escort_logic:GetEscortInfo()

    if escort_info.status == constants["ESCORT_STATUS"]["READY"] then
        self.start_btn:setTitleText(lang_constants:Get("ready_to_escort"))
    elseif escort_info.status == constants["ESCORT_STATUS"]["FINISH"] then
        self.start_btn:setTitleText(lang_constants:Get("escort_finish"))
    elseif escort_info.status == constants["ESCORT_STATUS"]["ESCORTING"] then
        self.start_btn:setTitleText(lang_constants:Get("is_escorting"))
    end
end

--显示完成动画
function escort_main_panel:ShowFinishAnimation()
    local escort_info = escort_logic:GetEscortInfo()
    if escort_info.status == constants["ESCORT_STATUS"]["FINISH"] then
        if not self.root_node:isVisible() then
            return
        end
        
        --播放完完成动画后，回调显示运送奖励界面
        self.mine_tramcar_sub_panel:ShowFinishAnimation(function ()
            graphic:DispatchEvent("show_world_sub_panel", "escort_reward_panel")
        end)
    end
end

function escort_main_panel:RegisterEvent()
    --刷新可拦截目标
    graphic:RegisterEvent("update_rob_target_list", function(show_animation)
        self:RefreshTargetTramcar(show_animation)
    end)

    --刷新剩余可拦截次数
    graphic:RegisterEvent("refresh_remain_rob_times", function(show_animation)
        self:RefreshRemainRobTimes()
    end)

    --开始运送矿车
    graphic:RegisterEvent("start_escort", function(show_animation)
        self:RefreshMineTramcar()
    end)

    --运送完成
    graphic:RegisterEvent("finish_escort", function(show_animation)
        self:RefreshEscortBtn()
        self:ShowFinishAnimation()
    end)

    --领取奖励
    graphic:RegisterEvent("receive_reward_success", function(show_animation)
        self:RefreshEscortBtn()
    end)

    --刷新剩余运送次数
    graphic:RegisterEvent("refresh_remain_escort_times", function(show_animation)
        self:RefreshRemainEscortTimes()
        self:RefreshEscortBtn()
    end)

    --更新运送相关的次数
    graphic:RegisterEvent("update_escort_times", function()
        self:RefreshRemainEscortTimes()
        self:RefreshRemainRobTimes()
    end)

    --更新被拦截信息
    graphic:RegisterEvent("update_be_robbed_list", function()
        self:RefreshRemainBeRobbedTimes()
    end)

    --gm工具开关控制
    graphic:RegisterEvent("update_feature_config", function()
        self:ShowRobTimesNode()
    end)
end

function escort_main_panel:RegisterWidgetEvent()
    --点击可拦截目标
    self.click_rob_target = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()

            local sub_panel = self.target_tramcar_sub_panel_list[index]
            if sub_panel.rob_target_info then
                graphic:DispatchEvent("show_world_sub_panel", "escort_rob_target_panel", sub_panel.rob_target_info)
            end
        end
    end

    --购买拦截次数
    self.add_rob_times_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local could_buy, cost = escort_logic:GetBuyRobCost(1)
            if could_buy then
                local mode = client_constants["BATCH_MSGBOX_MODE"]["escort_buy_rob_times"]
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
            else
                graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_rob_times")
            end
        end
    end)

    --开始运送
    self.start_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local escort_info = escort_logic:GetEscortInfo()
            if escort_info.status == constants["ESCORT_STATUS"]["ESCORTING"] then
                --运送中：提示运送完成倒计时
                graphic:DispatchEvent("show_prompt_panel", "escorting_remain_time", panel_util:GetTimeStr(escort_info.escort_end_time - time_logic:Now()))
            elseif escort_info.status == constants["ESCORT_STATUS"]["FINISH"] then
                --运送完成：显示奖励界面
                graphic:DispatchEvent("show_world_sub_panel", "escort_reward_panel")
            else
                --准备运送：显示矿车选择界面
                graphic:DispatchEvent("show_world_sub_panel", "escort_tramcar_panel")
            end
        end
    end)

    --刷新可拦截目标
    self.refresh_rob_target_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local escort_info = escort_logic:GetEscortInfo()
            if escort_info.refresh_rob_target_time > time_logic:Now() then
                --刷新CD没有结束：付费立即刷新 --这个刷新要gm工具后天控制
                if self.refresh_rob_target_btn_can_buy then
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["refresh_rob_target_immediately"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
                end
            else
                --普通刷新
                escort_logic:RefreshRobTarget("normal")
            end
        end
    end)

    --规则说明
    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("show_world_sub_panel", "escort_rule_panel")
        end
    end)

    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return escort_main_panel

