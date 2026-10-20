local colors   = require "lib.colors"
local Timer    = require "lib.timer"
local lume     = require "lib.lume"
local utils    = require "lib.utils"
local audio    = require "lib.audio"

---@alias Color [number, number, number]
---@alias Boundary [number, number, number, number]

---@class Circle
---@field x number
---@field y number
---@field color Color
---@field actionable boolean
---@field npc boolean
---@field radius number
---@field speedX number
---@field speedY number
---@field infected boolean
---@field dead boolean
local Circle   = {}
Circle.__index = Circle

---@param opts { x?: number, y?: number, color?: Color, actionable?: boolean, npc?: boolean, radius?: number }?
---@return Circle
function Circle:new(opts)
    opts = opts or {}
    local t = {
        x = opts.x or 0,
        y = opts.y or 0,
        color = opts.color or { colors.random() },
        actionable = opts.actionable or false,
        npc = opts.npc or false,
        radius = opts.radius or 20,
        speedX = 150 * (love.math.random(1, 2) * 2 - 3),
        speedY = 150 * (love.math.random(1, 2) * 2 - 3),
        infected = false,
        dead = false
    }
    setmetatable(t, Circle)
    return t
end

---Set coords
---@param x number
---@param y number
---@return Circle
function Circle:setCoord(x, y)
    self.x = x
    self.y = y
    return self
end

---Set color
---@param r number
---@param g number
---@param b number
---@return Circle
function Circle:setColor(r, g, b)
    self.color = { r, g, b }
    return self
end

---Returns visible boundaries
---@return Boundary
function Circle:getBoundary()
    return {
        self.x - self.radius, -- min X
        self.y - self.radius, -- min Y
        self.x + self.radius, -- max X
        self.y + self.radius  -- max Y
    }
end

---@alias BoundarySide "left" | "right" | "top" | "bottom"

---Checks if the circle touches or crosses the window boundaries
---@param bx number Safe area X
---@param by number Safe area Y
---@param bw number Safe area Width
---@param bh number Safe area Height
---@return boolean hit Whether a collision occurred
---@return BoundarySide[] sides List of sides hit
function Circle:hitsBoundary(bx, by, bw, bh)
    local minX, minY, maxX, maxY = unpack(self:getBoundary())
    local sides = {}

    if minX <= bx then table.insert(sides, "left") end
    if maxX >= (bx + bw) then table.insert(sides, "right") end
    if minY <= by then table.insert(sides, "top") end
    if maxY >= (by + bh) then table.insert(sides, "bottom") end

    return #sides > 0, sides
end

---Checks collision between this circle and another circle
---@param other Circle
---@return boolean hit
function Circle:collidesWithCircle(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    local distanceSq = dx * dx + dy * dy
    local radiiSum = self.radius + other.radius

    -- avoided math.sqrt for performance; comparing squared values is faster
    return distanceSq <= (radiiSum * radiiSum)
end

function Circle:render()
    if self.infected then
        local r, g, b = unpack(self.color)
        love.graphics.setColor(colors.lighten(.5, r, g, b, .5))
    else
        love.graphics.setColor(unpack(self.color))
    end
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

---@param dt number
function Circle:move(dt)
    local bx, by, bw, bh = love.window.getSafeArea()
    local hit, sides = self:hitsBoundary(bx, by, bw, bh)

    if hit then
        for _, side in ipairs(sides) do
            if side == "left" and self.speedX < 0 then
                self.speedX = -self.speedX
            elseif side == "right" and self.speedX > 0 then
                self.speedX = -self.speedX
            elseif side == "top" and self.speedY < 0 then
                self.speedY = -self.speedY
            elseif side == "bottom" and self.speedY > 0 then
                self.speedY = -self.speedY
            end
        end
    end

    local updateX = self.x + self.speedX * dt
    local updateY = self.y + self.speedY * dt
    self:setCoord(updateX, updateY)
end

---Summon circles
---@param circles Circle[]
---@param amount number
function Circle.summon(circles, amount)
    if #circles >= 500 then return end
    local bx, by, bw, bh = love.window.getSafeArea()
    utils.mass_insert(circles, function()
        return Circle:new({
            x = love.math.random(bx, bw),
            y = love.math.random(by, bh),
            npc = true
        })
    end, amount or 1)
    audio.play("appear")
end

---@param dt number
---@param circles Circle[]
function Circle:update(dt, circles)
    -- Stop moving if infected
    if self.npc and not self.infected then
        self:move(dt)

        -- Get all currently infected circles
        local infected = lume.filter(circles, function(c)
            return c.infected
        end)

        for _, v in ipairs(infected) do
            -- If this clean NPC hits ANY infected circle, infect THIS circle (self)
            if self:collidesWithCircle(v) then
                self:infect()
                break -- Exit loop early once infected
            end
        end
    end
end

---Helper method to handle infection state and animation cleanly
function Circle:infect()
    if self.infected then return end

    audio.play("pop")
    self.infected = true

    -- Target self (this NPC circle), not the circle that hit it
    Timer.tween(0.3, self, { radius = 120 }, 'out-quad', function()
        Timer.tween(2, self, { radius = 0 }, 'in-out-quad', function()
            self.dead = true
        end)
    end)
end

return Circle
