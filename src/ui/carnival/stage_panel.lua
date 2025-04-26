local config_manager = require "logic.config_manager"

local platform_manager = require "logic.platform_manager"
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

local REWARD_TYPE = constants.REWARD_TYPE
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

local MAZE_STATUS =
{
    lang_constants:Get("cant_finish_maze"),
    lang_constants:Get("finish_maze"),
    lang_constants:Get("already_taken_the_reward"),
}

--阶段领取奖励活动
local stage_panel = panel_prototype.New()
stage_panel.__index = stage_panel

function stage_panel.New()
    return setmetatable({}, stage_panel)
end

function stage_panel.InitMeta(root_node)
    stage_panel.meta_root_node = root_node
end

function stage_panel:Init(root_node)
    self.root_node = self.meta_root_node:clone()

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    self.desc_text = self.root_node:getChildByName("desc")
    self.num_text = self.root_node:getChildByName("num")

    self.get_btn = self.root_node:getChildByName("get_btn")
    self.icon_img = self.root_node:getChildByName("icon")
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

function stage_panel:Show(config, step_index)
    self.config = config or self.config
    self.step_index = step_index or self.step_index

    --todo carnival_logic 接收到config的时候解析出来
    if self.config.need_type == "collect_token" then
        self.need_value = self.config.collect_step[self.step_index].step_info[1]
    else
        self.need_value = self.config.mult_num1[self.step_index]
    end

    self.cur_value, self.reward_mark = carnival_logic:GetValueAndReward(self.config, self.step_index, self.step_index)

    self.num_text:setVisible(true)
    self.get_btn:setVisible(true)
    self.num_str = ""

    if self.config.carnival_type == CARNIVAL_TYPE["single_payment"] or self.config.carnival_type == CARNIVAL_TYPE["single_equal"] then
        self.num_text:setVisible(false)
    elseif self.config.carnival_type == CARNIVAL_TYPE["ladder"] then
        self.get_btn:setVisible(false)
    end

    self:ReLoadIconSubPanel(self.config.reward_list[self.step_index].reward_info)
    self:SetText()
    self:SetConditionDescAndIcon()
    self:CarnivalRewardStatus()

    self.root_node:setVisible(true)
end

--关卡的num_text是文本要特殊处理
function stage_panel:SetMazeText()
    local maze_conf = config_manager.adventure_maze_config[self.need_value]
    local need_income_id = maze_conf["income_id"]
    local need_difficulty = lang_constants:Get("adventure_difficulty" .. config_manager.adventure_income_config[need_income_id]["difficulty"])

    local status = carnival_logic:GetStageRewardIndex(self.config.key, self.step_index)

    self.num_str = MAZE_STATUS[status]
    self.need_value = maze_conf["name"] .. need_difficulty
end

--设文本 根据need_type
function stage_panel:SetText()
    local get_text = lang_constants:Get("carnival_take_btn1")
    self:SetColor(0xffffff, 0xffffff)

    if self.config.need_type == constants["ACHIEVEMENT_TYPE"]["maze"] then
        --关卡的显示文本
        self:SetMazeText()
    else
        local need_value = panel_util:ConvertUnit(self.need_value)
        self.num_str = panel_util:ConvertUnit(self.cur_value) .. "/" .. need_value

        if self.config.need_type == constants.REWARD_TYPE["carnival_token"] then
            get_text = lang_constants:Get("carnival_take_btn2")
        end

    end

    self.num_text:setString(self.num_str)
    self.get_btn:setTitleText(get_text)
end

--设定描述 和 icon
function stage_panel:SetConditionDescAndIcon()
    local str_index = #self.config.mult_str1 == 1 and 1 or self.step_index
    local icon_index = #self.config.mult_str2 == 1 and 1 or self.step_index

    self.desc_text:setString(string.format(self:GetLocaleInfoString(self.config, "mult_str1", str_index), tostring(self.need_value)))
    self.icon_img:loadTexture(self.config.mult_str2[icon_index], PLIST_TYPE)
end

function stage_panel:GetLocaleInfoString( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

--设定奖励的sub_panel颜色
function stage_panel:SetColor(color, btn_color)
    self.root_node:setColor(panel_util:GetColor4B(color))
    self.get_btn:setColor(panel_util:GetColor4B(btn_color))
    for i = 1, 6 do
        self.icon_sub_panels[i]:SetColor(color)
    end
end

function stage_panel:CarnivalRewardStatus()
    self.status = carnival_logic:GetStageRewardIndex(self.config.key, self.step_index)
    if self.status == STEP_STATUS["can_take"] then
        self:SetColor(0xffffff, 0xffffff)

    elseif self.status == STEP_STATUS["cant_take"] then
        self:SetColor(0xffffff, 0x7f7f7f)

    elseif self.status == STEP_STATUS["already_taken"] then
        self:SetColor(0x7f7f7f, 0x7f7f7f)
        self.get_btn:setVisible(false)
    end
end

--重置奖励的sub_panel
function stage_panel:ReLoadIconSubPanel(reward_list)
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

function stage_panel:RegisterWidgetEvent()
    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.config.carnival_type == CARNIVAL_TYPE["single_payment"] and self.reward_mark < 0 and self.config.need_type == constants.ACHIEVEMENT_TYPE["all_payment"] then
                --单笔充值直接进入购买流程
                for k, product in ipairs(payment_logic.products_list) do
                    if product.price == self.need_value then
                        payment_logic:TryBuy(product)
                        break
                    end
                end

            else
                local can_take = carnival_logic:TakeReward(self.config, self.step_index)
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
       end
    end)
end

return stage_panel
