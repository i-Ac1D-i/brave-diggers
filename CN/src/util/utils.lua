local utils = {} 

-- time 相关字符串转换
function utils:getTimesMinute()
    return 60;
end

function utils:getTimesHour()
    return 60*60
end

function utils:getTimesDay()
    return 24 * 60 * 60
end

function utils:getTimeString(seconds,is_recurit)
    if not self.array or not is_recurit then
        self.array = {}
    end   
    local array = {}
    if seconds >= self:getTimesHour() then  --是否大于1小时
        local hours = math.floor(seconds/self:getTimesHour())  
        seconds = seconds - self:getTimesHour()*hours
        self.array["hours"] = hours 
        return self:getTimeString(seconds,true);
    elseif seconds >= self:getTimesMinute() then  --判断是否大于1分钟
        local minutes = math.floor(seconds/self:getTimesMinute())
        seconds = seconds - self:getTimesMinute()*minutes
        self.array["minutes"] = minutes 
        return self:getTimeString(seconds,true);
    else  --递归结束条件
        table.insert(self.array,1,seconds)
        self.array["seconds"] = seconds 
        return self.array 
    end     
end
--转换单位
function utils:convertToUnit(number)

    if number >= 1000000 then  --是否大于1M
        local num = math.floor(number/1000000)  
        local reduce = math.floor(number%1000000) / 1000000
        reduce = string.format("%.2f",reduce) 
        local total
        if reduce == 0 then
            total = num
        else
            total = num + reduce
        end
        return total.."M"
    elseif number >= 1000 then  --判断是否大于1分钟
        local num = math.floor(number/1000)  
        local reduce = math.floor(number%1000) / 1000
        reduce = string.format("%.2f",reduce) 
        local total = num + reduce
        return total.."K"
    else
        return number
    end 
end

--将秒数转换成日期
function utils:convertToDate(seconds)
  return os.date("%Y/%m/%d %H:%M:%S",math.ceil(seconds));
end

--延迟调用方法相关
function utils:performWithDelay(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    node:runAction(sequence)
    return sequence
end

--action 实现调度，可以通过stopAction来停止这个调度
--先执行方法，再执行等待
function utils:scheduleBeforeDelay(node,func,delay)
    local Func = cc.CallFunc:create(func);
    local Delay = cc.DelayTime:create(delay);
    local seq = cc.Sequence:create(Func,Delay);
    local action = cc.RepeatForever:create(seq)
    node:runAction(action);
    return action;
end
--先执行等待再执行方法
function utils:scheduleAfterDelay(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    local action = cc.RepeatForever:create(sequence)
    node:runAction(action)
    return action
end

--给定时间里，调用次数
function utils:scheduleLimiteTimes(node, callback, all_time,times,callback2)
    local delay = cc.DelayTime:create(1)
    local delay_time = all_time/times
    local delay = cc.DelayTime:create(delay_time)
    local sequence = cc.Sequence:create(cc.CallFunc:create(callback),delay)
    --local sequence = cc.Sequence:create(callback,delay)
    local action = cc.Repeat:create(sequence,times)

    local sequence2 = cc.Sequence:create( action,cc.CallFunc:create(callback2))

    node:runAction(sequence2)

    return sequence2
end

--字符串操作相关
function utils:replaceStr(str,origin,target)
    return string.gsub(str, origin, target)
end

--字符串截取  闭区间
function utils:getSubString(str,startPos,endPos)
    return string.sub(str,startPos,endPos)  
end

--获取字符串的长度
function utils:getStrLength(str)
  return string.len(str)  -- 获取字符串的长度
end 

--字符串替换  将字符串中的空格去掉
function utils:trim(str)
    return string.gsub(str," ", "");
end

--设置相关
function utils:setFPS(isEnable)
    cc.Director:getInstance():setDisplayStats(isEnable)
end


--日志设置相关
function utils:setOutPut(isEnable)
   self.clsoe_output = isEnable
end

function utils:addDeveloper(name)
 if not self.filters then
   self.filters = {}
 end  
    table.insert(self.filters,name);
end

function utils:log(...)
    if (not self.close_output) then
        return
    end

    local arr = {...};
    local ress = "";
    local find=false;
    for key, var in pairs(self.filters) do
        if(string.find(arr[1],var)) then
            find=true;
            break ;
        end
    end
    
    if(not find) then
        return;
    end

    for _, para in pairs(arr) do
        if type(para) == "string" or type(para)=="number" or type(para) == "boolean" then
            ress = ress.." "..tostring(para);
        elseif type(para) == "table" then
            ress = ress.." "..json.encode(para);
        end
    end

    local maxLen = 4000;
    local len=string.len(ress)
    --如果太长了, 则分开打 
    for var=0, math.floor(len/maxLen) do
        local str = string.sub(ress,var*maxLen+1,(var+1)*maxLen);
        print(str);    
    end
end

function utils:saveLog(txt)
    local url = cc.FileUtils:getInstance():getWritablePath().."log"..".txt"
    local file = io.open(url,"a+")
    file:write(tostring(txt).."\n")
    file:close()
end

--table相关
---------------------------
--查询指定元素在数组中的位置
---------------------------
function utils:indexOf(array,item)
    for key, var in pairs(array) do
        if (var == item) then
            return key;
        end
    end
    return -1;
end

---------------------------
--删除数组中指定的元素
---------------------------
function utils:remove(array,item)
    local index=self:indexOf(array,item);
    if (index>=1) then
        table.remove(array,index);
        return true
    end
    return false
end

---------------------------
--获取指定key满足某数据的数组key
---------------------------
function utils:indexOfByKey(array, key, cond)
    for k, var in ipairs(array) do
        if (tostring(var[key]) == tostring(cond)) then
            return k;
        end
    end
    return -1;
end


---------------------------
--数组合并,返回新的数组
---------------------------
function utils:merge(array1, array2)
    local newList = {};
    if array1 ~= nil then
        for key, var in pairs(array1) do
            table.insert(newList,var)
        end
    end
    if array2 ~= nil then
        for key, var in pairs(array2) do
            table.insert(newList,var)
        end
    end
    return newList;
end

-----------------------显示对象处理相关-----------------------


---------------------------
--批量设置隐藏
---------------------------
function utils:hide(...)
    local p={...}
    for _, var in ipairs(p) do
        if(var~=nil) then
            var:setVisible(false)
        end
    end
end

---------------------------
--批量设置显示
---------------------------
function utils:show(...)
    local p={...}
    for _, var in ipairs(p) do
        if(var~=nil) then
            var:setVisible(true)
        end
    end
end


---------------------------
--添加不可用的效果
---------------------------
function utils:addDisableEffect(view)
    
end

---------------------------
--添加模糊的效果
---------------------------
function utils:addBlurEffect(view)
     
end

---------------------------
--移除不可用的效果
---------------------------
function utils:removeDisableEffect(view)
     
end
--------------------------------------------
--封装一下 disable
--@param view dis 要设定的对象
--@param bo bool 为false则变灰
--@param touchEnabled bool 为false,则屏蔽鼠标事件
--------------------------------------------- 
function utils:setEnable(view, bo, touchEnabled)
    if bo then
        v.removeDisableEffect(view);
    else
        v.addDisableEffect(view);
    end
    if touchEnabled ~= nil then
        view:setTouchEnabled(touchEnabled);
    end
end


----根据起始点,目标点,及移动速度,求单位时间里X和Y轴的位移量
--@param rawPos Point
--@param targetPos Point
--@param speed Point
--@return Point description
function utils:getOffset(rawPos,targetPos,speed)
    local xdis=targetPos.x-rawPos.x;
    local ydis=targetPos.y-rawPos.y;
    local dis=math.sqrt(xdis*xdis+ydis*ydis)

    return cc.p(xdis*speed/dis,ydis*speed/dis)

end

---------------------------
--将字符串分解成一个个字符
---------------------------
function utils:strSplit(str)
    local strList = {}

    for uchar in string.gfind(str, "[%z\1-\127\194-\244][\128-\191]*") do
        strList[#strList+1] = uchar;
    end

    return strList
end

---------------------------
--判断是否为中文
---------------------------
function utils:isChinese(str)
    for uchar in string.gfind(str, "[%z\194-\244][\128-\191]*") do
        return true
    end

    return false
end

--过滤emoji
function utils:strSplitWithEmoji(str)
    local end_str = ""
    for uchar in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
        local byteLen = string.len(uchar) --编码占多少字节

        if byteLen > 3 then --超过三个字节的必须是emoji字符啊
        end

        if byteLen == 3 then
            if string.find(uchar, "[\226][\132-\173]") or string.find(uchar, "[\227][\128\138]") then
            else
                end_str = end_str .. uchar
            end
        end

        if byteLen == 1 then
            local ox = string.byte(uchar)
            if (33 <= ox and 47 >= ox) or (58 <= ox and 64 >= ox) or (91 <= ox and 96 >= ox) or (123 <= ox and 126 >= ox) or (uchar == "　") then
            else
                end_str = end_str .. uchar
            end
        end
    end
    return end_str
end

---------------------------
--按照数字的大小排序........
---------------------------
function utils:sortByNum(v1,v2)
    return tonumber(v2)>tonumber(v1);
end


---------------------------
--通过一个字段对数组排序，可以指定是否升序。默认为升
--比如要通过id对数组进行排序  {{id=3},{id=2}}
---------------------------
function utils:sortByField(tab,field,isAsc)
    if(isAsc==nil or isAsc==true) then
        table.sort(tab,function(v1,v2)
            return v2[field]>v1[field];
        end)
    else
        table.sort(tab,function(v1,v2)
            return v2[field]<v1[field];
        end)
    end
    return tab;
end


local CCNUMBER = {"一","二","三","四","五","六","七","八","九","十","零"};
---------------------------
--convertChinaNumber
--目前只支持2位，待扩展
---------------------------
function utils:convertChinaNumber(number)
    local len = string.len(tostring(number));
    if (len == 1) then
        return self:convertSingleNumber(number);
    elseif (len == 2) then
        if (number == 10) then
            return CCNUMBER[10];
        end
        local first = self:convertSingleNumber(tonumber(string.sub(tostring(number), 1, 1)));
        local second = self:convertSingleNumber(tonumber(string.sub(tostring(number), 2, 2)));
        if (number > 10 and number < 20) then
            return CCNUMBER[10] .. second;
        elseif (number % 10 == 0) then
            return first .. CCNUMBER[10];
        else
            return first .. CCNUMBER[10] .. second;
        end
    end
    return "";
end

-----------------------------
--将中文数字转换成阿拉伯数字
-----------------------------
function utils:convertSingleNumber(number)
    if (number == 0) then
        return CCNUMBER[11];
    else
        return CCNUMBER[number];
    end
end

---------------------------
--给数组的每一向都加一个属性
---------------------------
function utils:tableAddAttr(tab, key, value)
    for _, var in pairs(tab) do
        var[key] = value;
    end
end

function utils:setNetIP(ip_adress)
    self._ip = ip_adress
end

---------------------------
--获取外网IP
---------------------------
function utils:getNetIP(callback,isReConnect)
    if self._ip then
        callback(self._ip) 
    end
end

function utils:sendXMLHTTPrequrestByGet(url,callBack)
      local xhr = cc.XMLHttpRequest:new() -- http请求
      xhr.responseType = 0 -- 响应类型
      xhr:open("GET", url) -- 打开链接
 
      -- 状态改变时调用
      local function onReadyStateChange()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                  local receive = xhr.response 
                  callBack(receive)  
                  xhr:unregisterScriptHandler()        
        else
            --print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
            xhr:unregisterScriptHandler()
            callBack() --如果出错返回nil  
        end
      end
 
      -- 注册脚本回调方法
      xhr:registerScriptHandler(onReadyStateChange)
      xhr:send() -- 发送请求
end

---------------------------
--XML解析
-- 1.2 - Created new structure for returned table
-- 1.1 - Fixed base directory issue with the loadFile() function.
--
-- NOTE: This is a modified version of Alexander Makeev's Lua-only XML parser
-- found here: http://lua-users.org/wiki/LuaXml
---------------------------
function utils:newParser()

    local XmlParser = {};

    function XmlParser:ToXmlString(value)
        value = string.gsub(value, "&", "&amp;"); -- '&' -> "&amp;"
        value = string.gsub(value, "<", "&lt;"); -- '<' -> "&lt;"
        value = string.gsub(value, ">", "&gt;"); -- '>' -> "&gt;"
        value = string.gsub(value, "\"", "&quot;"); -- '"' -> "&quot;"
        value = string.gsub(value, "([^%w%&%;%p%\t% ])",
            function(c)
                return string.format("&#x%X;", string.byte(c))
            end);
        return value;
    end

    function XmlParser:FromXmlString(value)
        value = string.gsub(value, "&#x([%x]+)%;",
            function(h)
                return string.char(tonumber(h, 16))
            end);
        value = string.gsub(value, "&#([0-9]+)%;",
            function(h)
                return string.char(tonumber(h, 10))
            end);
        value = string.gsub(value, "&quot;", "\"");
        value = string.gsub(value, "&apos;", "'");
        value = string.gsub(value, "&gt;", ">");
        value = string.gsub(value, "&lt;", "<");
        value = string.gsub(value, "&amp;", "&");
        return value;
    end

    function XmlParser:ParseArgs(node, s)
       local abc = string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a)
            node:addProperty(w, self:FromXmlString(a))
        end)
    end

    function XmlParser:ParseXmlText(xmlText)
        local stack = {}
        local top = utils:newNode()  
        table.insert(stack, top)
        local ni, c, label, xarg, empty
        local i, j = 1, 1
        while true do
            ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)
            if not ni then break end
            local text = string.sub(xmlText, i, ni - 1);
            if not string.find(text, "^%s*$") then
                local lVal = (top:value() or "") .. self:FromXmlString(text)
                stack[#stack]:setValue(lVal)
            end
            if empty == "/" then -- empty element tag
                local lNode = utils:newNode(label)
                self:ParseArgs(lNode, xarg)
                top:addChild(lNode)
            elseif c == "" then -- start tag
                local lNode = utils:newNode(label)
                self:ParseArgs(lNode, xarg)
                table.insert(stack, lNode)
        top = lNode
            else -- end tag
                local toclose = table.remove(stack) -- remove top

                top = stack[#stack]
                if #stack < 1 then
                    error("XmlParser: nothing to close with " .. label)
                end
                if toclose:name() ~= label then
                    error("XmlParser: trying to close " .. toclose.name .. " with " .. label)
                end
                top:addChild(toclose)
            end
            i = j + 1
        end
        local text = string.sub(xmlText, i);
        if #stack > 1 then
            error("XmlParser: unclosed " .. stack[#stack]:name())
        end
        return top
    end

    function XmlParser:loadFile(path)
        local hFile, err = io.open(path, "r");

        if hFile and not err then
            local xmlText = hFile:read("*a"); -- read file content
            io.close(hFile);
            return self:ParseXmlText(xmlText), nil;
        else
            print(err)
            return nil
        end
    end

    return XmlParser
end

function utils:newNode(name) 
    local node = {}
    node.___value = nil
    node.___name = name
    node.___children = {}
    node.___props = {}

    function node:value() return self.___value end
    function node:setValue(val) self.___value = val end
    function node:name() return self.___name end
    function node:setName(name) self.___name = name end
    function node:children() return self.___children end
    function node:numChildren() return #self.___children end
    function node:addChild(child)
        if self[child:name()] ~= nil then
            if type(self[child:name()].name) == "function" then
                local tempTable = {}
                table.insert(tempTable, self[child:name()])
                self[child:name()] = tempTable
            end
            table.insert(self[child:name()], child)
        else
            self[child:name()] = child
        end
        table.insert(self.___children, child)
    end

    function node:properties() return self.___props end
    function node:numProperties() return #self.___props end
    function node:addProperty(name, value)
        local lName = "@" .. name
        if self[lName] ~= nil then
            if type(self[lName]) == "string" then
                local tempTable = {}
                table.insert(tempTable, self[lName])
                self[lName] = tempTable
            end
            table.insert(self[lName], value)
        else
            self[lName] = value
        end
        table.insert(self.___props, { name = name, value = self[name] })
    end

    return node
end
 
function utils:dump(value, desciption, nesting)
    local function dump_value_(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end
    function string.trim(input)
        input = string.gsub(input, "^[ \t\n\r]+", "")
        return string.gsub(input, "[ \t\n\r]+$", "")
    end
    function string.split(input, delimiter)
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

    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(desciption), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(desciption), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(desciption))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function utils:decode(s,startPos) 
    function decode_scanWhitespace(s,startPos)
      local whitespace=" \n\r\t"
      local stringLen = string.len(s)
      while ( string.find(whitespace, string.sub(s,startPos,startPos), 1, true)  and startPos <= stringLen) do
        startPos = startPos + 1
      end
      return startPos
    end
    function decode_scanObject(s,startPos)
      local object = {}
      local stringLen = string.len(s)
      local key, value
      assert(string.sub(s,startPos,startPos)=='{','decode_scanObject called but object does not start at position ' .. startPos .. ' in string:\n' .. s)
      startPos = startPos + 1
      repeat
        startPos = decode_scanWhitespace(s,startPos)
        assert(startPos<=stringLen, 'JSON string ended unexpectedly while scanning object.')
        local curChar = string.sub(s,startPos,startPos)
        if (curChar=='}') then
          return object,startPos+1
        end
        if (curChar==',') then
          startPos = decode_scanWhitespace(s,startPos+1)
        end
        assert(startPos<=stringLen, 'JSON string ended unexpectedly scanning object.')
        -- Scan the key
        key, startPos = self:decode(s,startPos)
        assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
        startPos = decode_scanWhitespace(s,startPos)
        assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
        assert(string.sub(s,startPos,startPos)==':','JSON object key-value assignment mal-formed at ' .. startPos)
        startPos = decode_scanWhitespace(s,startPos+1)
        assert(startPos<=stringLen, 'JSON string ended unexpectedly searching for value of key ' .. key)
        value, startPos = self:decode(s,startPos)
        object[key]=value
      until false   -- infinite loop while key-value pairs are found
    end
    function decode_scanArray(s,startPos)
      local array = {}  -- The return value
      local stringLen = string.len(s)
      assert(string.sub(s,startPos,startPos)=='[','decode_scanArray called but array does not start at position ' .. startPos .. ' in string:\n'..s )
      startPos = startPos + 1
      -- Infinite loop for array elements
      repeat
        startPos = decode_scanWhitespace(s,startPos)
        assert(startPos<=stringLen,'JSON String ended unexpectedly scanning array.')
        local curChar = string.sub(s,startPos,startPos)
        if (curChar==']') then
          return array, startPos+1
        end
        if (curChar==',') then
          startPos = decode_scanWhitespace(s,startPos+1)
        end
        assert(startPos<=stringLen, 'JSON String ended unexpectedly scanning array.')
        object, startPos = decode(s,startPos)
        table.insert(array,object)
      until false
    end

    function decode_scanNumber(s,startPos)
      local endPos = startPos+1
      local stringLen = string.len(s)
      local acceptableChars = "+-0123456789.e"
      while (string.find(acceptableChars, string.sub(s,endPos,endPos), 1, true)
        and endPos<=stringLen
        ) do
        endPos = endPos + 1
      end
      local stringValue = 'return ' .. string.sub(s,startPos, endPos-1)
      local stringEval = loadstring(stringValue)
       assert(stringEval, 'Failed to scan number [ ' .. stringValue .. '] in JSON string at position ' .. startPos .. ' : ' .. endPos)
      return stringEval(), endPos
    end
    function decode_scanString(s,startPos)
      assert(startPos, 'decode_scanString(..) called without start position')
      local startChar = string.sub(s,startPos,startPos)
      assert(startChar==[[']] or startChar==[["]],'decode_scanString called for a non-string')
      local escaped = false
      local endPos = startPos + 1
      local bEnded = false
      local stringLen = string.len(s)
      repeat
        local curChar = string.sub(s,endPos,endPos)
        if not escaped then
          if curChar==[[\]] then
            escaped = true
          else
            bEnded = curChar==startChar
          end
        else
          -- If we're escaped, we accept the current character come what may
          escaped = false
        end
        endPos = endPos + 1
        assert(endPos <= stringLen+1, "String decoding failed: unterminated string at position " .. endPos)
      until bEnded
      local stringValue = 'return ' .. string.sub(s, startPos, endPos-1)
      local stringEval = loadstring(stringValue)
      assert(stringEval, 'Failed to load string [ ' .. stringValue .. '] in JSON4Lua.decode_scanString at position ' .. startPos .. ' : ' .. endPos)
      return stringEval(), endPos
    end
    function decode_scanComment(s, startPos)
      assert( string.sub(s,startPos,startPos+1)=='/*', "decode_scanComment called but comment does not start at position " .. startPos)
      local endPos = string.find(s,'*/',startPos+2)
      assert(endPos~=nil, "Unterminated comment in string at " .. startPos)
      return endPos+2
    end
    function decode_scanConstant(s, startPos)
      local consts = { ["true"] = true, ["false"] = false, ["null"] = nil }
      local constNames = {"true","false","null"}

      for i,k in pairs(constNames) do
        --print ("[" .. string.sub(s,startPos, startPos + string.len(k) -1) .."]", k)
        if string.sub(s,startPos, startPos + string.len(k) -1 )==k then
          return consts[k], startPos + string.len(k)
        end
      end
      assert(nil, 'Failed to scan constant from string ' .. s .. ' at starting position ' .. startPos)
    end



      startPos = startPos and startPos or 1
      startPos = decode_scanWhitespace(s,startPos)
      assert(startPos<=string.len(s), 'Unterminated JSON encoded object found at position in [' .. s .. ']')
      local curChar = string.sub(s,startPos,startPos)
      -- Object
      if curChar=='{' then
        return decode_scanObject(s,startPos)
      end
      -- Array
      if curChar=='[' then
        return decode_scanArray(s,startPos)
      end
      -- Number
      if string.find("+-0123456789.e", curChar, 1, true) then
        return decode_scanNumber(s,startPos)
      end
      -- String
      if curChar==[["]] or curChar==[[']] then
        return decode_scanString(s,startPos)
      end
      if string.sub(s,startPos,startPos+1)=='/*' then
        return self:decode(s, decode_scanComment(s,startPos))
      end
      -- Otherwise, it must be a constant
      return decode_scanConstant(s,startPos)
end
--获取一个先加速 后减速的动作
function utils:getEaseOutMv(all_time,mv_pos)
    local mv = cc.MoveBy:create(all_time,mv_pos) 
    local action = cc.EaseOut:create(mv,2)   
    return action 
end

--获取一个先减速 后加速的动作
function utils:getEaseInMv(all_time,mv_pos)
    local mv = cc.MoveBy:create(all_time,mv_pos) 
    local action = cc.EaseIn:create(mv,2) 
    return action 
end

--获取一个先减速 后加速的弹跳动作  在初始时跳一次  末尾跳一次
function utils:getEaseElasticInOutMv(all_time,mv_pos)
    local mv = cc.MoveBy:create(all_time,mv_pos) 
    local action = cc.EaseElasticInOut:create(mv) 
    return action 
end
-- @function [parent=#JumpTo] create 
-- @param self
-- @param #float duration
-- @param #vec2_table position
-- @param #float height
-- @param #int jumps
--获取一个先减速 后加速的弹跳动作  在初始时跳一次  末尾跳一次 
function utils:getJumpInMv(all_time,mv_pos)
    local mv1 = self:getEaseOutMv(all_time,mv_pos) 
    local mv2 = self:getEaseInMv(0.1,cc.p(0,-40)) 
    local action = cc.Sequence:create(mv1,mv2) 
    return action 
end

function utils:getJumpOutMv(all_time,mv_pos)
    local mv1 = self:getEaseOutMv(0.1,cc.p(0,-30)) 
    local mv2 = self:getEaseOutMv(all_time,mv_pos) 
    
    local action = cc.Sequence:create(mv1,mv2) 
    return action 
end

function utils:splitStr(str,symbol)     
    local temp = {}
    local format = string.format("([^'%s']+)",symbol)
    for w in string.gmatch(str,format) do     
        table.insert(temp,w) 
    end
    return temp 
end

--毫秒时间
function utils:startTime()
    local socket = require "socket"
    print("start  time == ",socket.gettime())
end

function utils:endTime()
    local socket = require "socket"
    print("end  time == ",socket.gettime())
end

--聊天内容转换为xml
function utils:ConvertToXML(str)
    --标签组装
    local client_constants = require "util.client_constants"
    local look_img = client_constants["CHAT_IMG_PATH"]
    local xml_str = "<text><text>"

    function findstr(check_str)
        local start_pos, end_pos, first, center, end_str = string.find(check_str,"(%[)(.-)(%])")
        if start_pos then
            if start_pos > 1 then
                xml_str = xml_str .. string.sub(check_str, 1,start_pos - 1)
            end 
            if look_img[center] then
                --这是个图片标签要转换为图片
                xml_str = xml_str .. "</text><img scale='2' >" .. look_img[center] .. "</img><text>"
            else
                xml_str = xml_str .."["..center.."]"
            end
            findstr(string.sub(check_str, end_pos + 1))
        else
            --没有找到图片标签直接转换纯文字
            xml_str = xml_str .. check_str
        end
    end
    findstr(str)
    xml_str = xml_str .. "</text></text>"
    return xml_str
end

function utils:getCenterPos()
    local visibel_size = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    return {x=origin.x+visibel_size.width/2,y=origin.y+visibel_size.height/2}
end

function utils:setTimeZone(time_zone)
    self.time_zone = time_zone
end

--获取当前是周几  周日返回的是0,所以这里处理下让其返回7
function utils:getWDay(time)
    local num = tonumber(os.date("!%w",time + self.time_zone))
    num = (num == 0) and 7 or num
    return num
end

return utils;
 