local config_manager = require "logic.config_manager"

local resource_logic = require "logic.resource"
local graphic = require "logic.graphic"
local user_logic = require "logic.user"
local social_logic = require "logic.social"
local carnival_logic = require "logic.carnival"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"

local SOCIAL_MSGBOX_TYPE = client_constants.SOCIAL_MSGBOX_TYPE
local icon_template = require "ui.icon_panel"
local reuse_scrollview = require "widget.reuse_scrollview"

local SUB_PANEL_HEIGHT = 124
local FIRST_SUB_PANEL_OFFSET = -80
local MAX_SUB_PANEL_NUM = 7

local PLIST_TYPE = ccui.TextureResType.plistType

--兑换奖励的详细信息panel
local friend_sub_panel = panel_prototype.New()
friend_sub_panel.__index = friend_sub_panel

function friend_sub_panel.New()
    return setmetatable({}, friend_sub_panel)
end

function friend_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(false)
    self.root_node:setCascadeOpacityEnabled(false)

    self.name_text = self.root_node:getChildByName("name")
    self.login_time_text = self.root_node:getChildByName("login_time")

    self.add_friendship_pt_btn = self.root_node:getChildByName("add_friendship_pt_btn")
    self.add_friendship_pt_btn:setCascadeColorEnabled(true)
    self.double_img_icon = self.add_friendship_pt_btn:getChildByName("double")

    self.icon_img = self.add_friendship_pt_btn:getChildByName("icon")
    self.icon_img:ignoreContentAdaptWithSize(true)

    self.fight_btn = self.root_node:getChildByName("fight_btn")
    self.fight_btn:setVisible(true)

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(self.root_node, true)
    self.icon_panel:SetPosition(60, 60)
    self.icon_panel.root_node:setTouchEnabled(true)

    self.icon_panel.root_node:setTag(index)
    self.add_friendship_pt_btn:setTag(index)
    self.fight_btn:setTag(index)
end

function friend_sub_panel:Show(friend, send_gift)
    self.root_node:setVisible(true)

    if not friend then
        return
    end

    self.name_text:setString(friend.name)

    if friend.send_gift_time == 0 then 
        self.login_time_text:setString(lang_constants:Get("social_has_not_sent_gift"))
    else
        
        local day = math.ceil((time_logic:Now()+time_logic.time_zone_offset)/86400) - math.ceil((friend.send_gift_time+time_logic.time_zone_offset)/86400)
        if day == 0 then
            self.login_time_text:setString(lang_constants:Get("social_has_sent_gift1"))
        else
            self.login_time_text:setString(string.format(lang_constants:Get("social_has_sent_gift2"), day))
        end
    end

    self.icon_panel:Show(constants.REWARD_TYPE["mercenary"], friend.leader_mercenary, nil, nil, false)

    if send_gift then
        self.add_friendship_pt_btn:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.add_friendship_pt_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
    end

    self.can_double = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["friendship"])

    if self.is_delete then
        self.double_img_icon:setVisible(false)
    else
        self.double_img_icon:setVisible(self.can_double)
    end

    self.send_gift_flag = send_gift

    self.friend = friend
end

--转换状态 送礼--删除
function friend_sub_panel:Switch(is_delete)

    local img = ""
    if is_delete then
        img = "button/buttonbg_6.png"

        self.icon_img:loadTexture("button/decide_no.png", PLIST_TYPE)
        self.double_img_icon:setVisible(false)

    else
        img = "button/buttonbg_5.png"
        self.icon_img:loadTexture("icon/resource/friend.png", PLIST_TYPE)

        self.double_img_icon:setVisible(self.can_double)
    end

    self.add_friendship_pt_btn:loadTextures(img, img, img, PLIST_TYPE)

    self.is_delete = is_delete
    self:SetFriendShipBtnColor(is_delete)
end

--送礼按钮颜色
function friend_sub_panel:SetFriendShipBtnColor(is_delete)
    if is_delete then
        self.add_friendship_pt_btn:setColor(panel_util:GetColor4B(0xffffff))
    else
        if self.friend then
            if self.send_gift_flag then
                self.add_friendship_pt_btn:setColor(panel_util:GetColor4B(0xffffff))
            else
                self.add_friendship_pt_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            end
        end
    end
end

local social_main_panel = panel_prototype.New(true)
function social_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/social_main_panel.csb")
    self.title_text = self.root_node:getChildByName("title_text")
    --btn
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.delete_friend_btn = self.root_node:getChildByName("delete_btn")
    self.delete_desc_text = self.delete_friend_btn:getChildByName("desc")

    self.search_player_btn = self.root_node:getChildByName("search_btn")
    self.invitation_btn = self.root_node:getChildByName("invitation_btn")
    self.invitation_num_bg_img = self.invitation_btn:getChildByName("num_bg")
    self.invitation_num_text = self.invitation_btn:getChildByName("num")
    --reward
    self.reward_node = self.root_node:getChildByName("reward")
    self.reward_icon_img = self.reward_node:getChildByName("reward_icon")
    self.reward_value_text = self.reward_node:getChildByName("reward_value")
    self.reward_node:setVisible(false)

    --我的id
    local mine_id_bg_img = self.root_node:getChildByName("id_bg")
    mine_id_bg_img:setCascadeOpacityEnabled(false)
    self.mine_id_text = mine_id_bg_img:getChildByName("id")

    --友情点数
    local mine_friendship_pt_bg_img = self.root_node:getChildByName("friendship_pt_bg")
    mine_friendship_pt_bg_img:setCascadeOpacityEnabled(false)
    self.friendship_pt_text = mine_friendship_pt_bg_img:getChildByName("value")

    self.frendship_left_pt_text = mine_friendship_pt_bg_img:getChildByName("value2")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.root_node:getChildByName("template")
    self.template:setVisible(false)

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self.friend_sub_panels = {}

    local sub_panel = friend_sub_panel.New()
    sub_panel:Init(self.template:clone(), 1)
    self.friend_sub_panels[1] = sub_panel
    sub_panel.add_friendship_pt_btn:addTouchEventListener(self.add_friendship_pt_method)
    sub_panel.fight_btn:addTouchEventListener(self.challenge_friend_method)

    self.scroll_view:addChild(sub_panel.root_node)
    self.sub_panel_num = 1

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.friend_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return social_logic:GetFriendNum()
        end,

        function(self, sub_panel, is_up)
            local index
            if is_up then
                index = self.data_offset + self.sub_panel_num
            else
                index = self.data_offset + 1
            end

            local parent_panel = self.parent_panel
            local user_id, unsend = parent_panel:GetUserStatus(index)

            sub_panel:Show(social_logic:GetFriendInfo(user_id), unsend)
            sub_panel:SetFriendShipBtnColor(parent_panel.delete_mode)
        end
    )

    self.reward_spine_node = spine_manager:GetNode("maze_txt")
    self.reward_spine_node:setVisible(false)

    self.root_node:addChild(self.reward_spine_node, 300)
    self.reward_spine_tracker = spine_node_tracker.New(self.reward_spine_node, "txt")

    self.delete_mode = false
end

function social_main_panel:GetUserStatus(index)
    local user_id, unsend

    if index <= #self.unsend_gift_list then
        user_id = self.unsend_gift_list[index]
        unsend = true
    else
        user_id = self.send_gift_list[index - #self.unsend_gift_list]
        unsend = false
    end

    return user_id, unsend
end

function social_main_panel:CreateSubPanels()

    local num = math.min(MAX_SUB_PANEL_NUM, social_logic:GetFriendNum())
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = friend_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)
        self.friend_sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)

        sub_panel.add_friendship_pt_btn:addTouchEventListener(self.add_friendship_pt_method)
        sub_panel.fight_btn:addTouchEventListener(self.challenge_friend_method)
    end

    self.sub_panel_num = num
end

function social_main_panel:Show()

    self.mine_id_text:setString(user_logic:GetUserId())

    self.send_gift_list = social_logic:GetSendGiftList()
    self.unsend_gift_list = social_logic:GetUnsendGiftList()

    local cur_friend_num = social_logic:GetFriendNum()

    self:CreateSubPanels()

    local height = math.max(cur_friend_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.friend_sub_panels[i]

        local user_id, unsend = self:GetUserStatus(i)

        if user_id then
            local friend = social_logic:GetFriendInfo(user_id)
            sub_panel:Show(friend, unsend)
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(height, 0)

    self:UpdateInvitationNum()

    self.friendship_pt_text:setString(resource_logic:GetResourceNum(constants.RESOURCE_TYPE["friendship_pt"]))
    self:UpdateFriendship()

    self.max_friend_num = social_logic:GetMaxFriendNum()
    self.title_text:setString(string.format(lang_constants:Get("friend_title"), cur_friend_num, self.max_friend_num))

    self.delete_mode = false
    self:SwitchDeleteMode()

    self.root_node:setVisible(true)
end

function social_main_panel:Update(elspsed_time)

    self.reward_spine_tracker:Update()
end

function social_main_panel:UpdateReward(reward)

    self.reward_icon_img:loadTexture(icon, PLIST_TYPE)
    self.reward_value_text:setString(tostring(reward))

    self.reward_spine_node:setVisible(true)
    self.reward_spine_tracker:Bind("txt", "txt_alpha", 255, 1000, self.reward_node)
    self:UpdateFriendship()
end

function social_main_panel:UpdateFriendship()
    local left_point = social_logic:GetMaxFriendPoint() - social_logic:GetFriendshipPoint()
    self.frendship_left_pt_text:setString(string.format(lang_constants:Get("daily_left_gift") ,left_point))
end

function social_main_panel:UpdateInvitationNum()
    local cur_invitation_num = social_logic:GetInvitationNum()
    if cur_invitation_num == 0 then
        self.invitation_num_bg_img:setVisible(false)
        self.invitation_num_text:setVisible(false)
    else
        self.invitation_num_bg_img:setVisible(true)
        self.invitation_num_text:setVisible(true)
        self.invitation_num_text:setString(cur_invitation_num)
    end
end

function social_main_panel:SwitchDeleteMode()
    for i = 1, self.sub_panel_num do
        local sub_panel = self.friend_sub_panels[i]
        sub_panel:Switch(self.delete_mode)
    end

    if self.delete_mode then
        self.delete_desc_text:setString(lang_constants:Get("exit_delete"))
    else
        self.delete_desc_text:setString(lang_constants:Get("delete"))
    end
end

function social_main_panel:RegisterEvent()

    graphic:RegisterEvent("new_friend", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("accept_invitation", function()
        if not self.root_node:isVisible() then
            return
        end

        self:Show()
    end)

    graphic:RegisterEvent("refuse_invitation", function()
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateInvitationNum()
    end)

    graphic:RegisterEvent("new_invite", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateInvitationNum()

    end)

    graphic:RegisterEvent("remove_friend", function(active_delete)
        if not self.root_node:isVisible() then
            return
        end

        self:Show()

        if active_delete then
            self.delete_mode = not self.delete_mode
            self:SwitchDeleteMode()
        end
    end)

    graphic:RegisterEvent("send_friend_gift", function(user_id, friend_pt)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, self.sub_panel_num do
            --从界面映射回数据层索引
            local user_id_index = self.reuse_scrollview:GetDataIndex(i)
            local user_id, unsend = self:GetUserStatus(user_id_index)

            if user_id then
                local friend = social_logic:GetFriendInfo(user_id)
                self.friend_sub_panels[i]:Show(friend, unsend)
            else
                self.friend_sub_panels[i]:Hide()
            end

            self:UpdateReward(friend_pt)
        end

        self.friendship_pt_text:setString(resource_logic:GetResourceNum(constants.RESOURCE_TYPE["friendship_pt"]))
    end)
end

function social_main_panel:RegisterWidgetEvent()
    self.add_friendship_pt_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local friend = self.friend_sub_panels[index].friend
            if not self.delete_mode then
                social_logic:SendGift(friend.user_id)
            else
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("confirm_delete_friend_title"),
                            lang_constants:Get("confirm_delete_friend_desc"),
                            lang_constants:Get("common_confirm"),
                            lang_constants:Get("common_cancel"),
                function()
                     social_logic:Remove(friend.user_id)
                end)
            end
        end
    end

    self.challenge_friend_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()

            local friend = self.friend_sub_panels[index].friend
            social_logic:QueryTroopInfo(friend.user_id)
            local SOCIAL_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]["friend"]
            graphic:DispatchEvent("show_world_sub_panel", "social_event_panel", friend.user_id, SOCIAL_SHOW_TYPE)
        end
    end

    self.back_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    self.search_player_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "social_msgbox", SOCIAL_MSGBOX_TYPE["search_player_msgbox"])
        end
    end)

    self.invitation_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "social_msgbox", SOCIAL_MSGBOX_TYPE["deal_invitation_msgbox"])
        end
    end)

    self.delete_friend_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.delete_mode = not self.delete_mode
            self:SwitchDeleteMode()
        end
    end)
end

return social_main_panel
