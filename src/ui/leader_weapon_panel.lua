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
    self.weapon_icon_img:loadTexture(client_constants["DESTINY_WEAPON_IMG"] .. id .. ".png", PLIST_TYPE)

    local is_actived = destiny_logic:IsWeaponActived(id)
    self.lock_icon_img:setVisible(not is_actived)

    local is_equiped = troop_logic:IsWeaponEquipped(troop_logic:GetCurFormationId(), id)
    self.equiped_icon_img:setVisible(is_equiped)
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

    local weapon_info_panel = self.weapon_info_panel
    self.weapon_name_text = weapon_info_panel:getChildByName("weapon_name")
    panel_util:SetTextOutline(self.weapon_name_text)

    self.weapon_status_text = weapon_info_panel:getChildByName("is_get_status")
    self.left_modify_img = weapon_info_panel:getChildByName("left_modify")
    self.right_modify_img = weapon_info_panel:getChildByName("right_modify")
    self.weapon_desc_text = weapon_info_panel:getChildByName("desc")

    self.weapon_icon_img = weapon_info_panel:getChildByName("weapon_icon")

    --技能
    local skill_bg_img = root_node:getChildByName("skill_bg_img")
    self.skill_name_text = skill_bg_img:getChildByName("skill_name")
    self.skill_desc_sview = skill_bg_img:getChildByName("skill_desc_sview")
    self.skill_desc_text = self.skill_desc_sview:getChildByName("desc")

    --FYD  修改宿命武器的合体技介绍不换行的问题        
    local skill_height = platform_manager:GetChannelInfo().leader_weapon_skill_desc_height 
    if skill_height then
       local size = self.skill_desc_text:getContentSize() 
       self.skill_desc_text:setContentSize(size.width,skill_height)
    end

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

    local id = 11
    local sub_panel = weapon_sub_panel.New()
    sub_panel:Init(tempalte:clone(), id)
    self.list_view:addChild(sub_panel.root_node)
    self.weapon_sub_panels[id] = sub_panel

    self.back_btn = self.root_node:getChildByName("back_btn")

    self.equip_spine = spine_manager:GetNode("equip_destiny_weapon", 1.0, true)
    self.equip_spine:setPosition(320, 568)

    self.equip_spine:setVisible(false)
    self.root_node:addChild(self.equip_spine, 300)

    self.list_view:refreshView()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function leader_weapon_panel:Show()
    self.cur_equip_weapon_id = troop_logic:GetCurWeaponId()

    for id = 1, constants["MAX_DESTINY_WEAPON_ID"] do
        self.weapon_sub_panels[id]:Show()
        self.weapon_sub_panels[id]:Selected(false)
    end
    
    self.cur_weapon_id = (self.cur_equip_weapon_id == 0) and 6 or self.cur_equip_weapon_id
    self.weapon_sub_panels[self.cur_weapon_id]:Selected(true)
    self:UpdateWeaponInfo(self.cur_weapon_id)
    self:UpdateSkill(self.cur_weapon_id)
    self:UpdateModifyPosX()

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

--更新weapon信息
function leader_weapon_panel:UpdateWeaponInfo(weapon_id)
    local is_actived = destiny_logic:IsWeaponActived(weapon_id)

    local weapon_config = destiny_skill_config[weapon_id]
    self.weapon_status_text:setColor(panel_util:GetColor4B(0x231e0c))
    panel_util:disableEffect(self.weapon_status_text)
    self.weapon_status_text:getVirtualRenderer():setAdditionalKerning(0)

    self.weapon_name_text:setString(weapon_config["name"])
    self.weapon_icon_img:loadTexture(client_constants["DESTINY_WEAPON_IMG"] .. weapon_id .. ".png", PLIST_TYPE)

    if is_actived then
        self.weapon_icon_img:setOpacity(255)
        self.weapon_desc_text:setString(weapon_config["desc"])

        local is_equiped = troop_logic:IsWeaponEquipped(troop_logic:GetCurFormationId(), weapon_id)
        if is_equiped then
            self.weapon_status_text:setString(lang_constants:Get("destiny_weapon_already_equipped"))
            panel_util:SetTextOutline(self.weapon_status_text)

            self.weapon_status_text:setColor(panel_util:GetColor4B(0xb8ec4a))
        else
            self.weapon_status_text:setString(lang_constants:Get("destiny_weapon_do_equip"))
        end
    else

        self.weapon_desc_text:setString(weapon_config["lock_desc"])
        self.weapon_status_text:setString(lang_constants:Get("destiny_weapon_not_get"))
        self.weapon_icon_img:setOpacity(255 * 0.5)
    end

end

function leader_weapon_panel:UpdateSkill(weapon_id)
    local skill_id = destiny_skill_config[weapon_id]["skill_id"]
    local skill_info = panel_util:GetSkillInfo(skill_id)

    self.skill_name_text:setString(string.format(lang_constants:Get("mercenary_destiny_skill_name"), skill_info.name))
    self.skill_desc_text:setString(skill_info.desc)
end

function leader_weapon_panel:UpdateModifyPosX()
    local pos_x = self.weapon_status_text:getPositionX()
    local width = self.weapon_status_text:getContentSize().width / 2

    self.left_modify_img:setPositionX(pos_x - width - 20)
    self.right_modify_img:setPositionX(pos_x + width + 20)
end

function leader_weapon_panel:RegisterEvent()
    --装备武器
    graphic:RegisterEvent("update_leader_weapon", function(equiped_weapon_id)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateWeaponInfo(equiped_weapon_id)
        self:UpdateModifyPosX()

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
end

function leader_weapon_panel:RegisterWidgetEvent()
    local view_weapon_info = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.select_id = widget:getTag()
            self:UpdateWeaponInfo(self.select_id)
            self:UpdateSkill(self.select_id)
            self:UpdateModifyPosX()

            self.weapon_sub_panels[self.cur_weapon_id]:Selected(false)
            self.weapon_sub_panels[self.select_id]:Selected(true)
            self.cur_weapon_id = self.select_id
        end
    end

    for i = 1, constants["MAX_DESTINY_WEAPON_ID"] do
        local sub_panel = self.weapon_sub_panels[i].root_node
        sub_panel:setTag(i)
        sub_panel:setTouchEnabled(true)
        sub_panel:addTouchEventListener(view_weapon_info)
    end

    self.bg_img:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            destiny_logic:Equip(troop_logic:GetCurFormationId(), self.cur_weapon_id)
        end
    end)

    -- 返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return leader_weapon_panel
