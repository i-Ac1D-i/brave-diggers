local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"

local arena_logic = require "logic.arena"
local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local panel_util  = require "ui.panel_util"
local user_logic = require "logic.user"
local campaign_logic = require "logic.campaign"
local platform_manager = require "logic.platform_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]

local pvp_main_panel = panel_prototype.New()

local CAMPAIGN_DESC_OFFSET_Y = 15

local CAMPAIGN_CD_OFFSET_Y = -10

function pvp_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/pvp_main_panel.csb")

    self.ladder_bg_img = self.root_node:getChildByName("ladder")
    self.cur_rank_text = self.ladder_bg_img:getChildByName("rank")
    self.ladder_pos_y = self.ladder_bg_img:getPositionY()

    self.arena_bg_img = self.root_node:getChildByName("arena")
    self.arena_challenge_cd_text = self.arena_bg_img:getChildByName("cd")
    self.arena_pos_y = self.arena_bg_img:getPositionY()


    self.campaign_bg_img = self.root_node:getChildByName("campaign")

    self.campaign_desc_txt = self.campaign_bg_img:getChildByName("desc")
    self.campaign_name_txt = self.campaign_bg_img:getChildByName("name")
    self.campaign_cd_txt = self.campaign_bg_img:getChildByName("cd")

    --r2合战上面的显示文字放不下，用两行显示
    if platform_manager:GetChannelInfo().pvp_main_panel_campaign_child_show_two_line then
       
       self.campaign_desc_txt:setPositionY(self.campaign_desc_txt:getPositionY()+CAMPAIGN_DESC_OFFSET_Y)
       local desc_icon = self.campaign_bg_img:getChildByName("arrow")
       desc_icon:setPositionY(desc_icon:getPositionY()+CAMPAIGN_DESC_OFFSET_Y)

       self.campaign_cd_txt:setPositionY(self.campaign_cd_txt:getPositionY()+CAMPAIGN_CD_OFFSET_Y)
       local cd_icon = self.campaign_bg_img:getChildByName("time_icon")
       cd_icon:setPositionY(cd_icon:getPositionY()+CAMPAIGN_CD_OFFSET_Y)
       
    end
    
    self:RegisterWidgetEvent()
end

function pvp_main_panel:Show()
    self.root_node:setVisible(true)
    local rank = ladder_logic:GetCurrentRank()
    print("FYD  current rank is = "..rank)

    if platform_manager:GetChannelInfo().meta_channel == "txwy" then
        if type(rank) == "string" then
           rank = tonumber(rank)
        end
        if rank <= 0 then
            rank = "5000+"
        end
    end
    
    self.cur_rank_text:setString(rank) 
    self.duration = time_logic:GetDurationToFixedTime(arena_logic.refresh_time)
    self.campaign_time_duration = 0

    -- 合战栏目
    local is_campaign_opening = campaign_logic:IsOpen()
    self.campaign_bg_img:setVisible(is_campaign_opening)

    if is_campaign_opening then
        self.campaign_time_duration = time_logic:GetDurationToFixedTime(campaign_logic.end_time)
        self.campaign_name_txt:setString(campaign_logic.title)
        self.campaign_desc_txt:setString(campaign_logic.info)
        self.campaign_cd_txt:setString(panel_util:GetTimeStr(self.campaign_time_duration))

        self.ladder_bg_img:setPositionY(self.ladder_pos_y - 90)
        self.arena_bg_img:setPositionY(self.arena_pos_y - 90)
    end
end

function pvp_main_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time
    self.campaign_time_duration = self.campaign_time_duration - elapsed_time

    --时间到了则重新请求数据
    if self.duration <= 0 then
        self.duration = 0
    end
    self.arena_challenge_cd_text:setString(panel_util:GetTimeStr(self.duration))


    if self.campaign_time_duration < 0 then
        self.campaign_time_duration = 0
        self.campaign_bg_img:setVisible(false)
    end
    self.campaign_cd_txt:setString(panel_util:GetTimeStr(self.campaign_time_duration))
end

function pvp_main_panel:RegisterWidgetEvent()

    self.arena_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            arena_logic:Query()
        end
    end)

    self.ladder_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if user_logic:IsFeatureUnlock(FEATURE_TYPE["ladder"]) then
                ladder_logic:Query()
            end
        end
    end)

    self.campaign_bg_img:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            if user_logic.base_info.create_time <= 1452614400 or user_logic:IsFeatureUnlock(FEATURE_TYPE["campaign"]) then
                if campaign_logic:IsQueryLevelInfo() then
                    campaign_logic:QueryLevelInfo()
                else
                    graphic:DispatchEvent("show_world_sub_scene", "campaign_sub_scene")
                end
            end
        end
    end)
end

return pvp_main_panel
