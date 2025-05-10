local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local icon_panel = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"
local social_logic = require "logic.social"
local escort_logic = require "logic.escort"

local platform_manager = require "logic.platform_manager"
local channel_info = platform_manager:GetChannelInfo()

local PLIST_TYPE = ccui.TextureResType.plistType

local escort_rob_target_panel = panel_prototype.New(true)
function escort_rob_target_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/tramcar_friend_msgbox.csb")

    local rob_target_node = self.root_node:getChildByName("template")

    self.name_text = rob_target_node:getChildByName("name")
    self.battle_point_text = rob_target_node:getChildByName("bp_value")

    self.add_friend_btn = self.root_node:getChildByName("confirm_btn")
    self.rob_btn = self.root_node:getChildByName("canel_btn")
    local offset_x = channel_info.escort_rob_target_panel_rob_btn_desc_offset_x
    if offset_x then
        local rob_btn_desc = self.rob_btn:getTitleRenderer()
        rob_btn_desc:setAnchorPoint(cc.p(0,0.5))
        rob_btn_desc:setPositionX(offset_x)
    end

    local template_node = self.root_node:getChildByName("template")
    self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(template_node)
    self.icon_panel:SetPosition(60, 60)

    self:RegisterEvent()
    self:RegisterWidgetEvent()

end

function escort_rob_target_panel:Show(rob_target_info)
    self.rob_target_info = rob_target_info

    self:ShowInfo()
    self:ShowRobBtn()
    self:ShowFriendBtn()
    self.root_node:setVisible(true)
end

function escort_rob_target_panel:ShowInfo()
    if self.rob_target_info then
        self.name_text:setString(self.rob_target_info.leader_name)
        self.battle_point_text:setString(tostring(self.rob_target_info.battle_point))

        self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], self.rob_target_info.template_id, nil, nil, false)
    end
end

function escort_rob_target_panel:ShowRobBtn()
    if escort_logic:GetRemainRobTimes() <= 0 then
        self.rob_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
    else
        self.rob_btn:setColor(panel_util:GetColor4B(0xffffff))
    end
end

function escort_rob_target_panel:ShowFriendBtn()
    local could_add_friend = false
    if self.rob_target_info and self.rob_target_info.is_robot == 0 then
        could_add_friend = not social_logic:HasFriend(self.rob_target_info.user_id)
    end

    if could_add_friend then
        self.add_friend_btn:setColor(panel_util:GetColor4B(0xffffff))
        self.add_friend_btn:setTouchEnabled(true)
    else
        self.add_friend_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.add_friend_btn:setTouchEnabled(false)
    end
end

function escort_rob_target_panel:RegisterEvent()
    graphic:RegisterEvent("update_rob_target_list", function(refresh_type)
        if not self.root_node:isVisible() then
            return
        end

        self:ShowInfo()
        self:ShowFriendBtn()
    end)

    --加好友
    graphic:RegisterEvent("invite_player", function(player)
        if not self.root_node:isVisible() then
            return
        end

        self:ShowFriendBtn()
    end)

end

function escort_rob_target_panel:RegisterWidgetEvent()
   
    self.add_friend_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local could_add_friend = false
            if self.rob_target_info and self.rob_target_info.is_robot == 0 then
                could_add_friend = not social_logic:HasFriend(self.rob_target_info.user_id)
            end

            if could_add_friend then
                social_logic:Invite(self.rob_target_info.user_id)
            end
        end
    end)

    self.rob_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local escort_info = escort_logic:GetEscortInfo()
            if self.rob_target_info then
                if escort_logic:GetRemainRobTimes() <= 0 then
                    graphic:DispatchEvent("show_prompt_panel", "no_rob_times")
                else
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                    escort_logic:RobTarget(self.rob_target_info.user_id)
                end
            end
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return escort_rob_target_panel

