-- Framework bridge: provides PlayerFramework.getMetadata() so client.lua
-- can check the local player's death/cuff state without hard-coding a framework.
PlayerFramework = {}

if Config.Framework == 'qb' then
    local Core = exports['qb-core']:GetCoreObject()

    function PlayerFramework.getMetadata()
        return Core.PlayerData and Core.PlayerData.metadata
    end
else
    -- QBX: QBX.PlayerData is populated by @qbx_core/modules/playerdata.lua (fxmanifest).
    function PlayerFramework.getMetadata()
        return QBX and QBX.PlayerData and QBX.PlayerData.metadata
    end
end
