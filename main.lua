local InfoBox = require("src/ui/infobox")
local BossTab = require("src/ui/bosstab")
local Events = require("src/events")
local PluginSettingsWindow = require("src/settings")

-- Temporary code for development purposes
ExecuteConsoleCommand("ppr zamorak-bad-luck-tracker")
ExecuteConsoleCommand("ppe zamorak-bad-luck-tracker trackingAccess")

-- Initializes the plugin by starting the region listeners for ED4, setting up the window size listener, and starting the boss tab listener.
Events.StartRegionListener()
Events.WindowSizeListener()
Events.StartBossTabListener()

-- Binds the plugin settings to the InfoBox.
PluginSettingsWindow.Start()
InfoBox.BindSettings(PluginSettingsWindow)

-- Cleans up the plugin when it is shut down.
function PluginShutdown()
    Events.Destroy()
    InfoBox.Destroy()
    BossTab.Destroy()
    PluginSettingsWindow.Destroy()
end