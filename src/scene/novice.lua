local graphic = require "logic.graphic"
local mining_logic = require "logic.mining"
local troop_logic = require "logic.troop"
local adventure_logic = require "logic.adventure"
local platform_manager = require "logic.platform_manager"

local spine_manager = require "util.spine_manager"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local audio_manager = require "util.audio_manager"
local config_manager = require "logic.config_manager"

local sub_scene = require "scene.sub_scene"

local PLIST_TYPE = ccui.TextureResType.plistType

local BATTLE_TYPE = client_constants.BATTLE_TYPE

local MASK_ORIGIN = { x = 0, y = 0 }
local MASK_DESTINATION = { x = 640, y = 1136 }

local DEFAULT_MASK_ALPHA = 0.7
local MASK_COLOR = { a = 0.70, r = 0.0, g = 0.0, b = 0.0 }

local DEFAULT_TRANSITION_TIME = 0.25

--普通文本
local TEXT_COLOR_ONE = {a = 255, r = 255, g = 255, b = 255}
--对话文本
local TEXT_COLOR_TWO = {a = 255, r = 0, g = 0, b = 0}

local FONT_SIZE_ONE = 28
local FONT_SIZE_TWO = 28
local FONT_SIZE_ONE_EN = 22
local FONT_SIZE_TWO_EN = 22
local TEXT_WIDTH = 580
local TEXT_HEIGHT = 200


local NOVICE_TRIGGER_TYPE = client_constants["NOVICE_TRIGGER_TYPE"]
local NOVICE_TYPE = client_constants["NOVICE_TYPE"]
local NOVICE_MARK = client_constants["NOVICE_MARK"]

local VISIBLE_SIZE_WIDTH = cc.Director:getInstance():getVisibleSize().width
local VISIBLE_SIZE_HEIGHT = cc.Director:getInstance():getVisibleSize().height

local solve_event_cond= require "scene.novice.solve_event_cond"
local create_leader_cond = require "scene.novice.create_leader_cond"
local first_use_feature_cond = require "scene.novice.first_use_feature_cond"
local first_battle_failure_cond = require "scene.novice.first_battle_failure_cond"
local first_discover_golem_cond = require "scene.novice.first_discover_golem_cond"
local open_panel_cond = require "scene.novice.open_panel_cond"

local novice_sub_scene = sub_scene.New()

local novice_step = {}
novice_step.__index = novice_step

function novice_step:Play()
end

function novice_step:Stop()
end

function novice_step:Update(elapsed_time)
end

function novice_step:IsFinish()
    return true
end

function novice_step:OnTouch()
    audio_manager:PlayEffect("click")
end

function novice_step:OnRecvMsg(msg_name, msg_content)
end

local animation_step = setmetatable({}, novice_step)
animation_step.__index = animation_step

function animation_step.New(data)
    data.is_loop = data.is_loop or false
    data.scale = data.scale or 1.0
    setmetatable(data, animation_step)
end

function animation_step:Play()
    local spine_node = novice_sub_scene.animation_spine_node
    spine_node:setVisible(true)
    --spine_node:setToSetupPose()
    spine_node:setPosition(self.x, self.y)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)
    spine_node:setRotation(self.rotation)
    spine_node:setScale(self.scale)

    novice_sub_scene.cur_animation_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end
end

function animation_step:Stop()
    local spine_node = novice_sub_scene.animation_spine_node
    spine_node:setVisible(false)
    spine_node:clearTrack(0)
end

local text_step = setmetatable({}, novice_step)
text_step.__index = text_step

function text_step.New(data)
    setmetatable(data, text_step)
end

function text_step:Play()
    local text = novice_sub_scene.text1
    text:setVisible(true)
    text:setPosition(self.x, self.y)
    text:setContentSize(self.width, self.height)

    text:setString(lang_constants.NOVICE_STR[self.content_id])
end

function text_step:Stop()
    novice_sub_scene.text1:setVisible(false)
end

local color = {}
local dialogue_step = setmetatable({}, novice_step)
dialogue_step.__index = dialogue_step

function dialogue_step.New(data)
    data.is_loop = data.is_loop or false
    setmetatable(data, dialogue_step)
end

function dialogue_step:Play()
    local spine_node = novice_sub_scene.dialogue_spine_node
    --spine_node:setToSetupPose()
    spine_node:setVisible(true)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)

    novice_sub_scene.cur_dialogue_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end

    spine_node:setPosition(320, 0)

    local text = novice_sub_scene.text2
    text:setVisible(true)
    text:setString(lang_constants.NOVICE_STR[self.content_id])
end

function dialogue_step:Stop()
    local spine_node = novice_sub_scene.dialogue_spine_node
    spine_node:setVisible(false)
    spine_node:clearTrack(0)

    novice_sub_scene.text2:setVisible(false)
end

function dialogue_step:Update(elapsed_time)
    local spine_node = novice_sub_scene.dialogue_spine_node
    local widget = novice_sub_scene.text2

    local x, y, scale_x, scale_y, alpha, rotation, r, g, b = spine_node:getSlotTransform("txt1")
    widget:setPosition(320 + x, y)
    widget:setScale(scale_x, scale_y)
    color.r = r
    color.b = b
    color.g = g
    widget:setColor(color)
end

function dialogue_step:IsFinish()
    return self.is_finish
end

local talker_step = setmetatable({}, novice_step)
talker_step.__index = talker_step

function talker_step.New(data)
    data.is_loop = data.is_loop or false

    if type(data.mercenary_id) == "string" then
        data.mercenary_id = troop_logic:GetLeader().template_info.ID
    end

    setmetatable(data, talker_step)
end

function talker_step:Play()
    local spine_node = novice_sub_scene.talker_spine_node
    --spine_node:setToSetupPose()
    spine_node:setVisible(true)
    spine_node:setAnimation(0, self.animation_name, self.is_loop)

    self.hide_spine_node = self.animation_name == "talker_exit"

    novice_sub_scene.cur_talker_step = self
    if not self.is_loop then
        self.is_finish = false
    else
        self.is_finish = true
    end

    novice_sub_scene.mercenary_img:setVisible(true)
    local conf = config_manager.mercenary_config[self.mercenary_id]
    novice_sub_scene.mercenary_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. conf.sprite .. ".png", PLIST_TYPE)
end

function talker_step:Stop()
    if self.hide_spine_node then
        novice_sub_scene.talker_spine_node:setVisible(false)
        novice_sub_scene.mercenary_img:setVisible(false)
    end
    novice_sub_scene.talker_spine_node:clearTrack(0)
end

function talker_step:Update(elapsed_time)
    local spine_node = novice_sub_scene.talker_spine_node
    local widget = novice_sub_scene.mercenary_img

    local x, y, scale_x, scale_y, alpha, rotation, r, g, b = spine_node:getSlotTransform("talker")
    widget:setPosition(320 + x, y)
    widget:setScale(scale_x*2, scale_y*2)

    color.r = r
    color.b = b
    color.g = g
    widget:setColor(color)
end

function dialogue_step:IsFinish()
    return self.is_finish
end

--打开界面
--参数：
--界面名称name
local open_panel_step = setmetatable({}, novice_step)
open_panel_step.__index = open_panel_step

function open_panel_step.New(data)
    setmetatable(data, open_panel_step)
end

function open_panel_step:Play()
    graphic:DispatchEvent("show_world_sub_panel", self.name)
end

function open_panel_step:Stop()
end

--打开场景
--参数：
--场景名称name
local open_sub_scene_step = setmetatable({}, novice_step)
open_sub_scene_step.__index = open_sub_scene_step

function open_sub_scene_step.New(data)
    setmetatable(data, open_sub_scene_step)
end

function open_sub_scene_step:Play()
    graphic:DispatchEvent("show_world_sub_scene", self.name)
end

function open_sub_scene_step:Stop()
end

--升级
local sim_levelup_step = setmetatable({}, novice_step)
sim_levelup_step.__index = sim_levelup_step

function sim_levelup_step.New(data)
    setmetatable(data, sim_levelup_step)
end

function sim_levelup_step:Play()
    troop_logic:AllocMercenaryExp(troop_logic:GetLeader().instance_id, 1)
end

function sim_levelup_step:Stop()
end

--挖矿
local sim_dig_block_step = setmetatable({}, novice_step)
sim_dig_block_step.__index = sim_dig_block_step

function sim_dig_block_step.New(data)
    setmetatable(data, sim_dig_block_step)
end

function sim_dig_block_step:Play()
    mining_logic:DigOrCollectBlock(self.block_x, self.block_y)
end

--战斗
local sim_battle_step = setmetatable({}, novice_step)
sim_battle_step.__index = sim_battle_step

function sim_battle_step.New(data)
    setmetatable(data, sim_battle_step)
end

function sim_battle_step:Play()
    if self.battle_type == BATTLE_TYPE["vs_monster"] then
        adventure_logic:SolveEvent(self.event_id)
    end
end

--进入下一关
local sim_enter_maze_step = setmetatable({}, novice_step)
sim_enter_maze_step.__index = sim_enter_maze_step

function sim_enter_maze_step.New(data)
    setmetatable(data, sim_enter_maze_step)
end

function sim_enter_maze_step:Play()
    adventure_logic:EnterNextMaze()
end

--模拟点击
local sim_touch_step = setmetatable({}, novice_step)
sim_touch_step.__index = sim_touch_step

local glview = cc.Director:getInstance():getOpenGLView()

local real_size = glview:getFrameSize()
local viewport_rect = glview:getViewPortRect()

local scale_x = glview:getScaleX()
local scale_y = glview:getScaleY()

function sim_touch_step.New(data)

    data.x = data.x * scale_x+ viewport_rect.x
    data.y = real_size.height - data.y  * scale_y + viewport_rect.y

    setmetatable(data, sim_touch_step)
end

function sim_touch_step:Play()
    novice_sub_scene.can_swallow_touch_event = false
    aandm.simTouch(self.x, self.y)
    novice_sub_scene.can_swallow_touch_event = true
end

function sim_touch_step:OnTouch()

end

--网络同步
local network_sync_step = setmetatable({}, novice_step)
network_sync_step.__index = network_sync_step

function network_sync_step.New(data)
    setmetatable(data, network_sync_step)
end

function network_sync_step:Play()
    self.is_finish = false
end

function network_sync_step:OnRecvMsg(msg_name, msg_content)
    if msg_name ~= self.msg_name then
        return
    end

    --矿区数据分块传输
    if self.msg_name == "query_mining_block_info_ret" then
        self.is_finish = msg_content.is_finish_query
    else
        self.is_finish = true
    end
end

function network_sync_step:IsFinish()
    return self.is_finish
end

local novice_group = {}
novice_group.__index = novice_group

function novice_group.New()
    return setmetatable({}, novice_group)
end

function novice_group:Play()
    local last_steps = self.cur_steps

    if last_steps then
        for i, step in ipairs(last_steps) do
            step:Stop()
        end
    end

    self.cur_steps = self[self.cur_step_index]
    if not self.cur_steps then
        return true
    end

    self.cur_alpha = last_steps and last_steps.mask_info.alpha or 0
    self.next_alpha = self.cur_steps.mask_info.alpha

    self.last_mask_info = last_steps and last_steps.mask_info or nil

    self.transition_time = self.cur_steps.mask_info.transition_time
    self.delta_time = 0

    self.auto_play_next_step = self.cur_steps.auto_play_next_step
    novice_sub_scene.enable_forward = false

    self.waiting_transition = self.cur_steps.mask_info.waiting_transition
    self.cur_step_index = self.cur_step_index + 1

    self.is_playing = false
    self.is_cur_step_finish = false

    if not self.last_mask_info or not self.last_mask_info.x then
        local mask_info = self.cur_steps.mask_info
        if mask_info.x then
            self:SetMaskSize(mask_info.x, mask_info.y, mask_info.width, mask_info.height, mask_info.padding)
        else
            novice_sub_scene.mask_node:setVisible(false)
            novice_sub_scene.fuzzy_node:setVisible(false)
        end
    end

    --判读是否会和跳过按钮重合
    local skip_btn = novice_sub_scene.skip_btn 
    if skip_btn and mask_info then
        local skip_btn_width = skip_btn:getContentSize().width*skip_btn:getScale()
        local skip_btn_height = skip_btn:getContentSize().height*skip_btn:getScale()
        local mask_info_x = mask_info.x  or 0
        local mask_info_width = mask_info.width or 0
        local mask_info_y = mask_info.y  or 0
        local mask_info_height = mask_info.height  or 0
        if mask_info_x ~= VISIBLE_SIZE_WIDTH/2 and mask_info_x + mask_info_width/2 >= VISIBLE_SIZE_WIDTH - skip_btn_width and mask_info_y + mask_info_height/2 >= VISIBLE_SIZE_HEIGHT - skip_btn_height then
            skip_btn:setPosition({x = skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        else
            skip_btn:setPosition({x = VISIBLE_SIZE_WIDTH - skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        end
    end

    if not self.waiting_transition then
        self:DoPlay()
    end

    return false
end


local mask_color = { a = 0.75, r = 0.0, g = 0.0, b = 0.0 }
function novice_group:Update(elapsed_time)
    if not self.cur_steps then
        return
    end

    if self.is_playing then
        local finish_num = 0

        for i, step in ipairs(self.cur_steps) do
            step:Update(elapsed_time)

            if step:IsFinish() then
                finish_num = finish_num + 1
            end
        end

        if #self.cur_steps == finish_num then
            self.is_cur_step_finish = true

            if self.auto_play_next_step then
                novice_sub_scene.enable_forward = true
            end
        end
    end

    self.delta_time = self.delta_time + elapsed_time
    if self.delta_time <= self.transition_time then
        --过渡
         local percent = 1.01 * math.exp(- ( 1.2 * (self.delta_time/self.transition_time)  -1.5) ^ 4) - 0.15 * math.sin((self.delta_time/self.transition_time) * 6.28 )
        mask_color.a = self.cur_alpha + (self.next_alpha - self.cur_alpha) * percent
        if mask_color.a < 0 then
            mask_color.a = 0

        elseif mask_color.a > 1 then
            mask_color.a = 1
        end

        novice_sub_scene.black_node:clear()
        novice_sub_scene.black_node:drawSolidRect(MASK_ORIGIN, MASK_DESTINATION, mask_color)

        local mask_info = self.cur_steps.mask_info
        if self.last_mask_info and self.last_mask_info.x and mask_info.x then
            local x = self.last_mask_info.x + (mask_info.x - self.last_mask_info.x) * percent
            local y = self.last_mask_info.y + (mask_info.y - self.last_mask_info.y) * percent
            local width = self.last_mask_info.width + (mask_info.width - self.last_mask_info.width) * percent
            local height = self.last_mask_info.height + (mask_info.height - self.last_mask_info.height) * percent
            self:SetMaskSize(x, y, width, height, mask_info.padding)
        end

    else
        if not self.is_playing then
            --过渡结束
            self:DoPlay()
        end
    end
end

function novice_group:DoPlay()
    self.is_playing = true

    for i, step in ipairs(self.cur_steps) do
        step:Play()
    end
end

local rect = cc.rect(0, 0, 0, 0)
function novice_group:SetMaskSize(x, y, width, height, padding)
    local node = novice_sub_scene.fuzzy_node
    padding = padding or 0

    rect.x = padding
    rect.y = padding
    rect.width = novice_sub_scene.raw_mask_width - padding * 2
    rect.height = novice_sub_scene.raw_mask_height - padding * 2

    node:setContentSize(width, height)
    node:setCapInsets(rect)
    node:setPosition(x, y)

    node:setVisible(true)

    novice_sub_scene.mask_node:setPosition(x, y)
    novice_sub_scene.mask_node:setContentSize(width, height)
    novice_sub_scene.mask_node:setCapInsets(rect)

    novice_sub_scene.mask_node:setVisible(true)
end

function novice_group:Stop()
    if not self.cur_steps then
        return
    end

    for i, step in ipairs(self.cur_steps) do
        step:Stop()
    end
end

function novice_group:OnTouch()
    if self.is_playing then
        for i, step in ipairs(self.cur_steps) do
            step:OnTouch()
        end

        if self.is_cur_step_finish and not self.auto_play_next_step and self.delta_time >= self.transition_time then
            novice_sub_scene.enable_forward = true
        end
    end
end

function novice_group:OnRecvMsg(msg_name, msg_content)
    if self.is_playing then
        for i, step in ipairs(self.cur_steps) do
            step:OnRecvMsg(msg_name, msg_content)
        end

        if self.is_cur_step_finish and not self.auto_play_next_step and self.delta_time >= self.transition_time then
            novice_sub_scene.enable_forward = true
        end
    end

end

function novice_sub_scene:InitMeta()
    self.prototypes = {}
    self.groups = {}

    self.prototypes[NOVICE_TYPE["animation"]] = animation_step
    self.prototypes[NOVICE_TYPE["text"]] = text_step
    self.prototypes[NOVICE_TYPE["dialogue"]] = dialogue_step
    self.prototypes[NOVICE_TYPE["talker"]] = talker_step
    self.prototypes[NOVICE_TYPE["open_panel"]] = open_panel_step
    self.prototypes[NOVICE_TYPE["open_sub_scene"]] = open_sub_scene_step
    self.prototypes[NOVICE_TYPE["sim_levelup"]] = sim_levelup_step
    self.prototypes[NOVICE_TYPE["sim_dig_block"]] = sim_dig_block_step
    self.prototypes[NOVICE_TYPE["sim_enter_maze"]] = sim_enter_maze_step
    self.prototypes[NOVICE_TYPE["sim_battle"]] = sim_battle_step
    self.prototypes[NOVICE_TYPE["sim_touch"]] = sim_touch_step
    self.prototypes[NOVICE_TYPE["network_sync"]] = network_sync_step
end

function novice_sub_scene:Init()

    self.__name = "novice_sub_scene"

    self.cur_group = nil
    self.cur_step_index = nil
    self.is_finish = false
    self.can_swallow_touch_event = false

    self.root_node = cc.Node:create()
    self.black_node = cc.DrawNode:create()
    self.black_node:setVisible(true)
    self.black_node:drawSolidRect(MASK_ORIGIN, MASK_DESTINATION, MASK_COLOR)

    self.mask_node = ccui.Scale9Sprite:create("res/ui/novice_mask.png")
    self.raw_mask_width = self.mask_node:getSprite():getTexture():getPixelsWide()
    self.raw_mask_height = self.mask_node:getSprite():getTexture():getPixelsHigh()
    self.fuzzy_node = ccui.Scale9Sprite:create("res/ui/novice_mask.png")

    self.stencil_node = cc.Node:create()
    self.stencil_node:addChild(self.mask_node)

    self.clipping_node = cc.ClippingNode:create(self.stencil_node)
    self.clipping_node:addChild(self.black_node)
    self.clipping_node:setInverted(true)

    self.clipping_node:setVisible(true)

    self.root_node:addChild(self.clipping_node)
    self.root_node:addChild(self.fuzzy_node)

    self.text1 = ccui.Text:create("", client_constants["FONT_FACE"], platform_manager:GetLocale() == "en-US" and FONT_SIZE_ONE_EN or FONT_SIZE_ONE)
    self.text2 = ccui.Text:create("", client_constants["FONT_FACE"], platform_manager:GetLocale() == "en-US" and FONT_SIZE_TWO_EN or FONT_SIZE_TWO)
    self.text2:ignoreContentAdaptWithSize(false)
    self.text2:setContentSize(cc.size(TEXT_WIDTH, TEXT_HEIGHT))
    self.text2:setTextVerticalAlignment(1)

    if platform_manager:GetChannelInfo().novice_change_text_size and platform_manager:GetLocale() == "fr" then 
        self.text1:setFontSize(FONT_SIZE_ONE_EN)
    end

    self.text1:setVisible(false)
    self.text1:setColor(TEXT_COLOR_ONE)

    self.text2:setVisible(false)
    self.text2:setColor(TEXT_COLOR_TWO)
    self.text2:setAnchorPoint(cc.p(0.0, 0.5))

    self.dialogue_spine_node = spine_manager:GetNode("novice_dialogue")
    self.animation_spine_node = spine_manager:GetNode("novice_gesture")
    self.talker_spine_node = spine_manager:GetNode("novice_talker")

    self.dialogue_spine_node:setVisible(false)
    self.animation_spine_node:setVisible(false)
    self.talker_spine_node:setVisible(false)

    self.mercenary_img = ccui.ImageView:create()

    self.root_node:addChild(self.dialogue_spine_node, 2)
    self.root_node:addChild(self.animation_spine_node, 1)
    self.root_node:addChild(self.talker_spine_node, 1)

    self.root_node:addChild(self.text1, 3)
    self.root_node:addChild(self.text2, 3)

    self.root_node:addChild(self.mercenary_img, 1)

    self.root_node:setVisible(false)

    --跳过按钮
    if platform_manager:GetChannelInfo().novice_scene_skip_btn_show then 
        self.skip_btn = ccui.ImageView:create()
        self.skip_btn:loadTexture("button/buttonbg_1.png", PLIST_TYPE)
        self.skip_btn:setScale9Enabled(true)
        
        self.skip_btn:setCapInsets({x=76,y=24,width=76,height=24})
        self.skip_btn:setContentSize({width=180,height=80})
        self.skip_btn:setScale(0.6)
        local skip_btn_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
        local skip_btn_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
        self.skip_btn:setPosition({x = VISIBLE_SIZE_WIDTH - skip_btn_width/2, y = VISIBLE_SIZE_HEIGHT - skip_btn_height/2-10})
        self.root_node:addChild(self.skip_btn)

        --跳过文字
        local btn_text = cc.Label:createWithTTF(lang_constants:Get("novice_sub_scene_skip_btn_desc"),"ui/fonts/general.ttf",36)
        btn_text:setColor({r=0,g=0,b=0})
        btn_text:setPosition({x = self.skip_btn:getContentSize().width/2,y = self.skip_btn:getContentSize().height/2})
        self.skip_btn:addChild(btn_text)
    end    

    self:RegisterWidgetEvent()
end

function novice_sub_scene:AddGroup(group_id, trigger_cond, ...)
    local datas = {...}

    local group = novice_group.New()
    assert(not self.groups[group_id], string.format("repeat group_id %d", group_id))
    self.groups[group_id] = group

    group.trigger_cond = trigger_cond

    for i = 1, #datas do
        local steps = datas[i]

        local mask_info = steps.mask_info
        mask_info.alpha = mask_info.alpha or DEFAULT_MASK_ALPHA
        mask_info.transition_time = mask_info.transition_time or DEFAULT_TRANSITION_TIME

        for j = 1, #steps do
            local step = steps[j]
            local prototype = self.prototypes[step.type]
            assert(prototype)

            step.step_id = i
            prototype.New(step)
        end

        group[i] = steps
    end
end

function novice_sub_scene:Trigger(type, param)
    if _G["AUTH_MODE"] or platform_manager:IsAdmin() then
        return false
    end
    
    for group_id, group in pairs(self.groups) do
        local cond = group.trigger_cond
        if cond.type == type and cond:Check(param) then
            group.cur_steps = nil
            group.cur_step_index = 1

            self.cur_group = group
            self.is_finish = false
            return true
        end
    end

    return false
end

function novice_sub_scene:Show()
    if not self.root_node:isVisible() then
        self.root_node:setVisible(true)
    end

    self.can_swallow_touch_event = true
    -- print("－－－－－－－开启引导功能－－－－－－－－－");
    graphic:DispatchEvent("guide_open");
    
    if self.cur_group then
        self.cur_group:Play()
    end
end

function novice_sub_scene:Hide()
    self.can_swallow_touch_event = false
    self.is_finish = false
    self.root_node:setVisible(false)
    graphic:DispatchEvent("guide_close");
    -- print("－－－－－－－－关闭引导功能－－－－－－－－－－");
end

function novice_sub_scene:CanSwallowTouchEvent()
    return self.can_swallow_touch_event
end

function novice_sub_scene:IsVisbile()
    return self.root_node:isVisible()
end

function novice_sub_scene:Forward()
    if not self.cur_group then
        return
    end

    self.is_finish = self.cur_group:Play()
end

function novice_sub_scene:GoComment()
    graphic:DispatchEvent("show_simple_msgbox", 
    lang_constants:Get("comment_msgbox_title"),
    lang_constants:Get("comment_msgbox_content"),
    lang_constants:Get("comment_msgbox_btn2"),
    lang_constants:Get("comment_msgbox_btn1"),
    function()
        --去好评发奖
        --local carnival_logic = require "logic.carnival"
        --carnival_logic:TakeReward({},1)
        local channel_info = platform_manager:GetChannelInfo()
        cc.Application:getInstance():openURL(channel_info.appraise_url)
    end, 
    function()
        --去吐槽开网页
        local channel_info = platform_manager:GetChannelInfo()
        local user_logic = require "logic.user"
        graphic:DispatchEvent("show_world_sub_panel", "web_panel", channel_info.other_url[1]..user_logic:GetUserId(), "comment_panel_title")
    end)
end

function novice_sub_scene:Update(elapsed_time)
    if not self.cur_group or not self.root_node:isVisible() then
        return
    end

    self.cur_group:Update(elapsed_time)

    if not self.is_finish and self.enable_forward and self.cur_group.delta_time >= self.cur_group.transition_time then
        self:Forward()
    end

    if self.is_finish then
        self:Hide()

        local cond = self.cur_group.trigger_cond
        local channel_info = platform_manager:GetChannelInfo()
        if cond.type == NOVICE_TRIGGER_TYPE["solve_event"] and cond.event_id == 1000012 and channel_info.meta_channel == "qikujp" then
            self:GoComment()
        end
    end
end

function novice_sub_scene:OnTouch()
    if not self.is_finish then
        self.cur_group:OnTouch()
    end
end

function novice_sub_scene:OnTouchBegan(touch)
    if touch ~= nil and self.skip_btn then
        local size_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
        local size_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
        local posx = self.skip_btn:getPositionX()
        local posy = self.skip_btn:getPositionY()
        local touchPosx = touch:getLocation().x
        local touchPosy = touch:getLocation().y
        if touchPosx >=posx-size_width/2 and  touchPosx <=posx+size_width  and touchPosy >= posy-size_height/2 and touchPosy <= posy+size_height then
            -- print("你开触摸了跳过按钮")
            self.onTouchBegan = true
            self.skip_btn:setScale(0.5)
        end
    end
end

function novice_sub_scene:OnTouchEned(touch)
    local canTouch = true
    if self.skip_btn then
        if touch ~= nil then
            local size_width = self.skip_btn:getContentSize().width*self.skip_btn:getScale()
            local size_height = self.skip_btn:getContentSize().height*self.skip_btn:getScale()
            local posx = self.skip_btn:getPositionX()
            local posy = self.skip_btn:getPositionY()
            local touchPosx = touch:getLocation().x
            local touchPosy = touch:getLocation().y
            if touchPosx >=posx-size_width/2 and  touchPosx <=posx+size_width and touchPosy >= posy-size_height/2 and touchPosy <= posy+size_height then
                if self.onTouchBegan then
                    -- print("你触摸了跳过按钮")
                    self.is_finish=true
                    canTouch = false
                end
            end
        end
        self.skip_btn:setScale(0.6)
    end
    self.onTouchBegan = false

    if not self.is_finish and canTouch then
        self.cur_group:OnTouch()
    end
end


function novice_sub_scene:OnRecvMsg(msg_name, msg_content)
    if self.cur_group then
        self.cur_group:OnRecvMsg(msg_name, msg_content)
    end
end

function novice_sub_scene:RegisterWidgetEvent()
    self.dialogue_spine_node:registerSpineEventHandler(function(event)
        self.cur_dialogue_step.is_finish = true
    end, sp.EventType.ANIMATION_END)

    self.animation_spine_node:registerSpineEventHandler(function(event)
        self.cur_animation_step.is_finish = true
    end, sp.EventType.ANIMATION_END)

    self.talker_spine_node:registerSpineEventHandler(function(event)
        self.cur_talker_step.is_finish = true
    end, sp.EventType.ANIMATION_END)
end

novice_sub_scene:InitMeta()

--剧情介绍--以及冒险界面介绍
novice_sub_scene:AddGroup(1, create_leader_cond.New(),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 1 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 1 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 2 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 2  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 2 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 3 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 3 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 4 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 4  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 5 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 5  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 6 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 6  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 6  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 7  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 7 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 7 },
    },

    --进入冒险界面进行冒险界面解说
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 18,  x = 162, y = 300, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 158 , y = 192 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 151, y = 53 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 8 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 8 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 9 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 9 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 9 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 10 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 10  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 10  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 11 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 618 , width = 620, height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 11  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 418 , width = 640, height = 368 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 12 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 418 , width = 640, height = 368 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 12  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 418 , width = 640, height = 368 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 13  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 418 , width = 640, height = 368 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 13  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 620 , width = 628, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 14  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 620 , width = 628, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 14  },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 740 , y = 530 , width = 0, height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 15  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 15  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 16  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 16  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = -100 , width = 0, height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 16  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 200 , width = 292, height = 154 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 17,  x = 295, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 300 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 1 , x = 320 , y = 200 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["sim_battle"], battle_type = BATTLE_TYPE["vs_monster"], event_id = 1000001 },
    }
)


novice_sub_scene:AddGroup(2, solve_event_cond.New(1000001),
    --战斗结束收尾，进入新地图
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7, transition_time = 0.5 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 19 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 19 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 19 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = -100 , y = 882 , width = 0, height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 20 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = -100 , y = 882 , width = 0, height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 20 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 20 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 21 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 21 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 21 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 22 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 882 , width = 620, height = 420 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 22 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 212 , width = 292 , height = 154 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 22 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 212 , width = 292 , height = 154 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 23,  x = 320, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 300 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = -100 , width = 0 , height = 0 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320 , y = 212},
        { type = NOVICE_TYPE["network_sync"], msg_name = "enter_adventure_maze_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 24 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 121 , y = 697 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 24  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 121 , y = 697 , width = 230, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 25 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 121 , y = 697 , width = 230, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 25 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 121 , y = 697 , width = 230, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 26 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 121 , y = 697 , width = 230, height = 78 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 26 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 27 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 27 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 28 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 28  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 28  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 28  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 28  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 300, height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 28 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 308 , y = 1107 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 29 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 29 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 30 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 30 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 30 },
    }
)

--升级功能
novice_sub_scene:AddGroup(3, solve_event_cond.New(1000002),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 31 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 31 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 31 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 32 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 32  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 32  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 33 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 740 , y = 193 , width = 0 , height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 33 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 33 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 34,  x = 420, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 443 , y = 303 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 543 , y = 193},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 35,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 36 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 36 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 37 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 37 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 37 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 38, x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 39,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 40,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 41,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 42,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 47 , y = 181 , width = 250 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 43,  x = 78, y = 422, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 78 , y = 272 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 47 , y = 181 , width = 0 , height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 47 , y = 181},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 44 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 44 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 45 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 45 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 45 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 46 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 46 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 46 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 47 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 47  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 47  },
    }
)

--第二次升级引导
novice_sub_scene:AddGroup(11, solve_event_cond.New(1000003),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 77 , y = 171 , width = 174 , height = 90 , padding = 20 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 48,  x = 420, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 443 , y = 303 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 543 , y = 193},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 35,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
    }
)

--阵容功能
novice_sub_scene:AddGroup(4, solve_event_cond.New(1000005),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 11000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 49 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 49  },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 50 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 50 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 51 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 51 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 740 , y = 53 , width = 0 , height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 51 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52, x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 53,  x = 270, y = 675, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 785 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 930 , width = 620 , height = 290 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 934},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 11000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 956 , width = 640 , height = 259 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 54 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 956 , width = 640 , height = 259 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 54 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 956 , width = 640 , height = 259 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 55 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 956 , width = 640 , height = 259 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 55 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 556 , width = 640 , height = 514 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 56 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 556 , width = 640 , height = 514 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 56 },
    },
    {
        auto_play_next_step = true,
        -- mask_info = { alpha = 0.7 , x = 320 , y = 500 , width = 630 , height = 520 , padding = 20 },
        mask_info = { alpha = 0.7 , x = 200 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 57 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 200 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 57 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 200 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 57 },
    },
    --选择空位
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 200 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 58,  x = 196, y = 490, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 196, y = 640 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 70 , y = 961 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 196, y = 690},
    },

    --选择更换佣兵
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 70 , y = 961 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 59,  x = 72, y = 649, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 72 , y = 839 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 600 , width = 640 , height = 262 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 68, y = 961},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 11000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 600 , width = 640 , height = 262 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 60 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 600 , width = 640 , height = 262 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 60 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 60 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 61,  x = 574, y = 263, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 594 , y = 413 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 594, y = 513},
        { type = NOVICE_TYPE["network_sync"], msg_name = "insert_formation_ret" },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 18,  x = 162, y = 350, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 158 , y = 192 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 151, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 62, x = 420, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 443 , y = 303 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 736 , width = 640 , height = 168 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 543 , y = 193},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 736 , width = 640 , height = 168 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 35,  x = 519, y = 486, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 519 , y = 636 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 736 , width = 640 , height = 168 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 543 , y = 736},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 736 , width = 640 , height = 168 , padding = 20 },
    }
)
--2-4佣兵上阵，改到2-1
novice_sub_scene:AddGroup(18, solve_event_cond.New(1000006),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 11000018 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000018  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 63 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 63 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000018  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 63 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 53,  x = 270, y = 675, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 785 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 690 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 934},
    },
    --选择空位
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 58,  x = 320, y = 480, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 609 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 70 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 690},
    },

    --选择更换佣兵
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 70 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 59,  x = 70, y = 689, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 70 , y = 839 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 70, y = 961},
    },

    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 61,  x = 574, y = 263, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 594 , y = 413 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 594, y = 513},
        { type = NOVICE_TYPE["network_sync"], msg_name = "insert_formation_ret" },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 18,  x = 162, y = 300, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 158 , y = 151 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 0, height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 151, y = 53 },
    }
)

--2-5以后增加一步上阵引导（上阵两个兔女郎）
novice_sub_scene:AddGroup(21, solve_event_cond.New(1000010),
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 53,  x = 270, y = 675, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 785 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 444 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 934},
    },
    
 --选择空位（上阵第1个）
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 444 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 58,  x = 444, y = 890, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 444 , y = 640 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 72 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 444, y = 740},
    },

    --选择更换佣兵
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 72 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 59,  x = 72, y = 706, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 72 , y = 856 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 70, y = 956},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 61,  x = 564, y = 263, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 574 , y = 413 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 594 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 594, y = 513},
        { type = NOVICE_TYPE["network_sync"], msg_name = "insert_formation_ret" },
    },
    --选择空位（上阵第2个）
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 574 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 58,  x = 564, y = 500, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 564 , y = 660 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 72 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 594, y = 740},
    },
    --选择更换佣兵
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 72 , y = 956 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 59,  x = 72, y = 706, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 72 , y = 856 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 70, y = 956},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 594 , y = 513 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 61,  x = 564, y = 263, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 574 , y = 413 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 594, y = 513},
        { type = NOVICE_TYPE["network_sync"], msg_name = "insert_formation_ret" },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 18,  x = 162, y = 300, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 158 , y = 151 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 0, height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 151, y = 53 },
    }
)

--开启探索功能
novice_sub_scene:AddGroup(9, solve_event_cond.New(1000008),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 64 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 64 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 65 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 65 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 66 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 66 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 67 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 67 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 67 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 562 , y = 530 , width = 110, height = 110 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 68,  x = 573, y = 330, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 573 , y = 430 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 573, y = 530},
        { type = NOVICE_TYPE["network_sync"], msg_name = "open_box_ret" },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 69 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 69 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 70 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 560 , width = 590, height = 537 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 70 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 346 , width = 514, height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 70 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 346 , width = 514, height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 71,  x = 320, y = 96, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 246 , rotation = 90 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 106 , y = 193 , width = 229, height = 120 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 377},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 106 , y = 193 , width = 229, height = 120 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 72,  x = 206, y = 393, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 156 , y = 243 , rotation = 315 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 564 , width = 618, height = 755 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 106, y = 193},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 564 , width = 618, height = 755 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 73 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 564 , width = 618, height = 755 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 73 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 560, height = 161 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 74 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 560, height = 161 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 74 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 526 , y = 820 , width = 112, height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 74 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 526 , y = 820 , width = 112, height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 75,  x = 526, y = 570, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 526 , y = 720 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 591 , y = 912 , width = 91, height = 90 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 526, y = 800},
        { type = NOVICE_TYPE["network_sync"], msg_name = "use_item_ret" },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 591 , y = 912 , width = 91, height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 76,  x = 591, y = 712, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 591 , y = 812 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 591 , y = 912 , width = 0, height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 591, y = 912},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 77 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 536 , y = 700 , width = 174, height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 77 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 536 , y = 700 , width = 174, height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 77 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 536 , y = 700 , width = 174, height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 78,  x = 536, y = 504, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 536 , y = 604 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 542, height = 671 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 536, y = 700},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
        {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 542, height = 671 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 79 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 542, height = 671 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 79  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 430 , width = 470, height = 334 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 79 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 430 , width = 470, height = 334 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 80 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 430 , width = 470, height = 334 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 80 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 82, height = 76 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 80 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 553 , y = 871 , width = 90, height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 76,  x = 553, y = 621, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 553 , y = 771 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 528 , y = 871 , width = 0, height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 528, y = 871},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000021 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 81 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 81 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 82 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 82 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 528 , y = 782 , width = 0, height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000021  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 82 },
    }
)

----佣兵召唤，改为3-2之后引导（原2-5）
novice_sub_scene:AddGroup(5, solve_event_cond.New(1000012),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000020 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 83 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 83 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 83 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 84 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 84 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 84 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 85 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 85 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 480 , y = -100 , width = 124 , height = 138 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 85 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 480 , y = 39 , width = 124 , height = 138 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 86,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 401 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 480 , y = -100 , width = 0 , height = 0 , padding = 20 },
        { type =  NOVICE_TYPE["sim_touch"], x = 480 , y = 39},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000020  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 87 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 873 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 87 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 873 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 88 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 873 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 88 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 695 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 89 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 695 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 89 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 518 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 518 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 340 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 91 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 340 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 91 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 92 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 75 , y = 38 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 92 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 75 , y = 38 , width = 150 , height = 76 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 92 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 873 , width = 600 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 93,  x = 320, y = 623, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 773 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 500 , y = 636 , width = 130 , height = 77 , padding = 20 },
        { type =  NOVICE_TYPE["sim_touch"], x = 320 , y = 873},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 500 , y = 636 , width = 130 , height = 77 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 94,  x = 500, y = 386, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 500 , y = 536 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 183 , y = 571 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["sim_touch"], x = 500 , y = 636},
        { type =  NOVICE_TYPE["network_sync"], msg_name = "recruit_mercenary_ret" }
    },    
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , transition_time = 3 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 75 , y = 38 , width = 150 , height = 76 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 95,  x = 79, y = 324, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 79 , y = 174 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 75 , y = 38 , width = 150 , height = 76 , padding = 20 },
        { type =  NOVICE_TYPE["sim_touch"], x = 75 , y = 38},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0 , x = 320 , y = 873 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["text"], content_id = 96,  x = 100, y = 418, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 100 , y = 568 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 595 , y = 782 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["sim_touch"], x = 75 , y = 38},
    }, 
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 595 , y = 782 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 97,  x = 535, y = 1035, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 516 , y = 880 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["sim_touch"], x = 595 , y = 782},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 98 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 75 , y = 38 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 98 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 75 , y = 38 , width = 150 , height = 76 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000020  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 98 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 130 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 53,  x = 270, y = 675, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 785 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 318 , y = 173 , width = 310 , height = 85 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 934},
    },
    -- 推荐上阵
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 318 , y = 173 , width = 310 , height = 85 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 99,  x = 328, y = 365, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 318 , y = 270 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 435 , y = 690 , width = 220 , height = 80 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 318, y = 180},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 435 , y = 690 , width = 220 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 100,  x = 445, y = 420, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 435 , y = 570 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type = NOVICE_TYPE["sim_touch"], x = 435, y = 690},
    }
 )

--宿命武器功能
novice_sub_scene:AddGroup(6, solve_event_cond.New(1000013),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000041 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 101 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 101 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 102 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 102 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 102 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 103 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 103 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 103 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000041 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 104 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 104 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 104 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 592 , width = 620 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 592 , width = 620 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 105,  x = 320, y = 342, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 492 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000041 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 592},
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 106 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 106 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 107 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 107 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 327 , width = 578 , height = 179 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 107  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 565 , width = 630 , height = 725 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 108,  x = 320, y = 205, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 465 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 37 , y = 171 , width = 250 , height = 90 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 565},
        { type =  NOVICE_TYPE["network_sync"], msg_name = "choose_destiny_weapon_ret" },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 109  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 109 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 110 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 36 , y = 74 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 110  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000041  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 110 },
    }, 
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 18,  x = 162, y = 300, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 158 , y = 151 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 158 , y = 51 , width = 130, height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 151, y = 53 },
    }
)

--竞技场功能
novice_sub_scene:AddGroup(7, open_panel_cond.New(NOVICE_MARK["pvp_sub_scene"]),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "change_novice_mark_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000032 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 111 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 111 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 112 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 112 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 112 },
    },

    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 420 , width = 587 , height = 164 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 113,  x = 320, y = 188, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 338 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000032 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 438},
        { type = NOVICE_TYPE["network_sync"], msg_name = "query_arena_rival_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 114 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 114 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 115 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 115 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 115 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 116 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 116 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 116 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000032 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 117 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 117 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 118 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 118 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 119 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 119 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 120 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 1032 , width = 510 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 120 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 482 , y = 253 , width = 272 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 121 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 482 , y = 253 , width = 272 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 121  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 72 , y = 253 , width = 272 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 122 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 72 , y = 253 , width = 272 , height = 74 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 122 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 566 , y = 895 , width = 105 , height = 95 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 123 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 566 , y = 895 , width = 105 , height = 95 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 123 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 566 , y = 895 , width = 105 , height = 95 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 123 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 566 , y = 895 , width = 105 , height = 95 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 124,  x = 566, y = 761, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 566 , y = 811 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 566 , y = 911 , width = 105 , height = 95 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 566, y = 911},
    }
)

--矿区功能+宿命强化+普通强化前期引导
novice_sub_scene:AddGroup(8, solve_event_cond.New(1000018),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 125 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 125 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 126  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 126 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 127 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 127 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 127 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 100,  x = 265, y = 253, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 265 , y = 153 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 607 , width = 620 , height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 265, y = 53},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 160 , y = 860 , width = 330 , height = 310 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 128,  x = 160, y = 930, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 160 , y = 760 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 160 , y = 860 , width = 330 , height = 310 , padding = 20 },
        { type = NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 160, y = 860},
        { type = NOVICE_TYPE["network_sync"], msg_name = "query_mining_block_info_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 607 , width = 620 , height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 129 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 607 , width = 620 , height = 900 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 129 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 152 , y = 672 , width = 104 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 129 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 152 , y = 672 , width = 104 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 130,  x = 152, y = 872, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 152 , y = 772 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 152 , y = 672 , width = 104 , height = 104 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 152, y = 672},
        { type = NOVICE_TYPE["network_sync"], msg_name = "dig_block_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 152 , y = 672 , width = 104 , height = 104 , padding = 20 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "collect_mine_ret"},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 208 , y = 616 , width = 104 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 131,  x = 208, y = 816, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 208 , y = 716 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 208 , y = 616 , width = 104 , height = 104 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 208, y = 616},
        { type = NOVICE_TYPE["network_sync"], msg_name = "dig_block_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 208 , y = 616 , width = 104 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "collect_mine_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 132 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 132 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 133 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 133 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 134 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 134 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 135 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 135 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 136 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 136 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 137 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 137 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 137 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 138,  x = 320, y = 570, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 720 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 72 , y = 690 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 820},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 72 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 139,  x = 72, y = 490, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 72 , y = 640 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 598 , y = 873 , width = 200 , height = 100 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 72, y = 740},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 598 , y = 873 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 140,  x = 438, y = 623, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 438 , y = 783 , rotation = 135 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 598, y = 873},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 141 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 141 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 142 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 142 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 143 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 143 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 144 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 144 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 145 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 145 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 146 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 665 , width = 548 , height = 402 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 146 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 543 , width = 548 , height = 158 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 147 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 543 , width = 548 , height = 158 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 147 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 446 , y = 293 , width = 250 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 147 },
    },

    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 446 , y = 293 , width = 250 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 148,  x = 446, y = 93, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 446 , y = 193 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 446, y = 293},
        { type = NOVICE_TYPE["network_sync"], msg_name = "forge_destiny_weapon_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 149 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 149 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 593 , y = 892 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 149 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 593 , y = 892 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 76,  x = 446, y = 992, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 543 , y = 942 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 593 , y = 892 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 593, y = 892},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 150 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 150 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 150 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 196 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 151,  x = 196, y = 490, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 196 , y = 640 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 575 , y = 805 , width = 130 , height = 70 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 196, y = 740},
    },
        --mask_info = { alpha = 0.7 , x = 320 , y = 930 , width = 620 , height = 290 , padding = 20 },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 598 , y = 873 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 140,  x = 438, y = 623, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 438 , y = 783 , rotation = 135 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 568 , width = 618 , height = 715 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
        { type = NOVICE_TYPE["sim_touch"], x = 598, y = 873},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 152 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 152 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 540 , width = 534 , height = 210 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 153 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 540 , width = 534 , height = 210 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 153 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 343 , width = 250 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 153 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 343 , width = 250 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 154,  x = 320, y = 143, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 243 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 343},
        { type = NOVICE_TYPE["network_sync"], msg_name = "forge_mercenary_weapon_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 , transition_time = 1 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 155 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 155 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 156 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 156 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 157 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 157 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 588 , y = 856 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 157 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 588 , y = 856 , width = 91 , height = 85 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 76,  x = 588, y = 656, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 588 , y = 756 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 588, y = 856},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 128,  x = 265, y = 253, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 265 , y = 153 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 607 , width = 620 , height = 900 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 265, y = 53},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 607 , width = 620 , height = 900 , padding = 20 },
    }
)

--觉醒功能
novice_sub_scene:AddGroup(10, solve_event_cond.New(1000020),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000042 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 158 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 158 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 158 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 159 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 159 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 159 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000042 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 160 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 160 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 160  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 820 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 138,  x = 320, y = 570, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 720 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 72 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 820},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 72 , y = 740 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 139,  x = 181, y = 490, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 181 , y = 640 , rotation = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 46 , y = 873 , width = 200 , height = 100 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 72, y = 740 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 46 , y = 873 , width = 200 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 161,  x = 66, y = 623, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 46 , y = 773 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 46, y = 873},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 162 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 162 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 163 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 163 },
    },
        {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 164 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 164 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 165 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 165 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 166 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 166 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 167  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 167 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 168 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 168 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 508 , width = 520 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000042  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 168 },
    }
)

--天空神殿功能
novice_sub_scene:AddGroup(12, solve_event_cond.New(1000025),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 15000009 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 169 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 169 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 170 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 170 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 171 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 480 , y = 39 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 171 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 480 , y = 39 , width = 124 , height = 138 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 171 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 480 , y = 39 , width = 124 , height = 138 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 86,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 401 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 340 , width = 576 , height = 154 , padding = 20 },
        { type =  NOVICE_TYPE["sim_touch"], x = 480 , y = 39},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 340 , width = 576 , height = 154 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 172,  x = 320, y = 590, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 440 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 629 , width = 620 , height = 770 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 15000009 },
        { type =  NOVICE_TYPE["sim_touch"], x = 320 , y = 340},
        { type =  NOVICE_TYPE["network_sync"], msg_name = "query_temple_mercenary_ret"},
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 629 , width = 620 , height = 770 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 173 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 629 , width = 620 , height = 770 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 173 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 174 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 174 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 175 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 175 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 176 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 176 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 15000009  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 177 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 177 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 416 , y = 170 , width = 474 , height = 52 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 177 },
    }
)

--天梯功能
novice_sub_scene:AddGroup(13, solve_event_cond.New(1000030),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000015 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 178 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 178 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 179 },
    },

    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 179 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 179 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 180 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 180 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 180 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000015 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 181 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 181 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 181 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 182,  x = 372, y = 253, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 372 , y = 153 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 700 , width = 587 , height = 163 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 372, y = 53},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 700 , width = 587 , height = 163 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 183,  x = 320, y = 356, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 456 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000015 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 626},
        { type = NOVICE_TYPE["network_sync"], msg_name = "query_ladder_info_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 184 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 184 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 185 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 185 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 186 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 186 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 187 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 187 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 188 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 188 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 189 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 318 , y = 1035 , width = 500 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 189 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 608 , y = 1035 , width = 100 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 190 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 608 , y = 1035 , width = 100 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 190 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 608 , y = 1035 , width = 100 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 191 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 608 , y = 1035 , width = 100 , height = 65 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 191 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 9 , y = 281 , width = 100 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 192 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 9 , y = 281 , width = 100 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 192  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 17 , y = 1035 , width = 84 , height = 62 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 193 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 17 , y = 1035 , width = 84 , height = 62 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 193 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 17 , y = 1035 , width = 84 , height = 62 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000015  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 193 },
    }
)

--工坊功能，神力矿工包使用
novice_sub_scene:AddGroup(14, solve_event_cond.New(1000031),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 194 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 194 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 195 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 195 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 196 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 196 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 196 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 265 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 128,  x = 265, y = 253, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 265 , y = 153 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 265, y = 53},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 160 , y = 860 , width = 330 , height = 320 , padding = 20 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 160 , y = 700 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 160 , y = 860 , width = 330 , height = 320 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 160, y = 860},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 159 , y = 1022 , width = 298 , height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 197,  x = 159, y = 822, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 159 , y = 922 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
        { type = NOVICE_TYPE["sim_touch"], x = 159, y = 1022},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 198 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 198 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 198 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 199,  x = 512, y = 434, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 512, y = 684},
        { type = NOVICE_TYPE["network_sync"], msg_name = "use_mining_tool_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 200,  x = 512, y = 434, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 512, y = 684},
        { type = NOVICE_TYPE["network_sync"], msg_name = "use_mining_tool_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 201,  x = 512, y = 434, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 512, y = 684},
        { type = NOVICE_TYPE["network_sync"], msg_name = "use_mining_tool_ret" },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 688 , width = 550 , height = 234 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 202,  x = 512, y = 434, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 512 , y = 584 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 588 , y = 921 , width = 97 , height = 80 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 512, y = 684},
        { type = NOVICE_TYPE["network_sync"], msg_name = "use_mining_tool_ret" },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 588 , y = 921 , width = 97 , height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 76,  x = 588, y = 721, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 588 , y = 821 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 588 , y = 921 , width = 0 , height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 588, y = 921},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 203 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 203 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 204 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 482 , y = 191 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 204 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 482 , y = 191 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 204 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 482 , y = 191 , width = 100 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 205,  x = 482, y = 391, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 482 , y = 291 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 650 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
        { type = NOVICE_TYPE["sim_touch"], x = 482, y = 191},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 650 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 206 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 650 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 206 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 650 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 207 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 650 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 207 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 486 , y = 835 , width = 246 , height = 85 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 207 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 486 , y = 835 , width = 246 , height = 85 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 208,  x = 486, y = 635, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 486 , y = 735 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 567 , width = 610 , height = 761 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
        { type = NOVICE_TYPE["sim_touch"], x = 486, y = 835},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 567 , width = 610 , height = 761 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 209 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 567 , width = 610 , height = 761 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 209 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 210 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 210 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 211 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 211 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 212 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 212 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 213 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 593 , width = 486 , height = 263 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 213 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 803 , width = 486 , height = 137 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 214 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 803 , width = 486 , height = 137 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 214 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 375 , width = 486 , height = 137 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 215 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 375 , width = 486 , height = 137 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 215 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 449 , y = 267 , width = 260 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 215 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 449 , y = 267 , width = 260 , height = 90 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 216,  x = 449, y = 467, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 449 , y = 367 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 830 , width = 630 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
        { type = NOVICE_TYPE["sim_touch"], x = 449, y = 267},
        { type = NOVICE_TYPE["network_sync"], msg_name = "add_mining_project_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 830 , width = 630 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 217 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 830 , width = 630 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 217 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 375 , width = 486 , height = 137 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 217 },
    }
)

--难度引导，以及介绍4维
novice_sub_scene:AddGroup(20, solve_event_cond.New(1000035),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 218 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 218 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 219 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 53 , y = 1042 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 219 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 53 , y = 1042 , width = 196 , height = 114 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 219 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 53 , y = 1042 , width = 196 , height = 114 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 220,  x = 53, y = 792, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 53 , y = 942 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 156 , y = 879 , width = 300 , height = 89 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 53, y = 1042},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 156 , y = 879 , width = 300 , height = 89 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 221,  x = 156, y = 629, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 156 , y = 779 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 106 , y = 870 , width = 180 , height = 180 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 156, y = 879},
        --{ type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 106 , y = 870 , width = 180 , height = 180 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 222,  x = 106, y = 670, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 106 , y = 770 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 106 , y = 870 , width = 0 , height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 106, y = 870},
        { type = NOVICE_TYPE["network_sync"], msg_name = "enter_adventure_maze_ret" },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 223 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 223 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 224 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 224 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 225 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 226 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 226 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 226 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 501, y = 287, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 934 , width = 630 , height = 130 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 53,  x = 270, y = 675, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 785 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 180 , y = 235 , width = 320 , height = 69 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 934},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 180 , y = 235 , width = 320 , height = 69 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 227 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 180 , y = 235 , width = 320 , height = 69 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 227 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 85 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 228 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 85 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 228 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 145 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 229 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 145 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 229 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 210 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 230 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 210 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 230 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 275 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 231 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 275 , y = 235 , width = 85 , height = 66 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 231 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 180 , y = 235 , width = 320 , height = 69 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 231 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 180 , y = 235 , width = 320 , height = 69 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 232,  x = 200, y =481, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 200 , y = 331 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 200, y = 231},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000043  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 233 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 233 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 234 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 234 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 235 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 235 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 520 , width = 610 , height = 558 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 18000043  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 235 },
    }

)


--商会功能
--[[
novice_sub_scene:AddGroup(15, solve_event_cond.New(1000045),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 16000006 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 236 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 236 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 237 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 55 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 237 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 55 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 237 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 55 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 238,  x = 155, y = 203, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 105 , y = 103 , rotation = 315 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 268 , y = 886 , width = 115 , height = 115 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 55, y = 53},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 268 , y = 886 , width = 115 , height = 115 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 239,  x = 268, y = 636, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 268 , y = 786 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 16000006 },
        { type = NOVICE_TYPE["sim_touch"], x = 268, y = 886},
        { type = NOVICE_TYPE["network_sync"], msg_name = "query_merchant_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 240 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 240 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 241 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 241 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 242 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 242 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 243 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 570 , width = 620 , height = 554 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 243 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 244 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 244 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 245 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 245 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 246 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 246 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 320 , y = 906 , width = 620 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 16000006  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 246 },
    }
)
]]
--第一次战斗失败
novice_sub_scene:AddGroup(16, first_battle_failure_cond.New(),
    --战斗结束收尾，进入新地图
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 , x = 77 , y = 171 , width = 174 , height = 90 , padding = 20 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 543 , y = 193 , width = 230 , height = 104 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 48,  x = 420, y = 450, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 443 , y = 303 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 543 , y = 193},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 35,  x = 520, y = 616, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 520 , y = 766 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 866 , width = 640 , height = 124 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 520 , y = 866},
        { type = NOVICE_TYPE["network_sync"], msg_name = "alloc_mercenary_exp_ret" },
    }
)

--第一次遇到巨魔雕像
novice_sub_scene:AddGroup(17, first_discover_golem_cond.New(),
    --战斗结束收尾，进入新地图
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000031 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000031  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 247 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 247 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000031  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 247 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 248 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 248 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 248 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000060 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 249 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 249 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 250 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 250 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 251 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 251 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 252 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 252 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000060  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 253 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 253 },
    }
)

--解雇功能开启
novice_sub_scene:AddGroup(19, solve_event_cond.New(1000021),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = "leader"  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 254 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 254 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 255 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 255 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 255 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 586 , y = 53 , width = 124 , height = 124 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 52,  x = 420, y = 292, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 501 , y = 137 , rotation = 225 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 478 , width = 620 , height = 134 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 586, y = 53 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 478 , width = 620 , height = 134 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 256,  x = 320, y = 228, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 378 , rotation = 90},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 478 , width = 0 , height = 0 , padding = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 478 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 11000019  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 257 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 257 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 300 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 258 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 300 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 258 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 300 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 259 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 300 , height = 100 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 259 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 132 , y = 990 , width = 0 , height = 0 , padding = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 260 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 260 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 11000019  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 260},
    }
)

------契约进化功能
novice_sub_scene:AddGroup(27,---编号不能重复，加在引导前的
    open_panel_cond.New(NOVICE_MARK["mercenary_contract_sub_scene"]),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "change_novice_mark_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 261 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 261  },
    },-----说完话等待操作
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 261 },
    },
     {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 262 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 262 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 262 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 420, height = 70 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 100,  x = 325, y = 660, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 580 , rotation = 270 , scale = 0.5},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 530 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 263 },
    },
    { auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 263 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 264 },
    },

    { 
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 264 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 265 },
    },
    { auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 265 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 265 },
    }
)

------灵力转移功能
novice_sub_scene:AddGroup(29, open_panel_cond.New(NOVICE_MARK["transmigration_sub_scene"]),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "change_novice_mark_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 266 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 266  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 267 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 267 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 780 , width = 450, height = 295 , padding = 20},
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 268 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 780 , width = 450, height = 295 , padding = 20},
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 268 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 450 , width = 450, height = 300 , padding = 20 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 269 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7, x = 320 , y = 450 , width = 450, height = 300 , padding = 20 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 269 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = true, content_id = 270 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 270 },
    }
)

------重新召唤功能
--
novice_sub_scene:AddGroup(30, open_panel_cond.New(NOVICE_MARK["mercenary_library_sub_scene"]),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["network_sync"], msg_name = "change_novice_mark_ret" },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "leader"  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 271 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 271 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 271 },
    },

    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 272 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 272 },
    },-----说完话等待操作
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 272 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 70 , y = 961 , width = 150 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 100,  x = 70, y = 1090, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 70 , y = 1031 , rotation = 270 , scale = 0.5 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 70, y = 961 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 600 , y = 35 , width = 250, height = 80 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 100,  x = 600, y = 185, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 580 , y = 95 , rotation = 270 , scale = 0.5},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
        { type = NOVICE_TYPE["sim_touch"], x = 600, y = 35 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 273 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 273 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id ="leader" },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 273 },
    }
    -- {
    --     auto_play_next_step = false,
    --     mask_info = { alpha = 0.9 , x = 430 , y = 870 , width = 240, height = 80 , padding = 20 },
    --     { type =  NOVICE_TYPE["text"], content_id = 274,  x = 430, y = 1010, width = 100, height = 100 },
    --     { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 430 , y = 930 , rotation = 270 , scale = 0.5},
    -- },
    -- {
    --     auto_play_next_step = true,
    --     mask_info = { alpha = 0 },
    --     { type = NOVICE_TYPE["sim_touch"], x = 430, y = 870},
    -- }
)
--]]

-- 合战新手引导, 28-5开启
novice_sub_scene:AddGroup(31, solve_event_cond.New(1000320),
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = "19000032"  },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 182,  x = 372, y = 253, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 372 , y = 153 , rotation = 270 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 372 , y = 53 , width = 112 , height = 116 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 372, y = 53},
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 , x = 320 , y = 775 , width = 560 , height = 150 , padding = 20 },
        { type =  NOVICE_TYPE["text"], content_id = 275,  x = 320, y = 588, width = 100, height = 100 },
        { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 750 , rotation = 90 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 , x = 320 , y = 775 , width = 560 , height = 150 , padding = 20 },
        { type = NOVICE_TYPE["sim_touch"], x = 320, y = 800},
        -- { type = NOVICE_TYPE["network_sync"], msg_name = "query_arena_rival_ret"},
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type = NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000032 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 276 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 276 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7  },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 277 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 277 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 278 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 278 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 279 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 279  },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 280 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 280 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 281 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 281 },
    },
    {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_talk", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_enter", is_loop = false, content_id = 282 },
    },
    {
        auto_play_next_step = false,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_loop", is_loop = true, content_id = 282 },
    },
        {
        auto_play_next_step = true,
        mask_info = { alpha = 0.7 },
        { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000032  },
        { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 283 },
    }
)

return novice_sub_scene
