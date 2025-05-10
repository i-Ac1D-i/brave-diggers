local utils = require('util.utils')
local client_constants = require "util.client_constants"
local look_img = client_constants["CHAT_IMG_PATH"]
local panel_util = require "ui.panel_util"

local v = class("RichLabelText",function() 
		return ccui.Layout:create()
	end)

function v:ctor(str, max_length, fontSize, line_space, start_pos_y) 
	self.max_length = max_length or 0
	self.str = str or ""
 	self:setString(str)
    self.line_space = line_space or 0
    self.start_pos_y = start_pos_y or 0
 	self.height = 0

 	self.defult_color = "0x000000"
  	self.defult_fontName = "Arial"
  	self.defult_fontSize = fontSize or 38
end

--设置默认的字体颜色
function v:SetDefultColor(color)
	self.defult_color = color
end

function v:ParsedXml(str)
	--创建一个解析器
	local parser = utils:newParser()
	--解析完成后的对象
 	local parsedXml = parser:ParseXmlText(str)
	local msg =  parsedXml.text
	if not msg then
		return
	end 

  	local children = msg:children()
  	local last_type = 0
	for index,item in ipairs(children) do
	 	if item:name() == 'text' then
	 		--文本
			local str = item:value()
			if str ~= nil and str ~= "" then
				self:addText(str, item["@fontSize"], item["@color"])
			end
		elseif item:name() == 'img' then
			--找到了一张图片
			local img_path = item["@path"]
			if img_path == nil then
				img_path = item:value()
			end

			if img_path ~= nil then
				local scale = 1
				if item["@scale"] then
					scale = tonumber(item["@scale"])
				end
				self:addImg(img_path,scale)
			end
		end
	end
end

--添加一行
function v:addLine()
	self.now_line = self.now_line + 1
	self.line_width = 0
	table.insert(self.line_heights, 0)
	table.insert(self.line_nodes, {})
end

--添加文本
function v:addText(str, font_size, font_color)
	local font_size = font_size or self.defult_fontSize
	local font_color = font_color or self.defult_color
	local label = cc.Label:createWithSystemFont("", "Arial", font_size)
	label:setAnchorPoint(cc.p(0,0))
	if font_color then
		label:setColor(panel_util:GetColor4B(font_color))
	end
	self:addChild(label)
	--剩余的字符
	local surplus_str = ""
	local ss = utils:strSplit(str)
	for k1,v1 in pairs(ss) do
		if string.byte(v1) == 8 then
			--这个字符是特殊字符，要转换回去
			v1 = "<"
		end
	   	local now_str = label:getString()
	   	local add_str = now_str .. v1
	   	label:setString(add_str)
	   	if self.max_length > 0 and (self.line_width + label:getContentSize().width) > self.max_length then
	   		--这里这行满了要换行
	   		label:setString(now_str)
	   		--剩余的字符
	   		surplus_str = string.sub(str,string.len(now_str) + 1) 
			break
	   	else
	   		label:setString(add_str)
	   	end
	end
	
	local now_line_tb = self.line_nodes[self.now_line]
	if now_line_tb then
		self.line_width = self.line_width + label:getContentSize().width
		local now_height = self.line_heights[self.now_line]
		if now_height and now_height < label:getContentSize().height then
			self.line_heights[self.now_line] = label:getContentSize().height
		end
		table.insert(now_line_tb, label)
	end

	if surplus_str and surplus_str ~= "" then
		--有剩余的字符，说明换行了
		self:addLine()
		self:addText(surplus_str, font_size, font_color)
	end
end

--添加图片
function v:addImg(img_path, scale)
	local sp = cc.Sprite:createWithSpriteFrameName(img_path)
	sp:setAnchorPoint(cc.p(0,0))
	sp:setScale(scale or 1)
	self:addChild(sp)
	local width = sp:getContentSize().width * sp:getScale()
	local height = sp:getContentSize().height * sp:getScale()
	if self.max_length > 0 and (self.line_width + width) > self.max_length then
		--这里换行了
		self:addLine()
	end
	local now_line_tb = self.line_nodes[self.now_line]
	if now_line_tb then
		self.line_width = self.line_width + width
		local now_height = self.line_heights[self.now_line]
		if now_height and now_height < height then
			self.line_heights[self.now_line] = height
		end
		table.insert(now_line_tb, sp)
	end
end
 
function v:setString(str)  
	self.str = str 
	if self.str == "" then
		return
	end
	self:removeAllChildren()

	--每一行的node
	self.line_nodes = {}
	--每一行的高度
	self.line_heights = {}

	self.now_line = 0 
	self.height = 0

    self:addLine()
    self:ParsedXml(self.str)

    self:formarRenderers()
end

--整理每一行，进行排版
function v:formarRenderers()
	local all_height = 0
	local max_width = 0
	for k,line_node in pairs(self.line_nodes) do
		local end_x = 0
		local line_height = self.line_heights[k] + self.line_space
		all_height = all_height + line_height
		for k1,node in pairs(line_node) do
			local node_width = node:getContentSize().width * node:getScale()
			node:setPosition(cc.p(end_x, -all_height))
			end_x = end_x + node_width
		end

		if k <= 1 then
			max_width = end_x
		else
			--超过一行，当前行宽为最大宽度
			max_width = self.max_length
		end 
		
	end
	self.height = all_height
	self.width = max_width
end

return v