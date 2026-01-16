-- Server for doogle-id
local function tryAddToInventory(src, itemName, count, metadata)
  -- Prefer ox_inventory if available
  if exports and exports.ox_inventory then
    local ok = false
    local success, err = pcall(function()
      exports.ox_inventory:AddItem(src, itemName, count, metadata)
    end)
    if success then return true end
  end

  -- Try RSGCore player methods (rsg-inventory integration)
  if exports and exports['rsg-core'] then
    local ok,Player = pcall(function()
      local core = exports['rsg-core']:GetCoreObject()
      return core.Functions.GetPlayer(src)
    end)
    if ok and Player and Player.Functions and Player.Functions.AddItem then
      local added
      local suc, err = pcall(function()
        added = Player.Functions.AddItem(itemName, count, nil, metadata)
      end)
      if suc and added ~= false then return true end
    end
  end

  -- Try rsg-inventory export directly
  if GetResourceState('rsg-inventory') == 'started' and exports['rsg-inventory'] then
    local ok, err = pcall(function()
      exports['rsg-inventory']:AddItem(src, itemName, count, metadata)
    end)
    if ok then return true end
  end

  -- Try common server event fallback
  local ok, err = pcall(function()
    TriggerEvent('rsg-inventory:server:AddItem', src, itemName, count, metadata)
  end)
  if ok then return true end

  return false
end

RegisterNetEvent('doogle-id:server:CreateID')
AddEventHandler('doogle-id:server:CreateID', function(data)
  local src = source
  if not data or not data.image then
    TriggerClientEvent('chat:addMessage', src, { args = { '^1ID', 'Invalid data supplied.' } })
    return
  end

  local meta = {
    name = data.name or 'Unknown',
    dob = data.dob or '',
    height = data.height or '',
    haircolor = data.haircolor or '',
    weight = data.weight or '',
    placeOfBirth = data.placeOfBirth or '',
    parentsPlaceOfBirth = data.parentsPlaceOfBirth or '',
    issued = data.issued or os.date('%Y-%m-%d'),
    idnumber = data.idnumber or tostring(math.random(100000,999999)),
    image = data.image
  }

  local added = tryAddToInventory(src, Config.ItemName or 'doogle_id', 1, meta)
  if added then
    TriggerClientEvent('chat:addMessage', src, { args = { '^2ID', 'ID card added to your inventory.' } })
  else
    -- Fallback: open preview for player so they can then save externally
    TriggerClientEvent('doogle-id:client:ShowID', src, data.image)
    TriggerClientEvent('chat:addMessage', src, { args = { '^3ID', 'Inventory integration not found—opened preview instead.' } })
  end
end)

-- Register usable item so players can use/view their ID from inventory
CreateThread(function()
  if exports and exports['rsg-core'] then
    local ok, core = pcall(function() return exports['rsg-core']:GetCoreObject() end)
    if ok and core and core.Functions and core.Functions.CreateUseableItem then
      core.Functions.CreateUseableItem(Config.ItemName or 'doogle_id', function(source, item)
        local meta = item and item.info or nil
        if meta and meta.image then
          TriggerClientEvent('doogle-id:client:ShowID', source, meta.image)
        else
          TriggerClientEvent('chat:addMessage', source, { args = { '^3ID', 'This ID has no image.' } })
        end
      end)
    end
  end
end)

-- Simple command to open creation UI from server-side
RegisterCommand('openidui', function(source)
  if source == 0 then
    print('This command is player-only.')
    return
  end
  TriggerClientEvent('doogle-id:client:OpenCreateUI', source)
end)
