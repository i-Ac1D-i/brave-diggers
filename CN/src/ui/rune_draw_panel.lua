local config_manager = require "logic.config_manager"
local resource_logic = require "logic.resource"
local constants = require "util.constants"
local audio_manager = require "util.audio_manager"

local graphic = require "logic.graphic"

local panel_prototype = require "ui.panel"
local panel_util = require "ui.panel_util"
local client_constants = require "util.client_constants"
local lang_constants = require "util.language_constants"
local spine_manager = require "util.spine_manager"
local rune_logic = require "logic.rune"
local escort_logic = require "logic.escort"
local JUMP_CONST = client_constants["JUMP_CONST"] 
local rune_config = config_manager.rune_config
local rune_draw_config = config_manager.rune_draw_config

local PLIST_TYPE = ccui.TextureResType.plistType

local NEW_RUNE_BEZIER_POSITION = { x = 320, y = 600 }
local NEW_RUNE_INIT_POSITION = { x = 320, y = 400 }

local RUNE_RECEIVE_POSITION = { x = 90, y = 625 }
local SPINE_POSITION = { x = 320, y = 410 }

local DRAW_PLATFORM_OFFSET = 200
local DRAW_PLATFORM_SCALE = 2

local DRAW_PLATFORM_SPRITE = client_constants["DRAW_PLATFORM_SPRITE"]

local PLATFROM_NUM_TEXT = {
    [1] = "I",
    [2] = "II",
    [3] = "III",
    [4] = "IV",
    [5] = "V",
}

local BAG_CELL_COL = 5

local rune_sub_panel = panel_prototype.New()
rune_sub_panel.__index = rune_sub_panel

function rune_sub_panel.New()
    return setmetatable({}, rune_sub_panel)
end

function rune_sub_panel:Init(root_node)
    self.root_node = root_node
    self.icon_img = self.root_node:getChildByName("rune_icon")
    self.bg_img = self.root_node:getChildByName("graph")
    self.name_txt = self.root_node:getChildByName("rune_name_txt")

    self.top_quality_icon = self.root_node:getChildByName("top_quality")
    self.equipped_icon = self.root_node:getChildByName("equipped_icon")
    self.level_text = self.root_node:getChildByName("level")
    self.level_text:setLocalZOrder(1)
    panel_util:SetTextOutline(self.level_text, 0x000, 2)

    self.top_quality_icon:setVisible(false)
    self.equipped_icon:setVisible(false)
    self.level_text:setVisible(false)

    self.spine_node = spine_manager:GetNode("fuwen", 1.0, true)
    self.spine_node:setScale(2)
    self.spine_node:setPosition(cc.p(self.root_node:getContentSize().width / 2, self.root_node:getContentSize().height / 2))
    self.root_node:addChild(self.spine_node)
    self.spine_node:setTimeScale(1.0)
end

function rune_sub_panel:Show(rune_info)
    self.rune_info = rune_info
    
    self.icon_img:loadTexture(self.rune_info.template_info.icon, PLIST_TYPE)
    self.name_txt:setString(self.rune_info.template_info.name)
    self.level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))
    self.name_txt:setVisible(true)
    self.level_text:setVisible(true)
    self.top_quality_icon:setVisible(self.rune_info.template_info.quality == constants["MAX_RUNE_QUALITY"])

    self.root_node:setVisible(true)
end

function rune_sub_panel:ShowNewRuneAnimation(rune_info, final_pos, call_back)
    self:Show(rune_info)
    self.name_txt:setVisible(false)
    self.level_text:setVisible(false)

    self.root_node:setLocalZOrder(20)
    self.root_node:setPosition(NEW_RUNE_INIT_POSITION)
    self.root_node:setVisible(true)

    self.bg_img:setOpacity(0)
    self.icon_img:setOpacity(0)
    self.top_quality_icon:setOpacity(0)

    self.bg_img:runAction(cc.FadeIn:create(0.3))
    self.icon_img:runAction(cc.FadeIn:create(0.3))
    self.top_quality_icon:runAction(cc.FadeIn:create(0.3))

    self.root_node:runAction(cc.Sequence:create( 
                                                cc.EaseIn:create(cc.BezierTo:create(0.5, {NEW_RUNE_BEZIER_POSITION, final_pos, final_pos}), 1.5),
                                                cc.CallFunc:create(function()
                                                    self.root_node:setLocalZOrder(10)
                                                    self.name_txt:setVisible(true)
                                                    self.level_text:setVisible(true)
                                                    if call_back then
                                                        call_back()
                                                    end
                                                end)
                                                )
                            )
end

function rune_sub_panel:ShowReceiveAnimation()
    self.root_node:stopAllActions()
    self.name_txt:setVisible(false)
    self.level_text:setVisible(false)

    self.root_node:setLocalZOrder(20)

    self.bg_img:runAction(cc.FadeOut:create(0.3))
    self.icon_img:runAction(cc.FadeOut:create(0.3))
    self.top_quality_icon:runAction(cc.FadeOut:create(0.3))
    self.receive_action = cc.Sequence:create( 
                            cc.EaseIn:create(cc.MoveTo:create(0.3, RUNE_RECEIVE_POSITION), 1.5),
                            cc.CallFunc:create(function()
                                self.receive_action = nil
                                self.root_node:removeFromParent()
                            end)
                            )
    self.root_node:runAction(self.receive_action)
end

function rune_sub_panel:ShowMovePosAnimation(new_pos, is_disapper, call_back)
    if self.receive_action then
        self.root_node:stopActionByTag(self.receive_action)
        self.receive_action = nil
    end
    self.name_txt:setVisible(false)
    self.level_text:setVisible(false)

    self.root_node:setLocalZOrder(20)

    if is_disapper then
        self.bg_img:runAction(cc.FadeOut:create(0.5))
        self.icon_img:runAction(cc.FadeOut:create(0.5))
        self.top_quality_icon:runAction(cc.FadeOut:create(0.5))
    end

    self.root_node:runAction(cc.Sequence:create( 
                                                cc.EaseIn:create(cc.MoveTo:create(0.5, new_pos), 1.5),
                                                cc.CallFunc:create(function()
                                                    if is_disapper then
                                                        self.root_node:removeFromParent()
                                                    else
                                                        self.root_node:setLocalZOrder(10)
                                                        self.name_txt:setVisible(true)
                                                        self.level_text:setVisible(true)
                                                        self.level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))
                                                    end
                                                    if call_back then
                                                        call_back()
                                                    end
                                                end)
                                                )
                            )
end

function rune_sub_panel:ShowUpgradeAnimation(exp, level, call_back)
    self.spine_node:setAnimation(0, "upgrade", false)
    self.rune_info.exp = exp
    self.rune_info.level = level
    self.level_text:setString(string.format(lang_constants:Get("rune_level"), self.rune_info.level))

    if call_back then
        self.spine_node:registerSpineEventHandler(function(event)
            call_back()           
        end, sp.EventType.ANIMATION_COMPLETE)
    end
end

local draw_platform_sub_panel = panel_prototype.New()
draw_platform_sub_panel.__index = draw_platform_sub_panel

function draw_platform_sub_panel.New()
    return setmetatable({}, draw_platform_sub_panel)
end

function draw_platform_sub_panel:Init(root_node, index)
    self.root_node = root_node
    self.platform_img = cc.Sprite:createWithSpriteFrameName(DRAW_PLATFORM_SPRITE[index])
    self.platform_img:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
    self.platform_img:setPosition(cc.p(0,35))

    self.root_node:addChild(self.platform_img)

end

local rune_draw_panel = panel_prototype.New(true)
function rune_draw_panel:Init(root_node)
    self.root_node = cc.CSLoader:createNode("ui/rune_draw_panel.csb")
    
    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/ui/entrust.plist")

    local title_node = self.root_node:getChildByName("title_bg")
    self.rune_name_text = title_node:getChildByName("rune_change")
    self.rune_desc_text = self.root_node:getChildByName("rune_desc")
    self.crystal_all_text = self.root_node:getChildByName("reward_value_0")

    self.go_node = self.root_node:getChildByName("Image_250")
    self.go_to_4_node = self.root_node:getChildByName("Image_252")

    self.go_cost_text = self.go_node:getChildByName("Text_68")
    self.go_to_4_cost_text = self.go_to_4_node:getChildByName("Text_70")

    panel_util:SetTextOutline(self.go_cost_text, 0x000, 2)
    panel_util:SetTextOutline(self.go_to_4_cost_text, 0x000, 2)

    self.back_btn = self.root_node:getChildByName("back_btn")
    self.setup_btn = self.root_node:getChildByName("levelup_btn")
    self.receive_btn = self.root_node:getChildByName("set_btn")
    self.go_btn = self.root_node:getChildByName("go")
    self.go_to_4_btn = self.root_node:getChildByName("go_to_area4")
    self.go_to_4_text = self.root_node:getChildByName("go_to_area4_txt")

    self.rune_template = self.root_node:getChildByName("rune_panel")
    self.rune_template:setVisible(false)

    self.draw_platform_scrollview = self.root_node:getChildByName("ScrollView_1")

    self.bag_cell_prototype = self.root_node:getChildByName("rune_box")
    self.bag_cell_tmp = self.root_node:getChildByName("rune_box_0")
    self.bag_cell_selected = self.root_node:getChildByName("select")

    self.bag_cell_prototype:setVisible(false)
    self.bag_cell_tmp:setVisible(false)
    self.bag_cell_selected:setVisible(false)
    self.bag_cell_selected:setLocalZOrder(15)

    self.auto_go_btn = self.root_node:getChildByName("10times_btn")
    self.auto_go_select_img = self.root_node:getChildByName("yes_icon")

    self.auto_compose_btn = self.root_node:getChildByName("auto_btn")
    self.auto_compose_select_img = self.root_node:getChildByName("yes_icon_0")

    self.rule_btn = self.root_node:getChildByName("rule_btn")
    self.platform_text = self.root_node:getChildByName("Text_139")

    self.ore_bag_btn = self.root_node:getChildByName("add_area_btn")

    self.rune_list = {}
    self.bag_cell_pos = {}
    self.rune_sub_panels = {}
    self.draw_platform_sub_panels = {}

    self.spine_node = spine_manager:GetNode("fuwen", 1.0, true)
    self.spine_node:setAnimation(0, "stand", true)
    self.spine_node:setPosition(SPINE_POSITION)
    self.root_node:addChild(self.spine_node)
    self.spine_node:setScale(1.5)
    self.spine_node:setTimeScale(1.0)

    self:RegisterEvent()
    self:RegisterWidgetEvent()
    self:CreateRuneBag()
    self:CreateDrawPlatform()
end

function rune_draw_panel:Show()
    self.root_node:setVisible(true)
    
    self:SetAutoGoSelected(rune_logic:IsSelectedAutoGo())
    self:SetAutoComposeSelected(rune_logic:IsSelectedAutoCompose())
    self:ShowRunes()
    self:UpdateDrawPlatformSacle()

    self.cur_draw_platform_id = rune_logic:GetCurDrawPlatformId()
    self:MoveToDrawPlatform(self.cur_draw_platform_id, false)
    
    self:RefreshGoToArea4BtnVisible()
    self:RefreshResource()
    self:RefreshCost()
    
    self.ten_number = 0
    rune_logic:SetDrawState(false)
    rune_logic:SetIsMovingState(false)
    -- 资源跳转
    graphic:DispatchEvent("jump_finish",JUMP_CONST["rune"]) 
end

function rune_draw_panel:RefreshResource()
    local crystal = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["crystal"])
    self.crystal_all_text:setString(tostring(crystal))
end

function rune_draw_panel:RefreshCost()
    local crystal = resource_logic:GetResourceNum(constants.RESOURCE_TYPE["crystal"])
    local rune_draw_conf = rune_draw_config[self.cur_draw_platform_id]
    self.go_cost_text:setString(tostring(rune_draw_conf.cost_num))

    if crystal >= rune_draw_conf.cost_num then
        self.go_cost_text:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
    else
        self.go_cost_text:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["red"]))
    end
end

function rune_draw_panel:MoveToDrawPlatform(new_draw_platform_id, is_scroll_to, result, draw_type, go_to_area_4, new_rune_list)
    if not self.root_node:isVisible() then
        graphic:DispatchEvent("update_blood_diamond")
        return
    end

    if not (self.cur_draw_platform_id < 4 and go_to_area_4) then
        self.crystal_all_text:setString(tostring(tonumber(self.crystal_all_text:getString()) - rune_draw_config[self.cur_draw_platform_id].cost_num))
    else
        graphic:DispatchEvent("update_blood_diamond",-20)
    end
              
    local percent = (new_draw_platform_id - 1) * 100 / (constants["MAX_RUNE_PLATFORM_ID"] - 1)

    local speed_scale = (draw_type == "ten_times") and 0.25 or 1
 
    if is_scroll_to then
        self.spine_node:setAnimation(0, "eaquire", false)
        self.spine_node:setTimeScale(1 / speed_scale)

        local scroll_when_disapper = false
        if self.cur_draw_platform_id == 5 and new_draw_platform_id == 1 then
            self.spine_node:addAnimation(0, "man_clear", false)
            self.spine_node:addAnimation(0, "man_appear", false)
            scroll_when_disapper = true
        else
            self.spine_node:addAnimation(0, "jamp", false)
        end

        self.spine_node:registerSpineEventHandler(function(event)
                local animation_name = event.animation
                if animation_name == "eaquire" then
                    if not scroll_when_disapper then
                        performWithDelay(self.draw_platform_scrollview, function ()
                            self.draw_platform_scrollview:scrollToPercentHorizontal(percent, 0.3 * speed_scale, true)
                        end, 0.1 * speed_scale)
                    end
                elseif animation_name == "man_clear" then
                    self.draw_platform_scrollview:scrollToPercentHorizontal(percent, 0.3 * speed_scale, true)
                elseif animation_name == "jamp" or animation_name == "man_appear" then
                    if #new_rune_list == 0 then
                        self.spine_node:setTimeScale(1)
                        self.spine_node:setAnimation(0, "stand", true)
                    end

                    self.platform_text:setString(PLATFROM_NUM_TEXT[new_draw_platform_id])
                    self:RefreshCost()
                    self:ShowNewRuneAnimation(result, draw_type, go_to_area_4, new_rune_list) 
                end
            end, sp.EventType.ANIMATION_COMPLETE)
    else
        self.draw_platform_scrollview:jumpToPercentHorizontal(percent)
        self:UpdateDrawPlatformSacle()

        self.platform_text:setString(PLATFROM_NUM_TEXT[new_draw_platform_id])
    end

    self.cur_draw_platform_id = new_draw_platform_id
end

function rune_draw_panel:ShowRunes()
    self.rune_list = rune_logic:GetRuneTemporaryList()

    for index =1, rune_logic:GetRuneTemporaryBagCapacity() do
        local sub_panel = self.rune_sub_panels[index]
        local rune_info = self.rune_list[index]
        if rune_info then
            sub_panel:Show(rune_info)
        else
            sub_panel.root_node:setVisible(false)
        end
    end

    self:SetRuneSelectSprite()
end

function rune_draw_panel:SetAutoGoSelected( is_selected )
    self.auto_go_select_img:setVisible(is_selected)
    rune_logic:SetSelectedAutoGo(is_selected)
end

function rune_draw_panel:SetAutoComposeSelected( is_selected )
    self.auto_compose_select_img:setVisible(is_selected)
    rune_logic:SetSelectedAutoCompose(is_selected)
end

function rune_draw_panel:RefreshGoToArea4BtnVisible()
    local isEnable = (self.cur_draw_platform_id < 4 )
    if isEnable then
        self.go_to_4_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["write"]))
    else
        self.go_to_4_btn:setColor(panel_util:GetColor4B(client_constants["TEXT_COLOR"]["gray"]))
    end
end

function rune_draw_panel:SetRuneSelectSprite( index )
    if not index then
        if #self.rune_list > 0 then
            index = 1
        else
            index = 0
        end
    end

    if index > 0 and self.bag_cell_pos[index] then
        self.bag_cell_selected:setPosition(self.bag_cell_pos[index])
        self.bag_cell_selected:setVisible(true)
    else
        self.bag_cell_selected:setVisible(false)
    end
    self:ShowRuneDesc(index)
end

function rune_draw_panel:ShowRuneDesc( index )
    if index > 0 and self.rune_list[index] then
        self.rune_name_text:setString(self.rune_list[index].template_info.name)
        local desc_str = rune_logic:GetRunePropertysDesc(self.rune_list[index].template_id, self.rune_list[index].level)
        if desc_str ~= "" then
            desc_str = desc_str .. lang_constants:Get("comma")
        end
        self.rune_desc_text:setString(desc_str .. self.rune_list[index].template_info.desc)
    else
        self.rune_name_text:setString("")
        self.rune_desc_text:setString(lang_constants:Get("rune_draw_no_select_desc"))
    end
end

function rune_draw_panel:CreateRuneSubPanel(index)
    local sub_panel = rune_sub_panel.New()
    sub_panel:Init(self.rune_template:clone())
    sub_panel.root_node:setTag(index)
    sub_panel.root_node:setLocalZOrder(10)
    sub_panel.root_node:setPosition(self.bag_cell_pos[index])

    sub_panel.root_node:setTouchEnabled(true)
    sub_panel.root_node:addTouchEventListener(self.view_rune_content)
    self.root_node:addChild(sub_panel.root_node)

    return sub_panel
end

function rune_draw_panel:CreateRuneBag()
    local bag_init_x = self.bag_cell_tmp:getPositionX()
    local bag_init_y = self.bag_cell_prototype:getPositionY()
    local bag_offset_x = self.bag_cell_prototype:getPositionX() - bag_init_x
    local bag_offset_y = self.bag_cell_tmp:getPositionY() - bag_init_y

    for index = 1, rune_logic:GetRuneTemporaryBagCapacity() do
        local row = math.ceil(index / BAG_CELL_COL) - 1
        local col = index - row * BAG_CELL_COL - 1
        self.bag_cell_pos[index] = {x = (bag_init_x + bag_offset_x * col), y = (bag_init_y + bag_offset_y * row)}

        local bag_cell = self.bag_cell_prototype:clone()
        bag_cell:setVisible(true)
        bag_cell:setPosition(self.bag_cell_pos[index])
        self.root_node:addChild(bag_cell)

        local sub_panel = self:CreateRuneSubPanel(index)
        self.rune_sub_panels[index] = sub_panel
    end
end

function rune_draw_panel:CreateDrawPlatform()
    local size = self.draw_platform_scrollview:getContentSize()
    self.draw_platform_scrollview:setDirection(ccui.ScrollViewDir.horizontal)

    for index = 1, constants["MAX_RUNE_PLATFORM_ID"] do
        local sub_panel = draw_platform_sub_panel.New()
        local node = cc.Node:create()
        sub_panel:Init(node, index)
        node:setPosition(size.width * 0.5 + DRAW_PLATFORM_OFFSET * (index - 1), size.height * 0.4)
        self.draw_platform_scrollview:addChild(node)

        self.draw_platform_sub_panels[index] = sub_panel
    end

    self.draw_platform_scrollview:setInnerContainerSize(cc.size(size.width + DRAW_PLATFORM_OFFSET * (constants["MAX_RUNE_PLATFORM_ID"] - 1), size.height))
end

function rune_draw_panel:UpdateDrawPlatformSacle()
    local offsetX = self.draw_platform_scrollview:getInnerContainer():getPositionX()
    local size = self.draw_platform_scrollview:getContentSize()

    for index = 1, constants["MAX_RUNE_PLATFORM_ID"] do
        local sub_panel = self.draw_platform_sub_panels[index]
        local distance = math.abs(sub_panel.root_node:getPositionX() - size.width * 0.5 - math.abs(offsetX))

        if distance < DRAW_PLATFORM_OFFSET then
            sub_panel.root_node:setScale(DRAW_PLATFORM_SCALE - (DRAW_PLATFORM_SCALE - 1) * (distance / DRAW_PLATFORM_OFFSET))
        else
            sub_panel.root_node:setScale(1)
            sub_panel.root_node:setOpacity(0)
        end
    end
end

function rune_draw_panel:ShowNewRuneAnimation(result, draw_type, go_to_area_4, new_rune_list)
    if #new_rune_list > 0 then
        for empty_index = 1, rune_logic:GetRuneTemporaryBagCapacity() do
            local empty_sub_panel = self.rune_sub_panels[empty_index]
            if not self.rune_sub_panels[empty_index].rune_info then
                local draw_info = table.remove(new_rune_list, 1)
                if #new_rune_list <= 0 and draw_type == "ten_times" then
                    -- print("这是十连抽最后一个")

                    empty_sub_panel:ShowNewRuneAnimation(draw_info.rune_info, self.bag_cell_pos[empty_index],function() 
                        rune_logic:SetDrawState(false)
                        self:startMoreTenNewRune() 
                        end)
                else
                    empty_sub_panel:ShowNewRuneAnimation(draw_info.rune_info, self.bag_cell_pos[empty_index], empty_index == 1 and function() self:SetRuneSelectSprite(1) end)
                end 
                self:MoveToDrawPlatform(draw_info.new_platform_id, true, result, draw_type, go_to_area_4, new_rune_list)

                break
            end
        end
    else
        if result ~= "success" then
            self.ten_number = 0
            if result == "not_enough_resource" then
                resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["crystal"])
            elseif result == "not_enough_blood_diamond" then
                resource_logic:ShowLackResourcePrompt(constants.RESOURCE_TYPE["blood_diamond"])
            else
                graphic:DispatchEvent("show_prompt_panel", result)
            end
        else
            --SYY
            if draw_type ~= "ten_times" then
                self.ten_number = 0
            end
        end
        rune_logic:SetDrawState(false)
        self:RefreshGoToArea4BtnVisible()
        self:RefreshResource()
    end
end

--SYYSYY
--多次十连抽
function rune_draw_panel:startMoreTenNewRune()
    if not self.root_node:isVisible() then
        --判断界面是否显示如果不显示直接中断十连抽
        self.ten_number = 0
        return
    end 

    if self.ten_number > 0 then
        
        local state = rune_logic:OneKeyReceive()
        if not state then
            --临时背包是空的
            self.ten_number = self.ten_number - 1
            rune_logic:DrawRune("ten_times")
        end
    else
        self.ten_number = 0
        --多次十抽取的最后一次要进行收取背包
        if self.root_node:isVisible() then
            rune_logic:OneKeyReceive()
        end
        graphic:DispatchEvent("update_blood_diamond")
    end
end

--判断是否进行十连抽
function rune_draw_panel:IsTenNewRune(is_tips)

    if self.ten_number > 0  or rune_logic:GetDrawState() or rune_logic:GetIsMovingState() then
        --抽取中 抽取次数没有抽完，最后一次没有抽完
        if is_tips then
            graphic:DispatchEvent("show_prompt_panel", "is_drawing_rune")
        end
        return true
    end
    return false
end

function rune_draw_panel:RegisterEvent()
    graphic:RegisterEvent("update_resource_list", function(source)
        if not self.root_node:isVisible() then
            return
        end

        if resource_logic:IsResourceUpdated(constants.RESOURCE_TYPE["crystal"]) then
            if source and source ~= constants.REWARD_SOURCE["draw_rune"] then
                self:RefreshResource()
            end
        end
    end)

    graphic:RegisterEvent("new_rune_in_temporary_bag", function(result, draw_type, go_to_area_4, new_rune_list)
        if not self.root_node:isVisible() then
            rune_logic:SetDrawState(false)
            return
        end
        self.new_rune_list_number = #new_rune_list
        self:ShowNewRuneAnimation(result, draw_type, go_to_area_4, new_rune_list)
    end)
    
    graphic:RegisterEvent("receive_rune_to_bag", function(target_rune_info, exp_rune_id_list, move_rune_id_list, is_full)
        if not self.root_node:isVisible() then
            rune_logic:SetIsMovingState(false)
            return
        end

        self:SetRuneSelectSprite(0)

        local target_sub_panel
        if target_rune_info then
            for index,sub_panel in ipairs(self.rune_sub_panels) do
                if sub_panel.rune_info and sub_panel.rune_info.rune_id == target_rune_info.rune_id then
                    target_sub_panel = sub_panel
                    break
                end
            end
        end

        local function move_rune_to_bag()
            if move_rune_id_list and #move_rune_id_list > 0 then
                for _,move_rune_id in ipairs(move_rune_id_list) do
                    for index,sub_panel in ipairs(self.rune_sub_panels) do
                        if sub_panel.rune_info and sub_panel.rune_info.rune_id == move_rune_id then
                            sub_panel:ShowReceiveAnimation()
                            self.rune_sub_panels[index] = self:CreateRuneSubPanel(index)
                            break
                        end
                    end
                end
            end

            for empty_index = 1, rune_logic:GetRuneTemporaryBagCapacity() do
                local empty_sub_panel = self.rune_sub_panels[empty_index]
                if not self.rune_sub_panels[empty_index].rune_info then
                    local is_found_not_empty = false
                    for index = empty_index + 1, rune_logic:GetRuneTemporaryBagCapacity() do
                        local sub_panel = self.rune_sub_panels[index]
                        if sub_panel.rune_info then
                            sub_panel:ShowMovePosAnimation(self.bag_cell_pos[empty_index], false, empty_index == 1 and function() self:SetRuneSelectSprite(1) end)
                            sub_panel.root_node:setTag(empty_index)
                            empty_sub_panel.root_node:setTag(index)
                            self.rune_sub_panels[empty_index], self.rune_sub_panels[index] = sub_panel, empty_sub_panel
                            is_found_not_empty = true
                            break
                        end
                    end
                    if not is_found_not_empty then
                        break
                    end
                end
            end

            rune_logic:SetIsMovingState(false)
            if self.ten_number > 0 then
                --这个是进行多次十连抽
                if is_full then
                    self.ten_number = 0
                elseif self.root_node:isVisible() then
                    self.ten_number = self.ten_number - 1
                    rune_logic:DrawRune("ten_times")
                end
            end
        end

        if target_sub_panel and exp_rune_id_list and #exp_rune_id_list > 0 then
            local target_index = target_sub_panel.root_node:getTag()

            local function call_back() 
                target_sub_panel:ShowUpgradeAnimation(target_rune_info.exp, target_rune_info.level, move_rune_to_bag) 
            end

            for _,exp_rune_id in ipairs(exp_rune_id_list) do
                for index,sub_panel in ipairs(self.rune_sub_panels) do
                    if sub_panel.rune_info and sub_panel.rune_info.rune_id == exp_rune_id then
                        sub_panel:ShowMovePosAnimation(self.bag_cell_pos[target_index], true, call_back)
                        self.rune_sub_panels[index] = self:CreateRuneSubPanel(index)
                        call_back = nil
                        break
                    end
                end
            end
        else
            move_rune_to_bag()
        end
    end)
end

function rune_draw_panel:RegisterWidgetEvent()
    --点击背包符文格
    self.view_rune_content = function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --判断是否正在十连抽
            if not self:IsTenNewRune(true) then
                local index = widget:getTag()

                local sub_panel = self.rune_sub_panels[index]

                self:SetRuneSelectSprite(index)
            end
        end
    end

    --是否使用血钻抽取
    self.auto_go_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --判断是否正在十连抽
            if not self:IsTenNewRune(true) then
                if not rune_logic:IsSelectedAutoGo() and not rune_logic:IsSelectedAutoGoTips() then
                    local mode = client_constants.CONFIRM_MSGBOX_MODE["draw_rune_use_blood_tips"]

                    graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode, self.auto_go_select_img)
                else
                    self:SetAutoGoSelected( not rune_logic:IsSelectedAutoGo() )
                end
            end
        end
    end)

    --自动合成
    self.auto_compose_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --判断是否正在十连抽
            if not self:IsTenNewRune(true) then
                self:SetAutoComposeSelected( not rune_logic:IsSelectedAutoCompose() )
            end
        end
    end)

    --安装
    self.setup_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            --判断是否正在十连抽
            if not self:IsTenNewRune(true) then
                graphic:DispatchEvent("show_world_sub_scene", "rune_equip_sub_scene")
            end
        end
    end)

    --一键收取
    self.receive_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if rune_logic:GetDrawState() then
                graphic:DispatchEvent("show_prompt_panel", "is_drawing_rune")
            elseif rune_logic:GetIsMovingState() then
                graphic:DispatchEvent("show_prompt_panel", "is_moving_rune")
            elseif not self:IsTenNewRune(true) then
                --正在十连抽
                self.ten_number = 0
                rune_logic:OneKeyReceive()
            end
        end
    end)

    --抽取
    self.go_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if rune_logic:GetDrawState() then
                graphic:DispatchEvent("show_prompt_panel", "is_drawing_rune")
            elseif rune_logic:GetIsMovingState() then
                graphic:DispatchEvent("show_prompt_panel", "is_moving_rune")
            elseif not self:IsTenNewRune(true) then
                --判断是否正在十连抽
                self.ten_number = 0
                rune_logic:DrawRune("once", false)
            end
        end
    end)

    --跳至第四层
    self.go_to_4_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            if rune_logic:GetDrawState() then
                graphic:DispatchEvent("show_prompt_panel", "is_drawing_rune")
            elseif rune_logic:GetIsMovingState() then
                graphic:DispatchEvent("show_prompt_panel", "is_moving_rune")
            elseif not self:IsTenNewRune(true) then
                if self.cur_draw_platform_id < 4 then
                    if rune_logic:IsIgnoreGoToArea4Tip() then
                        rune_logic:DrawRune( "once", true )
                    else
                        local mode = client_constants.CONFIRM_MSGBOX_MODE["draw_rune_go_to_area_4"]
                        graphic:DispatchEvent("show_world_sub_panel", "confirm_msgbox", mode)
                    end
                else
                    graphic:DispatchEvent("show_prompt_panel", "already_after_area_4", self.cur_draw_platform_id)
                end
            end
        end
    end)

    self.draw_platform_scrollview:addEventListener(function(widget, event_type)
        if event_type == ccui.ScrollViewEventType.scrolling then
            self:UpdateDrawPlatformSacle()
        end
    end)

    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not self:IsTenNewRune(true) then
                graphic:DispatchEvent("show_world_sub_panel", "rune_rule_panel")
            end
        end
    end)

    self.ore_bag_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not self:IsTenNewRune(true) then
                graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel", 2, true)
            end
        end
    end)

    --多次十连抽
    self.back_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            if not self:IsTenNewRune(true) then
                local box_call = function (numbers)
                    if self.ten_number <= 0 then
                        self.ten_number = numbers / 10
                        self:startMoreTenNewRune()
                    end
                end
                graphic:DispatchEvent("show_world_sub_panel", "quick_store_msgbox", box_call, client_constants.QUICK_STORE_MSGBOX_TYPE["rune_more_ten"])
            end
        end
    end)
end

return rune_draw_panel

