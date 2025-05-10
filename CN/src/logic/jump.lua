local json = require "util.json"
local constants = require "util.constants"
local client_constants = require "util.client_constants"
local store_logic = require "logic.store"
local mining_logic = require "logic.mining"
local FEATURE_TYPE = client_constants["FEATURE_TYPE"]
local user_logic = require "logic.user"
local payment_logic = require "logic.payment"
local TAB_TYPE = client_constants["WORLD_TAB_TYPE"]
local graphic = require "logic.graphic"
local magic_shop = require "logic.magic_shop" 
local SCENE_TRANSITION_TYPE = constants["SCENE_TRANSITION_TYPE"]
local audio_manager = require "util.audio_manager"
local merchant_logic = require "logic.merchant"
local escort_logic = require "logic.escort"
local carnival_logic = require "logic.carnival"
local JUMP_CONST = client_constants["JUMP_CONST"] 
local CHOOSE_ETHER_CAVE = client_constants["MINING_NORMAL_CAVES"]["ether_cave"]
local CHOOSE_MONSTER_CAVE = client_constants["MINING_NORMAL_CAVES"]["monster_cave"]
local troop_logic = require "logic.troop"
local arena_logic = require "logic.arena"
local daily_logic = require "logic.daily"
local campaign_logic = require "logic.campaign"
local guild_logic = require "logic.guild"
local feature_config = require "logic.feature_config"
local mine_logic = require "logic.mine"
local network = require "util.network"
local resource_logic 
local jump_finish = {}

local jump = {}
local jump_resources = {}
local list_data = {}
function jump:Init()
	self:RegisterEvent()
	self.reference = 0
end

function jump:RegisterGraphEvent()
	graphic:RegisterEvent("jump_finish", function(panel_id)  
		panel_id = tostring(panel_id) 
		if jump_finish[panel_id] then 
			jump_finish[panel_id]() --处理方法
			jump_finish[panel_id] = nil   
		end
	end)
end

function jump:RegisterEvent()
    network:RegisterEvent("refresh_jump_list", function(recv_msg) 
        list_data = recv_msg.list_data
        for k,v in pairs(list_data) do
           jump_resources[v.resource_id] = true  
        end 
    end)

    network:RegisterEvent("get_jump_list_ret", function(recv_msg) 
        
        list_data = recv_msg.list_data
        for k,v in pairs(list_data) do
           jump_resources[v.resource_id] = true  
        end
    end)
end

function jump:IsLock(panel_id) 

end

function jump:HidePanel()
	self.delegate:HidePanel() 
end

function jump:IsCanGoPanel(pannel_id,need_prompt)   
	if not resource_logic then
		resource_logic = require "logic.resource" 
	end
	
	local default = true 
	if pannel_id == JUMP_CONST["mining"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt)
	elseif pannel_id == JUMP_CONST["pvp"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"], need_prompt)
	elseif pannel_id == JUMP_CONST["summon"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["recruit"], need_prompt)
	elseif pannel_id == JUMP_CONST["mercenary"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mercenary"], need_prompt)
	elseif pannel_id == JUMP_CONST["pay"] then
		default = payment_logic.enable_pay
		if need_prompt and not default then
			graphic:DispatchEvent("show_prompt_panel", "payment_purchase_not_available")
		end
	elseif pannel_id == JUMP_CONST["rune"] then  
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"], need_prompt)
	elseif pannel_id == JUMP_CONST["market"] then	
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["merchant"])
		if not default and need_prompt then
			graphic:DispatchEvent("show_prompt_panel", "merchant_not_open")
		end
	elseif pannel_id == JUMP_CONST["check_daily"] then 
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"], need_prompt)
	elseif pannel_id == JUMP_CONST["daily_prayer"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"], need_prompt)
	elseif pannel_id == JUMP_CONST["daily_lchemy"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["explore_box"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_area"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_work_shop"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt) and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["quarry"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_Tub"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt) and user_logic:IsFeatureUnlock(client_constants["FEATURE_TYPE"]["escort_and_rune"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_exploration"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt) and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_explore"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_troll_lair"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt) and user_logic:IsFeatureUnlock(client_constants.FEATURE_TYPE["mining_golem"], need_prompt)
	elseif pannel_id == JUMP_CONST["mining_area_boss"] then
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mining"], need_prompt)
	elseif pannel_id == JUMP_CONST["rune_crystal"] then 
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"])
		if not default and need_prompt then
			graphic:DispatchEvent("show_prompt_panel", "rune_not_open")
		end
	elseif pannel_id == JUMP_CONST["rune_installation"] then 
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["escort_and_rune"], need_prompt)
	elseif pannel_id == JUMP_CONST["mercenary_dismissal"] then 
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["mercenary"], need_prompt) and user_logic:IsFeatureUnlock(FEATURE_TYPE["fire"], need_prompt) and not troop_logic:CheckMercenaryLimiteOverTime()
	elseif pannel_id == JUMP_CONST["pvp_arena"] then   
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"], need_prompt) 
	elseif pannel_id == JUMP_CONST["pvp_qualifying"] then   
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"], need_prompt)and user_logic:IsFeatureUnlock(FEATURE_TYPE["ladder"],need_prompt) 
	elseif pannel_id == JUMP_CONST["pvp_campaign"] then   
		default = self:processCampaign(need_prompt) 
	elseif pannel_id == JUMP_CONST["pvp_arena_exchange"] then   
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"], need_prompt)
	elseif pannel_id == JUMP_CONST["pvp_war"] then   
		default = self:processCampaign(need_prompt)
	elseif pannel_id == JUMP_CONST["mercenary_levelup_panel"] then   
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["alloc_exp"], need_prompt) and not troop_logic:CheckMercenaryLimiteOverTime()   
	elseif pannel_id == JUMP_CONST["mercenary_levelup_forge"] then    
		default = user_logic:IsFeatureUnlock(FEATURE_TYPE["alloc_exp"], need_prompt) and not troop_logic:CheckMercenaryLimiteOverTime()  
	elseif pannel_id == JUMP_CONST["guild_main"] then
		default = feature_config:IsFeatureOpen("guild") and user_logic:IsFeatureUnlock(FEATURE_TYPE["guild"],need_prompt) 
	elseif pannel_id == JUMP_CONST["guild_boss"] then
		default = feature_config:IsFeatureOpen("guild") and user_logic:IsFeatureUnlock(FEATURE_TYPE["guild"],need_prompt) and guild_logic:IsGuildMember()
	elseif pannel_id == JUMP_CONST["guild_boss_shop"] then
		default = feature_config:IsFeatureOpen("guild") and user_logic:IsFeatureUnlock(FEATURE_TYPE["guild"],need_prompt) and guild_logic:IsGuildMember()
	elseif pannel_id == JUMP_CONST["mine_main"] then
    	default = feature_config:IsFeatureOpen("mine_and_cultivation") and user_logic:IsFeatureUnlock(FEATURE_TYPE["mine_and_cultivation"],need_prompt)
	end
	return default 
end

function jump:processCampaign(need_prompt)
	local default 
	local is_unlock = user_logic:IsFeatureUnlock(FEATURE_TYPE["arena"], need_prompt)
	local is_visible = campaign_logic:IsOpen() 
	default = is_unlock and is_visible
	if is_unlock and not is_visible and need_prompt  then
		graphic:DispatchEvent("show_prompt_panel", "campaign_not_open") 
	end
	return default 
end
-- 外部递归
function jump:GoToPannel(pannel_id,resource_id,lack_num,blood_replace_pre) --	lack_num 缺少个数    blood_replace_pre血钻替代比率
-----------------------------------一级界面-------------------------------------
	if pannel_id == JUMP_CONST["main"] then
		graphic:DispatchEvent("update_world_tab", TAB_TYPE["main"])
	elseif pannel_id == JUMP_CONST["adventure"] then  
		graphic:DispatchEvent("update_world_tab", TAB_TYPE["adventure"])
	elseif pannel_id == JUMP_CONST["mining"] then
        graphic:DispatchEvent("update_world_tab", TAB_TYPE["mining"])
	elseif pannel_id == JUMP_CONST["pvp"] then
        graphic:DispatchEvent("update_world_tab", TAB_TYPE["arena"])  
	elseif pannel_id == JUMP_CONST["summon"] then
        graphic:DispatchEvent("update_world_tab", TAB_TYPE["recruit"])  
	elseif pannel_id == JUMP_CONST["mercenary"] then
        graphic:DispatchEvent("update_world_tab", TAB_TYPE["mercenary"]) 
    elseif pannel_id == JUMP_CONST["blood_diamond_shop"] then
		store_logic:Query() 
	elseif pannel_id == JUMP_CONST["pay"] then
		graphic:DispatchEvent("show_world_sub_scene", "payment_sub_scene") 
	elseif pannel_id == JUMP_CONST["rune"] then  
        graphic:DispatchEvent("show_world_sub_scene", "rune_draw_sub_scene")
	elseif pannel_id == JUMP_CONST["friends"] then
		graphic:DispatchEvent("show_world_sub_scene", "social_sub_scene")
	elseif pannel_id == JUMP_CONST["carnival"] then
		graphic:DispatchEvent("show_world_sub_scene", "carnival_sub_scene")
	elseif pannel_id == JUMP_CONST["achievement"] then
		graphic:DispatchEvent("show_world_sub_scene", "achievement_sub_scene")
	elseif pannel_id == JUMP_CONST["market"] then	
        merchant_logic:Query() 
    elseif pannel_id == JUMP_CONST["check_daily"] then	--签到界面 
	    daily_logic:RequestDaily()  
	elseif pannel_id == JUMP_CONST["mercenary_levelup_panel"] then --佣兵经验界面
		graphic:DispatchEvent("show_world_sub_scene", "mercenary_levelup_sub_scene")
	elseif pannel_id == JUMP_CONST["guild_main"] then
        guild_logic:Query()
----------------------------------签到界面子界面---------------------------------
	elseif pannel_id == JUMP_CONST["daily_prayer"] then
		jump_finish[tostring(JUMP_CONST["check_daily"])] = function() 
	        graphic:DispatchEvent("change_daily_tab",2)  --祈祷 
		end
		self:GoToPannel(JUMP_CONST["check_daily"])  --先跳到签到界面
	elseif pannel_id == JUMP_CONST["daily_lchemy"] then
		jump_finish[tostring(JUMP_CONST["check_daily"])] = function() 
	        graphic:DispatchEvent("change_daily_tab",3)    --炼金
		end
		self:GoToPannel(JUMP_CONST["check_daily"])  --先跳到签到界面
	-------------------------------矿区子界面------------------------------
	elseif pannel_id == JUMP_CONST["mining_area"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
	        mining_logic:QueryBlockInfo()
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
	elseif pannel_id == JUMP_CONST["mining_work_shop"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
           	graphic:DispatchEvent("show_world_sub_scene", "quarry_sub_scene")
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
	elseif pannel_id == JUMP_CONST["mining_Tub"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
            escort_logic:QueryRobTargetList()
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
	elseif pannel_id == JUMP_CONST["mining_exploration"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
	        graphic:DispatchEvent("show_world_sub_scene", "cave_event_sub_scene", nil, CHOOSE_ETHER_CAVE)
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
	elseif pannel_id == JUMP_CONST["mining_troll_lair"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
           	graphic:DispatchEvent("show_world_sub_scene", "cave_event_sub_scene", nil, CHOOSE_MONSTER_CAVE)
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面		 
	elseif pannel_id == JUMP_CONST["mining_area_boss"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
			graphic:DispatchEvent("to_mining_boos")
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
 	elseif pannel_id == JUMP_CONST["mine_main"] then --先跳到矿区界面
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
			if mine_logic:GetMineAllRewardsList() then
				graphic:DispatchEvent("show_world_sub_scene", "mine_sub_scene")
			end
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面

	-------------------------------符文子界面-------------------------------	
	elseif pannel_id == JUMP_CONST["rune_crystal"] then 
		jump_finish[tostring(JUMP_CONST["rune"])] = function() 
			escort_logic:QueryRobTargetList()
		end
		self:GoToPannel(JUMP_CONST["rune"])  --先跳到符文界面
	elseif pannel_id == JUMP_CONST["rune_installation"] then 
		jump_finish[tostring(JUMP_CONST["rune"])] = function() 
			graphic:DispatchEvent("show_world_sub_scene", "rune_equip_sub_scene")
		end
		self:GoToPannel(JUMP_CONST["rune"])  --先跳到符文界面
-----------------------------------佣兵子界面-----------------------------------
	elseif pannel_id == JUMP_CONST["mercenary_dismissal"] then 
		jump_finish[tostring(JUMP_CONST["mercenary"])] = function() 
	        graphic:DispatchEvent("show_world_sub_scene", "mercenary_fire_sub_scene", SCENE_TRANSITION_TYPE["none"])
	    end
        self:GoToPannel(JUMP_CONST["mercenary"])  --先跳到佣兵界面
	elseif pannel_id == JUMP_CONST["mercenary_levelup_forge"] then 
		jump_finish[tostring(JUMP_CONST["mercenary_levelup_panel"])] = function()  
            graphic:DispatchEvent("change_to_forge") 
		end
		self:GoToPannel(JUMP_CONST["mercenary_levelup_panel"])  --先跳到佣兵经验界面
-----------------------------------PVP子界面------------------------------------
	elseif pannel_id == JUMP_CONST["pvp_arena"] then  --竞技场界面
		jump_finish[tostring(JUMP_CONST["pvp"])] = function() 
			graphic:DispatchEvent("change_to_sub_pvp",pannel_id)  
		end
		self:GoToPannel(JUMP_CONST["pvp"])  --先跳到pvp界面
	elseif pannel_id == JUMP_CONST["pvp_qualifying"] then
		jump_finish[tostring(JUMP_CONST["pvp"])] = function() 
			graphic:DispatchEvent("change_to_sub_pvp",pannel_id)  
		end
		self:GoToPannel(JUMP_CONST["pvp"])  --先跳到pvp界面
	elseif pannel_id == JUMP_CONST["pvp_campaign"] then
		jump_finish[tostring(JUMP_CONST["pvp"])] = function() 
			graphic:DispatchEvent("change_to_sub_pvp",pannel_id)  
		end
		self:GoToPannel(JUMP_CONST["pvp"])  --先跳到pvp界面
-------------------------------公会子界面--------------------------------------
    elseif pannel_id == JUMP_CONST["guild_boss"] then
        jump_finish[tostring(JUMP_CONST["guild_main"])] = function() 

         	if guild_logic.guild_cur_boss_id == nil then
	            guild_logic.query_boss_info = true
	            guild_logic:QueryGuildBossInfo() 
	            return 
	        end
	        graphic:DispatchEvent("show_world_sub_scene", "guild_boss_sub_scene") --跳到boss界面
	    end
        
        self:GoToPannel(JUMP_CONST["guild_main"])  
	elseif pannel_id == JUMP_CONST["guild_boss_shop"] then
	jump_finish[tostring(JUMP_CONST["guild_boss"])] = function() 

		local data = guild_logic:GetGuildBossExchangeRewardInfo()
		if data ~= nil then
            graphic:DispatchEvent("show_world_sub_panel", "guild.boss_exchange_reward_msgbox")
        end
  
	end
	self:GoToPannel(JUMP_CONST["guild_boss"])  --跳到boss界面

----------------------------------PVP三级子界面----------------------------------
	elseif pannel_id == JUMP_CONST["pvp_arena_exchange"] then
		jump_finish[tostring(JUMP_CONST["pvp_arena"])] = function() 
			 arena_logic:QueryExchangeConfig()  --跳到奖励界面
		end
		self:GoToPannel(JUMP_CONST["pvp_arena"])  --先跳到pvp界面
	elseif pannel_id == JUMP_CONST["pvp_war"] then
		jump_finish[tostring(JUMP_CONST["pvp_campaign"])] = function()  
			if campaign_logic:IsQueryRewardInfo() then
                campaign_logic:QueryRewardInfo()
            else
                graphic:DispatchEvent("show_world_sub_panel", "campaign_reward_msgbox")
            end
		end
		self:GoToPannel(JUMP_CONST["pvp_campaign"])  --先跳到pvp界面 
-------------------------------矿区三级界面------------------------------
	elseif pannel_id == JUMP_CONST["mining_shop"] then
		jump_finish[tostring(JUMP_CONST["mining"])] = function() 
	        mining_logic:QueryBlockInfo()
	        graphic:DispatchEvent("show_world_sub_panel", "ore_bag_panel", 2)
		end
		self:GoToPannel(JUMP_CONST["mining"])  --先跳到矿区界面
-------------------------------血钻替代资源----------------------------------
	elseif pannel_id == JUMP_CONST["blood_replace"] then
		if resource_id and lack_num and blood_replace_pre then
			graphic:DispatchEvent("show_blood_replace_panel", resource_id,lack_num,blood_replace_pre)
		end
	end
end

function jump:GetListData()
	return list_data
end

function jump:GetJumpResources()
	return jump_resources
end

return jump