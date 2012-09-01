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
      e:update(dt)
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

function Puff:update(dt)
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