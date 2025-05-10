local user_logic = require('logic.user') 
local audio_manager = require "util.audio_manager"
local platform_manager = require "logic.platform_manager"
local network = require "util.network"
local graphic = require "logic.graphic"
local utils = require('util.utils')
local chat_lang = require("locale."..platform_manager:GetLocale()).RAW_STR 
local v = class("chat_pannel",function() 
        return ccui.Layout:create() 
    end)

function v:ctor(root_node,hot_arean) 
    self.root_node = root_node
    self.hot_arean = hot_arean  
    hot_arean:setLocalZOrder(99) 
    self:registerEvent(hot_arean) 

    local parent = root_node:getParent()
    parent:removeChild(root_node)
    self:addChild(root_node) 
    self.root_node = root_node 

    self.click_chat = root_node:getChildByName('Text_126') 
    
    --底框
    self.bottom_bar = root_node:getChildByName('bottom_bar')  
    self.bottom_bar:setLocalZOrder(9) 
    --输入
    self.input_msg_layout = self.bottom_bar:getChildByName('input_msg_layout')  
    local size = self.input_msg_layout:getContentSize()  

    self.input_msg = ccui.TextField:create("","general.ttf",35)  ----FALJSDFJALSDFJAIOJSDFLJ
    self.input_msg:setAnchorPoint(cc.p(0,0))  
    self.input_msg:setTouchAreaEnabled(true)  
    self.input_msg:ignoreContentAdaptWithSize(true)  
    self.input_msg:setTouchAreaEnabled(true) 
    self.input_msg:setString("") 

    self.cursor = self.bottom_bar:getChildByName('mouse')
    self.cursor:setAnchorPoint(cc.p(0,0))
    self.cursor:setPosition(cc.p(0,0)) 
    self.cursor:removeFromParent()
    self.input_msg:addChild(self.cursor)  
    self.cursor:runAction(cc.RepeatForever:create(cc.Blink:create(1,1)))   
  
    self.input_msg_layout:addChild(self.input_msg)   
    local invok_layout = root_node:getChildByName('invok_layout') 
    invok_layout:setLocalZOrder(20)   
       
    self.invok_input = invok_layout:getChildByName('invok_input')  
    self.invok_input:setOpacity(0) 
    self:invokeInuptEvent();
    --列表
    self.list_view_retain = root_node:getChildByName('list_view') 
     --时间
    self.time_text = self.list_view_retain:getChildByName('time_text')
    self.time_text:setPosition(cc.p(0,0)) 
    self.time_text:retain()
    self.list_view_retain:removeChild(self.time_text)    
    self.list_view_size = self.list_view_retain:getContentSize() 
    self.mutext_list_view = {} 
    self.mutext_list_view["world"] = self.list_view_retain:clone() 
    self.mutext_list_view["local"] = self.list_view_retain:clone()
    self.mutext_list_view["union"] = self.list_view_retain:clone()
    self.mutext_is_scrolling = {} 
    for k,v in pairs(self.mutext_list_view) do
         root_node:addChild(v)     

            v:addEventListener(function(lview, event_type)
                if event_type == ccui.ScrollViewEventType.scrolling then
                    if not self.mutext_is_scrolling[k] then
                        print('FYD  Scrolling') 
                        self.mutext_is_scrolling[k] = true
                    end
                else
                    if self.mutext_is_scrolling[k] then  
                        self.mutext_is_scrolling[k] = false 
                    end
                end
        end)

    end 
    root_node:removeChild(self.list_view_retain)
    
  
    self.world_btn = root_node:getChildByName("world"):getChildByName("world_btn") 
    self.local_btn = root_node:getChildByName("local"):getChildByName("local_btn") 
    self.union_btn = root_node:getChildByName("union"):getChildByName("union_btn") 
    self.types_bg = {}
    self.types_bg["world"] = root_node:getChildByName("world"):getChildByName("Image_204") 
    self.types_bg["local"] = root_node:getChildByName("local"):getChildByName("Image_204") 
    self.types_bg["union"] = root_node:getChildByName("union"):getChildByName("Image_204") 

    self:setCurrentMode("world")

    self.world_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
             self:setCurrentMode("world") 
        end
    end)
    self.local_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
             self:setCurrentMode("local")  
        end
    end)
    self.union_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
             self:setCurrentMode("union") 
        end
    end)
 
    --发送按钮
    self.send_btn = self.bottom_bar:getChildByName('send_btn')  
    self.bottom_bar:setSwallowTouches(false) 
    self.send_btn:setSwallowTouches(false) 

    self.bottom_bar:setLocalZOrder(999) 
    self.send_btn:setOpacity(0) 
    self.send_bg = self.bottom_bar:getChildByName('send_bg')
    self.send_bg:setSwallowTouches(false)    
     
    self.bottom_bar:setVisible(false)   
    self:sendMessageEvent() 

    --网络事件
    self:networkEvent()  
    


    self.origin_pos = cc.p(self:getPosition()) 
    self.target_pos = cc.p(self.origin_pos.x+620,self.origin_pos.y)
    self:setPosition(self.target_pos) 

    self.back_icon = root_node:getChildByName('back_icon')
    self.back_btn = self.back_icon:getChildByName('back_btn_hoearea')  
    self.chat_btn = root_node:getChildByName('chat_btn')
    self.green_point = self.chat_btn:getChildByName('remind_icon_0')  
    self.green_point:setVisible(false)    
    self.mutext_btn = {self.chat_btn,self.back_icon} 
    self.mutext_state = "close"
    self:setButtonState("close") 
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:hide()
        end
    end)
    self.chat_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:show()
        end
    end)

    self.cd_time = 0
end

function v:setCurrentMode(mode) 
    if self.mode == mode then
        return 
    end
    self.mode = mode  
    --list_view 选择
    for k,v in pairs(self.mutext_list_view) do
        if k == mode then
            self.list_view = v 
            v:setVisible(true) 
            v:setLocalZOrder(2)
        else
            v:setVisible(false) 
            v:setLocalZOrder(1)    
        end    
    end
    --button背景
    for k,v in pairs(self.types_bg) do  
         if k == mode then
            v:setVisible(false) 
         else
            v:setVisible(true)   
         end
     end 
end

function v:networkEvent()
    local time_size = self.time_text:getContentSize() 
    network:RegisterEvent("coze_record_append_ret", function(recv_msg)
        -- print("coze_record_append_ret")
           if recv_msg.result == "success" then
                -- print('发送成功')
           else
                if recv_msg.type == 1 then

                    self:setTip(chat_lang["forbide_chat"]or "禁言中")   
                elseif recv_msg.type == 2 then
                    self:setTip(chat_lang["have_forbide_words"]or "含有屏蔽字")
                    return      
                end
           end
        end) 

    network:RegisterEvent("user_coze_update_ret", function(recv_msg)
         print("user_coze_update_ret")
            local msg = recv_msg.newMessage
            local mode = recv_msg.type
            local language = recv_msg.language
            --如果消息为本地类型,那么语言类型不同的屏蔽 
            if mode == "local" and (self:getLocalLanguage() ~= language) then  
                return 
            end
            --如果工会ID不相同，屏蔽
            if mode == "union" then  
                local guild_logic = require "logic.guild"
                if guild_logic.guild_id  ~= recv_msg.guildID then
                    return 
                end
            end
            local rep_str = require("locale."..language).RAW_STR["not_in_guild"]   
            msg = string.gsub(msg,rep_str,chat_lang["not_in_guild"])      

            local list_view =  self.mutext_list_view[mode]
            local layout = ccui.Layout:create()
            local time_txt = self.time_text:clone()
            time_txt:getChildByName("Text_118"):setString(recv_msg.time)  
            layout:addChild(time_txt)  
            local rich_text = require('ui.URichText').new(self.list_view_size.width-30)    
            rich_text:setData(msg)  
            rich_text:setPosition(cc.p(0,time_size.height+1))   
            layout:addChild(rich_text) 
            layout:setContentSize(cc.size(self.list_view_size.width,time_size.height + rich_text:getContentSize().height+1)) 
            layout:setVisible(false)
            list_view:pushBackCustomItem(layout)
            if 50 <= #list_view:getItems() then--
                list_view:removeItem(0) 
            end

            local utils = require('util.utils')
            utils:performWithDelay(self,function() 
                --判断当前是否处于移动状态
                if self.mutext_is_scrolling[mode] then  --如果当前是处于移动状态的
                    return 
                end
                local show = cc.Show:create()
                local place = cc.MoveBy:create(0,cc.p(0,-30)) 
                
                local fade_in = cc.FadeIn:create(0.2)
                local mv = cc.MoveBy:create(0.2,cc.p(0,30)) 
                mv = cc.EaseOut:create(mv,1.5)
                local spwan = cc.Spawn:create(fade_in,mv) 
                local seq = cc.Sequence:create(place,show,spwan) 
                layout:runAction(seq)   
                list_view:scrollToBottom(0.01,false)   --移动到底部     
                end,0.01) 

            self.green_point:setVisible(true)  
    end) 
end

function v:setTip(str)
    local channel_info = platform_manager:GetChannelInfo()
    local font_file = channel_info.font_file
    local tip_size = channel_info.tip_size
    local not_exit_guild_text = cc.Label:createWithTTF(str,font_file,tip_size)  
    not_exit_guild_text:setMaxLineWidth(500) 
    not_exit_guild_text:setLineBreakWithoutSpace(true) 
    not_exit_guild_text:setTextColor(cc.c4b(255,255,0,255))  
    self:getParent():addChild(not_exit_guild_text) 
    local v_size = cc.Director:getInstance():getVisibleSize()
    not_exit_guild_text:setPosition(cc.p(v_size.width/2,v_size.height/2+100))  
    local fade = cc.FadeOut:create(1) 
    local mv = cc.MoveBy:create(1,cc.p(0,100))
    local remove = cc.CallFunc:create(function(node) 
            local parent = node:getParent();
            parent:removeChild(node,true)
        end)
    local seq = cc.Sequence:create(mv,remove)  
    
    local spawn = cc.Spawn:create(seq,fade)  
    not_exit_guild_text:runAction(spawn)     
end

function v:sendMessageEvent()
    self.send_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
             local utils = require('util.utils')
             if utils:trim(self.invok_input:getString()) == "" then     
                return 
             end

             if self.cd_time > 0 then
                self:setTip(chat_lang["time_cd_tip"]or "两次间隔不能小于10s")           
                return 
             end
             if #utils:strSplit(self.invok_input:getString()) > 128 then
                self:setTip(chat_lang["chat_forbid_msg_length"]or "消息不能超过128个字符")
                return             
             end

            local guild_logic = require "logic.guild"
            if self.mode == "union" and (not guild_logic.guild_id) then  
                ---提示该玩家没有工会 FYD
                local str = chat_lang["chat_not_guild_id"] or "该玩家没有工会"
                self:setTip(str)             
                return 
            end
            
            self.bottom_bar:setVisible(false)   

            local str = self.input_msg:getString()
            self.input_msg:setString("") 
            self.invok_input:setString("")
            self.input_msg:setPosition(cc.size(0,0)) 
            self.cursor:setPosition(cc.p(0,0)) 
            
            
            local channel_info = platform_manager:GetChannelInfo()
            local font_file = channel_info.font_file
            local font_size = channel_info.chat_font_size
            local font_color =  channel_info.font_color
            local role_font_size = channel_info.role_font_size
            local union_font_size = channel_info.union_font_size
            local input_font_size = channel_info.input_font_size
            
            local msg1,msg2 = self:generalFormatMessage(role_font_size,union_font_size,input_font_size,font_file,font_size,font_color,str) 
            --------cceee
            network:Send({coze_record_append = {type = self.mode,language = self:getLocalLanguage(),newMessage = msg2,guildID = guild_logic.guild_id}}) 
            utils:performWithDelay(self,function() 
                    self.cd_time = 0  
                end,10) 
 
            self.cd_time = 10   --聊天CD
        end
    end) 
end

function v:invokeInuptEvent()
    self.invok_input:addEventListener(function(widget, event_type)
        if event_type == ccui.TextFiledEventType.attach_with_ime then
             -- print('attach_with_time')
            local pos = cc.p(self.bottom_bar:getPosition())
            pos.y = pos.y + 350
            -- self.bottom_bar:setPosition(pos) 
            local mv = cc.MoveTo:create(0.05,pos)   
            self.bottom_bar:runAction(mv) 

            self.bottom_bar:setVisible(true)  
        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
            -- print('dettach_with_time') 
            local pos = cc.p(self.bottom_bar:getPosition())
            self.bottom_bar:setVisible(false)   
            pos.y = pos.y - 350
            -- self.bottom_bar:setPosition(pos)  
            local mv = cc.MoveTo:create(0.05,pos) 
            self.bottom_bar:runAction(mv)  

        elseif event_type == ccui.TextFiledEventType.insert_text or event_type == ccui.TextFiledEventType.delete_backward then
            local font_file = "general.ttf"
            local font_size = platform_manager:GetChannelInfo().chat_font_size
            local font_color =  platform_manager:GetChannelInfo().font_color
            -- local msg1,msg2 = self:generalFormatMessage(font_file,font_size,font_color,self.invok_input:getString()) 
            --local msg1,msg2 = self:generalFormatMessage(font_file,font_size,font_color,"Each player may only raise 1 report per day. Reports are considered carefully by our customer service team. Continue?") 
           
            if event_type == ccui.TextFiledEventType.insert_text and #utils:strSplit(self.invok_input:getString()) > 128 then
                self:setTip(chat_lang["chat_forbid_msg_length"]or "消息不能超过128个字符")
                return
            elseif event_type == ccui.TextFiledEventType.delete_backward and #utils:strSplit(self.invok_input:getString()) > 128 then
                self.invok_input:setString(self.input_msg:getString())                            
            end

            self.input_msg:setString(self.invok_input:getString()) 
            local cur_size = self.input_msg:getAutoRenderSize()
            local cont_size = self.input_msg_layout:getContentSize()
  
            local dwidth = cur_size.width - (cont_size.width - 30) 
            if dwidth >= 0 then  --需要移动位置了
                local new_pos = {}
                new_pos.y = self.input_msg:getPositionY()
                new_pos.x = - dwidth
                self.input_msg:setPosition(new_pos)  
            end
            self.cursor:setPosition(cc.p(cur_size.width,0)) 

        end
    end)
end

function v:getLocalLanguage()  
    return platform_manager:GetLocale()  
end


function v:generalFormatMessage(role_font_size,union_font_size,input_font_size,font_file,font_size,text_color,msg)  
    local guild_logic = require "logic.guild"
    local union_name =  guild_logic.guild_name    
    if not union_name then  --To Do  
         union_name = chat_lang["not_in_guild"] or "未加入工会"   
    end
    local role = string.format("%s ",user_logic:GetUserLeaderName())  
    local role_color = '#FFFF00' 
    
    local format_msg = ""
    local format_msg2 = ""
    local format1 = string.format("<text color='%s' fontName='%s' fontSize='%s'>",text_color,font_file,input_font_size)  
    format_msg = format_msg .. format1
    local format1_x = string.format("<text color='%s' fontName='%s' fontSize='%s'>",text_color,font_file,font_size)  
    format_msg2 = format_msg2 .. format1_x

    local format2 = string.format("<text fontSize='%d' title='true' color='%s'>%s</text>",role_font_size,role_color,role)  --role
    format_msg2 = format_msg2 .. format2

    local format2_x = string.format("<text fontSize='%d' title='true'>  %s</text>",union_font_size,union_name)   --工会
    format_msg2 = format_msg2 .. format2_x


    local format3 = string.format("<text>%s</text>",msg)
    format_msg = format_msg .. format3 
    format_msg2 = format_msg2 .. format3
    local end_str = "</text>" 
    format_msg = format_msg .. end_str
    format_msg2 = format_msg2 .. end_str
 
    return format_msg,format_msg2
end

function v:registerEvent(hot_arean)
    local onTouchBegan = function(touch, event) 
        local location = touch:getLocation()
        self.pos_begin = location 
        pos = hot_arean:convertToNodeSpace(location)
         
        local size = hot_arean:getContentSize() 
        local rect = cc.rect(0,0,size.width,size.height)
        local isContain = cc.rectContainsPoint( rect, pos )
        return isContain 
    end

    local onTouchMoved = function(touch, event) 
        -- print('FYD--moved') 
    end

    local onTouchEnded = function(touch, event)  
        local location = touch:getLocation()
         local distance_x =  location.x - self.pos_begin.x 
         local distance_y =  location.y - self.pos_begin.y 
         if math.abs(distance_y) > math.abs(distance_x) then
            return 
         end
         if distance_x >= 100 then
            self:hide() 
         elseif distance_x <= -100 then
            self:show()
         end
    end

    --创建一个单点触屏事件
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false) 
    --注册触屏开始事件
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    --注册触屏移动事件
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    --注册触屏结束事件
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    --获取层的事件派发器
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher() 
    --事件派发器 注册一个node事件   
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,hot_arean)   

end

function v:setButtonState(state) 
    if state == "open" then
        self.mutext_btn[2]:setVisible(true)
        self.mutext_btn[1]:setVisible(false)
    elseif state == "close" then
        self.mutext_btn[1]:setVisible(true)
        self.mutext_btn[2]:setVisible(false)
    end
end

function v:show(time)
    if self.mutext_state == "openning" or self.mutext_state == "open" then
        return 
    end

    if not time then
        time = 0.3
    end
    chat_lang = require("locale."..platform_manager:GetLocale()).RAW_STR
    --切换语言的时候更改翻译
    self.click_chat:setString(chat_lang["chat_invoke_input"]or "点击发言")  
    self.root_node:getChildByName("world"):setString(chat_lang["chat_world"]or "世界") 
    self.root_node:getChildByName("local"):setString(chat_lang["chat_local"]or "本地")
    self.root_node:getChildByName("union"):setString(chat_lang["chat_union"]or "公会")
    self.send_bg:setTitleText(chat_lang["chat_send_btn"]or "发送")


    self.mutext_state = "openning"
    self:setButtonState("open") 
    local func = cc.CallFunc:create(function() 
         self.mutext_state = "open"
         self.green_point:setVisible(false)  
        end)
    local mv = cc.MoveTo:create(time,self.origin_pos)
    local seq = cc.Sequence:create(mv,func) 
    seq:setTag(999) 
    self:stopActionByTag(999)  
    self:runAction(seq) 
end

function v:hide(time)
    if self.mutext_state == "closing" or self.mutext_state == "close" then
        return 
    end

    if not time then
        time = 0.3
    end
    self.green_point:setVisible(false) 
    self.mutext_state = "closing"
    self:setButtonState("close")  
    local func = cc.CallFunc:create(function() 
        self.mutext_state = "close" 
        self.bottom_bar:setVisible(false)    
        end)
    local mv = cc.MoveTo:create(time,self.target_pos) 
    local seq = cc.Sequence:create(mv,func)
    seq:setTag(999) 
    self:stopActionByTag(999)  
    self:runAction(seq)    
end





return v 