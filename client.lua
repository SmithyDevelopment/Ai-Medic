QBCore = nil
local QBCore = exports['qb-core']:GetCoreObject()

local Active = false
local Veh1 = nil
local Ped1 = nil
local spam = true
local lastDoctorTime = 0
 


RegisterCommand("medic", function(source, args, raw)
	if (QBCore.Functions.GetPlayerData().metadata["isdead"]) or (QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and spam then
		QBCore.Functions.TriggerCallback('aimedic:docOnline', function(EMSOnline, hasEnoughMoney)
			if EMSOnline <= Config.Doctor and hasEnoughMoney and spam then
				SpawnVehicle(GetEntityCoords(PlayerPedId()))
				TriggerServerEvent('aimedic:charge')
				Notify("Medic is arriving")
				lastDoctorTime = GetGameTimer()
			else
				if EMSOnline > Config.Doctor then
					Notify("There is too many medics online", "error")
				elseif not hasEnoughMoney then
					Notify("Not Enough Money", "error")
				else
					Notify("Wait Paramadic is on its Way", "primary")
				end	
			end
		end)
	else
		Notify("This can only be used when dead", "error")
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        if lastDoctorTime > 0 and GetGameTimer() - lastDoctorTime >= 60000 then
            local playerPed = PlayerPedId()
            local ld = GetEntityCoords(Ped1)
            if DoesEntityExist(Ped1) then
                SetEntityCoords(playerPed, ld.x + 1.0, ld.y + 1.0, ld.z, 1, 0, 0, 1)
            end
            lastDoctorTime = 0
        end
    end
end)

function SpawnVehicle(x, y, z)  
	spam = false
	local vehhash = GetHashKey("sheriff")	-- set vehicle spawn name here                                                     
	local loc = GetEntityCoords(PlayerPedId())
	RequestModel(vehhash)
	while not HasModelLoaded(vehhash) do
		Wait(1)
	end
	RequestModel('s_m_m_doctor_01')
	while not HasModelLoaded('s_m_m_doctor_01') do
		Wait(1)
	end
	local spawnRadius = 40                                                    
    local found, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(loc.x + math.random(-spawnRadius, spawnRadius), loc.y + math.random(-spawnRadius, spawnRadius), loc.z, 0, 3, 0)

	if not DoesEntityExist(vehhash) then
        medVeh = CreateVehicle(vehhash, spawnPos, spawnHeading, true, false)                        
        ClearAreaOfVehicles(GetEntityCoords(medVeh), 5000, false, false, false, false, false);  
        SetVehicleOnGroundProperly(medVeh)
		SetVehicleNumberPlateText(medVeh, "MED1")
		SetEntityAsMissionEntity(medVeh, true, true)
		SetVehicleEngineOn(medVeh, true, true, false)
		SetVehicleSiren(medVeh, true)
        
        medPed = CreatePedInsideVehicle(medVeh, 26, GetHashKey('s_m_m_doctor_01'), -1, true, false)              	
        
        medBlip = AddBlipForEntity(medVeh)                                                        	
        SetBlipFlashes(medBlip, true)  
        SetBlipColour(medBlip, 2)


		PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
		Wait(2000)
		TaskVehicleDriveToCoord(medPed, medVeh, loc.x, loc.y, loc.z, 20.0, 0, GetEntityModel(medVeh), 524863, 2.0)
		Veh1 = medVeh
		Ped1 = medPed
		Active = true
    end
end

Citizen.CreateThread(function()
    while true do
      Citizen.Wait(200)
        if Active then
            local playerPed = GetPlayerPed(-1)
            local loc = GetEntityCoords(playerPed)
			local lc = GetEntityCoords(Veh1)
			local ld = GetEntityCoords(Ped1)
            local dist = Vdist(loc.x, loc.y, loc.z, lc.x, lc.y, lc.z)
			local dist1 = Vdist(loc.x, loc.y, loc.z, ld.x, ld.y, ld.z)
            if dist <= 10 then
				if Active then
					TaskGoToCoordAnyMeans(Ped1, loc.x, loc.y, loc.z, 1.0, 0, 0, 786603, 0xbf800000)
				end
				if dist1 <= 1 then 
					Active = false
					ClearPedTasksImmediately(Ped1)
					if IsPedInAnyVehicle(playerPed, false) then
                        local veh = GetVehiclePedIsIn(playerPed, false)
                        SetEntityCoords(playerPed, ld.x + 1.0, ld.y + 1.0, ld.z, 0, 0, 0, 1)
                        DoctorNPC()
                    else
						DoctorNPC()
					end	
				end
            end
        end
    end
end)


function DoctorNPC()
	RequestAnimDict("mini@cpr@char_a@cpr_str")
	while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
		Citizen.Wait(1000)
	end

	TaskPlayAnim(Ped1, "mini@cpr@char_a@cpr_str","cpr_pumpchest",1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
	QBCore.Functions.Progressbar("revive_doc", "The doctor is giving you medical aid", Config.ReviveTime, false, false, {
		disableMovement = false,
		disableCarMovement = false,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		ClearPedTasks(Ped1)
		Citizen.Wait(500)
		TriggerServerEvent("hospital:server:RevivePlayer",  GetPlayerServerId(PlayerId()))
		StopScreenEffect('DeathFailOut')	
		Notify("Your treatment is done, you were charged: "..Config.Price, "success")
		RemovePedElegantly(Ped1)
		TaskEnterVehicle(Ped1, veh, 0, 2, 3.0, 1, 0)
		TaskVehicleDriveWander(Ped1, veh, 25.0, 524295)
		Wait(40000)
		DeleteEntity(Veh1)
		DeleteEntity(Ped1)
		spam = true
	end)
end


function Notify(msg, state)
    QBCore.Functions.Notify(msg, state)
end
