require "cocos.init"

local common_function = require "util.common_function"

local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()

_G["cclog"] = function(...)
    print(string.format(...))
end

local cclog = _G["cclog"]

function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end


--C++回调函数
function applicationDidEnterBackground()
    local scene = cc.Director:getInstance():getRunningScene()
    if scene and scene.__name == "world" then
        scene:DidEnterBackground()
    end
end

--C++回调函数
function applicationDidEnterForeground()
    local scene = cc.Director:getInstance():getRunningScene()
    if scene and scene.__name == "world" then
        scene:DidEnterForeground()
    end
end

-- 收到消息推送
function MessageReceive()
end

local platform_manager = require "logic.platform_manager"
local director = cc.Director:getInstance()

local function main()
    local init = function()
        local time_logic = require "logic.time"
        time_logic:Init()

        local shader_manager = require "util.shader_manager"
        shader_manager:Init()

        local scene_manager = require "scene.scene_manager"
        scene_manager:Init()

        if _G["HAS_DOWNLOADED_PATCH"] then
            scene_manager:ChangeScene("login")
        else
            scene_manager:ChangeScene("download")
        end
    end

    local channel = platform_manager:GetChannelInfo()
    local configuration = require "util.configuration"

    if channel.show_agreement and not configuration:GetAcceptAgreement() then
        local scene = cc.Director:getInstance():getRunningScene()
        local agreement_panel = require "ui.agreement_panel"
        agreement_panel:Init()

        scene:addChild(agreement_panel:GetRootNode(), 2)
        agreement_panel:Show(function()
            configuration:SetAcceptAgreement(true)
            configuration:Save()
            init()
        end)

    else
        init()
    end
end

if _G["NEED_RELOAD"] then
    _G["NEED_RELOAD"] = false
    platform_manager:Init()

    local status, msg = xpcall(main, __G__TRACKBACK__)
    if not status then
        error(msg)
    end

else
    local configuration = require "util.configuration"
    configuration:Init()

    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    -- initialize director
    local glview = director:getOpenGLView()
    if not glview then
        glview = cc.GLViewImpl:createWithRect("Adventure&Mining", cc.rect(0, 0, 640, 1000), 1.0)
        director:setOpenGLView(glview)
    end

    director:setDisplayStats(false)
    director:setAnimationInterval(1.0 / 60)

    math.randomseed(os.time())

    local CheckDecompress = function()
        local file_util = cc.FileUtils:getInstance()

        --检测是否为第一次启动
        if TARGET_PLATFORM == cc.PLATFORM_OS_WINDOWS or TARGET_PLATFORM == cc.PLATFORM_OS_MAC or TARGET_PLATFORM == cc.PLATFORM_OS_LINUX then
            file_util:addSearchPath("res")
            file_util:addSearchPath("res/ui")

        else
            local writable_path = file_util:getWritablePath()
            local do_decompress = aandm.needDecompress()

            if do_decompress then
                local str = cc.FileUtils:getInstance():getStringFromFile("assets.manifest")
                local file = io.open(writable_path .. "project.manifest", "w")
                file:write(str)
                file:close()

                local str = cc.FileUtils:getInstance():getStringFromFile("version.manifest")
                local file = io.open(writable_path .. "version.manifest", "w")
                file:write(str)
                file:close()

                local file_list = {
                                    "data.zip", "data.mu",
                                    "adventure.zip", "battle_background.zip",
                                    "ui.zip", "effect.zip", "role.zip",
                                    "shader.zip", "fonts.zip", "sound.zip",
                                    "spine.zip", "particle.zip", "animation.zip",
                                    "language.zip"
                                }
                --zip文件全部解压到目标文件夹中
                for _, file_name in ipairs(file_list) do
                    if not aandm.decompress(file_name, writable_path) then
                        print("decompress err", file_name)
                    end
                end
            end

            file_util:addSearchPath(writable_path)
            file_util:addSearchPath(writable_path .. "res")
            file_util:addSearchPath(writable_path .. "res/ui")
        end

        if type(platform_manager:GetChannelInfo().locale) == "table" then
            if platform_manager:GetChannelInfo().meta_channel == "r2games" then
                common_function.CopyFile(string.format("res/ui/fonts/%s.ttf", platform_manager:GetChannelInfo().locale[1]), string.format("res/ui/fonts/general.ttf"))
            elseif platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then

            else
                common_function.CopyFile(string.format("res/ui/fonts/%s.ttf", platform_manager:GetLocale()), string.format("res/ui/fonts/general.ttf"))
            end
        end
    end

    local scene = cc.Scene:create()

    local CreateLogo = function()

        local time = 0
        local channel = platform_manager:GetChannelInfo()

        local color_node, logo_sprite

        if channel.has_logo then
            PlatformSDK.CreateLogo()

        else
            color_node = cc.DrawNode:create()
            scene:addChild(color_node)

            local visible_size = cc.Director:getInstance():getVisibleSize()
            local half_width = visible_size.width/2
            local half_height = visible_size.height/2

            color_node:drawSolidRect({x = 0, y = 0}, {x = visible_size.width, y = visible_size.height}, { r = 1, g =1, b=1, a=1})

            if channel.meta_channel == "r2games" then
                logo_sprite = cc.Sprite:create("res/ui/logo_r2game.png")
            elseif channel.meta_channel == "txwy" then
                logo_sprite = cc.Sprite:create("res/ui/logo_txwy.png")
            elseif channel.meta_channel == "txwy_dny" then
                logo_sprite = cc.Sprite:create("res/ui/logo_playcomet.png")
            else
                logo_sprite = cc.Sprite:create("res/ui/logo.png")
            end

            logo_sprite:setPosition(half_width, half_height)
            scene:addChild(logo_sprite, 1)
        end

        local schedule_id = 0
        local finish_logo = false

        schedule_id = director:getScheduler():scheduleScriptFunc(function(elapsed_time)
            if finish_logo then
                return
            end

            time = time + elapsed_time
            if time >= 1.0 then
                --停止
                finish_logo = true
                director:getScheduler():unscheduleScriptEntry(schedule_id)

                local glview = director:getOpenGLView()
                glview:setDesignResolutionSize(640, 1136, cc.ResolutionPolicy.SHOW_ALL)

                if color_node then
                    color_node:clear()
                end
                
                if logo_sprite then
                    logo_sprite:setVisible(false)
                end

                local status, msg = xpcall(main, __G__TRACKBACK__)
                if not status then
                    error(msg)
                end
            end

        end, 0, false)
    end

    scene:registerScriptHandler(function(event)
        if event == "enter" then
            platform_manager:Init()

            if TARGET_PLATFORM == cc.PLATFORM_OS_IPHONE or TARGET_PLATFORM == cc.PLATFORM_OS_IPAD then
                CheckDecompress()

                local glview = director:getOpenGLView()
                glview:setDesignResolutionSize(640, 1136, cc.ResolutionPolicy.SHOW_ALL)

                local status, msg = xpcall(main, __G__TRACKBACK__)
                if not status then
                    error(msg)
                end

            elseif TARGET_PLATFORM == cc.PLATFORM_OS_WINDOWS or TARGET_PLATFORM == cc.PLATFORM_OS_MAC or TARGET_PLATFORM == cc.PLATFORM_OS_LINUX then
                --停留一段时间
                _G["HAS_DOWNLOADED_PATCH"] = true
                CheckDecompress()
                CreateLogo()
                
            elseif TARGET_PLATFORM == cc.PLATFORM_OS_ANDROID then
                --停留一段时间
                CheckDecompress()
                CreateLogo()
            end

        elseif event == "exit" then
            scene:removeAllChildren()
        end
    end)

    cc.Director:getInstance():replaceScene(scene)
end
