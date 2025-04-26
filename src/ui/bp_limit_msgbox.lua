local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local troop_logic = require "logic.troop"
local adventure_logic = require "logic.adventure"
local graphic = require "logic.graphic"

local client_constants = require "util.client_constants"
local PLIST_TYPE = ccui.TextureResType.plistType

local bp_limit_msgbox = panel_prototype.New(true)

function bp_limit_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/bp_limit_msgbox.csb")

    local node = self.root_node:getChildByName("bp_limit")
    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.cur_bp_text = node:getChildByName("value")
    self.bp_text = node:getChildByName("limit_value")

    self.desc_text = self.root_node:getChildByName("desc")
    self.name_text = self.root_node:getChildByName("title"):getChildByName("name")

    local panel = self.root_node:getChildByName("panel")
    panel:setOpacity(255 * 0.7)

    panel:getChildByName("bg"):loadTexture(client_constants["BATTLE_BACKGROUND"][client_constants["BATTLE_BACKGROUND"].fight_bg])

    self:RegisterWidgetEvent()
end

function bp_limit_msgbox:Show(area_conf, next_maze_id)
    local cur_limit = area_conf.bp_limit
    local cur_bp = troop_logic:GetTroopBP()
    self.next_maze_id = next_maze_id

    self.bp_text:setString(tostring(cur_limit))
    self.cur_bp_text:setString(tostring(cur_bp))

    self.can_enter = cur_bp >= cur_limit
    local img = ""

    if self.can_enter then
        self.cur_bp_text:setColor(panel_util:GetColor4B(0xC4FC35))
        img = "button/buttonbg_3.png"
    else
        self.cur_bp_text:setColor(panel_util:GetColor4B(0xFC4B35))
        img = "button/buttonbg_1.png"
    end
    self.confirm_btn:loadTextures(img, img, img, PLIST_TYPE)

    self.name_text:setString(area_conf.name)
    self.desc_text:setString(area_conf.desc)

    self.root_node:setVisible(true)
end

function bp_limit_msgbox:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            
            if self.can_enter then
                adventure_logic:EnterMaze(self.next_maze_id)
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            else
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                graphic:DispatchEvent("show_world_sub_scene", "mercenary_levelup_sub_scene")
            end
        end
    end)
end

return bp_limit_msgbox
