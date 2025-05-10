local audio_manager = require "util.audio_manager"
local panel_prototype = require "ui.panel"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local agreement_panel = panel_prototype.New()

function agreement_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/agreement_panel.csb")

    self.accept_btn = self.root_node:getChildByName("accept_btn")
    self.refuse_btn = self.root_node:getChildByName("refuse_btn")

    self.scrollview = self.root_node:getChildByName("scrollview")
    self.back_top_btn = self.scrollview:getChildByName("back_top_btn")
    
    --追加滾動內容
    self.agreement_text = self.scrollview:getChildByName("title_desc")
    local append = platform_manager:GetChannelInfo().agreement_scrollview_append_content
    if append then
        local origin_size = self.scrollview:getInnerContainerSize()
        origin_size.height = origin_size.height + append 
        self.scrollview:setInnerContainerSize(origin_size)
        local x,y = self.agreement_text:getPosition()
        self.agreement_text:setPosition(cc.p(x, y + append))

        local size = self.agreement_text:getContentSize()
        size.height =  size.height + append 
        self.agreement_text:setContentSize(size)
    end
  
    self:RegisterWidgetEvent()
end

function agreement_panel:Show(callback)
    self.root_node:setVisible(true)
    self.agreement_text:setString(lang_constants:GetAgreementStr())
    self.callback = callback
end

function agreement_panel:RegisterWidgetEvent()
    
    self.accept_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.root_node:setVisible(false)
            self.callback()
        end
    end)

    self.refuse_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.root_node:setVisible(false)
            cc.Director:getInstance():endToLua()
        end
    end)

    self.back_top_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.scrollview:jumpToTop()
        end
    end)

    self.scrollview:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            local y = self.scrollview:getInnerContainer():getPositionY()
            --self.back_top_btn:setVisible(y > self.container_pos_y)
        end
    end)
end

return agreement_panel
