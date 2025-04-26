local config_manager = require "logic.config_manager"
local carnival_logic = require "logic.carnival"

local graphic = require "logic.graphic"
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local icon_template = require "ui.icon_panel"

local CARNIVAL_TYPE = constants.CARNIVAL_TYPE
local REWARD_TYPE = constants.REWARD_TYPE
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

--展示活动, 收集道具，首充奖励等使用这个sub_panel
local display_panel = panel_prototype.New()
display_panel.__index = display_panel

function display_panel.New()
    return setmetatable({}, display_panel)
end

function display_panel.InitMeta(root_node)
    display_panel.meta_root_node = root_node
end

function display_panel:Init(root_node)
    self.root_node = self.meta_root_node:clone()

    self.name_text = self.root_node:getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")
    self.num_text = self.root_node:getChildByName("num")

    self.tip_img = self.root_node:getChildByName("tip_bg")
    self.tip_desc_text = self.tip_img:getChildByName("desc")
    self.exchange_btn = self.root_node:getChildByName("exchange_btn")
    self.exchange_icon_img = self.exchange_btn:getChildByName("icon")
    self.exchange_need_value_text = self.exchange_btn:getChildByName("value")

    self.icon_without_panel =  icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_without_panel:Init(self.root_node)
    self.icon_without_panel.root_node:setPosition(77, 81)

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)
    self.exchange_btn:setCascadeColorEnabled(true)
    self:RegisterWidgetEvent()
end

function display_panel:Show(config, index)
    self.config = config or self.config
    self.index = index or self.index

    self.exchange_btn:setVisible(false)
    self.tip_img:setVisible(false)
    self.num_text:setVisible(false)
    self:SetColor(true)

    --todo 再优化, 区分collect_item 和 carnival_token
    local source, template_id, num, show_text_bg = 0, 0, 0, true
    if self.config.carnival_type == constants.CARNIVAL_TYPE["collect_item"] then
        if self.config.need_type and self.config.need_type == constants["REWARD_TYPE"]["carnival_token"] then
            local single_reward = self.config.reward_list[self.index].reward_info[1]
            template_id = single_reward.param1
            source = single_reward.reward_type
            self.exchange_btn:setVisible(true)
            self.exchange_need_value_text:setString(self.config.collect_step[self.index].step_info[1])
            self.exchange_icon_img:loadTexture(config_manager.carnival_token_config[self.config.mult_num1[1]].icon, PLIST_TYPE)
            local status = carnival_logic:GetStageRewardIndex(self.config.key, self.index)
            self:SetColor(status ~= STEP_STATUS["already_taken"])

        else
            --直接显示道具的名称和数量
            self.num_text:setVisible(true)
            local need_value = self.config["collect_step"][1]["step_info"][self.index]
            local cur_value, reward_mark = carnival_logic:GetValueAndReward(self.config, self.index, 1)
            self.num_text:setString(cur_value .. "/" .. need_value)

            local color = reward_mark > 0 and  cur_value >= need_value or false
            self:SetColor(color)
            template_id = self.config.mult_num1[self.index]
            source = self.config.need_type

        end
        show_text_bg = false

    elseif self.config.carnival_type == constants.CARNIVAL_TYPE["first_payment"] then
        local single_reward = self.config.reward_list[1].reward_info[self.index]
        source = single_reward.reward_type
        template_id = single_reward.param1
        num = single_reward.param2

        self:SetColor(not carnival_logic:GetFirstPaymentMark())
        self.tip_img:setVisible(true)

    elseif self.config.carnival_type == 0 then
        --永恒神殿
        source = REWARD_TYPE["mercenary"]
        template_id = self.config.mult_num1[self.index]
    end

    local conf = self.icon_without_panel:Show(source, template_id, num, nil, true)
    self.icon_without_panel:ShowTextBg(show_text_bg)

    self.name_text:setString(self:GetLocaleInfoString(conf, "name"))
    self.desc_text:setString(self:GetLocaleInfoString(conf, "desc"))
    self.root_node:setVisible(true)
end

function display_panel:SetColor(can_take)
    local color = can_take and 0xffffff or 0x7f7f7f
    self.root_node:setColor(panel_util:GetColor4B(color))
end

function display_panel:GetLocaleInfoString( cur_config, key )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale]
    end
    return result
end

function display_panel:RegisterWidgetEvent()
    self.exchange_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local can_take = carnival_logic:CanTakeReward(self.config, self.index)

            if not can_take then
                return
            end

            graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("confirm_take_reward_title"),
                        lang_constants:Get("confirm_take_reward_desc"),
                        lang_constants:Get("common_confirm"),
                        lang_constants:Get("common_cancel"),
            function()
                 carnival_logic:TakeReward(self.config, self.index)
            end)
        end
    end)
end

return display_panel
