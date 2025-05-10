local graphic = require "logic.graphic"
local panel_prototype = require "ui.panel"
local config_manager = require "logic.config_manager"
local audio_manager = require "util.audio_manager"

local constants = require "util.constants"
local client_constants = require "util.client_constants"
local title_panel = require "ui.title_panel"
local ladder_logic = require "logic.ladder"
local time_logic = require "logic.time"
local troop_logic = require "logic.troop"
local server_pvp_logic = require "logic.server_pvp"
local user_logic = require "logic.user"
local login_logic = require "logic.login"
local feature_config = require "logic.feature_config"
local panel_util = require "ui.panel_util"
local icon_template = require "ui.icon_panel"
local spine_manager = require "util.spine_manager"

local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local PLIST_TYPE = ccui.TextureResType.plistType
local TOWER_SPRITE = client_constants["SERVER_PVP_TOWER_SPRITE"]
local TOWER_HEIGHT = client_constants["SERVER_PVP_TOWER_HEIGHT"]
local PRICK_SPRITE = client_constants["SERVER_PVP_TOWER_PRICK_SPRITE"]
local PART_SPRITE_INFO = client_constants["SERVER_PVP_TOWER_PART_SPRITE_INFO"]

local LINE_OFFSET_X = 200
local PRICK_OFFSET_X = 200

local TOWER_TOP_OFFSET_Y = 90
local DIANTI_OFFSET_Y = 270

local RANK_ZORDER = 10
local CLOUD_ZORDER = 5
local PART_ZORDER = 1
local BG_ZORDER = -10
local STAR_ZORDER = -9
local LINE_ZORDER = -4
local PRICK_ZORDER = -5

local rank_sub_panel = panel_prototype.New()
rank_sub_panel.__index = rank_sub_panel

function rank_sub_panel.New()
    return setmetatable({}, rank_sub_panel)
end

function rank_sub_panel:Init(root_node)
    self.root_node = root_node

    self.challenge_btn = root_node
    self.challenge_btn:setTouchEnabled(true)
            
    self.bg = self.root_node:getChildByName("bg")
    self.bg1 = self.root_node:getChildByName("bg1")
    self.bg2 = self.root_node:getChildByName("bg2")
    self.bg3 = self.root_node:getChildByName("bg3")

    if self.bg then
        self.bg:setVisible(false)
    end
    if self.bg1 then
        self.bg1:setVisible(false)
    end
    if self.bg2 then
        self.bg2:setVisible(false)
    end
    if self.bg3 then
        self.bg3:setVisible(false)
    end

    self.rank_value = self.root_node:getChildByName("rank_value")

    self.leader_img = self.root_node:getChildByName("hero_0")
    self.leader_img:setScale(2)
    self.leader_img:ignoreContentAdaptWithSize(true)
    self.name_text = self.root_node:getChildByName("name")
    self.server_name_text = self.root_node:getChildByName("server_name")
    if feature_config:IsFeatureOpen("title") then
        local title_icon = self.root_node:getChildByName("title_icon")
        self.title = title_panel.New()
        self.title:Init(title_icon)
        self.title:Hide()
    else
        self.title_icon = self.root_node:getChildByName("title_icon")
        if self.title_icon then
            self.title_icon:setVisible(false) 
        end
    end

    self:RegisterWidgetEvent()
end

function rank_sub_panel:Show(rank_info)
    self.rank_info = rank_info
    
    if rank_info.rank == 1 then
        self.bg1:setVisible(true)
    elseif rank_info.rank == 2 then
        self.bg2:setVisible(true)
    elseif rank_info.rank == 3 then
        self.bg3:setVisible(true)
    else
        self.bg:setVisible(true)
    end

    if rank_info.rank <= 10 then
        self.rank_value:setScale(1.2)
    elseif rank_info.rank <= 99 then
        self.rank_value:setScale(1)
    elseif rank_info.rank <= 999 then
        self.rank_value:setScale(0.8)
    else
        self.rank_value:setScale(0.5)
    end

    self.rank_value:setString(self.rank_info.rank)

    if rank_info.rank > 3 and rank_info.rank <= 10 then
        local aircraft_spine_node = spine_manager:GetNode("pengke_ta", 1.0, true)
        aircraft_spine_node:setRotationSkewY(180)
        aircraft_spine_node:setPosition(cc.p(230, 70))
        aircraft_spine_node:setAnimation(0, string.format("feiting%d", math.random(3)), true)
        aircraft_spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])

        self.root_node:addChild(aircraft_spine_node, -1)
    end

    local server_info = config_manager.server_config[self.rank_info.server_id]
    local server_info = config_manager.server_config[self.rank_info.origin_server_id]
    if server_info then
        self.server_name_text:setString(server_info.name)
    else
        self.server_name_text:setString("")
    end

    local template_info = config_manager.mercenary_config[self.rank_info.template_id]
    self.leader_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. template_info.sprite .. ".png", PLIST_TYPE)
    self.name_text:setString(self.rank_info.leader_name)

    self.root_node:setVisible(true)
    if feature_config:IsFeatureOpen("title") then
        if rank_info.title_id and rank_info.title_id ~= 0 then
            self.title:Show()
            self.title:Load(rank_info.title_id)
        else
            self.title:Hide() 
        end
    end
end

function rank_sub_panel:RegisterWidgetEvent()
    --返回
    self.challenge_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")

            if server_pvp_logic:GetCurRank() ~= self.rank_info.rank then
                server_pvp_logic:ChallengeRival(self.rank_info.rank)
            end
        end
    end)
end

local server_pvp_panel = panel_prototype.New()
function server_pvp_panel:Init()
    self.root_node = cc.CSLoader:createNode("ui/server_pvp_panel.csb")
    local root_node = self.root_node

    self.back_scrollView = self.root_node:getChildByName("ScrollView_back")
    self.back_scrollView:setTouchEnabled(false)
    self.back_scrollView:removeFromParent()

    self.rank_scrollView = self.root_node:getChildByName("ScrollView_4")
    self.rank_scrollView:setTouchEnabled(true)
    self.rank_scrollView:setDirection(ccui.ScrollViewDir.vertical)

    self.left_template = self.root_node:getChildByName("Button_left")
    self.right_template = self.root_node:getChildByName("Button_right")
    self.top3_template = self.root_node:getChildByName("Button_1-3")
    self.top10_template = self.root_node:getChildByName("Button_4-10")

    self.left_template:setVisible(false)
    self.right_template:setVisible(false)
    self.top3_template:setVisible(false)
    self.top10_template:setVisible(false)

    self.mine_rank_icon = self.root_node:getChildByName("rank_icon")
    self.mine_rank_value = self.root_node:getChildByName("rank_value")

    self.mine_node = self.root_node:getChildByName("me")
    self.leader_img = self.mine_node:getChildByName("hero")
    self.leader_img:setScale(2)
    self.leader_img:ignoreContentAdaptWithSize(true)
    
    self.name_text = self.mine_node:getChildByName("name")
    self.server_name_text = self.mine_node:getChildByName("srever_name")
    self.cd_text = self.mine_node:getChildByName("cd")
    self.mine_rank_btn = self.mine_node:getChildByName("top_ten_rank_btn")

    self.team_btn = self.root_node:getChildByName("change_team_btn")
    self.world_rank_btn = self.root_node:getChildByName("formation_btn")
    self.rule_btn = self.root_node:getChildByName("view_info_btn")
    self.buy_btn = self.root_node:getChildByName("challenge_bg")
    self.buy_btn:setTouchEnabled(true)

    self.root_node:getChildByName("btn"):setTouchEnabled(false)

    self.challenge_time_text = self.root_node:getChildByName("challenge_num")

    self:RegisterEvent()
    self:RegisterWidgetEvent()

    local space_spine_node = spine_manager:GetNode("pengke_sky", 1.0, true)
    space_spine_node:setVisible(false)
    space_spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
    self.root_node:addChild(space_spine_node, STAR_ZORDER)

    local aircraft_spine_node = spine_manager:GetNode("pengke_ta", 1.0, true)
    aircraft_spine_node:setVisible(false)
    aircraft_spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])

    self.root_node:addChild(aircraft_spine_node, -1)
end

function server_pvp_panel:Show()
    self:ShowMineInfo()
    self:ShowRankInfo()
    self:ShowChallengeTime()
    self.root_node:setVisible(true)
end

function server_pvp_panel:ShowMineInfo()
    if server_pvp_logic:GetCurRank() == 0  then
        self.mine_rank_value:setString("")
    else
        self.mine_rank_value:setString(server_pvp_logic:GetCurRank())
    end

    local server_info = config_manager.server_config[login_logic.server_id]
    if server_info then
        self.server_name_text:setString(server_info.name)
    else
        self.server_name_text:setString("")
    end

    self.leader_img:loadTexture(client_constants["MERCENARY_ROLE_IMG_PATH"] .. troop_logic:GetLeader().template_info.sprite .. ".png", PLIST_TYPE)
    self.name_text:setString(user_logic:GetUserLeaderName())
end

function server_pvp_panel:CreateRandomCloud(tower_bottom_pos, pos_y)
    local cloud_sprite = cc.Sprite:createWithSpriteFrameName(string.format("tower/cloud0%d.png", math.random(2,6)))
    cloud_sprite:setOpacity(math.random(150, 255))
    cloud_sprite:setAnchorPoint(cc.p(0.5, 0.5))

    local scale = math.random(30, 40) / 10
    cloud_sprite:setScale(scale)

    local scroll_size = self.rank_scrollView:getContentSize()
    local cloud_size = cloud_sprite:getContentSize()
    if math.random(2) == 1 then
        cloud_sprite:setPosition(cc.p(0 - cloud_size.width * scale / 2, math.random(tower_bottom_pos, pos_y)))
        cloud_sprite:runAction(cc.Sequence:create( 
                                    cc.MoveBy:create(math.random(20, 40),cc.p(cloud_size.width * scale + scroll_size.width,0)),
                                    cc.CallFunc:create(function()
                                        cloud_sprite:removeFromParent()
                                        self:CreateRandomCloud(tower_bottom_pos, pos_y)
                                    end)
                                    )
        )
    else
        cloud_sprite:setPosition(cc.p(scroll_size.width + cloud_size.width * scale / 2, math.random(tower_bottom_pos, pos_y)))
        cloud_sprite:runAction(cc.Sequence:create( 
                                    cc.MoveBy:create(math.random(20, 40),cc.p(-(cloud_size.width * scale + scroll_size.width),0)),
                                    cc.CallFunc:create(function()
                                        cloud_sprite:removeFromParent()
                                        self:CreateRandomCloud(tower_bottom_pos, pos_y)
                                    end)
                                    )
        )
    end

    self.rank_scrollView:addChild(cloud_sprite, CLOUD_ZORDER)
end

function server_pvp_panel:ShowRankInfo()
    self.my_pos_percent = 100
    self.rank_scrollView:removeAllChildren()

    local size = self.rank_scrollView:getContentSize()
    local half_width = size.width / 2

    local rank_list = server_pvp_logic:GetRankList()

    local my_pos
    local pos_y = 0
    local space_middle_pos = 0
    local space_middle_height = TOWER_HEIGHT["top"] * 2
    local tower_bottom_pos = 0

    --如果自己没有排名，则显示塔的底座
    if server_pvp_logic:GetCurRank() == 0 then
        local tower_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["bottom"])
        tower_sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
        tower_sprite:setAnchorPoint(cc.p(0.5, 0))
        tower_sprite:setPosition(cc.p(half_width, pos_y))
        tower_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
        self.rank_scrollView:addChild(tower_sprite)

        pos_y = pos_y + TOWER_HEIGHT["bottom"] * client_constants["SERVER_PVP_TOWER_SCALE"]
        tower_bottom_pos = TOWER_HEIGHT["bottom"] * client_constants["SERVER_PVP_TOWER_SCALE"]

        local spine_node = spine_manager:GetNode("pengke_ta", 1.0, true)
        spine_node:setPosition(cc.p(130, tower_bottom_pos + 20))
        spine_node:setAnimation(0, "pengke_chilun", true)
        spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
        self.rank_scrollView:addChild(spine_node, -3)

        local line_sprite_left = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
        line_sprite_left:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
        line_sprite_left:setFlippedX(true)
        line_sprite_left:setAnchorPoint(cc.p(0.5, 1))
        line_sprite_left:setPosition(cc.p(half_width - LINE_OFFSET_X, tower_bottom_pos + 20))
        line_sprite_left:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
        self.rank_scrollView:addChild(line_sprite_left, LINE_ZORDER)

        local line_sprite_right = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
        line_sprite_right:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
        line_sprite_right:setAnchorPoint(cc.p(0.5, 1))
        line_sprite_right:setPosition(cc.p(half_width + LINE_OFFSET_X, tower_bottom_pos + 20))
        line_sprite_right:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
        self.rank_scrollView:addChild(line_sprite_right, LINE_ZORDER)
    end

    local is_left = false
    local has_tower_top = false
    for index,rank_info in ipairs(rank_list) do
        --塔身
        local tower_height = 0
        local rank_pos = 0
        if rank_info.rank <= 11 then
            tower_height = TOWER_HEIGHT[string.format("top_%d", rank_info.rank)] * client_constants["SERVER_PVP_TOWER_SCALE"]
        else
            local middle_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["middle"])
            middle_sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            middle_sprite:setAnchorPoint(cc.p(0.5, 0))
            middle_sprite:setPosition(cc.p(half_width, pos_y))
            middle_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            self.rank_scrollView:addChild(middle_sprite)

            if not ((rank_list[index + 1] and rank_list[index + 1].rank == 10) or (rank_list[index + 2] and rank_list[index + 2].rank == 10) or (rank_list[index + 2] and rank_list[index + 2].rank == 11)) then
                if is_left then
                    local part_info = PART_SPRITE_INFO[math.random(#PART_SPRITE_INFO)]
                    local part_sprite = cc.Sprite:createWithSpriteFrameName(part_info.sprite)
                    part_sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                    part_sprite:setAnchorPoint(cc.p(0.5,0))
                    part_sprite:setFlippedX(true)
                    part_sprite:setPosition(cc.p(half_width - part_info.pos_x, pos_y + part_info.pos_y))
                    part_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                    self.rank_scrollView:addChild(part_sprite, PART_ZORDER)
                else
                    local part_info = PART_SPRITE_INFO[math.random(#PART_SPRITE_INFO)]
                    local part_sprite = cc.Sprite:createWithSpriteFrameName(part_info.sprite)
                    part_sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                    part_sprite:setAnchorPoint(cc.p(0.5,0))
                    part_sprite:setPosition(cc.p(half_width + part_info.pos_x, pos_y + part_info.pos_y))
                    part_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                    self.rank_scrollView:addChild(part_sprite, PART_ZORDER)
                end
            end

            local line_sprite_left = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
            line_sprite_left:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            line_sprite_left:setFlippedX(true)
            line_sprite_left:setAnchorPoint(cc.p(0.5, 0))
            line_sprite_left:setPosition(cc.p(half_width - LINE_OFFSET_X, pos_y))
            line_sprite_left:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            self.rank_scrollView:addChild(line_sprite_left, LINE_ZORDER)

            local line_sprite_right = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
            line_sprite_right:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            line_sprite_right:setAnchorPoint(cc.p(0.5, 0))
            line_sprite_right:setPosition(cc.p(half_width + LINE_OFFSET_X, pos_y))
            line_sprite_right:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            self.rank_scrollView:addChild(line_sprite_right, LINE_ZORDER)

            tower_height = TOWER_HEIGHT["middle"] * client_constants["SERVER_PVP_TOWER_SCALE"]
        end
        rank_pos = pos_y + tower_height / 2

        --第10名与其余名次之间有间隔
        if not has_tower_top and (rank_info.rank == 10 or (rank_list[index + 1] and rank_list[index + 1].rank == 10)) then
            has_tower_top = true

            if rank_info.rank > 11 then
                local middle_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["middle"])
                middle_sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                middle_sprite:setAnchorPoint(cc.p(0.5, 0))
                middle_sprite:setPosition(cc.p(half_width, pos_y))
                middle_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                self.rank_scrollView:addChild(middle_sprite)

                local line_sprite_left = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
                line_sprite_left:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                line_sprite_left:setFlippedX(true)
                line_sprite_left:setAnchorPoint(cc.p(0.5, 0))
                line_sprite_left:setPosition(cc.p(half_width - LINE_OFFSET_X, pos_y))
                line_sprite_left:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                self.rank_scrollView:addChild(line_sprite_left, LINE_ZORDER)

                local line_sprite_right = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
                line_sprite_right:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                line_sprite_right:setAnchorPoint(cc.p(0.5, 0))
                line_sprite_right:setPosition(cc.p(half_width + LINE_OFFSET_X, pos_y))
                line_sprite_right:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                self.rank_scrollView:addChild(line_sprite_right, LINE_ZORDER)

                pos_y = pos_y + TOWER_HEIGHT["middle"] * client_constants["SERVER_PVP_TOWER_SCALE"]
            end

            local spine_node = spine_manager:GetNode("pengke_ta", 1.0, true)
            spine_node:setAnimation(0, "pengke_ta", true)
            spine_node:setAnchorPoint(cc.p(0.5, 0))
            spine_node:setPosition(cc.p(half_width, pos_y - TOWER_TOP_OFFSET_Y))
            spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            self.rank_scrollView:addChild(spine_node)

            if #rank_list > 10 then
                local spine_node_left = spine_manager:GetNode("pengke_ta", 1.0, true)
                spine_node_left:setPosition(cc.p(half_width, pos_y - DIANTI_OFFSET_Y))
                spine_node_left:setAnimation(0, string.format("pengke_dianti_%d", math.random(4)), true)
                spine_node_left:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                self.rank_scrollView:addChild(spine_node_left)
                
                local spine_node_right = spine_manager:GetNode("pengke_ta", 1.0, true)
                spine_node_right:setPosition(cc.p(half_width, pos_y - DIANTI_OFFSET_Y))
                spine_node_right:setAnimation(0, string.format("pengke_dianti_%d", math.random(4)), true)
                spine_node_right:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
                spine_node_right:setRotationSkewY(180)
                self.rank_scrollView:addChild(spine_node_right)
            end

            local line_sprite_left = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
            line_sprite_left:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            line_sprite_left:setFlippedX(true)
            line_sprite_left:setAnchorPoint(cc.p(0.5, 0))
            line_sprite_left:setPosition(cc.p(half_width - LINE_OFFSET_X, pos_y))
            line_sprite_left:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            self.rank_scrollView:addChild(line_sprite_left, LINE_ZORDER)

            local line_sprite_right = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["line"])
            line_sprite_right:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
            line_sprite_right:setAnchorPoint(cc.p(0.5, 0))
            line_sprite_right:setPosition(cc.p(half_width + LINE_OFFSET_X, pos_y))
            line_sprite_right:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            self.rank_scrollView:addChild(line_sprite_right, LINE_ZORDER)

            space_middle_pos = pos_y
            
            if rank_info.rank ~= 11 then
                local sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["cloud"])
                sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"] * 2)
                sprite:setAnchorPoint(cc.p(0.5, 0.1))
                sprite:setPosition(cc.p(half_width, pos_y - 100))
                sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                self.rank_scrollView:addChild(sprite, 3)

                sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["cloud"])
                sprite:setScale(client_constants["SERVER_PVP_TOWER_SCALE"] * 2)
                sprite:setAnchorPoint(cc.p(0.5, 0.1))
                sprite:setOpacity(200)
                sprite:setPosition(cc.p(half_width, pos_y + 150))
                sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
                self.rank_scrollView:addChild(sprite, 3)

                pos_y = pos_y + TOWER_HEIGHT["top"]
            end
        end
        
        if index == 1 and rank_info.rank == 10 then
            pos_y = pos_y + TOWER_HEIGHT["middle"] * client_constants["SERVER_PVP_TOWER_SCALE"]
            rank_pos = pos_y + TOWER_HEIGHT["middle"]
        end

        --排名节点
        local sub_panel = rank_sub_panel.New()

        --根据名次判断X轴位置
        if rank_info.rank <= 10 then
            --前十名
            if rank_info.rank <= 3 then
                sub_panel:Init(self.top3_template:clone())
            else
                sub_panel:Init(self.top10_template:clone())
            end
            if rank_info.rank == 1 then
                --第一名在中间
                sub_panel.root_node:setPosition(cc.p(sub_panel.root_node:getPositionX() - 50, rank_pos))
            elseif rank_info.rank % 2 == 0 then
                --2、4、6、8、10 在左边
                sub_panel.root_node:setPosition(cc.p(sub_panel.root_node:getPositionX() - 160, rank_pos))
            else
                --3、5、7、9 在右边
                sub_panel.root_node:setPosition(cc.p(sub_panel.root_node:getPositionX() + 95, rank_pos))
            end
        else
            --其余的
            if is_left then
                sub_panel:Init(self.left_template:clone())
                sub_panel.root_node:setPosition(cc.p(sub_panel.root_node:getPositionX() - 100, rank_pos))
            else
                sub_panel:Init(self.right_template:clone())
                sub_panel.root_node:setPosition(cc.p(sub_panel.root_node:getPositionX() + 100, rank_pos))

            end
            is_left = not is_left
        end
        if not my_pos or server_pvp_logic:GetCurRank() == rank_info.rank then
            my_pos = rank_pos
        end

        sub_panel:Show(rank_info)
        
        self.rank_scrollView:addChild(sub_panel.root_node, RANK_ZORDER)

        pos_y = pos_y + tower_height
    end

    local space_bg_bottom_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["space_bg_bottom"])
    space_bg_bottom_sprite:setAnchorPoint(cc.p(0.5, 0))
    space_bg_bottom_sprite:setScale(size.width / space_bg_bottom_sprite:getContentSize().width * 2, space_middle_pos / space_bg_bottom_sprite:getContentSize().height)
    space_bg_bottom_sprite:setPosition(cc.p(half_width, 0))
    self.rank_scrollView:addChild(space_bg_bottom_sprite, BG_ZORDER)

    local space_bg_top_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["space_bg_top"])
    space_bg_top_sprite:setAnchorPoint(cc.p(0.5, 1))
    space_bg_top_sprite:setScale(size.width / space_bg_top_sprite:getContentSize().width * 2, (pos_y - space_middle_pos) / space_bg_top_sprite:getContentSize().height)
    space_bg_top_sprite:setPosition(cc.p(half_width, pos_y))
    self.rank_scrollView:addChild(space_bg_top_sprite, BG_ZORDER)

    local space_bg_middle_sprite = cc.Sprite:createWithSpriteFrameName(TOWER_SPRITE["space_bg_middle"])
    space_bg_middle_sprite:setAnchorPoint(cc.p(0.5, 0.5))
    space_bg_middle_sprite:setScale(size.width / space_bg_middle_sprite:getContentSize().width * 2, space_middle_height / space_bg_middle_sprite:getContentSize().height)
    space_bg_middle_sprite:setPosition(cc.p(half_width, space_middle_pos))
    self.rank_scrollView:addChild(space_bg_middle_sprite, BG_ZORDER)

    local star_num = math.random(10, 15)
    for i=1,star_num do
        local star_sprite = cc.Sprite:createWithSpriteFrameName(string.format("tower/space0%d.png", math.random(2,4)))
        star_sprite:setPosition(cc.p(math.random(size.width), math.random(space_middle_pos + space_middle_height / 2, pos_y)))
        star_sprite:setScale(3)
        star_sprite:setRotation(math.random(360))
        star_sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)

        self.rank_scrollView:addChild(star_sprite, STAR_ZORDER)
    end

    local space_spine_node = spine_manager:GetNode("pengke_sky", 1.0, true)
    space_spine_node:setAnimation(0, "animation", true)
    space_spine_node:setPosition(cc.p(half_width, pos_y - 1150))
    space_spine_node:setScale(client_constants["SERVER_PVP_TOWER_SCALE"])
    self.rank_scrollView:addChild(space_spine_node, STAR_ZORDER)

    --创建随机云
    for i=1,math.random(10, 15) do
        self:CreateRandomCloud(tower_bottom_pos, space_middle_pos)
    end

    local prick_pos_y = math.random(tower_bottom_pos, space_middle_pos)
    for i=1,math.random(3, 6) do
        local sprite = cc.Sprite:createWithSpriteFrameName(PRICK_SPRITE[math.random(#PRICK_SPRITE)])
        sprite:setPosition(cc.p(half_width + PRICK_OFFSET_X, prick_pos_y))
        sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
        self.rank_scrollView:addChild(sprite, PRICK_ZORDER)

        prick_pos_y = prick_pos_y + math.random(20, 40)
    end

    prick_pos_y = math.random(tower_bottom_pos, space_middle_pos)
    for i=1,math.random(3, 6) do
        local sprite = cc.Sprite:createWithSpriteFrameName(PRICK_SPRITE[math.random(#PRICK_SPRITE)])
        sprite:setFlippedX(true)
        sprite:setPosition(cc.p(half_width - PRICK_OFFSET_X, prick_pos_y))
        sprite:getTexture():setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
        self.rank_scrollView:addChild(sprite, PRICK_ZORDER)

        prick_pos_y = prick_pos_y + math.random(20, 40)
    end

    if my_pos <= size.height / 2 then
        self.my_pos_percent = 100
    else
        self.my_pos_percent = 100 - (my_pos - size.height / 2) / (pos_y - size.height) * 100
    end
    self.rank_scrollView:setInnerContainerSize(cc.size(size.width, pos_y))
end

function server_pvp_panel:ShowChallengeTime()
    self.challenge_time_text:setString(server_pvp_logic.challenge_times .. "/" .. constants["PVP_MAX_NUM"])
end

function server_pvp_panel:Update(elapsed_time)
    local t_now = time_logic:Now()

    local cd = 0
    if server_pvp_logic.challenge_cd_end_time > t_now then
        cd = time_logic:GetDurationToFixedTime(server_pvp_logic.challenge_cd_end_time)
    end

    self.cd_text:setString(panel_util:GetTimeStr(cd))
end

function server_pvp_panel:RegisterEvent()
    graphic:RegisterEvent("update_server_pvp_rank", function(is_winner)
        self:ShowMineInfo()
        self:ShowRankInfo()
        self:ShowChallengeTime()
    end)

    graphic:RegisterEvent("update_server_pvp_times", function(is_winner)
        self:ShowChallengeTime()
    end)
end

function server_pvp_panel:RegisterWidgetEvent()

    self.mine_rank_btn:addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            self.rank_scrollView:scrollToPercentVertical(self.my_pos_percent, 0.2, true)
        end
    end)

    self.team_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then 
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "formation_sub_scene", SCENE_TRANSITION_TYPE["none"], client_constants["FORMATION_PANEL_MODE"]["server_pvp"], back_panel)
            graphic:DispatchEvent("update_battle_point", troop_logic:GetTroopBP(constants["KF_PVP_TROOP_ID"]))
        end
    end)

    self.rule_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            graphic:DispatchEvent("show_world_sub_panel", "server_pvp_rule_panel")
        end
    end)

    self.buy_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            local could_buy, cost = server_pvp_logic:GetBuyCost(1)
            if could_buy then
                local mode = client_constants["BATCH_MSGBOX_MODE"]["server_pvp_buy_times"]
                graphic:DispatchEvent("show_world_sub_panel", "store_msgbox", mode)
            else
                graphic:DispatchEvent("show_prompt_panel", "has_buy_too_much_server_pvp_times")
            end
        end
    end)
    
    self.world_rank_btn:addTouchEventListener(function(widget, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            
            server_pvp_logic:QueryServerPvpWorldRank()
        end
    end)

    --返回
    self.root_node:getChildByName("back_btn"):addTouchEventListener(function(sender, event_type)
        if event_type == ccui.TouchEventType.ended then
            audio_manager:PlayEffect("click")
            graphic:DispatchEvent("show_world_sub_scene", "pvp_sub_scene")
        end
    end)

end

return server_pvp_panel
