
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local social_logic
local chat_logic
local troop_logic
local platform_manager = require "logic.platform_manager"
local configuration = require "util.configuration"
local network = require "util.network"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local common_function = require "util.common_function"
local bit_extension = require "util.bit_extension"
local feature_config = require "logic.feature_config"

local guild = {}
local string_gmatch = string.gmatch 
local string_find = string.find
local string_sub = string.sub
local to_number = tonumber

local GUILD_GRADE = constants.GUILD_GRADE
local GUILD_PERMISSION_LIST = constants.GUILD_PERMISSION_LIST

local NO_WAR_FIELD = client_constants["NO_WAR_FIELD"]

local SEASON_KEY_PREFIX = 6

local BASE_SCORE = constants.GUILDWAR_BASE_SCORE
local ROUND_SCORE = constants.GUILDWAR_ROUND_SCORE
local FIELD_SCORE = constants.GUILDWAR_FIELD_SCORE
local KILL_SCORE = constants.GUILDWAR_KILL_SCORE
local REWARD_TYPE = constants.REWARD_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE

local BATTLE_STATUS = client_constants.BATTLE_STATUS

local BUFF_FACTOR = constants.GUILDWAR_BUFF_FACTOR
local BUFF_TYPE = constants.GUILDWAR_BUFF_TYPE
local BUFF_TYPE_NAME = {}
for k, v in pairs(BUFF_TYPE) do
    BUFF_TYPE_NAME[v] = k
end

local CLIENT_GUILDWAR_STATUS_TIME_NAME = client_constants.CLIENT_GUILDWAR_STATUS_TIME_NAME
local CLIENT_GUILDWAR_STATUS = client_constants.CLIENT_GUILDWAR_STATUS

local FRIGHT_STATE = {
    ["normal"] = 0, --正常状态
    ["began_fright"] = 1, --发起进攻
    ["start_fright"] = 2, --战斗播放
}

-- 初始化
function guild:Init(user_id)
    chat_logic = require "logic.chat"
    social_logic = require "logic.social"
    troop_logic = require "logic.troop"

    self.user_id = user_id

    self.cur_status = CLIENT_GUILDWAR_STATUS["NONE"]
    self.cur_season_conf = nil

    self.mercenary_list = {}
    self.warfield_member = {}
    self.member_troop_info = {}
    self.rival_troop_info = {}
    self.guild_ranklist = {}

    self.has_query_reward_config = false
    self.has_query_guild_rank = false
    self.has_query_war_result = false

    self.season_config_list = {}
    self.season_key_map = {}
    self.war_season_info = {}

    self:Clear()
    self:GetGuildSetting()

    self:RegisterMsgHandler()

    self.guild_boss_ranklist = nil
    self.guild_boss_list = nil
    self.guild_boss_reset_time = 0
    self.time_recod = 0
    self.guild_boss_over = true
    self.fight_boss_state = FRIGHT_STATE.normal
    self.query_guild_boss_rank_time = 0
end

function guild:Update(elapsed_time)
    if self.cur_season_conf then
        local t_now = time_logic:Now()
        local status_changed = true

        if self.cur_status == CLIENT_GUILDWAR_STATUS["NONE"] and t_now > self.cur_season_conf.start_time then
            self:UpdateMemberInfo()
            self.cur_status = CLIENT_GUILDWAR_STATUS["READY"]

        elseif self.cur_status == CLIENT_GUILDWAR_STATUS["READY"] and t_now > self.cur_season_conf.ready_end_time then
            self:ClearMemberWarField()
            self.cur_status = CLIENT_GUILDWAR_STATUS["WAIT_ENTER"]

        elseif self.cur_status == CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] and t_now > self.cur_season_conf.enter_end_time then
            self.cur_status = CLIENT_GUILDWAR_STATUS["WAIT_TROOP"]

        elseif self.cur_status == CLIENT_GUILDWAR_STATUS["WAIT_TROOP"] and t_now > self.cur_season_conf.set_troop_end_time then
            self.cur_status = CLIENT_GUILDWAR_STATUS["MATCHING"]

        elseif self.cur_status == CLIENT_GUILDWAR_STATUS["MATCHING"] and t_now > self.cur_season_conf.match_end_time then
            self.has_query_war_result = false
            self.cur_status = CLIENT_GUILDWAR_STATUS["WAIT_FINISH"]

        elseif self.cur_status == CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] and t_now > self.cur_season_conf.fight_end_time then
            self.cur_status, self.cur_season_conf = self:GetSeasonConfByCurTime()
        else
            status_changed = false
        end

        if status_changed then
            graphic:DispatchEvent("update_guild_war_status", self.cur_status)
        end
    end

    if not self.guild_boss_over then
        local times = self.guild_boss_reset_time - time_logic:Now()
        if times <= 0 then
            self.time_recod = self.time_recod + elapsed_time
            if self.time_recod >= 5 then
                --5秒刷新一次
                self.time_recod = 0
                self.fresh_boss = false
            end
            if not self.fresh_boss then 
                self.fresh_boss = true
                self:BossRest()
            end
        end
    end
end

function guild:GetCurrentRound()
    return self.cur_season_conf["round"] or 0
end

function guild:GetRoundTimeInfo(status)
    if self.cur_season_conf then
        return self.cur_season_conf[CLIENT_GUILDWAR_STATUS_TIME_NAME[status]]
    end
end

function guild:IsEnterForCurrentWar()
    local entered_flag = false

    if not self.cur_season_conf then
        return false
    end

    local round = to_number(self.cur_season_conf["round"])
    if self.war_season_info then 
        for k, t_round in ipairs(self.war_season_info) do 
            if t_round == round then
                entered_flag = true 
                break
            end
        end
    end

    return entered_flag
end

function guild:GetMyGuildRight()
    return self.own_member_info.grade_type
end

function guild:GetSeasonInfo()
    return self.war_season_info
end

function guild:UpdateMemberInfo()
    self.war_member_list = nil
end

function guild:GetMemberWarScoreDetail()
    local kill_score = 0
    local round_score = 0
    local field_score = 0
    local base_score = 0

    if self.war_member_list then
        for _,member in pairs(self.war_member_list) do
            if member.user_id == self.user_id then
                kill_score = member.kill_score
                round_score = member.round_score
                field_score = member.field_score
                base_score = member.base_score
                break
            end
        end
    end

    return base_score, field_score, round_score, kill_score
end

function guild:ClearMemberWarField()
    if self.member_list then 
        for i = 1, #self.member_list do
            self.member_list[i].war_field = NO_WAR_FIELD
            self.member_list[i].buff_info = 0
            self.member_list[i].buff_num = 0
        end
    end
    self:UpdateFieldData()
end

function guild:GetCurStatus()
    return self.cur_status
end

function guild:GetCurStatusAndRemainTime()
    if self.cur_season_conf then
        return self.cur_status, self.cur_season_conf[CLIENT_GUILDWAR_STATUS_TIME_NAME[self.cur_status]] or 0
    else
        return CLIENT_GUILDWAR_STATUS["NONE"], 0
    end
end

function guild:GetCurSeasonConf()
    return self.cur_season_conf
end

function guild:Clear()
    self.guild_id = nil
    self.guild_name = nil
    self.member_list = {}
    self.notice_list = {}
    self.warfield_member = nil
    self.rival_info = nil
    self.notice_unread_num = 0
    self.guild_ranklist = {}
    self.member_troop_info = {}
    self.battle_records_map = {}
    self.war_member_list = nil
    self.vs_troop_nums = nil
    self.remain_troop_nums = nil
    self.vs_remain_troop_nums = nil
    self.field_status = nil
    
    self.has_query_guild_rank = false
    self.has_query_war_result = false
    self.query_war_result_time = 0

    chat_logic.already_request_bbs_guild = false
    chat_logic.new_mine_guild = 0

    self.allocated = 0
    self.alloc_num = 0

    self.war_season_info = {}

    self.war_score = 1500
    self.old_war_score = 1500

    self.guild_boss_ranklist = nil
    self.guild_boss_list = nil
    self.guild_boss_reset_time = 0
    self.guild_boss_exchange_reward_info = nil
    self.guild_cur_boss_id = nil
    self.guild_boss_over = true

end

--根据当前时间获取season_conf
function guild:GetSeasonConfByCurTime()
    local cur_status = CLIENT_GUILDWAR_STATUS["NONE"]
    local cur_season_conf
    local t_now = time_logic:Now()

    local tmp_time = 0
    for _,season_conf in ipairs(season_config_list) do
        if t_now < season_conf.end_time then
            cur_season_conf = season_conf
            break
        end
    end

    if cur_season_conf then
        for status, status_name in ipairs(CLIENT_GUILDWAR_STATUS_TIME_NAME) do
            if t_now < cur_season_conf[status_name] then
                cur_status = status
                break
            end
        end
    end

    return cur_status, cur_season_conf
end

function guild:InitMemberList()
    self.member_list = self.member_list or {}

    for k, v in pairs(self.member_list) do
        if v.user_id == self.user_id then
            self.own_member_info = v
        end

        if v.grade_type == GUILD_GRADE["chairman"] then
            self.chairman_info = v
        end

        v.buff_info = v.buff_info or 0
        self:CalcMemberBuffNum(v)
    end
end

function guild:SortMemberList(sort_type)
    local sort_member
    if sort_type == client_constants["MEMBER_SORT_TYPE"]["login_time"] then 
        sort_member = function(a, b)
            return a.last_login_time > b.last_login_time
        end        
    elseif sort_type == client_constants["MEMBER_SORT_TYPE"]["score"] then 
        sort_member = function(a, b)
            return a.season_score > b.season_score
        end        
    else
        return
    end
    if type(sort_member) == "function" then 
       table.sort(self.member_list, sort_member)
    end
end

function guild:CalcMemberBuffNum(member)
    member.buff_num = 0
    for i = 1, 5 do
        if bit_extension:GetBitNum(member.buff_info, i-1) == 1 then
            member.buff_num = member.buff_num + 1
        end
    end
end

function guild:CalcMemberBuffInfo(member, troop_info, i)
    local has_buff = bit_extension:GetBitNum(member.buff_info, i-1) == 1
    if i == BUFF_TYPE["bp"] then
        troop_info.battle_point = has_buff and math.ceil(troop_info.battle_point * (1+BUFF_FACTOR[i])) or troop_info.battle_point

    else
        troop_info[BUFF_TYPE_NAME[i]] = has_buff and troop_info[BUFF_TYPE_NAME[i]] + BUFF_FACTOR[i] or troop_info[BUFF_TYPE_NAME[i]]
    end
end

function guild:UpdateFieldData()
    self.warfield_member = {}

    --未上阵成员
    self.warfield_member[0] = {}
    
    for i = 1, 3 do
        self.warfield_member[i] = {}
    end

    if self.member_list then
        for k, v in pairs(self.member_list) do
            table.insert(self.warfield_member[v.war_field], v)
        end
    end
end

function guild:GetFieldMembersByField(war_field)
    if self.warfield_member[war_field] then 
        return self.warfield_member[war_field]

    else
        return {}
    end
end

function guild:GetMemberByUserid(user_id)
    local member = nil
    for k, v in pairs(self.member_list) do 
        if v.user_id == user_id then 
            member = v 
            break
        end
    end

    return member
end

function guild:GetMembersInWarField(war_field)
    local num = 0
    if self.warfield_member[war_field] then 
        num = #self.warfield_member[war_field]
    end

    return num
end

function guild:UpdateTroopBP(bp)
    if self.own_member_info then
        self.own_member_info.bp = bp
    end
end

function guild:InitNoticeList()
    local count = 0
    self.notice_list = self.notice_list or {}
    self.read_notice_time = self.read_notice_time or 0
    for k, v in pairs(self.notice_list) do
        if v.create_time > self.read_notice_time then
            count = count + 1
        end
    end
    self.notice_unread_num = count
end

-- 查询公会信息
function guild:Query()
    graphic:DispatchEvent("show_world_sub_scene", "guild_sub_scene")
end

function guild:CheckPermission(purpose, prompt_key, not_use_prompt)
    if not self.own_member_info then
        return false
    end
    
    local not_use_prompt = not_use_prompt or false
    local prompt_key = prompt_key or "guild_has_no_permission"
    
    if not GUILD_PERMISSION_LIST[purpose][self.own_member_info.grade_type] then
        if not not_use_prompt then 
           graphic:DispatchEvent("show_prompt_panel", prompt_key)
        end

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

    local result = common_function.ValidName(guild_name, constants["LEADER_NAME_LENGTH"])
    if result == "invalid_char" then
        graphic:DispatchEvent("show_prompt_panel", "guild_name_special_char")
        return false
    elseif result == "exceed_max_length" then
        graphic:DispatchEvent("show_prompt_panel", "guild_name_too_long", constants["LEADER_NAME_LENGTH"])
        return false
    end

    guild_name = common_function.Strip(guild_name)

    network:Send({create_guild = {guild_name = guild_name, bp_limit_idx = bp_limit_idx}})
end

function guild:GetGuildShowList()
    network:Send({get_guild_list = {}})
end

--查找公会ID
function guild:SearchGuild(guild_id)

    if string.len(guild_id) == 0 then
        graphic:DispatchEvent("show_prompt_panel", "guild_id_not_none")
        return false
    end

    network:Send({search_guild = {guild_id = guild_id}})
end

function guild:alreadyJoin(guild_id)

    if self:IsGuildMember() then
        
        return true
    else
        return false
    end
end
--加入公会
function guild:JoinGuild(guild_id)
    if self:IsGuildMember() then
        graphic:DispatchEvent("show_prompt_panel", "guild_repeat_member")
    else
        network:Send({join_guild = {guild_id = guild_id}})
    end
end

--解散公会
function guild:DismissGuild()
    if not self:IsGuildChairman() then
        graphic:DispatchEvent("show_prompt_panel", "executor_not_chairman")
        return
    end

    if self:IsEnterForCurrentWar() then 
       graphic:DispatchEvent("show_prompt_panel", "guild_dismiss_tip1")
    else
        network:Send({dismiss_guild = {}})
    end
end

--退出公会
function guild:ExitGuild()
    if self.cur_status == CLIENT_GUILDWAR_STATUS["NONE"] or self.own_member_info.war_field == NO_WAR_FIELD then 
        network:Send({exit_guild = {}})
    else
        graphic:DispatchEvent("show_prompt_panel", "guild_war_member_in_warfield")
    end
end

-- 开除公会
function guild:FireMember(target_user_id)
    if not self:CheckPermission("fire") then
        return
    end

    local member = self:GetMemberByUserid(target_user_id)
    if member and (self.cur_status == CLIENT_GUILDWAR_STATUS["NONE"] or member.war_field == NO_WAR_FIELD) then 
        network:Send({fire_guild_member = {user_id = target_user_id}})
    else
        graphic:DispatchEvent("show_prompt_panel", "guild_war_member_in_warfield")
    end
end

-- 转让公会
function guild:TransferGuild(target_user_id)
    if not self:CheckPermission("transfer") then
        return
    end

    network:Send({transfer_guild = {user_id = target_user_id}})
end

function guild:AppointMember(target_user_id, new_grade_type)
    if not self:CheckPermission("appoint") then
        return
    end

    network:Send({guild_appoint_member = {member_user_id = target_user_id, grade_type = new_grade_type }})
end

function guild:SetSetting(bp_limit_idx)
    if not self:CheckPermission("set_conf") then
        return
    end

    self.bp_limit_idx = bp_limit_idx
    network:Send({set_guild_conf = {bp_limit_idx = bp_limit_idx}})
end

function guild:GetGenreData()
    if self.cur_season_conf and self.cur_season_conf["bonus_genre"] and self.cur_season_conf["bonus_factor"] then 
       return self.cur_season_conf["bonus_genre"], self.cur_season_conf["bonus_factor"]
    end
    return {0, 0, 0}, {0, 0, 0}
end

function guild:EnterForGuildWar()
    if not self:CheckPermission("enter_for_war", "guild_enterfor_no_permission") then
        return
    end

    if self:IsEnterForCurrentWar() then 
       return
    end

    network:Send({ guild_enter_for = {}})
end

function guild:UpdateWarField(target_user_id, war_field)
    if war_field > constants["MAX_WAR_FIELDS"] then 
        return
    end

    if self.cur_status <= CLIENT_GUILDWAR_STATUS["READY"] or self.cur_status >= CLIENT_GUILDWAR_STATUS["MATCHING"] then
        graphic:DispatchEvent("show_prompt_panel", "guild_war_cant_update_member_field")
        return
    end

    if target_user_id ~= self.user_id then 
        local member_info = self:GetMemberByUserid(target_user_id)

        if not member_info then 
            return 
        end

        if not self:CheckPermission("update_warfield") then
           return 
        end

        if self.own_member_info.grade_type <= member_info.grade_type then 
           graphic:DispatchEvent("show_prompt_panel", "has_no_permission")
           return 
        end
    end

    network:Send({ guild_update_warfield = {user_id = target_user_id, war_field = war_field }})
end

function guild:QueryMemberTroop(user_id, reason)
    if not self.own_member_info then
        return
    end

    network:Send({ query_guild_member_troop = {user_id = user_id, reason = reason} })
end

function guild:QueryRival()
    local query_success = true
    
    if not self:IsEnterForCurrentWar() then
        return
    end

    if self.has_query_rival then 
        graphic:DispatchEvent("refresh_war_rival_info")
    else
        query_success = network:Send({ query_guild_rival_info = {} })
    end

    return query_success
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

function guild:GetMemberList()
    return self.member_list
end

function guild:IsMyGuildMember(user_id)
    if self.member_list then
        for _, member in pairs(self.member_list) do
            if member.user_id == user_id then
                return true
            end
        end
    end

    return false
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

function guild:IsGuildManager()
    if not self.own_member_info then 
       return false
    end

    if self.own_member_info.grade_type == GUILD_GRADE["highstaff"] then
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

-- 获取设置信息（是否提示公会通知,查看成员时间,查看通知时间）
function guild:GetGuildSetting()

    local guild_info_list = configuration:GetGuildInfoList()

    local guild_info = guild_info_list[self.user_id] or {}

    if type(guild_info.read_notice_time) == "number" then
        self.read_notice_time = guild_info.read_notice_time
    else
        self.read_notice_time = 0
    end

    self.is_notice_notify = guild_info.is_notice_notify
end

-- 保存设置信息（查看成员列表时间,查看通知时间,是否开启通知提醒）
function guild:SaveGuildSetting()

    local guild_info_list = configuration:GetGuildInfoList()
    local guild_info = {}
    guild_info.read_notice_time =  self.read_notice_time
    guild_info.is_notice_notify = self.is_notice_notify
    guild_info_list[self.user_id] = guild_info

    configuration:Save()
end

-- 查看公会通知
function guild:ReadNoticeList()
    if self:IsGuildMember() then
        graphic:DispatchEvent("show_world_sub_panel", "guild.notice_panel")

        self.read_notice_time = time_logic:Now()
        self.notice_unread_num = 0

        graphic:DispatchEvent("refresh_notice_tips")

        self:SaveGuildSetting()
    else
        graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
    end
end

function guild:SetBan()
    self.is_notice_notify = not self.is_notice_notify
    --这里临时注释不向服务器存储状态，因为这个协议会导致客户端停滞在这里，
    -- network:Send({ guild_notice_tips = {} })

    self:SaveGuildSetting()
end

function guild:GetWarField()
    local war_field = 0
    if self.own_member_info.war_field then 
       war_field = self.own_member_info.war_field
    end

    return war_field
end

function guild:GetScore()
    return self.war_score
end

function guild:GetOldScore()
    return self.old_war_score
end

function guild:GetIsAllocated()
    return not (self.allocated == 0)
end

function guild:GetAllocBonus()
    return self.alloc_bonus
end

function guild:GetGuildTier(score)
    local tier
    for k, v in ipairs(constants["GUILDWAR_SCORE_TIER_MAP"]) do 
        tier = k
        if score >= v then 
           break
        end
    end

    return tier
end

function guild:GetMyGuildTier()
    return self:GetGuildTier(self:GetScore())
end

function guild:GetTroopMercenaryNum()
    return #self.mercenary_list
end

function guild:GetMercenaryList()
    return self.mercenary_list
end

--查询公会战结果
function guild:QueryWarResult()
    if not self:IsEnterForCurrentWar() then
        return
    end

    if not self.has_query_war_result and time_logic:Now() > self.query_war_result_time then
        self.query_war_result_time = time_logic:Now() + 1.5
        network:Send({query_guild_war_result = {}})
    end
end

function guild:QueryBattleRecord(user_id)
    if self.battle_records_map[user_id] then
        self.cur_battle_record = self.battle_records_map[user_id]
        graphic:DispatchEvent("show_world_sub_panel", "guild.battle_replay_msgbox", user_id)
    else
        network:Send({query_guild_war_record = { user_id = user_id }})
    end
end

function guild:GetCurBattleRecords()
    return self.cur_battle_record
end

function guild:GetSingleBattleRecord(index)
    return self.cur_battle_record[index]
end

function guild:GetWarMemberList()
    return self.war_member_list  
end

function guild:GetVsTroopNum(index)
    local num = 0
    if self.vs_troop_nums and self.vs_troop_nums[index] then 
        num = self.vs_troop_nums[index]
    end

    return num
end

function guild:GetRemainTroopNum(index)
    local num = 0
    if self.remain_troop_nums and self.remain_troop_nums[index] then 
        num = self.remain_troop_nums[index]
    end

    return num
end

function guild:GetVsRemainTroopNum(index)
    local num = 0
    if self.vs_remain_troop_nums and self.vs_remain_troop_nums[index] then 
        num = self.vs_remain_troop_nums[index]
    end

    return num
end

function guild:HandleGuildInfo(info)
    for k, v in pairs(info) do
        self[k] = v
    end

    --不需要主动发送查询对手的协议
    if self.rival_info then
        self.has_query_rival = true
    end

    self:InitMemberList()
    self:UpdateFieldData()
    self:InitNoticeList()
end

function guild:GetMemberTroopInfo(user_id)
    return self.member_troop_info[user_id]
end

function guild:GetRivalInfo()
    return self.rival_info
end

function guild:BuyBuff(user_id, buff_type)
    local member = self:GetMemberByUserid(user_id)
    if not member then
        return
    end

    if self.cur_status >= CLIENT_GUILDWAR_STATUS["MATCHING"] then 
        graphic:DispatchEvent("show_prompt_panel", "guild_war_buff_wrong_status")
        return
    end

    --已经购买过
    if bit_extension:GetBitNum(member.buff_info, buff_type-1) == 1 then
        graphic:DispatchEvent("show_prompt_panel", "guild_war_buff_already_bought")
        return
    end

    --检测权限
    if user_id ~= self.user_id and not self:CheckPermission("buy_buff") then
        return
    end

    local bd_num = constants.GUILDWAR_BUFF_COST[buff_type]
    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], bd_num, true) then
        return
    end

    network:Send({buy_guild_member_buff = {user_id = user_id, buff_type = buff_type} })
end

function guild:QueryExchangeConfig()
    if self.has_query_reward_config then
        graphic:DispatchEvent("show_world_sub_panel", "guild.exchange_reward_msgbox")

    else
        network:Send({ query_guild_war_reward_config = {} })
    end
end

function guild:GetExchangeRewardConifg()
    return self.exchange_reward_config
end

function guild:GetWarFieldResult(index)
    local result = 0
    if self.field_status and self.field_status[index] then 
       result = self.field_status[index] 
    end
    return result
end

function guild:ExchangeReward(id, exchange_num)
    network:Send({ exchange_guild_war_reward = { reward_id = id, exchange_num = exchange_num or 1} })
end

function guild:QueryGuildRank()
    if not self.has_query_guild_rank then
        network:Send({ query_rank_list = {} }) 
    else
        graphic:DispatchEvent("show_world_sub_panel", "guild.ranklist_panel")
    end
end

function guild:GetRankList()
    return self.guild_ranklist
end

---------------------------------   公会boss  INFO SYY --------------------------------------------
--公会boss信息功能开关是否打开
function guild:IsOpenGuildBoss()
    return feature_config:IsFeatureOpen("guild_boss")
end

--请求公会boss信息包括排行等
function guild:QueryGuildBossInfo()
    if self:IsOpenGuildBoss() then
        network:Send({ query_guild_boss_info = {} }) 
    end
end

function guild:QueryGuildBossExchangeReard()
    if self:IsOpenGuildBoss() then
        network:Send({ query_guild_boss_exchange_reward_info = {} })
    end 
end

function guild:BossRest()
    if not self.is_rest_boss then
        self.is_rest_boss = true
        self.guild_boss_ranklist = nil
        self.guild_cur_boss_id = nil
        self:QueryGuildBossInfo()
    end
end

function guild:BuyTicketCost(num)
    if self.guild_boss_cost_list_config == nil then
        self.guild_boss_cost_list_config = config_manager.guild_boss_cost_list_config
    end
    local cost = 0
    local start_index = self.guild_boss_buy_count + 1 or 1
    local end_index = self.guild_boss_buy_count + num
    for i=start_index,end_index do
        if self.guild_boss_cost_list_config[i] then
            cost = cost + self.guild_boss_cost_list_config[i].blood_diamond
        end
    end
    
    return cost
end

function guild:GetBuyTicketMax()
    if self.guild_boss_cost_list_config == nil then
        self.guild_boss_cost_list_config = config_manager.guild_boss_cost_list_config
    end
    local now_count = self.guild_boss_buy_count or 0
    local max = math.max(#self.guild_boss_cost_list_config - now_count,0)
    return max
end

function guild:GetBossRankList()
    if self:IsOpenGuildBoss() then
        if self.guild_boss_ranklist == nil or time_logic:Now() - self.query_guild_boss_rank_time >= 60 then
            self.query_guild_boss_rank_time = time_logic:Now()
            network:Send({ query_guild_boss_rank = {} }) 
        end
    end

    return self.guild_boss_ranklist or {}
end

--公会boss列表
function guild:GetGuildBossList()
    
    if self.guild_boss_list == nil then
        self.guild_boss_list = config_manager.guild_boss_info_list_config
    end
    return self.guild_boss_list or {}
end

function guild:GetGuildBossExchangeRewardInfo()
    if self.guild_boss_exchange_reward_info == nil then
        self:QueryGuildBossExchangeReard()
    end

    return self.guild_boss_exchange_reward_info 
end

function guild:GetGuildBossRewardStateList()
    return self.guild_boss_reward_state_list or {}
end

function guild:GetNowCurRewardList()
    local index = 1
    if self.can_give_reward_index and self.can_give_reward_index >= 3 then
        index = 2
    end 
    return self.guild_boss_cur_reward_list[index].reward_list or {} 
end

function guild:GetNeedCostString()
    local all_tick = resource_logic:GetResourceNum(RESOURCE_TYPE["guild_boss_ticket"])
    return all_tick.."/"..constants["GUILD_BOSS_FRIGHT_CONSUME"], all_tick, constants["GUILD_BOSS_FRIGHT_CONSUME"]
end

--攻击boss的状态 0正常状态，1正在发起攻击，2是正在战斗中
function guild:GetFrightBossState()
    return self.fight_boss_state or 0
end


--请求兑换  good_id 要兑换的id,exchange_num 兑换的数量
function guild:GuildBossExchangeReward(good_id,exchange_num)
    network:Send({ guild_boss_exchange_reward = {good_id = good_id, exchange_num = exchange_num} }) 
end

--攻击boss
function guild:GuildBossChallenge(boss_id)
    self.fight_boss_state = FRIGHT_STATE.began_fright
    network:Send({ guild_boss_challenge = {boss_id = boss_id} })    
end

--购买进入门票（为啥要叫门票。。这个别问程序，策划说的）
function guild:GuildBossBuyTicket(buy_count)
    network:Send({ guild_boss_buy_ticket = {count = buy_count} })    
end

--领取奖励
function guild:GuildBossReward(boss_id)
    network:Send({ guild_boss_reward = {boss_id = boss_id} })
end

--重置奖励兑换列表
function guild:RestExchangeRewardInfo()
    if self.guild_boss_exchange_reward_info ~= nil then
        for k,v in pairs(self.guild_boss_exchange_reward_info) do
            v.count = 0
        end
    end
end

function guild:IsShowBossRemid()
    if self.guild_cur_boss_id == 1 and not self.guild_boss_over then
        return true
    end
    if self.guild_cur_boss_id ~= nil then
        local reward_list = self:GetGuildBossRewardStateList()
        if #reward_list < self.guild_cur_boss_id-1 then
            return true
        end
    else
        self:QueryGuildBossInfo()
    end

    return false
end



---------------------------------   公会boss --------------------------------------------

function guild:AllocBonus( alloc_list )
    network:Send({guild_alloc_bonus = { alloc_list = alloc_list }})
end


--注册服务端回调
function guild:RegisterMsgHandler()
    network:RegisterEvent("query_guild_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.war_season_info = {}
            self:HandleGuildInfo(recv_msg.guild_info)
        end
    end)
    
    network:RegisterEvent("query_guild_season_config_ret", function(recv_msg)
        if recv_msg.result == "success" then

            season_config_list = recv_msg.season_config_list or {}
            season_key_map = {}
            for index, season_conf in ipairs(season_config_list) do
                season_key_map[season_conf.season_key] = index
            end

            self.cur_status, self.cur_season_conf = self:GetSeasonConfByCurTime()
        end
    end)
    
    --创建公会反馈
    network:RegisterEvent("create_guild_ret", function (recv_msg)
        if recv_msg.result == "success" then
            self:HandleGuildInfo(recv_msg.guild_info)
            self.war_season_info = {}
            self.read_notice_time = time_logic:Now()
            self.is_notice_notify = false

            self.guild_cur_boss_id = nil 
            self.guild_boss_ranklist = nil
            self.guild_boss_exchange_reward_info = nil

            self:SaveGuildSetting()
           
            graphic:DispatchEvent("join_guild", true)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)
    
    --需要显示公会信息 
    network:RegisterEvent("get_guild_list_ret", function (recv_msg)
        graphic:DispatchEvent("get_guild_list_result", recv_msg)
    end)    

    -- 搜索公会反馈
    network:RegisterEvent("search_guild_ret", function (recv_msg)
        graphic:DispatchEvent("search_guild_result", recv_msg)
    end)

    -- 加入公会反馈
    network:RegisterEvent("join_guild_ret", function (recv_msg)
        if recv_msg.result == "success" then
            self:HandleGuildInfo(recv_msg.guild_info)
            
            self.read_notice_time = time_logic:Now()
            self.is_notice_notify = false

            self.guild_cur_boss_id = nil 
            self.guild_boss_ranklist = nil
            self.guild_boss_exchange_reward_info = nil

            self:SaveGuildSetting()
            
            graphic:DispatchEvent("join_guild", false)
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    -- 退出公会处理
    local exit_guild_callback = function (recv_msg)
        if recv_msg.result == "success" then
            self:Clear()
            graphic:DispatchEvent("exit_guild")

        elseif recv_msg.result == "member_is_in_warfield" then
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)

        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end

    --退出公会反馈
    network:RegisterEvent("exit_guild_ret", exit_guild_callback)
    --解散公会反馈
    network:RegisterEvent("dismiss_guild_ret", exit_guild_callback)

    network:RegisterEvent("fire_guild_member_ret", function (recv_msg)
        if recv_msg.result ~= "success" then
            if recv_msg.result == "member_is_in_warfield" then
                graphic:DispatchEvent("show_prompt_panel", "guild_war_member_in_warfield")
            else
                graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            end
        end
    end)

    network:RegisterEvent("transfer_guild_ret", function (recv_msg)
        if recv_msg.result ~= "success" then
            if recv_msg.result == "has_no_permission" then
                graphic:DispatchEvent("show_prompt_panel", "guild_has_no_permission")
            else
                graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
            end
        end
    end)

    --更新会员数据
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

        if recv_msg.add_member_list then
            --添加会员
            for _, new_member in pairs(recv_msg.add_member_list) do
                table.insert(new_member_list, new_member)
            end
        end

        self.member_list = new_member_list

        --刷新公会成员界面
        self:InitMemberList()
        self:UpdateFieldData()
        graphic:DispatchEvent("update_guild_member")
    end)

    --更新通知
    network:RegisterEvent("update_notice_new", function(recv_msg)
        local list = recv_msg.add_notice_list
        self.notice_list = self.notice_list or {}
        self.notice_unread_num = self.notice_unread_num or 0
        for k, v in pairs(list) do
            --如果收到了解散公会的通知,就清空本地数据
            if v.notice_type == constants.GUILD_NOTICE.notice_dismiss then
                self:Clear()
                --troop_logic:ResetFormation(constants["GUILD_WAR_TROOP_ID"])
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

    network:RegisterEvent("guild_appoint_member_ret",function (recv_msg)
        if recv_msg.result == "success" then
            if recv_msg.grade_type == GUILD_GRADE["highstaff"] then 
                graphic:DispatchEvent("show_prompt_panel", "guild_appoint_high")

            elseif recv_msg.grade_type == GUILD_GRADE["staff"] then 
                graphic:DispatchEvent("show_prompt_panel", "guild_appoint_low")
            end

            local member = self:GetMemberByUserid(recv_msg.member_user_id)
            if member then
                member.grade_type = recv_msg.grade_type
                graphic:DispatchEvent("update_guild_member_grade")
                if self.own_member_info.war_field > NO_WAR_FIELD then 
                   graphic:DispatchEvent("guildwar_formation_refresh", recv_msg.member_user_id, self.own_member_info.war_field, self.own_member_info.war_field)
                end
            end
        end
    end)

    network:RegisterEvent("guild_enter_for_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.war_season_info = recv_msg.war_season_info
            self:ClearMemberWarField()
 
            graphic:DispatchEvent("guildwar_enlist_refresh")
            graphic:DispatchEvent("show_prompt_panel", "guild_war_enterfor_success")

        elseif recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "guild_war_enterfor_is_out_of_date")

        elseif recv_msg.result == "has_no_permission" then
            graphic:DispatchEvent("show_prompt_panel", "guild_has_no_permission")
        end
        graphic:DispatchEvent("show_world_sub_scene", "guildwar_sub_scene")
    end)

    network:RegisterEvent("guild_update_warfield_ret", function(recv_msg)
        if recv_msg.result == "success" then 
            local member

            if recv_msg.user_id == self.user_id then 
                if recv_msg.war_field == NO_WAR_FIELD then 
                    graphic:DispatchEvent("show_prompt_panel", "guild_war_exit_warfield")
                end

                member = self.own_member_info

            else
                member = self:GetMemberByUserid(recv_msg.user_id)
            end

            local new_field, old_field = recv_msg.war_field, member.war_field
            member.war_field = recv_msg.war_field      

            for i = 1, #self.warfield_member[old_field] do
                if self.warfield_member[old_field][i].user_id == recv_msg.user_id then
                    table.remove(self.warfield_member[old_field], i)
                    break
                end
            end

            table.insert(self.warfield_member[new_field], member)
            graphic:DispatchEvent("guildwar_formation_refresh", recv_msg.user_id, new_field, old_field)

        elseif recv_msg.result == "has_no_permission" then
            graphic:DispatchEvent("show_prompt_panel", "guild_has_no_permission")
        end
    end)

    network:RegisterEvent("query_guild_war_result_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.has_query_war_result = true
            self.has_query_guild_rank = false
            self.battle_records_map = {}
                
            self.rival_info = recv_msg.rival_info
            graphic:DispatchEvent("refresh_war_rival_info")

            local war_result = recv_msg.war_result
            if war_result then
                self.field_status = {}
                for i, guild_id in ipairs(war_result.win_guild_id_list) do
                    --获取每个据点的胜负关系
                    if guild_id == "" then
                        self.field_status[i] = BATTLE_STATUS["draw"]
                    elseif guild_id == self.guild_id and war_result.self_mirror_win_list[i] == 0 then
                        self.field_status[i] = BATTLE_STATUS["win"]
                    else
                        self.field_status[i] = BATTLE_STATUS["lose"]
                    end
                end

                --war_member_list 可能为空，所有据点均未发生战斗
                self.war_member_list = war_result.war_member_list
                
                --本方及对战方各据点出战及剩余人员数量
                self.vs_troop_nums = war_result.vs_troop_nums
                self.remain_troop_nums = war_result.remain_troop_nums
                self.vs_remain_troop_nums = war_result.vs_remain_troop_nums

                --原、新公会积分
                self.war_score = war_result.war_score
                self.old_war_score = war_result.old_war_score
            end
        end
    end)

    network:RegisterEvent("query_guild_war_record_ret", function(recv_msg)
        if recv_msg.result == "success" then
            if not recv_msg.record_list then
                return
            end
            self.cur_battle_record = recv_msg.record_list
            self.cur_battle_record.user_id = recv_msg.user_id

            if self.war_member_list then
                for _,member in pairs(self.war_member_list) do
                    if member.user_id == recv_msg.user_id then
                        self.cur_battle_record.leader_name = member.leader_name
                        self.cur_battle_record.win_num = member.win_num
                        break
                    end
                end
            end

            self.battle_records_map[recv_msg.user_id] = self.cur_battle_record
            graphic:DispatchEvent("show_world_sub_panel", "guild.battle_replay_msgbox", recv_msg.user_id)

        elseif recv_msg.result == "failure" then

        end
    end)

    network:RegisterEvent("query_guild_member_troop_ret", function(recv_msg)
        if not recv_msg.user_id or recv_msg.result == "failure" then
            graphic:DispatchEvent("show_prompt_panel", "social_cant_view_troop")
            return
        end

        local troop_info = {}
        for k, v in pairs(recv_msg) do
            troop_info[k] = v
        end

        self.member_troop_info[recv_msg.user_id] = troop_info
        local member = self:GetMemberByUserid(recv_msg.user_id)
        troop_info.name = member.leader_name

        social_logic:GenerateTroopInfo(troop_info)
        --计算据点加成
        if member.war_field ~= NO_WAR_FIELD then
            local mercenary_num = #troop_info.template_id_list
            --特权数量
            local evo_num = 0
            local cur_genre = self.cur_season_conf["bonus_genre"][member.war_field]

            for i = 1, mercenary_num do
                local template_info = config_manager.mercenary_config[troop_info.template_id_list[i]]

                if template_info.genre == cur_genre then
                    evo_num = evo_num + 1
                end
            end

            troop_info.battle_point = math.ceil(troop_info.battle_point + (troop_info.battle_point / mercenary_num) * evo_num * self.cur_season_conf["bonus_factor"][member.war_field] / 100)
        end

        --计算buff加成
        for i = 1, 5 do
            self:CalcMemberBuffInfo(member, troop_info, i)
        end

        if recv_msg.reason == client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"]["view"] then
            local SOCIAL_SHOW_TYPE = client_constants["SOCIAL_EVENT_SHOW_TYPE"]["guild_member"]
            graphic:DispatchEvent("show_world_sub_panel", "social_event_panel", recv_msg.user_id, SOCIAL_SHOW_TYPE)

        elseif recv_msg.reason == client_constants["VIEW_GUILD_MEMBER_TROOP_MODE"]["buy_buff"] then
            graphic:DispatchEvent("show_world_sub_panel", "guild.arm_msgbox", recv_msg.user_id)
        end
    end)

    network:RegisterEvent("buy_guild_member_buff_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local member = self:GetMemberByUserid(recv_msg.user_id)
            if not member then
                return
            end

            member.buff_info = bit_extension:SetBitNum(member.buff_info, recv_msg.buff_type-1, true)
            self:CalcMemberBuffNum(member)
            self:CalcMemberBuffInfo(member, self.member_troop_info[recv_msg.user_id], recv_msg.buff_type)

            graphic:DispatchEvent("update_guild_member_buff", recv_msg.user_id, member)

        elseif result == "has_no_permission" then
            graphic:DispatchEvent("show_prompt_panel", "guild_has_no_permission")
        end
    end)

    network:RegisterEvent("query_guild_war_reward_config_ret", function(recv_msg)
        self.has_query_reward_config = true

        self.exchange_reward_config = recv_msg.reward_list

        local my_guild_tier = self:GetMyGuildTier()
        --排序规则：按照奖励兑换需要的公会段位，"需要段位"大于等于"当前段位"的:根据"需要段位"从小到大，"需要段位"小于"当前段位"的:根据"需要段位"从大到小
        local channel = platform_manager:GetChannelInfo()

        if not channel.not_need_sort then
            --东南亚要求不用排序根据策划表显示
            table.sort(self.exchange_reward_config, function(a, b)
                                                        if a.need_tier < my_guild_tier and b.need_tier >= my_guild_tier then
                                                            return false
                                                        elseif b.need_tier < my_guild_tier and a.need_tier >= my_guild_tier then
                                                            return true
                                                        elseif a.need_tier < my_guild_tier then
                                                            return a.need_tier > b.need_tier
                                                        else
                                                            return a.need_tier < b.need_tier
                                                        end
                                                    end)
        end

        graphic:DispatchEvent("show_world_sub_panel", "guild.exchange_reward_msgbox")
    end)

    network:RegisterEvent("exchange_guild_war_reward_ret", function(recv_msg)
        if recv_msg.result == "success" then
            for _,reward_config in pairs(self.exchange_reward_config) do
                if reward_config.id == recv_msg.reward_id then
                    reward_config.count = reward_config.count + recv_msg.exchange_num
                    break
                end
            end

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("update_guild_exchange_count", recv_msg.reward_id)
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("query_rank_list_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.has_query_guild_rank = true
            self.guild_ranklist = recv_msg.rank_list
        end

        graphic:DispatchEvent("show_world_sub_panel", "guild.ranklist_panel")
    end)
    
    network:RegisterEvent("update_alloc_bonus_ret", function(recv_msg)
        self.alloc_bonus = recv_msg.alloc_bonus
        self.allocated = recv_msg.allocated

        for i,member_info in pairs(self.member_list) do
            member_info.alloc_num = 0

            if recv_msg.alloc_list then
                for _,alloc_item in pairs(recv_msg.alloc_list) do
                    if alloc_item.user_id == member_info.user_id then
                        member_info.alloc_num = alloc_item.alloc_num
                        break
                    end
                end
            end
        end

        graphic:DispatchEvent("update_guild_alloc_bonus")
    end)

    network:RegisterEvent("guild_alloc_bonus_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("update_guild_alloc_info")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("update_war_settlement_ret", function(recv_msg)
        if recv_msg.settlement_info_list then
            for i,settlement_info in ipairs(recv_msg.settlement_info_list) do
                local member_info = self:GetMemberByUserid(settlement_info.user_id)
                if member_info then
                    member_info.battle_num = settlement_info.battle_num
                    member_info.win_num = settlement_info.win_num 
                    member_info.season_score = settlement_info.season_score
                    member_info.battle_round = settlement_info.battle_round
                end
            end
        end
    end)

    --公会boss网络服务
    --公会boss信息返回
    network:RegisterEvent("query_guild_boss_info_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.guild_kill_boss_count = recv_msg.kill_boss_count
            self.guild_cur_boss_hp = recv_msg.cur_boss_hp
            self.guild_all_boss_hp = recv_msg.cur_boss_hp
            self.guild_cur_boss_id = recv_msg.boss_id or 1
            self.guild_boss_reset_time = recv_msg.boss_reset_time
            self.guild_boss_buy_count = recv_msg.buy_count
            self.guild_boss_reward_state_list  = recv_msg.reward_state_list or {}
            self.guild_boss_cur_reward_list = recv_msg.chests_list
            self.can_give_reward_index = recv_msg.attack_count 
            self.sum_boss_hp = recv_msg.sum_boss_hp
            if self.is_rest_boss then
                self.is_rest_boss = false
                self:RestExchangeRewardInfo()
                graphic:DispatchEvent("guild_boss_info_rest")
            end
            
            --判断返回过来的时间是否已经结束
            local times = self.guild_boss_reset_time - time_logic:Now()
            if times <= 0 then
                self.guild_boss_over = true
            else
                self.guild_boss_over = false
            end

            if self.query_boss_info then
                --请求了boss
                self.query_boss_info = false
                graphic:DispatchEvent("show_world_sub_scene", "guild_boss_sub_scene")
            end
            graphic:DispatchEvent("guild_boss_info_update")
        end
    end)

    --请求公会boss排行返回
    network:RegisterEvent("query_guild_boss_rank_ret", function(recv_msg)
        if recv_msg.rank_list then
            self.guild_boss_ranklist = recv_msg.rank_list
            graphic:DispatchEvent("guild_ranking_refsh")
        end
    end)

    --公会boss兑换奖励列表返回
    network:RegisterEvent("query_guild_boss_exchange_reward_info_ret", function(recv_msg)
        if recv_msg.reward_list then
            self.guild_boss_exchange_reward_info = recv_msg.reward_list
            graphic:DispatchEvent("show_world_sub_panel", "guild.boss_exchange_reward_msgbox")
        end
    end)

    --公会boss兑换奖励返回
    network:RegisterEvent("guild_boss_exchange_reward_ret", function(recv_msg)
        if recv_msg.result == "success" then
            for k,v in pairs(self.guild_boss_exchange_reward_info) do
                if v.good_id == recv_msg.good_id then
                    v.count = recv_msg.cur_exchange_count
                    break
                end
            end
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("update_guild_boss_exchange_count", recv_msg.good_id)
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)


    --公会boss血量更新
    network:RegisterEvent("guild_boss_update_ret", function(recv_msg)
        if recv_msg.cur_boss_bp and self.guild_cur_boss_id ~= nil and self.guild_cur_boss_id ~= 0 then
            self.guild_cur_boss_hp = recv_msg.cur_boss_bp
            if recv_msg.boss_id ~= self.guild_cur_boss_id then
                self.sum_boss_hp = recv_msg.cur_boss_bp
                self.guild_cur_boss_id = recv_msg.boss_id
                graphic:DispatchEvent("boss_change_refsh")
            end
            graphic:DispatchEvent("boss_hp_refsh")
        end
    end)
    
    --挑战boss结果返回
    network:RegisterEvent("guild_boss_challenge_ret", function(recv_msg)
        if recv_msg.result == "success" then
            
            local is_winner = false
            if recv_msg.boss_bp <= 0 then 
                is_winner = true
            else
                self.guild_cur_boss_hp = recv_msg.boss_bp
            end
            self.can_give_reward_index = recv_msg.attack_count
            local battle_type = client_constants.BATTLE_TYPE["vs_guild_boss"]
            local boss_list = self:GetGuildBossList()
            local boss_info = boss_list[recv_msg.boss_id]
            self.fight_boss_state = FRIGHT_STATE.start_fright
            local close_reward_call = function ()
                self.fight_boss_state = FRIGHT_STATE.normal
                if is_winner then
                    graphic:DispatchEvent("boss_deid_refsh")
                else
                    graphic:DispatchEvent("boss_hp_refsh")
                end
            end
            graphic:DispatchEvent("show_battle_room", battle_type, boss_info.master_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                 graphic:DispatchEvent("show_world_sub_panel", "reward_panel",close_reward_call)
            end) 
        else
            self.fight_boss_state = FRIGHT_STATE.normal
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --公会boss门票购买结果
    network:RegisterEvent("guild_boss_buy_ticket_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.guild_boss_buy_count = recv_msg.buy_count
        elseif recv_msg.result == "not_enough_resource" then
            graphic:DispatchEvent("show_prompt_panel", "resource_general_not_enough")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --公会boss宝箱领取结果
    network:RegisterEvent("guild_boss_reward_ret", function(recv_msg)
        if recv_msg.result == "success" then
            table.insert(self.guild_boss_reward_state_list,recv_msg.boss_id)
            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("boss_hp_refsh")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    

    

end

return guild
