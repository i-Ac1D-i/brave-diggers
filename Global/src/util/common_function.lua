--[[
    @file    common_function.lua
    @date    2015.12.15
    @author  xiaoting.huang
    @note    abstract common function 
--]]
local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()
local common_function = {}

--[[--
深度克隆一个值

-- 下面的代码，t2 是 t1 的引用，修改 t2 的属性时，t1 的内容也会发生变化
local t1 = {a = 1, b = 2}
local t2 = t1
t2.b = 3    -- t1 = {a = 1, b = 3} <-- t1.b 发生变化

-- clone() 返回 t1 的副本，修改 t2 不会影响 t1
local t1 = {a = 1, b = 2}
local t2 = Clone(t1)
t2.b = 3    -- t1 = {a = 1, b = 2} <-- t1.b 不受影响
@param mixed object 要克隆的值
@return mixed
]]
function common_function.Clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--[[
   读取文件内容
]]
function common_function.IoReadFile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

-- start --

--------------------------------
-- 以字符串内容写入文件，成功返回 true，失败返回 false
-- @function [parent=#io] writefile
-- @param string path 文件完全路径
-- @param string content 要写入的内容
-- @param string mode 写入模式，默认值为 "w+b"
-- @return boolean#boolean 

--[[--
以字符串内容写入文件，成功返回 true，失败返回 false

"mode 写入模式" 参数决定 common_function.IoReadFile() 如何写入内容，可用的值如下：

-   "w+" : 覆盖文件已有内容，如果文件不存在则创建新文件
-   "a+" : 追加内容到文件尾部，如果文件不存在则创建文件

此外，还可以在 "写入模式" 参数最后追加字符 "b" ，表示以二进制方式写入数据，这样可以避免内容写入不完整。
**Android 特别提示:** 在 Android 平台上，文件只能写入存储卡所在路径，assets 和 data 等目录都是无法写入的。
]]

-- end --
function common_function.IoWriteFile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

-- start --

--------------------------------
-- 拆分一个路径字符串，返回组成路径的各个部分
-- @function [parent=#io] pathinfo
-- @param string path 要分拆的路径字符串
-- @return table#table 
--[[--
拆分一个路径字符串，返回组成路径的各个部分
~~~ lua
local pathinfo  = common_function.IoPathInfo("/var/app/test/abc.png")
-- 结果:
-- pathinfo.dirname  = "/var/app/test/"
-- pathinfo.filename = "abc.png"
-- pathinfo.basename = "abc"
-- pathinfo.extname  = ".png"
~~~
]]
-- end --
function common_function.IoPathInfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

-- start --

--------------------------------
-- 返回指定文件的大小，如果失败返回 false
-- @function [parent=#io] IoFileSize
-- @param string path 文件完全路径
-- @return integer#integer 

-- end --

function common_function.IoFileSize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end


--------------------------------
-- @module table

-- start --

--------------------------------
-- 计算表格包含的字段数量
-- @function [parent=#table] common_function.TableNums
-- @param table t 要检查的表格
-- @return integer#integer 

--[[--
计算表格包含的字段数量
Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。
]]

-- end --

function common_function.TableNums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

-- start --

--------------------------------
-- 返回指定表格中的所有键
-- @function [parent=#table] common_function.TableKeys
-- @param table hashtable 要检查的表格
-- @return table#table 

--[[
返回指定表格中的所有键
local hashtable = {a = 1, b = 2, c = 3}
local keys = common_function.TableKeys(hashtable)
-- keys = {"a", "b", "c"}
]]

-- end --

function common_function.TableKeys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

-- start --

--------------------------------
-- 返回指定表格中的所有值
-- @function [parent=#table] common_function.TableValues
-- @param table hashtable 要检查的表格
-- @return table#table 

--[[--
返回指定表格中的所有值
local hashtable = {a = 1, b = 2, c = 3}
local values = common_function.TableValues(hashtable)
-- values = {1, 2, 3}
]]

-- end --

function common_function.TableValues(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

-- start --

--------------------------------
-- 将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值
-- @function [parent=#table] TableMerge
-- @param table dest 目标表格
-- @param table src 来源表格

--[[
将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值
local dest = {a = 1, b = 2}
local src  = {c = 3, d = 4}
common_function.TableMerge(dest, src)
-- dest = {a = 1, b = 2, c = 3, d = 4}
]]

-- end --

function common_function.TableMerge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

-- start --

--------------------------------
-- 在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格
-- @function [parent=#table] TableInsertTo
-- @param table dest 目标表格
-- @param table src 来源表格
-- @param integer begin 插入位置,默认最后

--[[--
在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格
local dest = {1, 2, 3}
local src  = {4, 5, 6}
common_function.TableInsertTo(dest, src)
-- dest = {1, 2, 3, 4, 5, 6}
dest = {1, 2, 3}
common_function.TableInsertTo(dest, src, 5)
-- dest = {1, 2, 3, nil, 4, 5, 6}
]]

-- end --

function common_function.TableInsertTo(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

-- start --

--------------------------------
-- 从表格中查找指定值，返回其索引，如果没找到返回 false
-- @function [parent=#table] common_function.TableIndexOf
-- @param table array 表格
-- @param mixed value 要查找的值
-- @param integer begin 起始索引值
-- @return integer#integer 

--[[--
从表格中查找指定值，返回其索引，如果没找到返回 false
local array = {"a", "b", "c"}
print(common_function.TableIndexOf(array, "b")) -- 输出 2
]]

-- end --

function common_function.TableIndexOf(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

-- start --

--------------------------------
-- 从表格中查找指定值，返回其 key，如果没找到返回 nil
-- @function [parent=#table] common_function.TableKeyOf
-- @param table hashtable 表格
-- @param mixed value 要查找的值
-- @return string#string  该值对应的 key
--[[--
从表格中查找指定值，返回其 key，如果没找到返回 nil
local hashtable = {name = "dualface", comp = "chukong"}
print(common_function.TableKeyOf(hashtable, "chukong")) -- 输出 comp
]]

-- end --

function common_function.TableKeyOf(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

-- start --

--------------------------------
-- 从表格中删除指定值，返回删除的值的个数
-- @function [parent=#table] common_function.TableRemoveByValue
-- @param table array 表格
-- @param mixed value 要删除的值
-- @param boolean removeall 是否删除所有相同的值
-- @return integer#integer 

--[[--
从表格中删除指定值，返回删除的值的个数
~~~ lua
local array = {"a", "b", "c", "c"}
print(common_function.TableRemoveByValue(array, "c", true)) -- 输出 2
~~~
]]

-- end --
function common_function.TableRemoveByValue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

--[[
   获取唯一array
]]
function common_function.TableUnique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end
-- start --

--------------------------------
-- 用指定字符或字符串分割输入字符串，返回包含分割结果的数组
-- @function [parent=#string] Split
-- @param string input 输入字符串
-- @param string delimiter 分割标记字符或字符串
-- @return array#array  包含分割结果的数组

--[[--
用指定字符或字符串分割输入字符串，返回包含分割结果的数组
~~~ lua
local input = "Hello,World"
local res = common_function.Split(input, ",")
-- res = {"Hello", "World"}
local input = "Hello-+-World-+-Quick"
local res = common_function.Split(input, "-+-")
-- res = {"Hello", "World", "Quick"}
~~~
]]

-- end --

function common_function.Split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- start --

--------------------------------
-- 去除输入字符串头部的空白字符，返回结果
-- @function [parent=#string] Ltrim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see common_function.Rtrim, common_function.Trim

--[[--
去除输入字符串头部的空白字符，返回结果
~~~ lua
local input = "  ABC"
print(common_function.Ltrim(input))
-- 输出 ABC，输入字符串前面的两个空格被去掉了
~~~
空白字符包括：
-   空格
-   制表符 \t
-   换行符 \n
-   回到行首符 \r
]]
-- end --

function common_function.Ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

-- start --

--------------------------------
-- 去除输入字符串尾部的空白字符，返回结果
-- @function [parent=#string] Rtrim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see common_function.Ltrim, common_function.Trim

--[[
去除输入字符串尾部的空白字符，返回结果
local input = "ABC  "
print(common_function.Rtrim(input))
-- 输出 ABC，输入字符串最后的两个空格被去掉了
]]

-- end --

function common_function.Rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

-- start --

--------------------------------
-- 去掉字符串首尾的空白字符，返回结果
-- @function [parent=#string] Trim
-- @param string input 输入字符串
-- @return string#string  结果
-- @see common_function.ltrim, common_function.Rtrim

--[[--

去掉字符串首尾的空白字符，返回结果

]]

-- end --

function common_function.Trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

-- start --

--------------------------------
-- 将字符串的第一个字符转为大写，返回结果
-- @function [parent=#string] common_function.UcFirst
-- @param string input 输入字符串
-- @return string#string  结果

--[[--
将字符串的第一个字符转为大写，返回结果
local input = "hello"
print(common_function.UcFirst(input))
-- 输出 Hello
]]

-- end --

function common_function.UcFirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

function common_function.Utf8to32(utf8str)
    local res, seq, val = {}, 0, nil
    for i = 1, #utf8str do
        local c = string.byte(utf8str, i)
        if seq == 0 then
            table.insert(res, val)
            seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
            error("invalid UTF-8 character sequence")
            val = bit.band(c, 2^(8-seq) - 1)
        else
            val = bit.bor(bit.lshift(val, 6), bit.band(c, 0x3F))
        end
        seq = seq - 1
    end

    table.insert(res, val)
    table.insert(res, 0)
    return res
end

function common_function.Utf8Len(input)
    local len = 0

    local t = common_function.Utf8to32(input)

    --单个中文字符长度为2
    for i = 1, #t-1 do
        len = t[i] <= 255 and len + 1 or len + 2
    end

    return len
end

function common_function.CopyFile(src_path, dest_path)
    local writable_path
    if TARGET_PLATFORM == cc.PLATFORM_OS_WINDOWS or TARGET_PLATFORM == cc.PLATFORM_OS_MAC or TARGET_PLATFORM == cc.PLATFORM_OS_LINUX then
        writable_path = ""
    else
        writable_path = cc.FileUtils:getInstance():getWritablePath()
    end

    local str = aandm.getDataFromFile(writable_path .. src_path)
    local file = io.open(writable_path .. dest_path, "wb")
    file:write(str)
    file:close()
end

function common_function.ValidName(name, max_length)
    local name_table = common_function.Utf8to32(name)
    local len = 0
    for i = 1, #name_table-1 do

        local val = name_table[i]

        if val == 0x20 or val == 0x25 or val == 0x26 or val == 0x7C then
            --检测空格
            return "invalid_char"
        end

        if val <= 255 then
            len = len + 1
        else
            len = len + 2
        end
    end

    if len > max_length then
        return "exceed_max_length"
    end

    return "ok", len
end

function common_function.Utf8Len(input)
    local len = 0

    local t = common_function.Utf8to32(input)

    --单个中文字符长度为2
    for i = 1, #t-1 do
        len = t[i] <= 255 and len + 1 or len + 2
    end

    return len
end

function common_function.Strip(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

return common_function
