module(..., package.seeall)

local SIZE = 32
local instance = {}

function new(start, level, opts)
   local e = {}
   setmetatable(e, {__index=instance})

   e.path = {}
   e.destination_idx = 1
   e.speed = SIZE * 2

   assert(#opts%2==0)
   for n = 1, #opts do
      if n%2==1 then
         table.insert(e.path, point(opts[n]*SIZE, opts[n+1]*SIZE) + point(SIZE/2, SIZE/2))
      end
   end

   local b = love.physics.newBody(level.world,
                                 SIZE*(start.x + 0.5), SIZE*(start.y + 0.5),
                                 'kinematic')
   local s = love.physics.newCircleShape(15)
   local _, entity = level.manager:add(b, s, 'enemy')
   e.entity = entity

   return e
end

function instance:update(dt)
   local loc = point(self.entity.body:getPosition())
   local dest = self.path[self.destination_idx]
   local delta = dest - loc
   local dir = delta:normal()

   if delta:magnitude() <= self.speed * dt then
      self.location = dest
      self.destination_idx = self.destination_idx + 1
      if self.destination_idx > #self.path then
         self.destination_idx = 1
      end
   else
      loc = loc + dir * (self.speed * dt)
   end

   self.entity.body:setPosition(loc())
end