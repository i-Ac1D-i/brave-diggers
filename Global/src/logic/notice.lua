local network = require "util.network"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"

local notice = {}
local channel_info = platform_manager:GetChannelInfo()

function notice:Init()
    self.notice_info = 
    {
        title = "",
        desc = "",
    }
    
    self.can_open_notice = false
    self.has_new_notice = false

    self:RegisterMsgHandler()
end

function notice:GetNoticeInfo()
    return self.notice_info
end

-- 是否主动弹公告
function notice:OpenNotice()
    local channel = platform_manager:GetChannelInfo()
    if channel.notice_url then
        --有公告URL 还要根据不同的平台来判断是否主动打开公告
        if channel.meta_channel == "qikujp" then
            return true
        end
    end

    return self.can_open_notice
end

function notice:HasNewNotice()
    return self.has_new_notice
end

function notice:SetNewNotice(has)
    self.has_new_notice = has
end

function notice:RegisterMsgHandler()
    network:RegisterEvent("query_notice_info_ret", function(recv_msg)
        print("query_notice_info_ret")

        for k, v in pairs(recv_msg) do
            self.notice_info[k] = v
        end

        local last_time = configuration:GetNoticePublishTime()
        if last_time ~= self.notice_info["time"] then
            self.can_open_notice = true
            self.has_new_notice = true
        end

        if channel_info.notice_url then
            self.has_new_notice = true
        end

        configuration:SetNoticePublishTime(self.notice_info["time"])
    end)
end

return notice
