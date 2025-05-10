local proxy = {}

local PROXY_SERVER = 
{
    ["china"] = {
        [1] = "socks5h://115.29.225.89:17678",
        [2] = "socks5h://123.59.14.201:17678",
        [3] = "socks5h://120.132.66.221:17678",
    },
}

function proxy:GetProxyUrl(region, fail_count)
    local proxy_url = nil

    if not fail_count then
        return nil
    end

    if PROXY_SERVER[region] then
        local proxy_id = fail_count % (#PROXY_SERVER[region]+1)
        proxy_url = PROXY_SERVER[region][proxy_id]
    end

    return proxy_url    
end

return proxy
