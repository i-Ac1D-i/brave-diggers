local constants = require "util.constants"

local VISIBLE_SIZE_WIDTH = 640
local VISIBLE_SIZE_HEIGHT = 1136

local rtl_transition = 
{
    MAX_DURATION = 0.3
}

function rtl_transition:Init(world_scene)
    self.world_scene = world_scene

    self.duration = self.MAX_DURATION

    self.x_offset = VISIBLE_SIZE_WIDTH / self.MAX_DURATION

    world_scene.next_sub_scene:GetRootNode():setPosition(VISIBLE_SIZE_WIDTH, 0)

    world_scene.origin_event_dispatcher:setEnabled(false)
end

function rtl_transition:Update(elapsed_time)
    self.duration = self.duration - elapsed_time

    if self.world_scene.cur_active_sub_scene then
        local root_node = self.world_scene.cur_active_sub_scene:GetRootNode()
        root_node:setPositionX( root_node:getPositionX() - elapsed_time * self.x_offset)
    end

    local next_root_node = self.world_scene.next_sub_scene:GetRootNode()
    next_root_node:setPositionX( next_root_node:getPositionX() - elapsed_time * self.x_offset)

    if self.duration < 0 then
        next_root_node:setPositionX(0)
        self.world_scene:FinishChangeSubScene()
    end
end

local transition_manager = {}
function transition_manager:Init()

    VISIBLE_SIZE_WIDTH = cc.Director:getInstance():getVisibleSize().width
    VISIBLE_SIZE_HEIGHT = cc.Director:getInstance():getVisibleSize().height

    self.transitions = {}

    self.transitions[constants["SCENE_TRANSITION_TYPE"]["right_to_left"]] = rtl_transition
end

function transition_manager:GetTransition(trans_type)
    return self.transitions[trans_type]   
end

do
    transition_manager:Init()
end

return transition_manager
