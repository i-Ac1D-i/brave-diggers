local client_constants = require "util.client_constants"
local constants = require "util.constants"
local feature_config = require "logic.feature_config"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local open_panel_cond = { type = NOVICE_TRIGGER_TYPE["first_open_panel"] }
open_panel_cond.__index = open_panel_cond

function open_panel_cond.New(id)
    return setmetatable({panel_id = id}, open_panel_cond)
end

function open_panel_cond:Check(panel_name)
    local user_logic = require "logic.user"
    local achievement_logic = require "logic.achievement"

    local panel_list = client_constants["NOVICE_MARK"]
    local panel_idx = client_constants["NOVICE_MARK"][panel_name]

    if not panel_idx or panel_idx ~= self.panel_id then
        -- 不在引导界面列表中
        return false
    end

    if panel_idx == panel_list["pvp_sub_scene"] and achievement_logic:GetStatisticValue(constants["ACHIEVEMENT_TYPE"]["arena_win1"]) > 0 then
        -- 触发过pvp引导
        return false
    end

    if panel_idx == panel_list["mercenary_library_sub_scene"] and not feature_config:IsFeatureOpen("craft_soul_stone") then
        return false
    end

    if user_logic:GetNoviceMark(panel_idx) then
        -- 界面已经引导过
        return false
    end

    user_logic:SetNoviceMark(panel_idx, true)
    
    return true
end

return open_panel_cond
