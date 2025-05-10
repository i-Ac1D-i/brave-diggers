local network = require "util.network"
local time_logic = require "logic.time"
local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local graphic = require "logic.graphic"
local json = require "util.json"
local daily_logic

local bit_extension = require "util.bit_extension"

local quest = {}
function quest:Init()

    daily_logic = require "logic.daily"

    self.time_info = time_logic:GetDateInfo(time_logic:Now())
    self.mail_list = {}
    self.quest_random_mail_time = nil
    self.has_unread_mail = false
    self.loop_time = 0

    self.mail_data = config_manager.quest_mail_config
    self.random_mail_data = config_manager.quest_random_mail_config

    self:RegisterEvent()
end

function quest:HasUnreadMail()
    return self.has_unread_mail
end

function quest:Update(elapsed_time)
    self.loop_time = self.loop_time + elapsed_time

    if self.loop_time >= 1 then
        local t_now = time_logic:Now()

        -- 当日登录如果没有随机邮件
        if not daily_logic:GetDailyTag(constants.DAILY_TAG["quest_random_mail"]) then
            self:SetRandomMailTime(math.random(300, 900) + t_now)
        end

        -- 增加随机邮件
        if self:GetRandomMailTime() and self:GetRandomMailTime() <= t_now then
            self:GetNewQuestMail()
        end

        self.loop_time = 0
    end
end

function quest:InitMailList(const_mail_list, random_mail_list)
    local data, un_read_list, list = nil, {}, {}

    local merge_data = function (origin_data, config_data, is_random_mail)
        for i, v in pairs(origin_data) do
            data = config_data[v.id]
            if data then
                data.id = v.id
                data.time = v.time
                data.is_read = v.is_read
                data.is_random_mail = is_random_mail
                if not is_random_mail then data.level = 0 end
                table.insert(list, data)
            end
        end
    end

    if #const_mail_list > 0 then
        merge_data(const_mail_list, self.mail_data, false)
    end

    if #random_mail_list > 0 then
        merge_data(random_mail_list, self.random_mail_data, true)
    end

    table.sort(list, function (a, b)
        return b.time < a.time
    end)

    local tmp_list = {}
    for k, v in pairs(list) do
        if not v.is_read then
            table.insert(un_read_list, v)
        else
            table.insert(tmp_list, v)
        end
    end

    local un_read_count = #un_read_list
    local count = 0

    for i=#tmp_list, 1, -1 do
        count = count + 1
        if count <= 50-un_read_count then
            table.insert(self.mail_list, tmp_list[i])
        end
    end

    count = #self.mail_list
    for k, v in pairs(un_read_list) do
        count = count + 1
        table.insert(self.mail_list, count, v)
    end

    if #un_read_list > 0 then self.has_unread_mail = true end
end

function quest:GetMailList()
    return self.mail_list
end

function quest:GetRandomMailTime()
    return self.quest_random_mail_time
end

function quest:SetRandomMailTime(time)
    if not time then
        return
    end

    self.quest_random_mail_time = time
    daily_logic:SetDailyTag(constants.DAILY_TAG["quest_random_mail"], true)
end

function quest:GetNewQuestMail()
    self.quest_random_mail_time = nil
    network:Send({ get_new_quest_mail = {} })
end

function quest:ReadMail(idx, mail_one)
    if mail_one.is_read then
        return
    end

    network:Send({ read_quest_mail = {mail_level = mail_one.level,  mail_id = mail_one.id} })

    mail_one.is_read = true
    table.remove(self.mail_list, idx)

    local update_idx = 1
    local count, un_read_count = self.mail_list, 0
    for k, v in pairs(self.mail_list) do
        if v.is_read and mail_one.time >= v.time then
            update_idx = k+1
        end

        if not v.is_read then
            un_read_count = un_read_count + 1
        end
    end

    table.insert(self.mail_list, update_idx, mail_one)

    if un_read_count == 0 then
        self.has_unread_mail = false
        graphic:DispatchEvent("update_mailbox_animate", "normal")
    end
end

function quest:RegisterEvent()
    network:RegisterEvent("query_quest_mail_list_ret", function(recv_msg)
        print("query_quest_mail_list_ret")

        if not recv_msg then
            return
        end

        local random_mail_list, const_mail_list = {}, {}
        if recv_msg.const_mail_list then
            const_mail_list = recv_msg.const_mail_list
        end

        if recv_msg.random_mail_list then
            random_mail_list = recv_msg.random_mail_list
        end

        self:InitMailList(const_mail_list, random_mail_list)
    end)

    network:RegisterEvent("get_new_quest_mail_ret", function(recv_msg)
        print("get_new_quest_mail_ret")
        if not recv_msg then
            return
        end

        if recv_msg.mail_id then
            local data = nil

            if recv_msg.random_mail then
                data = self.random_mail_data[recv_msg.mail_id]
            else
                data = self.mail_data[recv_msg.mail_id]
                data.level = 0
            end

            if not data then
                return
            end

            data.id = recv_msg.mail_id
            data.time = os.time()
            data.is_read = false
            data.is_random_mail = recv_msg.random_mail
            table.insert(self.mail_list, #self.mail_list+1, data)

            self.has_unread_mail = true
            graphic:DispatchEvent("update_mailbox_animate", "newtip")
            graphic:DispatchEvent("update_quest_panel")
        end
    end)

    network:RegisterEvent("read_quest_mail_ret", function(recv_msg)
        if not recv_msg  then
            return
        end
    end)
end

return quest

