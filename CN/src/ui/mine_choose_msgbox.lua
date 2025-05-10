local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local panel_util = require "ui.panel_util"
local icon_panel = require "ui.icon_panel"

local lang_constants = require "util.language_constants"
local mine_logic = require "logic.mine"

local MSGBOX_MODE = client_constants["QUICK_STORE_MSGBOX_TYPE"]
local RESOURCE_TYPE_NAME = constants["RESOURCE_TYPE_NAME"]

local PLIST_TYPE = ccui.TextureResType.plistType
local TEMPLENT_HEIGHT = 135
local TEMPLENT_FRIST_POS_Y = 690
local CHOOSE_BG_HEIGHT_MIN = 300

local mine_choose_sub_panel = panel_prototype.New()
mine_choose_sub_panel.__index = mine_choose_sub_panel

function mine_choose_sub_panel.New()
    return setmetatable({}, mine_choose_sub_panel)
end

function mine_choose_sub_panel:Init(root_node)
    self.root_node = root_node

    self.mine_level_img = self.root_node:getChildByName("Image_44") 
    self.name = self.root_node:getChildByName("name")
    self.battle_point_text = self.root_node:getChildByName("bp_value")
    
    self.revenge = self.root_node:getChildByName("challenge_btn")
    self.revenge:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.info_conf and self.info_conf.user_id and self.report_id then
                mine_logic:MineRobTarget(client_constants.ROB_TYPE.revenge, self.info_conf.user_id, self.info_conf.mine_index, self.report_id)
                graphic:DispatchEvent("hide_world_sub_panel", "mine_choose_msgbox")
            end
        end
    end)
end

function mine_choose_sub_panel:Show(index, info_conf, report_id)
    self.root_node:setVisible(true)
    self.root_node:setPositionY(TEMPLENT_FRIST_POS_Y - (index - 1) * TEMPLENT_HEIGHT)
    self.report_id = report_id
    self.info_conf = info_conf
    if info_conf then
        self.name:setString(info_conf.leader_name)

        self.battle_point_text:setString(info_conf.battle_point)

        self.mine_level_img:loadTexture(client_constants["MINE_TYPE_IMG_PATH"][info_conf.mine_level], PLIST_TYPE)

    end

end


local mine_choose_msgbox = panel_prototype.New(true)
function mine_choose_msgbox:Init()

    self.root_node = cc.CSLoader:createNode("ui/mine_choose_msgbox.csb")
    --关闭按钮
    self.close_btn = self.root_node:getChildByName("close_btn")

    self.bg_img =  self.root_node:getChildByName("bg")

    self.templent = self.root_node:getChildByName("template")

    self.templent:setVisible(false)

    self.mine_choose_sub_panels = {}

    self:RegisterWidgetEvent()
end

function mine_choose_msgbox:Show(choose_list, report_id) 
    self.root_node:setVisible(true)
    for i=1,#choose_list do
        local sub_panel = self.mine_choose_sub_panels[i]
        if sub_panel == nil then
            sub_panel = mine_choose_sub_panel.New()
            local temp = self.templent:clone()
            self.root_node:addChild(temp)
            sub_panel:Init(temp)
            self.mine_choose_sub_panels[i] = sub_panel
        end
        sub_panel:Show(i, choose_list[i], report_id)
    end

    self.bg_img:setContentSize(cc.size(self.bg_img:getContentSize().width, CHOOSE_BG_HEIGHT_MIN + (#choose_list-1) * TEMPLENT_HEIGHT))

    for i=#choose_list+1, #self.mine_choose_sub_panels do
        self.mine_choose_sub_panels[i]:Hide()
    end
end

function mine_choose_msgbox:Update(elapsed_time)

end

function mine_choose_msgbox:RegisterWidgetEvent()

    self.close_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)


end

return mine_choose_msgbox
