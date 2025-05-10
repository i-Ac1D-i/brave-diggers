local scene_manager = require "scene.scene_manager"
local graphic = require "logic.graphic"
local spine_manager = require "util.spine_manager"
local user_logic = require "logic.user"
local platform_manager = require "logic.platform_manager"

local loading_scene = class("loading_scene", function()
    return cc.Scene:create()
end)

local IMG_TASK_LIST =
{
    { "ui/ui.png", "ui/ui.plist" },
    -- { "role/mercenary.png", "role/mercenary.plist" }, 
    { "ui/block.png", "res/ui/block.plist" },
    -- { "role/artifact.png", "role/artifact.plist" },
    { "ui/carnival.png", "ui/carnival.plist" },
    { "ui/icon.png", "ui/icon.plist" },
    { "ui/campaign.png", "ui/campaign.plist" }
}

local SINGLE_TASK_PROGRESS = 20

function loading_scene:ctor(next_scene_name)
    self.next_scene_name = next_scene_name
    self.stop_query_to_login = false

    self:registerScriptHandler(function(event)
        if event == "enter" then
            self.spine_node = spine_manager:GetNode("loading")
            self.spine_node:setPosition(320, 568)

            self:addChild(self.spine_node)

            self.spine_node:setSkin(tostring(math.random(1, 6)))
            self.spine_node:setAnimation(0, "animation", true)

            self.progress = 0
            self.next_progress = 0

            --根据语言包更新大图
            self:UpdateImgTaskListWithLanguage()

            SINGLE_TASK_PROGRESS = 100 / (#IMG_TASK_LIST + 1)

            local texture_cache = cc.Director:getInstance():getTextureCache()

            cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile("login.plist")
            texture_cache:removeTextureForKey("ui/login.png")

            if self.next_scene_name == "world" then
                for i = 1, #IMG_TASK_LIST do

                    local img = IMG_TASK_LIST[i][1]
                    local plist = IMG_TASK_LIST[i][2]

                    cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(plist)
                    texture_cache:removeTextureForKey(img)

                    texture_cache:addImageAsync(img, function(texture)
                        self.next_progress = self.next_progress + SINGLE_TASK_PROGRESS
                        texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

                        cc.SpriteFrameCache:getInstance():addSpriteFrames(plist)
                    end)
                end
            elseif self.next_scene_name == "login" then
                scene_manager:ChangeScene(self.next_scene_name)
                return
            end

            self:RegisterEvent()

        elseif event == "exit" then
            spine_manager:DestroyNode("loading")
            self:removeAllChildren()
        end
    end)
end

function loading_scene:Update(elapsed_time)

    if self.stop_query_to_login then
        self.stop_query_to_login = false
        local network = require "util.network"
        network:Disconnect()
        scene_manager:ChangeScene("login")

    elseif self.next_scene_name ~= "login" then
        user_logic:PollQueryMsg()  --FYD3  每帧都会调用队列查询

        if self.progress < self.next_progress then
            self.progress = math.min(self.progress + SINGLE_TASK_PROGRESS * elapsed_time, self.next_progress)
            self.progress = math.ceil(self.progress)
        end

        if self.progress >= 100 then
            self.progress = 0
            scene_manager:ChangeScene(self.next_scene_name)
        end
    end
end

function loading_scene:Forward()
    self.next_progress = self.next_progress + SINGLE_TASK_PROGRESS
end

function loading_scene:UpdateImgTaskListWithLanguage()

    local mercenary_img_path = string.format("language/%s/role/mercenary.png", platform_manager:GetLocale())
    local mercenary_plist_path = string.format("language/%s/role/mercenary.plist", platform_manager:GetLocale())
    if not cc.FileUtils:getInstance():isFileExist(mercenary_img_path) or not cc.FileUtils:getInstance():isFileExist(mercenary_plist_path) then
        mercenary_img_path = "role/mercenary.png"
        mercenary_plist_path = "role/mercenary.plist"
    end

    local artifact_img_path = string.format("language/%s/role/artifact.png", platform_manager:GetLocale())
    local artifact_plist_path = string.format("language/%s/role/artifact.plist", platform_manager:GetLocale())
    if not cc.FileUtils:getInstance():isFileExist(artifact_img_path) or not cc.FileUtils:getInstance():isFileExist(artifact_plist_path) then
        artifact_img_path = "role/artifact.png"
        artifact_plist_path = "role/artifact.plist"
    end

    table.insert(IMG_TASK_LIST, { mercenary_img_path, mercenary_plist_path })
    table.insert(IMG_TASK_LIST, { artifact_img_path, artifact_plist_path })
end

function loading_scene:RegisterEvent()
    graphic:RegisterEvent("lost_connection", function()
        scene_manager:ChangeScene("login")
    end)

    graphic:RegisterEvent("user_finish_query_info", function()
        if scene_manager.current_scene_name == "loading" then
            self:Forward()
        end
    end)

    graphic:RegisterEvent("loading_scene_signout", function()
        if scene_manager:GetCurrentSceneName() == "loading" then
            self.stop_query_to_login = true
        end
    end)
end

return loading_scene
