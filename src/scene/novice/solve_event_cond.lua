local client_constants = require "util.client_constants"
local campaign_logic = require "logic.campaign"
local troop_logic = require "logic.troop"
local bag_logic = require "logic.bag"

local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]

local solve_event_cond = { type = NOVICE_TRIGGER_TYPE["solve_event"] }
solve_event_cond.__index = solve_event_cond

function solve_event_cond.New(event_id)
    return setmetatable({
        event_id = event_id,
    }, solve_event_cond)
end

function solve_event_cond:Check(event_id)

    if self.event_id ~= event_id then
        return false
    end
    
    if event_id == 1000320 then
        -- 28-5 合战引导
        return campaign_logic:IsOpen()

    elseif event_id == 1000006 then
        -- 2-1 上阵检测是否有空位
        local list = troop_logic:GetFormationMercenaryList(troop_logic:GetCurFormationId())
        return #list < 3

    elseif event_id == 1000010 then
        -- 2-5 上阵检测是否与空位
        local list = troop_logic:GetFormationMercenaryList(troop_logic:GetCurFormationId())
        return #list < 4

    elseif event_id == 1000008 then
        --开宝箱，检测背包空间
        return #bag_logic:GetItemList() == 0

    elseif event_id == 1000012 then
        --佣兵召唤，检测数量
        return troop_logic:GetCampCapacity() > troop_logic:GetCurMercenaryNum()
    elseif event_id == 1000045 then
        local feature_config = require "logic.feature_config"
        return feature_config:IsFeatureOpen("merchant")
    end

    return true
end

return solve_event_cond
