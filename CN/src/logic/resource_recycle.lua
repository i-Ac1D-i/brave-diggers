local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"

local utils = require "util.utils"

local user_logic
local time_logic
local resource_logic
local troop_logic

local resource_recycle = {}

function resource_recycle:Init()
    user_logic =  require "logic.user"
    time_logic = require "logic.time"
    resource_logic = require "logic.resource"

    self.temperature = 0  --温度百分比
    self.process = 0    --进度百分比

    self:RegisterMsgHandler()
end



--------------------------------------网络请求
function resource_recycle:AddMaterial(res_type, num)
    network:Send({ add_material = {materials = {{type = res_type, num = num}}} })
end

function resource_recycle:Query()
    network:Send({ query_resource_recycle = {} })
end

function resource_recycle:ClickPlayEnd(click_num)
    network:Send({ resource_recycle_click_finish = {click_times = click_num} })
end



--注册监听事件
function resource_recycle:RegisterMsgHandler()

    --查询冗余资源信息
    network:RegisterEvent("query_resource_recycle_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.temperature = recv_msg.temperature
            self.process = recv_msg.process
            graphic:DispatchEvent("query_resource_recycle_success")
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    --燃烧材料
    network:RegisterEvent("add_material_ret", function(recv_msg)
        if recv_msg.result == "success" then
            local up_temperature = recv_msg.temperature - self.temperature
            self.temperature = recv_msg.temperature
            local up_process = recv_msg.process - self.process  
            self.process = recv_msg.process
            graphic:DispatchEvent("add_material_success", recv_msg, up_temperature, up_process)
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)

    network:RegisterEvent("resource_recycle_click_finish_ret", function(recv_msg)
        if recv_msg.result == "success" then
            graphic:DispatchEvent("resource_recycle_click_finish_success", recv_msg.reward_list)
        else
            --其他结果
            graphic:DispatchEvent("show_prompt_panel", recv_msg.result)
        end
    end)
    
    
end

return resource_recycle
