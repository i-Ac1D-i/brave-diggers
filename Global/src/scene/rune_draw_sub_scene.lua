local graphic = require "logic.graphic"
local sub_scene = require "scene.sub_scene"

local rune_draw_sub_scene = sub_scene.New()

function rune_draw_sub_scene:Init()
    self.root_node = cc.Node:create()

    self:SetRememberFromScene(true)

    self.root_node:registerScriptHandler(function(event)
        if event == "enter" then
            self.ui_root = require "ui.rune_draw_panel"
            self.ui_root:Init()
            self.ui_root:Hide()
            self.root_node:addChild(self.ui_root:GetRootNode())
        elseif event == "exit" then

        end
    end)
end

function rune_draw_sub_scene:Show()
    self.root_node:setVisible(true)
    self.ui_root:Show()
end

function rune_draw_sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()
end

function rune_draw_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

return rune_draw_sub_scene
