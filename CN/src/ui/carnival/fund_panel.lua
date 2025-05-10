local config_manager = require "logic.config_manager"

local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
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

local fund_panel = panel_prototype.New()
fund_panel.__index = fund_panel

function fund_panel.New()
    return setmetatable({}, fund_panel)
end

function fund_panel.InitMeta(root_node)
    fund_panel.meta_root_node = root_node
end

function fund_panel:Init()
    self.root_node = self.meta_root_node:clone()

    self.blood_diamond_text = self.root_node:getChildByName("blood_num")
    self.credit_text = self.root_node:getChildByName("credit")

    self.profit_text = self.root_node:getChildByName("profit_text")
    self.invest_btn = self.root_node:getChildByName("invest_btn")

    self.desc_text = self.root_node:getChildByName("desc")

    self:RegisterWidgetEvent()
end

function fund_panel:Show(config, step_index)
    self.config = config or self.config
    self.step_index = step_index or self.step_index

    local need_credit_num = self.config.mult_num2[step_index]

    self.blood_diamond_text:setString(tostring(need_credit_num))
    self.credit_text:setString(tostring(need_credit_num))

    self.profit_text:setString(carnival_logic:GetLocaleInfoString(self.config, "mult_str1", step_index))

    local desc = self:GetDesc()
    self.desc_text:setString(desc)

    local info = carnival_logic:GetCarnivalInfo(self.config.key)
    if info.cur_value_multi[step_index] == 0 then
        self.invest_btn:setTitleText(lang_constants:Get("carnival_take_btn3"))
    else
        self.invest_btn:setTitleText(lang_constants:Get("carnival_take_btn4"))
    end

    self.root_node:setVisible(true)
end

function fund_panel:GetDesc()
    --第一天只能领取血钻
    local fund_type = self.config.mult_num1[self.step_index]

    local conf = config_manager.fund_config[fund_type]
    local first_conf = conf[1]
    local bd_num = first_conf.reward_list[1].param2

    local second_conf = conf[2]

    local nums = {}
    for i = 1, #second_conf.reward_list do
        table.insert(nums, second_conf.reward_list[i].param2)
    end

    return string.format(carnival_logic:GetLocaleInfoString(first_conf, "desc"), bd_num, conf.profit_duration-1, unpack(nums))
end

function fund_panel:RegisterWidgetEvent()
    self.invest_btn:addTouchEventListener(function(widget, event_type)
    
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local info = carnival_logic:GetCarnivalInfo(self.config.key)
            if info.cur_value_multi[self.step_index] == 0 then

                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("carnival_fund_title"), self:GetDesc(), lang_constants:Get("common_confirm"), lang_constants:Get("common_close"), function()
                    carnival_logic:TakeFundProfit(self.config.key, self.step_index)
                end)

            else
                --查看领取界面
                graphic:DispatchEvent("show_world_sub_panel", "carnival.take_profit_msgbox", self.config, self.config.mult_num1[self.step_index])
            end
        end
    end)
end

return fund_panel
