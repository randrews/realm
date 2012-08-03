assert(love, "Run this inside Love")

local Level = require('level')
local point = require('point')

local world = nil

local edge = nil
local player = nil

local level = Level.new{
   "..........######.........",
   "..........#..............",
   "..........#.#............",
   ".....######.#............",
   "............#............",
   ".....##..##.#............",
   "......#..##.#............",
   "......#..#........#......",
   "..................#.##...",
   ".........................",
   ".....#...#.......##.#....",
   "...#...#...#........#....",
   ".....#...#...............",
   ".........................",
   ".........................",
   "........................."
}

function love.load()
   math.randomseed(os.time())

   love.physics.setMeter(32)
   world = love.physics.newWorld(0, 0)

   edge = level:makeEdges(world)
   level:makeWalls(world)
   player = level:makePlayer(world)
end

function love.draw()
   local g = love.graphics

   g.setColor(64, 120, 64)
   g.rectangle('fill', 0, 0, level.width*32, level.height*32)

   if player.location then
      g.setColor(255,255,255)
      local l = player.location * 32
      g.rectangle('line', l.x, l.y, 32, 32)

      if player.direction then
         g.setColor(255,0,0)
         local t = (player.location + player.direction) * 32
         g.rectangle('line', t.x, t.y, 32, 32)
      end
   end

   g.setColor(160, 64, 64)
   g.circle('fill',
            player.body:getX(), player.body:getY(), 16)

   g.setColor(155, 155, 155)
   for p in level:each() do
      if level(p) == '#' then
         g.rectangle('fill', p.x*32, p.y*32, 32, 32)
      end
   end
end

function love.mousepressed(mouse_x, mouse_y)
end

function love.mousereleased()
end

function love.update(dt)
   local f = 1500 * dt
   local k = love.keyboard.isDown
   local kd = 0
   local dir = nil

   if k('up') then player.body:applyForce(0, -f) ; dir = point.up ; kd = kd + 1 end
   if k('down') then player.body:applyForce(0, f) ; dir = point.down ; kd = kd + 1 end
   if k('left') then player.body:applyForce(-f, 0) ; dir = point.left ; kd = kd + 1 end
   if k('right') then player.body:applyForce(f, 0) ; dir = point.right ; kd = kd + 1 end

   if kd > 0 then
      player.body:setLinearDamping(0.25)
   else
      player.body:setLinearDamping(15)
   end

   player.location = point(
      math.floor(player.body:getX() / 32),
      math.floor(player.body:getY() / 32))

   if kd == 1 then
      player.direction = dir
      local acc = 25

      if player.direction.y == 0 then -- horizontal
         local y = player.body:getY()-16
         local ty = player.location.y * 32
         local f = dt * acc * (ty - y)
         player.body:applyForce(0, f)
      else -- vertical
         local x = player.body:getX()-16
         local tx = player.location.x * 32
         local f = dt * acc * (tx - x)
         player.body:applyForce(f, 0)
      end
   end

   max_speed(player.body, 300)
   world:update(dt)
end

function max_speed(body, spd)
   local x, y = body:getLinearVelocity()
   if x*x + y*y > spd*spd then
      local a = math.atan2(y,x)
      body:setLinearVelocity(spd * math.cos(a),
                             spd * math.sin(a))
   end
end