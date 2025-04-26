local client_constants = require "util.client_constants"
local user_logic = require "logic.user"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local create_leader_cond = { type = NOVICE_TRIGGER_TYPE["create_leader"] }
function create_leader_cond.New()
    return create_leader_cond
end

function create_leader_cond:Check()
    if user_logic:IsJustCreateLeader() then
        user_logic:SetJustCreateLeader(false)
        return true
    end

    return false
end

return create_leader_cond
