local language_constants = {}
function language_constants:Init(locale,channel_info)

    local mod_name1 = "locale." .. locale
    local mod_name2 = "locale.csd_" .. locale
    local mod_name3 = "locale.font_" .. locale

    local dir = channel_info.change_language_dir
    if dir then
        mod_name1 = string.format("locale.%s.",dir) .. locale 
        mod_name2 = string.format("locale.%s.csd_",dir) .. locale 
        mod_name3 = string.format("locale.%s.font_",dir) .. locale 
    end

    package.loaded[mod_name1] = nil
    package.loaded[mod_name2] = nil
    package.loaded[mod_name3] = nil

    local strings = require(mod_name1)

    local succ, str = pcall(require, mod_name2)

    if succ then
        self.CSD_STRINGS = str
    else
        self.CSD_STRINGS = {}
    end
    
    succ, font_map = pcall(require, mod_name3)
    if succ then
        self.FONT_SIZE_MAP = font_map
    else
        self.FONT_SIZE_MAP = nil
    end    
    
    for k, v in pairs(strings) do
        self[k] = v
    end

    self.campaign_cond = {self.RACE_STR, self.SEX_STR, self.JOB_STR}
    self.LOCALE_STR = {['zh-CN'] = "简体中文", ['en-US'] = "English", ['zh-TW'] = "繁体中文",["vi"] = "越南",["th"] = "泰文"}
end

function language_constants:GetLocaleStr(locale)
    return self.LOCALE_STR[locale]
end

function language_constants:Get(str)
    return self.RAW_STR[str] or ""
end

function language_constants:GetFormattedStr(str, ...)
    if self.RAW_STR[str] then
        return string.format(self.RAW_STR[str], ...)
    
    else
        return ""
    end
end

function language_constants:GetJob(index)
    return self.JOB_STR[index] or ""
end

function language_constants:GetSex(index)
    return self.SEX_STR[index] or ""
end

function language_constants:GetRace(index)
    return self.RACE_STR[index] or ""
end

function language_constants:GetTip(name)
    local map = self.TIP_STR[name]

    if map then
        local r = math.random(1, #map)
        local str = map[r]
        return str
    end

    return ""
end

function language_constants:GetExploreTip()
    local r = math.random(1, #self.EXPLORE_TIP_STR)
    local str = self.EXPLORE_TIP_STR[r]
    return str or ""
end

function language_constants:GetCampaignBuffType(type)
    return self.CAMPAIGN_BUFF_TYPE[type]
end

function language_constants:GetCampaignCond(type, value)
    return self.campaign_cond[type][value].."  ".. self.CAMPAIGN_COND_TYPE[type]
end

function language_constants:GetGuildNotice(type)
    return self.GUILD_NOTICE_STR[type] or ""
end

function language_constants:GetNoviceStr()
    return self.NOVICE_STR
end

function language_constants:GetAgreementStr()
    return self.AGREEMENT_STR or ""
end

language_constants["CONVERT_LANG"] = 
{
    ["zh-TW"] = "tw",
    ["zh-CN"] = "cn",
    ["en-US"] = "en",
    ["th"] = "th",
    ["th-TH"] = "th",
    ["vi"] = "vi",
    ["vi-VN"] = "th",
}

language_constants["LOCALE_TRANSFORM"] = {
    ["zh-HK"] = "zh-TW",
    ["zh-MO"] = "zh-TW",
    ["zh-SG"] = "zh-TW",
    ["zh-TW"] = "zh-TW",
    ["zh-Hant"] = "zh-TW",
    ["zh-CN"] = "zh-CN",
    ["zh-Hans"] = "zh-CN",
    ["zh-Hans-CN"] = "zh-CN",
    ["zh-Hans-TW"] = "zh-CN",
    ["zh-Hant-TW"] = "zh-TW",
    ["zh-Hant-HK"] = "zh-TW",
    ["zh-Hant-MO"] = "zh-TW",
    ["en-US"] = "en-US",
    ["en"] = "en-US",
    ["en-AU"] = "en-US",
    ["en-BZ"] = "en-US",
    ["en-CA"] = "en-US",
    ["en-029"] = "en-US",
    ["en-IE"] = "en-US",
    ["en-JM"] = "en-US",
    ["en-NZ"] = "en-US",
    ["en-PH"] = "en-US",
    ["en-ZA"] = "en-US",
    ["en-TT"] = "en-US",
    ["en-GB"] = "en-US",
    ["en-ZW"] = "en-US",
    ["fr"] = "fr",
    ["fr-BE"] = "fr",
    ["fr-CA"] = "fr",
    ["fr-FR"] = "fr",
    ["fr-LU"] = "fr",
    ["fr-MC"] = "fr",
    ["fr-CH"] = "fr",
    ["de"] = "de",
    ["de-AT"] = "de",
    ["de-DE"] = "de",
    ["de-LI"] = "de",
    ["de-LU"] = "de",
    ["de-CH"] = "de",
    ["pt"] = "pt-BR",
    ["pt-BR"] = "pt-BR",
    ["pt-PT"] = "pt-BR",
    ["ru-RU"] = "ru",
    ["ru"] = "ru",
    ["es"] = "es-MX",
    ["es-AR"] = "es-MX",
    ["es-BO"] = "es-MX",
    ["es-CL"] = "es-MX",
    ["es-CO"] = "es-MX",
    ["es-CR"] = "es-MX",
    ["es-DO"] = "es-MX",
    ["es-EC"] = "es-MX",
    ["es-SV"] = "es-MX",
    ["es-GT"] = "es-MX",
    ["es-HN"] = "es-MX",
    ["es-MX"] = "es-MX",
    ["es-NI"] = "es-MX",
    ["es-PA"] = "es-MX",
    ["es-PY"] = "es-MX",
    ["es-PE"] = "es-MX",
    ["es-PR "] = "es-MX",
    ["es-ES"] = "es-MX",
    ["es-UY"] = "es-MX",
    ["es-VE"] = "es-MX",
    ["tr"] = "tr-TR",
    ["tr-TR"] = "tr-TR",
    ["th"] = "th",
    ["th-TH"] = "th",
    ["vi"] = "vi",
    ["vi-TW"] = "vi",
    ["vi-VN"] = "th",
    ["th-TW"] = "th",
}

return language_constants
