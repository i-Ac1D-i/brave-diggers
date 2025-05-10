local notification = {}

function notification:Init()
    if Notification and Notification.registerLuaHandler then
        Notification.registerLuaHandler(function(msg_name, result)

            if msg_name == "save_token" then
                print("token:", result)
            end
        end)
    end
end

function notification:GetToken()
    Notification.getToken()
end

return notification
