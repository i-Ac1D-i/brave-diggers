local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local network = require "util.network"
local user_logic = require "logic.user"
local constants = require "util.constants"
local random_name = require "util.random_name"
local platform_manager = require "logic.platform_manager"
local common_function = require "util.common_function"

local panel_util = require "ui.panel_util"

local rename_panel = panel_prototype.New(true)

function rename_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/rename_panel.csb")

    local reply_detail = self.root_node:getChildByName("reply_detail")
    -- 输入框
    self.text_field = reply_detail:getChildByName("textfield")
    -- 剩余字数
    self.remain_word = reply_detail:getChildByName("remain_word")

    -- 确认修改按钮
    self.confirm_rename_btn = self.root_node:getChildByName("add_reply_btn")
    -- 取消按钮
    self.cancel_rename_btn = self.root_node:getChildByName("reply_cancel_btn")

    self.cost_text = self.confirm_rename_btn:getChildByName("value")

    -- 随机名字按钮
    self.random_name_btn = self.root_node:getChildByName("name_btn")

    self.cost_text:setString(tostring(constants.RENAME_COST))

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function rename_panel:Show()
    self.root_node:setVisible(true)
end

function rename_panel:RegisterWidgetEvent()
    -- 关闭面板
    self.cancel_rename_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", "rename_panel")
        end
    end)

    -- 确认改名
    self.confirm_rename_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local leader_name = string.gsub(self.text_field:getString(), " ", "")
            --检查血钻消耗
            if not panel_util:CheckBloodDiamond(constants["RENAME_COST"]) then
                return
            end

            user_logic:ChangeLeaderName(leader_name)
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    -- 改名面板剩余字数
    self.text_field:addEventListener(function(sender, eventType)
        if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
            local string_table = common_function.Utf8to32(self.text_field:getString())
            local left_words = constants["LEADER_NAME_LENGTH"] - #string_table + 1
            if left_words < 0 then left_words = 0 end
            self.remain_word:setString(tostring(left_words))
        end
    end)

    -- 随机名字按钮
    self.random_name_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local leader_name = random_name:GetRandomName()
            self.text_field:setString(leader_name)

            local left_words = constants["LEADER_NAME_LENGTH"] - common_function.Utf8Len(leader_name)
            if left_words < 0 then left_words = 0 end
            self.remain_word:setString(tostring(left_words))
        end
    end)
end

function rename_panel:RegisterEvent()
    graphic:RegisterEvent("update_panel_leader_name", function(name)
        if not self.root_node:isVisible() then
            return
        end

        self.text_field:setString("")
        self.remain_word:setString(tostring(constants["LEADER_NAME_LENGTH"]))
    end)
end

return rename_panel
