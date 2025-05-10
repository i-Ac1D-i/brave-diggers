local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local graphic = require "logic.graphic"
local audio_manager = require "util.audio_manager"
local user_logic = require "logic.user"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"
local http_client = require "logic.http_client"
local json = require "util.json"
local share_logic = require "logic.share"
local constants = require "util.constants"
local resource_logic = require "logic.resource"
local lang_constants = require "util.language_constants"

local client_constants = require "util.client_constants"
local PLIST_TYPE = ccui.TextureResType.plistType
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local share_panel = panel_prototype.New(true)

function share_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/share_panel.csb")

    self.close_btn = self.root_node:getChildByName("back_btn")

    self.share_btn = self.root_node:getChildByName("take_btn_0")

    --当前积分
    self.now_score_text = self.root_node:getChildByName("max-number_0_0")

    --领取按钮
    self.reward_btn = self.root_node:getChildByName("back_btn_0_0")
    self.use_score_btn = self.root_node:getChildByName("go_to_area4")

    --可领取进度

    self.reward_score_text = self.root_node:getChildByName("max-number_0")

    --分享次数
    self.share_count_text = self.root_node:getChildByName("present_number")

    self.share_max_count_text = self.root_node:getChildByName("max-number")

    --点击次数
    self.click_count_text = self.root_node:getChildByName("present_number1")

    self.click_max_count_text = self.root_node:getChildByName("max-number1")

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function share_panel:Show()
    self:ShowShareInfo()
    self.share_btn_state = false
    share_logic:QueryShareInfo()
    self.root_node:setVisible(true)

    self.share_max_count_text:setString("/"..constants["SHARE_TIMES"])
    self.click_max_count_text:setString("/"..constants["SHAR_MAX_CLICK"])
end

function share_panel:ShowShareInfo()
    --可以领取的积分
    self.reward_score_text:setString(share_logic:GetShareScore())

    --自己的积分
    local share_integral = resource_logic:GetResourceNum(RESOURCE_TYPE["share_integral"])
    self.now_score_text:setString(share_integral)

    self.share_count_text:setString(share_logic.share_times)

    self.click_count_text:setString(share_logic:GetClickCount())

end

function share_panel:RegisterWidgetEvent()
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    self.reward_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            share_logic:GetLeadingIntegral()
        end
    end)


    --分享按钮
    self.share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "share_add_panel")
        end
    end)

    --时装按钮
    self.use_score_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_prompt_panel", "no_use")
        end
    end)
end

function share_panel:RegisterEvent()
    --积分刷新
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(RESOURCE_TYPE["guild_boss_ticket"]) then
            self:ShowShareInfo()
        end
    end)

    --状态改变
    graphic:RegisterEvent("update_share_info_state", function()
        if not self.root_node:isVisible() then
            return
        end

        self:ShowShareInfo()
    end)

end

return share_panel
