local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local lang_constants = require "util.language_constants"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"

local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local temple_logic = require "logic.temple"
local carnival_logic = require "logic.carnival"
local daily_logic = require "logic.daily"

local time_logic = require "logic.time"
local panel_util = require "ui.panel_util"
local magic_shop = require "logic.magic_shop"
local feature_config = require "logic.feature_config"

local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local SCENE_TRANSITION_TYPE = constants.SCENE_TRANSITION_TYPE

local MAX_REFREDH_TIME = 1
local SUB_PANEL_HEIGHT = 190

local recruit_panel = panel_prototype.New()
function recruit_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/recruit_panel.csb")
    local root_node = self.root_node

    self.list_view = self.root_node:getChildByName("list_view")

    self.auto_fire_btn = self.root_node:getChildByName("10times_btn")--自动解雇按钮
    self.auto_fire_icon = self.root_node:getChildByName("yes_icon")--自动解雇勾

    if self.auto_fire_icon then
        if feature_config:IsFeatureOpen("auto_fire_mercenary") then
            self.auto_fire_icon:setVisible(configuration:GetAutoFire())
        end
    end

    self.gold_coin_recruit_btn = self.list_view:getChildByName("coin_recruit")
    self.gold_coin_text = self.gold_coin_recruit_btn:getChildByName("coin_cost")

    self.blood_diamond_recruit_btn = self.list_view:getChildByName("blood_diamond_recruit")

    self.temple_recruit_btn  = self.list_view:getChildByName("temple")
    self.temple_cd_text = self.temple_recruit_btn:getChildByName("reset_time")

    self.friend_recruit_btn = self.list_view:getChildByName("friend_recruit")

    self.magic_recruit_btn = self.list_view:getChildByName("magic_recruit")
    self.magic_recruit_btn:setVisible(false)

    self.magic_recruit_time_text = self.magic_recruit_btn:getChildByName("timetip"):getChildByName("time") 
    self.magic_recruit_cost_text = self.magic_recruit_btn:getChildByName("blood_diamond_cost")
 
    self.top = self.magic_recruit_btn:getPositionY()

    self.recruit_sub_panels = {}
    self.recruit_sub_panels[1] = self.magic_recruit_btn
    self.recruit_sub_panels[2] = self.blood_diamond_recruit_btn
    self.recruit_sub_panels[3] = self.gold_coin_recruit_btn
    self.recruit_sub_panels[4] = self.friend_recruit_btn
    self.recruit_sub_panels[5] = self.temple_recruit_btn
    
    self.store_01_btn = self.list_view:getChildByName("store_01") --积分商店
    self.store_02_btn = self.list_view:getChildByName("store_02") --FYD限时积分商店
    if feature_config:IsFeatureOpen("magic_shop") then
        self.magic_recruit_btn2 = self.store_02_btn:getChildByName("magic_recruit")   
        self.store_02_time_text = self.store_02_btn:getChildByName("timetip"):getChildByName("time")
        self.store_02_btn:setVisible(false)

        self.store_01_time_text = self.store_01_btn:getChildByName("reset_time_0")
        
        table.insert(self.recruit_sub_panels, 3, self.store_02_btn)
        table.insert(self.recruit_sub_panels, self.store_01_btn)
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end


function recruit_panel:Show() 
    self.root_node:setVisible(true)
    self:UpdateCost()
    self.duration = time_logic:GetDurationToNextDay()
    
    self:UpdateMagicDoor()
    self.list_view:jumpToTop()
end

function recruit_panel:UpdateMagicDoor()
    --判断是否显示秘术召唤
    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["magic_door"])
    if conf and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["magic"], false) then
        self.magic_recruit_btn:setVisible(true)
        self.magic_recruit_cost_text:setString(tostring(conf.extra_num1))
    else
        self.magic_recruit_btn:setVisible(false)
    end

    --判断是否显示血钻召唤
    if feature_config:IsFeatureOpen("review") then
        self.blood_diamond_recruit_btn:setVisible(false)
    else
        self.blood_diamond_recruit_btn:setVisible(true)   
    end 

    --判断是否显示积分商店
    if self.store_01_btn then
        if feature_config:IsFeatureOpen("magic_shop") then
            self.store_01_btn:setVisible(true)
        else 
            self.store_01_btn:setVisible(false)
        end 
    end

    --判断是否显示限时积分商店
    if self.store_02_btn then 
        local time_info = magic_shop:GetShopTimeInfo()
        local cur_time = time_logic:Now() 
        if feature_config:IsFeatureOpen("magic_shop") and time_info and tonumber(time_info.end_time) > tonumber(cur_time) and tonumber(time_info.begin_time) <= tonumber(cur_time) then  --限时商店开启
            self.store_02_btn:setVisible(true)   
        else
            self.store_02_btn:setVisible(false)   
        end
    end

    --调整位置
    local index = 0
    for _,sub_panel in ipairs(self.recruit_sub_panels) do
        if sub_panel:isVisible() then
            sub_panel:setPositionY(self.top - index * SUB_PANEL_HEIGHT)
            index = index + 1
        end
    end
end

function recruit_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time

    if self.duration <= 0 then
        self.duration = time_logic:GetDurationToNextDay()
    end

    self.temple_cd_text:setString(panel_util:GetTimeStr(self.duration))

    local conf = carnival_logic:GetSpecialCarnival(client_constants.CARNIVAL_TEMPLATE_TYPE["magic_door"])
    if conf then
        local cur_time = time_logic:Now()
        self.magic_recruit_time_text:setString(panel_util:GetTimeStr(conf.end_time - cur_time))
    end

    if self.store_02_time_text then
        local time_info = magic_shop:GetShopTimeInfo()
        if time_info then
            local cur_time = time_logic:Now()
            self.store_02_time_text:setString(panel_util:GetTimeStr(time_info.end_time - cur_time))
        end
    end

    if self.store_01_time_text then
        --积分商城
        if magic_shop.needRestTime then --推送
            magic_shop.next_rest_time = magic_shop.needRestTime
        end

        if magic_shop.next_rest_time then 
            local cur_time = time_logic:Now()
            local  time = magic_shop.next_rest_time - cur_time
            
            if  time <= 0 then 
                time = 0
            end
            self.store_01_time_text:setString(panel_util:GetTimeStr(time))
        else
            self.store_01_time_text:setString(lang_constants:Get("next_reset_time_none"))
        end
    end
end

function recruit_panel:UpdateCost()
    panel_util:ConvertUnit(daily_logic:GetRecruitCost(), self.gold_coin_text)
end

function recruit_panel:RegisterEvent()
    graphic:RegisterEvent("recruit_mercenary", function(door_type)
        if not self.root_node:isVisible() then
            return
        end

        self:UpdateCost()
    end)
    graphic:RegisterEvent("update_feature_config", function()
        if not self.root_node:isVisible() then
            return
        end
        self:UpdateMagicDoor()
    end)
end

function recruit_panel:RegisterWidgetEvent()

    --自动解雇状态
    if self.auto_fire_btn then
        self.auto_fire_btn:addTouchEventListener(function(widget, event_type) 
            if event_type == ccui.TouchEventType.ended then
                if self.auto_fire_icon:isVisible() then
                    configuration:SetAutoFire(false)
                    self.auto_fire_icon:setVisible(false)
                else
                    configuration:SetAutoFire(true)
                    self.auto_fire_icon:setVisible(true)
                end
                configuration:Save()
            end
        end)
    end

    --金币招募
    self.gold_coin_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", client_constants.CONFIRM_MSGBOX_MODE["recruit_mercenary"], "recruiting_door")
        end
    end)

    --友情招募
    self.friend_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "friendship_recruit_msgbox")
        end
    end)

    --血钻招募
    self.blood_diamond_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "blood_diamond_recruit_msgbox")
        end
    end)

    --神殿
    self.temple_recruit_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["temple"]) then
                temple_logic:MercenaryQuery()
            end
        end
    end)

    --秘术招募
    self.magic_recruit_btn:getChildByName("magic_recruit"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "magic_recruit_msgbox")
        end
    end)
    
    if self.store_01_btn then
        --积分商店
        self.store_01_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                if magic_shop.needRestTime then
                    magic_shop.isShowScene = true
                    magic_shop:requireInfo() --重新发送请求
                else
                    graphic:DispatchEvent("show_world_sub_scene", "magic_shop_sub_scene",nil,false)--false  暂时只有非限时的酒馆
                end
            end
        end)
    end

    if self.magic_recruit_btn2 then
        --限时积分商店
        self.magic_recruit_btn2:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if not self.magic_shop_pannel then
                    self.magic_shop_pannel = require("ui.magic_shop_pannel").new(true)    
                end 
                self.magic_shop_pannel:Show(self.root_node)   
            end
        end)
    end
end

return recruit_panel
