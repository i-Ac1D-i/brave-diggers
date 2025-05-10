local client_constants = require "util.client_constants"
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local first_use_feature_cond= { type = NOVICE_TRIGGER_TYPE["first_use_feature"] }
first_use_feature_cond.__index = first_use_feature_cond

function first_use_feature_cond.New(mark)
    return setmetatable({
        feature_mark = mark
    }, first_use_feature_cond)
end

function first_use_feature_cond:Check(mark)
    local user_logic = require "logic.user"

    if mark ~= self.feature_mark then
        return false
    end

    if mark == client_constants.FEATURE_TYPE["merchant"] then
        local feature_config = require "logic.feature_config"
        if not feature_config:IsFeatureOpen("merchant") then
            return false
        end
    end

    return not user_logic:GetNoviceMark(self.feature_mark)
end

return first_use_feature_cond
