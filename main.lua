assert(love, "Run this inside Love")

local Map = require('map')
local point = require('point')

local world = nil

local edge = nil
local player = nil

local level = Map.new_from_strings{
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
   "........................."
}

function love.load()
   math.randomseed(os.time())

   love.physics.setMeter(32)
   world = love.physics.newWorld(0, 0)
   edge = makeEdges(world,
                    0, 0,
                    level.width*32, level.height*32)

   makeWalls(world, level, 32)
   player = makePlayer(world)
end

function makeEdges(world, x, y, w, h)
   local edge = {}
   edge.body = love.physics.newBody(world, 0, 0, 'static')
   edge.shapes = {}
   table.insert(edge.shapes, love.physics.newEdgeShape(x, y, x+w, y))
   table.insert(edge.shapes, love.physics.newEdgeShape(x, y, x, y+h))
   table.insert(edge.shapes, love.physics.newEdgeShape(x+w, y+h, x+w, y))
   table.insert(edge.shapes, love.physics.newEdgeShape(x+w, y+h, x, y+h))
   for _, s in ipairs(edge.shapes) do love.physics.newFixture(edge.body, s) end
   return edge
end

function makeWalls(world, level, size)
   local ph = love.physics
   size = size or 32
   local walls = ph.newBody(world, 0, 0, 'static')

   for p in level:each() do
      if level(p) == '#' then
         local s = ph.newRectangleShape(p.x*size + size/2, p.y*size + size/2,
                                        size, size)
         ph.newFixture(walls, s)
      end
   end
end

function makePlayer(world)
   local player = {}
   local ph = love.physics

   player.body = ph.newBody(world, 32, 32, 'dynamic')
   player.shape = ph.newCircleShape(10)
   ph.newFixture(player.body, player.shape)

   player.body:setMass(0.01)
   return player
end

function love.draw()
   local g = love.graphics

   g.setColor(64, 120, 64)
   g.rectangle('fill', 0, 0, level.width*32, level.height*32)

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
   local f = 600 * dt
   local k = love.keyboard.isDown
   local kd = false
   if k('up') then player.body:applyForce(0, -f) ; kd = true end
   if k('down') then player.body:applyForce(0, f) ; kd = true end
   if k('left') then player.body:applyForce(-f, 0) ; kd = true end
   if k('right') then player.body:applyForce(f, 0) ; kd = true end

   if kd then
      player.body:setLinearDamping(0.1)
   else
      player.body:setLinearDamping(10)
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