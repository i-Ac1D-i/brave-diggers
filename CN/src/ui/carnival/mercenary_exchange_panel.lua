local config_manager = require "logic.config_manager"

local carnival_logic = require "logic.carnival"
local payment_logic = require "logic.payment"

local graphic = require "logic.graphic"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"

local reuse_scrollview = require "widget.reuse_scrollview"
local CARNIVAL_TYPE = constants.CARNIVAL_TYPE

local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

--阶段领取奖励活动
local mercenary_exchange_panel = panel_prototype.New()
mercenary_exchange_panel.__index = mercenary_exchange_panel

function mercenary_exchange_panel.New()
    return setmetatable({}, mercenary_exchange_panel)
end

function mercenary_exchange_panel.InitMeta(root_node)
    mercenary_exchange_panel.meta_root_node = root_node
end

function mercenary_exchange_panel:Init(root_node)
    self.root_node = self.meta_root_node:clone()

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    self.desc_text = self.root_node:getChildByName("desc")

    self.get_btn = self.root_node:getChildByName("get_btn")
    self.icon_img = self.root_node:getChildByName("Image_505_0")
    self.icon_img:ignoreContentAdaptWithSize(true)

    local begin_x, begin_y, interval_x = 56, 65, 80
    self.icon_sub_panels = {}
    --默认创建6个奖励
    for i = 1, 6 do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.icon_sub_panels[i] = sub_panel
    end

    self:RegisterWidgetEvent()
end

function mercenary_exchange_panel:Show(config, step_index)
    self.config = config
    self.step_index = step_index

    self.cur_value, self.reward_mark = carnival_logic:GetValueAndReward(self.config, self.step_index, self.step_index)

    self.get_btn:setVisible(true)
    self.get_btn:setTitleText(lang_constants:Get("carnival_take_btn5"))

    self:ReLoadIconSubPanel(self.config.reward_list[self.step_index].reward_info)
    self:SetConditionDescAndIcon()

    self.root_node:setVisible(true)
end

--设定描述 和 icon
function mercenary_exchange_panel:SetConditionDescAndIcon()
    local str_index = #self.config.mult_str1 == 1 and 1 or self.step_index
    local icon_index = #self.config.mult_str2 == 1 and 1 or self.step_index
    self.desc_text:setString(self.config.mult_str1[str_index])
    self.icon_img:loadTexture(self.config.mult_str2[icon_index], PLIST_TYPE)
end

--设定奖励的sub_panel颜色
function mercenary_exchange_panel:SetColor(color, btn_color)
    self.root_node:setColor(panel_util:GetColor4B(color))
    self.get_btn:setColor(panel_util:GetColor4B(btn_color))
    for i = 1, 6 do
        self.icon_sub_panels[i]:SetColor(color)
    end
end

--重置奖励的sub_panel
function mercenary_exchange_panel:ReLoadIconSubPanel(reward_list)
    for i = 1, 6 do
        local sub_panel = self.icon_sub_panels[i]
        if i <= #reward_list then
            local re = reward_list[i]
            sub_panel:Show(re.reward_type, re.param1, re.param2,  false, false)
        else
            sub_panel.root_node:setVisible(false)
        end
    end
end

function mercenary_exchange_panel:RegisterWidgetEvent()
    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.config.carnival_type == CARNIVAL_TYPE["mercenary_exchange"] then
                graphic:DispatchEvent("show_world_sub_scene", "carnival_exchange_sub_scene", constants["SCENE_TRANSITION_TYPE"]["none"], self.config, self.step_index)
            end
       end
    end)
end

return mercenary_exchange_panel
