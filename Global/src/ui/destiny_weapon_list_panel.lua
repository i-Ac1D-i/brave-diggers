local config_manager = require "logic.config_manager"

local constants = require "util.constants"
local client_constants  = require "util.client_constants"

local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local destiny_logic = require "logic.destiny_weapon"

local panel_prototype = require "ui.panel"

local panel_util = require "ui.panel_util"

local lang_constants = require "util.language_constants"
local destiny_skill_config = config_manager.destiny_skill_config

local EQUIPED_ICON_PATH = client_constants["EQUIPED_ICON_PATH"]
local PLIST_TYPE = ccui.TextureResType.plistType

local weapon_sub_panel = panel_prototype.New()
weapon_sub_panel.__index = weapon_sub_panel

function weapon_sub_panel.New()
    return setmetatable({}, weapon_sub_panel)
end

function weapon_sub_panel:Init(root_node)
    self.root_node = root_node

    self.root_node:setCascadeColorEnabled(true)

    self.weapon_icon_img = root_node:getChildByName("icon")
    self.equiped_icon_img = root_node:getChildByName("equiped_icon")
    self.name_text = root_node:getChildByName("name")
    self.desc_text = root_node:getChildByName("desc")
    self.skill_name_text = root_node:getChildByName("skill_name")

    panel_util:SetTextOutline(self.name_text)
    panel_util:SetTextOutline(self.skill_name_text)


end

function weapon_sub_panel:Show(id, is_actived, is_equiped)
    self.weapon_icon_img:loadTexture(client_constants["DESTINY_WEAPON_IMG"] .. id .. ".png", PLIST_TYPE)
    self.name_text:setString(destiny_skill_config[id]["name"])
    self.equiped_icon_img:setVisible(false)

    local skill_id = destiny_skill_config[id]["skill_id"]
    local skill_info = panel_util:GetSkillInfo(skill_id)

    self.skill_name_text:setString(skill_info.name)

    if is_actived then
        self:SetEquipImg(id, is_equiped)
    else
        self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))

        self.desc_text:setColor(panel_util:GetColor4B(0x685d29))
        self.desc_text:setString(lang_constants:Get("destiny_weapon_not_get"))
        panel_util:disableEffect(self.desc_text)
        self.desc_text:getVirtualRenderer():setAdditionalKerning(0)
        
    end
end

function weapon_sub_panel:SetEquipImg(id, is_equiped)

    if id < 1 or id > constants["MAX_DESTINY_WEAPON_ID"] then
        return
    end

    if is_equiped then
        self.root_node:setCascadeColorEnabled(false)

        self.equiped_icon_img:setVisible(true)

        panel_util:SetTextOutline(self.desc_text)
        self.desc_text:setString(lang_constants:Get("destiny_weapon_already_equipped"))
        self.desc_text:setColor(panel_util:GetColor4B(0xb8e90a))

        self.root_node:setColor(panel_util:GetColor4B(0xe2ff7b))
        self.equiped_icon_img:loadTexture(EQUIPED_ICON_PATH, PLIST_TYPE)

        
    else
        self.equiped_icon_img:setVisible(false)

        self.desc_text:setString(lang_constants:Get("destiny_weapon_already_get"))
        self.desc_text:setColor(panel_util:GetColor4B(0x685d29))
        panel_util:disableEffect(self.desc_text)
        
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        self.root_node:setCascadeColorEnabled(true)


    end
end
--
local destiny_weapon_list_panel = panel_prototype.New(true)
function destiny_weapon_list_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/destiny_weapon_list_panel.csb")
    local root_node = self.root_node
    self.title_text = root_node:getChildByName("title_text")
    panel_util:SetTextOutline(self.title_text)

    self.close_btn = root_node:getChildByName("close_btn")

    self.list_view = root_node:getChildByName("list_view")

    local template = root_node:getChildByName("template")

    self.weapon_sub_panels = {}

    for i = 1, constants["MAX_DESTINY_WEAPON_ID"] do
        self.weapon_sub_panels[i] = weapon_sub_panel.New()
        self.weapon_sub_panels[i]:Init(template:clone())
        self.list_view:addChild(self.weapon_sub_panels[i].root_node)
    end

    template:setVisible(false)
    self.cur_equiped_weapon_id = 0
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function destiny_weapon_list_panel:Show(formation_id)
    self.root_node:setVisible(true)

    self.formation_id = formation_id or self.formation_id

    self.cur_equiped_weapon_id = troop_logic:GetFormationWeaponId(self.formation_id)

    for id = 1, constants["MAX_DESTINY_WEAPON_ID"] do
        local is_actived = destiny_logic:IsWeaponActived(id)
        self.weapon_sub_panels[id]:Show(id, is_actived, self.cur_equiped_weapon_id == id)
    end
end

function destiny_weapon_list_panel:Hide()
    self.root_node:setVisible(false)
end

function destiny_weapon_list_panel:RegisterEvent()
    --装备武器
    graphic:RegisterEvent("update_leader_weapon", function(cur_weapon_id, formation_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.formation_id ~= formation_id then
            return
        end

        self.weapon_sub_panels[cur_weapon_id]:SetEquipImg(cur_weapon_id, true)

        if self.cur_equiped_weapon_id and self.cur_equiped_weapon_id ~= 0 then
            self.weapon_sub_panels[self.cur_equiped_weapon_id]:SetEquipImg(self.cur_equiped_weapon_id, false)
        end

        audio_manager:PlayEffect("equip")

        self.cur_equiped_weapon_id = cur_weapon_id
    end)
end

function destiny_weapon_list_panel:RegisterWidgetEvent()
    --弹窗注册事件
   panel_util:RegisterCloseMsgbox(self.close_btn, "destiny_weapon_list_panel")

   local view_weapon_info = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self.select_id = widget:getTag()

            if troop_logic:GetFormationWeaponId(self.formation_id) == self.select_id then
                return
            end

            local is_actived = destiny_logic:IsWeaponActived(self.select_id)
            if not is_actived then
                return
            end

            destiny_logic:Equip(self.formation_id, self.select_id)
        end
   end

   --
   for i = 1, constants["MAX_DESTINY_WEAPON_ID"] do
       local sub_panel = self.weapon_sub_panels[i].root_node
       sub_panel:setTouchEnabled(true)
       sub_panel:setTag(i)
       sub_panel:addTouchEventListener(view_weapon_info)
   end

end

return destiny_weapon_list_panel
