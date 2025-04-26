local resource_logic = require "logic.resource"
local arena_logic = require "logic.arena"
local graphic = require "logic.graphic"
local daily_logic = require "logic.daily"
local bag_logic = require "logic.bag"
local config_manager = require "logic.config_manager"

local resource_config = config_manager.resource_config
local alchemy_prayer_config = config_manager.alchemy_prayer_config

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"
local spine_manager = require "util.spine_manager"
local spine_node_tracker = require "util.spine_node_tracker"
local platform_manager = require "logic.platform_manager"
local icon_tempalte = require "ui.icon_panel"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local REWARD_TYPE = constants["REWARD_TYPE"]
local RESOURCE_TYPE = constants["RESOURCE_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType

local DAILY_TIME_ICON = "icon/mercenarylist/time.png"
local ALCHEMY_ICON = "icon/item/3000004.png"
local PRAYER_ICON = "icon/item/2000010.png"
local GOLD_ICON = resource_config[RESOURCE_TYPE["gold_coin"]].icon
local EXP_ICON  = resource_config[RESOURCE_TYPE["exp"]].icon
local SOUL_ICON = resource_config[RESOURCE_TYPE["soul_chip"]].icon

--渲染层级  1 2 3 7
local LOW_ZORDER = 1
local MID_ZORDER = 2
local HIGH_ZORDER = 3
local TIP_ZORDER = 7

--混色 0x7f7f7f  0xffffff 
local DARK_COLOR = client_constants["DARK_BLEND_COLOR"]
local LIGHT_COLOR = client_constants["LIGHT_BLEND_COLOR"]

-- 淡入效果持续时间
local TRANSLATE_TIME = client_constants["DAILY_PANEL_TRANSLATE_TIME"]
-- 进度条动画持续时间
local LOADING_TIME = client_constants["DAILY_PANEL_LOADING_TIME"]

local daily_panel = panel_prototype.New(true)

local TAB_TYPE = client_constants["DAILY_TYPE"]

function daily_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/check_in_daily_panel.csb")
    local root_node = self.root_node

    -- 签到标签
    local check_in_node = root_node:getChildByName("checkin_node")

    self.checkin_desc_text = check_in_node:getChildByName("desc1")

    -- 祈祷标签
    local prayer_node = root_node:getChildByName("pray_and_alchemy_node")
    -- 炼金标签
    local alchemy_node = root_node:getChildByName("pray_and_alchemy_node")
    -- 签到更多奖励
    self.more_reward_btn = check_in_node:getChildByName("more_reward_btn")
    -- 操作按钮
    self.operation_btn = root_node:getChildByName("check_in_btn")
    -- 祈祷&炼金
    self.prayer_alchemy_desc_text = prayer_node:getChildByName("desc1")
    self.prayer_alchemy_level_text = prayer_node:getChildByName("icon"):getChildByName("level_value")
    self.prayer_alchemy_img = prayer_node:getChildByName("icon")
    self.prayer_alchemy_item_list = {}
    self.prayer_alchemy_choose_list = {}
    for i = 1, 3 do
        local item = {}
        item.root_node = prayer_node:getChildByName("template"..i)
        item.name_text = item.root_node:getChildByName("name")
        item.desc_text = item.root_node:getChildByName("desc")
        item.icon_img = item.root_node:getChildByName("icon"):getChildByName("icon")
        item.icon_text = item.root_node:getChildByName("icon"):getChildByName("num")
        item.resource_img = item.root_node:getChildByName("resourse_icon")
        item.soul_img = item.root_node:getChildByName("soul_icon")
        item.root_node:setTag(i)
        item.root_node:setTouchEnabled(true)
        item.resource_img:setScale(0.35)
        table.insert(self.prayer_alchemy_item_list, i, item)

        local choose_item = {}
        choose_item.root_node = prayer_node:getChildByName("template"..i.."_choose")
        choose_item.chosen_icon = choose_item.root_node:getChildByName("chosen_icon")
        choose_item.desc_text = choose_item.root_node:getChildByName("empty_desc")
        choose_item.root_node:setTag(i)
        table.insert(self.prayer_alchemy_choose_list, i, choose_item)

        local tip_bg = item.root_node:getChildByName("tip_bg")
        if tip_bg then
            item.value = tip_bg:getChildByName("value")
        end
    end

    self.cur_item_idx = 0
    self.prayer_idx = 0
    self.alchemy_idx = 0
    
    -- 标签内容面板列表
    self.tab_node_list = {
        [TAB_TYPE.check_in] = check_in_node,
        [TAB_TYPE.prayer] = prayer_node,
        [TAB_TYPE.alchemy] = alchemy_node,
    }
    -- 标签绿点提示列表
    self.tab_tip_list = {
        [TAB_TYPE.check_in] = root_node:getChildByName("checkin_tab_tip"),
        [TAB_TYPE.prayer] = root_node:getChildByName("pray_tab_tip"),
        [TAB_TYPE.alchemy] = root_node:getChildByName("alchemy_tab_tip"),
    }
    -- 标签切换按钮列表
    self.tab_button_list = {
        [TAB_TYPE.check_in] = root_node:getChildByName("checkin_tab"),
        [TAB_TYPE.prayer] = root_node:getChildByName("pray_tab"),
        [TAB_TYPE.alchemy] = root_node:getChildByName("alchemy_tab"),
    }
    self.tab_button_list[TAB_TYPE.check_in]:setTag(TAB_TYPE.check_in)
    self.tab_button_list[TAB_TYPE.prayer]:setTag(TAB_TYPE.prayer)
    self.tab_button_list[TAB_TYPE.alchemy]:setTag(TAB_TYPE.alchemy)

    for k, v in pairs(TAB_TYPE) do
        self.tab_node_list[v]:setVisible(false)
        self.tab_button_list[v]:setColor(panel_util:GetColor4B(DARK_COLOR))
        self.tab_tip_list[v]:setLocalZOrder(TIP_ZORDER)
    end

    local CHECKIN_TIME = constants.CHECKIN_TIME
    local time1 = "0-" .. CHECKIN_TIME["first"] .. ":00"
    local time2 = CHECKIN_TIME["first"] .. "-" .. CHECKIN_TIME["second"] .. ":00"
    local time3 = CHECKIN_TIME["second"] .. "-" .. CHECKIN_TIME["third"] .. ":00"

    self.checkin_desc_text:setString(string.format(lang_constants:Get("daily_check_in_desc3"), time1, time2, time3))

    self.root_node:getChildByName("close_btn"):setLocalZOrder(TIP_ZORDER)
    self:InitCheckIn()
    self:InitSpineNodeTracker()

    self:RegisterEvent()
    self:RegisterSpineEvent()
    self:RegisterWidgetEvent()
end

function daily_panel:InitCheckIn()

    self.checkin_item_list = {}
    for i = 1, 3 do
        local item = {}
        item.img = self.tab_node_list[TAB_TYPE.check_in]:getChildByName("img" .. i)
        item.bg_img = icon_tempalte.New(item.img:getChildByName("bg"))
        item.take_img = item.img:getChildByName("finish")
        item.bg_img:Init()
        table.insert(self.checkin_item_list, i, item)

        item.img:setCascadeColorEnabled(false)
    end
    self.total_node = self.tab_node_list[TAB_TYPE.check_in]:getChildByName("accumulative_total_bg")

    self.total_desc_text = self.total_node:getChildByName("desc")

    self.reward_info_node = self.total_node:getChildByName("reward_info")

    self.loading_bar = self.reward_info_node:getChildByName("loadingbar")
    self.loading_bar_desc = self.loading_bar:getChildByName("desc")
    self.loading_flag = false

    self.condition_desc = self.reward_info_node:getChildByName("condition_desc")
    self.reward_desc = self.reward_info_node:getChildByName("reward_desc")
    self.reward = icon_tempalte.New(self.reward_info_node:getChildByName("reward_bg"))

    self.reward:Init(self.reward_info_node, false)
    self.reward.root_node:setPosition(85, 84)
end

local SPINE_STATUS = {
    ["init"] = 0,
    ["next_reward"] = 1,
    ["begin"] = 2,
    ["end"] = 3,
}
function daily_panel:InitSpineNodeTracker()
    self.reward_info_list = {}
    self.play_nodes = {
        ["check_in"] = self.reward_info_node:getChildByName("border"),
        ["prayer"] = self.tab_node_list[TAB_TYPE.prayer]:getChildByName("level_bg"),
        ["reward_check_in"] = cc.CSLoader:createNode("ui/reward_simple_panel.csb"),
        ["reward_prayer"] = cc.CSLoader:createNode("ui/reward_simple_panel.csb"),
    }

    self.play_nodes["reward_check_in"]:getChildByName("reward"):setPosition(200, 50)
    self.play_nodes["reward_prayer"]:getChildByName("reward"):setPosition(0, 50)
    self.play_nodes["reward_check_in"]:setVisible(false)
    self.play_nodes["reward_prayer"]:setVisible(false)

    self.total_node:addChild(self.play_nodes["reward_check_in"])
    self.tab_node_list[TAB_TYPE.prayer]:addChild(self.play_nodes["reward_prayer"])

    self.spine_nodes = {
        ["check_in"] = spine_manager:GetNode("check_in"),
        ["prayer"] = spine_manager:GetNode("check_in"),
        ["reward_check_in"] = spine_manager:GetNode("maze_txt"),
        ["reward_prayer"] = spine_manager:GetNode("maze_txt"),
    }

    for k,v in pairs(self.spine_nodes) do
        v:setVisible(false)
    end

    self.total_node:addChild(self.spine_nodes["check_in"], 300)
    self.total_node:addChild(self.spine_nodes["reward_check_in"], 300)
    self.tab_node_list[TAB_TYPE.prayer]:addChild(self.spine_nodes["prayer"], 300)
    self.tab_node_list[TAB_TYPE.prayer]:addChild(self.spine_nodes["reward_prayer"], 300)

    self.spine_trackers = {
        ["check_in"] = spine_node_tracker.New(self.spine_nodes["check_in"], "sign_in_node_light"),
        ["prayer"] = spine_node_tracker.New(self.spine_nodes["prayer"], "pray_n_metallury"),
        ["reward_check_in"] = spine_node_tracker.New(self.spine_nodes["reward_check_in"], "txt"),
        ["reward_prayer"] = spine_node_tracker.New(self.spine_nodes["reward_prayer"], "txt"),
    }

end

local ANIMATION_NAMES = {
    [TAB_TYPE.check_in] = "sign_in",
    [TAB_TYPE.prayer] = "pray",
    [TAB_TYPE.alchemy] = "pray",
}

-- border/level_bg 节点动画
function daily_panel:CommonSpine()

    local animation = ANIMATION_NAMES[self.cur_tab]

    if self.cur_tab == TAB_TYPE.check_in then
        self.spine_trackers["check_in"]:Bind(animation, nil, 308, 48, self.play_nodes["check_in"])
        self.spine_nodes["check_in"]:setVisible(true)
        self.spine_nodes["prayer"]:setVisible(false)
    else
        self.spine_trackers["prayer"]:Bind(animation, nil, 107, 864, self.play_nodes["prayer"])
        self.spine_nodes["check_in"]:setVisible(false)
        self.spine_nodes["prayer"]:setVisible(true)
    end
end

-- reward 节点动画  显示获取资源数量
function daily_panel:RewardSpine()
    local list_size = #self.reward_info_list
    if list_size <= 0 then
        return
    end

    local reward_node
    local reward_tracker
    local play_node
    if self.cur_tab == TAB_TYPE.check_in then
        reward_node = self.spine_nodes["reward_check_in"]
        reward_tracker = self.spine_trackers["reward_check_in"]
        play_node = self.play_nodes["reward_check_in"]
    else
        reward_node = self.spine_nodes["reward_prayer"]
        reward_tracker = self.spine_trackers["reward_prayer"]
        play_node = self.play_nodes["reward_prayer"]
    end 
    local icon_img = play_node:getChildByName("reward"):getChildByName("reward_icon")
    local value_text = play_node:getChildByName("reward"):getChildByName("reward_value")

    icon_img:loadTexture(self.reward_info_list[1].icon_str, PLIST_TYPE)
    value_text:setString(tostring(self.reward_info_list[1].value_str))

    local scale = (list_size > 1) and 2.0 or 1.0

    if self.cur_tab == TAB_TYPE.check_in then
        self.spine_trackers["reward_check_in"]:Bind("txt", "txt_alpha", 308, 48, self.play_nodes["reward_check_in"])
        self.spine_nodes["reward_check_in"]:setTimeScale(scale)
    else
        self.spine_trackers["reward_prayer"]:Bind("txt", "txt_alpha", 107, 864, self.play_nodes["reward_prayer"])
        self.spine_nodes["reward_prayer"]:setTimeScale(scale)
    end       
end

function daily_panel:LoadRewardInfo(tab_type, index, param)
    -- 动画未播完 或者索引无效时，不加载动画资源
    -- if index == 0 or self.spine_flag ~= SPINE_STATUS["init"] or self.reward_flag ~= SPINE_STATUS["init"] then
    --     return
    -- end

    self.reward_info_list = {}
    local info = {}
    local info_req = {}

    if tab_type == TAB_TYPE.check_in then
        info.icon_str = DAILY_TIME_ICON
        info.value_str = "+".."1"
        table.insert(self.reward_info_list, 1, info)

    else
        local score, score_req = daily_logic:GetScore(tab_type, index, param)
        info.icon_str = (self.cur_tab == TAB_TYPE.prayer) and EXP_ICON or GOLD_ICON
        info.value_str = panel_util:ConvertUnit(score)
        table.insert(self.reward_info_list, 1, info)

        local info_req = {}
        info_req.icon_str = SOUL_ICON
        info_req.value_str = panel_util:ConvertUnit(score_req)

        if score_req ~= 0 then
            table.insert(self.reward_info_list, 2, info_req)
        end
    end
end

function daily_panel:Show(new_tab_type)
    self.root_node:setVisible(true)
    self.cur_tab = TAB_TYPE.check_in

    self.loading_bar_duration = 0

    self:AutoNextTab(false)

    if #self.reward_info_list > 0 then
        for i, v in ipairs(self.reward_info_list) do
            table.remove(self.reward_info_list, i)
        end
    end
    -- 控制进度条动画播放，只播放一次
    self.loading_bar_animation = false

    -- level_bg/border 节点动画状态
    self.spine_flag = SPINE_STATUS["init"]

    -- reward 节点动画状态
    self.reward_flag = SPINE_STATUS["init"]
end

-- 自动跳转
function daily_panel:AutoNextTab(fade_in)

    if not daily_logic:AlreadyCheckin() then
        self.cur_tab = TAB_TYPE.check_in

    elseif not daily_logic:AlreadyPrayer() then
        self.cur_tab = TAB_TYPE.prayer

    elseif not daily_logic:AlreadyAlchemy() then
        self.cur_tab = TAB_TYPE.alchemy
    else
        --tab页没更新时,不播放淡入效果
        fade_in = false
    end

    self:SwitchTab(self.cur_tab, fade_in)
end

function daily_panel:ShowItemInfo(item, index)
    
    local gold_str = lang_constants:Get("daily_reward_gold")
    local exp_str = lang_constants:Get("daily_reward_exp")
    local common_str = (self.cur_tab == TAB_TYPE.alchemy) and gold_str or exp_str
    local extrn_str = lang_constants:Get("daily_reward_extern")
    local final_str = ""

    local info = (self.cur_tab == TAB_TYPE.alchemy) and constants.ALCHEMY_CONFIG[index] or constants.PRAYER_CONFIG[index]
    local score, score_req = daily_logic:GetScore(self.cur_tab, index, daily_logic:GetDailyParam(self.cur_tab))

    if score_req ~= 0 then
        final_str = string.format(common_str, panel_util:ConvertUnit(score)) .. "\n".. string.format(extrn_str, score_req)
    else
        final_str = string.format(common_str, panel_util:ConvertUnit(score))
    end

    if item.value and info.req_value ~= 0 then
        item.value:setString(info.req_value)
    end

    item.soul_img:setVisible(score_req ~= 0)
    item.desc_text:setString(final_str)
    item.icon_text:setString(panel_util:ConvertUnit(score))
end

function daily_panel:ShowAlchemyTable()
    if daily_logic.alchemy_info.mark ~= 0 then
        self.alchemy_idx = daily_logic.alchemy_info.mark
    end
    if self.alchemy_idx ~= 0 then
        self.prayer_alchemy_choose_list[self.alchemy_idx].chosen_icon:setVisible(true)
        self.prayer_alchemy_choose_list[self.alchemy_idx].desc_text:setVisible(false)
    end

    local item_list = self.prayer_alchemy_item_list
    for i = 1, 3 do
        local name = string.format(lang_constants:Get("daily_alchemy_idx"..i),constants.ALCHEMY_CONFIG[i].lv)
        item_list[i].name_text:setString(name)
        item_list[i].icon_img:loadTexture(GOLD_ICON, PLIST_TYPE)
        item_list[i].resource_img:loadTexture("icon/resource/coin_header.png", PLIST_TYPE)
        self:ShowItemInfo(item_list[i], i)
    end

    self.prayer_alchemy_img:loadTexture(ALCHEMY_ICON, PLIST_TYPE)
    self.prayer_alchemy_desc_text:setString(lang_constants:Get("daily_alchemy_desc"))
    self.prayer_alchemy_level_text:setString(daily_logic.alchemy_info.level)

    if not daily_logic:AlreadyAlchemy() then
        self.operation_btn:setTitleText(lang_constants:Get("daily_alchemy_used"))
        self.operation_btn:setColor(panel_util:GetColor4B(LIGHT_COLOR))
    else
        self.operation_btn:setTitleText(lang_constants:Get("daily_alchemy_unused"))
        self.operation_btn:setColor(panel_util:GetColor4B(DARK_COLOR))
    end
    self:UpdateItemBg()
end

function daily_panel:ShowPrayerTable()

    if daily_logic.prayer_info.mark ~= 0 then
        self.prayer_idx = daily_logic.prayer_info.mark
    end

    if self.prayer_idx ~= 0 then
       self.prayer_alchemy_choose_list[self.prayer_idx].chosen_icon:setVisible(true)
       self.prayer_alchemy_choose_list[self.prayer_idx].desc_text:setVisible(false)
   end

    local item_list = self.prayer_alchemy_item_list
    for i = 1, 3 do
        local name = string.format(lang_constants:Get("daily_prayer_idx"..i), constants.PRAYER_CONFIG[i].lv)
        item_list[i].name_text:setString(name)
        item_list[i].icon_img:loadTexture(EXP_ICON, PLIST_TYPE)
        item_list[i].resource_img:loadTexture("icon/resource/exp_header.png", PLIST_TYPE)

        self:ShowItemInfo(item_list[i], i)
    end

    self.prayer_alchemy_img:loadTexture(PRAYER_ICON, PLIST_TYPE)
    self.prayer_alchemy_desc_text:setString(lang_constants:Get("daily_prayer_desc"))
    self.prayer_alchemy_level_text:setString(daily_logic.prayer_info.level)

    if not daily_logic:AlreadyPrayer() then
        self.operation_btn:setTitleText(lang_constants:Get("daily_prayer_used"))
        self.operation_btn:setColor(panel_util:GetColor4B(LIGHT_COLOR))
    else
        self.operation_btn:setTitleText(lang_constants:Get("daily_prayer_unused"))
        self.operation_btn:setColor(panel_util:GetColor4B(DARK_COLOR))
    end

    self:UpdateItemBg()
end

function daily_panel:ShowCheckInTable()
    local daily_list = daily_logic:GetDailyList()
    local current_day_check_in_count = daily_logic:GetTheDayCheckInCount()

    -- 距离下次签到的时间
    self.duration = daily_logic:GetDurationToNextCheckin()
    for i = 1, 3 do
        local daily_info = daily_list[i]
        local count = daily_logic:GetTheDayCheckInCount()
        local item = self.checkin_item_list[i]

        if count >= i then
            item.img:setColor(panel_util:GetColor4B(DARK_COLOR))
            item.bg_img.root_node:setColor(panel_util:GetColor4B(DARK_COLOR))
            item.take_img:setVisible(true)
        else
            item.img:setColor(panel_util:GetColor4B(LIGHT_COLOR))
            item.take_img:setVisible(false)
        end
        item.bg_img:Show(daily_info.reward_type, daily_info.param1, daily_info.param2, false, true)
    end

    if daily_logic:AlreadyCheckin() then
        self.duration = daily_logic:GetDurationToNextCheckin()
        self.operation_btn:setColor(panel_util:GetColor4B(DARK_COLOR))
        if duration then
            self.operation_btn:setTitleText(string.format(lang_constants:Get("daily_check_in_unused"), panel_util:GetTimeStr(duration)))
        end
    else
        self.operation_btn:setColor(panel_util:GetColor4B(LIGHT_COLOR))
        self.operation_btn:setTitleText(lang_constants:Get("daily_check_in_used"))
    end

    self:UpdateNextReward()
end

function daily_panel:UpdateNextReward()

    if daily_logic.next_reward then
        self.reward_info_node:setVisible(true)

        -- 下次累计签到奖励
        self.loading_bar_desc:setString(daily_logic.check_in_count.."/"..daily_logic.check_in_count_next)

        local percent = math.min(daily_logic.check_in_count/daily_logic.check_in_count_next, 1) * 100
        local src_percent = percent

        if self.loading_bar_animation then
            src_percent = math.min((daily_logic.check_in_count-1)/daily_logic.check_in_count_next, 1) * 100
        end

        self.loading_bar_animation = false
        self:SetLoadingBarParams(src_percent, percent)

        local conf = self.reward:Show(daily_logic.next_reward.reward_type, daily_logic.next_reward.param1, daily_logic.next_reward.param2, false, true)
        self.reward_desc:setString(conf.name .. " x" .. daily_logic.next_reward.param2)

        self.total_desc_text:setString(lang_constants:Get("daily_check_in_desc1"))
        self.total_desc_text:setPositionY(204)

    else
        self.reward_info_node:setVisible(false)
        self.total_desc_text:setString(lang_constants:Get("daily_check_in_desc2"))
        self.total_desc_text:setPositionY(140)
    end

    self.condition_desc:setString(string.format(lang_constants:Get("daily_check_in_accmulate"), daily_logic.check_in_count_next))
end

-- fade_in: 是否需要淡入效果
function daily_panel:SwitchTab(new_tab_type, fade_in)

    for k, v in pairs(TAB_TYPE) do
        self.tab_node_list[v]:setVisible(false)
        self.tab_tip_list[v]:setVisible(false)
        self.tab_button_list[v]:setLocalZOrder(MID_ZORDER)
        self.tab_button_list[v]:setColor(panel_util:GetColor4B(DARK_COLOR))
    end

    --清除所有选择
    for i = 1, 3 do
        self.prayer_alchemy_choose_list[i].chosen_icon:setVisible(false)
        self.prayer_alchemy_choose_list[i].desc_text:setVisible(true)
    end

    self.cur_tab = new_tab_type
    self.switch_flag = fade_in
    self.tab_node_list[new_tab_type]:setVisible(true)
    self:UpdateTabButton()
    self:UpdateTabTips()

    if new_tab_type == TAB_TYPE.prayer then 
        self:ShowPrayerTable()
    elseif new_tab_type == TAB_TYPE.alchemy then 
        self:ShowAlchemyTable()
    elseif new_tab_type == TAB_TYPE.check_in then
        self:ShowCheckInTable()
    end
end

function daily_panel:Update(elapsed_time)

    if self.tab_node_list[TAB_TYPE.check_in]:isVisible() then

        if daily_logic:AlreadyCheckin() then

            if not self.duration then
                self.duration = daily_logic:GetDurationToNextCheckin()
            else
                self.duration = math.max(self.duration - elapsed_time, 0)
            end

            if self.duration ~= 0 then
                self.operation_btn:setTitleText(string.format(lang_constants:Get("daily_check_in_unused"), panel_util:GetTimeStr(self.duration)))
            else
                self.operation_btn:setTitleText(lang_constants:Get("daily_check_in_used"))
            end
        end

        self:UpdateLoadingBar(elapsed_time)
    end

    -- tab淡入效果
    if platform_manager:GetChannelInfo().daily_panel_enable_switch_tab_animation then 
        self:SwitchAnimation(elapsed_time)
    end

    -- spine动画，进度条动画结束 后执行
    if self.spine_flag == SPINE_STATUS["end"] and self.loading_bar_duration == 0 and self.reward_flag == SPINE_STATUS["end"] then
        self:AutoNextTab(true)
        self.spine_flag = SPINE_STATUS["init"]
        self.reward_flag = SPINE_STATUS["init"]
    end

    -- 下一个reward节点动画
    if self.reward_flag == SPINE_STATUS["next_reward"] then
        self.reward_flag = SPINE_STATUS["start"]
        self:RewardSpine()
    end

    self.spine_trackers["reward_check_in"]:Update()
    self.spine_trackers["reward_prayer"]:Update()
end

-- tab页切换动画(淡入)
local time_delta = 0
function daily_panel:SwitchAnimation(elapsed_time)

    if self.switch_flag or time_delta > 0 then
        time_delta = time_delta + elapsed_time
        if time_delta < TRANSLATE_TIME then
            local percent = time_delta / TRANSLATE_TIME
            self.tab_node_list[self.cur_tab]:setOpacity(255 * percent)
        else
            self.switch_flag = false
            time_delta = 0 
        end
    end
end

-- 设置loadingbar的变化范围
function daily_panel:SetLoadingBarParams(percent_src, percent_des)
    percent_des =  percent_des > 100 and 100 or percent_des

    self.loading_bar_from = percent_src
    self.loading_bar_to = percent_des
    self.loading_bar:setPercent(percent_src)

    self.loading_bar_duration = LOADING_TIME
    self.speed = (percent_des - percent_src) / LOADING_TIME
end

function daily_panel:UpdateLoadingBar(elapsed_time)
    
    if self.loading_bar_duration > 0 then
        if self.tab_node_list[TAB_TYPE.check_in]:isVisible() then
            self.loading_bar_duration = math.max(self.loading_bar_duration - elapsed_time, 0)
            local percent = self.loading_bar_to - (self.loading_bar_duration * self.speed)
            self.loading_bar:setPercent(percent)
            
        else
            self.loading_bar_duration = 0
            self.loading_bar:setPercent(self.loading_bar_to)
        end
    end
end

function daily_panel:UpdateTabTips(tab_type)

    if not tab_type or tab_type == TAB_TYPE.check_in then
        local need_show = (not daily_logic:AlreadyCheckin()) and true or false
        self.tab_tip_list[TAB_TYPE.check_in]:setVisible(need_show)
    end

    if not tab_type or tab_type == TAB_TYPE.alchemy then
        local need_show = (not daily_logic:AlreadyAlchemy()) and true or false
        self.tab_tip_list[TAB_TYPE.alchemy]:setVisible(need_show)
    end

    if not tab_type or tab_type == TAB_TYPE.prayer then
        local need_show = (not daily_logic:AlreadyPrayer()) and true or false
        self.tab_tip_list[TAB_TYPE.prayer]:setVisible(need_show)
    end
end

function daily_panel:UpdateTabButton()

    self.tab_button_list[self.cur_tab]:setLocalZOrder(HIGH_ZORDER)
    self.tab_button_list[self.cur_tab]:setColor(panel_util:GetColor4B(LIGHT_COLOR))

    if self.cur_tab ~= TAB_TYPE.check_in then
        self.tab_button_list[TAB_TYPE.check_in]:setLocalZOrder(LOW_ZORDER)
    end

    if self.cur_tab ~= TAB_TYPE.alchemy then
        self.tab_button_list[TAB_TYPE.alchemy]:setLocalZOrder(LOW_ZORDER)
    end
end

-- 祈祷&炼金  设置选择项的背景色  
function daily_panel:UpdateItemBg(index)
    local list = self.prayer_alchemy_item_list

    local curr_idx = nil
    local already = false
    if self.cur_tab == TAB_TYPE.prayer then
        curr_idx = self.prayer_idx
        already = daily_logic:AlreadyPrayer()
    else
        curr_idx = self.alchemy_idx
        already = daily_logic:AlreadyAlchemy()
    end

    for k, v in pairs(list) do
        if curr_idx == 0 then
            v.root_node:setColor(panel_util:GetColor4B(LIGHT_COLOR))
        else
            v.root_node:setColor(panel_util:GetColor4B(DARK_COLOR))
        end
    end

    if curr_idx > 0 and not already then
        list[curr_idx].root_node:setColor(panel_util:GetColor4B(LIGHT_COLOR))
    end
end

function daily_panel:RegisterEvent()

    graphic:RegisterEvent("take_daily_reward", function(type, param)
        if self.root_node:isVisible() then
            if type == TAB_TYPE.check_in then
                self.loading_bar_animation = true
                audio_manager:PlayEffect("checkin")
                self:LoadRewardInfo(TAB_TYPE.check_in)

            elseif type == TAB_TYPE.prayer then 
                if daily_logic.prayer_info.mark <= 2 then
                    audio_manager:PlayEffect("pray_normal")
                else
                    audio_manager:PlayEffect("pray_better")
                end
                self:LoadRewardInfo(TAB_TYPE.prayer, self.prayer_idx, param)

            elseif type == TAB_TYPE.alchemy then
                if daily_logic.alchemy_info.mark <= 2 then
                    audio_manager:PlayEffect("alchemy_normal")
                else
                    audio_manager:PlayEffect("alchemy_better")
                end
                self:LoadRewardInfo(TAB_TYPE.alchemy, self.alchemy_idx, param)
            end

            self:SwitchTab(self.cur_tab, false)
            self:RewardSpine()
            self:CommonSpine()
        end

        graphic:DispatchEvent("remind_check_in", 0)
    end)
end

function daily_panel:RegisterSpineEvent()
    
    local spine_callback = function(event)
        print('COME here')
        self.spine_flag = SPINE_STATUS["end"]
    end

    self.spine_nodes["check_in"]:registerSpineEventHandler(spine_callback, sp.EventType.ANIMATION_END)
    self.spine_nodes["prayer"]:registerSpineEventHandler(spine_callback, sp.EventType.ANIMATION_END)

    local reward_callback = function(event)
        table.remove(self.reward_info_list, 1)

        if #self.reward_info_list > 0 then
            self.reward_flag = SPINE_STATUS["next_reward"]
        else
            self.reward_flag = SPINE_STATUS["end"]
        end
    end

    self.spine_nodes["reward_check_in"]:registerSpineEventHandler(reward_callback, sp.EventType.ANIMATION_END)
    self.spine_nodes["reward_prayer"]:registerSpineEventHandler(reward_callback, sp.EventType.ANIMATION_END)
end

function daily_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), "daily_panel")
    -- 标签页面按钮
    for key, btn in ipairs(self.tab_button_list) do

        btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                self:SwitchTab(key, true)
            end
        end)
    end

    -- 祈祷&炼金选项
    local item_listener = function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then

                if self.cur_tab == TAB_TYPE.prayer and daily_logic:AlreadyPrayer() then
                    return
                end

                if self.cur_tab == TAB_TYPE.alchemy and daily_logic:AlreadyAlchemy() then
                    return
                end

                audio_manager:PlayEffect("click")
                local chosen_list = self.prayer_alchemy_choose_list
                self.cur_item_idx = (self.cur_tab == TAB_TYPE.prayer) and self.prayer_idx or self.alchemy_idx

                if self.cur_item_idx ~= 0 then
                    chosen_list[self.cur_item_idx].chosen_icon:setVisible(false)
                    chosen_list[self.cur_item_idx].desc_text:setVisible(true)
                end

                self.cur_item_idx = widget:getTag()

                if self.cur_tab == TAB_TYPE.prayer then
                    self.prayer_idx = self.cur_item_idx

                elseif self.cur_tab == TAB_TYPE.alchemy then
                    self.alchemy_idx = self.cur_item_idx
                end

                chosen_list[self.cur_item_idx].chosen_icon:setVisible(true)
                chosen_list[self.cur_item_idx].desc_text:setVisible(false)
                self:UpdateItemBg(self.cur_item_idx)
            end
        end

    for i = 1, 3 do
        self.prayer_alchemy_item_list[i].root_node:addTouchEventListener(item_listener)
        self.prayer_alchemy_choose_list[i].root_node:addTouchEventListener(item_listener)
    end

    --签到更多奖励
    self.more_reward_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            daily_logic:RequestWeekly()
        end
    end)

    --操作按钮
    self.operation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if self.cur_tab == TAB_TYPE.prayer then

                if self.prayer_idx ~= 0 then

                    if daily_logic.prayer_info.mark ~= 0 then
                        graphic:DispatchEvent("show_prompt_panel", "daily_prayer_unused")
                        return
                    end

                    --检查血钻
                    local cost_blood_diamand = constants["PRAYER_CONFIG"][self.prayer_idx].req_value
                    if not panel_util:CheckBloodDiamond(cost_blood_diamand) then
                        return 
                    end

                    daily_logic:TakePrayer(self.prayer_idx)
                else
                    graphic:DispatchEvent("show_prompt_panel", "daily_choose_desc1")
                end
                
            elseif self.cur_tab == TAB_TYPE.alchemy then

                if self.alchemy_idx ~= 0 then

                    if daily_logic.alchemy_info.mark ~= 0 then
                        graphic:DispatchEvent("show_prompt_panel", "daily_alchemy_unused")
                        return
                    end

                    --检查血钻
                    local cost_blood_diamand = constants["ALCHEMY_CONFIG"][self.alchemy_idx].req_value
                    if not panel_util:CheckBloodDiamond(cost_blood_diamand) then
                        return 
                    end

                    daily_logic:TakeAlchemy(self.alchemy_idx)
                else
                    graphic:DispatchEvent("show_prompt_panel", "daily_choose_desc2")
                end
                
            elseif self.cur_tab == TAB_TYPE.check_in then

                daily_logic:TakeCheckIn()
            end
        end
    end)
end

return daily_panel
