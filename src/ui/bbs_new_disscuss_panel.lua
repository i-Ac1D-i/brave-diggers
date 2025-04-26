local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local client_constants = require "util.client_constants"
local constants = require "util.constants"
local PLIST_TYPE = ccui.TextureResType.plistType

local troop_logic = require "logic.troop"
local chat_logic = require "logic.chat"

local common_function = require "util.common_function"

local MAX = 90

-- 留言发起讨论
local bbs_new_discuss_panel = panel_prototype.New(true)
function bbs_new_discuss_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/discuss_add_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.add_discuss_btn = self.root_node:getChildByName("add_discuss_btn")

    self.discuss_detail_img = self.root_node:getChildByName("discuss_detail")
    self.user_icon = self.discuss_detail_img:getChildByName("user_icon")
    self.user_name = self.discuss_detail_img:getChildByName("user_name")
    self.text_field = self.discuss_detail_img:getChildByName("textfield")
    self.left_word_text = self.discuss_detail_img:getChildByName("surplus_word")

    self.user_name:setString(troop_logic:GetLeaderName())

    local icon = ""
    if troop_logic.mercenary_list then
        local mercenary = troop_logic.mercenary_list[1]
        if mercenary then
            icon = mercenary.template_info.sprite
        end
    end

    if not tonumber(icon) or string.len(icon) <= 0 then
        icon = 99000002
    end

    self.user_icon:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. icon .. ".png", PLIST_TYPE)

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function bbs_new_discuss_panel:Show(channel_type)
    self.channel_type = channel_type
    self.root_node:setVisible(true)

    self.left_word_text:setString(tostring(MAX))
end

function bbs_new_discuss_panel:RegisterWidgetEvent()
    -- 返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene", "bbs_new_discuss_sub_scene")
        end
    end)

    -- 发起讨论按钮
    self.add_discuss_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local text = self.text_field:getString()

            if common_function.Utf8Len(text) == 0 then
                --长度为零了
                graphic:DispatchEvent("show_prompt_panel", "input_not_null")
                return
            end

            local left_words = MAX - common_function.Utf8Len(text)
            if left_words <= 0 then
                graphic:DispatchEvent("show_prompt_panel", "input_too_long")
                return
            end

            if string.match(text, "(%s)+") == text then
                graphic:DispatchEvent("show_prompt_panel", "input_not_null")
                return
            end

            self.text_field:setString("")
            graphic:DispatchEvent("hide_world_sub_scene", "bbs_new_discuss_sub_scene")
            chat_logic:NewDiscuss(self.channel_type, text)
        end
    end)

    self.text_field:addEventListener(function(sender, eventType)
        if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
            local left_words = MAX - common_function.Utf8Len(self.text_field:getString())
            if left_words < 0 then left_words = 0 end
            self.left_word_text:setString(tostring(left_words))
        end
    end)
end

function bbs_new_discuss_panel:RegisterEvent()

end

return bbs_new_discuss_panel
