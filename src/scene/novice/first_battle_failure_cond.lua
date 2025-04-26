local client_constants = require "util.client_constants"
local constants = require "util.constants"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local first_battle_failure_cond = { type = NOVICE_TRIGGER_TYPE["first_battle_failure"] }
first_battle_failure_cond.__index = first_battle_failure_cond

function first_battle_failure_cond.New()
    return setmetatable({
    }, first_battle_failure_cond)
end

function first_battle_failure_cond:Check()
    local user_logic = require "logic.user"
    local adventure_logic = require "logic.adventure"

    if adventure_logic.cur_area_id ~= 1 then
        return false
    end

    local mark = client_constants["NOVICE_MARK"]["first_battle_failure"]
    if user_logic:GetNoviceMark(mark) then
        return false
    end

    user_logic:SetNoviceMark(mark, true)
    
    return true
end

return first_battle_failure_cond
