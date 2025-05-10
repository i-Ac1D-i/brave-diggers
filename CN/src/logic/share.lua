local network = require "util.network"
local constants = require "util.constants"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local platform_manager = require "logic.platform_manager"
local carnival_logic = require "logic.carnival"
local client_constants = require "util.client_constants"
local user_logic = require "logic.user"
local configuration = require "util.configuration"
local http_client = require "logic.http_client"
local json = require "util.json"
local lang_constants = require "util.language_constants"

local share = {}

function share:Init()

    self.share_state_lock = false
    --可领取积分
    self.can_reward_integral  = 0 
    --当前进度
    self.progress = nil 

    self.share_times = 0

    self.progress = nil

    self:RegisterMsgHandler()
end

function share:GetShareScore()
    return self.can_reward_integral
end

--查询分享状态
function share:QueryShareInfo()
    network:Send({ query_leading_integral = {} })
end

--领取分享积分
function share:GetLeadingIntegral()
    if self.can_reward_integral > 0 then
        network:Send({ get_leading_integral = {} })
    else
        graphic:DispatchEvent("show_prompt_panel", "get_leading_integral_no")
    end
end

function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

--当前点击次数
function share:GetClickCount()
    if self.progress then
        local progress = split(self.progress, "/")
        if progress[1] then
            return progress[1]
        end
    end
    return 0
end

--分享成功告诉服务器分享了一次
function share:shareSuccess()
    if self.share_times < constants.SHARE_TIMES then
        network:Send({ shared_success = {} })
    end
end

function share:startShare(platform_id)
    if not platform_manager:GetChannelInfo().share_url then
        return
    end
    if not self.share_state_lock then
        self.share_state_lock = true
        self.share_platform_id = platform_id

        local user_id = user_logic:GetUserId()
        local server_id = configuration:GetServerId()
        local role_name = user_logic.leader_name
        local channel = platform_manager:GetChannelInfo().name
        local post_data = {}
        post_data.app = "am"
        post_data.roleId = user_id
        post_data.serverId = server_id
        post_data.roleName = role_name
        post_data.accountId = user_id
        post_data.shareType = platform_id
        post_data.channel = channel

        local is_android = string.find(channel, "android")
        if is_android then
            post_data.platform = 0
        else
            post_data.platform = 1
        end

        --组合请求需要的参数
        local send_data = ""
        local i = 0
        for k,v in pairs(post_data) do
            i = i + 1
            if i == 1 then
                --第一个参数前面没有&这个符号
                send_data = send_data .. k .. "=" .. v
            else
                send_data = send_data .. "&" .. k .. "=" .. v
            end 
        end
        http_client:Post(platform_manager:GetChannelInfo().share_url, send_data, function(status_code, content)
            if status_code == 200 then
                local ret_msg = json:decode(content)
                if ret_msg then
                    self.url  = ret_msg.url
                    self:downImage(ret_msg.img)
                end
            else
                self.share_state_lock = false 
            end
        end)
    end
    
end

function share:downImage(url)
    local xml_http = cc.XMLHttpRequest:new()
    xml_http:open("GET", url)
    xml_http.responseType = 1
    xml_http:registerScriptHandler(function()
        if xml_http.readyState == 4 and xml_http.status == 200 then
            local str = cc.FileUtils:getInstance():getWritablePath().."share.jpg"

            local file = io.open(str, "w")

            for i,v in ipairs(xml_http.response) do
                file:write(string.char(v))
            end
            file:close() 

            PlatformSDK.startShare(self.share_platform_id, lang_constants:Get("share_title_text"), lang_constants:Get("share_desc_text"), self.url, url, str)
            self.share_state_lock = false 
        end
        self.share_state_lock = false 
        xml_http:unregisterScriptHandler()   
    end)
    xml_http:send()
end

function share:RegisterMsgHandler() 

    network:RegisterEvent("query_leading_integral_ret", function(recv_msg)

        --可领取积分
        self.can_reward_integral  = recv_msg.lead_nums  
        self.progress = recv_msg.progress           --当前的进度
        self.share_times = recv_msg.share_times         --分享次数
        --当前进度
        graphic:DispatchEvent("update_share_info_state")
    end)

    --领取返回
    network:RegisterEvent("get_leading_integral_ret", function(recv_msg)
        print("recv_msg.result = ",recv_msg.result)
        if recv_msg.result == "success" then
            self.can_reward_integral  = 0
            graphic:DispatchEvent("show_prompt_panel", "get_leading_integral_success")
            graphic:DispatchEvent("update_share_info_state")
        else
            graphic:DispatchEvent("show_prompt_panel", "get_leading_integral_failure")
        end
    end)

    --分享成功返回
    network:RegisterEvent("shared_success_ret", function(recv_msg)
        if recv_msg.result == "success" then
            self.can_reward_integral  = recv_msg.lead_nums  
            self.progress = recv_msg.progress           --当前的进度
            self.share_times = recv_msg.share_times         --分享次数
            graphic:DispatchEvent("update_share_info_state")
        end
    end)

    platform_manager:RegisterEvent("share_platform_result", function(status_code)
        if status_code == 0 then
            -- print("分享成功lua调用")
            self:shareSuccess()
        elseif status_code == 2 then
            --没有客户端
            graphic:DispatchEvent("show_prompt_panel", "share_no_client")
        else
            -- print("分享失败lua调用")
            graphic:DispatchEvent("show_prompt_panel", "share_failure")
        end
        graphic:DispatchEvent("share_callback", status_code)
    end)


end

return share
