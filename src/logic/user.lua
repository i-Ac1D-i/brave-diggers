local network = require "util.network"
local graphic = require "logic.graphic"
local constants = require "util.constants"
local platform_manager = require "logic.platform_manager"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"
local bit = require "bit"
local bit_extension = require "util.bit_extension"

local config_manager = require "logic.config_manager"
local common_function = require "util.common_function"
local analytics_manager = require "logic.analytics_manager"
local user_login = require("logic.login") 
local adventure_maze_config = config_manager.adventure_maze_config

local troop_logic
local adventure_logic
local mining_logic
local destiny_weapon_logic
local reward_logic
local bag_logic
local merchant_logic
local arena_logic
local temple_logic
local store_logic
local ladder_logic
local payment_logic
local mail_logic
local notice_logic
local time_logic
local social_logic
local achievement_logic
local carnival_logic
local vip_logic
local quest_logic
local notification_logic
local campaign_logic
local daily_logic
local reminder_logic
local guild_logic
local chat_logic
local sns_logic
local limite_logic
local rune_logic
local escort_logic

local MAX_RECONNECT_NUM = 5

local user = {}
function user:Init(user_id, reconnect_token)
    self.base_info = {}
    self.waiting_msg_name = ""

    self.user_id = user_id
    self.reconnect_token = reconnect_token or ""

    self.account = platform_manager:GetChannelInfo()

    self.just_create_leader = false
    self.leader_name = ""

    self.reconnect_num = 0
    self.is_reconnect = false
    self.reconnect_time = 0

    time_logic = require "logic.time"

    troop_logic = require "logic.troop"
    troop_logic:Init()

    adventure_logic = require "logic.adventure"
    adventure_logic:Init()

    mining_logic = require "logic.mining"
    mining_logic:Init()

    resource_logic = require "logic.resource"
    resource_logic:Init()

    reward_logic = require "logic.reward"
    reward_logic:Init()

    destiny_weapon_logic = require "logic.destiny_weapon"
    destiny_weapon_logic:Init()

    bag_logic = require "logic.bag"
    bag_logic:Init()

    merchant_logic = require "logic.merchant"
    merchant_logic:Init()

    temple_logic = require "logic.temple"
    temple_logic:Init()

    arena_logic = require "logic.arena"
    arena_logic:Init()

    store_logic = require "logic.store"
    store_logic:Init()

    ladder_logic = require "logic.ladder"
    ladder_logic:Init()

    payment_logic = require "logic.payment"
    payment_logic:Init(user_id)

    mail_logic = require "logic.mail"
    mail_logic:Init()

    daily_logic = require "logic.daily"
    daily_logic:Init()

    notice_logic = require "logic.notice"
    notice_logic:Init()

    social_logic = require "logic.social"
    social_logic:Init()

    chat_logic = require "logic.chat"
    chat_logic:Init(user_id)

    achievement_logic = require "logic.achievement"
    achievement_logic:Init()

    carnival_logic = require "logic.carnival"
    carnival_logic:Init()

    vip_logic = require "logic.vip"
    vip_logic:Init()

    quest_logic = require "logic.quest"
    quest_logic:Init()

    notification_logic = require "logic.notification"
    notification_logic:Init()

    campaign_logic = require "logic.campaign"
    campaign_logic:Init()

    reminder_logic = require "logic.reminder"
    reminder_logic:Init()

    guild_logic = require "logic.guild"
    guild_logic:Init(user_id)

    sns_logic = require "logic.sns"
    sns_logic:Init(user_id)

    limite_logic = require "logic.limite"
    limite_logic:Init()

	rune_logic = require "logic.rune"
    rune_logic:Init()

    escort_logic = require "logic.escort"
    escort_logic:Init()
    
    self:RegisterEvent()
end

function user:Update(elapsed_time)
    --检测是否需要重新连接
    self:CheckReconnect()

    adventure_logic:Update(elapsed_time)
    mining_logic:Update(elapsed_time)
    quest_logic:Update(elapsed_time)
    payment_logic:Update(elapsed_time)
    campaign_logic:Update(elapsed_time)
    carnival_logic:Update(elapsed_time)

    if self:DailyClear() then
        --清空
        daily_logic:DailyClear()
        temple_logic:DailyClear()
        social_logic:DailyClear()
    end
end
--FYD2 将该请求放入请求队列当中
function user:CacheQueryMsg(msg)
    table.insert(self.query_queue, msg)
end
--FYD4 执行栈顶的请求，并将其从栈顶移除
function user:PollQueryMsg()
    if #self.query_queue > 0 then
        if self.waiting_msg_name == "" or network.cur_msg_name == self.waiting_msg_name then
            local msg = table.remove(self.query_queue, 1)
            self.waiting_msg_name = next(msg) .. "_ret"
            local json = require "util.json"
            print("WLM Send msg = "..json:encode(msg))
            network:Send(msg)

            if self.waiting_msg_name == "finish_all_query_ret" then
                graphic:DispatchEvent("user_finish_query_info")
            end
        end
    end
end

function user:Query()
    self.query_queue = {}
    self.waiting_msg_name = ""

    --请求基础信息
    self:CacheQueryMsg({ query_user_base_info = {} })

    --请求宿命武器
    self:CacheQueryMsg({ query_destiny_weapon = {} })

    --请求资源信息
    self:CacheQueryMsg({ query_resource_list = {} })

    --请求雇佣兵信息
    self:CacheQueryMsg({ query_troop_info = {} })

    --请求冒险列表
    self:CacheQueryMsg({ query_adventure_maze_list = {} })

    --请求成就信息
    self:CacheQueryMsg({ query_achievement_list = {} })

    --请求矿区信息
    self:CacheQueryMsg({ query_mining_info = {} })

    --请求背包信息
    self:CacheQueryMsg({ query_bag_info = {} })

    --请求支付信息
    self:CacheQueryMsg({ query_payment_info = {} })

    --请求mail信息
    self:CacheQueryMsg({ query_mail_info = {} })

    --请求当天签到信息
    self:CacheQueryMsg({ query_daily = {}})

    --请求公告信息
    self:CacheQueryMsg({ query_notice_info = {} })

    --请求好友信息
    self:CacheQueryMsg({ query_social_info = {} })

    --请求合战信息
    self:CacheQueryMsg({ query_campaign_info = {} })

    --请求vip信息
    self:CacheQueryMsg({ query_vip = {} })

    --请求委托邮件信息
    self:CacheQueryMsg({ query_quest_mail_list = {} })

    -- 请求公会信息
    self:CacheQueryMsg({ query_guild = {} })

    --请求商品列表
    if payment_logic:CanQuery() then
        self:CacheQueryMsg({ query_payment_products_list = {} })
    end

    self:CacheQueryMsg({ query_store_info = { time_stamp = 0 } })

    --请求活动配置表信息   FYD1
    self:CacheQueryMsg({ query_carnival_config = {} })

    --请求活动数据
    self:CacheQueryMsg({ query_carnival_info = {} })
    
    --请求符文信息
    self:CacheQueryMsg({ query_rune_info = {} })

    --请求运送矿车相关次数信息
    self:CacheQueryMsg({ query_escort_info = {} })

    --请求运送矿车信息
    self:CacheQueryMsg({ query_escort_times = {} })

    --请求矿车列表信息
    self:CacheQueryMsg({ query_tramcar_list = {} })
    
    --FYD 7
    if platform_manager:GetChannelInfo().has_sns_share then
       self:CacheQueryMsg({ query_sns_info = {} })
    end

    self:CacheQueryMsg({ query_limite_package = {} })

    self:CacheQueryMsg({ finish_all_query = {} })
end

function user:GetUserId()
    return self.user_id
end

function user:GetUserLeaderName()
    return self.leader_name
end

--检测是否可以重新连接
function user:CheckReconnect()
    local cur_time = time_logic:Now()

    if self.is_reconnect then
        --五秒之后仍旧没有得到服务器响应
        if (cur_time - self.reconnect_time) > 5 then
            self:StartLogout()
        end
        return
    end

    network:HeartBeat()

    if not network:HasLostConnection() then
        return
    end

    if self.reconnect_num == MAX_RECONNECT_NUM then
        self:StartLogout()
        return
    end

    if self.reconnect_time == 0 then
        --自动进行一次重连
        self:DoReconnect()

    elseif cur_time > (self.reconnect_time + 1) then
        graphic:DispatchEvent("lost_connection")
    end
end

function user:DoReconnect()
    local cur_time = time_logic:Now()
    self.reconnect_num = self.reconnect_num + 1

    local server_info = configuration:GetServerInfo()

    local err = network:Connect(server_info.ip, server_info.port)

    if not err then
        self.is_reconnect = true
        self.reconnect_time = cur_time
        network:Send({reconnect = {user_id = self.user_id, reconnect_token = self.reconnect_token }}, true)

    else
        if self.reconnect_num >= MAX_RECONNECT_NUM then
            self:StartLogout()
        else
            self.is_reconnect = false
            graphic:DispatchEvent("lost_connection")
        end
    end
end
---FYD
function user:StartLogout(is_switch_account)
    
    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.name == "qikujp_appstore" then  --FYD  如果账户类型是gamecenter 那么必须先将gamecenter的开关变量设置为false
        PlatformSDK.signOut()
    end
    graphic:DispatchEvent("user_logout", is_switch_account)
end

function user:DoLogout()
    network:Disconnect()
    network.session = 0
    network.internal_session = 0

    PlatformSDK.removeTransactionObserver()
end

function user:FilterName(leader_name)
    local result = common_function.ValidName(leader_name, constants["LEADER_NAME_LENGTH"])
    if result == "invalid_char" then
        graphic:DispatchEvent("show_prompt_panel", "account_leader_name_special_char")
        return false
    elseif result == "exceed_max_length" then
        graphic:DispatchEvent("show_prompt_panel", "account_leader_name_too_long", constants["LEADER_NAME_LENGTH"])
        return false
    end

    return true
end

function user:CreateLeader(leader_name, mercenary_id)
    if self.just_create_leader then
        return
    end

    --先过滤开头和末尾的空格
    leader_name = common_function.Strip(leader_name)

    if not self:FilterName(leader_name) then
        return
    end

    local device_id = ""
    local device_type = ""

    if PlatformSDK.getUUID then
        device_id = PlatformSDK.getUUID()
    end

    if PlatformSDK.getDeviceType then
        device_type = PlatformSDK.getDeviceType()
    end

    network:Send({ create_leader = { name = leader_name, mercenary_id = mercenary_id, channel = platform_manager:GetChannelInfo().name, device_id = device_id, device_type = device_type}} )
end

function user:DailyClear()
    local t_now = time_logic:Now()
    local clear_day = time_logic:GetDateInfo(daily_logic.daily_clear_time).day
    local now_day = time_logic:GetDateInfo(t_now).day

    if clear_day == now_day then
        return false
    end

    daily_logic.daily_clear_time = t_now
    daily_logic.daily_num = 0
    daily_logic.check_in_mark = 0

    daily_logic.gold_recruit_cost = constants["RECRUIT_COST"]["recruiting_door"]

    return true
end

function user:IsJustCreateLeader()
    return self.just_create_leader
end

function user:SetJustCreateLeader(b)
    self.just_create_leader = b
end

function user:GetPermanentMark(mark)
    local flag = bit_extension:GetBitNum(self.base_info["permanent_mark"], mark - 1)
    return flag == 1
end

function user:SetPermanentMark(mark, flag)
    self.base_info["permanent_mark"] = bit_extension:SetBitNum(self.base_info["permanent_mark"], mark - 1, flag)
end

function user:IsFeatureUnlock(mark, need_prompt,from)
    if _G["AUTH_MODE"] then
        return true
    end

    local config = config_manager.open_permanent_config
    local OPEN_PERMANENT_TYPE = constants["OPEN_PERMANENT_TYPE"]
    local is_unlock = false

    need_prompt = (need_prompt == nil) and true or need_prompt

    local mark_type = config[mark]["type"]
    local value = config[mark]["value"]

    if mark_type == OPEN_PERMANENT_TYPE["maze_level"] then
        is_unlock = adventure_logic:IsMazeClear(value)
        if not is_unlock and need_prompt then
            --FYD 台灣需求在礦區最後的BOSS點擊之後，提示暫未開放、敬請期待(所以這裡也需要返回false 未解鎖狀態  如果需要解鎖則需要熱更解決)
            --如果是mining_main調用過來的(礦區boss) 且關卡要求為26-1，則認為是最下面的boss點擊
            local channel_info = platform_manager:GetChannelInfo()
            if channel_info.meta_channel == "txwy" and from == "mining_main" and adventure_maze_config[value]["name"] == "26-1" then  
               graphic:DispatchEvent("show_prompt_panel", "feature_unlock", "FYD_MINING_BOSS",channel_info.mining_lock_tip)  
               return false 
            else
              graphic:DispatchEvent("show_prompt_panel", "feature_unlock", adventure_maze_config[value]["name"])
            end
        end

    elseif mark_type == OPEN_PERMANENT_TYPE["troop_bp"] then
        is_unlock = troop_logic:GetTroopBP() >= value
    end

    return is_unlock
end

function user:GetNoviceMark(mark)
    local flag = bit_extension:GetBitNum(self.base_info["novice_mark"], mark - 1)
    return flag == 1
end

function user:SetNoviceMark(mark, flag)
    network:Send({ change_novice_mark = { mark_index = mark, mark_value = flag } })
end

function user:UpdateUserInfo(is_create)
    local channel = platform_manager:GetChannelInfo()
    if not channel.update_user_info then
        return
    end

    if is_create == nil then
        is_create = false
    end

    local server_id = configuration:GetServerId()
    local server_name = configuration:GetServerName()

    local bd_num = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["blood_diamond"]) or 0
    local leader = troop_logic:GetLeader()

    if channel.name == "yayawan1_android" or channel.name == "yayawan_android" then
        level = leader and leader.battle_point or 100

    else
        --level是觉醒等级
        level = leader and leader.wakeup or 1
    end

    local info = string.format("roleId=%s&roleName=%s&roleLevel=%s&zoneId=%s&zoneName=%s&isCreate=%s&balance=%d", self.user_id, self.leader_name, tostring(level), tostring(server_id), server_name, tostring(is_create), bd_num)

    platform_manager:SetUserInfo(info)
end

function user:UpdateLeaderName(leader_name)
    self.leader_name = leader_name
    self:UpdateUserInfo(false)
end

function user:ChangeLeaderName(leader_name)
    if string.len(leader_name) <= 0 then
        return
    end

    if self.leader_name == leader_name then
        return
    end

    leader_name = common_function.Strip(leader_name)

    if not self:FilterName(leader_name) then
        return
    end

    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], constants["RENAME_COST"], true) then
        return
    end

    network:Send({ change_leader_name = { leader_name = leader_name, mercenary_id = 0 } })
end

function user:RegisterEvent()
    network:RegisterEvent("query_user_base_info_ret", function(recv_msg)
        print("query_user_base_info_ret")
        for k, v in pairs(recv_msg) do
            self.base_info[k] = v
        end

        if TalkingDataGA then
            TalkingDataGA:onEvent("login")
        end

        analytics_manager:TriggerEvent("login", self.user_id)

        self.leader_name = recv_msg.leader_name

        troop_logic:SetLeaderName(recv_msg.leader_name, recv_msg.leader_bp)
        arena_logic:SetRefreshTime(recv_msg.arena_refresh_time)
        ladder_logic:SetCurrentRank(recv_msg.cur_rank)
    end)

    network:RegisterEvent("create_leader_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.just_create_leader = true
            self.leader_name = recv_msg.name

            if TalkingDataGA then
                TalkingDataGA:onEvent("create_role")
            end

            --楼上两句 功能实现效果一样 只要再manager里面判断平台即可区分
            analytics_manager:TriggerEvent("create_role", recv_msg.user_id)

            self:UpdateUserInfo(true)

            platform_manager:GetAccountDelegate():UpdateLeaderName(self.leader_name, self.user_id)
        end

        graphic:DispatchEvent("user_finish_create_leader", recv_msg.result)
    end)

    network:RegisterEvent("reconnect_ret", function(recv_msg)
        self.is_reconnect = false
        if recv_msg.result == "success" then
            self.reconnect_num = 0
            self.reconnect_time = 0
            time_logic:SyncTime(recv_msg.server_time, recv_msg.time_zone)
        else
            self:StartLogout()
        end
    end)

    network:RegisterEvent("logout_ret", function(recv_msg)
        if recv_msg.reason == "kick" then
        elseif recv_msg.reason == "repeated_login" then
        end

        self:StartLogout()
    end)

    network:RegisterEvent("update_base_info", function(recv_msg)
        if recv_msg.base_info_type == "max_box_num" then
            adventure_logic:SetMaxBoxNum(recv_msg.new_value)
        end
    end)

    network:RegisterEvent("finish_all_query_ret", function(recv_msg)
        print("finish_all_query_ret")

        local server_id = configuration:GetServerId()
        local channel_name = platform_manager:GetChannelInfo().name
        if channel_name == "snda_android" then
            platform_manager:SetUserInfo(server_id)

        else
            self:UpdateUserInfo(false)
        end

        --主界面请求一次social
        chat_logic:QueryToken(false)

        configuration:Save()
        if TalkingDataGA then
            TDGAAccount:setAccount(self.user_id)
            TDGAAccount:setAccountName(self.leader_name)
            -- TDGAAccount:setLevel(self.base_info.leader_bp)
            TDGAAccount:setGameServer(server_id)
        end

    end)

    network:RegisterEvent("change_leader_name_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local leader_name = recv_msg.leader_name

            self:UpdateLeaderName(leader_name)
            troop_logic:SetLeaderName(leader_name)

            if TalkingDataGA then
                TDGAAccount:setAccountName(leader_name)
            end

            platform_manager:GetAccountDelegate():UpdateLeaderName(self.leader_name, self.user_id)

            graphic:DispatchEvent("update_panel_leader_name", leader_name)

        elseif recv_msg.result == "invalid_name" then
            graphic:DispatchEvent("show_prompt_panel", "account_leader_name_invalid_char")

        elseif recv_msg.result == "repeat_name" then
            graphic:DispatchEvent("show_prompt_panel", "account_repeat_leader_name")
        end
    end)

    network:RegisterEvent("change_novice_mark_ret", function(recv_msg)

        if recv_msg.result == "success" then
            self.base_info["novice_mark"] = recv_msg.novice_mark or self.base_info["novice_mark"]
        end
    end)

    network:RegisterEvent("bind_account_ret", function(recv_msg)
        if recv_msg.result == "success" then
            platform_manager:GetAccountDelegate():UpdateLeaderName(self.leader_name, self.user_id)
        end

        graphic:DispatchEvent("show_bind_account_result", recv_msg.result)
    end)
end

return user
