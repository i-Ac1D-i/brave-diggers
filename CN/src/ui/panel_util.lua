local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local resource_logic = require "logic.resource"

local user_logic = require "logic.user"
local troop_logic = require "logic.troop"
local time_logic = require "logic.time"
local guild_logic = require "logic.guild"

local config_manager = require "logic.config_manager"

local skill_manager = require "logic.skill_manager"

local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local cooperative_skill_config = config_manager.cooperative_skill_config

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local MERCENARY_TEMPLATE_PANEL_SOURCE = client_constants["MERCENARY_TEMPLATE_PANEL_SOURCE"]
local CONFIRM_MSGBOX_MODE = client_constants["CONFIRM_MSGBOX_MODE"]

local MERCENARY_MSGBOX = client_constants["MERCENARY_MSGBOX"]
local SKILL_BG_IMG_PATH = client_constants["SKILL_BG_IMG_PATH"]
local NO_SKILL_BG_IMG_PATH = client_constants["NO_SKILL_BG_IMG_PATH"]

local COST_RESOURCE_IMG_POS_X = 320   -- 消耗资源居中位置
local COST_RESOURCE_IMG_INTEVAL_X = 90 --间隔像素

local PASSIVE_SKILL_ICON_PATH = client_constants["PASSIVE_SKILL_ICON_PATH"]
local ACTIVE_SKILL_ICON_PATH = client_constants["ACTIVE_SKILL_ICON_PATH"]

local TIP_STATUS = client_constants["GUILDWAR_TIP_STATUS"]
local CLIENT_GUILDWAR_STATUS = client_constants["CLIENT_GUILDWAR_STATUS"]

local SORT_TYPE = client_constants["SORT_TYPE"]

local bit = require "bit"
local bit_rshift = bit.rshift
local bit_band = bit.band

local panel_util = {}

function panel_util:LoadCostResourceInfo(config, sub_panels, pos_y, widget_num, pos_x, is_not_cost)
    local cost_type_num = 0
    local resource_is_enough = true
    if is_not_cost == nil then
        is_not_cost = true
    end

    --要消耗资源的字段
    local resource_havre_params = {}
    for resource_type,resource_type_name in ipairs(constants["RESOURCE_TYPE_NAME"]) do
        local need_resource_num = config[resource_type_name]

        if need_resource_num and need_resource_num > 0 then
            cost_type_num = cost_type_num + 1
            table.insert(resource_havre_params,resource_type_name)

            if cost_type_num > widget_num then
                return
            end

            sub_panels[cost_type_num]:Show(constants.REWARD_TYPE["resource"], resource_type, need_resource_num, is_not_cost, false)
            resource_is_enough = resource_is_enough and resource_logic:CheckResourceNum(resource_type, need_resource_num, false)
        end
    end
    self:SetIconSubPanelsPosition(sub_panels, widget_num, cost_type_num, pos_y, pos_x)
    return cost_type_num, resource_is_enough, resource_havre_params
end

--设定icon_template clone出的sub_panel 的位置
function panel_util:SetIconSubPanelsPosition(sub_panels, max_num, cur_show_num, pos_y, pos_x)
    local left_num = math.floor(cur_show_num/2)
    local begin_x

    pos_x = pos_x or COST_RESOURCE_IMG_POS_X

    local interval = cur_show_num <= 4 and 86 or 76
    --sub_panel的锚点为0.5, 0.5

    if cur_show_num % 2 == 0 then
        begin_x = pos_x - (left_num - 0.5) * interval

    else
        begin_x = pos_x - left_num * interval
    end

    for i = 1, max_num do
        local pos_x = begin_x + interval * (i - 1)
        sub_panels[i]:SetPosition(pos_x, pos_y)
    end

    for i = cur_show_num + 1, max_num do
        sub_panels[i]:Hide()
    end
end

function panel_util:GetTimeHour(duration)
    local hour = math.floor(duration / (60 * 60))

    return hour
end

function panel_util:GetTimeStr(duration, not_show_hour)
    duration = math.ceil(duration)

    local hour = math.floor(duration / (60 * 60))
    local hour_mod = duration % (60 * 60)
    local minute = math.floor(hour_mod / 60)
    local second = hour_mod % 60

    local time_str = ""
    if not not_show_hour then
        time_str = hour ..":"
    end

    if minute < 10 then
        time_str = time_str .. "0" .. minute ..":"
    else
        time_str = time_str .. minute ..":"
    end

    if second < 10 then
        time_str = time_str .. "0" .. second
    else
        time_str = time_str .. second
    end

    return time_str
end

function panel_util:GetSkillDesc(property_desc, value)
    if not value or value == 0 then
        return ""
    end
    value = value > 0 and ("+" .. value) or value
    return lang_constants:Get(property_desc) .. tostring(value) .. " "
end

--佣兵技能
function panel_util:ParseSkillInfo(template_id, skills_info)
    local mer_template_info = config_manager.mercenary_config[template_id]
    --个人
    local skill_info, _, skill_icon = panel_util:GetSkillInfo(mer_template_info.skill1)
    local name, desc, icon, has_skill, active_num = "", "", "", false, 0

    if skill_info then
        name = string.format(lang_constants:Get("mercenary_single_skill_name"), skill_info.name)
        desc = skill_info.desc
        icon = skill_icon
        has_skill = true

        active_num = skill_info.times_limit
    else
        name = lang_constants:Get("mercenary_no_skill_name_short")
        desc = lang_constants:Get("mercenary_no_skill")
        icon = NO_SKILL_BG_IMG_PATH
        has_skill = false
    end

    skills_info[1].id = mer_template_info.skill1
    skills_info[1].name = name
    skills_info[1].desc = desc
    skills_info[1].has_skill = has_skill
    skills_info[1].icon = icon
    skills_info[1].can_use = false
    skills_info[1].active_num = active_num

    self:ParseCoopSkillInfo(template_id, skills_info)
    self:ParsArtifactSkillInfo(template_id, skills_info)
end

--合体技
function panel_util:ParseCoopSkillInfo(template_id, skills_info)
    local mer_template_info = config_manager.mercenary_config[template_id]
    local name, desc, icon, has_skill, can_use, active_num = "", "", "", false, false, 0

    for i = 1, 2 do
        local coop_skill_id = mer_template_info["ex_skill" .. i]
        skills_info[i + 1].id = coop_skill_id

        if coop_skill_id ~= 0 then
            local coop_skill_template_info = cooperative_skill_config[coop_skill_id]
            name = string.format(lang_constants:Get("mercenary_coop_skill_name"), coop_skill_template_info.name)
            desc = coop_skill_template_info.desc
            has_skill = true
            active_num = coop_skill_template_info.times_limit

            local _, _, skill_icon = panel_util:GetSkillInfo(coop_skill_template_info.real_skill1)
            icon = skill_icon
            can_use = skill_manager:CheckCoopSkillCanUse(troop_logic, coop_skill_id)

        else
            name = nil
            desc = nil
            has_skill = false
            icon = NO_SKILL_BG_IMG_PATH
            can_use = false
        end

        skills_info[i + 1].name = name
        skills_info[i + 1].desc = desc
        skills_info[i + 1].has_skill = has_skill
        skills_info[i + 1].icon = icon
        skills_info[i + 1].can_use = can_use
        skills_info[i + 1].active_num = active_num

    end
end

--将宝具加成伪造成一个技能
function panel_util:ParsArtifactSkillInfo(template_id, skills_info)
    local mer_template_info = config_manager.mercenary_config[template_id]
    local name, desc, icon, icon1 = "", "", "", ""
    --宝具技
    skills_info[4].has_skill = mer_template_info.have_artifact

    if skills_info[4].has_skill then
        --判断宝具加成
        desc = desc .. self:GetSkillDesc("mercenary_speed", mer_template_info.artifact_speed)
        desc = desc .. self:GetSkillDesc("mercenary_defense", mer_template_info.artifact_defense)
        desc = desc .. self:GetSkillDesc("mercenary_dodge", mer_template_info.artifact_dodge)
        desc = desc .. self:GetSkillDesc("mercenary_authority", mer_template_info.artifact_authority)

        name = string.format(lang_constants:Get("mercenary_artifact_skill_name"), mer_template_info.artifact_name)
        icon1 =  client_constants["ARTIFACT_ICON_PATH"] .. mer_template_info.artifact_icon
        icon = SKILL_BG_IMG_PATH

    else
        name = nil
        desc = nil
        icon = NO_SKILL_BG_IMG_PATH
    end

    skills_info[4].name = name
    skills_info[4].desc = desc
    skills_info[4].icon = icon
    skills_info[4].artifact_icon = icon1
end

--获取技能信息
function panel_util:GetSkillInfo(skill_id)
    if skill_id >= constants["ACTIVE_SKILL_ID_OFFSET"] then
        local skill = config_manager.active_skill_config[skill_id]
        if skill then
            return skill, false, ACTIVE_SKILL_ICON_PATH[skill.effect_type]
        end
    else
        local skill = config_manager.passive_skill_config[skill_id]
        if skill then
            return skill, true, PASSIVE_SKILL_ICON_PATH[skill.effect_type]
        end
    end
end

--关闭弹窗
function panel_util:RegisterCloseMsgbox(widget, panel_name)
    widget:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", panel_name)
        end
    end)
end

--佣兵界面弹窗显示
function panel_util:ShowMercenaryMsgBox(msgbox_type, mercenary_id, is_leader, param1)
    if msgbox_type == MERCENARY_MSGBOX["wakeup"] then
        if user_logic:IsFeatureUnlock(FEATURE_TYPE["wakeup"]) then
            graphic:DispatchEvent("show_world_sub_panel", "mercenary_wakeup_panel", mercenary_id)
        end

    elseif msgbox_type == MERCENARY_MSGBOX["weapon"] then
        if user_logic:IsFeatureUnlock(FEATURE_TYPE["forge"]) then
            if is_leader then
                graphic:DispatchEvent("show_world_sub_panel", "destiny_forge_panel")
            else
                graphic:DispatchEvent("show_world_sub_panel", "mercenary_weapon_panel", mercenary_id, param1)
            end
        end

    elseif msgbox_type == MERCENARY_MSGBOX["fire"] then
        if is_leader then
            graphic:DispatchEvent("show_prompt_panel", "leader_cant_fire")
        else
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", CONFIRM_MSGBOX_MODE["fire_mercenary"], mercenary_id)
        end
    end
end

--根据英雄品质设定佣兵的名称颜色
function panel_util:SetMercenaryNameColor(widget, mercenary_template, is_show_name)
    local quality = mercenary_template.quality
    local name = mercenary_template.name

    if is_show_name then
        widget:setString(name)
    else
        widget:setString(lang_constants:Get(string.format("mercenary_quality%d", quality)))
    end

    self:SetTextOutline(widget)
    widget:setColor(self:GetColor4B(client_constants["TEXT_QUALITY_COLOR"][quality]))
end

--将color_string, 解析为color4b
local color_4b = {a = 0, r = 0, g = 0, b = 0}
function panel_util:GetColor4B(color, alpha_value)
    color_4b.a = alpha_value or 255
    color_4b.r = bit_band(bit_rshift(color, 16), 0xff)
    color_4b.g = bit_band(bit_rshift(color, 8), 0xff)
    color_4b.b = bit_band(color, 0xff)

    return color_4b
end

--设定字体描边
function panel_util:SetTextOutline(widget, color, outline_width, font_interval)
    if widget then
        local color_str =  color or 0x000000
        local outline_width =  outline_width or 3
        local font_interval = font_interval or -3

        widget:enableOutline(self:GetColor4B(color_str, 255), outline_width)
        if not platform_manager:GetChannelInfo().is_open_system then
           widget:getVirtualRenderer():setAdditionalKerning(font_interval)
        end
    end
end

--设置字体取消所有的效果，如描边，阴影等
function  panel_util:disableEffect(widget)
    widget:disableEffect()
    if not platform_manager:GetChannelInfo().is_open_system then
        widget:getVirtualRenderer():setAdditionalKerning(0)
    end
end

--保留两位小数
function panel_util:KeepTwoDecimalPlace(unit, value)
    local temp = value / unit

    return math.floor(temp * 100) / 100
end

--单位换算
function panel_util:ConvertUnit(value, value_widget, add_minus_sign)
    local unit = ""

    if value < client_constants["UNIT"]["K"] then

    elseif value < client_constants["UNIT"]["M"] then
        --千
        value = self:KeepTwoDecimalPlace(client_constants["UNIT"]["K"], value)
        unit = "K"

    elseif value < client_constants["UNIT"]["B"] then
        --百万
        value = self:KeepTwoDecimalPlace(client_constants["UNIT"]["M"], value)
        unit = "M"

    else
        --十亿
        value = self:KeepTwoDecimalPlace(client_constants["UNIT"]["B"], value)
        unit = "B"

    end

    if add_minus_sign then
        value = "-" .. value
    else
        value = tostring(value)
    end

    value = value .. unit

    -- 根据语言调整小数点格式
    local language = platform_manager:GetLocale()
    if language == "de" or language == "fr" or language == "es-MX" or language == "ru" and platform_manager:GetChannelInfo().panel_util_change_language_dot_format then
        value = self:SetFormatWithPoint(value)
    end

    if value_widget then
        value_widget:setString(value)
    end

    return value

end

-- 根据语言调整小数点格式
function panel_util:SetFormatWithPoint(value)
    return string.gsub(value, "%.", ",")
end

function panel_util:GetLastLoginTimeStr(last_login_time)
    local cur_time = time_logic:Now()

    local cur_day, cur_hour, cur_minute = math.ceil(cur_time / (24 * 60 * 60) ), math.ceil(cur_time / (60 * 60)), math.ceil(cur_time / 60)

    local last_day, last_hour, last_minute = math.ceil(last_login_time / (24 * 60 * 60) ), math.ceil(last_login_time / (60 * 60)), math.ceil(last_login_time / 60)

    local day = cur_day - last_day
    local hour = cur_hour - last_hour
    local minute = cur_minute - last_minute

    if day > 0 then
        return string.format(lang_constants:Get("last_login_time_day"), day)
    elseif hour > 0 then
        return string.format(lang_constants:Get("last_login_time_hour"), hour)
    elseif minute > 0 then
        return string.format(lang_constants:Get("last_login_time_minute"), minute)
    else
        return lang_constants:Get("last_login_time_second")
    end
end

--契约当前加成
function panel_util:GetContactPropertyDesc(instance_id)

    local mercenary = troop_logic:GetMercenaryInfo(instance_id)
    local conf = troop_logic:GetContractConf(instance_id, mercenary.contract_lv)

    if conf then
        local desc = ""
        desc = desc .. self:GetSkillDesc("mercenary_speed", conf.speed)
        desc = desc .. self:GetSkillDesc("mercenary_defense", conf.defense)
        desc = desc .. self:GetSkillDesc("mercenary_dodge", conf.dodge)
        desc = desc .. self:GetSkillDesc("mercenary_authority", conf.authority)

        return desc
    end

    return lang_constants:Get("mercenary_contract_state2")
end

--契约最终加成
function panel_util:GetMaxContractLvProperty(template_id)
    local  mercenary_contract_config = config_manager.mercenary_contract_config
    for i = #mercenary_contract_config, 1, -1 do
        local conf = mercenary_contract_config[i][template_id]
        if conf then
            local desc = ""
            desc = desc .. self:GetSkillDesc("mercenary_speed", conf.speed)
            desc = desc .. self:GetSkillDesc("mercenary_defense", conf.defense)
            desc = desc .. self:GetSkillDesc("mercenary_dodge", conf.dodge)
            desc = desc .. self:GetSkillDesc("mercenary_authority", conf.authority)

            return desc
        end
    end

    return lang_constants:Get("mercenary_contract_state2")
end

function panel_util:GetLeaderContractInfo()
    local index = troop_logic:GetLeaderContractConfIndex()
    local desc = ""
    local title = string.format(lang_constants:Get("leader_contract_lv"), index)
    if index == 0 then
        desc = lang_constants:Get("leader_not_contrart")
        return title, desc
    end

    local conf = config_manager.leader_contract_config[index]
    desc = desc .. lang_constants:Get("leader_contract_add_bp") .. "+" .. conf.bp .. " "
    desc = desc .. self:GetSkillDesc("mercenary_speed", conf.speed)
    desc = desc .. self:GetSkillDesc("mercenary_defense", conf.defense)
    desc = desc .. self:GetSkillDesc("mercenary_dodge", conf.dodge)
    desc = desc .. self:GetSkillDesc("mercenary_authority", conf.authority)

    return title, desc
end

local is_mine_fomation = false

local all_sort_method =
{
    [SORT_TYPE["bp"]] = function(mercenary1, mercenary2)

        --主角排最前面
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            if troop_logic:IsMercenaryInMineFormation(mercenary1) and not troop_logic:IsMercenaryInMineFormation(mercenary2) then
                return false
            elseif not troop_logic:IsMercenaryInMineFormation(mercenary1) and troop_logic:IsMercenaryInMineFormation(mercenary2) then
                return true
            end
        end

        if mercenary1.battle_point == mercenary2.battle_point then
            return mercenary1.template_info.ID < mercenary2.template_info.ID
        else
            return mercenary1.battle_point > mercenary2.battle_point
        end
    end,

    [SORT_TYPE["wakeup"]] = function(mercenary1, mercenary2)
        --主角排最前面
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        if mercenary1.wakeup == mercenary2.wakeup then
            return mercenary1.template_info.ID < mercenary2.template_info.ID
        else
            return mercenary1.wakeup > mercenary2.wakeup
        end
    end,

    [SORT_TYPE["quality"]] = function(mercenary1, mercenary2)
        --主角排最前面
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        if mercenary1.template_info.quality == mercenary2.template_info.quality then
            return mercenary1.template_info.ID < mercenary2.template_info.ID
        else
            return mercenary1.template_info.quality > mercenary2.template_info.quality
        end
    end,

    [SORT_TYPE["level"]] = function(mercenary1, mercenary2)

        --主角排最前面
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        if mercenary1.level == mercenary2.level then
            return mercenary1.template_info.ID < mercenary2.template_info.ID
        else
            return mercenary1.level > mercenary2.level
        end
    end,

    [SORT_TYPE["contract"]] = function(mercenary1, mercenary2)
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        local contract_conf1 = troop_logic:CanContractLv(mercenary1.template_info.ID)
        local contract_conf2 = troop_logic:CanContractLv(mercenary2.template_info.ID)

        if contract_conf1 and not contract_conf2 then
            return true
        end

        if contract_conf2 and not contract_conf1 then
            return false
        end

        if contract_conf1 and contract_conf2 then
            if mercenary1.contract_lv ~= mercenary2.contract_lv then
                return mercenary1.contract_lv > mercenary2.contract_lv
            end

            if mercenary1.template_info.quality == mercenary2.template_info.quality then
                if  mercenary1.contract_lv == mercenary2.contract_lv then
                    return mercenary1.template_info.ID < mercenary2.template_info.ID
                else
                    return mercenary1.contract_lv > mercenary2.contract_lv
                end
            else
                return mercenary1.template_info.quality > mercenary2.template_info.quality
            end
        end

        if not contract_conf1 and not contract_conf2 then
            local template_info1, template_info2 = mercenary1.template_info, mercenary2.template_info

            if template_info1.quality == template_info2.quality then
                return template_info1.ID < template_info2.ID
            else
                return template_info1.quality > template_info2.quality
            end
        end
    end,

    [SORT_TYPE["genre"]] = function(mercenary1, mercenary2)
        --主角排最前面
        if mercenary1.is_leader then
            return true
        elseif mercenary2.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        local template_info1 = mercenary1.template_info
        local template_info2 = mercenary2.template_info

        if template_info1.genre ~= template_info2.genre then
            return template_info1.genre < template_info2.genre
        end

        if template_info1.quality ~= template_info2.quality then
            return template_info1.quality > template_info2.quality
        end

        if template_info1.ID == template_info2.ID then
            return mercenary1.battle_point > mercenary2.battle_point
        else
            return template_info1.ID > template_info2.ID
        end
    end,

    [SORT_TYPE["recommend"]] = function(mercenary_front, mercenary_back)
        --主角排最前面
        if  mercenary_front.is_leader then
            return true
        elseif mercenary_back.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        local template_front = mercenary_front.template_info
        local template_back = mercenary_back.template_info

        --战力系数
        if template_front.bp_factor ~= template_back.bp_factor then
            return template_front.bp_factor > template_back.bp_factor
        end

        --品质
        if template_front.quality ~= template_back.quality then
             return template_front.quality > template_back.quality
         end

         --战力
         if mercenary_front.battle_point ~= mercenary_back.battle_point then
             return mercenary_front.battle_point > mercenary_back.battle_point 
         end

         --流派
         if template_front.genre == 1 and template_back.genre == 1 then 
             -- ID 
             if template_front.ID == template_back.ID then 
                 --获得先后
                 return mercenary_front.instance_id < mercenary_back.instance_id
             else
                 return template_front.ID > template_back.ID
             end

         else
             if template_front.genre == 1 then 
                 return template_front.genre < template_back.genre

             elseif template_back.genre == 1 then 
                 return template_back.genre < template_front.genre
             else 
                 -- ID 
                 if template_front.ID == template_back.ID then 
                     --获得先后
                     return mercenary_front.instance_id < mercenary_back.instance_id
                 else
                     return template_front.ID > template_back.ID
                 end
             end
         end
    end,

    [SORT_TYPE["recommend_by_skill"]] = function(mercenary_front, mercenary_back)
        --主角排最前面
        if  mercenary_front.is_leader then
            return true
        elseif mercenary_back.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        local template_front = mercenary_front.template_info
        local template_back = mercenary_back.template_info

        --技能率
        if template_front.use_skill_percent ~= template_back.use_skill_percent then
            return template_front.use_skill_percent > template_back.use_skill_percent
        end
        
        --强度
        if template_front.strength ~= template_back.strength then 
            return template_front.strength > template_back.strength
        end

        --战力
        if mercenary_front.battle_point == mercenary_back.battle_point then
            --获得先后
            return mercenary_front.instance_id < mercenary_back.instance_id
        else
            return mercenary_front.battle_point > mercenary_back.battle_point 
        end
    end,

    [SORT_TYPE["strength"]] = function(mercenary_front, mercenary_back)
        --主角排最前面
        if  mercenary_front.is_leader then
            return true
        elseif mercenary_back.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end

        local template_front = mercenary_front.template_info
        local template_back = mercenary_back.template_info

           --强度
        if template_front.strength ~= template_back.strength then
            return template_front.strength > template_back.strength
        end

        --技能率
        if template_front.use_skill_percent ~= template_back.use_skill_percent then
            return template_front.use_skill_percent > template_back.use_skill_percent
        end
        
        --战力
        if mercenary_front.battle_point == mercenary_back.battle_point then
            --获得先后
            return mercenary_front.instance_id < mercenary_back.instance_id
        else
            return mercenary_front.battle_point > mercenary_back.battle_point 
        end
    end,

    [SORT_TYPE["passive_strength"]] = function(mercenary_front, mercenary_back)
        --主角排最前面
        if  mercenary_front.is_leader then
            return true
        elseif mercenary_back.is_leader then
            return false
        end

        if is_mine_fomation then
            --是否已经上阵
            local mercenary1_mine_status1, mercenary1_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary1)
            local mercenary2_mine_status1, mercenary2_mine_status2 = troop_logic:IsMercenaryInMineFormation(mercenary2)

            if mercenary1_mine_status2 and not mercenary2_mine_status2 then
                return true
            elseif not mercenary1_mine_status2 and mercenary2_mine_status2 then
                return false
            end


            if mercenary1_mine_status1 and not mercenary2_mine_status1 then
                return false
            elseif not mercenary1_mine_status1 and mercenary2_mine_status1 then
                return true
            end
        end


        local template_front = mercenary_front.template_info
        local template_back = mercenary_back.template_info

        --强度
        if template_front.passive_strength ~= template_back.passive_strength then
            return template_front.passive_strength > template_back.passive_strength
        end
        
        --战力
        if mercenary_front.battle_point == mercenary_back.battle_point then
            --获得先后
            return mercenary_front.instance_id < mercenary_back.instance_id
        else
            return mercenary_front.battle_point > mercenary_back.battle_point 
        end
    end,
}


function panel_util:SortMercenary(sort_type, mercenary_list, is_mine)
    is_mine_fomation = is_mine
    local sort_method = all_sort_method[sort_type]
    table.sort(mercenary_list, sort_method)
end

--返回佣兵介绍 (品质，性别，种族，工作)
function panel_util:GetMercenaryIntroduction(mercenary)
    return string.format(lang_constants:Get("mercenary_job_desc"), lang_constants:Get("mercenary_quality" .. mercenary.quality),
        lang_constants:GetSex(mercenary.sex),
        lang_constants:GetRace(mercenary.race),
        lang_constants:GetJob(mercenary.job)
    )
end

function panel_util:GetDiffTimeStr(diff_time)
    if diff_time < 3600 then
        return lang_constants:Get("time_1")
    elseif diff_time < 86400 then --小时描述
        local hour = diff_time / 60 / 60
        return string.format(lang_constants:Get("time_2"), math.floor(hour))
    elseif diff_time < 5184000 then -- 天描述
        local day = diff_time / 60 / 60 / 24
        return string.format(lang_constants:Get("time_3"), math.floor(day))
    else
        return lang_constants:Get("time_4")
    end
end

function panel_util:GetDateByUtf(utf_value)
    local date_table = os.date("*t", utf_value)
    return date_table
end

function panel_util:GetGuildWarStatus()
    local status, time = guild_logic:GetCurStatusAndRemainTime()
    
    if status == CLIENT_GUILDWAR_STATUS["NONE"] then

    elseif status == CLIENT_GUILDWAR_STATUS["READY"] then

    elseif status == CLIENT_GUILDWAR_STATUS["WAIT_ENTER"] then
        if guild_logic:IsEnterForCurrentWar() then
            status = CLIENT_GUILDWAR_STATUS["WAIT_TROOP"]
            time = guild_logic:GetRoundTimeInfo(status)
        end
    elseif status == CLIENT_GUILDWAR_STATUS["WAIT_TROOP"] then

    elseif status == CLIENT_GUILDWAR_STATUS["MATCHING"] then

    elseif status == CLIENT_GUILDWAR_STATUS["WAIT_FINISH"] then

    end

    return status, time
end

-- 血钻不足时，弹出充值界面
function panel_util:CheckBloodDiamond(need_num)
    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], need_num, true) then

        graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("blood_diamond_not_enough"),
            lang_constants:Get("blood_diamond_not_enough_desc"),
            lang_constants:Get("common_confirm"),
            lang_constants:Get("common_cancel"),
        function()
            graphic:DispatchEvent("hide_all_sub_panel")
            graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene")
        end)
        return false
    end
    return true
end

function panel_util:GetGenreInfos( genre_nums )
    local all_num = 0
    local genre_infos = {}
    all_num = tonumber(string.match(genre_nums, "(%d+)#"))
    if all_num then
        for genre, num in string.gmatch(genre_nums, "(%d+),(%d+),") do
            genre_infos[tonumber(genre)] = tonumber(num)
        end
    end
    all_num = all_num or 0
    return all_num, genre_infos
end

function panel_util:strSplit(str, sep)
    local t = {} 
    for s in string.gmatch(str, "([^".. sep .."]+)") do
        t[#t + 1] = s
    end
    return t
end

return panel_util
