local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local platform_manager = require "logic.platform_manager"
local share_logic = require "logic.share"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local SHARE_TYPE = {
    wechat_circle = 1,
    wechat_friend = 2,
    qq = 3,
    qq_zone = 4,
    weibo = 5,
}

local share_add_panel = panel_prototype.New(true)
function share_add_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/share_add_panel.csb")
    self.close_bg = self.root_node:getChildByName("shedows")
    self.close_bg:setOpacity(0)  --透明度设置为o

    self.platform_share_btn_node = self.root_node:getChildByName("Node_22")
    self.platform_share_btn_node_end_pos_y = self.platform_share_btn_node:getPositionY()
    self.platform_share_btn_node:setVisible(false)

    self.cancel_share = self.platform_share_btn_node:getChildByName("Image_469_0")
    self.cancel_share:setTouchEnabled(true)

    local share_btn_bg = self.platform_share_btn_node:getChildByName("Image_469")
    share_btn_bg:setTouchEnabled(true)

    self.wechat_friend = self.platform_share_btn_node:getChildByName("Button_51")
    self.wechat = self.platform_share_btn_node:getChildByName("Button_51_0")
    self.qq = self.platform_share_btn_node:getChildByName("Button_51_0_0")
    self.qqzone = self.platform_share_btn_node:getChildByName("Button_51_0_0_0")
    self.weibo = self.platform_share_btn_node:getChildByName("Button_51_0_0_0_0")
    self.share_btn_state = false

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function share_add_panel:Show()
    self.root_node:setVisible(true)
    self:showShareBtn(true)
end

function share_add_panel:Hide()
    self.share_btn_state = false
    self.root_node:setVisible(false)
end

--显示隐藏按钮
function share_add_panel:showShareBtn(state)
    if state ~= self.share_btn_state and state then
        self.share_btn_state = state
        self.can_close = false
        self.platform_share_btn_node:setVisible(true)
        self.platform_share_btn_node:setPositionY(self.platform_share_btn_node_end_pos_y - 250)
        local move_action = cc.MoveTo:create(0.35,cc.p(self.platform_share_btn_node:getPositionX(), self.platform_share_btn_node_end_pos_y))
        local sequence = cc.Sequence:create(move_action, cc.CallFunc:create(function ()
            self.can_close = true
        end))
        self.platform_share_btn_node:runAction(sequence)
    elseif state ~= self.share_btn_state and not state then
        self.share_btn_state = state
        local move_action = cc.MoveTo:create(0.35,cc.p(self.platform_share_btn_node:getPositionX(), self.platform_share_btn_node_end_pos_y - 250))
        local sequence = cc.Sequence:create(move_action, cc.CallFunc:create(function ()
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end))
        self.platform_share_btn_node:runAction(sequence)
    end
end

function share_add_panel:RegisterWidgetEvent()

    --朋友圈分享
    self.wechat_friend:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.share_platform_type = SHARE_TYPE.wechat_circle
            share_logic:startShare(platform_manager:GetSharePlatformType("wechat_circle"))
        end
    end)
    --微信分享
    self.wechat:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.share_platform_type = SHARE_TYPE.wechat_friend
            share_logic:startShare(platform_manager:GetSharePlatformType("wechat_friend"))
        end
    end)
    --qq分享
    self.qq:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.share_platform_type = SHARE_TYPE.qq
            share_logic:startShare(platform_manager:GetSharePlatformType("qq"))
        end
    end)
    --qqzone分享
    self.qqzone:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.share_platform_type = SHARE_TYPE.qq_zone
            share_logic:startShare(platform_manager:GetSharePlatformType("qq_zone"))
        end
    end)

    --微博分享
    self.weibo:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.share_platform_type = SHARE_TYPE.weibo
            share_logic:startShare(platform_manager:GetSharePlatformType("weibo"))
        end
    end)

    --取消分享
    self.cancel_share:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.can_close then
                self:showShareBtn(false)
            end
        end
    end)

    self.close_bg:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.can_close then
                self:showShareBtn(false)
            end
        end
    end)
end

function share_add_panel:RegisterEvent()
    --分享回来
    graphic:RegisterEvent("share_callback", function (state_code)
        if state_code == 0 then
            --分享成功返回0.5延迟显示
            local delay = cc.DelayTime:create(0.1)
            local sequence = cc.Sequence:create(delay, cc.CallFunc:create(function ()
                graphic:DispatchEvent("show_prompt_panel", "share_success")
                self:showShareBtn(false)
            end))
            self.root_node:runAction(sequence)
            
        end
        
    end)
end


return share_add_panel
