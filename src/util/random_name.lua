local csv = require "util.csv"

local random_name = {}

local COMBIN_TYPE = {
    ["de"] = 3,
    ["es-MX"] = 2,
    ["fr"] = 2,
    ["pt-BR"] = 2,
    ["ru"] = 2,
    ["tr-TR"] = 2,
}

function random_name:GetRandomName()
    local platform_manager = require "logic.platform_manager"
    local config_manager = require "logic.config_manager"
    local locale = platform_manager:GetLocale()

    if not self.cur_locale then
        self.random_name_config = csv.Load("random_name")

    elseif self.cur_locale ~= locale then
        local succ, map = pcall(require, ("locale.csv_" .. locale))

        local m = map["random_name"]
        for ID, conf in pairs(self.random_name_config) do
            for i, field in ipairs({"r1", "r2", "r3"}) do
                conf[field] = m[ID .. "_" .. field]
            end
        end
    end

    self.cur_locale = locale

    local name = ""

    local combin_type = self:GetCombinType()

    if combin_type == 1 then

        for i = 1, 3 do
            local r = math.random(1, #self.random_name_config)
            name = name .. self.random_name_config[r]["r" .. tostring(i)]
        end

    elseif combin_type == 2 then

        local r1 = math.random(1, #self.random_name_config)
        local first_name = self.random_name_config[r1]["r1"]

        local r2 = math.random(1, 2) + 1 
        r1 = math.random(1, #self.random_name_config)
        local second_name = self.random_name_config[r1]["r" .. tostring(r2)]
        print("***",first_name,second_name)
        name = first_name .. second_name

    elseif combin_type == 3 then

        local r1 = math.random(1, #self.random_name_config)
        local r2 = math.random(1, 2)
        local first_name = self.random_name_config[r1]["r" .. tostring(r2)]

        r1 = math.random(1, #self.random_name_config)
        local second_name = self.random_name_config[r1]["r3"]
        print("$$$",first_name,second_name)
        name = first_name .. second_name

    end

    

    return name or ""
end

-- 根据不同的语言来获取 r1 r2 r3字符组合的规则类型
-- 1：r1 + r2 + r3
-- 2: r1 + r2/r3
-- 3: r1/r2 + r3
function random_name:GetCombinType()
    local result = 1

    if COMBIN_TYPE[self.cur_locale] then
        result = COMBIN_TYPE[self.cur_locale]
    end

    return result
end

return random_name
