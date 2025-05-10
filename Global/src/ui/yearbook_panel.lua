local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local icon_template = require "ui.icon_panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"

local PLIST_TYPE = ccui.TextureResType.plistType
local ARIL_ROLE_IMG_ID = "17000009"
local MONKEY_ROLE_IMG_ID = "18000041"
local ALAN_ROLE_IMG_ID = "18000039"
local TONITONI_ROLE_IMG_ID = "19000091"
local ZHANGFEI_ROLE_IMG_ID = "19000026"
local PIZZA_ROLE_IMG_ID = "19000033"
local ZHAOZILONG_ROLE_IMG_ID = "18000010"
local CHACHA_ROLE_IMG_ID = "17000031"
local ROLE_CONFIG = {
            [1] = {ROLE_ID = ARIL_ROLE_IMG_ID, UI_NAME = "part2_2"},
            [2] = {ROLE_ID = MONKEY_ROLE_IMG_ID, UI_NAME = "part3_2"},
            [3] = {ROLE_ID = ALAN_ROLE_IMG_ID, UI_NAME = "part4_2"},
            [4] = {ROLE_ID = TONITONI_ROLE_IMG_ID, UI_NAME = "part6_role"},
            [5] = {ROLE_ID = ZHANGFEI_ROLE_IMG_ID, UI_NAME = "part5_role1"},
            [6] = {ROLE_ID = PIZZA_ROLE_IMG_ID, UI_NAME = "part5_role2"},
            [7] = {ROLE_ID = ZHAOZILONG_ROLE_IMG_ID, UI_NAME = "part5_role3"},
            [8] = {ROLE_ID = CHACHA_ROLE_IMG_ID, UI_NAME = "part5_role4"},
}

local yearbook_panel = panel_prototype.New(true)
function yearbook_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/carnival_newyearbook_panel.csb")
    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.scroll_view:setClippingEnabled(true)
    self.scroll_view:setTouchEnabled(true)
    
    for k, v in pairs(ROLE_CONFIG) do
        local temp_img = self.scroll_view:getChildByName(v.UI_NAME)
        temp_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. v.ROLE_ID .. ".png", PLIST_TYPE)
    end

    self.back_btn = self.root_node:getChildByName("back_btn")

    self:RegisterWidgetEvent()
end

function yearbook_panel:RegisterWidgetEvent()
     panel_util:RegisterCloseMsgbox(self.back_btn, self:GetName())
end

return yearbook_panel

