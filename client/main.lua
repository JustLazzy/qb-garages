local QBCore = exports['qb-core']:GetCoreObject()
local currentHouseGarage = nil
local hasGarageKey = nil
local currentGarage = nil
local currentDepot = nil
local nearspawnpoint = nil
local OutsideVehicles = {}
local garagePoly = {}
RegisterNetEvent('qb-garages:client:setHouseGarage', function(house, hasKey)
    currentHouseGarage = house
    hasGarageKey = hasKey
    
end)
RegisterNetEvent('qb-garages:client:houseGarageConfig', function(garageConfig)
    HouseGarages = garageConfig
end)
RegisterNetEvent('qb-garages:client:addHouseGarage', function(house, garageInfo)
    HouseGarages[house] = garageInfo
end)

-- Functions
function RegisterHousePoly(house)
    if HouseGarages[house] then     
        if garagePoly[house] then return end
        local coords = HouseGarages[house].takeVehicle
        if not coords or not coords.x then return end
        local pos = vector3(coords.x, coords.y, coords.z)
        local Polyzone = BoxZone:Create(pos,5,3.5, {
            name = house,
            offset = {0.0, 0.0, 0.0},
            debugPoly = DebugPoly,
            heading = coords.h,
            minZ = pos.z - 1.0,
            maxZ = pos.z + 1.0,
        })
        garagePoly[house] = {
            Polyzone = Polyzone,
            coords = coords,
        }
        Polyzone:onPlayerInOut(function(isPpointInside)
            if isPpointInside then
                inHouseParking = true
                exports['qb-core']:DrawText('Parking','left')
            else
                exports['qb-core']:HideText()	
                exports['qb-radialmenu']:RemoveOption(5)
                inHouseParking = false
            end
        end)
    end
end

function RemovePoly(house)
    if garagePoly[house] then
        local Poly = garagePoly[house].Polyzone
        Poly:destroy()
        garagePoly[house] = nil
    end
end

local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}
    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = PlayerPedId()
        coords = GetEntityCoords(playerPed)
    end
    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))
        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities+1] = isPlayerEntities and k or entity
        end
    end
    return nearbyEntities
end
local function GetVehiclesInArea(coords, maxDistance) -- Vehicle inspection in designated area
    return EnumerateEntitiesWithinDistance(QBCore.Functions.GetVehicles(), false, coords, maxDistance) 
end
local function IsSpawnPointClear(coords, maxDistance) -- Check the spawn point to see if it's empty or not:
    return #GetVehiclesInArea(coords, maxDistance) == 0 
end
local function GetNearSpawnPoint() -- Get nearest spawn point
    local near = nil
    local distance = 10000
    if inParkingZone and currentgarage ~= nil then
        for k, v in pairs(Garages[currentgarage].spawnPoint) do
            if IsSpawnPointClear(vector3(v.x, v.y, v.z), 2.5) then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local cur_distance = #(pos - vector3(v.x, v.y, v.z))
                if cur_distance < distance then
                    distance = cur_distance
                    near = k
                end
            end
        end
    end
    return near
end
local function GetNearDepotPoint() -- Get nearest spawn point
    local near = nil
    local distance = 10000
    if inDepotZone and currentdepot ~= nil then
        for k, v in pairs(Depots[currentdepot].spawnPoint) do
            if IsSpawnPointClear(vector3(v.x, v.y, v.z), 2.5) then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local cur_distance = #(pos - vector3(v.x, v.y, v.z))
                if cur_distance < distance then
                    distance = cur_distance
                    near = k
                end
            end
        end
    end
    return near
end
local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end
local function MenuHouseGarage(house)
    exports['qb-menu']:openMenu({
        {
            header = "House Garage",
            isMenuHeader = true
        },
        {
            header = "My Vehicles",
            txt = "View your stored vehicles!",
            params = {
                event = "qb-garages:client:HouseGarage",
                args = house
            }
        },
        {
            header = "⬅ Leave Garage",
            txt = "",
            params = {
                event = "qb-menu:closeMenu"
            }
        },
    })
end
local function ClearMenu()
	TriggerEvent("qb-menu:closeMenu")
end
local function closeMenuFull()
    currentGarage = nil
    ClearMenu()
end
local function doCarDamage(currentVehicle, veh)
	smash = false
	damageOutside = false
	damageOutside2 = false
	local engine = veh.engine + 0.0
	local body = veh.body + 0.0
	if engine < 200.0 then
		engine = 200.0
    end

    if engine > 1000.0 then
        engine = 1000.0
    end

	if body < 150.0 then
		body = 150.0
	end
	if body < 900.0 then
		smash = true
	end

	if body < 800.0 then
		damageOutside = true
	end

	if body < 500.0 then
		damageOutside2 = true
	end

    Wait(100)
    SetVehicleEngineHealth(currentVehicle, engine)
	if smash then
		SmashVehicleWindow(currentVehicle, 0)
		SmashVehicleWindow(currentVehicle, 1)
		SmashVehicleWindow(currentVehicle, 2)
		SmashVehicleWindow(currentVehicle, 3)
		SmashVehicleWindow(currentVehicle, 4)
	end
	if damageOutside then
		SetVehicleDoorBroken(currentVehicle, 1, true)
		SetVehicleDoorBroken(currentVehicle, 6, true)
		SetVehicleDoorBroken(currentVehicle, 4, true)
	end
	if damageOutside2 then
		SetVehicleTyreBurst(currentVehicle, 1, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 2, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 3, false, 990.0)
		SetVehicleTyreBurst(currentVehicle, 4, false, 990.0)
	end
	if body < 1000 then
		SetVehicleBodyHealth(currentVehicle, 985.1)
	end
end
local function CheckPlayers(vehicle)
    for i = -1, 5,1 do
        seat = GetPedInVehicleSeat(vehicle,i)
        if seat ~= 0 then
            TaskLeaveVehicle(seat,vehicle,0)
            SetVehicleDoorsLocked(vehicle)
            Wait(1500)
            QBCore.Functions.DeleteVehicle(vehicle)
        end
   end
end


-- Events
RegisterNetEvent('vehicle:flipit', function()
	local veh = QBCore.Functions.GetClosestVehicle()
	QBCore.Functions.Progressbar("flipping_vehicle", "Flipping Vehicle", 15000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {
	    animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 8,
	}, {}, {}, function() -- Done
		SetVehicleOnGroundProperly(veh)
	end, function()
		QBCore.Functions.Notify("Cancelled!", "error")
	end)
end)

-- // Depot \\ --
RegisterNetEvent("qb-garages:client:DepotList", function(data)
    currentGarage = data.id
    QBCore.Functions.TriggerCallback("qb-garage:server:GetDepotVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any impounded vehicles!", "error", 5000)
        else
            local MenuDepotOptions = {
                {
                    header = "Depot: "..Depots[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Impound"
                end

                MenuDepotOptions[#MenuDepotOptions+1] = {
                    header = vname.." ["..v.depotprice.."]",
                    txt = "Plate: "..v.plate.."<br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:TakeOutDepotVehicle",
                        args = v
                    }
                }
            end

            MenuDepotOptions[#MenuDepotOptions+1] = {
                header = "⬅ Leave Depot",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuDepotOptions)
        end
    end)
end)
RegisterNetEvent('qb-garages:client:takeOutDepot', function(vehicle)
    local VehExists = DoesEntityExist(OutsideVehicles[vehicle.plate])
    local lastnearspawnpoint = nearspawnpoint
    if not VehExists then
        if not IsSpawnPointClear(vector3(Depots[currentdepot].spawnPoint[lastnearspawnpoint].x, Depots[currentdepot].spawnPoint[lastnearspawnpoint].y, Depots[currentdepot].spawnPoint[lastnearspawnpoint].z), 2.5) then
            QBCore.Functions.Notify("A Vehicle is in the way", 'error', 2500)
            return
        else
            if OutsideVehicles and next(OutsideVehicles) then
                if OutsideVehicles[vehicle.plate] then
                    local Engine = GetVehicleEngineHealth(OutsideVehicles[vehicle.plate])
                    QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                        QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                            QBCore.Functions.SetVehicleProperties(veh, properties)
                            enginePercent = round(vehicle.engine / 10, 0)
                            bodyPercent = round(vehicle.body / 10, 0)
                            currentFuel = vehicle.fuel

                            if vehicle.plate then
                                DeleteVehicle(OutsideVehicles[vehicle.plate])
                                OutsideVehicles[vehicle.plate] = veh
                                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                            end

                            SetVehicleNumberPlateText(veh, vehicle.plate)
                            SetEntityHeading(veh, Depots[currentdepot].spawnPoint[lastnearspawnpoint].w)
                            exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                            SetEntityAsMissionEntity(veh, true, true)
                            doCarDamage(veh, vehicle)
                            TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                            closeMenuFull()
                            SetVehicleEngineOn(veh, true, true)
                        end, vehicle.plate)
                        TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                    end, Depots[currentdepot].spawnPoint[lastnearspawnpoint], true)
                    SetTimeout(250, function()
                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
                    end)
                else
                    QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                        QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                            QBCore.Functions.SetVehicleProperties(veh, properties)
                            enginePercent = round(vehicle.engine / 10, 0)
                            bodyPercent = round(vehicle.body / 10, 0)
                            currentFuel = vehicle.fuel

                            if vehicle.plate then
                                OutsideVehicles[vehicle.plate] = veh
                                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                            end

                            SetVehicleNumberPlateText(veh, vehicle.plate)
                            SetEntityHeading(veh, Depots[currentdepot].spawnPoint[lastnearspawnpoint].w)
                            exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                            SetEntityAsMissionEntity(veh, true, true)
                            doCarDamage(veh, vehicle)
                            TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                            closeMenuFull()
                            SetVehicleEngineOn(veh, true, true)
                        end, vehicle.plate)
                        TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                    end, Depots[currentdepot].spawnPoint[lastnearspawnpoint], true)
                    SetTimeout(250, function()
                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
                    end)
                end
            else
                QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                    QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                        QBCore.Functions.SetVehicleProperties(veh, properties)
                        enginePercent = round(vehicle.engine / 10, 0)
                        bodyPercent = round(vehicle.body / 10, 0)
                        currentFuel = vehicle.fuel
                        if vehicle.plate then
                            OutsideVehicles[vehicle.plate] = veh
                            TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                        end
                        SetVehicleNumberPlateText(veh, vehicle.plate)
                        SetEntityHeading(veh, Depots[currentdepot].spawnPoint[lastnearspawnpoint].w)
                        exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                        SetEntityAsMissionEntity(veh, true, true)
                        doCarDamage(veh, vehicle)
                        TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                        closeMenuFull()
                        SetVehicleEngineOn(veh, true, true)
                    end, vehicle.plate)
                    TriggerEvent("vehiclekeys:client:SetOwner", vehicle.plate)
                end, Depots[currentdepot].spawnPoint[lastnearspawnpoint], true)
                SetTimeout(250, function()
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(GetVehiclePedIsIn(PlayerPedId(), false)))
                end)
            end
        end
    else
        QBCore.Functions.Notify("Your car is not in impound", "error", 5000)
    end
end)
RegisterNetEvent('qb-garages:client:TakeOutDepotVehicle', function(vehicle)
    if vehicle.state == "Impound" then
        TriggerServerEvent("qb-garage:server:PayDepotPrice", vehicle)
        Wait(1000)
    end
end)


RegisterNetEvent("qb-garages:client:HouseGarage", function(house)
    house = house or currentHouseGarage
    if not house then return end
    QBCore.Functions.TriggerCallback("qb-garage:server:GetHouseVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in your garage!", "error", 5000)
        else
            local MenuHouseGarageOptions = {
                {
                    header = "Garage: "..HouseGarages[house].label,
                    isMenuHeader = true
                },
            }

            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = HouseGarages[house].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "Garaged"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuHouseGarageOptions[#MenuHouseGarageOptions+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = "State: "..v.state.. "<br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:TakeOutHouseGarage",
                        args = v
                    }
                }
            end

            MenuHouseGarageOptions[#MenuHouseGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuHouseGarageOptions)
        end
    end, house)
end)

RegisterNetEvent('qb-garages:client:TakeOutHouseGarage', function(vehicle)
    if vehicle.state == "Garaged" then
        QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
            QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)
                QBCore.Functions.SetVehicleProperties(veh, properties)
                enginePercent = round(vehicle.engine / 10, 1)
                bodyPercent = round(vehicle.body / 10, 1)
                currentFuel = vehicle.fuel

                if vehicle.plate then
                    OutsideVehicles[vehicle.plate] = veh
                    TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                end

                SetVehicleNumberPlateText(veh, vehicle.plate)
                SetEntityHeading(veh, HouseGarages[currentHouseGarage].takeVehicle.h)
                exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                SetEntityAsMissionEntity(veh, true, true)
                doCarDamage(veh, vehicle)
                TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                closeMenuFull()
                TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                SetPedIntoVehicle(PlayerPedId(), veh, -1)
            end, vehicle.plate)
        end, HouseGarages[currentHouseGarage].takeVehicle, true)
    end
end)

-- // Public Garage \\ --
RegisterNetEvent("qb-garages:client:VehicleList", function(data)
    currentGarage = data.id
    QBCore.Functions.TriggerCallback("qb-garage:server:GetUserVehicles", function(result)
        if result == nil then
            QBCore.Functions.Notify("You don't have any vehicles in this garage!", "error", 5000)
        else
            local MenuPublicGarageOptions = {
                {
                    header = "Garage: "..Garages[currentGarage].label,
                    isMenuHeader = true
                },
            }
            for k, v in pairs(result) do
                enginePercent = round(v.engine / 10, 0)
                bodyPercent = round(v.body / 10, 0)
                currentFuel = v.fuel
                curGarage = Garages[v.garage].label
                vname = QBCore.Shared.Vehicles[v.vehicle].name

                if v.state == 0 then
                    v.state = "Out"
                elseif v.state == 1 then
                    v.state = "Garaged"
                elseif v.state == 2 then
                    v.state = "Impounded By Police"
                end

                MenuPublicGarageOptions[#MenuPublicGarageOptions+1] = {
                    header = vname.." ["..v.plate.."]",
                    txt = "State: "..v.state.." <br>Fuel: "..currentFuel.." | Engine: "..enginePercent.." | Body: "..bodyPercent,
                    params = {
                        event = "qb-garages:client:takeOutPublicGarage",
                        args = v,
                    }
                }
            end

            MenuPublicGarageOptions[#MenuPublicGarageOptions+1] = {
                header = "⬅ Leave Garage",
                txt = "",
                params = {
                    event = "qb-menu:closeMenu",
                }
            }
            exports['qb-menu']:openMenu(MenuPublicGarageOptions)
        end
    end, currentGarage)
end)
RegisterNetEvent('qb-garages:client:takeOutPublicGarage', function(vehicle)
    local lastnearspawnpoint = nearspawnpoint 
    if vehicle.state == "Garaged" then
        if not IsSpawnPointClear(vector3(Garages[currentgarage].spawnPoint[lastnearspawnpoint].x, Garages[currentgarage].spawnPoint[lastnearspawnpoint].y, Garages[currentgarage].spawnPoint[lastnearspawnpoint].z), 2.5) then
            QBCore.Functions.Notify("A Vehicle is in the way", 'error', 2500)
            return
        else
            enginePercent = round(vehicle.engine / 10, 1)
            bodyPercent = round(vehicle.body / 10, 1)
            currentFuel = vehicle.fuel
            QBCore.Functions.SpawnVehicle(vehicle.vehicle, function(veh)
                QBCore.Functions.TriggerCallback('qb-garage:server:GetVehicleProperties', function(properties)

                    if vehicle.plate then
                        OutsideVehicles[vehicle.plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end

                    QBCore.Functions.SetVehicleProperties(veh, properties)
                    SetVehicleNumberPlateText(veh, vehicle.plate)
                    SetEntityHeading(veh, Garages[currentGarage].spawnPoint[lastnearspawnpoint].w)
                    exports['lj-fuel']:SetFuel(veh, vehicle.fuel)
                    doCarDamage(veh, vehicle)
                    SetEntityAsMissionEntity(veh, true, true)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 0, vehicle.plate, vehicle.garage)
                    closeMenuFull()
                    TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                    SetVehicleEngineOn(veh, true, true)
                end, vehicle.plate)

            end, Garages[currentgarage].spawnPoint[lastnearspawnpoint], true)
        end
    elseif vehicle.state == "Out" then
        QBCore.Functions.Notify("Your vehicle may be at the depot!", "error", 2500)
    elseif vehicle.state == "Impound" then
        QBCore.Functions.Notify("This vehicle was impounded by the police!", "error", 4000)
    end
end)


RegisterNetEvent('qb-garages:client:putGarageHouse', function()
    local ped = PlayerPedId()
    local curVeh = GetVehiclePedIsIn(ped)
    local plate = QBCore.Functions.GetPlate(curVeh)
    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleHouseOwner', function(owned)
        if owned then
            local bodyDamage = round(GetVehicleBodyHealth(curVeh), 1)
            local engineDamage = round(GetVehicleEngineHealth(curVeh), 1)
            local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
            local vehProperties = QBCore.Functions.GetVehicleProperties(curVeh)
            CheckPlayers(curVeh)
            if DoesEntityExist(curVeh) then
                QBCore.Functions.Notify("Vehicle not stored, please check if is someone inside the car", "error", 4500)
            else
            TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, currentHouseGarage)
            TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, currentHouseGarage)
            TriggerServerEvent('qb-vehicletuning:server:SaveVehicleProps', vehProperties)
            QBCore.Functions.DeleteVehicle(curVeh)
            if plate then
                OutsideVehicles[plate] = veh
                TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
            end
            QBCore.Functions.Notify("Vehicle Parked", "primary", 4500)
        end
        else
            QBCore.Functions.Notify("You don't own this vehicle", "error", 3500)
        end

    end, plate, currentHouseGarage)
end)

RegisterNetEvent('qb-garages:client:openHouseGarage', function()
    if hasGarageKey then
        MenuHouseGarage(currentHouseGarage)
    else
        QBCore.Functions.Notify("You can't open this garage, you don't have the key.")
    end
end)


RegisterNetEvent("qb-garages:client:putpublicgarage", function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    --PUBLIC GARAGE
    if inParkingZone and IsPedInAnyVehicle(ped) then
        inGarageRange = true
        if inParkingZone then
            local curVeh = GetVehiclePedIsIn(ped)
            local plate = GetVehicleNumberPlateText(curVeh)
            QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned)
                if owned then
                    local bodyDamage = math.ceil(GetVehicleBodyHealth(curVeh))
                    local engineDamage = math.ceil(GetVehicleEngineHealth(curVeh))
                    local totalFuel = exports['lj-fuel']:GetFuel(curVeh)
                    TriggerServerEvent('qb-garage:server:updateVehicleStatus', totalFuel, engineDamage, bodyDamage, plate, currentgarage)
                    TriggerServerEvent('qb-garage:server:updateVehicleState', 1, plate, currentgarage)
                    TriggerServerEvent('vehiclemod:server:saveStatus', plate)
                    TaskLeaveVehicle(ped, curVeh, 64)
                    Wait(1750)
                    QBCore.Functions.DeleteVehicle(curVeh)
                    if plate ~= nil then
                        OutsideVehicles[plate] = veh
                        TriggerServerEvent('qb-garages:server:UpdateOutsideVehicles', OutsideVehicles)
                    end
                    QBCore.Functions.Notify("Vehicle parked in, "..Garages[currentgarage].label, "primary", 5000)
                else
                    QBCore.Functions.Notify("You do not own this car", "error", 3500)
                end
            end, plate)
        end
    end
end)

-- Threads
CreateThread(function()
    for k, v in pairs(Garages) do
        if v.showBlip then
            local Garage = AddBlipForCoord(Garages[k].blippoint.x, Garages[k].blippoint.y, Garages[k].blippoint.z)
            SetBlipSprite (Garage, 357)
            SetBlipDisplay(Garage, 4)
            SetBlipScale  (Garage, 0.65)
            SetBlipAsShortRange(Garage, true)
            SetBlipColour(Garage, 3)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Garages[k].label)
            EndTextCommandSetBlipName(Garage)
        end
    end

    for k, v in pairs(Depots) do
        if v.showBlip then
            local Depot = AddBlipForCoord(Depots[k].blippoint.x, Depots[k].blippoint.y, Depots[k].blippoint.z)
            SetBlipSprite (Depot, 68)
            SetBlipDisplay(Depot, 4)
            SetBlipScale  (Depot, 0.7)
            SetBlipAsShortRange(Depot, true)
            SetBlipColour(Depot, 5)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Depots[k].label)
            EndTextCommandSetBlipName(Depot)
        end
    end
end)

-- New Polyzone shit --
local alap01 = PolyZone:Create({
    vector2(-277.81, -886.02),
    vector2(-350.82, -870.54),
    vector2(-350.93, -876.85),
    vector2(-364.04, -876.83),
    vector2(-364.02, -960.54),
    vector2(-344.49, -970.1),
    vector2(-346.89, -976.18),
    vector2(-296.06, -994.68),
    vector2(-289.88, -977.25),
    vector2(-311.05, -969.75),
    vector2(-297.59, -932.39),
    vector2(-303.34, -930.45),
    vector2(-298.82, -919.58),
    vector2(-282.72, -925.09),
    vector2(-271.78, -894.83),
    vector2(-280.08, -891.88),
    }, {
        name="alap01",
        minZ = 31.00-3,
        maxZ = 31.00+3,
})
alap01:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "alta"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local legion = PolyZone:Create({
    vector2(239.94, -820.54),
    vector2(200.06, -805.75),
    vector2(226.43, -733.09),
    vector2(271.99, -748.68),
    }, {
        name="legion",
        minZ = 31.00-3,
        maxZ = 31.00+3,
})
legion:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "legion"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local paleto = PolyZone:Create({
    vector2(-25.48, 6326.9),
    vector2(66.53, 6418.76),
    vector2(116.84, 6372.94),
    vector2(-12.46, 6300.82),
    vector2(-25.88, 6316.64),
    }, {
        name="paleto",
        minZ = 30.00,
        maxZ = 40.00,
})
paleto:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "paleto"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local vinewood = PolyZone:Create({
    vector2(388.57, 257.13),
    vector2(349.74, 271.67),
    vector2(352.75, 281.97),
    vector2(358.69, 302.3),
    vector2(390.11, 295.08),
    vector2(400.61, 291.21),
    }, {
        name="vinewood",
        minZ = 100.00,
        maxZ = 110.00,
})
vinewood:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "vinewood"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local sandy = PolyZone:Create({
    vector2(1091.8948974609, 2676.7536621094),
    vector2(1139.7840576172, 2675.5483398438),
    vector2(1140.6735839844, 2643.6525878906),
    vector2(1108.7120361328, 2644.1350097656),
    vector2(1108.6146240234, 2659.7451171875),
    vector2(1091.6341552734, 2659.46484375),
    }, {
        name="sandy",
        minZ = 37.00-5,
        maxZ = 37.00+5,
})
sandy:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "sandy"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local mrpd = PolyZone:Create({
    vector2(423.16, -1000.29),
    vector2(463.7, -1000.29),
    vector2(463.7, -973.04),
    vector2(423.16, -973.04),
    }, {
        name="mrpd",
        minZ = 25.00-5,
        maxZ = 25.00+5,
})
mrpd:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inParkingZone = true
        currentgarage = "mrpd"
        exports['qb-core']:DrawText('Parking','left')
    else
        inParkingZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
-- Depot
local hayesdepot = PolyZone:Create({
    vector2(-155.78700256348, -1159.1724853516),
    vector2(-129.38655090332, -1158.8568115234),
    vector2(-129.38841247559, -1186.3132324219),
    vector2(-155.80316162109, -1185.8881835938)
  }, {
    name="hayesdepot",
    minZ = 23.00-5,
    maxZ = 23.00+5,
})
hayesdepot:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inDepotZone = true
        currentdepot = "hayesdepot"
        exports['qb-core']:DrawText('Depot','left')
    else
        inDepotZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)
local davisdepot = PolyZone:Create({
    vector2(410.33, -1660.35),
    vector2(423.39, -1645.19),
    vector2(424.0, -1640.5),
    vector2(423.87, -1632.95),
    vector2(423.17, -1628.41),
    vector2(411.61, -1619.73),
    vector2(406.27, -1626.09),
    vector2(403.39, -1623.67),
    vector2(388.1, -1641.98),
  }, {
    name="davisdepot",
    minZ = 25.00-20,
    maxZ = 25.00+20,
})
davisdepot:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inDepotZone = true
        currentdepot = "davisdepot"
        exports['qb-core']:DrawText('Depot','left')
    else
        inDepotZone = false
        exports['qb-radialmenu']:RemoveOption(5)
        exports['qb-core']:HideText()	
    end
end)

CreateThread(function()
    while true do
        sleep = 1000
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if inParkingZone then
                nearspawnpoint = GetNearSpawnPoint()
                if currentgarage == "mrpd" then
                    if QBCore.Functions.GetPlayerData().job.name == "police" or QBCore.Functions.GetPlayerData().job.name == "bcso" or QBCore.Functions.GetPlayerData().job.name == "sast" then
                        if not IsPedInAnyVehicle(ped) then
                            exports['qb-radialmenu']:AddOption({
                                id = currentgarage,
                                title = 'Open Garage',
                                icon = 'warehouse',
                                type = 'client',
                                event = 'qb-garages:client:VehicleList',
                                shouldClose = true
                            }, 5)
                        elseif IsPedInAnyVehicle(ped) then
                            exports['qb-radialmenu']:AddOption({
                                id = currentgarage,
                                title = 'Park Vehicle',
                                icon = 'parking',
                                type = 'client',
                                event = 'qb-garages:client:putpublicgarage',
                                shouldClose = true
                            }, 5)
                        end
                    end
                else
                    if not IsPedInAnyVehicle(ped) then
                        exports['qb-radialmenu']:AddOption({
                            id = currentgarage,
                            title = 'Open Garage',
                            icon = 'warehouse',
                            type = 'client',
                            event = 'qb-garages:client:VehicleList',
                            shouldClose = true
                        }, 5)
                    elseif IsPedInAnyVehicle(ped) then
                        exports['qb-radialmenu']:AddOption({
                            id = currentgarage,
                            title = 'Park Vehicle',
                            icon = 'parking',
                            type = 'client',
                            event = 'qb-garages:client:putpublicgarage',
                            shouldClose = true
                        }, 5)
                    end
                end
            end
            if inDepotZone then
                nearspawnpoint = GetNearDepotPoint()
                if not IsPedInAnyVehicle(ped) then
                    exports['qb-radialmenu']:AddOption({
                        id = currentdepot,
                        title = 'Open Depot',
                        icon = 'warehouse',
                        type = 'client',
                        event = 'qb-garages:client:DepotList',
                        shouldClose = true
                    }, 5)
                elseif IsPedInAnyVehicle(ped) then
                    exports['qb-radialmenu']:RemoveOption(5)
                end
            end
        end
        Wait(sleep)
    end
end)


-- NEW SHIT

-- // House Garage \\ --

CreateThread(function ()
    while true do
        if HouseGarages and currentHouseGarage then
            RegisterHousePoly(currentHouseGarage)
        end
        Wait(1000)
    end
end)

CreateThread(function ()
    while true do
        if garagePoly then
            for k, v in pairs(garagePoly) do
                local coords = v.coords
                local pos = vector3(coords.x, coords.y, coords.z)
                local dist = #(pos - GetEntityCoords(PlayerPedId()))
                if dist > 20.0 then
                    RemovePoly(k)
                end
            end
        end
        Wait(5000)
    end
end)

CreateThread(function ()
    while true do
        if LocalPlayer.state['isLoggedIn'] then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if inHouseParking then
                if not IsPedInAnyVehicle(ped) then
                    exports['qb-radialmenu']:AddOption({
                        id = currentHouseGarage,
                        title = 'Open Garage',
                        icon = 'warehouse',
                        type = 'client',
                        event = 'qb-garages:client:openHouseGarage',
                        shouldClose = true
                    }, 5)
                elseif IsPedInAnyVehicle(ped) then
                    exports['qb-radialmenu']:AddOption({
                        id = currentgarage,
                        title = 'Park Vehicle',
                        icon = 'parking',
                        type = 'client',
                        event = 'qb-garages:client:putGarageHouse',
                        shouldClose = true
                    }, 5)
                end
            end     
        end
        Wait(100)
    end
end)

