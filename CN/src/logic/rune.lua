local config_manager = require "logic.config_manager"
local network = require "util.network"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local achievement_logic
local time_logic
local user_logic
local rune_config

local rune = {}
function rune:Init()
    achievement_logic = require "logic.achievement"
    user_logic = require "logic.user"
    time_logic = require "logic.time"

    rune_config = config_manager.rune_config

    self.cur_draw_platform_id = 1
    self.rune_bag_level = 1
    self.rune_bag_capacity = 1
    self.max_rune_bag_capacity = constants.MAX_RUNE_BAG_CAPACITY
    self.rune_list = {}
    self.rune_temporary_bag_capacity = constants.MAX_RUNE_TEMPORARY_BAG_CAPACITY
    self.rune_temporary_list = {}
    self.rune_equipment_list = {}

    self.is_selected_auto_go = false
    self.is_selected_auto_go_tips = false
    self.is_selected_auto_compose = false
    self.is_selected_more_quality = false

    self.is_ignore_go_to_area4_tip = false

    self.is_drawing = false
    self.is_moving = false

    self:RegisterMsgHandler()
end

function rune:GetCurDrawPlatformId()
    return self.cur_draw_platform_id
end

function rune:GetRuneList()
    return self.rune_list
end

function rune:GetSortRuneList(asc_type, asc_quality, asc_level)
    asc_type = asc_type == nil and true
    asc_quality = asc_quality == nil and true
    asc_level = asc_level == nil and true

    table.sort( self.rune_list, function(a, b)
                                    if a.equip_pos == 0 and b.equip_pos ~= 0 then
                                        return false
                                    elseif a.equip_pos ~= 0 and b.equip_pos == 0 then
                                        return true
                                    elseif a.template_info.type ~= b.template_info.type then
                                        if asc_type then
                                            return a.template_info.type < b.template_info.type
                                        else
                                            return a.template_info.type > b.template_info.type
                                        end
                                    elseif a.template_info.quality ~= b.template_info.quality then
                                        if asc_quality then
                                            return a.template_info.quality < b.template_info.quality
                                        else
                                            return a.template_info.quality > b.template_info.quality
                                        end
                                    elseif a.level ~= b.level then
                                        if asc_level then
                                            return a.level < b.level
                                        else
                                            return a.level > b.level
                                        end
                                    else
                                        return a.rune_id > b.rune_id
                                    end
                                end )

    return self.rune_list
end

function rune:GetExchangeRuneList(rune_info1)
    local rune_exchange_list = {}
    for k,rune_info in pairs(self.rune_list) do
        if rune_info.template_info.type ~= 1 then
            if rune_info1 then
                if rune_info.rune_id ~= rune_info1.rune_id then
                    table.insert(rune_exchange_list,rune_info)
                end
            else
                table.insert(rune_exchange_list,rune_info)
            end
        end
    end
    
    table.sort(rune_exchange_list,function (rune1 ,rune2)
            if rune_info1 and rune1.template_info.quality ~= rune2.template_info.quality and rune1.template_info.quality == rune_info1.template_info.quality then
                return true
            elseif rune_info1 and rune1.template_info.quality ~= rune2.template_info.quality and rune2.template_info.quality == rune_info1.template_info.quality then
                return false
            end
            if rune1.template_info.type ~= rune2.template_info.type then
                return rune1.template_info.type > rune2.template_info.type
            elseif rune1.template_info.quality ~= rune2.template_info.quality then
                return rune1.template_info.quality > rune2.template_info.quality
            elseif rune1.level ~= rune2.level then
                return rune1.level > rune2.level
            else
                return rune1.rune_id > rune2.rune_id
            end

    end)

    
    return rune_exchange_list
end

function rune:GetRuneTemporaryList()
    return self.rune_temporary_list
end

function rune:GetRuneEquipmentList()
    return self.rune_equipment_list
end

function rune:GetRuneBagCapacity()
    return self.rune_bag_capacity
end

function rune:GetRuneTemporaryBagCapacity()
    return self.rune_temporary_bag_capacity
end

function rune:GetMaxRuneBagCapacity()
    return self.max_rune_bag_capacity
end

function rune:IsSelectedAutoGo()
    return self.is_selected_auto_go
end

function rune:SetSelectedAutoGo(is_selected_auto_go)
    self.is_selected_auto_go = is_selected_auto_go
end

function rune:IsSelectedAutoGoTips()
    return self.is_selected_auto_go_tips
end

function rune:SetSelectedAutoGoTips(is_selected_auto_go_tips)
    self.is_selected_auto_go_tips = is_selected_auto_go_tips
end

function rune:IsSelectedAutoCompose()
    return self.is_selected_auto_compose
end

function rune:SetSelectedAutoCompose(is_selected_auto_compose)
    self.is_selected_auto_compose = is_selected_auto_compose
end

function rune:IsIgnoreGoToArea4Tip()
    return self.is_ignore_go_to_area4_tip
end

function rune:SetIgnoreGoToArea4Tip(is_ignore_go_to_area4_tip)
    self.is_ignore_go_to_area4_tip = is_ignore_go_to_area4_tip
end

function rune:IsSelectedMoreQuality()
    return self.is_selected_more_quality
end

function rune:SetSelectedMoreQuality(is_selected_more_quality)
    self.is_selected_more_quality = is_selected_more_quality
end

function rune:RegisterMsgHandler()
	--查询玩家符文数据
    network:RegisterEvent("query_rune_info_ret", function(recv_msg)
        print("query_rune_info_ret")

        self.cur_draw_platform_id = recv_msg.cur_draw_platform_id
        self.rune_bag_level = recv_msg.rune_bag_level
        self.exchange_cost_list = recv_msg.rune_exchange_info
        self.rune_bag_capacity = config_manager.rune_bag_config[self.rune_bag_level]["capacity"]

        if recv_msg.rune_list then
            for i, rune_info in ipairs(recv_msg.rune_list) do
                --过滤非法的id
                if rune_config[rune_info.template_id] then
                    rune_info.template_info = rune_config[rune_info.template_id]
                    table.insert(self.rune_list, rune_info)
                end
            end
        end

        if recv_msg.rune_temporary_list then
            for i, rune_info in ipairs(recv_msg.rune_temporary_list) do
                --过滤非法的item
                if rune_config[rune_info.template_id] then
                    rune_info.template_info = rune_config[rune_info.template_id]
                    table.insert(self.rune_temporary_list, rune_info)
                end
            end
        end

        self:GenerateRuneEquipment()
    end)

    --一键收取
    network:RegisterEvent("rune_one_key_receive_ret", function(recv_msg)
        if recv_msg.target_rune_info then
            for index,rune_temporary_info in ipairs(self.rune_temporary_list) do
                if rune_temporary_info.rune_id == recv_msg.target_rune_info.rune_id then
                    rune_temporary_info.exp = recv_msg.target_rune_info.exp
                    rune_temporary_info.level = recv_msg.target_rune_info.level
                    break 
                end
            end
        end

        if recv_msg.move_rune_id_list then
            for i, move_rune_id in ipairs(recv_msg.move_rune_id_list) do
                for index,rune_temporary_info in ipairs(self.rune_temporary_list) do
                    if rune_temporary_info.rune_id == move_rune_id then
                        table.insert(self.rune_list, table.remove(self.rune_temporary_list, index))
                        break
                    end
                end
            end
        end

        if recv_msg.exp_rune_id_list then
            for i, exp_rune_id in ipairs(recv_msg.exp_rune_id_list) do
                for index,rune_temporary_info in ipairs(self.rune_temporary_list) do
                    if rune_temporary_info.rune_id == exp_rune_id then
                        table.remove(self.rune_temporary_list, index)
                        break
                    end
                end
            end
        end
        local is_full = false
        if #self.rune_temporary_list > 0 then
            is_full = true
            graphic:DispatchEvent("show_prompt_panel", "rune_bag_full")
        end

        graphic:DispatchEvent("receive_rune_to_bag", recv_msg.target_rune_info, recv_msg.exp_rune_id_list, recv_msg.move_rune_id_list, is_full)  

         
    end)

    --抽符文
    network:RegisterEvent("draw_rune_ret", function(recv_msg)
        local new_rune_list = {}
        if recv_msg.draw_records then
            for i,record in ipairs(recv_msg.draw_records) do
                local rune_info = self:NewRune(record.rune_info.rune_id, record.rune_info.template_id, record.rune_info.level, constants["RUNE_BAG_TYPE"]["TEMPORARY_BAG"])

                local draw_info = { new_platform_id = record.new_platform_id, rune_info = rune_info }
                table.insert(new_rune_list, draw_info)
            end
        end

        self.cur_draw_platform_id = recv_msg.cur_draw_platform_id
        
        graphic:DispatchEvent("new_rune_in_temporary_bag", recv_msg.result, recv_msg.draw_type, recv_msg.go_to_area_4, new_rune_list)
    end)

    --购买背包格
    network:RegisterEvent("buy_rune_bag_cell_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.rune_bag_level = recv_msg.rune_bag_level
            local add_capacity = config_manager.rune_bag_config[self.rune_bag_level]["capacity"] - self.rune_bag_capacity
            self.rune_bag_capacity = config_manager.rune_bag_config[self.rune_bag_level]["capacity"]
            graphic:DispatchEvent("refresh_rune_bag")
            graphic:DispatchEvent("show_prompt_panel", "rune_bag_capacity_add_tips", add_capacity) --提示开启了多少个
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --安装符文
    network:RegisterEvent("equip_rune_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local rune_id = recv_msg.rune_id
            local equip_pos = recv_msg.equip_pos

            for index, rune_info in ipairs(self.rune_list) do
                if rune_info.rune_id == rune_id then
                    rune_info.equip_pos = equip_pos
                elseif rune_info.equip_pos == equip_pos then
                    rune_info.equip_pos = 0
                end
            end
            self:GenerateRuneEquipment()

            graphic:DispatchEvent("refresh_rune_equipment")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --升级符文
    network:RegisterEvent("upgrade_rune_ret", function(recv_msg)
        if recv_msg.result == "success" then

            for i,exp_rune_id in ipairs(recv_msg.exp_rune_id_list) do
                for index,rune_info in ipairs(self.rune_list) do
                    if rune_info.rune_id == exp_rune_id then
                        table.remove(self.rune_list, index)
                        break
                    end
                end
            end

            for index,rune_info in ipairs(self.rune_list) do
                if rune_info.rune_id == recv_msg.rune_info.rune_id then
                    local start_level = rune_info.level
                    local start_exp = rune_info.exp
                    rune_info.level = recv_msg.rune_info.level
                    rune_info.exp = recv_msg.rune_info.exp

                    --当前符文达到顶级
                    if rune_info.level >= rune_info.template_info.level_limit then
                        --如果品质在指定的范围内
                        for quality2,achieve_type in pairs(constants.RUNE_QUALITY_TO_ACHIEVE) do
                            if rune_info.template_info.quality == quality2 then
                                --更新该成就
                                achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE[string.format("rune_quality%d_max_level",quality2)],1)
                            end
                        end
                    end

                    graphic:DispatchEvent("rune_upgrade_success", start_level, start_exp, rune_info)
                    break
                end
            end

        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --交换符文
    network:RegisterEvent("rune_exchange_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local rune_info1_index = nil
            local rune_info2_index = nil
            for index,rune_info in ipairs(self.rune_list) do
                if rune_info.rune_id == recv_msg.rune_id then
                    rune_info1_index = index
                elseif rune_info.rune_id == recv_msg.rune_id2 then
                    rune_info2_index = index
                end
            end
            local rune_info1_level = self.rune_list[rune_info1_index].level
            local rune_info1_exp = self.rune_list[rune_info1_index].exp
            self.rune_list[rune_info1_index].level = self.rune_list[rune_info2_index].level
            self.rune_list[rune_info1_index].exp = self.rune_list[rune_info2_index].exp
            self.rune_list[rune_info2_index].level = rune_info1_level
            self.rune_list[rune_info2_index].exp = rune_info1_exp

            graphic:DispatchEvent("rune_exchange_success")
            graphic:DispatchEvent("show_prompt_panel", "exchange_success_tips")
        else
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)
end

--获取当前抽取的状态
function rune:GetDrawState()
    return self.is_drawing
end

--设置当前抽取状态
function rune:SetDrawState(state)
    self.is_drawing = state
end

--是否正在移动至背包状态
function rune:GetIsMovingState()
    return self.is_moving
end

--设置正在移动至背包状态
function rune:SetIsMovingState(state)
    self.is_moving = state
end


--检查符文背包空间
function rune:CheckRuneCapacity()
    return #self.rune_list < self.rune_bag_capacity
end

--检查符文背包空间
function rune:CheckRuneTemporaryCapacity()
    return #self.rune_temporary_list < self.rune_temporary_bag_capacity
end

--新符文
function rune:NewRune(rune_id, template_id, level, rune_bag_type)
    local rune_conf = rune_config[template_id]
    local level = level or 1
    local exp = 0
    if rune_conf then
        local rune_info = {}
        rune_info.rune_id = rune_id
        rune_info.template_id = template_id
        rune_info.template_info = rune_conf
        rune_info.equip_pos = 0

        if level > rune_conf.level_limit then
            level = rune_conf.level_limit
        end

         --如果等级为最大等级
        if level >= rune_conf.level_limit then
            --如果不是经验符文
            if not constants.RUNE_ACHIEVE_EXTRA[template_id] then
                --如果品质在指定的范围内
                for quality,achieve_type in pairs(constants.RUNE_QUALITY_TO_ACHIEVE) do
                    if rune_conf.quality == quality then
                        --更新该成就
                        achievement_logic:UpdateStatisticValue(constants.ACHIEVEMENT_TYPE[string.format("rune_quality%d_max_level",quality)],1)
                    end
                end
            end
        end


        if level > 1 then
            local rune_exp_conf = config_manager.rune_exp_config[level]
            if rune_exp_conf and rune_exp_conf[string.format("need_exp_%d", rune_conf.quality)] then
                exp = rune_exp_conf[string.format("need_exp_%d", rune_conf.quality)]
            end
        end

        rune_info.level = level
        rune_info.exp = exp
        rune_info.create_time = time_logic:Now()
        
        if rune_bag_type == constants["RUNE_BAG_TYPE"]["TEMPORARY_BAG"] and self:CheckRuneTemporaryCapacity() then
            table.insert(self.rune_temporary_list, rune_info)
        elseif rune_bag_type == constants["RUNE_BAG_TYPE"]["BAG"] and self:CheckRuneCapacity() then
            table.insert(self.rune_list, rune_info)
        end

        return rune_info
    end
end

--一键收取
function rune:OneKeyReceive(is_auto_compose)
    if #self.rune_temporary_list > 0 then
        self.is_moving = true
        network:Send({ rune_one_key_receive = { is_auto_compose = self.is_selected_auto_compose } })
        return true
    end
    return false
end

--抽符文
function rune:DrawRune( draw_type, go_to_area_4 )
    self:SetDrawState(true)
    if go_to_area_4 == nil then 
        go_to_area_4 = self:IsSelectedAutoGo()
    end
    network:Send({ draw_rune = { draw_type = draw_type, go_to_area_4 = go_to_area_4 } })
end

function rune:IsCanBuyRuneBugCell( is_show_prompt )
    local next_rune_bag_conf = config_manager.rune_bag_config[self.rune_bag_level + 1]

    if next_rune_bag_conf and self.rune_bag_capacity < self.max_rune_bag_capacity then
        return true, next_rune_bag_conf
    else
        if is_show_prompt then
            graphic:DispatchEvent("show_prompt_panel", "max_rune_bag_level")
        end
        return false
    end
end

--得到要买的等级的花费
--param 购买等级的增量
--return 花费的血钻
function rune:GetBuyIndexCost(level_up_num)
    local cost_num = 0
    local get_cell = 0
    if level_up_num and level_up_num > 0 then
        for i=1,level_up_num do
            local next_rune_bag_conf = config_manager.rune_bag_config[self.rune_bag_level + i]
            if next_rune_bag_conf and self.rune_bag_capacity < self.max_rune_bag_capacity then 
                cost_num = cost_num + next_rune_bag_conf.cost_num
                get_cell = next_rune_bag_conf.capacity
            end
        end
    end
    return cost_num,get_cell-self.rune_bag_capacity
end

--还可以升多少级
function rune:GetRuneBagCanUpadge()
    local max_level = #config_manager.rune_bag_config - self.rune_bag_level
    return  math.max(max_level,0)
end

--购买背包
function rune:BuyRuneBugCell(buy_num)
    if buy_num and buy_num > 0 then
        network:Send({ buy_rune_bag_cell = { buy_times = buy_num} })
    end
end

--装备符文
function rune:EquipRune(select_pos, select_rune)
    if select_rune and select_pos >= 1 and select_pos <= constants["MAX_RUNE_EQUIPMENT_NUM"] then
        network:Send({ equip_rune = { rune_id = select_rune.rune_id, equip_pos = select_pos } })
    end
end

--符文升级
function rune:UpgradeRune(target_rune_info, exp_rune_list)
    if target_rune_info and exp_rune_list and #exp_rune_list > 0 then
        local exp_rune_id_list = {}
        for index,exp_rune_info in ipairs(exp_rune_list) do
            table.insert(exp_rune_id_list, exp_rune_info.rune_id)
        end

        network:Send({ upgrade_rune = { rune_id = target_rune_info.rune_id, exp_rune_id_list = exp_rune_id_list } })
    end
end

--符文交换
function rune:ExchangeRuneProperty(rune_id1, rune_id2)
    network:Send({ rune_exchange = { rune_id = rune_id1, rune_id2 = rune_id2 } })
end

--符文交换消耗列表
function rune:GetExchangeCost(quality)
    if self.exchange_cost_list then
        for k,cost_info in pairs(self.exchange_cost_list) do
            if cost_info.quality == quality then
                return cost_info.cost
            end
        end
    end
    return 0
end

--生成已安装的符文记录
function rune:GenerateRuneEquipment()
    self.rune_equipment_list = {}
    for k,rune_info in pairs(self.rune_list) do
        if rune_info.equip_pos > 0 then
            if not self.rune_equipment_list[rune_info.equip_pos] then
                self.rune_equipment_list[rune_info.equip_pos] = rune_info
            else
                --若发现有重复安装位置的符文，则重置符文为未安装状态
                rune_info.equip_pos = 0
            end
        end
    end
end

--获取已安装符文的效果
function rune:GenerateRuneListPropertys(rune_list)
    rune_list = rune_list or {}
    
    local propertys = {}
    for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
        propertys[key] = {}
        for _,property_name in pairs(constants["PROPERTY_TYPE_NAME"]) do
            propertys[key][property_name] = 0
        end
    end

    for _,rune_info in pairs(rune_list) do
        local rune_conf = rune_config[rune_info.template_id]
        local rune_property_conf = config_manager.rune_property_config[rune_info.template_id]
        if rune_conf and rune_property_conf then
            for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
                local property = rune_property_conf[key][rune_info.level]
                if not property then
                    property = rune_property_conf[key][rune_conf.level_limit] or {}
                end
                for property_name,property_value in pairs(property) do
                    if property_value > 0 then
                        property_value = math.ceil(property_value)
                    elseif property_value < 0 then
                        property_value = math.floor(property_value)
                    end
                    propertys[key][property_name] = property_value + (propertys[key][property_name] or 0)
                end
            end
        end
    end
    
    return propertys
end

--获取符文升级后的等级
function rune:GetRunePreviewLevelAndExp(rune_info, exp_rune_list)
    local preview_level = 0
    local preview_exp = 0
    if rune_info and exp_rune_list and #exp_rune_list > 0 then
        preview_level = rune_info.level
        preview_exp = rune_info.exp

        local quality = rune_info.template_info.quality

        for index,exp_rune_info in ipairs(exp_rune_list) do
            preview_exp = preview_exp + exp_rune_info.exp + exp_rune_info.template_info.out_exp
        end

        for level=rune_info.level,rune_info.template_info.level_limit do
            local conf = config_manager.rune_exp_config[level]
            if conf and conf[string.format("need_exp_%d", quality)] then
                if preview_exp >= conf[string.format("need_exp_%d", quality)] then
                    preview_level = level
                    if level >= rune_info.template_info.level_limit then
                        preview_exp = conf[string.format("need_exp_%d", quality)]
                        break
                    end
                else
                    break
                end
            end
        end
    end
    return preview_level, preview_exp
end

--获取符文经验百分比
function rune:GetRuneExpForShow( exp, level, quality )
    local cur_level_conf = config_manager.rune_exp_config[level] or {}
    local next_level_conf = config_manager.rune_exp_config[level + 1] or {}

    local cur_level_exp_limit = cur_level_conf[string.format("need_exp_%d", quality)] or 0
    local next_level_exp_limit = next_level_conf[string.format("need_exp_%d", quality)]

    local show_exp = exp - cur_level_exp_limit
    local show_exp_limit = next_level_exp_limit and (next_level_exp_limit - cur_level_exp_limit) or show_exp

    return show_exp, show_exp_limit
end

--获取符文属性的描述
function rune:GetRunePropertysDesc(template_id, level)
    local propertys_desc_list = {}

    local property_conf = config_manager.rune_property_config[template_id]
    if property_conf then
        for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
            local property = property_conf[key][level] or {}

            for k,property_name in pairs(constants["PROPERTY_TYPE_NAME"]) do
                local property_value = property[property_name] or 0
                if property_value ~= 0 then
                    local desc_name = ""
                    local rune_draw_panel_desc_space = platform_manager:GetChannelInfo().rune_draw_panel_desc_space
                    if rune_draw_panel_desc_space then
                        desc_name = string.format("%s %s %s%d", lang_constants:Get(key), lang_constants:Get(string.format("%s_property", property_name)), property_value > 0 and "+" or "-", math.ceil(math.abs(property_value)))
                    else
                        desc_name = string.format("%s%s%s%d", lang_constants:Get(key), lang_constants:Get(string.format("%s_property", property_name)), property_value > 0 and "+" or "-", math.ceil(math.abs(property_value)))
                    end
                    table.insert(propertys_desc_list, desc_name)
                end
            end
        end
    end

    return table.concat( propertys_desc_list, ", " )
end

--获取符文属性值及文字
function rune:GetRunPropertyValueAndTitle(template_id, level)
    local property_conf = config_manager.rune_property_config[template_id]
    if property_conf then
        for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
            local property = property_conf[key][level] or {}

            for k,property_name in pairs(constants["PROPERTY_TYPE_NAME"]) do
                local property_value = property[property_name] or 0
                if property_value ~= 0 then
                    if property_value < 0 then
                        property_value = math.floor(property_value)
                    else
                        property_value = math.ceil(property_value)
                    end
                    return property_value, lang_constants:Get(string.format("%s_property", property_name))
                end
            end
        end
    end
    return 0, ""
end

return rune