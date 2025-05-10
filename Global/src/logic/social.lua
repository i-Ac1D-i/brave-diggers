local network = require "util.network"
local time_logic = require "logic.time"
local user_logic
local resource_logic
local achievement_logic

local skill_manager = require "logic.skill_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local REWARD_SOURCE = constants.REWARD_SOURCE

local config_manager = require "logic.config_manager"

local graphic = require "logic.graphic"

local social = {}
function social:Init()
    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    user_logic = require "logic.user"
    achievement_logic = require "logic.achievement"

    self.friend_list = {}
    self.friend_num = 0

    self.invitation_list = {}
    self.invitation_num = 0

    self.friend_troop_info = {}

    self.ban_invite = false
    self.max_friend_num = constants.MAX_FRIEND_NUM
    self.max_daily_friendship_pt = 0
    self.daily_friendship_pt = 0

    --已经送礼的好友
    self.send_gift_list = {}
    --还未送礼的好友
    self.unsend_gift_list = {}

    self.daily_max_invitation = 0

    self.cooperative_skill_list = {}
    self.all_mercenary_template_ids = {}
    self.stack_list = {}

    self:RegisterMsgHandler()
end

function social:DailyClear()
    self.daily_max_invitation = constants["MAX_INVITATION"]

    --重置
    for i = #self.send_gift_list, 1, -1 do
        table.remove(self.send_gift_list, i)
    end

    for i = #self.unsend_gift_list, 1, -1 do
        table.remove(self.unsend_gift_list, i)
    end

    for user_id, friend in pairs(self.friend_list) do
        table.insert(self.unsend_gift_list, user_id)
    end

end

function social:GetFriendList()
    return self.friend_list
end

--获得已经送礼的好友
function social:GetSendGiftList()
    return self.send_gift_list
end

--获得未送礼的好友
function social:GetUnsendGiftList()
    return self.unsend_gift_list
end

function social:GetFriendInfo(user_id)
    return self.friend_list[user_id]
end

--获取邀请列表
function social:GetInvitationList()
    return self.invitation_list
end

function social:GetFriendNum()
    return self.friend_num
end

-- 每日最大领取友情点数
function social:GetMaxFriendPoint()
    return self.max_daily_friendship_pt
end

-- 每日已领取友情点数
function social:GetFriendshipPoint()
    return self.daily_friendship_pt
end

function social:SetFriendshipPoint(point)
    if point > 0 then
        self.daily_friendship_pt = math.min(self.daily_friendship_pt + point, self.max_daily_friendship_pt)
    end
end

function social:GetMaxFriendNum()
    return self.max_friend_num
end

function social:GetInvitationNum()
    return self.invitation_num
end

function social:GetFriendTroopInfo(user_id)
    return self.friend_troop_info[user_id]
end

function social:GetRivalInfo()
    return self.rival_info
end

--是否有新的邀请
function social:HasNewInvitation()
    return self.invitation_num > 0
end

--邀请
function social:Invite(user_id)

    --不能邀请自己
    if user_id == user_logic:GetUserId() then
        graphic:DispatchEvent("show_prompt_panel", "cant_invite_yourself")
        return
    end

    --已经有这个好友
    if self.friend_list[user_id] then
        graphic:DispatchEvent("show_prompt_panel", "this_friend_is_in_your_list")
        return
    end

    --每日申请上限
    if self.daily_max_invitation <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "reach_max_search_num")
        return
    end

    --好友数量上限
    if self.friend_num == self.max_friend_num then
        graphic:DispatchEvent("show_prompt_panel", "friend_list_is_full")
        return
    end

    network:Send({invite_friend = {user_id = user_id} })
end

function social:Accept(user_id)

    if user_id == user_logic:GetUserId() then
        return
    end

    --已经有这个好友了
    if self.friend_list[user_id] then
        return
    end

    --好友数量上限
    if self.friend_num == self.max_friend_num then
        graphic:DispatchEvent("show_prompt_panel", "friend_list_is_full")
        return
    end

    network:Send({ accept_invitation = {user_id = user_id} })
end

function social:GetDailyInvitation()
    return self.daily_max_invitation
end

function social:Refuse(user_id)
    --不在邀请队列中
    if not self.invitation_list[user_id] then
        return
    end

    network:Send({ refuse_invitation = {user_id = user_id} })
end

function social:Remove(user_id)

    --没有此好友
    if not self.friend_list[user_id] then
        return
    end

    network:Send({ remove_friend = {user_id = user_id} })
end

--不再接收邀请
function social:SetBan()
    network:Send({ set_ban_invite = {} })
end

--检测user_id 是否在list表中
function social:CheckUserId(list, user_id)
    for i, id in ipairs(list) do
        if user_id == id then
            return true, i
        end
    end
    return false, 0
end

function social:HasFriend(user_id)
    return self.friend_list[user_id]
end

function social:SendGift(user_id)

    if not self.friend_list[user_id] then
        return
    end

    local send_flag = self:CheckUserId(self.send_gift_list, user_id)
    if send_flag then
        graphic:DispatchEvent("show_prompt_panel", "already_send_gift")
        return
    end

    network:Send({ send_gift = {user_id = user_id} })
end

function social:SearchFriend(user_id)
    if not user_id then
        return
    end

    if user_id == user_logic:GetUserId() then
        return
    end

    --有这个好友
    if self.friend_list[user_id] then
        return
    end

    --该好友已经在邀请队列中
    if self.invitation_list[user_id] then
        return
    end

    network:Send({ search_friend = {user_id = user_id} })
end

function social:ChallengeFriend(user_id)
    if user_id == user_logic:GetUserId() then
        return
    end

    if user_id == "" or not user_id then
        return
    end

    network:Send({ challenge_friend = { user_id = user_id }})
end

function social:QueryTroopInfo(user_id)
    if self.friend_troop_info[user_id] then
        return
    end

    network:Send({ query_friend_troop = {user_id = user_id} })
end

function social:OnRecvMail(mail)

    for user_id, friend in pairs(self.friend_list) do
        if mail.writer_name == friend.name then
            friend.send_gift_time = math.ceil(time_logic:Now())
            break
        end
    end
end

function social:GenerateTroopInfo(troop_info)
    for k, v in pairs(self.cooperative_skill_list) do
        self.cooperative_skill_list[k] = nil
    end

    for id, _ in pairs(self.all_mercenary_template_ids) do
        self.all_mercenary_template_ids[id] = 0
    end

    for id, _ in pairs(self.stack_list) do
        self.stack_list[id] = 0
    end

    local cooperative_skill_list = self.cooperative_skill_list
    local all_mercenary_template_ids = self.all_mercenary_template_ids
    troop_info.all_mercenary_template_ids = self.all_mercenary_template_ids
    troop_info.stack_list = self.stack_list
    troop_info.special_skill_list = {}

    troop_info.extra_speed, troop_info.extra_dodge, troop_info.extra_authority, troop_info.extra_defense = 0, 0, 0, 0

    troop_info.special_skill_index = 0
    skill_manager:AddPassiveSkill(troop_info, troop_info.leader_skill_id)

    for i = 1, #troop_info.template_id_list do
        local template_id = troop_info.template_id_list[i]
        local template_info = config_manager.mercenary_config[template_id]

        all_mercenary_template_ids[template_id] = all_mercenary_template_ids[template_id] and all_mercenary_template_ids[template_id] + 1 or 1

        for i = 1, 3 do
            local skill_id = template_info["skill"..i]
            if skill_id ~= 0 then
                troop_info.special_skill_index = 0
                skill_manager:AddPassiveSkill(troop_info, skill_id)
            end
        end

        for i = 1, 2 do
            local ex_skill = template_info["ex_skill" .. i]
            if ex_skill ~= 0 then
                cooperative_skill_list[ex_skill] = true
            end
        end
    end

    --检测合体技能
    for skill_id, _ in pairs(self.cooperative_skill_list) do
        local can_use = skill_manager:CheckCoopSkillCanUse(troop_info, skill_id)
        local coop_skill = config_manager.cooperative_skill_config[skill_id]

        if can_use and coop_skill then
            --只用检测被动技能
            for i = 1, 3 do
                local skill_id = coop_skill["real_skill" .. i]
                if skill_id ~= 0 then
                    troop_info.special_skill_index = 0
                    skill_manager:AddPassiveSkill(troop_info, skill_id)
                end
            end
        end
    end

    if troop_info.special_skill_list then
        for i, skill_id in ipairs(troop_info.special_skill_list) do
            troop_info.special_skill_index = i
            skill_manager:AddPassiveSkill(troop_info, skill_id, true)
        end

        troop_info.dodge = troop_info.dodge + troop_info.extra_dodge
        troop_info.authority = troop_info.authority + troop_info.extra_authority
        troop_info.defense = troop_info.defense + troop_info.extra_defense
        troop_info.speed = troop_info.speed + troop_info.extra_speed
    end

end

function social:RegisterMsgHandler()

    network:RegisterEvent("query_social_info_ret", function(recv_msg)
        if recv_msg.friends then
            self.friend_num = 0
            for i, friend in ipairs(recv_msg.friends) do
                self.friend_list[friend.user_id] = friend
                self.friend_num = self.friend_num + 1

                local is_send = false

                if recv_msg.daily_friend_gift then
                    is_send = self:CheckUserId(recv_msg.daily_friend_gift, friend.user_id)
                end

                if is_send then
                    table.insert(self.send_gift_list, friend.user_id)
                else
                    table.insert(self.unsend_gift_list, friend.user_id)
                end

                if recv_msg.send_gift_times then
                    friend.send_gift_time = recv_msg.send_gift_times[i]
                end
            end
        end

        if recv_msg.invitations then
            self.invitation_num = 0
            for i, invitation in ipairs(recv_msg.invitations) do
                self.invitation_list[invitation.user_id] = invitation
                self.invitation_num = self.invitation_num + 1
            end
        end

        self.ban_invite = recv_msg.ban

        self.daily_friendship_pt = recv_msg.daily_friendship_pt
        self.max_daily_friendship_pt = recv_msg.max_daily_friendship_pt
        self.daily_max_invitation = recv_msg.daily_max_invitation
    end)

    network:RegisterEvent("invite_friend_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.daily_max_invitation = self.daily_max_invitation - 1

            graphic:DispatchEvent("show_prompt_panel", "invite_friend")
            graphic:DispatchEvent("invite_player", recv_msg.user_id)

        elseif recv_msg.result == "not_find" then
            graphic:DispatchEvent("show_prompt_panel", "not_find_friend")

        elseif recv_msg.result == "failure" then

        elseif recv_msg.result == "ban" then
            graphic:DispatchEvent("show_prompt_panel", "dest_friend_ban_invite")

        elseif recv_msg.result == "full_friends" then
            graphic:DispatchEvent("show_prompt_panel", "friend_list_is_full")

        elseif recv_msg.result == "dest_full_friends" then
            graphic:DispatchEvent("show_prompt_panel", "dest_friend_list_is_full")

        elseif recv_msg.result == "already_invite" then
            graphic:DispatchEvent("show_prompt_panel", "already_invite")
        end
    end)

    network:RegisterEvent("accept_invitation_ret", function(recv_msg)
        if recv_msg.result == "success" then

            local invitation = self.invitation_list[recv_msg.user_id]
            if invitation and not self.friend_list[recv_msg.user_id] then
                self.invitation_list[recv_msg.user_id] = nil
                self.invitation_num = self.invitation_num - 1

                invitation.send_gift_time = 0
                self.friend_list[recv_msg.user_id] = invitation

                self.friend_num = self.friend_num + 1
                table.insert(self.unsend_gift_list, recv_msg.user_id)

                graphic:DispatchEvent("show_prompt_panel", "accept_friend", invitation.name)

                graphic:DispatchEvent("accept_invitation")
            end

        elseif recv_msg.result == "not_find" then
            graphic:DispatchEvent("show_prompt_panel", "not_find_friend")

        elseif recv_msg.result == "full_friends" then
            graphic:DispatchEvent("show_prompt_panel", "friend_list_is_full")

        elseif recv_msg.result == "dest_full_friends" then
            graphic:DispatchEvent("show_prompt_panel", "dest_friend_list_is_full")
        end
    end)

    network:RegisterEvent("refuse_invitation_ret", function(recv_msg)
        if recv_msg.result == "success" then

            if self.invitation_list[recv_msg.user_id] then

                self.invitation_list[recv_msg.user_id] = nil
                self.invitation_num = self.invitation_num - 1

                graphic:DispatchEvent("refuse_invitation")
            end

        elseif recv_msg.result == "failure" then

        end
    end)

    network:RegisterEvent("new_friend_ret", function(recv_msg)
        print("new_friend_ret")
        if recv_msg then
            if not self.friend_list[recv_msg.user_id] then
                recv_msg.send_gift_time = 0
                self.friend_list[recv_msg.user_id] = recv_msg

                self.friend_num = self.friend_num + 1

                table.insert(self.unsend_gift_list, recv_msg.user_id)
                graphic:DispatchEvent("new_friend")
            end

            --同意接受对方为好友 所以要把该好友从申请好友列表里删除掉
            if self.invitation_list[recv_msg.user_id] then
                self.invitation_list[recv_msg.user_id] = nil
                self.invitation_num = self.invitation_num - 1

                graphic:DispatchEvent("refuse_invitation")
            end
        end
    end)

    network:RegisterEvent("new_invite_ret", function(recv_msg)
        if recv_msg then
            if not self.invitation_list[recv_msg.user_id] then
                self.invitation_list[recv_msg.user_id] = recv_msg
                self.invitation_num = self.invitation_num + 1
                graphic:DispatchEvent("new_invite")
            end
        end
    end)

    network:RegisterEvent("remove_friend_ret", function(recv_msg)

        if recv_msg.result == "success" or recv_msg.result == "be_removed" then
            if self.friend_list[recv_msg.user_id] then

                self.friend_list[recv_msg.user_id] = nil
                self.friend_num = self.friend_num - 1

                local send_flag, index = self:CheckUserId(self.unsend_gift_list, recv_msg.user_id)
                if send_flag then
                    table.remove(self.unsend_gift_list, index)
                end

                send_flag, index = self:CheckUserId(self.send_gift_list, recv_msg.user_id)
                if send_flag then
                    table.remove(self.send_gift_list, index)
                end

                if recv_msg.result == "success" then
                    graphic:DispatchEvent("show_prompt_panel", "delete_friend")
                    graphic:DispatchEvent("remove_friend", true)
                else
                    graphic:DispatchEvent("remove_friend", false)

                end
            end
        end
    end)

    --未测
    network:RegisterEvent("set_ban_invite_ret", function(recv_msg)
        self.ban_invite = recv_msg.ban
    end)

    network:RegisterEvent("send_gift_ret", function(recv_msg)
        if recv_msg.result == "success" then

            table.insert(self.send_gift_list, recv_msg.user_id)

            local send_flag, index = self:CheckUserId(self.unsend_gift_list, recv_msg.user_id)
            if send_flag then
                table.remove(self.unsend_gift_list, index)
            end

            --统计羁绊点数也就是送礼次数
            achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["send_gift"], 1)

            graphic:DispatchEvent("show_prompt_panel", "already_send_gift")
            graphic:DispatchEvent("send_friend_gift", recv_msg.user_id, recv_msg.friendship_pt or constants["SEND_GITF_PT"])

        elseif recv_msg.result == "full_friendship" then
            graphic:DispatchEvent("show_prompt_panel", "full_friendship")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "send_gift_failure")
        end

    end)

    network:RegisterEvent("search_friend_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("search_player_result", recv_msg.result, recv_msg.friend_info)
        else
            graphic:DispatchEvent("search_player_result", recv_msg.result)
        end
    end)

    network:RegisterEvent("query_friend_troop_ret", function(recv_msg)
        if not recv_msg.user_id or recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "social_cant_view_troop")
            return
        end

        local troop_info = {}
        for k, v in pairs(recv_msg) do
            troop_info[k] = v
        end
        self.friend_troop_info[recv_msg.user_id] = troop_info

        troop_info.name = self.friend_list[recv_msg.user_id].name

        self:GenerateTroopInfo(troop_info)

        local SOCIAL_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]["FRIEND"]
        graphic:DispatchEvent("show_world_sub_panel", "social_event_panel", recv_msg.user_id, SOCIAL_SHOW_TYPE)
    end)

    network:RegisterEvent("challenge_friend_ret", function(recv_msg)
        if not recv_msg.user_id or recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "social_cant_view_troop")
            return
        end

        local rival_info = self.rival_info or {}

        rival_info.leader_name = recv_msg.leader_name
        rival_info.template_id_list = recv_msg.template_id_list

        self.rival_info = rival_info

        graphic:DispatchEvent("show_battle_room", client_constants.BATTLE_TYPE["vs_friend"], recv_msg.user_id, recv_msg.battle_property, recv_msg.battle_record, recv_msg.is_winner, function()
        end)
    end)
end

return social
