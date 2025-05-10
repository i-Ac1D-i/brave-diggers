local audio_manager = require "util.audio_manager"
local panel_prototype = require "ui.panel"

local msgbox = panel_prototype.New()
function msgbox:Init(root_node)
    self.root_node = root_node or cc.CSLoader:createNode("ui/simple_msgbox.csb")

    self.close1_btn = self.root_node:getChildByName("close1_btn")
    self.close2_btn = self.root_node:getChildByName("close2_btn")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")

    self.title_text = self.root_node:getChildByName("title"):getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")

    self.title_text1 = self.root_node:getChildByName("title"):getChildByName("name_2")
    self.desc_text1 = self.root_node:getChildByName("desc_2")

    self.root_node:setVisible(false)

    self:RegisterWidgetEvent()
end

function msgbox:Show(title, desc, confirm_txt, close_txt, callback, close_callback, close_callback2)
    self.title_text:setString(title)
    self.desc_text:setString(desc)
    self.confirm_btn:setTitleText(confirm_txt)

    if close_txt and #close_txt > 0 then
        self.close2_btn:setTitleText(close_txt)
    end

    self.callback = callback

    self.close_callback = close_callback

    if callback_second then
        self.callback_second = callback_second
    else
        self.callback_second = close_callback
    end

    self.root_node:setVisible(true)
    
    if self.title_text1 then
        self.title_text1:setVisible(false)
    end
    if self.desc_text1 then
        self.desc_text1:setVisible(false)
    end
end

function msgbox:RegisterWidgetEvent()

    self.close1_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.root_node:setVisible(false)

            local callback = self.close_callback2
            self.close_callback2 = nil

            if callback then
                callback()
            end
        end
    end)

    self.close2_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.root_node:setVisible(false)

            local callback = self.close_callback
            self.close_callback = nil

            if callback then
                callback()
            end
        end
    end)

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.root_node:setVisible(false)

            local callback = self.callback
            self.callback = nil

            if callback then
                callback()
            end
        end
    end)
end

return msgbox
