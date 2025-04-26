local config_manager = require "logic.config_manager"
local network = require "util.network"
local bit = require "bit"
local platform_manager = require "logic.platform_manager"
local graphic = require "logic.graphic"
local analytics_manager = require "logic.analytics_manager"

local bit_band = bit.band
local bit_bor = bit.bor
local bit_lshift = bit.lshift

local user_logic
local troop_logic
local resource_logic
local bag_logic
local time_logic
local achievement_logic
local carnival_logic
local vip_logic
local sns_logic

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local MINING_EVENT_TYPE_ID = constants["MINING_EVENT_TYPE_ID"]
local BOX_STATUS = constants["EXPLORE_BOX_TYPE"]

local MAZE_EVENT_STATUS = client_constants.ADVENTURE_MAZE_EVENT_STATUS
local MAX_UPDATE_EXP_COIN_TIME = 1

local adventure = {}

function adventure:Init()
    user_logic = require "logic.user"
    troop_logic = require "logic.troop"

    resource_logic = require "logic.resource"
    bag_logic = require "logic.bag"

    time_logic = require "logic.time"
    achievement_logic = require "logic.achievement"
    carnival_logic = require "logic.carnival"
    vip_logic = require "logic.vip"
    sns_logic = require "logic.sns"

    self.cur_maze_id = 0
    self.maze_list = {}
    self.event_cd_list = {}
    self.event_fail_time_list = {}
    self.area_list = {}

    --增加到1 时，增加经验，金钱，饱食度-1
    self.update_exp_coin_time = 0

    --迷宫中事件的状态
    self.maze_event_status = 0

    --记录进入冒险探索场景的来源
    self.can_enter_next_area = false
    self.can_enter_next_maze = false
    self.next_maze_id = 0

    self:RegisterMsgHandler()
end

function adventure:Update(elapsed_time)
    self.update_exp_coin_time = self.update_exp_coin_time + elapsed_time

    --增加金钱和经验
    if self.update_exp_coin_time >= MAX_UPDATE_EXP_COIN_TIME then
        local n = math.floor(self.update_exp_coin_time / MAX_UPDATE_EXP_COIN_TIME)
        self.update_exp_coin_time = self.update_exp_coin_time - n * MAX_UPDATE_EXP_COIN_TIME

        resource_logic:IncreaseGoldCoinAndExp(self.income_info["gold_coin"] * n, self.income_info["exp"] * n)
        graphic:DispatchEvent("update_resource_list")
    end

    --探索事件
    if self.maze_event_status == MAZE_EVENT_STATUS["is_exploring"] then
        local cur_time = self.cur_maze_info.event_time + elapsed_time
        local event_need_time = self.cur_maze_template_info.event_time

        self.cur_maze_info.event_time = cur_time

        graphic:DispatchEvent("update_explore_event_progress", self.cur_maze_template_info.event_id, cur_time, event_need_time)

        --探索到新事件
        if cur_time >= event_need_time then
            self.maze_event_status = MAZE_EVENT_STATUS["explored_but_not_solve"]
        end
    end

    local n = 0

    --探索宝箱
    if self.explored_box_num < self.max_box_num then
        self.explored_box_time = self.explored_box_time + elapsed_time

        local vip_info = vip_logic:GetVipInfo(constants.VIP_TYPE["adventure"])

        if self.cur_maze_info["first_box_status"] == BOX_STATUS["never_get"] then
            local box_need_time = self.cur_maze_template_info["box_time1"]

            if vip_info and vip_info.reward_mark > 0 then
                box_need_time = box_need_time * constants.VIP_PRIVILEGE["box_time"]
            end

            if self.explored_box_time >= box_need_time then
                self.cur_maze_info["first_box_status"] = BOX_STATUS["already_get"]
                self.explored_box_time = self.explored_box_time - box_need_time

                self.explored_box_num = 1
                n = 1
            end

            self.cur_maze_info["box_time"] = self.explored_box_time
            self.cur_maze_info["box_num"]  = self.explored_box_num

        else
            local box_need_time = self.cur_maze_template_info["box_time2"]

            if vip_info and vip_info.reward_mark > 0  then
                box_need_time = box_need_time * constants.VIP_PRIVILEGE["box_time"]
            end

            n = math.floor(self.explored_box_time / box_need_time)
            self.explored_box_time = self.explored_box_time - n * box_need_time
            self.explored_box_num = math.min(self.explored_box_num + n, self.max_box_num)

            self.cur_maze_info["box_time"] = self.explored_box_time
            self.cur_maze_info["box_num"]  = self.explored_box_num

            if self.explored_box_num == self.max_box_num then
                self.explored_box_time = 0
            end
        end
    end
end

function adventure:IsAdventureEvent(event_id)
    return self.cur_maze_template_info.event_id == event_id
end

function adventure:IsEventInCD(event_id)
    --cd未到
    local event_cd = self.event_cd_list[event_id]
    if event_cd and event_cd > time_logic:Now() then
        graphic:DispatchEvent("show_prompt_panel", "adventure_event_is_in_cd", event_cd - time_logic:Now())
        return true
    end

    return false
end

function adventure:GetCurEventCD()
    local event_cd = self.event_cd_list[self.cur_maze_template_info.event_id]
    if event_cd and event_cd ~= 0 then
        return event_cd - time_logic:Now()
    else
        return 0
    end
end

function adventure:CheckEventResetMark()
    local cur_time = time_logic:Now()
    local t = time_logic:GetDateInfo(cur_time)

    local check_hour = 0

    if t.hour < constants.CHECKIN_TIME["first"] then
        mark = 0
        check_hour = constants.CHECKIN_TIME["first"]

    elseif t.hour < constants.CHECKIN_TIME["second"] then
        mark = 1
        check_hour = constants.CHECKIN_TIME["second"]
    else
        mark = 2
        check_hour = constants.CHECKIN_TIME["third"]
    end

    local remain_time = (check_hour - t.hour) * 3600 - t.min * 60 - t.sec

    local need_reset = false
    if bit_band(self.event_reset_mark, bit_lshift(1, mark)) == 0 then
        need_reset = true
    end

    if not need_reset then
        return remain_time
    end

    self.event_reset_mark = bit_lshift(1, mark)

    local event_fail_time_list = self.event_fail_time_list
    for event_id in pairs(event_fail_time_list) do
        event_fail_time_list[event_id] = 0
    end

    return remain_time
end

function adventure:CheckEventCost(event_id)
    local event_conf = config_manager.event_config[event_id]
    local need_num_iter = string.gmatch(event_conf.need_num, "(%d+)")

    local fail_time = self.event_fail_time_list[event_id] or 0

    for resource_type in string.gmatch(event_conf.need_resource_id, "(%d+)") do
        local need_num = need_num_iter()

        if need_num then
            resource_type = tonumber(resource_type)
            need_num = tonumber(need_num) * math.pow(2, fail_time)

            if not resource_logic:CheckResourceNum(resource_type, tonumber(need_num), true) then
                return false
            end
        end
    end

    return true
end

--解决事件
function adventure:SolveEvent(event_id)
    local is_adventure_event = self:IsAdventureEvent(event_id)

    if not is_adventure_event then
        graphic:DispatchEvent("show_prompt_panel", "adventure_event_not_exist")
        return false
    end

    --检测背包
    if bag_logic:GetSpaceCount() < constants["EVENT_MAX_BAG_SPACE_COUNT"] then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return false
    end

    if self:IsEventInCD(event_id) then
        return false
    end

    if not self:CheckEventCost(event_id) then
        return false
    end

    --已经完成过事件不需要发送
    if self.maze_event_status == MAZE_EVENT_STATUS["explored_but_not_solve"] then
        local event_config = config_manager.event_config[event_id]
        network:Send({ solve_adventure_event = { event_id = event_id } })

    elseif self.maze_event_status == MAZE_EVENT_STATUS["solved"] then
        graphic:DispatchEvent("show_prompt_panel", "adventure_event_already_solved")

    elseif self.maze_event_status == MAZE_EVENT_STATUS["is_exploring"] then
        graphic:DispatchEvent("show_prompt_panel", "adventure_event_is_exploring")

    elseif self.maze_event_status == MAZE_EVENT_STATUS["not_start_explore"] then
        graphic:DispatchEvent("show_prompt_panel", "adventure_event_not_start_explore")
    end

    return true
end

function adventure:GetBoxRemainTime()
    local vip_info = vip_logic:GetVipInfo(constants["VIP_TYPE"]["adventure"])
    local box_need_time = 0
    if self.cur_maze_info["first_box_status"] == BOX_STATUS["never_get"] then

        box_need_time = self.cur_maze_template_info["box_time1"]
        if vip_info.reward_mark > 0 then
            box_need_time = box_need_time * 0.75
        end
        return box_need_time - self.explored_box_time, box_need_time

    elseif self.explored_box_num == self.max_box_num then
        return 0, 1

    else
        box_need_time = self.cur_maze_template_info["box_time2"]
        if vip_info.reward_mark > 0 then
            box_need_time = box_need_time * 0.75
        end

        return box_need_time - self.explored_box_time, box_need_time
    end
end

function adventure:SetMaxBoxNum(num)
    self.max_box_num = num
end

function adventure:IsAreaUnlocked(area_id)
    local area_info = self.area_list[area_id]
    return string.byte(area_info) ~= 0
end

function adventure:IsDifficultyUnlocked(area_id, difficulty)
    local area_info = string.byte(self.area_list[area_id])
    return bit_band(area_info, bit_lshift(1, difficulty-1)) ~= 0
end

function adventure:ParseAreaInfo(area_list_str)
    local len = #area_list_str
    for i = 1, constants["MAX_AREA_NUM"] do
        self.area_list[i] = i <= len and string.sub(area_list_str, i, i) or '\0'
    end
end

function adventure:UnlockArea(area_id, difficulty)
    if area_id < 1 or area_id > constants["MAX_AREA_NUM"] then
        assert("invalid area id")
    end

    local info = self.area_list[area_id]
    if info and info ~= "" then
        info = string.byte(info)
    else
        info = 0
    end

    --先检测是否已解锁过该难度
    local mask = bit_lshift(1, difficulty-1)
    if bit_band(info, mask) ~= 0 then
        print("repeat unlock")
    end

    info = bit_bor(info, mask)

    self.area_list[area_id] = string.char(info)
end

--开宝箱
function adventure:OpenBox()
    local bag_space_count = bag_logic:GetSpaceCount()

    if self.explored_box_num == 0 then
        graphic:DispatchEvent("show_prompt_panel", "adventure_no_box_generate")

    elseif self.explored_box_num > bag_space_count then
        graphic:DispatchEvent("show_prompt_panel", "adventure_open_box_not_enough_space")
        if bag_space_count ~= 0 then
            network:Send({ open_box = {}})
        end
    else
        network:Send({ open_box = {}})
    end
end

--玩家进入新的冒险关卡
function adventure:EnterMaze(maze_id)
    --想要进入的地图跟目前正在探索的地图是一致的
    if maze_id == self.cur_maze_id then
        return
    end

    if not self.maze_list[maze_id] then
        graphic:DispatchEvent("show_prompt_panel", "adventure_maze_is_locked")
        return
    end

    network:Send({enter_adventure_maze = { maze_id = maze_id }})
end

--事件已经解决，尝试进入下一关
function adventure:EnterNextMaze()
    if not self.can_enter_next_area and not self.can_enter_next_maze then
        return
    end

    if self.maze_list[self.next_maze_id].event_time == 0 then
        local next_maze_template_info = config_manager.adventure_maze_config[self.next_maze_id]
        local income_info = config_manager.adventure_income_config[next_maze_template_info.income_id]
        local area_info = config_manager.area_info_config[income_info.area_id]

        if income_info.difficulty == 1 and next_maze_template_info.type == 1 and area_info.bp_limit > troop_logic:GetTroopBP() then
            graphic:DispatchEvent("show_prompt_panel", "adventure_maze_bp_limit")
            return
        end
    end

    network:Send({enter_adventure_maze = { maze_id = self.next_maze_id }})
end

function adventure:InitCurrentMaze(maze_id)
    --maze 模板信息 即表格中信息
    self.cur_maze_template_info = config_manager.adventure_maze_config[maze_id]

    --maze 服务端信息 也就是maze的状态信息
    self.cur_maze_info = self.maze_list[maze_id]

    self.income_info = config_manager.adventure_income_config[self.cur_maze_template_info.income_id]

    self.explored_box_time = self.cur_maze_info["box_time"]
    self.explored_box_num = self.cur_maze_info["box_num"]

    self.maze_event_status = MAZE_EVENT_STATUS["not_start_explore"]

    local need_time = self.cur_maze_template_info["event_time"]
    local event_time = self.cur_maze_info["event_time"]

    self.cur_area_id = self.income_info.area_id
    self.cur_difficulty = self.income_info.difficulty

    if event_time >= need_time then
        if self.cur_maze_info["event_is_finish"] then
            self.maze_event_status = MAZE_EVENT_STATUS["solved"]
        else
            self.maze_event_status = MAZE_EVENT_STATUS["explored_but_not_solve"]
        end

    elseif event_time > 0 and event_time < need_time then
        self.maze_event_status = MAZE_EVENT_STATUS["is_exploring"]

    elseif event_time == 0 then
        self.maze_event_status = MAZE_EVENT_STATUS["not_start_explore"]
    end

    self:CheckNextMaze()
end

function adventure:CheckNextMaze()
    local cur_maze_type = self.cur_maze_template_info.type
    if cur_maze_type == client_constants["MAZE_TYPE"]["boss"] then
        --boss关卡结束后，总是进入下一个区域
        self.can_enter_next_area = self.cur_maze_info.event_is_finish and self.cur_area_id < constants["MAX_AREA_NUM"]
        self.can_enter_next_maze = false

        if self.can_enter_next_area then
            local maze_list_map = config_manager.area_info_config[self.cur_area_id+1]["maze_list_map"]
            local easy = constants["AREA_DIFFICULTY_LEVEL"]["easy"]
            self.next_maze_id = maze_list_map[easy][1].ID
        end
    else
        self.can_enter_next_area = false
        local maze_list_map = config_manager.area_info_config[self.cur_area_id]["maze_list_map"]

        local next_maze_id = maze_list_map[self.cur_difficulty][cur_maze_type + 1].ID
        if self.maze_list[next_maze_id] then
            self.can_enter_next_maze = true
            self.next_maze_id = next_maze_id
        else
            self.can_enter_next_maze = false
        end
    end
end

function adventure:StartExplore()
    if self.maze_event_status == MAZE_EVENT_STATUS["not_start_explore"] then
        self.maze_event_status = MAZE_EVENT_STATUS["is_exploring"]
    end
end

function adventure:UnlockMaze(maze_id, is_unlock_difficulty)
    if self.maze_list[maze_id] then
        return
    end

    local maze_info = {
        id = maze_id,
        first_box_status = BOX_STATUS["never_get"],
        event_is_finish = false,
        event_time = 0,
        box_num = 0,
        box_time = 0,
    }

    self.maze_list[maze_id] = maze_info

    if is_unlock_difficulty then
        local new_maze_template_info = config_manager.adventure_maze_config[maze_id]
        local income_info = config_manager.adventure_income_config[new_maze_template_info.income_id]
        self:UnlockArea(income_info.area_id, income_info.difficulty)
    end

    graphic:DispatchEvent("unlock_new_adventure_maze", is_unlock_difficulty)
end

function adventure:GetBattleType(event_id, is_winner)
    local battle_type = constants.BATTLE_TYPE["vs_monster"]

    if (event_id >= MINING_EVENT_TYPE_ID["golem"] and event_id < 3000000) or event_id >= MINING_EVENT_TYPE_ID["red_king"] then
        --需要区分矿区事件
        battle_type = constants.BATTLE_TYPE["vs_golem"]

        for k, v in pairs(MINING_EVENT_TYPE_ID) do
            if v == event_id and is_winner then
                battle_type = constants.BATTLE_TYPE["vs_boss"]
                local block_type = constants.BLOCK_TYPE[k]
                --FYD  增加判断，如果胜利，同时分享功能开启那么进行分享  这里是r2的分享
                if is_winner and platform_manager:GetChannelInfo().enable_sns_og_share  then
                    sns_logic:UpdateSNSInfo(constants.SNS_EVENT_TYPE["share_mining"], block_type)
                end
                break
            end
        end
    end

    return battle_type
end

function adventure:RegisterMsgHandler()
    --maze 信息列表
    network:RegisterEvent("query_adventure_maze_list_ret", function(recv_msg)
        print("query_adventure_maze_list_ret")
        for i, maze_info in ipairs(recv_msg.maze_list) do
            self.maze_list[maze_info.id] = maze_info
        end

        if recv_msg.event_cd_list then
            for i, event_cd in ipairs(recv_msg.event_cd_list) do
                self.event_cd_list[event_cd.id] = event_cd.cd_time
            end
        end

        if recv_msg.event_fail_time_list then
            for i, event in ipairs(recv_msg.event_fail_time_list) do
                self.event_fail_time_list[event.id] = event.fail_time
            end
        end

        self.cur_maze_id = recv_msg.cur_maze_id
        self.max_box_num = recv_msg.max_box_num
        self.event_reset_mark = recv_msg.event_reset_mark or 0
        self.buy_adventure_num = recv_msg.buy_adventure_num or 0

        self:ParseAreaInfo(recv_msg.area_list)
        self:InitCurrentMaze(self.cur_maze_id)
    end)

    --进入地图
    network:RegisterEvent("enter_adventure_maze_ret", function(recv_msg)
        if recv_msg.result == "success" then
            if self.maze_list[recv_msg.maze_id].event_time == 0 then
                if TalkingDataGA then
                    TDGAMission:onBegin(tostring(recv_msg.maze_id))
                end
            end

            --更新新进入的地图数据
            self.cur_maze_id = recv_msg.maze_id
            self:InitCurrentMaze(recv_msg.maze_id)

            graphic:DispatchEvent("enter_maze", self.cur_area_id, self.cur_difficulty)

        elseif recv_msg.result == "bp_limit" then
            graphic:DispatchEvent("show_prompt_panel", "adventure_maze_bp_limit")
        end
    end)

    --解决事件
    network:RegisterEvent("solve_adventure_event_ret", function(recv_msg)

        local event_id = recv_msg.event_id
        if recv_msg.result == "success" then
            if event_id == self.cur_maze_template_info.event_id then
                self.cur_maze_info["event_is_finish"] = true
                self.maze_event_status = MAZE_EVENT_STATUS["solved"]

                self:CheckNextMaze()

                --统计关卡进度
                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["maze"], self.cur_maze_id)

                --每种难度的关卡区域完成数量
                local cur_maze_conf = config_manager.adventure_maze_config[self.cur_maze_id]
                if cur_maze_conf.type == 5 then
                    local income_info = config_manager.adventure_income_config[cur_maze_conf.income_id]
                    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["maze_difficulty" .. income_info.difficulty], 1)
                end

            end

        elseif recv_msg.result == "already_solved" then
            graphic:DispatchEvent("show_prompt_panel", "adventure_event_already_solved")
            return
        elseif recv_msg.result == "not_enough_event_time" then
            graphic:DispatchEvent("show_prompt_panel", "adventure_event_is_exploring")
            return

        elseif recv_msg.result == "event_cd" then
            graphic:DispatchEvent("show_prompt_panel", "adventure_event_is_in_cd", 1)
            return
        end

        local event_config = config_manager.event_config[event_id]
        --播放战斗结果
        if event_config.event_type == constants.ADVENTURE_EVENT_TYPE["battle"] then
            if recv_msg.battle_record then
                local is_winner = recv_msg.result == "success"

                --设置失败cd
                if is_winner then
                    self.event_cd_list[event_id] = nil
                    self.event_fail_time_list[event_id] = nil

                else
                    self.event_cd_list[event_id] = event_config.fail_cd + time_logic:Now()

                    local fail_time = self.event_fail_time_list[event_id]
                    self.event_fail_time_list[event_id] = fail_time and fail_time + 1 or 1
                end

                local battle_type = client_constants.BATTLE_TYPE["vs_monster"]
                if (event_id >= MINING_EVENT_TYPE_ID["golem"] and event_id < 3000000) or event_id >= MINING_EVENT_TYPE_ID["red_king"] then
                    --需要区分矿区事件
                    battle_type = client_constants.BATTLE_TYPE["vs_golem"]
                end

                if battle_type == client_constants.BATTLE_TYPE["vs_monster"] then
                    if recv_msg.result == "success" then
                        analytics_manager:TriggerEvent("finish_fight", self.cur_maze_id)

                        if TalkingDataGA then
                            TDGAMission:onCompleted(tostring(self.cur_maze_id))
                        end
                    else
                        if TalkingDataGA then
                            TDGAMission:onFailed(tostring(self.cur_maze_id), "dead")
                        end
                    end
                end

                graphic:DispatchEvent("show_battle_room", battle_type, event_config.monster_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                    graphic:DispatchEvent("solve_event_result", event_id, is_winner, true)

                    if is_winner then
                        graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                    end
                end)
            end

        else
            graphic:DispatchEvent("solve_event_result", event_id, recv_msg.result == "success", false)
            if recv_msg.result == "success" then
                graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            end
        end

    end)

    --点开宝箱
    network:RegisterEvent("open_box_ret", function(recv_msg)
        print("open_box_ret", recv_msg.result)
        if recv_msg.open_box_num == 0 then
            return
        end

        if recv_msg.result == "success" or recv_msg.result == "bag_full" then
            if recv_msg.maze_info then
                local maze_id = self.cur_maze_id

                --标记 要对当前maze_info做一次生拷贝，否则maze_list的cur_maze_id 指向的内存空间就变了
                local maze_info = self.maze_list[maze_id]
                for k, v in pairs(recv_msg.maze_info) do
                    maze_info[k] = v
                end

                self:InitCurrentMaze(maze_id)
            end

            local is_open_box = true
            graphic:DispatchEvent("show_maze_box", is_open_box, recv_msg.open_box_num)
        else
            graphic:DispatchEvent("show_prompt_panel", "adventure_open_box_failure")
        end
    end)

    --解决事件
    network:RegisterEvent("buy_adventure_reward_ret", function(recv_msg)

        if recv_msg.result == "success" then

            self.buy_adventure_num = recv_msg.buy_adventure_num
            graphic:DispatchEvent("show_world_sub_panel", "quick_battle_reward_msgbox", recv_msg)
            graphic:DispatchEvent("refresh_quick_battle")
            
        elseif recv_msg.result == "failure" then
            -- 没有关卡信息 理论上不存在
        elseif recv_msg.result == "not_enough_blood_diamond" then
            -- 血钻不足
            local lang_constants = require "util.language_constants"
            graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("blood_diamond_not_enough"),
                lang_constants:Get("blood_diamond_not_enough_desc"),
                lang_constants:Get("common_confirm"),
                lang_constants:Get("common_cancel"),
            function()
                graphic:DispatchEvent("hide_all_sub_panel")
                graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene")
            end)
        elseif recv_msg.result == "not_enough_buy_nums" then
            -- 次数用完
            graphic:DispatchEvent("show_prompt_panel", "adventurer_buy_not_enough_nums")
        elseif recv_msg.result == "not_enough_vip" then
            -- 需要月卡才能进行购买
            graphic:DispatchEvent("show_prompt_panel", "adventurer_buy_not_enough_vip")
        end
    end)
end

---------------------------------------
----供给外部调用的函数，外部获取这些数据
---------------------------------------
function adventure:GetMazeList()
    return self.maze_list
end

function adventure:GetCurMazeInfo()
    return self.cur_maze_info, self.cur_maze_template_info
end

function adventure:IsMazeClear(maze_id)
    if not self.maze_list[maze_id] then
        return false
    end

    return self.maze_list[maze_id].event_is_finish
end

function adventure:IsMazeNew(maze_id)
    if not self.maze_list[maze_id] then
        return true
    end

    return self.maze_list[maze_id].event_time == 0
end

return adventure
