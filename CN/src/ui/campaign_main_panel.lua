local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"

local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local troop_logic = require "logic.troop"
local arena_logic = require "logic.arena"
local campaign_logic = require "logic.campaign"
local spine_manager = require "util.spine_manager"
local lang_constants = require "util.language_constants"
local panel_util = require "ui.panel_util"

local JUMP_CONST = client_constants["JUMP_CONST"]
local PLIST_TYPE = ccui.TextureResType.plistType

local function ScrollAllLayer(list,offset)
    local list2_offset_y = offset * 0.73
    local list3_offset_y = offset * 0.46
    local list4_offset_y = offset * 0.15
    local list_offset_y = {list2_offset_y,list3_offset_y,list4_offset_y}
    for i = 1, 3 do
        list[i]:getInnerContainer():setPositionY(list_offset_y[i])
    end
end

local campaign_main_panel = panel_prototype.New()
function campaign_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/campaign_panel.csb")
    local root_node = self.root_node

    -- 返回
    self.back_btn = root_node:getChildByName("back_btn")

    -- 规则按钮
    self.rule_btn = root_node:getChildByName("refresh_btn")

    -- 排行按钮
    self.rank_btn = root_node:getChildByName("ladder_btn")

    -- 合战奖励
    self.reward_btn = root_node:getChildByName("ext_exchange_btn")

    self.cat1_bg = root_node:getChildByName("cat1")
    self.cat1_bg:setVisible(false)

    self.cat2_bg = root_node:getChildByName("cat2")
    self.cat2_bg:setVisible(false)

    -- 经验背景框
    local exp_img = root_node:getChildByName("exp_bg")
    -- BUFF按钮
    self.buff_btn = exp_img:getChildByName("levelup_btn")
    -- 经验值
    self.exp_txt = exp_img:getChildByName("num")

    -- 标题背景框
    local titleBg = root_node:getChildByName("title_bg")
    -- 排名
    self.rank_txt = titleBg:getChildByName("ladder_value")
    -- 赛点
    self.score_txt = titleBg:getChildByName("point_value")
    -- 排名奖励
    self.reward_value = titleBg:getChildByName("reward_value")

    -- 战斗限制次数
    self.challenge_num_img = root_node:getChildByName("times_bg")
    -- 剩余战斗次数
    self.count_txt = self.challenge_num_img:getChildByName("num")
    -- 增加战斗次数
    self.count_btn = self.challenge_num_img:getChildByName("btn")

    self.level_list2 = root_node:getChildByName("levelList2")
    self.level_list3 = root_node:getChildByName("levelList3")

    self.level_list4 = root_node:getChildByName("levelList4")

    self.level_adder_list = {self.level_list2,self.level_list3,self.level_list4}
    self.level_base_pos = {self.level_list2:getPositionY(),self.level_list3:getPositionY(),self.level_list3:getPositionY()}

    -- 初始化塔身模板
    local tower_body_template = root_node:getChildByName("tower_body_template")
    tower_body_template:setVisible(false)
    -- 塔列表
    self.level_list = root_node:getChildByName("levelList")
    self.level_list:addScrollViewEventListener(function (sender,event_type)
        if event_type ~= ccui.ScrollViewEventType.scrolling then
            return
        end
        local pos = sender:getInnerContainer():getPositionY()
        ScrollAllLayer(self.level_adder_list,pos)
    end)

    local tower_top_template = root_node:getChildByName("tower_top_template")
    tower_top_template:setVisible(true)
    tower_top_template:removeFromParent()
    self.cat2_btn = tower_top_template:getChildByName("cat2_btn")
    self.cat2_node = tower_top_template:getChildByName("node_cat2")

    local end_story = tower_top_template:getChildByName("end_story")
    self.tower_library_btn = end_story:getChildByName("bg")

    local tower_bottom_template = root_node:getChildByName("tower_bottom_template")
    tower_bottom_template:setVisible(false)
    tower_bottom_template:removeFromParent()
    self.cat1_btn = tower_bottom_template:getChildByName("cat1_btn")


    -- 关卡模板
    local tower_level_template = root_node:getChildByName("tower_level_template")
    tower_level_template:setVisible(false)

    self.tower_level_list = {}
    self.tower_cd_list = {}
    self.tower_cd_str = {}
    self.tower_time_list = {}
    self.tower_num_list = {}

    local tower_body_list = {}
    local num = 1
    local body = nil

    local is_first_tower = true

    for i=1, (#campaign_logic.level_info_list / 5) do
        if is_first_tower then
            body = tower_bottom_template
            is_first_tower = false
        else
            body = tower_body_template:clone()
        end
        body:setVisible(true)
        table.insert(tower_body_list, body)
    end

    self.level_list:addChild(tower_top_template)
    for i = #tower_body_list,1,-1 do
        self.level_list:addChild(tower_body_list[i])
    end

    self.level_list:setItemsMargin(-36)
    self.level_list:refreshView()

    local time_info = time_logic:GetDateInfo(time_logic:Now())
    local campaign_spine_name = "campaign"
    if time_logic:IsFestivalDuration(time_info, "spring") then
       campaign_spine_name = "campaign_newyear"
    end

    local spine_node = spine_manager:GetNode(campaign_spine_name, 1.0, true)
    spine_node:setPosition(251, 0)
    spine_node:setToSetupPose()
    spine_node:setAnimation(0, "template3", true)
    tower_body_list[1]:addChild(spine_node)

    local cat2_spine = spine_manager:GetNode("cat2", 1.0, true)
    cat2_spine:setAnimation(0, "cat2", true)
    self.cat2_node:addChild(cat2_spine)

    local num = 1
    local y_index = 0
    for i = 1, #campaign_logic.level_info_list do
        local template = tower_level_template:clone()
        template:setVisible(true)
        self.tower_level_list[campaign_logic.level_info_list[i].level_id] = template
        local xx = client_constants["CAMPAIGN_TOWER_POSITION"][num][1]
        local yy = client_constants["CAMPAIGN_TOWER_POSITION"][num][2] + y_index * 260 + 30
        template:setPosition(xx, yy)
        tower_body_list[1]:addChild(template)
        num = num + 1
        if num > 5 then
            num = 1
            y_index = y_index + 1
        end

        local sp = cc.Sprite:createWithSpriteFrameName("campaign/round_shade.png")
        local left = cc.ProgressTimer:create(sp)
        left:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
        left:setPercentage(100)
        left:setPosition(cc.p(45, 45))
        left:setScale(1.0)
        left:setOpacity(220)
        left:setReverseDirection(true)
        left:setVisible(false)

        template:addChild(left, 2)
        self.tower_cd_list[i] = left
    end

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function campaign_main_panel:Show()
    self.root_node:setVisible(true)

    self:RefreshMainProp()

    self.level_list:jumpToBottom()

    for k,v in pairs(campaign_logic.level_info_list) do
        self:SetTowerLevelInfo(v)
    end

    local pos_x,pos_y = self.level_list:getInnerContainer():getPosition()
    local offset = self.cur_tower - 1
    self.level_list:getInnerContainer():setPosition(cc.p(pos_x, offset * -230))
    ScrollAllLayer(self.level_adder_list,offset * -230)

    if campaign_logic.status ==  constants.CAMPAIGN_STATUS.reward then
        if campaign_logic:IsQueryRewardInfo() then
            campaign_logic:QueryRewardInfo()
        else
            graphic:DispatchEvent("show_world_sub_panel", "campaign_reward_msgbox")
        end
    else
        --如果没有查看过规则
        if not campaign_logic.has_view_rule then
            campaign_logic:QueryRuleInfo()
        end
    end

    --  合战界面已经完整的显示出来了
    graphic:DispatchEvent("jump_finish",JUMP_CONST["pvp_campaign"])  
end

-- 刷新主属性
function campaign_main_panel:RefreshMainProp()
    if campaign_logic.rank == 0  then
        self.rank_txt:setString("---")
    else
        self.rank_txt:setString(campaign_logic.rank)
    end
    self.score_txt:setString(campaign_logic.score)
    self.exp_txt:setString(campaign_logic.exp)
    self.count_txt:setString(campaign_logic.challenge_num)

    self.reward_value:setString(0)
    local rank = campaign_logic.rank
    for i,v in pairs(campaign_logic.top_score_list) do
        if v.min<=rank and v.max >= rank then
            self.reward_value:setString(v.value)
        end
    end
end

-- 设置关卡界面
function campaign_main_panel:SetTowerLevelInfo(data)
    if not data then
        return
    end
    local level_widget = self.tower_level_list[data.level_id]
    level_widget:setTouchEnabled(false)

    local level_num = level_widget:getChildByName("level_num")
    local lockicon = level_widget:getChildByName("lockicon")
    local bossicon = level_widget:getChildByName("bossicon")
    local countdown = level_widget:getChildByName("countdown")
    local successicon = level_widget:getChildByName("successicon")
    local new_text = level_widget:getChildByName("win_icon_new2")
    new_text:setString(lang_constants:Get("campaign_level_new_icon"))
    panel_util:SetTextOutline(new_text)
    
    if not self.tower_cd_str[data.level_id] then
        self.tower_cd_str[data.level_id] = countdown
    end
    if not self.tower_num_list[data.level_id] then
        self.tower_num_list[data.level_id] = level_num
    end
    level_num:setColor(panel_util:GetColor4B(0xffffff))

    lockicon:setLocalZOrder(1)
    lockicon:setVisible(false)
    bossicon:setLocalZOrder(1)
    bossicon:setVisible(false)
    countdown:setLocalZOrder(3)
    countdown:setVisible(false)
    level_num:setVisible(true)
    successicon:setVisible(false)
    new_text:setVisible(false)
    if data.status == "lock" then -- 关卡尚未开放
        lockicon:setVisible(true)
        level_num:setVisible(false)
    else
        if data.status == "new" then
            new_text:setVisible(true)
        end

        self.cur_tower = math.ceil(data.level_id / 5)
        level_num:setString(data.level_id)
        level_widget:setTouchEnabled(true)
        level_widget.data = data
        level_widget:addTouchEventListener(self.challenge_method)
    end
    local t_now = time_logic:Now()
    if not data.next_battle_time or t_now >= data.next_battle_time then
        self.tower_cd_list[data.level_id]:setVisible(false)
    else
        self.tower_cd_list[data.level_id]:setVisible(true)
        self.tower_time_list[data.level_id] = true
    end

    if data.is_boss == 1 then
        if data.status == "limit" then
            bossicon:setVisible(false)
            level_num:setVisible(false)
            successicon:setVisible(true)
            successicon:loadTexture("campaign/round_success.png", PLIST_TYPE)
            successicon:ignoreContentAdaptWithSize(true)
        else
            bossicon:setVisible(true)
            successicon:setVisible(false)
        end
    else
        successicon:setVisible(false)
    end
end

function campaign_main_panel:Update(elapsed_time)

    local t_now = time_logic:Now()
    for k, v in pairs(self.tower_time_list) do
        if v then
            local next_battle_time = campaign_logic.level_info_list[k].next_battle_time
            local start_battle_time = campaign_logic.level_info_list[k].start_battle_time
            local diff_time = next_battle_time - start_battle_time
            if t_now <= next_battle_time then
                local last_time = next_battle_time - t_now
                self.tower_cd_list[k]:setPercentage(last_time*100/diff_time)
                self.tower_cd_str[k]:setVisible(true)
                self.tower_cd_str[k]:setString(math.ceil(last_time).."s")
                self.tower_num_list[k]:setColor(panel_util:GetColor4B(0x717171))
            else
                self.tower_num_list[k]:setColor(panel_util:GetColor4B(0xffffff))
                self.tower_cd_str[k]:setVisible(false)
                self.tower_time_list[k] = false
                self.tower_cd_list[k]:setVisible(false)
                self.tower_cd_list[k]:setPercentage(100)
            end
        end
    end

end

function campaign_main_panel:RegisterEvent()
    graphic:RegisterEvent("update_campaign_main_exp", function()
        self.exp_txt:setString(campaign_logic.exp)
    end)

    graphic:RegisterEvent("update_campaign_main_score", function()
        self.score_txt:setString(campaign_logic.score)
    end)

    graphic:RegisterEvent("update_campaign_level", function(level_data)
        self:SetTowerLevelInfo(level_data)
    end)

    graphic:RegisterEvent("update_campaign_main", function()
        self:RefreshMainProp()
    end)
end

function campaign_main_panel:RegisterWidgetEvent()

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "pvp_sub_scene")
        end
    end)

    self.rule_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not campaign_logic:IsQueryRuleInfo() then
                campaign_logic:QueryRuleInfo()
            else
                graphic:DispatchEvent("show_world_sub_panel", "campaign_rule_msgbox")
            end
        end
    end)

    self.rank_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            campaign_logic:QueryRankInfo()
        end
    end)

    self.reward_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if campaign_logic:IsQueryRewardInfo() then
                campaign_logic:QueryRewardInfo()
            else
                graphic:DispatchEvent("show_world_sub_panel", "campaign_reward_msgbox")
            end
        end
    end)

    self.buff_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            campaign_logic:QueryBuffInfo()
        end
    end)

    self.challenge_method = function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            local level_data = widget.data

            if campaign_logic.status ~= constants.CAMPAIGN_STATUS.game then
                graphic:DispatchEvent("show_prompt_panel", "campaign_game_enough")
                return
            end

            if campaign_logic:SetExeLevelId(level_data.level_id) then
                graphic:DispatchEvent("show_world_sub_panel", "campaign_event_msgbox", client_constants["CAMPAIGN_MSGBOX_MODE"]["campaign"], level_data)
            else
                graphic:DispatchEvent("show_prompt_panel", "campaign_boss_limit")
            end
        end
    end

    self.challenge_num_img:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            campaign_logic:QueryOverTimeInfo()
        end
    end)

    self.tower_library_btn:addTouchEventListener(function (widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            graphic:DispatchEvent("show_world_sub_panel", "campaign_library_msgbox")
        end
    end)

    self.cat1_btn:addTouchEventListener(function (widget, event_type )
        if event_type == ccui.TouchEventType.began then
            local x,y = widget:getPosition()
            local pos = widget:getParent():convertToWorldSpaceAR(cc.p(x,y));
            pos.x = pos.x - 300
            pos.y = pos.y + 100
            self.cat1_bg:setPosition(pos)
            self.cat1_bg:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.cat1_bg:setVisible(false)
        end
    end)

    self.cat2_btn:addTouchEventListener(function (widget, event_type )
        if event_type == ccui.TouchEventType.began then
            local x,y = widget:getPosition()
            local pos = widget:getParent():convertToWorldSpaceAR(cc.p(x,y));
            pos.x = pos.x - 240
            pos.y = pos.y + 50
            self.cat2_bg:setPosition(pos)
            self.cat2_bg:setVisible(true)
        elseif event_type == ccui.TouchEventType.ended or event_type == ccui.TouchEventType.canceled then
            self.cat2_bg:setVisible(false)
        end
    end)

end

return campaign_main_panel
