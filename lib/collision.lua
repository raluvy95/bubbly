local Collision = {}

---@param c1 Circle
---@param c2 Circle
---@return boolean
function Collision.circleVsCircle(c1, c2)
    local dx = c1.x - c2.x
    local dy = c1.y - c2.y
    local distanceSq = dx * dx + dy * dy
    local radiiSum = c1.radius + c2.radius
    return distanceSq <= (radiiSum * radiiSum)
end

---@param circle Circle
---@param rect { x: number, y: number, w: number, h: number }
---@return boolean
function Collision.circleVsRect(circle, rect)
    local closestX = math.max(rect.x, math.min(circle.x, rect.x + rect.w))
    local closestY = math.max(rect.y, math.min(circle.y, rect.y + rect.h))

    local dx = circle.x - closestX
    local dy = circle.y - closestY

    return (dx * dx + dy * dy) <= (circle.radius * circle.radius)
end

---@param circle Circle
---@param point { x: number, y: number }
---@return boolean
function Collision.circleVsPoint(circle, point)
    local dx = circle.x - point.x
    local dy = circle.y - point.y
    return (dx * dx + dy * dy) <= (circle.radius * circle.radius)
end

---@param point { x: number, y: number }
---@param rect { x: number, y: number, w: number, h: number }
---@return boolean
function Collision.pointVsRect(point, rect)
    return point.x >= rect.x and
        point.x <= rect.x + rect.w and
        point.y >= rect.y and
        point.y <= rect.y + rect.h
end

---@param rect1 { x: number, y: number, w: number, h: number }
---@param rect2 { x: number, y: number, w: number, h: number }
---@return boolean
function Collision.rectVsRect(rect1, rect2)
    return rect1.x < rect2.x + rect2.w and
        rect1.x + rect1.w > rect2.x and
        rect1.y < rect2.y + rect2.h and
        rect1.y + rect1.h > rect2.y
end

---Generic shape collision checker
---@param a Circle|{ x: number, y: number, w: number, h: number }|{ x: number, y: number }
---@param b Circle|{ x: number, y: number, w: number, h: number }|{ x: number, y: number }
---@return boolean
function Collision.check(a, b)
    -- Circle vs Anything
    if a.radius then
        ---@cast a Circle
        if b.radius then
            ---@cast b Circle
            return Collision.circleVsCircle(a, b)
        elseif b.w and b.h then
            ---@cast b { x: number, y: number, w: number, h: number }
            return Collision.circleVsRect(a, b)
        elseif b.x and b.y then
            ---@cast b { x: number, y: number }
            return Collision.circleVsPoint(a, b)
        end
        -- Rect vs Anything
    elseif a.w and a.h then
        ---@cast a { x: number, y: number, w: number, h: number }
        if b.radius then
            ---@cast b Circle
            return Collision.circleVsRect(b, a)
        elseif b.w and b.h then
            ---@cast b { x: number, y: number, w: number, h: number }
            return Collision.rectVsRect(a, b)
        elseif b.x and b.y then
            ---@cast b { x: number, y: number }
            return Collision.pointVsRect(b, a)
        end
        -- Point vs Anything
    elseif a.x and a.y then
        ---@cast a { x: number, y: number }
        if b.radius then
            ---@cast b Circle
            return Collision.circleVsPoint(b, a)
        elseif b.w and b.h then
            ---@cast b { x: number, y: number, w: number, h: number }
            return Collision.pointVsRect(a, b)
        end
    end

    return false
end

return Collision
