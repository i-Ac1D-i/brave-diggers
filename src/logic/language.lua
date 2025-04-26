local language = {}

function language:Init(locales, cur_locale)
    self.locales = locales
    self.cur_locale = cur_locale
    self.chosen_index = self:GetDefaultLocale()
    print("****",self.chosen_index)
end

function language:GetDefaultLocale()
    local result

    if type(self.locales) == "table" then
        local i = 1
        for k, v in pairs(self.locales) do
            if v == self.cur_locale then
                result = i
                break
            end

            i = i + 1
        end
    else
        result = 1
    end

    return result
end

function language:GetLocales()
    return self.locales
end

function language:SetChosenLocale(index)
    self.chosen_index = index
end

function language:GetChosenLocale()
    return self.chosen_index
end

return language
