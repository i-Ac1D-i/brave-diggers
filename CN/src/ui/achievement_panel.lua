local config_manager = require "logic.config_manager"
local animation_manager = require "util.animation_manager"
local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config
local item_config = config_manager.item_config
local destiny_skill_config = config_manager.destiny_skill_config

local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local resource_logic = require "logic.resource"
local achievement_logic = require "logic.achievement"
local adventure_logic = require "logic.adventure"
local sns_logic = require "logic.sns"
local title_logic = require "logic.title"
local graphic = require "logic.graphic"
local feature_config = require "logic.feature_config"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local icon_tempalte = require "ui.icon_panel"
local reuse_scrollview = require "widget.reuse_scrollview"

local platform_manager = require "logic.platform_manager"
local channel_info = platform_manager:GetChannelInfo()

local utils = require "util.utils"
local time_logic = require "logic.time"

local SUB_PANEL_HEIGHT = 164
local SUB_TITLE_PANEL_HEIGHT = 228
local FIRST_SUB_PANEL_OFFSET = -80
local FIRST_TITLE_SUB_PANEL_OFFSET = -50
local MAX_SUB_PANEL_NUM = 7
local MAX_SUB_TITLE_PANEL_NUM = 5
local MAX_PROGRESS = 6
local REWARD_TYPE = constants["REWARD_TYPE"]


local title_sub_panel = panel_prototype.New()
title_sub_panel.__index = title_sub_panel

function title_sub_panel.New()
    return setmetatable({}, title_sub_panel)
end

function title_sub_panel:Init(root_node)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)
    
    --佩戴、激活、按钮
    self.wear_btn = self.root_node:getChildByName("Button_11")
    --称号条件描述
    self.desc = self.root_node:getChildByName("desc")
    --时间描述
    self.remain_time = self.root_node:getChildByName("remain_time")

    self.complete_img = self.root_node:getChildByName("Image_410")
    self.complete_img:setVisible(false)

    self.panel = self.root_node:getChildByName("Panel_3")
    self.bp_value = self.panel:getChildByName("bp_value")
    self.speed_value = self.panel:getChildByName("speed_value")
    self.defense_value = self.panel:getChildByName("defense_value")
    self.dodge_value = self.panel:getChildByName("dodge_value")
    self.authority_value = self.panel:getChildByName("authority_value")

    self.title_node = self.root_node:getChildByName("title_icon")
    self.title_left = self.title_node:getChildByName("title_left")
    self.title_name = self.title_node:getChildByName("Text_96")

    local shadow1 = self.panel:getChildByName("shadow1_1")
    local shadow2 = self.panel:getChildByName("shadow1")
    local shadow3 = self.panel:getChildByName("shadow1_0_0_0")
    local shadow4 = self.panel:getChildByName("shadow1_0")
    local shadow5 = self.panel:getChildByName("shadow1_0_0")

    shadow1:setOpacity(255*0.15)
    shadow2:setOpacity(255*0.15)
    shadow3:setOpacity(255*0.15)
    shadow4:setOpacity(255*0.15)
    shadow5:setOpacity(255*0.15)

    graphic:RegisterEvent("update_title_limit_time",function() 
        if self.data and self.data.start_time then
            local data = self.data
            local cur_time = time_logic:Now()
            local end_time = data.start_time + data.title_limit * 60
            local seconds = math.abs(end_time - cur_time) 
            local date = utils:getTimeString(seconds)
            
            local hours = date.hours or 0
            local minutes = date.minutes or 0
            local seconds = date.seconds or 0

            self.remain_time:setString(string.format(lang_constants:Get("title_time_limit"),string.format("%d:%d:%d",hours,minutes,seconds)))
        end
    end) 
    
end

function title_sub_panel:ReloadData(index)
    local title_config = title_logic.title_config

    local data = title_config[index]
    self.data = data
    local desc = data.desc 
    if data.is_view and data.achievement then
        local value = achievement_logic.statistic_list[data.type]
        desc = string.format(desc,value) 
    end

    if data.state and data.state >= client_constants.TITLE_STATE.actived then
        desc = lang_constants:Get("title_finish")
    end

    self.desc:setString(desc)

    self.bp_value:setString(utils:convertToUnit(data.bp)) 
    self.speed_value:setString(data.speed)
    self.defense_value:setString(data.defense)
    self.dodge_value:setString(data.dodge)
    self.authority_value:setString(data.authority)

    self.title_name:setString(data.title_name)

    local bottom_path = data.icon or "titles/title_01.png"
    self.title_left:loadTexture(bottom_path,PLIST_TYPE)

    if data.start_time then
        local cur_time = time_logic:Now()
        local end_time = data.start_time + data.title_limit * 60
        local seconds = math.abs(end_time - cur_time) 
        local date = utils:getTimeString(seconds)
        local hours = date.hours or 0
        local minutes = date.minutes or 0
        local seconds = date.seconds or 0

        self.remain_time:setString(string.format(lang_constants:Get("title_time_limit"),string.format("%d:%d:%d",hours,minutes,seconds)))
    elseif data.title_limit > 0 then
        local seconds = data.title_limit * 60
        local date = utils:getTimeString(seconds)
        
        local hours = date.hours or 0
        local minutes = date.minutes or 0
        local seconds = date.seconds or 0
        self.remain_time:setString(string.format(lang_constants:Get("title_time_limit"),string.format("%d:%d:%d",hours,minutes,seconds)))
    else
        self.remain_time:setString(lang_constants:Get("title_time_forever")) 
    end
    self.wear_btn:setVisible(true) 
    local btn_str = ""
    if data.state == client_constants["TITLE_STATE"]["actived"] then
        btn_str = lang_constants:Get("title_".."actived")
        self.wear_btn:loadTextureNormal("button/buttonbg_4.png", PLIST_TYPE)
        self.wear_btn:loadTexturePressed("button/buttonbg_4.png", PLIST_TYPE)
    elseif data.state == client_constants["TITLE_STATE"]["wear"] then
        self.wear_btn:setVisible(false) 
        self.complete_img:setVisible(true) 
    elseif data.state == client_constants["TITLE_STATE"]["can_active"] then
        btn_str = lang_constants:Get("title_".."can_active")
        self.wear_btn:loadTextureNormal("button/buttonbg_5.png", PLIST_TYPE)
        self.wear_btn:loadTexturePressed("button/buttonbg_5.png", PLIST_TYPE)
    else
        btn_str = lang_constants:Get("title_".."none")
        self.wear_btn:loadTextureNormal("button/buttonbg_6.png", PLIST_TYPE)
        self.wear_btn:loadTexturePressed("button/buttonbg_6.png", PLIST_TYPE)
    end
    self.wear_btn:setTitleText(btn_str) 

    self.wear_btn:setTag(index)
end

function title_sub_panel:Show(index,is_flip)

    if is_flip and self.root_node:isVisible() then
        local delay = cc.DelayTime:create(0.1*index) 
        local scaleX = cc.ScaleTo:create(0.1,1,0)
        local func = cc.CallFunc:create(function()
            self:ReloadData(index)
        end) 
        local scaleX2 = cc.ScaleTo:create(0.1,1,1)
        local seq = cc.Sequence:create(delay,scaleX,func,scaleX2)
        self.root_node:runAction(seq)
    else  
        self:ReloadData(index)
    end
end


--兑换奖励的详细信息panel
local achievement_sub_panel = panel_prototype.New()
achievement_sub_panel.__index = achievement_sub_panel

function achievement_sub_panel.New()
    return setmetatable({}, achievement_sub_panel)
end

function achievement_sub_panel:Init(root_node)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)
    self.desc_text = root_node:getChildByName("desc")

    self.progress_imgs = {}
    for i = 1, MAX_PROGRESS do
        self.progress_imgs[i] = root_node:getChildByName("star" .. i)
        self.progress_imgs[i]:loadTexture("icon/global/star.png", PLIST_TYPE)
    end

    self.cur_process_text = root_node:getChildByName("value")
    if channel_info.achievement_panel_change_process_text_pos_x and platform_manager:GetLocale() == "de" then
        self.cur_process_text:setPositionX(self.cur_process_text:getPositionX() + 15)
    end

    self.icon_panel = icon_tempalte.New(nil, 2)
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(77, 81)

    local channel = platform_manager:GetChannelInfo()
    if channel.meta_channel == "txwy_dny" then
        --东南亚渠道icon缩放
        self.icon_panel:SetPosition(70, 81)
        self.icon_panel.root_node:setScale(0.8)
    end
    

    self.take_reward_btn = root_node:getChildByName("get_btn")
    self.complete_flag_img = root_node:getChildByName("completed_bg")

    self.fb_share_node = root_node:getChildByName("fb_share_panel")
    self.fb_share_btn = self.fb_share_node:getChildByName("fb_share_btn")
    self.fb_share_num = self.fb_share_node:getChildByName("reward_num")

    if platform_manager:GetChannelInfo().facebook_share_not_get_reward then
        self.fb_share_icon = self.fb_share_node:getChildByName("reward_icon")
        self.fb_share_bg = self.fb_share_node:getChildByName("bg")
        self.fb_share_num:setVisible(false)
        self.fb_share_icon:setVisible(false)
        self.fb_share_bg:setVisible(false)
    end
    --r2修改
    if platform_manager:GetChannelInfo().achievement_sub_panel_icon_panel_hide then
        --法语不明白为什多在icon下面多一串字，这个方法隐藏了就没有了
        self.icon_panel.root_node:setVisible(false)
    end
end

function achievement_sub_panel:Show(achievement_type)
    self.achievement_type = achievement_type or self.achievement_type
    local cur_step = achievement_logic:GetCurStep(self.achievement_type)
    local max_step = #config_manager.achievement_config[achievement_type]
    local achievement_step_conf

    if cur_step < max_step then
        achievement_step_conf = config_manager.achievement_config[achievement_type][cur_step + 1]
    else
        achievement_step_conf = config_manager.achievement_config[achievement_type][cur_step]
    end

    if not channel_info.has_sns_share then
        self.complete_flag_img:setVisible(cur_step == max_step)
        self.fb_share_node:setVisible(false)
    else
        --检测是否分享过
        if sns_logic:CanShare(constants.SNS_EVENT_TYPE["share_achievement"], achievement_type) then
            self.complete_flag_img:setVisible(false)
            self.fb_share_node:setVisible(true)
        else
            self.complete_flag_img:setVisible(cur_step == max_step)
            self.fb_share_node:setVisible(false)
        end
    end

    local need_value = achievement_step_conf["need_value"]
    local cur_value = achievement_logic:GetStatisticValue(achievement_type)

    self.desc_text:setString(achievement_step_conf["desc"])

    if self.achievement_type == constants.ACHIEVEMENT_TYPE["maze"] then
        self:Maze(cur_step, max_step, cur_value, need_value)
    else
        self.cur_process_text:setString(cur_value .. "/" .. need_value)
        if cur_step == max_step then
            self.take_reward_btn:setVisible(false)
            self.root_node:setColor(panel_util:GetColor4B(0xdcff7f))
        else
            if cur_value >= need_value then
                self.root_node:setColor(panel_util:GetColor4B(0xdcff7f))
                self.take_reward_btn:setVisible(true)
            else
                self.root_node:setColor(panel_util:GetColor4B(0xffffff))
                self.take_reward_btn:setVisible(false)
            end
        end
    end

    self.fb_share_num:setString(string.format(lang_constants:Get("share_og_get_reward_count"),constants["SNS_SHARE_REWARD"]["share_achievement"]))

    self:SetProgressImg(cur_step, max_step)
    self:LoadRewardInfo(achievement_step_conf)
end

--关卡显示
function achievement_sub_panel:Maze(cur_step, max_step, cur_value, need_value)
    if cur_step == max_step then
        self.take_reward_btn:setVisible(false)
        self.root_node:setColor(panel_util:GetColor4B(0xdcff7f))
        self.cur_process_text:setString("1/1")
    else

        local maze_clear = adventure_logic:IsMazeClear(need_value)
        if maze_clear then
            self.cur_process_text:setString("1/1")
            self.root_node:setColor(panel_util:GetColor4B(0xdcff7f))
        else
            self.cur_process_text:setString("0/1")
            self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        end
        self.take_reward_btn:setVisible(maze_clear)
    end
end

function achievement_sub_panel:LoadRewardInfo(achievement_step_conf)
    local reward_type = achievement_step_conf["reward_type"]
    local param1 = achievement_step_conf["param1"]
    local param2 = achievement_step_conf["param2"]
    self.icon_panel:Show(reward_type, param1, param2, false, true)

end

--进度图片
function achievement_sub_panel:SetProgressImg(cur_step, max_step)
    if cur_step == max_step then
        for i = 1, MAX_PROGRESS do
            self.progress_imgs[i]:setVisible(false)
        end

    else
        local switch_step = max_step - cur_step
        for i = 1, MAX_PROGRESS do
            self.progress_imgs[i]:setVisible(true)

            if i <=  switch_step then
                self.progress_imgs[i]:setOpacity(255 * 0.3)

            elseif i <= max_step then
                self.progress_imgs[i]:setOpacity(255)

            else
                self.progress_imgs[i]:setVisible(false)
            end
        end
    end
end

local achievement_panel = panel_prototype.New(true)

function achievement_panel:Init()
    if feature_config:IsFeatureOpen("title") then
        self.root_node = cc.CSLoader:createNode("ui/honor_panel.csb")
    else
        self.root_node = cc.CSLoader:createNode("ui/achievement_panel.csb")
    end

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.google_btn = self.root_node:getChildByName("google_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.scroll_view:getChildByName("template")

    if feature_config:IsFeatureOpen("title") then
        --FYD:
        self.title_bg = self.root_node:getChildByName("title_bg")
        self.title_name = self.title_bg:getChildByName("name")
        self.id_bg = self.root_node:getChildByName("id_bg")
        self.id_bg_desc = self.root_node:getChildByName("desc_0")

        self.view_info_btn = self.root_node:getChildByName("view_info_btn")
        self.id_bg_desc:setString(lang_constants:Get("title_desc"))

        self.scroll_view_title = self.root_node:getChildByName("scroll_view_title")
        self.scroll_view_title:setVisible(false)
        self.id_bg:setVisible(false)
        self.id_bg_desc:setVisible(false)
        self.view_info_btn:setVisible(false)
        self.template_title = self.scroll_view_title:getChildByName("template_title")
        self.template_title:setAnchorPoint(cc.p(0.5,0.5))
        self.node_achievement_btn = self.root_node:getChildByName("node_achievement_btn")
        self.node_title_btn = self.root_node:getChildByName("node_title_btn")
        self.achieve_img = self.node_achievement_btn:getChildByName("dizuo"):getChildByName("Image_1")
        self.title_img = self.node_title_btn:getChildByName("dizuo"):getChildByName("Image_1")

        self.achieve_green = self.node_achievement_btn:getChildByName("remind_icon")
        self.title_green = self.node_title_btn:getChildByName("remind_icon")

        self.title_sub_panels = {}
        self.reuse_scrollview_title = reuse_scrollview.New(self, self.scroll_view_title, self.title_sub_panels, SUB_TITLE_PANEL_HEIGHT)
        self.reuse_scrollview_title:RegisterMethod(
            function(self)
                return self.parent_panel.title_num
            end,

            function(self, sub_panel, is_up)
                local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
                sub_panel:Show(index)
            end
        )
    end
    
    self.achievement_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.achievement_sub_panels, SUB_PANEL_HEIGHT)

    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.achievement_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel:GetAchievementType(index))
        end
    )

    if self.google_btn then
        if channel_info.show_achievement_btn then
            self.google_btn:setVisible(true)
        else
            self.google_btn:setVisible(false)
        end
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self:CreateSubPanels()
    if feature_config:IsFeatureOpen("title") then
        self:CreateSubTitlePanels()
        self:LoadAnimation()
    end
end

function achievement_panel:CreateSubTitlePanels()
    for i = 1 , MAX_SUB_TITLE_PANEL_NUM do
        local sub_panel = title_sub_panel.New()
        if i == 1 then
            sub_panel:Init(self.template_title)
        else
            sub_panel:Init(self.template_title:clone())
            self.scroll_view_title:addChild(sub_panel.root_node)
        end

        self.title_sub_panels[i] = sub_panel
        sub_panel.wear_btn:addTouchEventListener(self.complete_title)
    end
    self.sub_title_panel_num = MAX_SUB_TITLE_PANEL_NUM
end


function achievement_panel:CreateSubPanels()
    for i = 1 , MAX_SUB_PANEL_NUM do
        local sub_panel = achievement_sub_panel.New()
        if i == 1 then
            sub_panel:Init(self.template)
        else
            sub_panel:Init(self.template:clone())
            self.scroll_view:addChild(sub_panel.root_node)
        end

        self.achievement_sub_panels[i] = sub_panel

        sub_panel.take_reward_btn:setTag(i)
        sub_panel.take_reward_btn:addTouchEventListener(self.complete_achievement)
        sub_panel.fb_share_btn:setTag(i)
        sub_panel.fb_share_btn:addTouchEventListener(self.share_method)

    end
    self.sub_panel_num = MAX_SUB_PANEL_NUM
end

function achievement_panel:Show()
    self.root_node:setVisible(true)
    self.complete_list = achievement_logic:GetCompleteList()
    self.uncomplete_list = achievement_logic:GetUnCompleteList()

    self.complete_num = #self.complete_list
    self.achievement_num =  self.complete_num + #self.uncomplete_list

    local height = math.max(self.achievement_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1,  self.sub_panel_num do
        local sub_panel = self.achievement_sub_panels[i]
        local achievement_type = self:GetAchievementType(i)

        sub_panel:Show(achievement_type)

        local y = height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT
        sub_panel.root_node:setPositionY(y)
    end

    self.reuse_scrollview:Show(height+100, 0)

    if feature_config:IsFeatureOpen("title") then
        --FYD:
        self.title_num = #title_logic.title_config
        local height2 = math.max(self.title_num * SUB_TITLE_PANEL_HEIGHT, self.reuse_scrollview_title.sview_height)
        for i = 1,  self.sub_title_panel_num do
            local sub_panel = self.title_sub_panels[i] 
            sub_panel:Show(i)

            local y = height2 + FIRST_TITLE_SUB_PANEL_OFFSET - (i - 1) * SUB_TITLE_PANEL_HEIGHT
            sub_panel.root_node:setPositionY(y)
        end
        self.reuse_scrollview_title:Show(height2+100, 0)

        if self.tab_index == "title" then
            title_logic.has_green = nil
        end
        self.title_green:setVisible(title_logic:CheckGreen())
        self.achieve_green:setVisible(#achievement_logic.can_complete_list > 0)
    end
end

function achievement_panel:GetAchievementType(index)
    local achievement_type

    if index <= self.complete_num then
        achievement_type = self.complete_list[index]
    else
        achievement_type = self.uncomplete_list[index - self.complete_num]
    end

    return achievement_type
end

function achievement_panel:RegisterEvent()
    graphic:RegisterEvent("complete_achievement", function(achievement_type)
        if not self.root_node:isVisible() then
            return
        end

        self.complete_num = #self.complete_list

        for i = 1, self.sub_panel_num do
            local achievement_type_index = self.reuse_scrollview:GetDataIndex(i)
            local achievement_type = self:GetAchievementType(achievement_type_index)

            self.achievement_sub_panels[i]:Show(achievement_type)
        end
        if self.achieve_green then
            self.achieve_green:setVisible(#achievement_logic.can_complete_list > 0)
        end
    end)

    --更新
    graphic:RegisterEvent("update_achievement_progress", function(achievement_type)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_num do
            local cur_sub_panel = self.achievement_sub_panels[i]
            if cur_sub_panel.achievement_type == achievement_type then
                cur_sub_panel:Show(achievement_type)
            end
        end
    end)

    -- 隐藏FB按钮
    graphic:RegisterEvent("hide_achieve_panel_fb_node", function(achievement_type)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_num do
            local cur_sub_panel = self.achievement_sub_panels[i]
            if cur_sub_panel.achievement_type == achievement_type then
                cur_sub_panel.fb_share_node:setVisible(false)
            end
        end
    end)
    if feature_config:IsFeatureOpen("title") then
         --更新称号系统 按钮的文本
        graphic:RegisterEvent("update_title_btn_title", function ()
            self.title_num = #title_logic.title_config
            local height2 = math.max(self.title_num * SUB_TITLE_PANEL_HEIGHT, self.reuse_scrollview_title.sview_height)
            for i = 1,  self.sub_title_panel_num do
                local sub_panel = self.title_sub_panels[i] 
                sub_panel:Show(i,true)

                local y = height2 + FIRST_TITLE_SUB_PANEL_OFFSET - (i - 1) * SUB_TITLE_PANEL_HEIGHT
                sub_panel.root_node:setPositionY(y)
            end
            self.reuse_scrollview_title:Show(height2+100, 0)
        end)
    end
end

function achievement_panel:LoadAnimation()
    self.time_line_action_achieve = animation_manager:GetTimeLine("achievement_tab_timeline")
    self.node_achievement_btn:runAction(self.time_line_action_achieve)

    self.time_line_action_title = animation_manager:GetTimeLine("title_tab_timeline")
    self.node_title_btn:runAction(self.time_line_action_title)
    self.time_line_action_title:gotoFrameAndPause(3)
    self.tab_index = "achievement"
end

function achievement_panel:PlayAnimation(id,scale_small)
    if id == "achievement" then
        if scale_small then
            self.time_line_action_achieve:gotoFrameAndPlay(1, 3, false)
        else
            self.time_line_action_achieve:gotoFrameAndPlay(4, 6, false)
        end
        
    elseif id == "title" then
        
        if scale_small then
            self.time_line_action_title:gotoFrameAndPlay(1, 3, false)
        else
            self.time_line_action_title:gotoFrameAndPlay(4, 6, false)
        end
    end
end

function achievement_panel:SelectTab(id)
    if id == "achievement" then
        self:PlayAnimation("achievement",false) 
        self:PlayAnimation("title",true) 
        self.scroll_view:setVisible(true) 
        self.scroll_view_title:setVisible(false)
        self.id_bg:setVisible(false)
        self.id_bg_desc:setVisible(false)
        self.view_info_btn:setVisible(false)
        self.tab_index = id 
        self.title_name:setString(lang_constants:Get("title_name1"))
    elseif id == "title" then  
        self:PlayAnimation("achievement",true) 
        self:PlayAnimation("title",false) 
        self.scroll_view:setVisible(false)
        self.scroll_view_title:setVisible(true)
        self.id_bg:setVisible(true)
        self.id_bg_desc:setVisible(true)
        self.view_info_btn:setVisible(true)
        self.tab_index = id 
        self.title_name:setString(lang_constants:Get("title_name2"))
        title_logic.has_green = nil
        self.title_green:setVisible(title_logic:CheckGreen())
    end
end

function achievement_panel:RegisterWidgetEvent()
    if feature_config:IsFeatureOpen("title") then
        self.achieve_img:addTouchEventListener(function(sender, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if self.tab_index ~= "achievement" then
                    self:SelectTab("achievement")
                end
            end
        end)

        self.title_img:addTouchEventListener(function(sender, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if self.tab_index ~= "title" then
                    self:SelectTab("title")
                end
            end
        end)
        --i
        self.view_info_btn:addTouchEventListener(function(sender, event_type)
            if event_type == ccui.TouchEventType.began then
                local desc = lang_constants:Get("title_rule_description")
                local origin = cc.p(sender:getPosition())
                local world_pos = self.root_node:convertToWorldSpace(origin)
                local target_pos = self.root_node:convertToNodeSpace(world_pos)
                local title_rule_name = lang_constants:Get("title_rule_name")
                graphic:DispatchEvent("show_floating_panel",title_rule_name,desc,target_pos.x,target_pos.y,true)
            elseif event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("hide_floating_panel")
            elseif event_type == ccui.TouchEventType.canceled then
                audio_manager:PlayEffect("click")
                graphic:DispatchEvent("hide_floating_panel")
            end
        end)

        self.complete_title = function(widget, event_type)

            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                local index = widget:getTag()

                local title_config = title_logic.title_config
                local data = title_config[index]
                if data.state == client_constants["TITLE_STATE"]["actived"] then
                    --当前处于激活状态
                    title_logic:WearTitle(data.ID) 
                elseif data.state == client_constants["TITLE_STATE"]["wear"] then
                    --当前处于佩戴状态
                    graphic:DispatchEvent("show_prompt_panel", "title_arrady_wear")
                elseif data.state == client_constants["TITLE_STATE"]["can_active"] then
                    --当前处于可激活状态
                    title_logic:ActiveTitle(data.ID) 
                else
                    --当前处于未激活状态
                    graphic:DispatchEvent("show_prompt_panel", "title_not_conddition")
                end 
            end
        end
    end

    self.complete_achievement = function(widget, event_type)

        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local index = widget:getTag()
            local sub_panel = self.achievement_sub_panels[index]
            if sub_panel.achievement_type then
                achievement_logic:Complete(sub_panel.achievement_type)
            end
        end
    end

    self.share_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local sub_panel = self.achievement_sub_panels[index]
            if sub_panel.achievement_type then
                sns_logic:Share(constants.SNS_EVENT_TYPE["share_achievement"], sub_panel.achievement_type)
            end
        end
    end

    self.back_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    if self.google_btn then 
        self.google_btn:addTouchEventListener(function(sender, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                achievement_logic:ShowAchievement()
            end
        end)
    end
end

return achievement_panel
