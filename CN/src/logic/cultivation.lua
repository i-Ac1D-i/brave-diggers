--修炼信息

local network = require "util.network"
local config_manager = require "logic.config_manager"
local cultivation_config = config_manager.cultivation_config

local graphic = require "logic.graphic"
local utils = require "util.utils"
local lang_constants = require "util.language_constants"
local cultivation = {}

--一共六种修炼类型  每种类型有两种修炼方式（加成类和削减类）没类有四个等级（暂定）
function cultivation:Init()
	self.cultivation_info = nil 
	self:RegisterEvent()    
end

function cultivation:RegisterEvent()
    network:RegisterEvent("query_cultivation_info_ret", function(recv_msg) 
        self.cultivation_info = recv_msg.cultivation_states
    end)
    network:RegisterEvent("cultivate_ret", function(recv_msg) 
    	if recv_msg.result == "success" then
    		local cur_state = recv_msg.cur_state
    		if self.coefficient == 1 then
    			self.cultivation_info[self.selectType].coefficient1 = cur_state
    		else
    			self.cultivation_info[self.selectType].coefficient2 = cur_state
    		end
    		--graphic:DispatchEvent("show_world_sub_panel", "cultivation_levelup_msgbox", self.selectType)
    		graphic:DispatchEvent("update_cultivation")
    	else
    		graphic:DispatchEvent("show_prompt_panel", recv_msg.result)  ---TODO 
    	end
    end) 
end

function cultivation:SendCultivation(cultivation_type,coefficient_type) --修炼类型   coefficient1 加成 coefficient2 抵抗
	self.selectType = cultivation_type

	if coefficient_type == "coefficient1" then
		self.coefficient = 1
	else
		self.coefficient = 2
	end
	network:Send({cultivate = {cultivation_type = cultivation_type,coefficient_type = coefficient_type}})  
end

function cultivation:getCurStateByType(culType) --通过类型获得该类型两种修炼方式的信息（level）
	 return self.cultivation_info[culType]
end

function cultivation:getCurInfoByType(culType) --通过类型获得该类型两种修炼方式的信息（所有）--没有的
	 local info = {}
	 local temp1 = {}
	 local temp2 = {}
	 local level = self.cultivation_info[culType].coefficient1
	 if level and level > 0 then
	 	temp1["ID"] = tonumber(cultivation_config[culType][level].ID) 
	 	temp1["coefficient1"] = tonumber(cultivation_config[culType][level].coefficient1) 
	 	temp1["coefficient2"] = tonumber(cultivation_config[culType][level].coefficient2) 
	 	temp1["cost_nums"] = cultivation_config[culType][level].cost_nums
	 	temp1["cultivation_type"] = tonumber(cultivation_config[culType][level].cultivation_type) 
	 	temp1["level"] = tonumber(cultivation_config[culType][level].level) 
	 	temp1["resource_ids"] = cultivation_config[culType][level].resource_ids

	 	table.insert(info , temp1)
	 else
	 	table.insert(info , temp1)
	 end

	 level = self.cultivation_info[culType].coefficient2
	 if level and level > 0 then
	 	temp2["ID"] = tonumber(cultivation_config[culType][level].ID) 
	 	temp2["coefficient1"] = tonumber(cultivation_config[culType][level].coefficient1) 
	 	temp2["coefficient2"] = tonumber(cultivation_config[culType][level].coefficient2) 
	 	temp2["cost_nums"] = cultivation_config[culType][level].cost_nums
	 	temp2["cultivation_type"] = tonumber(cultivation_config[culType][level].cultivation_type) 
	 	temp2["level"] = tonumber(cultivation_config[culType][level].level) 
	 	temp2["resource_ids"] = cultivation_config[culType][level].resource_ids

	 	table.insert(info , temp2)
	 else
	 	table.insert(info , temp2)
	 end

	 return info 
end

function cultivation:getAttAddByLevel(culType,level) --获取指定类型 两种方式的 相应阶段 的总百分比
	local info = {}
	local add = cultivation_config[culType][level].coefficient1
	local sub = cultivation_config[culType][level].coefficient2
	table.insert(info,add)
	table.insert(info,sub)
	return info
end

function cultivation:getNewInfo(selectType)
	local newInfo = {}
	local selectInfo = self:getCurInfoByType(selectType)  
	for i=1,2 do
		local listInfo = {}
		local  curInfo = {}
		local  nextInfo = {} 
		if selectInfo[i].level and selectInfo[i].level > 0 then 
			curInfo.level = selectInfo[i].level
			local coefficient  = self:getAttAddByLevel(selectType,curInfo.level)[i]
			curInfo.coefficient = coefficient

			local nextLevel = curInfo.level + 1
			local next_info =  cultivation_config[selectType][nextLevel] 
			if next_info then
				nextInfo.nextLevel = nextLevel
				nextInfo.coefficient = self:getAttAddByLevel(selectType,nextLevel)[i]

				nextInfo.cost_nums =  utils:splitStr(next_info.cost_nums,"|")     
				nextInfo.resource_ids =  utils:splitStr(next_info.resource_ids,"|")     
			else
				nextInfo = nil
			end
		else
			curInfo.level = 0
			curInfo.coefficient = 0

			local nextLevel = curInfo.level + 1
			local next_info =  cultivation_config[selectType][nextLevel] 
			if next_info then
				nextInfo.nextLevel = nextLevel
				nextInfo.coefficient = self:getAttAddByLevel(selectType,nextLevel)[i]
				nextInfo.cost_nums = utils:splitStr(next_info.cost_nums,"|")    
				nextInfo.resource_ids = utils:splitStr(next_info.resource_ids,"|")  
			else
				nextInfo = nil
			end
		end
		listInfo["curInfo"] = curInfo
		listInfo["nextInfo"] = nextInfo
		table.insert(newInfo,listInfo)
	end
	return newInfo
end

return cultivation




