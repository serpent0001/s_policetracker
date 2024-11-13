ESX = nil
local trackers = {}
local istracker = {}
local placing, trackerdetected = false 
local vehicletracked, vehicleplate = nil
Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports["es_extended"]:getSharedObject()
        Citizen.Wait(500) 
    end
end)

RegisterNetEvent('s_policetracker:useitem')
AddEventHandler('s_policetracker:useitem', function()
    ESX.TriggerServerCallback('esx:getPlayerData', function(playerData)
        if playerData.job.name == 'police' then
            placing = true
            Citizen.CreateThread(function()
                nearbycars()
            end)
        else
            TriggerEvent('esx:showNotification', 'You are not a police officer!')
        end
    end)
end)

function nearbycars()
    while placing do
        local playerped = PlayerPedId()
        local playercoords = GetEntityCoords(playerped)
        local vehicles = ESX.Game.GetVehiclesInArea(playercoords, 2.0) 
        local found = false

       
        if IsControlJustReleased(0, 73) then  
            placing = false
            return
        end

        for _, vehicle in pairs(vehicles) do
            local vehiclecoords = GetEntityCoords(vehicle)
            local distance = #(vehiclecoords - playercoords)

            if distance < 4.2 then
                found = true
                local plate = GetVehicleNumberPlateText(vehicle)
                
                Create3DText(vehiclecoords.x, vehiclecoords.y, vehiclecoords.z + 1.0, "[E] Place tracker [X] Cancel")

                if IsControlJustReleased(0, 38) then 
                    place(vehicle, plate) 
                    placing = false 
                    return 
                end
            end
        end

        if not found then
            Citizen.Wait(500) 
        else
            Citizen.Wait(5) 
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7000)

        ESX.TriggerServerCallback('s_policetracker:active', function(active)
            
            for _, blip in pairs(trackers) do
                RemoveBlip(blip)
            end
            trackers = {}

            
            for plate, _ in pairs(active) do
                local vehicle = getcar(plate)
                if DoesEntityExist(vehicle) then
                    local coords = GetEntityCoords(vehicle)
                    local blip = AddBlipForCoord(coords)
                    
                    SetBlipSprite(blip, 41) 
                    SetBlipColour(blip, 1) 
                    SetBlipScale(blip, 0.8)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Tracker [" .. plate .. "]")
                    EndTextCommandSetBlipName(blip)

                    table.insert(trackers, blip)
                end
            end
        end)
    end
end)

Citizen.CreateThread(function()
    while true do
        local playerped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerped, false)

        if vehicle ~= 0 then
            local plate = GetVehicleNumberPlateText(vehicle)

            if not istracker[plate] then
                istracker[plate] = true 

                ESX.TriggerServerCallback('s_policetracker:active', function(active)
                    if active[plate] then
                        local found = math.random(1, 100)

                        if found <= 5 then 
                            local showtime = GetGameTimer() + 5000
                            
                            
                            while GetGameTimer() < showtime do
                                Create2DText(0.66, 1.40, 1.0, 1.0, 0.6, "~w~You noticed a ~r~Tracker ~w~ in your vehicle.", 255, 255, 255, 255)
                                Citizen.Wait(0)
                            end

                            trackerdetected = true
                            vehicleplate = plate
                            vehicletracked = vehicle
                        end
                    end
                end)
            end
        else
            
            if trackerdetected and vehicletracked then
                
                Citizen.CreateThread(function()
                    while trackerdetected do
                        local vehicleCoords = GetEntityCoords(vehicletracked)
                        Create3DText(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.0, "~w~Press [E] to remove the tracker")
                        
                        local playercoords = GetEntityCoords(playerped)
                        local distance = #(playercoords - vehicleCoords)
                        if IsControlJustReleased(0, 38) and distance < 4.2 then
                            trackerdetected = false
                            vehicletracked = nil
                            
                            animation()
                            
                            TriggerServerEvent('s_policetracker:delete', vehicleplate)
                            vehicleplate = nil
                        end
                        
                        Citizen.Wait(5)
                    end
                end)
            end

            istracker = {}
        end

        Citizen.Wait(1000)
    end
end)

function getcar(plate)
    local vehicles = ESX.Game.GetVehicles()
    for _, vehicle in pairs(vehicles) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            return vehicle
        end
    end
    return nil
end

function place(vehicle, plate)
    local vehicleid = NetworkGetNetworkIdFromEntity(vehicle)

    animation()
    TriggerServerEvent('s_policetracker:placetracker', plate, vehicleid)
end


function animation()
    local playerped = PlayerPedId()
    
    RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
        Citizen.Wait(100)
    end

    TaskPlayAnim(playerped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8, -1, 1, 0, false, false, false)
    Citizen.Wait(5000) 

    ClearPedTasksImmediately(playerped)
end




function Create3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    
    if onScreen then
       
    local scale = math.max(0.4, (0.1) * 1.5 * (100 / (GetGameplayCamFov())))
            
    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextEntry('STRING')
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 200) 

    AddTextComponentString(text)
    DrawText(_x, _y)
    end
end

function Create2DText(x, y, width, height, scale, text, r, g, b, a)
     SetTextFont(4)
     SetTextProportional(1)
     SetTextScale(scale, scale)
     SetTextColour(r, g, b, a)
     SetTextDropShadow(2, 2, 0, 0, 255)
     SetTextEdge(1, 0, 0, 0, 255)
     SetTextOutline()              
     SetTextEntry("STRING")
     AddTextComponentString(text)
     DrawText(x - width / 2, y - height / 2 + 0.005)
end