module(..., package.seeall)

local SIZE = 32
methods = {}

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
      drawEntity(gem)
   end

   -- Draw crates
   g.setColor(180, 120, 90)
   for _, c in ipairs(self.manager:find('crate')) do
      drawEntity(c)
   end

   -- Draw goal
   drawGoal(self)

   self.effect_manager:draw()
end

------------------------------------------------------------

-- Takes an entity with a rectangular shape and draws it
function drawEntity(e)
   local g = love.graphics

   g.push()
   g.translate(e.body:getX(), e.body:getY())
   g.rotate(e.body:getAngle())
   local tlx, tly, brx, bry = e.shape:computeAABB(0, 0, 0)
   g.rectangle('fill', tlx, tly, brx-tlx, bry-tly)
   g.pop()
end

function drawGoal(self)
   local g = love.graphics

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
end