local config_manager = require "logic.config_manager"
local carnival_logic = require "logic.carnival"
local graphic = require "logic.graphic"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local icon_template = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"

local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]
local RANK_POSITION_PROMPT =
{
    lang_constants:Get("union_carnival_rank_1"),
    lang_constants:Get("union_carnival_rank_2"),
    lang_constants:Get("union_carnival_rank_3"),
}

local CARNIVAL_TYPE = constants.CARNIVAL_TYPE
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"


--排名活动（比如，某几个佣兵的全服数量）
local rank_panel = panel_prototype.New()
rank_panel.__index = rank_panel

function rank_panel.New()
    return setmetatable({}, rank_panel)
end

function rank_panel.InitMeta(root_node)
    rank_panel.meta_root_node = root_node
end

function rank_panel:Init()
    self.root_node = self.meta_root_node:clone()

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    self.name_text = self.root_node:getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")

    self.icon_without_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_without_panel:Init(self.root_node)
    self.icon_without_panel:SetPosition(78, 82)
    self.icon_without_panel.root_node:setLocalZOrder(100)

    self.tip_bg_img = self.root_node:getChildByName("tip_bg")
    self.tip_bg_img:setLocalZOrder(101)

    self.tip_icon_img = self.tip_bg_img:getChildByName("icon")
    self.tip_desc_text = self.tip_bg_img:getChildByName("desc")

    self.mine_num_text = self.root_node:getChildByName("num")
    self.icon_img = self.root_node:getChildByName("ladder_icon")
    self.cur_num_text = self.icon_img:getChildByName("value")

    self.vote_btn = self.root_node:getChildByName("btn")
    self.vote_icon_img = self.vote_btn:getChildByName("token_icon")
    self.vote_text = self.vote_icon_img:getChildByName("value")

    self.root_node:getChildByName("desc"):setVisible(false)

    self:RegisterWidgetEvent()
end

function rank_panel:Show(config, index)
    self.index = index or self.index
    self.config = config or self.config

    if self.config.carnival_type == CARNIVAL_TYPE["vote"] then
        self:LoadVote(self.index)
    else
        self:Load(self.config.mult_num1[self.index], self.index)
    end
    self.root_node:setVisible(true)
end

function rank_panel:Load(template_id, index)
    self.vote_btn:setVisible(false)

    local conf = self.icon_without_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, true)
    self.name_text:setString(self:GetLocaleInfoString(conf, "name"))

    local template_index = carnival_logic:GetMercenaryIdInitIndex(self.config, template_id)

    local cur_value = carnival_logic:GetValueAndReward(self.config, template_index, 1)
    --self.cur_num_text:setString(string.format(self.config.mult_str1[1], tostring(cur_value)))

    if cur_value == 0 then
        self.mine_num_text:setString(lang_constants:Get("destiny_weapon_not_get"))
        self.mine_num_text:setColor(panel_util:GetColor4B(0x97823C))
    else
        self.mine_num_text:setString(lang_constants:Get("destiny_weapon_already_get"))
        self.mine_num_text:setColor(panel_util:GetColor4B(0xFFDA5E))
    end

    self.tip_bg_img:setVisible(false)

    if time_logic:Now() > self.config.reward_time then
        self.tip_bg_img:setVisible(true)
        local is_no1 = index == 1
        self.tip_icon_img:setVisible(is_no1)
        self.tip_desc_text:setVisible(not is_no1)
        self.tip_desc_text:setString(RANK_POSITION_PROMPT[index])
    end
end

--佣兵投票活动
function rank_panel:LoadVote(index)
    --排名
    local info = carnival_logic:GetCarnivalInfo(self.config.key)
    local vote_rank_info = info.rank[index]

    self.vote_index = vote_rank_info.vote_index

    local template_id = self.config.mult_num1[vote_rank_info.vote_index]

    local conf = self.icon_without_panel:Show(constants.REWARD_TYPE["mercenary"], template_id, nil, nil, true)
    self.name_text:setString(self:GetLocaleInfoString(conf, "name"))
    self.vote_btn:setVisible(true)

    self.icon_img:setVisible(false)
    self.desc_text:setVisible(true)

    self.tip_bg_img:setVisible(true)
    self.tip_bg_img:getChildByName("icon"):setVisible(false)

    local token_conf = config_manager.carnival_token_config[self.config.extra_num1]

    if info.cur_value_multi[3] == 0 then
        --购买佣兵
        self.desc_text:setString(lang_constants:Get("carnival_vote_desc1"))
        self.vote_text:setString(tostring(self.config.extra_num2))

        self.vote_icon_img:setVisible(true)
        self.vote_icon_img:loadTexture(token_conf.icon, PLIST_TYPE)

        self.mine_num_text:setVisible(false)
        self.tip_desc_text:setString(lang_constants:Get("carnival_vote_not_rank"))

    else
        --投票
        if info.cur_value_multi[3] == vote_rank_info.vote_index then
            self.vote_btn:setVisible(true)
            self.mine_num_text:setString(lang_constants:Get("carnival_vote_status1"))
            self.root_node:setColor(panel_util:GetColor4B(0xffffff))
        else
            self.vote_btn:setVisible(false)
            self.mine_num_text:setString(lang_constants:Get("carnival_vote_status2"))
            self.root_node:setColor(panel_util:GetColor4B(0x7f7f7f))
        end

        self.mine_num_text:setVisible(true)
        local quality_str = lang_constants:Get("mercenary_quality" .. (7-index))

        self.desc_text:setString(string.format(lang_constants:Get("carnival_vote_desc2"), self:GetLocaleInfoString(token_conf, "name"), vote_rank_info.votes, quality_str))

        if info.cur_value_multi[1] == 0 then
            self.vote_btn:setTitleText(lang_constants:Get("carnival_vote_not_enough"))
        else
            self.vote_btn:setTitleText(lang_constants:Get("carnival_vote_btn"))
        end

        self.vote_icon_img:setVisible(false)

        --名次
        local is_no1 = index == 1
        self.tip_icon_img:setVisible(is_no1)
        self.tip_desc_text:setVisible(not is_no1)
        self.tip_desc_text:setString(RANK_POSITION_PROMPT[index])

    end

    self.vote_info = info.cur_value_multi
    self.token_conf = token_conf
end

function rank_panel:GetLocaleInfoString( cur_config, key )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale]
    end
    return result
end

function rank_panel:RegisterWidgetEvent()
    self.vote_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.began then
            audio_manager:PlayEffect("click")
            local pos = widget:getTouchBeganPosition()
            self.show_floating_panel = true

            if self.vote_info[3] == 0 then
                --1是拥有的票数
                if self.vote_info[1] < self.config.extra_num2 then
                    graphic:DispatchEvent("show_prompt_panel", "carnival_vote_not_enough")
                    graphic:DispatchEvent("show_floating_panel", self.token_conf.name, self.token_conf.desc, pos.x, pos.y)

                else
                    self.show_floating_panel = false
                    -- 确认兑换提示
                    graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("carnival_vote_title"),
                                self.config.mult_str1[1],
                                lang_constants:Get("common_confirm"),
                                lang_constants:Get("common_cancel"),
                    function()
                         carnival_logic:VoteCarnival(self.config.key, self.vote_index)
                    end)
                    return
                end

            elseif self.vote_info[1] > 0 then
                self.show_floating_panel = false
                carnival_logic:VoteCarnival(self.config.key, self.vote_index)
            else
                --floating
                graphic:DispatchEvent("show_floating_panel", self.token_conf.name, self.token_conf.desc, pos.x, pos.y)
            end
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            if self.show_floating_panel then
                self.show_floating_panel = false
                graphic:DispatchEvent("hide_floating_panel")
            end
        end
    end)
end

return rank_panel
