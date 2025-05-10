local json = require "util.json"
local constants = require "util.constants"
local configuration = require "util.configuration"

local feedback_manager = {}

--追踪平台ID 
local FEEDBACK_ID =
{
    R2GAME_HELPLIST_APIKEY_ANDROID = "a41b2d35b7f3f70a64cba7f1b820431f",
    R2GAME_HELPLIST_DOMAIN_ANDROID = "r2games.helpshift.com",
    R2GAME_HELPLIST_APPID_ANDROID = "r2games_platform_20160308042129070-7f46d7fffc11f29",
    R2GAME_HELPLIST_APIKEY_IOS = "a41b2d35b7f3f70a64cba7f1b820431f",
    R2GAME_HELPLIST_DOMAIN_IOS = "r2games.helpshift.com",
    R2GAME_HELPLIST_APPID_IOS = "r2games_platform_20160329073952024-64732554ba7350c",
}

function feedback_manager:Init(channel_info)
    self.channel_info = channel_info

    if self.channel_info.name == "r2games_android" then

        local key_info = {apiKey = FEEDBACK_ID.R2GAME_HELPLIST_APIKEY_ANDROID, 
                            domain = FEEDBACK_ID.R2GAME_HELPLIST_DOMAIN_ANDROID, 
                            appId = FEEDBACK_ID.R2GAME_HELPLIST_APPID_ANDROID }
        
        PlatformSDK.initFeedback(json:encode(key_info))

    elseif self.channel_info.name == "r2games_appstore" then

        local key_info = {apiKey = FEEDBACK_ID.R2GAME_HELPLIST_APIKEY_IOS, 
                            domain = FEEDBACK_ID.R2GAME_HELPLIST_DOMAIN_IOS, 
                            appId = FEEDBACK_ID.R2GAME_HELPLIST_APPID_IOS }
        
        PlatformSDK.initFeedback(json:encode(key_info))
    end
end

function feedback_manager:GetFeedbackData(login_able)
    
    local resault = ""
    if self.channel_info.meta_channel == "r2games" then

        if login_able then
            resault = json:encode({ user_id = "0", nickname = "0", server_info = "0".."&".."FromLogin", max_bp = "0", level = "0" })
        else
            local config_manager = require "logic.config_manager"

            local user_logic = require "logic.user"
            local achievement_logic = require "logic.achievement"
            local adventure_logic = require "logic.adventure"

            local server_info = configuration:GetServerInfo()
            local max_bp = achievement_logic:GetStatisticValue(constants.ACHIEVEMENT_TYPE["max_bp"])
            local level = ""

            for i = constants["MAX_AREA_NUM"], 1, -1 do
                if string.byte(adventure_logic.area_list[i]) ~= 0 then
                    level = config_manager.area_info_config[i].maze_list_map[1][5].name
                    break
                end
            end

            resault = json:encode({ user_id = user_logic:GetUserId(), nickname = user_logic:GetUserLeaderName(),
                                    server_info = server_info.id.."&"..server_info.name, max_bp = max_bp, level = level })
        end
        
    elseif self.channel_info.meta_channel == "txwy" or self.channel_info.meta_channel == "txwy_dny" then
        local user_logic = require "logic.user"
        local server_info = configuration:GetServerInfo()
        resault = server_info.id.."|"..user_logic:GetUserLeaderName().."|"..configuration:GetVersion()
    end

    return resault
end

function feedback_manager:ShowFeedback(is_login)
    if is_login then
        if self.channel_info.meta_channel == "r2games" then
            PlatformSDK.showFeedback(feedback_manager:GetFeedbackData(true))
        end
    else
        if self.channel_info.meta_channel == "r2games" or self.channel_info.meta_channel == "txwy" or self.channel_info.meta_channel == "txwy_dny" then
            PlatformSDK.showFeedback(feedback_manager:GetFeedbackData(false))
        end
    end
end

return feedback_manager
