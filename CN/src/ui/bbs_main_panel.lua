local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local panel_prototype = require "ui.panel"
local audio_manager = require "util.audio_manager"
local time_logic = require "logic.time"
local chat_logic = require "logic.chat"
local guild_logic = require "logic.guild"
local feature_config = require "logic.feature_config"
local cjson = require "util.json"
local platform_manager = require "logic.platform_manager"
local client_constants = require "util.client_constants"
local constants = require "util.constants"
local lang_constants = require "util.language_constants"
local configuration = require "util.configuration"
local rech_text = require "ui.RichLableText"
local input_widget = require "ui.InputWidget"
local utils = require "util.utils"
local user_logic = require "logic.user"
local common_function = require "util.common_function"
local config_manager = require "logic.config_manager"
local vip_logic = require "logic.vip"
local adventure_logic = require "logic.adventure"
local login_logic = require "logic.login"
local open_permanent_config = config_manager.open_permanent_config

local reuse_scrollview = require "widget.reuse_scrollview"
local adventure_maze_config = config_manager.adventure_maze_config

local PLIST_TYPE = ccui.TextureResType.plistType
local look_img_path = client_constants["CHAT_IMG_PATH"]

local MARGIN = 5
local FIRST_SUB_PANEL_OFFSET = -30
local MAX_SUB_PANEL_NUM = 7
local SUB_PANEL_HEIGHT = 0
local CHAT_CONTENT_OFFSET_X = 15
local CHAT_LIST_OFFSET_X = 45
local MAX_CONTENTS_NUMBER = 50
local MAX_TEXT_NUMBER = 150

local BG_SPEC = 0xFFB9B9 -- 后台发布讨论背景
local BG_NORMAL = 0xFFFFFF -- 普通讨论背景

local TAB_TYPE =
{
    ["all"] = 1,
    ["guild"] = 2,
    ["mine"] = 3,
    ["world_chat"] = 4,
}
local TAB_NUM = 4

--聊天模板
local chat_sub_panel = panel_prototype.New()
chat_sub_panel.__index = chat_sub_panel

function chat_sub_panel.New()
    return setmetatable({}, chat_sub_panel)
end

function chat_sub_panel:Init(root_node)
    self.root_node = root_node
    --名字
    self.name_text = self.root_node:getChildByName("Text_91")
    self.name_top_dis = self.root_node:getContentSize().height - self.name_text:getPositionY()

    --区服
    self.region_text = self.root_node:getChildByName("Text_91_0")
    self.region_top_dis = self.root_node:getContentSize().height - self.region_text:getPositionY()

    --聊天背景框
    self.chatbox_bg = self.root_node:getChildByName("chat_box")
    self.chatbox_bg_top_dis = self.root_node:getContentSize().height - self.chatbox_bg:getPositionY()

    --向右的箭头
    self.right_arrow = self.root_node:getChildByName("chat_box21")
    self.right_arrow_top_dis = self.root_node:getContentSize().height - self.right_arrow:getPositionY()

    --向左的箭头
    self.left_arrow = self.root_node:getChildByName("chat_box2")
    self.left_arrow_top_dis = self.root_node:getContentSize().height - self.left_arrow:getPositionY()

    --聊天文字
    self.chatbox_bg_width = self.chatbox_bg:getContentSize().width
    self.chatbox_bg_pos_x = self.chatbox_bg:getPositionX()   
    self.chat_text = rech_text.new("",self.chatbox_bg_width - 20,22)
    self.chatbox_bg:addChild(self.chat_text)
    
    --左边的头像
    self.left_shawdown = self.root_node:getChildByName("user_bg")
    self.left_user_icon = self.left_shawdown:getChildByName("user_icon")
    self.left_shawdown_top_dis = self.root_node:getContentSize().height - self.left_shawdown:getPositionY()

    --右边的头像
    self.right_shawdown = self.root_node:getChildByName("user_bg1")
    self.right_user_icon = self.right_shawdown:getChildByName("user_icon")
    self.right_shawdown_top_dis = self.root_node:getContentSize().height - self.right_shawdown:getPositionY()
end

function chat_sub_panel:Show(info)
    self.root_node:setVisible(true)
    --将获取得到的内容转换为XML格式的，转换中有图片，
    local content = utils:ConvertToXML(info.content)
    self.chat_text:setString(content)

    --头像图片路径
    local conf = config_manager.mercenary_config[info.template_id]
    self.conf_icon = client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png"
    

    --判断是否是自己说的话
    self.is_self_talk = false
    if info.user_id == user_logic:GetUserId() then
        --是自己说话，右边显示，左边隐藏
        self.name_text:setVisible(false)
        self.left_shawdown:setVisible(false)
        self.left_arrow:setVisible(false)
        self.right_arrow:setVisible(true)
        self.right_shawdown:setVisible(true)
        self.region_text:setVisible(false)
        self.is_self_talk = true
        self.right_user_icon:loadTexture(self.conf_icon, PLIST_TYPE)
    else
        --别人说的话，左边显示右边隐藏
        self.name_text:setVisible(true)
        self.left_shawdown:setVisible(true)
        self.left_arrow:setVisible(true)
        self.right_arrow:setVisible(false)
        self.right_shawdown:setVisible(false)
        self.region_text:setVisible(true)
        --要显示名字和区服
        self.name_text:setString(info.leader_name)
        self.region_text:setString("【"..info.server_name.."】")
        self.region_text:setPositionX(self.name_text:getPositionX() + self.name_text:getContentSize().width + 3)
        self.left_user_icon:loadTexture(self.conf_icon, PLIST_TYPE)
    end

    --设置聊天文字内容边距
    self.chatbox_bg:setContentSize(cc.size(self.chat_text.width + 30, self.chat_text.height + 20))
    if self.is_self_talk then
        --自己的对话框整体偏移右边
        self.chatbox_bg:setPositionX(self.chatbox_bg_pos_x + (self.chatbox_bg_width - self.chat_text.width - 30))
    end
    --内容偏移
    self.chat_text:setPosition(cc.p(CHAT_CONTENT_OFFSET_X,(self.chat_text.height + 10)))
    self.height = self.chat_text.height + 30 + CHAT_LIST_OFFSET_X
    --当前整个对话框的大小设置
    self.root_node:setContentSize(cc.size(self.root_node:getContentSize().width,self.height))
    self:LoadPosition()
end

--重新设置控件的位置
function chat_sub_panel:LoadPosition()
    --聊天框向下扩展，所以所有控件以上边对齐，进行位置偏移
    self.left_shawdown:setPositionY(self.height - self.left_shawdown_top_dis)
    self.right_shawdown:setPositionY(self.height - self.right_shawdown_top_dis)
    self.name_text:setPositionY(self.height - self.name_top_dis)
    self.region_text:setPositionY(self.height - self.region_top_dis)
    self.chatbox_bg:setPositionY(self.height - self.chatbox_bg_top_dis)
    self.right_arrow:setPositionY(self.height - self.right_arrow_top_dis)
    self.left_arrow:setPositionY(self.height - self.left_arrow_top_dis)
end

local discuss_sub_panel = panel_prototype.New()
discuss_sub_panel.__index = discuss_sub_panel

function discuss_sub_panel.New()
    return setmetatable({}, discuss_sub_panel)
end

function discuss_sub_panel:Init(root_node, index)
    self.root_node = root_node

    self.role_img = root_node:getChildByName("user_icon")
    self.name_text = root_node:getChildByName("user_name")
    self.time_text = root_node:getChildByName("time")
    self.detail_text = root_node:getChildByName("discuss_detail")

    self.reply_num_text = root_node:getChildByName("discuss_num")

    self.root_node:setTag(index)
end

function discuss_sub_panel:Show(discuss)
    local content = discuss
    content.discuss = content.discuss or ""
    self.name_text:setString(content.role)

    self.detail_text:setString(content.discuss)

    local date = time_logic:GetDateInfo(content.time)
    if platform_manager:GetLocale() == "en-US" then
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.month, date.day, date.year, date.hour, date.min, date.sec))
    elseif platform_manager:GetLocale() == "zh-CN" or platform_manager:GetLocale() == "zh-TW" then
        self.time_text:setString(string.format("%d/%02d/%02d %d:%d:%d", date.year, date.month, date.day, date.hour, date.min, date.sec))
    else
        self.time_text:setString(string.format("%02d/%02d/%d %d:%d:%d", date.day, date.month, date.year, date.hour, date.min, date.sec))
    end

    self.role_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. content.icon .. ".png", PLIST_TYPE)
    self.role_img:setScale(2, 2)

    if tonumber(content.user_type) == 1 then
        self.root_node:setColor(panel_util:GetColor4B(BG_SPEC))
    else
        self.root_node:setColor(panel_util:GetColor4B(BG_NORMAL))
    end

    self.reply_num_text:setString(tostring(discuss.num))

    self.root_node:setVisible(true)

    self.root_node.discuss = content
end

local bbs_main_panel = panel_prototype.New(true)
function bbs_main_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/discuss_main_panel.csb")
    self.back_btn = self.root_node:getChildByName("back_btn")

    self.new_discuss_btn = self.root_node:getChildByName("discuss_btn")
    if platform_manager:GetLocale() == "fr" and platform_manager:GetChannelInfo().bbs_main_panel_change_discuss_btn_text_pos_x then
        self.new_discuss_btn:getTitleRenderer():setPositionX(self.new_discuss_btn:getTitleRenderer():getPositionX() + 45)
    end

    self.back_top_btn = self.root_node:getChildByName("back_top_btn")

    self.guild_tab_btn = self.root_node:getChildByName("tab_discuss_guild")
    self.guild_tab_btn:setTag(TAB_TYPE["guild"])

    self.guild_tab_btn:setVisible(feature_config:IsFeatureOpen("guild"))

    self.all_tab_btn = self.root_node:getChildByName("tab_discuss")
    self.all_tab_btn:setTag(TAB_TYPE["all"])

    self.mine_tab_btn = self.root_node:getChildByName("tab_mine")
    self.mine_tab_btn:setTag(TAB_TYPE["mine"])

    --世界聊天
    if feature_config:IsFeatureOpen("chat_world") then
        self.world_chat_btn = self.root_node:getChildByName("tab_discuss_0")
        self.world_chat_btn:setTag(TAB_TYPE["world_chat"])
        self.chat_panel = self.root_node:getChildByName("chat01")
        self:InitChat()
    end

    self.tab_btns = {}
    self.tab_btns[TAB_TYPE["all"]] = self.all_tab_btn
    self.tab_btns[TAB_TYPE["guild"]] = self.guild_tab_btn
    self.tab_btns[TAB_TYPE["mine"]] = self.mine_tab_btn
    if feature_config:IsFeatureOpen("chat_world") then
        self.tab_btns[TAB_TYPE["world_chat"]] = self.world_chat_btn
    end
    self.new_tips_img = self.root_node:getChildByName("new_tips")
    self.tips_num_text = self.new_tips_img:getChildByName("num")

    self.new_tips_img:setVisible(false)
    self.new_tips_img:setLocalZOrder(10)
    self.tips_num_text:setString("0")

    self.rotation = 0
    self.flush_flag = false

    self.loading_img = self.root_node:getChildByName("loading_img")
    self.loading_text = self.root_node:getChildByName("loading_text")

    self.discuss_list = self.root_node:getChildByName("discuss_list")

    self.template = self.root_node:getChildByName("template")
    self.template:getChildByName("user_icon"):ignoreContentAdaptWithSize(true)
    self.template:setVisible(false)

    self.discuss_list:setBounceEnabled(true)

    SUB_PANEL_HEIGHT = self.template:getContentSize().height + MARGIN
    if self.back_top_btn then
        self.back_top_btn:setVisible(false)
    end
    self.discuss_sub_panels = {}
    self.sub_panel_num = 0

    self.bbs_list = {}

    self.reuse_scrollview = reuse_scrollview.New(self, self.discuss_list, self.discuss_sub_panels, SUB_PANEL_HEIGHT)
    self.reuse_scrollview:RegisterMethod(
        function(self)
            return #self.parent_panel.bbs_list
        end,

        function(self, sub_panel, is_up)
            local index =  is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Show(self.parent_panel.bbs_list[index])
        end
    )

    self.height = 0
    self.data_offset = 0

    self.cur_tab_type = TAB_TYPE["all"]

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function bbs_main_panel:Show(default_tab_type)
    self.root_node:setVisible(true)

    self.cur_tab_type = TAB_TYPE[default_tab_type] or self.cur_tab_type

    if self.cur_tab_type == TAB_TYPE["all"] then
        chat_logic:QueryDiscussCommon()
    elseif self.cur_tab_type == TAB_TYPE["guild"] then
        chat_logic:QueryDiscussGuild()
    end

    if feature_config:IsFeatureOpen("chat_world") then
        self.root_node:setPosition(cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y))
        self.look_face_panel:setVisible(false)
    end

    self:UpdateTab(self.cur_tab_type)
    self:ResetData(self.cur_tab_type)
end

function bbs_main_panel:CreateSubPanels()
    local num = math.min(MAX_SUB_PANEL_NUM, #self.bbs_list)
    if self.sub_panel_num >= num then
        return
    end

    for i = self.sub_panel_num + 1, num do
        local sub_panel = discuss_sub_panel.New()
        sub_panel:Init(self.template:clone(), i)

        self.discuss_sub_panels[i] = sub_panel
        sub_panel.root_node:addTouchEventListener(self.view_discuss_method)

        self.discuss_list:addChild(sub_panel.root_node)
    end

    self.sub_panel_num = num
end

--初始化聊天控件
function bbs_main_panel:InitChat()
    self.chat_panel_pos_y = self.root_node:getPositionY()
    --聊天列表
    self.chat_list = self.chat_panel:getChildByName("ListView_2")
    
    --聊天模板
    self.chat_templeat_left = self.chat_panel:getChildByName("chat_box_1")
    self.chat_templeat_left:setVisible(false)
    self.caht_templeat_right = self.chat_panel:getChildByName("chat_box_2")
    self.caht_templeat_right:setVisible(false)
    self.caht_templeat_history = self.chat_panel:getChildByName("chat_box_2_0")
    self.caht_templeat_history:setVisible(false)
    
    --输入框背景
    local chat_input_bg = self.chat_panel:getChildByName("bottom_bar_0")
    --发送按钮
    self.chat_send_btn = chat_input_bg:getChildByName("send_bg")
    --表情按钮
    self.chat_send_look_face = chat_input_bg:getChildByName("send_bg_0")
    --添加输入框
    local input_bg = chat_input_bg:getChildByName("bp_condition")
    -- self.edit_box = ccui.EditBox:create(cc.size(input_bg:getContentSize().width,input_bg:getContentSize().height), "bg/weaponbox_infobg2_d.png", 0)
    -- self.edit_box:setPosition(input_bg:getPosition())
    -- self.edit_box:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_ALL_CHARACTERS)
    -- self.edit_box:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    -- self.edit_box:setAnchorPoint(cc.p(0,0.5))
    -- self.edit_box:setPlaceHolder(lang_constants:Get("input_widget_place_holder"))
    -- chat_input_bg:addChild(self.edit_box)

    self.text_filed = chat_input_bg:getChildByName("room_number_0")
    self.text_feild_start_pos_x = chat_input_bg:getPositionY() + self.text_filed:getPositionY()
    self.light = chat_input_bg:getChildByName("light")
    self.light:setVisible(false)
    self.text_filed:setPlaceHolder(lang_constants:Get("input_widget_place_holder"))
    self.text_filed:setTextVerticalAlignment(1)
    self.text_filed:setOpacity(0)
    self.text_field_text = chat_input_bg:getChildByName("Panel_6"):getChildByName("Text_137")
    self.text_field_text:setFontSize(24)
    self.text_filed:setString("")
    self:UpdateLightPos()
    
    --表情框
    self.look_face_panel = self.chat_panel:getChildByName("face") 
    self.look_face_panel:setVisible(false)
    self.look_face_list = self.look_face_panel:getChildByName("PageView_1")

    --房间输入
    local room_node = self.chat_panel:getChildByName("Node_room")
    --房间输入框
    local room_input_bg = room_node:getChildByName("input_bg")
    self.room_input = ccui.EditBox:create(cc.size(room_input_bg:getContentSize().height,room_input_bg:getContentSize().width + 8), "bg/weaponbox_infobg2_d.png", 0)
    self.room_input:setPosition(cc.p(room_input_bg:getPosition()))
    self.room_input:setMaxLength(3)
    --设置格式为纯数字输入
    self.room_input:setInputMode(3) 
    self.room_input:setAnchorPoint(cc.p(0,0.5))
    room_node:addChild(self.room_input)
    self.room_input:setText("0")
    self.room_max_tips_text = room_node:getChildByName("num_1")

    --新消息提示框
    self.new_message_tips_bg = self.chat_panel:getChildByName("bg3_0")
    self.new_message_tips_bg:setVisible(false)
    
    --初始化表情
    self:InitEmojPanel()

    self.chat_message_number = 0 
    self.edit_old_box_str = ""
end

--添加表情面板
function bbs_main_panel:InitEmojPanel()
    --这里如果翻页还得另外处理
    local now_page_widget = self.look_face_list:getChildByName("Panel_5")
    local i = 1
    for k,v in pairs(look_img_path) do
        local emoj_img = now_page_widget:getChildByName(string.format("btn_%02d",i))
        emoj_img:loadTexture(v,PLIST_TYPE)
        emoj_img:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                --添加到当前聊天输入框里
                local old_text = self.text_filed:getString()
                -- print("index = ",i)
                self.text_filed:setString(old_text .. "["..k.."]")
                self.edit_old_box_str = self.text_filed:getString()
                self:UpdateLightPos()
            end
        end)
        i = i + 1
    end

    --删除按钮
    local delete_btn = now_page_widget:getChildByName("btn_back") 
    delete_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --添加到当前聊天输入框里
            local old_text = self.text_filed:getString()
            -- -- print("index = ",i)
            local str_arry = utils:strSplit(old_text)
            local new_str = ""
            for i=1,(#str_arry-1) do
                new_str = new_str .. str_arry[i]
            end
            self.text_filed:setString(new_str)
            self:CheckWillDeleteText(self.edit_old_box_str)
        end
    end)

end

--添加一个聊天消息进入列表
function bbs_main_panel:AddChatToListView(content)
    local temp = self.chat_templeat_left:clone()
    local chat_sub = chat_sub_panel.New()
    chat_sub:Init(temp)
    chat_sub:Show(content)
    self.chat_list:pushBackCustomItem(temp)
end

--检查是否有新消息
function bbs_main_panel:CheckChatNewMessage()
    --获取新的消息数量
    local now_chat_content = chat_logic:getNewChatContent()
    if #now_chat_content > 0 then
        --如果有新消息
        for k,content in pairs(now_chat_content) do
            self:AddChatToListView(content)
        end
        --移除所有已经添加了的新消息
        chat_logic:removeAllNewChatContent()
        --判断当前聊天内容是否已经满了，如果已经超过了最大值，就移除（这个放到移动之后）
        local number = #self.chat_list:getItems()
        if number > MAX_CONTENTS_NUMBER then
            for i = 1, number - MAX_CONTENTS_NUMBER do
                self.chat_list:removeItem(0)
            end
        end
    end
end

function bbs_main_panel:ResetData(tab_type)
    if self.chat_panel then
        self.chat_panel:setVisible(false)
    end
    self.back_btn:setVisible(true)
    self.new_discuss_btn:setVisible(true)
    self.discuss_list:setVisible(true)
    if self.room_input then
        -- self.edit_box:setVisible(false)
        self.room_input:setVisible(false)
    end

    if tab_type == TAB_TYPE["all"] then
        self.bbs_list = chat_logic.bbs_channel_common or {}
        self.new_discuss_btn:setVisible(true)

    elseif tab_type == TAB_TYPE["mine"] then
        self.new_discuss_btn:setVisible(false)
        self.bbs_list = chat_logic.bbs_channel_mine or {}

        -- 更新刷新时间
        configuration:SetFlushBBSTime(os.time())
        configuration:Save()

        graphic:DispatchEvent("new_bbs")
        chat_logic.new_mine_num = 0

    elseif tab_type == TAB_TYPE["guild"] then
        self.new_discuss_btn:setVisible(true)
        self.bbs_list = chat_logic.bbs_channel_guild or {}
    elseif tab_type == TAB_TYPE["world_chat"] then
        --聊天
        self.cur_tab_type = tab_type
        self.chat_panel:setVisible(true)
        self.back_btn:setVisible(false)
        self.new_discuss_btn:setVisible(false)
        self.discuss_list:setVisible(false)
        self.room_input:setVisible(true)

        --检查聊天是否连接服务器
        if chat_logic:CheckIsConnect() then
            -- print("连接成功")
            self.room_input:setText(chat_logic.connect_ip_id)
            self:CheckChatNewMessage()
            local chat_server_list = login_logic:GetChatServerList()
            if #chat_server_list > 0 then
                self.room_max_tips_text:setString(string.format(lang_constants:Get("chat_room_number_max_tips"), #chat_server_list))
            end
        else
            -- print("连接失败")
        end

        return
    end

    -- 小绿点
    local new_mine = chat_logic.new_mine_num
    if new_mine > 0 then
        self.new_tips_img:setVisible(true)
        self.tips_num_text:setString(tostring(new_mine))
    else
        self.new_tips_img:setVisible(false)
    end

    self.loading_img:setVisible(false)
    self.loading_text:setVisible(false)

    self:CreateSubPanels()

    if self.cur_tab_type ~= tab_type then
        self.data_offset = 0

    else
        self.data_offset = self.reuse_scrollview.data_offset
    end

    self:UpdatePanel()
    self.cur_tab_type = tab_type
end

function bbs_main_panel:UpdatePanel()
    local count = #self.bbs_list

    self.height = math.max(SUB_PANEL_HEIGHT * count, self.reuse_scrollview.sview_height) + 30
    if self.back_top_btn then
        self.back_top_btn:setVisible(false)
    end
    for i = 1, self.sub_panel_num do
        local discuss = self.bbs_list[i + self.data_offset]
        local sub_panel = self.discuss_sub_panels[i]

        if discuss then
            sub_panel:Show(discuss)
            sub_panel.root_node:setPositionY(self.height + FIRST_SUB_PANEL_OFFSET - (self.data_offset + i - 1) * SUB_PANEL_HEIGHT)

        else
            sub_panel:Hide()
        end
    end

    self.reuse_scrollview:Show(self.height, self.data_offset)
end

function bbs_main_panel:UpdateTab(tab_type)

    for i = 1, #self.tab_btns do
        local is_selected = tab_type == i
        local tab_btn = self.tab_btns[i]
        if is_selected then
            tab_btn:setColor(panel_util:GetColor4B(0xFFFFFF))
            tab_btn:setLocalZOrder(2)
        else
            tab_btn:setColor(panel_util:GetColor4B(0x7F7F7F))
            tab_btn:setLocalZOrder(1)
        end
    end
end

function bbs_main_panel:Hide()
    self.root_node:setVisible(false)
    if self.room_input then
        --因为这两个输入框没有跟着root_node隐藏，所以要手动隐藏
        self.room_input:setVisible(false)
    end
end

function bbs_main_panel:RegisterWidgetEvent()

    --返回按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_scene")
        end
    end)

    --发起讨论
    self.new_discuss_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not chat_logic:IsAuthorized() then
                -- 月卡购买提示
                graphic:DispatchEvent("show_simple_msgbox", lang_constants:Get("buy_vip_title"),
                            lang_constants:Get("chat_not_use_desc"),
                            lang_constants:Get("common_confirm"),
                            lang_constants:Get("common_cancel"),
                function()
                     graphic:DispatchEvent("show_world_sub_panel", "vip_panel")
                end)
                return
            end

            local channel_type = constants.BBS_CHANNEL.common
            if self.cur_tab_type  == TAB_TYPE["all"] then
                channel_type = constants.BBS_CHANNEL.common
            elseif self.cur_tab_type  == TAB_TYPE["guild"] then
                channel_type = constants.BBS_CHANNEL.guild
            end
            graphic:DispatchEvent("show_world_sub_scene", "bbs_new_disscuss_sub_scene", false, channel_type)
        end
    end)

    self.mine_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            self:UpdateTab(TAB_TYPE["mine"])
            self:ResetData(TAB_TYPE["mine"])
        end
    end)
    if self.world_chat_btn then
        self.world_chat_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
                local chat_open_permanent_config = open_permanent_config[FEATURE_TYPE["chat_world"]]
                if not chat_open_permanent_config then
                    return
                end
                local open_value = chat_open_permanent_config.value  
                local is_unlock = adventure_logic:IsMazeClear(open_value)

                --判断是否开启条件
                if not is_unlock and not vip_logic:IsActivated(constants["VIP_TYPE"]["adventure"]) then
                    graphic:DispatchEvent("show_prompt_panel", "chat_need_vip_tips", adventure_maze_config[open_value]["name"])
                    return
                end

                self:UpdateTab(TAB_TYPE["world_chat"])
                self:ResetData(TAB_TYPE["world_chat"])
            end
        end)
    end

    self.all_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            chat_logic:QueryDiscussCommon()

            self:UpdateTab(TAB_TYPE["all"])
            self:ResetData(TAB_TYPE["all"])
        end
    end)

    self.guild_tab_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not guild_logic:IsGuildMember() then
                graphic:DispatchEvent("show_prompt_panel", "guild_not_member")
                return
            end

            chat_logic:QueryDiscussGuild()

            self:UpdateTab(TAB_TYPE["guild"])
            self:ResetData(TAB_TYPE["guild"])
        end
    end)

    if self.back_top_btn then
        self.back_top_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                self.back_top_btn:setVisible(false)
                self.reuse_scrollview:Show(self.height, 0)
                self:ResetData(self.cur_tab_type)
            end
        end)
    end

    self.view_discuss_method =  function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            chat_logic:QueryDiscussDetail(widget.discuss)
        end
    end

    self.discuss_list:addEventListener(function(widget, event_type)
        if event_type == ccui.ScrollViewEventType.bounceTop then
            --隐藏返回顶部按钮
            if self.back_top_btn then
                self.back_top_btn:setVisible(false)
            end
            if self.flush_flag then
                if self.cur_tab_type == TAB_TYPE["all"] then
                    chat_logic:QueryDiscussCommon(true)
                elseif self.cur_tab_type == TAB_TYPE["guild"] then
                    chat_logic:QueryDiscussGuild(true)
                else
                    self.loading_img:setVisible(false)
                    self.loading_text:setVisible(false)
                end
            end

        elseif event_type == ccui.ScrollViewEventType.scrolling then
            local cur_y = self.discuss_list:getInnerContainer():getPositionY()
            if cur_y < (self.reuse_scrollview.sview_height - self.height) then
                self.loading_img:setVisible(true)
                self.loading_text:setVisible(true)
                self.flush_flag = true
            else
                self.loading_img:setVisible(false)
                self.loading_text:setVisible(false)
                if self.back_top_btn then
                    self.back_top_btn:setVisible(true)
                end
            end

            self.reuse_scrollview:OnScrolling(widget, event_type)
        end
    end)

    if self.chat_list then
        self.chat_list:addScrollViewEventListener(function(widget, event_type)
            if event_type == ccui.ScrollViewEventType.scrolling then
                self.is_bottom = false
            elseif event_type == ccui.ScrollViewEventType.scrollToBottom then 
                --检查是否有新的消息
                self.is_bottom = true
                self.new_message_tips_bg:setVisible(false)
            end
        end)
    end

    --发送消息
    if self.chat_send_btn then
        self.chat_send_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                function trim (s) 
                    return (string.gsub(s, "^%s*(.-)%s*$", "%1")) 
                end

                local str = trim(self.text_filed:getString())
                if str == "" or str == nil then
                    return
                end
                self.edit_old_box_str = ""
                self.text_filed:setString("")

                local now_input_str_arry = utils:strSplit(str)
                local send_str = ""
                for k,v in pairs(now_input_str_arry) do
                    local input_word = v
                    if v == "<" then
                        --这个字符要进行转换后使用，不然不能被解析
                        input_word = string.char(8)
                    end
                    send_str = send_str .. input_word
                end

                chat_logic:SendMessage(send_str)

                self:UpdateLightPos()
                if self.look_face_panel:isVisible() then
                    self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y)))
                    self.look_face_panel:setVisible(false)
                end
            end
        end)
    end

    --添加表情
    if self.chat_send_look_face then
        self.chat_send_look_face:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                if self.look_face_panel:isVisible() then
                    self.root_node:stopAllActions()
                    self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y)))
                    self.look_face_panel:setVisible(false)
                else
                    if not self.attach_with_ime then
                        local move_height = self.look_face_panel:getContentSize().height
                        self.look_face_panel:setVisible(true)
                        self.root_node:stopAllActions()
                        self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y + move_height)))
                    end
                end
            end
        end)
    end

    if self.edit_box then
        self.edit_box:registerScriptEditBoxHandler(function (eventType)
            if eventType == "began" then
                -- print("开始输入")
            elseif eventType == "ended" then
                -- print("输入结束")
                if self.look_face_panel:isVisible() then
                    self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y)))
                    self.look_face_panel:setVisible(false)
                end
            elseif eventType == "changed" then
                local str = self.edit_box:getText()
                local now_length = string.len(str)
                local old_length = string.len(self.edit_old_box_str)
                if now_length < old_length then
                    -- local input_str = string.sub(self.edit_old_box_str,now_length + 1)
                    -- print("删除字体",input_str)
                    self:CheckWillDeleteText(self.edit_old_box_str)
                else
                    self.edit_old_box_str = str
                end
                
            elseif eventType == "return" then
                if self.look_face_panel:isVisible() then
                    self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.chat_panel:getPositionX(),self.chat_panel_pos_y)))
                    self.look_face_panel:setVisible(false)
                end
            end
        end)
    end

    if self.text_filed then
        self.text_filed:addEventListener(function (sender, eventType)
        if eventType == ccui.TextFiledEventType.attach_with_ime then 
            self.attach_with_ime = true
            self.root_node:stopAllActions()
            self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.root_node:getPositionX(),self.chat_panel_pos_y + (1136/2 - self.text_feild_start_pos_x))))
            if self.look_face_panel:isVisible() then
                self.look_face_panel:setVisible(false)
            end
        elseif eventType == ccui.TextFiledEventType.detach_with_ime then
            self.attach_with_ime = false
            self.root_node:stopAllActions()
            self.root_node:runAction(cc.MoveTo:create(0.25,cc.p(self.root_node:getPositionX(),self.chat_panel_pos_y)))
        elseif eventType == ccui.TextFiledEventType.insert_text then
            local now_str = self.text_filed:getString()
            local now_length = string.len(now_str)
            if now_length > MAX_TEXT_NUMBER then
                self.text_filed:setString(self.edit_old_box_str)
            end
            local str = self.text_filed:getString()
            self.edit_old_box_str = str
            self:UpdateLightPos()
            
        elseif eventType == ccui.TextFiledEventType.delete_backward then  
            self:CheckWillDeleteText(self.edit_old_box_str)
        end 
    end)
    end

    --房间输入监听
    if self.room_input then
        self.room_input:registerScriptEditBoxHandler(function (eventType)
            if eventType == "began" then
                self.start_change_room = true
            elseif eventType == "ended" then
                if self.start_change_room then
                    self:ChangeConnect()
                end
                self.start_change_room = false
            elseif eventType == "changed" then
               
            elseif eventType == "return" then
                if self.start_change_room then
                    self:ChangeConnect()
                end
                self.start_change_room = false
            end
        end)
    end
end

--检查删除的字体是否是一张图片，如果是一张图片，则删除整个标签
function bbs_main_panel:CheckWillDeleteText(delete_str)
    local str_arry = utils:strSplit(delete_str)
    if str_arry[#str_arry] == "]" then
        --如果最后一位是这个符号，可能是一张图片
        local content_str = ""
        local find = 0
        for i=#str_arry-1,0,-1 do
            local next_str = str_arry[i]
            if next_str == "]" then
                --在找到"["这个之前找到了这个，说明最后一个不是图片
                break
            elseif next_str == "[" then
                --找到了”[“和前面的组合成为一对
                find = i
                break
            elseif next_str then
                content_str = next_str .. content_str
            end
        end
       
        if find > 0 then
            --判断是否是图片key
            if look_img_path[content_str] then
                local new_str = ""
                for i=1,(find-1) do
                    new_str = new_str .. str_arry[i]
                end
                self.text_filed:setString(new_str)
            end
        end
    end
    self.edit_old_box_str = self.text_filed:getString()
    self:UpdateLightPos()
end

function bbs_main_panel:UpdateLightPos()

    local now_str = self.text_filed:getString()
    self.text_field_text:setString(now_str)
    if now_str == "" then
        self.light:stopAllActions()
        self.light_action = false
        self.light:setVisible(false)
        self.text_filed:setOpacity(255)
        return
    end
    self.text_filed:setOpacity(0)

    local size = self.text_field_text:getContentSize()
    if not self.light_action then
        self.light_action = true
        self.light:runAction(cc.RepeatForever:create(cc.Blink:create(1,1)))
    end
    local pos_x = 0
    if size.width >= self.text_filed:getContentSize().width then
        pos_x = self.text_filed:getContentSize().width - size.width
        self.light:setPositionX(self.text_filed:getPositionX() + self.text_filed:getContentSize().width)
    else
        self.light:setPositionX(self.text_filed:getPositionX() + size.width)
        self.light:setVisible(true)
    end
    self.text_field_text:setPositionX(pos_x)
end

function bbs_main_panel:ChangeConnect()
    local now_id = tonumber(self.room_input:getText())
    if chat_logic.connect_ip_id ~= now_id then
        if not chat_logic:ChangeConnect(now_id) then
            self.room_input:setText(chat_logic.connect_ip_id)
        end
    end
end


function bbs_main_panel:RegisterEvent()
    graphic:RegisterEvent("update_bbs_main_panel", function()
        if self.flush_flag then
            self.flush_flag = false
        end

        if not self.root_node:isVisible() then
            return
        end
        self:ResetData(self.cur_tab_type)
    end)

    graphic:RegisterEvent("update_bbs_detail_panel", function(discuss)
        if not self.root_node:isVisible() then
            return
        end
    end)

    --聊天有新的消息
    graphic:RegisterEvent("have_a_new_message", function (msg)
        self:CheckChatNewMessage()
        self.new_message_tips_bg:setVisible(true)
        if self.is_bottom then
            self.new_message_tips_bg:setVisible(false)
            self.chat_list:refreshView()
            self.chat_list:scrollToBottom(0.2, false)
            self.is_bottom = true
        end
    end)

    --选择聊天服务器成功
    graphic:RegisterEvent("select_connect_success", function (msg)
        self.chat_list:removeAllItems()
        self.chat_message_number = 0
        self.is_bottom = true
        self.room_input:setText(chat_logic.connect_ip_id)
    end)

    --聊天选择服务器失败
    graphic:RegisterEvent("select_connect_failed", function (msg)
        self.room_input:setText(chat_logic.connect_ip_id)
    end)
    
end

function bbs_main_panel:Update(elapsed_time)
    if self.loading_img:isVisible() then
        self.rotation = self.rotation + elapsed_time * 180
        self.loading_img:setRotation(self.rotation)
    end
end

return bbs_main_panel
