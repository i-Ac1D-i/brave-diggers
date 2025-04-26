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

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local CHOOSE_SHOW_MODE = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]

local SORT_TYPE = client_constants["SORT_TYPE"]

local INFO_TYPE =
{
    ["material"] = 1,
    ["acceptor"] = 2,
}

local temp_mercenary = {}

local info_sub_panel = panel_prototype.New()
info_sub_panel.__index = info_sub_panel

function info_sub_panel.New()
    return setmetatable({}, info_sub_panel)
end

function info_sub_panel:Init(root_node, panel_type)
    self.root_node = root_node
    root_node:setVisible(false)
    self.type = panel_type

    self.selected_node = root_node:getChildByName("selected")
    self.unselected_node = root_node:getChildByName("not_selected")

    self.name_text = self.selected_node:getChildByName("role_name")
    self.role_bg_img = self.selected_node:getChildByName("rolebg")
    self.role_icon_img = self.role_bg_img:getChildByName("icon")
    self.role_icon_img:ignoreContentAdaptWithSize(true)
    --self.ui_role = ui_role_prototype.New()
    --level
    self.level_value_text = self.selected_node:getChildByName("level_value")

    --bp
    local bp_node = self.selected_node:getChildByName("bp")
    self.cur_bp_text = bp_node:getChildByName("value1")
    self.after_bp_text = bp_node:getChildByName("value2")

    --weapon
    local weapon_node = self.selected_node:getChildByName("weapon")
    self.cur_weapon_text = weapon_node:getChildByName("value1")
    self.after_weapon_text = weapon_node:getChildByName("value2")

    --artifact
    local artifact_node = self.selected_node:getChildByName("artifact")
    self.cur_artifact_text = artifact_node:getChildByName("value1")
    self.after_artifact_text = artifact_node:getChildByName("value2")
    -- 多语言调整X位置
    if platform_manager:GetLocale() == "fr" or platform_manager:GetLocale() == "de" and platform_manager:GetChannelInfo().transmigration_panel_change_artifact_value1_x then
        self.cur_artifact_text:setPositionX(self.cur_artifact_text:getPositionX() - 22)
        self.after_artifact_text:setPositionX(self.after_artifact_text:getPositionX() - 10)
    end

    --wake up
    local wakeup_node = self.selected_node:getChildByName("wakeup")
    self.cur_wakeup_text = wakeup_node:getChildByName("value1")
    self.after_wakeup_text = wakeup_node:getChildByName("value2")

    --突破
    local force_lv_node = self.selected_node:getChildByName("break")
    self.cur_force_lv_text = force_lv_node:getChildByName("value1")
    self.after_force_lv_text = force_lv_node:getChildByName("value2")

    self.change1_mercenary_btn = self.selected_node:getChildByName("change_btn")
    self.change2_mercenary_btn = self.unselected_node:getChildByName("change1_btn")

end

function info_sub_panel:SetValueTextColor(cur_value, after_value, after_widget)

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

function info_sub_panel:Show(cur_mercenary, temp_mercenary)
    self.root_node:setVisible(true)
    local template_info = cur_mercenary.template_info

    self.role_bg_img:loadTexture(MERCENARY_BG_SPRITE[template_info.quality], PLIST_TYPE)
    self.role_icon_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)

    self.name_text:setString(template_info.name)
    --计算战斗力和等级
    troop_logic:CalcMercenaryLevel(cur_mercenary)
    troop_logic:CalcMercenaryBP(cur_mercenary)

    --武器等级
    self.cur_weapon_text:setString(cur_mercenary.weapon_lv .. "/" ..constants["MAX_WEAPON_LV"])
    self.after_weapon_text:setString(temp_mercenary.weapon_lv .. "/" .. constants["MAX_WEAPON_LV"])
    self:SetValueTextColor(cur_mercenary.weapon_lv, temp_mercenary.weapon_lv, self.after_weapon_text)

    --觉醒
    self.cur_wakeup_text:setString(cur_mercenary.wakeup .. "/" .. template_info.max_wakeup)
    temp_mercenary.wakeup = math.min(temp_mercenary.wakeup, template_info.max_wakeup)

    self.after_wakeup_text:setString(temp_mercenary.wakeup .. "/" .. template_info.max_wakeup)
    self:SetValueTextColor(cur_mercenary.wakeup, temp_mercenary.wakeup, self.after_wakeup_text)

    --突破
    self.cur_force_lv_text:setString(cur_mercenary.force_lv .. "%")
    if template_info.can_upgrade_force then
        self.after_force_lv_text:setString(temp_mercenary.force_lv .. "%")
    else
        self.after_force_lv_text:setString("%0")
        temp_mercenary.force_lv = 0
    end
    self:SetValueTextColor(cur_mercenary.force_lv, temp_mercenary.force_lv, self.after_force_lv_text)

    --宝具
  if template_info.have_artifact then
        if temp_mercenary.is_open_artifact then
            self.after_artifact_text:setString(lang_constants:Get("mercenary_open_artifact"))
        else
            self.after_artifact_text:setString(lang_constants:Get("mercenary_not_open_artifact"))
        end

        if cur_mercenary.is_open_artifact then
            self.cur_artifact_text:setString(lang_constants:Get("mercenary_open_artifact"))
        else
            self.cur_artifact_text:setString(lang_constants:Get("mercenary_not_open_artifact"))
        end
    else
        self.after_artifact_text:setString(lang_constants:Get("mercenary_not_has_artifact"))
        self.cur_artifact_text:setString(lang_constants:Get("mercenary_not_has_artifact"))
    end

    local cur_open_value = cur_mercenary.is_open_artifact and 1 or 0
    local after_open_value = temp_mercenary.is_open_artifact and 1 or 0

    self:SetValueTextColor(cur_open_value, after_open_value, self.after_artifact_text)

    troop_logic:CalcMercenaryLevel(temp_mercenary)
    if temp_mercenary.template_info then
        troop_logic:CalcMercenaryBP(temp_mercenary)
    end

    --战斗力
    panel_util:ConvertUnit(cur_mercenary.battle_point, self.cur_bp_text, false)
    panel_util:ConvertUnit(temp_mercenary.battle_point, self.after_bp_text, false)
    self:SetValueTextColor(cur_mercenary.battle_point, temp_mercenary.battle_point, self.after_bp_text)

    --等级
    self.level_value_text:setString(lang_constants:Get("level_shot_string") .. cur_mercenary.level .. ">>" .. temp_mercenary.level)
end

--是否选中佣兵
function info_sub_panel:IsSelectedMerceanry()
    return self.selected_node:isVisible()
end

--设定选中状态
function info_sub_panel:SetSelectedStatus(select_mercenary)
    self.selected_node:setVisible(select_mercenary)
    self.unselected_node:setVisible(not select_mercenary)
end

local transmigration_panel = panel_prototype.New()
function transmigration_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/transmigration_panel.csb")
    local root_node = self.root_node

    self.explain_node = root_node:getChildByName("explain")
    self.explain_node:setVisible(false)

    --FYD 解决文字重叠问题
    local explain_desc2_text = self.explain_node:getChildByName("desc2")
    local change_height = platform_manager:GetChannelInfo().transmigration_explain_desc2_change_height 
    if change_height then
        local x,y = explain_desc2_text:getPosition();
         explain_desc2_text:setPosition(x,y + change_height);
    end


    self.title_bg_img = root_node:getChildByName("title_bg")
    self.title_bg_img:setTouchEnabled(true)

    --灵源
    self.material_sub_panel = info_sub_panel.New() -- material
    self.material_sub_panel:Init(root_node:getChildByName("material"), INFO_TYPE["material"])

    --灵主
    self.acceptor_sub_panel = info_sub_panel.New()
    self.acceptor_sub_panel:Init(root_node:getChildByName("acceptor"), INFO_TYPE["acceptor"])

    self.init_acceptor_pos_y = self.acceptor_sub_panel.root_node:getPositionY()
    --按钮
    self.back_btn = root_node:getChildByName("back_btn")

    self.arrow_img = root_node:getChildByName("transmigration_arrow2_d_0")

    --
    local bottom_bar = root_node:getChildByName("bottom_bar")
    self.do_transmigrate_btn = bottom_bar:getChildByName("confirm_btn")
    self.do_transmigrate_text = self.do_transmigrate_btn:getChildByName("desc")

    self.cost_text = bottom_bar:getChildByName("blood_diamond_value")

    self.saleinfo_btn = self.root_node:getChildByName("saleinfo_btn")

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function transmigration_panel:InitWidgetVisible()
    self.material_mercenary = nil
    self.acceptor_mercenary = nil

    self.acceptor_sub_panel.root_node:setPositionY(self.init_acceptor_pos_y)

    self.explain_node:setVisible(false)

    self.acceptor_sub_panel:SetSelectedStatus(false)
    self.material_sub_panel:SetSelectedStatus(false)

    self.acceptor_sub_panel.root_node:setVisible(true)
    self.material_sub_panel.root_node:setVisible(true)

    self.do_transmigrate_text:setString(lang_constants:Get("mercenary_trans_unchoose"))
    self.cost_text:setString("0")
    self.do_transmigrate_btn:setColor(panel_util:GetColor4B(0x7f7f7f))

    self.material_sub_panel.change1_mercenary_btn:setVisible(true)
    self.acceptor_sub_panel.change1_mercenary_btn:setVisible(true)

    self.arrow_img:setVisible(true)

    self.transmigration_success = false
end

function transmigration_panel:SwapMercenary()
    --灵源面板
    self:SetAfterMercenaryInfo(self.acceptor_mercenary)
    temp_mercenary.template_info = self.material_mercenary.template_info
    self.material_sub_panel:Show(self.material_mercenary, temp_mercenary)

    --灵主面板， temp
    self:SetAfterMercenaryInfo(self.material_mercenary)
    temp_mercenary.template_info = self.acceptor_mercenary.template_info
    self.acceptor_sub_panel:Show(self.acceptor_mercenary, temp_mercenary)

end

function transmigration_panel:Show(mode, cur_mercenary)

    if mode == CHOOSE_SHOW_MODE["material"] then
        --更新灵源信息
        self.material_mercenary = cur_mercenary
        --如果已经选择灵主，则更新灵主信息
        if self.acceptor_sub_panel:IsSelectedMerceanry() then
            self:SwapMercenary()
        else
            self:SetAfterMercenaryInfo()
            temp_mercenary.template_info = cur_mercenary.template_info
            self.material_sub_panel:Show(self.material_mercenary, temp_mercenary)
        end

        self.material_sub_panel:SetSelectedStatus(true)

    elseif mode == CHOOSE_SHOW_MODE["acceptor"] then
        self.acceptor_mercenary = cur_mercenary

        if self.material_sub_panel:IsSelectedMerceanry() then
            self:SwapMercenary()
        else
            self:SetAfterMercenaryInfo()
            temp_mercenary.template_info = self.acceptor_mercenary.template_info
            self.acceptor_sub_panel:Show(self.acceptor_mercenary, temp_mercenary)
        end

        self.acceptor_sub_panel:SetSelectedStatus(true)

    else
        self:InitWidgetVisible()
    end

    --灵主和灵源同时都选定时
    if self.material_sub_panel:IsSelectedMerceanry() and self.acceptor_sub_panel:IsSelectedMerceanry() then
        local cost_blood_diamond = troop_logic:GetTransmigrationPrice(self.material_mercenary.instance_id, self.acceptor_mercenary.instance_id)
        self.cost_text:setString(tostring(cost_blood_diamond))

        if resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], cost_blood_diamond, false) then
            self.do_transmigrate_text:setString(lang_constants:Get("mercenary_trans_start"))
            self.do_transmigrate_btn:setColor(panel_util:GetColor4B(0xffffff))

        else
            self.do_transmigrate_text:setString(lang_constants:Get("mercenary_trans_not_enough_blood_diamond"))
        end
    end

    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["transmigrate"], constants.CARNIVAL_TYPE["transmigrate"])
    local free_tag = configuration:GetViewedFreeTransmigration()
    if free_tag then
        self.saleinfo_btn:setVisible(true)
        self.saleinfo_btn:getChildByName("tip"):setVisible(not configuration:HasViewedTransmigration() or free_tag)
    else
        self.saleinfo_btn:setVisible(false)
    end

    self.root_node:setVisible(true)
end

function transmigration_panel:SetAfterMercenaryInfo(mercenary)
    if mercenary then
        temp_mercenary.exp = mercenary.exp
        temp_mercenary.weapon_lv = mercenary.weapon_lv
        temp_mercenary.wakeup = mercenary.wakeup
        temp_mercenary.is_open_artifact = mercenary.is_open_artifact
        temp_mercenary.force_lv = mercenary.force_lv
    else
        temp_mercenary.exp = 0
        temp_mercenary.weapon_lv = 0
        temp_mercenary.wakeup = 1
        temp_mercenary.is_open_artifact = false
        temp_mercenary.force_lv = 0
    end
end

function transmigration_panel:RegisterWidgetEvent()
    --选择灵源
    local select_material = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local acceptor_mercenary_id = 0
            if self.acceptor_mercenary then
                acceptor_mercenary_id = self.acceptor_mercenary.instance_id
            end
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", SCENE_TRANSITION_TYPE["none"], CHOOSE_SHOW_MODE["material"], acceptor_mercenary_id, 0, 0)
        end
    end

    self.material_sub_panel.change1_mercenary_btn:addTouchEventListener(select_material)
    self.material_sub_panel.change2_mercenary_btn:addTouchEventListener(select_material)

    --选择灵主
    local select_acceptor = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local material_mercenary_id = 0
            if self.material_mercenary then
                material_mercenary_id = self.material_mercenary.instance_id
            end
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", SCENE_TRANSITION_TYPE["none"], CHOOSE_SHOW_MODE["acceptor"], material_mercenary_id, 0, 0)
        end
    end

    self.acceptor_sub_panel.change1_mercenary_btn:addTouchEventListener(select_acceptor)
    self.acceptor_sub_panel.change2_mercenary_btn:addTouchEventListener(select_acceptor)

    --返回到佣兵主界面
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "mercenary_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"])
        end
    end)

    self.do_transmigrate_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if self.transmigration_success then
                self:InitWidgetVisible()
            else
                if self.material_mercenary and self.acceptor_mercenary then
                    local confirm = client_constants.CONFIRM_MSGBOX_MODE["transmigration"]
                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", confirm, self.material_mercenary.instance_id, self.acceptor_mercenary.instance_id)
                end
            end
        end
    end)


    self.title_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            self.explain_node:setVisible(true)

        elseif event_type == ccui.TouchEventType.ended then
            self.explain_node:setVisible(false)

        elseif event_type == ccui.TouchEventType.canceled then
            self.explain_node:setVisible(false)
        end
    end)

    self.saleinfo_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --configuration:SetViewTransmigrationTime(time_logic:Now())
            graphic:DispatchEvent("show_world_sub_panel", "transmigration_sale_msgbox")
        end
    end)
end

function transmigration_panel:RegisterEvent()
    graphic:RegisterEvent("transmigrate_mercenary", function()
        if not self.root_node:isVisible() then
            return
        end

        --转生成功之后
        self.material_sub_panel.root_node:setVisible(false)
        self.acceptor_sub_panel.root_node:setPositionY(586)
        self.acceptor_sub_panel.change1_mercenary_btn:setVisible(false)
        self.do_transmigrate_text:setString(lang_constants:Get("mercenary_trans_continue"))

        self.transmigration_success = true
        self.material_mercenary = nil
        self.acceptor_mercenary = nil

        self.arrow_img:setVisible(false)
    end)
end

return transmigration_panel
