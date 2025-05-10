local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local icon_panel = require "ui.icon_panel"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"

local PLIST_TYPE = ccui.TextureResType.plistType

local resource_recycle_bouns_msgbox = panel_prototype.New(true)
function resource_recycle_bouns_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/resource_recycle_bouns_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("confirm_btn") 
    

    self.have_reward_node = self.root_node:getChildByName("Node_3") 

    self.desc_node = self.root_node:getChildByName("Node_3_0")

    self.title_name = self.root_node:getChildByName("title_name")

    self.reward_bg = self.have_reward_node:getChildByName("scrollview")

    self.reward_sub_panels = {}
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--显示界面
function resource_recycle_bouns_msgbox:Show(temperature_up, process_up, reward_list, random_id)
    self.root_node:setVisible(true)
    self.reward_list = reward_list
    self.random_id = random_id
    self.temperature_up = temperature_up
    self.process_up = process_up
    if reward_list then
        self.have_reward_node:setVisible(true)
        self.desc_node:setVisible(false)
        self:LoadReward(reward_list)
    else
        self.have_reward_node:setVisible(false)
        self.desc_node:setVisible(true)
    end
    self:ShowTitleAndDesc()
end

--设置title
function resource_recycle_bouns_msgbox:ShowTitleAndDesc()
    local show_node = self.desc_node
    if self.reward_list then
        show_node = self.have_reward_node
    end

    --过热度上升
    show_node:getChildByName("text"):getChildByName("Text_13_0_0_0"):setString(self.temperature_up / 100 .."%")
    show_node:getChildByName("text"):getChildByName("Text_13_0_0_0_0"):setString(self.process_up/100)

    local conf = config_manager.resource_recycle_random_name[tonumber(self.random_id)]
    if conf then
        show_node:getChildByName("text"):getChildByName("Text_13"):setString(conf.desc)
        self.title_name:setString(conf.title)
    end
end

--加载奖励
function resource_recycle_bouns_msgbox:LoadReward(reward_list)
    
    --删除之前的奖励
    for k,cost_sub_panel in ipairs(self.reward_sub_panels) do
        cost_sub_panel.root_node:removeFromParent()
    end
    self.reward_sub_panels = {}

    local reward_config = {}
    local reward_num = 0
    local width = 0
    for k,reward in pairs(reward_list) do
        reward_num = reward_num + 1
        if self.reward_sub_panels[reward_num] == nil then
            local reward_sub_panel = icon_panel.New()
            reward_sub_panel:Init(self.reward_bg)
            self.reward_sub_panels[reward_num] = reward_sub_panel
        end
        self.reward_sub_panels[reward_num]:Show(reward.reward_type,reward.param1,reward.param2)
        width = width + self.reward_sub_panels[reward_num].root_node:getContentSize().width + 4
        self.reward_sub_panels[reward_num]:SetPosition((reward_num - 0.5) * (self.reward_sub_panels[reward_num].root_node:getContentSize().width + 4), self.reward_bg:getContentSize().height/2)
    end
    self.reward_bg:setInnerContainerSize(cc.size(width, self.reward_bg:getContentSize().height))

end

--Update定时器
function resource_recycle_bouns_msgbox:Update(elapsed_time)

end

function resource_recycle_bouns_msgbox:RegisterEvent()

    --开始开采
    -- graphic:RegisterEvent("mine_start_success", function(mine_index)
    --     if not self.root_node:isVisible() then
    --         return
    --     end
    --     local mine_info_config = mine_logic.mine_info_list
    --     if mine_info_config then
    --         mine_nodes[mine_index]:Show(mine_index, mine_info_config[mine_index])
    --     end
    -- end)

    -- --购买次数成功
    -- graphic:RegisterEvent("mine_buy_times_success", function()
    --     if not self.root_node:isVisible() then
    --         return
    --     end

    --     self:RefreshTimes()
    -- end)
    
end

function resource_recycle_bouns_msgbox:RegisterWidgetEvent()

    -- --购买掠夺次数
    -- self.add_plunder_count_btn:addTouchEventListener(function(widget, event_type)
    --     if event_type == ccui.TouchEventType.ended then
    --         audio_manager:PlayEffect("click")
    --         local mode = client_constants["BATCH_MSGBOX_MODE"]["mine_buy_rob_times"]
    --         graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
    --     end
    -- end)

    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

return resource_recycle_bouns_msgbox

