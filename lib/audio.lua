local audio = {}

audio.load = function()
    audio.appearSource = love.audio.newSource("assets/appear.wav", "static")
    audio.popSource = love.audio.newSource("assets/pop.wav", "static")
end

---Play sound effect with automatic random pitch
---@param type "appear"|"pop"
audio.play = function(type)
    local src = (type == "appear" and audio.appearSource or audio.popSource)

    local instance = src:clone()

    -- Pick a random pitch between 0.9x and 1.1x speed/pitch
    local pitch = love.math.random(0.9, 1.1)
    instance:setPitch(pitch)

    instance:play()
end

return audio
