local sub_scene = {}
sub_scene.__index = sub_scene

function sub_scene.New()
    local new_sub_scene = { __name = "", root_panel_name = ""}

    new_sub_scene.__index = new_sub_scene
    setmetatable(new_sub_scene, sub_scene)

    return new_sub_scene
end

function sub_scene:Init()
    self.root_node = cc.Node:create()

    self.ui_root = require ("ui." .. self.root_panel_name)

    self.ui_root:Init()
    self.ui_root:Hide()

    self.root_node:addChild(self.ui_root:GetRootNode(), 0)
end

function sub_scene:Clear()

end

function sub_scene:Show(...)
    self.root_node:setVisible(true)
    self.ui_root:Show(...)
end

function sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()
end

function sub_scene:ShowQuick()
    self.root_node:setVisible(true)
end

function sub_scene:HideQuick()
    self.root_node:setVisible(false)
end

function sub_scene:Update(elapsed_time)

end

function sub_scene:GetRootNode()
    return self.root_node
end

function sub_scene:IsVisible()
    return self.root_node:isVisible()
end

function sub_scene:SetName(name)
    self.__name = name
end

function sub_scene:GetName()
    return self.__name
end

function sub_scene:IsRememberFromScene()
    return self.__is_rembmer_from_scene
end

function sub_scene:SetRememberFromScene(remember)
    self.__is_rembmer_from_scene = remember
end

function sub_scene:PushEventDispatcher()
    assert(not self.__origin_event_dispatcher)
    self.__origin_event_dispatcher = cc.Director:getInstance():getEventDispatcher()
    cc.Director:getInstance():setEventDispatcher(self.__event_dispatcher)
end

function sub_scene:PopEventDispatcher()
    assert(self.__origin_event_dispatcher)
    cc.Director:getInstance():setEventDispatcher(self.__origin_event_dispatcher)
    self.__origin_event_dispatcher = nil
end

function sub_scene:GetEventDispatcher()
    return self.__event_dispatcher
end

function sub_scene:Clear()
    if self.ui_root then
        self.ui_root:Clear()
    end

    self.root_node:removeAllChildren()
end

return sub_scene
