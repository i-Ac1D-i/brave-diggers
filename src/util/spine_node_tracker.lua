local spine_node_tracker = {}
spine_node_tracker.__index = spine_node_tracker

function spine_node_tracker.New(root_node, slot_name)
    local t = {}
    t.slot_name = slot_name
    t.root_node = root_node

    t.root_node:registerSpineEventHandler(function(event)
        t.root_node:setVisible(false)
        t.widget:setVisible(false)
    end, sp.EventType.ANIMATION_END)

    return setmetatable(t, spine_node_tracker)
end

function spine_node_tracker:Bind(animation, skin, x, y, widget)
    if not widget then
        self.root_node:setVisible(false)
        return
    end

    if skin then
        self.root_node:setSkin(skin)
    end

    self.root_node:setSlotsToSetupPose()
    self.root_node:setAnimation(0, animation, false)

    self.offset_x = x
    self.offset_y = y

    self.widget = widget

    widget:setPosition(x, y)
    widget:setVisible(true)

    self.root_node:setPosition(x, y)
    self.root_node:setVisible(true)
end

function spine_node_tracker:Update()
    if self.root_node:isVisible() and self.widget then
        local x, y, scale_x, scale_y, alpha, rotation = self.root_node:getSlotTransform(self.slot_name)
        self.widget:setPosition(self.offset_x + x, self.offset_y + y)
        self.widget:setScale(scale_x, scale_y)
        self.widget:setOpacity(alpha)
        self.widget:setRotation(rotation)
    end
end

return spine_node_tracker
