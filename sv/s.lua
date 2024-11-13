ESX = exports["es_extended"]:getSharedObject()

local active = {}

ESX.RegisterUsableItem('tracker', function(source)
    local xplayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('s_policetracker:useitem', source)
end)

ESX.RegisterServerCallback('s_policetracker:active', function(source, cb)
    local xplayer = ESX.GetPlayerFromId(source)

    if xplayer and xplayer.job and xplayer.job.name == 'police' then
        cb(active)  
    else
        cb({})  
    end
end)

RegisterServerEvent('s_policetracker:placetracker') 
AddEventHandler('s_policetracker:placetracker', function(plate, vehicleid)
    local xplayer = ESX.GetPlayerFromId(source)
    if xplayer.job.name == 'police' then
       
        active[plate] = true
        
        xplayer.removeInventoryItem("tracker", 1)
        TriggerClientEvent('esx:showNotification', source, 'Tracker placed to a vehicle with plate: ' .. plate)

        
        Citizen.SetTimeout(15 * 60 * 1000, function()
            active[plate] = nil
            TriggerClientEvent('esx:showNotification', source, 'Tracker ' .. plate .. ' lost connection after 15-minutes.')
        end)
    else
        TriggerClientEvent('esx:showNotification', source, 'You must be an police officer to do this.') 
    end
end)

RegisterNetEvent('s_policetracker:delete')
AddEventHandler('s_policetracker:delete', function(plate)
    if active[plate] then
        active[plate] = nil 
        TriggerClientEvent('esx:showNotification', source, 'The tracker has been removed.')
    else
        TriggerClientEvent('esx:showNotification', source, 'No tracker found on this vehicle.')
    end
end)