--修炼主界面

local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local lang_constants = require "util.language_constants"
local cultivation_logic = require "logic.cultivation"
local panel_prototype = require "ui.panel"
local platform_manager = require "logic.platform_manager"
local cultivation_panel = panel_prototype.New()
local PLIST_TYPE = ccui.TextureResType.plistType
local CULTIVATION_TYPE =
{
    ["AAA"] = 1,
    ["BBB"] = 2,
    ["CCC"] = 3,
    ["DDD"] = 4,
    ["EEE"] = 5,
    ["FFF"] = 6,
}
local LIST_ALL_NUM = 6
local LIST_OFF_NUM = 20
local SKILL_DESC_LINE_HEIGHT = 25
local BASE_HEIGHT = 240
local BASE_WIDTH_TEXT = 342
function cultivation_panel:Init()
	--修炼类型
	self.root_node = cc.CSLoader:createNode("ui/cultivation_panel.csb") 
	self.title_text = self.root_node:getChildByName("title_text")

	self.cultivation_btn1 = self.root_node:getChildByName("Button_area01")
	self.cultivation_btn1:setTouchEnabled(true)
	self.cultivation_name1 = self.cultivation_btn1:getChildByName("Text_110")
	self.cultivation_btn1:setTag(CULTIVATION_TYPE["AAA"])

	self.cultivation_btn2 = self.root_node:getChildByName("Button_area01_0")
	self.cultivation_btn2:setTouchEnabled(true)
	self.cultivation_btn2:setTag(CULTIVATION_TYPE["EEE"]) 
	self.cultivation_name2 = self.cultivation_btn2:getChildByName("Text_110") 

	self.cultivation_btn3 = self.root_node:getChildByName("Button_area01_0_0")
	self.cultivation_btn3:setTouchEnabled(true)
	self.cultivation_btn3:setTag(CULTIVATION_TYPE["FFF"]) 
	self.cultivation_name3 = self.cultivation_btn3:getChildByName("Text_110") 

	self.cultivation_btn4 = self.root_node:getChildByName("Button_area01_0_0_0")
	self.cultivation_btn4:setTouchEnabled(true)
	self.cultivation_btn4:setTag(CULTIVATION_TYPE["BBB"]) 
	self.cultivation_name4 = self.cultivation_btn4:getChildByName("Text_110") 

	self.cultivation_btn5 = self.root_node:getChildByName("Button_area01_0_0_0_0")
	self.cultivation_btn5:setTouchEnabled(true)
	self.cultivation_btn5:setTag(CULTIVATION_TYPE["CCC"]) 
	self.cultivation_name5 = self.cultivation_btn5:getChildByName("Text_110") 

	self.cultivation_btn6 = self.root_node:getChildByName("Button_area01_0_0_0_0_0")
	self.cultivation_btn6:setTouchEnabled(true)
	self.cultivation_btn6:setTag(CULTIVATION_TYPE["DDD"]) 
	self.cultivation_name6 = self.cultivation_btn6:getChildByName("Text_110") 

	self.rule_icon_btn = self.root_node:getChildByName("view_info_btn") 
	
	--属性加成
	self.title_att = self.root_node:getChildByName("title_2") 

	self.selected = self.root_node:getChildByName("selected") 

	--漂浮的属性信息
	self.skill_info_bg_img = self.root_node:getChildByName("skill_info_bg")
    self.skill_title_text = self.skill_info_bg_img:getChildByName("name")
	self.skill_title_text:ignoreContentAdaptWithSize(true)
    --self.skill_title_text:setContentSize(cc.size(430, 200))
    self.skill_info_bg_img:setVisible(false)

	self.item = self.selected:getChildByName("item01") 
	self.item:retain()
	self.item:removeFromParent()
	self.item_box = self.item:getBoundingBox() 
	
	self.items = {}
	local x = self.item:getPositionX() + 13
	local y = self.item:getPositionY() 
	for i=1,LIST_ALL_NUM do
		local item = self.item:clone()
		local btn = item:getChildByName("Button_27") 
		btn:setOpacity(0)
		btn:setTag(i)
		btn:addTouchEventListener(function(widget, event_type)
	        if event_type == ccui.TouchEventType.began then
	            audio_manager:PlayEffect("click")
	            self.skill_info_bg_img:setVisible(true)
	            self:ShowSkillDesc(widget)
			elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
	            self.skill_info_bg_img:setVisible(false)
	            graphic:DispatchEvent("hide_floating_panel")
	        end
    	end)
		self.items[i] = item
		item:setPosition(x,y)
		self.selected:addChild(item)  
		y = y - self.item_box.height  
		local desc1 =  lang_constants:Get("cultivation_destributions"..i)
		item:getChildByName("desc"):setString(desc1)
		if i == 1 then
			item:getChildByName("Image_295"):loadTexture("bg/skill/skill_2.png", PLIST_TYPE)
		elseif i == 2 then
			item:getChildByName("Image_295"):loadTexture("entrust/skill_22.png", PLIST_TYPE)
		elseif i == 3 then
			item:getChildByName("Image_295"):loadTexture("entrust/skill_23.png", PLIST_TYPE)
		elseif i == 4 then
			item:getChildByName("Image_295"):loadTexture("entrust/skill_24.png", PLIST_TYPE)
		elseif i == 5 then
			item:getChildByName("Image_295"):loadTexture("bg/skill/skill_13.png", PLIST_TYPE)
		elseif i == 6 then
			item:getChildByName("Image_295"):loadTexture("bg/skill/skill_9.png", PLIST_TYPE)
		end
	end

	self.back_btn = self.root_node:getChildByName("back_btn") 

	--默认值
	self.cur_type = CULTIVATION_TYPE["AAA"] --第一个

	local convert = {[1] = 1,[2] = 4,[3] = 5,[4] = 6,[5] = 2,[6] = 3}

	local positions = {}
	for index = 1,6 do
		local top = self.items[index]
		local position_tb = cc.p(top:getPositionX() - 20 , top:getPositionY())
		positions[index] = position_tb
	end
	
	for index = 1,6 do
		local top = self.items[index]
		top:setPosition(positions[ convert[index] ])
	end
	self.floadWidth = self.skill_info_bg_img:getBoundingBox().width
	self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function cultivation_panel:ShowSkillDesc(node_btn)
	local desc1 =  lang_constants:Get("cultivation_float_des"..node_btn:getTag())
	self.skill_title_text:setString(desc1)
    local label_render = self.skill_title_text:getVirtualRenderer():setMaxLineWidth(BASE_WIDTH_TEXT)

    local line_num = label_render:getStringNumLines()
    if platform_manager:GetChannelInfo().is_open_system then
	    local size = self.skill_title_text:getAutoRenderSize()
	    local content_size = self.skill_title_text:getVirtualRenderer():getContentSize()
	    line_num = math.ceil(size.width / content_size.width)
    end
    local text_height = line_num * SKILL_DESC_LINE_HEIGHT 
    self.skill_title_text:setContentSize(BASE_WIDTH_TEXT,text_height)

    local click = self.items[node_btn:getTag()]:getPositionY()
    local height = SKILL_DESC_LINE_HEIGHT * line_num + 40 
    click = click + BASE_HEIGHT + height + 25
    self.skill_info_bg_img:setPositionY(click)
	self.skill_title_text:setPosition(self.floadWidth/2,height - 22)
	self.skill_info_bg_img:setContentSize(cc.size(self.floadWidth, height))
end

function cultivation_panel:Show()
	self.root_node:setVisible(true) 
	self:UpdateAtt()
end

function cultivation_panel:UpdateAtt()--刷新属性
	self.allAttCofficient = {}
	for k=1,6 do --6中类型
		local level1 = cultivation_logic.cultivation_info[k].coefficient1
		local level2 = cultivation_logic.cultivation_info[k].coefficient2
		local add_all = 0
		local sub_all = 0
		if level1 and level1 > 0 then
			add_all = cultivation_logic:getAttAddByLevel(k,level1)[1]
		end
		if level2 and level2 > 0 then
			sub_all = cultivation_logic:getAttAddByLevel(k,level2)[2]
		end
		local info = {}
		info.coefficient1 = add_all
		info.coefficient2 = math.abs(sub_all)
		table.insert(self.allAttCofficient,info)
	end

	for k,v in pairs(self.items) do
		v:getChildByName("value2"):setString(self.allAttCofficient[k].coefficient1.."%")
		v:getChildByName("value2_0"):setString(self.allAttCofficient[k].coefficient2.."%")
	end
end

function cultivation_panel:RegisterWidgetEvent()
    --关闭界面
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene", "mercenary_cultivation_sub_scene")   
        end
    end)

    self.rule_icon_btn:addTouchEventListener(function(widget, event_type)
			if event_type == ccui.TouchEventType.ended then
			    graphic:DispatchEvent("show_world_sub_panel", "cultivation_rule_msgbox")    
			end
		end)

    local function onClick(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.cur_type = widget:getTag()
            graphic:DispatchEvent("show_world_sub_panel", "cultivation_levelup_msgbox", self.cur_type)
        end
    end
    self.cultivation_btn1:addTouchEventListener(onClick)
    self.cultivation_btn2:addTouchEventListener(onClick)
    self.cultivation_btn3:addTouchEventListener(onClick)
    self.cultivation_btn4:addTouchEventListener(onClick)
    self.cultivation_btn5:addTouchEventListener(onClick)
    self.cultivation_btn6:addTouchEventListener(onClick)

end

function cultivation_panel:RegisterEvent()
     graphic:RegisterEvent("update_cultivation",function( )
     	self:UpdateAtt()
     end)
end

return cultivation_panel