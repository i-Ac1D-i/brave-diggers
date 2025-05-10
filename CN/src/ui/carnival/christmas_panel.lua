local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local carnival_logic = require "logic.carnival"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local feature_config = require "logic.feature_config"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local REWARD_TYPE = constants.REWARD_TYPE
local MAX_SUB_PANEL_NUM = 5
local SUB_PANEL_Y = 420 --480

local christmas_panel = panel_prototype.New(true)
function christmas_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/carnival_snowman_panel.csb")

    self.title_text = self.root_node:getChildByName("title")

    self.desc_text = self.root_node:getChildByName("desc")
    self.cost_title_text = self.root_node:getChildByName("cost_title")

    self.yearbook_img = self.root_node:getChildByName("newyearrole")
    self.yearbook_btn = self.yearbook_img:getChildByName("yearbook_btn")
    self.yearbook_btn:setTouchEnabled(true)

    if feature_config:IsFeatureOpen("year_summary") then
        self.yearbook_img:setVisible(true)
    else
        self.yearbook_img:setVisible(false)
    end

    self.reward_sub_panel = self.root_node:getChildByName("point_template")
    self.reward_name_text = self.reward_sub_panel:getChildByName("name")
    self.reward_desc_text = self.reward_sub_panel:getChildByName("desc")

    self.reward_icon_panel = icon_template.New(nil, client_constants.ICON_TEMPLATE_MODE["with_text2"])
    self.reward_icon_panel:Init(self.reward_sub_panel, true)
    self.reward_icon_panel:SetPosition(76, 81)

    self.item_sub_panels = {}
    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        self.item_sub_panels[i] = sub_panel
        self.item_sub_panels[i].root_node:setPositionY(SUB_PANEL_Y)
    end

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function christmas_panel:Show(config)
    config = config or self.config
    self.title_text:setString(config.name)

    local step = carnival_logic:GetCanDoTaskIndex(config)
    if step == 0 then
        return
    end

    local step_num = config.collect_step[step].step_info

    local info = carnival_logic:GetCarnivalInfo(config.key)

    self.can_get_reward = true

    for i = 1, MAX_SUB_PANEL_NUM do
        local sub_panel = self.item_sub_panels[i]
        if i <= #step_num then
            sub_panel:Show(REWARD_TYPE["carnival_token"], config.mult_num1[i], step_num[i], false, false)
            local need_num = step_num[i]
            local cur_num = info.collect_info[i]
            if cur_num >= need_num then
                sub_panel.num_text:setColor(panel_util:GetColor4B(0xa1e01b))
            else
                self.can_get_reward = false
                sub_panel.num_text:setColor(panel_util:GetColor4B(0xf87f26))
            end
            sub_panel.num_text:setString(panel_util:ConvertUnit(cur_num) .. "/" .. panel_util:ConvertUnit(need_num))

        else
            sub_panel:Hide()
        end
    end

    panel_util:SetIconSubPanelsPosition(self.item_sub_panels, MAX_SUB_PANEL_NUM, #step_num, SUB_PANEL_Y)

    local reward_info = config.reward_list[step].reward_info[1]
    local conf = self.reward_icon_panel:Show(reward_info.reward_type, reward_info.param1, reward_info.param2,  false, true)
    self.reward_name_text:setString(conf.name)
    self.reward_desc_text:setString(conf.desc)

    self.cost_title_text:setString(config.mult_str1[step])
    self.desc_text:setString(config.desc)

    self.config = config
    self.step = step

    self.root_node:setVisible(true)
end

function christmas_panel:RegisterWidgetEvent()
    self.yearbook_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "yearbook_panel")
        end
    end)

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.can_get_reward then
                carnival_logic:TakeReward(self.config, self.step, false)
            else
                graphic:DispatchEvent("show_prompt_panel", "carnival_token_not_enough")
            end
        end
    end)
    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("cancel_btn"), self:GetName())
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

function christmas_panel:RegisterEvent()

    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key, step)
        if not self.root_node:isVisible() then
            return
        end

        if carnival_logic:GetCanDoTaskIndex(self.config) == 0 then
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        else
            self:Show()
        end
    end)

end

return christmas_panel
