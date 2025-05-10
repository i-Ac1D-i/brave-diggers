local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local MERCENARY_BG_SPRITE = client_constants["MERCENARY_BG_SPRITE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local role_item = class("role_item")

function role_item:ctor(root_node,is_limit) 
	self.is_limit = is_limit 
	self.root_node = root_node 
	root_node:setTouchEnabled(true) 
	self.role_img = self.root_node:getChildByName("icon")
	self.role_img:ignoreContentAdaptWithSize(true)  
	self.role_img:setScale(2) 
	self.cost_text = self.root_node:getChildByName("Text_7")
	self.cost_text:enableOutline(cc.c4b(0,0,0,255),3) 

	self.reduce_text = self.root_node:getChildByName('Text_28') 
	self.select_bg = self.root_node:getChildByName("select") 
	self.Image_55 = self.root_node:getChildByName("Image_55")
	self.Image_55:setOpacity(150)
	self.select_bg:setVisible(false) 
end

function role_item:setDelegate(delegate) 
	self.delegate = delegate 
end

function role_item:ResetState()
	self.root_node:setScale(1)
	self.select_bg:setVisible(false) 
end

function role_item:RefreshRduceText()
	self.times = self.times - 1 
	if self.times <= 0 then
		self.times = 0 
	end
	self.reduce_text:setString(string.format(lang_constants:Get("magic_gold_reduce"),self.times)) 
end

function role_item:InitInfo(template_info)  
	self.info = template_info
	self.root_node:loadTexture(MERCENARY_BG_SPRITE[tonumber(template_info.quality)+6], PLIST_TYPE) 
	self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)
	self.cost_text:setString(tostring(self.info.cost))  

	self.times = template_info.times
	self.reduce_text:setString(string.format(lang_constants:Get("magic_gold_reduce"),template_info.times))  
end

function role_item:RegisterEventListener()
    self.root_node:addTouchEventListener(function(widget, event_type)
	    if event_type == ccui.TouchEventType.ended then
	         self.root_node:runAction(cc.ScaleTo:create(0.05,1.1))  
	         self.delegate:SetCurrentMercenary(self)
	         self.select_bg:setVisible(true)  

	    elseif event_type == ccui.TouchEventType.began then
	    	 self.root_node:runAction(cc.ScaleTo:create(0.05,0.98))    
	    end
    end)
end
 
return role_item