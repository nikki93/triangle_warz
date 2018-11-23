require 'libs'
local server = cs.server

local serpent = require 'https://raw.githubusercontent.com/pkulchenko/serpent/522a6239f25997b101c585c0daf6a15b7e37fad9/src/serpent.lua'

local W, H = 800, 600 -- Game world size

server.enabled = true
server.start('22122')

local share = server.share
local homes = server.homes

function server.load()
    share.triangles = {}
    share.bullets = {}
end

function server.connect(id)
    share.triangles[id] = {
        x = math.random(0, W),
        y = math.random(0, H),
        r = math.random(),
        g = math.random(),
        b = math.random(),
        targetX = 0,
        targetY = 0,
    }
end

function server.disconnect(id)
end

function server.update(dt)
    -- Update triangles
    for id, tri in pairs(share.triangles) do
        local home = homes[id]
        if home.move then -- Info may have not arrived yet
            -- Set target
            tri.targetX, tri.targetY = home.targetX, home.targetY

            -- Move
            local move = home.move
            local vx, vy = 0, 0
            if move.up then vy = vy - 220 end
            if move.down then vy = vy + 220 end
            if move.left then vx = vx - 220 end
            if move.right then vx = vx + 220 end
            local vLen = math.sqrt(vx * vx + vy * vy)
            if vLen > 0 then vx, vy = 220 * vx / vLen, 220 * vy / vLen end -- Limit speed
            tri.x, tri.y = tri.x + vx * dt, tri.y + vy * dt
            if tri.x < 0 then tri.x = tri.x + W end
            if tri.x > W then tri.x = tri.x - W end
            if tri.y < 0 then tri.y = tri.y + H end
            if tri.y > H then tri.y = tri.y - H end
        end
    end
end
