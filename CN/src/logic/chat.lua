local graphic = require "logic.graphic"
local json = require "util.json"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local configuration = require "util.configuration"
local network = require "util.network"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local key_words =require "logic.key_words"
local chat_network = require "util.chat_network"
local feature_config = require "logic.feature_config"
local login_logic = require "logic.login"
local client_constants = require "util.client_constants"
local open_permanent_config = config_manager.open_permanent_config
local guild_logic

local http_client

local vip_logic
local adventure_logic

local BBS = 1
local COMMENT = 2
local MAX_CONTENTS_NUMBER = 50

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
    self.social_server["bbs"] = string.format("%s/bbs", login_logic.bbs_server)
    self.social_server["comment"] = string.format("%s/comment", login_logic.comment_server)

    self.already_request_bbs_common = false
    self.bbs_channel_common = {}

    self.already_request_bbs_guild = false
    self.bbs_channel_guild = {}

    self.bbs_channel_mine = {}
    self.new_mine_num = 0
    self.new_mine_guild = 0
    self.try_connect_index = 0

    self.comment_num_cache = {}

    self.comment_info_cache = {}

    self.chat_msg_list = {}
    self.chat_new_message_list = {}

    self.chat_network = chat_network.New()
    self.chat_network:Init()

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
    args["channel_id"] = configuration:GetMergeId()
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
        channel_id = configuration:GetMergeId()
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

    self:RegisterChatMsgHandler()

end

function chat:RegisterChatMsgHandler()
    self.chat_network:RegisterEvent("append_chat_ret", function(recv_msg)
        if recv_msg.result == "success" then
            -- print("发送成功")
        elseif recv_msg.result == "forbiding" then
            --禁言中
            local time = recv_msg.forbid_time
            if time then
                local hour = math.floor(time/3600)
                local min = math.floor((time - (hour * 3600)) / 60)
                local sec = time % 60
                local time_str =  hour.. ":".. min .. ":" .. sec
                if time > 3600*24*7 then
                    graphic:DispatchEvent("show_prompt_panel", "forbiding_than_seven_hour", time_str)
                else
                    graphic:DispatchEvent("show_prompt_panel", "forbiding_less_seven_hour", time_str)
                end
            else
                graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            end
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    self.chat_network:RegisterEvent("refresh_chat_msg", function(recv_msg)
        if recv_msg.msg_list then
            -- print("有新的消息")
            local msg = recv_msg.msg_list
            local show_content = nil
            for k,content in pairs(msg) do
                if content.user_id ~= self.user_id then
                    show_content = content
                end
                self:addChatContent(content)
            end
            
            graphic:DispatchEvent("have_a_new_message", show_content)
        end
    end)

    self.chat_network:RegisterEvent("query_chat_ret", function(recv_msg)
        self.chat_msg_list = recv_msg.msg_list or {}
        if recv_msg.msg_list  then
            -- print("查询成功------------")
            local msg = recv_msg.msg_list
            -- print("消息列表大小",#msg)
            for k,content in pairs(msg) do
                self:addChatContent(content)
            end
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

--------------------------------------------------聊天--------------------------------------------------
--检查是否连接服务器
function chat:CheckIsConnect()
    if not feature_config:IsFeatureOpen("chat_world") then
        return false
    end
    if self.chat_network:IsConnected() then
        return true
    else
        self:TryConnectChat(true)
    end
    return false
end

function chat:TryConnectChat(is_show_prompt)
    local chat_server_list = login_logic:GetChatServerList()
    if not feature_config:IsFeatureOpen("chat_world") or #chat_server_list <= 0 then
        return 
    end
    local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
    local chat_open_permanent_config = open_permanent_config[FEATURE_TYPE["chat_world"]]
    if not chat_open_permanent_config then
        return
    end
    local open_value = chat_open_permanent_config.value 
    local is_unlock = adventure_logic:IsMazeClear(open_value)

    --判断是否开启条件
    if not is_unlock and not vip_logic:IsActivated(constants["VIP_TYPE"]["adventure"]) then
        if is_show_prompt then
            graphic:DispatchEvent("show_prompt_panel", "chat_need_vip_tips", config_manager.adventure_maze_config[open_value]["name"])
        end
        return
    end

    if not self.chat_network:IsConnected() then
        self.try_connect_index = self.try_connect_index + 1
        if self.try_connect_index <= #chat_server_list then
            local connect_info = chat_server_list[self.try_connect_index]
            local err = self.chat_network:Connect(connect_info.ip, tonumber(connect_info.port))
            if not err then
                --连接成功
                if not self.chat_network.event_name_list["login_chat_ret"] then
                    self.chat_network:RegisterEvent("login_chat_ret", function(recv_msg)
                        if recv_msg.result == "success" then
                            self.chat_msg_list = {}
                            self.chat_new_message_list = {}
                            self.connect_ip_id = self.try_connect_index
                            self.try_connect_index = 0
                            if is_show_prompt then
                                graphic:DispatchEvent("select_connect_success")
                            end
                        else
                            --没有连接成功
                            self.chat_network:Disconnect()
                            self:TryConnectChat()
                        end
                    end)
                end
                self:TryLoginChat(self.chat_network)
            end
        end
    end
end

--断开连接
function chat:ChatNetworkClear()
    if not feature_config:IsFeatureOpen("chat_world") then
        return 
    end
    self.chat_network:Clear()
end

--更换连接服务器
function chat:ChangeConnect(select_id)
    local chat_server_list = login_logic:GetChatServerList()
    if #chat_server_list <= 0 then
        return false
    end
    local select_info = chat_server_list[select_id]
    if select_info == nil then    
        return false
    end
    if select_id == self.connect_ip_id then
        return false
    end
    self.will_connect = chat_network.New()
    self.will_connect:Init()
    local err = self.will_connect:Connect(select_info.ip, tonumber(select_info.port))
    if not err then
        --连接成功
        if not self.will_connect.event_name_list["login_chat_ret"] then
            self.will_connect:RegisterEvent("login_chat_ret", function(recv_msg)
                if recv_msg.result == "success" then
                    self.chat_network:Clear()
                    self.chat_network = self.will_connect
                    self:RegisterChatMsgHandler()
                    self.chat_msg_list = {}
                    self.chat_new_message_list = {}
                    self.connect_ip_id = select_id
                    self.try_connect_index = 0
                    graphic:DispatchEvent("select_connect_success")
                    graphic:DispatchEvent("show_prompt_panel", "select_chat_server_success")
                else
                    if self.will_connect then
                        self.will_connect:Clear()
                        self.will_connect = nil
                    end
                    graphic:DispatchEvent("select_connect_failed")
                    graphic:DispatchEvent("show_prompt_panel", "select_chat_server_faile")
                end
            end)
        end
        self:TryLoginChat(self.will_connect)
    else
        self.will_connect = nil
        graphic:DispatchEvent("show_prompt_panel", "select_chat_server_faile")
        return false
    end
    return true
end

function chat:TryLoginChat(chat_net)
    local self_user_id = self.user_id
    chat_net:Send({login_chat = {user_id = self_user_id}})
end

--发送消息
function chat:SendMessage(message)
    if not self:CheckIsConnect() then
        return false
    end
    local self_user_id = self.user_id
    local server_id = configuration:GetMergeId()

    local server_name = configuration:GetServerName()
    local troop_logic = require "logic.troop"
    local leader_name = troop_logic:GetLeaderName()
    local cur_formation_id = troop_logic:GetCurFormationId()
    local cur_formation = troop_logic:GetFormationMercenaryList(cur_formation_id)
    local template_id = cur_formation[1].template_id
    message = self:CheckIllegalCharacter(message)
    self.chat_network:Send({append_chat = { user_id = self_user_id, template_id = template_id, server_name = server_name, leader_name = leader_name, server_id = server_id, content = message}})
    
    return true
end

function chat:getChatContent()
    return self.chat_msg_list or {} 
end

function chat:getNewChatContent()
    return self.chat_new_message_list or {}
end

function chat:addChatContent(content)
    table.insert(self.chat_msg_list,content)
    table.insert(self.chat_new_message_list,content)
    if #self.chat_new_message_list > MAX_CONTENTS_NUMBER then
        self:removeNewChatContent(1)
    end
end

function chat:removeNewChatContent(index)
    table.remove(self.chat_new_message_list,index)
end

function chat:removeAllNewChatContent()
    self.chat_new_message_list = {}
end

function chat:removeChatContent(index)
    table.remove(self.chat_msg_list,index)
end

--------------------------------------------------------------------------------------------------------

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
