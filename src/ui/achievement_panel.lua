local config_manager = require "logic.config_manager"

local mercenary_config = config_manager.mercenary_config
local resource_config = config_manager.resource_config
local item_config = config_manager.item_config
local achievement_config = config_manager.achievement_config
local destiny_skill_config = config_manager.destiny_skill_config

local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local resource_logic = require "logic.resource"
local achievement_logic = require "logic.achievement"
local adventure_logic = require "logic.adventure"
local sns_logic = require "logic.sns"

local graphic = require "logic.graphic"

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

local SUB_PANEL_HEIGHT = 164
local FIRST_SUB_PANEL_OFFSET = -80
local MAX_SUB_PANEL_NUM = 7
local MAX_PROGRESS = 6
local REWARD_TYPE = constants["REWARD_TYPE"]

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
    local hide=platform_manager:GetChannelInfo().achievement_sub_panel_icon_panel_hide
    if hide then
        --法语不明白为什多在icon下面多一串字，这个方法隐藏了就没有了
        self.icon_panel.root_node:setVisible(false)
    end
    
end

function achievement_sub_panel:Show(achievement_type)
    self.achievement_type = achievement_type or self.achievement_type
    local cur_step = achievement_logic:GetCurStep(self.achievement_type)
    local max_step = #achievement_config[self.achievement_type]
    local achievement_step_conf
    if cur_step < max_step then
        achievement_step_conf = achievement_config[self.achievement_type][cur_step + 1]
    else
        achievement_step_conf = achievement_config[self.achievement_type][cur_step]
    end

    if not channel_info.has_sns_share then
        self.complete_flag_img:setVisible(cur_step == max_step)
        self.fb_share_node:setVisible(false)
    else
        --检测是否分享过
        if sns_logic:CanShare(constants.SNS_EVENT_TYPE["share_achievement"], self.achievement_type) then
            self.complete_flag_img:setVisible(false)
            self.fb_share_node:setVisible(true)
        else
            self.complete_flag_img:setVisible(cur_step == max_step)
            self.fb_share_node:setVisible(false)
        end
    end

    local need_value = achievement_step_conf["need_value"]
    local cur_value = achievement_logic:GetStatisticValue(self.achievement_type)

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

    self.root_node = cc.CSLoader:createNode("ui/achievement_panel.csb")

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.google_btn = self.root_node:getChildByName("google_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.scroll_view:getChildByName("template")

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
end

function achievement_panel:RegisterWidgetEvent()

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
