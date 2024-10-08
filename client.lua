local PlayerJob, Props, Targets, Peds, Blip, soundId = {}, {}, {}, {}, {}, GetSoundId()
AllItems = {}
------------------------------------------------------------
if Config.Inv == "ox" then
	for item, data in pairs(exports.ox_inventory:Items()) do
		AllItems[item] = data.label
	end
end

--Hide the mineshaft doors
---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
CreateModelHide(vec3(-596.04, 2089.01, 131.41), 10.5, -1241212535, true)

local function removeJob() -- 删除所有已存在的 Targets, Peds, Props 数据
	for k in pairs(Targets) do -- 预先删除已存在的目标
		exports['qb-target']:RemoveZone(k)
	end

	for _, v in pairs(Peds) do -- 预先删除已存在的任务模型
		unloadModel(GetEntityModel(v))
		DeletePed(v)
	end

	for i = 1, #Props do -- 预先删除已存在的实体模型
		unloadModel(GetEntityModel(Props[i]))
		DeleteObject(Props[i])
	end
	for i = 1, #Blip do RemoveBlip(Blip[i]) end
end

local function makeJob() -- 创建所有任务数据
	removeJob()

	for mine in pairs(Config.Locations["Mines"]) do -- 获取 Config.Locations 表内 ["Mines"] 预配置矿场数据
		local loc = Config.Locations["Mines"][mine]
		if loc.Enable then                           -- 判断是否开启整个矿场数据
			if loc.Blip.Enable then                    -- 判断是否开启 Blip
				Blip[#Blip + 1] = makeBlip(loc["Blip"])
			end

			if loc["OrePositions"] then -- 获取 Config.Locations["Mines"][mine]["OrePositions"] 矿场内矿石位置数据
				for i = 1, #loc["OrePositions"] do
					local name = "Ore" .. "_" .. mine .. "_" .. i
					local coords = loc["OrePositions"][i]
					local propTable = {
						{ full = "cs_x_rubweec", empty = "prop_rock_5_a" },
					}

					if Config.K4MB1Prop then
						propTable = {
							{ full = "k4mb1_crystalblue",  empty = "k4mb1_crystalempty" },
							{ full = "k4mb1_crystalgreen", empty = "k4mb1_crystalempty" },
							{ full = "k4mb1_crystalred",   empty = "k4mb1_crystalempty" },
							{ full = "k4mb1_copperore2",   empty = "k4mb1_emptyore2" },
							{ full = "k4mb1_ironore2",     empty = "k4mb1_emptyore2" },
							{ full = "k4mb1_goldore2",     empty = "k4mb1_emptyore2" },
							{ full = "k4mb1_leadore2",     empty = "k4mb1_emptyore2" },
							{ full = "k4mb1_tinore2",      empty = "k4mb1_emptyore2" },
						}
					end

					-- 根据坐标创建所有矿石模型, 并重新设置其旋转角度
					local propPick = propTable[math.random(1, #propTable)]
					Props[#Props + 1] = makeProp({ coords = vec4(coords.x, coords.y, coords.z + (not Config.K4MB1Prop and 1.10 or 0.8), coords.a), prop = propPick.full }, 1, false)
					local rot = GetEntityRotation(Props[#Props])
					rot = vec3(rot.x - math.random(60, 100), rot.y, rot.z)
					SetEntityRotation(Props[#Props], rot.x, rot.y, rot.z, 0, false)

					Targets[name] = exports['qb-target']:AddCircleZone(name, vec3(coords.x, coords.y, coords.z), 1.2, { name = name, debugPoly = Config.Debug, useZ = true, }, {
						options = {
							{ event = "jim-mining:MineOre:Pick",  icon = "fas fa-hammer",             item = "pickaxe",     label = Loc[Config.Lan].info["mine_ore"] .. AllItems["pickaxe"],     job = loc.Job, name = name, stone = Props[#Props] },
							{ event = "jim-mining:MineOre:Drill", icon = "fas fa-screwdriver",        item = "miningdrill", label = Loc[Config.Lan].info["mine_ore"] .. AllItems["miningdrill"], job = loc.Job, name = name, stone = Props[#Props] },
							{ event = "jim-mining:MineOre:Laser", icon = "fas fa-screwdriver-wrench", item = "mininglaser", label = Loc[Config.Lan].info["mine_ore"] .. AllItems["mininglaser"], job = loc.Job, name = name, stone = Props[#Props] },
						},
						distance = 1.7
					})

					Props[#Props + 1] = makeProp({ coords = vec4(coords.x, coords.y, coords.z + (not Config.K4MB1Prop and 1.1 or 0.8), coords.a), prop = propPick.empty }, 1, false)
					SetEntityRotation(Props[#Props], rot.x, rot.y, rot.z, 0, false)
				end
			end

			if loc["Lights"] then -- 添加灯光模型及其效果
				if loc["Lights"].Enable then
					for i = 1, #loc["Lights"].positions do
						Props[#Props + 1] = makeProp({ coords = loc["Lights"].positions[i], prop = loc["Lights"].prop }, 1, false)
					end
				end
			end

			if loc["Store"] then -- 添加商店
				for i = 1, #loc["Store"] do
					local name = "Store" .. "_" .. mine .. "_" .. i
					Peds[#Peds + 1] = makePed(loc["Store"][i].model, loc["Store"][i].coords, 1, 1, loc["Store"][i].scenario)
					Targets[name] = exports['qb-target']:AddCircleZone(name, loc["Store"][i].coords.xyz, 1.0, { name = name, debugPoly = Config.Debug, useZ = true, }, {
						options = { { event = "jim-mining:openShop", icon = "fas fa-store", label = Loc[Config.Lan].info["browse_store"], job = loc.Job, ped = Peds[#Peds] }, },
						distance = 2.0
					})
				end
			end

			if loc["Smelting"] then -- 添加熔炉冶炼
				for i = 1, #loc["Smelting"] do
					local name = "Smelting" .. "_" .. mine .. "_" .. i
					if loc["Smelting"][i].blipEnable then Blip[#Blip + 1] = makeBlip(loc["Smelting"][i]) end
					Targets[name] = exports['qb-target']:AddCircleZone(name, loc["Smelting"][i].coords.xyz, 3.0, { name = name, debugPoly = Config.Debug, useZ = true, }, {
						options = { { event = "jim-mining:CraftMenu", icon = "fas fa-fire-burner", label = Loc[Config.Lan].info["use_smelter"], craftable = Crafting.SmeltMenu, job = loc.Job }, },
						distance = 10.0
					})
				end
			end

			if loc["Cracking"] then
				for i = 1, #loc["Cracking"] do
					local name = "Cracking" .. "_" .. mine .. "_" .. i
					if loc["Cracking"][i].blipEnable then Blip[#Blip + 1] = makeBlip(loc["Cracking"][i]) end
					Props[#Props + 1] = makeProp(loc["Cracking"][i], 1, false)
					Targets[name] = exports['qb-target']:AddTargetEntity(Props[#Props], {
						options = {
							{ event = "jim-mining:CrackStart", icon = "fas fa-compact-disc", item = "stone", label = Loc[Config.Lan].info["crackingbench"], bench = Props[#Props] },
						},
						distance = 2.0
					})
				end
			end

			if loc["OreBuyer"] then -- 添加矿石售卖点
				for i = 1, #loc["OreBuyer"] do
					local name = "OreBuyer" .. "_" .. mine .. "_" .. i
					Peds[#Peds + 1] = makePed(loc["OreBuyer"][i].model, loc["OreBuyer"][i].coords, 1, 1, loc["OreBuyer"][i].scenario)
					if loc["OreBuyer"][i].blipEnable then Blip[#Blip + 1] = makeBlip(loc["OreBuyer"][i]) end
					Targets[name] = exports['qb-target']:AddCircleZone(name, loc["OreBuyer"][i].coords.xyz, 0.9, { name = name, debugPoly = Config.Debug, useZ = true, }, {
						options = { { event = "jim-mining:SellOre", icon = "fas fa-sack-dollar", label = Loc[Config.Lan].info["sell_ores"], ped = Peds[#Peds], job = Config.Job }, },
						distance = 2.0
					})
				end
			end

			if loc["JewelCut"] then
				for i = 1, #loc["JewelCut"] do
					local name = "JewelCut" .. "_" .. mine .. "_" .. i
					if loc["JewelCut"][i].blipEnable then Blip[#Blip + 1] = makeBlip(loc["JewelCut"][i]) end
					Props[#Props + 1] = makeProp(loc["JewelCut"][i], 1, false)
					Targets[name] = exports['qb-target']:AddTargetEntity(Props[#Props], {
						options = {
							{ event = "jim-mining:JewelCut", icon = "fas fa-gem", label = Loc[Config.Lan].info["jewelcut"], bench = Props[#Props], job = Config.Job },
						},
						distance = 2.0
					})
				end
			end
		end
	end

	--[[Stone Washing]] --
	if Config.Locations["Washing"].Enable then -- 获取 Config.Locations 表内 ["Washing"] 预配置洗石数据
		for k, v in pairs(Config.Locations["Washing"].positions) do
			local name = "Washing" .. k

			Targets[name] = exports['qb-target']:AddCircleZone(name, v.coords.xyz, 9.0, { name = name, debugPoly = Config.Debug, useZ = true, }, {
				options = { { event = "jim-mining:WashStart", icon = "fas fa-hands-bubbles", item = "stone", label = Loc[Config.Lan].info["washstone"], coords = v.coords }, },
				distance = 2.0
			})

			if v.blipEnable then
				Blip[#Blip + 1] = makeBlip(v)
			end
		end
	end

	--[[Panning]] --
	if Config.Locations["Panning"].Enable then
		for location in pairs(Config.Locations["Panning"].positions) do
			local loc = Config.Locations["Panning"].positions[location]

			if loc.Blip.Enable then
				Blip[#Blip + 1] = makeBlip(loc["Blip"])
			end

			for i = 1, #loc.Positions do
				local name = "Panning" .. location .. i

				Targets[name] = exports['qb-target']:AddBoxZone(name, loc.Positions[i].coords.xyz, loc.Positions[i].w, loc.Positions[i].d, { name = name, heading = loc.Positions[i].coords.w, debugPoly = Config.Debug, minZ = loc.Positions[i].coords.z - 10.0, maxZ = loc.Positions[i].coords.z + 10.0 }, {
					options = {
						{
							event = "jim-mining:PanStart",
							icon = "fas fa-ring",
							item = "goldpan",
							label = Loc[Config.Lan].info["goldpan"],
							coords = loc.Positions[i].coords
						},
					},
					distance = 2.0
				})
			end
		end
	end

	--[[Jewel Buyer]] --
	if Config.Locations["JewelBuyer"].Enable then
		for k, v in pairs(Config.Locations["JewelBuyer"].positions) do
			Peds[#Peds + 1] = makePed(v.model, v.coords, 1, 1, v.scenario)

			Targets["JewelBuyer" .. k] = exports['qb-target']:AddCircleZone("JewelBuyer" .. k, v.coords.xyz, 1.2, { name = "JewelBuyer" .. k, debugPoly = Config.Debug, useZ = true, }, {
				options = { { event = "jim-mining:JewelSell", icon = "fas fa-gem", label = Loc[Config.Lan].info["jewelbuyer"], ped = Peds[#Peds], job = Config.Job }, },
				distance = 2.0
			})
		end
	end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, _, _)
	PlayerJob = xPlayer.job

	if Config.Job then
		if PlayerJob.name == Config.Job then
			makeJob()
		else
			removeJob()
		end
	else
		makeJob()
	end
end)

RegisterNetEvent('esx:setJob', function(job, _)
	PlayerJob = job

	if Config.Job then
		if PlayerJob.name == Config.Job then
			makeJob()
		else
			removeJob()
		end
	end
end)

AddEventHandler('onResourceStart', function(resource)
	if GetCurrentResourceName() ~= resource then return end

	PlayerJob = ESX.GetPlayerData().job

	if Config.Job then
		if PlayerJob.name == Config.Job then
			makeJob()
		else
			removeJob()
		end
	else
		makeJob()
	end
end)

--------------------------------------------------------
RegisterNetEvent('jim-mining:openShop', function(data)
	local event = "inventory:server:OpenInventory"

	if Config.JimShops then
		event = "jim-shops:ShopOpen"
	elseif Config.Inv == "ox" then
		exports.ox_inventory:openInventory('shop', { type = 'miningShop' })
	end

	TriggerServerEvent(event, "shop", "miningShop", Config.Items)
	lookEnt(data.ped)
end)

local function stoneBreak(name, stone)
	CreateThread(function()
		local rockcoords = GetEntityCoords(stone)

		if Config.Debug then
			print("^5Debug^7: ^2Hiding prop and target^7: '^6" .. name .. "^7' ^2at coords^7: ^6" .. rockcoords)
		end

		-- 矿石进入冷却并等待CD时间后重新生成矿石
		SetEntityAlpha(stone, 0)
		exports['qb-target']:RemoveZone(name)
		Targets[name] = nil
		Wait(Config.Debug and 2000 or Config.Timings["OreRespawn"])

		-- 完成冷却后取消隐藏矿石并创建新的目标位置
		SetEntityAlpha(stone, 255)
		Targets[name] = exports['qb-target']:AddCircleZone(name, vec3(rockcoords.x, rockcoords.y, rockcoords.z), 1.2, { name = name, debugPoly = Config.Debug, useZ = true, }, {
			options = {
				{ event = "jim-mining:MineOre:Pick",  icon = "fas fa-hammer",             item = "pickaxe",     label = Loc[Config.Lan].info["mine_ore"] .. AllItems["pickaxe"],     job = Config.Job, name = name, stone = stone },
				{ event = "jim-mining:MineOre:Drill", icon = "fas fa-screwdriver",        item = "miningdrill", label = Loc[Config.Lan].info["mine_ore"] .. AllItems["miningdrill"], job = Config.Job, name = name, stone = stone },
				{ event = "jim-mining:MineOre:Laser", icon = "fas fa-screwdriver-wrench", item = "mininglaser", label = Loc[Config.Lan].info["mine_ore"] .. AllItems["mininglaser"], job = Config.Job, name = name, stone = stone },
			},
			distance = 1.3
		})

		if Config.Debug then
			print("^5Debug^7: ^2Remaking Prop and Target^7: '^6" .. name .. "^7' ^2at coords^7: ^6" .. rockcoords)
		end
	end)
end

local isMining = false
RegisterNetEvent('jim-mining:MineOre:Pick', function(data)
	local Ped = PlayerPedId()

	if isMining then return else isMining = true end -- 阻止玩家将事件翻倍

	-- 人物动画加载
	local dict = "amb@world_human_hammering@male@base"
	local anim = "base"
	loadAnimDict(tostring(dict))
	loadDrillSound()

	-- 创建镐头并链接玩家
	local PickAxe = makeProp({ prop = "prop_tool_pickaxe", coords = vec4(0, 0, 0, 0) }, 0, 1)
	DisableCamCollisionForObject(PickAxe)
	DisableCamCollisionForEntity(PickAxe)
	AttachEntityToEntity(PickAxe, Ped, GetPedBoneIndex(Ped, 57005), 0.09, -0.53, -0.22, 252.0, 180.0, 0.0, false, true, true, true, 0, true)
	local IsDrilling = true
	local rockcoords = GetEntityCoords(data.stone)

	-- 使人物朝向矿石
	lookEnt(data.stone)
	if #(rockcoords - GetEntityCoords(Ped)) > 1.5 then
		TaskGoStraightToCoord(Ped, rockcoords, 0.5, 400, 0.0, 0)
		Wait(400)
	end

	-- 加载粒子特效并开始动画
	loadPtfxDict("core")
	CreateThread(function()
		while IsDrilling do
			UseParticleFxAssetNextCall("core")
			TaskPlayAnim(Ped, tostring(dict), tostring(anim), 8.0, -8.0, -1, 2, 0, false, false, false)
			Wait(200)
			local pickcoords = GetOffsetFromEntityInWorldCoords(PickAxe, -0.4, 0.0, 0.7)
			local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", pickcoords.x, pickcoords.y, pickcoords.z, 0.0, 0.0, 0.0, 0.4, 0.0, 0.0, 0.0)
			Wait(350)
		end
	end)

	if progressBar({ label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Pickaxe"], cancel = true, icon = "pickaxe" }) then
		TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil })
		if math.random(1, 10) >= 9 then
			local breakId = GetSoundId()
			PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", true, 0)
			toggleItem(false, "pickaxe", 1)
		end
		stoneBreak(data.name, data.stone)
	end

	StopAnimTask(Ped, tostring(dict), tostring(anim), 1.0)
	destroyProp(PickAxe)
	unloadPtfxDict("core")
	unloadAnimDict(dict)
	unloadDrillSound()
	StopSound(soundId)

	IsDrilling = false
	isMining = false
end)

RegisterNetEvent('jim-mining:MineOre:Drill', function(data)
	local Ped = PlayerPedId()

	if isMining then return else isMining = true end -- 阻止玩家将事件翻倍

	if HasItem("drillbit", 1) then
		-- 加载声音和动画
		loadDrillSound()
		local dict = "anim@heists@fleeca_bank@drilling"
		local anim = "drill_straight_fail"
		loadAnimDict(tostring(dict))

		-- 创建钻探并链接玩家
		local DrillObject = makeProp({ prop = "hei_prop_heist_drill", coords = vec4(0, 0, 0, 0) }, 0, 1)
		AttachEntityToEntity(DrillObject, Ped, GetPedBoneIndex(Ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
		local IsDrilling = true
		local rockcoords = GetEntityCoords(data.stone)

		--计算当前朝向是否在 20.0 度范围内
		lookEnt(data.stone)
		if #(rockcoords - GetEntityCoords(Ped)) > 1.5 then
			TaskGoStraightToCoord(Ped, rockcoords, 0.5, 400, 0.0, 0)
			Wait(400)
		end
		TaskPlayAnim(Ped, tostring(dict), tostring(anim), 3.0, 3.0, -1, 1, 0, false, false, false)
		Wait(200)
		if Config.DrillSound then PlaySoundFromEntity(soundId, "Drill", DrillObject, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0) end
		CreateThread(function() -- Dust/Debris Animation
			loadPtfxDict("core")
			while IsDrilling do
				UseParticleFxAssetNextCall("core")
				local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", rockcoords.x, rockcoords.y, rockcoords.z, 0.0, 0.0, GetEntityHeading(Ped) - 180.0, 1.0, 0.0, 0.0, 0.0)
				Wait(600)
			end
		end)
		if progressBar({ label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Pickaxe"], cancel = true, icon = "pickaxe" }) then
			TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil })
			--Destroy drill bit chances
			if math.random(1, 10) >= 8 then
				local breakId = GetSoundId()
				PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
				toggleItem(0, "drillbit", 1)
				stoneBreak(data.name, data.stone)
			end
		end
		StopAnimTask(Ped, "anim@heists@fleeca_bank@drilling", "drill_straight_idle", 1.0)
		unloadDrillSound()
		StopSound(soundId)
		destroyProp(DrillObject)
		unloadPtfxDict("core")
		unloadAnimDict(dict)
		IsDrilling = false
		isMining = false
	else
		triggerNotify(nil, Loc[Config.Lan].error["no_drillbit"], nil)
		isMining = false
		return
	end
end)

RegisterNetEvent('jim-mining:MineOre:Laser', function(data)
	local Ped = PlayerPedId()
	if isMining then return else isMining = true end -- 阻止玩家将事件翻倍
	-- Sounds & Anim Loading
	RequestAmbientAudioBank("DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS", 0)
	RequestAmbientAudioBank("dlc_xm_silo_laser_hack_sounds", 0)
	local dict = "anim@heists@fleeca_bank@drilling"
	local anim = "drill_straight_fail"
	loadAnimDict(dict)
	--Create Drill and Attach
	local DrillObject = makeProp({ prop = "ch_prop_laserdrill_01a", coords = vec4(0, 0, 0, 0) }, 0, 1)
	AttachEntityToEntity(DrillObject, Ped, GetPedBoneIndex(Ped, 57005), 0.14, 0, -0.01, 90.0, -90.0, 180.0, true, true, false, true, 1, true)
	local IsDrilling = true
	local rockcoords = GetEntityCoords(data.stone)
	--Calculate if you're facing the stone--
	lookEnt(data.stone)
	--Activation noise & Anims
	TaskPlayAnim(Ped, tostring(dict), 'drill_straight_idle', 3.0, 3.0, -1, 1, 0, false, false, false)
	PlaySoundFromEntity(soundId, "Pass", DrillObject, "dlc_xm_silo_laser_hack_sounds", 1, 0)
	Wait(1000)
	TaskPlayAnim(Ped, tostring(dict), tostring(anim), 3.0, 3.0, -1, 1, 0, false, false, false)
	PlaySoundFromEntity(soundId, "EMP_Vehicle_Hum", DrillObject, "DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS", 1, 0) --Not sure about this sound, best one I could find as everything else wouldn't load
	--Laser & Debris Effect
	local lasercoords = GetOffsetFromEntityInWorldCoords(DrillObject, 0.0, -0.5, 0.02)
	CreateThread(function()
		loadPtfxDict("core")
		while IsDrilling do
			UseParticleFxAssetNextCall("core")
			local laser = StartNetworkedParticleFxNonLoopedAtCoord("muz_railgun", lasercoords.x, lasercoords.y, lasercoords.z, 0, -10.0, GetEntityHeading(DrillObject) + 270, 1.0, 0.0, 0.0, 0.0)
			UseParticleFxAssetNextCall("core")
			local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", rockcoords.x, rockcoords.y, rockcoords.z, 0.0, 0.0, GetEntityHeading(Ped) - 180.0, 1.0, 0.0, 0.0, 0.0)
			Wait(60)
		end
	end)
	if progressBar({ label = Loc[Config.Lan].info["drilling_ore"], time = Config.Debug and 1000 or Config.Timings["Laser"], cancel = true, icon = "mininglaser" }) then
		TriggerServerEvent('jim-mining:Reward', { mine = true, cost = nil })
		stoneBreak(data.name, data.stone)
	end
	IsDrilling = false
	isMining = false
	StopAnimTask(Ped, tostring(dict), tostring(anim), 1.0)
	ReleaseAmbientAudioBank("DLC_HEIST_BIOLAB_DELIVER_EMP_SOUNDS")
	ReleaseAmbientAudioBank("dlc_xm_silo_laser_hack_sounds")
	StopSound(soundId)
	destroyProp(DrillObject)
	unloadPtfxDict("core")
	unloadAnimDict(dict)
end)
------------------------------------------------------------
-- Cracking Command / Animations
local Cracking = false
RegisterNetEvent('jim-mining:CrackStart', function(data)
	local Ped = PlayerPedId()
	if Cracking then return end
	local cost = 1
	if HasItem("stone", cost) then
		Cracking = true
		lockInv(true)
		-- Sounds & Anim Loading
		local dict = "amb@prop_human_parking_meter@male@idle_a"
		local anim = "idle_a"
		loadAnimDict(dict)
		loadDrillSound()
		local benchcoords = GetOffsetFromEntityInWorldCoords(data.bench, 0.0, -0.2, 2.08)
		--Calculate if you're facing the bench--
		lookEnt(data.bench)
		if #(benchcoords - GetEntityCoords(Ped)) > 1.5 then
			TaskGoStraightToCoord(Ped, benchcoords, 0.5, 400, 0.0, 0)
			Wait(400)
		end
		local Rock = makeProp({ prop = "prop_rock_5_smash1", coords = vec4(benchcoords.x, benchcoords.y, benchcoords.z, 0) }, 0, 1)
		if Config.DrillSound then PlaySoundFromCoord(soundId, "Drill", benchcoords, "DLC_HEIST_FLEECA_SOUNDSET", 0, 4.5, 0) end
		loadPtfxDict("core")
		CreateThread(function()
			while Cracking do
				UseParticleFxAssetNextCall("core")
				local dust = StartNetworkedParticleFxNonLoopedAtCoord("ent_dst_rocks", benchcoords.x, benchcoords.y, benchcoords.z - 0.9, 0.0, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0)
				Wait(400)
			end
		end)
		TaskPlayAnim(Ped, dict, anim, 3.0, 3.0, -1, 1, 0, false, false, false)
		if progressBar({ label = Loc[Config.Lan].info["cracking_stone"], time = Config.Debug and 1000 or Config.Timings["Cracking"], cancel = true, icon = "stone" }) then
			TriggerServerEvent('jim-mining:Reward', { crack = true, cost = cost })
		end
		StopAnimTask(Ped, dict, anim, 1.0)
		unloadDrillSound()
		StopSound(soundId)
		unloadPtfxDict("core")
		unloadAnimDict(dict)
		destroyProp(Rock)
		lockInv(false)
		Cracking = false
	else
		triggerNotify(nil, Loc[Config.Lan].error["no_stone"], 'error')
	end
end)
------------------------------------------------------------
-- Washing Command / Animations
local Washing = false
RegisterNetEvent('jim-mining:WashStart', function(data)
	local Ped = PlayerPedId()
	if Washing then return end
	local cost = 1
	if HasItem("stone", cost) then
		Washing = true
		lockInv(true)
		--Create Rock and Attach
		local Rock = makeProp({ prop = "prop_rock_5_smash1", coords = vec4(0, 0, 0, 0) }, 0, 1)
		AttachEntityToEntity(Rock, Ped, GetPedBoneIndex(Ped, 60309), 0.1, 0.0, 0.05, 90.0, -90.0, 90.0, true, true, false, true, 1, true)
		TaskStartScenarioInPlace(Ped, "PROP_HUMAN_BUM_BIN", 0, true)
		local water
		CreateThread(function()
			Wait(3000)
			loadPtfxDict("core")
			while Washing do
				UseParticleFxAssetNextCall("core")
				water = StartNetworkedParticleFxLoopedOnEntity("water_splash_veh_out", PlayerPedId(), 0.0, 1.0, -0.2, 0.0, 0.0, 0.0, 2.0, 0, 0, 0)
				Wait(500)
			end
		end)
		if progressBar({ label = Loc[Config.Lan].info["washing_stone"], time = Config.Debug and 1000 or Config.Timings["Washing"], cancel = true, icon = "stone" }) then
			TriggerServerEvent('jim-mining:Reward', { wash = true, cost = cost })
		end
		lockInv(false)
		StopParticleFxLooped(water, 0)
		destroyProp(Rock)
		unloadPtfxDict("core")
		Washing = false
		ClearPedTasks(Ped)
	else
		triggerNotify(nil, Loc[Config.Lan].error["no_stone"], 'error')
	end
end)
------------------------------------------------------------
-- Gold Panning Command / Animations
local Panning = false
RegisterNetEvent('jim-mining:PanStart', function(data)
	local Ped = PlayerPedId()
	if Panning then return else Panning = true end
	lockInv(true)
	--Create Rock and Attach
	local trayCoords = GetOffsetFromEntityInWorldCoords(Ped, 0.0, 0.5, -0.9)
	Props[#Props + 1] = makeProp({ coords = vec4(trayCoords.x, trayCoords.y, trayCoords.z + 1.03, GetEntityHeading(Ped)), prop = `bkr_prop_meth_tray_01b` }, 1, 1)
	CreateThread(function()
		loadPtfxDict("core")
		while Panning do
			UseParticleFxAssetNextCall("core")
			local water = StartNetworkedParticleFxLoopedOnEntity("water_splash_veh_out", Props[#Props], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0, 0, 0)
			Wait(100)
		end
	end)
	--Start Anim
	TaskStartScenarioInPlace(Ped, "CODE_HUMAN_MEDIC_KNEEL", 0, true)
	if progressBar({ label = Loc[Config.Lan].info["goldpanning"], time = Config.Debug and 1000 or Config.Timings["Panning"], cancel = true, icon = "goldpan" }) then
		TriggerServerEvent('jim-mining:Reward', { pan = true, cost = nil })
	end
	ClearPedTasksImmediately(Ped)
	destroyProp(Props[#Props])
	unloadPtfxDict("core")
	lockInv(false)
	Panning = false
end)

------------------------------------------------------------
--Selling animations are simply a pass item to seller animation
RegisterNetEvent('jim-mining:SellAnim', function(data)
	local Ped = PlayerPedId()
	if not HasItem(data.item, 1) then
		triggerNotify(nil, Loc[Config.Lan].error["dont_have"] .. " " .. AllItems[data.item], 'error')
		return
	end
	for k, v in pairs(GetGamePool('CObject')) do
		for _, model in pairs({ `p_cs_clipboard` }) do
			if GetEntityModel(v) == model then
				if IsEntityAttachedToEntity(data.ped, v) then
					DeleteObject(v)
					DetachEntity(v, 0, 0)
					SetEntityAsMissionEntity(v, true, true)
					Wait(100)
					DeleteEntity(v)
				end
			end
		end
	end
	loadAnimDict("mp_common")
	TriggerServerEvent('jim-mining:Selling', data) -- Had to slip in the sell command during the animation command
	loadAnimDict("mp_common")
	lookEnt(data.ped)
	TaskPlayAnim(Ped, "mp_common", "givetake2_a", 100.0, 200.0, 0.3, 1, 0.2, 0, 0, 0) --Start animations
	TaskPlayAnim(data.ped, "mp_common", "givetake2_b", 100.0, 200.0, 0.3, 1, 0.2, 0, 0, 0)
	Wait(2000)
	StopAnimTask(Ped, "mp_common", "givetake2_a", 1.0)
	StopAnimTask(data.ped, "mp_common", "givetake2_b", 1.0)
	unloadAnimDict("mp_common")
	if data.sub then
		TriggerEvent('jim-mining:JewelSell:Sub', { sub = data.sub, ped = data.ped })
		return
	else
		TriggerEvent('jim-mining:SellOre', data)
		return
	end
end)

------------------------------------------------------------
RegisterNetEvent('jim-mining:SellOre', function(data)
	local sellMenu = {}
	if Config.Menu == "qb" then
		sellMenu[#sellMenu + 1] = { header = Loc[Config.Lan].info["header_oresell"], txt = Loc[Config.Lan].info["oresell_txt"], isMenuHeader = true }
		sellMenu[#sellMenu + 1] = { icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].info["close"], params = { event = "jim-mining:CraftMenu:Close" } }
	end
	for _, v in pairs(Config.OreSell) do
		local setheader = AllItems[v]
		local disable = true
		if HasItem(v, 1) then
			setheader = setheader .. " 💰"
			disable = false
		end
		sellMenu[#sellMenu + 1] = {
			icon = "nui://" .. Config.img .. v .. ".png",
			disabled = disable,
			header = setheader,
			txt = Loc[Config.Lan].info["sell_all"] .. " " .. Config.SellingPrices[v] .. " " .. Loc[Config.Lan].info["sell_each"],
			params = { event = "jim-mining:SellAnim", args = { item = v, ped = data.ped } },
			title = setheader,
			description = Loc[Config.Lan].info["sell_all"] .. " " .. Config.SellingPrices[v] .. " " .. Loc[Config.Lan].info["sell_each"],
			event = "jim-mining:SellAnim",
			args = { item = v, ped = data.ped },
		}
		Wait(0)
	end
	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'sellMenu', title = Loc[Config.Lan].info["header_oresell"], position = 'top-right', options = sellMenu })
		exports.ox_lib:showContext("sellMenu")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(sellMenu)
	end
	lookEnt(data.ped)
end)
------------------------
--Jewel Selling Main Menu
RegisterNetEvent('jim-mining:JewelSell', function(data)
	local sellMenu = {}
	if Config.Menu == "qb" then
		sellMenu[#sellMenu + 1] = { header = Loc[Config.Lan].info["jewel_buyer"], txt = Loc[Config.Lan].info["sell_jewel"], isMenuHeader = true }
		sellMenu[#sellMenu + 1] = { icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].info["close"], params = { event = "jim-mining:CraftMenu:Close" } }
	end
	local table = {
		{ title = AllItems["emerald"],               sub = "emerald" },
		{ title = AllItems["ruby"],                  sub = "ruby" },
		{ title = AllItems["diamond"],               sub = "diamond" },
		{ title = AllItems["sapphire"],              sub = "sapphire" },
		{ title = Loc[Config.Lan].info["rings"],     sub = "rings" },
		{ title = Loc[Config.Lan].info["necklaces"], sub = "necklaces" },
		{ title = Loc[Config.Lan].info["earrings"],  sub = "earrings" },
	}
	for i = 1, #table do
		sellMenu[#sellMenu + 1] = {
			header = table[i].title,
			txt = Loc[Config.Lan].info["see_options"],
			params = { event = "jim-mining:JewelSell:Sub", args = { sub = table[i].sub, ped = data.ped } },
			title = table[i].title,
			description = Loc[Config.Lan].info["see_options"],
			event = "jim-mining:JewelSell:Sub",
			args = { sub = table[i].sub, ped = data.ped }
		}
	end
	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'sellMenu', title = Loc[Config.Lan].info["jewel_buyer"], position = 'top-right', options = sellMenu })
		exports.ox_lib:showContext("sellMenu")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(sellMenu)
	end
	lookEnt(data.ped)
end)
--Jewel Selling - Sub Menu Controller
RegisterNetEvent('jim-mining:JewelSell:Sub', function(data)
	local list = {}
	local sellMenu = {}
	if Config.Menu == "qb" then
		sellMenu[#sellMenu + 1] = { header = Loc[Config.Lan].info["jewel_buyer"], txt = Loc[Config.Lan].info["sell_jewel"], isMenuHeader = true }
	end
	sellMenu[#sellMenu + 1] = {
		icon = "fas fa-circle-arrow-left",
		header = "",
		txt = Loc[Config.Lan].info["return"],
		params = { event = "jim-mining:JewelSell", args = data },
		title = Loc[Config.Lan].info["return"],
		event = "jim-mining:JewelSell",
		args = data
	}
	local table = {
		["emerald"] = { "emerald", "uncut_emerald" },
		["ruby"] = { "ruby", "uncut_ruby" },
		["diamond"] = { "diamond", "uncut_diamond" },
		["sapphire"] = { "sapphire", "uncut_sapphire" },
		["rings"] = { "gold_ring", "silver_ring", "diamond_ring", "emerald_ring", "ruby_ring", "sapphire_ring", "diamond_ring_silver", "emerald_ring_silver", "ruby_ring_silver", "sapphire_ring_silver" },
		["necklaces"] = { "goldchain", "silverchain", "diamond_necklace", "emerald_necklace", "ruby_necklace", "sapphire_necklace", "diamond_necklace_silver", "emerald_necklace_silver", "ruby_necklace_silver", "sapphire_necklace_silver" },
		["earrings"] = { "gold_earring", "silverearring", "diamond_earring", "emerald_earring", "ruby_earring", "sapphire_earring", "diamond_earring_silver", "emerald_earring_silver", "ruby_earring_silver", "sapphire_earring_silver" },
	}
	for _, v in pairs(table[data.sub]) do
		local disable = true
		local setheader = AllItems[v]
		if HasItem(v, 1) then
			setheader = setheader .. " 💰"
			disable = false
		end
		sellMenu[#sellMenu + 1] = {
			disabled = disable,
			icon = "nui://" .. Config.img .. v .. ".png",
			header = setheader,
			txt = Loc[Config.Lan].info["sell_all"] .. " " .. Config.SellingPrices[v] .. " " .. Loc[Config.Lan].info["sell_each"],
			params = { event = "jim-mining:SellAnim", args = { item = v, sub = data.sub, ped = data.ped } },
			title = setheader,
			description = Loc[Config.Lan].info["sell_all"] .. " " .. Config.SellingPrices[v] .. " " .. Loc[Config.Lan].info["sell_each"],
			event = "jim-mining:SellAnim",
			args = { item = v, sub = data.sub, ped = data.ped }
		}
		Wait(0)
	end
	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'sellMenu', title = Loc[Config.Lan].info["jewel_buyer"], position = 'top-right', options = sellMenu })
		exports.ox_lib:showContext("sellMenu")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(sellMenu)
	end
	lookEnt(data.ped)
end)
--Cutting Jewels
RegisterNetEvent('jim-mining:JewelCut', function(data)
	local cutMenu = {}
	if Config.Menu == "qb" then
		cutMenu[#cutMenu + 1] = { header = Loc[Config.Lan].info["craft_bench"], txt = Loc[Config.Lan].info["req_drill_bit"], isMenuHeader = true }
		cutMenu[#cutMenu + 1] = { icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].info["close"], params = { event = "jim-mining:CraftMenu:Close" } }
	end
	local table = {
		{ header = Loc[Config.Lan].info["gem_cut"],   txt = Loc[Config.Lan].info["gem_cut_section"],    craftable = Crafting.GemCut, },
		{ header = Loc[Config.Lan].info["make_ring"], txt = Loc[Config.Lan].info["ring_craft_section"], craftable = Crafting.RingCut, },
		{ header = Loc[Config.Lan].info["make_neck"], txt = Loc[Config.Lan].info["neck_craft_section"], craftable = Crafting.NeckCut, },
		{ header = Loc[Config.Lan].info["make_ear"],  txt = Loc[Config.Lan].info["ear_craft_section"],  craftable = Crafting.EarCut, },
	}
	for i = 1, #table do
		cutMenu[#cutMenu + 1] = {
			header = table[i].header,
			txt = table[i].txt,
			params = { event = "jim-mining:CraftMenu", args = { craftable = table[i].craftable, ret = true, bench = data.bench } },
			title = table[i].header,
			description = table[i].txt,
			event = "jim-mining:CraftMenu",
			args = { craftable = table[i].craftable, ret = true, bench = data.bench },
		}
	end
	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'cutMenu', title = Loc[Config.Lan].info["craft_bench"], position = 'top-right', options = cutMenu })
		exports.ox_lib:showContext("cutMenu")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(cutMenu)
	end
end)

RegisterNetEvent('jim-mining:CraftMenu', function(data)
	local CraftMenu = {}
	local header = (data and data.ret) and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"]
	if data.ret then
		if Config.Menu == "qb" then
			CraftMenu[#CraftMenu + 1] = { header = header, txt = Loc[Config.Lan].info["req_drill_bit"], isMenuHeader = true }
		end
		CraftMenu[#CraftMenu + 1] = { icon = "fas fa-circle-arrow-left", header = "", txt = Loc[Config.Lan].info["return"], title = Loc[Config.Lan].info["return"], event = "jim-mining:JewelCut", args = data, params = { event = "jim-mining:JewelCut", args = data } }
	else
		if Config.Menu == "qb" then
			CraftMenu[#CraftMenu + 1] = { header = header, txt = Loc[Config.Lan].info["smelt_ores"], isMenuHeader = true }
			CraftMenu[#CraftMenu + 1] = { icon = "fas fa-circle-xmark", header = "", txt = Loc[Config.Lan].info["close"], params = { event = "jim-mining:CraftMenu:Close" } }
		end
	end
	for i = 1, #data.craftable do
		for k in pairs(data.craftable[i]) do
			if k ~= "amount" then
				local text = ""
				setheader = AllItems[k]
				if data.craftable[i]["amount"] ~= nil then setheader = setheader .. " x" .. data.craftable[i]["amount"] end
				local disable = false
				local checktable = {}
				for l, b in pairs(data.craftable[i][tostring(k)]) do
					if b == 0 or b == 1 then number = "" else number = " x" .. b end
					if AllItems[l] == nil then
						print("^3Error^7: ^2Script can't find ingredient item in items - ^1" .. l .. "^7")
						return
					end
					if Config.Menu == "ox" then text = text .. "" .. AllItems[l] .. number .. "" end
					if Config.Menu == "qb" then text = text .. "" .. AllItems[l] .. number .. "" end
					settext = text
					checktable[l] = HasItem(l, b)
				end
				for _, v in pairs(checktable) do
					if v == false then
						disable = true
						break
					end
				end
				if not disable then setheader = setheader .. " ✔️" end
				local event = Config.MultiCraft and "jim-mining:Crafting:MultiCraft" or "jim-mining:Crafting:MakeItem"
				CraftMenu[#CraftMenu + 1] = {
					disabled = disable,
					icon = "nui://" .. Config.img .. tostring(k) .. ".png",
					header = setheader,
					txt = settext,                                                                                                                                         --qb-menu
					title = setheader,
					description = settext,                                                                                                                                 -- ox_lib
					event = event,
					args = { item = k, craft = data.craftable[i], craftable = data.craftable, header = header, ret = data.ret, bench = data.bench },                       -- ox_lib
					params = { event = event, args = { item = k, craft = data.craftable[i], craftable = data.craftable, header = header, ret = data.ret, bench = data.bench } } -- qb-menu
				}
				settext, setheader = nil
			end
		end
	end

	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'CraftMenu', title = data.ret and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"], position = 'top-right', options = CraftMenu })
		exports.ox_lib:showContext("CraftMenu")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(CraftMenu)
	end
	lookEnt(data.coords)
end)

RegisterNetEvent('jim-mining:Crafting:MultiCraft', function(data)
	local success = Config.MultiCraftAmounts
	local Menu = {}
	for k in pairs(success) do
		success[k] = true
		for l, b in pairs(data.craft[data.item]) do
			local has = HasItem(l, (b * k))
			if not has then
				success[k] = false
				break
			else
				success[k] = true
			end
		end
	end
	if Config.Menu == "qb" then Menu[#Menu + 1] = { header = data.header, txt = "", isMenuHeader = true } end
	Menu[#Menu + 1] = { icon = "fas fa-arrow-left", title = Loc[Config.Lan].info["return"], header = "", txt = Loc[Config.Lan].info["return"], params = { event = "jim-mining:CraftMenu", args = data }, event = "jim-mining:CraftMenu", args = data }
	for k in pairsByKeys(success) do
		Menu[#Menu + 1] = {
			disabled = not success[k],
			icon = "nui://" .. Config.img .. data.item .. ".png",
			header = AllItems[data.item] .. " (x" .. k * (data.craft.amount or 1) .. ")",
			title = AllItems[data.item] .. " (x" .. k * (data.craft.amount or 1) .. ")",
			event = "jim-mining:Crafting:MakeItem",
			args = { item = data.item, craft = data.craft, craftable = data.craftable, header = data.header, anim = data.anim, amount = k, ret = data.ret, bench = data.bench },
			params = { event = "jim-mining:Crafting:MakeItem", args = { item = data.item, craft = data.craft, craftable = data.craftable, header = data.header, anim = data.anim, amount = k, ret = data.ret, bench = data.bench } }
		}
	end
	if Config.Menu == "ox" then
		exports.ox_lib:registerContext({ id = 'Crafting', title = data.ret and Loc[Config.Lan].info["craft_bench"] or Loc[Config.Lan].info["smelter"], position = 'top-right', options = Menu })
		exports.ox_lib:showContext("Crafting")
	elseif Config.Menu == "qb" then
		exports['qb-menu']:openMenu(Menu)
	end
end)

RegisterNetEvent('jim-mining:Crafting:MakeItem', function(data)
	local bartext, animDictNow, animNow, scene, Ped = "", nil, nil, nil, PlayerPedId()
	if not data.ret then
		bartext = Loc[Config.Lan].info["smelting"] .. AllItems[data.item]
	else
		bartext = Loc[Config.Lan].info["cutting"] .. AllItems[data.item]
	end
	local bartime = Config.Timings["Crafting"]
	if (data.amount and data.amount ~= 1) then
		data.craft.amount = data.craft.amount or 1
		data.craft["amount"] *= data.amount
		for k in pairs(data.craft[data.item]) do data.craft[data.item][k] *= data.amount end
		bartime *= data.amount
		bartime *= 0.9
	end
	lockInv(true)
	local isDrilling = true
	if data.ret then -- If jewelcutting
		if not HasItem("drillbit", 1) then
			triggerNotify(nil, Loc[Config.Lan].error["no_drillbit"], 'error')
			TriggerEvent('jim-mining:JewelCut', data)
			lockInv(false)
			return
		else
			local dict = "anim@amb@machinery@speed_drill@"
			local anim = "operate_02_hi_amy_skater_01"
			loadAnimDict(tostring(dict))
			lockInv(true)
			loadDrillSound()
			if Config.DrillSound then
				PlaySoundFromEntity(soundId, "Drill", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 0.5, 0)
			end
			local drillcoords = GetOffsetFromEntityInWorldCoords(data.bench, 0.0, -0.15, 1.1)
			scene = NetworkCreateSynchronisedScene(GetEntityCoords(data.bench), GetEntityRotation(data.bench), 2, false, false, 1065353216, 0, 1.3)
			NetworkAddPedToSynchronisedScene(Ped, scene, tostring(dict), tostring(anim), 0, 0, 0, 16, 1148846080, 0)
			NetworkStartSynchronisedScene(scene)
			CreateThread(function()
				loadPtfxDict("core")
				while isDrilling do
					UseParticleFxAssetNextCall("core")
					local dust = StartNetworkedParticleFxNonLoopedAtCoord("glass_side_window", drillcoords.x, drillcoords.y, drillcoords.z, 0.0, 0.0, GetEntityHeading(Ped) + math.random(0, 359), 0.2, 0.0, 0.0, 0.0)
					Wait(100)
				end
				unloadAnimDict(dict)
			end)
		end
	else -- If not Jewel Cutting, you'd be smelting (need to work out what is possible for this)
		animDictNow = "amb@prop_human_parking_meter@male@idle_a"
		animNow = "idle_a"
	end
	if progressBar({ label = bartext, time = Config.Debug and 2000 or bartime, cancel = true, dict = animDictNow, anim = animNow, flag = 8, icon = data.item }) then
		TriggerServerEvent('jim-mining:Crafting:GetItem', data.item, data.craft)
		if data.ret then
			if math.random(1, 1000) <= 75 then
				local breakId = GetSoundId()
				PlaySoundFromEntity(breakId, "Drill_Pin_Break", Ped, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
				toggleItem(false, "drillbit", 1)
			end
		end
		Wait(500)
		TriggerEvent("jim-mining:CraftMenu", data)
	end
	lockInv(false)
	StopSound(soundId)
	unloadDrillSound()
	lockInv(false)
	NetworkStopSynchronisedScene(scene)
	unloadPtfxDict("core")
	isDrilling = false
	StopAnimTask(Ped, animDictNow, animNow, 1.0)
	FreezeEntityPosition(Ped, false)
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then removeJob() end end)
