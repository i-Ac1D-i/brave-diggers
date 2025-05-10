local utils = require('util.utils')
local client_constants = require "util.client_constants"
local look_img = client_constants["CHAT_IMG_PATH"]
local panel_util = require "ui.panel_util"
local rech_text = require "ui.RichLableText"
local lang_constants = require "util.language_constants"

local INPUT_TYPE = {
	text = 1,
	img = 2,
}

local input_widget = {}
input_widget.__index = input_widget

function input_widget.New()
    return setmetatable({}, input_widget)
end	

function input_widget:Init(text_field, text_field_parent, font_size, place_holder) 
	self.last_type = INPUT_TYPE.text
	self.text_field = text_field
	self.text_field_parent = text_field_parent
	self.text_field:setOpacity(0)
	self.old_str = ""
	self.place_holder = place_holder or lang_constants:Get("input_widget_place_holder")
	--一个滚动容器
	self.scroll_view = ccui.ScrollView:create()
	self.scroll_view:setTouchEnabled(false)
	self.scroll_view:setContentSize(self.text_field:getContentSize())

	self.text_field:addChild(self.scroll_view)
	--当前输入的数组，用来删除用的
	self.input_strs = {} 
	font_size = font_size or 30
	--自己输入的富文本标签
	self.text_field_text =  rech_text.new("",self.text_field:getContentSize().width,font_size)
	self.scroll_view:addChild(self.text_field_text)

	--记录当前输入框的位置
	self.start_pos_y = self.text_field:getPositionY()
	if self.text_field_parent then
		self.start_pos_y = self.text_field_parent:getPositionY()
	end


	self.text_field:addEventListener(function (sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then 
         
	         if self.input_layer then
	         	self.input_layer:stopAllActions()
	         	self.input_layer:runAction(cc.MoveTo:create(0.25,cc.p(self.input_layer:getPositionX(),self.input_layer_pos_y + (1136/2 - self.start_pos_y))))
	         elseif self.text_field_parent then
	         	self.text_field_parent:setPositionY(1136/2)
	         else
	         	self.text_field:setPositionY()
	         end

        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
	        if self.input_layer then
	        	self.input_layer:stopAllActions()
	         	self.input_layer:runAction(cc.MoveTo:create(0.25,cc.p(self.input_layer:getPositionX(),self.input_layer_pos_y)))
	        elseif self.text_field_parent then
	         	self.text_field_parent:setPositionY(self.start_pos_y)
	        else
	         	self.text_field:setPositionY(self.start_pos_y)
	        end 
        elseif eventType == ccui.TextFiledEventType.insert_text then
			local str = self.text_field:getString()
			local now_length = string.len(str)
			local old_length = string.len(self.old_str)
			local input_str = string.sub(str,old_length + 1)
			local now_input_str_arry = utils:strSplit(input_str)
			for k,v in pairs(now_input_str_arry) do
				local input_word = v
				if v == "<" then
					--这个字符要进行转换后使用，不然不能被解析
					input_word = string.char(8)
				end
				table.insert(self.input_strs, input_word) 
			end
            self:InputChange()
            
        elseif eventType == ccui.TextFiledEventType.delete_backward then  
            local now_str = self.text_field:getString()
            self:DeleteOne()
        end 
    end)
end

function input_widget:setInputLayer(layer)
	self.input_layer = layer
	if self.input_layer then
		self.input_layer_pos_y = self.input_layer:getPositionY()
	end
end

function input_widget:InputChange()
	--当前输入框的信息变化了
    local str = self.text_field:getString()
    self.old_str = str
   	local color = "0xffffff"
    if str == "" then
    	self.input_strs = {}
    	--这个是空字符要显示提示文字
    	str = self.place_holder
    	color = "0x515C68"
    else
    	str = ""
    	for k,v in pairs(self.input_strs) do
			str = str .. v
		end
    end

    local str = "<text><text color='"..color.."' >"..str.."</text></text>"
    self.text_field_text:setString(str)
    self.text_field_text:setPositionY(self.text_field_text.height - 5)
end

function input_widget:DeleteOne()
	if #self.input_strs <= 0 then
		return
	end
	table.remove(self.input_strs,#self.input_strs)
	local remove_end_str = ""
	for k,v in pairs(self.input_strs) do
		remove_end_str = remove_end_str .. v
	end
	self.text_field:setString(remove_end_str)
	self:InputChange()
end

--添加一个图片
function input_widget:InsertImage(image_src)
	local str = self.text_field:getString()
	local insert_str = "</text><img>"..image_src.."</img><text>"
	table.insert(self.input_strs, insert_str) 
	self.text_field:setString(str..insert_str)
	self:InputChange()
end

--得到当前的输入
function input_widget:getString()
	local str = self.text_field:getString()
    if str == "" or str == nil then
        return ""
    end
    str = ""
    
    for k,v in pairs(self.input_strs) do
		str = str .. v
	end

	str = "<text><text>"..str.."</text></text>"
	return str
end

function input_widget:setString(str)
	self.text_field:setString(str)
	self:InputChange()
end

--设置默认的提示文字
function input_widget:setPlaceHolder(place_holder)
	self.place_holder = place_holder
end

--隐藏键盘
function input_widget:setDetachWithIME(flat)
	self.text_field:setDetachWithIME(flat)
end

return input_widget