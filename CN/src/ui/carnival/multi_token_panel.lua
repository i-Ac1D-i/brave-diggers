local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local icon_template = require "ui.icon_panel"

local REWARD_TYPE = constants.REWARD_TYPE
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]
local MAX_TOKEN_NUM = 5 --一个活动最多可搜集的代币

--多种代币兑换多档奖励
local multi_token_panel = panel_prototype.New()
multi_token_panel.__index = multi_token_panel

function multi_token_panel.New()
    return setmetatable({}, multi_token_panel)
end

function multi_token_panel.InitMeta(root_node)
    multi_token_panel.meta_root_node = root_node
end

function multi_token_panel:Init(root_node)
    self.root_node = self.meta_root_node:clone()

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    self.desc_text = self.root_node:getChildByName("desc")
    self.get_btn = self.root_node:getChildByName("get_btn")

    local begin_x, begin_y, interval_x = 56, 65, 80
    self.icon_sub_panels = {}
    --默认创建6个奖励
    for i = 1, 6 do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.icon_sub_panels[i] = sub_panel
    end

    begin_x, begin_y, interval_x = 538, 16, 60
    self.token_sub_panels = {}
    for i = 1, MAX_TOKEN_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.desc_text)
        sub_panel.root_node:setPosition(begin_x - (i - 1) * interval_x, begin_y)
        sub_panel.root_node:setScale(0.75, 0.75)
        sub_panel.num_text:setFontSize(28)
        sub_panel.text_bg_img:setContentSize(45, 36)
        self.token_sub_panels[i] = sub_panel
    end

    self:RegisterWidgetEvent()
end

--显示
function multi_token_panel:Show(config, step_index)
    self.config = config or self.config
    self.step_index = step_index or self.step_index

    self:ReLoadIconSubPanel()
    self:LoadTokenSubPanel()
    self.root_node:setVisible(true)

    self.get_btn:setVisible(true)
    self.status = carnival_logic:GetStageRewardIndex(self.config.key, self.step_index)
    if self.status == STEP_STATUS["can_take"] then
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        self.get_btn:setColor(panel_util:GetColor4B(0xffffff))

    elseif self.status == STEP_STATUS["cant_take"] then
        self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        self.get_btn:setColor(panel_util:GetColor4B(0x7f7f7f))

    elseif self.status == STEP_STATUS["already_taken"] then
        self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
        self.get_btn:setVisible(false)
    end

    self.get_btn:setTitleText(lang_constants:Get("campaign_reward_rank_tips"))
    
end

--重置奖励的sub_panel
function multi_token_panel:ReLoadIconSubPanel()
    local reward_list =  self.config.reward_list[self.step_index].reward_info
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

--需要代币
function multi_token_panel:LoadTokenSubPanel()
    for i = 1, MAX_TOKEN_NUM do
        local sub_panel = self.token_sub_panels[i]
        local need_value = self.config.collect_step[self.step_index].step_info[i]
        if i <= #self.config.mult_num1 then
            self.desc_text:setString(string.format(self.config.mult_str1[i], self.config.mult_num1[i]))
            sub_panel:Show(REWARD_TYPE["carnival_token"], self.config.mult_num1[i], need_value, false, false)
        else
            sub_panel.root_node:setVisible(false)
        end
    end
end

--控件事件
function multi_token_panel:RegisterWidgetEvent()
    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local can_take = carnival_logic:CanTakeReward(self.config, self.step_index)
 
            if not can_take then
                return
            end

            graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("confirm_take_reward_title"),
                        lang_constants:Get("confirm_take_reward_desc"),
                        lang_constants:Get("common_confirm"),
                        lang_constants:Get("common_cancel"),
            function()
                 carnival_logic:TakeReward(self.config, self.step_index)
            end)
        end
    end)
end

return multi_token_panel
