--修炼升级界面
local spine_manager = require "util.spine_manager"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local lang_constants = require "util.language_constants"
local animation_manager = require "util.animation_manager"
local config_manager = require "logic.config_manager"
local cultivation_config = config_manager.cultivation_config
local client_constants = require "util.client_constants"

local cultivation_logic = require "logic.cultivation"
local panel_util = require "ui.panel_util"
local icon_panel = require "ui.icon_panel"
local constants = require "util.constants"
local resource_logic = require "logic.resource"
local utils = require "util.utils"
local ARTIFACT_COST_SUB_PANEL_POS_Y = 153  --消耗sub_panel 位置
local ARTIFACT_COST_SUB_PANEL_POS_X = 240  --消耗sub_panel 位置
local PLIST_TYPE = ccui.TextureResType.plistType
local GREEN = 0xa1e01b
local panel_prototype = require "ui.panel"
local cultivation_levelup_panel = panel_prototype.New(true)

function cultivation_levelup_panel:Init()
	self.root_node = cc.CSLoader:createNode("ui/cultivation_levelup_msgbox.csb")
	self.close_btn = self.root_node:getChildByName("close_btn") 
	self.close_btn:setTouchEnabled(true)
	self.title_name = self.root_node:getChildByName("title"):getChildByName("title_name")
	self.title_des1 = self.root_node:getChildByName("Text_15")

	self.title_des1:ignoreContentAdaptWithSize(false)
	self.title_des1:setContentSize(cc.size(450, 60))

	self.title_des2 = self.root_node:getChildByName("Text_15_0") 
	self.up_bg = self.root_node:getChildByName("Image_18") 

	--加成列表
	self.add_panel = self.root_node:getChildByName("gain_list")
	self.add_skill_icon = self.add_panel:getChildByName("Image_295")
	self.action_up_node = self.add_panel:getChildByName("cultivation_number1_up")
	self.up_line_action = animation_manager:GetTimeLine("cultivation_number1_up")
    self.action_up_node:runAction(self.up_line_action)

    --self.action_up_node:setVisible(false)

	self.add_value1 = self.action_up_node:getChildByName("value1") 
	self.add_value2 = self.action_up_node:getChildByName("value2")
	self.add_arrow = self.action_up_node:getChildByName("arrow")
	self.add_full = self.action_up_node:getChildByName("full")

	self.add_btn = self.add_panel:getChildByName("confirm_btn") 
	self.add_btn:setTag(1)
	self.add_cost_title = self.add_panel:getChildByName("cost_title")
	self.up_source_bg = self.add_panel:getChildByName("Panel_1")
	self.up_item_bg = self.up_source_bg:getChildByName("Image_196")
	self.up_cost_title = self.add_panel:getChildByName("cost_title")
	--削减列表
	self.sub_panel = self.root_node:getChildByName("gain_list_1")
	self.sub_skill_icon = self.sub_panel:getChildByName("Image_295")
	self.action_down_node = self.sub_panel:getChildByName("cultivation_number2_up")
	self.down_line_action = animation_manager:GetTimeLine("cultivation_number2_up")
    self.action_down_node:runAction(self.down_line_action)

    local up_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "change1" then
        	self.add_value1:setString(self.addInfo2.coefficient.."%")
        elseif event_name == "change2" then
        	local next_next_info = cultivation_config[self.selectType][self.addNextLevel+1]
        	if  next_next_info then
        		self.add_value2:setString(next_next_info.coefficient1.."%")
        	else
        		self.add_value2:setVisible(false)
				self.add_arrow:setVisible(false)
				self.add_full:setVisible(true)
        	end
        	local delay = cc.DelayTime:create(0.5)
        	local func = cc.CallFunc:create(function()
        		self:ConfigAtt()
        	end)
        	local sequence = cc.Sequence:create(delay , func)
        	self.root_node:runAction(sequence)
        end
    end
    self.up_line_action:clearFrameEventCallFunc()
    self.up_line_action:setFrameEventCallFunc(up_call_function)

    local down_call_function = function(frame)
        local event_name = frame:getEvent()
        if event_name == "change1" then
        	self.sub_value1:setString(self.subInfo2.coefficient.."%")
        elseif event_name == "change2" then
        	local next_next_info = cultivation_config[self.selectType][self.subNextLevel+1]
        	if next_next_info then
        		self.sub_value2:setString(math.abs(next_next_info.coefficient2).."%")
        	else
        		self.sub_value2:setVisible(false)
				self.sub_arrow:setVisible(false)
				self.sub_full:setVisible(true)
        	end
        	local delay = cc.DelayTime:create(0.5)
        	local func = cc.CallFunc:create(function()
        		self:ConfigAtt()
        	end)
        	local sequence = cc.Sequence:create(delay , func)
        	self.root_node:runAction(sequence)
        end
    end
    self.down_line_action:clearFrameEventCallFunc()
    self.down_line_action:setFrameEventCallFunc(down_call_function)

    --self.action_up_node:setVisible(false)
	self.sub_value1 = self.action_down_node:getChildByName("value1")
	self.sub_value2 = self.action_down_node:getChildByName("value2") 
	self.sub_arrow = self.action_down_node:getChildByName("arrow")
	self.sub_full = self.action_down_node:getChildByName("full")

	self.sub_btn = self.sub_panel:getChildByName("confirm_btn")
	self.sub_btn:setTag(2)
	self.sub_cost_title = self.sub_panel:getChildByName("cost_title")
	self.down_source_bg = self.sub_panel:getChildByName("Panel_1")
	self.down_item_bg = self.down_source_bg:getChildByName("Image_196")
	self.down_cost_title = self.sub_panel:getChildByName("cost_title")
	--资源列表
	self.cost_up_panels = {}
	self.cost_down_panels = {}

	--修炼动画
    self.spine_node = spine_manager:GetNode("cultivation_up", 1.0, true) 
    --self.spine_node:setScale(0.8)
    self.up_source_bg:addChild(self.spine_node)
    self.spine_node:setPosition(cc.p(self.up_source_bg:getBoundingBox().width/2 + 18, self.up_source_bg:getBoundingBox().height - 58))
    --self.spine_node:setTimeScale(1.0)
    self.spine_node:setVisible(false)

    --资源消失动画
    self.spine_node1 = spine_manager:GetNode("fuwen", 1.0, true) 
    --self.spine_node1:setScale(1.5)
    self.root_node:addChild(self.spine_node1)
    self.spine_node1:setPosition(cc.p(self.add_panel:getPositionX(),self.add_panel:getPositionY() - 110))
    --self.spine_node1:setTimeScale(1.0)
    self.spine_node1:setVisible(false)

    self.spine_node1:registerSpineEventHandler(function(event)
	        local animation_name = event.animation
	        if animation_name == "clear" then
	        end
    	end, sp.EventType.ANIMATION_COMPLETE)
     
    self.spine_node2 = spine_manager:GetNode("cultivation_up", 1.0, true) 
    self.down_source_bg:addChild(self.spine_node2)
    self.spine_node2:setPosition(cc.p(self.down_source_bg:getBoundingBox().width/2 + 18,self.down_source_bg:getBoundingBox().height - 58))
    self.spine_node2:setVisible(false)

    self.actionStatu = "action_end"
	self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function cultivation_levelup_panel:Show(curType)
	self.root_node:setVisible(true)
	self.selectType = curType
	self:ConfigAtt(true)
	self:ConfigUpDes()
end

function cultivation_levelup_panel:ConfigUpDes()
	self.title_des1:setString(lang_constants:Get("cultivation_des_text"..self.selectType)) 
	self.title_des2:setString(lang_constants:Get("cultivation_adorn_text"..self.selectType))
	if self.selectType == 1 then
		self.add_skill_icon:loadTexture("bg/skill/skill_2.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("bg/skill/skill_2.png",PLIST_TYPE)
		self.up_bg:loadTexture("bg/mapbg/mapbg_ruins.png",PLIST_TYPE)
	elseif self.selectType == 2 then
		self.add_skill_icon:loadTexture("entrust/skill_22.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("entrust/skill_22.png",PLIST_TYPE)
		self.up_bg:loadTexture("bg/mapbg/mapbg_time.png",PLIST_TYPE)
	elseif self.selectType == 3 then
		self.add_skill_icon:loadTexture("entrust/skill_23.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("entrust/skill_23.png",PLIST_TYPE)
		self.up_bg:loadTexture("bg/mapbg/mapbg_angel.png",PLIST_TYPE)
	elseif self.selectType == 4 then
		self.add_skill_icon:loadTexture("entrust/skill_24.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("entrust/skill_24.png",PLIST_TYPE)
		self.up_bg:loadTexture("bg/mapbg/mapbg_cave.png",PLIST_TYPE)
	elseif self.selectType == 5 then
		self.add_skill_icon:loadTexture("bg/skill/skill_13.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("bg/skill/skill_13.png",PLIST_TYPE)
		self.up_bg:loadTexture("bg/mapbg/mapbg_ether.png",PLIST_TYPE)
	elseif self.selectType == 6 then
		self.add_skill_icon:loadTexture("bg/skill/skill_9.png",PLIST_TYPE)
		self.sub_skill_icon:loadTexture("bg/skill/skill_9.png",PLIST_TYPE)			
		self.up_bg:loadTexture("bg/mapbg/mapbg_aircity.png",PLIST_TYPE)
	end
end

function cultivation_levelup_panel:ConfigAtt(not_action)

	local listInfo = cultivation_logic:getNewInfo(self.selectType)
	self.addInfo1 = listInfo[1].curInfo
	self.addInfo2 = listInfo[1].nextInfo

	self.subInfo1 = listInfo[2].curInfo
	self.subInfo2 = listInfo[2].nextInfo

	self.add_value1:setString(self.addInfo1.coefficient.."%")
	self.subInfo1.coefficient = math.abs(self.subInfo1.coefficient)
	self.sub_value1:setString(self.subInfo1.coefficient.."%")

    self.up_item_bg:removeAllChildren()
	self.down_item_bg:removeAllChildren()
    self.cost_up_panels = {}
    self.cost_down_panels = {}
	if self.addInfo2 then
		self.up_cost_title:setVisible(true)
		self.add_btn:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
        self.add_btn:setTouchEnabled(true)
		self.add_value2:setVisible(true)
		self.add_arrow:setVisible(true)
		self.add_full:setVisible(false)
		self.add_value2:setString(self.addInfo2.coefficient.."%")
		self.addCostRes =  self.addInfo2.resource_ids
		self.addCostNum =  self.addInfo2.cost_nums
		self.addNextLevel = self.addInfo2.nextLevel
		self.addOff = self.addInfo2.coefficient - self.addInfo1.coefficient
		--加载消耗资源
		local cost_config = {}
		local cost_num = 0
		if self.addCostRes then
			for i,id in ipairs(self.addCostRes) do
				cost_num = cost_num + 1
				cost_config[constants["RESOURCE_TYPE_NAME"][tonumber(id)]] = tonumber(self.addCostNum[i]) 
			end
		end
	    self.cost_up_spine = {}

	    for i=1,cost_num do
	    	local cost_add_panel = icon_panel.New()
            cost_add_panel:Init(self.up_item_bg)
            cost_add_panel.root_node:setScale(1.0)
            local spine = self.spine_node1:clone()
            cost_add_panel.root_node:addChild(spine)
            local size = cost_add_panel.root_node:getContentSize()
            spine:setPosition(size.width/2, size.height/2)
            table.insert(self.cost_up_spine,spine) 
            self.cost_up_panels[i] = cost_add_panel
	    end
	    panel_util:LoadCostResourceInfo(cost_config, self.cost_up_panels, ARTIFACT_COST_SUB_PANEL_POS_Y, cost_num, ARTIFACT_COST_SUB_PANEL_POS_X)
	else  --满级
		self.up_cost_title:setVisible(false)
		self.add_btn:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
		self.add_btn:setTouchEnabled(false)
		self.add_value2:setVisible(false)
		self.add_arrow:setVisible(false)
		self.add_full:setVisible(true)
	end

	if self.subInfo2 then
		self.down_cost_title:setVisible(true)
		self.sub_btn:setColor(panel_util:GetColor4B(client_constants["LIGHT_BLEND_COLOR"]))
		self.sub_btn:setTouchEnabled(true)
		self.sub_value2:setVisible(true)
		self.sub_arrow:setVisible(true)
		self.sub_full:setVisible(false)
		self.subInfo2.coefficient = math.abs(self.subInfo2.coefficient)
		self.sub_value2:setString(self.subInfo2.coefficient.."%")
		self.subCostRes =  self.subInfo2.resource_ids
		self.subCostNum =  self.subInfo2.cost_nums
		self.subNextLevel = self.subInfo2.nextLevel
		self.subOff = self.subInfo2.coefficient - self.subInfo1.coefficient

		--加载消耗资源
		local cost_config = {}
		local cost_num = 0
		if self.subCostRes then
			for i,id in ipairs(self.subCostRes) do
				cost_num = cost_num + 1
				cost_config[constants["RESOURCE_TYPE_NAME"][tonumber(id)]] = tonumber(self.subCostNum[i]) 
			end
		end
	    self.cost_down_spine = {}

	    for i=1,cost_num do
	    	local cost_sub_panel = icon_panel.New()
            cost_sub_panel:Init(self.down_item_bg)
            cost_sub_panel.root_node:setScale(1.0)
            local spine = self.spine_node1:clone()
            cost_sub_panel.root_node:addChild(spine)
            local size = cost_sub_panel.root_node:getContentSize()
            spine:setPosition(size.width/2, size.height/2)
			table.insert(self.cost_down_spine,spine)
            self.cost_down_panels[i] = cost_sub_panel
	    end
	    panel_util:LoadCostResourceInfo(cost_config, self.cost_down_panels, ARTIFACT_COST_SUB_PANEL_POS_Y, cost_num, ARTIFACT_COST_SUB_PANEL_POS_X) 
	else --满级
		self.down_cost_title:setVisible(false)
		self.sub_btn:setColor(panel_util:GetColor4B(client_constants["DARK_BLEND_COLOR"]))
		self.sub_btn:setTouchEnabled(false)
		self.sub_value2:setVisible(false)
		self.sub_arrow:setVisible(false)
		self.sub_full:setVisible(true)
	end

	if not not_action then
		if self.addInfo2 and self.clickType == "coefficient1" then 
			for i,v in ipairs(self.cost_up_panels) do
				local origin = v.root_node:getScale()
				local func = cc.CallFunc:create(function ()
					self.actionStatu = "action_end"
				end)
				v.root_node:setScale(0.2*origin)
				local scaleTo1 = cc.ScaleTo:create(0.2,1.1*origin)
				local scaleTo2 = cc.ScaleTo:create(0.2,origin)
			    local sequence = cc.Sequence:create(scaleTo1, scaleTo2,func)
			    v.root_node:runAction(sequence)
			end
		elseif self.subInfo2 and self.clickType == "coefficient2" then 
			for i,v in ipairs(self.cost_down_panels) do
				local origin = v.root_node:getScale()
				v.root_node:setScale(0.2*origin)
				local func = cc.CallFunc:create(function ()
					self.actionStatu = "action_end"
				end)
				local scaleTo1 = cc.ScaleTo:create(0.2,1.1*origin)
				local scaleTo2 = cc.ScaleTo:create(0.1,origin)
			    local sequence = cc.Sequence:create(scaleTo1, scaleTo2 ,func)
			    v.root_node:runAction(sequence)
			end
		end
		if self.clickType == "coefficient1" and not self.addInfo2 then
			self.actionStatu = "action_end"
		end

		if self.clickType == "coefficient2" and not self.subInfo2 then
			self.actionStatu = "action_end"
		end
	end
end

function cultivation_levelup_panel:RegisterWidgetEvent()
    --关闭界面
    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.actionStatu = "action_end"
            graphic:DispatchEvent("hide_world_sub_panel", "cultivation_levelup_msgbox")   
        end
    end)

    local function onClick(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if self.actionStatu and self.actionStatu == "action_run" then
            	return
            end
            audio_manager:PlayEffect("click")
            local tag = widget:getTag()
            if tag == 1 then
            	if self.addInfo2 == nil then
            		graphic:DispatchEvent("show_prompt_panel", "already_top")
            		return
            	end

            	for k,v in ipairs(self.addCostRes) do
					local cost = self.addCostNum[k]
			   		if not resource_logic:CheckResourceNum(tonumber(v) , tonumber(cost), true) then
        				return
    				end
				end
				self.clickType = "coefficient1"
				self.actionStatu = "action_run"
            	cultivation_logic:SendCultivation(self.selectType,"coefficient1")
            else
            	if self.subInfo2 == nil then
            		graphic:DispatchEvent("show_prompt_panel", "already_top")
            		return
            	end

            	for k,v in ipairs(self.subCostRes) do
					local cost = self.subCostNum[k]
					if not resource_logic:CheckResourceNum(tonumber(v) , tonumber(cost), true) then
        				return
    				end
				end
				self.clickType = "coefficient2"
				self.actionStatu = "action_run"
				cultivation_logic:SendCultivation(self.selectType,"coefficient2")
            end
        end
    end
    self.add_btn:addTouchEventListener(onClick)
    self.sub_btn:addTouchEventListener(onClick)
end

function cultivation_levelup_panel:RegisterEvent()
	graphic:RegisterEvent("update_cultivation", function()
		if self.clickType then
			if self.clickType == "coefficient1" then
				if self.spine_node then
					self.spine_node:setVisible(true)
					self.spine_node:setAnimation(0, "cultivation_up", false)
				end

				local func1 = cc.CallFunc:create(function()
					for i,v in pairs(self.cost_up_spine) do
						v:setAnimation(0, "clear", false)
					end
				end)

				local delay = cc.DelayTime:create(1.0)
				local func2 = cc.CallFunc:create(function()
					local prompt_label = self.add_value1:clone()
					prompt_label:setString("+"..self.addOff.."%")
					prompt_label:setColor(panel_util:GetColor4B(GREEN))
					prompt_label:setScale(1.5)
					local delay = cc.DelayTime:create(0.1)
					local size = self.root_node:getContentSize()
					prompt_label:setPosition(size.width/2 - 30,630)
					local moveBy = cc.MoveBy:create(1.0,cc.p(0,80))
					self.root_node:addChild(prompt_label)
					self.up_line_action:play("play", false)
				    local sequence = cc.Sequence:create(delay,moveBy,cc.CallFunc:create(function()
						prompt_label:removeFromParent()
					end))
	                local delay = cc.DelayTime:create(0.5)
	                local fade_out = cc.FadeOut:create(0.3)
	                local sequence_out = cc.Sequence:create(delay, fade_out)
 					prompt_label:runAction(sequence_out)
					prompt_label:runAction(sequence)
				end)
				local sequence = cc.Sequence:create(func1,delay,func2)
				self.root_node:runAction(sequence) 

			 	local fade_out = cc.FadeOut:create(0.2)
				for k,v in pairs(self.cost_up_panels) do
					v.root_node:setCascadeOpacityEnabled(true)
					v.root_node:runAction(fade_out:clone())
				end
			elseif self.clickType == "coefficient2" then 
				if self.spine_node2 then
					self.spine_node2:setVisible(true)
					self.spine_node2:setAnimation(0, "cultivation_up", false)
				end
				for i,v in pairs(self.cost_down_spine) do
					v:setAnimation(0, "clear", false)
				end

				local func1 = cc.CallFunc:create(function()
					for i,v in pairs(self.cost_down_spine) do
						v:setAnimation(0, "clear", false)
					end
				end)
				local delay = cc.DelayTime:create(1.0)
				local func2 = cc.CallFunc:create( function()
                	local prompt_label = self.add_value1:clone()
	                prompt_label:setString("+"..self.subOff.."%")
	                prompt_label:setColor(panel_util:GetColor4B(GREEN))
	                prompt_label:setScale(1.5)
	                local delay = cc.DelayTime:create(0.1)
	                local size = self.root_node:getContentSize()
	                prompt_label:setPosition(size.width/2-30,310)
	                local moveBy = cc.MoveBy:create(1.0,cc.p(0,80))
	                self.root_node:addChild(prompt_label)
	                self.down_line_action:play("play", false)
	                local sequence = cc.Sequence:create(delay,moveBy, cc.CallFunc:create(function()
	                    prompt_label:removeFromParent()
	                end))
	                local delay = cc.DelayTime:create(0.5)
	                local fade_out = cc.FadeOut:create(0.3)
	                local sequence_out = cc.Sequence:create(delay, fade_out)
 					prompt_label:runAction(sequence_out)
	                prompt_label:runAction(sequence)
	             	end)

					local sequence = cc.Sequence:create(func1,delay,func2)
					self.root_node:runAction(sequence)

					local fade_out = cc.FadeOut:create(0.2)
					for k,v in pairs(self.cost_down_panels) do
						v.root_node:setCascadeOpacityEnabled(true)
						v.root_node:runAction(fade_out:clone())
					end
			end
		end
	end)

    graphic:RegisterEvent("update_resource_list", function()
        if not self.root_node:isVisible() then
            return
        end
        self:RefreshResource()
    end)
end

function cultivation_levelup_panel:RefreshResource()
    for k,v in pairs(self.cost_up_panels) do
    	local resourceType = v:GetIconResourceType()
    	if resource_logic:IsResourceUpdated(resourceType) then
    		v:SetTextStatus(resourceType)
    	end
    end
    for k,v in pairs(self.cost_down_panels) do
    	local resourceType = v:GetIconResourceType()
    	if resource_logic:IsResourceUpdated(resourceType) then
    		v:SetTextStatus(resourceType)
    	end
    end
end

return cultivation_levelup_panel