

local panel_prototype = require "ui.panel"

local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"

local PLIST_TYPE = ccui.TextureResType.plistType

local single_reward_panel = panel_prototype.New()
single_reward_panel.__index = single_reward_panel

function single_reward_panel.New()
    return setmetatable({}, single_reward_panel)
end

function single_reward_panel:Init(root_node)

    self.root_node = root_node
    self.parent_node = self.root_node:getParent()
    self.icon_img = self.root_node:getChildByName("reward_icon")
    self.value_text = self.root_node:getChildByName("reward_value")
    self.root_node:setVisible(false)

    self.spine_node = spine_manager:GetNode("maze_txt")
    self.spine_node:setVisible(false)

    self.parent_node:addChild(self.spine_node, 300)
    self.spine_tracker = spine_node_tracker.New(self.spine_node, "txt")
end

function single_reward_panel:LoadIcon(resource)
    self.icon_img:loadTexture(resource, PLIST_TYPE)
end

function single_reward_panel:SetString(str)
    self.value_text:setString(str)
end

function single_reward_panel:ToBindNode()
    self.spine_node:setVisible(true)
    self.spine_tracker:Bind("txt", "txt_alpha", 255, 1000, self.root_node)
end

function single_reward_panel:Update(elapsed_time)
    self.spine_tracker:Update()
end

function single_reward_panel:IsSpineVisible()
    return self.spine_node:isVisible()
end

return single_reward_panel
