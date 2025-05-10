local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local reminder_logic = require "logic.reminder"
local remind_list_panel = panel_prototype.New(true)
local REMIND_NUMBERS = 1 

local remind_sub_panel = panel_prototype.New()
remind_sub_panel.__index = remind_sub_panel
--[[
  metatable 设置
]]
function remind_sub_panel.New()
    return setmetatable({}, remind_sub_panel)
end
--[[
  remind 子模块
]]
function remind_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.button_bg_img = root_node:getChildByName("completed_bg")
    self.button_icon = self.button_bg_img:getChildByName("icon")
    self.forge_switched = configuration:GetRemindClosedSwitch("closed_remind_forge_switch")
    self:UpdateSelectedIcon(not self.forge_switched)
    self.forge_text = root_node:getChildByName("list_text")
    self.forge_text:setString(lang_constants:Get("forge_remind_tip"))
    self:RegisterWidgetEvent()
end
--[[
  选中框显示处理
]]
function remind_sub_panel:UpdateSelectedIcon(flag)
    self.button_icon:setVisible(flag)
end
--[[
   控件事件注册
]]
function remind_sub_panel:RegisterWidgetEvent()
    self.button_bg_img:setTouchEnabled(true)
    self.button_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.forge_switched = not self.forge_switched
            self:UpdateSelectedIcon(not self.forge_switched)
            configuration:SetRemindClosedSwitch("closed_remind_forge_switch",self.forge_switched)
            -- 检测强化提醒
            reminder_logic:CheckForgeReminder()
        end
    end)
end
--[[
   提醒界面初始化
]]
function remind_list_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/remind_list_panel.csb")
    self.remind_list_view = self.root_node:getChildByName("listview")
    self.template = self.remind_list_view:getChildByName("template")
    -- 之后配好了循环生成
    local sub_panel = remind_sub_panel.New()
    sub_panel:Init(self.template, 1)

    self:RegisterWidgetEvent()
end
--[[
  隐藏
]]
function remind_list_panel:Hide()
   configuration:Save()
   self.root_node:setVisible(false)
end
--[[
  注册控件事件
]]
function remind_list_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return remind_list_panel
