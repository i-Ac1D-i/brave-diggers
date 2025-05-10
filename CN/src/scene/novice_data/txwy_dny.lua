local create_leader_cond = require "scene.novice.create_leader_cond"
local solve_event_cond= require "scene.novice.solve_event_cond"
local first_use_feature_cond = require "scene.novice.first_use_feature_cond"
local first_battle_failure_cond = require "scene.novice.first_battle_failure_cond"
local first_discover_golem_cond = require "scene.novice.first_discover_golem_cond"
local open_panel_cond = require "scene.novice.open_panel_cond"

local client_constants = require "util.client_constants"

local BATTLE_TYPE = client_constants["BATTLE_TYPE"]
local NOVICE_TYPE = client_constants["NOVICE_TYPE"]
local NOVICE_MARK = client_constants["NOVICE_MARK"]

return function(novice_sub_scene)
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
            mask_info = { alpha = 0.7 , x = 320 , y = 520 , width = 587 , height = 164 , padding = 20 },
            { type =  NOVICE_TYPE["text"], content_id = 113,  x = 320, y = 288, width = 100, height = 100 },
            { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 438 , rotation = 90 },
        },
        {
            auto_play_next_step = true,
            mask_info = { alpha = 0.7 , x = 320 , y = 580 , width = 620 , height = 740 , padding = 20 },
            { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 19000032 },
            { type = NOVICE_TYPE["sim_touch"], x = 320, y = 538},
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
            mask_info = { alpha = 0.7 , x = 320 , y = 243 , width = 250 , height = 90 , padding = 20 },
            { type =  NOVICE_TYPE["talker"],  animation_name = "talker_exit", is_loop = false,  mercenary_id = 19000060  },
            { type =  NOVICE_TYPE["dialogue"],  animation_name = "dialogue_exit", is_loop = false, content_id = 153 },
        },
        {
            auto_play_next_step = false,
            mask_info = { alpha = 0.7 , x = 320 , y = 243 , width = 250 , height = 90 , padding = 20 },
            { type =  NOVICE_TYPE["text"], content_id = 154,  x = 320, y = 43, width = 100, height = 100 },
            { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 143 , rotation = 90 },
        },
        {
            auto_play_next_step = true,
            mask_info = { alpha = 0.7 , x = 320 , y = 572 , width = 618 , height = 627 , padding = 20 },
            { type = NOVICE_TYPE["sim_touch"], x = 320, y = 243},
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
            mask_info = { alpha = 0.7 , x = 320 , y = 710 , width = 587 , height = 163 , padding = 20 },
            { type = NOVICE_TYPE["sim_touch"], x = 372, y = 53},
        },
        {
            auto_play_next_step = false,
            mask_info = { alpha = 0.7 , x = 320 , y = 710 , width = 587 , height = 163 , padding = 20 },
            { type =  NOVICE_TYPE["text"], content_id = 183,  x = 320, y = 356, width = 100, height = 100 },
            { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 320 , y = 456 , rotation = 90 },
        },
        {
            auto_play_next_step = true,
            mask_info = { alpha = 0.7 , x = 320 , y = 601 , width = 620 , height = 740 , padding = 20 },
            { type =  NOVICE_TYPE["talker"],  animation_name = "talker_enter", is_loop = false,  mercenary_id = 18000015 },
            { type = NOVICE_TYPE["sim_touch"], x = 320, y = 726},
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
    --[[
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
        },
        {
            auto_play_next_step = false,
            mask_info = { alpha = 0.9 , x = 430 , y = 870 , width = 240, height = 80 , padding = 20 },
            { type =  NOVICE_TYPE["text"], content_id = 274,  x = 430, y = 1010, width = 100, height = 100 },
            { type =  NOVICE_TYPE["animation"], animation_name = "gesture_loop", is_loop = true , x = 430 , y = 930 , rotation = 270 , scale = 0.5},
        },
        {
            auto_play_next_step = true,
            mask_info = { alpha = 0 },
            { type = NOVICE_TYPE["sim_touch"], x = 430, y = 870},
        }
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
            -- { type = NOVICE_TYPE["network_sync"], msg_name = "query_campaign_level_ret"},
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
end