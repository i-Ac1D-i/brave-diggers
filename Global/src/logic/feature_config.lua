local constants = require "util.constants"
local feature_config = {}

function feature_config:Init(channel_info)

    self.channel_info = channel_info
    self.meta_channel = channel_info.meta_channel

    if self.meta_channel == "r2games" then
        constants["MAX_AREA_NUM"] = 50

        constants["CHECKIN_TIME"] =
        {
            ["first"] = 8,
            ["second"] = 16,
            ["third"] = 24,
        }

        feature_config["FEATURE_TYPE"] =
		{
		    ["craft_soul_stone"] = false,
		    ["sign_contract"] = true,
		    ["merchant"] = true,
		    ["open_chest"] = false,
		    ["guild"] = false,
		    ["cave_boss"] = true,
		}
    elseif self.meta_channel == "qikujp" then
        constants["MAX_AREA_NUM"] = 45

        feature_config["FEATURE_TYPE"] =
		{
		    ["craft_soul_stone"] = false,
		    ["sign_contract"] = false,
		    ["merchant"] = false,
		    ["open_chest"] = false,
		    ["guild"] = false,
		    ["cave_boss"] = false,
		}
    elseif self.meta_channel == "txwy" then
        constants["MAX_AREA_NUM"] = 45
        
        feature_config["FEATURE_TYPE"] =
        {
            ["craft_soul_stone"] = false,
            ["sign_contract"] = true,
            ["merchant"] = true,
            ["open_chest"] = true,
            ["guild"] = true,
            ["cave_boss"] = true,
        }
    end
end

function feature_config:IsFeatureOpen(mark)
    if self.meta_channel == "r2games" or self.meta_channel == "qikujp" or self.meta_channel == "txwy" then
        return self["FEATURE_TYPE"][mark]
    else
        return true
    end
end

return feature_config
