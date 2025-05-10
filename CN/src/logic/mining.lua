local network = require "util.network"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local graphic = require "logic.graphic"
local config_manager = require "logic.config_manager"

local CONST_BLOCK_TYPE = constants.BLOCK_TYPE
local RESOURCE_TYPE = constants.RESOURCE_TYPE
local BLOCK_COLLECT_TYPE = constants.BLOCK_COLLECT_TYPE
local QUARRY_BOSS_ITERATE = constants.QUARRY_BOSS_ITERATE
local MINING_BOSS_MAP = constants.MINING_BOSS_MAP
local mining_random_activity_config = config_manager.mining_random_activity_config
local common_function_util = require "util.common_function"
local adventure_logic
local time_logic
local user_logic
local achievement_logic
local bag_logic
local bit = require "bit"
local bit_lshift = bit.lshift
local troop_logic

local PROMPT_MAP =
{
    ["time_limit"] = "mining_is_digging",
    ["collect_first"] = "mining_collect_resource_first",
    ["not_enough_count"] = "mining_not_enough_dig_count",
    ["destroy_level"] = "mining_lack_destroy_level",
    ["explore_first"] = "mining_explore_first",
    ["not_enough_layer"] = "mining_lack_depth",
    ["bug"] = "mining_dig_out_of_range",
    ["refresh_time_limit"]  = "mining_cant_refresh_area",
    ["not_enough_golem_lv"] = "mining_not_enough_golem_lv"
}


local CHEST_BLOCK_MAP = constants["CHEST_BLOCK_MAP"]

local mining = {}

function mining:Init()
    user_logic = require "logic.user"
    adventure_logic = require "logic.adventure"
    time_logic = require "logic.time"
    achievement_logic = require "logic.achievement"
    bag_logic = require "logic.bag"
    troop_logic = require "logic.troop"

    self.pickaxe_id = 1

    self.dig_max_count = 15
    self.dig_count = 0

    self.dig_recover_time = 0
    self.max_recover_time = 1

    self.has_queried_block_info = false
    self.has_queried_cave_config_info = false

    self.cur_query_packet_count = 0
    self.max_query_packet_count = 0
    self.block_counts = {}
    self.block_count = 0

    --矿区结构刷新时间
    self:ResetArea()

    self.project_list = {}
    self.random_event = {}
    --矿区信息
    self.cave_config_info = {}

    self:RegisterMsgHandler()
end

function mining:ResetArea(lv)
    if not lv or lv <= 1 then 
        self.golem_lv = 1
    else 
        self.golem_lv = lv
    end

    self.refresh_time = 0
    self.golem_num = 0
    self.golem_coordinates = {}
    self.chest_coordinates = {}

    self.is_discover_golem = false
    self.block_list = {}
    self.random_event_list = {}
    self.random_event = {}
    self.boss_id = CONST_BLOCK_TYPE["golem_dark"]

    local begin_lv = MINING_BOSS_MAP[CONST_BLOCK_TYPE["seven_doom"]]
    for boss_type, lv in pairs(MINING_BOSS_MAP) do
        if self.golem_lv <= lv and begin_lv >= lv then
            begin_lv = lv
            self.boss_id = boss_type
        end
    end

    self.dig_endtime = 0
    self.cur_position = { x = 0, y = 0 }
    self.boss_pos = { x = 0, y = 0 }
    self.cur_block_type = CONST_BLOCK_TYPE["empty"]
end

function mining:InitEventOpenDay()
    self.cave_event_open_day_data = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
        }
    for open_day = 1, 7 do 
        local config_data = self.cave_config_info[open_day]
        for _,v in pairs(config_data) do 
            table.insert(self.cave_event_open_day_data[v],open_day) 
        end
    end
end

--刷新 随机事件次数
function mining:DailyClear()
    local event_count = 0
    for k,v in pairs(mining_random_activity_config) do
        event_count = event_count + v.max_happen
    end
    self.event_count = event_count
    graphic:DispatchEvent("refresh_event_count")
end

function mining:Update(elapsed_time)
    --自动恢复
    if self.dig_count < self.dig_max_count then
        self.dig_recover_time = self.dig_recover_time + elapsed_time
        local is_count_increased = false

        if self.dig_recover_time >= self.max_recover_time then
            local recover_count = math.floor(self.dig_recover_time / self.max_recover_time)
            self.dig_recover_time = self.dig_recover_time - recover_count * self.max_recover_time
            self.dig_count = math.min(self.dig_count + recover_count, self.dig_max_count)
            if self.dig_count == self.dig_max_count then
                self.dig_recover_time = 0
            end

            is_count_increased = true
        end

        graphic:DispatchEvent("update_dig_recover_time", is_count_increased)
    end

    local boss_x, boss_y = self.boss_pos.x, self.boss_pos.y
    if boss_x ~= 0 and boss_y ~= 0 and self.boss_time > 0 then
        if self.boss_time <= time_logic:Now() then
            self.boss_pos.x = 0
            self.boss_pos.y = 0
            self.boss_time = 0

            if self.block_list[boss_y] then
                self.block_list[boss_y][boss_x] = CONST_BLOCK_TYPE["rock"]
                graphic:DispatchEvent("update_mining_boss_info", boss_x, boss_y, 0)
            end
        end
    end
end

function mining:ParseBlockInfo(block_str)
    local block_list = self.block_list

    for x, y, block_type in string.gmatch(block_str, "(-?%d+),(%d+),(%d+)|") do
        x = tonumber(x)
        y = tonumber(y)
        block_type = tonumber(block_type)

        local row_block_list = block_list[y]

        if not row_block_list then
            row_block_list = {}
            block_list[y] = row_block_list
        end

        row_block_list[x] = block_type

        if block_type == CONST_BLOCK_TYPE["golem"] then
            table.insert(self.golem_coordinates, { x = x, y = y })

        elseif CHEST_BLOCK_MAP[block_type] then
            table.insert(self.chest_coordinates, { x = x, y = y })
        end
    end
end

local s_byte = string.byte
local s_find = string.find
local CHAR = string.char(255)

function mining:ParseBlockInfoEx(y_offset, block_str, is_negative, is_ext)
    local count = self.block_count

    local block_list = self.block_list
    if is_ext then
        local pos = 1
        while pos < #block_str do
            local high_y, low_y, high_x, low_x, block_type = s_byte(block_str, pos, pos+4)

            local y = bit_lshift(high_y, 8) + low_y
            local x = bit_lshift(high_x, 8) + low_x
            x = is_negative and -x or x

            local row_block_list = block_list[y]
            if not row_block_list then
                row_block_list = {}
                block_list[y] = row_block_list
            end

            row_block_list[x] = block_type
            count = count + 1

            if block_type == CONST_BLOCK_TYPE["golem"] then
                table.insert(self.golem_coordinates, { x = x, y = y })

            elseif CHEST_BLOCK_MAP[block_type] then
                table.insert(self.chest_coordinates, { x = x, y = y })
            end

            if self.block_counts[block_type] then
                self.block_counts[block_type] = self.block_counts[block_type] + 1
            else
                self.block_counts[block_type] = 1
            end

            pos = pos + 5
        end

    else
        local pos1 = 1
        local pos2 = s_find(block_str, CHAR, pos1)
        while pos2 do
            local y = s_byte(block_str, pos1, pos1) + y_offset
            local len = pos2 - pos1 - 1

            local row_block_list = block_list[y]
            if not row_block_list then
                row_block_list = {}
                block_list[y] = row_block_list
            end

            for i = 1, len / 2 do
                local offset = pos1 + i * 2 - 1
                local x, block_type = s_byte(block_str, offset, offset+1)
                x = is_negative and -x or x

                row_block_list[x] = block_type

                count = count + 1

                if block_type == CONST_BLOCK_TYPE["golem"] then
                    table.insert(self.golem_coordinates, { x = x, y = y })

                elseif CHEST_BLOCK_MAP[block_type] then
                    table.insert(self.chest_coordinates, { x = x, y = y })
                end

                if self.block_counts[block_type] then
                    self.block_counts[block_type] = self.block_counts[block_type] + 1
                else
                    self.block_counts[block_type] = 1
                end
            end

            pos1 = pos2 + 1
            pos2 = s_find(block_str, CHAR, pos1)
        end
    end

    self.block_count = count
end

function mining:GetDigTime()
    if self.cur_block_type  == CONST_BLOCK_TYPE["empty"] then
        return 0, 1
    end

    --根据矿稿等级获取挖据需要的时间
    local config = config_manager.mining_dig_info_config[self.cur_block_type]
    local efficiency = config_manager.mining_pickaxe_config[self.pickaxe_id].efficiency

    local total_time = config["need_time" .. efficiency]
    local remain_time = self.dig_endtime - time_logic:Now()

    return remain_time, total_time
end

function mining:GetBlockList()
    return self.block_list
end

function mining:getRandomEvent()
    return self.random_event_list
end

--更新挖掘次数
function mining:UpdatePickaxeReoverTime()
    local config = config_manager.mining_pickaxe_config[self.pickaxe_id]
    if config then
        self.max_recover_time = config.recover_time
    else
        self.max_recover_time = 1
    end
end

function mining:IsResourceFound(resource_type)
    return self.resource_type_found[resource_type]
end

function mining:UpdateFoundResourceType(resource_type)
    self.resource_type_found[resource_type] = true
end

function mining:GetProjectInfo(slot)
    return self.project_list[slot]
end

function mining:GetMaxProjectCount()
    return self.max_project_count
end

--检测是否有工程完成
function mining:IsProjectCompleted()
    local project = self.project_list[1]

    if not project then
        return false
    end

    if project.endtime > time_logic:Now() then
        return false
    end

    return true
end

--获取深度
function mining:GetDepth()
    local dig_depth = #self.block_list
    if dig_depth > 0 then 
       self.dig_depth = dig_depth
    end
    return self.dig_depth
end

function mining:GetAreaRefreshTime()
    return self.refresh_time
end

--获取当前魔像等级
function mining:GetGolemLv()
    return self.golem_lv
end

--设置魔像等级
function mining:SetGolemLv(golem_lv)
    self.golem_lv = golem_lv
end

function mining:AddDigCount(dig_count)
    self.dig_count = self.dig_count + dig_count
end

function mining:QueryBlockInfo()
    if self.has_queried_block_info then
        graphic:DispatchEvent("show_world_sub_scene", "mining_district_sub_scene")
    else
        for k, v in pairs(CONST_BLOCK_TYPE) do
            self.block_counts[v] = 0
        end
        
        self.block_count = 0

        network:Send({ query_mining_block_info = {} })
    end
end

function mining:GetBlockCount(block_type)
    return self.block_counts[block_type]
end

function mining:QueryCaveEventConfigInfo()
    if self.has_queried_cave_config_info then
        graphic:DispatchEvent("show_world_sub_scene", "mining_sub_scene")
    else
        network:Send({ query_cave_event_config_info = {} })
    end
end

function mining:GetBlockType(block_x, block_y)
    if not self.block_list[block_y] then
        return
    end

    return self.block_list[block_y][block_x]
end

--
function mining:IsCollect(block_x, block_y)

    if self.cur_position.x == block_x and self.cur_position.y == block_y then
        --检测是否为收集资源操作
        if self.cur_block_type ~= CONST_BLOCK_TYPE["empty"] then
            if self.dig_endtime > time_logic:Now() then
                graphic:DispatchEvent("show_prompt_panel", "mining_is_digging")
                return true
            end

            local block_info = self:GetBlockInfo(block_x, block_y)

            if block_info.output_resource_id ~= 0 then
                network:Send( { collect_mine = { x = block_x, y = block_y } })
                return true
            end
        end
    end

    return false
end

function mining:GetBlockInfo(block_x, block_y)
    local block_type = self.block_list[block_y][block_x]
    if not block_type then
        return
    end

    local block_info = config_manager.mining_dig_info_config[block_type]
    if not block_info or block_info.destroy_level == 0 then
        return
    end

    return block_info
end

--
function mining:DigOrCollectBlock(block_x, block_y)
    -- 随机事件提示
    for k,v in pairs(self.random_event_list) do   -- 随机事件 提示 TIPS 
        if v.event_type ==  constants["RANDOM_EVENT_TYPE"]["occupancy"] and block_x == v.position.x and block_y == v.position.y  then
            graphic:DispatchEvent("show_prompt_panel", "mining_random_evet_tips")
        end
    end

    --检查是否触发宝箱
    if self:CheckTreasureHuntEvent(block_x,block_y) == true then
        return
    end

    if not self.block_list[block_y] then
        return
    end

    local block_info = self:GetBlockInfo(block_x, block_y)
    if not block_info then
        return
    end
    
    if block_info.collect_type >= BLOCK_COLLECT_TYPE["golem"] then
        --查询事件id
        network:Send({ query_golem_info = {x = block_x, y = block_y} })
        return
    end

    if self.cur_position.x == block_x and self.cur_position.y == block_y then
        --检测是否为收集资源操作
        if self.cur_block_type ~= CONST_BLOCK_TYPE["empty"] then
            if self.dig_endtime > time_logic:Now() then
                --正在挖矿中
                graphic:DispatchEvent("show_prompt_panel", "mining_is_digging")
                return
            end

            if block_info.output_resource_id ~= 0 then
                network:Send( { collect_mine = { x = block_x, y = block_y } })
            end
        end

    else
        if self.dig_endtime > time_logic:Now() then
            return
        end

        if block_info.ID ~= CONST_BLOCK_TYPE["rock_purple_gold"] then
            if block_info.destroy_level > config_manager.mining_pickaxe_config[self.pickaxe_id].destroy_level then
                graphic:DispatchEvent("show_prompt_panel", "mining_lack_destroy_level")
                return
            end

            if self.dig_count < (self.golem_num + 1) then
                return "lack_count"
            end
        end

        --获取资源
        local cur_block_info = config_manager.mining_dig_info_config[self.cur_block_type]
        if cur_block_info.collect_type ~= BLOCK_COLLECT_TYPE["nothing"] then
            graphic:DispatchEvent("show_prompt_panel", "mining_collect_resource_first")
            return
        end

        return self:DigBlock(block_x, block_y)
    end
end

function mining:DigBlock(block_x, block_y)
    local dig_info = {}
    dig_info.position = {}
    dig_info.position.x = block_x
    dig_info.position.y = block_y
    dig_info.open_random_event = user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_random_event"], false)  --是否开启随机事件

    if self:CheckConnected(block_x, block_y) then
        network:Send({dig_block = dig_info})
        return "success"
    else
        graphic:DispatchEvent("show_prompt_panel", "mining_dig_out_of_range")
    end
end

--检查是否 点击寻宝 宝箱
function mining:CheckTreasureHuntEvent(pos_x,pos_y)
    for k,v in pairs(self.random_event_list) do
        if v.event_type == constants["RANDOM_EVENT_TYPE"]["treasure_hunt"] then --周围是否有 寻宝事件 宝箱
            if  self:CheckConnected(v.position.x,v.position.y) == true then --周围是否有空地（判断能不能开启宝箱）
                
                if v.position.x == pos_x and v.position.y == pos_y then
                    self:FinishRandomEvent(v)
                    return true
                end
            end
        end

    end
    return false
end

function mining:CheckConnected(block_x, block_y)
    local is_connected = false

    if self:GetBlockType(block_x, block_y-1) == CONST_BLOCK_TYPE["empty"] then
        is_connected = true
    elseif self:GetBlockType(block_x, block_y+1) == CONST_BLOCK_TYPE["empty"] then
        is_connected = true
    elseif self:GetBlockType(block_x-1, block_y) == CONST_BLOCK_TYPE["empty"] then
        is_connected = true
    elseif self:GetBlockType(block_x+1, block_y) == CONST_BLOCK_TYPE["empty"] then
        is_connected = true
    end

    return is_connected
end

--使用雷管
function mining:UseTNT()
    local block_info = config_manager.mining_dig_info_config[self.cur_block_type]

    --雷管数量不足
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["tnt"], block_info.tnt_count, true) then
        return
    end

    network:Send( { use_tnt = {} } )
end

--使用矿工包
function mining:UseTool(resource_type, num)
    if not resource_logic:CheckResourceNum(resource_type, num, true) then
        return
    end

    network:Send( { use_mining_tool = { resource_id = resource_type, num = num } })
end

function mining:SolveEvent(event_id)
    if event_id ~= self.cur_event_id then
        return false
    end

    --检测背包
    if bag_logic:GetSpaceCount() < constants["EVENT_MAX_BAG_SPACE_COUNT"] then
        graphic:DispatchEvent("show_prompt_panel", "bag_full")
        return false
    end

    if adventure_logic:IsEventInCD(event_id) then
        return false
    end

    if not adventure_logic:CheckEventCost(event_id) then
        return false
    end


    local dig_info = {}
    dig_info.position = {}
    dig_info.position.x = self.cur_event_position.x
    dig_info.position.y = self.cur_event_position.y
    dig_info.open_random_event = user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_random_event"], false)  --是否开启随机事件
    
    network:Send({ dig_block = dig_info })
    return true
end

--添加工程
function mining:AddProject(project_id)
    if #self.project_list >= self.max_project_count then
        return false
    end

    local config = config_manager.mining_quarry_config[project_id]
    if self:GetDepth() < config.need_layer then
        graphic:DispatchEvent("show_prompt_panel", "mining_lack_depth", config.need_layer)
        return false
    end

    if self.dig_count < config.dig_count then
        graphic:DispatchEvent("show_prompt_panel", "mining_not_enough_dig_count")
        return false
    end

    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["tnt"], config.tnt_count, true) then
        return false
    end

    network:Send({ add_mining_project = { id = project_id } })

    return true
end

--解锁工程槽位
function mining:UnlockProjectSlot()
    if self.max_project_count >= constants["MAX_PROJECT_COUNT"] then
        return
    end

    network:Send({ unlock_mining_project = {} })
end

--解锁矿区BOSS
function mining:UnlockMineCaveBoss()
    if self.cave_boss_lv == 0 then 
       if not resource_logic:CheckResourceNum(RESOURCE_TYPE["demon_medal"], constants["OPEN_CAVE_BOSS_DEMON_MEDAL"], true) then  
          return 
       end
       network:Send({ unlock_cave_boss = {} })
    end
end

function mining:BuyCaveChallengeCounts(cave_type)
    if self.cave_buy_challenge_nums[cave_type] <= 0 then
        graphic:DispatchEvent("show_prompt_panel", "mining_not_enough_buy_challenge", true)
        return 
    end

    local current_counts = self.cave_buy_challenge_nums[cave_type]
    local max_counts = constants["CAVE_DAILY_BUY_CHALLENGE_NUM"][cave_type]

    local price_index = max_counts - current_counts + 1
    local price = constants["CAVE_DAILY_BUY_PRICE"][cave_type][price_index]
    
    if not price then 
        return
    end
    
    if not resource_logic:CheckResourceNum(RESOURCE_TYPE["blood_diamond"], price, true) then  
       return 
    end

    network:Send({ buy_cave_challenge = { cave_type = cave_type } })
end

--领取奖励
function mining:GetProjectReward()
    local project = self.project_list and self.project_list[1] or nil
    if not project then
        return
    end

    if project.endtime > time_logic:Now() then
        return
    end

    network:Send({ get_mining_project_reward = { } })
end

function mining:CheckRefreshArea(golem_lv, has_item)
    if self.dig_endtime > time_logic:Now() then
        --正在挖矿中
        graphic:DispatchEvent("show_prompt_panel", "mining_is_digging")
        return
    end

    if not has_item and self.refresh_time > time_logic:Now() then
        --刷新时间未到
        graphic:DispatchEvent("show_prompt_panel", "mining_cant_refresh_area")
        return false
    end

    for i = 1, #config_manager.mining_refresh_config do
        local conf = config_manager.mining_refresh_config[i]

        if conf.golem_lv == golem_lv then
            if self.golem_lv < conf.reset_lv then
                graphic:DispatchEvent("show_prompt_panel", "mining_not_enough_golem_lv")
                return
            end

            if not resource_logic:CheckResourceNum(RESOURCE_TYPE["tnt"], conf.tnt, true) then
                return
            end

            if not resource_logic:CheckResourceNum(RESOURCE_TYPE["ultimate_tool"], conf.ultimate_tool, true) then
                return
            end

            break
        end
    end

    return true
end

function mining:RefreshArea(golem_lv)
    if not self:CheckRefreshArea(golem_lv) then
        return
    end

    network:Send({ refresh_mining_area = { golem_lv = golem_lv} })
end

function mining:SolveCaveEvent(event_data)
    local cave_type = event_data.cave_type
    local cave_level = event_data.level
    local lang_constants = require "util.language_constants"

    --counts
    if self.cave_challenge_nums[cave_type] < 1 then 
       if self.cave_buy_challenge_nums[cave_type] > 0 then
          graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("mining_cave_counts_limit"),
           lang_constants:Get("mining_cave_counts_limit_desc"),
           lang_constants:Get("common_confirm"),
           lang_constants:Get("common_cancel"),
           function()
             local mode = client_constants["CONFIRM_MSGBOX_MODE"]["buy_cave_challenge"]
             graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, cave_type)
           end) 
       else
           graphic:DispatchEvent("show_prompt_panel", "mining_cave_counts_limit") 
       end

       return 
    end

    if self.dig_count < event_data.pickaxe_count then 
       graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("mining_cave_pickaxe_limit_title"),
         lang_constants:Get("mining_cave_pickaxe_limit_desc"),
         lang_constants:Get("common_confirm"),
         lang_constants:Get("common_cancel"),
         function()
            graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel", 2)
         end,
         function()
            graphic:DispatchEvent("show_prompt_panel", "mining_cave_pickaxe_limit")
         end)
       
       return 
    end

    --bp check
    if event_data.bp_limit > troop_logic:GetTroopBP() then 
        graphic:DispatchEvent("show_prompt_panel", "mining_cave_bp_limit")
        return 
    end

    network:Send({ solve_cave_event = { cave_type = cave_type, cave_lv = cave_level } })
    return true
end

function mining:FinishRandomEvent(random_event)
    network:Send({ finish_random_event = { random_event = random_event } })
end

--是否接受随机事件
function mining:AcceptRandomEvent(accept_opeation)
    network:Send({ accept_random_event = { accept_opeation = accept_opeation, random_event = self.show_random_event} })
end

function mining:ChallengeCaveBoss()
    if self.cave_boss_lv > 0 then 
        if not resource_logic:CheckResourceNum(RESOURCE_TYPE["demon_medal"], constants["CAVE_BOSS_CHALLANGE_SUB"], true) then  
            return 
        end

        --检测背包
        if bag_logic:GetSpaceCount() < constants["EVENT_MAX_BAG_SPACE_COUNT"] then
            graphic:DispatchEvent("show_prompt_panel", "bag_full")
            return false
        end

        network:Send({ challenge_cave_boss = {} })
    end
end

function mining:GetCaveEventData(cave_type, cave_level)
    local event_data = config_manager.mining_event_config[cave_type][cave_level]
    return event_data
end

function mining:GetCaveConfigData(cave_type, cave_level)
    local event_data = config_manager.mining_event_config[cave_type][cave_level]
    local config_data = {}
    local reward_table = common_function_util.Split(event_data.reward_type, '|')
    local param1_table = common_function_util.Split(event_data.param1, '|')
    local to_number = tonumber
    
    for index = 1, #reward_table do 
        local t_config = {}
        t_config.reward_type = to_number(reward_table[index])
        t_config.param1 = to_number(param1_table[index])

        table.insert(config_data,t_config)
    end

    return config_data
end

function mining:RegisterMsgHandler()
    network:RegisterEvent("query_mining_info_ret", function(recv_msg)
        for k, v in pairs(recv_msg) do
            if k == "resource_type_found" then
                self.resource_type_found = {}
                for resource_type in string.gmatch(v, "(%d+)") do
                    self.resource_type_found[tonumber(resource_type)] = true
                end

            else
                self[k] = v
            end
        end

        if self.dig_count >= self.dig_max_count then
            self.dig_recover_time = 0
        end

        for k, v in pairs(CONST_BLOCK_TYPE) do
            self.block_counts[v] = 0
        end
        
        self.project_list = recv_msg.project_list or {}
        self.max_project_count = recv_msg.project_max_count
        self.event_count = recv_msg.event_count
        self:UpdatePickaxeReoverTime()
    end)

    --是否接受随机事件
    network:RegisterEvent("accept_random_event_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.dig_count = self.dig_count - recv_msg.pick_cost
            graphic:DispatchEvent("update_dig_count")

            self.event_count = self.event_count - 1
            graphic:DispatchEvent("refresh_event_count")

            if recv_msg.accept_opeation == "accept" then
                table.insert(self.random_event_list, recv_msg.random_event)
            end
            graphic:DispatchEvent("accept_random_event", recv_msg)
            achievement_logic:UpdateStatisticValue(constants["ACHIEVEMENT_TYPE"]["mining_random_event_count"],1)
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(constants["RESOURCE_TYPE"][recv_msg.reource_type])
        elseif PROMPT_MAP[recv_msg.result] then
            graphic:DispatchEvent("show_prompt_panel", PROMPT_MAP[recv_msg.result])
        end
    end)

    --完成随机事件
    network:RegisterEvent("finish_random_event_ret", function(recv_msg)
        local random_event = recv_msg.random_event
        if recv_msg.result == "success" then
            --事件完成后 本地数据删除随机事件
            for k,v in pairs(self.random_event_list) do
                if random_event.position.x == v.position.x and random_event.position.y == v.position.y then
                    table.remove(self.random_event_list,k)
                    break
                end
            end
            graphic:DispatchEvent("finish_random_event", recv_msg)

        elseif recv_msg.result == "failure" then --寻宝事件 时间到 为失败
            if random_event.event_type == constants["RANDOM_EVENT_TYPE"]["treasure_hunt"] then
                local random_event = recv_msg.random_event
                for k,v in pairs(self.random_event_list) do
                    if random_event.position.x == v.position.x and random_event.position.y == v.position.y then
                        table.remove(self.random_event_list,k)
                        break
                    end
                end
                graphic:DispatchEvent("finish_random_event", recv_msg)
            end
        end
    end)

    network:RegisterEvent("query_mining_block_info_ret", function(recv_msg)
        self:ParseBlockInfoEx(recv_msg.y_offset, recv_msg.negative_block_list, true, recv_msg.is_ext)
        self:ParseBlockInfoEx(recv_msg.y_offset, recv_msg.positive_block_list, false, recv_msg.is_ext)

        if recv_msg.is_finish_query then
            self.has_queried_block_info = true
            self.max_query_packet_count = recv_msg.count
        else
            self.cur_query_packet_count = self.cur_query_packet_count + 1
        end
        self.random_event_list = {}

        if recv_msg.random_event_list and #recv_msg.random_event_list > 0 then
            for i = 1 , #recv_msg.random_event_list do
                local random_event = recv_msg.random_event_list[i]
                table.insert(self.random_event_list,random_event)
            end
        end

        if self.cur_query_packet_count == self.max_query_packet_count then
            self.cur_block_type = self.block_list[self.cur_position.y][self.cur_position.x]
            if not self.cur_block_type then
                self.cur_block_type = CONST_BLOCK_TYPE["empty"]
            end

            graphic:DispatchEvent("show_world_sub_scene", "mining_district_sub_scene")
        end
    end)

    network:RegisterEvent("dig_block_ret", function(recv_msg)
        self.random_event = {}
        if user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_random_event"], false) and recv_msg.random_event then
            self.random_event = recv_msg.random_event
        end

        if recv_msg.result == "success" then
            self.cur_position = recv_msg.cur_position
            local old_golem_num = self.golem_num
            if recv_msg.golem_num then
                self.is_discover_golem = recv_msg.golem_num > self.golem_num
                self.golem_num = recv_msg.golem_num
            end
            
            local old_block_type = self.block_list[self.cur_position.y][self.cur_position.x]
            local config = config_manager.mining_dig_info_config[old_block_type]

            if config.collect_type >= BLOCK_COLLECT_TYPE["golem"] then
                --特殊事件
                if recv_msg.block_list then
                    self:ParseBlockInfo(recv_msg.block_list)
                end

                self.golem_lv = recv_msg.golem_lv or self.golem_lv

                --统技打败矿区boss次数
                if config.collect_type == BLOCK_COLLECT_TYPE["boss"] then
                    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["mining_boss_kill"], 1)
                    self.boss_pos.x = 0
                    self.boss_pos.y = 0
                    self.boss_time = 0
                    
                elseif config.collect_type == BLOCK_COLLECT_TYPE["chest"] then
                    achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["open_chest"], 1)
                    local cur_x, cur_y = self.cur_position.x, self.cur_position.y
                    for i, position in pairs(self.chest_coordinates) do
                        if position.x == cur_x and position.y == cur_y then
                            table.remove(self.chest_coordinates, i)
                            break
                        end
                    end

                elseif config.collect_type == BLOCK_COLLECT_TYPE["golem"] then
                    local cur_x, cur_y = self.cur_position.x, self.cur_position.y
                    for i, position in pairs(self.golem_coordinates) do
                        if position.x == cur_x and position.y == cur_y then
                            table.remove(self.golem_coordinates, i)
                            break
                        end
                    end
                end

                graphic:DispatchEvent("finish_dig_block", old_block_type)
                self.block_list[self.cur_position.y][self.cur_position.x] = CONST_BLOCK_TYPE["empty"]
            else
                self:ParseBlockInfo(recv_msg.block_list)

                self.cur_block_type = self.block_list[self.cur_position.y][self.cur_position.x]

                --统计力量点数 也就是挖矿点数
                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE["strength_pt"], config["strength_pt"])

                if config.collect_type == BLOCK_COLLECT_TYPE["nothing"] then
                    self.block_list[self.cur_position.y][self.cur_position.x] = CONST_BLOCK_TYPE["empty"]
                end

                if config.ID == CONST_BLOCK_TYPE["rock_purple_gold"] then
                    --紫金岩
                    graphic:DispatchEvent("finish_dig_block", old_block_type)
                    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                else
                    self.dig_count = self.dig_count - (1 + old_golem_num)
                    if recv_msg.dig_count and recv_msg.dig_count > self.dig_count then
                        self.dig_count = recv_msg.dig_count
                        self.dig_recover_time = 0
                    end
                    
                    if recv_msg.dig_endtime then
                        local efficiency = config_manager.mining_pickaxe_config[self.pickaxe_id].efficiency
                        local total_time = config["need_time" .. efficiency]

                        --添加一定误差
                        self.dig_endtime = time_logic:Now() + total_time + 0.05
                    end
                end

                if self.dig_endtime - time_logic:Now() <= 0 then
                    --挖矿结束
                    graphic:DispatchEvent("finish_dig_block", old_block_type)
                end
            end

            if recv_msg.dig_recover_time then
                self.dig_recover_time = recv_msg.dig_recover_time
                self:UpdatePickaxeReoverTime()
            end

            graphic:DispatchEvent("show_new_mining_block", recv_msg.block_list or "")
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]

            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end

            if recv_msg.result == "not_enough_resource" then
                resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["tnt"])
            end
        end
    end)

    --使用TNT
    network:RegisterEvent("use_tnt_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.dig_endtime = time_logic:Now()

            graphic:DispatchEvent("finish_use_tnt")
        elseif recv_msg.result == "not_enough_resource" then
            --雷管不足
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["tnt"])
        end
    end)

    --收取资源
    network:RegisterEvent("collect_mine_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local block_info = config_manager.mining_dig_info_config[self.cur_block_type]

            self.cur_block_type = CONST_BLOCK_TYPE["empty"]
            self.block_list[self.cur_position.y][self.cur_position.x] = self.cur_block_type

            graphic:DispatchEvent("finish_collect_mine", block_info.output_resource_id, block_info.output_resource_count)
        elseif recv_msg.result == "time_limit" then
            graphic:DispatchEvent("show_prompt_panel", "mining_is_digging")
        end
    end)

    --查询巨魔信息
    network:RegisterEvent("query_golem_info_ret", function(recv_msg)
        if recv_msg.event_id then
            self.cur_event_id = recv_msg.event_id
            self.cur_event_position = recv_msg.cur_position

            local event_info = config_manager.event_config[recv_msg.event_id]
            local event_type = event_info["event_type"]

            if event_type == constants["ADVENTURE_EVENT_TYPE"]["battle"] then
                graphic:DispatchEvent("show_world_sub_panel", "event_panel", event_type, recv_msg.event_id)
            elseif event_type == constants["ADVENTURE_EVENT_TYPE"]["resource"] then
                graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants["CONFIRM_MSGBOX_MODE"]["open_chest"],
                recv_msg.event_id, self.cur_event_position, self.cur_event_position.y)
            elseif event_type == constants["ADVENTURE_EVENT_TYPE"]["gossip"] then
                self:SolveEvent(self.cur_event_id)
            end
        end
    end)

    --添加工程
    network:RegisterEvent("add_mining_project_ret", function(recv_msg)
        local config = config_manager.mining_quarry_config[recv_msg.id]

        if recv_msg.result == "success" then
            if self.dig_count >= self.dig_max_count then
                self.dig_recover_time = 0
            end

            self.project_list = recv_msg.project_list
            self.dig_count = self.dig_count - config.dig_count
            graphic:DispatchEvent("update_mining_project_list", false)
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["tnt"])
        elseif recv_msg.result == "not_enough_layer" then
            graphic:DispatchEvent("show_prompt_panel", "mining_lack_depth", config.need_layer)
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]
            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end
        end
    end)

    --获取工程奖励
    network:RegisterEvent("get_mining_project_reward_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local project_id = self.project_list[1].id
            self.project_list = recv_msg.project_list or {}
            graphic:DispatchEvent("update_mining_project_list", true, project_id)
        end
    end)

    --解锁工程
    network:RegisterEvent("unlock_mining_project_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.max_project_count = self.max_project_count + 1
            graphic:DispatchEvent("unlock_mining_project")
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE["soul_chip"])
        end
    end)

    --更新矿区信息
    network:RegisterEvent("update_mining_info", function(recv_msg)
        local recover_time_flag = false
        if self.dig_count >= self.dig_max_count then
            recover_time_flag = true
        end
        if recv_msg.pickaxe_id then
            self.pickaxe_id = recv_msg.pickaxe_id
            self:UpdatePickaxeReoverTime()
        end

        if recv_msg.dig_max_count then
            self.dig_max_count = recv_msg.dig_max_count
        end

        if recv_msg.dig_count then
            self.dig_count = recv_msg.dig_count
        end

        if recover_time_flag and self.dig_count < self.dig_max_count then
            self.dig_recover_time = 0
        end
    end)

    network:RegisterEvent("use_mining_tool_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("use_mining_tool", recv_msg.resource_id,recv_msg.num)
            graphic:DispatchEvent("reload_campaign_cave_event")
        end
    end)

    --刷新矿区结构
    network:RegisterEvent("refresh_mining_area_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self:ResetArea(recv_msg.golem_lv)
            self.refresh_time = recv_msg.refresh_time
            self:ParseBlockInfo(recv_msg.block_list)
            
            graphic:DispatchEvent("refresh_random_event")
            graphic:DispatchEvent("show_prompt_panel", "mining_refresh_area_success")
            graphic:DispatchEvent("refresh_mining_area")
            graphic:DispatchEvent("hide_world_sub_panel", "mining_reset_panel")
        else
            local prompt_id = PROMPT_MAP[recv_msg.result]

            if prompt_id then
                graphic:DispatchEvent("show_prompt_panel", prompt_id)
            end

            if recv_msg.result == "not_enough_resource" then
                resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE[recv_msg.reource_type])
            end
        end
    end)

    --矿区副本
    network:RegisterEvent("solve_cave_event_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local battle_type = client_constants.BATTLE_TYPE["vs_monster"]
            local is_winner = recv_msg.is_winner
            local event_config = self:GetCaveEventData(recv_msg.cave_type, recv_msg.cave_lv)
            if not event_config then 
                return 
            end

            local refresh_flag = false
            if is_winner then 
                self.cave_challenge_nums[recv_msg.cave_type] = self.cave_challenge_nums[recv_msg.cave_type] - 1
                local old_level = self.cave_levels[recv_msg.cave_type] 
                if recv_msg.cave_lv == old_level then 
                   self.cave_levels[recv_msg.cave_type] = recv_msg.cave_lv + 1
                   refresh_flag = true
               end
            end

            self.dig_count = self.dig_count - event_config.pickaxe_count
            if recv_msg.dig_count and recv_msg.dig_count > self.dig_count then 
               self.dig_count = recv_msg.dig_count
               self.dig_recover_time = 0
            end

            graphic:DispatchEvent("cave_event_update", recv_msg.cave_type, refresh_flag)

            graphic:DispatchEvent("show_battle_room", battle_type, event_config.monster_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                if is_winner then
                    graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                end
            end)
        end
    end)
    
    --购买次数
    network:RegisterEvent("buy_cave_challenge_ret", function(recv_msg)
        if recv_msg.result == "success" then
           self.cave_challenge_nums[recv_msg.cave_type] = self.cave_challenge_nums[recv_msg.cave_type] + 1
           self.cave_buy_challenge_nums[recv_msg.cave_type] = self.cave_buy_challenge_nums[recv_msg.cave_type] - 1

           graphic:DispatchEvent("cave_event_update", recv_msg.cave_type, false)
           graphic:DispatchEvent("reload_campaign_cave_event")

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE[recv_msg.reource_type])
        end
    end)

    --解锁矿区BOSS
    network:RegisterEvent("unlock_cave_boss_ret", function(recv_msg)
        if recv_msg.result == "success" then
           if self.cave_boss_lv == 0 then 
              self.cave_boss_lv = 1
              self.cave_boss_end_time = recv_msg.cave_boss_end_time
              graphic:DispatchEvent("cave_boss_update", true)
           end
        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt(RESOURCE_TYPE[recv_msg.reource_type])
        end
    end)

    --副本配置信息查询返回
    network:RegisterEvent("query_cave_event_config_info_ret", function(recv_msg)
        
        for k, v in pairs(recv_msg.cave_open_config) do 
            if not self.cave_config_info[v.day] then 
               self.cave_config_info[v.day] = {}
            end
            self.cave_config_info[v.day] = v.cave_types 
        end
        --副本开放数据生成
        self:InitEventOpenDay()

        self.has_queried_cave_config_info = true

        graphic:DispatchEvent("show_world_sub_scene", "mining_sub_scene")
    end)

    --矿区BOSS
    network:RegisterEvent("challenge_cave_boss_ret", function(recv_msg)
        if recv_msg.result == "success" then
           local battle_type = client_constants.BATTLE_TYPE["vs_monster"]
           local event_config = self:GetCaveEventData(constants["CAVE_BOSS_EVENT_TYPE"], recv_msg.cave_boss_lv)
           if not event_config then 
              return 
           end

           local record_boss_lv = recv_msg.cave_boss_lv
           if recv_msg.cave_boss_lv > self.cave_boss_lv then
              record_boss_lv = record_boss_lv - 1
           end

           self.cave_boss_lv = recv_msg.cave_boss_lv 
           local is_winner = false
           local old_boss_bp = self.cave_boss_bp
           if recv_msg.cave_boss_bp <= 0 then 
              is_winner = true
              self.cave_boss_bp = event_config.max_bp
              self.cave_boss_end_time = recv_msg.cave_boss_end_time
           else
              self.cave_boss_bp = recv_msg.cave_boss_bp
           end

           local battle_record_event_config = self:GetCaveEventData(constants["CAVE_BOSS_EVENT_TYPE"], record_boss_lv)
           if not battle_record_event_config then 
              return 
           end

           graphic:DispatchEvent("cave_boss_update", false)
           graphic:DispatchEvent("show_battle_room", battle_type, battle_record_event_config.monster_id, recv_msg.battle_property, recv_msg.battle_record, is_winner, function()
                 graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
                 graphic:DispatchEvent("cave_boss_bp_animation", old_boss_bp - recv_msg.cave_boss_bp, old_boss_bp )
            end)  
        end
    end)

end

return mining
