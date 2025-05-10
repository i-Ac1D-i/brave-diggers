local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"
local platform_manager = require "logic.platform_manager"
local channel_info = platform_manager:GetChannelInfo()

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local weapon_total_star_config = config_manager.weapon_total_star_config

local star_sub_panel = panel_prototype.New()
star_sub_panel.__index = star_sub_panel
function star_sub_panel.New()
    return setmetatable({}, star_sub_panel)
end

function star_sub_panel:Init(root_node, conf)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(true)

    self.total_star_num_text = root_node:getChildByName("cost_title_0")
    self.total_speed_text = root_node:getChildByName("cost_title_0_0")
    self.total_defense_text = root_node:getChildByName("cost_title_0_0_0")
    self.total_dodge_text = root_node:getChildByName("cost_title_0_0_0_0")
    self.total_authority_text = root_node:getChildByName("cost_title_0_0_0_0_0")

    self.conf = conf
end

function star_sub_panel:Show()
    self.total_star_num_text:setString(self.conf.star_num)
    self.total_speed_text:setString(self.conf.speed)
    self.total_defense_text:setString(self.conf.defense)
    self.total_dodge_text:setString(self.conf.dodge)
    self.total_authority_text:setString(self.conf.authority)
end

local destiny_weapon_total_star_panel = panel_prototype.New(true)
function destiny_weapon_total_star_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/leader_weapon_4_msgbox.csb")

    self.list_view = self.root_node:getChildByName("listview")
    self.template = self.root_node:getChildByName("template")

    for i,conf in ipairs(weapon_total_star_config) do
        local sub_panel = star_sub_panel.New()
        sub_panel:Init(self.template:clone(), conf)
        sub_panel:Show()
        self.list_view:addChild(sub_panel.root_node)
    end

    self.template:setVisible(false)

    self:RegisterWidgetEvent()
end

function destiny_weapon_total_star_panel:Show()
    self.list_view:jumpToTop()
    self.root_node:setVisible(true)
end

function destiny_weapon_total_star_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return destiny_weapon_total_star_panel

