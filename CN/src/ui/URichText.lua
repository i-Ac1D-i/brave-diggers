local utils = require('util.utils')
local platform_manager = require "logic.platform_manager"

local v = class("URichText",function() 
		return ccui.Layout:create()
	end)

function v:ctor(max_length) 
	self.max_length = max_length 
 
    self.line_space = 0
 
end

function v:getData()
	if not self._data then
		return nil 
	end
	return self._data 
end

function v:getRetainData()
	if not self._retain_data then
		return nil 
	end
	return self._retain_data 
end

function v:setClear()
	if self._richText then
		self:removeChild(self._richText) 
		self._richText = nil 
	end
	if self._richText_test then
		self:removeChild(self._richText_test) 
		self._richText_test = nil 
	end

	if self.title_text then
		self:removeChild(self.title_text) 
		self.title_text = nil 
	end

	self.title_text = ccui.RichText:create()
	self.title_text:setAnchorPoint(cc.p(0,0)) 
	self.title_text:ignoreContentAdaptWithSize(true)  
	self:addChild(self.title_text)

	self._richText = ccui.RichText:create()
    self._richText:setAnchorPoint(cc.p(0,0))
     
    self:addChild(self._richText)

    self._richText:setContentSize(cc.size(self.max_length,0)) 
    self._richText:ignoreContentAdaptWithSize(false) 

    self._richText_test = ccui.RichText:create()
    self._richText_test:ignoreContentAdaptWithSize(true)

    self:addChild(self._richText_test)  
	self._richText_tb = {self._richText,self._richText_test}
end
 
function v:setData(data,retain_ata)  
	self._data = data 
	self._retain_data = retain_ata
	 
	self:setClear()  
    local utils = require("util.utils") 
    
    local parser = utils:newParser();
 
	 --local parsedXml = parser:loadFile("/Users/zhaoqinglong/Documents/workspace/CMKGM/src/test.xml"); 
	 local parsedXml = parser:ParseXmlText(data)
	 local msg =  parsedXml.text 
  	 self.defult_color = msg["@color"] or "#FFFFFF"
  	 self.defult_fontName = msg["@fontName"] or "Arial"
  	 self.defult_fontSize = tonumber(msg["@fontSize"] or "20")
  	 local children = msg:children()

	for index,item in ipairs(children) do 
	 	if item:name() == 'text' then
	 		local fontName = item["@fontName"] or self.defult_fontName
				local fontSize = item["@fontSize"] or self.defult_fontSize
				local color = item["@color"] or self.defult_color
				local title = item["@title"]
	 		for i=1,2 do
	 			if title then
	 				local re = ccui.RichElementText:create(index, self:convertToRGB(color), 255, item:value(), fontName, tonumber(fontSize))
	 				self.title_text:pushBackElement(re)
	 				break 
	 			else
					local re = ccui.RichElementText:create(index, self:convertToRGB(color), 255, item:value(), fontName, tonumber(fontSize))
					self._richText_tb[i]:pushBackElement(re)
	 			end

	 		end
 
		elseif item:name() == 'img' then
			for i=1,2 do
				local img = ccui.ImageView:create()
				img:loadTexture(item["@path"]) 
				img:setAnchorPoint(cc.p(0,0)) 
				local size = img:getContentSize() 
				local recustom = ccui.RichElementCustomNode:create(index, cc.c3b(255, 255, 255), 255, img)
				self._richText_tb[i]:pushBackElement(recustom) 
			end
		end
	 end
	 self._richText_tb[1]:formatText();
	 self._richText_tb[2]:formatText();
	 self.title_text:formatText();
	 local size = self._richText_test:getContentSize()
 	 local title_size = self.title_text:getContentSize()
	 local height =(math.ceil((size.width / self.max_length)))* (size.height + self.line_space)
	 self.title_text:setPosition(cc.p(-title_size.width/2,height-title_size.height/2)) 
	 self._richText:setPosition(cc.p(-self.max_length/2,height))

	 height = height+self.title_text:getContentSize().height
	 self:setContentSize(cc.size(self.max_length,height)) 
	 self:removeChild(self._richText_test)   
	 self._richText_test = nil  
	 
	  
end
 
-- function v:drawLine(target,color3b)
-- 	local color4f = cc.c4f(color3b.r/255,color3b.g/255,color3b.b/255,1)
-- 	local draw_node = cc.DrawNode:create()
-- 	target:addChild(draw_node,10)
-- 	local origin_pos = cc.p(0,0)
-- 	local size = target:getContentSize()
-- 	local tar_pos =  cc.p(size.width,0) 
-- 	draw_node:drawLine(cc.p(0,0),tar_pos,color4f) 
-- end
 
function v:convertToRGB(hex)
	hex = string.gsub(hex,"#","")
	local red = string.sub(hex, 1, 2)  
	local green = string.sub(hex, 3, 4)  
	local blue = string.sub(hex, 5, 6)  
	 
	red = tonumber(red, 16)  
	green = tonumber(green, 16)  
	blue = tonumber(blue, 16)  
	return cc.c3b(red,green,blue) 
end
 



return v