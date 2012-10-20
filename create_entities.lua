module(..., package.seeall)

local SIZE = 32
local methods = _M

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

function methods:makeSpecials(specials)
   for p in self:each() do
      local c = self(p)

      if c >= '0' and c <= '9' then
         self.messages[p] = specials[c]
      end
   end
end