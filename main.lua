local Circle = require "props.circle"
local Player = require "props.player"
local button = require "props.button"
local Timer = require "lib.timer"
local audio = require "lib.audio"

---@type Circle[]
local circles = {}

---@class Player
local player = Player:new()

---@class Button
local Btn = button:new({
	text = "Circles: 9999",
	callback = function()
		Circle.summon(circles, 10)
	end
})

function love.load()
	audio.load()
	love.window.setMode(800, 600, {
		resizable = true,
		fullscreen = false,
		borderless = false
	})
	Circle.summon(circles, 50)

	Timer:every(5, function()
		Circle.summon(circles, 10)
	end)

	local icon = love.image.newImageData("assets/bubblyicon.png")
	love.window.setIcon(icon)
	love.window.setTitle("Bubbly")
end

function love.draw()
	for _, v in pairs(circles) do
		v:render()
	end
	player:render()
	Btn:render()
end

function love.mousepressed(x, y, button)
	local status = Btn:onPress(x, y, button)

	if button == 1 and status ~= true then
		player:nuke(circles)
	end
end

function love.update(dt)
	Timer:update(dt)

	player:update(dt)

	for i = #circles, 1, -1 do
		local v = circles[i]
		v:update(dt, circles)
		if v.dead then
			table.remove(circles, i)
		end
	end

	Btn.text = "Circles: " .. #circles
	Btn:update()
end
