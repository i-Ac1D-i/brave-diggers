local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local lang_constants = require "util.language_constants"

local web_panel = panel_prototype.New(true)

function web_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/notice_panel2.csb")
    self.close_btn = self.root_node:getChildByName("close_btn")
    self.web_title = self.root_node:getChildByName("title")
    self.web_title_text = self.web_title:getChildByName("name")

    self.web_node = nil
    self.web_url = ""

    self:RegisterWidgetEvent()
end

function web_panel:GetUrl()
    return self.web_url
end

function web_panel:Show(url, title_name)

    if self.web_node then
        if self.web_url == url then
            self.web_node:setVisible(true)
        else
            self.root_node:removeChild(self.web_node, true)
            self.web_node = nil
            self:Show(url, title_name)
        end
    else
        self.web_node = PlatformSDK.createWebView(url)

        if self.web_node then
            self.web_node:setContentSize(513, 584)
            self.web_node:setPosition(64, 893)
            self.web_node:ignoreAnchorPointForPosition(false)
            self.web_node:setAnchorPoint(0, 1)
            self.root_node:addChild(self.web_node)
        end

        self.web_url = url
        self.web_title_text:setString(lang_constants:Get(title_name))
    end
    
    self.root_node:setVisible(true)


     if _G["AUTH_MODE"] == true then  --FYD
            if self.web_node then        
                self.web_node:setVisible(false)
            end
            graphic:DispatchEvent("hide_world_sub_panel", "web_panel")
    end
end

function web_panel:RegisterWidgetEvent()
    
    --关闭按钮
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.web_node then
                self.web_node:setVisible(false)
            end

            graphic:DispatchEvent("hide_world_sub_panel", "web_panel")
        end
    end)
end

return web_panel
