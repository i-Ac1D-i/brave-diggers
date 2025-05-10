 local config_manager = require "logic.config_manager"

local lang_constants = require "util.language_constants"
local event_config = config_manager.event_config
local item_config = config_manager.item_config

local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"
local adventure_logic = require 'logic.adventure'
local mining_logic = require 'logic.mining'
local troop_logic = require "logic.troop"
local user_logic = require "logic.user"
local bag_logic = require "logic.bag"
local resource_logic = require "logic.resource"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local panel_prototype = require "ui.panel"
local panel_util= require "ui.panel_util"
local platform_manager = require "logic.platform_manager"

local PLIST_TYPE = ccui.TextureResType.plistType

local ITEM_HEIGHT = 180
local CHAR_WIDTH_ZH_CN = 28
local CHAR_WIDTH_EN_US = 28

local MAX_DIALOG_WIDTH_EN_US = 38
local MAX_DIALOG_WIDTH_ZH_CN = 14
local MAX_DIALOG_WIDTH_DE = 43
local MAX_DIALOG_WIDTH_FR = 43
local MAX_DIALOG_WIDTH_RU = 38
local MAX_DIALOG_WIDTH_ES_MX = 38


local dialog_sub_panel = panel_prototype.New()
dialog_sub_panel.__index = dialog_sub_panel

function dialog_sub_panel.New()
    return setmetatable({}, dialog_sub_panel)
end

function dialog_sub_panel:Init(root_node)
    self.root_node = root_node

    self.bg_img = root_node:getChildByName("bg")
    self.paragraph_text = root_node:getChildByName("paragraph")

    self.paragraph_text:getVirtualRenderer():setMaxLineWidth(400)

    self.real_height = 0
end

function dialog_sub_panel:Show(str, index)

   self.root_node:setVisible(true)

    self.index = index

    self.paragraph_text:setString(str)

    local len = self.paragraph_text:getVirtualRenderer():getStringLength()
  
    local max_text_length  --最大字符的个数
    local char_width
    if platform_manager:GetLocale() == "zh-CN" or platform_manager:GetLocale() == "zh-TW" then 
        max_text_length = MAX_DIALOG_WIDTH_ZH_CN   
        char_width = CHAR_WIDTH_ZH_CN              
    elseif platform_manager:GetLocale() == "jp" then
        char_width = CHAR_WIDTH_JP                    --FYD  并不是每个字符都一样大，如果以当前方式的话修改的话，只能设定一个比较大的值
        max_text_length = math.floor(400/char_width)  --FYD  注意：由于日文字体并不是每个字符都一样大的，所以这个每行容纳的字符个数就不能是固定的
    elseif platform_manager:GetLocale() == "de" then
        max_text_length = MAX_DIALOG_WIDTH_DE
        char_width = CHAR_WIDTH_EN_US
    elseif platform_manager:GetLocale() == "fr" then
        max_text_length = MAX_DIALOG_WIDTH_FR
        char_width = CHAR_WIDTH_EN_US
    elseif platform_manager:GetLocale() == "ru" then
        max_text_length = MAX_DIALOG_WIDTH_RU
        char_width = CHAR_WIDTH_EN_US
    elseif platform_manager:GetLocale() == "es-MX" then
        max_text_length = MAX_DIALOG_WIDTH_ES_MX
        char_width = CHAR_WIDTH_EN_US    
    else
        max_text_length = MAX_DIALOG_WIDTH_EN_US
        char_width = CHAR_WIDTH_EN_US
    end
    print("len==",len,"max text _length",max_text_length)
    if len >= max_text_length then
        local line_num = math.ceil(len / max_text_length)
        self.real_height = 107 + (line_num - 1) * 29

        self.bg_img:setContentSize({ width = 446, height = self.real_height })
        self.paragraph_text:setContentSize({width = 400, height = self.real_height })

    else
        local bg_height = 107
        local bg_default_height = platform_manager:GetChannelInfo().event_panel_msg_bg_defult_height
        if bg_default_height then
            bg_height = bg_default_height
        end

        self.bg_img:setContentSize({ width = math.min(82 + (len-1)*char_width, 446), height = bg_height })
        self.paragraph_text:setContentSize({width = math.min(len*char_width, 400), height = 128})

        self.real_height = bg_height
    end

    self.real_height = self.real_height + 20
end

--事件详细信息penel
local event_info_panel = panel_prototype.New(true)

function event_info_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/event_panel.csb")

    self.confirm_btn = self.root_node:getChildByName("confirm_btn")
    self.back_btn = self.root_node:getChildByName("back_btn")
    self.formation_btn = self.root_node:getChildByName("formation_btn")

    self.cost_nodes = {}
    self.cost_name_texts = {}
    self.cost_val_texts = {}
    self.cost_icon_imgs = {}

    local cost_node = self.root_node:getChildByName("cost")
    
    self.no_cost_text = cost_node:getChildByName("empty_bg"):getChildByName("desc")

    for i = 1, 2 do
        self.cost_nodes[i] = cost_node:getChildByName("cost" .. i)
        self.cost_name_texts[i] = self.cost_nodes[i]:getChildByName("name")
        self.cost_val_texts[i] = self.cost_nodes[i]:getChildByName("value")
        self.cost_icon_imgs[i] = self.cost_nodes[i]:getChildByName("icon")
    end

    self.title_name_text = self.root_node:getChildByName("title_name")

    self.remain_time_text = cost_node:getChildByName("remain_time")

    local bg = self.root_node:getChildByName("panel")
    self.leader_sprite = bg:getChildByName("leader_icon")
    self.enemy_sprite = bg:getChildByName("enemy_icon")

    self.dialog_sview = self.root_node:getChildByName("scrollview")

    self.dialog_template1 = self.dialog_sview:getChildByName("template1")
    self.dialog_template2 = self.dialog_sview:getChildByName("template2")

    self.left_dialog_num = 1
    self.right_dialog_num = 1

    self.left_dialog_sub_panels = {}
    self.right_dialog_sub_panels = {}

    self.all_sub_panels = {}

    local sub_panel = dialog_sub_panel.New()
    sub_panel:Init(self.dialog_template1)
    self.left_dialog_sub_panels[1] = sub_panel

    local sub_panel = dialog_sub_panel.New()
    sub_panel:Init(self.dialog_template2)
    self.right_dialog_sub_panels[1] = sub_panel

    self:RegisterWidgetEvent()
    self:RegisterEvent()
end

function event_info_panel:ShowNormalEvent(event_type, event_id)
    if event_id then
        self.event_id = event_id
    end

    if event_type then
        self.event_type = event_type
    end

    self.remain_time = 0
    self.is_dialog_finish = false

    if self.event_type == constants.ADVENTURE_EVENT_TYPE["battle"] then
        self:ShowBattleEvent(self.event_id)

    elseif self.event_type == constants.ADVENTURE_EVENT_TYPE["item"] then
        self:ShowDeliverItemEvent(self.event_id)
    end
end

function event_info_panel:ShowCaveEvent(event_type,event_data)
    if event_type then
        self.event_type = event_type
    end

    self.remain_time = 0
    self.is_dialog_finish = false

    if self.event_type == constants.ADVENTURE_EVENT_TYPE["battle"] then
        self:ShowBattleEvent(nil, event_data)
    end
end

function event_info_panel:Show(event_type, event_id, cave_event_flag, event_data)
    local cave_event_flag = cave_event_flag or false

    self.cave_event_flag = cave_event_flag
    self.remain_time_text:setVisible(not cave_event_flag)
    self.root_node:setVisible(true)

    if cave_event_flag then 
        self.cave_event_data = event_data
        self:ShowCaveEvent(event_type,event_data)
    else
        self.cave_event_data = nil
        self:ShowNormalEvent(event_type, event_id)
    end

    self.formation_btn:setVisible(user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mercenary"], false))

    self:LoadFormationInfo()
end

function event_info_panel:Hide()
    self.root_node:setVisible(false)
end

function event_info_panel:LoadFormationInfo()
    local const_str = lang_constants:Get("mercenary_adjust_formation") .. ": "
    local formation_str = string.format(lang_constants:Get("mercenary_cur_formation"), troop_logic:GetCurFormationId())
    self.formation_btn:setTitleText(const_str..formation_str)
end

function event_info_panel:Update(elapsed_time)
    self.remain_time = self.remain_time - elapsed_time
    if self.remain_time < 0 then
        if self.event_type == constants.ADVENTURE_EVENT_TYPE["battle"] then
            self:UpdateBattleCost(self.event_id)
        end

    else
        self.remain_time_text:setString(string.format(lang_constants:Get("adventure_event_fail_reset_cd"), panel_util:GetTimeStr(self.remain_time)))
    end
end

function event_info_panel:LoadIcon(sprite, sprite_path)
    local image_path = string.format("res/language/%s/role/%s.png", platform_manager:GetLocale(), sprite_path)
    if not cc.FileUtils:getInstance():isFileExist(image_path) then
        image_path = "res/role/" .. sprite_path .. ".png"
    end

    local texture = cc.Director:getInstance():getTextureCache():addImage(image_path)

    local frame_width = texture:getPixelsWide() / 3
    local frame_height = texture:getPixelsHigh() / 4

    texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    sprite:setTexture(texture)
    sprite:setTextureRect(cc.rect(0, 0, frame_width, frame_height))
    sprite:setScale(2, 2)
end

function event_info_panel:UpdateBattleCost(event_id)
    local cave_event_flag = self.cave_event_flag or false
    if  cave_event_flag then
        self.no_cost_text:setVisible(true)
        
        for i = 1, 2 do
            self.cost_nodes[i]:setVisible(false)
        end
    else
        self.no_cost_text:setVisible(true)
        local cur_event_info = config_manager.event_config[event_id]
        local cost_num = 0

        self.remain_time = adventure_logic:CheckEventResetMark()
        local fail_time = adventure_logic.event_fail_time_list[event_id] or 0

        local need_num_iter = string.gmatch(cur_event_info.need_num, "(%d+)")

        for resource_type in string.gmatch(cur_event_info.need_resource_id, "(%d+)") do
            local need_num = need_num_iter()

            if need_num then
                resource_type = tonumber(resource_type)
                need_num = tonumber(need_num) * math.pow(2, fail_time)

                local cur_num = resource_logic:GetResourceNum(resource_type)

                cost_num = cost_num + 1
                self.cost_nodes[cost_num]:setVisible(true)
                
                self.no_cost_text:setVisible(false)

                local res_conf = config_manager.resource_config[resource_type]

                self.cost_name_texts[cost_num]:setString(res_conf.name)

                self.cost_val_texts[cost_num]:setString(panel_util:ConvertUnit(need_num) .. "/" .. panel_util:ConvertUnit(cur_num))
                self.cost_val_texts[cost_num]:setColor(cur_num >= tonumber(need_num) and panel_util:GetColor4B(0xffffff) or panel_util:GetColor4B(0xff8d8d))
                self.cost_icon_imgs[cost_num]:loadTexture(res_conf.icon, PLIST_TYPE)
            end
        end
        
        for i = cost_num + 1, 2 do
            self.cost_nodes[i]:setVisible(false)
        end
    end
end

function event_info_panel:ShowBattleEvent(event_id, event_data)
    local cur_event_info
    if self.cave_event_flag then 
        cur_event_info = event_data
        self:UpdateBattleCost(nil)
    else
       cur_event_info = config_manager.event_config[event_id]
       self:UpdateBattleCost(event_id)
    end


    self:LoadIcon(self.leader_sprite, troop_logic:GetLeader().template_info.sprite)
    local conf = config_manager.mercenary_config[cur_event_info.mercenary_id]

    self:LoadIcon(self.enemy_sprite, conf.sprite)

    self.title_name_text:setString(cur_event_info.name)
    self.item_name = ""

    if adventure_logic.event_fail_time_list[event_id] and not self.cave_event_flag then
        --立即生成所有对话
        self.confirm_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
        self.confirm_btn:loadTextureNormal("button/buttonbg_1.png", PLIST_TYPE)
        self.confirm_btn:loadTexturePressed("button/buttonbg_1.png", PLIST_TYPE)
        self.is_dialog_finish = true

        self:GenerateDialog(cur_event_info, true)

    else
        self.confirm_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_finish"))
        self.confirm_btn:loadTextureNormal("button/buttonbg_1.png", PLIST_TYPE)
        self.confirm_btn:loadTexturePressed("button/buttonbg_1.png", PLIST_TYPE)
        self.is_dialog_finish = true

        self:GenerateDialog(cur_event_info, true)
    end
end

function event_info_panel:ShowDeliverItemEvent(event_id)
    local cur_event_info = config_manager.event_config[event_id]

    local item_template_info = config_manager.item_config[cur_event_info["need_item_id"]]

    self.icon_panel:Show(constants.REWARD_TYPE["item"], cur_event_info["need_item_id"], nil, nil, false)
    self.icon_panel.icon_img:setScale(1.0, 1.0)

    self.event_name_text:setString(item_template_info["name"])

    local item_count = bag_logic:GetItemCount(cur_event_info["need_item_id"])

    self.item_num_text:setString(item_count .. "/" .. cur_event_info["need_num"])
    self.item_num_text:setColor(item_count >= cur_event_info["need_num"] and panel_util:GetColor4B(0xa1e01b) or panel_util:GetColor4B(0xf87f26))

    self.item_num_text:setVisible(true)
    self.enemy_desc_text:setVisible(false)

    self.title_name_text:setString(cur_event_info.name)
    self.confirm_btn:setTitleText(lang_constants:Get("adventure_event_dialogue_continue"))

    self.item_name = item_template_info["name"]

    self:GenerateDialog(cur_event_info)
end

function event_info_panel:GenerateDialog(cur_event_info, show_all)
    local str = cur_event_info.desc
    if self.item_name ~= "" then
        str = string.gsub(str, "#item#", self.item_name)
    end

    local left_num = 0
    local right_num = 0

    local n = 0
    self.height = 0

    for d1, d2 in string.gmatch(str, "#(%d)#([^#]+)") do
        n = n + 1

        local sub_panel
        if d1 == "1" then
            left_num = left_num + 1
            sub_panel = self:GetDialogSubPanel(left_num, true)

            sub_panel:Show(d2, n)
        else
            right_num = right_num + 1
            sub_panel = self:GetDialogSubPanel(right_num, false)

            sub_panel:Show(d2, n)
        end

        self.all_sub_panels[n] = sub_panel
        self.height = self.height + sub_panel.real_height
    end

    self.height = self.height + 100

    --self.height = ITEM_HEIGHT * (n+0.5) + 60
    self.dialog_sview:setInnerContainerSize(cc.size(550, self.height))
    self.dialog_sview:jumpToTop()

    local next_sub_panel_y = self.height

    if show_all then
        for i = 1, n do
            local sub_panel = self.all_sub_panels[i]
            next_sub_panel_y = next_sub_panel_y - sub_panel.real_height
            sub_panel.root_node:setPositionY(next_sub_panel_y)
        end
    end

    for i = left_num + 1, self.left_dialog_num do
        local sub_panel = self.left_dialog_sub_panels[i]
        sub_panel:Hide()
    end

    for i = right_num + 1, self.right_dialog_num do
        local sub_panel = self.right_dialog_sub_panels[i]
        sub_panel:Hide()
    end
end

function event_info_panel:GetDialogSubPanel(index, is_left)
    local sub_panels
    local template
    if is_left then
        sub_panels = self.left_dialog_sub_panels
        template = self.dialog_template1
    else
        sub_panels = self.right_dialog_sub_panels
        template = self.dialog_template2
    end

    local sub_panel = sub_panels[index]
    if not sub_panel then
        sub_panel = dialog_sub_panel.New()
        sub_panel:Init(template:clone())

        sub_panels[index] = sub_panel

        self.dialog_sview:addChild(sub_panel.root_node)

        if is_left then
            self.left_dialog_num = self.left_dialog_num + 1
        else
            self.right_dialog_num = self.right_dialog_num + 1
        end
    end

    return sub_panel
end

--注册控件相关事件
function event_info_panel:RegisterWidgetEvent()
    --注册战斗事件
    self.confirm_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if not self.is_dialog_finish then
                return
            end

            if self.cave_event_flag then 
                if mining_logic:SolveCaveEvent(self.cave_event_data) then
                    graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                end
            else
                if adventure_logic:IsAdventureEvent(self.event_id) then
                    if adventure_logic:SolveEvent(self.event_id) then
                        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                    end

                else
                    if mining_logic:SolveEvent(self.event_id) then
                        graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
                    end
                end
            end
        end
    end)

    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
        end
    end)

    self.formation_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            local trans_type = constants["SCENE_TRANSITION_TYPE"]["none"]
            local mode = client_constants["FORMATION_PANEL_MODE"]["multi"]
            local back_panel = self:GetName()

            graphic:DispatchEvent("hide_world_sub_panel", self:GetName())
            if self.cave_event_flag then 
                local ex_params = {}
                ex_params[1] = self.cave_event_flag
                ex_params[2] = self.cave_event_data
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, true, mode, back_panel, ex_params)
            else
                graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", trans_type, true, mode, back_panel, nil)
            end
        end
    end)

end

function event_info_panel:RegisterEvent()
    graphic:RegisterEvent("change_troop_formation", function()
        if not self.root_node:isVisible() then
            return
        end

        self:LoadFormationInfo()
    end)
end

return event_info_panel
