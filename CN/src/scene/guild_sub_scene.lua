local sub_scene = require "scene.sub_scene"
local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local spine_manager = require "util.spine_manager"
local guild_logic = require "logic.guild"
local time_logic = require "logic.time"
local carnival_logic = require "logic.carnival"

local guild_sub_scene = sub_scene.New()

function guild_sub_scene:Init()
    self.root_node = cc.Node:create()

    local time_info = time_logic:GetDateInfo(time_logic:Now())
    local guild_spine_name = "guild"
    if time_logic:IsFestivalDuration(time_info, "spring") then
       guild_spine_name = "guild_newyear"
    end

    self.spine_node = spine_manager:GetNode(guild_spine_name, 1.0, true)
    self.spine_node:setPosition(320, 568)
    self.spine_node:setToSetupPose()
    self.root_node:addChild(self.spine_node)

    self.guild_completed_node = spine_manager:GetNode("guild_completed", 1.0, true)
    self.guild_completed_node:setPosition(320, 568)
    self.guild_completed_node:setToSetupPose()
    self.guild_completed_node:setVisible(false)
    self.root_node:addChild(self.guild_completed_node)

    self.box_node = spine_manager:GetNode("box_ani", 1.0, true)
    self.box_node:setPosition(157, 320)
    self.box_node:setToSetupPose()
    self.box_node:setVisible(false)
    self.root_node:addChild(self.box_node)

    self:SetRememberFromScene(true)

    self.is_create_guild = false
    --[[
    self.spine_node:registerSpineEventHandler(function(event)
        -- print("event = "..json:encode(event))
        if event.eventData.name == "success" and self.is_create_guild then
            self.guild_completed_node:setVisible(true)
            self.guild_completed_node:setAnimation(0, "animation", false)
        end
    end, sp.EventType.ANIMATION_EVENT)
    --]]

    self.guild_completed_node:registerSpineEventHandler(function(event)
        self.guild_completed_node:setVisible(false)
    end, sp.EventType.ANIMATION_END)

    self.root_node:registerScriptHandler(function(event)
        if event == "enter" then
            self.ui_root = require "ui.guild.main_panel"
            self.ui_root:Init()
            self.ui_root:Hide()
            self.root_node:addChild(self.ui_root:GetRootNode())
        elseif event == "exit" then

        end
    end)
    self:RegisterEvent()
end

function guild_sub_scene:Show()
    self.root_node:setVisible(true)

    self:PlayAnimation()
    self:PlayBoxAnimation()
    self.ui_root:Show()
end

function guild_sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()
end

function guild_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

function guild_sub_scene:PlayAnimation()
    if guild_logic:IsGuildMember() then
        self.spine_node:setAnimation(0, "established_loop", true)
    else
        self.spine_node:setAnimation(0, "not_established", true)
    end
end

function guild_sub_scene:PlayBoxAnimation()
    self.box_node:setVisible(false)

    if guild_logic:IsGuildMember() then
        local spec_type = carnival_logic:GetSpecialVisibleStyle()
        if spec_type and spec_type == 1 then
            self.box_node:setVisible(true)
            self.box_node:setAnimation(1, "box_message_am", true)
        end
    end

end

function guild_sub_scene:RegisterEvent()
    graphic:RegisterEvent("exit_guild", function()
        self:PlayAnimation()
        self:PlayBoxAnimation()
    end)

    graphic:RegisterEvent("join_guild", function(is_creator)
        self.spine_node:setAnimation(0, "established", false)
        self.spine_node:addAnimation(0, "established_loop", true)
        self.is_create_guild = is_creator

        self.spine_node:registerSpineEventHandler(function(event)
            self:PlayBoxAnimation()
        end,sp.EventType.ANIMATION_COMPLETE)
    end)
end

return guild_sub_scene
