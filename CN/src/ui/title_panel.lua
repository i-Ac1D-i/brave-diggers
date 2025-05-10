local panel_prototype = require "ui.panel"
local title_logic = require "logic.title"
local animation_manager = require "util.animation_manager"
local config_manager = require "logic.config_manager"
local utils = require "util.utils"
local PLIST_TYPE = ccui.TextureResType.plistType
local title_panel = panel_prototype.New()
title_panel.__index = title_panel
 
function title_panel.New()
    return setmetatable({}, title_panel)
end

function title_panel:Init(root_node)
    self.root_node = root_node  
    self.tetle_pic = self.root_node:getChildByName("tetle_pic")
    if self.tetle_pic then
      self.title_name = self.tetle_pic:getChildByName("title_mane")
      self.title_right = self.tetle_pic:getChildByName("title_right")
      self.time_line_action = animation_manager:GetTimeLine("title_player_time_line")
      self.root_node:runAction(self.time_line_action)
    else
      self.title_right = self.root_node:getChildByName("title_right")
      self.title_name = self.root_node:getChildByName("Text_96") 
    end
end

function title_panel:Load(title_id)   
    local data = config_manager.title_config[title_id] 
    self.title_name:setString(data.title_name)
    local bottom_path = data.icon or "titles/title_01.png"
    self.title_right:loadTexture(bottom_path,PLIST_TYPE)
end

function title_panel:PlayAnimation()
    self.time_line_action:gotoFrameAndPlay(0, 34, false)
end

function title_panel:PlayBattleAction(time,pos,call_back)
   local action = cc.MoveBy:create(time,pos)
   local action2 = cc.DelayTime:create(1)
   pos.x = -pos.x
   pos.y = -pos.y
   local action3 = cc.MoveBy:create(time,pos)
   local action4 = cc.CallFunc:create(call_back) 
   local seq = cc.Sequence:create(action,action2,action3,action4)

   self.root_node:runAction(seq)
end


return title_panel

