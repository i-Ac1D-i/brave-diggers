local panel = {}
panel.__index = panel

function panel.New(is_modal)
    local new_panel = {}

    new_panel.is_modal = is_modal
    return setmetatable(new_panel, panel)
end

function panel:Init()

end

function panel:Show()
    self.root_node:setVisible(true)
end

function panel:Hide()
    if self.root_node then
        self.root_node:setVisible(false)
    end
end

function panel:Clear()
    if self.root_node then
        self.root_node:removeAllChildren()
    end
end

function panel:GetRootNode()
    return self.root_node
end

function panel:GetName()
    return self.__name
end

function panel:IsVisible()
    return self.root_node:isVisible()
end

function panel:Update(elapsed_time)

end

function panel:AddSubPanel(name, sub_panel, z_order)
    self.sub_panels = self.sub_panels or {}
    z_order = z_order or 0

    self.sub_panels[name] = sub_panel

    sub_panel:Init()

    if not sub_panel.root_node:getParent() then
        self.root_node:addChild(sub_panel.root_node, z_order)
    end

    sub_panel.root_node:setVisible(false)
end

function panel:GetEventDispatcher()
    return self.__event_dispatcher
end

--该方法不能重入
function panel:PushEventDispatcher()
    assert(not self.__origin_event_dispatcher)
    self.__origin_event_dispatcher = cc.Director:getInstance():getEventDispatcher()
    cc.Director:getInstance():setEventDispatcher(self.__event_dispatcher)
end

--该方法不能重入
function panel:PopEventDispatcher()
    assert(self.__origin_event_dispatcher)
    cc.Director:getInstance():setEventDispatcher(self.__origin_event_dispatcher)
    self.__origin_event_dispatcher = nil
end

function panel:RegisterWidgetEvent(widget, handler)
    self.__listener_map[widget:getName()] = widget

    widget:setTouchEnabled(true)
    widget:addTouchEventListener(handler)
end

function panel:UnregisterWidgetEvent()
    for name, widiget in pairs(self.__listener_map) do
        widget:setTouchEnabled(false)
    end
end

return panel
