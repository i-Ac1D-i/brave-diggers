local troop_logic = require "logic.troop"
local graphic = require "logic.graphic"
local sub_scene = require "scene.sub_scene"

local formation_sub_scene = sub_scene.New()

function formation_sub_scene:Init()
    self.root_node = cc.Node:create()
    self:SetRememberFromScene(true)

    self.ui_root = require "ui.mercenary_formation_panel"
    self.ui_root:Init()

    self.root_node:addChild(self.ui_root:GetRootNode(), 0)
end

function formation_sub_scene:Show(tag, mode, back_panel, ex_params)
    self.root_node:setVisible(true)

    self.ui_root:Show(mode)
 
    self.ui_root:SetBackPanel(back_panel, ex_params)
end

function formation_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

function formation_sub_scene:ShowEx()
    self.root_node:setVisible(true)

    self.ui_root:ShowEx()
end

function formation_sub_scene:Hide(last_sub_scene)
    self.root_node:setVisible(false)

    self.ui_root:Hide(last_sub_scene)
end

return formation_sub_scene
