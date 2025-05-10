local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"

local guild_logic = require "logic.guild"
local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local spine_manager = require "util.spine_manager"

local PLIST_TYPE = ccui.TextureResType.plistType


local settlement_step2_panel = panel_prototype.New(true)
function settlement_step2_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_settlement_panel.csb")

    self.time_line_action = animation_manager:GetTimeLine("guildwar_settlement_step2_timeline")
    self.root_node:runAction(self.time_line_action)

    self.basic_node = self.root_node:getChildByName("basic_point")
    self.basic_num_text = self.basic_node:getChildByName("num")

    self.chain_node = self.root_node:getChildByName("chain_point")
    self.chain_num_text = self.chain_node:getChildByName("num")

    self.win_node = self.root_node:getChildByName("win_point")
    self.win_num_text = self.win_node:getChildByName("num")

    self.spine_node = spine_manager:GetNode("box_all", 1.0, true)
    self.spine_node:setPosition(320, 600)
    self.root_node:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)

    self.is_waiting_for_touch = false

    self:RegisterWidgetEvent()
end

function settlement_step2_panel:Show()

    self.spine_node:setToSetupPose()
	self.spine_node:setAnimation(0, "over_box_in", false)
	self.spine_node:addAnimation(0, "over_box_open", false)

	local base_score, field_score, round_score, kill_score = guild_logic:GetMemberWarScoreDetail()
	self.basic_num_text:setString(tostring(base_score))
	self.chain_num_text:setString(tostring(kill_score))
	self.win_num_text:setString(tostring(field_score))

    self.is_waiting_for_touch = false

    self.root_node:setVisible(true)
end

function settlement_step2_panel:RegisterWidgetEvent()


	self.spine_node:registerSpineEventHandler(function(event)
		if event.animation == "over_box_open" then
    		self.time_line_action:play("ani_box_in", false)
			self.is_waiting_for_touch = true
        elseif event.animation == "over_box_close" then
            local seq_action = cc.CallFunc:create(  function()
                                                        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                                                    end)
            self.root_node:runAction(seq_action)
		end
    end, sp.EventType.ANIMATION_COMPLETE)


    local touch_func = function(touch, event)
		self.time_line_action:play("ani_box_out", false)
        self.spine_node:setAnimation(0, "over_box_close", false)
    end

    local touch_listener = cc.EventListenerTouchOneByOne:create()
    touch_listener:registerScriptHandler(function(touch, event)
    	if self.is_waiting_for_touch == true then
    		self.is_waiting_for_touch = false
        	return true
        else
        	return false
        end
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    
    touch_listener:registerScriptHandler(touch_func, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touch_listener, self.root_node)
end

return settlement_step2_panel

