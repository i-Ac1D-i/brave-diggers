local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local configuration = require "util.configuration"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local resource_logic = require "logic.resource"
local carnival_logic = require "logic.carnival"
local time_logic = require "logic.time"

local panel_prototype = require "ui.panel"
local ui_role_prototype = require "entity.ui_role"

local panel_util = require "ui.panel_util"

local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local rune_logic = require "logic.rune"

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]

local SORT_TYPE = client_constants["SORT_TYPE"]

local rune_exchange_panel = panel_prototype.New()
function rune_exchange_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/rune_translate.csb")
    local root_node = self.root_node

    --按钮
    self.back_btn = root_node:getChildByName("back_btn")
    local bottom_bar = root_node:getChildByName("bottom_bar")
    self.do_transmigrate_btn = bottom_bar:getChildByName("confirm_btn")
    self.do_transmigrate_text = self.do_transmigrate_btn:getChildByName("desc")
    self.cost_text = bottom_bar:getChildByName("blood_diamond_value")

    --一键清除按钮
    self.one_clear = root_node:getChildByName("btn_delete")

    --转换材料
    local acceptor_root = root_node:getChildByName("acceptor")
    --转换原材料
    local material_root = root_node:getChildByName("material")

    self.acceptor_select = acceptor_root:getChildByName("selected")
    self.acceptor_not_select = acceptor_root:getChildByName("not_selected")
    --选择按钮
    self.acceptor_not_select_choose_btn = self.acceptor_not_select:getChildByName("change1_btn")
    self.acceptor_select_choose_btn = self.acceptor_select:getChildByName("change_btn")

    self.material_select = material_root:getChildByName("selected")
    self.material_not_select = material_root:getChildByName("not_selected")
    --选择按钮
    self.material_not_select_choose_btn = self.material_not_select:getChildByName("change1_btn")
    self.material_select_choose_btn = self.material_select:getChildByName("change_btn")

    self.role_img = self.root_node:getChildByName("npc")
    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. 1 .. ".png", PLIST_TYPE)

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function rune_exchange_panel:Show(is_reset)
    self.root_node:setVisible(true)
    if is_reset then
        self:LoadMaterial()
        self:LoadAcceptor()
    end
end

function rune_exchange_panel:LoadMaterial(rune_id)
    if rune_id then
        self.material_not_select:setVisible(false)
        self.material_select:setVisible(true)
        local rune_panel = self.material_select:getChildByName("rune_panel")
        local icon_img = rune_panel:getChildByName("rune_icon")
        local top_quality_img = rune_panel:getChildByName("top_quality")
        local name_text = self.material_select:getChildByName("rune_name_up")
        name_text:setString(self.rune_info1.template_info.name)
        icon_img:loadTexture(self.rune_info1.template_info.icon, PLIST_TYPE)
        top_quality_img:setVisible(self.rune_info1.template_info.quality == constants["MAX_RUNE_QUALITY"])
        self:ChangeProperty()
    else
        self.rune_info1 = nil 
        self.material_not_select:setVisible(true)
        self.material_select:setVisible(false)
    end
    self:RefshExchangeCost()
end

function rune_exchange_panel:LoadAcceptor(rune_id)
    if rune_id then
        self.acceptor_not_select:setVisible(false)
        self.acceptor_select:setVisible(true)

        local rune_panel = self.acceptor_select:getChildByName("rune_panel_0")
        local icon_img = rune_panel:getChildByName("rune_icon")
        local top_quality_img = rune_panel:getChildByName("top_quality")
        local name_text = self.acceptor_select:getChildByName("rune_name")
        name_text:setString(self.rune_info2.template_info.name)
        icon_img:loadTexture(self.rune_info2.template_info.icon, PLIST_TYPE)
        top_quality_img:setVisible(self.rune_info2.template_info.quality == constants["MAX_RUNE_QUALITY"])
        self:ChangeProperty()
    else
        self.rune_info2 = nil
        self.acceptor_not_select:setVisible(true)
        self.acceptor_select:setVisible(false)
    end
    self:RefshExchangeCost()
end

function rune_exchange_panel:ChangeProperty()
    if self.rune_info2 and self.rune_info1 then
        self:UpLevel(self.rune_info1.level, self.rune_info2.level)
        self:UpExp(self.rune_info1.exp, self.rune_info2.exp)
    elseif self.rune_info1 then
        self:UpLevel(self.rune_info1.level, nil)
        self:UpExp(self.rune_info1.exp, nil)
    elseif self.rune_info2 then
        self:UpLevel(nil, self.rune_info2.level)
        self:UpExp(nil, self.rune_info2.exp)
    end
    
    self:UpProperty()
end

function rune_exchange_panel:UpLevel(value1, value2)
    local level_node1 = self.material_select:getChildByName("lv")
    local level1_text1 = level_node1:getChildByName("value1")
    local level1_text2 = level_node1:getChildByName("value2")
    local level1_arrw = level_node1:getChildByName("arrow")

    local level_node2 = self.acceptor_select:getChildByName("lv")
    local level2_text1 = level_node2:getChildByName("value1")
    local level2_text2 = level_node2:getChildByName("value2")
    local level2_arrw = level_node2:getChildByName("arrow")

    level1_arrw:setVisible(false)
    level2_arrw:setVisible(false)
    level2_text2:setVisible(false)
    level1_text2:setVisible(false)

    level1_text1:setString(value1 or "")
    level2_text1:setString(value2 or "")

    if value1 and value2 then
        --两个值都有的情况下就要交换属性
        level1_arrw:setVisible(true)
        level2_arrw:setVisible(true)
        level2_text2:setVisible(true)
        level1_text2:setVisible(true)
        level1_text2:setString(value2)
        self:SetValueTextColor(value1,value2,level1_text2)
        level2_text2:setString(value1)
        self:SetValueTextColor(value2,value1,level2_text2)
    end

end

function rune_exchange_panel:UpExp(value1, value2)
    local exp_node1 = self.material_select:getChildByName("exp")
    local exp1_text1 = exp_node1:getChildByName("value1")
    local exp1_text2 = exp_node1:getChildByName("value2")
    local exp1_arrw = exp_node1:getChildByName("arrow")

    local exp_node2 = self.acceptor_select:getChildByName("exp")
    local exp2_text1 = exp_node2:getChildByName("value1")
    local exp2_text2 = exp_node2:getChildByName("value2")
    local exp2_arrw = exp_node2:getChildByName("arrow")

    exp1_arrw:setVisible(false)
    exp2_arrw:setVisible(false)
    exp2_text2:setVisible(false)
    exp1_text2:setVisible(false)

    exp1_text1:setString(value1 or "")
    exp2_text1:setString(value2 or "")

    if value1 and value2 then
        --两个值都有的情况下就要交换属性
        exp1_arrw:setVisible(true)
        exp2_arrw:setVisible(true)
        exp2_text2:setVisible(true)
        exp1_text2:setVisible(true)
        exp1_text2:setString(value2)
        self:SetValueTextColor(value1,value2,exp1_text2)
        exp2_text2:setString(value1)
        self:SetValueTextColor(value2,value1,exp2_text2)
    end
end

function rune_exchange_panel:UpProperty()
    local property_node1 = self.material_select:getChildByName("property")
    local property_title1 = property_node1:getChildByName("desc")
    local property_arrw1 = property_node1:getChildByName("arrow")
    local property_now_value1 = property_node1:getChildByName("value1")
    local property_end_value1 = property_node1:getChildByName("value2")
    property_end_value1:setVisible(false)
    property_arrw1:setVisible(false)

    local property_node2 = self.acceptor_select:getChildByName("lv_0")
    local property_title2 = property_node2:getChildByName("desc")
    local property_arrw2 = property_node2:getChildByName("arrow")
    local property_now_value2 = property_node2:getChildByName("value1")
    local property_end_value2 = property_node2:getChildByName("value2")
    property_end_value2:setVisible(false)
    property_arrw2:setVisible(false)

    if self.rune_info1 and self.rune_info2 then
        local rune_property_value1, rune1_title = rune_logic:GetRunPropertyValueAndTitle(self.rune_info1.template_id, self.rune_info1.level)
        local rune_property_end_value1 = rune_logic:GetRunPropertyValueAndTitle(self.rune_info1.template_id, self.rune_info2.level)
        
        local rune_property_value2, rune2_title = rune_logic:GetRunPropertyValueAndTitle(self.rune_info2.template_id, self.rune_info2.level)
        local rune_property_end_value2 = rune_logic:GetRunPropertyValueAndTitle(self.rune_info2.template_id, self.rune_info1.level)

        property_arrw1:setVisible(true)
        property_end_value1:setVisible(true)
        property_title1:setString(rune1_title)
        property_now_value1:setString(rune_property_value1)
        property_end_value1:setString(rune_property_end_value1)
        self:SetValueTextColor(math.abs(rune_property_value1),math.abs(rune_property_end_value1),property_end_value1)

        property_arrw2:setVisible(true)
        property_end_value2:setVisible(true)
        property_title2:setString(rune2_title)
        property_now_value2:setString(rune_property_value2)
        property_end_value2:setString(rune_property_end_value2)
        self:SetValueTextColor(math.abs(rune_property_value2),math.abs(rune_property_end_value2),property_end_value2)

    elseif self.rune_info1 then
        local rune_property_value1, rune1_title = rune_logic:GetRunPropertyValueAndTitle(self.rune_info1.template_id, self.rune_info1.level)
        property_title1:setString(rune1_title)
        property_now_value1:setString(rune_property_value1)
    elseif self.rune_info2 then
        local rune_property_value2, rune2_title = rune_logic:GetRunPropertyValueAndTitle(self.rune_info2.template_id, self.rune_info2.level)
        property_title2:setString(rune2_title)
        property_now_value2:setString(rune_property_value2)
    end
end

function rune_exchange_panel:SetValueTextColor(cur_value, after_value, after_widget)

    if cur_value < after_value then
        --up
        after_widget:setColor(panel_util:GetColor4B(0x5e8e00))
    elseif cur_value == after_value then
        --same
        after_widget:setColor(panel_util:GetColor4B(0x3c3532))
    else
        --down
        after_widget:setColor(panel_util:GetColor4B(0xef3d34))
    end

end

function rune_exchange_panel:RegisterWidgetEvent()
   
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    self.do_transmigrate_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.rune_info1 == nil or self.rune_info2 == nil  then
                graphic:DispatchEvent("show_prompt_panel", "please_select_two_rune_can_exchange")
                return
            end
            local exchange_data = {self.rune_info1, self.rune_info2}
            local mode = client_constants["CONFIRM_MSGBOX_MODE"]["rune_exchange_cost_msgbox"]
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.need_cost, exchange_data)
        end
    end)

    self.acceptor_not_select_choose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EXCHANGE"], {}, 2, self.rune_info1)
        end
    end)

    self.acceptor_select_choose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EXCHANGE"], {}, 2, self.rune_info1)
        end
    end)

    self.material_not_select_choose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EXCHANGE"], {}, 1, self.rune_info2)
        end
    end)

    self.material_select_choose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "rune_bag_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], client_constants["RUNE_BAG_SHOW_TYPE"]["EXCHANGE"], {}, 1, self.rune_info2)
        end
    end)

    self.one_clear:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:LoadMaterial()
            self:LoadAcceptor()
        end
    end)
end

function rune_exchange_panel:RefshExchangeCost()

    if self.rune_info1 and  self.rune_info2 then
        self.do_transmigrate_btn:setColor(panel_util:GetColor4B(0xffffff))
    else
        self.do_transmigrate_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
    end

    if self.rune_info1 then
        self.one_clear:setVisible(true)
        self.need_cost = rune_logic:GetExchangeCost(self.rune_info1.template_info.quality)
        self.cost_text:setString(self.need_cost)
    elseif self.rune_info2 then
        self.one_clear:setVisible(true)
        self.need_cost = rune_logic:GetExchangeCost(self.rune_info2.template_info.quality)
        self.cost_text:setString(self.need_cost)
    else
        self.need_cost = 0
        self.one_clear:setVisible(false)
        self.cost_text:setString(0)
    end
end

function rune_exchange_panel:RegisterEvent()
    graphic:RegisterEvent("rune_exchange_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:LoadMaterial()
        self:LoadAcceptor()
    end)

    --选择符文成功
    graphic:RegisterEvent("rune_bag_select_confirm", function(show_type, select_rune_list, select_index)
        if not self.root_node:isVisible() then
            return
        end
        if show_type == client_constants["RUNE_BAG_SHOW_TYPE"]["EXCHANGE"] and #select_rune_list > 0 and select_index then
            if select_index == 1 then
                self.rune_info1 = select_rune_list[1]
                self:LoadMaterial(select_rune_list[1])
            else
                self.rune_info2 = select_rune_list[1]
                self:LoadAcceptor(select_rune_list[1])
            end
        end
    end)
end

return rune_exchange_panel
