local InfoBox = require("src/ui/infobox")

local PluginSettingsWindow = {}
local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

--- Creates a dropdown UI element with a label and a list of options.
--- @param parent userdata The parent UI component to which the dropdown will be attached.
--- @param options table The options for the dropdown, including label, entries, stored values, and callbacks.
--- @param posX number The X position of the dropdown relative to the parent component.
--- @param posY number The Y position of the dropdown relative to the parent component.
--- @return table A table containing the label and dropdown list UI elements.
local function createDropdown(parent, options, posX, posY, index)
    local background = ui.Rectangle.new(parent)
    background:SetPos(posX - 5, posY - 5)
    background:SetSize(parent.width, 60)
    background.fill = true
    if index % 2 == 0 then
        background.colour = Vector4.new(46 / 255, 40 / 255, 37 / 255, 1.0)
    else
        background.colour = Vector4.new(36 / 255, 33 / 255, 30 / 255, 1.0)
    end

    local label = ui.Text.new(parent)
    label:SetPos(posX, posY)
    label:SetSize(100, 20)
    label.content = options.label
    label.font = config.Font.MUSEO_SANS_13PT_REGULAR.id
    label.colour = Vector4.new(180 / 255, 160 / 255, 146 / 255, 1.0)
    label.isShadowed = true

    local description = ui.Text.new(parent)
    description:SetPos(posX, posY + 20)
    description:SetSize(335, 40)
    description.content = options.description
    description.font = config.Font.MUSEO_SANS_11PT_REGULAR.id
    description.colour = Vector4.new(219 / 255, 207 / 255, 199 / 255, 1.0)
    description.isShadowed = true

    local dropdownList = ui.List.new(parent)
    dropdownList:SetPos(posX + 375, posY + 15)
    dropdownList:SetSize(160, 20)
    dropdownList.dropdownMaxVisibleEntries = 3
    dropdownList.stylesheetID = 1
    dropdownList:SetEntries(options.entries)
    if options.selected and options.selected.type == 'fromStoredKey' then
        dropdownList:SetEntrySelected(options.storedKeys[PersistentDB:GetString(options.dbKey) or options.default], true)
    end
    dropdownList:Subscribe(ui.Hook.ONSELECTIONCHANGED, options.onChange)
    return { label = label, dropdownList = dropdownList }
end 

--- The main table containing all plugin settings and their configurations.
PluginSettingsWindow.Settings = {
    COMPACT_DIRECTION = {
        order = 0,
        value = PersistentDB:GetString("COMPACT_DIRECTION") or "topLeft",
        controlType = 'dropdown',
        control = nil,
        controlOptions = {
            label = "Compact direction",
            description = "Select the direction in which the compact InfoBox will collpase when minimized.",
            dbKey = "COMPACT_DIRECTION",
            default = "topLeft",
            entries = { ["Top left"] = 1, ["Top right"] = 2, ["Bottom left"] = 3, ["Bottom right"] = 4 },
            storedValues = { [1] = "topLeft", [2] = "topRight", [3] = "bottomLeft", [4] = "bottomRight" },
            storedKeys = { ["topLeft"] = 0, ["topRight"] = 1, ["bottomLeft"] = 2, ["bottomRight"] = 3 },
            selected = { type = 'fromStoredKey' },
            onChange = function(component, entryID, selected)
                InfoBox.CompactDirection = PluginSettingsWindow.Settings.COMPACT_DIRECTION.controlOptions.storedValues[entryID]
                if InfoBox.SimpleView then
                    InfoBox.Destroy()
                    InfoBox.CreatePanel()
                end
            end
        }
    },
    CHANCE_DISPLAY = {
        order = 1,
        value = PersistentDB:GetString("CHANCE_DISPLAY") or "percent",
        controlType = 'dropdown',
        control = nil,
        controlOptions = {
            label = "Unique chance display",
            description = "Select how the unique drop chance is displayed in the info box.",
            dbKey = "CHANCE_DISPLAY",
            default = "percent",
            entries = { ["Percentage"] = 1, ["Fraction"] = 2 },
            storedValues = { [1] = "percent", [2] = "fraction" },
            storedKeys = { ["percent"] = 0, ["fraction"] = 1 },
            selected = { type = 'fromStoredKey' },
            onChange = function(component, entryID, selected)
                InfoBox.ChanceDisplay = PluginSettingsWindow.Settings.CHANCE_DISPLAY.controlOptions.storedValues[entryID]
                if InfoBox.SimpleView then
                    InfoBox.ToggleChanceDisplay(true)
                end
            end
        }
    },
    TOGGLE_DISPLAY_OPTION = {
        order = 2,
        value = PersistentDB:GetString("TOGGLE_DISPLAY_OPTION") or "off",
        controlType = 'dropdown',
        control = nil,
        controlOptions = {
            label = "Toggle chance display",
            description = "Allows you to set a quick toggle for the unique drop chance within the info box.",
            dbKey = "TOGGLE_DISPLAY_OPTION",
            default = "off",
            entries = { ["Off"] = 1, ["Click"] = 2, ["Hover"] = 3 },
            storedValues = { [1] = "off", [2] = "click", [3] = "hover" },
            storedKeys = { ["off"] = 0, ["click"] = 1, ["hover"] = 2 },
            selected = { type = 'fromStoredKey' },
            onChange = function(component, entryID, selected)
                if InfoBox.SimpleView then
                    if InfoBox.ToggleOption == "click" then
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Unsubscribe(ui.Hook.ONCLICK, "TOGGLE_CHANCE_DISPLAY")
                    end
                    if InfoBox.ToggleOption == "hover" then
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Unsubscribe(ui.Hook.ONMOUSEOVER, "HOVER_START_CHANCE_DISPLAY")
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Unsubscribe(ui.Hook.ONMOUSELEAVE, "HOVER_END_CHANCE_DISPLAY")
                    end

                    InfoBox.ToggleOption = PluginSettingsWindow.Settings.TOGGLE_DISPLAY_OPTION.controlOptions.storedValues[entryID]
                    if InfoBox.ToggleOption == "click" then
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONCLICK, "TOGGLE_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
                    end
                    if InfoBox.ToggleOption == "hover" then
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONMOUSEOVER, "HOVER_START_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
                        InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONMOUSELEAVE, "HOVER_END_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
                    end
                else
                    InfoBox.ToggleOption = PluginSettingsWindow.Settings.TOGGLE_DISPLAY_OPTION.controlOptions.storedValues[entryID]
                end
                PersistentDB:SetString("TOGGLE_DISPLAY_OPTION", InfoBox.ToggleOption)
            end
        }
    },
}

--- Initializes the plugin settings window.
PluginSettingsWindow.Start = function()
    --- This section subscribes to the settings layer ready event and when triggered mounts the plugin settings window, then draws the plugin options.
    Event.SettingsLayerReady.Subscribe("SettingsOpened", function(event)
        PluginSettingsWindow.SettingsLayer = event.component
        PluginSettingsWindow.DrawOptions()
    end)
end

--- Draws the plugin settings options within the settings window.
--- Iterates through all settings and creates the corresponding dropdown controls.
PluginSettingsWindow.DrawOptions = function()
    local posX, posY, lineHeight = 15, 10, 64
    for _, setting in pairs(PluginSettingsWindow.Settings) do
        setting.control = createDropdown(PluginSettingsWindow.SettingsLayer, setting.controlOptions, posX, posY + lineHeight * setting.order, setting.order)
    end
end

--- Refreshes the plugin settings window by destroying existing controls and redrawing them.
PluginSettingsWindow.Refresh = function()
    if PluginSettingsWindow.SettingsLayer then
        for _, setting in pairs(PluginSettingsWindow.Settings) do
            if setting.control then
                setting.control.label:Destroy()
                setting.control.dropdownList:Destroy()
                setting.control = nil
            end
        end
        PluginSettingsWindow.DrawOptions()
    end
end

--- Destroys the plugin settings window and cleans up associated resources.
PluginSettingsWindow.Destroy = function()
    if PluginSettingsWindow.SettingsLayer then
        PluginSettingsWindow.SettingsLayer = nil
        Event.SettingsLayerReady.Unsubscribe("SettingsOpened")
    end
end

return PluginSettingsWindow