local config_manager = require "logic.config_manager"

local constants = require "util.constants"
local client_constants  = require "util.client_constants"

local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"
local store_logic = require "logic.store"
local spine_manager = require "util.spine_manager"
local animation_manager = require "util.animation_manager"

local panel_prototype = require "ui.panel"

local panel_util = require "ui.panel_util"

local lang_constants = require "util.language_constants"
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

local destiny_weapon_star_panel = panel_prototype.New(true)
function destiny_weapon_star_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/leader_weapon_stars_up_panel.csb")
    
    --武器tab
    local weapon_tab_node = self.root_node:getChildByName("weapon_tab")
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

    local id = constants["MAX_DESTINY_WEAPON_ID"] + 1
    local super_weapon_panel = weapon_sub_panel.New()
    super_weapon_panel:Init(tempalte:clone(), id)
    self.list_view:addChild(super_weapon_panel.root_node)
    self.weapon_sub_panels[id] = super_weapon_panel

    local skill_bg_img = self.root_node:getChildByName("skill_bg_img")

    local star_panel = skill_bg_img:getChildByName("star")
    self.star_btn_list = {}
    self.star_spine_list = {}
    self.star_light_list = {}
    for i=1,constants["DESTINY_WEAPON_MAX_STAR_LEVEL"] do
        local star_node = star_panel:getChildByName("star" .. i)
        self.star_btn_list[i] = star_node:getChildByName("Button_1")
        self.star_spine_list[i] = spine_manager:GetNode("star_lv", 1.0, true)
        self.star_spine_list[i]:setAnimation(0, "star_loop", true)
        self.star_spine_list[i]:setVisible(false)
        self.star_light_list[i] = star_node:getChildByName("light_1")
        star_node:getChildByName("Node_10"):addChild(self.star_spine_list[i])
    end

    local resource_panel = self.root_node:getChildByName("Node_5")
    self.resource_num_text = resource_panel:getChildByName("Text_85")
    self.add_resource_btn = resource_panel:getChildByName("add_area_btn")

    self.upgrade_once_btn = self.root_node:getChildByName("exchange_reward_btn")
    self.upgrade_auto_btn = self.root_node:getChildByName("formation_btn")
    self.rule_btn = self.root_node:getChildByName("view_info_btn")
    self.close_btn = self.root_node:getChildByName("back_btn")

    self.weapon_info_panel = self.root_node:getChildByName("weapon_info_panel")
    self.weapon_name_text = self.weapon_info_panel:getChildByName("weapon_name")
    self.weapon_icon_img = self.weapon_info_panel:getChildByName("weapon_icon")
    self.weapon_star_level_text = self.weapon_info_panel:getChildByName("weapon_name_0")
    self.weapon_exp_text = skill_bg_img:getChildByName("skill_level_0")
    self.skill_name_text = skill_bg_img:getChildByName("skill_name_0")
    self.skill_desc_sview = skill_bg_img:getChildByName("skill_desc_sview")
    self.skill_desc_text = self.skill_desc_sview:getChildByName("desc")
    self.add_bp_text = skill_bg_img:getChildByName("desc_0")
    panel_util:SetTextOutline(self.weapon_name_text)
    panel_util:SetTextOutline(self.weapon_star_level_text)

    self.weapon_spine = spine_manager:GetNode("lose_light")
    self.weapon_spine:setVisible(false)
    self.weapon_info_panel:getChildByName("Node_22"):addChild(self.weapon_spine)

    self.cost_icon = self.root_node:getChildByName("Image_89")
    self.cost_text = self.root_node:getChildByName("Text_62")
    panel_util:SetTextOutline(self.cost_text)

    local weapon_bg = self.weapon_info_panel:getChildByName("weapon_bg2")

    self.exp_progress = cc.ProgressTimer:create(cc.Sprite:createWithSpriteFrameName("entrust/hoop_exp.png"))
    self.exp_progress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.exp_progress:setPosition(weapon_bg:getPosition())
    self.exp_progress:setScale(2)
    self.exp_progress:setPercentage(0)
    self.weapon_info_panel:addChild(self.exp_progress, 10)

    self.weapon_exp_light = self.weapon_info_panel:getChildByName("weapon_bg2_0")
    self.weapon_exp_light:setOpacity(0)
    
    panel_util:SetTextOutline(self.weapon_exp_text)

    self.time_line_action = animation_manager:GetTimeLine("weapon_star_upgrade_timeline")
    self.upgrade_animation_node = cc.CSLoader:createNode("ui/leader_info.csb")
    local pos_x, pos_y = weapon_bg:getPosition()
    self.upgrade_animation_node:setPosition(cc.p(pos_x, pos_y - 90))
    self.weapon_info_panel:addChild(self.upgrade_animation_node, 15)
    self.upgrade_animation_node:runAction(self.time_line_action)
    self.upgrade_animation_node:setVisible(false)

    self.action_exp_text = self.upgrade_animation_node:getChildByName("Text_1")
    self.action_light_img = self.upgrade_animation_node:getChildByName("ban_light1")
    panel_util:SetTextOutline(self.action_exp_text)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function destiny_weapon_star_panel:Show(select_weapon_id)
    for _,sub_panel in ipairs(self.weapon_sub_panels) do
        sub_panel:Show()
        sub_panel:Selected(false)
    end
    
    if select_weapon_id then
        self.select_weapon_id = select_weapon_id
    end
    self:ShowWeapon(self.select_weapon_id)
    self.weapon_sub_panels[self.select_weapon_id]:Selected(true)

    self:RefreshResource()

    -- list_view 显示百分比
    local percent = 0
    local sub_percent = 100 / 6
    if self.select_weapon_id >= 8 and self.select_weapon_id <= 10 then
        percent = (self.select_weapon_id - 8)*sub_percent
    elseif self.select_weapon_id == 11 then
        percent = 100
    elseif self.select_weapon_id <= 5 then
        percent = (self.select_weapon_id + 2)*sub_percent
    end
    self.list_view:jumpToPercentHorizontal(percent)

    self.root_node:setVisible(true)
end

function destiny_weapon_star_panel:RefreshResource()
    local fatecrystal = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["fatecrystal"])
    self.resource_num_text:setString(tostring(fatecrystal))
end

function destiny_weapon_star_panel:ShowWeapon(weapon_id, is_upgrade)
    local weapon_star_info = destiny_logic:GetWeaponStarInfo(weapon_id)
    local weapon_star_conf = destiny_logic:GetWeaponStarConf(weapon_star_info.weapon_id, weapon_star_info.star_level)

    self:ShowWeaponExp(weapon_id, weapon_star_conf, weapon_star_info, is_upgrade)
    self:ShowWeaponInfo(weapon_id, weapon_star_conf)
    self:ShowCost(weapon_id, weapon_star_conf)

    destiny_logic.show_animation = false
end

function destiny_weapon_star_panel:ShowCost(weapon_id, weapon_star_conf)
    local is_show = weapon_star_conf.level < constants["DESTINY_WEAPON_MAX_STAR_LEVEL"]
    self.upgrade_once_btn:setVisible(is_show)
    self.upgrade_auto_btn:setVisible(is_show)
    self.cost_icon:setVisible(is_show)
    self.cost_text:setVisible(is_show)

    if is_show then
        self.cost_text:setString(weapon_star_conf.cost_num)
    end
end

function destiny_weapon_star_panel:ShowWeaponExp(weapon_id, weapon_star_conf, weapon_star_info, is_upgrade)
    self.exp_progress:stopAllActions()

    self.weapon_exp_text:setString(lang_constants:GetFormattedStr("destiny_weapon_exp", weapon_star_info.exp, weapon_star_conf.show_max_exp))
    
    self.exp_progress:setPercentage(100 * weapon_star_info.exp / weapon_star_conf.show_max_exp)

    for i,star_btn in ipairs(self.star_btn_list) do
        self.star_light_list[i]:setVisible(false)
        self.star_light_list[i]:stopAllActions()
        if i <= weapon_star_info.star_level then
            self.star_spine_list[i]:setVisible(true)
            self.star_spine_list[i]:setToSetupPose()
            if i == weapon_star_info.star_level and is_upgrade then
                self.star_spine_list[i]:setAnimation(0, "star_in", false)
                self.star_spine_list[i]:addAnimation(0, "star_loop", true)

                self.star_spine_list[i]:registerSpineEventHandler(function(event)
                    local animation_name = event.animation
                    if animation_name == "star_in" then
                        graphic:DispatchEvent("show_world_sub_panel", "destiny_weapon_star_info_panel", weapon_id)
                        destiny_logic.show_animation = false
                    end
                end, sp.EventType.ANIMATION_COMPLETE)
            else
                self.star_spine_list[i]:setAnimation(0, "star_loop", true)
            end
        else
            if i == weapon_star_info.star_level + 1 then
                self.star_light_list[i]:setVisible(true)
                self.star_light_list[i]:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(0.5,1.5), cc.ScaleTo:create(1,1.1))))
            end
            self.star_spine_list[i]:setVisible(false)
        end
    end
end

function destiny_weapon_star_panel:ShowWeaponInfo(weapon_id, weapon_star_conf)
    local weapon_config = destiny_skill_config[weapon_id]
    local skill_info = panel_util:GetSkillInfo(weapon_star_conf.skill_id)

    self.weapon_name_text:setString(weapon_config["name"])
    self.weapon_icon_img:loadTexture(weapon_config["icon"], PLIST_TYPE)
    
    self.skill_name_text:setString(string.format(lang_constants:Get("mercenary_destiny_skill_name"), skill_info.name))
    self.skill_desc_text:setString(skill_info.desc)
    self.skill_desc_sview:jumpToTop()

    self.add_bp_text:setString("+" .. panel_util:ConvertUnit(weapon_star_conf.add_bp))
    self.weapon_star_level_text:setString(weapon_star_conf.level)

    if weapon_star_conf.level < 4 then
        self.weapon_spine:setVisible(false)
    elseif weapon_star_conf.level < 8 then
        self.weapon_spine:setAnimation(0, "b_light", true)
        self.weapon_spine:setVisible(true)
    elseif weapon_star_conf.level < 12 then
        self.weapon_spine:setAnimation(0, "g_light3", true)
        self.weapon_spine:setVisible(true)
    else
        self.weapon_spine:setAnimation(0, "y_light2", true)
        self.weapon_spine:setVisible(true)
    end

    local weapon_star_info = destiny_logic:GetWeaponStarInfo(weapon_id)
    for i,star_light in ipairs(self.star_light_list) do
        if i == weapon_star_conf.level then
            star_light:setVisible(true)
            star_light:setScale(1.1)
        elseif i ~= weapon_star_info.star_level + 1 then
            star_light:setVisible(false)
        end
    end
end

function destiny_weapon_star_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function(source)
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(constants.RESOURCE_TYPE["fatecrystal"]) then
            self:RefreshResource()
        end
    end)

    graphic:RegisterEvent("weapon_upgrade_star_success", function(upgrade_info)
        if not self.root_node:isVisible() then
            return
        end

        if self.select_weapon_id ~= upgrade_info.weapon_id then
            return 
        end
        
        local weapon_star_info = destiny_logic:GetWeaponStarInfo(upgrade_info.weapon_id)
        local weapon_star_conf = destiny_logic:GetWeaponStarConf(upgrade_info.weapon_id, upgrade_info.star_level)

        self.action_light_img:setVisible(upgrade_info.is_crit)
        if upgrade_info.is_crit then
            self.action_exp_text:setString(lang_constants:Get("destiny_weapon_crit") .. "+" .. upgrade_info.upgrade_exp)
            self.action_exp_text:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["yellow"]))
            self.upgrade_animation_node:setScale(1.5)
        else
            self.action_exp_text:setString("+" .. upgrade_info.upgrade_exp)
            self.action_exp_text:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
            self.upgrade_animation_node:setScale(1)
        end
        self.time_line_action:gotoFrameAndPlay(0, 50, false)
        self.upgrade_animation_node:setVisible(true)

        self.exp_progress:runAction(cc.Sequence:create( 
                                                    cc.ProgressTo:create(0.3, 100 * upgrade_info.exp / weapon_star_conf.show_max_exp),
                                                    cc.CallFunc:create(function()
                                                        if upgrade_info.is_upgrade then
                                                            self.weapon_exp_light:runAction(cc.Sequence:create(cc.FadeIn:create(0.5),cc.FadeOut:create(0.5)))
                                                        end
                                                    end),
                                                    cc.DelayTime:create(upgrade_info.is_upgrade and 0.5 or 0),
                                                    cc.CallFunc:create(function()
                                                        destiny_logic.show_animation = false
                                                        if upgrade_info.is_upgrade then
                                                            self:ShowWeapon(upgrade_info.weapon_id, true)
                                                        elseif upgrade_info.upgrade_type == "auto" then
                                                            destiny_logic:UpgradeStar(upgrade_info.weapon_id, "auto")
                                                        end
                                                    end)
                                                    )
                                )

        self.weapon_exp_text:setString(lang_constants:GetFormattedStr("destiny_weapon_exp", upgrade_info.exp, weapon_star_conf.show_max_exp))
    end)
end

function destiny_weapon_star_panel:RegisterWidgetEvent()
    self.close_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    local view_weapon_info = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if not destiny_logic.show_animation then
                audio_manager:PlayEffect("click")
                
                self.weapon_sub_panels[self.select_weapon_id]:Selected(false)
                self.select_weapon_id = widget:getTag()
                self:ShowWeapon(self.select_weapon_id)
                self.weapon_sub_panels[self.select_weapon_id]:Selected(true)
            end
        end
    end

    for i,sub_panel in ipairs(self.weapon_sub_panels) do
        local root_node = sub_panel.root_node
        root_node:setTag(i)
        root_node:setTouchEnabled(true)
        root_node:addTouchEventListener(view_weapon_info)
    end

    self.upgrade_once_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            destiny_logic:UpgradeStar(self.select_weapon_id, "once")
        end
    end)

    self.upgrade_auto_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            destiny_logic:UpgradeStar(self.select_weapon_id, "auto")
        end
    end)

    local preview_weapon_info = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local star_level = widget:getTag()
            local weapon_star_conf = destiny_logic:GetWeaponStarConf(self.select_weapon_id, star_level)

            self:ShowWeaponInfo(self.select_weapon_id, weapon_star_conf)
        end
    end

    for i,star_btn in ipairs(self.star_btn_list) do
        star_btn:setTag(i)
        star_btn:setTouchEnabled(true)
        star_btn:addTouchEventListener(preview_weapon_info)
    end

    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("show_world_sub_panel", "destiny_weapon_star_rule_panel")
        end
    end)

    self.add_resource_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if not destiny_logic.show_animation then
                audio_manager:PlayEffect("click")
                
                local mode = client_constants.BATCH_MSGBOX_MODE.blood_store

                local goods_index = store_logic:GetResourceGoodsIndex(constants["RESOURCE_TYPE"]["fatecrystal"])
                if goods_index then
                    graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode, goods_index)
                end
            end
        end
    end)

    self.weapon_icon_img:setTouchEnabled(true)
    self.weapon_icon_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if not destiny_logic.show_animation then
                audio_manager:PlayEffect("click")

                self:ShowWeapon(self.select_weapon_id)
            end
        end
    end)
end

return destiny_weapon_star_panel
