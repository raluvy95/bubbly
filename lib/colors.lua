---@class ColorLib
local color = {}

-- helper to idiot-proof the inputs
local function clamp(val, min, max)
    if type(val) ~= "number" then return max end
    return val < min and min or (val > max and max or val)
end

---@param r number
---@param g number
---@param b number
---@param a? number
---@return number, number, number, number
function color.rgba(r, g, b, a)
    return clamp(r, 0, 255) / 255,
        clamp(g, 0, 255) / 255,
        clamp(b, 0, 255) / 255,
        a and clamp(a, 0, 255) / 255 or 1.0
end

---@param r number
---@param g number
---@param b number
---@param a? number
---@return integer, integer, integer, integer?
function color.to_rgba(r, g, b, a)
    return math.floor(clamp(r, 0, 1) * 255 + 0.5),
        math.floor(clamp(g, 0, 1) * 255 + 0.5),
        math.floor(clamp(b, 0, 1) * 255 + 0.5),
        a and math.floor(clamp(a, 0, 1) * 255 + 0.5) or nil
end

---@param hex_str string|number
---@param alpha_override? number
---@return number, number, number, number
function color.hex(hex_str, alpha_override)
    local h = tostring(hex_str or ""):gsub("#", ""):lower()
    local r, g, b, a = 255, 255, 255, 255

    if #h == 3 or #h == 4 then
        r = tonumber(h:sub(1, 1):rep(2), 16) or 255
        g = tonumber(h:sub(2, 2):rep(2), 16) or 255
        b = tonumber(h:sub(3, 3):rep(2), 16) or 255
        if #h == 4 then a = tonumber(h:sub(4, 4):rep(2), 16) or 255 end
    elseif #h == 6 or #h == 8 then
        r = tonumber(h:sub(1, 2), 16) or 255
        g = tonumber(h:sub(3, 4), 16) or 255
        b = tonumber(h:sub(5, 6), 16) or 255
        if #h == 8 then a = tonumber(h:sub(7, 8), 16) or 255 end
    end

    a = alpha_override and clamp(alpha_override, 0, 255) or a
    return r / 255, g / 255, b / 255, a / 255
end

---@param r number
---@param g number
---@param b number
---@param a? number
---@param include_hash? boolean
---@return string
function color.to_hex(r, g, b, a, include_hash)
    local r8, g8, b8, a8 = color.to_rgba(r, g, b, a)
    local hex = string.format("%02x%02x%02x", r8, g8, b8)

    if a8 then
        hex = hex .. string.format("%02x", a8)
    end

    return (include_hash and "#" or "") .. hex
end

---@param min? number 0-255 range
---@param max? number 0-255 range
---@param include_alpha? boolean
---@return number, number, number, number
function color.random(min, max, include_alpha)
    min = min or 0
    max = max or 255
    local r = love.math.random(min, max)
    local g = love.math.random(min, max)
    local b = love.math.random(min, max)
    local a = include_alpha and love.math.random(min, max) or 255
    return color.rgba(r, g, b, a)
end

---@param r number
---@param g number
---@param b number
---@param a? number
---@return number, number, number, number
function color.invert(r, g, b, a)
    return 1.0 - clamp(r, 0, 1),
        1.0 - clamp(g, 0, 1),
        1.0 - clamp(b, 0, 1),
        a and clamp(a, 0, 1) or 1.0
end

---@param factor number 0.0 to 1.0 (e.g. 0.2 = 20% lighter)
---@param r number
---@param g number
---@param b number
---@param a? number
---@return number, number, number, number
function color.lighten(factor, r, g, b, a)
    local f = clamp(factor, 0, 1)
    return clamp(r + (1.0 - r) * f, 0, 1),
        clamp(g + (1.0 - g) * f, 0, 1),
        clamp(b + (1.0 - b) * f, 0, 1),
        a and clamp(a, 0, 1) or 1.0
end

---@param factor number 0.0 to 1.0 (e.g. 0.2 = 20% darker)
---@param r number
---@param g number
---@param b number
---@param a? number
---@return number, number, number, number
function color.darken(factor, r, g, b, a)
    local f = 1.0 - clamp(factor, 0, 1)
    return clamp(r * f, 0, 1),
        clamp(g * f, 0, 1),
        clamp(b * f, 0, 1),
        a and clamp(a, 0, 1) or 1.0
end

--- Tint/colorize a normalized LÖVE color (0-1) with a custom hex effect
---@param r number Base red (0-1)
---@param g number Base green (0-1)
---@param b number Base blue (0-1)
---@param a? number Base alpha (0-1)
---@param hex_effect string|number Tint hex (e.g. "#ff0055")
---@param alpha_override? number 0-255 range
---@return number, number, number, number
function color.colorize(r, g, b, a, hex_effect, alpha_override)
    local tr, tg, tb, ta = color.hex(hex_effect)

    local cr = clamp(r, 0, 1) * tr
    local cg = clamp(g, 0, 1) * tg
    local cb = clamp(b, 0, 1) * tb

    local base_a = a and clamp(a, 0, 1) or 1.0
    local final_a = alpha_override and (clamp(alpha_override, 0, 255) / 255) or (base_a * ta)

    return cr, cg, cb, final_a
end

return color
