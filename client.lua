-- Client for doogle-id
local function openUI()
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open' })
end

RegisterCommand('makeid', function()
  openUI()
end)

RegisterNetEvent('doogle-id:client:OpenCreateUI')
AddEventHandler('doogle-id:client:OpenCreateUI', openUI)

RegisterNUICallback('close', function(_, cb)
  SetNuiFocus(false, false)
  cb({ ok = true })
end)

RegisterNUICallback('create', function(data, cb)
  SetNuiFocus(false, false)
  -- data contains: name,dob,job,photo (base64 or url),idnumber,issued
  TriggerServerEvent('doogle-id:server:CreateID', data)
  cb({ ok = true })
end)

RegisterNetEvent('doogle-id:client:ShowID')
AddEventHandler('doogle-id:client:ShowID', function(imageData)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'view', image = imageData })
end)


-- NPC interaction: spawn an NPC and allow players to press E to open the create-ID UI
local npc = nil
local npcCoords = vector3(-877.81, -1334.78, 43.97)
local npcHeading = 279.33
local npcModelName = 'gc_lemoynecaptive_males_01'

local function draw3DText(x, y, z, text)
  local onScreen, _x, _y = World3dToScreen2d(x, y, z)
  if onScreen then
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
  end
end

Citizen.CreateThread(function()
  local model = GetHashKey(npcModelName)
  RequestModel(model)
  local tick = 0
  while not HasModelLoaded(model) and tick < 1000 do
    Wait(10)
    tick = tick + 1
  end
  if HasModelLoaded(model) then
    npc = CreatePed(model, npcCoords.x, npcCoords.y, npcCoords.z, npcHeading, false, true, true, true)
    if npc and DoesEntityExist(npc) then
      SetEntityHeading(npc, npcHeading)
      FreezeEntityPosition(npc, true)
      SetBlockingOfNonTemporaryEvents(npc, true)
      SetEntityInvincible(npc, true)
      TaskStandStill(npc, -1)
    end
    SetModelAsNoLongerNeeded(model)
  end

  while true do
    local sleep = 1000
    if npc and DoesEntityExist(npc) then
      local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId(), true))
      local nx, ny, nz = table.unpack(GetEntityCoords(npc, true))
      local dist = Vdist(px, py, pz, nx, ny, nz)
      if dist < 8.0 then
        sleep = 5
        draw3DText(nx, ny, nz + 1.0, "Press ~INPUT_CONTEXT~ to create an ID")
        if dist < 2.5 and IsControlJustReleased(0, 38) then -- E
          openUI()
        end
      end
    end
    Wait(sleep)
  end
end)

AddEventHandler('onResourceStop', function(name)
  if name == GetCurrentResourceName() and npc and DoesEntityExist(npc) then
    DeleteEntity(npc)
  end
end)
