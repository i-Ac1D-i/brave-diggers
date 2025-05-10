local audio_manager = require "util.audio_manager"
local panel_prototype = require "ui.panel"
local configuration = require "util.configuration"
local platform_manager = require "logic.platform_manager"

--下载子面板
local download_panel = panel_prototype.New()
function download_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/download_panel.csb")

    self.cur_version_text = self.root_node:getChildByName("version")

    self.update_node = self.root_node:getChildByName("update")

    self.download_lbar = self.update_node:getChildByName("lbar")
    self.next_version_text = self.update_node:getChildByName("next_version")
    self.percent_text = self.update_node:getChildByName("percent")
    self.percent_img = self.update_node:getChildByName("percent_icon")

    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.down_load_version_move_x then  --FYD  热更版本号文本向右移动  (解决覆盖问题)
        self.next_version_text:setPositionX(self.next_version_text:getPositionX() + channel_info.down_load_version_move_x) 
    end

    self.rotation = 0
end

function download_panel:Show()
    self.cur_version_text:setString("Version" .. configuration:GetVersion())

    self.update_node:setVisible(false)
    
    self.rotation = 0

    self.download_lbar:setPercent(0)
    self.percent_text:setString("0%")

    self.root_node:setVisible(true)
end

function download_panel:UpdateDownloadProgress(percent)
    self.download_lbar:setPercent(percent)
    self.percent_text:setString(percent .. "%")
end


function download_panel:UpdatePercentIcon(elapsed_time)
    if self.root_node:isVisible() then
        self.rotation = self.rotation + elapsed_time * 180
        self.percent_img:setRotation(self.rotation)
    end
end

function download_panel:ShowDownload(ver)
    self.update_node:setVisible(true)
    self.next_version_text:setString(ver)
end

return download_panel
