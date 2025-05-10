local sub_scene_prototype = require "scene.sub_scene"

local function PIPELINE_A(name, panel_name, remember)
    local sub_scene = sub_scene_prototype.New()
    sub_scene.root_panel_name = panel_name

    sub_scene:SetRememberFromScene(remember or false)

    return sub_scene
end

local function PIPELINE_B(name, panel_name, remember)
    local sub_scene = sub_scene_prototype.New()

    sub_scene.root_panel_name = panel_name
    sub_scene:SetRememberFromScene(remember or false)

    function sub_scene:Update(elapsed_time)
        self.ui_root:Update(elapsed_time)
    end

    return sub_scene
end

local function PIPELINE_C(name)
    local sub_scene = require ("scene." .. name)
    return sub_scene
end

local SUB_SCENE_MAP =
{
    ["achievement_sub_scene"] = { PIPELINE_B, "achievement_panel", true },
    ["area_choose_sub_scene"] = { PIPELINE_A, "area_choose_panel", true },

    ["arena_sub_scene"] = { PIPELINE_B, "arena_main_panel", true, },
    ["bbs_detail_sub_scene"] = { PIPELINE_A, "bbs_detail_panel", true },
    ["bbs_new_disscuss_sub_scene"] = { PIPELINE_A, "bbs_new_disscuss_panel", true },
    ["bbs_sub_scene"] = { PIPELINE_B, "bbs_main_panel", true },
    ["campaign_sub_scene"] = { PIPELINE_B, "campaign_main_panel" ,true },
    ["carnival_sub_scene"] = { PIPELINE_B, "carnival.carnival_panel", true },

    ["ladder_sub_scene"] = { PIPELINE_B, "ladder_main_panel", true },

    ["leader_weapon_sub_scene"] = { PIPELINE_A, "leader_weapon_panel", true },
    ["mercenary_choose_sub_scene"] = { PIPELINE_B, "mercenary_choose_panel", true },
    ["mercenary_contract_sub_scene"] = { PIPELINE_B, "mercenary_contract_panel", true },
    ["mercenary_fire_sub_scene"] = { PIPELINE_B, "mercenary_fire_panel", true },

    ["mercenary_levelup_sub_scene"] = { PIPELINE_B, "mercenary_levelup_panel", true},
    ["mercenary_library_sub_scene"] = { PIPELINE_A, "mercenary_library_panel", true },
    ["quest_sub_scene"] = { PIPELINE_A, "quest_panel", true},

    ["temple_sub_scene"] = { PIPELINE_B, "temple_panel", true },
    ["transmigration_sub_scene"] = { PIPELINE_A, "transmigration_panel", true },

    ["mercenary_list_sub_scene"] = { PIPELINE_B, "mercenary_list_panel", true },

    ["merchant_sub_scene"] = { PIPELINE_B, "merchant_panel", true },
    ["payment_sub_scene"] = { PIPELINE_B, "payment_panel", true },
    ["quarry_sub_scene"] = { PIPELINE_B, "quarry_panel", true },
    ["cave_event_sub_scene"] = { PIPELINE_B, "mining_cave_event_panel", true },
    ["social_sub_scene"] = { PIPELINE_B, "social_main_panel", true },
    ["store_sub_scene"] = { PIPELINE_B, "store_panel", true },

    ["mining_sub_scene"] = { PIPELINE_B, "mining_main_panel", true },

    ["sns_sub_scene"] = { PIPELINE_A, "carnival.sns_panel", true },

    ["mercenary_sub_scene"] = { PIPELINE_C },
    ["mining_district_sub_scene"] = { PIPELINE_C },
    ["exploring_sub_scene"] = { PIPELINE_C },
    ["formation_sub_scene"] = { PIPELINE_C },
    ["pvp_sub_scene"] = { PIPELINE_C },
    ["main_sub_scene"] = { PIPELINE_C },
    ["recruit_sub_scene"] = { PIPELINE_C },
    ["guild_sub_scene"] = { PIPELINE_C },
    ["rune_bag_sub_scene"] = { PIPELINE_C },
    ["rune_draw_sub_scene"] = { PIPELINE_C },
    ["rune_upgrade_sub_scene"] = { PIPELINE_C },
    ["rune_equip_sub_scene"] = { PIPELINE_C },
    ["escort_sub_scene"] = { PIPELINE_C },
}

local sub_scene_factory = {}
function sub_scene_factory:Create(name)
    local params = SUB_SCENE_MAP[name]

    local sub_scene = params[1](name, unpack(params, 2))
    sub_scene:Init()

    sub_scene:SetName(name)

    return sub_scene
end

return sub_scene_factory
