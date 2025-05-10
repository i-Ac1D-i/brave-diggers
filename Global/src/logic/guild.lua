local config_manager = require "logic.config_manager"
local configuration = require "util.configuration"
local network = require "util.network"
local json = require "util.json"

local graphic = require "logic.graphic"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local common_function = require "util.common_function"

local guild = {}

-- 初始化
function guild:Init(user_id)
    self.user_id = user_id

    self.already_request_guild = false

    self:Clear()
    self:GetGuildSetting()

    self:RegisterMsgHandler()
end

-- 查询公会所有信息
function guild:QueryAllGuildInfo()
    network:Send({ query_guild_member = {} })
end

function guild:Clear()
    self.guild_id = nil
    self.guild_name = nil
    self.member_list = nil
    self.notice_list = nil
    self.notice_unread_num = 0
    self.member_unread_num = 0

    local chat_logic = require "logic.chat"
    chat_logic.already_request_bbs_guild = false
    chat_logic.new_mine_guild = 0

    --graphic:DispatchEvent("refresh_notice_tips")
    --graphic:DispatchEvent("refresh_member_tips")
end

function guild:InitOwnMemberInfo()
    local count = 0
    self.member_list = self.member_list or {}
    self.read_member_time = self.read_member_time or 0
    for k,v in pairs(self.member_list) do
        if v.user_id == self.user_id then
            self.own_member_info = v
        end

        if v.grade_type == constants.GUILD_GRADE.chairman then
            self.chairman_info = v
            graphic:DispatchEvent("refresh_guild_chairman")
        end

        if v.join_guild_time and v.join_guild_time > self.read_member_time then
            count = count + 1
        end
    end
    local function SortMember(a,b)
        return a.last_login_time > b.last_login_time
    end
    table.sort(self.member_list, SortMember)
    self.member_unread_num = count
end

function guild:InitNoticeList()
    local count = 0
    self.notice_list = self.notice_list or {}
    self.read_notice_time = self.read_notice_time or 0
    for k,v in pairs(self.notice_list) do
        if v.create_time > self.read_notice_time then
            count = count + 1
        end
    end
    self.notice_unread_num = count
end

-- 查询公会信息
function guild:Query()
    if not self.already_request_guild  then
        self:QueryAllGuildInfo()
    end

    graphic:DispatchEvent("show_world_sub_scene", "guild_sub_scene")
end

function guild:FilterName(guild_name)
    local leader_name_table = common_function.Utf8to32(guild_name)
    local len = 0
    for i = 1, #leader_name_table-1 do

        local val = leader_name_table[i]

        if val == 0x20 or val == 0x25 or val == 0x26 or val == 0x7C then
            --检测空格
            graphic:DispatchEvent("show_prompt_panel", "guild_name_special_char")
            return false
        end

        if val <= 255 then
            len = len + 1
        else
            len = len + 2
        end
    end

    if len > constants["LEADER_NAME_LENGTH"] then
        graphic:DispatchEvent("show_prompt_panel", "guild_name_too_long", constants["LEADER_NAME_LENGTH"])
        return false
    end
    return true
end

-- 创建公会
-- @guild_name 公会名称
-- @bp_limit_idx 战力门槛idx
function guild:CreateGuild(guild_name, bp_limit_idx)
    if string.len(guild_name) == 0 then
        graphic:DispatchEvent("show_prompt_panel", "guild_name_not_none")
        return false
    end

    if not self:FilterName(guild_name) then
        return false
    end

    network:Send({create_guild = {guild_name = guild_name, bp_limit_idx = bp_limit_idx}})
end

-- 查找公会ID
function guild:SearchGuild(guild_id)
    if string.len(guild_id) == 0 then
        graphic:DispatchEvent("show_prompt_panel", "guild_id_not_none")
        return false
    end

    network:Send({search_guild = {guild_id = guild_id}})
end

-- 加入公会
function guild:JoinGuild(guild_id)
    if self:IsGuildMember() then
        graphic:DispatchEvent("show_prompt_panel", "guild_repeat_member")
    else
        network:Send({join_guild = {guild_id = guild_id}})
    end
end

-- 解散公会
function guild:DismissGuild()
    if not self:IsGuildChairman() then
        graphic:DispatchEvent("show_prompt_panel", "executor_not_chairman")
        return
    end
    -- print("解散公会")
    network:Send({dismiss_guild = {}})
end

-- 退出公会
function guild:ExitGuild()
    -- print("退出公会")
    network:Send({exit_guild = {}})
end

-- 开除公会
function guild:FireGuild(target_user_id)
    -- print("开除公会")
    network:Send({fire_guild = {user_id = target_user_id}})
end

-- 转让公会
function guild:TransferGuild(target_user_id)
    if not self:IsGuildChairman() then
        graphic:DispatchEvent("show_prompt_panel", "executor_not_chairman")
        return
    end
    -- print("转让公会")
    network:Send({transfer_guild = {user_id = target_user_id}})
end

function guild:SetSetting(bp_limit_idx)
    if not self:IsGuildChairman() then
        graphic:DispatchEvent("show_prompt_panel", "executor_not_chairman")
        return
    end
    self.bp_limit_idx = bp_limit_idx
    network:Send({set_guild_setting = {bp_limit_idx = bp_limit_idx}})
end

-- 是否是公会会员
function guild:IsGuildMember()
    if self.guild_id then
        return true
    end
    return false
end

-- 获取公会当前会员数量
function guild:GetCurMemberNum()
    if self.member_list then
        return #self.member_list
    end

    return 0
end

-- 获取公会最大会员数量
function guild:GetMaxMemberNum()
    return constants.GUILD_MAX_MEMBER
end

-- 自己是否是公会会长
function guild:IsGuildChairman()
    if not self.chairman_info then
        return false
    end

    if self.chairman_info.user_id == self.user_id then
        return true
    end

    return false
end

-- 获取通知数量
function guild:GetNoticeNum()
    if self.notice_list then
        return #self.notice_list
    end

    return 0
end

-- 获取通知列表
function guild:GetNoticeList()
    return self.notice_list or {}
end

-- 获取公会头像
function guild:GetTemplateId()
    if not self.chairman_info then
        return 0
    end

    return self.chairman_info.template_id
end

-- 获取通知数量
function guild:GetNoticeUnReadNum()
    if not self.notice_list then
        return 0
    end
    return self.notice_unread_num or 0
end

-- 获取会员数量
function guild:GetMemberUnReadNum()
    if not self.member_list then
        return 0
    end

    return self.member_unread_num or 0
end

-- 获取设置信息（是否提示公会通知，查看成员时间，查看通知时间）
function guild:GetGuildSetting()

    local guild_info_list = configuration:GetGuildInfoList()

    local guild_info = guild_info_list[self.user_id] or {}

    if type(guild_info.read_notice_time) == "number" then
        self.read_notice_time = guild_info.read_notice_time
    else
        self.read_notice_time = 0
    end

    if type(guild_info.read_member_time) == "number" then
        self.read_member_time = guild_info.read_member_time
    else
        self.read_member_time = 0
    end

    if guild_info.is_notice_notify == true then
        self.is_notice_notify = true
    else
        self.is_notice_notify = false
    end

end

-- 保存设置信息（查看成员列表时间,查看通知时间,是否开启通知提醒）
function guild:SaveGuildSetting()

    local guild_info_list = configuration:GetGuildInfoList()
    local guild_info = {}
    guild_info.read_notice_time =  self.read_notice_time
    guild_info.read_member_time = self.read_member_time
    guild_info.is_notice_notify = self.is_notice_notify
    guild_info_list[self.user_id] = guild_info

    configuration:Save()
end

-- 查看公会通知
function guild:ReadNoticeList()
    if self:IsGuildMember() then
        graphic:DispatchEvent("show_world_sub_panel", "guild_notice_panel")

        self.read_notice_time = time_logic:Now()
        self.notice_unread_num = 0

        graphic:DispatchEvent("refresh_notice_tips")

        self:SaveGuildSetting()
    else
        graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
    end
end

-- 查看公会会员
function guild:ReadMemberList()
    self.read_member_time = time_logic:Now()
    self.member_unread_num = 0

    graphic:DispatchEvent("show_world_sub_panel", "guild_member_panel")
    graphic:DispatchEvent("refresh_member_tips")

    self:SaveGuildSetting()
end

function guild:SetBan()
    self.is_notice_notify = not self.is_notice_notify
    network:Send({ guild_notice_tips = {} })

    self:SaveGuildSetting()
end

-- 注册服务端回调
function guild:RegisterMsgHandler()
    network:RegisterEvent("query_guild_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local guild_info = recv_msg.guild_info
            for k,v in pairs(guild_info) do
                self[k] = v
            end
        end
    end)


    --会员列表
    network:RegisterEvent("query_guild_member_ret",function (recv_msg)
        self.member_list = {}
        if recv_msg.member_list then
            self.member_list = recv_msg.member_list
            self:InitOwnMemberInfo()
        end

        network:Send({ query_guild_notice = {} })
    end)

    --通知列表
    network:RegisterEvent("query_guild_notice_ret",function (recv_msg)
        self.notice_list = {}
        if recv_msg.notice_list then
            self.notice_list = recv_msg.notice_list
            self:InitNoticeList()
        end

        self.already_request_guild = true
    end)

    --创建公会反馈
    network:RegisterEvent("create_guild_ret", function (recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("hide_world_sub_panel", "guild_create_msgbox")

            local guild_info = recv_msg.guild_info
            for k, v in pairs(guild_info) do
                self[k] = v
            end

            self.read_notice_time = time_logic:Now()
            self.read_member_time = time_logic:Now()
            self.is_notice_notify = false
            -- self.is_notice_notify = recv_msg.is_notice_notify

            self:SaveGuildSetting()
            self:QueryAllGuildInfo()
            graphic:DispatchEvent("join_guild", true)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    -- 搜索公会反馈
    network:RegisterEvent("search_guild_ret", function (recv_msg)
        graphic:DispatchEvent("search_guild_result", recv_msg)
    end)

    -- 加入公会反馈
    network:RegisterEvent("join_guild_ret", function (recv_msg)
        if recv_msg.result == "success" then
            local guild_info = recv_msg.guild_info
            for k,v in pairs(guild_info) do
                self[k] = v
            end
            self.read_notice_time = time_logic:Now()
            self.read_member_time = time_logic:Now()
            self.is_notice_notify = false

            self:SaveGuildSetting()
            self:QueryAllGuildInfo()

            graphic:DispatchEvent("hide_world_sub_panel", "guild_search_panel")
            graphic:DispatchEvent("join_guild", false)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    -- 退出公会处理
    local exit_guild_callback = function (recv_msg)
        if recv_msg.result == "success" then
            self:Clear()
            graphic:DispatchEvent("hide_world_sub_panel", "guild_member_panel")
            graphic:DispatchEvent("exit_guild")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end

    --退出公会反馈
    network:RegisterEvent("exit_guild_ret", exit_guild_callback)
    --解散公会反馈
    network:RegisterEvent("dismiss_guild_ret", exit_guild_callback)

    --更新会员状态
    local update_member_callback = function (recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end
    network:RegisterEvent("fire_guild_ret", update_member_callback)
    network:RegisterEvent("transfer_guild_ret", update_member_callback)

    -- 更新会员数据
    network:RegisterEvent("update_member_ret", function (recv_msg)
        local new_member_list = {}
        self.member_list = self.member_list or {}

        for k, v in pairs(self.member_list) do
            -- 删除会员操作
            local is_delete = false
            if recv_msg.del_member_list then
                for idx, user_id in pairs(recv_msg.del_member_list) do

                    if user_id == self.user_id then
                        self:Clear()
                        graphic:DispatchEvent("hide_world_sub_panel", "guild_member_panel")
                        graphic:DispatchEvent("exit_guild")
                    end

                    if v.user_id == user_id then
                        is_delete = true
                        table.remove(recv_msg.del_member_list, idx)
                        break
                    end
                end
            end

            --更新会员操作
            if recv_msg.update_member_list then
                for idx,member_info in pairs(recv_msg.update_member_list) do
                    if v.user_id == member_info.user_id then
                        v = member_info
                        table.remove(recv_msg.update_member_list, idx)
                        break
                    end
                end
            end

            if not is_delete then
                table.insert(new_member_list, v)
            end
        end

        self.member_unread_num = self.member_unread_num or 0
        if recv_msg.add_member_list then
            --添加会员
            for _, new_member in pairs(recv_msg.add_member_list) do
                table.insert(new_member_list, new_member)
                self.member_unread_num = self.member_unread_num + 1
            end
        end

        self.member_list = new_member_list
        --刷新公会成员界面
        self:InitOwnMemberInfo()
        graphic:DispatchEvent("update_guild_member")
    end)

    --更新通知
    network:RegisterEvent("update_notice_new", function(recv_msg)
        local list = recv_msg.add_notice_list
        self.notice_list = self.notice_list or {}
        self.notice_unread_num = self.notice_unread_num or 0
        for k, v in pairs(list) do
            --如果收到了解散公会的通知，就清空本地数据
            if v.notice_type == constants.GUILD_NOTICE.notice_dismiss then
                self:Clear()
                graphic:DispatchEvent("exit_guild")

            else
                table.insert(self.notice_list, v)
                self.notice_unread_num = self.notice_unread_num + 1
            end
        end

        graphic:DispatchEvent("refresh_notice_tips")
    end)

    -- 消息
    network:RegisterEvent("guild_result",function (recv_msg)
        if recv_msg.result ~= "success" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)
end

return guild
