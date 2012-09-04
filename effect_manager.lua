module(..., package.seeall)

local methods = {}

function new()
   local tbl = {}
   setmetatable(tbl, {__index=methods})
   tbl:init()
   return tbl
end

function methods:init()
   self.effects = {} -- Array of current effects
   -- An effect is a table with a draw fn, an update fn, and a finished flag.
end

function methods:add(effect)
   assert(effect)
   assert(type(effect.draw) == 'function')
   assert(type(effect.update) == 'function')
   assert(not effect.finished)

   table.insert(self.effects, effect)
end

function methods:update(dt)
   local effects = self.effects
   local n = 1
   while n <= #effects do
      local e = effects[n]
      e:update(dt, self)
      if e.finished then
         table.remove(effects, n)
      else
         n = n + 1
      end
   end
end

function methods:draw(dt)
   for _, e in ipairs(self.effects) do
      e:draw()
   end
end

----------------------------------------
-- Effects:

local Puff = {
   duration = 0.5,
   final_size = 100
}

function puff(x, y, a)
   return setmetatable({x=x,y=y,a=a,t=0}, {__index=Puff})
end

function Puff:update(dt, effect_manager)
   self.t = self.t + dt
   self.finished = self.t >= self.duration
end

function Puff:draw()
   local g = love.graphics
   local s = self.final_size * self.t / self.duration

   g.push()
   g.translate(self.x, self.y)
   g.rotate(self.a)
   g.setColor(190, 190, 30, 255 * (self.duration - self.t))
   g.rectangle('fill', -s/2, -s/2, s, s)
   g.pop()
end

----------------------------------------

local Fade = {
   duration = 0.5
}

function fade(x, y)
   return setmetatable({x=x,y=y,t=0}, {__index=Fade})
end

function Fade:update(dt, effect_manager)
   self.t = self.t + dt

   self.finished = self.t >= self.duration

   if self.finished then
      effect_manager:add(vortex(self.x, self.y))
   end
end                     

function Fade:draw()
   local g = love.graphics

   g.push()
   g.translate(self.x, self.y)
   g.setColor(40, 230, 40, 255 * (self.duration - self.t))
   g.circle('fill', 0, 0, 16)
   g.pop()
end

----------------------------------------

local Vortex = {
   particle = love.graphics.newImage('particle.png')
}

function vortex(x, y)
   local p = love.graphics.newParticleSystem(Vortex.particle, 1000)
   local t = {x=x, y=y, particles = p}
   
   p:setColors(
      math.floor(0.22*255), math.floor(0.85*255), math.floor(0.22*255), 0, -- start
      math.floor(0.22*255), math.floor(0.85*255), math.floor(0.22*255), 255, -- start
      math.floor(0.22*255), math.floor(0.85*255), math.floor(0.22*255), 0
   )

   p:setLifetime(-1)

   p:setEmissionRate(60)
   p:setParticleLife(0.7, 1)
   p:setSizes(3, 0)

   p:setSpin(2)
   p:setRotation(0, math.pi*2)

   p:start()

   return setmetatable(t, {__index=Vortex})
end

function Vortex:update(dt)
   self.particles:update(dt)
end

function Vortex:draw()
   love.graphics.draw(self.particles, self.x, self.y)
end
