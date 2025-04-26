local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local rune_logic = require "logic.rune"

local rune_config = config_manager.rune_config

local PLIST_TYPE = ccui.TextureResType.plistType

local BAG_CELL_COL = 5

local RUNE_PROPERTY_KEYS_NODE_NAME = {
    ["mine_property"] = "property_me",
    ["enemy_property"] = "property_enemy",
}

local equip_pos_sub_panel = panel_prototype.New()
equip_pos_sub_panel.__index = equip_pos_sub_panel

function equip_pos_sub_panel.New()
    return setmetatable({}, equip_pos_sub_panel)
end

function equip_pos_sub_panel:Init(pos, root_node)
    self.pos = pos
    self.root_node = root_node

    self.icon_img = self.root_node:getChildByName("rune_icon")
    self.top_quality_img = self.root_node:getChildByName("top_quality")
    self.select_img = self.root_node:getChildByName("select_light")
    self.select_img:setVisible(false)

    self.rune_level_text = self.root_node:getChildByName("rune_level")
    self.rune_level_text:setLocalZOrder(1)
    panel_util:SetTextOutline(self.rune_level_text, 0x000, 2)

    self.rune_name_text = self.root_node:getChildByName("rune_name")

    self.equip_rune_btn = self.root_node:getChildByName("add_btn01")
    self.add_img = self.root_node:getChildByName("add_btn_1")
    self.add_img:setTouchEnabled(false)
    self.add_img:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(1, 150), cc.FadeTo:create(1, 255))))

    self.rune_info = nil
end

function equip_pos_sub_panel:Show(rune_info)
    self.rune_info = rune_info
    
    if self.rune_info then
        self.icon_img:setVisible(true)
        self.icon_img:loadTexture(self.rune_info.template_info.icon, PLIST_TYPE)
        self.top_quality_img:setVisible(self.rune_info.template_info.quality == constants["MAX_RUNE_QUALITY"])
        if self.rune_info.level >= self.rune_info.template_info.level_limit then
            self.rune_level_text:setString("Lv MAX")
        else
            self.rune_level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))
        end
        self.rune_name_text:setString(self.rune_info.template_info.name)
        self.rune_name_text:setColor(panel_util:GetColor4B(client_constants["RUNE_TEXT_QUALITY_COLOR"][self.rune_info.template_info.quality]))
        self.add_img:setVisible(false)
    else
        self.icon_img:setVisible(false)
        self.top_quality_img:setVisible(false)
        self.rune_level_text:setString("")
        self.rune_name_text:setString("")
        self.add_img:setVisible(true)
    end
end

function equip_pos_sub_panel:SetRuneSelectSprite( is_selected )
    self.select_img:setVisible(is_selected)
end

local rune_equip_panel = panel_prototype.New(true)
function rune_equip_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/rune_panel.csb")

    local title_node = self.root_node:getChildByName("title_bg")
    self.rune_name_text = title_node:getChildByName("rune_name")
    self.rune_desc_text = self.root_node:getChildByName("rune_desc")

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.draw_btn = self.root_node:getChildByName("draw_btn")
    self.bag_btn = self.root_node:getChildByName("set_btn")
    self.replace_btn = self.root_node:getChildByName("replace_btn")
    self.levelup_btn = self.root_node:getChildByName("levelup_btn")

    local property_node = self.root_node:getChildByName("lineup")
    self.property_text_list = {}
    for i,key in ipairs(constants["RUNE_PROPERTY_KEYS"]) do
        self.property_text_list[key] = {}
        for property_type, property_name in ipairs(constants["PROPERTY_TYPE_NAME"]) do
            self.property_text_list[key][property_name] = property_node:getChildByName(RUNE_PROPERTY_KEYS_NODE_NAME[key]):getChildByName(property_name):getChildByName("value")
        end
    end

    self.equip_pos_templates = {}
    for pos = 1, constants["MAX_RUNE_EQUIPMENT_NUM"] do
        self.equip_pos_templates[pos] = self.root_node:getChildByName(string.format("rune_00%d", pos))
    end

    self.cur_select_pos = 1
    self.rune_sub_panels = {}

    self:RegisterEvent()
    self:RegisterWidgetEvent()
    self:CreateEquipPos()
end

function rune_equip_panel:Show()
    self:ShowRuneEquipment()

    self.root_node:setVisible(true)
end

function rune_equip_panel:ShowRuneDesc()
    local rune_info = self.rune_sub_panels[self.cur_select_pos].rune_info
    if rune_info then
        self.rune_name_text:setString(rune_info.template_info.name)
        local desc_str = rune_logic:GetRunePropertysDesc(rune_info.template_id, rune_info.level)
        if desc_str ~= "" then
            desc_str = desc_str .. lang_constants:Get("comma")
        end
        self.rune_desc_text:setString(desc_str .. rune_info.template_info.desc)
        self.rune_desc_text:setColor(panel_util:GetColor4B(0xdecb97))
    else
        self.rune_name_text:setString("")
        self.rune_desc_text:setString(lang_constants:Get("rune_pos_no_equip_desc"))
        self.rune_desc_text:setColor(panel_util:GetColor4B(0xffd100))

    end
end

function rune_equip_panel:ShowRuneEquipmentPropertys()
    local rune_property = rune_logic:GenerateRuneListPropertys(rune_logic:GetRuneEquipmentList())

    for key,propertys in pairs(rune_property) do
        for property_name,property_value in pairs(propertys) do
            local color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"])
            if property_value > 0 then
                color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["green"])
                property_value = string.format("+%d", property_value)
            elseif property_value < 0 then
                color = panel_util:GetColor4B(client_constants["TEXT_COLOR"]["red"])
            end
            self.property_text_list[key][property_name]:setColor(color)
            self.property_text_list[key][property_name]:setString(tostring(property_value))
        end
    end
end

function rune_equip_panel:ShowRuneEquipment()
    local rune_equipment_list = rune_logic:GetRuneEquipmentList()
    for pos = 1, constants["MAX_RUNE_EQUIPMENT_NUM"] do
        local sub_panel = self.rune_sub_panels[pos]
        sub_panel:Show(rune_equipment_list[pos])
    end

    self.rune_sub_panels[self.cur_select_pos]:SetRuneSelectSprite( true )
    self:ShowReplaceAndLevelUpBtn(self.rune_sub_panels[self.cur_select_pos].rune_info)
    self:ShowRuneDesc()
    self:ShowRuneEquipmentPropertys()
end

function rune_equip_panel:ShowReplaceAndLevelUpBtn( rune_info )
    if rune_info then
        self.replace_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
        if rune_info.level < rune_info.template_info.level_limit then
            self.levelup_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
        else
            self.levelup_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["gray"]))
        end
    else
        self.replace_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["gray"]))
        self.levelup_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["gray"]))
    end
end

function rune_equip_panel:CreateEquipPos()
    for pos = 1, constants["MAX_RUNE_EQUIPMENT_NUM"] do
        local sub_panel = equip_pos_sub_panel.New()
        sub_panel:Init(pos, self.equip_pos_templates[pos])

        sub_panel.equip_rune_btn:setTag(pos)
        sub_panel.equip_rune_btn:addTouchEventListener(self.equip_rune_method)
        self.rune_sub_panels[pos] = sub_panel
    end
end

function rune_equip_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end

    end)

    graphic:RegisterEvent("rune_bag_select_confirm", function(show_type, select_rune_list)
        if not self.root_node:isVisible() then
            return
        end

        if show_type ~= client_constants["RUNE_BAG_SHOW_TYPE"]["EQUIP"] or #select_rune_list == 0 then
            return
        end

        rune_logic:EquipRune(self.cur_select_pos, select_rune_list[1])
    end)

    graphic:RegisterEvent("refresh_rune_equipment", function()
        if not self.root_node:isVisible() then
            return
        end
        self:ShowRuneEquipment()
    end)

end

function rune_equip_panel:RegisterWidgetEvent()
    --点击装备格
    self.equip_rune_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local pos = widget:getTag()
            local sub_panel = self.rune_sub_panels[pos]
            if not sub_panel.rune_info then
                graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EQUIP"])
            end

            self.rune_sub_panels[self.cur_select_pos]:SetRuneSelectSprite( false )
            self.cur_select_pos = pos
            self.rune_sub_panels[self.cur_select_pos]:SetRuneSelectSprite( true )

            self:ShowReplaceAndLevelUpBtn(sub_panel.rune_info)

            self:ShowRuneDesc()
        end
    end

    --替换
    self.replace_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if self.rune_sub_panels[self.cur_select_pos].rune_info then
                graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EQUIP"], { self.rune_sub_panels[self.cur_select_pos].rune_info })
            else
                graphic:DispatchEvent("show_prompt_panel", "no_replace_rune")
            end
        end
    end)

    --升级
    self.levelup_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local rune_info = self.rune_sub_panels[self.cur_select_pos].rune_info
            if rune_info then
                if rune_info.level < rune_info.template_info.level_limit then
                    graphic:DispatchEvent("show_world_sub_scene", "rune_upgrade_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], rune_info)
                else
                    graphic:DispatchEvent("show_prompt_panel", "rune_already_max_level")
                end
            else
                graphic:DispatchEvent("show_prompt_panel", "no_target_rune")
            end
        end
    end)

    --符文抽取
    self.draw_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("hide_world_sub_scene")
            graphic:DispatchEvent("show_world_sub_scene", "rune_draw_sub_scene")
        end
    end)

    --符文背包
    self.bag_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["PACKAGE"])
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self.rune_sub_panels[self.cur_select_pos]:SetRuneSelectSprite( false )
            self.cur_select_pos = 1
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)
end

return rune_equip_panel

