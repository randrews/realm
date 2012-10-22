module(..., package.seeall)

local SIZE = 32
local instance = {}

function new(level, path)
   local e = {}
   setmetatable(e, {__index=instance})

   e.path = path
   e.destination_idx = 2
   e.speed = SIZE * 2

   assert(#e.path > 0)
   local start = e.path[1]

   local b = love.physics.newBody(level.world,
                                 start.x, start.y,
                                 'kinematic')
   local s = love.physics.newCircleShape(15)
   local _, entity = level.manager:add(b, s, 'enemy')
   e.entity = entity

   return e
end

function instance:update(dt)
   if self.destination_idx > #self.path then return end

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