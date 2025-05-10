local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"

local arena_logic = require "logic.arena"
local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local panel_util  = require "ui.panel_util"
local user_logic = require "logic.user"
local campaign_logic = require "logic.campaign"
local server_pvp_logic = require "logic.server_pvp"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"
local ladder_tower_logic = require "logic.ladder_tower"
local destiny_weapon_logic = require "logic.destiny_weapon"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local PERMANENT_MARK = constants["PERMANENT_MARK"]
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local SUB_PANEL_OFFSET_POS_Y = client_constants["PVP_MAIN_SUB_PANEL_OFFSET_POS_Y"]
local NODE_BEG_POS_Y = 780
local NODE_OFFSET_POS_Y = 190
local CAMPAIGN_DESC_OFFSET_Y = 15
local CAMPAIGN_CD_OFFSET_Y = -10
local MAX_TEMPLENT_COUNT = 4
local MORE_TEMPLENT_OFFSET = 20

local JUMP_CONST = client_constants["JUMP_CONST"] 

local pvp_main_panel = panel_prototype.New()

function pvp_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/pvp_main_panel.csb")

    self.scrollView = self.root_node:getChildByName("ScrollView_1")

    self.ladder_bg_img = self.scrollView:getChildByName("ladder")
    self.cur_rank_text = self.ladder_bg_img:getChildByName("rank")
    self.ladder_pos_y = self.ladder_bg_img:getPositionY()
    
    self.arena_bg_img = self.scrollView:getChildByName("arena")
    self.arena_challenge_cd_text = self.arena_bg_img:getChildByName("cd")
    self.arena_pos_y = self.arena_bg_img:getPositionY()

    self.campaign_bg_img = self.scrollView:getChildByName("campaign")
    self.campaign_desc_txt = self.campaign_bg_img:getChildByName("desc")
    self.campaign_name_txt = self.campaign_bg_img:getChildByName("name")
    self.campaign_cd_txt = self.campaign_bg_img:getChildByName("cd")

    self.ladder_tournament_bg_img = self.scrollView:getChildByName("ladder_tournament")
    if self.ladder_tournament_bg_img then
        self.ladder_tournament_bg_img:setVisible(false)
    end

    --r2合战上面的显示文字放不下，用两行显示
    if platform_manager:GetChannelInfo().pvp_main_panel_campaign_child_show_two_line then
       self.campaign_desc_txt:setPositionY(self.campaign_desc_txt:getPositionY()+CAMPAIGN_DESC_OFFSET_Y)
       local desc_icon = self.campaign_bg_img:getChildByName("arrow")
       desc_icon:setPositionY(desc_icon:getPositionY()+CAMPAIGN_DESC_OFFSET_Y)

       self.campaign_cd_txt:setPositionY(self.campaign_cd_txt:getPositionY()+CAMPAIGN_CD_OFFSET_Y)
       local cd_icon = self.campaign_bg_img:getChildByName("time_icon")
       cd_icon:setPositionY(cd_icon:getPositionY()+CAMPAIGN_CD_OFFSET_Y)
    end

    if feature_config:IsFeatureOpen("server_pvp") then
        self.server_pvp_bg_img = self.scrollView:getChildByName("server_pvp")
        self.server_pvp_desc_txt = self.server_pvp_bg_img:getChildByName("desc")
        self.server_pvp_cd_txt = self.server_pvp_bg_img:getChildByName("cd")
        self.server_pvp_pos_y = self.server_pvp_bg_img:getPositionY()
    else
        self.server_pvp_bg_img = self.scrollView:getChildByName("server_pvp")
        if self.server_pvp_bg_img then
            self.server_pvp_bg_img:setVisible(false) 
        end
    end

    if feature_config:IsFeatureOpen("ladder_grade") then
        --宿命远征
        self.ladder_tournament_bg_img:setVisible(true)
        self.ladder_tournament_cd_text = self.ladder_tournament_bg_img:getChildByName("cd")
        self.ladder_tournament_desc_text = self.ladder_tournament_bg_img:getChildByName("desc")
    end

    self:RegisterWidgetEvent()
end

function pvp_main_panel:Show()
    self.root_node:setVisible(true)
    
    local rank = ladder_logic:GetCurrentRank()
    if platform_manager:GetChannelInfo().meta_channel == "txwy" or platform_manager:GetChannelInfo().meta_channel == "txwy_dny" then
        if rank <= 0 then
            rank = "5000+"
        end
    end
    
    self.cur_rank_text:setString(rank) 
    self.duration = time_logic:GetDurationToFixedTime(arena_logic.refresh_time)
    self.campaign_time_duration = 0

    local node_list = {}
    -- 合战栏目
    local is_campaign_opening = campaign_logic:IsOpen()
    self.campaign_bg_img:setVisible(is_campaign_opening)

    if is_campaign_opening then
        self.campaign_time_duration = time_logic:GetDurationToFixedTime(campaign_logic.end_time)
        self.campaign_name_txt:setString(campaign_logic.title)
        self.campaign_desc_txt:setString(campaign_logic.info)
        self.campaign_cd_txt:setString(panel_util:GetTimeStr(self.campaign_time_duration))
        table.insert(node_list, self.campaign_bg_img)
    end

    table.insert(node_list, self.ladder_bg_img)
    table.insert(node_list, self.arena_bg_img)

    if self.server_pvp_bg_img then
        if server_pvp_logic.cur_season_end_time ~= 0 or server_pvp_logic.next_season_beg_time ~= 0 then
            table.insert(node_list, self.server_pvp_bg_img)
        else
            self.server_pvp_bg_img:setVisible(false)
        end
    end

    --天梯赛
    if feature_config:IsFeatureOpen("ladder_grade") then
        table.insert(node_list, self.ladder_tournament_bg_img)
        --设置按钮上的额名字
        if self.ladder_tournament_bg_img then
            self.ladder_tournament_bg_img:getChildByName("name"):setString(lang_constants:Get("ladder_towerment_name"))
        end
        --检查时间是否结束
        ladder_tower_logic:CheckNewSeason()
    else
        self.ladder_tournament_bg_img:setVisible(false)
    end
    
    local need_height = self.scrollView:getContentSize().height
    local offset_y = math.max(math.min((MAX_TEMPLENT_COUNT - #node_list), 1) * NODE_OFFSET_POS_Y, 0) + MORE_TEMPLENT_OFFSET 
    
    local max_height = #node_list * NODE_OFFSET_POS_Y
    if max_height > need_height then
        need_height = max_height 
        offset_y =  MORE_TEMPLENT_OFFSET
    end
    
    self.scrollView:setInnerContainerSize(cc.size(self.scrollView:getContentSize().width,need_height ))

    for index,node in ipairs(node_list) do
        node:setPositionY(need_height - NODE_OFFSET_POS_Y * (index - 0.5) - offset_y)
    end
    
    --  PVP界面已经完整的显示出来了
    graphic:DispatchEvent("jump_finish",JUMP_CONST["pvp"]) 
end

function pvp_main_panel:ShowServerPvpTimeStr()
    if self.server_pvp_bg_img then
        local t_now = time_logic:Now()

        self.server_pvp_bg_img:setVisible(true)
        self.server_pvp_cd_txt:setVisible(true)

        if server_pvp_logic.cur_season_end_time == 0 and server_pvp_logic.next_season_beg_time == 0 then
            self.server_pvp_bg_img:setVisible(false)
        elseif server_pvp_logic.cur_season_end_time > t_now then
            self.server_pvp_time_duration = time_logic:GetDurationToFixedTime(server_pvp_logic.cur_season_end_time)
            self.server_pvp_cd_txt:setString(panel_util:GetTimeStr(self.server_pvp_time_duration))
            self.server_pvp_desc_txt:setString(lang_constants:Get("server_pvp_cool_down_end"))
        elseif server_pvp_logic.next_season_beg_time > t_now then
            self.server_pvp_time_duration = time_logic:GetDurationToFixedTime(server_pvp_logic.next_season_beg_time)
            self.server_pvp_cd_txt:setString(panel_util:GetTimeStr(self.server_pvp_time_duration))
            self.server_pvp_desc_txt:setString(lang_constants:Get("server_pvp_cool_down_next"))
        elseif server_pvp_logic.next_season_beg_time > 0 then
            server_pvp_logic:QueryServerPvpSeason()
        else
            self.server_pvp_cd_txt:setVisible(false)
            self.server_pvp_desc_txt:setString(lang_constants:Get("server_pvp_no_next"))
        end
    end
end

function pvp_main_panel:ShowLadderTowerTimeStr(elapsed_time)
    if not feature_config:IsFeatureOpen("ladder_grade") then
        self.ladder_tournament_bg_img:setVisible(false)
        return 
    end

    local t_now = time_logic:Now()
    if ladder_tower_logic.end_time >= t_now then
        --没有结束
        local duration = 0
        if ladder_tower_logic.countdown > t_now then
            --在准备开始
            duration = ladder_tower_logic.countdown - t_now
                
            self.ladder_tournament_desc_text:setString(lang_constants:Get("ladder_start_before_text"))
        elseif ladder_tower_logic.duration > t_now then
            --正在开战中
            duration = ladder_tower_logic.duration - t_now
            self.ladder_tournament_desc_text:setString(lang_constants:Get("ladder_start_now_text"))
        elseif ladder_tower_logic.duration <= t_now then
            --休战中
            duration = ladder_tower_logic.end_time - t_now
            self.ladder_tournament_desc_text:setString(lang_constants:Get("ladder_start_end_text"))
        end
        self.ladder_tournament_cd_text:setString(panel_util:GetTimeStr(duration))
    else
        --赛季结束
        self.ladder_tournament_desc_text:setString(lang_constants:Get("ladder_end_desc"))
        self.ladder_tournament_cd_text:setString(panel_util:GetTimeStr(0))
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

    if feature_config:IsFeatureOpen("server_pvp") then
        self:ShowServerPvpTimeStr()
    end

    --宿命远征
    if true then
        self:ShowLadderTowerTimeStr(elapsed_time)
    end

end

function pvp_main_panel:RegisterWidgetEvent()
    -- 资源跳转
    graphic:RegisterEvent("change_to_sub_pvp", function(index) 
            if index == JUMP_CONST["pvp_arena"] then
                if self.arena_bg_img:isVisible() then
                    arena_logic:Query()
                end
            elseif index == JUMP_CONST["pvp_qualifying"] then
                if self.ladder_bg_img:isVisible() then
                    if user_logic:IsFeatureUnlock(FEATURE_TYPE["ladder"]) then
                        ladder_logic:Query()
                    end
                end 
            elseif index == JUMP_CONST["pvp_campaign"] then
                if user_logic.base_info.create_time <= 1452614400 or user_logic:IsFeatureUnlock(FEATURE_TYPE["campaign"], true) then
                    if campaign_logic:IsQueryLevelInfo() then
                        campaign_logic:QueryLevelInfo()
                    else
                        graphic:DispatchEvent("show_world_sub_scene", "campaign_sub_scene")
                    end
                end    
            end
        end)
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

    if self.server_pvp_bg_img then
        self.server_pvp_bg_img:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                local t_now = time_logic:Now()
                if server_pvp_logic.cur_season_end_time == 0 then
                    graphic:DispatchEvent("show_prompt_panel", "server_pvp_no_next")
                else
                    server_pvp_logic:QueryServerPvpInfo()
                end
            end
        end)
    end
    if self.ladder_tournament_bg_img then
        self.ladder_tournament_bg_img:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                local t_now = time_logic:Now()
                if ladder_tower_logic.end_time >= t_now and ladder_tower_logic.start_time < t_now then
                    --没有结束
                    print("destiny_weapon_logic:GetWeaponNum() == ",destiny_weapon_logic:GetWeaponNum())
                    if destiny_weapon_logic:GetWeaponNum() >= constants["LADDER_OPEN_NEED_WEAPON_NUM"] then
                        graphic:DispatchEvent("show_world_sub_scene", "ladder_tournament_sub_scene")
                    else
                        graphic:DispatchEvent("show_prompt_panel", "weapons_not_enough")
                    end
                else
                    --赛季结束
                    graphic:DispatchEvent("show_prompt_panel", "ladder_end_desc")
                end
                
            end
        end)
    end
end

return pvp_main_panel
