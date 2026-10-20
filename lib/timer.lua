--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]] --

--- @class TimerHandle
--- @field time number Accumulated elapsed time for this handle.
--- @field during fun(dt: number, remaining: number) Callback function executed every frame.
--- @field after fun(self_fn?: function): boolean|nil Callback function executed when timer hits limit.
--- @field limit number Target duration before trigger.
--- @field count number Remaining iterations.

--- @class Tween
--- @overload fun(self: Timer, len: number, subject: table, target: table, method?: string|function, after?: function, ...: any): TimerHandle
--- @field linear fun(s: number): number
--- @field quad fun(s: number): number
--- @field cubic fun(s: number): number
--- @field quart fun(s: number): number
--- @field quint fun(s: number): number
--- @field sine fun(s: number): number
--- @field expo fun(s: number): number
--- @field circ fun(s: number): number
--- @field back fun(s: number, bounciness?: number): number
--- @field bounce fun(s: number): number
--- @field elastic fun(s: number, amp?: number, period?: number): number
--- @field out fun(f: function): function
--- @field chain fun(f1: function, f2: function): function

--- @class Timer
--- @field functions table<TimerHandle, boolean> Active timer handles.
--- @field tween Tween
local Timer = {}
Timer.__index = Timer

local function _nothing_() end

local function updateTimerHandle(handle, dt)
    -- handle: {
    --   time = <number>,
    --   after = <function>,
    --   during = <function>,
    --   limit = <number>,
    --   count = <number>,
    -- }
    handle.time = handle.time + dt
    handle.during(dt, math.max(handle.limit - handle.time, 0))

    while handle.time >= handle.limit and handle.count > 0 do
        if handle.after(handle.after) == false then
            handle.count = 0
            break
        end
        handle.time = handle.time - handle.limit
        handle.count = handle.count - 1
    end
end

--- Updates all active timers in the instance.
--- @param dt number Delta time since last frame in seconds.
function Timer:update(dt)
    -- timers may create new timers, which leads to undefined behavior
    -- in pairs() - so we need to put them in a different table first
    local to_update = {}
    for handle in pairs(self.functions) do
        to_update[handle] = handle
    end

    for handle in pairs(to_update) do
        if self.functions[handle] then
            updateTimerHandle(handle, dt)
            if handle.count == 0 then
                self.functions[handle] = nil
            end
        end
    end
end

--- Runs a function continuously for a duration, then optionally calls a finishing function.
--- @param delay number Duration in seconds.
--- @param during fun(dt: number, remaining: number) Executed every update frame.
--- @param after? fun() Optional callback executed when timer finishes.
--- @return TimerHandle
function Timer:during(delay, during, after)
    local handle = { time = 0, during = during, after = after or _nothing_, limit = delay, count = 1 }
    self.functions[handle] = true
    return handle
end

--- Executes a callback once after a set delay.
--- @param delay number Delay in seconds.
--- @param func fun() Callback function.
--- @return TimerHandle
function Timer:after(delay, func)
    return self:during(delay, _nothing_, func)
end

--- Executes a callback repeatedly at fixed intervals.
--- @param delay number Delay between executions in seconds.
--- @param after fun(): boolean|nil Callback function. Return false to cancel early.
--- @param count? number Maximum number of iterations (defaults to math.huge).
--- @return TimerHandle
function Timer:every(delay, after, count)
    local count = count or math.huge -- exploit below: math.huge - 1 = math.huge
    local handle = { time = 0, during = _nothing_, after = after, limit = delay, count = count }
    self.functions[handle] = true
    return handle
end

--- Cancels an active timer handle.
--- @param handle TimerHandle Handle returned from timer methods.
function Timer:cancel(handle)
    self.functions[handle] = nil
end

--- Clears all active timers in this instance.
function Timer:clear()
    self.functions = {}
end

--- Executes a function inside a coroutine, allowing timed yields.
--- @param f fun(wait: fun(t: number)) Function containing yieldable timer logic.
function Timer:script(f)
    local co = coroutine.wrap(f)
    co(function(t)
        self:after(t, co)
        coroutine.yield()
    end)
end

Timer.tween = setmetatable({
    -- helper functions
    out     = function(f) -- 'rotates' a function
        return function(s, ...) return 1 - f(1 - s, ...) end
    end,
    chain   = function(f1, f2) -- concatenates two functions
        return function(s, ...) return (s < .5 and f1(2 * s, ...) or 1 + f2(2 * s - 1, ...)) * .5 end
    end,

    -- useful tweening functions
    linear  = function(s) return s end,
    quad    = function(s) return s * s end,
    cubic   = function(s) return s * s * s end,
    quart   = function(s) return s * s * s * s end,
    quint   = function(s) return s * s * s * s * s end,
    sine    = function(s) return 1 - math.cos(s * math.pi / 2) end,
    expo    = function(s) return 2 ^ (10 * (s - 1)) end,
    circ    = function(s) return 1 - math.sqrt(1 - s * s) end,

    back    = function(s, bounciness)
        bounciness = bounciness or 1.70158
        return s * s * ((bounciness + 1) * s - bounciness)
    end,

    bounce  = function(s) -- magic numbers ahead
        local a, b = 7.5625, 1 / 2.75
        return math.min(a * s ^ 2, a * (s - 1.5 * b) ^ 2 + .75, a * (s - 2.25 * b) ^ 2 + .9375, a * (s - 2.625 * b) ^ 2 +
            .984375)
    end,

    elastic = function(s, amp, period)
        amp, period = amp and math.max(1, amp) or 1, period or .3
        return (-amp * math.sin(2 * math.pi / period * (s - 1) - math.asin(1 / amp))) * 2 ^ (10 * (s - 1))
    end,
}, {

    -- register new tween
    __call = function(tween, self, len, subject, target, method, after, ...)
        -- recursively collects fields that are defined in both subject and target into a flat list
        local function tween_collect_payload(subject, target, out)
            for k, v in pairs(target) do
                local ref = subject[k]
                assert(type(v) == type(ref), 'Type mismatch in field "' .. k .. '".')
                if type(v) == 'table' then
                    tween_collect_payload(ref, v, out)
                else
                    local ok, delta = pcall(function() return (v - ref) * 1 end)
                    assert(ok, 'Field "' .. k .. '" does not support arithmetic operations')
                    out[#out + 1] = { subject, k, delta }
                end
            end
            return out
        end

        method = tween[method or 'linear'] -- see __index
        local payload, t, args = tween_collect_payload(subject, target, {}), 0, { ... }

        local last_s = 0
        return self:during(len, function(dt)
            t = t + dt
            local s = method(math.min(1, t / len), unpack(args))
            local ds = s - last_s
            last_s = s
            for _, info in ipairs(payload) do
                local ref, key, delta = unpack(info)
                ref[key] = ref[key] + delta * ds
            end
        end, after)
    end,

    -- fetches function and generated compositions for method `key`
    __index = function(tweens, key)
        if type(key) == 'function' then return key end

        assert(type(key) == 'string', 'Method must be function or string.')
        if rawget(tweens, key) then return rawget(tweens, key) end

        local function construct(pattern, f)
            local method = rawget(tweens, key:match(pattern))
            if method then return f(method) end
            return nil
        end

        local out, chain = rawget(tweens, 'out'), rawget(tweens, 'chain')
        return construct('^in%-([^-]+)$', function(...) return ... end)
            or construct('^out%-([^-]+)$', out)
            or construct('^in%-out%-([^-]+)$', function(f) return chain(f, out(f)) end)
            or construct('^out%-in%-([^-]+)$', function(f) return chain(out(f), f) end)
            or error('Unknown interpolation method: ' .. key)
    end
})

--- Creates a new isolated Timer instance.
--- @return Timer
function Timer.new()
    return setmetatable({ functions = {}, tween = Timer.tween }, Timer)
end

-- default instance
local default = Timer.new()

--- @class DefaultTimerModule : Timer
--- @field tween Tween
--- @operator call(): Timer
local module = {}
for k in pairs(Timer) do
    if k ~= "__index" then
        module[k] = function(...)
            if (...) == module then
                return default[k](default, select(2, ...))
            end
            return default[k](default, ...)
        end
    end
end
module.tween = setmetatable({}, {
    __index = Timer.tween,
    __newindex = function(k, v) Timer.tween[k] = v end,
    __call = function(t, ...) return default:tween(...) end,
})

return setmetatable(module, { __call = Timer.new })
