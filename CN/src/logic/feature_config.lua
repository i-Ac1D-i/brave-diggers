local constants = require "util.constants"
local feature_config = {}

function feature_config:SetConfig(config)
    --TAG:MASTER_MERGE
    --功能开关改为后台配表控制
    self.config = config
end

function feature_config:IsFeatureOpen(feature_key)
    --TAG:MASTER_MERGE
    --有配置根据配置返回
    return self.config[feature_key]
end

return feature_config
