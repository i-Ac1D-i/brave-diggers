local sub_scene = require "scene.sub_scene"
local audio_manager = require "util.audio_manager"

local pvp_sub_scene = sub_scene.New()

function pvp_sub_scene:Init()
    self.root_node = cc.Node:create()

    self.root_node:registerScriptHandler(function(event)
        if event == "enter" then
            self.ui_root = require "ui.pvp_main_panel"
            self.ui_root:Init()
            self.ui_root:Hide()

            self.root_node:addChild(self.ui_root:GetRootNode())

        elseif event == "exit" then

        end
    end)
end

function pvp_sub_scene:Show()
    self.root_node:setVisible(true)
    self.ui_root:Show()

    audio_manager:PlayMusic("pvp", true)
end

function pvp_sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()
end

function pvp_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

return pvp_sub_scene
