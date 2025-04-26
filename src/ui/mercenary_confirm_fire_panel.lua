local panel_prototype = require "ui.panel"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local troop_logic = require "logic.troop"

local platform_manager = require "logic.platform_manager"

local client_constants = require "util.client_constants"
local PLIST_TYPE = ccui.TextureResType.plistType
local panel_util = require "ui.panel_util" 
local feature_config = require "logic.feature_config"
--佣兵批量解雇
local mercenary_confirm_fire_panel = panel_prototype.New(true)

function mercenary_confirm_fire_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_confirm_fire_panel.csb")

   local temp_info_node = self.root_node:getChildByName("info")
   self.soul_chip_num_text = temp_info_node:getChildByName("soul_chip")
   self.exp_text = temp_info_node:getChildByName("total_exp")
   self.tobe_fired_num_text = temp_info_node:getChildByName("choose_num")
   
   
   self.soul_chip_0 = temp_info_node:getChildByName("soul_chip_0")
   self.soul_chip_1 = temp_info_node:getChildByName("soul_chip_1")
   self.soul_chip_2 = temp_info_node:getChildByName("soul_chip_2")
   self.soul_chip_3 = temp_info_node:getChildByName("soul_chip_3")
   self.soul_chip_4 = temp_info_node:getChildByName("soul_chip_4")
   self.soul_chip_5 = temp_info_node:getChildByName("soul_chip_5")
   self.confirm_btn = self.root_node:getChildByName("confirm_btn")

   self.cancel_btn = self.root_node:getChildByName("cancel_btn")
   self.close_btn = self.root_node:getChildByName("close_btn")
   
    for i = 1 , 6 do
        temp_info_node:getChildByName("soul_bone" .. i):setVisible(feature_config:IsFeatureOpen("sign_contract"))
        temp_info_node:getChildByName("soul_bone_icon" .. i):setVisible(feature_config:IsFeatureOpen("sign_contract"))
        self["soul_chip_" .. i-1]:setVisible(feature_config:IsFeatureOpen("sign_contract"));
    end

   self:RegisterWidgetEvent()
   local titleInof=temp_info_node:getChildByName("soul_chip_title_0")

   --TW 解僱字體顯示不全 修改字體大小
   local channel = platform_manager:GetChannelInfo()
   if channel.is_open_qi2 then
   else
    local titleInof=temp_info_node:getChildByName("soul_chip_title_0")
    titleInof:setFontSize(22)
   end
    --r2位置调整
    local title_posy=platform_manager:GetChannelInfo().mercenary_confirm_fire_panel_title_pos_y
    if title_posy ~= nil then
          local titleInof=temp_info_node:getChildByName("soul_chip_title_0")
          titleInof:setPositionY(titleInof:getPositionY()+title_posy)
    end
    local algin_left=platform_manager:GetChannelInfo().mercenary_confirm_fire_panel_algin_left
    if algin_left then
        local soul_chip_title = temp_info_node:getChildByName("soul_chip_title")
        local choose_num_title = temp_info_node:getChildByName("choose_num_title")
        local total_exp_title = temp_info_node:getChildByName("total_exp_title")
        local soul_desc_1 = temp_info_node:getChildByName("soul_bone1")
        local soul_desc_2 = temp_info_node:getChildByName("soul_bone2")
        local soul_desc_3 = temp_info_node:getChildByName("soul_bone3")
        local soul_desc_4 = temp_info_node:getChildByName("soul_bone4")
        local soul_desc_5 = temp_info_node:getChildByName("soul_bone5")
        local soul_desc_6 = temp_info_node:getChildByName("soul_bone6")

        local soul_chip_icon = temp_info_node:getChildByName("soul_chip_icon")
        local ancp = cc.p(0,0.5) --要对齐的锚点
        local offsetX = soul_chip_icon:getPositionX()+soul_chip_icon:getContentSize().width/2+5 --x偏移量

        soul_desc_1:setAnchorPoint(ancp)
        soul_desc_1:setPositionX(offsetX)
        soul_desc_2:setAnchorPoint(ancp)
        soul_desc_2:setPositionX(offsetX)
        soul_desc_3:setAnchorPoint(ancp)
        soul_desc_3:setPositionX(offsetX)
        soul_desc_4:setAnchorPoint(ancp)
        soul_desc_4:setPositionX(offsetX)
        soul_desc_5:setAnchorPoint(ancp)
        soul_desc_5:setPositionX(offsetX)
        soul_desc_6:setAnchorPoint(ancp)
        soul_desc_6:setPositionX(offsetX)
        soul_chip_title:setAnchorPoint(ancp)
        soul_chip_title:setPositionX(offsetX)
        choose_num_title:setAnchorPoint(ancp)
        choose_num_title:setPositionX(offsetX)
        total_exp_title:setAnchorPoint(ancp)
        total_exp_title:setPositionX(offsetX)
    end

end


function mercenary_confirm_fire_panel:Show(fire_num, soul_chip, exp, tobe_fired_id_list,soul_bone,quality)

    self.tobe_fired_id_list = tobe_fired_id_list

    self.tobe_fired_num_text:setString(fire_num .. "/" ..constants.MAX_FIRE_NUM_ONCE)
    self.soul_chip_num_text:setString(soul_chip)
    self.exp_text:setString(exp)

    for i = 0 , 5 do
      self["soul_chip_" .. i]:setString("0")
      self["soul_chip_" .. i]:setString(soul_bone[i+1])
    end
    
    self.root_node:setVisible(true)
end

function mercenary_confirm_fire_panel:RegisterWidgetEvent()
    --确认解雇
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            troop_logic:FireMercenary(self.tobe_fired_id_list)

            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    panel_util:RegisterCloseMsgbox(self.cancel_btn, self:GetName())

    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())

end

return mercenary_confirm_fire_panel
