local config_manager = require "logic.config_manager"

local resource_logic = require "logic.resource"
local graphic = require "logic.graphic"
local social_logic = require "logic.social"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local ui_role_prototype = require "entity.ui_role"

local PLIST_TYPE = ccui.TextureResType.plistType
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"

local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -60
local MAX_INVITATION_SUB_PANEL_NUM = 5

--邀请
local invitation_sub_panel = panel_prototype.New()
invitation_sub_panel.__index = invitation_sub_panel

function invitation_sub_panel.New()
    return setmetatable({}, invitation_sub_panel)
end

function invitation_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.root_node:setPositionX(0)

    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)

    self.name_text = self.root_node:getChildByName("name")
    self.login_time_text = self.root_node:getChildByName("login_time")

    self.refuse_btn = self.root_node:getChildByName("refuse_btn")
    self.accept_btn = self.root_node:getChildByName("accept_btn")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(60, 60)

    self.refuse_btn:setTag(index)
    self.accept_btn:setTag(index)
end

function invitation_sub_panel:Show(invitation)
    self.root_node:setVisible(true)
    self.name_text:setString(invitation.name)

    local last_login_time_str = panel_util:GetLastLoginTimeStr(invitation.last_online)
    self.login_time_text:setString(last_login_time_str)

    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], invitation.leader_mercenary, nil, nil, false)

    self.invitation = invitation
end

--搜索好友
local search_player_msgbox = panel_prototype.New()
function search_player_msgbox:Init(root_node)
    self.root_node = root_node
    self.close_btn = root_node:getChildByName("close_btn")
    local input_bg_img = root_node:getChildByName("input_bg")
    input_bg_img:setCascadeOpacityEnabled(false)

    self.user_id_textfield = self.root_node:getChildByName("user_id")
    self.desc_text = self.root_node:getChildByName("desc")

    self.search_result_text = self.root_node:getChildByName("search_status")

    self.friend_info_img = self.root_node:getChildByName("friend_info_bg")
    self.player_name_text = self.friend_info_img:getChildByName("name")
    self.login_time_text = self.friend_info_img:getChildByName("login_time")

    self.cant_invite_btn = self.friend_info_img:getChildByName("cancel_btn")
    self.invite_btn = self.friend_info_img:getChildByName("invite_btn")
    self.search_btn = self.root_node:getChildByName("search_btn")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.friend_info_img)
    self.icon_panel:SetPosition(80, 90)
    self.icon_panel.root_node:setTouchEnabled(true)

    self:RegisterWidgetEvent()
end

function search_player_msgbox:Show()
    self.root_node:setVisible(true)
    self.user_id_textfield:setString("")
    self.search_result_text:setVisible(true)

    if social_logic:GetDailyInvitation() <= 0 then
        self.search_result_text:setString(lang_constants:Get("reach_max_search_num"))
        self.search_result_text:setColor(panel_util:GetColor4B(0xf17843))
    else
        self.search_result_text:setString(lang_constants:Get("cant_search"))
        self.search_result_text:setColor(panel_util:GetColor4B(0x9b8d5b))
    end

    self.friend_info_img:setVisible(false)
    self.desc_text:setVisible(true)
end

function search_player_msgbox:SearchResult(result, player)
    if result == "success" and player then
        self.friend_info_img:setVisible(true)
        self.player_name_text:setString(player.name)

        self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], player.leader_mercenary, nil, nil, true)

        local last_login_time_str = panel_util:GetLastLoginTimeStr(player.last_online)
        self.login_time_text:setString(last_login_time_str)

        self.search_result_text:setVisible(false)
        self.player = player

    else
        self.search_result_text:setVisible(true)
        self.search_result_text:setString(lang_constants:Get("cant_search_player"))
    end
end

function search_player_msgbox:RegisterWidgetEvent()
    self.search_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local search_user = self.user_id_textfield:getString()
            social_logic:SearchFriend(search_user)
        end
    end)

    self.invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            social_logic:Invite(self.player.user_id)
        end
    end)

    self.cant_invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:Show()
        end
    end)
end

--邀请好友
local invite_player_msgbox = panel_prototype.New()
function invite_player_msgbox:Init(root_node)
    self.root_node = root_node
    self.close_btn = root_node:getChildByName("close_btn")

    self.friend_info_img = self.root_node:getChildByName("friend_info_bg")
    self.player_name_text = self.friend_info_img:getChildByName("name")
    self.login_time_text = self.friend_info_img:getChildByName("login_time")

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.friend_info_img)
    self.icon_panel:SetPosition(80, 90)
    self.icon_panel.root_node:setTouchEnabled(true)

    self.cant_invite_btn = self.friend_info_img:getChildByName("cancel_btn")
    self.invite_btn = self.friend_info_img:getChildByName("invite_btn")

    self.cant_invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("hide_world_sub_panel", "social_msgbox")
        end
    end)

    self.invite_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            social_logic:Invite(self.user_id)
        end
    end)
end

function invite_player_msgbox:Show(player)
    self.root_node:setVisible(true)
    self.player_name_text:setString(player.name)

    local last_login_time_str = panel_util:GetLastLoginTimeStr(player.last_online)
    self.login_time_text:setString(last_login_time_str)

    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], player.leader_mercenary, nil, nil, true)

    self.user_id = player.user_id
end

local reuse_scrollview = require "widget.reuse_scrollview"

--处理好友邀请
local deal_invitation_msgbox = panel_prototype.New()
function deal_invitation_msgbox:Init(root_node)
    self.root_node = root_node
    self.close_btn = root_node:getChildByName("close_btn")

    self.accept_invite_chk = self.root_node:getChildByName("select")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.root_node:getChildByName("template")
    self.template:setVisible(false)

    self:RegisterWidgetEvent()

    self.invitation_sub_panels = {}

    local sub_panel = invitation_sub_panel.New()
    sub_panel:Init(self.template:clone(), 1)
    self.invitation_sub_panels[1] = sub_panel
    self.scroll_view:addChild(sub_panel.root_node)

    sub_panel.refuse_btn:addTouchEventListener(self.refuse_method)
    sub_panel.accept_btn:addTouchEventListener(self.accept_method)

    self.sub_panel_num = 1

    self.invitation_list = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.invitation_sub_panels, SUB_PANEL_HEIGHT)

    self.reuse_scrollview:RegisterMethod(
        function(self)
            return social_logic:GetInvitationNum()
        end,

        function(self, sub_panel, is_up)
            local index
            if is_up then
                index = self.data_offset + self.sub_panel_num
            else
                index = self.data_offset + 1
            end

            sub_panel:Show(self.parent_panel.invitation_list[index])
        end
    )
end

function deal_invitation_msgbox:CreateSubPanels()

    local num = math.min(MAX_INVITATION_SUB_PANEL_NUM, social_logic:GetInvitationNum())
    if self.sub_panel_num >= num then
        return
    end
    for i = self.sub_panel_num + 1, num do
        local sub_panel = invitation_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)

        sub_panel.refuse_btn:addTouchEventListener(self.refuse_method)
        sub_panel.accept_btn:addTouchEventListener(self.accept_method)

        self.invitation_sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function deal_invitation_msgbox:Show()
    self.root_node:setVisible(true)
    self.accept_invite_chk:setSelected(social_logic.ban_invite)

    self:CreateSubPanels()

    self:LoadInvitationsInfo()
end

function deal_invitation_msgbox:LoadInvitationsInfo()
    local invitation_num = social_logic:GetInvitationNum()
    local height = math.max(invitation_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = #self.invitation_list, 1, -1 do
        table.remove(self.invitation_list, i)
    end

    local invitations = social_logic:GetInvitationList()
    for k, v in pairs(invitations) do
        table.insert(self.invitation_list, v)
    end

    for i = 1, self.sub_panel_num do
        local sub_panel = self.invitation_sub_panels[i]
        if i <= invitation_num then
            sub_panel:Show(self.invitation_list[i])
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)
end

function deal_invitation_msgbox:RegisterWidgetEvent()
    self.refuse_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()

            local invitation = self.invitation_sub_panels[index].invitation
            social_logic:Refuse(invitation.user_id)
        end
    end

    self.accept_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local invitation = self.invitation_sub_panels[index].invitation
            social_logic:Accept(invitation.user_id)

        end
    end

    self.accept_invite_chk:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            social_logic:SetBan()
        end
    end)
end

local social_msgbox = panel_prototype.New(true)
function social_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/social_msgbox.csb")

    search_player_msgbox:Init(self.root_node:getChildByName("search_msgbox"))
    invite_player_msgbox:Init(self.root_node:getChildByName("invite_player_msgbox"))
    deal_invitation_msgbox:Init(self.root_node:getChildByName("deal_invitation_msgbox"))

    self.social_sub_msgbox = {}
    self.social_sub_msgbox[1] = search_player_msgbox
    self.social_sub_msgbox[2] = invite_player_msgbox
    self.social_sub_msgbox[3] = deal_invitation_msgbox

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function social_msgbox:Show(mode, ...)
    self.root_node:setVisible(true)
    for i = 1, 3 do
        if mode == i then
            self.social_sub_msgbox[i]:Show(...)
        else
            self.social_sub_msgbox[i]:Hide()
        end
    end
end

function social_msgbox:RegisterEvent()
    --接受邀请
    graphic:RegisterEvent("accept_invitation", function()
        local mode = client_constants["SOCIAL_MSGBOX_TYPE"]["deal_invitation_msgbox"]
        if not self.root_node:isVisible() and not self.social_sub_msgbox[mode].root_node:isVisible() then
            return
        end
        self.social_sub_msgbox[mode]:LoadInvitationsInfo()
    end)

    --拒绝邀请
    graphic:RegisterEvent("refuse_invitation", function()
        local mode = client_constants["SOCIAL_MSGBOX_TYPE"]["deal_invitation_msgbox"]
        if not self.root_node:isVisible() and not self.social_sub_msgbox[mode].root_node:isVisible() then
            return
        end
        self.social_sub_msgbox[mode]:LoadInvitationsInfo()
    end)

    --新的好友邀请
    graphic:RegisterEvent("new_invite", function()
        local mode = client_constants["SOCIAL_MSGBOX_TYPE"]["deal_invitation_msgbox"]
        if not self.root_node:isVisible() and not self.social_sub_msgbox[mode].root_node:isVisible() then
            return
        end
        self.social_sub_msgbox[mode]:LoadInvitationsInfo()
    end)

    --搜索结果
    graphic:RegisterEvent("search_player_result", function(result, player)
        local mode = client_constants["SOCIAL_MSGBOX_TYPE"]["search_player_msgbox"]
        if not self.root_node:isVisible() and not self.social_sub_msgbox[mode].root_node:isVisible() then
            return
        end
        self.social_sub_msgbox[mode]:SearchResult(result, player)
    end)

    --邀请好友
    graphic:RegisterEvent("invite_player", function(player)
        if not self.root_node:isVisible() then
            return
        end

        local search_mode = client_constants["SOCIAL_MSGBOX_TYPE"]["search_player_msgbox"]
        if self.social_sub_msgbox[search_mode].root_node:isVisible() then
            self.social_sub_msgbox[search_mode]:Show()
        end

        local invite_mode = client_constants["SOCIAL_MSGBOX_TYPE"]["invite_player_msgbox"]
        if self.social_sub_msgbox[invite_mode].root_node:isVisible() then
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

function social_msgbox:RegisterWidgetEvent()
    for i = 1, 3 do
        self.social_sub_msgbox[i].close_btn:addTouchEventListener(function(sender, event_type)
            if event_type == ccui.TouchEventType.ended then
                self.social_sub_msgbox[i]:Hide()
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
        end)
    end

    local search_index = client_constants["SOCIAL_MSGBOX_TYPE"]["search_player_msgbox"]
    local user_id_textfield = self.social_sub_msgbox[search_index].user_id_textfield

    user_id_textfield:addEventListener(function(sender, event_type)
        if event_type == ccui.TextFiledEventType.attach_with_ime then
            self.social_sub_msgbox[search_index].desc_text:setVisible(false)

        elseif event_type == ccui.TextFiledEventType.detach_with_ime then

        end
    end)
end

return social_msgbox
