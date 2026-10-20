local collision = require "lib.collision"
local colors    = require "lib.colors"
local Timer     = require "lib.timer"

---@class Button
---@field text string
---@field callback fun()
---@field x integer
---@field y integer
---@field color Color
---@field font love.Font
---@field textWidth number
---@field textHeight number
---@field padding integer
---@field w number
---@field h number
---@field hoverProgress number
---@field hoverTween number
local Button    = {}
Button.__index  = Button

---Initialize Button class
---@param opts? { text?: string, callback?: fun(), x?: integer, y?: integer, color?: Color, font?: love.Font, padding?: integer, textColor?: Color }
---@return Button
function Button:new(opts)
    opts = opts or {}

    local font = opts.font or love.graphics.newFont("assets/Born2bSportyFS.otf", 22)
    local text = opts.text or "Hello World"
    local txtObj = love.graphics.newText(font, text)

    local padding = opts.padding or 10
    local textWidth = txtObj:getWidth()
    local textHeight = txtObj:getHeight()

    local t = {
        text = text,
        txtObj = txtObj,
        font = font,
        callback = opts.callback or function() end,
        x = opts.x or 10,
        y = opts.y or 10,
        color = opts.color or { colors.darken(.5, colors.random()) },
        textColor = opts.textColor or { 1, 1, 1, 1 },
        padding = padding,
        textWidth = textWidth,
        textHeight = textHeight,
        w = textWidth + (padding * 2),
        h = textHeight + (padding * 2),
        hoverProgress = 0,
        transitionSpeed = 10
    }

    return setmetatable(t, self)
end

---Used in mousepressed
---@param x number
---@param y number
---@param button number
function Button:onPress(x, y, button)
    if collision.check(self, { x = x, y = y }) and button == 1 then
        self.callback()
        return true
    else
        return false
    end
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function Button:render()
    local baseColor = self.color
    local hoverColor = { baseColor[1] * 1.3, baseColor[2] * 1.3, baseColor[3] * 1.3, 1 }

    local r = lerp(baseColor[1], hoverColor[1], self.hoverProgress)
    local g = lerp(baseColor[2], hoverColor[2], self.hoverProgress)
    local b = lerp(baseColor[3], hoverColor[3], self.hoverProgress)

    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 10)

    -- text draw
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.font)
    local yOffset = self.y + math.floor((self.h - self.textHeight) / 2)
    love.graphics.printf(self.text, self.x, yOffset, self.w, "center")
end

function Button:update()
    local mx, my = love.mouse.getPosition()
    local isHovered = collision.check({ x = mx, y = my }, self)

    -- Mouse ENTER
    if isHovered and not self.isHovered then
        self.isHovered = true
        Timer.tween(0.15, self, { hoverProgress = 1 }, 'out-quad')
        -- Mouse LEAVE
    elseif not isHovered and self.isHovered then
        self.isHovered = false
        Timer.tween(0.15, self, { hoverProgress = 0 }, 'out-quad')
    end
end

return Button
