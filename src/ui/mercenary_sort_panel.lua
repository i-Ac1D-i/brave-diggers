local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local client_constants = require "util.client_constants"
local SORT_TYPE = client_constants["SORT_TYPE"]
local SORT_RANGE = client_constants["SORT_RANGE"]
local SORT_SPRITE = constants["SORT_SPRITE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local panel_util = require "ui.panel_util"

--排序面板
local sort_msgbox = panel_prototype.New(true)
function sort_msgbox.New()
    return setmetatable({}, sort_msgbox)
end

function sort_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/sort_panel.csb")

    self.close_btn = self.root_node:getChildByName("close_btn")

    self.sort_btns = {}

    self.sort_btns[SORT_TYPE["bp"]] = self.root_node:getChildByName("bp_btn")
    self.sort_btns[SORT_TYPE["wakeup"]] = self.root_node:getChildByName("wakeup_btn")
    self.sort_btns[SORT_TYPE["quality"]] = self.root_node:getChildByName("quality_btn")
    self.sort_btns[SORT_TYPE["level"]] = self.root_node:getChildByName("level_btn")
    self.sort_btns[SORT_TYPE["contract"]] = self.root_node:getChildByName("contract_btn")
    self.sort_btns[SORT_TYPE["genre"]] = self.root_node:getChildByName("genre_btn")

    self.sort_range_btns = {}
    self.range_chks = {}

    for i = 1, 8 do
        local node = self.root_node:getChildByName("node" .. i)
        self.sort_range_btns[i] = node
        self.range_chks[i]= node:getChildByName("select")
    end

    self:RegisterWidgetEvent()
end

--显示
function sort_msgbox:Show(source, current_sort_type, current_sort_range, callback)
    self.root_node:setVisible(true)
    self.current_sort_type = current_sort_type
    self:SwitchRange(current_sort_range)

    self.callback = callback

    if source == client_constants["SORT_PANEL_SOURCE"]["library"] then
        for i = 1, 6 do
            local btn = self.sort_btns[i]
            btn:loadTextures("button/buttonbg_1.png", "button/buttonbg_3.png", "button/buttonbg_3.png", PLIST_TYPE)
            btn:setColor(panel_util:GetColor4B(0xffffff))

            if i ~=  SORT_TYPE["quality"] and i ~= SORT_TYPE["genre"]  then
                btn:setTouchEnabled(false)
                btn:setColor(panel_util:GetColor4B(0x7f7f7f))
            end

            if i == current_sort_type then
                btn:loadTextures("button/buttonbg_3.png", "button/buttonbg_3.png", "button/buttonbg_3.png", PLIST_TYPE)
            end
        end
    else
        for i = 1, 6 do
            local btn = self.sort_btns[i]
            btn:setColor(panel_util:GetColor4B(0xffffff))
            btn:setTouchEnabled(true)
            if i == current_sort_type then
                btn:loadTextures("button/buttonbg_3.png", "button/buttonbg_3.png", "button/buttonbg_3.png", PLIST_TYPE)
            else
                btn:loadTextures("button/buttonbg_1.png", "button/buttonbg_3.png", "button/buttonbg_3.png", PLIST_TYPE)
            end
        end
    end
end

-- 选择范围
function sort_msgbox:SwitchRange(type)
    for i = 1, 8 do
        self.range_chks[i]:setSelected(i == type)
    end
    self.current_sort_range = type
end

function sort_msgbox:RegisterWidgetEvent()

    local start_sort_mercenary = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local sort_type = widget:getTag()

            self.current_sort_type = sort_type

            if self.callback then
                self.callback(sort_type, self.current_sort_range)
            end

            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end

    for i = 1, 6 do
        self.sort_btns[i]:setTouchEnabled(true)
        self.sort_btns[i]:addTouchEventListener(start_sort_mercenary)
        self.sort_btns[i]:setTag(i)
    end

    local select_range_mercenary = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local sort_range = widget:getTag()
            self:SwitchRange(sort_range)

            if self.callback then
                self.callback(self.current_sort_type, self.current_sort_range)
            end
        end
    end

    for i = 1, 8 do
        self.sort_range_btns[i]:setTouchEnabled(true)
        self.sort_range_btns[i]:setTag(i)
        self.sort_range_btns[i]:addTouchEventListener(select_range_mercenary)
    end

    panel_util:RegisterCloseMsgbox(self.close_btn, "mercenary_sort_panel")

end

return sort_msgbox
