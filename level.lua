module(..., package.seeall)

local Map = require('map')

methods = setmetatable({}, {__index=Map.methods})
local SIZE = 32

function new(strs)
   local tbl = Map.new_from_strings(strs)
   getmetatable(tbl).__index = methods
   tbl:init()
   return tbl
end

function methods:init()
   self.world = love.physics.newWorld(0, 0)
   self:makeEdges()
   self:makeWalls()
   self:makeCrates(world)
   self.player = self:makePlayer()
end

function methods:makeEdges()
   local w = SIZE * self.width
   local h = SIZE * self.height

   local edge = {}
   edge.body = love.physics.newBody(self.world, 0, 0, 'static')
   edge.shapes = {}
   table.insert(edge.shapes, love.physics.newEdgeShape(0, 0, w, 0))
   table.insert(edge.shapes, love.physics.newEdgeShape(0, 0, 0, h))
   table.insert(edge.shapes, love.physics.newEdgeShape(w, h, w, 0))
   table.insert(edge.shapes, love.physics.newEdgeShape(w, h, 0, h))
   for _, s in ipairs(edge.shapes) do love.physics.newFixture(edge.body, s) end
   return edge
end

function methods:makeCrates()
   local ph = love.physics
   self.crates = {}

   for p in self:each() do
      if self(p) == 'o' then
         local b = ph.newBody(self.world,
                              p.x*SIZE + SIZE/2,
                              p.y*SIZE + SIZE/2,
                              'dynamic')
         local s = ph.newRectangleShape(0, 0,
                                        SIZE, SIZE)

         b:setMass(0.02)
         b:setLinearDamping(1)
         b:setFixedRotation(true)
         ph.newFixture(b, s)
         table.insert(self.crates, {body=b, shape=s})
      end
   end         
end

function methods:makeWalls()
   local ph = love.physics
   local walls = ph.newBody(self.world, 0, 0, 'static')

   for p in self:each() do
      if self(p) == '#' then
         local s = ph.newRectangleShape(p.x*SIZE + SIZE/2, p.y*SIZE + SIZE/2,
                                        SIZE, SIZE)
         ph.newFixture(walls, s)
      end
   end
end

function methods:makePlayer()
   local player = {}
   local ph = love.physics

   player.body = ph.newBody(self.world, SIZE*1.5, SIZE*1.5, 'dynamic')
   player.shape = ph.newCircleShape(10)
   ph.newFixture(player.body, player.shape)

   player.body:setMass(0.01)
   return player
end

function methods:draw()
   local g = love.graphics

   -- Draw ground
   g.setColor(64, 120, 64)
   g.rectangle('fill', 0, 0, self.width*SIZE, self.height*SIZE)

   -- if player.location then
   --    g.setColor(255,255,255)
   --    local l = player.location * SIZE
   --    g.rectangle('line', l.x, l.y, SIZE, SIZE)

   --    if player.direction then
   --       g.setColor(255,0,0)
   --       local t = (player.location + player.direction) * SIZE
   --       g.rectangle('line', t.x, t.y, SIZE, SIZE)
   --    end
   -- end

   -- Draw player
   g.setColor(160, 64, 64)
   g.circle('fill',
            self.player.body:getX(), self.player.body:getY(), SIZE/2)

   -- Draw walls
   g.setColor(155, 155, 155)
   for p in self:each() do
      if self(p) == '#' then
         g.rectangle('fill', p.x*SIZE, p.y*SIZE, SIZE, SIZE)
      end
   end

   g.setColor(180, 120, 90)
   for _, c in ipairs(self.crates) do
      g.rectangle('fill', c.body:getX()-SIZE/2, c.body:getY()-SIZE/2, SIZE, SIZE)
   end
end

function methods:update(dt)
   local f = 1200*dt
   local k = love.keyboard.isDown
   local kd = 0
   local dir = point(0, 0)

   local p = self.player

   if k('up') then dir = dir + point.up ; kd = kd + 1 end
   if k('down') then dir = dir + point.down ; kd = kd + 1 end
   if k('left') then dir = dir + point.left ; kd = kd + 1 end
   if k('right') then dir = dir + point.right ; kd = kd + 1 end

   if kd > 0 then
      p.body:setLinearDamping(0.25)
   else
      p.body:setLinearDamping(15)
   end

   p.location = point(
      math.floor(p.body:getX() / SIZE),
      math.floor(p.body:getY() / SIZE))

   if kd == 1 then
      p.direction = dir
   end

   if kd > 0 then
      p.target = p.location + dir
   end

   if p.target then
      self:nudgeToSquare(p.body, p.target, dt)
   end

   for _, c in ipairs(self.crates) do
      local sq = point(
         math.floor(c.body:getX() / SIZE),
         math.floor(c.body:getY() / SIZE))
      self:nudgeToSquare(c.body, sq, dt)
   end

   self:max_speed(p.body, 300)
   self.world:update(dt)
end

function methods:nudgeToSquare(body, sq, dt)
   local acc = 30

   local y = body:getY() - SIZE/2
   local ty = sq.y * SIZE
   local f = dt * acc * (ty - y)
   body:applyForce(0, f)

   local x = body:getX() - SIZE/2
   local tx = sq.x * SIZE
   local f = dt * acc * (tx - x)
   body:applyForce(f, 0)
end

function methods:max_speed(body, spd)
   local x, y = body:getLinearVelocity()
   if x*x + y*y > spd*spd then
      local a = math.atan2(y,x)
      body:setLinearVelocity(spd * math.cos(a),
                             spd * math.sin(a))
   end
end
