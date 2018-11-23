local common = {}

local W, H = 800, 600 -- Game world size

function common.move_triangle(tri, dt, home) -- `home` is used to apply controls if given
    tri.vx, tri.vy = 0, 0
    if home then
        local move = home.move
        if move.up then tri.vy = tri.vy - 220 end
        if move.down then tri.vy = tri.vy + 220 end
        if move.left then tri.vx = tri.vx - 220 end
        if move.right then tri.vx = tri.vx + 220 end
    end
    local v = math.sqrt(tri.vx * tri.vx + tri.vy * tri.vy)
    if v > 0 then tri.vx, tri.vy = 220 * tri.vx / v, 220 * tri.vy / v end -- Limit speed
    tri.x, tri.y = tri.x + tri.vx * dt, tri.y + tri.vy * dt
    tri.x, tri.y = math.max(0, math.min(tri.x, W)), math.max(0, math.min(tri.y, H))
end

function common.move_bullet(bul, dt)
    bul.x, bul.y = bul.x + 800 * bul.dirX * dt, bul.y + 800 * bul.dirY * dt
end

return common