local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local carnival_logic = require "logic.carnival"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local time_logic = require "logic.time"

local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local CARNIVAL_REWARD_PANEL_TYPE = client_constants["CARNIVAL_REWARD_PANEL_TYPE"]

local PLIST_TYPE = ccui.TextureResType.plistType
local STEP_STATUS = client_constants["CARNIVAL_STEP_STATUS"]

--投票活动
local vote_sub_panel = panel_prototype.New()
vote_sub_panel.__index = vote_sub_panel

function vote_sub_panel.New()
    return setmetatable({}, vote_sub_panel)
end

function vote_sub_panel:Init(root_node)
    self.root_node = root_node
    local t_node = self.root_node:getChildByName("template1")
    self.value_text = t_node:getChildByName("value")
    self.get_img = t_node:getChildByName("get")
    self.bg_img = t_node:getChildByName("bg")

    local begin_x, begin_y, interavl_x = 170, 54, 80
    self.icon_panels = {}
    for i = 1, 5 do
        local sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text"])
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i -1) * interavl_x, begin_y)
        sub_panel.root_node:setLocalZOrder(50 + i)
        self.icon_panels[i] = sub_panel
    end

    self.get_img:setLocalZOrder(100)

end

function vote_sub_panel:Show(config, index)
    -- body
    local reward_list = config.reward_list[index].reward_info

    local need_num = config.mult_num2[index]

    self.value_text:setString(tostring(need_num))

    for i = 1, 5 do
        local sub_panel = self.icon_panels[i]
        if i <= #reward_list then
            local re = reward_list[i]
            sub_panel:Show(re.reward_type, re.param1, re.param2,  false, false)
        else
            sub_panel.root_node:setVisible(false)
        end
    end

    local vote_info = carnival_logic:GetCarnivalInfo(config.key)
    self.get_img:setVisible(vote_info.cur_value_multi[2] >= need_num)

    self.root_node:setVisible(true)
end

--收集活动
local collect_sub_panel = panel_prototype.New()
collect_sub_panel.__index = collect_sub_panel

function collect_sub_panel.New()
    return setmetatable({}, collect_sub_panel)
end

function collect_sub_panel:Init(root_node)
    self.root_node = root_node
    self.name_text = self.root_node:getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")
    self.icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_panel:Init(self.root_node)
    self.icon_panel.root_node:setPosition(77, 81)
end

function collect_sub_panel:Show(reward_info)
    local conf = self.icon_panel:Show(reward_info.reward_type, reward_info.param1, reward_info.param2, nil, true)
    self.name_text:setString(carnival_logic:GetLocaleInfoString(conf, "name"))
    self.desc_text:setString(carnival_logic:GetLocaleInfoString(conf, "desc"))
    self.root_node:setVisible(true)
end

--跟所有玩家相关的活动
local rank_sub_panel = panel_prototype.New()
rank_sub_panel.__index = rank_sub_panel

function rank_sub_panel.New()
    return setmetatable({}, rank_sub_panel)
end

function rank_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.index = index
    self.name_text = self.root_node:getChildByName("name")
    self.get_btn = self.root_node:getChildByName("get_btn")

    self.condition_text = self.root_node:getChildByName("condition")
    self.tip_bg_img = self.root_node:getChildByName("tip_bg")
    self.tip_desc_text = self.tip_bg_img:getChildByName("desc")

    self.name_text = self.root_node:getChildByName("name")
    self.desc_text = self.root_node:getChildByName("desc")

    self.icon_sub_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
    self.icon_sub_panel:Init(self.root_node)
    self.icon_sub_panel.root_node:setPosition(77, 81)
    self.icon_sub_panel.root_node:setLocalZOrder(100)
    self.tip_bg_img:setLocalZOrder(101)

    self:RegisterWidgetEvent()
end

function rank_sub_panel:SetGetBtn(color, text)
    self.get_btn:setTitleText(lang_constants:Get(text))
    self.get_btn:setColor(panel_util:GetColor4B(color))
end

function rank_sub_panel:Show(config, index)
    self.index = index
    self.config = config
    local reward_info = config.reward_list[self.index].reward_info[1]
    self.tip_desc_text:setString(string.format(lang_constants:Get("union_carnival_reward_rank"), index))

    local conf = self.icon_sub_panel:Show(reward_info.reward_type, reward_info.param1, reward_info.param2,  false, true)
    self.name_text:setString(carnival_logic:GetLocaleInfoString(conf, "name"))
    self.desc_text:setString(carnival_logic:GetLocaleInfoString(conf, "desc"))

    local cur_time = time_logic:Now()
    if cur_time > config.reward_time then
        local template_id = config.order_ids[self.index] or self.config.mult_num1[self.index]

        local template_index = carnival_logic:GetMercenaryIdInitIndex(self.config, template_id)

        self.condition_text:setString(string.format(lang_constants:Get("union_carnival_reward"), config_manager.mercenary_config[template_id].name))
        self.condition_text:setVisible(true)

        local cur_value, reward_mark = carnival_logic:GetValueAndReward(config, template_index, self.index)
        self.can_take_reward = true

        if cur_value == 0 then
            self.can_take_reward = false
            self:SetGetBtn(0x7f7f7f, "not_mercenary")

        elseif reward_mark > 0 then
            self:SetGetBtn(0xffffff, "campaign_reward_rank_tips")
        else
            self:SetGetBtn(0x7f7f7f, "campaign_reward_rank_convert")
        end
    else
        self.condition_text:setVisible(false)
        self.get_btn:setTitleText(lang_constants:Get("campaign_reward_date"))
    end
    self.root_node:setVisible(true)
end

function rank_sub_panel:RegisterWidgetEvent()
    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.can_take_reward then
                carnival_logic:TakeReward(self.config, self.index, true)
            end
        end
    end)
end

--活动奖励面板
local extra_reward_msgbox = panel_prototype.New(true)
function extra_reward_msgbox:Init(root_node)
    self.root_node =  cc.CSLoader:createNode("ui/carnival_ladder_reward_panel.csb")

    self.rank_node = self.root_node:getChildByName("ladder_reward_node")
    self.rank_desc_text = self.rank_node:getChildByName("desc")

    self.collect_node = self.root_node:getChildByName("collect_reward_node")
    self.get_collect_btn = self.collect_node:getChildByName("get_btn")

    self.time1_node = self.rank_node:getChildByName("time1")
    self.time2_node = self.rank_node:getChildByName("time2")

    self.time_text = self.time1_node:getChildByName("time_num")
    self.time_desc_text = self.time1_node:getChildByName("time_desc")
    self.time_desc2_text = self.time2_node:getChildByName("time_desc")

    self.sub_panels = {}
    for i = 1, 3 do
        self["template" .. i] = self.root_node:getChildByName("reward_template" .. i)
        self["template" .. i]:setVisible(false)
    end

    self.list_view = self.root_node:getChildByName("listview")

    self.sub_panels = {}
    self.sub_num = 0
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--创建一个子面板
function extra_reward_msgbox:CreateOnePanel(index, source)

    if source == CARNIVAL_REWARD_PANEL_TYPE["rank"] then
        sub_panel = rank_sub_panel.New()

    elseif source ==  CARNIVAL_REWARD_PANEL_TYPE["collect"] then
        sub_panel = collect_sub_panel.New()

    elseif source ==  CARNIVAL_REWARD_PANEL_TYPE["vote"] then
        sub_panel = vote_sub_panel.New()
    end

    sub_panel:Init(self["template" .. source]:clone(), index)
    self.sub_panels[source][index] = sub_panel
end

function extra_reward_msgbox:CreateSubPanels(source, num)
    if not self.sub_panels[source] then self.sub_panels[source] = {} end

    if self.source == source then
        if num == self.sub_num then
            return
        elseif num > self.sub_num then
            for i = self.sub_num + 1, num do
                self:CreateOnePanel(i, source)
                self.list_view:addChild(self.sub_panels[source][i].root_node)
            end
        else
            for i = num + 1, self.sub_num do
                self.list_view:removeChild(self.sub_panels[self.source][i].root_node, false)
            end
        end
    else
        --先将已经存在的移除掉
        for i = 1, self.sub_num do
            self.list_view:removeChild(self.sub_panels[self.source][i].root_node, false)
        end

        for i = 1, num  do
            if i > #self.sub_panels[source] then
                self:CreateOnePanel(i, source)
            end
            self.list_view:addChild(self.sub_panels[source][i].root_node)
        end
    end

    self.sub_num = num
    self.source = source

end

function extra_reward_msgbox:Show(config, step_index)
    self.config = self.config or config
    self.step_index = self.step_index or 1

    local panel_type = self.config.reward_panel_type
    self.rank_node:setVisible(panel_type == CARNIVAL_REWARD_PANEL_TYPE["rank"])
    self.collect_node:setVisible(panel_type == CARNIVAL_REWARD_PANEL_TYPE["collect"])

    if panel_type == CARNIVAL_REWARD_PANEL_TYPE["rank"] then
        local cur_time = time_logic:Now()
        self.can_reward = cur_time > self.config.reward_time
        self.time1_node:setVisible(self.can_reward)
        self.time2_node:setVisible(not self.can_reward)

        if self.can_reward then
            self.reward_duration = time_logic:GetDurationToFixedTime(self.config.end_time)
        end

        self:CreateSubPanels(panel_type, #self.config.mult_num1)

        for i = 1, #self.config.mult_num1 do
            if not self.config.order_ids then self.config.order_ids = {} end
            self.sub_panels[panel_type][i]:Show(self.config, i)
        end

    elseif panel_type == CARNIVAL_REWARD_PANEL_TYPE["collect"] then
        local reward_info = self.config.reward_list[1].reward_info
        self:CreateSubPanels(panel_type, #reward_info)

        for i = 1, #reward_info do
            self.sub_panels[panel_type][i]:Show(reward_info[i])
        end

        local status = carnival_logic:GetStageRewardIndex(self.config.key, self.step_index)
        if status == STEP_STATUS["can_take"] then
            self.get_collect_btn:setTitleText(lang_constants:Get("take_vip_reward"))
        elseif status == STEP_STATUS["cant_take"] then
            self.get_collect_btn:setTitleText(lang_constants:Get("ladder_cant_get_reward"))
        elseif status == STEP_STATUS["already_taken"] then
            self.get_collect_btn:setTitleText(lang_constants:Get("ladder_already_get_reward"))
        end

    elseif panel_type == CARNIVAL_REWARD_PANEL_TYPE["vote"] then
        self.rank_node:setVisible(true)
        self.time1_node:setVisible(true)
        self.time_desc_text:setVisible(false)

        self.time2_node:setVisible(true)
        self.time_desc2_text:setString(lang_constants:Get("carnival_vote_num_desc2"))
        local cur_value, reward_mark = carnival_logic:GetValueAndReward(self.config, 1, 1) or 0

        self.time_text:setString(tostring(carnival_logic:GetCarnivalInfo(self.config.key).cur_value_multi[2]))
        self.rank_desc_text:setString(lang_constants:Get("carnival_vote_reward_desc"))

        self:CreateSubPanels(panel_type, #self.config.reward_list)

        for i = 1, #self.config.reward_list do
            self.sub_panels[panel_type][i]:Show(self.config, i)
        end
    end

    self.root_node:setVisible(true)
end

function extra_reward_msgbox:Update(elapsed_time)
    if self.can_reward then
        self.reward_duration = self.reward_duration - elapsed_time
        self.time_text:setString(panel_util:GetTimeStr(self.reward_duration))
    end

end

function extra_reward_msgbox:RegisterWidgetEvent()
    --关闭
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
    self.get_collect_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            carnival_logic:TakeReward(self.config, self.step_index)
       end
    end)
end

function extra_reward_msgbox:RegisterEvent()

    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key, step)
        if not self.root_node:isVisible() then
            return
        end

        if self.config.key ~= key or self.step_index ~= step then
            return
        end

        self:Show()
    end)

end

return extra_reward_msgbox

