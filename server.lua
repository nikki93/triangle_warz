local cs = require 'https://raw.githubusercontent.com/expo/share.lua/2d850666da9ac1fb32489cf1090547b8b0b9dd4c/cs.lua'
local server = cs.server

local common = require 'common'

local W, H = 800, 600 -- Game world size

--server.enabled = true
server.useCastleServer()
--server.start('22122')

local share = server.share
local homes = server.homes

function server.load()
    share.scores = {}
    share.triangles = {}
    share.bullets = {}
end

function server.connect(clientId)
    share.scores[clientId] = 0
    share.triangles[clientId] = {
        x = math.random(0, W),
        y = math.random(0, H),
        r = math.random(),
        g = math.random(),
        b = math.random(),
        vx = 0,
        vy = 0,
        targetX = 0,
        targetY = 0,
        shootTimer = 0, -- Can shoot if <= 0
        health = 100,
    }
end

function server.disconnect(clientId)
    share.scores[clientId] = nil
    share.triangles[clientId] = nil
end

local nextBulletId = 1 -- For choosing bullet ids

function server.update(dt)
    -- Triangles
    for clientId, tri in pairs(share.triangles) do
        local home = homes[clientId]
        if home.move then -- Info may have not arrived yet
            -- Moving
            common.move_triangle(tri, dt, home)

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
                    ownerClientId = clientId,
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
                server.send('all', 'bulletSound')
            end

            -- Check if we got shot...
            local nang = -math.atan2(tri.targetY - tri.y, tri.targetX - tri.x)
            local sin, cos = math.sin(nang), math.cos(nang)
            for bulId, bul in pairs(share.bullets) do
                if bul.ownerClientId ~= clientId then -- Don't get shot by own bullet...
                    local dx, dy = bul.x - tri.x, bul.y - tri.y
                    local hitX, hitY
                    if dx * dx + dy * dy < 3600 then -- Ignore if far
                        for i = -1, 1, 0.2 do -- Check a few points to prevent 'tunneling'
                            -- Isosceles triangle point membership math...
                            local bx, by = bul.x + 18 * i * bul.dirX, bul.y + 18 * i * bul.dirY
                            local dx, dy = bx - tri.x, by - tri.y
                            local rdx, rdy = dx * cos - dy * sin, dx * sin + dy * cos
                            if rdx > -20 then
                                rdx = rdx + 20
                                rdy = math.abs(rdy)
                                if rdx / 50 + rdy / 20 < 1 then
                                    hitX, hitY = bx, by
                                    break
                                end
                            end
                        end
                    end
                    if hitX then -- We got shot!
                        share.bullets[bulId] = nil
                        tri.health = tri.health - 5
                        if tri.health <= 0 then -- We died!
                            tri.health = 100
                            tri.x, tri.y = math.random(10, W - 10), math.random(10, H - 10)
                            local shooterScore = share.scores[bul.ownerClientId] -- Award shooter
                            if shooterScore then
                                share.scores[bul.ownerClientId] = shooterScore + 1
                            end
                            server.send('all', 'bigExplosionSound')
                        else -- Just got hurt
                            server.send('all', 'smallExplosionSound')
                        end
                    end
                end
            end
        end
    end

    -- Bullets
    for bulId, bul in pairs(share.bullets) do
        common.move_bullet(bul, dt)
        bul.lifetime = bul.lifetime - dt
        if bul.lifetime <= 0 then
            share.bullets[bulId] = nil
        end
    end
end
