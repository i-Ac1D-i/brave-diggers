local config_manager = require "logic.config_manager"
local adventure_logic = require "logic.adventure"
local troop_logic = require "logic.troop"
local constants = require "util.constants"

local maze_component = require "entity.maze"

local sub_scene = require "scene.sub_scene"
local graphic = require "logic.graphic"
local GR_EVENT_TYPE = graphic.EVENT_TYPE

local exploring_sub_scene = sub_scene.New()
function exploring_sub_scene:Init()

    self.root_node = cc.Node:create()

    self.root_node:registerScriptHandler(function(event)
        if event == "enter" then
            self.ui_root = require "ui.exploring_panel"
            self.ui_root:Init()
            self.root_node:addChild(self.ui_root:GetRootNode())

            self.maze_component = maze_component.New()
            self.maze_component:Init(self.ui_root.layer_node)

            self:RegisterEvent()
        end
    end)
end

function exploring_sub_scene:Show(area_id, difficulty)
    self.root_node:setVisible(true)

    self.ui_root:Show(area_id, difficulty)

    self.maze_component:LoadInfo()
end

function exploring_sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()

    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end

function exploring_sub_scene:Update(elapsed_time)
    self.maze_component:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

function exploring_sub_scene:RegisterEvent()
    graphic:RegisterEvent("change_troop_formation", function()
        self.maze_component:SetLoadMercenaryflag(false)
    end)

    graphic:RegisterEvent("update_exploring_merceanry_position", function()
        self.maze_component:SetLoadMercenaryflag(false)
    end)
end

return exploring_sub_scene
