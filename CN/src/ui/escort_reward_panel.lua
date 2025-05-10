local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local reuse_scrollview = require "widget.reuse_scrollview"
local user_logic = require "logic.user"
local escort_logic = require "logic.escort"

local PLIST_TYPE = ccui.TextureResType.plistType
local SUB_PANEL_HEIGHT = 60
local FIRST_SUB_PANEL_OFFSET = -10
local MAX_SUB_PANEL_NUM = 3

local robber_sub_panel = panel_prototype.New()
robber_sub_panel.__index = robber_sub_panel

function robber_sub_panel.New()
    local t = {}
    return setmetatable(t, robber_sub_panel)
end

function robber_sub_panel:Init(root_node)
    self.root_node = root_node

    self.desc_text = self.root_node
end

function robber_sub_panel:Show(index, robber_info)
    self.robber_info = robber_info

    if self.robber_info then
        --被拦截，根据是否拦截成功显示不同的字符串
        if self.robber_info.result == constants["ROB_RESULT"]["SUCCESS"] then
            local tramcar_id = escort_logic:GetEscortInfo().tramcar_id

            local desc_str = ""
            local tramcar_conf = escort_logic:GetTramcarList()[tramcar_id]
            if tramcar_conf and tramcar_conf.rewards then

                for index,reward in ipairs(tramcar_conf.rewards) do
                    local template_id = reward.param1
                    local num = reward.param2
                    num = math.ceil(num * constants["ROB_REWARD_PERCENT"] / 100)

                    local resource_conf = config_manager.resource_config[template_id]
                    if resource_conf then
                        desc_str = desc_str .. (index == 1 and "" or ",") .. resource_conf.name .. "X" .. num
                    end
                end
            end

            self.desc_text:setString(string.format(lang_constants:Get("be_robbed_success"), robber_info.leader_name ,desc_str))
        elseif self.robber_info.result == constants["ROB_RESULT"]["FAILURE"] then
            self.desc_text:setString(string.format(lang_constants:Get("be_robbed_failure"), robber_info.leader_name))
        end
    elseif index == 1 then
        --没有被拦截过
        self.desc_text:setString(lang_constants:Get("had_not_been_robbed"))
    end
    
    self.root_node:setVisible(true)
end


local escort_reward_panel = panel_prototype.New(true)
function escort_reward_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/tramcar_rewards_msgbox.csb")

    self.reward_node = self.root_node:getChildByName("reward_node")

    self.scroll_view = self.root_node:getChildByName("ScrollView_1")
    self.template = self.scroll_view:getChildByName("Text_02")
    self.template:setVisible(false)

    self.receive_btn = self.root_node:getChildByName("alipay_btn")

    self.sub_panel_num = 0
    self.robber_sub_panels = {}
    self.be_robbed_list = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.robber_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.be_robbed_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            print(index)
            sub_panel:Show(index, self.parent_panel.be_robbed_list[index])
        end
    )

    self:RegisterWidgetEvent()
end

function escort_reward_panel:CreateSubPanels()
    --如果没有被拦截过，需要显示一行对应的文本
    if #self.be_robbed_list == 0 then
        self.be_robbed_num = 1
    else
        self.be_robbed_num = #self.be_robbed_list
    end

    local num = math.min(MAX_SUB_PANEL_NUM, self.be_robbed_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = robber_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.robber_sub_panels[i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

function escort_reward_panel:Show()
    local escort_info = escort_logic:GetEscortInfo()

    self.be_robbed_list = escort_logic:GetCurBeRobbedList(escort_info.escort_beg_time, escort_logic:GetBeRobbedList())

    self:CreateSubPanels()

    local height = math.max(self.be_robbed_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    for i = 1, self.sub_panel_num do
        local sub_panel = self.robber_sub_panels[i]

        sub_panel:Show(i, self.be_robbed_list[i])
        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
    end

    self.reuse_scrollview:Show(height, 0)

    self:ShowRewards()
    
    self.root_node:setVisible(true)
end

--显示获得的奖励
function escort_reward_panel:ShowRewards()
    self.reward_node:removeAllChildren()
    
    local escort_info = escort_logic:GetEscortInfo()
    local tramcar_id = escort_info.tramcar_id

    --被成功拦截的次数
    local be_robbed_success_num = escort_logic:GetBeRobbedSuccessNum(self.be_robbed_list)

    local tramcar_conf = escort_logic:GetTramcarList()[tramcar_id]

    --奖励列表
    local reward_list = {}
    if tramcar_conf and tramcar_conf.rewards then

        --每一项奖励都扣除被成功拦截的损失
        for index,reward in ipairs(tramcar_conf.rewards) do
            local template_id = reward.param1
            local num = reward.param2
            num = num - math.ceil(num * constants["ROB_REWARD_PERCENT"] / 100) * be_robbed_success_num

            local resource_conf = config_manager.resource_config[template_id]
            if resource_conf then
                table.insert(reward_list, {reward_type = reward.reward_type, template_id = template_id, num = num})
            end
        end
    end

    --根据不懂数量的奖励居中排列显示
    local reward_num = #reward_list
    local beg_pos_x = 0 - (reward_num - 1) * 50
    for index,reward in ipairs(reward_list) do
        local icon_panel = icon_template.New(nil, client_constants["ICON_TEMPLATE_MODE"]["with_text2"])
        icon_panel:Init(self.reward_node, false)
        icon_panel:Show(reward.reward_type, reward.template_id, reward.num, false, true)
        icon_panel:SetPosition(beg_pos_x + (index - 1) * 100 , 0)
        icon_panel.root_node:setScale(0.8)
    end
end

function escort_reward_panel:RegisterWidgetEvent()
    --获取奖励
    self.receive_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            escort_logic:ReceiveEscortReward()
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return escort_reward_panel

