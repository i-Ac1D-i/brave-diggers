local login_logic = require "logic.login"
local audio_manager = require "util.audio_manager"
local panel_prototype = require "ui.panel"
local configuration = require "util.configuration"
local graphic = require "logic.graphic"

local platform_manager = require "logic.platform_manager"
local configuration = require "util.configuration"

local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"

local PLIST_TYPE = ccui.TextureResType.plistType
local panel_util = require "ui.panel_util"
local reuse_scrollview = require "widget.reuse_scrollview"
local feedback_manager = require "logic.feedback_manager"

local SUB_PANEL_HEIGHT = 88
local MAX_ALL_SERVER_SUB_PANEL_NUM = 9
local MAX_SCROLL_VIEW_CONTENT_HEIGHT = 1
local WORLD_PANEL_ZORDER = 1000

--注册子面板
local register_panel = panel_prototype.New()
function register_panel:Init(root_node)
    self.root_node = root_node

    --username输入框
    self.username_bg_img = self.root_node:getChildByName("username_bg")
    self.password_bg_img =self.root_node:getChildByName("password_bg")

    self.username_textfield = self.username_bg_img:getChildByName("textfield")
    self.pwd_textfield = self.password_bg_img:getChildByName("textfield")

    local touch_size = {width = 508, height = 60}
    self.username_textfield:setTouchAreaEnabled(true)
    self.username_textfield:setTouchSize(touch_size)

    self.pwd_textfield:setTouchAreaEnabled(true)
    self.pwd_textfield:setTouchSize(touch_size)

    self.close_btn = root_node:getChildByName("close_btn")

    self.title_text = root_node:getChildByName("title"):getChildByName("name")

    self.desc_texts = {}
    for i = 1, 4 do
        self.desc_texts[i] = root_node:getChildByName("desc" .. i)
    end

    self.switch_btn = root_node:getChildByName("btn1")
    self.login_btn = root_node:getChildByName("btn2")

    self.spine_node = sp.SkeletonAnimation:create("res/spine/choose_focus.json", "res/spine/choose_focus.atlas", 1.0)
    self.root_node:addChild(self.spine_node)

    self.spine_node:setVisible(false)
    self.focus_tracker = spine_manager:CreateFocusTracker(self.spine_node, "login_input_box")

    self.init_y = self.root_node:getPositionY()

    self:RegisterWidgetEvent()
end

function register_panel:Show(is_show_register)
    if is_show_register then
        self.desc_texts[3]:setVisible(true)
        self.desc_texts[4]:setVisible(true)

        local title = lang_constants:Get("account_register_title")
        self.title_text:setString(title)
        self.login_btn:setTitleText(title)
        self.switch_btn:setTitleText(lang_constants:Get("account_switch1"))

        self.username_textfield:setString("")
        self.pwd_textfield:setString("")

    else
        local name, pwd = login_logic:GetUsernameAndPwd()
        if name then
            self.username_textfield:setString(name)
        end

        if pwd then
            self.pwd_textfield:setString(pwd)
        end

        self.desc_texts[3]:setVisible(false)
        self.desc_texts[4]:setVisible(false)

        local title = lang_constants:Get("account_login_title")
        self.title_text:setString(title)
        self.login_btn:setTitleText(title)
        self.switch_btn:setTitleText(lang_constants:Get("account_switch2"))
    end

    if self.username_textfield:getAttachWithIME() then
        self.username_textfield:setAttachWithIME(false)
    end

    if self.pwd_textfield:getAttachWithIME() then
        self.pwd_textfield:setAttachWithIME(false)
    end


    self.username_bg_img:setScale(1, 1)
    self.password_bg_img:setScale(1, 1)
    self.focus_tracker.root_node:setVisible(false)

    self.is_show_register = is_show_register

    self.root_node:setPositionY(self.init_y)
    self.root_node:setVisible(true)
end

function register_panel:Update(elapsed_time)
    if not self.root_node:isVisible() then
        return
    end

    self.focus_tracker:Update()
end

function register_panel:RegisterWidgetEvent()
    self.login_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            local name = self.username_textfield:getString()
            local pwd = self.pwd_textfield:getString()

            if self.is_show_register then
                --注册
                login_logic:SignUp(name, pwd)
            else
                --登录
                login_logic:SignIn(name, pwd)
            end
        end
    end)

    self.switch_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self:Show(not self.is_show_register)
        end
    end)

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            self:Hide()
        end
    end)

    local click_textfield_method = function(widget, event_type)
        local tag = widget:getTag()

        if event_type == ccui.TextFiledEventType.attach_with_ime then
            if self.is_show_register then
                local text = self.desc_texts[tag]
                text:setVisible(false)
            end

            local locator_img
            if tag == 3 then
                locator_img = self.username_bg_img
                self.password_bg_img:setScale(1, 1)
            else
                locator_img = self.password_bg_img
                self.username_bg_img:setScale(1, 1)
            end

            local x, y = locator_img:getPosition()
            self.focus_tracker:Bind("login_input", x, y, locator_img)

            self.root_node:setPositionY(self.init_y + 220)

        elseif event_type == ccui.TextFiledEventType.detach_with_ime then
            if (self.focus_tracker.widget and self.focus_tracker.widget:getTag() == tag) then
                self.focus_tracker:Hide()
                self.root_node:setPositionY(self.init_y)
            end
        end
    end

    self.username_textfield:addEventListener(click_textfield_method)
    self.pwd_textfield:addEventListener(click_textfield_method)

    self.username_textfield:setTag(3)
    self.pwd_textfield:setTag(4)
    self.username_bg_img:setTag(3)
    self.password_bg_img:setTag(4)
end

--服务列表子面板
local server_sub_panel = panel_prototype.New()
server_sub_panel.__index = server_sub_panel

function server_sub_panel.New()
    return setmetatable({}, server_sub_panel)
end

function server_sub_panel:Init(root_node)
    self.root_node = root_node

    self.cur_name_text = root_node:getChildByName("name")
    self.cur_icon_img = root_node:getChildByName("icon")
    self.cur_status_text = root_node:getChildByName("status")
end

function server_sub_panel:Load(server_info)
    self.root_node:setTag(server_info.id)
    local locale = platform_manager:GetLocale()
    if server_info["name_"..locale] then
        self.cur_name_text:setString(server_info["name_"..locale])
    else
        self.cur_name_text:setString(server_info.name)
    end

    if server_info.status then

        local author_text = ""
        if server_info["author_"..locale] then
            author_text = server_info["author_"..locale]
        elseif server_info.author then
            author_text = server_info.author
        end
        self.cur_status_text:setString(string.format(lang_constants:Get("server_author"), author_text))

        if server_info.status == 4 then
            self.cur_icon_img:loadTexture("login/red_soul_crystal.png", PLIST_TYPE)

        else
            self.cur_icon_img:loadTexture("login/green_soul_crystal.png", PLIST_TYPE)
        end
    end
end

--服务器列表弹窗
local server_list_panel = panel_prototype.New()

function server_list_panel:Init(root_node, box_shadow_img, server_node)
    self.root_node = root_node

    self.box_shadow_img = box_shadow_img
    self.box_shadow_img:setTouchEnabled(true)
    server_sub_panel:Init(server_node)

    self.cur_server_sub_panel = cur_server_sub_panel

    self.recommand_server_tab = self.root_node:getChildByName("tab1")
    self.recommand_server_tab:setTouchEnabled(true)

    self.all_server_tab = self.root_node:getChildByName("tab2")
    self.all_server_tab:setTouchEnabled(true)

    self.template = self.root_node:getChildByName("template")
    self.template:setVisible(false)
    self.recommand_server_node = self.root_node:getChildByName("server_node1")
    self.all_server_sview = self.root_node:getChildByName("server_sview1")

    self:RegisterWidgetEvent()

    --新服
    self.new_server_sub_panels = {}
    for i = 1, 2 do
        local sub_panel = server_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.root_node:setVisible(false)
        sub_panel.root_node:setPosition(300, 686 - (i - 1) * SUB_PANEL_HEIGHT)
        sub_panel.root_node:addTouchEventListener(self.select_method)
        self.recommand_server_node:addChild(sub_panel.root_node)
        self.new_server_sub_panels[i] = sub_panel
    end

    --登录过的服务器
    self.logined_server_sub_panels = {}
    for i = 1, 5 do
        local sub_panel = server_sub_panel.New()
        sub_panel:Init(self.template:clone())
        sub_panel.root_node:setVisible(false)
        sub_panel.root_node:addTouchEventListener(self.select_method)
        sub_panel.root_node:setPosition(300, 464 - (i - 1) * SUB_PANEL_HEIGHT)
        self.logined_server_sub_panels[i] = sub_panel
        self.recommand_server_node:addChild(sub_panel.root_node)
    end

    self.all_server_sub_panels = {}
    self.all_server_sub_panel_num = 0
    self.total_server_num = 0

    self.all_server_sview:setLocalZOrder(100)

    self.reuse_scrollview = reuse_scrollview.New(self, self.all_server_sview, self.all_server_sub_panels, SUB_PANEL_HEIGHT)

    self.reuse_scrollview:RegisterMethod(
        function(self)
            return server_list_panel.total_server_num
        end,

        function(self, sub_panel, is_up)
            local index = is_up and self.data_offset + self.sub_panel_num or self.data_offset + 1
            sub_panel:Load(self.parent_panel.server_list[index])
        end
    )

    --id 哈希表
    self.server_id_hash = {}
end

--创建子sub_panel
function server_list_panel:CreateServerSubPanel()
    local num = math.min(MAX_ALL_SERVER_SUB_PANEL_NUM, self.total_server_num)

    if self.all_server_sub_panel_num >= num then
        return
    end

    for i = self.all_server_sub_panel_num + 1, num do
        local sub_panel = server_sub_panel.New()
        sub_panel:Init(self.template:clone())

        self.all_server_sub_panels[i] = sub_panel
        self.all_server_sview:addChild(sub_panel.root_node)
        sub_panel.root_node:addTouchEventListener(self.select_method)

        sub_panel.root_node:setPositionX(260)
    end

    self.all_server_sub_panel_num = num
end

function server_list_panel:Show()
    self:ShowSubPanel(1)
    --新服
    self:NewServerList()
    --登录过的服务器
    self:LoginedServerList()
    --所有服务器
    self:AllServerList()

    self.box_shadow_img:setVisible(true)
    self.root_node:setVisible(true)
end

--初始化server_list_panel 信息
function server_list_panel:InitServerListInfo()
    local last_server_id, server_list = login_logic:GetServerList()

    for i = 1, #server_list do
        local server_info = server_list[i]
        self.server_id_hash[server_info.id] = server_info
    end

    self.last_server_id = last_server_id
    self.server_list = server_list
end

--load当前server_info
function server_list_panel:LoadCurServerInfo()
    if self.last_server_id then
        if self.server_id_hash[self.last_server_id] then
            server_sub_panel:Load(self.server_id_hash[self.last_server_id])
            self.server_id = self.last_server_id
        else
            server_sub_panel:Load(self.server_list[1])
            self.server_id = self.server_list[1].id
        end
    else
        server_sub_panel:Load(self.server_list[1])
        self.server_id = self.server_list[1].id
    end
end

function server_list_panel:AllServerList()
    self.total_server_num = #self.server_list
    local width, height = 640
    local height = math.max(self.total_server_num * SUB_PANEL_HEIGHT, self.reuse_scrollview.sview_height)

    self:CreateServerSubPanel()

    for i = 1, self.all_server_sub_panel_num do
        local sub_panel = self.all_server_sub_panels[i]
        sub_panel:Load(self.server_list[i])
        sub_panel.root_node:setPositionY(height - (i - 1) * SUB_PANEL_HEIGHT - 60)
        sub_panel.root_node:setVisible(true)
    end

    self.reuse_scrollview:Show(height, 0)

    self.server_id = self.last_server_id
end

--新服
function server_list_panel:NewServerList()
    local new_num = 0
    for i = 1, #self.server_list do
        if self.server_list[i].status == 1 then
            new_num = new_num + 1
            self.new_server_sub_panels[new_num]:Load(self.server_list[i])
            self.new_server_sub_panels[new_num].root_node:setVisible(true)
        end

        if new_num == 2 then
            break
        end
    end
end

--登录过的服务器
function server_list_panel:LoginedServerList()
    local logined_list = configuration:GetLoginedServerList()

    for i = 1, 5 do
        if i <= #logined_list then
            if self.server_id_hash[logined_list[i]] then
                self.logined_server_sub_panels[i]:Load(self.server_id_hash[logined_list[i]])
                self.logined_server_sub_panels[i].root_node:setVisible(true)
            else
                self.logined_server_sub_panels[i].root_node:setVisible(false)
            end
        else
            self.logined_server_sub_panels[i].root_node:setVisible(false)
        end
    end

end

--显示面板
function server_list_panel:ShowSubPanel(sub_panel_type)
    if sub_panel_type == 1 then
        self.recommand_server_tab:setColor(panel_util:GetColor4B("0xffffff"))
        self.all_server_tab:setColor(panel_util:GetColor4B("0x7f7f7f"))

        self.recommand_server_node:setVisible(true)
        self.all_server_sview:setVisible(false)

        self.recommand_server_tab:setLocalZOrder(101)
        self.all_server_tab:setLocalZOrder(100)

    else
        self.recommand_server_tab:setColor(panel_util:GetColor4B("0x7f7f7f"))
        self.all_server_tab:setColor(panel_util:GetColor4B("0xffffff"))

        self.recommand_server_node:setVisible(false)
        self.all_server_sview:setVisible(true)

        self.recommand_server_tab:setLocalZOrder(100)
        self.all_server_tab:setLocalZOrder(101)

    end
end

function server_list_panel:RegisterWidgetEvent()
    self.select_method = function(widget, event_type)
       if event_type == ccui.TouchEventType.ended then
           audio_manager:PlayEffect("click")

            local server_id = widget:getTag()
            self.server_id = server_id
            self.box_shadow_img:setVisible(false)

            self:Hide()
            for i = 1, self.total_server_num do
                local server_info = self.server_list[i]
                if server_info.id == server_id then
                    server_sub_panel:Load(server_info)
                    break
                end
            end
       end
   end

   self.root_node:getChildByName("close_btn"):addTouchEventListener(function(widget, event_type)
       if event_type == ccui.TouchEventType.ended then
           audio_manager:PlayEffect("click")
           self.box_shadow_img:setVisible(false)
           server_list_panel:Hide()
       end
   end)

    self.recommand_server_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ShowSubPanel(1)
        end
    end)

    self.all_server_tab:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ShowSubPanel(2)
        end
    end)
end

local login_panel = panel_prototype.New()
function login_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/login_panel.csb")

    self.cur_version_text = self.root_node:getChildByName("version")

    --登录按钮
    self.bottom_node = self.root_node:getChildByName("bottom")
    self.wechat_btn = self.bottom_node:getChildByName("wechat_btn")
    self.guest_btn = self.bottom_node:getChildByName("guest_btn")

    self.login_btn = self.bottom_node:getChildByName("login_btn")

    local channel_info = platform_manager:GetChannelInfo()
    self.guest_btn:setVisible(channel_info.has_guest and platform_manager:HasAccountPlatform("guest"))
    self.wechat_btn:setVisible(false)

     
    register_panel:Init(self.root_node:getChildByName("register_node"))

    local server_node = self.root_node:getChildByName("server_node")

    self.back_btn = server_node:getChildByName("back_btn")
    self.enter_btn = server_node:getChildByName("enter_btn")
    self.view_list_img = server_node:getChildByName("current_server_bg")

    local news_bg_img = server_node:getChildByName("news_bg")
    self.notice_sview = news_bg_img:getChildByName("scrollview")
    self.notice_text = self.notice_sview:getChildByName("desc")

    self.notice_sview:setInnerContainerSize(cc.size(560, 200))

    -- 拥有切换账户和用户中心按钮的渠道需要使用
    self.change_user_btn = server_node:getChildByName("account_btn")
    if self.change_user_btn then
        self.change_user_btn:setVisible(false)
    end
    self.user_center_btn = server_node:getChildByName("usercenter_btn")
    if self.user_center_btn then
        self.user_center_btn:setVisible(false)
    end

    server_node:setVisible(false)
    self.server_node = server_node

    local box_shadow_img = self.root_node:getChildByName("box_shadow")

    server_list_panel:Init(self.root_node:getChildByName("server_msgbox"), box_shadow_img, server_node)
    server_list_panel:Hide()

    self.loading_node = self.root_node:getChildByName("loading")
    self.loading_node:setVisible(false)

    self.rotation = 0
    self.percent_img = self.loading_node:getChildByName("percent_icon")

    local channel_info = platform_manager:GetChannelInfo()
    local copyright2 = self.root_node:getChildByName("copyright2")
    if copyright2 then
        if channel_info.show_copyright then
            copyright2:setVisible(true)
        else
            copyright2:setVisible(false)
        end
    end

    if channel_info.center_login_btn then
        self.login_btn:setPositionX(320)
    end

    if channel_info.disable_signin_btn then
        self.login_btn:setVisible(false)
    end

    if channel_info.login_has_user_center_ex and self.user_center_btn then
        self.user_center_btn:setVisible(true)
        self.user_center_btn:setTitleText(lang_constants:Get("account_bind_btn2"))
    end

    if channel_info.login_has_change_user and self.change_user_btn then
        self.change_user_btn:setVisible(true)
        self.change_user_btn:setTitleText(lang_constants:Get("switch_account_btn_name"))
    end

    self.language_btn = self.root_node:getChildByName("language_btn")
    if self.language_btn then
        self.language_btn:setVisible(false)
    end

    self.customer_btn = self.root_node:getChildByName("customer_btn")
    if self.customer_btn then
        self.customer_btn:setVisible(false)
    end

    self.locale_panel = nil

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function login_panel:ShowBottom()
    self.root_node:setVisible(true)
    self.bottom_node:setVisible(true)
    self.loading_node:setVisible(false)
    self.server_node:setVisible(false)

    self.cur_version_text:setString("Version " .. configuration:GetVersion())

    local channel_info = platform_manager:GetChannelInfo()
    local account_type = channel_info.signin[2]

    if (channel_info.name == "appstore" or channel_info.name == "mu77_appstore") and not _G["AUTH_MODE"] then
        self.wechat_btn:setVisible(account_type == "wechat")
    else
        self.wechat_btn:setVisible(account_type and platform_manager:HasAccountPlatform(account_type))
    end

    if account_type then
        self.wechat_btn:setVisible(true)
        local login_desc2 = lang_constants:Get(account_type .. "_login_desc")
        if login_desc2 ~= "" then
            self.wechat_btn:setTitleText(login_desc2)
        end

        local wechat_icon = self.wechat_btn:getChildByName("Image_1")
        wechat_icon:setVisible(account_type == "wechat")

    else
        self.wechat_btn:setVisible(false)
    end

    if channel_info.signin[3] then
        self.guest_btn:setVisible(true)
        local login_desc3 = lang_constants:Get(channel_info.signin[3] .. "_login_desc")
        if login_desc3 ~= "" then
            self.guest_btn:setTitleText(login_desc3)
        end

    else
        self.guest_btn:setVisible(false)
    end
    
    if self.language_btn and type(channel_info.locale) == "table" and #channel_info.locale > 1 and channel_info.login_has_change_loacle then
        self.language_btn:setVisible(true)
    end

    if self.customer_btn and channel_info.login_has_feedback then
        self.customer_btn:setVisible(true)
    end
    
    --FYD 如果signin 字符段存在gamecenter  则设置weichat 按钮为GameCenter
     -- for k,v in ipairs(platform_manager:GetChannelInfo().signin) do
     --     if v == "gamecenter" then
     --        self.wechat_btn:setTitleText("GAMECENTER");
     --        self.wechat_btn:setVisible(true)
            
     --        break; 
     --     end
     -- end

    register_panel:Hide()
    server_list_panel:Hide()
    self:AutoSignin()
end

function login_panel:AutoSignin()
    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.auto_signin then
        local signin_type = channel_info.signin[1]

        PlatformSDK.showSignIn(platform_manager:GetAccountPlatformType(signin_type))
    end
end

function login_panel:HideAllSubPanel()
    self.root_node:setVisible(true)
    self.bottom_node:setVisible(false)
    self.loading_node:setVisible(false)
    self.server_node:setVisible(false)

    self.cur_version_text:setString("Version" .. configuration:GetVersion())

    register_panel:Hide()
    server_list_panel:Hide()
end

function login_panel:SetLoadingTime(time)
    self.loading_time = time
    self.loading_node:setVisible(true)
end

function login_panel:Update(elapsed_time)
    if self.loading_node:isVisible() then
        self.rotation = self.rotation + elapsed_time * 180
        self.loading_time = self.loading_time - elapsed_time

        self.percent_img:setRotation(self.rotation)

        if self.loading_time <= 0 then
            self.loading_node:setVisible(false)
        end
    end

    register_panel:Update(elapsed_time)
end

function login_panel:AuthSuccess()
    register_panel:Hide()

    server_list_panel:InitServerListInfo()
    server_list_panel:LoadCurServerInfo()

    self.server_node:setVisible(true)
    self.notice_text:setString(login_logic:GetGlobalNotice())

    self.bottom_node:setVisible(false)
end

function login_panel:ShowLogin()
    local channel_info = platform_manager:GetChannelInfo()
    if channel_info.account_type then
        --木七七
        register_panel:Show(false)
    else
        --其他平台登录
        local account_type = channel_info.signin[1]
        if account_type and platform_manager:HasAccountPlatform(account_type) then
            PlatformSDK.showSignIn(platform_manager:GetAccountPlatformType(account_type))
        end
    end
end

function login_panel:ShowLocalePanel()

    local sub_panel = self.locale_panel

    if not sub_panel then
        sub_panel = require("ui.locale_panel")
        sub_panel.__name = name

        sub_panel:Init(true)
        self.root_node:addChild(sub_panel:GetRootNode(), WORLD_PANEL_ZORDER)

        sub_panel:GetRootNode():setVisible(false)
        self.locale_panel = sub_panel
    end

    sub_panel:Show()
end

function login_panel:RegisterEvent()
    graphic:RegisterEvent("show_auth_result", function(result)
        local scene = cc.Director:getInstance():getRunningScene()
        if scene and scene.__name == "login" and result == "platform_auth_success" then
            self:AuthSuccess()
        end

        self.loading_node:setVisible(false)
        graphic:DispatchEvent("show_prompt_panel", result)
    end)

    graphic:RegisterEvent("show_login_result", function(result)
        if result == "invalid_pwd" then
            graphic:DispatchEvent("show_prompt_panel", "account_not_exist")

        elseif result == "register_first" then
            graphic:DispatchEvent("show_prompt_panel", "account_not_exist")

        elseif result == "invalid_char" then
            graphic:DispatchEvent("show_prompt_panel", "account_register_invalid_char")

        elseif result == "auth_failure" then
            graphic:DispatchEvent("show_prompt_panel", "platform_auth_failed")

        elseif result == "server_is_busy" then
            graphic:DispatchEvent("show_prompt_panel", "account_server_is_busy")

        elseif result == "forbidden_create" then
            graphic:DispatchEvent("show_prompt_panel", "account_forbid_create")
        end

        self.loading_node:setVisible(false)
    end)
end

--注册控件相关事件
function login_panel:RegisterWidgetEvent()

    local channel_info = platform_manager:GetChannelInfo()
    self.login_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            self:ShowLogin()
        end
    end)

    --微信登录
    self.wechat_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            register_panel:Hide()

            self:SetLoadingTime(5)

            local account_type = channel_info.signin[2]
            if account_type then
                PlatformSDK.showSignIn(platform_manager:GetAccountPlatformType(account_type))
            end
        end
    end)

    --游客登录
    self.guest_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            register_panel:Hide()

            local account_type = channel_info.signin[3]
            if account_type then
                PlatformSDK.showSignIn(platform_manager:GetAccountPlatformType(account_type))
            else
                if platform_manager:HasAccountPlatform("guest") then
                    login_logic:SignInAsGuest()
                end
            end
        end
    end)

    --返回账号登录
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if channel_info.has_signout then
                PlatformSDK.signOut()

            else
                server_list_panel:Hide()
                self.server_node:setVisible(false)
                self.bottom_node:setVisible(true)
                self:ShowLogin()
            end
        end
    end)

    self.back_btn:setVisible(channel_info.switch_account and not _G["AUTH_MODE"])

    --进入游戏
    self.enter_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if login_logic:UserLogin(server_list_panel.server_id) then
                self:SetLoadingTime(5)
            end
        end
    end)

    --显示服务器列表
    self.view_list_img:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            server_list_panel:Show()
        end
    end)

    if self.change_user_btn then
        self.change_user_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")

                local channel_info = platform_manager:GetChannelInfo()
                if channel_info.login_has_change_user then
                    if channel_info.meta_channel == "txwy" then
                        PlatformSDK.signOut()
                    end
                end
            end
        end)
    end

    if self.user_center_btn then
        self.user_center_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                local channel_info = platform_manager:GetChannelInfo()
                if channel_info.login_has_user_center_ex then
                    platform_manager:ShowUserCenterEx()
                end
            end
        end)
    end

    --切换语言按钮
    if self.language_btn then
        self.language_btn:addTouchEventListener(function(widget, event_type)

            if event_type ~= ccui.TouchEventType.ended then
                return
            end

            audio_manager:PlayEffect("click")
            self:ShowLocalePanel()
        end)
    end

    if self.customer_btn then
        self.customer_btn:addTouchEventListener(function(widget, event_type)

            if event_type ~= ccui.TouchEventType.ended then
                return
            end

            audio_manager:PlayEffect("click")
            feedback_manager:ShowFeedback(true)
        end)
    end
end

return login_panel
