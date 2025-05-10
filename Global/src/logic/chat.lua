local graphic = require "logic.graphic"
local json = require "util.json"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local configuration = require "util.configuration"
local network = require "util.network"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local key_words =require "logic.key_words"
local guild_logic

local http_client

local vip_logic
local adventure_logic

local BBS = 1
local COMMENT = 2

-- query bbs 数量限制
local DISCUSS_LIMIT = 49
local REPLY_LIMIT = 59

local chat = {}

function chat:Init(user_id)
    self.user_id = user_id
    self.token = nil

    http_client = require "logic.http_client"
    guild_logic = require "logic.guild"

    vip_logic = require "logic.vip"
    adventure_logic = require "logic.adventure"

    local login_logic = require "logic.login"
    self.social_server = {}
    self.social_server["bbs"] = string.format("http://%s/bbs", login_logic.bbs_server)
    self.social_server["comment"] = string.format("http://%s/comment", login_logic.comment_server)

    self.already_request_bbs_common = false
    self.bbs_channel_common = {}

    self.already_request_bbs_guild = false
    self.bbs_channel_guild = {}

    self.bbs_channel_mine = {}
    self.new_mine_num = 0
    self.new_mine_guild = 0

    self.comment_num_cache = {}

    self.comment_info_cache = {}

    self:RegisterMsgHandler()
end

function chat:IsAuthorized()
    if _G["AUTH_MODE"] then
        return true
    end

    if platform_manager:GetChannelInfo().disable_bbs_limit then
        return true
    end

    if vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
        return true
    end

    --14-1解锁发帖功能
    local MAZE_ID = 100106
    if adventure_logic:IsMazeClear(MAZE_ID) then
        return true
    end

    graphic:DispatchEvent("show_prompt_panel", "feature_unlock", config_manager.adventure_maze_config[MAZE_ID]["name"])
    return false
end

local function SortDiscuss(a,b)
    local old = tonumber(tostring(a.user_type)..tostring(a.update_time))
    local new = tonumber(tostring(b.user_type)..tostring(b.update_time))
    return old > new
end

function chat:BuildMineChannelList()
    local list = {}
    local new_mine_num = 0
    local new_mine_guild = 0
    local last_flash_time = configuration:GetFlushBBSTime() or 0

    for k,v in pairs(self.bbs_channel_common) do
        if v.uid == self.user_id then
            table.insert(list,v)
            if tonumber(v.update_time) > last_flash_time then
                new_mine_num = new_mine_num + 1
            end
        end
    end

    for k,v in pairs(self.bbs_channel_guild) do
        if v.uid == self.user_id then
            table.insert(list,v)
            if tonumber(v.update_time) > last_flash_time then
                 new_mine_num = new_mine_num + 1
                new_mine_guild = new_mine_guild + 1
            end
        end

    end
    table.sort(list, SortDiscuss)
    self.new_mine_num = new_mine_num
    self.new_mine_guild = new_mine_guild
    self.bbs_channel_mine = list
end

-- 查询token
function chat:QueryToken(is_refresh)
    network:Send({ query_chat_token = { is_refresh = is_refresh} })
end

-- 查询讨论区-公共频道
function chat:QueryDiscussCommon(is_refresh)
    if self.already_request_bbs_common and not is_refresh then
        return
    end
    if not self.token then
        graphic:DispatchEvent("show_prompt_panel", "social_is_close")
        return
    end

    local args = {}
    args["command"] = "QueryDiscuss"
    args["channel_type"] = constants.BBS_CHANNEL.common --公共频道
    args["channel_id"] = configuration:GetServerId()
    args["version"] = 1

    self:RequestSocial("bbs", args, function (response)
        self.already_request_bbs_common = true
        self.bbs_channel_common = response.data or {}

        self:BuildMineChannelList()
        graphic:DispatchEvent("update_bbs_main_panel")
    end)

end

function chat:QueryDiscussGuild(is_refresh)
    if not guild_logic:IsGuildMember() then
        return
    end
    if not self.token then
        graphic:DispatchEvent("show_prompt_panel", "social_is_close")
        return
    end

    if self.already_request_bbs_guild and not is_refresh then
        return
    end


    local args = {}
    args["command"] = "QueryDiscuss"
    args["channel_type"] = constants.BBS_CHANNEL.guild --公会频道
    args["channel_id"] = guild_logic.guild_id
    args["version"] = 1
    self:RequestSocial("bbs", args, function (response)
        self.already_request_bbs_guild = true
        self.bbs_channel_guild = response.data or {}

        -- self.bbs_channel_guild = {}
        -- for i,v in ipairs(response.data) do
        --     local info = json:decode(v)
        --     table.insert(self.bbs_channel_guild, info)
        -- end

        self:BuildMineChannelList()
        graphic:DispatchEvent("update_bbs_main_panel")
    end)
end

-- 查看评论
function chat:QueryReply(discuss)
    if not discuss then
        return
    end

    local args = {}
    args["command"] = "QueryReply"
    args["channel_type"] = discuss.channel_type
    args["channel_id"] = discuss.channel_id
    args["discuss_id"] = discuss.id
    self:RequestSocial("bbs", args, function (response)
        local list = {}
        for i,v in ipairs(response.reply_list) do
            local info = json:decode(v)
            table.insert(list, info)
        end
        discuss.reply_list = list
        discuss.has_reported = response.has_reported
        graphic:DispatchEvent("show_world_sub_scene", "bbs_detail_sub_scene", false, discuss)
    end)
end

-- 打开评论明细界面
function chat:QueryDiscussDetail(discuss)
    if not discuss.reply_list then
        self:QueryReply(discuss)
        return
    end
   graphic:DispatchEvent("show_world_sub_scene", "bbs_detail_sub_scene", false, discuss)
end

-- 举报评论
function chat:ReportDiscuss(discuss)
    discuss.has_reported = true

    local args = {}
    args["command"] = "Report"
    args["discuss_id"] = discuss.id
    self:RequestSocial("bbs", args, function (response)
        discuss.has_reported = true
    end)

end

-- 新的评论
function chat:NewDiscuss(channel_type, desc)
    if not self.token then
        graphic:DispatchEvent("show_prompt_panel", "social_is_close")
        return
    end
    local channel_id = 0
    if channel_type == constants.BBS_CHANNEL.common then
        channel_id = configuration:GetServerId()
    elseif channel_type == constants.BBS_CHANNEL.guild then
        if not guild_logic:IsGuildMember() then
            graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
            return
        end
        channel_id = guild_logic.guild_id
    else
        return
    end

    local troop_logic = require "logic.troop"

    local icon = ""
    if troop_logic.mercenary_list then
        local mercenary = troop_logic.mercenary_list[1]
        if mercenary then
            icon = mercenary.template_info.sprite
        end
    end

    if not tonumber(icon) or string.len(icon) <= 0 then
        icon = 99000002
    end

    local args = {}
    args["command"] = "NewDiscuss"
    args["channel_type"] = channel_type
    args["channel_id"] = channel_id
    args["user_name"] = troop_logic:GetLeaderName()
    args["user_icon"] = icon
    args["info"] = self:CheckIllegalCharacter(desc)

    self:RequestSocial("bbs", args, function (response)
        local info = json:decode(response.info)
        if channel_type == constants.BBS_CHANNEL.common then
            table.insert(self.bbs_channel_common, info)
            table.sort(self.bbs_channel_common, SortDiscuss)
        elseif channel_type == constants.BBS_CHANNEL.guild then
            table.insert(self.bbs_channel_guild, info)
            table.sort(self.bbs_channel_guild, SortDiscuss)
        end
        self:BuildMineChannelList()
        graphic:DispatchEvent("update_bbs_main_panel")
    end)
end

-- 新的留言
function chat:NewReply(discuss, desc)
    if not self.token then
        graphic:DispatchEvent("show_prompt_panel", "social_is_close")
        return
    end

    local args = {}
    args["command"] = "NewReply"
    args["discuss_id"] = discuss.id
    args["info"] = self:CheckIllegalCharacter(desc)

    self:RequestSocial("bbs", args, function (response)
        discuss.reply_list = discuss.reply_list or {}
        table.insert(discuss.reply_list,1, response.info)
        discuss.num = discuss.num + 1
        discuss.update_time = response.info.time
        self:BuildMineChannelList()
        graphic:DispatchEvent("update_bbs_detail_panel", discuss)
    end)
end

local req_api
local req_args
local req_success_callback

-- 重新申请token
function chat:ResetTokenToServer(api, args, success_callback)
    req_api = api
    req_args = args
    req_success_callback = success_callback
    self:QueryToken(true)
end

function chat:RequestSocial(api, args, success_callback)
    if not self.token then
        return
    end
    args["token"] = self.token
    args["user_id"] = self.user_id
    http_client:Post(self.social_server[api], json:encode(args),
        function(status_code, data)
            if status_code ~= 200 or not data then
                return
            end
            local response = json:decode(data)

            if not response then
                return
            end

            if response.result == 0 then
                if success_callback then
                    success_callback(response)
                end

            elseif response.result == 11009 then
                -- 如果发现token过期或者错误，就重新申请一次
                self.token = nil
                self:ResetTokenToServer(api, args, success_callback)
            elseif response.result == 11008 then
                graphic:DispatchEvent("show_prompt_panel", "", lang_constants:Get("chat_gag_in"))
            else
                -- graphic:DispatchEvent("show_prompt_panel", "", response.msg)
                graphic:DispatchEvent("show_prompt_panel", "", lang_constants:Get("chat_illegal_chars"))
            end
        end
    )
end

-- 查看数量
function chat:GetCommentNum(comment_type, target_id)
    local key = comment_type..":"..target_id
    return self.comment_num_cache[key]
end

-- 查看内容
function chat:GetCommentList(comment_type, target_id)
    local key = comment_type..":"..target_id
    return self.comment_info_cache[key]
end

-- 查看评论数量
function chat:QueryCommentNum(comment_type, target_id)
    -- print("QueryCommentNum = comment_type>"..comment_type..", target_id = "..target_id)
    local args = {}
    args["command"] = "QueryCommentNum"
    args["comment_type"] = comment_type
    args["target_id"] = target_id

    self:RequestSocial("comment", args, function(response)
        local key = comment_type..":"..target_id
        self.comment_num_cache[key] = tonumber(response.num or 0)
        graphic:DispatchEvent("update_comment_num", comment_type, target_id, self.comment_num_cache[key])
    end)

end
-- 查看评论列表
function chat:QueryCommentList(comment_type, target_id)
    if not self.token then
        graphic:DispatchEvent("show_prompt_panel", "social_is_close")
        return
    end
    if self:GetCommentList(comment_type, target_id) then
        graphic:DispatchEvent("show_world_sub_panel", "comment_panel", comment_type, target_id)
        return
    end

    local args = {}
    args["command"] = "QueryCommentInfo"
    args["comment_type"] = comment_type
    args["target_id"] = target_id
    self:RequestSocial("comment", args, function (response)
        local key = comment_type..":"..target_id
        self.comment_info_cache[key] = response.list
        graphic:DispatchEvent("show_world_sub_panel", "comment_panel", comment_type, target_id)
    end)
end

-- 点赞
function chat:LikeComment(comment_id)
    -- print("LikeComment = comment_id>"..comment_id..", user_id = "..self.user_id)
    local args = {}
    args["command"] = "Like"
    args["comment_id"] = comment_id
    self:RequestSocial("comment", args)
end

-- 发表评论
function chat:NewComment(comment_type, target_id, desc)

    local args = {}
    args["command"] = "NewComment"
    args["comment_type"] = comment_type
    args["target_id"] = target_id
    local troop_logic = require "logic.troop"
    args["role"] = troop_logic:GetLeaderName()
    args["desc"] = self:CheckIllegalCharacter(desc)

    self:RequestSocial("comment", args, function (response)
        local info = response.info
        local key = comment_type..":"..target_id
        local list = self.comment_info_cache[key] or {}

        local size = #list
        if size > 5 then
            table.insert(list,6,info)
        else
            table.insert(list,info)
        end
        self.comment_info_cache[key] = list
        self.comment_num_cache[key] = #list
        graphic:DispatchEvent("update_comment_num", comment_type, target_id, self.comment_num_cache[key])
        graphic:DispatchEvent("update_comment_panel", comment_type, target_id, list)
        graphic:DispatchEvent("show_prompt_panel", "comment_success")
    end)
end

function chat:RegisterMsgHandler()
    network:RegisterEvent("update_chat_token_ret", function(recv_msg)
        self.token = recv_msg.token

        if req_api then
            self:RequestSocial(req_api, req_args, req_success_callback)
            req_api = nil
            req_args = nil
            req_success_callback = nil
        end
    end)

end

function getStartByLen(str)
    local start_str = ""
    local i = 1
    while i <= string.len(str) do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        i = i + shift
        start_str = start_str.."*"
    end
    return start_str
end

--检查非法字符将其转换为*
function chat:CheckIllegalCharacter(desc)
    for k, v in pairs(key_words) do
        if string.find(desc, v) then
            desc = string.gsub(desc,v,getStartByLen(v))
        end
    end
    return desc
end


return chat
