local config_manager = require "logic.config_manager"
local network = require "util.network"
local graphic = require "logic.graphic"
local vip_logic = require "logic.vip"

local constants = require "util.constants"

local RESOURCE_TYPE = constants.RESOURCE_TYPE

local time_logic
local user_logic
local troop_logic
local resource_logic
local mining_logic

local bag = {}
function bag:Init()
    user_logic = require "logic.user"
    troop_logic = require "logic.troop"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"
    vip_logic = require "logic.vip"
    mining_logic = require "logic.mining"

    self.level = 1
    self.item_list = {}
    self.capacity = 1

    self.item_id_generator = 0

    self:RegisterMsgHandler()
end

function bag:GetItemList()
    return self.item_list
end

function bag:GetItemInfo(item_id)
    for i, item in ipairs(self.item_list) do
        if item.item_id == item_id then
            return item
        end
    end
end

function bag:GetItemCount(template_id)
    local count = 0
    for i, item in ipairs(self.item_list) do
        if item.template_id == template_id then
            count = count + 1
        end
    end
    return count
end

function bag:GetCapacity()
    return self.capacity, self.level
end

--获取包裹中空白的位置
function bag:GetSpaceCount()
    return self.capacity - #self.item_list
end

function bag:ResetItemFlag()
    for i, item in ipairs(self.item_list) do
        item.is_new = false
    end
end

--使用道具
function bag:UseItem(item_id, golem_lv)
    local found = false
    local cur_item
    for i, item in ipairs(self.item_list) do
        if item.item_id == item_id then
            found = true
            cur_item = item
            break
        end
    end

    if not found then
        graphic:DispatchEvent("show_prompt_panel", "bag_item_not_exist")
        return
    end

    if cur_item.template_info.rule_type == constants.ITEM_RULE["hero_biography"] and not troop_logic:CheckMercenaryNum() then
        return

    elseif cur_item.template_info.rule_type == constants.ITEM_RULE["refresh_mining"] and not mining_logic:CheckRefreshArea(golem_lv, true) then
        return
    end

    network:Send({ use_item = { item_id = item_id, golem_lv = golem_lv} })
end

local upgrade_params = { "copper", "iron", "silver", "tin", "gold", "diamond", "ruby", "purple_gem", "emerald", "topaz" }

--升级背包
function bag:UpgradeBag()
    local config = config_manager.bag_info_config[self.level]

    if not config then
        return
    end

    --检测资源是否充足
    for i = 1, #upgrade_params do
        local num = config[upgrade_params[i]]
        local resource_type = RESOURCE_TYPE[upgrade_params[i]]

        if num > 0 and not resource_logic:CheckResourceNum(resource_type, num, true) then
            return
        end
    end

    network:Send({ upgrade_bag = { } })
end

function bag:NewItem(template_id)
    if #self.item_list >= self.capacity then
        return
    end

    local item = {}
    self.item_id_generator = self.item_id_generator + 1
    item.item_id = self.item_id_generator
    item.template_id = template_id
    item.template_info = config_manager.item_config[template_id]
    item.create_time = time_logic:Now()

    table.insert(self.item_list, item)
    -- 背包是否满了提醒
    graphic:DispatchEvent("bag_is_full")
end

function bag:RegisterMsgHandler()
    network:RegisterEvent("query_bag_info_ret", function(recv_msg)
        print("query_bag_info_ret")
        self.level = recv_msg.level
        self.capacity = recv_msg.max_count

        local item_config = config_manager.item_config

        if recv_msg.item_list then
            for i, item in ipairs(recv_msg.item_list) do
                --过滤非法的item
                if item_config[item.template_id] then
                    item.template_info = item_config[item.template_id]
                    item.is_new = false
                    table.insert(self.item_list, item)
                end
            end
        end

        self.item_id_generator = recv_msg.item_id_generator

        -- 背包是否满了提醒
        graphic:DispatchEvent("bag_is_full")
    end)

    network:RegisterEvent("use_item_ret", function(recv_msg)
        if recv_msg.result == "success" or recv_msg.result == "event_take" then
            local item_index = 0
            local template_info

            for i, item in ipairs(self.item_list) do
                if item.item_id == recv_msg.item_id then
                    item_index = i
                    template_info = item.template_info
                    break
                end
            end

            if item_index ~= 0 then
                table.remove(self.item_list, item_index)
            end

            if template_info and template_info.rule_type == constants.ITEM_RULE["vip"] then
                vip_logic:ActivateAdventurer(template_info.roll_count * 86400)
            end

            if recv_msg.result == "success" then
                graphic:DispatchEvent("use_item_which_in_bag", recv_msg.item_id, recv_msg.extra_num, template_info)
                -- 背包是否满了提醒
                graphic:DispatchEvent("bag_is_full")
            end

        elseif recv_msg.result == "daily_limit" then
            graphic:DispatchEvent("show_prompt_panel", "bag_use_item_dayly_limit")

        elseif recv_msg.result == "item_not_found" then
            graphic:DispatchEvent("show_prompt_panel", "bag_item_not_exist")

        elseif recv_msg.result == "not_enough_mercenary_space" then
            graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", troop_logic:GetCampCapacity())

        elseif recv_msg.result == "mining_time_limit" then
            graphic:DispatchEvent("show_prompt_panel", "mining_is_digging")

        elseif recv_msg.result == "mining_collect_first" then
            graphic:DispatchEvent("show_prompt_panel", "mining_collect_resource_first")

        elseif recv_msg.result == "temple_today_cant_recruit" then
            graphic:DispatchEvent("show_prompt_panel", "temple_not_enough_recruit_count")

        elseif recv_msg.result == "mining_not_enough_golem_lv" then
            graphic:DispatchEvent("show_prompt_panel", "mining_not_enough_golem_lv")
        end
    end)

    network:RegisterEvent("upgrade_bag_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.level = recv_msg.new_level

            local config = config_manager.bag_info[self.level]
            self.capacity = config.capacity

            graphic:DispatchEvent("show_prompt_panel", "bag_upgrade_success")
            graphic:DispatchEvent("update_bag")
            -- 背包是否满了提醒
            graphic:DispatchEvent("bag_is_full")

        elseif recv_msg.result == "not_enough_resource" then
            resource_logic:ShowLackResourcePrompt()

        elseif recv_msg.result == "reach_max_level" then
            graphic:DispatchEvent("show_prompt_panel", "bag_already_max_level")
        end
    end)
end

return bag
