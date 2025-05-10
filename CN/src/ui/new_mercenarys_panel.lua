local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local feature_config = require "logic.feature_config"

local config_manager = require "logic.config_manager"
local mercenary_config = config_manager.mercenary_config
local lang_constants = require "util.language_constants"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local reward_logic = require 'logic.reward'
local REWARD_SOURCE = constants.REWARD_SOURCE

local time_logic = require "logic.time"
local mercenary_detail_panel = require "ui.mercenary_detail_panel"

local spine_manager = require "util.spine_manager"
local icon_template  = require "ui.icon_panel"

local SCENE_TRANSITION_TYPE = constants.SCENE_TRANSITION_TYPE

local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]

local PLIST_TYPE = ccui.TextureResType.plistType

local spine_node_tracker = panel_prototype.New()
spine_node_tracker.__index = spine_node_tracker

local FRAGMENT_PART =
{
    ["none"] = 0,
    ["mercenarys_begin"] = 1,
    ["mercenarys_translate"] = 2,                   --平移
    ["mercenarys_pause"] = 3,                       --暂停
    ["play_mercenary_start_animation"] = 4,         --动画
    ["is_new_mercenary"] = 5,                       --新佣兵
    ["mercenarys_end"] = 6,
}

local SHOW_TYPE = {
    ["vainty_adventure"] = 1,  --虚空冒险展示佣兵列表
}

function spine_node_tracker.New(root_node)
    local t = {}
    t.root_node = root_node

    t.complete_start = false
    t.complete_end = false
    t.bind_end = false

    t.slot_names ={}
    t.widgets = {}
    t.offset_x = {}
    t.offset_y = {}
    t.indexs = {}
    t.root_node:registerSpineEventHandler(function(event)

        if event.animation == "end" then
            t.complete_end = true
        end
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, spine_node_tracker)
end

function spine_node_tracker:BindWidget(slot_name, widget, x, y, index)

    if not widget then
        return
    end

    table.insert(self.slot_names, slot_name)
    table.insert(self.widgets, widget)
    table.insert(self.offset_x, x)
    table.insert(self.offset_y, y)
    table.insert(self.indexs, index)
    widget:setVisible(true)
end

function spine_node_tracker:SetSkin(skin)
    self.root_node:setSkin(skin)
end

function spine_node_tracker:SetAnimation(animation, bind_end)
    self.root_node:addAnimation(0, animation, false)
    self.bind_end = bind_end
    self.root_node:setVisible(true)
end

function spine_node_tracker:Update()
    if not self.root_node:isVisible() then
        return
    end

    for i, widget in ipairs(self.widgets) do
        local slot_name = self.slot_names[i]
        local offset_x = self.offset_x[i]
        local offset_y = self.offset_y[i]
        local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(slot_name)
        if slot_name == "role2" then
            if self.indexs[i] == 2 or self.indexs[i] == 3 then
                -- widget:setPosition(x, y)
                widget:setOpacity(alpha * 0.7)
            else
                widget:setPosition(56 + x, 56 + y)
                widget:setScale(scale_x, scale_y)
                widget:setOpacity(alpha)
            end

        else
            widget:setScale(scale_x, scale_y)
            widget:setOpacity(alpha)
            widget:setPosition(offset_x + x, offset_y + y)
        end

       -- widget:setRotation(rotation)
    end

end

local new_mercenarys_panel = panel_prototype.New()
function new_mercenarys_panel:Init()
    self.root_node = cc.Node:create()

    self.bg_img = ccui.Layout:create()
    self.bg_img:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    self.bg_img:setBackGroundColor(panel_util:GetColor4B(0x000000))
    self.bg_img:setOpacity(40)
    self.bg_img:setAnchorPoint(0.5, 0.5)
    self.bg_img:setContentSize(cc.size(640, 1136))
    self.bg_img:setPosition(320, 568)

    self.root_node:addChild(self.bg_img)

    self:CreateSpineNodes()
    self:CreateMercenarySubPanels()

    self.mercenary_detail_sub_panel = mercenary_detail_panel.New()
    self.mercenary_detail_sub_panel:Init()
    self.root_node:addChild(self.mercenary_detail_sub_panel.root_node, 101)
    self.mercenary_detail_sub_panel:Hide()

    self.num = 0
    self.pause_timer = 0
    self.end_timer = 0
    self.can_leave_reward = false
    self.new_mercenary_list = {}
    self.autoFireList = {}

    self.can_skip = false
    self.csb_node = cc.CSLoader:createNode("ui/new_mercenarys_panel.csb")
    self.skip_btn = self.csb_node:getChildByName("skip_btn")
    self.root_node:addChild(self.csb_node)

    local update_methods = {}

    update_methods[FRAGMENT_PART["mercenarys_begin"]] = function(elapsed_time)
        self.part_index = FRAGMENT_PART["mercenarys_translate"]
    end

    update_methods[FRAGMENT_PART["mercenarys_translate"]] = function(elapsed_time)
        --平移
        if self.show_spine_start then
            for i = 1, self.num do
                local tracker_root = self.spine_trackers[i].root_node
                local x = tracker_root:getPositionX()
                if x > self.spines_pos[i].x then
                    tracker_root:setPositionX(x - 75)   --每次平移75像素
                else
                    tracker_root:setPositionX(self.spines_pos[i].x)
                    self.show_spine_start = false
                end
            end
        end
        -- 下一步
        if not self.show_spine_start then
            self.part_index = FRAGMENT_PART["mercenarys_pause"]
        end
    end

    update_methods[FRAGMENT_PART["mercenarys_pause"]] = function(elapsed_time)
        --暂停
        if not self.show_spine_start then
            if self.pause_timer <= 0.5 then
                self.pause_timer = self.pause_timer + elapsed_time
            else
                --self.pause_timer = 1 保证暂停时间过去之后，self.show_spine_end = true 只运行一次
                if self.pause_timer ~= 1 then
                    self.show_spine_end = true
                end
                self.pause_timer = 1
            end
        end

        if self.show_spine_end then
            self.part_index = FRAGMENT_PART["play_mercenary_start_animation"]
        end

    end

    update_methods[FRAGMENT_PART["play_mercenary_start_animation"]] = function(elapsed_time)

        --动画
        for i = 1, self.num do
            local tracker = self.spine_trackers[i]
            if not tracker.complete_end then
                self.play_count = i
                tracker:Update(elapsed_time)

                if not tracker.bind_end then
                    local sub_panel = self.mercenary_sub_panels[i]
                    local sp_x, sp_y = self.spines_pos[i].x, self.spines_pos[i].y

                    tracker:BindWidget("role2", sub_panel.icon_img, sp_x, sp_y, 1)
                    tracker:BindWidget("role2", sub_panel.text_bg_img, sp_x, sp_y, 2)
                    tracker:BindWidget("role2", sub_panel.num_text, sp_x, sp_y, 3)

                    tracker:BindWidget("herolist_bg5", sub_panel.root_node, sp_x, sp_y, 4)
                    if self.new_mercenary_list[i].template_info.quality >= 5 then 
                        audio_manager:PlayEffect("se_recruit2")
                    else
                        local source = reward_logic.last_reward_source
                        if source == REWARD_SOURCE["recruit_blood"] or  source == REWARD_SOURCE["recruit_ten_blood"] or source == REWARD_SOURCE["recruit_normal"]
                        or source == REWARD_SOURCE["recruit_friendship"] or source == REWARD_SOURCE["recruit_ten_friendship"] or source == REWARD_SOURCE["recruit_magic"] then
                            if feature_config:IsFeatureOpen("auto_fire_mercenary") and configuration:GetAutoFire() then --如果召唤 自动解雇 
                                table.insert(self.autoFireList,self.new_mercenary_list[i].instance_id)
                            end
                        end
                    end

                    --是否跳过
                    if self.can_skip then --跳过动画
                        self:ShowMercenary(i)
                    else
                        tracker:SetAnimation("end", true)
                    end
                end
                break

            elseif self:NewMercenary(i) then
                self.part_index = FRAGMENT_PART["is_new_mercenary"]
                break
            end
        end

        local tracker =  self.spine_trackers[self.num]
        if tracker.is_new_mercenary then--最后一个是新（弹出新英雄详情） 
            if self.spine_trackers[self.num].complete_end and self.spine_trackers[self.num].show_detail then
                self.part_index = FRAGMENT_PART["mercenarys_end"]
            end
        elseif self.spine_trackers[self.num].complete_end then
            self.part_index = FRAGMENT_PART["mercenarys_end"]
        end
    end

    update_methods[FRAGMENT_PART["is_new_mercenary"]] = function(elapsed_time)
        -- 等待
    end

    update_methods[FRAGMENT_PART["mercenarys_end"]] = function(elapsed_time)
        -- 最后一个播放完毕，则可以离开界面
        if self.spine_trackers[self.num].complete_end then --自动播完
            if self.show_type == SHOW_TYPE["vainty_adventure"] then
                self.skip_btn:setTitleText(lang_constants:Get("vainty_adventure_join_us_btn_title"))
                self.skip_btn:setVisible(true) 
            else
                self.skip_btn:setVisible(false) 
            end
            self.can_leave = true
            self.show_spine_end = false
            if self.num == self.play_count then
                local tracker =  self.spine_trackers[self.play_count]
                if tracker.is_new_mercenary then--最后一个是新（弹出新英雄详情）
                    if self.canAutoFire then
                        if #self.autoFireList > 0 then
                            troop_logic:FireMercenary(self.autoFireList)
                        end
                    end
                else
                    if #self.autoFireList > 0 then
                        troop_logic:FireMercenary(self.autoFireList)
                    end
                end
                self.canAutoFire = false
                self.part_index = FRAGMENT_PART["none"]
            end
        end
    end
    self.update_methods = update_methods

    self:RegisterWidgetEvent()
end

function new_mercenarys_panel:CreateSpineNodes()
    self.spine_trackers = {}
    local begin_x = 110
    local begin_y = 708
    local interval = 140

    self.spines_pos = {}
    for i = 1, 10 do
        local spine_node = spine_manager:GetNode("recruit_start_n_end", 1.0, true)

        local row = math.ceil(i / 4)
        local col = i - (row - 1) * 4

        local x = begin_x + (col - 1) * interval
        local y = begin_y - (row - 1) * interval

        local pos = {x = x, y = y}
        self.spines_pos[i] = pos

        spine_node:setPosition(x, y)
        self.root_node:addChild(spine_node, 100)

        spine_node:setVisible(false)
        self.spine_trackers[i] = spine_node_tracker.New(spine_node)
    end

    self.new_mercenary_spine = spine_manager:GetNode("recruit_new", 1.0, false)
    self.root_node:addChild(self.new_mercenary_spine, 200)

    self.new_mercenary_spine:setVisible(false)
    self.new_mercenary_spine:setPosition(320, 568)
end

function new_mercenarys_panel:CreateMercenarySubPanels()
    self.mercenary_sub_panels = {}

    for i = 1, 10 do
        local sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
        sub_panel:Init(self.root_node, true)
        sub_panel:SetPosition(self.spines_pos[i].x, self.spines_pos[i].y)

        self.mercenary_sub_panels[i] = sub_panel
    end
end

function new_mercenarys_panel:Show(new_mercenary_list, num, show_type)
    self.can_leave_reward = false

    self.show_type = show_type

    self.root_node:setVisible(true)

    local source_type = constants.REWARD_TYPE["mercenary"]

    self.num = num
    self.autoFireList = {} --自动解雇list
    self.canAutoFire = false --当最后一个是新佣兵时的处理

    for i = 1, 10 do
        local mercenary = new_mercenary_list[i]
        local tracker = self.spine_trackers[i]

        if mercenary then
            local conf = self.mercenary_sub_panels[i]:Show(source_type, mercenary.template_info.ID, nil, nil, true)
            local quality = conf.quality
            if quality == 6 then
                quality = 5
            end

            tracker:SetSkin("reel" .. quality)
            tracker.is_new_mercenary = mercenary.is_new

            self.new_mercenary_list[i] = mercenary
        else
            self.new_mercenary_list[i] = nil
        end

        self.mercenary_sub_panels[i]:Hide()

        tracker.complete_start = false
        tracker.complete_end = false
        tracker.bind_end = false
        tracker.show_detail = false

        tracker.root_node:setPositionX(self.spines_pos[i].x)
        local x = tracker.root_node:getPositionX() + 640
        tracker.root_node:setPositionX(x)

        tracker.root_node:setToSetupPose()
        tracker.root_node:setVisible(true)
    end
    self.show_spine_start = true
    self.show_spine_end = false
    self.pause_timer = 0

    self.can_leave = false
    self.play_count = 0

    self.can_skip = false
    self.skip_btn:setVisible(true)
    
    self.part_index = FRAGMENT_PART["mercenarys_begin"]

    self.mercenary_detail_sub_panel:Hide()
    self.new_mercenary_spine:setVisible(false)

    self.skip_btn:setTitleText(lang_constants:Get("novice_sub_scene_skip_btn_desc"))
    
    if self.show_type == SHOW_TYPE["vainty_adventure"] then
        self.skip_btn:setVisible(false) 
    end

    audio_manager:PlayEffect("se_recruit1")
end

function new_mercenarys_panel:Hide()
    self.can_leave_reward = false
    self.root_node:setVisible(false)
end

function new_mercenarys_panel:Update(elapsed_time)
    if self.num == 0 then
        return
    end

    if self.part_index ~= FRAGMENT_PART["none"] then
        self.update_methods[self.part_index](elapsed_time)
    end
end

function new_mercenarys_panel:PlayNewMercenarySpine(template_id)
    self.new_mercenary_spine:setVisible(true)
    self.new_mercenary_spine:setToSetupPose()
    local quality = mercenary_config[template_id]["quality"]
    if quality == 5 then
        self.new_mercenary_spine:setAnimation(0, "new_leader", false)
    elseif quality == 6 then
        self.new_mercenary_spine:setAnimation(0, "new_leader_king", false)
    else
        self.new_mercenary_spine:setAnimation(0, "new", false)
    end
end

function new_mercenarys_panel:RegisterWidgetEvent()

    self.bg_img:setTouchEnabled(true)
    self.bg_img:addTouchEventListener(function (widget,event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.can_leave and not self.mercenary_detail_sub_panel.root_node:isVisible() then
                audio_manager:PlayEffect("click")
                if self.show_type == SHOW_TYPE["vainty_adventure"] then
                
                else
                    self.can_leave_reward = true
                end
            end
        end
    end)

    self.mercenary_detail_sub_panel.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.show_spine_end = true
            self.new_mercenary_spine:setVisible(false)
            self.mercenary_detail_sub_panel:Hide()

            if self.play_count == self.num then
                self.canAutoFire = true --关闭详情之后再发送解雇请求
            end
            self.part_index = FRAGMENT_PART["play_mercenary_start_animation"]
        end
    end)

    self.skip_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.show_type == SHOW_TYPE["vainty_adventure"] then
                self.can_leave_reward = true
            else
                self.can_skip = true
                self.skip_btn:setVisible(false)
            end
        end
    end)
end

function new_mercenarys_panel:NewMercenary(index)
    -- 监测当前是不是新的佣兵
    local tracker =  self.spine_trackers[index]
    if tracker.is_new_mercenary and not tracker.show_detail then
        tracker.show_detail = true
        self.show_spine_end = false
        self.canAutoFire = false
        local template_id = self.new_mercenary_list[self.play_count].template_id
        self.mercenary_detail_sub_panel:Show(client_constants["MERCENARY_DETAIL_MODE"]["recruit"], template_id, false)
        self:PlayNewMercenarySpine(template_id)
        return true
    elseif not tracker.show_detail then
        return false
    end
end

function new_mercenarys_panel:ShowMercenary(index)
    -- 不播放渐变动画，直接显示
    local tracker =  self.spine_trackers[index]
    -- local x, y, scale_x, scale_y, alpha, rotation = tracker.root_node:getSlotTransform("role2")
    tracker.root_node:setVisible(false)

    local sub_panel = self.mercenary_sub_panels[index]

    sub_panel.root_node:setOpacity(255)
    sub_panel.icon_img:setOpacity(255)
    sub_panel.icon_img:setVisible(true)
    sub_panel.text_bg_img:setOpacity(255 * 0.7)

    sub_panel.num_text:setOpacity(255 * 0.7)
    sub_panel.root_node:setScale(1, 1)

    tracker.bind_end = true
    tracker.complete_end = true
end

return new_mercenarys_panel
