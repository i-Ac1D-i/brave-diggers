local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local resource_logic = require "logic.resource"
local utils = require('util.utils') 
local panel_util = require "ui.panel_util"
local icon_panel = require "ui.icon_panel"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager" 
local panel_prototype = require "ui.panel"
local resource_config = config_manager.resource_config

local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]
local blood_replace_panel = panel_prototype.New()
function blood_replace_panel:Init()
	self.root_node = cc.CSLoader:createNode("ui/blood_replace_msgbox.csb") 
	self.root_node:setVisible(false) 

	self.title_text = self.root_node:getChildByName("title")
	self.des_text = self.root_node:getChildByName("version_text")
	self.lack_text = self.root_node:getChildByName("award_title_0")
	self.lack_num_text = self.root_node:getChildByName("award_title_0_0")
	self.item_bg = self.root_node:getChildByName("award_bg_0")
	
	self.cost_blood_des = self.root_node:getChildByName("award_title")
	self.blood_bg = self.root_node:getChildByName("award_bg")

	self.confirm_btn = self.root_node:getChildByName("confirm_btn")
	self.cancel_btn = self.root_node:getChildByName("cancel_btn")
	self.close_btn = self.root_node:getChildByName("close_btn")

	self:RegisterWidgetEvent()
	self:RegisterEvent() 
end

function blood_replace_panel:Show(resource_id,lack_num,blood_replace_pre)
	self.root_node:setVisible(true) 
	self.resource_id = resource_id
	self.lack_num = lack_num
	self.blood_replace_pre = blood_replace_pre
	self.lack_num_text:setString(self.lack_num)
	self:refreshSource()
end

function blood_replace_panel:refreshSource()
	self.item_bg:removeAllChildren()
	self.item_icon = nil

	self.blood_bg:removeAllChildren()
	self.blood_icon = nil

	local pre_blood = panel_util:strSplit(self.blood_replace_pre,"-")
	local pre = tonumber(pre_blood[2])
	if tonumber(pre_blood[1]) > tonumber(pre_blood[2]) then
		pre = tonumber(pre_blood[1])
	end

	self.blood_num = self.lack_num*pre

	self.item_icon = icon_panel.New(false,3)
	self.item_icon:Init(self.item_bg)
	local item_sub_panels = {}
	table.insert(item_sub_panels,self.item_icon)

	self.blood_icon = icon_panel.New()
	self.blood_icon:Init(self.blood_bg)
	local blood_sub_panels = {}
	table.insert(blood_sub_panels,self.blood_icon)

	local item_config = {}
	item_config[RESOURCE_TYPE_NAME[tonumber(self.resource_id)]] = tonumber(self.lack_num) 
	local blood_config = {}
	blood_config[RESOURCE_TYPE_NAME[RESOURCE_TYPE["blood_diamond"]]] = self.blood_num

	panel_util:LoadCostResourceInfo(item_config,item_sub_panels, 45,1 ,211) 
	panel_util:LoadCostResourceInfo(blood_config,blood_sub_panels, 45,1,211) 
end

function blood_replace_panel:RegisterWidgetEvent()
	self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
		    if not resource_logic:CheckResourceNum(constants.RESOURCE_TYPE["blood_diamond"], self.blood_num, true) then
		        return 
		    end

            if self.resource_id and self.lack_num then
            	resource_logic:BuyResourceByBlood(tonumber(self.resource_id),tonumber(self.lack_num))
            end
        end
    end)

	self.cancel_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_blood_replace_panel")
        end
    end)

	self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_blood_replace_panel")
        end
    end)
end

function blood_replace_panel:RegisterEvent()
	
end

return blood_replace_panel
























