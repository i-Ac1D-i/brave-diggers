local socket = require "socket"
local crypt = require "crypt"
local bit = require "bit"
local event_listener = require "util.event_listener"
require "util.protobuf"

local protobuf = protobuf

local NET_STATUS =
{
    ["unconnected"] = 1,
    ["try_connect"] = 2,
    ["connected"] = 3,
    ["lost_connection"] = 4,
}

local HEART_BEAT_DELAY = 15

local HEADER_SIZE = 2

local str_char = string.char
local bit_rshift = bit.rshift
local bit_band = bit.band

local function unpack_package(text)
    local size = #text

    if size < HEADER_SIZE then
        return nil, text
    end

    local s = text:byte(1) * 256 + text:byte(2)
    if size < s + HEADER_SIZE then
        return nil, text
    end

    return text:sub(3, 2 + s), text:sub(3 + s)
end

local network = {}

function network:Init()
    self.event_listener = event_listener.New()
    self.cur_time = 0

    self:Clear()
end

function network:RegisterProto()
    local buff = aandm.getDataFromFile("proto/msg.pb")
    protobuf.register(buff)
end

function network:SetTime(time)
    self.cur_time = time
    self.next_heart_beat_time = self.cur_time + HEART_BEAT_DELAY
end

function network:Clear()
    self.last_content = ""
    self.socket = nil

    self.status = NET_STATUS["unconnected"]

    self.session = 0
    self.internal_session = 0
    self.waiting_heart_beat_response = false
end

function network:Connect(ip, port)

    -- 优先尝试tcp6
    self.socket = socket.tcp6()

    if self.status == NET_STATUS["unconnected"] then
        self.socket:settimeout(6)
    else
        self.socket:settimeout(3)
    end
    local status, err = self.socket:connect(ip, port)

    if err then
        self.socket:settimeout(0)
        self.status = NET_STATUS["unconnected"]
        self.socket:close()
        print(err .. "tcp6")
        err = nil                           -- tcp6失败就尝试tcp4
        self.socket = socket.tcp()
        if self.status == NET_STATUS["unconnected"] then
            self.socket:settimeout(6)
        else
            self.socket:settimeout(3)
        end
        
        status, err = self.socket:connect(ip, port)
        if err then
            self.status = NET_STATUS["unconnected"]
            print(err .. "tcp4")
        else
            self.socket:settimeout(0)
            self.status = NET_STATUS["connected"]
        end
    else
        self.socket:settimeout(0)
        self.status = NET_STATUS["connected"]
    end
    
    return err
end

function network:IsConnected()
    return self.status == NET_STATUS["connected"]
end

function network:Disconnect(net_status)
    if self.socket then
        self.socket:close()
    end

    self.socket = nil

    self.last_content = ""
    self.status = net_status or NET_STATUS["unconnected"]
    self.waiting_heart_beat_response = false
end

function network:Update(elapsed_time)
    self.cur_time = self.cur_time + elapsed_time

    if self.status == NET_STATUS["connected"] then
        local chunck, status, partial = self.socket:receive("*a")

        if status and status ~= "timeout" then
            print("net status ", status)
            self:Disconnect(NET_STATUS["lost_connection"])
            return
        end

        if partial and #partial ~= 0 then
            self.last_content = self.last_content .. partial
        elseif chunck then
            self.last_content = self.last_content .. chunck
        end

        local result
        result, self.last_content = unpack_package(self.last_content)
        if result then
            local msg_name, msg_content

            local msg = protobuf.decode2("GS2C", result)
            local new_session

            for k, v in pairs(msg) do
                if k == "session" then
                    new_session = v

                else
                    msg_name = k
                    msg_content = v
                end
            end

            if msg_name == "heart_beat_ret" then
                self.waiting_heart_beat_response = false

            else
                self.session = new_session
                self.internal_session = new_session
            end

            self.next_heart_beat_time = self.cur_time + HEART_BEAT_DELAY

            self.event_listener:Dispatch(msg_name, msg_content)

            self.cur_msg_name = msg_name
            self.cur_msg_content = msg_content
        end

    elseif self.status == NET_STATUS["try_connect"] then

    end
end

function network:Send(msg, ignore_session)
    if not self:IsConnected() then
        self.status = NET_STATUS["lost_connection"]
        return false
    end

    if not ignore_session and self.session < self.internal_session then
        print(self.session, self.internal_session, next(msg), self.cur_msg_name)
        return false
    end

    msg.session = self.session

    local t = protobuf.encode("C2GS", msg)
    local size = #t

    local buf = string.char(bit_band(bit_rshift(size, 8), 0xff)) .. string.char(bit_band(size, 0xff)) .. t
    local i, err = self.socket:send(buf)
    if err then
        print("send err", err)
        if err == "closed" then
            self:Disconnect(NET_STATUS["lost_connection"])
        end
        return false
    end

    self.internal_session = self.internal_session + 1

    return true
end

function network:HeartBeat()
    if not self:IsConnected() then
        return
    end

    if self.waiting_heart_beat_response then
        if self.cur_time > (self.heart_beat_time + HEART_BEAT_DELAY) then
            print("heart beat fail")
            self.waiting_heart_beat_response = false
            self:Disconnect(NET_STATUS["lost_connection"])
        end
    else
        if self.cur_time < self.next_heart_beat_time then
            return
        end

        local t = protobuf.encode("C2GS", { heart_beat = {}, session = self.session} )
        local size = #t

        local buf = string.char(bit_band(bit_rshift(size, 8), 0xff)) .. string.char(bit_band(size, 0xff)) .. t
        local i, err = self.socket:send(buf)
        if err then
            if err == "closed" then
                self:Disconnect(NET_STATUS["lost_connection"])
            end

        else
            self.waiting_heart_beat_response = true
            self.heart_beat_time = self.cur_time
        end
    end
end

function network:RegisterEvent(msg_name, handler)
    self.event_listener:Register(msg_name, handler)
end

function network:HasLostConnection()
    return self.status == NET_STATUS["lost_connection"]
end

do
    network:Init()
end

return network
