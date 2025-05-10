local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"

local OFFSET_X = 320
local OFFSET_Y = 568

local READING_MAIL = 1
local MAIL_EXIT = 2

local reading_mail_panel = panel_prototype.New(true)

local spine_node_tracker = {}
spine_node_tracker.__index = spine_node_tracker

function spine_node_tracker.New(root_node, slots)
    local t = {}
    t.slots = slots
    t.root_node = root_node

    t.root_node:registerSpineEventHandler(function(event)
        if event.animation == "normal_exit" or event.animation == "levelup_exit" then
            graphic:DispatchEvent("hide_world_sub_panel", "reading_mail_panel")
            reading_mail_panel.root_node:setVisible(false)
            if not reading_mail_panel.is_read then
                graphic:DispatchEvent("update_quest_panel")
            end

            reading_mail_panel.animation = nil
        elseif event.animation == "levelup_enter" then
            reading_mail_panel:Play("levelup_loop")
        end
        reading_mail_panel.animation_done = true
    end, sp.EventType.ANIMATION_COMPLETE)

    return setmetatable(t, spine_node_tracker)
end

function spine_node_tracker:Bind(animation)
    local loop = false
    if animation == "levelup_loop" then
        loop = true
    end

    self.root_node:setAnimation(0, animation, loop)
    if not self.root_node then self.root_node:setVisible(true) end
end

function spine_node_tracker:UpdateFocusWidget(detail)
    table.foreachi(self.slots, function (i, focus_one)
        if focus_one.key and detail[focus_one.key] then
            focus_one.widget:setString(detail[focus_one.key])
        end
    end)
end

function spine_node_tracker:Update()
    if not self.root_node:isVisible() or not self.slots then
        return
    end

    table.foreachi(self.slots, function (i, focus_one)
        local x, y, scale_x, scale_y, alpha = self.root_node:getSlotTransform(focus_one.slot_name)
        focus_one.widget:setPosition(OFFSET_X + x, OFFSET_Y + y)
        focus_one.widget:setScale(scale_x, scale_y)
        focus_one.widget:setOpacity(alpha)
    end)
end

function reading_mail_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/entrust_read_panel.csb")
    self.root_node:setVisible(false)

    local shadow = self.root_node:getChildByName("box_shadow")
    shadow:setTouchEnabled(true)
    shadow:setLocalZOrder(-2)
    shadow:setOpacity(0)

    local reading_node = self.root_node:getChildByName("reading")
    self.levelup_txt = reading_node:getChildByName("txt2_levelup")

    local read_mail_spine_node = spine_manager:GetNode("read_mail", 1.0, true)
    read_mail_spine_node:setPosition(OFFSET_X, OFFSET_Y)
    read_mail_spine_node:setLocalZOrder(-1)
    self.root_node:addChild(read_mail_spine_node)

    local slots, focus_one = {}, {}
    focus_one.slot_name = "txt1"
    focus_one.widget = reading_node:getChildByName("txt1_recipient")
    table.insert(slots, focus_one)

    self.role_name_widget = focus_one.widget

    focus_one = {}
    focus_one.slot_name = "txt2"
    focus_one.widget = reading_node:getChildByName("txt2_normal")

    --FYD  更改信件的字体大小
    local font_size = platform_manager:GetChannelInfo().focus_one_font_height
    if font_size then
        focus_one.widget:setFontSize(font_size) 
    end

    focus_one.key = "content"
    table.insert(slots, focus_one)

    focus_one = {}
    focus_one.slot_name = "txt3"
    focus_one.widget = reading_node:getChildByName("txt3_writer")
    focus_one.key = "writer"
    table.insert(slots, focus_one)

    self.spine_tracker = spine_node_tracker.New(read_mail_spine_node, slots)

    self.back_btn = reading_node:getChildByName("back_btn")

    self.animation = nil
    self.animation_done = true
    self.mail_id = 0
    self.show_backbtn_loop_time = 0
    self.loop = 0
    self.is_read = false

    self:RegisterWidgetEvent()
end

function reading_mail_panel:Show(mail_one, leader_name)
    if self.root_node:isVisible() then
        return
    end

    self.back_btn:setVisible(false)
    self.root_node:setVisible(true)

    if not self.mail_id or self.mail_id ~= mail_one.ID then
        self.role_name_widget:setString(lang_constants:Get("mail_to") .. "" .. leader_name)
        self.spine_tracker:UpdateFocusWidget(mail_one)
        self.mail_id = mail_one.ID
    end

    self.is_read = mail_one.is_read
    self.show_backbtn_loop_time = 1

    self:Play("normal_enter")
    -- self:Play("levelup_enter")
end

function reading_mail_panel:Play(animation)
    self.animation = animation
    self.animation_done = false
    self.spine_tracker:Bind(animation)
end

function reading_mail_panel:Update(elapsed_time)
    if not self.root_node or not self.root_node:isVisible() then
        return
    end

    -- 更新更随组件
    if self.animation and not self.animation_done then
        self.spine_tracker:Update(elapsed_time)
    end

    if self.show_backbtn_loop_time > 0 then
        self.loop = self.loop + elapsed_time
        if self.loop >= self.show_backbtn_loop_time then
            self.show_backbtn_loop_time = 0
            self.loop = 0

            self.back_btn:setVisible(true)
        end
    end
end

function reading_mail_panel:RegisterWidgetEvent()
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.back_btn:setVisible(false)

            if self.animation == "normal_enter" then
                self:Play("normal_exit")
            elseif self.animation == "levelup_loop" then
                self:Play("levelup_exit")
            end
        end
    end)
end

return reading_mail_panel
