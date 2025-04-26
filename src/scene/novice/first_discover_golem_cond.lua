local client_constants = require "util.client_constants"
local constants = require "util.constants"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local first_discover_golem_cond = { type = NOVICE_TRIGGER_TYPE["first_discover_golem"] }
first_discover_golem_cond.__index = first_discover_golem_cond

function first_discover_golem_cond.New()
    return setmetatable({
    }, first_discover_golem_cond)
end

function first_discover_golem_cond:Check()
    local user_logic = require "logic.user"
    local mining_logic = require "logic.mining"

    if not mining_logic.is_discover_golem then
        return false
    end

    local mark =  - 1
    if user_logic:GetNoviceMark(client_constants["NOVICE_MARK"]["first_discover_golem"]) then
        return false
    end

    user_logic:SetNoviceMark(client_constants["NOVICE_MARK"]["first_discover_golem"], true)
    
    return  true
end

return first_discover_golem_cond
