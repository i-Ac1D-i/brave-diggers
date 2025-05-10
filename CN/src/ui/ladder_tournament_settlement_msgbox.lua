local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local icon_panel = require "ui.icon_panel"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local ladder_tower_logic = require "logic.ladder_tower"
local animation_manager = require "util.animation_manager"
local spine_manager = require "util.spine_manager"

local PLIST_TYPE = ccui.TextureResType.plistType
local LIGHT_SPINE_OFFSET_X = 18


local ladder_tournament_settlement_msgbox = panel_prototype.New(true)
function ladder_tournament_settlement_msgbox:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/ladder_tournament_settlement_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("close_btn")
    self.reward_bg = self.root_node:getChildByName("award_bg")
    self.ok_btn = self.root_node:getChildByName("confirm_btn")

    self.image_panel = self.root_node:getChildByName("image_panel")

    self.level_update_animation_node = cc.CSLoader:createNode("ui/ladder_image.csb")

    self.old_level_img = self.level_update_animation_node:getChildByName("Image_all")
    self.next_level_img = self.level_update_animation_node:getChildByName("Image_new")

    self.root_node:addChild(self.level_update_animation_node,100)
    self.level_update_animation_node:setPosition(self.image_panel:getPosition())

    self.level_update_time_line_action = animation_manager:GetTimeLine("ladder_update_timeline")
    self.level_update_animation_node:runAction(self.level_update_time_line_action)

    self.level_text = self.root_node:getChildByName("name_0")

    local node_score = self.root_node:getChildByName("Node_15")
    self.score_text = node_score:getChildByName("percent_value_skill")
    panel_util:SetTextOutline(self.score_text)
    self.percent_bar = node_score:getChildByName("percent_bar_skill")

    self.light_spine = spine_manager:GetNode("check_in", 1.0, true)
    self.percent_bar:addChild(self.light_spine)
    self.light_spine:setPosition(cc.p(self.percent_bar:getContentSize().width/2 + LIGHT_SPINE_OFFSET_X,self.percent_bar:getContentSize().height/2))
    self.light_spine:setVisible(true)
    self.light_spine:setScale(1.1)

    self.reward_sub_panels = {}
    self:RegisterWidgetEvent()
end

function ladder_tournament_settlement_msgbox:Show(reward_list, old_integral_num, old_level)
    self.root_node:setVisible(true)

    self.old_integral_num = old_integral_num
    self.old_level = old_level

    self.old_level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][self.old_level], PLIST_TYPE)

    self.next_level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][ladder_tower_logic.ladder_level], PLIST_TYPE)

    self.level_text:setString(lang_constants:Get("ladder_level_"..self.old_level))

    self.level_update_time_line_action:play("normal", false)


    --删除旧的icon
    --获得的奖励iconf
    for k,reward_sub_panel in ipairs(self.reward_sub_panels) do
        reward_sub_panel.root_node:removeFromParent()
    end
    self.reward_sub_panels = {}

    local reward_config = {}
    local reward_num = 0
    for k,v in pairs(reward_list) do
        reward_num = reward_num + 1
        reward_config[constants["RESOURCE_TYPE_NAME"][v.param1]] = v.param2
    end

    for i = 1, reward_num do
        if self.reward_sub_panels[i] == nil then
            local sub_panel = icon_panel.New()
            sub_panel:Init(self.reward_bg)
            self.reward_sub_panels[i] = sub_panel
        end
    end
    panel_util:LoadCostResourceInfo(reward_config, self.reward_sub_panels, self.reward_bg:getContentSize().height*2/5, reward_num, self.reward_bg:getContentSize().width/2, false) 

    self.dis_score = 0

    self:InitProgressPercent()

end

function ladder_tournament_settlement_msgbox:InitProgressPercent()
    self.start_progress_percent = self.old_integral_num / ladder_tower_logic:GetNowNeedAllSocre(self.old_level) * 100

    if self.old_level  < ladder_tower_logic.ladder_level then
        self.loading_bar_to = 100
        self.end_score = ladder_tower_logic:GetNowNeedAllSocre(self.old_level)
        self.dis_score = ladder_tower_logic:GetNowNeedAllSocre(self.old_level)- self.old_integral_num
    else
        self.end_score = ladder_tower_logic.integral_num
        self.dis_score = ladder_tower_logic.integral_num - self.old_integral_num
        if ladder_tower_logic:GetNowNeedAllSocre(self.old_level) > 0 then
            self.loading_bar_to = math.min(ladder_tower_logic.integral_num / ladder_tower_logic:GetNowNeedAllSocre(self.old_level) * 100, 100)
        else
            --最大等级了
            self.loading_bar_to = 100
        end
    end
    self.loading_bar_duration = 0.3
    self.speed = (self.loading_bar_to - self.start_progress_percent) / self.loading_bar_duration
    self.speed2 = (self.dis_score) / self.loading_bar_duration
    self.can_play_animation = true
end

function ladder_tournament_settlement_msgbox:Update(elapsed_time)
    
    if self.loading_bar_duration > 0 then
        self.light_spine:setVisible(true)
        self.loading_bar_duration = math.max(self.loading_bar_duration - elapsed_time, 0)

        local show_score = self.end_score - (self.loading_bar_duration * self.speed2)

        local need_score = ladder_tower_logic:GetNowNeedAllSocre(self.old_level)
        if need_score == 0 then
            self.score_text:setString(math.floor(show_score))
            self.percent_bar:setPercent(self.loading_bar_to)
        else
            local percent = self.loading_bar_to - (self.loading_bar_duration * self.speed)
            self.percent_bar:setPercent(percent)
            self.score_text:setString(math.floor(show_score).."/"..need_score)
        end
        
        
        if self.loading_bar_duration <= 0.3 and self.can_play_animation then
            self.can_play_animation = false
            self.light_spine:setAnimation(0, "sign_in", false)
        end
    else
        if self.old_level  < ladder_tower_logic.ladder_level then
            self.old_level = ladder_tower_logic.ladder_level
            self.level_update_time_line_action:play("play", false)
            self.end_score = ladder_tower_logic.integral_num

            local need_score = ladder_tower_logic:GetNowNeedAllSocre(self.old_level)
            if need_score == 0 then
                self.loading_bar_to = 100
            else
                self.loading_bar_to = ladder_tower_logic.integral_num / ladder_tower_logic:GetNowNeedAllSocre(self.old_level) * 100
            end
            self.level_text:setString(lang_constants:Get("ladder_level_"..self.old_level))
        else
            local need_score = ladder_tower_logic:GetNowNeedAllSocre(self.old_level)
            if need_score == 0 then
                self.score_text:setString(self.end_score)
            else
                self.score_text:setString(self.end_score.."/"..need_score)
            end

            self.percent_bar:setPercent(self.loading_bar_to)
        end
    end

end

function ladder_tournament_settlement_msgbox:RegisterWidgetEvent()
	--关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.ok_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

return ladder_tournament_settlement_msgbox

