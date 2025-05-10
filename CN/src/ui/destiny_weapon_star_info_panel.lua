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

local destiny_logic = require "logic.destiny_weapon"

local PLIST_TYPE = ccui.TextureResType.plistType
local destiny_skill_config = config_manager.destiny_skill_config

local destiny_weapon_star_info_panel = panel_prototype.New(true)
function destiny_weapon_star_info_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/leader_weapon_stars_up_success_msgbox.csb")

    self.star_num_text = self.root_node:getChildByName("output")
    self.add_bp_text = self.root_node:getChildByName("bp")

    self.property_node = self.root_node:getChildByName("title_bg1_0")
    self.speed_text = self.property_node:getChildByName("title_2_1")
    self.defense_text = self.property_node:getChildByName("title_2_1_0")
    self.dodge_text = self.property_node:getChildByName("title_2_1_0_0")
    self.authority_text = self.property_node:getChildByName("title_2_1_0_0_0")

    self.next_level_node = self.root_node:getChildByName("Node_7")
    self.next_level_text = self.next_level_node:getChildByName("output_0")

    self.weapon_icon_img = self.root_node:getChildByName("weapon_icon")
    self.skill_name_text = self.root_node:getChildByName("cost_title")
    self.skill_desc_sview = self.root_node:getChildByName("skill_desc_sview")
    self.skill_desc_text = self.skill_desc_sview:getChildByName("desc")
    self:RegisterWidgetEvent()
end

function destiny_weapon_star_info_panel:Show(weapon_id)
    local total_star, total_add_bp, total_star_conf, next_total_star_conf = destiny_logic:GetWeaponTotalStarInfo()
    local weapon_star_info = destiny_logic:GetWeaponStarInfo(weapon_id)
    local weapon_star_conf = destiny_logic:GetWeaponStarConf(weapon_star_info.weapon_id, weapon_star_info.star_level)
    local skill_id = destiny_logic:GetCurWeaponSkillId(weapon_id)
    local skill_info = panel_util:GetSkillInfo(skill_id)

    local weapon_config = destiny_skill_config[weapon_id]
    self.weapon_icon_img:loadTexture(weapon_config["icon"], PLIST_TYPE)

    self.star_num_text:setString(weapon_star_info.star_level)
    self.add_bp_text:setString(weapon_star_conf.add_bp)

    if total_star_conf.star_num == total_star then
        self.property_node:setVisible(true)
        self.next_level_node:setVisible(false)
        self.speed_text:setString(total_star_conf.speed or 0)
        self.defense_text:setString(total_star_conf.defense or 0)
        self.dodge_text:setString(total_star_conf.dodge or 0)
        self.authority_text:setString(total_star_conf.authority or 0)
    else
        self.property_node:setVisible(false)
        if next_total_star_conf.star_num then
            self.next_level_node:setVisible(true)
            self.next_level_text:setString(next_total_star_conf.star_num - total_star)
        end
    end

    self.skill_name_text:setString(string.format(lang_constants:Get("mercenary_destiny_skill_name"), skill_info.name))
    self.skill_desc_text:setString(skill_info.desc)
    self.skill_desc_sview:jumpToTop()
    
    self.root_node:setVisible(true)
end

function destiny_weapon_star_info_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("confirm_btn"), self:GetName())
end

return destiny_weapon_star_info_panel

