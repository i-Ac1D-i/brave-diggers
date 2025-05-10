local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"

-- 评论类型
local COMMENT_TYPE = constants["COMMENT_TYPE"]

local chat_logic = require "logic.chat"
local common_function = require "util.common_function"

-- 回复
local bbs_reply_panel = panel_prototype.New(true)
function bbs_reply_panel:Init()
    --TAG:MASTER_MERGE
    self.max_words = client_constants["BBS_MAX_WORD_NUM"]
    
    -- 父窗口
    self.comment_type = 1

    self.root_node = cc.CSLoader:createNode("ui/discuss_reply_panel.csb")
    self.reply_cancel_btn = self.root_node:getChildByName("reply_cancel_btn")
    self.add_reply_btn = self.root_node:getChildByName("add_reply_btn")
    self.reply_detail_img = self.root_node:getChildByName("reply_detail")
    self.text_field = self.reply_detail_img:getChildByName("textfield")
    self.left_word_text = self.reply_detail_img:getChildByName("surplus_word")
    self.left_word_text:setString(self.max_words)

    self:RegisterWidgetEvent()
end

function bbs_reply_panel:Show(one, comment_type)
    if not comment_type then
        comment_type = COMMENT_TYPE["bbs"]
    end

    -- 更新显示可以输入的字数
    if self.comment_type ~= comment_type then
        self.comment_type = comment_type

        -- type  1: 佣兵评论, 2:关卡评论, 3: 留言板讨论回复
        if self.comment_type == COMMENT_TYPE["mercenary"] or self.comment_type == COMMENT_TYPE["maze"] then
            self.max_words = 60
        else
            self.max_words = 90
        end
    end

    local left_words = self.max_words - common_function.Utf8Len(self.text_field:getString())
    self.left_word_text:setString(left_words)

    if one then
        self.one = one
        self.root_node:setVisible(true)
    end
end

function bbs_reply_panel:RegisterWidgetEvent()
    -- 取消回复按钮
    self.reply_cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", "bbs_reply_panel")

            if self.comment_type == COMMENT_TYPE["mercenary"] or self.comment_type == COMMENT_TYPE["maze"] then
                graphic:DispatchEvent("show_world_sub_panel", "comment_panel", self.comment_type, self.one.ID)
            end
        end
    end)

    -- 回复按钮
    self.add_reply_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.one then
                local text = self.text_field:getString()
                local left_words = self.max_words - common_function.Utf8Len(text)
                if left_words < 0 then
                    graphic:DispatchEvent("show_prompt_panel", "input_too_long")
                    return
                end

                if string.match(text, "(%s)+") == text then
                    graphic:DispatchEvent("show_prompt_panel", "input_not_null")
                    return
                end

                if string.len(text) == 0 then
                    graphic:DispatchEvent("show_prompt_panel", "input_not_null")
                    return
                end

                if self.comment_type == COMMENT_TYPE["mercenary"] or self.comment_type == COMMENT_TYPE["maze"] then
                    chat_logic:NewComment(self.comment_type, self.one.ID, text)
                else
                    chat_logic:NewReply(self.one, text)
                end

                self.text_field:setString("")
                graphic:DispatchEvent("hide_world_sub_panel", "bbs_reply_panel")

                if self.comment_type == COMMENT_TYPE["mercenary"] or self.comment_type == COMMENT_TYPE["maze"] then
                    graphic:DispatchEvent("show_world_sub_panel", "comment_panel", self.comment_type, self.one.ID)
                end
            end
        end
    end)

    self.text_field:addEventListener(function(sender, eventType)
        if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
            local left_words = self.max_words - common_function.Utf8Len(self.text_field:getString())
            if left_words < 0 then left_words = 0 end
            self.left_word_text:setString(tostring(left_words))
        end
    end)
end

return bbs_reply_panel
