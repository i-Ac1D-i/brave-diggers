local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local icon_panel = require "ui.icon_panel"

local lang_constants = require "util.language_constants"
local mine_logic = require "logic.mine"

local MSGBOX_MODE = client_constants["QUICK_STORE_MSGBOX_TYPE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]

local PLIST_TYPE = ccui.TextureResType.plistType

local STATE = {
    ["can_reward"] = 1, --可以领取
    ["rewarding"] = 2,  --领取中
    ["rewarded"] = 3,   --领取过了
}

local reward_mine_msgbox = panel_prototype.New(true)
function reward_mine_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/reward_mine_msgbox.csb")
    --关闭按钮
    self.close_btn = self.root_node:getChildByName("close_btn")

    --确定按钮
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.reward_bg = self.root_node:getChildByName("item_bg")
    self.be_robbed_bg = self.root_node:getChildByName("item_bg2")

    self.desc_text = self.root_node:getChildByName("Text_2")

    self.title_text = self.root_node:getChildByName("title")

    self.reward_sub_panels = {}
    self.reward_config = {}
    self.reward_num = 0

    self.robbed_reward_config = {}
    self.robbed_reward_num = 0
    self.robbed_sub_panels = {}   --被抢劫的资源

    self.mine_index = 1

    self:RegisterEvent()
    self:RegisterWidgetEvent()
    
end

function reward_mine_msgbox:Show(reward_config, reward_num, mine_index) 
    self.root_node:setVisible(true)
    self.mine_index = mine_index or self.mine_index
        
    --删除旧的icon
    --获得的奖励iconf
    for k,cost_sub_panel in ipairs(self.reward_sub_panels) do
        cost_sub_panel.root_node:removeFromParent()
    end
    self.reward_sub_panels = {}
    --被掠夺的奖励列表
    for k,robbed_sub_panel in pairs(self.robbed_sub_panels) do
        robbed_sub_panel.root_node:removeFromParent()
    end
    self.robbed_sub_panels = {} 

    if reward_config and reward_num then
        self.reward_config = reward_config
        self.reward_num = reward_num
        self.reward_state = STATE["can_reward"]
        self.robbed_reward_config = {}
        self.robbed_reward_num = 0
    end

    self.be_robbed_bg:setVisible(false)

    self.confirm_btn:setTitleText(lang_constants:Get("mine_reward_btn_text"))   --点击收取按钮文字

    if self.reward_state ~= STATE["rewarded"] then
        self.title_text:setString(lang_constants:Get("mine_expected_reward_title"))   --title文字

        local status = mine_logic:GetMinesStatus(self.mine_index)
        if status == client_constants.MINE_STATE.mining then
           self.desc_text:setString(lang_constants:Get("mine_can_reward_desc")) 
        else
            self.desc_text:setString(string.format(lang_constants:Get("mine_can_and_full_reward_desc"))) 
        end
    else
        self.title_text:setString(lang_constants:Get("mine_reward_title")) --实际获得title文字
        self.confirm_btn:setTitleText(lang_constants:Get("mine_rewarded_btn_text"))   --确定按钮文字
        --被掠夺的资源
        if self.robbed_reward_num > 0 then
            self.desc_text:setString(lang_constants:Get("mine_robbed_reward_desc")) 
            for i = 1, self.robbed_reward_num do
                if self.robbed_sub_panels[i] == nil then
                    local sub_panel = icon_panel.New()
                    sub_panel:Init(self.be_robbed_bg)
                    self.robbed_sub_panels[i] = sub_panel
                end
            end
            self.be_robbed_bg:setVisible(true)
            panel_util:LoadCostResourceInfo(self.robbed_reward_config, self.robbed_sub_panels, self.be_robbed_bg:getContentSize().height*2/5 , self.robbed_reward_num, self.be_robbed_bg:getContentSize().width/2, false) 
        else
            self.desc_text:setString(lang_constants:Get("mine_no_robbed_reward_desc")) 
        end
    end

    for i = 1, self.reward_num do
        if self.reward_sub_panels[i] == nil then
            local sub_panel = icon_panel.New()
            sub_panel:Init(self.reward_bg)
            self.reward_sub_panels[i] = sub_panel
        end
    end

    panel_util:LoadCostResourceInfo(self.reward_config, self.reward_sub_panels, self.reward_bg:getContentSize().height*2/5, self.reward_num, self.reward_bg:getContentSize().width/2, false) 

end

function reward_mine_msgbox:Update(elapsed_time)

end

function reward_mine_msgbox:RegisterEvent()
    ----收取奖励成功成功刷新界面
    graphic:RegisterEvent("mine_receive_reward_success", function(current_reward_list, robbed_reward_list, mine_index)
        if not self.root_node:isVisible() then
            return
        end

        self.reward_state = STATE["rewarded"]
        self.reward_config = {}
        self.reward_num = 0

        if current_reward_list then
            table.sort(current_reward_list, function (a, b)
                return a.resource_id > b.resource_id
            end)
            for k,reward in pairs(current_reward_list) do
                self.reward_num = self.reward_num + 1
                self.reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward.resource_num
            end
        end

        self.robbed_reward_config = {}
        self.robbed_reward_num = 0
        if robbed_reward_list then
            table.sort(current_reward_list, function (a, b)
                return a.resource_id > b.resource_id
            end)
            for k,reward in pairs(robbed_reward_list) do
                self.robbed_reward_num = self.robbed_reward_num + 1
                self.robbed_reward_config[constants["RESOURCE_TYPE_NAME"][reward.resource_id]] = reward.resource_num
            end
        end
        self:Show()

    end)
end

function reward_mine_msgbox:RegisterWidgetEvent()

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --领取奖励按钮
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.reward_state == STATE["can_reward"] then
                mine_logic:MineReceiveReward(self.mine_index)
                self.reward_state = STATE["rewarding"]
            elseif self.reward_state == STATE["rewarding"] then
                graphic:DispatchEvent("show_prompt_panel", "mine_rewarding_tips_desc")
            elseif self.reward_state == STATE["rewarded"] then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            end
        end
    end)

end

return reward_mine_msgbox
