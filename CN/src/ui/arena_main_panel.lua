local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"
local arena_logic = require "logic.arena"
local social_logic = require "logic.social"
local troop_logic = require "logic.troop"
local vip_logic = require "logic.vip"
local user_logic = require "logic.user"

local time_logic = require "logic.time"
local panel_util = require "ui.panel_util"

local icon_panel = require "ui.icon_panel"
local platform_manager = require "logic.platform_manager"
local feature_config = require "logic.feature_config"

local JUMP_CONST = client_constants["JUMP_CONST"] 

local RIVAL_NUM = 9
local REWARD_COUNT = 3
local REWARD_BTN_BEGIN_POS_Y = 1040
local REWARD_BTN_DISTANCE = 100

--对手的基本信息sub panel
local rival_info_sub_panel = panel_prototype.New()
rival_info_sub_panel.__index = rival_info_sub_panel

function rival_info_sub_panel.New()
    local t = {}
    return setmetatable(t, rival_info_sub_panel)
end

function rival_info_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.index = index

    self.bg_img = root_node:getChildByName("bg")
    self.name_text = root_node:getChildByName("name")
    self.bp_text = root_node:getChildByName("bp_value")

    self.friend_btn = root_node:getChildByName("friend_btn")
    self.friend_btn:setTag(index)

    self.friend_btn_pos_x = self.friend_btn:getPositionX()
    self.friend_btn_pos_y = self.friend_btn:getPositionY()

    self.challenge_btn = root_node:getChildByName("challenge_btn")
    self.challenge_btn:setTag(index)

    self.win_icon_img = root_node:getChildByName("win_icon_new")
    self.win_icon_img:setVisible(false)

    self.icon_panel = icon_panel.New(nil, client_constants["ICON_TEMPLATE_MODE"]["no_text"])
    self.icon_panel:Init(root_node)
    self.icon_panel:SetPosition(60, 60)

end

function rival_info_sub_panel:ReLoadInfo()

    local rival_info = arena_logic:GetSingleRivalInfo(self.index)
    local template_id = rival_info.template_id

    self.icon_panel:Show(constants["REWARD_TYPE"]["mercenary"], template_id, nil, nil, false)

    --  多语言名字
    local loacle = platform_manager:GetLocale()
    if rival_info["leader_name_"..loacle] then
        self.name_text:setString(rival_info["leader_name_"..loacle])
    else
        self.name_text:setString(rival_info.leader_name)
    end
    
    self.bp_text:setString(rival_info.battle_point)

    if not rival_info.user_id then
        self.friend_btn:setVisible(false)
    else
        local has_friend = social_logic:HasFriend(rival_info.user_id)
        self.friend_btn:setVisible(not has_friend)
    end

    if rival_info.state then
        --挑战成功
        self.challenge_btn:setVisible(false)
        self.win_icon_img:setVisible(true)
        self.friend_btn:setPosition(self.challenge_btn:getPosition())
        self.bg_img:setColor(panel_util:GetColor4B(0xe9fe9e))

    else
        self.friend_btn:setPosition(self.friend_btn_pos_x, self.friend_btn_pos_y)
        self.win_icon_img:setVisible(false)
        self.challenge_btn:setVisible(true)
        self.bg_img:setColor(panel_util:GetColor4B(0xffffff))
    end

    self.user_id = rival_info.user_id
end

------------------------
local arena_main_panel = panel_prototype.New(true)
function arena_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/arena_main_panel.csb")
    local root_node = self.root_node

    local top_node = root_node:getChildByName("title_bg")
    self.challenge_num_text = top_node:getChildByName("challenge_num")
    self.challenge_bg_img = top_node:getChildByName("challenge_bg")
    self.challenge_bg_img:setTouchEnabled(true)
    --连胜奖励img
    self.reward_icon_imgs= {}
    for i = 1, REWARD_COUNT do
        local reward_icon = top_node:getChildByName("reward_icon" .. i)
        self.reward_icon_imgs[i] = reward_icon
        reward_icon:setColor(panel_util:GetColor4B(0xf7f7f7))
    end

    --胜利次数img
    self.win_times_imgs = {}
    for i = 1, RIVAL_NUM do
        local win_times_img = top_node:getChildByName("win" .. i)
        win_times_img:setVisible(false)
        self.win_times_imgs[i] = win_times_img
    end
    self.list_view = root_node:getChildByName("list_view")

    --文本加描边
    self.reward1_1x_txt = top_node:getChildByName("reward1_1x_txt")
    self.reward1_win_txt = top_node:getChildByName("reward1_win_txt")
    self.reward2_4x_txt = top_node:getChildByName("reward2_4x_txt")
    self.reward2_win_txt = top_node:getChildByName("reward2_win_txt")
    self.reward3_9x_txt_0 = top_node:getChildByName("reward3_9x_txt_0")
    self.reward3_win_txt = top_node:getChildByName("reward3_win_txt")

    if self.reward1_1x_txt then
        panel_util:SetTextOutline(self.reward1_1x_txt)
    end
    if self.reward1_win_txt then
        panel_util:SetTextOutline(self.reward1_win_txt)
    end
    if self.reward2_4x_txt then
        panel_util:SetTextOutline(self.reward2_4x_txt)
    end
    if self.reward2_win_txt then
        panel_util:SetTextOutline(self.reward2_win_txt)
    end
    if self.reward3_9x_txt_0 then
        panel_util:SetTextOutline(self.reward3_9x_txt_0)
    end
    if self.reward3_win_txt then
        panel_util:SetTextOutline(self.reward3_win_txt)
    end

    --对手
    self.rival_sub_panels = {}
    local template = root_node:getChildByName("template")

    for i = 1, RIVAL_NUM do
        local sub_panel = rival_info_sub_panel.New()
        sub_panel:Init(template:clone(), i)
        sub_panel:Show()

        self.rival_sub_panels[i] = sub_panel

        self.list_view:addChild(sub_panel.root_node)

    end

    local margin_node = ccui.Widget:create()
    local size = template:getContentSize()
    size.height = size.height / 2
    margin_node:setContentSize(size)
    self.list_view:addChild(margin_node)

    template:setVisible(false)

    self.refresh_btn = root_node:getChildByName("refresh_btn")
    self.refresh_time_text = self.refresh_btn:getChildByName("time")
    self.formation_btn = root_node:getChildByName("formation_btn")
    
    --刷新开关要通过gm开关控制
    self:ShowRefreshBtn()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function arena_main_panel:ShowRefreshBtn()
    --刷新开关要通过gm开关控制
    if feature_config:IsFeatureOpen("review") then
        self.refresh_btn:setTouchEnabled(false)
        local btn = self.refresh_btn:getChildByName("btn")
        local icon0 = self.refresh_btn:getChildByName("icon0")
        if btn:isVisible() then
            btn:setVisible(false)
            icon0:setVisible(false)
        end
    else
        self.refresh_btn:setTouchEnabled(true)
        local btn = self.refresh_btn:getChildByName("btn")
        local icon0 = self.refresh_btn:getChildByName("icon0")
        if not btn:isVisible() then
            btn:setVisible(true)
            icon0:setVisible(true)
        end
    end
end

function arena_main_panel:Show()
    self.root_node:setVisible(true)
    --1s滚动到顶部
    self.list_view:jumpToTop()

    self:ReLoadInfo()
    --  竞技场界面已经完整的显示出来了
    graphic:DispatchEvent("jump_finish",JUMP_CONST["pvp_arena"]) 
end
function arena_main_panel:ReLoadInfo()
    local win_times = arena_logic.win_num

    for i = 1, RIVAL_NUM do
        self.rival_sub_panels[i]:ReLoadInfo()

        if i <= win_times then
            self.win_times_imgs[i]:setVisible(true)
        else
            self.win_times_imgs[i]:setVisible(false)
        end
    end

    self.challenge_num_text:setString(arena_logic.challenge_num)
    self.duration = time_logic:GetDurationToFixedTime(arena_logic.refresh_time)

end

--检查连胜奖励是否获取
function arena_main_panel:CheckRewardIsGet()
    local win_times = arena_logic.win_num
    local color  = panel_util:GetColor4B(0xffffff)

    for i = 1, REWARD_COUNT do
        self.reward_icon_imgs[i]:setColor(panel_util:GetColor4B(0xf7f7f7))
        --领取奖励的条件 胜利次数达到1， 4 ，9
        local take_reward_win_times = i * i

        --领取奖励的btn状态和icon的状态
        if win_times >= take_reward_win_times then
            self.reward_icon_imgs[i]:setColor(color)
        end
    end
end

function arena_main_panel:Update(elapsed_time)
    self.duration = self.duration - elapsed_time
    --时间到了则重新请求数据
    if self.duration <= 0 then
        self.duration = 0
    end

    self.refresh_time_text:setString(panel_util:GetTimeStr(self.duration))
end

function arena_main_panel:RegisterEvent()
    --挑战
    graphic:RegisterEvent("arena_challenge_result", function(result)

        if not self.root_node:isVisible() then
            return
        end

        self.challenge_num_text:setString(arena_logic.challenge_num)
        if result == "success" then
            local challenge_pos = arena_logic.challenge_rival_pos

            local sub_panel = self.rival_sub_panels[challenge_pos]
            sub_panel:ReLoadInfo()

            local win_times = arena_logic.win_num

            if self.win_times_imgs[win_times] then
                self.win_times_imgs[win_times]:setVisible(true)
            else
                assert(false, "win_num " .. tostring(win_times))
            end

            self:CheckRewardIsGet()
        end
    end)

    --刷新竞技场
    graphic:RegisterEvent("arena_refresh_rival", function(result)
        if not self.root_node:isVisible() then
            return
        end

        self.list_view:jumpToTop()
        self:ReLoadInfo()
    end)

    --刷新连胜奖励
    graphic:RegisterEvent("arena_take_prize", function(result)
        if not self.root_node:isVisible() then
            return
        end
        self:CheckRewardIsGet()
    end)

    --邀请好友
    graphic:RegisterEvent("invite_player", function(player)
        if not self.root_node:isVisible() then
            return
        end

        --self.social_sub_msgbox[mode]:Show()
    end)

    --搜索结果
    graphic:RegisterEvent("search_player_result", function(result, player)
        if not self.root_node:isVisible() then
            return
        end

        if not player then
            return
        end
        graphic:DispatchEvent("show_world_sub_panel", "social_msgbox", client_constants.SOCIAL_MSGBOX_TYPE["invite_player_msgbox"], player)
    end)

    --gm工具开关控制
    graphic:RegisterEvent("update_feature_config", function()
        self:ShowRefreshBtn()
    end)
end

function arena_main_panel:RegisterWidgetEvent()
    --返回
    self.root_node:getChildByName("back_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "pvp_sub_scene")
        end
    end)

    --查看奖品规则
    self.root_node:getChildByName("look_rule_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_panel", "arena_rule_msgbox")
        end
    end)

    --刷新
    self.refresh_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local mode = client_constants["CONFIRM_MSGBOX_MODE"]["refresh_arena"]
            graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
        end
    end)

    --兑换奖励
    self.root_node:getChildByName("exchange_reward_btn"):addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            arena_logic:QueryExchangeConfig()
        end
    end)

    self.challenge_bg_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not vip_logic:IsActivated(constants.VIP_TYPE["adventure"]) then
                --月卡购买界面
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("buy_vip_title"),
                    lang_constants:Get("arena_times_desc"),
                    lang_constants:Get("common_confirm"),
                    lang_constants:Get("common_cancel"),
                    function()
                        graphic:DispatchEvent("show_world_sub_panel", "vip_panel")
                end)
            end
        end
    end)

    --阵容切换
    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local trans_type = constants["SCENE_TRANSITION_TYPE"]["none"]
            local mode = client_constants["FORMATION_PANEL_MODE"]["multi"]
            local back_panel = self:GetName()
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, mode, back_panel)
        end
    end)

    --挑战和加好友
    self.challenge_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local i = widget:getTag()
            arena_logic:ChallengeRival(i)
        end
    end

    self.friend_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local i = widget:getTag()
            local user_id = self.rival_sub_panels[i].user_id

            social_logic:SearchFriend(user_id)
        end
    end

    for i = 1, RIVAL_NUM do
        self.rival_sub_panels[i].friend_btn:addTouchEventListener(self.friend_method)
        self.rival_sub_panels[i].challenge_btn:addTouchEventListener(self.challenge_method)
    end

end



return arena_main_panel
