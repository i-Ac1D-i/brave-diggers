local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local network = require "util.network"
local user_logic = require "logic.user"
local troop_logic = require "logic.troop"

local constants = require "util.constants"
local random_name = require "util.random_name"
local platform_manager = require "logic.platform_manager"
local common_function = require "util.common_function"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local RENAME_PANEL_MODE = client_constants["RENAME_PANEL_MODE"]
local lang_constants = require "util.language_constants"

local rename_panel = panel_prototype.New(true)

function rename_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/rename_panel.csb")

    local reply_detail = self.root_node:getChildByName("reply_detail")
    -- 输入框
    self.text_field = reply_detail:getChildByName("textfield")
    self.text_field_place_text = self.text_field:getPlaceHolder()

    -- 剩余字数
    self.remain_word = reply_detail:getChildByName("remain_word")

    self.title_text = reply_detail:getChildByName("user_name")

    -- 确认修改按钮
    self.confirm_rename_btn = self.root_node:getChildByName("add_reply_btn")
    self.confirm_shadow_img = self.confirm_rename_btn:getChildByName("shadow")
    self.confirm_value_text = self.confirm_rename_btn:getChildByName("value")
    self.confirm_icon_img = self.confirm_rename_btn:getChildByName("icon")

    -- 取消按钮
    self.cancel_rename_btn = self.root_node:getChildByName("reply_cancel_btn")

    self.cost_text = self.confirm_rename_btn:getChildByName("value")

    -- 随机名字按钮
    self.random_name_btn = self.root_node:getChildByName("name_btn")

    self.cost_text:setString(tostring(constants.RENAME_COST))

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

--修改阵容名字：param1=formation_id
function rename_panel:Show(mode, param1)
    self.max_name_length = 0

    self.mode = mode
    self.param1 = param1

    self:SetStatus()

    self.text_field:setString("")
    self.text_field:setPlaceHolder(self.text_field_place_text)

    self.root_node:setVisible(true)
end

function rename_panel:SetStatus()
    local is_user = self.mode == RENAME_PANEL_MODE["user"]
    self.random_name_btn:setVisible(is_user)
    self.confirm_icon_img:setVisible(is_user)
    self.confirm_value_text:setVisible(is_user)
    self.confirm_shadow_img:setVisible(is_user)

    if is_user then
        self.title_text:setString(lang_constants:Get("change_user_name"))
        self.max_name_length = constants["LEADER_NAME_LENGTH"]
    else
        self.title_text:setString(lang_constants:Get("change_formation_name"))
        self.max_name_length = constants["FORMATION_NAME_LENGTH"]
    end

    self.text_field:setMaxLength(self.max_name_length)
    self.remain_word:setString(tostring(self.max_name_length))
end

function rename_panel:CalcTextFieldLength()
    local left_words = self.max_name_length - common_function.Utf8Len(self.text_field:getString())

    if left_words < 0 then
        left_words = 0
    end

    self.remain_word:setString(tostring(left_words))
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

            local name = string.gsub(self.text_field:getString(), " ", "")
            if self.mode == RENAME_PANEL_MODE["user"] then
                --检查血钻消耗
                if not panel_util:CheckBloodDiamond(constants["RENAME_COST"]) then
                    return
                end

                user_logic:ChangeLeaderName(name)
            else
                troop_logic:ChangeFormationName(self.param1, name)
            end
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    -- 改名面板剩余字数
    self.text_field:addEventListener(function(sender, eventType)
        if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
            self:CalcTextFieldLength()
        end
    end)

    -- 随机名字按钮
    self.random_name_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.mode == RENAME_PANEL_MODE["user"] then
                local leader_name = random_name:GetRandomName()
                self.text_field:setString(leader_name)

                self:CalcTextFieldLength()
            end
        end
    end)
end

function rename_panel:RegisterEvent()
    graphic:RegisterEvent("update_panel_leader_name", function(name)
        if not self.root_node:isVisible() then
            return
        end

        self.text_field:setString("")
        self.remain_word:setString(tostring(self.max_name_length))
    end)
end

return rename_panel
