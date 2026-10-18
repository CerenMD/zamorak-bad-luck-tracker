--- Reference values and constants used throughout the plugin.

-- Defines the size of the InfoBox panels.
local SIZES = {
    ["FULL"] = {WIDTH = 175, HEIGHT = 75},
    ["COMPACT"] = {WIDTH = 55, HEIGHT = 25}
}

-- Defines the rate at which the InfoBox panels resize.
local RESIZE_RATE = 6

-- Defines the map square corners for the ED4 region in order to determine if the player is within the region.
local ED4_MAP_SQUARE_CORNERS = {
    {x = 23, z = 24},
    {x = 27, z = 28}
}

local OUTSIDE_ED4_COORDS = {
    {mapSquareX = 27, mapSquareZ = 20, localX = 25, localZ = 55},
    {mapSquareX = 27, mapSquareZ = 20, localX = 35, localZ = 63}
}

local EGWD_MAP_SQUARE_CORNERS = {
    {x = 25, z = 16},
    {x = 29, z = 20}
}

-- Defines the direction mapping table for resizing the InfoBox panels relative to the panel corners.
local DIRECTION_TABLE = {
    ["bottomLeft"] = { x = 0, y = 1 },
    ["bottomRight"] = { x = 1, y = 1 },
    ["topLeft"] = { x = 0, y = 0 },
    ["topRight"] = { x = 1, y = 0 }
}

-- Base drop rates for uniques at different enrages, source: https://runescape.wiki/w/Zamorak,_Lord_of_Chaos#Drop_mechanics
local BLM_BASE_RATES = {
    ["Story Mode"] = { range_start = 0, range_end = 0, initial = 500, cap = 500 },
    [0] = { range_start = 0, range_end = 19, initial = 100, cap = 100 },
    [20] = { range_start = 20, range_end = 49, initial = 99, cap = 99 },
    [50] = { range_start = 50, range_end = 99, initial = 97, cap = 97 },
    [100] = { range_start = 100, range_end = 149, initial = 80, cap = 20 },
    [150] = { range_start = 150, range_end = 199, initial = 77, cap = 20 },
    [200] = { range_start = 200, range_end = 299, initial = 72, cap = 20 },
    [300] = { range_start = 300, range_end = 399, initial = 67, cap = 20 },
    [400] = { range_start = 400, range_end = 499, initial = 62, cap = 20 },
    [500] = { range_start = 500, range_end = 749,  initial = 52, cap = 20 },
    [750] = { range_start = 750, range_end = 899, initial = 47, cap = 20 },
    [900] = { range_start = 900, range_end = 999, initial = 40, cap = 20 },
    [1000] = { range_start = 1000, range_end = 1249, initial = 37, cap = 10 },
    [1250] = { range_start = 1250, range_end = 1499, initial = 35, cap = 10 },
    [1500] = { range_start = 1500, range_end = 1999, initial = 31, cap = 10 },
    [2000] = { range_start = 2000, range_end = 60000, initial = 28, cap = 5 }
}

--- Sprite IDs for feedback elements in the UI.
local FEEDBACK_SPRITE_IDS = {
    ["POSITION"] = {
        ["topLeftCorner"] = 18218,
        ["topSide"] = 18219,
        ["side"] = 18220,
        ["bottomLeftCorner"] = 18222,
        ["bottomSide"] = 18223
    },
    ["FINAL"] = {
        ["topLeftCorner"] = 18206,
        ["topSide"] = 18207,
        ["side"] = 18208,
        ["bottomLeftCorner"] = 18210,
        ["bottomSide"] = 18211
    }
}

return {
    SIZES = SIZES,
    RESIZE_RATE = RESIZE_RATE,
    ED4_MAP_SQUARE_CORNERS = ED4_MAP_SQUARE_CORNERS,
    EGWD_MAP_SQUARE_CORNERS = EGWD_MAP_SQUARE_CORNERS,
    OUTSIDE_ED4_COORDS = OUTSIDE_ED4_COORDS,
    DIRECTION_TABLE = DIRECTION_TABLE,
    BLM_BASE_RATES = BLM_BASE_RATES,
    FEEDBACK_SPRITE_IDS = FEEDBACK_SPRITE_IDS
}