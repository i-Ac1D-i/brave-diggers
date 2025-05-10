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


local settlement_step1_panel = panel_prototype.New(true)
function settlement_step1_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/guildwar_settlement1_panel.csb")

    self.time_line_action = animation_manager:GetTimeLine("guildwar_settlement_step1_timeline")
    self.root_node:runAction(self.time_line_action)
    self.time_line_action:play("ani_lv_in", false)

    self.ani_node = self.root_node:getChildByName("load_ani")
    self.tier_text = self.root_node:getChildByName("lv_num")

    self.num_node = self.root_node:getChildByName("chain_point")
    self.num_text = self.num_node:getChildByName("num")

    self.tier_spine_node = spine_manager:GetNode("box_all", 1.0, true)
    self.tier_spine_node:setPosition(self.ani_node:getContentSize().width / 2, self.ani_node:getContentSize().height / 2)
    self.ani_node:addChild(self.tier_spine_node)
    self.tier_spine_node:setTimeScale(1.0)

    self.has_show = false

    self:RegisterWidgetEvent()
end

function settlement_step1_panel:RefreshTierNode( score )
    local tier = guild_logic:GetGuildTier(score)
	
    self.tier_spine_node:setToSetupPose()

    if tier == 1 then
    	self.tier_spine_node:setAnimation(0, "rank_black2_in", false)
    	self.tier_spine_node:addAnimation(0, "rank_black2_loop", true)

		self.tier_text:setString("")
    else
    	self.tier_spine_node:setAnimation(0, "rank_black_in", false)
    	self.tier_spine_node:addAnimation(0, "rank_black_loop", true)

		self.tier_text:setString(tostring(tier))
    end
    
	self.num_text:setString(tostring(score))
end

function settlement_step1_panel:Show()
	self:RefreshTierNode(guild_logic:GetOldScore())
	
    self.has_show = false
    self.num_node:setScale(1)
    self.ani_node:setScale(1)
    self.tier_text:setScale(1)
	
    self.root_node:setVisible(true)
end

function settlement_step1_panel:RegisterWidgetEvent()
	
	self.tier_spine_node:registerSpineEventHandler(function(event)
		if event.animation == "rank_black_in" or event.animation == "rank_black2_in" then
			if not self.has_show then
				self.has_show = true
				local times = 0
				schedule(self.num_text, function ()
					if times < 40 then
						times = times + 1
						self.num_text:setString(tostring(math.ceil(guild_logic:GetOldScore() + (guild_logic:GetScore() - guild_logic:GetOldScore()) * (times / 40))))
					else
						self.num_text:stopAllActions()
						self:RefreshTierNode(guild_logic:GetScore()) 
					end
				end, 0.01)
			else
			    local seq_action = cc.Sequence:create(	cc.DelayTime:create(0.5),
				                                        cc.CallFunc:create(function()
															self.num_node:runAction(cc.ScaleTo:create(0.3, 0, 0))
															self.ani_node:runAction(cc.ScaleTo:create(0.3, 0, 0))
															self.tier_text:runAction(cc.ScaleTo:create(0.3, 0, 0))
				                                        end),
				                                        cc.DelayTime:create(0.3),
				                                        cc.CallFunc:create(function()
	       													graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        													graphic:DispatchEvent("show_world_sub_panel", "guild.settlement_step2_panel")
				                                        end)
			                                        )
			    self.root_node:runAction(seq_action)
			end
		end
    end, sp.EventType.ANIMATION_COMPLETE)

    
end

return settlement_step1_panel

