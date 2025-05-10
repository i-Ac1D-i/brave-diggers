local network = require "util.network"
local time_logic = require "logic.time"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"

local REWARD_SOURCE = constants.REWARD_SOURCE
local MAIL_PANEL_TYPE = constants.MAIL_PANEL_TYPE

local reward_logic
local resource_logic
local social_logic

local mail = {}

function mail:Init()
    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    social_logic = require "logic.social"

    self.not_read_list = {}

    self.already_read_list = {}

    -- 系统邮件
    self.system_mail_not_read_list = {}
    self.system_mail_already_read_list = {}
    -- 好友邮件
    self.friend_mail_not_read_list = {}
    self.friend_mail_already_read_list = {}

    self:RegisterMsgHandler()
end

function mail:GetSumMailNum(type)
    local not_read_num = 0
    local already_read_num = 0

    local num = 0

    if type == MAIL_PANEL_TYPE["system"] then
        not_read_num = table.maxn(self.system_mail_not_read_list)
        already_read_num = table.maxn(self.system_mail_already_read_list)

    elseif type == MAIL_PANEL_TYPE["friend"] then
        not_read_num = table.maxn(self.friend_mail_not_read_list)
        already_read_num = table.maxn(self.friend_mail_already_read_list)
    end

    num = not_read_num + already_read_num

    return num
end

function mail:GetNotReadMailNum(type)
    local num = 0

    if type == MAIL_PANEL_TYPE["system"] then
        num = table.maxn(self.system_mail_not_read_list)

    elseif type == MAIL_PANEL_TYPE["friend"] then
        num = table.maxn(self.friend_mail_not_read_list)
    end

    return num
end

function mail:GetNotReadMailList()
    return self.not_read_list
end

function mail:GetAlreadyMailList()
    return self.already_read_list
end

function mail:GetMailList(type)
    if type == "system_not_read" then
        return self.system_mail_not_read_list

    elseif type == "system_already_read" then
        return self.system_mail_already_read_list

    elseif type == "friend_not_read" then
        return self.friend_mail_not_read_list

    elseif type == "friend_already_read" then
        return self.friend_mail_already_read_list
    end
end

function mail:GetMail(index)
    return self.not_read_list[index]
end

function mail:SortMailByCreateTime(list)
    table.sort(list, function(a, b)
        return a.create_time > b.create_time
    end)
end

function mail:HasNewMail()

    if #self.not_read_list > 0  then
        return true
    else
        return false
    end
end

function mail:GetCountDown(mail)
    local cur_time = time_logic:Now()
    local durantion = cur_time - mail.create_time
    return math.ceil(7 - durantion / (86400))
end

function mail:OpenMail(mail)
    local id = mail.id

    if mail.mark_read then
        return
    end

    network:Send({open_mail = { id = id }})
end

--读取邮件成功
function mail:ReadMailSuccess(id)

    local cur_mail, index
    local mail_index = nil
    for i, mail in ipairs(self.not_read_list) do
        if id == mail.id then
            mail.mark_read = true
            cur_mail = mail
            index = i
        end
    end

    if cur_mail then 
        table.insert(self.already_read_list, cur_mail)
        table.remove(self.not_read_list, index)
        mail_index = self:GetIndexByNotReadMail(cur_mail)

    elseif not cur_mail then
    end

    if mail_index and cur_mail.detail_id == constants["RESOURCE_TYPE"]["friendship_pt"] then
        table.insert(self.friend_mail_already_read_list, cur_mail)
        table.remove(self.friend_mail_not_read_list, mail_index)
        return cur_mail

    elseif mail_index and cur_mail.detail_id ~= constants["RESOURCE_TYPE"]["friendship_pt"] then
        table.insert(self.system_mail_already_read_list, cur_mail)
        table.remove(self.system_mail_not_read_list, mail_index)
        return cur_mail
    end
end

function mail:GetIndexByNotReadMail(search_mail)
    
    local mail_list = {}
    local index
    if search_mail.detail_id == constants["RESOURCE_TYPE"]["friendship_pt"] then
        mail_list = self.friend_mail_not_read_list
    else
        mail_list = self.system_mail_not_read_list
    end

    for i, mail in ipairs(mail_list) do
        if search_mail.id == mail.id then
            index = i
            return index
        end
    end

    return nil    
end

function mail:GetMailById(id)
    for i, mail in ipairs(self.not_read_list) do
        if id == mail.id then
            return mail, i
        end
    end

    return
end

function mail:RegisterMsgHandler()

    network:RegisterEvent("query_mail_info_ret", function(recv_msg)
        print("query_mail_info_ret")

        if not recv_msg.mail_list then
            return
        end

        for i, mail in ipairs(recv_msg.mail_list) do
            --简单的过滤掉非有效邮件
            local valid = false
            if mail.mail_type == constants.MAIL_TYPE["item"] then
                if config_manager.item_config[mail.detail_id] then
                    valid = true
                end

            elseif mail.mail_type == constants.MAIL_TYPE["resource"] then
                if config_manager.resource_config[mail.detail_id] then
                    valid = true
                end
            else
                valid = true
            end

            ---只保存未读取的邮件
            if valid then
                if not mail.mark_read then
                    table.insert(self.not_read_list, mail)
                    self:AddNewMailToList(mail)
                end
            end
        end

        self:SortMailByCreateTime(self.not_read_list)
    end)

    network:RegisterEvent("new_mail_info_ret", function(recv_msg)
        --recv_msg 就是一封邮件
        table.insert(self.not_read_list, recv_msg)
        self:AddNewMailToList(recv_msg)

        social_logic:OnRecvMail(recv_msg)

        graphic:DispatchEvent("new_mail")
    end)

    network:RegisterEvent("open_mail_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local mail = self:ReadMailSuccess(recv_msg.id)

            graphic:DispatchEvent("open_mail", mail)

            if mail and mail.mail_type == constants.MAIL_TYPE["reward_group"] then
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            end

        elseif recv_msg.result == "bag_full" then
            graphic:DispatchEvent("show_prompt_panel", "bag_full")

        elseif recv_msg.result == "full_friendship_pt" then
            graphic:DispatchEvent("show_prompt_panel", "full_friendship")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "read_mail_failure")
        end
    end)
end


function mail:AddNewMailToList(mail)
    --添加未读邮件    
    if mail.detail_id == constants["REWARD_SOURCE"]["recruit_friendship"] then
        table.insert(self.friend_mail_not_read_list, mail)
    else 
        table.insert(self.system_mail_not_read_list, mail)
    end
end

return mail
