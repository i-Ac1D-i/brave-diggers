local config_manager = require "logic.config_manager"

local carnival_logic = require "logic.carnival"
local user_logic = require "logic.user"
local payment_logic = require "logic.payment"
local adveture_logic = require "logic.adventure"

local graphic = require "logic.graphic"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"

local icon_template = require "ui.icon_panel"
local MAX_TOKEN_NUM = 5 --一个活动最多可搜集的代币
local CARNIVAL_REWARD_TYPE = client_constants["CARNIVAL_REWARD_TYPE"]
local REWARD_TYPE = constants.REWARD_TYPE

--额外奖励panel
local reward_panel = panel_prototype.New()
function reward_panel:Init(root_node)
    self.root_node = root_node

    self.get_btn = self.root_node:getChildByName("get_btn") --收集活动或者代币活动领取奖励

    self.desc_text = self.root_node:getChildByName("desc")
    self.num_text = self.root_node:getChildByName("value")
    self.bg_img = self.root_node:getChildByName("bg")

    self.multi_token_desc_text = self.root_node:getChildByName("tokens")
    local begin_x, begin_y, interval_x = 530, 13, 65
    self.token_sub_panels = {}
    for i = 1, MAX_TOKEN_NUM do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.multi_token_desc_text)
        sub_panel.root_node:setPosition(begin_x - (i - 1) * interval_x, begin_y)
        sub_panel.root_node:setScale(0.85, 0.85)
        self.token_sub_panels[i] = sub_panel
    end

    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text"])
    self.icon_panel:Init(self.bg_img)
    self.icon_panel.root_node:setPosition(44, 45)

    self.vote_desc_text = self.desc_text:getChildByName("vote_desc")
    self.root_node_size = self.root_node:getContentSize()

    self:RegisterWidgetEvent()
end

--设定widget visible
function reward_panel:SetWidgetVisible(get_btn, num_text, desc, bg, multi_token)
    self.get_btn:setVisible(get_btn)
    self.num_text:setVisible(num_text)
    self.bg_img:setVisible(bg)
    self.desc_text:setVisible(desc)
    self.multi_token_desc_text:setVisible(multi_token)
end

function reward_panel:Show(config)
    self.config = config
    local cur_reward_type = self.config.reward_type
    self.height = 130
    self.desc_text:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    self.vote_desc_text:setVisible(false)

    if not cur_reward_type or cur_reward_type == 0 then
        self:SetWidgetVisible(false, false, false, false, false)
        self.height = 56
        self.icon_panel:Hide()

    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["permanent"] then
        self:SetWidgetVisible(false, false, false, false, false)
        self.icon_panel:Hide()

    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["single"] then
        self:SetWidgetVisible(true, false, true, true, false)
        local reward_info = self.config.reward_list[1].reward_info[1]
        local conf = self.icon_panel:Show(reward_info.reward_type, reward_info.param1, reward_info.param2, nil, false)
        self.desc_text:setString(self:GetLocaleInfoString(conf, "name") .. " x " .. reward_info.param2)
        self.icon_panel:ShowTextBg(false)

    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["multi"] then
        self:SetWidgetVisible(true, false, true, true, false)
        self.icon_panel:Load(REWARD_TYPE["item"], "icon/global/gift.png", 6, 0, "", "", false)
        self.icon_panel:ShowTextBg(false)
        self.desc_text:setString(self:GetLocaleInfoStringByIndex(self.config, "mult_str2", 1))

    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["token"] then
        self:SetWidgetVisible(false, true, true, true, false)

        local conf = self.icon_panel:Show(REWARD_TYPE["carnival_token"], self.config.mult_num1[1], nil, nil, false)
        local json = require "util.json"
        print("WLM  ",json:encode(conf))
        self.desc_text:setString(string.format(lang_constants:Get("carnival_item"), self:GetLocaleInfoString(conf, "name")))
        local cur_value = carnival_logic:GetValueAndReward(self.config)
        self.num_text:setString(string.format(lang_constants:Get("soul_stone_num"), cur_value))
        self.icon_panel:ShowTextBg(false)

    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["multi_token"] then
        self:SetWidgetVisible(false, false, false, true, true)
        self.icon_panel:Hide()

        for i = 1, MAX_TOKEN_NUM do
            local sub_panel = self.token_sub_panels[i]
            local cur_value = carnival_logic:GetValueAndReward(self.config, i, i)
            if i <= #self.config.mult_num1 then
                sub_panel:Show(REWARD_TYPE["carnival_token"], self.config.mult_num1[i], cur_value, false, false)
            else
                sub_panel.root_node:setVisible(false)
            end
        end
    elseif cur_reward_type == CARNIVAL_REWARD_TYPE["vote"] then
        self:SetWidgetVisible(true, false, true, true, false)

        local cur_value = carnival_logic:GetValueAndReward(self.config, 1, 1) or 0
        local conf = self.icon_panel:Show(REWARD_TYPE["carnival_token"], self.config.extra_num1, cur_value, false, false)

        self.desc_text:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        self.desc_text:setString(self:GetLocaleInfoString(conf, "name") .. "x" .. cur_value)
        self.vote_desc_text:setVisible(true)

        local info = carnival_logic:GetCarnivalInfo(self.config.key)
        self.vote_desc_text:setString(string.format(lang_constants:Get("carnival_vote_num_desc"), self:GetLocaleInfoStringByIndex(info, "cur_value_multi", 2), self:GetLocaleInfoString(conf, "name")))
        self.get_btn:setTitleText(lang_constants:Get("carnival_vote_btn_reward"))
    end

    self.root_node:setContentSize(self.root_node_size.width, self.height)
    self.config = config
    self.root_node:setVisible(true)
end

function reward_panel:GetLocaleInfoStringByIndex( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

function reward_panel:GetLocaleInfoString( cur_config, key )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale]
    end
    return result
end

function reward_panel:RegisterWidgetEvent()
    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.config.reward_panel_type ~= 0 then
                graphic:DispatchEvent("show_world_sub_panel", "carnival.extra_reward_msgbox", self.config)
            else
                carnival_logic:TakeReward(self.config, 1)
            end
        end
    end)
end

return reward_panel
