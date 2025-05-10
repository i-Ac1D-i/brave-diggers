local json = require "util.json"
local audio_manager = require "util.audio_manager" 
local jump_logic = require 'logic.jump'
local lang_constants = require "util.language_constants"
local graphic = require "logic.graphic"
local network = require "util.network"
local client_constants = require "util.client_constants"
local utils = require 'util.utils'
local constants = require "util.constants"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local RESOURCE_TYPE_NAME = constants.RESOURCE_TYPE_NAME
local resource_config = config_manager.resource_config
local JUMP_CONST_TYPE = client_constants["JUMP_CONST_TYPE"] 
local JUMP_CONST = client_constants["JUMP_CONST"] 
local logic_arena = require('logic.arena')

local jump_panel = panel_prototype.New(true)
function jump_panel:Init()
    jump_logic.delegate = self 
    jump_logic:RegisterGraphEvent()
    self.root_node = cc.CSLoader:createNode("ui/resources_msgbox.csb") 
    self.root_node:setVisible(false) 

    self.bg = self.root_node:getChildByName("bg")
    self.origin_bg_size = self.bg:getContentSize()
    self.close_right_btn = self.bg:getChildByName("close_right_btn") 
    self.close_btn = self.bg:getChildByName("close_btn") 
    self.desc = self.bg:getChildByName("desc")
    self.title = self.bg:getChildByName("title")
    self.title_name_text = self.bg:getChildByName("title"):getChildByName("name") 
    self.item_list = self.bg:getChildByName("item_list") 
    self.origin_list_size = self.item_list:getContentSize()
    self.item_list:setItemsMargin(client_constants["JUMP_CONSTANCE"].jump_list_margin)   

    self.list_item_btn = self.item_list:getChildByName("list_item_btn") 
    self.list_item_btn:removeFromParent() 
    self.list_item_btn:retain()

    self.blood_replace_btn = self.item_list:getChildByName("list_item_btn2") 
    self.blood_replace_btn:removeFromParent() 
    self.blood_replace_btn:retain()

    self:RegisterWidgetEvent()
    self.close_btn:setTitleText(lang_constants:Get("jump_panel_bg_close_btn"))
    self.title_name_text:setString(lang_constants:Get("jump_panel_bg_title_name"))
    self.desc:setString(lang_constants:Get("jump_panel_bg_desc"))

    self.origin_bg_height = self.bg:getContentSize().height 
    self.visible_size = cc.Director:getInstance():getVisibleSize()

    self.center_pos = cc.p(self.visible_size.width/2,self.visible_size.height/2)
end

function jump_panel:Hide()
    self.root_node:setVisible(false) 
    graphic:DispatchEvent("hide_mask_node") 
end

function jump_panel:RegisterWidgetEvent()
    self.close_right_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                self:Hide()
            end
        end)

    self.close_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                self:Hide()
            end
        end)

    local touch_listener = cc.EventListenerTouchOneByOne:create()
    touch_listener:setSwallowTouches(true) 
    touch_listener:registerScriptHandler(function(touches, event)
        if self.root_node:isVisible() then
            return true
        else
            return false
        end
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touch_listener,self.root_node) 
end 

function jump_panel:Show(resource_id,lackNum)
    self.lack_num = lackNum
    if not RESOURCE_TYPE_NAME[resource_id] then
        return 
    end
    if self.root_node:isVisible() then  --解决显示两次问题
        return 
    end

    self.list_data = jump_logic:GetListData() 

    self.root_node:setVisible(true) 
    utils:performWithDelay(self.root_node, function()  
           graphic:DispatchEvent("show_mask_node")  
        end, 0.01)  
    self.resource_id = resource_id   
    self:UpdateList(self.resource_id,self.list_data)  
end

function jump_panel:Resume() 
    self.item_list:setInnerContainerSize(self.origin_list_size) 
    self.item_list:setContentSize(self.origin_list_size) 
    self.bg:setContentSize(self.origin_bg_size)  
end

function jump_panel:UpdateList(resource_id,list_data)   
    local data 
    for key,cur in ipairs(list_data) do 
        if cur["resource_id"] == resource_id then
           data = cur["value"] 
           break 
        end
    end
 
    if not data then
        return  
    end 
    table.sort(data,function(a,b) 
        local a_id = a.sort_id
        local b_id = b.sort_id
        if a.is_recommend > b.is_recommend then   --如果有推荐的话，id 减去个权重
            a_id = a_id - 1000
        elseif a.is_recommend < b.is_recommend then
            b_id = b_id - 1000
        end
        return a_id < b_id  --如果为true 则a前b后 
    end)

    local resource_name = resource_config[resource_id].name  
    self.title_name_text:setString(lang_constants:GetFormattedStr("jump_panel_bg_title_name", resource_name))

    self:Resume()
    self.list_items = {} 
    self.item_list:removeAllItems() 
    
    for _,aData in ipairs(data) do
        local temp = self.list_item_btn:clone()
        if aData.jump_id == JUMP_CONST["blood_replace"] then
            temp = self.blood_replace_btn:clone()
            temp:setName("blood_replace")
        end
        table.insert(self.list_items,temp) 
        self.item_list:pushBackCustomItem(temp)
        temp:setTitleText(aData.jump_name)  
        local recommend = temp:getChildByName("recommend_bg") 
        if recommend then
            recommend:setVisible(aData.is_recommend == 1)   
        end
        
        if not jump_logic:IsCanGoPanel(aData.jump_id,false) then  --如果该关卡没有解锁,改变按钮颜色
            temp:setBright(false)    --todo  需要美术将disable图片换成灰白色的      
        else
            temp:setBright(true)   
        end  

        temp:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                if not jump_logic:IsCanGoPanel(aData.jump_id,false) then  --如果该关卡没有解锁 
                    jump_logic:IsCanGoPanel(aData.jump_id,true) 
                else
                    if widget:getName() == "blood_replace" then
                    else
                        self:HidePanel()
                    end
                    
                    self:JumpTo(aData.jump_id,aData.blood_replace)
                end
            end
        end) 
    end  
    self.item_list:doLayout() 

    local inner_size = self.item_list:getInnerContainerSize()
    self.item_list:setContentSize(inner_size)  
    local dy = inner_size.height - self.origin_list_size.height 
    local new_size = cc.size(self.origin_bg_size.width,self.origin_bg_size.height+dy) 
    self.bg:setContentSize(new_size) 

    local top = new_size.height 
    self.title:setPositionY(new_size.height-10)  
    self.close_right_btn:setPositionY(new_size.height-30)
    self.desc:setPositionY(new_size.height-35)
    self.item_list:setPositionY(new_size.height-135)  
    local cur_size = self.bg:getContentSize() 
    local y = self.center_pos.y + cur_size.height/2
    self.bg:setPositionY(y) 
    
end

function jump_panel:HidePanel()
    self:Hide() 
    self:BeforeJump() 
end

function jump_panel:BeforeJump()
    graphic:DispatchEvent("hide_all_sub_panel")  
end
--跳转到指定界面
function jump_panel:JumpTo(pannel_id,blood_replace_pre)--第二个参数为血钻替代钻石的比率 
    if JUMP_CONST_TYPE[pannel_id] then 
       jump_logic:GoToPannel(pannel_id,self.resource_id,self.lack_num,blood_replace_pre)      
    end  
end 

return jump_panel
