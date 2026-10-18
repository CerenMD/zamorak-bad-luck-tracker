local Refs = require("src/refs")
local InfoBox = require("src/ui/infobox")
local BossTab = require("src/ui/bosstab")

local Events = {}

local isInED4 = false

--- Event triggered when the EGWD_ZAMORAK_BOSS_PERM_4 updates, which happens when Zamorak is killed and when the
--- chest is looted. Bit masks are applied to retrieve the pertinent values including the loot state and the BLM
--- changing. These values are used as indicators in order to increment the tracking data.
---@param event any The VarTranmit event which is filtered for the EGWD_ZAMORAK_BOSS_PERM_4 updates.
---@return boolean success Whether the event was successfully processed.
local function zamorakKilled(event)
    -- EGWD_ZAMORAK_BOSS_PERM_4, contains the dry streak and BLM tracker information
    if InfoBox and event.var.id == var.VarPlayer.EGWD_ZAMORAK_BOSS_PERM_4.id then
        -- Enrage of the boss at the time of the event.
        local enrage = var.VarPlayer.DUNGEON_PROGRESS_BOSS_ENRAGE.value
        -- Mask the old and new BLM values, caps at 1000 with 10 being a decrement to the denominator by 1.
        local oldBLMValue, newBLMValue = (event.oldValue or 0) & 0x7ff, (event.newValue or 0) & 0x7ff
        -- Mask the old and new loot owed values: 2048 after kill, 0 after looted
        local oldLootOwed, newLootOwed = (event.oldValue) & 0x800, (event.newValue) & 0x800
        -- Mask the new rare owed values: 4096 if a rare drop is owed
        local newRareOwed = (event.newValue) & 0x1000

        -- Calculate the difference between the new and old masked values. As it is a hidden value, due to plugin guidelines I cannot display it directly.
        local blmChange = newBLMValue - oldBLMValue 
        local lootOwedChange = newLootOwed - oldLootOwed

        
        -- Update the dry streak and BLM tracker based on the changed values
        if lootOwedChange > 0 and newRareOwed > 0 then
            -- Detects if a rare drop is owed, prepping the plugin to reset when looted.
            InfoBox.uniqueRecieved = 1
            PersistentDB:SetInt("UNIQUE_RECEIVED", InfoBox.uniqueRecieved)
        elseif lootOwedChange < 0 and InfoBox.uniqueRecieved == 0 then
            -- Change is positive or 0 and loot was awarded, this means the player did not get a unique drop and the dry streak should be incremented.
            -- Update the dry streak and BLM tracker based on the changed values.
            InfoBox.dryStreak = InfoBox.dryStreak + 1
            PersistentDB:SetInt("DRY_STREAK", InfoBox.dryStreak)
            -- Increment the BLM tracker based on the change in the masked BLM value. If the dry streak is less than 10, change == 1 and the BLM tracker will not increment.
            InfoBox.blmTracker = InfoBox.blmTracker + math.max(blmChange // 10, 0)
            PersistentDB:SetInt("BLM_TRACKER", InfoBox.blmTracker)
        elseif lootOwedChange < 0 and InfoBox.uniqueRecieved == 1 then
            -- A unique drop was received, reset the dry streak and BLM tracker.
            InfoBox.dryStreak = 0
            InfoBox.blmTracker = 0
            InfoBox.uniqueRecieved = 0
            PersistentDB:SetInt("DRY_STREAK", InfoBox.dryStreak)
            PersistentDB:SetInt("BLM_TRACKER", InfoBox.blmTracker)
            PersistentDB:SetInt("UNIQUE_RECEIVED", InfoBox.uniqueRecieved)
        end
        -- Refresh the InfoBox display if it exists.
        if InfoBox and InfoBox.SimpleView and InfoBox.SimpleView.OverlayPanel then
            InfoBox.DestroyText()
            InfoBox.RefreshText()
        end
    end
    return true
end

--- Handles the interface unlocked event.
--- Updates the cursor configuration based on whether the interface is unlocked.
---@param event any The VarTransmit event containing information about the variable change.
---@return boolean success Whether the event was successfully processed.
local function interfaceUnlocked(event)
    if event.var.id == var.VarPlayer.TOPLEVEL_V2_SKINS_VARP.id then
        local isUnlocked = (event.var.value & 0x2) == 0
        InfoBox.SimpleView.ClickBox.cursorConfig.mouseOverCursor = isUnlocked and config.Cursor.TOPLEVEL_V2_MOVE.id or -1
    end
    return true
end

--- Branches the VarTransmit event to the appropriate handlers.
--- @param event any The VarTransmit event containing information about the variable change.
--- @return boolean success Whether the event was successfully processed.
local function handleVarTransmit(event)
    return zamorakKilled(event) and interfaceUnlocked(event)
end

--- Handles the player leaving the ED4 region.
--- Unsubscribes from relevant events and destroys the InfoBox if the file loaded.
local function leftED4()
    isInED4 = false
    Event.WorldCreated.Unsubscribe("worldCreated")
    Event.VarTransmit.Unsubscribe("varChange")
    if InfoBox then InfoBox.Destroy() end
end

--- Handles the player entering the EGWD world or ED4 region.
--- Subscribes to relevant events and creates the InfoBox if the file loaded.
local function enteredED4()
    isInED4 = true
    Event.WorldCreated.Subscribe("worldCreated", leftED4)
    Event.VarTransmit.Subscribe("varChange", handleVarTransmit)
    if InfoBox then InfoBox.CreatePanel() end
end

--- Checks if the player is currently in the ED4 region and triggers the appropriate enter/leave events.
local function checkRegion()
    if not World.IsRegion() then return end
    local curPlayer = PlayerList.Self()
    local worldCoord = World.GetRegionSourceForCoordGrid(curPlayer.coordGrid)
    -- Check if the player's current mapSquare are within the ED4 region boundaries.
    if worldCoord.mapSquareX >= Refs.ED4_MAP_SQUARE_CORNERS[1].x and worldCoord.mapSquareX <= Refs.ED4_MAP_SQUARE_CORNERS[2].x and worldCoord.mapSquareZ >= Refs.ED4_MAP_SQUARE_CORNERS[1].z and worldCoord.mapSquareZ <= Refs.ED4_MAP_SQUARE_CORNERS[2].z then
        Event.ServerLogic.Unsubscribe("nearTreasureChest")
        if not isInED4 then
            enteredED4()
        end
    elseif isInED4 then
        leftED4()
    end
    Event.RegionUpdated.Unsubscribe("regionUpdated")
end

--- Handles the player entering any region.
--- Subscribes to the region updated event to check the player's current region.
local function enteredRegion()
    Event.RegionUpdated.Subscribe("regionUpdated", checkRegion)
end

--- Checks if the player is outside the dungeon by the treasure chest. Allowing the InfoBox to be displayed in case they loot outside.
local function nearTreasureChest()
    local playerCoords = PlayerList.Self().coordGrid
    if  playerCoords.mapSquareX >= Refs.OUTSIDE_ED4_COORDS[1].mapSquareX and playerCoords.mapSquareX <= Refs.OUTSIDE_ED4_COORDS[2].mapSquareX and
        playerCoords.mapSquareZ >= Refs.OUTSIDE_ED4_COORDS[1].mapSquareZ and playerCoords.mapSquareZ <= Refs.OUTSIDE_ED4_COORDS[2].mapSquareZ and
        playerCoords.localX >= Refs.OUTSIDE_ED4_COORDS[1].localX and playerCoords.localX <= Refs.OUTSIDE_ED4_COORDS[2].localX and
        playerCoords.localZ >= Refs.OUTSIDE_ED4_COORDS[1].localZ and playerCoords.localZ <= Refs.OUTSIDE_ED4_COORDS[2].localZ then
        if not isInED4 then
            enteredED4()
        end
    elseif isInED4 then
        leftED4()
    end
end

--- Compares either the event map square area or the players coordinates to see if they are in or have EGWD loaded.
--- Player is only used on plugin load sequence as the WorldCreated event occurs before the player coordinates are updated.
--- @param evt any The WorldCreated event payload containing the map square boundaries.
local function inEGWD(evt)
    if evt then
        if  evt.mapSquareMinX <= Refs.EGWD_MAP_SQUARE_CORNERS[1].x and evt.mapSquareMaxX >= Refs.EGWD_MAP_SQUARE_CORNERS[2].x and
            evt.mapSquareMinZ <= Refs.EGWD_MAP_SQUARE_CORNERS[1].z and evt.mapSquareMaxZ >= Refs.EGWD_MAP_SQUARE_CORNERS[2].z then
            Event.ServerLogic.Subscribe("nearTreasureChest", nearTreasureChest)
        else
            Event.ServerLogic.Unsubscribe("nearTreasureChest")
        end
    else
        local playerCoords = PlayerList.Self().coordGrid
        if  playerCoords.mapSquareX >= Refs.EGWD_MAP_SQUARE_CORNERS[1].x and playerCoords.mapSquareX <= Refs.EGWD_MAP_SQUARE_CORNERS[2].x and
            playerCoords.mapSquareZ >= Refs.EGWD_MAP_SQUARE_CORNERS[1].z and playerCoords.mapSquareZ <= Refs.EGWD_MAP_SQUARE_CORNERS[2].z then
            Event.ServerLogic.Subscribe("nearTreasureChest", nearTreasureChest)
        else
            Event.ServerLogic.Unsubscribe("nearTreasureChest")
        end
    end
end

--- Handles the window size change event. This ensures the window remains in the boundaries of the screen if it is resized.
--- @param event any The window size change event payload.
local function handleWindowSizeChange(event)
    local relativeX, relativeY = event.newWidth / event.oldWidth, event.newHeight / event.oldHeight
    local newScale = game.options.InterfaceScale.setting / 100
    local adjustedScaleX = newScale / InfoBox.InterfaceScale

    InfoBox.Reposition(relativeX * InfoBox.SimpleView.root.x / adjustedScaleX, relativeY * InfoBox.SimpleView.root.y / adjustedScaleX)
    InfoBox.InterfaceScale = newScale
end

local function bossTabListener()
    local bossNameComponent = ui.Interfaces:GetComponent(id.Component.BSLAY_BOSS_INFO__BOSS_NAME)
    local descComponent = ui.Interfaces:GetComponent(id.Component.BSLAY_BOSS_INFO__BOSS_DESC_BUILD_LAYER)
    local dryStreakComponent = nil
    if descComponent ~= nil then
        dryStreakComponent = descComponent:GetChild(1, 1)
        if dryStreakComponent == nil and BossTab.dryStreakText ~= nil and BossTab.luckText ~= nil then
            BossTab.dryStreakText:Destroy()
            BossTab.dryStreakText = nil
            BossTab.luckText:Destroy()
            BossTab.luckText = nil
        end
    end
    if bossNameComponent ~= nil and (BossTab.dryStreakText == nil or dryStreakComponent == nil) then
        Event.ServerLogic.Unsubscribe("BossTabListener")
        Event.Logic.Subscribe("ZamorakPageListener", function()
            local bossNameComponent = ui.Interfaces:GetComponent(id.Component.BSLAY_BOSS_INFO__BOSS_NAME)
            if bossNameComponent == nil then 
                Event.Logic.Unsubscribe("ZamorakPageListener")
                Event.ServerLogic.Subscribe("BossTabListener", bossTabListener)
            elseif bossNameComponent.content == "Zamorak, Lord of Chaos" and BossTab.dryStreakText == nil then
                BossTab.DrawBossInfoUI()
                Event.Logic.Unsubscribe("ZamorakPageListener")
                Event.ServerLogic.Subscribe("BossTabListener", bossTabListener)
            end
        end)
    end
end

--- Initializes the event listeners for the plugin to detect entering ED4.
Events.StartRegionListener = function()
    checkRegion()
    inEGWD()
    Event.RegionCreated.Subscribe("regionCreated", enteredRegion)
    Event.WorldCreated.Subscribe("inEGWD", inEGWD)
end

--- Sets up the event listener for window size changes. This ensures the InfoBox is repositioned correctly when the window is resized.
Events.WindowSizeListener = function()
    Event.WindowSizeChanged.Subscribe("windowSizeChanged", handleWindowSizeChange)
end

Events.StartBossTabListener = function()
    Event.ServerLogic.Subscribe("BossTabListener", bossTabListener)
end

--- Cleans up all event listeners for the plugin.
Events.Destroy = function()
    Event.WorldCreated.Unsubscribe("worldCreated")
    Event.VarTransmit.Unsubscribe("varChange")
    Event.RegionUpdated.Unsubscribe("regionUpdated")
    Event.RegionCreated.Unsubscribe("regionCreated")
    Event.WorldCreated.Unsubscribe("inEGWD")
    Event.ServerLogic.Unsubscribe("nearTreasureChest")
end

return Events