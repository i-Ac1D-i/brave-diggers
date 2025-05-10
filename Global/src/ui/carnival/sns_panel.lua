local carnival_logic = require "logic.carnival"
local sns_logic = require "logic.sns"

local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local platform_manager = require "logic.platform_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local json = require "util.json"

local PLIST_TYPE = ccui.TextureResType.plistType

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local reuse_scrollview = require "widget.reuse_scrollview"
local stage_panel = require "ui.carnival.stage_panel"
local user =  require("logic.user") 
local icon_template = require "ui.icon_panel"
local config_manager = require "logic.config_manager"

local SNS_EVENT_TYPE = constants.SNS_EVENT_TYPE

local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE

local SUB_PANEL_HEIGHT = 0
local MAX_SUB_PANEL_NUM = 5
local FIRST_SUB_PANEL_OFFSET = 0
local SUB_PANEL_DISABLE_COLOR = 0x7f7f7f
local SUB_PANEL_ENABLE_COLOR = 0xffffff

local audio_manager = require "util.audio_manager"

local share_sub_panel = stage_panel.New()
function share_sub_panel:Init(root_node)
    self.root_node = root_node
    self.num_text = self.root_node:getChildByName("num")

    self.get_btn = self.root_node:getChildByName("get_btn")

    self.desc_text = self.root_node:getChildByName("desc")

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    local begin_x, begin_y, interval_x = 56, 65, 80
    self.icon_sub_panels = {}
    --默认创建6个奖励
    for i = 1, 6 do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.icon_sub_panels[i] = sub_panel
    end

    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            sns_logic:TakeShareLinkReward()
        end
    end)

    self.num_text:setVisible(false)
end

function share_sub_panel:Show()
    self.reward_list = sns_logic.share_link_reward_info
    self:Load()
    self.root_node:setVisible(true)
end

function share_sub_panel:Load()
    self:ReLoadIconSubPanel(self.reward_list)
    self.desc_text:setString(lang_constants:Get("share_game_get_reward_title"))
    self.get_btn:setTitleText(lang_constants:Get("carnival_take_btn1"))
    if sns_logic:AlreadyTakeShareReward() then
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
        self.get_btn:setVisible(false)
    elseif sns_logic:CanShare(SNS_EVENT_TYPE["share_link"]) then
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
    else
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
    end
end

local bind_sub_panel = stage_panel.New()
function bind_sub_panel:Init(root_node)
    share_sub_panel.Init(self, root_node)

    self.get_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            sns_logic:TakeBindReward()
        end
    end)
end

function bind_sub_panel:Show()
    self.reward_list = sns_logic.bind_reward_info
    self:Load()
    self.root_node:setVisible(true)
end

function bind_sub_panel:Load()
    self:ReLoadIconSubPanel(self.reward_list)
    self.desc_text:setString(lang_constants:Get("bind_account_get_reward_title"))
    self.get_btn:setTitleText(lang_constants:Get("carnival_take_btn1"))
    if sns_logic:AlreadyTakeBindReward() then
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
        self.get_btn:setVisible(false)
    elseif sns_logic:CanTakeBindReward() then
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
    else
        self.root_node:setColor(panel_util:GetColor4B(SUB_PANEL_ENABLE_COLOR))
        self.get_btn:setColor(panel_util:GetColor4B(SUB_PANEL_DISABLE_COLOR))
    end
end

local invitation_sub_panel = stage_panel.New()
invitation_sub_panel.__index = invitation_sub_panel

function invitation_sub_panel.New()
    return setmetatable({}, invitation_sub_panel)
end

function invitation_sub_panel:Init(root_node, config)
    self.root_node = root_node

    self.config = config
    self.num_text = self.root_node:getChildByName("num")

    self.get_btn = self.root_node:getChildByName("get_btn")

    self.desc_text = self.root_node:getChildByName("desc")

    self.root_node:setCascadeOpacityEnabled(false)
    self.root_node:setCascadeColorEnabled(true)

    local begin_x, begin_y, interval_x = 56, 65, 80
    self.icon_sub_panels = {}
    --默认创建6个奖励
    for i = 1, 6 do
        local sub_panel = icon_template.New()
        sub_panel:Init(self.root_node)
        sub_panel.root_node:setPosition(begin_x + (i - 1) * interval_x, begin_y)
        self.icon_sub_panels[i] = sub_panel
    end
end

function invitation_sub_panel:Show(step)
    self.step_index = step or 1
    self.info = carnival_logic:GetCarnivalInfo(self.config.key)

    self:Load()

    self.root_node:setVisible(true)
end
--FYD 显示
function invitation_sub_panel:Load()
    self:ReLoadIconSubPanel(self.config.reward_list[self.step_index].reward_info)
    self:CarnivalRewardStatus()

    self.cur_value, self.reward_mark = carnival_logic:GetValueAndReward(self.config, self.step_index, self.step_index)
    self.need_value = self.config.mult_num2[self.step_index]

    local need_value = panel_util:ConvertUnit(self.need_value)

    self.num_text:setString(panel_util:ConvertUnit(self.cur_value) .. "/" .. need_value)
    self.get_btn:setTitleText(lang_constants:Get("carnival_take_btn1"))

    local str_index = #self.config.mult_str1 == 1 and 1 or self.step_index
    self.desc_text:setString(string.format(self:GetLocaleInfoString(self.config, "mult_str1", str_index), self.config.mult_num2[self.step_index] , self.config.mult_num1[self.step_index]))
end

function invitation_sub_panel:GetLocaleInfoString( cur_config, key, index )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key][index]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale][index]
    end
    return result
end

function invitation_sub_panel:TakeReward()
    carnival_logic:TakeInvitationReward(self.config, self.step_index)
end

local txwy_invite_panel = panel_prototype.New()
function txwy_invite_panel:Init(root_node)
    self.root_node = root_node

    self.copy_btn = self.root_node:getChildByName("copy_btn")
    self.invite_link_text = self.root_node:getChildByName("text")
    self.shadow_bg = self.root_node:getChildByName("txt_shadow")

    local qr_code = self.root_node:getChildByName("qr_code")
    local bg = self.root_node:getChildByName("bg")
    qr_code:setVisible(false)
    bg:setVisible(false)
    ----------UI初始化完毕-------
    --FYD 如果是txwy，那么在初始化ui之后对ui以及逻辑进行处理
    local info =  platform_manager:GetChannelInfo()
    if info.meta_channel == "txwy" then
            self.copy_btn:setPositionX(self.copy_btn:getPositionX()+200)
            self.shadow_bg:setPositionX(self.shadow_bg:getPositionX()+110)
            self.invite_link_text:setPositionX(self.invite_link_text:getPositionX()+110)
            self:GeneralInviteLinkURL(function(url)   --FYD
            self.invite_link_text:setString(url)  --显示url连接  
        end)
    

        self.copy_btn:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                --TODO
                PlatformSDK.copyStrToPasteBoard(self.invite_link_text:getString())  
                self:copy_effect()  
            end
        end)
    end 
    
end
--分享按钮点击动画
function txwy_invite_panel:copy_effect()
           local tip_text = self.invite_link_text:clone()
            tip_text:setVisible(false)
            tip_text:setLocalZOrder(999)
            tip_text:setPositionX(250)
            local str = platform_manager:GetChannelInfo().sns_copy_str
            tip_text:setString(str)     --FYD
            self.root_node:addChild(tip_text)

            local show = cc.Show:create()
            local fade = cc.FadeOut:create(1)
            local mv = cc.MoveBy:create(0,cc.p(0,-100))
            local mv_up = cc.MoveBy:create(0.8,cc.p(0,100))
            local remove = cc.CallFunc:create(function(node) 
                    local parent = node:getParent();
                    parent:removeChild(node,true)
                end)
            local seq = cc.Sequence:create(mv,show,mv_up,remove) 
            local spaw = cc.Spawn:create(fade,seq)
            tip_text:runAction(spaw)
end

--获取分享的链接
function txwy_invite_panel:GeneralInviteLinkURL(callback)
    if txwy_invite_panel.url then
       return callback(txwy_invite_panel.url)    --缓存要显示的url
    end
    local utils = require("util.utils")
    local info = platform_manager:GetChannelInfo()
    local url = info.app_pre_link_url .. info.app_link_url..user:GetUserId()
    utils:sendXMLHTTPrequrestByGet(url,function(receive) 
              
              local msg_table =  JSONManager:decodeJSON(receive)
              if msg_table["msg"] ~= "success" then
                   print("FYD------获取短链接失败");
              end
              local url = msg_table["url"]     --FYD
              callback(url) 
              txwy_invite_panel.url = url
        end)
end

function txwy_invite_panel:Show()
    self.root_node:setVisible(true)
end

local sns_panel = panel_prototype.New()
function sns_panel:Init()
--FYD8
    self.root_node = cc.CSLoader:createNode("ui/carnival_facebook_panel.csb")
    local title_bg_img = self.root_node:getChildByName("title_bg")

    self.desc_text = self.root_node:getChildByName("desc")

    self.title_text = title_bg_img:getChildByName("title")
    self.duration_text = title_bg_img:getChildByName("value")

    self.like_btn = self.root_node:getChildByName("like_btn")
    self.fb_share_btn = self.root_node:getChildByName("fb_share_btn")
    self.invite_btn = self.root_node:getChildByName("invite_btn")

    self.line_share_btn = self.root_node:getChildByName("line_share_btn")

    self.scroll_view = self.root_node:getChildByName("scroll_view")
    self.template = self.scroll_view:getChildByName("template")
    self.template:setVisible(false)

    self.invitation_sub_panels = {}
    self.sub_panel_num = 0

    SUB_PANEL_HEIGHT = self.template:getContentSize().height
    self.channel = platform_manager:GetChannelInfo()

    txwy_invite_panel:Init(self.root_node:getChildByName("invite_panel"))

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    self:CreateSubPanels()

end

function sns_panel:Show()
    if self.channel.meta_channel == "txwy" then
        self:LoadTXWY()

    elseif self.channel.meta_channel == "r2games" then
        self:LoadR2GAMES()
    end

    if self.channel.enable_sns_bind_panel then
        bind_sub_panel:Show()
    end

    if self.channel.enable_sns_share_panel then
        share_sub_panel:Show()
    end

    for i = 1, self.carnival_num do
        local sub_panel = self.invitation_sub_panels[i]
        sub_panel:Show(i)
    end

    self.duration_text:setString(self:GetLocaleInfoString(self.config, "duration"))
    self.title_text:setString(self:GetLocaleInfoString(self.config, "name"))
    self.desc_text:setString(self:GetLocaleInfoString(self.config, "desc"))

    self.root_node:setVisible(true)
end

function sns_panel:Hide()
    self.root_node:setVisible(false)
    sns_logic:RemoveFBLikeBtn() 
end

function sns_panel:CreateSubPanels()

    self.config = carnival_logic:GetSpecialCarnival(CARNIVAL_TEMPLATE_TYPE["sns_invitation"])
    self.carnival_num = #self.config.mult_num2
    self.sub_panel_num = self.carnival_num 
    if self.channel.enable_sns_share_panel then
        share_sub_panel:Init(self.template:clone())
        self.scroll_view:addChild(share_sub_panel.root_node)
        self.sub_panel_num = self.sub_panel_num + 1
    end
    if self.channel.enable_sns_bind_panel then
        bind_sub_panel:Init(self.template:clone())
        self.scroll_view:addChild(bind_sub_panel.root_node)
        self.sub_panel_num = self.sub_panel_num + 1
    end

    local size = self.scroll_view:getContentSize()
    self.sview_height = size.height
    self.sview_width = size.width
    local offset = self.sub_panel_num - self.carnival_num
    -- local height = math.max(self.sub_panel_num * SUB_PANEL_HEIGHT, self.sview_height)
    local height = self.sub_panel_num * SUB_PANEL_HEIGHT

    for i = 1, self.carnival_num do
        local sub_panel = invitation_sub_panel.New()
        sub_panel:Init(self.template:clone(), self.config)

        self.invitation_sub_panels[i] = sub_panel
        sub_panel.get_btn:setTag(i)
        sub_panel.get_btn:addTouchEventListener(self.take_invite_reward_method)

        sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - (i - 1 + offset) * SUB_PANEL_HEIGHT)
        self.scroll_view:addChild(sub_panel.root_node)
    end

    if self.channel.enable_sns_share_panel then
        share_sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET)
    end

    if self.channel.enable_sns_bind_panel then
        if self.channel.enable_sns_share_panel then
            bind_sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET - SUB_PANEL_HEIGHT)
        else
            bind_sub_panel.root_node:setPositionY(height + FIRST_SUB_PANEL_OFFSET)
        end
    end

    self.scroll_view:setInnerContainerSize(cc.size(self.sview_width, height))
    self.scroll_view:getInnerContainer():setPositionY(self.sview_height - height)
end

function sns_panel:LoadTXWY()
    self.line_share_btn:setVisible(true)
    self.like_btn:setVisible(false)
    self.desc_text:setVisible(false)
    self.invite_btn:setVisible(false)
    
    txwy_invite_panel:Show()
end

function sns_panel:LoadR2GAMES()
    self.line_share_btn:setVisible(false)
    self.desc_text:setVisible(true)
    self.invite_btn:setVisible(true)

    local params = json:encode({url = self.channel.fb_like_url, posX = 40, posY = 184, width =100, height=200})
    if not sns_logic:ShowFBLikeBtn(params) then  --FYD10
        self.like_btn:setVisible(true)
    else
        self.like_btn:setVisible(false)
    end

    txwy_invite_panel:Hide()
end
   
function sns_panel:GetLocaleInfoString( cur_config, key )
    local locale = platform_manager:GetLocale()
    local result = cur_config[key]
    if cur_config[key.."_"..locale] then
        result = cur_config[key.."_"..locale]
    end
    return result
end

function sns_panel:RegisterEvent()
    graphic:RegisterEvent("update_sns_panel", function()
        if not self.root_node:isVisible() then
            return
        end

        if self.channel.enable_sns_bind_panel then
            bind_sub_panel:Load()
        end
        if self.channel.enable_sns_share_panel then
            share_sub_panel:Load()
        end
        
        for i = 1, self.carnival_num do
            local sub_panel = self.invitation_sub_panels[i]
            sub_panel:Load()
        end
    end)

    graphic:RegisterEvent("update_share_sub_panel", function()
        if not self.root_node:isVisible() then
            return
        end
        if self.channel.enable_sns_share_panel then
            share_sub_panel:Load()
        end
    end)

    graphic:RegisterEvent("update_bind_sub_panel", function()
        if not self.root_node:isVisible() then
            return
        end

        if self.channel.enable_sns_bind_panel then
            bind_sub_panel:Load()
        end
    end)
end

function sns_panel:RegisterWidgetEvent()
    self.take_invite_reward_method = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local index = widget:getTag()
            local sub_panel = self.invitation_sub_panels[index]

            sub_panel:TakeReward() 
        end
    end

    self.line_share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local channel_info = platform_manager:GetChannelInfo()
            if channel_info.meta_channel == "txwy" then
                local message = channel_info.share_message
                txwy_invite_panel:GeneralInviteLinkURL(function(url)
                       PlatformSDK.sendMessageandAndURL(message,url,0)  
                 end)  
                
            else
                 sns_logic:ShareLink("line") 
            end
   
            
        end
    end)

    self.fb_share_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local channel_info = platform_manager:GetChannelInfo()
            if channel_info.meta_channel == "txwy" then
                local message = channel_info.share_message
                txwy_invite_panel:GeneralInviteLinkURL(function(url)
                       PlatformSDK.sendMessageandAndURL(message,url,1)  
                 end)    
            else
              sns_logic:ShareLink("facebook") 
            end
        end
    end)

    self.invite_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            sns_logic:SendGameRequest()
        end
    end)

    self.like_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            sns_logic:FBLike()
        end
    end)

end

return sns_panel
