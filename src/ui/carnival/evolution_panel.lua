local config_manager = require "logic.config_manager"

local mercenary_config = config_manager.mercenary_config
local evolution_config = config_manager.mercenary_evolution_config

local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local troop_logic = require "logic.troop"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local ui_role_prototype = require "entity.ui_role"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"

local CARNIVAL_TYPE = constants.CARNIVAL_TYPE

local REWARD_TYPE = constants.REWARD_TYPE

local evolution_panel = panel_prototype.New()
evolution_panel.__index = evolution_panel

function evolution_panel.New()
    return setmetatable({}, evolution_panel)
end

function evolution_panel.InitMeta(root_node)
    evolution_panel.meta_root_node = root_node
end

function evolution_panel:Init()
    self.root_node = self.meta_root_node:clone()

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    self.evolution_btn = self.root_node:getChildByName("get_btn")

    local begin_x, begin_y, interval_x = 67, 67, 85
    self.origin_sub_panels = {}
    self.add_tip_imgs = {}

    for i = 1, 3 do
        local sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.origin_sub_panels[i] = sub_panel
        sub_panel.root_node:setLocalZOrder(50 + i)
        self.add_tip_imgs[i] = self.root_node:getChildByName("add_tip" .. i)
        self.add_tip_imgs[i]:setLocalZOrder(100 + i)
    end

    self.evolved_sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.evolved_sub_panel:Init(self.root_node)
    self.evolved_sub_panel.root_node:setPosition(407, 67)

    --角色图片
    self.role_sprite = cc.Sprite:create()
    self.role_sprite:setPosition(407, 67)
    self.role_sprite:setAnchorPoint(0.5, 0.5)
    self.root_node:addChild(self.role_sprite, 100)
    self.ui_role = ui_role_prototype.New()

    self:RegisterWidgetEvent()
end

function evolution_panel:Show(config, step_index)
    self.config = config or self.config
    self.step_index = step_index or self.step_index

    local formula_id = config.mult_num1[self.step_index]
    local conf = evolution_config[formula_id]

    self.origin_id = conf["mercenary_id"]
    self.origin_num = conf["mercenary_num"]

    self.formula_id = formula_id

    self.evoluted_mercenary = self.evolved_sub_panel:Show(REWARD_TYPE["mercenary"], conf["get_mercenary_id"], nil,  false, false)

    local mercenary_list = troop_logic:GetMercenaryList()
    self.cur_origin_num = 0
    for instance_id, mercenary in pairs(mercenary_list) do
        if mercenary.template_info.ID == self.origin_id then
            self.cur_origin_num = self.cur_origin_num + 1
        end
    end

    self:SetStatus(false)
    self.root_node:setVisible(true)
end

--选择完佣兵
function evolution_panel:ChooseMercenary(key, index, list)
    if self.step_index ~= index then
        return
    end

    if not list then
        return
    end

    self.mercenary_list = list
    self:SetStatus(true)
end

function evolution_panel:SetStatus(add_mercenary)
    local color = add_mercenary and 0xffffff or 0x7f7f7f
    for i = 1, 3 do
        local sub_panel = self.origin_sub_panels[i]
        if i <= self.origin_num then
            self.add_tip_imgs[i]:setVisible(not add_mercenary)
            sub_panel.root_node:setColor(panel_util:GetColor4B(color))
            sub_panel.icon_img:setColor(panel_util:GetColor4B(color))
            sub_panel:Show(REWARD_TYPE["mercenary"], self.origin_id, nil,  false, false)
        else
            sub_panel:Hide()
        end
    end

    self.evolution_btn:setColor(panel_util:GetColor4B(color))

    if add_mercenary then
        self.ui_role:Init(self.role_sprite, self.evoluted_mercenary.sprite)
        self.ui_role:WalkAnimation(1, 0.3)

        self.evolved_sub_panel.icon_img:setVisible(false)
    else
        self.evolved_sub_panel.icon_img:setVisible(true)
        self.role_sprite:setVisible(false)
    end
end

function evolution_panel:RegisterWidgetEvent()
    self.evolution_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.mercenary_list and #self.mercenary_list == self.origin_num then
                carnival_logic:EvolutionMercenary(self.config.key, self.formula_id, self.mercenary_list)
            else
                graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_not_enough2")
            end
        end
    end)

    local add_mercenary_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.cur_origin_num < self.origin_num then
                local name = mercenary_config[self.origin_id]["name"]
                graphic:DispatchEvent("show_prompt_panel", "carnival_evolution_not_enough", self.origin_num, name)
            else
                local scene_transition = constants["SCENE_TRANSITION_TYPE"]["none"]
                local choose_mode = client_constants["MERCENARY_CHOOSE_SHOW_MODE"]["evolution"]
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_choose_sub_scene", scene_transition, choose_mode, self.formula_id, self.config.key, self.step_index)
            end
        end
    end

    for i = 1, 3 do
        self.origin_sub_panels[i].root_node:addTouchEventListener(add_mercenary_method)
    end
end

function evolution_panel:OnEvolutionSuccess(formula_id)
    if self.formula_id ~= formula_id then
        return
    end

    self.cur_origin_num = self.cur_origin_num - self.origin_num
    self:SetStatus(false)
end

return evolution_panel
