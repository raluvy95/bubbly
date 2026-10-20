local utils = {}
local timer = 0

---Appends items created by a factory function to an array-like table.
---@generic T
---@param target T[] The target array table to mutate
---@param factory fun(): T A function that returns a new instance of T
---@param count integer How many times to create and insert the item
---@return T[] target The modified target table
function utils.mass_insert(target, factory, count)
    local len = #target
    for _ = 1, count do
        len = len + 1
        target[len] = factory()
    end
    return target
end

---Waits a specific seconds to update function
---@param dt number
---@param fun function
---@param seconds number
function utils.wait(dt, fun, seconds)
    timer = timer + dt
    if timer >= seconds then
        fun()
        timer = 0
    end
end

return utils
