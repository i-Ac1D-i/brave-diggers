local network = require "util.network"

local time = {}

local SECONDS_PER_DAY = 24 * 3600

--东八区
local TIME_ZONE_OFFSET = 3600 * 8
local FESTIVAL_DATA = {["spring"] = {begin_year = 2016, end_year = 2016, begin_month = 1, end_month = 2, begin_day = 30, end_day = 23 }}

function time:Init()
    self.current_time = os.time()
    self.time_zone_offset = TIME_ZONE_OFFSET
end

--返回服务器上的utc时间
function time:Now()
    return self.current_time
end

function time:SyncTime(server_time, time_zone)
    self.current_time = server_time

    if time_zone then
        self.time_zone_offset = time_zone * 3600
    else
        self.time_zone_offset = TIME_ZONE_OFFSET
    end
    
    local utils = require "util.utils"
    utils:setTimeZone(self.time_zone_offset)

    network:SetTime(server_time)
end

function time:GetDurationToNextDay()
    local current_time = self:Now()

    local utc_8 = os.date("!*t", current_time + self.time_zone_offset)
    local start_time = utc_8.hour * 3600 + utc_8.min * 60 + utc_8.sec

    return SECONDS_PER_DAY - start_time
end

function time:GetDurationToFixedTime(fixed_time)
    local current_time = self:Now()
    return fixed_time - current_time
end

function time:GetDaysBySeconds(seconds)
    return math.floor(seconds/SECONDS_PER_DAY)
end

--把天数转化成秒
function time:GetSecondsFromDays(days)
    return days * SECONDS_PER_DAY
end

function time:GetDateInfo(time)
    --先转成东八区
    time = time + self.time_zone_offset
    return os.date("!*t", time)
end

function time:Update(elapsed_time)
    self.current_time = self.current_time + elapsed_time
end

function time:IsFestivalDuration(time_date, festival_type)
   
   local result = false
   local festival_data = FESTIVAL_DATA[festival_type]

   if festival_data then 
      local t_year = time_date.year
      local t_month = time_date.month
      local t_day = time_date.day

      local current_day = t_year * 10 + t_month * 100 + t_day
      local begin_day = festival_data.begin_year * 10 +  festival_data.begin_month * 100 + festival_data.begin_day
      local end_day = festival_data.end_year * 10 + festival_data.end_month * 100 + festival_data.end_day
      
      if current_day >= begin_day and current_day <= end_day then       
         result = true
      end

   end
   
   return result 

end

return time
