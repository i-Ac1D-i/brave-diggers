local client_constants = require "util.client_constants"
local config_manager = require "logic.config_manager"
local mercenary_config = config_manager.mercenary_config
local magic_shop = require("logic.magic_shop") 
local network = require "util.network"
local graphic = require "logic.graphic"
local mercenary_library_config = config_manager.mercenary_library_config
local SORT_RANGE = client_constants["SORT_RANGE"]
local lang_constants = require "util.language_constants"
local resource_logic = require "logic.resource"
local utils = require('util.utils') 

local panel_prototype = require "ui.panel"
 local magic_shop_pannel = panel_prototype.New()

function magic_shop_pannel:Init()
	self.root_node = cc.CSLoader:createNode("ui/points_store.csb") 
	self.root_node:setVisible(false) 
	self.title_bg = self.root_node:getChildByName("title_bg")
	self.title_text = self.title_bg:getChildByName("name") 
	self.count_text = self.root_node:getChildByName("bottom_bar"):getChildByName("value_all")
	self.sort_btn = self.root_node:getChildByName("bottom_bar"):getChildByName("sort_btn")  
 	self.scroll_view = self.root_node:getChildByName("scroll_view")   
	self.scroll_view:getInnerContainer():ignoreAnchorPointForPosition(true)  
	self.scroll_view:getInnerContainer():setAnchorPoint(cc.p(0,1)) 
	self.rolebg_template = self.scroll_view:getChildByName("rolebg")

	self.rule_icon_btn = self.root_node:getChildByName("rule_icon")
	self.back_btn = self.root_node:getChildByName("back_btn") 
	-- self.rolebg_template:setAnchorPoint(cc.p(0,1))  
	self.rolebg_template:retain()
	self.scroll_view:removeChild(self.rolebg_template)   
	self:RegisterEvent() 
	--self:ResetShopInfo()

end

function magic_shop_pannel:SetCurrentMercenary(item)
	if self.cur_item then
		self.cur_item:ResetState()  
	end
	self.cur_item = item  
end

function magic_shop_pannel:UpdateCountText(count)
	self.cur_count = resource_logic:GetResourcenNumByName("magic_gold") or 0  
	self.count_text:setString(tostring(self.cur_count))    
end

function magic_shop_pannel:RegisterEvent()
	self:UpdateCountText()  
    --兑换佣兵返回
    network:RegisterEvent("get_mercenary_ret", function(recv_msg) 
    	local utils = require('util.utils')
        if recv_msg.result ~= "success" then
        	graphic:DispatchEvent("show_prompt_panel", recv_msg.result) 
            return 
        end

        self.cur_item:RefreshRduceText()  

 		graphic:DispatchEvent("show_world_sub_panel", "reward_panel") 

        local name = mercenary_config[tonumber(recv_msg.mercenary_id)]["name"]  
         graphic:DispatchEvent("show_prompt_panel", "magic_shop_recruit_success", name)
    end)

    graphic:RegisterEvent("get_mercenary", function(id,is_limit)     
            local str = "forever"
            if is_limit then 
                str = "limit"
            end

            network:Send({get_mercenary = {mercenary_id = id,shop_id = str}})   
    	end) 
    graphic:RegisterEvent("update_magic_gold", function()     
            self:UpdateCountText() 
    	end) 

    self.sort_btn:addTouchEventListener(function(widget, event_type)
			if event_type == ccui.TouchEventType.ended then
		 		graphic:DispatchEvent("show_world_sub_panel", "mercenary_detail_panel", "magic_shop", self.cur_item.info.ID,nil,self.cur_item.info.cost,self.is_limit,self.cur_count)  
			end
		end)
	self.back_btn:addTouchEventListener(function(widget, event_type)
			if event_type == ccui.TouchEventType.ended then
			    graphic:DispatchEvent("hide_world_sub_scene", "magic_shop_sub_scene")   
			end
		end) 

	self.rule_icon_btn:addTouchEventListener(function(widget, event_type)
			if event_type == ccui.TouchEventType.ended then
			    graphic:DispatchEvent("show_world_sub_panel", "point_rule_msgbox")    
			end
		end)
	graphic:RegisterEvent("hide_magic_shop_pannel", function(count)     
            graphic:DispatchEvent("hide_world_sub_scene", "magic_shop_sub_scene")   
    	end)
end

function magic_shop_pannel:ResetShopInfo()
	self.cur_item = nil 
	self:CreateRoles(self.is_limit)  
end

function magic_shop_pannel:Show(is_limit)
	self.root_node:setVisible(true) 
	self.is_limit = is_limit
	local str = "forever" 
	
	self.title_text:setString(lang_constants:Get("forever_magic_shop_title")) 
	if self.is_limit then
		str = "limit"
		self.title_text:setString(lang_constants:Get("limit_magic_shop_title")) 
	end

	self:UpdateCountText() 

	if magic_shop.isRefresh == true then --如果数据更新
		magic_shop.isRefresh = false 
		self:ResetShopInfo()    
	end
end

function magic_shop_pannel:IsMercenaryInShop(shop,mercenary_id) 
	mercenary_id = tostring(mercenary_id) 
	local data = nil  
	for k,conf in pairs(shop) do 
		if conf.mercenary_id == mercenary_id then
			data = conf
			break
		end
	end
	return data
end

function magic_shop_pannel:CreateRoles(is_limit) 
	self.mutext_items = {} 
	local shop_info 
	if is_limit then
		shop_info = magic_shop:GetLimitedShopInfo()
	else
		shop_info = magic_shop:GetForeverShopInfo()
	end
 	  
	self.mercenary_list ={} 
	for i, mercenary in pairs(mercenary_library_config) do
	 	local conf = self:IsMercenaryInShop(shop_info,mercenary.ID)
 		if conf then
 			mercenary.cost = conf.cost 
 			mercenary.times = conf.times
 			mercenary.order = conf.order
 			table.insert(self.mercenary_list,mercenary) 
 		end 
    end

 	--列表排序
	table.sort(self.mercenary_list , function( a,b)
		return a.order < b.order
	end)
	
	self.scroll_view:removeAllChildren()  --移除所有

	local size = self.rolebg_template:getContentSize() 
	local dx = 20  --间隔
	local dy = 45 
	local px = 90  --偏移
	local py = 100
	local index = 0 
	for k,mercenary in pairs(self.mercenary_list) do 
	    local item = require('ui.role_item').new(self.rolebg_template:clone(),is_limit) 
	    if not self.cur_item then
	    	self.cur_item = item 
	    	item.root_node:setScale(1.1) 
	    end
	    item:setDelegate(self) 
	    self.scroll_view:addChild(item.root_node)  
	    table.insert(self.mutext_items,item)
	    local reduc
	    if is_limit then
	    	reduce = magic_shop.limit_times[tostring(mercenary.ID)] or mercenary.times
	    else
	    	reduce = magic_shop.forever_times[tostring(mercenary.ID)] or mercenary.times
	    end

 		if reduce then
 			mercenary.times = reduce
 		end
	    item:InitInfo(mercenary)  
	    local x_num = (index % 4)+1
	    local x = (x_num-1) * (size.width+dx)   

	    local y_num = math.floor(index / 4) + 1
	    local y = (y_num-1) * (size.height + dy) 
	    x = x + px
	    y = y + py
	    item.root_node:setPosition(cc.p(x,-y))  
	    item:RegisterEventListener()    
	    index = index + 1
	end	
	local height = (math.floor(index / 4)+1) * (size.height+dy) +py  
	local origin_size = self.scroll_view:getContentSize()
	self.scroll_view:setInnerContainerSize(cc.size(origin_size.width,height)) 
	self.scroll_view:getInnerContainer():setPosition(cc.p(0,100))    

	utils:performWithDelay(self.scroll_view, function() 
			self.scroll_view:scrollToTop(2,true) 
		end, 0.1) 

end

return magic_shop_pannel