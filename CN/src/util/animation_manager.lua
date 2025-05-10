local animation_manager = {}

local TARGET_PLATFORM = cc.Application:getInstance():getTargetPlatform()

local ANIMATION_NAMES = {
     ["mining"] = { 
         plists = {
             [1] = "res/animation/ani_mining/huiceng_xu_all",
             [2] = "res/animation/ani_mining/huoyan_all_1",
             [3] = "res/animation/ani_mining/img_donghua_2",
             [4] = "res/animation/ani_mining/img_game4_01",
             [5] = "res/animation/ani_mining/myw_all_1",
             [6] = "res/animation/ani_mining/shanguang_ani",
             [7] = "res/animation/ani_mining/mining_car_f",
             [8] = "res/animation/ani_mining/tramcar_lv3",
             [9] = "res/animation/ani_mining/wheel_lv3",
             [10] = "res/animation/ani_mining/zhadao_1",
             [11] = "res/animation/ani_mining/zhadao_2",
             [12] = "res/animation/ani_mining/zhadao_3",
             [13] = "res/animation/ani_mining/zhadao_4",
             [14] = "res/animation/ani_mining/zhadao_5",
             [15] = "res/animation/ani_mining/zhadao_6",
             [16] = "res/animation/ani_mining/zhadao_light",
             [17] = "res/animation/ani_mining/min_st",
             [18] = "res/animation/ani_mining/min_st2",
             [19] = "res/animation/ani_mining/mine_lv3",
             [20] = "res/animation/ani_mining/mining_2016_1",
         },
         csb_file = "res/animation/ani_mining/scene_mining.csb"   
     }, 


    ["lottery_spring"] = {
        plists = {
            [1] = "res/animation/ani_giftbox/yunwu_ani", 
            [2] = "res/animation/ani_giftbox/2016_1_18",
        },
            
        csb_file = "res/animation/ani_giftbox/scene_redpaper.csb"  
    },

    ["tramcar_bg"] = {
        plists = {
            [1] = "res/ui/bg/bg001", 
        },
            
        csb_file = "res/ui/tramcar_bg.csb"  
    },

    ["tramcar_bg2"] = {
        plists = {
        },
            
        csb_file = "res/ui/node_stone.csb"  
    },

    ["start_rob"] = {
        plists = {
        },
            
        csb_file = "res/ui/node_hold_up.csb"  
    },

    ["start_up_cultivation1"] = {
        plists = {
        },
            
        csb_file = "res/ui/cultivation_number1_up.csb"  
    },

    ["start_up_cultivation2"] = {
        plists = {
        },
            
        csb_file = "res/ui/cultivation_number2_up.csb"  
    },

    ["weapon_star_upgrade"] = {
        plists = {
        },
            
        csb_file = "res/ui/leader_info.csb"  
    },
}

local TIMELINE_NAME = {
     ["mining_timeline"] = { csb_file = "res/animation/ani_mining/scene_mining.csb", }, 
     ["lottery_spring_timeline"] = { csb_file = "res/animation/ani_giftbox/scene_redpaper.csb", },
     ["guildwar_settlement_step1_timeline"] = { csb_file = "res/ui/guildwar_settlement1_panel.csb", },
     ["guildwar_settlement_step2_timeline"] = { csb_file = "res/ui/guildwar_settlement_panel.csb", },
     ["battle_rune_timeline"] = { csb_file = "res/ui/battle_rune.csb", },
     ["tramcar_bg_timeline"] = { csb_file = "res/ui/tramcar_bg.csb", },
     ["tramcar_bg2_timeline"] = { csb_file = "res/ui/node_stone.csb", },
     ["start_rob_timeline"] = { csb_file = "res/ui/node_hold_up.csb", },
     ["tramcar_selected_timeline"] = { csb_file = "res/ui/Node_car_light.csb", },
     ["guild_boss_enter_timeline"] = { csb_file = "res/ui/guild_boss_enter.csb", },
     ["mine_rob_enter_timeline"] = {csb_file = "res/ui/node_mine_change.csb", },
     ["mine_unlock_timeline"] = {csb_file = "res/ui/node_unlock.csb", }, 
     ["mine_car_enter_out_timeline"] = {csb_file = "res/ui/Node_xiaokuangche.csb",},  --矿山的小车进出动画
     ["cultivation_number1_up"] = {csb_file = "res/ui/cultivation_number1_up.csb",},  --修炼上面动画
     ["cultivation_number2_up"] = {csb_file = "res/ui/cultivation_number2_up.csb",},  --修炼下面动画
     ["ladder_update_timeline"] = {csb_file = "res/ui/ladder_image.csb",},  --天梯赛等级升级动画
     ["weapon_star_upgrade_timeline"] = {csb_file = "res/ui/leader_info.csb",},  --修炼下面动画
     ["leader_flash_timeline"] = {csb_file = "res/ui/evolution_panel_up.csb",},  --主角闪金化
     ["leader_unlock_timeline"] = {csb_file = "res/ui/node_levelup_light.csb",},  --主角闪金化
     ["leader_use_timeline"] = {csb_file = "res/ui/ladder_light.csb",},  --主角使用皮肤
     ["title_tab_timeline"] = {csb_file = "res/ui/Node_title.csb",},  --称号按钮
     ["achievement_tab_timeline"] = {csb_file = "res/ui/Node_achievement.csb",},  --成就按钮
     ["title_player_time_line"] = {csb_file = "res/ui/title_player.csb",},  --称号动画

     ["recover_timeline"] = {csb_file = "res/ui/recover.csb",},  --钻地动画
     ["finger_touch_timeline"] = {csb_file = "res/ui/recover_touch.csb",}, -- 手指动画
     ["recover_touch_yun_timeline"] = {csb_file = "res/ui/recover_touch_yun.csb",}, -- 手指动画

     ["vanity_main_bg_timeline"] = {csb_file = "res/ui/node_planet_beijing.csb",}, -- 虚空大冒险背景动画
     ["vanity_star_animation1_timeline"] = {csb_file = "res/ui/node_planet_1.csb",}, -- 虚空大星球动画1
     ["vanity_star_animation2_timeline"] = {csb_file = "res/ui/node_planet_2.csb",}, -- 虚空大星球动画2
     ["vanity_star_animation3_timeline"] = {csb_file = "res/ui/node_planet_3.csb",}, -- 虚空大星球动3
     ["vanity_star_animation4_timeline"] = {csb_file = "res/ui/node_planet_4.csb",}, -- 虚空大星球动画4
     ["vanity_star_animation5_timeline"] = {csb_file = "res/ui/node_planet_5.csb",}, -- 虚空大星球动画5
     ["vanity_star_animation6_timeline"] = {csb_file = "res/ui/node_planet_6.csb",}, -- 虚空大星球动画6
     ["vanity_star_animation_end_timeline"] = {csb_file = "res/ui/node_planet_blackhole.csb",}, -- 虚空大星球动画6
}

local SEARCH_PATH = {
    [1] = "res/animation/ani_mining",
    [2] = "res/animation/ani_giftbox"
}

local PLIST_NAME = ".plist" 
local PNG_NAME = ".png"

local file_util = cc.FileUtils:getInstance()
local sprite_frame_cache = cc.SpriteFrameCache:getInstance()
local action_manager = ccs.ActionTimelineCache:getInstance()
local texture_cache = cc.Director:getInstance():getTextureCache()

function animation_manager:Init()

    for k, path in pairs(SEARCH_PATH) do 
        if TARGET_PLATFORM == cc.PLATFORM_OS_IPHONE or TARGET_PLATFORM == cc.PLATFORM_OS_IPAD or TARGET_PLATFORM == cc.PLATFORM_OS_ANDROID then
           local writable_path = file_util:getWritablePath()
           path = writable_path .. path
        end

        file_util:addSearchPath(path)
    end

    self.animation_nodes = {}
    self.timeline_name = {}
end

function animation_manager:LoadAnimation(animation_name)
    local animation_config = ANIMATION_NAMES[animation_name]

    if animation_config and not self.animation_nodes[animation_name] then 
        for k, v in ipairs(animation_config.plists) do 
            sprite_frame_cache:addSpriteFrames(v .. PLIST_NAME )
            local tex = texture_cache:getTextureForKey(v .. PNG_NAME)

            if tex then 
               tex:setTexParameters(gl.NEAREST, gl.NEAREST, gl.CLAMP_TO_EDGE, gl.CLAMP_TO_EDGE)
            end
        end

        animation_node = cc.CSLoader:createNode(animation_config.csb_file)
        animation_node:retain()

        self.animation_nodes[animation_name] = animation_node
    end
end

function animation_manager:GetAnimationNode(animation_name)
    return self.animation_nodes[animation_name]
end

function animation_manager:RemoveAnimation(animation_name)
    local animation_config = ANIMATION_NAMES[animation_name]

    if animation_config and self.animation_nodes[animation_name] then 
        self.animation_nodes[animation_name]:release()
        self.animation_nodes[animation_name] = nil

        for k, v in ipairs(animation_config.plists) do 
            sprite_frame_cache:removeSpriteFramesFromFile(v .. PLIST_NAME)
            texture_cache:removeTextureForKey(v .. PNG_NAME)
        end
    
        texture_cache:removeUnusedTextures()
    end
end

function animation_manager:GetTimeLine(action_name)
    local timeline_config = TIMELINE_NAME[action_name]
    local action 
    if timeline_config then 
        action = cc.CSLoader:createTimeline(timeline_config.csb_file)
        self.timeline_name[action_name] = true 
    end

    return action 
end

function animation_manager:RemoveTimeLine(action_name)
    if self.timeline_name[action_name] then 
       local file_name = TIMELINE_NAME[action_name]
       action_manager:removeAction(file_name.csb_file)
       self.timeline_name[action_name] = nil
    end
end

function animation_manager:ClearAll()
   for k, v in pairs(self.timeline_name) do 
      if v then 
         self:RemoveTimeLine(k)
      end
   end
   self.timeline_name = {}

   for k,v in pairs(self.animation_nodes) do 
       if v then 
          self:RemoveAnimation(k)
       end
   end

   self.animation_nodes = {}
end

do
    animation_manager:Init()
end

return animation_manager
