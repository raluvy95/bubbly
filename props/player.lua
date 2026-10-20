local Circle = require "props.circle"
local colors = require "lib.colors"
local Timer = require "lib.timer"

---@class Player
local Player = {}

---@class Player: Circle
Player = setmetatable({}, { __index = Circle })
Player.__index = Player

---@return Circle
function Player:new()
    local t = Circle.new(self, {
        npc = false,
        actionable = true,
        radius = 50,
        color = { 1, 1, 1, .5 },
    })

    setmetatable(t, Player)

    return t
end

function Player:render()
    local pulse = (math.sin(love.timer.getTime() * 2) + 1) / 2 -- range 0 to 1
    local factor = 0.2 + (0.6 * pulse)                         -- range 0.2 to 0.8
    love.graphics.setColor(colors.darken(factor, unpack(self.color)))
    love.graphics.circle("fill", self.x, self.y, self.radius, 25)
    love.graphics.setColor(unpack(self.color))
    love.graphics.circle("fill", self.x, self.y, self.radius / 3, 25)
end

function Player:update(dt)
    local x, y = love.mouse.getPosition()
    self:setCoord(x, y)
end

---@param circles Circle[]
function Player:nuke(circles)
    for _, v in ipairs(circles) do
        if v ~= self and self:collidesWithCircle(v) then
            v:infect()
        end
    end
end

return Player
