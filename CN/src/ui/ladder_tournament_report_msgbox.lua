local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local icon_panel = require "ui.icon_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local ladder_tower_logic = require "logic.ladder_tower"
local time_logic = require "logic.time"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType


local ladder_tournament_report_msgbox = panel_prototype.New(true)
function ladder_tournament_report_msgbox:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/ladder_tournament_report_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("confirm_btn")

    --新赛季公告
    self.new_season = self.root_node:getChildByName("new_season")

    self.new_season_level_img = self.new_season:getChildByName("Image_9")

    --赛季结束公告
    self.end_season = self.root_node:getChildByName("report")

    --结算描述文字
    self.end_season_desc_text = self.end_season:getChildByName("desc")

    self.end_season_level_img = self.end_season:getChildByName("Image_9")

    self.end_season_rank_text = self.end_season:getChildByName("desc_0_1")
    panel_util:SetTextOutline(self.end_season_rank_text)

    self.reward_node = self.end_season:getChildByName("bonuses")

    self.reward_sub_panels = {}

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function ladder_tournament_report_msgbox:Show()
    self.root_node:setVisible(true)
    local now_time = time_logic:Now()
    self.show_end_season = false 
    if now_time <= ladder_tower_logic.duration then
        --赛季开始
        if not ladder_tower_logic.is_close_tab then
            self.new_season:setVisible(true)
            self.end_season:setVisible(false)
            local pre_group = ladder_tower_logic.pre_group or 1
            if pre_group then
                self.new_season_level_img:setVisible(true)
                self.new_season_level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][pre_group], PLIST_TYPE)
            else
                self.new_season_level_img:setVisible(false)
            end
        else
            --已经阅读过了
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    else
        --赛季结束
        self.show_end_season = true
        self.new_season:setVisible(false)
        self.end_season:setVisible(true)
        self.end_season_rank_text:setString("")
        --删除旧的icon
        for k,reward_sub_panel in ipairs(self.reward_sub_panels) do
            reward_sub_panel.root_node:removeFromParent()
        end
        local rank_info = ladder_tower_logic:GetSelfRankInfo() or {}
        local pre_group = rank_info.group or 1
        local pre_rank = rank_info.rank or 1
        if pre_group then
            self.end_season_level_img:setVisible(true)
            self.end_season_desc_text:setString(string.format(lang_constants:Get("ladder_end_text_desc"),lang_constants:Get("ladder_level_"..pre_group)))
            self.end_season_level_img:loadTexture(client_constants["LADDER_LEVEL_L_IMG_TYPE"][pre_group], PLIST_TYPE)
            if rank_info.rank then
                self.end_season_rank_text:setString(lang_constants:Get("end_season_rank_desc")..rank_info.rank)
            else
                self.end_season_rank_text:setString(lang_constants:Get("end_season_no_rank_desc"))
            end

            local reward_list = ladder_tower_logic.reward_list
            local rewrd_info = {}
            for k,info in pairs(reward_list) do
                if info.group_type == pre_group  then
                    if info.min_rank == info.max_rank then
                        if info.min_rank > 0 then
                            if info.max_rank == pre_rank then
                                --这个就是第几名
                                rewrd_info = info.reward_info
                                break
                            end
                        else
                            --这个是全组
                            rewrd_info = info.reward_info
                            break
                        end 
                    else
                        if info.min_rank == 0 then
                            if info.max_rank <= pre_rank then
                                --剩余全部
                                rewrd_info = info.reward_info
                                break
                            end
                        else
                            --在这个区间内
                            if info.max_rank <= pre_rank and info.min_rank >= pre_rank then
                                rewrd_info = info.reward_info
                                break
                            end
                        end
                    end
                end
            end
            --获得的奖励iconf
            
            self.reward_sub_panels = {}

            local reward_config = {}
            local reward_num = 0
            for k,v in pairs(rewrd_info) do
                reward_num = reward_num + 1
                reward_config[constants["RESOURCE_TYPE_NAME"][v.param1]] = v.param2
            end
            for i = 1, reward_num do
                if self.reward_sub_panels[i] == nil then
                    local sub_panel = icon_panel.New()
                    sub_panel:Init(self.reward_node)
                    self.reward_sub_panels[i] = sub_panel
                end
            end
            panel_util:LoadCostResourceInfo(reward_config, self.reward_sub_panels, 0, reward_num, 0, false) 

        else
            self.end_season_level_img:setVisible(false)
        end
    end

end

function ladder_tournament_report_msgbox:RegisterEvent()
    --
    graphic:RegisterEvent("ladder_show_start_season_success", function()
        if not self.root_node:isVisible() then
            return
        end
        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
    end)

    graphic:RegisterEvent("rank_refresh_success", function()
        if not self.root_node:isVisible() then
            return
        end
        self:Show()
    end)
    
end

function ladder_tournament_report_msgbox:RegisterWidgetEvent()
	--关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.show_end_season then
                graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            else
                ladder_tower_logic:IsOpenStartNotice()
            end
        end
    end)
end

return ladder_tournament_report_msgbox

