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

function server.connect(clientId)
    share.triangles[clientId] = {
        x = math.random(0, W),
        y = math.random(0, H),
        r = math.random(),
        g = math.random(),
        b = math.random(),
        targetX = 0,
        targetY = 0,
        shootTimer = 0, -- Can shoot if <= 0
    }
end

function server.disconnect(clientId)
end

local nextBulletId = 1 -- For choosing bullet ids

function server.update(dt)
    -- Triangles
    for clientId, tri in pairs(share.triangles) do
        local home = homes[clientId]
        if home.move then -- Info may have not arrived yet
            -- Moving
            local move = home.move
            local vx, vy = 0, 0
            if move.up then vy = vy - 220 end
            if move.down then vy = vy + 220 end
            if move.left then vx = vx - 220 end
            if move.right then vx = vx + 220 end
            local vLen = math.sqrt(vx * vx + vy * vy)
            if vLen > 0 then vx, vy = 220 * vx / vLen, 220 * vy / vLen end -- Limit speed
            tri.x, tri.y = tri.x + vx * dt, tri.y + vy * dt
            tri.x, tri.y = math.max(0, math.min(tri.x, W)), math.max(0, math.min(tri.y, H))

            -- Targeting
            tri.targetX, tri.targetY = home.targetX, home.targetY

            -- Shooting
            if tri.shootTimer > 0 then -- Tick the shoot timer
                tri.shootTimer = tri.shootTimer - dt
            end
            if tri.shootTimer <= 0 and home.wantShoot then -- Can and want to shoot? Shoot!
                local dirX, dirY = tri.targetX - tri.x, tri.targetY - tri.y
                if dirX == 0 and dirY == 0 then dirX = 1 end -- Prevent division by zero
                local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
                dirX, dirY = dirX / dirLen, dirY / dirLen
                share.bullets[nextBulletId] = { -- Create the bullet
                    owner = clientId,
                    x = tri.x + 30 * dirX,
                    y = tri.y + 30 * dirY,
                    dirX = dirX,
                    dirY = dirY,
                    r = 1.5 * tri.r,
                    g = 1.5 * tri.g,
                    b = 1.5 * tri.b,
                    lifetime = 1,
                }
                nextBulletId = nextBulletId + 1
                tri.shootTimer = 0.2
            end
        end
    end

    -- Bullets
    for bulId, bul in pairs(share.bullets) do
        bul.x, bul.y = bul.x + 800 * bul.dirX * dt, bul.y + 800 * bul.dirY * dt
        bul.lifetime = bul.lifetime - dt
        if bul.lifetime <= 0 then
            share.bullets[bulId] = nil
        end
    end
end
