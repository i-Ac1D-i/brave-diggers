local panel_prototype = require "ui.panel"

local panel_util = require "ui.panel_util"
local lang_constants = require "util.language_constants"
local platform_manager = require "logic.platform_manager"
local mercenary_lineup_details_panel = panel_prototype.New(true)

function mercenary_lineup_details_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/mercenary_lineup_details_panel.csb")
    self.scroll_view = self.root_node:getChildByName("scrollview")

    local crit_progress_node = self.scroll_view:getChildByName("crit_progress_bar")
    self.crit_percent_text = crit_progress_node:getChildByName("percent_value")
    self.crit_percent_progress = crit_progress_node:getChildByName("percent_bar")
    self.crit_desc_text = crit_progress_node:getChildByName("property_desc_b")

    local pure_progress_node = self.scroll_view:getChildByName("pure_progress_bar")
    self.pure_percent_text = pure_progress_node:getChildByName("percent_value")
    self.pure_percent_progress = pure_progress_node:getChildByName("percent_bar")

    local recovery_progress_node = self.scroll_view:getChildByName("recovery_progress_bar")
    self.recovery_percent_text = recovery_progress_node:getChildByName("percent_value")
    self.recovery_percent_progress = recovery_progress_node:getChildByName("percent_bar")
    self.recovery_desc_text = recovery_progress_node:getChildByName("property_desc_b")

    local stateless_progress_node = self.scroll_view:getChildByName("stateless_progress_bar")
    self.stateless_percent_text = stateless_progress_node:getChildByName("percent_value")
    self.stateless_percent_progress = stateless_progress_node:getChildByName("percent_bar")

    self.skill_percent_progress = self.scroll_view:getChildByName("percent_bar_skill")
    self.skill_percent_text = self.scroll_view:getChildByName("percent_value_skill")

    self.close_btn = self.root_node:getChildByName("close_btn")
    self.scroll_view = self.root_node:getChildByName("scrollview")
    self.scroll_view:setClippingEnabled(true)

    if platform_manager:GetChannelInfo().mercenary_lineup_detail_panel_height then
        self.authority_node = self.scroll_view:getChildByName("authority")
        self.authority_desc_text = self.authority_node:getChildByName("desc")
        local panel_height = platform_manager:GetChannelInfo().mercenary_lineup_detail_panel_height
        local width = self.authority_desc_text:getContentSize().width
        self.authority_desc_text:setContentSize(width, panel_height)
    end

    --r2
    if platform_manager:GetChannelInfo().mercenary_lineup_details_panel_hide_icon then
        local icon=pure_progress_node:getChildByName("icon")
        icon:setVisible(false)
        local icon2=pure_progress_node:getChildByName("icon2")
        icon2:setVisible(false)
    end

    self:RegisterWidgetEvent()
end

function mercenary_lineup_details_panel:UpdateProgress(datas)
    local function _GetProgressColor(percent) 
        local progress_bg_color 
        if percent >= 80 then 
           progress_bg_color = panel_util:GetColor4B(0xC1FA1A)
        elseif percent >= 40 and percent < 80 then
            progress_bg_color = panel_util:GetColor4B(0xF5D31F)
        else
            progress_bg_color = panel_util:GetColor4B(0xEB4D19)
        end 

        return progress_bg_color
    end

    self.skill_percent_progress:setColor(_GetProgressColor(datas.skill_percent))
    -- self.crit_percent_progress:setColor(_GetProgressColor(datas.critical_percent))
    -- self.pure_percent_progress:setColor(_GetProgressColor(datas.true_percent))
    -- self.recovery_percent_progress:setColor(_GetProgressColor(datas.increase_percent))
    -- self.stateless_percent_progress:setColor(_GetProgressColor(datas.other_percent))

    self.skill_percent_progress:setPercent(datas.skill_percent)
    self.crit_percent_progress:setPercent(datas.critical_percent)
    self.pure_percent_progress:setPercent(datas.true_percent)
    self.recovery_percent_progress:setPercent(datas.increase_percent)
    self.stateless_percent_progress:setPercent(datas.other_percent)

  
    self.skill_percent_text:setString(string.format(lang_constants:Get("skill_percent"),datas.skill_percent))
    self.crit_percent_text:setString(string.format(lang_constants:Get("skill_percent"),datas.critical_percent))
    self.pure_percent_text:setString(string.format(lang_constants:Get("skill_percent"),datas.true_percent))
    self.recovery_percent_text:setString(string.format(lang_constants:Get("skill_percent"),datas.increase_percent))
    self.stateless_percent_text:setString(string.format(lang_constants:Get("skill_percent"),datas.other_percent))

    self.crit_desc_text:setString(string.format(lang_constants:Get("mercenary_recommend_critcal_text"), datas.critical_effect))
    self.recovery_desc_text:setString(string.format(lang_constants:Get("mercenary_recommend_recovery_text"), datas.increase_effect))
end

function mercenary_lineup_details_panel:Show(datas)
    self:UpdateProgress(datas)
    self.root_node:setVisible(true)
end

function mercenary_lineup_details_panel:RegisterWidgetEvent()
    panel_util:RegisterCloseMsgbox(self.close_btn, self:GetName())
end

return mercenary_lineup_details_panel
