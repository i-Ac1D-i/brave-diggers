local config_manager = require "logic.config_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local resource_logic = require "logic.resource"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"

local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local destiny_skill_config = config_manager.destiny_skill_config

local PLIST_TYPE = ccui.TextureResType.plistType

local weapon_sub_panel = panel_prototype.New()
weapon_sub_panel.__index = weapon_sub_panel
function weapon_sub_panel.New()
    return setmetatable({}, weapon_sub_panel)
end

function weapon_sub_panel:Init(root_node, id)
    self.root_node = root_node
    self.root_node:setCascadeColorEnabled(true)

    self.weapon_icon_img = root_node:getChildByName("icon")
    self.equiped_icon_img = root_node:getChildByName("equiped_icon")
    self.lock_icon_img = root_node:getChildByName("lock")

    self.id = id
end

function weapon_sub_panel:Show()
    local id = self.id
    local config = destiny_skill_config[id]
    self.weapon_icon_img:loadTexture(config.icon, PLIST_TYPE)

    local is_actived = destiny_logic:IsWeaponActived(id)
    self.lock_icon_img:setVisible(not is_actived)

    local is_equiped = troop_logic:IsWeaponEquipped(troop_logic:GetCurFormationId(), id)
    self.equiped_icon_img:setVisible(is_equiped)

    if id <= constants["MAX_DESTINY_WEAPON_ID"] then
        self.root_node:loadTexture(client_constants["MERCENARY_BG_SPRITE"][5], PLIST_TYPE)
    else
        self.root_node:loadTexture(client_constants["MERCENARY_BG_SPRITE"][6], PLIST_TYPE)
    end
end

function weapon_sub_panel:Selected(is_selected)
    if is_selected then
        self.root_node:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
    else
        self.root_node:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
    end
end

local leader_weapon_panel = panel_prototype.New()
function leader_weapon_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/leader_weapon_panel.csb")
    local root_node = self.root_node
    --武器详细信息
    self.weapon_info_panel = root_node:getChildByName("weapon_info_panel")

    self.bg_img = self.weapon_info_panel:getChildByName("bg")
    self.bg_img:setTouchEnabled(true)

    panel_util:SetTextOutline(self.weapon_info_panel:getChildByName("weapon_name"))

    --技能
    self.skill_bg_img = root_node:getChildByName("skill_bg_img")

    --武器tab
    local weapon_tab_node = root_node:getChildByName("weapon_tab")
    self.list_view = weapon_tab_node:getChildByName("list_view")
    local tempalte = self.list_view:getChildByName("weapon_template")

    self.weapon_sub_panels = {}

    --通过关卡获得的武器放在最前面
    for id = 6, constants["MAX_DESTINY_WEAPON_ID"] - 1 do
        local sub_panel = weapon_sub_panel.New()
        if id == 6 then
            sub_panel:Init(tempalte, id)
        else
            sub_panel:Init(tempalte:clone(), id)
            self.list_view:addChild(sub_panel.root_node)
        end
        self.weapon_sub_panels[id] = sub_panel
    end

    for id = 1, 5 do
        local sub_panel = weapon_sub_panel.New()
        sub_panel:Init(tempalte:clone(), id)
        self.list_view:addChild(sub_panel.root_node)
        self.weapon_sub_panels[id] = sub_panel
    end

    local sub_panel = weapon_sub_panel.New()
    sub_panel:Init(tempalte:clone(), constants["MAX_DESTINY_WEAPON_ID"])
    self.list_view:addChild(sub_panel.root_node)
    self.weapon_sub_panels[constants["MAX_DESTINY_WEAPON_ID"]] = sub_panel

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.equip_spine = spine_manager:GetNode("equip_destiny_weapon", 1.0, true)
    self.equip_spine:setPosition(320, 568)

    self.equip_spine:setVisible(false)
    self.root_node:addChild(self.equip_spine, 300)

    self.list_view:refreshView()

    self.weapon_final_panel = root_node:getChildByName("weapon_final")
    self.star_lock_panel = root_node:getChildByName("destiny_weapon_panel_update")
    self.star_upgrade_panel = root_node:getChildByName("destiny_weapon_panel_massage")
    self.star_upgrade_btn = root_node:getChildByName("exchange_reward_btn")
    self.star_property_btn = root_node:getChildByName("formation_btn")
    self.equip_weapon_btn = root_node:getChildByName("exchange_reward_btn_0")

    if self.weapon_final_panel then        
        if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
            local id = constants["MAX_DESTINY_WEAPON_ID"] + 1
            local super_weapon_panel = weapon_sub_panel.New()
            super_weapon_panel:Init(weapon_tab_node:getChildByName("weapon_final"), id)
            self.weapon_sub_panels[id] = super_weapon_panel
        end

        self.weapon_final_panel:setVisible(feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        self.star_lock_panel:setVisible(feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        self.star_upgrade_panel:setVisible(feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        self.star_upgrade_btn:setVisible(feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        self.star_property_btn:setVisible(feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))

        panel_util:SetTextOutline(self.weapon_final_panel:getChildByName("weapon_name"))
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function leader_weapon_panel:Show()
    self.cur_equip_weapon_id = troop_logic:GetCurWeaponId()

    for _,sub_panel in ipairs(self.weapon_sub_panels) do
        sub_panel:Show()
        sub_panel:Selected(false)
    end
    
    self.cur_weapon_id = (self.cur_equip_weapon_id == 0) and 6 or self.cur_equip_weapon_id
    self.weapon_sub_panels[self.cur_weapon_id]:Selected(true)
    self:UpdateWeaponInfo(self.cur_weapon_id)

    -- list_view 显示百分比
    local percent = 0
    local sub_percent = 100 / 6
    if self.cur_weapon_id >= 8 and self.cur_weapon_id <= 10 then
        percent = (self.cur_weapon_id - 8)*sub_percent
    elseif self.cur_weapon_id == 11 then
        percent = 100
    elseif self.cur_weapon_id <= 5 then
        percent = (self.cur_weapon_id + 2)*sub_percent
    end
    self.list_view:jumpToPercentHorizontal(percent)

    self.root_node:setVisible(true)
end

function leader_weapon_panel:ShowWeaponStarInfo(weapon_id)
    if self.star_lock_panel then
        self.star_lock_panel:setVisible(false)
        self.star_upgrade_panel:setVisible(false)
        self.star_upgrade_btn:setVisible(false)
        if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then

            self.star_upgrade_btn:setTitleText(lang_constants:Get("destiny_weapon_upgrade_star_btn"))
            local total_star, total_add_bp, total_star_conf = destiny_logic:GetWeaponTotalStarInfo()
            local total_star_text = self.star_upgrade_panel:getChildByName("title_2")
            local total_add_bp_text = self.star_upgrade_panel:getChildByName("title_2_0")
            local total_speed_text = self.star_upgrade_panel:getChildByName("title_2_1")
            local total_defense_text = self.star_upgrade_panel:getChildByName("title_2_1_0")
            local total_dodge_text = self.star_upgrade_panel:getChildByName("title_2_1_0_0")
            local total_authority_text = self.star_upgrade_panel:getChildByName("title_2_1_0_0_0")

            total_star_text:setString(total_star)
            total_add_bp_text:setString(total_add_bp)
            total_speed_text:setString(total_star_conf.speed or 0)
            total_defense_text:setString(total_star_conf.defense or 0)
            total_dodge_text:setString(total_star_conf.dodge or 0)
            total_authority_text:setString(total_star_conf.authority or 0)

            if destiny_logic.weapon_star_can_upgrade then
                if weapon_id <= constants["MAX_DESTINY_WEAPON_ID"] then
                    self.star_upgrade_panel:setVisible(true)
                    if destiny_logic:IsWeaponActived(constants["MAX_DESTINY_WEAPON_ID"]) then
                        if destiny_logic:IsWeaponActived(weapon_id) then
                            self.star_upgrade_btn:setVisible(true)
                        end
                    end
                else
                    self.star_upgrade_btn:setVisible(true)
                    if destiny_logic:IsWeaponActived(weapon_id) then
                        self.star_upgrade_panel:setVisible(true)
                    else
                        self.star_upgrade_btn:setTitleText(lang_constants:Get("destiny_weapon_active_btn"))
                    end
                end
            else
                self.star_upgrade_btn:setVisible(true)
                self.star_upgrade_btn:setTitleText(lang_constants:Get("destiny_weapon_unlock_star_btn"))
                
                if weapon_id <= constants["MAX_DESTINY_WEAPON_ID"] then
                    self.star_lock_panel:setVisible(true)

                    local num_text = self.star_lock_panel:getChildByName("Text_197_0_0_0")
                    local weapon_num = destiny_logic:GetWeaponNum()
                    num_text:setString(string.format("%d/%d", weapon_num, constants["MAX_DESTINY_WEAPON_ID"]))
                    if weapon_num < constants["MAX_DESTINY_WEAPON_ID"] then
                        num_text:setColor(panel_util:GetColor4B(0x762f19))
                        self.star_upgrade_btn:setBright(false)
                    else
                        num_text:setColor(panel_util:GetColor4B(0xbfe322))
                        self.star_upgrade_btn:setBright(true)
                    end
                end
            end
        end
    end
end

--更新weapon信息
function leader_weapon_panel:UpdateWeaponInfo(weapon_id)
    local is_actived = destiny_logic:IsWeaponActived(weapon_id)

    local skill_id = destiny_logic:GetCurWeaponSkillId(weapon_id)
    local skill_info = panel_util:GetSkillInfo(skill_id)

    local info_panel
    local skill_panel
    if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") and weapon_id > constants["MAX_DESTINY_WEAPON_ID"] and not destiny_logic:IsWeaponActived(weapon_id) then
        self.weapon_info_panel:setVisible(false)
        self.skill_bg_img:setVisible(false)
        self.weapon_final_panel:setVisible(true)
        self.equip_weapon_btn:setVisible(false)

        info_panel = self.weapon_final_panel
        skill_panel = self.weapon_final_panel:getChildByName("skill_bg_img")

        local total_star, total_add_bp, total_star_conf = destiny_logic:GetWeaponTotalStarInfo()
        local star_num_text = self.weapon_final_panel:getChildByName("Text_02_1_0")
        star_num_text:setString(string.format("%d/%d", total_star, constants["FINAL_DESTINY_WEAPON_NEED_STAR_NUM"]))
    else
        self.weapon_info_panel:setVisible(true)
        if self.equip_weapon_btn then
            self.equip_weapon_btn:setVisible(is_actived)
        end
        self.skill_bg_img:setVisible(true)
        if self.weapon_final_panel then
            self.weapon_final_panel:setVisible(false)
        end

        info_panel = self.weapon_info_panel
        skill_panel = self.skill_bg_img
    end

    local weapon_name_text = info_panel:getChildByName("weapon_name")
    local weapon_status_text = info_panel:getChildByName("is_get_status")
    local weapon_desc_text = info_panel:getChildByName("desc")
    local weapon_icon_img = info_panel:getChildByName("weapon_icon")
    local left_modify_img = info_panel:getChildByName("left_modify")
    local right_modify_img = info_panel:getChildByName("right_modify")
    local skill_name_text = skill_panel:getChildByName("skill_name")
    local skill_desc_sview = skill_panel:getChildByName("skill_desc_sview")
    local skill_desc_text = skill_desc_sview:getChildByName("desc")
    local weapon_star_num_text = info_panel:getChildByName("weapon_star_num")

    local weapon_config = destiny_skill_config[weapon_id]
    weapon_status_text:setColor(panel_util:GetColor4B(0x231e0c))

    if not platform_manager:GetChannelInfo().is_open_system and not PlatformSDK.openChangeSystem then
        weapon_status_text:disableEffect()
        weapon_status_text:getVirtualRenderer():setAdditionalKerning(0)
    end

    weapon_name_text:setString(weapon_config["name"])
    weapon_icon_img:loadTexture(weapon_config["icon"], PLIST_TYPE)
    if weapon_star_num_text then
        panel_util:SetTextOutline(weapon_star_num_text)
        local weapon_star_info = destiny_logic:GetWeaponStarInfo(weapon_id)
        weapon_star_num_text:setString(weapon_star_info.star_level)
    end

    if is_actived then
        weapon_status_text:setVisible(not feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        left_modify_img:setVisible(not feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        right_modify_img:setVisible(not feature_config:IsFeatureOpen("expedition_and_destiny_weapon"))
        weapon_icon_img:setOpacity(255)
        weapon_desc_text:setString(weapon_config["desc"])

        local is_equiped = troop_logic:IsWeaponEquipped(troop_logic:GetCurFormationId(), weapon_id)
        if is_equiped then
            weapon_status_text:setString(lang_constants:Get("destiny_weapon_already_equipped"))
            panel_util:SetTextOutline(weapon_status_text)

            weapon_status_text:setColor(panel_util:GetColor4B(0xb8ec4a))
            if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
                self.equip_weapon_btn:setTitleText(lang_constants:Get("destiny_weapon_has_equiped"))
            end
        else
            if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
                self.equip_weapon_btn:setTitleText(lang_constants:Get("destiny_weapon_equip"))
                weapon_status_text:setString(lang_constants:Get("destiny_weapon_not_equip"))
            else
                weapon_status_text:setString(lang_constants:Get("destiny_weapon_do_equip"))
            end
        end
    else
        weapon_status_text:setVisible(true)
        left_modify_img:setVisible(true)
        right_modify_img:setVisible(true)
        weapon_desc_text:setString(weapon_config["lock_desc"])
        weapon_status_text:setString(lang_constants:Get("destiny_weapon_not_get"))
        weapon_icon_img:setOpacity(255 * 0.5)
    end

    local pos_x = weapon_status_text:getPositionX()
    local width = weapon_status_text:getContentSize().width / 2

    left_modify_img:setPositionX(pos_x - width - 20)
    right_modify_img:setPositionX(pos_x + width + 20)

    skill_name_text:setString(string.format(lang_constants:Get("mercenary_destiny_skill_name"), skill_info.name))
    skill_desc_text:setString(skill_info.desc)
    skill_desc_sview:jumpToTop()

    self:ShowWeaponStarInfo(weapon_id)
end

function leader_weapon_panel:RegisterEvent()
    --装备武器
    graphic:RegisterEvent("update_leader_weapon", function(equiped_weapon_id)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateWeaponInfo(equiped_weapon_id)

        --更新下面tab的显示
        if self.cur_equip_weapon_id ~= 0 then
            self.weapon_sub_panels[self.cur_equip_weapon_id]:Show()
        end

        self.weapon_sub_panels[equiped_weapon_id]:Show()
        self.cur_equip_weapon_id = equiped_weapon_id

        self.equip_spine:setVisible(true)
        self.equip_spine:setAnimation(0, "animation", false)

        audio_manager:PlayEffect("equip")
    end)

    graphic:RegisterEvent("get_final_destiny_weapon", function(equiped_weapon_id)
        if not self.root_node:isVisible() then
            return
        end
        
        self:UpdateWeaponInfo(self.cur_weapon_id)
        self.weapon_sub_panels[#self.weapon_sub_panels]:Show()
    end)

    graphic:RegisterEvent("unlock_destiny_weapon_star", function(equiped_weapon_id)
        if not self.root_node:isVisible() then
            return
        end
        
        self:UpdateWeaponInfo(self.cur_weapon_id)
    end)
end

function leader_weapon_panel:RegisterWidgetEvent()
    local view_weapon_info = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.select_id = widget:getTag()
            self:UpdateWeaponInfo(self.select_id)

            self.weapon_sub_panels[self.cur_weapon_id]:Selected(false)
            self.weapon_sub_panels[self.select_id]:Selected(true)
            self.cur_weapon_id = self.select_id
        end
    end

    for i,sub_panel in ipairs(self.weapon_sub_panels) do
        local root_node = sub_panel.root_node
        root_node:setTag(i)
        root_node:setTouchEnabled(true)
        root_node:addTouchEventListener(view_weapon_info)
    end

    -- 返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    if feature_config:IsFeatureOpen("expedition_and_destiny_weapon") then
        self.star_upgrade_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                if not destiny_logic.weapon_star_can_upgrade then
                    destiny_logic:UnlockDestinyWeaponStar()
                elseif self.cur_weapon_id > constants["MAX_DESTINY_WEAPON_ID"] and not destiny_logic:IsWeaponActived(self.cur_weapon_id) then
                    destiny_logic:GetFinalDestinyWeapon()
                else
                    graphic:DispatchEvent("show_world_sub_scene", "destiny_weapon_star_sub_scene", nil, self.cur_weapon_id)
                end
            end
        end)

        self.star_property_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                
                graphic:DispatchEvent("show_world_sub_panel", "destiny_weapon_total_star_panel")
            end
        end)

        self.equip_weapon_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                
                destiny_logic:Equip(troop_logic:GetCurFormationId(), self.cur_weapon_id)
            end
        end)
    else
        self.bg_img:addTouchEventListener(function (widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                destiny_logic:Equip(troop_logic:GetCurFormationId(), self.cur_weapon_id)
            end
        end)
    end
end

return leader_weapon_panel
