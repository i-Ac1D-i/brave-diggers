local v = class("Utils")

-- time 相关字符串转换
function v:getTimesMinute()
    return 60;
end
 
function v:getTimesHour()
    return 60*60
end

function v:getTimesDay()
    return 24 * 60 * 60
end

function v:getTimeString(seconds)
    if not v.array then
        v.array = {}
    end   
    if seconds >= self:getTimesDay() then  --是否大于一天
        local days = math.floor(seconds/self:getTimesDay())
        seconds = seconds - self:getTimesDay()*days
        table.insert(v.array,1,days)
        v:getTimeString(seconds);  
    elseif seconds >= self:getTimesHour() then  --是否大于1小时
        local hours = math.floor(seconds/self:getTimesHour())  
        seconds = seconds - self:getTimesHour()*hours
        table.insert(v.array,1,hours)
        v:getTimeString(seconds);
    elseif seconds >= self:getTimesMinute() then  --判断是否大于1分钟
        local minutes = math.floor(seconds/self:getTimesMinute())
        seconds = seconds - self:getTimesMinute()*minutes
        table.insert(v.array,1,minutes)
        v:getTimeString(seconds);
    else  --递归结束条件
        table.insert(v.array,1,seconds)
        
        --array  [1] 秒  [2] 分  [3] 时  [4] 天 ....
        return v.array 
    end  
   
end

--将秒数转换成日期
function v:convertToDate(seconds)
  return os.date("%Y/%m/%d %H:%M:%S",math.ceil(seconds));
end

--延迟调用方法相关
function v:performWithDelay(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    node:runAction(sequence)
    return sequence
end

--action 实现调度，可以通过stopAction来停止这个调度
--先执行方法，再执行等待
function v:scheduleBeforeDelay(node,func,delay)
    local Func = cc.CallFunc:create(func);
    local Delay = cc.DelayTime:create(delay);
    local seq = cc.Sequence:create(Func,Delay);
    local action = cc.RepeatForever:create(seq)
    node:runAction(action);
    return action;
end
--先执行等待再执行方法
function v:scheduleAfterDelay(node, callback, delay)
    local delay = cc.DelayTime:create(delay)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback))
    local action = cc.RepeatForever:create(sequence)
    node:runAction(action)
    return action
end

--字符串操作相关
function v:replaceStr(str,origin,target)
    return string.gsub(str, origin, target)
end

--字符串截取  闭区间
function v:getSubString(str,startPos,endPos)
    return string.sub(str,startPos,endPos)  
end

--获取字符串的长度
function v:getStrLength(str)
  return string.len(str)  -- 获取字符串的长度
end 

--字符串替换  将字符串中的空格去掉
function v:trim(str)
    return string.gsub(str," ", "");
end

--设置相关
function v:setFPS(isEnable)
    cc.Director:getInstance():setDisplayStats(isEnable)
end


--日志设置相关
function v:setOutPut(isEnable)
   self.clsoe_output = isEnable
end

function v:addDeveloper(name)
 if not self.filters then
   self.filters = {}
 end  
    table.insert(self.filters,name);
end

function v:log(...)
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

function v:saveLog(txt)
    local url = cc.FileUtils:getInstance():getWritablePath().."log"..".txt"
    local file = io.open(url,"a+")
    file:write(tostring(txt).."\n")
    file:close()
end

--table相关
---------------------------
--查询指定元素在数组中的位置
---------------------------
function v:indexOf(array,item)
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
function v:remove(array,item)
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
function v:indexOfByKey(array, key, cond)
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
function v:merge(array1, array2)
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
function v:hide(...)
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
function v.show(...)
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
function v:addDisableEffect(view)
    
end

---------------------------
--添加模糊的效果
---------------------------
function v:addBlurEffect(view)
     
end

---------------------------
--移除不可用的效果
---------------------------
function v:removeDisableEffect(view)
     
end
--------------------------------------------
--封装一下 disable
--@param view dis 要设定的对象
--@param bo bool 为false则变灰
--@param touchEnabled bool 为false,则屏蔽鼠标事件
--------------------------------------------- 
function v:setEnable(view, bo, touchEnabled)
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
function v:getOffset(rawPos,targetPos,speed)
    local xdis=targetPos.x-rawPos.x;
    local ydis=targetPos.y-rawPos.y;
    local dis=math.sqrt(xdis*xdis+ydis*ydis)

    return cc.p(xdis*speed/dis,ydis*speed/dis)

end

---------------------------
--将字符串分解成一个个字符
---------------------------
function v:strSplit(str)
    local strList = {}

    for uchar in string.gfind(str, "[%z\1-\127\194-\244][\128-\191]*") do
        strList[#strList+1] = uchar;
    end

    return strList
end

---------------------------
--判断是否为中文
---------------------------
function v:isChinese(str)
    for uchar in string.gfind(str, "[%z\194-\244][\128-\191]*") do
        return true
    end

    return false
end

---------------------------
--按照数字的大小排序........
---------------------------
function v:sortByNum(v1,v2)
    return tonumber(v2)>tonumber(v1);
end


---------------------------
--通过一个字段对数组排序，可以指定是否升序。默认为升
--比如要通过id对数组进行排序  {{id=3},{id=2}}
---------------------------
function v:sortByField(tab,field,isAsc)
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
function v:convertChinaNumber(number)
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
function v:convertSingleNumber(number)
    if (number == 0) then
        return CCNUMBER[11];
    else
        return CCNUMBER[number];
    end
end

---------------------------
--给数组的每一向都加一个属性
---------------------------
function v:tableAddAttr(tab, key, value)
    for _, var in pairs(tab) do
        var[key] = value;
    end
end

---------------------------
--获取外网IP
---------------------------
function v:getNetIP(callback,isReConnect)

  if (not self._ip) or isReConnect then  
     self.sendXMLHTTPrequrestByGet("http://www.cmyip.com/",function(receive) 
           if receive then
                Utils.times = 0
                local preStr = '<h1 class="page-title">My IP Address is '
                local lastStr = ' <a class="btn btn-danger btn-xs'
                local starIdx = string.find(receive, preStr,2000,true) 
                starIdx = starIdx + string.len(preStr)
                local endIdx =  string.find(receive, lastStr,2000,true) 

                local ip = string.sub(receive,starIdx,endIdx-1)
                callback(ip)
                self._ip = ip --缓存下来IP
           else
               if not self.times then
                  self.times = 0
               end
                if self.times >= 3 then
                   print("FYD   无法获取IP----请检查网络设置") 
                   self.times = nil 
                   return  
                end
                print(string.format("FYD  第%d次获取IP失败，重新获取中...",self.times)) 
                self:getNetIP(callback) 
                self.times = self.times + 1
           end        
    end)
  else
     callback(self._ip)  --返回缓存的NetIP
  end
end

function v:sendXMLHTTPrequrestByGet(url,callBack)
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
function v:newParser()

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
        local top = v:newNode()  
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
                local lNode = v:newNode(label)
                self:ParseArgs(lNode, xarg)
                top:addChild(lNode)
            elseif c == "" then -- start tag
                local lNode = v:newNode(label)
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

function v:newNode(name) 
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

function v:dump(value, desciption, nesting)
    local function dump_value_(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
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



return v;
 