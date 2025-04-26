local feature_config = require "logic.feature_config"
local panel_prototype = require "ui.panel"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local adventure_logic = require "logic.adventure"
local merchant_logic = require "logic.merchant"
local store_logic = require "logic.store"
local mail_logic = require "logic.mail"
local daily_logic = require "logic.daily"
local notice_logic = require "logic.notice"
local time_logic = require "logic.time"
local chat_logic = require "logic.chat"
local achievement_logic = require "logic.achievement"
local carnival_logic = require "logic.carnival"
local vip_logic = require "logic.vip"
local quest_logic = require "logic.quest"
local guild_logic = require "logic.guild"
local sns_logic = require "logic.sns"
local limite_logic = require "logic.limite"

local animation_manager = require "util.animation_manager" 
local platform_manager = require "logic.platform_manager"

local temple_logic = require "logic.temple"
local PLIST_TYPE = ccui.TextureResType.plistType

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"

local audio_manager = require "util.audio_manager"
local user_logic = require "logic.user"
local social_logic = require "logic.social"
local CARNICAL_LIMIT_ICON_PATH = "button/mainui_limitbuy.png"
local CARNIVAL_FIRST_PAYMENT_ICON_PATH = "button/mainui_firstbuy.png"

local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE
local CARNIVAL_TYPE = constants.CARNIVAL_TYPE
local TEXT_BORDER_WIDTH = 3

local panel_util = require "ui.panel_util"

local math_max = math.max

local FEATURE_TYPE = client_constants["FEATURE_TYPE"]

local main_panel = panel_prototype.New()
function main_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/main_panel.csb")

    self.menu_btn = self.root_node:getChildByName("menu_btn")
    self.pay_btn = self.root_node:getChildByName("pay_btn")
    self.merchant_btn = self.root_node:getChildByName("merchant_btn")

    self.rune_btn = self.root_node:getChildByName("rune_btn_")
    self.rune_remind_img = self.rune_btn:getChildByName("remind_icon")
    self.rune_lock_img = self.root_node:getChildByName("rune_lock")
    self.rune_lock_img:setVisible(not user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"], false))
    self.rune_remind_img:setVisible(false)

    self.gift_btn = self.root_node:getChildByName("gift_btn")
    self.gift_remind_img = self.gift_btn:getChildByName("remind_icon")

    self.checkin_btn = self.root_node:getChildByName("checkin_btn")
    self.checkin_remind_img = self.checkin_btn:getChildByName("remind_icon")

    if _G["AUTH_MODE"] == true then
        self.checkin_btn:setVisible(false)
    end


    self.carnival_btn = self.root_node:getChildByName("carnival_btn")
    self.carnival_remind_img = self.carnival_btn:getChildByName("remind_icon")
    self.carnival_btn:setVisible(not _G["AUTH_MODE"])

    self.friend_btn = self.root_node:getChildByName("friend_btn")
    self.friend_remind_img = self.friend_btn:getChildByName("remind_icon")
    self.friend_remind_img:setVisible(false)

    self.bbs_btn = self.root_node:getChildByName("discuss_btn")
    self.bbs_remind_img = self.bbs_btn:getChildByName("remind_icon")
    self.bbs_remind_img:setVisible(false)

    self.vip_btn = self.root_node:getChildByName("vip_btn")
    self.vip_remind_img = self.vip_btn:getChildByName("remind_icon")

    self.checkin_btn:getChildByName("remind_icon"):setVisible(false)

    self.achievement_btn = self.root_node:getChildByName("quest_btn")
    self.achievement_remind_btn = self.achievement_btn:getChildByName("remind_icon")
    self.achievement_remind_btn:setVisible(false)

    --限时礼包按钮
    self.limited_package_btn = self.root_node:getChildByName("gift02_btn")
    self.limited_package_light = self.root_node:getChildByName("Image_114")
    self.limited_package_btn_remind_btn = self.limited_package_btn:getChildByName("remind_icon")
    self.limited_package_btn_remind_btn:setVisible(false)

    self.limited_package_time_label = self.limited_package_btn:getChildByName("time") 

    self.maze_btn = self.root_node:getChildByName("maze_btn")

    self.guild_btn = self.root_node:getChildByName("guild_btn")

    self.notice_btn = self.root_node:getChildByName("news_btn")
    -- 任务委托系统 邮箱按钮
    self.mailbox_btn = self.root_node:getChildByName("mailbox_btn")
    self.mailbox_btn:setTouchEnabled(true)

    --r2 邮箱按钮 位置偏移
    local mailbox_btn_offset_x = platform_manager:GetChannelInfo().main_panel_mailbox_btn_offset_x or 0
    local mailbox_btn_offset_y = platform_manager:GetChannelInfo().main_panel_mailbox_btn_offset_y or 0

    self.mailbox_btn:setPosition(cc.p(self.mailbox_btn:getPositionX()+mailbox_btn_offset_x,self.mailbox_btn:getPositionY()+mailbox_btn_offset_y))

    self.snowman_btn = self.root_node:getChildByName("snowman_btn")
    -- self.snowman_btn:setOpacity(255)

    -- 提醒 任务 1、好友 2、讨论区 3、活动 4、签到 5

    self.update_btn = self.root_node:getChildByName("update_btn")
    self.update_btn:getChildByName("remind_icon"):setVisible(false)

    self.first_pay_btn = self.root_node:getChildByName("firstbuy_btn")

    self.carnival_limit_duration_text = self.first_pay_btn:getChildByName("limit_time")
    panel_util:SetTextOutline(self.carnival_limit_duration_text, 0x000, 2)

    self.share_btn = self.root_node:getChildByName("share_btn")
    self.share_txt = self.root_node:getChildByName("share_txt")
    self.remind_icon = self.root_node:getChildByName("remind_icon")

    self.spring_lottery_btn = self.root_node:getChildByName("newyear_btn")
    self.spring_lottery_remind_btn = self.spring_lottery_btn:getChildByName("remind_icon")
    self.spring_lottery_countdown_text = self.spring_lottery_btn:getChildByName("count_down")
    panel_util:SetTextOutline(self.spring_lottery_countdown_text, 0x000, 2)
    self.spring_lottery_remind_btn:setVisible(false)
    self.spring_lottery_btn:setVisible(false)

    -----------------------------------------chat---------------------------------------
    if platform_manager:GetChannelInfo().is_open_chat then
        if package.loaded["util.utils"] then 
            package.loaded["util.utils"] = nil 
        end
        self.chat_pannel = require('ui.chat_pannel').new(self.root_node:getChildByName("chat_pannel"),self.root_node:getChildByName("hot_area"))     
        self.root_node:addChild(self.chat_pannel)  
    else
         local chat_pannel = self.root_node:getChildByName("chat_pannel")
         if chat_pannel then
            self.root_node:removeChild(chat_pannel)
         end 
    end
    -----------------------------------------chat---------------------------------------

    self.open_spring_lottery_btn = nil 

    self.spring_lottery_config = nil
    self.spring_lottery_countdown = 0
    self.load_lottery_animation = false
    self.play_opening_animation = false
    self.lottery_rank_list = {}

    self.remind_list = {}
    self.loop_time = 0

    local btn_list = { self.rune_btn, self.merchant_btn, self.pay_btn, self.menu_btn, self.carnival_btn, self.gift_btn, self.friend_btn, 
                        self.checkin_btn, self.bbs_btn, self.vip_btn, self.achievement_btn, self.notice_btn, self.first_pay_btn }

    for _, btn in ipairs(btn_list) do
        panel_util:SetTextOutline(btn:getChildByName("name"))
    end

    self.merchant_btn:setVisible(feature_config:IsFeatureOpen("merchant"))

    
    if _G["AUTH_MODE"] == true then
        self.merchant_btn:setVisible(false)
    end


    self.root_node:getChildByName("guild_name"):setVisible(feature_config:IsFeatureOpen("guild"))

    local channel = platform_manager:GetChannelInfo()
    if channel.meta_channel == "r2games" then
        local icon = "button/mainui_vip_en.png"
        self.vip_btn:loadTextures(icon, icon, icon, PLIST_TYPE)
    end


    if channel.enable_sns  and (not _G["AUTH_MODE"]) then   --FYD  是否开启sns功能   --审核模式关闭sns功能
        self.share_btn:setVisible(true)
        self.share_txt:setVisible(true) 
        panel_util:SetTextOutline(self.share_txt)
    else 
        self.share_btn:setVisible(false)
        self.share_txt:setVisible(false)
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function main_panel:Show()
    self.gift_remind_img:setVisible(mail_logic:HasNewMail())
    -- SNS分享奖励提醒
    self.remind_icon:setVisible(sns_logic:HaveRewardsToTake())

    -- 签到开启的时候 签到提醒
    if user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"], false) then
        self.checkin_remind_img:setVisible(daily_logic:NeedShowTip())
    end

    self:UpdateRemindList(5, self.checkin_remind_img:isVisible())

    -- 好友提醒
    self.friend_remind_img:setVisible(social_logic:HasNewInvitation())
    self:UpdateRemindList(2, self.friend_remind_img:isVisible())

    -- 活动
    if carnival_logic:GetCarnivalNum() == 0 then
        self.carnival_btn:setVisible(false)
    else
        self.carnival_btn:setVisible(not _G["AUTH_MODE"])
    end

    -- 活动提醒
    self.carnival_remind_img:setVisible(carnival_logic:GetEntireRewardMark())
    self:UpdateRemindList(4, self.carnival_remind_img:isVisible())

    -- 讨论区提醒
    if chat_logic.new_mine_num > 0 then
        self.bbs_remind_img:setVisible(true)
    else
        self.bbs_remind_img:setVisible(false)
    end
    self:UpdateRemindList(3, self.bbs_remind_img:isVisible())

    -- 月卡
    self.vip_remind_img:setVisible(vip_logic:VipStatus(constants["VIP_TYPE"]["adventure"]))
    self.vip_btn:setVisible(not _G["AUTH_MODE"])

    -- 任务完成提醒
    if #achievement_logic.can_complete_list > 0 then
        self.achievement_remind_btn:setVisible(true)
    else
        self.achievement_remind_btn:setVisible(false)
    end
    self:UpdateRemindList(1, self.achievement_remind_btn:isVisible())

    if notice_logic:HasNewNotice() and not user_logic:IsJustCreateLeader() then
        --公告
        graphic:DispatchEvent("show_new_notice")
    end

    self.update_btn:setVisible(false)

    --苹果服
    local channel = platform_manager:GetChannelInfo()
    if channel.name == "appstore" and not _G["AUTH_MODE"] then
        local version_config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["version_update"])
        if version_config then
            local _, reward_mark = carnival_logic:GetValueAndReward(version_config, 1, 1)
            self.update_btn:setVisible(reward_mark > 0)
        end
    else
        self.update_btn:setVisible(false)
    end

    --首充，限时充值活动
    self:UpdateLimitPayment()

    self:UpdateLimitePackageState()

    self:CheckSpringLottery()

    self.root_node:setVisible(true)
end

function main_panel:UpdateLimitPayment()
    local config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["first_payment"], CARNIVAL_TYPE["first_payment"])
    local icon_path = CARNIVAL_FIRST_PAYMENT_ICON_PATH
    self.carnival_limit_duration_text:setVisible(false)

    if not config then
        config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["time_limit_store"], CARNIVAL_TYPE["time_limit_store"])
        if config then
            icon_path = CARNICAL_LIMIT_ICON_PATH
            self.carnival_duration = time_logic:GetDurationToFixedTime(config.end_time)
            self.update_time = true
            self.carnival_limit_duration_text:setVisible(true)
            self:UpdateRemindList(6, true)
        end
    end
    self.first_pay_btn:setVisible(config and true or false)

    if config then
        self.first_pay_btn:loadTextures(icon_path, icon_path, icon_path, PLIST_TYPE)
    end

end

function main_panel:UpdateLimitePackageState()
    --限时充值礼包

    if limite_logic:IsCanShow() then
        if self.limited_package_light and not self.limited_package_light:isVisible() then
            self.limited_package_light:setVisible(true)
            self.limited_package_light:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.5,90)))
            -- self.limited_package_light:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(0.5,0.8),cc.ScaleTo:create(0.5,0.6))))
        end
        self.limited_package_btn:setVisible(true)
        self.limite_duration = math.max(limite_logic.over_time - time_logic:Now(),0) --得到剩余时间        
         --是否显示绿点
        if limite_logic.is_come_in ~= 0 then
            self.limited_package_btn_remind_btn:setVisible(false)
        else
            self.limited_package_btn_remind_btn:setVisible(true)
        end
    else
        self.limite_duration = 0 
        self.limited_package_btn:setVisible(false)
        if self.limited_package_light then
            self.limited_package_light:setVisible(false)
            self.limited_package_light:stopAllActions()
        end
    end

end


-- 大地图标签：当主界面有任务、好友、讨论区、活动其中至少一个提醒时出现
function main_panel:UpdateRemindList(remind_id, flag)
    self.remind_list[remind_id] = flag

    if flag then
        graphic:DispatchEvent("remind_world_sub_scene", 1, true)
    else
        local show = false
        for i = 1, 6 do
            if self.remind_list[i] and not show then
                show = true
                break
            end
        end

        if not show then
            graphic:DispatchEvent("remind_world_sub_scene", 1, false)
        end
    end
end

--新春红包检测
function main_panel:CheckSpringLottery()
    self.spring_lottery_config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["spring_lottery"], CARNIVAL_TYPE["lottery"])
    if self.spring_lottery_config then
        animation_manager:LoadAnimation("lottery_spring")
        self:LoadLotteryAnimation()
        self.spring_lottery_countdown = math_max(0, self.spring_lottery_config.begin_time - time_logic:Now())
    else
        self.spring_lottery_config = nil
        self:RemoveLotteryAnimation()
    end

    self.spring_lottery_btn:setVisible(self.spring_lottery_config and true or false)
end    

function main_panel:LoadLotteryAnimation()
    if not self.load_lottery_animation then 
       self.lottery_animation_node = animation_manager:GetAnimationNode("lottery_spring")
       self.lottery_animation_node:setAnchorPoint(cc.p(0.5, 0.5))
       self.lottery_animation_node:setScale(3, 3)
       self.lottery_animation_node:setPosition(cc.p(320, 592))

       self.root_node:addChild(self.lottery_animation_node)
    
       self.lottery_action = animation_manager:GetTimeLine("lottery_spring_timeline")
       self.lottery_animation_node:runAction(self.lottery_action)
       
       self.open_spring_lottery_btn = self.guild_btn:clone()
       self.open_spring_lottery_btn:setPosition(cc.p(340,560))
       self.open_spring_lottery_btn:setVisible(true)
       self.open_spring_lottery_btn:setTouchEnabled(true)
       self.open_spring_lottery_btn:addTouchEventListener(self.open_lottery_function)
       self.lottery_animation_node:addChild(self.open_spring_lottery_btn)

       self.load_lottery_animation = true 
    end
end

function main_panel:RemoveLotteryAnimation()
    if self.load_lottery_animation then 
       animation_manager:RemoveTimeLine("lottery_spring_timeline")
       self.lottery_action = nil

       self.lottery_animation_node:removeFromParent()
       animation_manager:RemoveAnimation("lottery_spring")
       self.open_spring_lottery_btn = nil
       self.lottery_animation_node = nil
       
       self.load_lottery_animation = false
    end
end

function main_panel:CheckLotteryAnimation()
    if carnival_logic:GetStageRewardIndex(self.spring_lottery_config.key, 1) > 0 then
        if self.load_lottery_animation then 
           local event_frame_call_function = function(frame)
             local event_name = frame:getEvent()
             if event_name == "ani_in" then
                self.lottery_action:clearFrameEventCallFunc()
                self.lottery_action:gotoFrameAndPlay(50, 110, true)
             end
           end

            self.lottery_action:clearFrameEventCallFunc()
            self.lottery_action:setFrameEventCallFunc(event_frame_call_function)

            self.lottery_action:gotoFrameAndPlay(0, 50, false)
            self.lottery_animation_node:setVisible(true)
        end
    else
        if not self.play_opening_animation then 
           self.spring_lottery_btn:setVisible(true)
           self.lottery_animation_node:setVisible(false)
        end
    end
end

function main_panel:OpenedLottery(get_value, rank_list, new_flag)
    local event_frame_call_function = function(frame)
       local event_name = frame:getEvent()
       if event_name == "ani_out" then
           self.play_opening_animation = false
           self:ShowLotteryResult(get_value, rank_list, new_flag)
           graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
       end
    end
    self.lottery_action:clearFrameEventCallFunc()
    self.lottery_action:setFrameEventCallFunc(event_frame_call_function)
    self.play_opening_animation = true 
    self.lottery_action:gotoFrameAndPlay(111, 215, false)
    
end

function main_panel:ShowLotteryResult(value, rank_list, new_flag)
    graphic:DispatchEvent("show_world_sub_panel", "lottery_spring_panel", value, rank_list, new_flag)
end

--新春红包更新
function main_panel:UpdateSpringLottery(elapsed_time)

    if self.spring_lottery_countdown > 0 then 
        self.spring_lottery_btn:setVisible(true)
        self.spring_lottery_countdown_text:setVisible(true)
        self.lottery_animation_node:setVisible(false)
        self.spring_lottery_countdown = self.spring_lottery_countdown - elapsed_time
        self.spring_lottery_countdown_text:setString(panel_util:GetTimeStr(self.spring_lottery_countdown))
    else
        self.spring_lottery_countdown = 0
        self.spring_lottery_countdown_text:setVisible(false)
        self.spring_lottery_btn:setVisible(false)
        if self.spring_lottery_config then 
           if time_logic:Now() <= self.spring_lottery_config.end_time then
              self:CheckLotteryAnimation()
           else
              self:CheckSpringLottery()
           end
        end
    end
end

function main_panel:Update(elapsed_time)
    if self.update_time then
        self.carnival_duration = self.carnival_duration - elapsed_time
        if self.carnival_duration < 0 then
            self.update_time = false
            self.carnival_duration = 0
            self.first_pay_btn:setVisible(false)
            self:UpdateRemindList(6, false)
        end
        self.carnival_limit_duration_text:setString(panel_util:GetTimeStr(self.carnival_duration))
    end

    --限时礼包活动开启
    if self.limite_duration and self.limite_duration > 0 then
        if not self.limited_package_btn:isVisible() then
            self.limited_package_btn:setVisible(true)
        end
        self.limite_duration = math.max(self.limite_duration - elapsed_time, 0)
        local duration = math.ceil(self.limite_duration)
        local hour = math.floor(duration / (60 * 60))
        local time_str = ""
        if hour < 24 then
            time_str = panel_util:GetTimeStr(self.limite_duration)
        else
            time_str = string.format("剩余:%d天",math.floor(hour/24))
        end

        self.limited_package_time_label:setString(string.format("%s",time_str))
    else
        if self.limited_package_btn:isVisible() then
            self.limited_package_btn:setVisible(false)
        end
    end

    --红包
   -- self:UpdateSpringLottery(elapsed_time)
end

function main_panel:RegisterEvent()
    -- 礼包箱
    graphic:RegisterEvent("new_mail", function(pos, mail)
        if not self.root_node:isVisible() then
            return
        end

        self.gift_remind_img:setVisible(true)
    end)

    --活动提醒
    graphic:RegisterEvent("remind_carnival", function(carnival_type, group_id)
        self.carnival_remind_img:setVisible(carnival_logic:GetEntireRewardMark())
        self:UpdateRemindList(4, self.carnival_remind_img:isVisible())
    end)

    --好友邀请
    graphic:RegisterEvent("new_invite", function(pos, mail)
        self:UpdateRemindList(2, true)

        if not self.root_node:isVisible() then
            return
        end
        self.friend_remind_img:setVisible(true)
    end)

    graphic:RegisterEvent("open_mail", function(pos, mail)
        if not self.root_node:isVisible() then
            return
        end

        self.gift_remind_img:setVisible(mail_logic:HasNewMail())
    end)

    -- SNS奖励
    graphic:RegisterEvent("remind_sns_reward", function()
        if not self.root_node:isVisible() then
            return
        end

        self.remind_icon:setVisible(sns_logic:HaveRewardsToTake())
    end)

    --有新的bbs消息
    graphic:RegisterEvent("new_bbs", function()
        local visible = chat_logic.new_mine_num > 0
        self:UpdateRemindList(3, visible)

        if not self.root_node:isVisible() then
            return
        end

        self.bbs_remind_img:setVisible(visible)
    end)

    --任务完成提醒
    graphic:RegisterEvent("remind_achievement", function()
        local visible = #achievement_logic.can_complete_list > 0

        self:UpdateRemindList(1, visible)

        if not self.root_node:isVisible() then
            return
        end

        self.achievement_remind_btn:setVisible(visible)
    end)

    -- 签到开启的时候 签到提醒
    graphic:RegisterEvent("remind_check_in", function(flag)
        local visible = false
        if not flag and daily_logic:NeedShowTip() and user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"], false) then
            visible = true
        end

        self.checkin_remind_img:setVisible(visible)
        self:UpdateRemindList(5, visible)
    end)

    graphic:RegisterEvent("take_vip_reward_success", function()
        self.vip_remind_img:setVisible(false)
    end)

    graphic:RegisterEvent("update_sub_carnival_reward_status", function()
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateLimitPayment()

    end)

    graphic:RegisterEvent("update_limite_state", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateLimitePackageState()
    end)

    graphic:RegisterEvent("update_lottery_panel", function(get_value, rank_list, play_animation_flag)
        if not self.root_node:isVisible() then
            return
        end
      
        if get_value > 0 and play_animation_flag then 
            self:OpenedLottery(get_value, rank_list, play_animation_flag)
        else
            self:ShowLotteryResult(get_value, rank_list, play_animation_flag)
        end
    end)
    
    graphic:RegisterEvent("solve_event_result", function(event_id, is_winner)
        if not is_winner then
            return
        end

        if user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"], false) then
            self.rune_lock_img:setVisible(false)
        end
    end)
end

function main_panel:RegisterWidgetEvent()

    self.merchant_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["merchant"]) then
                merchant_logic:Query()
            end
        end
    end)

    self.menu_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "setting_panel")
        end
    end)

    self.pay_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
           store_logic:Query()
        end
    end)

    self.vip_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "vip_panel")
        end
    end)

    self.carnival_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_scene", "carnival_sub_scene")
        end
    end)
    
    self.rune_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"]) then
                graphic:DispatchEvent("show_world_sub_scene", "rune_draw_sub_scene")
            end
        end
    end)

    self.gift_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "mail_panel")
        end
    end)

    self.checkin_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"]) then
                daily_logic:RequestDaily()
            end
        end
    end)

    self.friend_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "social_sub_scene")
        end
    end)

    self.notice_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_new_notice")
        end
    end)

    self.achievement_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "achievement_sub_scene")
        end
    end)

    self.bbs_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "bbs_sub_scene", false, "all")
        end
    end)

    self.maze_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("update_world_tab_status", client_constants["WORLD_TAB_TYPE"]["adventure"])

            graphic:DispatchEvent("show_world_sub_scene", "exploring_sub_scene")
        end
    end)

    -- 任务委托系统 邮箱按钮
    self.mailbox_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "quest_sub_scene")
        end
    end)

    self.guild_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if feature_config:IsFeatureOpen("guild") and user_logic:IsFeatureUnlock(FEATURE_TYPE["guild"]) then
                guild_logic:Query()
            end
        end
    end)

    --版本更新
    self.update_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "carnival.version_update_panel")
        end
    end)

    --首充和限时购买
    self.first_pay_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            --首先查看是否有首充,若有则显示首充，没有则看看有无限时充值活动
            local config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["first_payment"], CARNIVAL_TYPE["first_payment"])
            if not config then
                config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["time_limit_store"], CARNIVAL_TYPE["time_limit_store"])
            end

            if config then
                graphic:DispatchEvent("show_world_sub_panel", "carnival.limit_store_panel", config)
            end
        end
    end)

    --新年活动
    self.snowman_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["christmas"], CARNIVAL_TYPE["collect_item"])
            if config and carnival_logic:GetCanDoTaskIndex(config) ~= 0 then
                graphic:DispatchEvent("show_world_sub_panel", "carnival.christmas_panel", config)
            end
        end
    end)

    --限时活动礼包按钮
    self.limited_package_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "time_limit_reward_msgbox_panel")
        end
    end)

    self.open_lottery_function = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.spring_lottery_countdown > 0 then 
                graphic:DispatchEvent("show_prompt_panel", "lottery_not_open")
                return
            else
                if not self.play_opening_animation then 
                   carnival_logic:OpenLottery(self.spring_lottery_config.key)
                end
            end
        end
    end
    self.spring_lottery_btn:addTouchEventListener(self.open_lottery_function)

    self.share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            sns_logic:GetAllGameRequests()
        end
    end)
end

return main_panel
