local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local reuse_scrollview = require "widget.reuse_scrollview"
local platform_manager = require "logic.platform_manager"
local channel_info = platform_manager:GetChannelInfo()

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local rune_logic = require "logic.rune"


local rune_rule_panel = panel_prototype.New(true)
function rune_rule_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/rune_rule_msgbox.csb")

    --是否需要重新排版
    local need_make_up = channel_info.rule_panel_rest_view
    if need_make_up then
        self:makeUpView()
    end

    self:RegisterWidgetEvent()
end

function rune_rule_panel:makeUpView()
    local offsetY = 25;
    local now_y = 0
    local scrollview = self.root_node:getChildByName("scrol_view")

    local text_5 = scrollview:getChildByName("Text_82_0_0_0_0")
    local text_5_height = self:getLines(text_5:getString(),18*3) * text_5:getVirtualRendererSize().height
    text_5:setContentSize({width = 436, height = text_5_height })
    now_y = now_y + text_5_height+offsetY-10
    text_5:setPositionY(now_y)

    local text_4 = scrollview:getChildByName("Text_82_0_0_0")
    local text_4_height = self:getLines(text_4:getString(),18*3) * text_4:getVirtualRendererSize().height
    text_4:setContentSize({width = 436, height = text_4_height })
    now_y = now_y + text_4_height+offsetY-10
    text_4:setPositionY(now_y)

    local text_3 = scrollview:getChildByName("Text_82_0_0")
    local text_3_height = self:getLines(text_3:getString(),18*3) * text_3:getVirtualRendererSize().height
    text_3:setContentSize({width = 436, height = text_3_height })
    now_y = now_y + text_3_height+offsetY-10
    text_3:setPositionY(now_y)

    local text_2 = scrollview:getChildByName("Text_82_0")
    local text_2_height = self:getLines(text_2:getString(),18*3) * text_2:getVirtualRendererSize().height
    text_2:setContentSize({width = 436, height = text_2_height })
    now_y = now_y + text_2_height+offsetY-10
    text_2:setPositionY(now_y)

    local text_1 = scrollview:getChildByName("Text_82")
    local text_1_height = self:getLines(text_1:getString(),18*3) * text_1:getVirtualRendererSize().height
    text_1:setContentSize({width = 436, height = text_1_height })
    now_y = now_y + text_1_height+offsetY-10
    text_1:setPositionY(now_y)
        
    local inner = scrollview:getInnerContainer()
    inner:setContentSize({width = scrollview:getContentSize().width, height = now_y + 60})
    scrollview:jumpToTop()
end

function rune_rule_panel:getLines(str,size)
   return math.ceil(string.len(str)/size) 
end

function rune_rule_panel:Show()
    self.root_node:setVisible(true)
end

function rune_rule_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.root_node:getChildByName("close_btn"), self:GetName())
end

return rune_rule_panel

