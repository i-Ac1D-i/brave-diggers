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
             [7] = "res/animation/ani_mining/mining_2016_1",
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
