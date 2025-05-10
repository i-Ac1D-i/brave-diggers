local config_manager = require "logic.config_manager"

local lang_constants = require "util.language_constants"
local item_config = config_manager.item_config

local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local adventure_logic = require 'logic.adventure'
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local panel_prototype = require "ui.panel"
local panel_util= require "ui.panel_util"

local icon_template = require "ui.icon_panel"

local AREA_DIFFICULTY_LEVEL = constants.AREA_DIFFICULTY_LEVEL

local DIFF_INTERVAL = 58
local MERCENARY_INTERVAL = 82
local DIFF_MERCENARY_INTERVAL = 105

local POSTION_XS = { 320, 184, 454 }

local loot_preview_panel = panel_prototype.New(true)

function loot_preview_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/loot_info_msgbox.csb")

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.mercenary_sub_panels = {}

    self.cur_area_id = nil
    self.cur_difficulty = nil

    for i = 1, 3 do
        local sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
        sub_panel:Init(self.root_node, true)

        sub_panel.root_node:setPosition(POSTION_XS[i], 357)
        self.mercenary_sub_panels[i] = sub_panel
    end

    self:RegisterWidgetEvent()
end

function loot_preview_panel:Show(cur_area_id, cur_difficulty)

    self.root_node:setVisible(true)

    if self.cur_area_id == cur_area_id and self.cur_difficulty == cur_difficulty then
        return
    end

    self.cur_area_id = cur_area_id
    self.cur_difficulty = cur_difficulty

    local area_conf = config_manager.area_info_config[cur_area_id]

    if cur_difficulty == constants["AREA_DIFFICULTY_LEVEL"]["easy"] then
        self:Load(AREA_DIFFICULTY_LEVEL["easy"], area_conf.easy_loot)

    elseif cur_difficulty == constants["AREA_DIFFICULTY_LEVEL"]["normal"]then
        self:Load(AREA_DIFFICULTY_LEVEL["normal"], area_conf.normal_loot)
    else
        self:Load(AREA_DIFFICULTY_LEVEL["hard"], area_conf.hard_loot)
    end
end

function loot_preview_panel:Load(difficulty, loot_info)

    if loot_info == "" then
        return
    end

    local index = 0

    for mercenary_template_id in string.gmatch(loot_info, "(%d+)") do
        index = index + 1
        local sub_panel = self.mercenary_sub_panels[index]
        sub_panel.root_node:setTag(tonumber(mercenary_template_id))
        sub_panel:Show(constants.REWARD_TYPE["mercenary"], tonumber(mercenary_template_id), nil, nil, true)
    end
end

function loot_preview_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, "loot_preview_panel")
end

return loot_preview_panel
