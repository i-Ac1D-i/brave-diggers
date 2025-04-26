local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local client_constants = require "util.client_constants"
local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_SPRITE = constants["SORT_SPRITE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local panel_util = require "ui.panel_util"
local MAX_BTNS = 6

--佣兵批量解雇
local mercenary_fire_batch_panel = panel_prototype.New(true)

function mercenary_fire_batch_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_fire_batch_panel.csb")

    self.btns = {}
    for i = 1, MAX_BTNS do
        self.btns[i] = self.root_node:getChildByName("quality" .. i .."_btn")
    end

    self.close_btn = self.root_node:getChildByName("close_btn")
    self:RegisterWidgetEvent()
end

--显示
function mercenary_fire_batch_panel:Show(callback)
    self.root_node:setVisible(true)

    self.callback = callback
end

function mercenary_fire_batch_panel:RegisterWidgetEvent()

    local filter_mercenary = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.callback then
                self.callback(widget:getTag())
            end

            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end

    for i = 1, 6 do
        local btn = self.btns[i]
        btn:setTouchEnabled(true)
        btn:addTouchEventListener(filter_mercenary)
        btn:setTag(i)
    end

    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

end

return mercenary_fire_batch_panel
