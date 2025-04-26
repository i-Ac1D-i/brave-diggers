local network = require "util.network"

local reward_logic
local resource_logic
local user_logic
local troop_logic
local time_logic
local daily_logic

local constants = require "util.constants"
local config_manager = require "logic.config_manager"

local mercenary_config = config_manager.mercenary_config

local graphic = require "logic.graphic"

local temple = {}
function temple:Init()
    reward_logic = require "logic.reward"
    resource_logic = require "logic.resource"
    user_logic = require "logic.user"
    troop_logic = require "logic.troop"
    time_logic = require "logic.time"
    daily_logic = require "logic.daily"

    self.has_query = false

    self.temple_mercenarys = {}
    self.recruit_merceanry_id = 0

    self.temple_time = 0
    self.temple_mercenary_num = 0

    self:RegisterMsgHandler()
end

function temple:GetTempleMercenarys()
    return self.temple_mercenarys
end
function temple:GetTempleMercenaryPrice(mercenary_id)
    return self.temple_mercenarys[mercenary_id].new_price
end

function temple:DailyClear()
    self.has_query = false
    self.temple_time = 0
end

function temple:MercenaryQuery()

    if not self.has_query then
        network:Send({ query_temple_mercenary = {}})
    else
        graphic:DispatchEvent("show_world_sub_scene", "temple_sub_scene")
    end
end

function temple:RecruitMercenary(mercenary_id)
    if not troop_logic:CheckMercenaryNum() then
        return
    end

    --招募每日限制
    if daily_logic:GetDailyTag(constants.DAILY_TAG["temple_recruit"]) then
        graphic:DispatchEvent("show_prompt_panel", "temple_not_enough_recruit_count")
        return
    end

    --灵魂碎片消耗判断
    local mercenary = self.temple_mercenarys[mercenary_id]
    if resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["soul_chip"], mercenary.new_price, true) then
        self.recruit_merceanry_id = mercenary_id
        network:Send({ recruit_temple_mercenary = { template_id = mercenary_id, quality = mercenary.new_quality } })
    end
end

function temple:Load(mercenarys)
    --清空神殿英雄
    for k, v in pairs(self.temple_mercenarys) do
        self.temple_mercenarys[k] = nil
    end

    --重新加载神殿英雄
    for i, mercenary in ipairs(mercenarys) do
        local template_id = mercenary.template_id
        local mercenary_template = mercenary_config[template_id]
        mercenary_template.new_price = mercenary.new_price

        --神殿自定义的quality
        mercenary_template.new_quality = mercenary.quality
        self.temple_mercenarys[template_id] = mercenary_template
    end
end

function temple:RegisterMsgHandler()
    network:RegisterEvent("query_temple_mercenary_ret", function(msg)
        print("query_temple_mercenary_ret")
        if not msg.mercenarys then
            return
        end
        
        self:Load(msg.mercenarys)

        if not self.has_query then
            self.has_query = true
            graphic:DispatchEvent("show_world_sub_scene", "temple_sub_scene")
        end
    end)

    network:RegisterEvent("refresh_temple_ret", function(msg)
        if not msg.mercenarys then
            return
        end
        
        self:Load(msg.mercenarys)
    end)

    network:RegisterEvent("recruit_temple_mercenary_ret", function(msg)
        print("recruit_temple_mercenary_ret")
        if msg.result == "success" then
            daily_logic:SetDailyTag(constants.DAILY_TAG["temple_recruit"], true)

            graphic:DispatchEvent("show_world_sub_panel", "reward_panel")
            graphic:DispatchEvent("temple_recruit_success")

        elseif msg.result == "today_cant_recruit" then
            graphic:DispatchEvent("show_prompt_panel", "temple_not_enough_recruit_count")

        elseif msg.result == "resource_is_not_enough" then
            resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["soul_chip"])

        elseif msg.result == "mercenary_not_in_temple" then
            graphic:DispatchEvent("show_prompt_panel", "temple_mercenary_not_exist")

        elseif msg.result == "not_enough_mercenary_space" then
            graphic:DispatchEvent("show_prompt_panel", "troop_not_enough_mercenary_space", troop_logic:GetCampCapacity())

        else
            graphic:DispatchEvent("show_prompt_panel", "temple_not_enough_recruit_count")
        end
    end)
end

return temple
