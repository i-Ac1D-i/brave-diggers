local sub_scene = require "scene.sub_scene"

local spine_manager = require "util.spine_manager"
local audio_manager = require "util.audio_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local quest_logic = require "logic.quest"
local carnival_logic = require "logic.carnival"
local constants = require "util.constants"
local client_constants = require "util.client_constants"

local main_sub_scene = sub_scene.New()
function main_sub_scene:Init()
    self.root_node = cc.Node:create()

    self.root_node:registerScriptHandler(function(event)
        if event == "enter" then
            local main_spine_name 
            local time_info = time_logic:GetDateInfo(time_logic:Now())

            if time_info.hour >= 6 and time_info.hour < 18 then  
                main_spine_name = "main_page_am"
            else
                main_spine_name = "main_page_pm"
            end
            self.main_spine_node = spine_manager:GetNode(main_spine_name, 1.0, true)
            
            self.main_spine_node:setPosition(320, 568)
            self.root_node:addChild(self.main_spine_node)
            self.main_spine_node:setTimeScale(1.0)
            self.main_spine_node:setAnimation(0, "main", true)

            -- 邮箱动画
            local mail_spine_name = "mailbox_tip"
            self.mailbox_spine_node = spine_manager:GetNode(mail_spine_name, 1.0, true)
            self.mailbox_spine_node:setPosition(cc.p(client_constants["MAIN_SUB_SCENE_MAIL_BOX_POS"]))
            self.root_node:addChild(self.mailbox_spine_node, 0)

            self.ui_root = require "ui.main_panel"
            self.ui_root:Init()

            --左下角收集活动动画
            self.snowman_spine_node = spine_manager:GetNode("box_ani", 1.0, true)
            self.snowman_spine_node:setPosition(62, 610)
            self.root_node:addChild(self.snowman_spine_node, 100)

            self.root_node:addChild(self.ui_root:GetRootNode())

            self:RegisterEvent()

        elseif event == "exit" then

        end
    end)
end

function main_sub_scene:Clear()
    sub_scene.Clear(self)
end

function main_sub_scene:Show()
    self.root_node:setVisible(true)
    self.ui_root:Show()

    local time_info = time_logic:GetDateInfo(time_logic:Now())

    if time_info.hour >= 6 and time_info.hour <= 18 then
        audio_manager:PlayMusic("main_am", true)
    else
        audio_manager:PlayMusic("main_pm", true)
    end

    if quest_logic:HasUnreadMail() then
        self:UpdateMailBoxStatus("newtip")
    else
        self:UpdateMailBoxStatus("normal")
    end

    self:BoxAnimation(time_info.hour)
end

function main_sub_scene:UpdateMailBoxStatus(normal_or_new)
    self.mailbox_spine_node:setAnimation(0, normal_or_new, true)
end

function main_sub_scene:BoxAnimation(hour)
    local spec_type = carnival_logic:GetSpecialVisibleStyle()
    if spec_type and spec_type == 0 then
        self.snowman_spine_node:setVisible(true)

        if hour >= 6 and hour <= 18 then
            self.snowman_spine_node:setAnimation(1, "box_message_am", true)
        else
            self.snowman_spine_node:setAnimation(1, "box_message_pm", true)
        end
    else
        self.snowman_spine_node:setVisible(false)
    end
end

function main_sub_scene:Hide()
    self.root_node:setVisible(false)
    self.ui_root:Hide()
end

function main_sub_scene:Update(elapsed_time)
    self.ui_root:Update(elapsed_time)
end

function main_sub_scene:RegisterEvent()
    graphic:RegisterEvent("update_mailbox_animate", function(animate)
        self:UpdateMailBoxStatus(animate)
    end)
end

return main_sub_scene
