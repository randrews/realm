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
   self:makeCrates()
   self:makeGems()
   self.world:setCallbacks(function(...) self.contact(self, ...) end)
   self.player = self:makePlayer()
end

function methods:contact(a, b)
   print("Contact between " .. self:type(a) .. " and " .. self:type(b))
end

function methods:type(fixture)
   assert(fixture)
   local u = fixture:getUserData()
   if u then return u.type end
   return 'unknown'
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
   for _, s in ipairs(edge.shapes) do
      local f = love.physics.newFixture(edge.body, s)
      f:setUserData{body=edge.body, shape=s, type='edge'}
   end
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
         local s = ph.newRectangleShape(0, 0, SIZE, SIZE)

         b:setMass(5)
         b:setLinearDamping(SIZE / 2)
         b:setFixedRotation(true)
         local f = ph.newFixture(b, s)
         f:setUserData{body=b, shape=s, type='crate'}
         table.insert(self.crates, f:getUserData())
      end
   end         
end

function methods:makeGems()
   local ph = love.physics

   self.gems = {}

   for p in self:each() do
      if self(p) == '*' then
         local b = ph.newBody(self.world,
                              p.x*SIZE + SIZE/2,
                              p.y*SIZE + SIZE/2,
                              'dynamic')
         local s = ph.newRectangleShape(0, 0, SIZE/2, SIZE/2)

         b:setAngle(math.pi/4)
         local f = ph.newFixture(b, s)
         f:setUserData{body=b, shape=s, type='gem'}
         f:setSensor(true)
         b:applyTorque(150)
         table.insert(self.gems, f:getUserData())
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
         local f = ph.newFixture(walls, s)
         f:setUserData{body=walls, shape=s, type='wall'}
      end
   end
end

function methods:makePlayer()
   local player = {type='player'}
   local ph = love.physics

   player.body = ph.newBody(self.world, SIZE*1.5, SIZE*1.5, 'dynamic')
   player.shape = ph.newCircleShape(10)
   local f = ph.newFixture(player.body, player.shape)
   f:setUserData(player)
   player.body:setMass(1)

   return player
end

function methods:draw()
   local g = love.graphics

   -- Draw ground
   g.setColor(64, 120, 64)
   g.rectangle('fill', 0, 0, self.width*SIZE, self.height*SIZE)

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

   -- Draw gems
   g.setColor(190, 190, 30)
   for _, gem in ipairs(self.gems) do
      g.push()
      g.translate(gem.body:getX(), gem.body:getY())
      g.rotate(gem.body:getAngle())
      g.rectangle('fill', -SIZE/4, -SIZE/4, SIZE/2, SIZE/2)
      g.pop()
   end

   g.setColor(180, 120, 90)
   for _, c in ipairs(self.crates) do
      g.rectangle('fill', c.body:getX()-SIZE/2, c.body:getY()-SIZE/2, SIZE, SIZE)
   end
end

function methods:update(dt) 
   local k = love.keyboard.isDown
   local kd = 0 -- num of keys down
   local dir = point(0, 0)

   local p = self.player

   if k('up') then dir = dir + point.up ; kd = kd + 1 end
   if k('down') then dir = dir + point.down ; kd = kd + 1 end
   if k('left') then dir = dir + point.left ; kd = kd + 1 end
   if k('right') then dir = dir + point.right ; kd = kd + 1 end

   if kd > 0 then
      p.body:setLinearDamping(0)
   else
      p.body:setLinearDamping(8)
   end

   local f = dir * SIZE * 15
   self.player.body:applyForce(f())

   p.location = point(
      math.floor(p.body:getX() / SIZE),
      math.floor(p.body:getY() / SIZE))

   if kd == 1 then
      p.direction = dir
      self:dampenSidewaysVelocity(p.body, p.direction, dt)
   end

   if kd > 0 then
      p.target = p.location + dir
   end

   for _, c in ipairs(self.crates) do
      local sq = point(
         math.floor(c.body:getX() / SIZE),
         math.floor(c.body:getY() / SIZE))
      self:nudgeToSquare(c.body, sq, SIZE)
   end

   self:max_speed(p.body, SIZE * 10)
   self.world:update(dt)
end

function methods:nudgeToSquare(body, sq, acc)
   local y = body:getY() - SIZE/2
   local ty = sq.y * SIZE
   local f = acc * (ty - y)
   body:applyForce(0, f)

   local x = body:getX() - SIZE/2
   local tx = sq.x * SIZE
   local f = acc * (tx - x)
   body:applyForce(f, 0)
end

function methods:dampenSidewaysVelocity(body, dir, dt)
   local v = point(body:getLinearVelocity())
   local a = 1 - 8 * dt
   if a > 1.0 then a = 1.0 elseif a < 0 then a = 0 end

   if dir.y == 0 then v.y = v.y * a end
   if dir.x == 0 then v.x = v.x * a end

   body:setLinearVelocity(v())
end

function methods:max_speed(body, spd)
   local x, y = body:getLinearVelocity()
   if x*x + y*y > spd*spd then
      local a = math.atan2(y,x)
      body:setLinearVelocity(spd * math.cos(a),
                             spd * math.sin(a))
   end
end
