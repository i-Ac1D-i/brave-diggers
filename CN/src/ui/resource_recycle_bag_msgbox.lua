local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"
local animation_manager = require "util.animation_manager"
local icon_panel = require "ui.icon_panel"
local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local time_logic = require "logic.time"
local spine_manager = require "util.spine_manager"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local user_logic = require "logic.user"

local RESOURCE_TYPE_NAME = constants['RESOURCE_TYPE']

local resource_config = config_manager.resource_config
local PLIST_TYPE = ccui.TextureResType.plistType
local OFFSET_X = 25

local detail_info_sub_panel = panel_prototype.New()

function detail_info_sub_panel:Init(root_node)
    self.root_node = root_node

    self.have_item_node = root_node:getChildByName("have_item_node")
    self.no_item_desc_text = root_node:getChildByName("no_item_desc")

    self.bg_img = self.have_item_node:getChildByName("item_bg")
    self.icon_img = self.have_item_node:getChildByName("item_icon")
    self.name_text = self.have_item_node:getChildByName("item_name")
    self.icon_img:ignoreContentAdaptWithSize(true)

    self.desc_scroll_view = self.have_item_node:getChildByName("desc_list")
    self.desc_text = self.desc_scroll_view:getChildByName("desc")

    self.root_node:setVisible(true)
end

function detail_info_sub_panel:Show(resource_name)
    if not resource_name or resource_name == "" then
        self.have_item_node:setVisible(false)
        self.no_item_desc_text:setVisible(true)
        return
    end

    self.have_item_node:setVisible(true)
    self.no_item_desc_text:setVisible(false)

    self:ShowResource(resource_name)
end

--显示资源
function detail_info_sub_panel:ShowResource(resource_name)
    if resource_name then
        local template_id = constants['RESOURCE_TYPE'][resource_name]
        local resource_template = resource_config[template_id]
        self.icon_img:loadTexture(resource_template.icon, PLIST_TYPE)
        self.item_id = template_id
        self.name_text:setString(resource_template.name .. "x" .. resource_logic:GetResourcenNumByName(resource_name))
        self.desc_text:setString(resource_template.desc)

        local quality = resource_template["quality"]
        self.bg_img:loadTexture(client_constants.MERCENARY_BG_SPRITE[quality], PLIST_TYPE)
        if quality == client_constants["DEFAULT_QUALITY"] then
            self.bg_img:setOpacity(255 * 0.6)
        else
            self.bg_img:setOpacity(255)
        end

    end
end

local template_node_panel = panel_prototype.New()
template_node_panel.__index = template_node_panel

function template_node_panel.New()
    return setmetatable({}, template_node_panel)
end

function template_node_panel:Init(root_node, index, select_function)
    self.root_node = root_node
    self.root_node:setTouchEnabled(true)
    self.root_node:setTag(index)
    self.root_node:setAnchorPoint(cc.p(0, 0))

    self.icon_img = self.root_node:getChildByName("item_icon")
    self.num_text_bg = self.root_node:getChildByName("text_bg")
    self.num_text = self.num_text_bg:getChildByName("num")
    local x = index % 6
    if x == 0 then
        x = 6
    end

    self.resource_name = nil
    local y = math.ceil(index / 6)
    self.x = OFFSET_X + (x - 1) * (self.root_node:getContentSize().width + 10)
    self.y = - y *(self.root_node:getContentSize().height + 10)
    self.root_node:setPosition(cc.p(self.x, self.y))

    self.root_node:addTouchEventListener(select_function)

end

function template_node_panel:Show(resource_name)
    self.root_node:setVisible(true)
    self.resource_name = resource_name
    local template_id = constants['RESOURCE_TYPE'][resource_name]
    local resource_template = resource_config[template_id]
    self.icon_img:loadTexture(resource_template.icon, PLIST_TYPE)
    self.icon_img:setVisible(true)
    self.item_id = template_id
    self.num_text_bg:setVisible(true)
    self.num_text:setString(resource_logic:GetResourcenNumByName(resource_name))
end

local resource_recycle_bag_msgbox = panel_prototype.New(true)
function resource_recycle_bag_msgbox:Init()
    self.root_node = cc.CSLoader:createNode("ui/resource_recycle_bag_msgbox.csb")
    self.back_btn = self.root_node:getChildByName("close_btn") 
        
    self.template = self.root_node:getChildByName("bag_template")
    self.template:setVisible(false)

    self.sub_templates = {}

    --列表视图
    self.list_scorllview = self.root_node:getChildByName("scroll_view")

    self.templates_node = cc.Node:create()
    self.list_scorllview:addChild(self.templates_node)

    --选择动画
    self.select_spine = spine_manager:GetNode("item_skill_choose")
    self.templates_node:addChild(self.select_spine, 1000)
    self.select_spine:setVisible(false)
    self.select_spine:setAnimation(0, "animation", true)

    detail_info_sub_panel:Init(self.root_node:getChildByName("item_explain"))

    self.use_btn = self.root_node:getChildByName("item_explain"):getChildByName("have_item_node"):getChildByName("use_btn")

    self.selelct_name = ""
    
    self:RegisterEvent()
    self:RegisterWidgetEvent()
end

--显示界面
function resource_recycle_bag_msgbox:Show(click_ok_func)
    self.root_node:setVisible(true)
    self.select_spine:setVisible(false)
    self.selelct_name = ""
    self.click_ok_func = click_ok_func
    self:LoadResource()

    detail_info_sub_panel:Show()
end

function resource_recycle_bag_msgbox:LoadResource()
    local item_list = {}
    local index = 0
    for k, v in pairs(RESOURCE_TYPE_NAME) do
        if resource_logic:GetResourcenNumByName(k) > 0 then
            local resource_template = resource_config[v]
            if resource_template.temperature and resource_template.temperature > 0 then
                index = index + 1
                local temp_node =  self.sub_templates[index] 
                if temp_node == nil then
                     self.sub_templates[index] = template_node_panel.New()
                     local clone_node = self.template:clone()
                     self.templates_node:addChild(clone_node)
                     self.sub_templates[index]:Init(clone_node, index, self.select_function)
                end
                self.sub_templates[index]:Show(k)  
            end
        end
    end

    local row = math.ceil(index / 6)
    
    --隐藏多余的
    for i = index + 1,#self.sub_templates do
        self.sub_templates[i]:Hide()
    end

    local now_height = (self.template:getContentSize().height + 10) * row
    local scorllview_height = self.list_scorllview:getContentSize().height
    if now_height > self.list_scorllview:getInnerContainerSize().height then
        self.list_scorllview:setInnerContainerSize(cc.size(self.list_scorllview:getContentSize().width, now_height))
        self.templates_node:setPositionY(now_height)
    else
        self.list_scorllview:setInnerContainerSize(cc.size(self.list_scorllview:getContentSize().width, scorllview_height))
        self.templates_node:setPositionY(scorllview_height)
    end

end

--Update定时器
function resource_recycle_bag_msgbox:Update(elapsed_time)

end

function resource_recycle_bag_msgbox:RegisterEvent()

    --开始开采
    -- graphic:RegisterEvent("mine_start_success", function(mine_index)
    --     if not self.root_node:isVisible() then
    --         return
    --     end
    --     local mine_info_config = mine_logic.mine_info_list
    --     if mine_info_config then
    --         mine_nodes[mine_index]:Show(mine_index, mine_info_config[mine_index])
    --     end
    -- end)

    -- --购买次数成功
    -- graphic:RegisterEvent("mine_buy_times_success", function()
    --     if not self.root_node:isVisible() then
    --         return
    --     end

    --     self:RefreshTimes()
    -- end)
    
end

function resource_recycle_bag_msgbox:RegisterWidgetEvent()

    -- --购买掠夺次数
    -- self.add_plunder_count_btn:addTouchEventListener(function(widget, event_type)
    --     if event_type == ccui.TouchEventType.ended then
    --         audio_manager:PlayEffect("click")
    --         local mode = client_constants["BATCH_MSGBOX_MODE"]["mine_buy_rob_times"]
    --         graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
    --     end
    -- end)

    self.select_function = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local click_res = self.sub_templates[widget:getTag()]
            if click_res and self.selelct_name ~= click_res.resource_name then
                self.select_spine:setVisible(true)
                self.select_spine:setPosition(cc.p(click_res.x + click_res.root_node:getContentSize().width/2,click_res.y+ click_res.root_node:getContentSize().height/2))
                self.selelct_name = click_res.resource_name
                detail_info_sub_panel:Show(self.selelct_name)
            end
            
        end
    end

    self.use_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if self.selelct_name and self.selelct_name ~= "" and self.click_ok_func then
                self.click_ok_func(self.selelct_name)
            end
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    --关闭按钮
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)
end

return resource_recycle_bag_msgbox

