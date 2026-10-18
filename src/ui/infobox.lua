local Refs = require("src/refs")
local InterfaceMouse = require("src/mouse")
local gameArea = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)

local InfoBox = {}

InfoBox.dryStreak = PersistentDB:GetInt("DRY_STREAK") or 0
InfoBox.blmTracker = PersistentDB:GetInt("BLM_TRACKER") or 0
InfoBox.uniqueRecieved = PersistentDB:GetInt("UNIQUE_RECEIVED") or 0
InfoBox.isOpen = (PersistentDB:CheckExistsTyped("IS_OPEN", 0) and PersistentDB:GetBool("IS_OPEN")) or not PersistentDB:CheckExistsTyped("IS_OPEN", 0)

InfoBox.CompactDirection = PersistentDB:GetString("COMPACT_DIRECTION") or "topLeft"
InfoBox.ChanceDisplay = PersistentDB:GetString("CHANCE_DISPLAY") or "percent"
InfoBox.ToggleOption = PersistentDB:GetString("TOGGLE_DISPLAY_OPTION") or "off"

--- Get the rate info for a given enrage value.
---@param enrage number The enrage value to get the rate info for.
---@return table rates Base rate info corresponding to the enrage value.
local function getRateInfo(enrage)
    if var.VarPlayer.DUNGEON_PROGRESS_STORYMODE.value == 1 then
        return Refs.BLM_BASE_RATES["Story Mode"]
    else
        for k,v in pairs(Refs.BLM_BASE_RATES) do
            if k ~= "Story Mode" and enrage >= v.range_start and enrage <= v.range_end then return v end
        end
    end
    error("No matching rate info found for enrage value: " .. tostring(enrage))
end

--- Toggle the display mode for the chance information between "percent" and "fraction".
--- Updates the corresponding UI element in the InfoBox.SimpleView.OverlayPanel.
--- @param toggle boolean If true, toggles the display mode; otherwise, updates the display based on the current mode.
InfoBox.ToggleChanceDisplay = function(toggle)
    local rateInfo = getRateInfo(var.VarPlayer.DUNGEON_PROGRESS_BOSS_ENRAGE.value)
    local demoninator = math.max(rateInfo.initial - InfoBox.blmTracker, rateInfo.cap)
    local percentChance = 1 / demoninator
    if (toggle and InfoBox.ChanceDisplay == "percent") or (not toggle and InfoBox.ChanceDisplay == "fraction") then
        InfoBox.ChanceDisplay = "fraction"
        PersistentDB:SetString("CHANCE_DISPLAY", InfoBox.ChanceDisplay)
        InfoBox.SettingsWindow.Refresh()
        if InfoBox.isOpen then
            InfoBox.SimpleView.OverlayPanel.children[3].value.content = string.format("1/%d", demoninator)
        else
            InfoBox.SimpleView.OverlayPanel.children[1].value.content = string.format("1/%d", demoninator)
        end
    else
        InfoBox.ChanceDisplay = "percent"
        PersistentDB:SetString("CHANCE_DISPLAY", InfoBox.ChanceDisplay)
        InfoBox.SettingsWindow.Refresh()
        if InfoBox.isOpen then
            InfoBox.SimpleView.OverlayPanel.children[3].value.content = string.format("%.2g%%", percentChance * 100)
        else
            InfoBox.SimpleView.OverlayPanel.children[1].value.content = string.format("%.2g%%", percentChance * 100)
        end
    end
end

--- Draw a title row within a PrettyUI parent element. This includes the title text and a divider line with a shadow.
--- @param title string The text to display as the title.
--- @param parent table The PrettyUI parent to which the title row will be added.
--- @param y number The y-coordinate for the title row within the parent element.
--- @param size table The size data for the panel, typically one of the entries from the SIZES table.
--- @return table row A table containing the title text element, the divider line elements, and the function to destroy them.
local function drawTitleRow(title, parent, y, size)
    local titleText = parent:AddText({
        x = 0,
        y = y,
        width = size.WIDTH,
        text = title,
        colour = 0xEFBE78FF,
        marginTop = 0,
        marginBottom = 0,
        alignHorizontal = ui.AlignMode.CENTRE,
        font = config.Font.MUSEO_SANS_11PT_REGULAR.id,
    })
    local dividerShadow = ui.Line.new(parent.root)
    dividerShadow:SetPos(4, y + 28)
    dividerShadow:SetSize(size.WIDTH - 9, 0)
    dividerShadow.width = 1
    dividerShadow.colour = Vector4.new(0, 0, 0, 1)

    local divider = ui.Line.new(parent.root)
    divider:SetPos(4, y + 27)
    divider:SetSize(size.WIDTH - 9, 0)
    divider.width = 1
    divider.colour = Vector4.new(148 / 255, 131 / 255, 120 / 255, 1)

    local function destroy()
        titleText:Destroy()
        divider:Destroy()
        dividerShadow:Destroy()
    end

    return { title = titleText, divider = { primary = divider, shadow = dividerShadow }, destroy = destroy }
end

--- Draw a text row within a PrettyUI parent element.
--- @param label string Text for the label in the text row.
--- @param value string Text for the value in the text row.
--- @param parent table The PrettyUI parent to which the text row will be added.
--- @param y number The y-coordinate for the text row within the parent element.
--- @param size table The size data for the panel, typically one of the entries from the SIZES table.
--- @return table row A table containing the label and value text elements and the function to destroy them.
local function drawTextRow(label, value, parent, y, size)
    local label = parent:AddText({
        x = 2,
        y = y,
        width = size.WIDTH,
        text = label,
        colour = 0xFFFFFFFF,
        marginTop = 0,
        marginBottom = 0,
        font = config.Font.MUSEO_SANS_11PT_REGULAR_MULTILINE.id
    })
    local value = parent:AddText({
        x = 0,
        y = y,
        width = size.WIDTH - 10,
        text = value,
        colour = 0xEFBE78FF,
        marginTop = 0,
        marginBottom = 0,
        alignHorizontal = ui.AlignMode.BOTTOMRIGHT,
        font = config.Font.MUSEO_SANS_11PT_REGULAR_MULTILINE.id
    })
    local function destroy()
        label:Destroy()
        value:Destroy()
    end
    return { label = label, value = value, destroy = destroy }
end

--- Draws the text into the compacted infobox and sets the tooltip.
--- @param value string The text value to display in the compacted infobox.
--- @param hoverText string The text to display in the tooltip when hovering over the compacted infobox.
--- @param parent table The PrettyUI parent to which the compacted text will be added.
--- @return table row The text element created for the compacted infobox and the function to destroy it.
local function drawCompactText(value, hoverText, parent)
    local value = parent:AddText({
        x = 0,
        y = -4,
        width = 48,
        text = value,
        colour = 0xEFBE78FF,
        marginTop = 0,
        marginBottom = 0,
        alignHorizontal = ui.AlignMode.CENTRE,
        font = config.Font.MUSEO_SANS_13PT_REGULAR.id,
        tooltip = { text = hoverText, placement = "above" }
    })
    local function destroy()
        value:Destroy()
    end
    return { value = value, destroy = destroy }
end


--- Handles the custom drag action for the InfoBox using a specified click box and draggable area.
--- This is implmenting a custom drag behavior for the InfoBox compared to what is available within PrettyUI.
--- This is a slight modification of PrettyUIs drag function from the Window class.
---@param parent table The parent element to which the draggable element belongs.
---@param element table The PrettyUI element to be dragged.
---@param clickBox table A rectangle representing the clickable area for dragging.
local function DragAction(parent, element, clickBox)
    local dragData = { final_border = nil, position_border = nil }
    local dragStart = nil
    local captureExpanded = false
    
    --- Checks if the interface is currently unlocked.
    --- @return boolean isInterfaceUnlocked True if the interface is unlocked.
    local function isInterfaceUnlocked()
        return (var.VarPlayer.TOPLEVEL_V2_SKINS_VARP.value & 0x2) == 0
    end
    
    --- Draws the native feedback border for a moving interface element.
    ---@param parent userdata The parent UI element to which the border will be attached.
    ---@param borderSprites table A table containing the sprite IDs for the border corners and sides.
    ---@param baseX? number The base X coordinate for positioning the border within the parent element.
    ---@param baseY? number The base Y coordinate for positioning the border within the parent element.
    ---@return table row A table containing the function to destroy the created border elements.
    local drawFeedbackBorder = function(parent, borderSprites, baseX, baseY)
        baseX = baseX or 0
        baseY = baseY or 0

        --- Creates the border sprite within the parent element.
        ---@param spriteID number The ID of the sprite to be drawn.
        ---@param parent userdata The parent UI element to which the sprite will be attached.
        ---@param x number The X coordinate for positioning the sprite within the parent element.
        ---@param y number The Y coordinate for positioning the sprite within the parent element.
        ---@param width number The width of the sprite.
        ---@param height number The height of the sprite.
        ---@param flippedHorizontally? boolean Whether the sprite should be flipped horizontally.
        ---@return userdata sprite The created sprite element.
        local function drawBorderSprite(spriteID, parent, x, y, width, height, flippedHorizontally)
            local corner = ui.Sprite.new(parent)
            corner.spriteID = spriteID
            corner:SetPos(baseX + x, baseY + y)
            corner:SetSize(width, height)
            if flippedHorizontally then
                corner.isFlippedHorizontally = true
            end
            return corner
        end

        local borderTopLeftCorner = drawBorderSprite(borderSprites.topLeftCorner, parent, 0, 0, 8, 8)
        local borderTopRightCorner = drawBorderSprite(borderSprites.topLeftCorner, parent, InfoBox.SimpleView.root.width - 8, 0, 8, 8, true)
        local borderBottomLeftCorner = drawBorderSprite(borderSprites.bottomLeftCorner, parent, 0, InfoBox.SimpleView.root.height - 8, 8, 8)
        local borderBottomRightCorner = drawBorderSprite(borderSprites.bottomLeftCorner, parent, InfoBox.SimpleView.root.width - 8, InfoBox.SimpleView.root.height - 8, 8, 8, true)
        local borderTop = drawBorderSprite(borderSprites.topSide, parent, 8, 0, InfoBox.SimpleView.root.width - 16, 8)
        local borderBottom = drawBorderSprite(borderSprites.bottomSide, parent, 8, InfoBox.SimpleView.root.height - 8, InfoBox.SimpleView.root.width - 16, 8)
        local borderLeft = drawBorderSprite(borderSprites.side, parent, 0, 8, 8, InfoBox.SimpleView.root.height - 16)
        local borderRight = drawBorderSprite(borderSprites.side, parent, InfoBox.SimpleView.root.width - 8, 8, 8, InfoBox.SimpleView.root.height - 16, true)

        local function destroyBorders()
            borderTopLeftCorner:Destroy()
            borderTopRightCorner:Destroy()
            borderBottomLeftCorner:Destroy()
            borderBottomRightCorner:Destroy()
            borderTop:Destroy()
            borderBottom:Destroy()
            borderLeft:Destroy()
            borderRight:Destroy()
        end

        return { destroy = destroyBorders }
    end

    --- Ends the drag action and resets the click box to its original position and size.
    local function stopDrag()
        dragStart = nil
        captureExpanded = false
        InterfaceMouse.EndCapture(clickBox)
        clickBox:SetPos(parent.root.x + element.root.x, parent.root.y + element.root.y)
        clickBox:SetSize(element.root.width, element.root.height)
        clickBox:Unsubscribe(ui.Hook.ONHOLD)
        clickBox:Unsubscribe(ui.Hook.ONRELEASE)
        clickBox:Unsubscribe(ui.Hook.ONDRAGCOMPLETE)
        

        -- Removes the feedback borders
        if dragData.final_border then
            dragData.final_border.destroy()
            dragData.final_border = nil
        end
        if dragData.position_border then
            dragData.position_border.destroy()
            dragData.position_border = nil
        end

        return false
    end

    --- Moves the dragged element based on the current mouse position and drag data.
    local function moveDrag(component, x, y)
        local mouse = InterfaceMouse.GetPosition(component, x, y)
        if dragStart and mouse then
            if not captureExpanded then
                dragData.final_border = drawFeedbackBorder(parent.root, Refs.FEEDBACK_SPRITE_IDS.FINAL)
                dragData.position_border = drawFeedbackBorder(gameArea, Refs.FEEDBACK_SPRITE_IDS.POSITION, parent.root.x, parent.root.y)
                captureExpanded = true
                dragStart.mouseX = mouse.x
                dragStart.mouseY = mouse.y
                dragStart.windowX = parent.root.x
                dragStart.windowY = parent.root.y
                clickBox:SetPos(0, 0)
                clickBox:SetSize(0, 0, 1.0, 1.0)
                clickBox:MoveToFront()
                return false
            end

            local nextX = dragStart.windowX + mouse.x - dragStart.mouseX
            local nextY = dragStart.windowY + mouse.y - dragStart.mouseY
            if parent.root.x ~= nextX or parent.root.y ~= nextY then
                parent.root:SetPos(nextX, nextY)
            end
        end
        return false
    end

    --- Subscribes to the click event on the click box to initiate the drag action.
    clickBox:Subscribe(ui.Hook.ONCLICK, function(component, x, y)
        if not isInterfaceUnlocked() then return false end
        InterfaceMouse.BeginScreenCapture(component, x, y)
        local mouse = InterfaceMouse.GetPosition(component, x, y)
        dragStart = {
            mouseX = mouse and mouse.x or 0,
            mouseY = mouse and mouse.y or 0,
            windowX = parent.root.x,
            windowY = parent.root.y,
        }
        clickBox:Subscribe(ui.Hook.ONHOLD, moveDrag)
        clickBox:Subscribe(ui.Hook.ONRELEASE, stopDrag)
        clickBox:Subscribe(ui.Hook.ONDRAGCOMPLETE, stopDrag)
        return false
    end)
end

--- Handles the custom resizing action for the InfoBox
---@param parent table The parent PrettyUI element to be resized. (The outer SimpleView)
---@param element table The element representing the InfoBox to be resized.
---@param clickBox table The click box element used for dragging.
---@param toggleButton table The toggle button associated with the InfoBox.
---@return function startResize The function to initiate the resizing action.
local function ResizeAction(parent, element, clickBox, toggleButton)
    --- Stops the resizing action if the target size has been reached.
    --- @param width number The current width of the InfoBox.
    --- @param height number The current height of the InfoBox.
    --- @return boolean isComplete Whether the resizing action has completed.
    local function stopResize(width, height)
        local doneShrinking = InfoBox.isOpen and width <= Refs.SIZES["COMPACT"].WIDTH and height <= Refs.SIZES["COMPACT"].HEIGHT
        local doneGrowing = not InfoBox.isOpen and width >= Refs.SIZES["FULL"].WIDTH and height >= Refs.SIZES["FULL"].HEIGHT

        if doneShrinking or doneGrowing then
            Event.Logic.Unsubscribe("RESIZE_PANEL")
            InfoBox.isOpen = not InfoBox.isOpen
            InfoBox.RefreshText()
            return true
        end
        return false
    end

    --- The primary resizing method for the InfoBox.
    local function resizePanel()
        local width, height = element.root.width, element.root.height
        if stopResize(width, height) then return end
        
        local SIZE = not InfoBox.isOpen and Refs.SIZES["FULL"] or Refs.SIZES["COMPACT"]
        local posX, posY = element.root.x, element.root.y
        local deltaW = (InfoBox.isOpen and -1 or 1) * (Refs.SIZES["FULL"].WIDTH - Refs.SIZES["COMPACT"].WIDTH) / Refs.RESIZE_RATE
        local deltaH = (InfoBox.isOpen and -1 or 1) * (Refs.SIZES["FULL"].HEIGHT - Refs.SIZES["COMPACT"].HEIGHT) / Refs.RESIZE_RATE
        local newW = InfoBox.isOpen and math.max(width + deltaW, SIZE.WIDTH) or math.min(width + deltaW, SIZE.WIDTH)
        local newY = InfoBox.isOpen and math.max(height + deltaH, SIZE.HEIGHT) or math.min(height + deltaH, SIZE.HEIGHT)
        local trueDeltaW, trueDeltaH = newW - width, newY - height

        element.root:SetSize(newW, newY)
        element.root:SetPos(posX - Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * trueDeltaW, posY - Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * trueDeltaH)
        clickBox:SetSize(newW, newY)
        clickBox:SetPos(
            parent.root.x + posX - Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * trueDeltaW,
            parent.root.y + posY - Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * trueDeltaH
        )
        --toggleButton.root:SetPos(
        --    Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * (parent.root.width - clickBox.width - 8) + clickBox.width - 16,
        --    Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * (parent.root.height - clickBox.height - 8) - 4
        --)
        toggleButton:SetPos(
            Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * (parent.root.width - clickBox.width - 8) + clickBox.width - 16,
            Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * (parent.root.height - clickBox.height - 8) - 4
        )
    end

    --- Starts the resizing process by subscribing to the draw event.
    local function startResize()
        InfoBox.DestroyText()
        Event.Logic.Subscribe("RESIZE_PANEL", resizePanel)
    end

    return startResize
end

--- UNUSED until the red-click animation is able to be removed/disabled.
--- Adds an entry to the mini menu for resizing the InfoBox.
---@param event any The event object containing the mini menu.
---@return boolean isAdded Whether the mini menu event was successfully.
local function AddMiniMenuEntry(event)
    --if not InfoBox.SimpleView.ToggleButton.root.isMouseOver then return true end
    if not InfoBox.SimpleView.ToggleButton.isMouseOver then return true end
    local text = InfoBox.isOpen and "Shrink" or "Expand"
    event.miniMenu:Add(text, ResizeAction(InfoBox.SimpleView, InfoBox.SimpleView.OverlayPanel, InfoBox.SimpleView.ClickBox, InfoBox.SimpleView.ToggleButton))
    event.miniMenu:Swap(1, #event.miniMenu.entries)
    return true
end

--- Destroys all text elements within the InfoBox's overlay panel.
InfoBox.DestroyText = function()
    if InfoBox.SimpleView and InfoBox.SimpleView.OverlayPanel then
        for _,v in ipairs(InfoBox.SimpleView.OverlayPanel.children) do
            if v.destroy then v:destroy() end
        end
        InfoBox.SimpleView.OverlayPanel.children = {}
    end
end

--- Refreshes the text for the InfoBox.
InfoBox.RefreshText = function()
    InfoBox.DestroyText()
    local SIZE = InfoBox.isOpen and Refs.SIZES["FULL"] or Refs.SIZES["COMPACT"]

    local rateInfo = getRateInfo(var.VarPlayer.DUNGEON_PROGRESS_BOSS_ENRAGE.value)
    local demoninator = math.max(rateInfo.initial - InfoBox.blmTracker, rateInfo.cap)
    local percentChance = 1 / demoninator

    local dryStreakValue = string.format("%d", InfoBox.dryStreak)
    local uniqueChanceValue = InfoBox.ChanceDisplay == "percent" and string.format("%.2g%%", percentChance * 100) or string.format("1/%d", demoninator)

    if InfoBox.isOpen then 
        table.insert(InfoBox.SimpleView.OverlayPanel.children, drawTitleRow("Zamorak Bad Luck", InfoBox.SimpleView.OverlayPanel, -2, SIZE))
        table.insert(InfoBox.SimpleView.OverlayPanel.children, drawTextRow("Dry streak:", dryStreakValue, InfoBox.SimpleView.OverlayPanel, 23, SIZE))
        table.insert(InfoBox.SimpleView.OverlayPanel.children, drawTextRow("Unique chance:", uniqueChanceValue, InfoBox.SimpleView.OverlayPanel, 43, SIZE))

        if InfoBox.ToggleOption == "click" then
            InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONCLICK, "TOGGLE_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
        end
        if InfoBox.ToggleOption == "hover" then
            InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONMOUSEOVER, "HOVER_START_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
            InfoBox.SimpleView.OverlayPanel.children[3].value:Subscribe(ui.Hook.ONMOUSELEAVE, "HOVER_END_CHANCE_DISPLAY", function() InfoBox.ToggleChanceDisplay(true) end)
        end
    else
        table.insert(InfoBox.SimpleView.OverlayPanel.children, drawCompactText(uniqueChanceValue, string.format("Dry streak: %d", InfoBox.dryStreak), InfoBox.SimpleView.OverlayPanel))
    end
end

--- Creates the info box panel and initializes its components.
InfoBox.CreatePanel = function()
    -- Retrieve the saved panel position from the persistent database
    local PANEL_X = PersistentDB:GetInt("PANEL_X") or 40
    local PANEL_Y = PersistentDB:GetInt("PANEL_Y") or 40
    local SIZE = InfoBox.isOpen and Refs.SIZES["FULL"] or Refs.SIZES["COMPACT"]

    -- Create the SimpleView using the constants.
    InfoBox.SimpleView = prettyui.SimpleView.new(gameArea, {
        width = Refs.SIZES["FULL"].WIDTH + 8,
        height = Refs.SIZES["FULL"].HEIGHT + 8,
        x = PANEL_X,
        y = PANEL_Y,
        scrollable = false,
        draggable = true,
    })

    -- Create the panel within the SimpleView
    local panelWidthOffset = Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * (Refs.SIZES["FULL"].WIDTH - Refs.SIZES["COMPACT"].WIDTH)
    local panelHeightOffset = Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * (Refs.SIZES["FULL"].HEIGHT - Refs.SIZES["COMPACT"].HEIGHT)
    InfoBox.SimpleView.OverlayPanel = InfoBox.SimpleView:AddPanel({
        width = SIZE.WIDTH,
        height = SIZE.HEIGHT,
        x = (InfoBox.isOpen and 0 or panelWidthOffset),
        y = 8 + (InfoBox.isOpen and 0 or panelHeightOffset),
        backgroundAlpha = 1,
        scrollable = false,
    })
    InfoBox.SimpleView.OverlayPanel.children = {}

    -- Create ClickBox for dragging the panel
    InfoBox.SimpleView.ClickBox = ui.Rectangle.new(gameArea)
    InfoBox.SimpleView.ClickBox:SetPos(InfoBox.SimpleView.root.x + (InfoBox.isOpen and 0 or panelWidthOffset), 8 + InfoBox.SimpleView.root.y + (InfoBox.isOpen and 0 or panelHeightOffset))
    InfoBox.SimpleView.ClickBox:SetSize(InfoBox.SimpleView.OverlayPanel.root.width, InfoBox.SimpleView.OverlayPanel.root.height)
    InfoBox.SimpleView.ClickBox.colour = Vector4.new(0, 0, 0, 0)
    local isUnlocked = (var.VarPlayer.TOPLEVEL_V2_SKINS_VARP.value & 0x2) == 0
    InfoBox.SimpleView.ClickBox.cursorConfig.mouseOverCursor = isUnlocked and config.Cursor.TOPLEVEL_V2_MOVE.id or -1
    DragAction(InfoBox.SimpleView, InfoBox.SimpleView.OverlayPanel, InfoBox.SimpleView.ClickBox)
    --InfoBox.SimpleView.ClickBox:Subscribe(ui.Hook.ONCLICK, "CLICK_BOX_CLICK", DragAction(InfoBox.SimpleView, InfoBox.SimpleView.OverlayPanel, InfoBox.SimpleView.ClickBox))

    -- Create the toggle button for resizing the panel
    local buttonWidthOffset = Refs.DIRECTION_TABLE[InfoBox.CompactDirection].x * (InfoBox.SimpleView.OverlayPanel.root.x)
    local buttonHeightOffset = Refs.DIRECTION_TABLE[InfoBox.CompactDirection].y * (InfoBox.SimpleView.OverlayPanel.root.y - 8)
    --[[InfoBox.SimpleView.ToggleButton = InfoBox.SimpleView:AddSprite(Plugin.resources.images.golden_zamorak, {
        x = SIZE.WIDTH - 16 + (InfoBox.isOpen and 0 or buttonWidthOffset - 4),
        y = (InfoBox.isOpen and 0 or buttonHeightOffset) - 4,
        size = 24
    })
    ]]
    InfoBox.SimpleView.ToggleButton = ui.Sprite.new(InfoBox.SimpleView.root)
    InfoBox.SimpleView.ToggleButton.sprite = Plugin.resources.images.golden_zamorak
    InfoBox.SimpleView.ToggleButton:SetPos(SIZE.WIDTH - 16 + (InfoBox.isOpen and 0 or buttonWidthOffset - 4), (InfoBox.isOpen and 0 or buttonHeightOffset) - 4)
    InfoBox.SimpleView.ToggleButton:SetSize(24, 24)
    InfoBox.SimpleView.ToggleButton.clickthrough = false
    
    --Event.MiniMenuReady.Subscribe("UPDATE_MINI_MENU", AddMiniMenuEntry)
    --InfoBox.SimpleView.ToggleButton.root:Subscribe(ui.Hook.ONCLICK, "TOGGLE_BUTTON_CLICK", ResizeAction(InfoBox.SimpleView, InfoBox.SimpleView.OverlayPanel, InfoBox.SimpleView.ClickBox, InfoBox.SimpleView.ToggleButton))
    InfoBox.SimpleView.ToggleButton:Subscribe(ui.Hook.ONCLICK, "TOGGLE_BUTTON_CLICK", ResizeAction(InfoBox.SimpleView, InfoBox.SimpleView.OverlayPanel, InfoBox.SimpleView.ClickBox, InfoBox.SimpleView.ToggleButton))

    InfoBox.RefreshText()
end

--- Repositions the InfoBox to the specified coordinates.
--- @param x number The x-coordinate to reposition the InfoBox to.
--- @param y number The y-coordinate to reposition the InfoBox to.
InfoBox.Reposition = function(x, y)
    if InfoBox.SimpleView then
        InfoBox.SimpleView.root:SetPos(x, y)
        InfoBox.SimpleView.ClickBox:SetPos(x + InfoBox.SimpleView.OverlayPanel.root.x, y + InfoBox.SimpleView.OverlayPanel.root.y)
        InfoBox.SimpleView.ClickBox:SetSize(InfoBox.SimpleView.OverlayPanel.root.width, InfoBox.SimpleView.OverlayPanel.root.height)
    end
end

--- Binds the provided settings window to the InfoBox. This allows the InfoBox to interact with the settings window.
--- This needs to be done to prevent a circular dependency between the InfoBox and the settings window.
--- @param settings table The settings window to bind to the InfoBox.
InfoBox.BindSettings = function(settings)
    InfoBox.SettingsWindow = settings
end

--- Destroys the InfoBox and cleans up event subscriptions.
InfoBox.Destroy = function()
    if InfoBox.SimpleView then
        -- Save the panel position and open state before destroying it.
        PersistentDB:SetInt("PANEL_X", InfoBox.SimpleView.root.x)
        PersistentDB:SetInt("PANEL_Y", InfoBox.SimpleView.root.y)
        PersistentDB:SetBool("IS_OPEN", InfoBox.isOpen)
        PersistentDB:SetString("CHANCE_DISPLAY", InfoBox.ChanceDisplay)
        PersistentDB:SetString("COMPACT_DIRECTION", InfoBox.CompactDirection)

        if InfoBox.SimpleView.ClickBox then 
            InfoBox.SimpleView.ClickBox:Unsubscribe(ui.Hook.ONCLICK, "CLICK_BOX_CLICK")
            InfoBox.SimpleView.ClickBox:Destroy()
        end
        if InfoBox.SimpleView.ToggleButton then
            --Event.MiniMenuReady.Unsubscribe("UPDATE_MINI_MENU")
            --InfoBox.SimpleView.ToggleButton.root:Unsubscribe(ui.Hook.ONCLICK, "TOGGLE_BUTTON_CLICK")
            InfoBox.SimpleView.ToggleButton:Unsubscribe(ui.Hook.ONCLICK, "TOGGLE_BUTTON_CLICK")
            --InfoBox.SimpleView.ToggleButton:Destroy()
        end
        InfoBox.DestroyText()
        InfoBox.SimpleView:Destroy()
        InfoBox.SimpleView = nil
    end
end

return InfoBox