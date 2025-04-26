local scene_mananger = require "scene.scene_manager"
local audio_manager = require "util.audio_manager"
local configuration = require "util.configuration"
local lang_constants = require "util.language_constants"

local download_scene = class("download_scene", function()
    return cc.Scene:create()
end)

local function DoExit()
    cc.Director:getInstance():endToLua()
end

local function DeleteFile()
    local file_util = cc.FileUtils:getInstance()

    local writable_path = file_util:getWritablePath()
    file_util:removeFile(writable_path .. "project.manifest")
    file_util:removeFile(writable_path .. "project.manifest.temp")
end

function download_scene:ctor()
    self:registerScriptHandler(function(event)
        if event == "enter" then
            self.ui_root = require "ui.download_panel"
            self.ui_root:Init()
            self:addChild(self.ui_root:GetRootNode())

            self.msgbox = require "ui.simple_msgbox"
            self.msgbox:Init()
            self.msgbox:Hide()
            self:addChild(self.msgbox:GetRootNode())

            self.has_decompress_err = false

            self:CreateAssetsManager()
            self.ui_root:Show()

            self.assets_manager:update()

        elseif event == "exit" then
            if self.assets_manager then
                self.assets_manager:release()
                self.assets_manager = nil
            end

            self:removeAllChildren()
        end
    end)
end

function download_scene:Update(elapsed_time)
    if self.ui_root then
        self.ui_root:UpdatePercentIcon(elapsed_time)
    end
end

--创建更新器
function download_scene:CreateAssetsManager()
    local writable_path = cc.FileUtils:getInstance():getWritablePath()
    local manifest_file_path = "assets.manifest"

    self.assets_manager = cc.AssetsManagerEx:create(manifest_file_path, writable_path)
    self.assets_manager:retain()

    local manifest = self.assets_manager:getLocalManifest()
    if manifest then
        configuration:SetVersion(manifest:getVersion())
    end

    local EVENT_CODE = cc.EventAssetsManagerEx.EventCode
    local OnUpdateEvent = function(event)
        local scene = cc.Director:getInstance():getRunningScene()

        if not self.assets_manager:getLocalManifest():isLoaded() then
            print("Fail to update assets, step skipped.")

        else
            local event_code = event:getEventCode()
            if event_code == EVENT_CODE.ERROR_NO_LOCAL_MANIFEST then
                print("No local manifest file found, skip assets update.")

            elseif event_code == EVENT_CODE.UPDATE_PROGRESSION then
                local assetId = event:getAssetId()
                local percent = event:getPercent()

                if assetId == cc.AssetsManagerExStatic.VERSION_ID then

                elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then

                else
                    self.ui_root:UpdateDownloadProgress(math.floor(percent))
                end

            elseif event_code == EVENT_CODE.NEW_VERSION_FOUND then
                --发现新版本，检测是否需要更新二进制包
                local local_manifest = self.assets_manager:getLocalManifest()
                local remote_manifest = self.assets_manager:getRemoteManifest()

                if remote_manifest:getBuildId() > local_manifest:getBuildId() then
                    --退出游戏
                    local title = lang_constants:Get("package_version_too_low_title")
                    local desc = lang_constants:Get("package_version_too_low")
                    local confirm_txt = lang_constants:Get("common_confirm")
                    local cancel_txt = lang_constants:Get("common_close")

                    self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                        --TODO 制定地址下载安装包
                        DeleteFile()
                        DoExit()
                    end,
                    
                    function()
                       DoExit() 
                    end)
                else
                    --继续更新
                    self.assets_manager:update()
                end

            elseif event_code == EVENT_CODE.NEW_PATCH_FOUND then
                local size = event:getCURLECode()

                local local_manifest = self.assets_manager:getLocalManifest()
                local remote_manifest = self.assets_manager:getRemoteManifest()

                if size == 0 then
                    --没有更新
                    self.assets_manager:update()


                elseif remote_manifest:getBuildId() > local_manifest:getBuildId() then
                    --退出游戏
                    local title = lang_constants:Get("package_version_too_low_title")
                    local desc = lang_constants:Get("package_version_too_low")
                    local confirm_txt = lang_constants:Get("common_confirm")
                    local cancel_txt = lang_constants:Get("common_close")

                    self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                        --TODO 制定地址下载安装包
                        DeleteFile()
                        DoExit()
                    end,
                    
                    function()
                       DoExit() 
                    end)

                else
                    --提示更新包
                    local title = lang_constants:Get("package_update_title")
                    local desc = string.format(lang_constants:Get("package_update"), size / 1048576)
                    local confirm_txt = lang_constants:Get("common_confirm")
                    local cancel_txt = lang_constants:Get("common_close")

                    self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                        local manifest = self.assets_manager:getRemoteManifest()
                        self.ui_root:ShowDownload(manifest:getVersion())
                        self.assets_manager:update()
                    end,
                    
                    function()
                        DoExit()
                    end
                    )

                    _G["NEED_RELOAD"] = true
                end

            elseif event_code == EVENT_CODE.ERROR_DOWNLOAD_MANIFEST or event_code == EVENT_CODE.ERROR_PARSE_MANIFEST or
                event_code == EVENT_CODE.UPDATE_FAILED then
                --下载失败
                local title = lang_constants:Get("network_unable_connect_title")
                local desc = lang_constants:Get("network_unable_connect")
                local confirm_txt = lang_constants:Get("network_unable_connect_confirm")
                local cancel_text = lang_constants:Get("network_unable_connect_close")

                print("EVENT_CODE.", event_code, event:getMessage())

                self.msgbox:Show(title, desc, confirm_txt, cancel_text, function()
                    if event_code == EVENT_CODE.ERROR_DOWNLOAD_MANIFEST then
                        --manifest文件下载失败，需要提示用户是否重新下载project.manifest
                        self.assets_manager:setState(4)
                        self.assets_manager:update()

                    elseif event_code == EVENT_CODE.UPDATE_FAILED then
                        --部分文件下载成功
                        self.assets_manager:downloadFailedAssets()
                    else
                        DoExit()
                    end
                end,
                
                function()
                   DoExit() 
                end)

            elseif event_code == EVENT_CODE.ERROR_UPDATING then
                print("EVENT_CODE.ERROR_UPDATING", event:getAssetId())

            elseif event_code == EVENT_CODE.ASSET_UPDATED then
                print("EVENT_CODE.ASSET_UPDATED", event:getAssetId())

            elseif event_code == EVENT_CODE.ERROR_DECOMPRESS then
                --解压失败
                self.has_decompress_err = true

            elseif event_code == EVENT_CODE.ALREADY_UP_TO_DATE or event_code == EVENT_CODE.UPDATE_FINISHED then
                --完成更新
                local manifest = self.assets_manager:getLocalManifest()

                if self.has_decompress_err then
                    self.has_decompress_err = false

                    local title = lang_constants:Get("package_decompress_err_title")
                    local desc = lang_constants:Get("package_decompress_err")
                    local confirm_txt = manifest:getBuildId() <= 9 and lang_constants:Get("package_decompress_err_confirm1") or lang_constants:Get("package_decompress_err_confirm2")
                    local cancel_txt = lang_constants:Get("common_close")

                    self.msgbox:Show(title, desc, confirm_txt, cancel_txt, function()
                        --TODO 代码兼容
                        if manifest:getBuildId() <= 9 then
                            DeleteFile()
                            DoExit()
                        else
                            self.assets_manager:downloadFailedAssets()
                        end
                    end,

                    function()
                        DeleteFile()
                        DoExit()
                    end
                    )
                    return
                end

                _G["HAS_DOWNLOADED_PATCH"] = true

                if _G["NEED_RELOAD"] then
                    --download_scene所依赖的脚本都必须重新加载
                    local module_name_list = { "util.configuration", "main", "util.audio_manager", "util.language_constants", "util.spine_manager", "util.animation_manager",
                                                "logic.graphic", "logic.time", "logic.channel_list", "logic.platform_manager", "ui.panel", "ui.simple_msgbox", "util.common_function",
                                                "util.constants", "logic.feature_config" }
                    
                    for _, module_name in ipairs(module_name_list) do
                        package.loaded[module_name] = nil
                    end

                    local scene_manager = require "scene.scene_manager"
                    scene_manager:Clear()

                    package.loaded["scene.scene_manager"] = nil

                    local configuration = require "util.configuration"
                    configuration:Init()

                    if manifest then
                        configuration:SetVersion(manifest:getVersion())
                    end

                    cc.SpriteFrameCache:getInstance():removeSpriteFrames()
                    cc.Director:getInstance():getTextureCache():reloadTexture("res/ui/login.png")

                    require "main"
                else
                    if manifest then
                        configuration:SetVersion(manifest:getVersion())
                    end

                    local scene_manager = require "scene.scene_manager"
                    scene_manager:ChangeScene("login")
                end
            end
        end
    end

    local listener = cc.EventListenerAssetsManagerEx:create(self.assets_manager, OnUpdateEvent)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)
end

return download_scene
