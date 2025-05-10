local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"
local troop_logic = require "logic.troop"
local mine_logic = require "logic.mine"
local reuse_scrollview = require "widget.reuse_scrollview"
local json = require "util.json"

local PLIST_TYPE = ccui.TextureResType.plistType
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]

local SUB_PANEL_HEIGHT = 114
local FIRST_SUB_PANEL_OFFSET = -62
local MAX_SUB_PANEL_NUM = 8

--战报每条信息
local mine_report_sub_panel = panel_prototype.New()
mine_report_sub_panel.__index = mine_report_sub_panel

function mine_report_sub_panel.New()
    local t = {}
    return setmetatable(t, mine_report_sub_panel)
end

function mine_report_sub_panel:Init(root_node)
    self.root_node = root_node
    self.text01 = self.root_node:getChildByName("text01")
    self.text02 = self.root_node:getChildByName("text02")
    self.name = self.root_node:getChildByName("name")
    self.revenge_btn = self.root_node:getChildByName("btn")
    self.gift_img = self.root_node:getChildByName("gift")
    self.shadow_img = self.root_node:getChildByName("Image_41")
    
    self.config = nil

    self.revenge_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.config ~= nil then
                if self.config.status ~= 1 then
                    if self.config.ext_data then
                        local data = json:decode(self.config.ext_data)
                        if data and data.rob_user_id then
                            mine_logic:QueryMineOtherState(data.rob_user_id, self.config.id)
                        end
                    end
                else
                    graphic:DispatchEvent("show_prompt_panel", "mine_has_revenged_tips")
                end
            end
        end
    end)

    self.gift_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.config ~= nil then
                if self.config.status ~= 1 then
                    mine_logic:MinReceiveAdditionalReward(self.config.id)
                else
                    graphic:DispatchEvent("show_prompt_panel", "mine_has_reward_tips")
                end
            end
        end
    end)

end

function mine_report_sub_panel:Show(reward_config)
    self.root_node:setVisible(true)
    
    self:HideAllWidget()
    self.config = reward_config
    if reward_config.report_type == client_constants["ReportType"].start_mine then
        -- print("开采战报")
        self.text02:setVisible(true)
        self.text02:setString(string.format(lang_constants:Get("mine_report_start_mine_desc"),self:GetTimeStr(reward_config.report_time)))
        
    elseif reward_config.report_type == client_constants["ReportType"].receive_reward then
        -- print("收取战报")
        self.text02:setVisible(true)
        self.text02:setString(string.format(lang_constants:Get("mine_report_receive_reward_desc"),self:GetTimeStr(reward_config.report_time)))

    elseif reward_config.report_type == client_constants["ReportType"].be_rob then
        -- print("被掠夺战报",reward_config.ext_data)
        local data = json:decode(self.config.ext_data)
        local rob_name = ""
        if data and data.rob_leader_name then
            rob_name = data.rob_leader_name
        end
        self.text01:setVisible(true)
        self.text01:setString(string.format(lang_constants:Get("mine_report_be_rob_desc"), self:GetTimeStr(reward_config.report_time), rob_name))
        self.revenge_btn:setVisible(true)
        if self.config.status == 1 then
            self.revenge_btn:setColor(cc.c3b(175,175,175))
        else
            self.revenge_btn:setColor(cc.c3b(255,255,255))
        end

        
    elseif reward_config.report_type == client_constants["ReportType"].be_steal then
        -- print("被偷取战报")
        local data = json:decode(self.config.ext_data)
        local rob_name = ""
        if data and data.rob_leader_name then
            rob_name = data.rob_leader_name
        end
        self.text01:setVisible(true)
        self.text01:setString(string.format(lang_constants:Get("mine_report_be_steal_desc"), self:GetTimeStr(reward_config.report_time), rob_name))
        self.revenge_btn:setVisible(true)
        if self.config.status == 1 then
            self.revenge_btn:setColor(cc.c3b(175,175,175))
        else
            self.revenge_btn:setColor(cc.c3b(255,255,255))
        end

    elseif reward_config.report_type == client_constants["ReportType"].be_revenge then
        -- print("被复仇战报")
        self.text02:setVisible(true)
        self.text02:setString(string.format(lang_constants:Get("mine_report_be_revenge_desc"),self:GetTimeStr(reward_config.report_time)))
    elseif reward_config.report_type == client_constants["ReportType"].additional_reward then
        -- print("特殊奖励")
        self.text01:setVisible(true)
        self.text01:setString(string.format(lang_constants:Get("mine_report_additional_reward_desc"),self:GetTimeStr(reward_config.report_time)))
        if self.config.status == 1 then
            self.gift_img:setVisible(false)
            self.shadow_img:setVisible(false)
        else
            self.gift_img:setVisible(true)
            self.shadow_img:setVisible(true)
        end
    elseif reward_config.report_type == client_constants["ReportType"].cancel_mine then
        -- print("收取战报")
        self.text02:setVisible(true)
        self.text02:setString(string.format(lang_constants:Get("mine_report_cancel_desc"),self:GetTimeStr(reward_config.report_time)))
        
    end
end

function mine_report_sub_panel:GetTimeStr(report_time)
    local date_info = time_logic:GetDateInfo(report_time)
    local time_str = string.format("%02d/%02d %02d:%02d", date_info.month, date_info.day, date_info.hour, date_info.min)
        
    return time_str
end

function mine_report_sub_panel:HideAllWidget()
    self.text01:setVisible(false)
    self.text02:setVisible(false)
    self.name:setVisible(false)
    self.revenge_btn:setVisible(false)
    self.gift_img:setVisible(false)
    self.shadow_img:setVisible(false)
end

local mine_report_panel = panel_prototype.New(true)
function mine_report_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mine_report_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.jump_top_btn = self.root_node:getChildByName("up_btn")

    self.scroll_view = self.root_node:getChildByName("ScrollView_2")
    self.template = self.root_node:getChildByName("template")
    self.template:setVisible(false)

    self.sub_panel_num = 0
    self.report_num = 0
    self.mine_report_sub_panels = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.scroll_view, self.mine_report_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return self.parent_panel.report_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            local report_list = mine_logic.report_list
            sub_panel:Show(report_list[index])
        end
    )

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    
end

function mine_report_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, self.report_num)
    
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = mine_report_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.root_node:setPositionX(self.scroll_view:getContentSize().width/2)
        self.mine_report_sub_panels[i] = sub_panel
        
        self.scroll_view:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

--显示界面
function mine_report_panel:Show()
    self:LoadScrollview()
    self.root_node:setVisible(true)
end

function mine_report_panel:LoadScrollview()
    local report_list = mine_logic.report_list
    if #report_list == 0 then
        return
    end
    if self.report_num ~= #report_list or self.top_time ~= report_list[1].report_time then
        self.top_time = report_list[1].report_time
        self.report_num = #report_list
        self:CreateSubPanels()

        local height = math.max(self.report_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

        
        for i = 1, self.sub_panel_num do
            local sub_panel = self.mine_report_sub_panels[i]

            sub_panel:Show(report_list[i])
            sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1) * SUB_PANEL_HEIGHT)
        end

        self.reuse_scrollview:Show(height, 0)
    end
end

--Update定时器
function mine_report_panel:Update(elapsed_time)
  
end


function mine_report_panel:RegisterEvent()

    --获取战报返回
    graphic:RegisterEvent("query_mine_report_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:LoadScrollview()
    end)

    --有可以复仇的列表
    graphic:RegisterEvent("have_revenge_info", function(choose_list, report_id)
        if not self.root_node:isVisible() then
            return
        end
        graphic:DispatchEvent("show_world_sub_panel", "mine_choose_msgbox", choose_list, report_id)
    end)

    --复仇返回
    graphic:RegisterEvent("report_state_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self.top_time = 0
        self:LoadScrollview()    
    end)
end

function mine_report_panel:RegisterWidgetEvent()
    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --跳转至顶部
    self.jump_top_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.top_time = 0
            self:LoadScrollview() 
        end
    end)
end

return mine_report_panel

