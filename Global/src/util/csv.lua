-----------------------------------------------------------------//--
-- @file	csv.lua
-- @date	2014.11.10
-- @author	Louis Huang | louis.huang@yqidea.com
-- @note	Use to decode a CSV file
--
-- This software is supplied under the terms of a license
-- agreement or nondisclosure agreement with YQIdea and may
-- not be copied or disclosed except in accordance with the
-- terms of that agreement.
--
-- 2014 YQidea.com All Rights Reserved.
--------------------------------------------------------------------/

-- record the type of every column
local _type
local sep = ','
local _path

local cur_csv_locale = nil


local function SetField(keys, index, txt, res)
    if keys then
        local key = keys[index]

        if _type[index] == "number" then
            txt = tonumber(txt) and tonumber(txt) or 0

        elseif _type[index] == "boolean" then
            txt = txt == "1" and true or false

        elseif cur_csv_locale then
            --转换文本
            local a = cur_csv_locale[res.ID .. "_" .. key]
            if a then
                txt = a
            end
        end

        res[key] = txt
    else
        table.insert(res, txt)
    end
end

local function ParseLine(line, keys)
    local res = {}
    local pos = 1
    local index = 1
    local key

    if keys then
        local startp, endp = string.find(line, sep, pos)
        local id_text = string.sub(line, 1, startp-1)
    
        if id_text == "" then
            --忽略注释行
            return

        else
            res[keys[index]] = tonumber(id_text)
            pos = startp + 1
            index = index + 1
            
            key = tonumber(id_text)
        end
    end

    while true do
        local c = string.sub(line, pos, pos)
        local txt = ""
        --if (c == "") then break end
        if (c == '"') then
            -- quoted value (ignore separator within)
            txt = ""
            repeat
                local startp,endp = string.find(line,'^%b""',pos)
                txt = txt..string.sub(line,startp+1,endp-1)
                pos = endp + 1
                c = string.sub(line,pos,pos)
                if (c == '"') then txt = txt..'"' end
                -- check first char AFTER quoted string, if it is another
                -- quoted string without separator, then append it
                -- this is the way to "escape" the quote char in a quote. example:
                --   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
            until (c ~= '"')
            if keys ~= nil then
                local key = keys[index]

                if cur_csv_locale then
                    local a = cur_csv_locale[res.ID .. "_" .. key]
                    if a then
                        txt = a
                    end
                end

                res[key] = txt
            else
                table.insert(res, txt)
            end
            assert(c == sep or c == "")

            pos = pos + 1
            index = index + 1
        else
            -- no quotes used, just look for the first separator
            local startp, endp = string.find(line,sep,pos)
            if startp then
                txt = string.sub(line, pos, startp-1)

                SetField(keys, index, txt, res)

                pos = endp + 1
                index = index + 1
            else
                -- no separator found -> use rest of string and terminate
                txt = string.sub(line,pos)
                SetField(keys, index, txt, res)

                break
            end
        end
    end

    return res, key
end

-- check the type of every column
-- the type of the first column must be "number"
local function CheckColType(types, col,path)
    if(types[col] ~= "number") then
        error("\nError:"..types[col].."!!!The type of \"ID\"(1st column ) must be number!")
    end

    local pattern = {"number", "string", "boolean"}
    for k, v in pairs(types) do
        if v ~= pattern[1] and v ~= pattern[2] and v ~= pattern[3] then
            error("\nError: The table"..path..", "..k.."st column's type \""..v.."\" is error！！this table just suport the type like:\"number\" or \"string\"")
        end
    end
end

-- check the name of every colume
-- the name of the first column must be "ID"
local function CheckColName(keys, col, path)
    if(keys[col] ~= "ID") then
        error("\nError:\"table:"..path..", "..keys[col].."\"!The first column must be \"ID\"!")
    end

    for k, v in pairs(keys) do
        local i = k + 1
        while keys[i] do
            if(v == keys[i]) then
                error("\nError:\"table:"..path..", "..v.."\" The name of column".. k .." and column"..i.." are repeated!!!");
            end
            i = i + 1
        end
    end
end

local csv = {}
function csv.Init(dir, locale)

    if locale then
        local succ, map = pcall(require, ("locale.csv_" .. locale))

        if succ then
            csv.locale_map = map
        else
            csv.locale_map = nil
        end
    else
        csv.locale_map = nil
    end

    csv.dir = dir
end

function csv.Load(file_name)
    _path = path
    local key_row = 3	-- key for each column
    local key_col = 1	-- key for each row

    local str = aandm.loadConfig(csv.dir .. file_name .. ".csv")

    if csv.locale_map then
        cur_csv_locale = csv.locale_map[file_name]
    else
        cur_csv_locale = nil
    end

    local line_num = 1
    local res = {}
    _type = {}
    local keys
    for line in string.gmatch(str, "[^\n]+") do
        --print("表的line",path,line)
        if string.find(line, "\r", -1) then
            line = string.sub(line, 1, -2)
        end

        if line_num > key_row then
            local row, key = ParseLine(line, keys)

            if key then
                res[key] = row
            end

        elseif line_num == key_row then
            --解析字段名
            keys = ParseLine(line)
            CheckColName(keys, key_col, path)

        elseif(line_num == key_row - 1) then
            --解析类型
            _type =  ParseLine(line)
            CheckColType(_type, key_col, path)
        end

        line_num = line_num + 1
    end

    return res
end

function csv.LoadWithoutDir(file_name)
    _path = path
    local key_row = 3   -- key for each column
    local key_col = 1   -- key for each row

    local str = aandm.loadConfig(file_name)

    if csv.locale_map then
        cur_csv_locale = csv.locale_map[file_name]
    else
        cur_csv_locale = nil
    end

    local line_num = 1
    local res = {}
    _type = {}
    local keys
    for line in string.gmatch(str, "[^\n]+") do
        --print("表的line",path,line)
        if string.find(line, "\r", -1) then
            line = string.sub(line, 1, -2)
        end

        if line_num > key_row then
            local row, key = ParseLine(line, keys)

            if key then
                res[key] = row
            end

        elseif line_num == key_row then
            --解析字段名
            keys = ParseLine(line)
            CheckColName(keys, key_col, path)

        elseif(line_num == key_row - 1) then
            --解析类型
            _type =  ParseLine(line)
            CheckColType(_type, key_col, path)
        end

        line_num = line_num + 1
    end

    return res
end

return csv
