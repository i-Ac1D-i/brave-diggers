local sub_scene = require "scene.sub_scene"
local audio_manager = require "util.audio_manager"

local mercenary_sub_scene = sub_scene.New()

function mercenary_sub_scene:Init()
    self.root_node = cc.Node:create()

    self.ui_root = require "ui.mercenary_main_panel"
    self.ui_root:Init()

    self.root_node:addChild(self.ui_root:GetRootNode(), 0)
end

function mercenary_sub_scene:Show()
    self.root_node:setVisible(true)
    self.ui_root:Show()

    audio_manager:PlayMusic("mercenary", true)
end

function mercenary_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

return mercenary_sub_scene

