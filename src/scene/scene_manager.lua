local time_logic = require "logic.time"
local graphic = require "logic.graphic"

package.loaded["util.spine_manager"] = nil
package.loaded["util.animation_manager"] = nil

local spine_manager = require "util.spine_manager"
local animation_manager = require "util.animation_manager"

local scene_manager =
{
}

function scene_manager:Init()
    self.current_scene_name = ""

    local director = cc.Director:getInstance()

    self.schedule_id = director:getScheduler():scheduleScriptFunc(function(elapsed_time)
        --先更新时间
        time_logic:Update(elapsed_time)

        local scene = director:getRunningScene()
        if scene and scene.Update then
            scene:Update(elapsed_time)
        end

    end, 0, false)
end

function scene_manager:ChangeScene(scene_name, ...)
    graphic:BindEventListener()
    spine_manager:Clear()
    animation_manager:ClearAll()

    cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)

    local scene = require("scene." .. scene_name .. "_scene", ...).new(...)
    scene.__name = scene_name
    self.current_scene_name = scene_name
    cc.Director:getInstance():replaceScene(scene)

    return scene
end

function scene_manager:GetCurrentSceneName()
    return self.current_scene_name
end

function scene_manager:PushScene(scene_name)
    local scene = require("scene." .. scene_name .. "_scene").new()
    cc.Director:getInstance():pushScene(scene)
end

function scene_manager:Clear()
    if self.schedule_id then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schedule_id)
    end
end

return scene_manager
