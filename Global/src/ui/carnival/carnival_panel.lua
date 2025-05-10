local carnival_logic = require "logic.carnival"

local graphic = require "logic.graphic"
local time_logic = require "logic.time"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local audio_manager = require "util.audio_manager"

local platform_manager = require "logic.platform_manager"

local cdkey_sub_panel = require "ui.carnival.cdkey_panel"
local reward_sub_panel = require "ui.carnival.reward_panel"

local template_manager = require "ui.carnival.template_manager"

local OFFSET_Y = 10
local MAX_SUB_PANEL_NUM = 7
local TAB_ICON_PATH = "carnival/"

local CARNIVAL_TEMPLATE_TYPE = client_constants["CARNIVAL_TEMPLATE_TYPE"]

local DESC_LINE_HEIGHT = 26

local credit_panel = panel_prototype.New()
function credit_panel:Init(root_node)
    self.root_node = root_node

    self.height = self.root_node:getContentSize().height

    self.value_text = self.root_node:getChildByName("value")
end

function credit_panel:Show(config)
    self.root_node:setVisible(true)

    local info = carnival_logic:GetCarnivalInfo(config.key)
    self.value_text:setString(tostring(info.cur_value))
end

local carnival_panel = panel_prototype.New(true)
function carnival_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/carnival_panel.csb")

    --头部标题和活动持续时间
    local title_bg_img = self.root_node:getChildByName("title_bg")
    self.title_text = title_bg_img:getChildByName("title")
    if platform_manager:GetChannelInfo().carnival_panel_change_title_text_size then
        self.title_text:setFontSize(self.title_text:getFontSize() - 4)
    end

    local title_offset_x = platform_manager:GetChannelInfo().carnival_panel_title_text_offset_x
    if title_offset_x then
        self.title_text:setPositionX(self.title_text:getPositionX()+title_offset_x)
    end

    self.duration_text = title_bg_img:getChildByName("value")

    --滚动容器
    self.scroll_view = self.root_node:getChildByName("scroll_view")

    --存放sub_panel 实例， 二维数组i=template_index, j = 实例id
    self.carnival_sub_panels = {}
    self.template_type = 0

    template_manager:Init()

    --活动描述
    self.desc_text = self.scroll_view:getChildByName("desc")
    self.desc_text:getVirtualRenderer():setMaxLineWidth(588)
    self.desc_text:setLocalZOrder(100)

    --领取奖励
    reward_sub_panel:Init(self.scroll_view:getChildByName("get_panel"))
    credit_panel:Init(self.scroll_view:getChildByName("credit_panel"))

    --cdkey
    cdkey_sub_panel:Init(self.root_node:getChildByName("gift_cdkey"))

    --tab
    local tab_node = self.root_node:getChildByName("tab")
    self.tab_lview = tab_node:getChildByName("tab_list_view")
    self.tab_template = tab_node:getChildByName("tab_template")
    self.tab_template:setVisible(false)
    self.tab_btns = {}

    self.sview_height = self.scroll_view:getContentSize().height
    self.sview_width = self.scroll_view:getContentSize().width

    self.head_sub_panel_y = 0
    self.head_sub_panel_index = 0
    self.data_offset = 0

    self.sub_panel_source = 0
    self.already_add_child = false

    --未开启的活动
    self.not_start_carnivals = {}
    --结束的活动
    self.end_carnivals = {}

    self.sub_panel_num = 0
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function carnival_panel:Clear()
    template_manager:Clear()
end

function carnival_panel:Show()
    self.config_list = carnival_logic:GetConfigList()

    if self.already_add_child then
        self:CheckNotStartCarinivals()
    else
        self:AddChildToTabLview()
        self.already_add_child = true
    end

    self.tab_lview:refreshView()
    self.tab_lview:jumpToLeft()

    self.cur_index = 1

    self:ShowCurCarnivalInfo()

    self.root_node:setVisible(true)
end

--tab 添加子项
function carnival_panel:AddChildToTabLview()
    local cur_time = time_logic:Now()
    for i = 1, #self.config_list do
        local conf = self.config_list[i]
        if cur_time >= conf.begin_time and cur_time <= conf.end_time then
            self:AddTab(conf, i)

        elseif cur_time < conf.begin_time then
            table.insert(self.not_start_carnivals, i)

            --白名单账号能看到活动
            if platform_manager:IsAdmin() then
                self:AddTab(conf, i)
            end
        elseif cur_time > conf.end_time then
            table.insert(self.end_carnivals, i)
        end
    end
end

--检测未开启的活动
function carnival_panel:CheckNotStartCarinivals()
    local cur_time = time_logic:Now()
    for i = #self.not_start_carnivals, 1, -1 do
        local conf_index = self.not_start_carnivals[i]
        local conf = self.config_list[conf_index]
        if cur_time >= conf.begin_time  and cur_time <= conf.end_time then
            self:AddTab(conf, conf_index)
            table.remove(self.not_start_carnivals, i)
        end
    end
end

--tab 颜色
function carnival_panel:SetTabColor()
    for i = 1, #self.tab_btns do
        local tab_btn = self.tab_btns[i]
        if tab_btn:getTag() == self.cur_index then
            tab_btn:setColor(panel_util:GetColor4B(0xffffff))
        else
            tab_btn:setColor(panel_util:GetColor4B(0x7f7f7f))
        end
    end
end

--添加
function carnival_panel:AddTab(conf, index)
    --todo 每次都要clone，然后设定一系列的参数
    local tab_btn = self.tab_template:clone()
    tab_btn:setVisible(true)

    tab_btn:setCascadeColorEnabled(true)

    local icon = "carnival/" .. conf.tab_icon
    tab_btn:loadTextures(icon, icon, icon, PLIST_TYPE)

    tab_btn:setTag(index)
    tab_btn:addTouchEventListener(self.view_carnival_info)

    --排名活动不显示图标
    tab_btn:getChildByName("icon"):setVisible(conf.visible_type == CARNIVAL_TEMPLATE_TYPE["rank"] and false or carnival_logic:CheckReward(conf.key))

    local tab_text = tab_btn:getChildByName("text")
    
    if platform_manager:GetChannelInfo().meta_channel == "r2games" then
        tab_text:setString("")
    else
        tab_text:setString(self:GetLocaleInfoString(conf,"name"))
        panel_util:SetTextOutline(tab_text, nil, 2, -4)
    end

    table.insert(self.tab_btns, tab_btn)
    self.tab_lview:addChild(tab_btn)
end

function carnival_panel:SetHeadSubPanel(index)
    if index > self.sub_panel_num then
        self.head_sub_panel_index = 1

    elseif index < 1 then
        self.head_sub_panel_index = self.sub_panel_num

    else
        self.head_sub_panel_index = index
    end

    local cur_pos_y =  self.carnival_sub_panels[self.template_type][self.head_sub_panel_index].root_node:getPositionY()
    self.head_sub_panel_y = self.sview_height - cur_pos_y
end

function carnival_panel:CreateSubPanels(template_type, cur_num)
    if not self.carnival_sub_panels[template_type] then self.carnival_sub_panels[template_type] = {} end
    local num = math.min(MAX_SUB_PANEL_NUM, cur_num)

    if self.template_type ~= template_type then
        local sub_panels = self.carnival_sub_panels[self.template_type]
        --从容器中移除 sub_panel
        for i = 1, self.sub_panel_num do
            self.scroll_view:removeChild(sub_panels[i].root_node, true)
        end

        self:CreateOneSubPanel(1, num, template_type)
        self.sub_panel_height = self.carnival_sub_panels[template_type][1].root_node:getContentSize().height + 10
        self.sub_panel_num = num

    else
        --移除多余的sub_panel
        if self.sub_panel_num >= num then
            for i = num + 1, self.sub_panel_num do
                self.scroll_view:removeChild(self.carnival_sub_panels[template_type][i].root_node, true)
            end

            self.sub_panel_num = num
        else
            --sub_panel_num < num
            self:CreateOneSubPanel(self.sub_panel_num+1, num, template_type)
            self.sub_panel_height = self.carnival_sub_panels[template_type][1].root_node:getContentSize().height + 10
            self.sub_panel_num = num
        end
    end
end

function carnival_panel:CreateOneSubPanel(start, num, template_type)
    for i = start, num do
        local sub_panel = template_manager:GetMetaPanel(template_type).New()
        sub_panel:Init()

        self.carnival_sub_panels[template_type][i] = sub_panel
        self.scroll_view:addChild(sub_panel.root_node)
    end
end

--显示当前的 活动的信息
function carnival_panel:ShowCurCarnivalInfo()
    local cur_config = self.config_list[self.cur_index]
    self.title_text:setString(self:GetLocaleInfoString(cur_config,"name"))
    self.duration_text:setString(self:GetLocaleInfoString(cur_config,"duration"))
    self:SetTabColor()

    local template_type = cur_config.template_type
    if template_type == CARNIVAL_TEMPLATE_TYPE['cdkey'] then
        self.scroll_view:setVisible(false)
        cdkey_sub_panel:Show()

    else
        self.desc_text:setString(self:GetLocaleInfoString(cur_config,"desc"))
        local font_height = DESC_LINE_HEIGHT
        local width = 640
        if platform_manager:GetChannelInfo().carnival_desc_font_height then
            font_height = platform_manager:GetChannelInfo().carnival_desc_font_height
            width = 588
        end
        self.desc_panel_height = self.desc_text:getVirtualRenderer():getStringNumLines() * font_height + 5
        self.desc_text:setContentSize(width, self.desc_panel_height)

        cdkey_sub_panel:Hide()
        self.scroll_view:setVisible(true)

        self.carnival_sub_num = cur_config.stages

        self:CreateSubPanels(template_type, cur_config.stages)
        self.template_type = template_type

        self:LoadSubPanelInfo(cur_config)
    end
end

--加载子面板数据
function carnival_panel:LoadSubPanelInfo(config)

    local top_panel_height = 0
    local height = 0

    if self.template_type == CARNIVAL_TEMPLATE_TYPE["fund"] then
        credit_panel:Show(config)
        reward_sub_panel:Hide()

        top_panel_height = credit_panel.height

        height = self.carnival_sub_num * self.sub_panel_height + self.desc_panel_height + top_panel_height + OFFSET_Y
        height = math.max(height, self.sview_height)

        credit_panel.root_node:setPositionY(height -  self.desc_panel_height - OFFSET_Y)

    else
        reward_sub_panel:Show(config)
        credit_panel:Hide()

        top_panel_height = reward_sub_panel.height

        height = self.carnival_sub_num * self.sub_panel_height + self.desc_panel_height + top_panel_height + OFFSET_Y
        height = math.max(height, self.sview_height)

        reward_sub_panel.root_node:setPositionY(height -  self.desc_panel_height - OFFSET_Y)
    end

    self.desc_text:setPositionY(height)

    local sub_panel_init_pos_y = height - self.desc_panel_height - top_panel_height - OFFSET_Y * 2

    local cur_config = self.config_list[self.cur_index]
    for i = 1, self.sub_panel_num do
        local sub_panel = self.carnival_sub_panels[self.template_type][i]
        sub_panel:Show(cur_config, i)
        sub_panel.root_node:setPositionX(320)
        sub_panel.root_node:setPositionY(sub_panel_init_pos_y - (i - 1) * self.sub_panel_height)
    end

    self.data_offset = 0
    self:SetHeadSubPanel(1)

    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
    --setInnerContainerSize会触发scrolling事件
    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))

    self.scroll_view:jumpToTop()
end

function carnival_panel:GetLocaleInfoString( cur_config, key )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale]
    end
    return result
end

function carnival_panel:RegisterEvent()
    graphic:RegisterEvent("update_sub_carnival_reward_status", function(key)
        if not self.root_node:isVisible() then
            return
        end

        local cur_config = self.config_list[self.cur_index]
        if cur_config.key ~= key then
            return
        end

        for i = 1, self.sub_panel_num do
            local sub_panel = self.carnival_sub_panels[self.template_type][i]

            local data_index
            if i < self.head_sub_panel_index then
                data_index = self.data_offset + (self.sub_panel_num - self.head_sub_panel_index) + i + 1
            else
                data_index = self.data_offset + i - self.head_sub_panel_index + 1
            end

            sub_panel:Show(cur_config, data_index)
        end

        if cur_config.carnival_type == constants.CARNIVAL_TYPE["fund"] then
           credit_panel:Show(cur_config) 

        elseif cur_config.reward_type ~= 0 then
            reward_sub_panel:Show(cur_config)
        end
    end)

    --更新底部提醒icon
    graphic:RegisterEvent("remind_carnival", function(index, new_reward)
        for i = 1, #self.tab_btns do
            local tab_btn = self.tab_btns[i]
            if tab_btn:getTag() == index then
                local template_type = self.config_list[index].template_type
                if template_type ~= CARNIVAL_TEMPLATE_TYPE["rank"] then
                    tab_btn:getChildByName("icon"):setVisible(new_reward)
                end
                break
            end
        end
    end)

    graphic:RegisterEvent("update_carnival_union_data", function(ids, nums)
        for i = 1, #ids do
            self.carnival_sub_panels[CARNIVAL_TEMPLATE_TYPE["rank"]][i]:Load(ids[i], i)
        end
    end)

    graphic:RegisterEvent("carnival_vote", function()
        if not self.root_node:isVisible() then
            return
        end

        local cur_config = self.config_list[self.cur_index]
        if cur_config.carnival_type ~= constants.CARNIVAL_TYPE["vote"] then
            return
        end

        reward_sub_panel:Show(cur_config)

        for i = 1, self.sub_panel_num do
            local sub_panel = self.carnival_sub_panels[self.template_type][i]
            sub_panel:Show(cur_config, i)
        end
    end)

    graphic:RegisterEvent("choose_mercenary_evolution", function(key, index, list)
        if not self.root_node:isVisible() then
            return
        end

        for i = 1, #self.config_list do
            if self.config_list[i].key == key then
                self.cur_index = i
                self:ShowCurCarnivalInfo()

                local sub_panel = self.carnival_sub_panels[self.template_type][index]
                sub_panel:ChooseMercenary(key, index, list)

                self.tab_lview:jumpToPercentHorizontal(self.cur_index / #self.config_list * 100 )
                self.tab_lview:refreshView()
                break
            end
        end
    end)

      graphic:RegisterEvent("mercenary_evolution_success", function(fomula_id)
        if not self.root_node:isVisible() then
            return
        end

        if self.template_type ~= CARNIVAL_TEMPLATE_TYPE["evolution"] then
            return
        end

        for i = 1, #self.carnival_sub_panels[self.template_type] do
            local sub_panel = self.carnival_sub_panels[self.template_type][i]
            sub_panel:OnEvolutionSuccess(fomula_id)
        end
    end)
end

function carnival_panel:RegisterWidgetEvent()
    self.view_carnival_info = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self.cur_index = widget:getTag()
            self:ShowCurCarnivalInfo()

            local config = self.config_list[self.cur_index]
            if config.template_type == CARNIVAL_TEMPLATE_TYPE["rank"] and config.carnival_type == constants.CARNIVAL_TYPE["collect_item"] then
                carnival_logic:GetUnionData(config)
            end
        end
    end

    self.scroll_view:addEventListener(function(lview, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            local y = self.scroll_view:getInnerContainer():getPositionY()

            if y >= self.head_sub_panel_y + self.sub_panel_height then
                if self.data_offset + self.sub_panel_num >= self.carnival_sub_num then

                else
                    self.data_offset = self.data_offset + 1

                    local sub_panel = self.carnival_sub_panels[self.template_type][self.head_sub_panel_index]
                    local last_sub_panel_index = self.sub_panel_num
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end

                    sub_panel.root_node:setPositionY(self.carnival_sub_panels[self.template_type][last_sub_panel_index].root_node:getPositionY() - self.sub_panel_height)

                    sub_panel:Show(self.config_list[self.cur_index], self.data_offset + self.sub_panel_num)
                    self:SetHeadSubPanel(self.head_sub_panel_index + 1)
                end

            elseif y <= self.head_sub_panel_y  then

                if self.data_offset ~= 0 then
                    self.data_offset = self.data_offset - 1

                    local last_sub_panel_index = self.sub_panel_num
                    if self.head_sub_panel_index ~= 1 then
                        last_sub_panel_index = self.head_sub_panel_index - 1
                    end

                    local sub_panel = self.carnival_sub_panels[self.template_type][last_sub_panel_index]
                    sub_panel.root_node:setPositionY(self.carnival_sub_panels[self.template_type][self.head_sub_panel_index].root_node:getPositionY() + self.sub_panel_height)

                    sub_panel:Show(self.config_list[self.cur_index], self.data_offset + 1)

                    self:SetHeadSubPanel(self.head_sub_panel_index - 1)
                end
            end
        end
    end)
end

return carnival_panel
