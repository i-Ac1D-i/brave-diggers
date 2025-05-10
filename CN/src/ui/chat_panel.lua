local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local graphic = require "logic.graphic"
local time_logic = require "logic.time"
local user_logic = require "logic.user"
local icon_panel = require "ui.icon_panel"

local client_constants = require "util.client_constants"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local panel_util = require "ui.panel_util"
local rech_text = require "ui.RichLableText"
local input_widget = require "ui.InputWidget"


local PLIST_TYPE = ccui.TextureResType.plistType
local look_img = client_constants["CHAT_IMG_PATH"]


local chat_panel = panel_prototype.New(true)
function chat_panel:Init()
    --加载csb
    self.root_node = cc.CSLoader:createNode("ui/chat_panel.csb")
    self.close_btn = self.root_node:getChildByName("back_btn")

    self.send_btn = self.root_node:getChildByName("send_btn")
    self.scorllview = self.root_node:getChildByName("ScrollView_1")
    self.scorllview_node = cc.Node:create()
    self.scorllview_node:setPosition(cc.p(0,0))
    self.scorllview:addChild(self.scorllview_node)
    self.templeat = self.scorllview:getChildByName("telmp")
    self.templeat:setVisible(false)
    cc.SpriteFrameCache:getInstance():addSpriteFrames("login.plist")

    --表情面板
    self.emoj_panel = self.root_node:getChildByName("ScrollView_2")
    self.emoj_img = self.emoj_panel:getChildByName("Image_61")
    self.emoj_img:setVisible(false)

    local text_field_parent = self.root_node:getChildByName("Image_126")
    self.text_field = text_field_parent:getChildByName("TextField_1")
    self.input_text = input_widget.New()
    self.input_text:Init(self.text_field,text_field_parent)

    self.data = {}
    self.height = 0

    self:InitEmojPanel()

    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

function chat_panel:Show(index)
    self.root_node:setVisible(true)
end

--添加表情面板
function chat_panel:InitEmojPanel()
    for k,v in pairs(look_img) do
        local emoj_clone = self.emoj_img:clone()
        emoj_clone:setVisible(true)
        emoj_clone:setTag(k)
        emoj_clone:loadTexture(v, PLIST_TYPE)
        emoj_clone:setPosition(cc.p((k%9 + 1) * emoj_clone:getContentSize().width, math.ceil(k/9)*(emoj_clone:getContentSize().height+10)))
        self.emoj_panel:addChild(emoj_clone)
        emoj_clone:addTouchEventListener(function(widget, event_type)
            if event_type == ccui.TouchEventType.ended then
                audio_manager:PlayEffect("click")
                self.input_text:InsertImage(v)
            end
        end)
    end
end

function chat_panel:addContent(str)
    local cccc =  rech_text.new("",567)
    cccc:setString(str)
    
    local templeat = self.templeat:clone()
    templeat:setVisible(true)
    local bg = templeat:getChildByName("shadow")
    bg:addChild(cccc)
    cccc:setPosition(cc.p(10,cccc.height + 10))
    bg:setContentSize(cc.size(bg:getContentSize().width,cccc.height + 20))
    templeat:setContentSize(cc.size(bg:getContentSize().height + 60,templeat:getContentSize().height))
    self.scorllview_node:addChild(templeat)
    self.height = self.height + templeat:getContentSize().width
    templeat:setPositionY(self.height)
    if (self.height + 60) > self.scorllview:getInnerContainerSize().height then
        self.scorllview:setInnerContainerSize(cc.size(self.scorllview:getContentSize().width, self.height + 60))
    else
        self.scorllview:setInnerContainerSize(self.scorllview:getContentSize())
    end
end

function chat_panel:Update(elapsed_time)

end

function chat_panel:RegisterEvent()
    -- graphic:RegisterEvent("buy_limite_success", function()
    --     self.jumpToTop = true
    --     --购买成功后
    --     self:UpdateScrollView() --刷新视图
    --     --关闭掉自己 触发机制用的
    --     graphic:DispatchEvent("hide_world_sub_panel", "time_limit_reward_msgbox_panel")
    -- end)
    -- graphic:RegisterEvent("update_limite_state", function()
    --     self.jumpToTop = true
    --     self:UpdateScrollView()
    -- end)
end

function chat_panel:RegisterWidgetEvent()

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.send_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local str = self.input_text:getString()
            if str == "" or str == nil then
                return
            end
            self.input_text:setString("")
            self:addContent(str)
        end
    end)
end

return chat_panel
