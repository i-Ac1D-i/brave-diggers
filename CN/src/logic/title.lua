local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local utils = require "util.utils"
local client_constants = require "util.client_constants"
local feature_config = require "logic.feature_config"
local troop_logic
local title = {}

function title:Init()
        troop_logic = require "logic.troop"
        self.has_green = false
        self.cur_title_id = 0
        self.title_config = utils:merge(config_manager.title_config)
        self:RegisterMsgHandler()
end

function title:Update()
    graphic:DispatchEvent("update_title_limit_time")
end

function title:GetProperty()
   local property = {bp=0,speed=0,defense=0,dodge=0,authority=0} 
   for i,data in ipairs(self.title_config) do
        if data.state and data.state >= client_constants["TITLE_STATE"]["actived"] then
           property.bp = property.bp + data.bp
           property.speed = property.speed + data.speed
           property.defense = property.defense + data.defense
           property.dodge = property.dodge + data.dodge
           property.authority = property.authority + data.authority
        end
   end
   return property
end

function title:RegisterMsgHandler()
    network:RegisterEvent("query_title_ret", function(recv_msg)
        self.cur_title_id = 0
        if recv_msg.cur_title_id then
            self.cur_title_id = recv_msg.cur_title_id
        end
        local title_forevers = recv_msg.title_forevers or {}
        local title_limits = recv_msg.title_limits or {}
        local titles = utils:merge(title_forevers,title_limits) 
        self:GeneralTitleData(titles) 
        troop_logic:UpdateTitleProperty() 
    end)

    network:RegisterEvent("wear_title_ret", function(recv_msg)
        if recv_msg.result == "success" then
            --改变之前的佩戴状态为激活状态
            if self.cur_title_id ~= 0 then
                local order = self:GetTitleData(self.cur_title_id)
                self.title_config[order].state = client_constants["TITLE_STATE"]["actived"]
            end
            --通知按钮显示更改
            local title_id = recv_msg.title_id
            order = self:GetTitleData(title_id)
            self.title_config[order].state = client_constants["TITLE_STATE"]["wear"]
            self.cur_title_id = title_id
            self:Sort() 
            graphic:DispatchEvent("update_title_btn_title")
        else
            graphic:DispatchEvent("show_prompt_panel", "title_wear_failer")
        end
    end)

    network:RegisterEvent("active_title_ret", function(recv_msg)
        if recv_msg.result == "success" then
            --通知按钮显示更改
            local title_id = recv_msg.title_id
            local order = self:GetTitleData(title_id)
            self.title_config[order].start_time = data.start_time 
            local state = client_constants["TITLE_STATE"]["actived"]
            self.title_config[order].state = state
            self:Sort() 
            graphic:DispatchEvent("update_title_btn_title") 
        else
            graphic:DispatchEvent("show_prompt_panel", "title_active_failer")
        end
    end)

    network:RegisterEvent("refresh_title", function(recv_msg)
        self.has_green = true
        local data = recv_msg.new_title
        local title_id = data.title_id
        local state = data.state
        local order = self:GetTitleData(title_id)
        self.title_config[order].start_time = data.start_time 
        self.title_config[order].state = state
        self:Sort()

        troop_logic:UpdateTitleProperty() 
        --通知按钮显示更改
        graphic:DispatchEvent("update_title_btn_title") 
    end)
end

function title:CheckGreen()
    return self.has_green
end

function title:GetCurrentTitleID()
    return self.cur_title_id
end

function title:Sort()
    table.sort(self.title_config,function(a,b)
        local a_order = math.abs(a.order - 100) 
        local b_order = math.abs(b.order - 100) 
        local a_weight = a.state or 0
        a_order = a_order + 1000 * a_weight
        local b_weight = b.state or 0
        b_order = b_order + 1000 * b_weight

        return a_order > b_order
     end)
end

function title:Clear()
    for i,data in ipairs(self.title_config) do
        data.state = nil
        data.start_time = nil
    end
end

function title:GeneralTitleData(titles)
    self:Clear()
    for i,data in ipairs(titles) do
        local title_id = data.title_id
        self.title_config[title_id].start_time = data.start_time 
        self.title_config[title_id].state = data.state
    end
    self:Sort()
end

function title:GetTitleData(title_id)
    local r_order = 0
    for order,data in ipairs(self.title_config) do
        if title_id == data.ID then
            r_order = order
            break
        end
    end
    return r_order
end

function title:WearTitle(title_id)
    network:Send({wear_title = {title_id = title_id}}) 
end

function title:ActiveTitle(title_id)
    network:Send({active_title = {title_id = title_id}}) 
end



return title