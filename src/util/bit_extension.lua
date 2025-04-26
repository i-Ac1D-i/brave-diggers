local bit = require "bit"

local bit_extension = {}

function bit_extension:SetBitNum(target, tag, flag)
    tag = bit.lshift(1, tag)
    if flag then
        target = bit.bor(target, tag)
    else
        tag = bit.bnot(tag)
        target = bit.band(target, tag)
    end
    return target
end

function bit_extension:GetBitNum(target, tag)
    local shift_value = bit.lshift(1, tag)
    local tag_num = bit.band(target, shift_value)
    return bit.rshift(tag_num, tag)
end

return bit_extension
