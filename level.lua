module(..., package.seeall)

local Map = require('map')
local EntityManager = require('entity_manager')
local EffectManager = require('effect_manager')

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
   self.manager = EntityManager.new(self.world)
   self.effect_manager = EffectManager.new()
   self.gem_count = 0

   self:makeEdges()
   self:makeWalls()
   self:makeCrates()
   self:makeGems()
   self.goal = self:makeGoal()
   self.player = self:makePlayer()

   self.manager:handler('gem', 'player',
                        function(gem, player)
                           self.player.gem_count = self.player.gem_count + 1
                           self.manager:remove(gem)
                           self.effect_manager:add(EffectManager.puff(gem.body:getX(), gem.body:getY(), gem.body:getAngle()))
                        end)

   self.manager:handler('gem', 'crate',
                        function(gem, crate)
                           local f = SIZE * 15
                           local dx = crate.body:getX() - gem.body:getX()
                           local dy = crate.body:getY() - gem.body:getY()
                           crate.body:applyForce(f*dx, f*dy)
                        end)
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
      self.manager:add(edge.body, s, 'edge')
   end
end

function methods:makeCrates()
   local ph = love.physics

   for p in self:each() do
      if self(p) == 'o' then
         local b = ph.newBody(self.world,
                              p.x*SIZE + SIZE/2,
                              p.y*SIZE + SIZE/2,
                              'dynamic')
         local s = ph.newRectangleShape(SIZE*0.8, SIZE*0.8)

         b:setMass(5)
         b:setLinearDamping(SIZE / 2)
         b:setFixedRotation(true)
         self.manager:add(b, s, 'crate')
      end
   end         
end

function methods:makeGems()
   local ph = love.physics
   self.gem_count = 0

   for p in self:each() do
      if self(p) == '*' then
         self.gem_count = self.gem_count + 1

         local b = ph.newBody(self.world,
                              p.x*SIZE + SIZE/2,
                              p.y*SIZE + SIZE/2,
                              'dynamic')
         local s = ph.newRectangleShape(0, 0, SIZE/2, SIZE/2)

         b:setAngle(math.pi/4)
         b:applyTorque(150)

         local f = self.manager:add(b, s, 'gem')
         f:setSensor(true)
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
         self.manager:add(walls, s, 'wall')
      end
   end
end

function methods:makePlayer()
   local player = self:find(function(m, pt) return m(pt) == '@' end)
   assert(#player == 1, "Must be exactly 1 player start location")
   player = player[1]

   local b = love.physics.newBody(self.world, SIZE*(player.x + 0.5), SIZE*(player.y + 0.5), 'dynamic')
   b:setMass(1)
   local s = love.physics.newCircleShape(10)

   local fix, player_entity = self.manager:add(b, s, 'player')
   player_entity.gem_count = 0

   return player_entity
end

function methods:makeGoal()
   local goal_loc = self:find(function(m,pt) return m(pt) == '&' end)
   assert(#goal_loc == 1, "Must be exactly one goal")
   goal_loc = goal_loc[1]

   local ph = love.physics
   local goal_blocker = ph.newBody(self.world,
                                   goal_loc.x*SIZE+SIZE/2,
                                   goal_loc.y*SIZE+SIZE/2,
                                   'static')
   local gb_shape = ph.newCircleShape(0, 0, SIZE/2*0.9)

   local _, goal_entity = self.manager:add(goal_blocker, gb_shape, 'goal_blocker')
   return goal_entity
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
   for _, gem in ipairs(self.manager:find('gem')) do
      self:drawEntity(gem)
   end

   -- Draw crates
   g.setColor(180, 120, 90)
   for _, c in ipairs(self.manager:find('crate')) do
      self:drawEntity(c)
   end

   -- Draw goal
   g.push()
   g.translate(self.goal.body:getX(), self.goal.body:getY())
   g.setColor(10, 70, 10)
   g.circle('fill', 0, 0, self.goal.shape:getRadius())

   if self.gem_count > 0 then
      g.rotate(-math.pi/2)
      g.setColor(40, 230, 40)
      local a = math.pi * 2 * (self.player.gem_count / self.gem_count)
      g.arc('fill', 0, 0, self.goal.shape:getRadius(), 0, a)
   end

   g.pop()

   self.effect_manager:draw()
end

-- Takes an entity with a rectangular shape and draws it
function methods:drawEntity(e)
   local g = love.graphics

   g.push()
   g.translate(e.body:getX(), e.body:getY())
   g.rotate(e.body:getAngle())
   local tlx, tly, brx, bry = e.shape:computeAABB(0, 0, 0)
   g.rectangle('fill', tlx, tly, brx-tlx, bry-tly)
   g.pop()
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

   for _, c in ipairs(self.manager:find('crate')) do
      local sq = point(
         math.floor(c.body:getX() / SIZE),
         math.floor(c.body:getY() / SIZE))
      self:nudgeToSquare(c.body, sq, SIZE)
   end

   self:max_speed(p.body, SIZE * 10)
   self.manager:cull()
   self.world:update(dt)
   self.effect_manager:update(dt)
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
