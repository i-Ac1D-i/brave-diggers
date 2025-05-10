local client_constants = require "util.client_constants"

local text_sub_panel = require "ui.carnival.text_panel"
local discount_sub_panel = require "ui.carnival.discount_panel"
local rank_sub_panel = require "ui.carnival.rank_panel"
local stage_sub_panel = require "ui.carnival.stage_panel"
local display_sub_panel = require "ui.carnival.display_panel"
local multi_token_sub_panel = require "ui.carnival.multi_token_panel"
local evolution_sub_panel = require "ui.carnival.evolution_panel"
local fund_sub_panel = require "ui.carnival.fund_panel"
local mercenary_exchange_sub_panel = require "ui.carnival.mercenary_exchange_panel"
local intro_sub_panel = require "ui.carnival.intro_panel"

--活动模版数量
local CARNIVAL_TEMPLATE_NUM = 9

local CARNIVAL_TEMPLATE_TYPE = client_constants.CARNIVAL_TEMPLATE_TYPE

local template_manager = {}

function template_manager:Init()
    self.root_node = cc.CSLoader:createNode("ui/carnival_template.csb")

    --活动模版, 存放template
    self.widget_list = {} 

    self.meta_sub_panels = {}

    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["rank"]] = rank_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["stage"]] = stage_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["display"]] = display_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["text"]] = text_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["discount"]] = discount_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["multi_token"]] = multi_token_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["evolution"]] = evolution_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["fund"]] = fund_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["mercenary_exchange"]] = mercenary_exchange_sub_panel
    self.meta_sub_panels[CARNIVAL_TEMPLATE_TYPE["scroll_intro"]] = intro_sub_panel

    for i = 1, CARNIVAL_TEMPLATE_NUM do
        self.meta_sub_panels[i].InitMeta(self.root_node:getChildByName("template" .. i))
    end

    self.root_node:retain()
end

function template_manager:Clear()
    self.root_node:release()
end

function template_manager:GetMetaPanel(template_type)
    return self.meta_sub_panels[template_type]
end

return template_manager
