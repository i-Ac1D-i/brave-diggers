local network = require "util.network"
local config_manager = require "logic.config_manager"
local time_logic = require "logic.time"
local json = require "util.json" 
local graphic = require "logic.graphic"
local lang_constants = require "util.language_constants"
local resource_logic 
local magic_shop = {}
function magic_shop:Init()
    resource_logic = require "logic.resource"
	self.shop_info = nil   
	--self.need_reload = nil 
	
	self.magic_shop_exist = {}
	self.limit_times = nil
	self.forever_times = nil
	self.next_rest_time = nil --这个是请求酒馆信息的时候的
	self.time_info = nil

	self.isShowScene = false -- 要不要打开面板scene
	self.isRefresh = false -- 本地数据是不是刷新了
	self.needRestTime = nil --如果到刷新点服务器会推送

	self:RegisterEvent()  
end

function magic_shop:GetLimitedShopInfo()
	return self.shop_info["limit_magic_shop_list"]
end

function magic_shop:GetForeverShopInfo()
	return self.shop_info["forever_magic_shop_list"] 
end

function magic_shop:RebuildTimes(times)
    if not times then
        return {}
    end
    local temp = {}
    for _,conf in ipairs(times) do
         temp[conf.mercenary_id] = conf.times
    end
    return temp 
end

function magic_shop:requireInfo()
	network:Send({query_mogic_shop_info = {}})
end

function magic_shop:RegisterEvent()
	--查询积分商城的信息
    network:RegisterEvent("query_mogic_shop_info_ret", function(recv_msg) 
	        self.shop_info = recv_msg.shop   --商店信息 
            self.limit_times = self:RebuildTimes(recv_msg.limit_times)   --限时酒馆的购买
            self.forever_times = self:RebuildTimes(recv_msg.forever_times)   --永久酒馆的已购买的佣兵剩余购买的次数
            self.next_rest_time = recv_msg["next_rest_time"]   --永久酒馆佣兵次数剩余重置时间
            self.time_info = self.shop_info["timer"] --商店更新时间
            self.isRefresh = true
    		if self.isShowScene == true then 
    			self.isShowScene = false
	            graphic:DispatchEvent("show_world_sub_scene", "magic_shop_sub_scene",nil,false)
    		end
            -- if self.need_reload then
            -- 	self.need_reload()
            -- 	self.need_reload = nil 
            -- end
        end) 
        --积分数量更新
    network:RegisterEvent("update_magic_gold_ret", function(recv_msg) 
        if recv_msg.count > 0 then
            self:RunAnimation(recv_msg.count)   
        end  
        graphic:DispatchEvent("update_magic_gold")   
    end)
    	--获取开启时间 （之前的版本用于限时酒馆，现在没用）
   	network:RegisterEvent("get_carnival_time_info_ret", function(recv_msg)
			if not recv_msg then
				return 
			end 
			 local time_info = recv_msg
			 if not time_info.end_time then
			 	return 
			 end 

			 if self.time_info and tonumber(self.time_info.end_time) ~= 0 then  --本地时间是否存在
			 	if self.time_info.end_time ~= time_info.end_time then  --如果结束时间不相同，则需要重新刷新shop_config 
			 		self.need_reload = self.call_back  
			 	else
			 		self.need_reload = nil   
			 	end
			 else --则需要拉取积分商城的shop_config
			 	if time_info.end_time ~= 0 then  --如果服務器上有新的活動
				 	self.need_reload = self.call_back  
				 	self.time_info = time_info  
				end
			 end
			 if not self.need_reload then
			 	self.call_back () 
			 else 
			 	self.magic_shop_exist["limit"] = true 
			 	self.magic_shop_exist["forever"] = true 
			 	network:Send({query_mogic_shop_info = {}})
			 end
		end)

   	network:RegisterEvent("refresh_times_reset", function(recv_msg)
   		self.needRestTime = recv_msg["next_rest_time"]

   	end)
end

function magic_shop:RunAnimation(d_count)  
	local opcity_begin = 0.2
	local time1 = 0.4
	local dy1 = 400
	local time2 = 0.35
	local dy2 = 400
	local scene =  cc.Director:getInstance():getRunningScene()
	local sp = cc.Sprite:create("ui/icon/recruit/points_02_small.png") 
	sp:setOpacity(255*opcity_begin) 
	local win_size = cc.Director:getInstance():getVisibleSize()
    sp:setPosition(win_size.width/2,win_size.height/2-100)  
	scene:addChild(sp,9999) 

	local light = cc.Sprite:create("ui/bg/light_effect002.png")
	local sp_size = sp:getContentSize()
	sp:addChild(light) 
	light:setPosition(cc.p(sp_size.width/2+80,sp_size.height/2+5)) 
	light:setOpacity(0) 

    sp:setGlobalZOrder(20) 

	local utils = require('util.utils')
	local mv_up1 = utils:getJumpInMv(time1,cc.p(0,dy1))
  
	local fadeIn = cc.FadeIn:create(time1)  
 
	local spwan1 = cc.Spawn:create(mv_up1,fadeIn) 

	local light_func = cc.CallFunc:create(function()
		  local fade_in =	cc.FadeIn:create(0.3) 
 
		  local scale = cc.ScaleTo:create(0.3,9,7,1)  
		  local spwan = cc.Spawn:create(fade_in,scale) 
		  local fade_out = cc.FadeOut:create(0.4) 
		  local seq = cc.Sequence:create(spwan,fade_out) 

		  light:runAction(seq)  
	 end)  

	local delay = cc.DelayTime:create(0.8)  

 	local mv_up_bounce = utils:getEaseInMv(0.3,cc.p(0,15))

 
	local mv_up2 = utils:getJumpOutMv(time2,cc.p(0,dy2)) 
	local fadeOut = cc.FadeOut:create(time2) 
  
	local spwan2 = cc.Spawn:create(mv_up2,fadeOut) 
	local func = cc.CallFunc:create(function( tar )
		tar:removeFromParent()
	end)
	local seq = cc.Sequence:create(spwan1,light_func,mv_up_bounce,delay,spwan2,func)  
	sp:runAction(seq) 

	local label = cc.Label:createWithTTF(string.format(lang_constants:Get("mercenary_magic_add"),d_count), "ui/fonts/general.ttf", 25)
	label:enableOutline(cc.c4b(0,0,0,255),3)   
	label:setTextColor(cc.c4b(255,215,0,255)) 
    label:setAnchorPoint(cc.p(0,0.5))   
    
    
 	label:setOpacity(255*opcity_begin) 
 	scene:addChild(label,9999)
 	label:runAction(seq:clone())  

 	light:setPosition(cc.p(sp_size.width/2+25 +label:getContentSize().width/2,sp_size.height/2+5)) 
 	local width_2  = sp_size.width/2 + label:getContentSize().width/2 

 	sp:setPosition(win_size.width/2 - width_2 + 20 ,win_size.height/2-100)

 	local x,y = sp:getPosition() 
 	label:setPosition(cc.p((x+sp:getContentSize().width/2 ),y ))  
end

function magic_shop:GetCarnivalTimeInfo(call_back)
	self.call_back = call_back
	network:Send({get_carnival_time_info = {}}) 
end

function magic_shop:GetEndTime()
	return self.time_info.end_time
end

function magic_shop:GetShopTimeInfo()
	if tonumber(self.time_info.end_time) == 0 then
		return nil 
	end 
	return self.time_info   --end_time  begin_time 
end

--在这里判断限时积分商城是否已经关闭  这里已经不用了   效率太低  
function magic_shop:Update(elapsed_time)
	-- if not self.limit_shop_time then
	-- 	local cur_time = time_logic:Now()
	--  	-- self.limit_shop_time
	-- end
	
end

return magic_shop