module(..., package.seeall)

local SIZE = 32
local methods = _M

function methods:draw()
   local g = love.graphics

   -- Draw ground
   g.setColor(64, 120, 64)
   g.rectangle('fill', 0, 0, self.width*SIZE, self.height*SIZE)

   -- Message markers
   local lw = g.getLineWidth()
   g.setColor(80, 110, 240)
   g.setLineWidth(3)
   for pt, msg in pairs(self.messages) do
      pt = pt * SIZE + point(SIZE/2, SIZE/2)
      g.circle('line', pt.x, pt.y, SIZE/2*0.8)
   end
   g.setLineWidth(lw)

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

   -- Message boxes
   local plyr = point(self.player.body:getX(), self.player.body:getY())
   
   for pt, msg in pairs(self.messages) do
      pt = pt * SIZE + point(SIZE/2, SIZE/2)
      local d = pt:dist(plyr)
      if d <= SIZE*2 then
         drawMessageBox(pt + point(msg.dx, msg.dy),
                        msg[1],
                        (SIZE*2-d) / (SIZE*2) * 255)
      end
   end

   self.effect_manager:draw()
end

------------------------------------------------------------

function messageSize(msg)
   local font = love.graphics.getFont()
   local w, l = font:getWrap(msg, 1000)
   return w, l*font:getHeight()
end

function drawMessageBox(topleft, msg, opacity)
   local g = love.graphics
   local w, h = messageSize(msg)

   g.setColor(80, 110, 240, opacity)
   g.rectangle('fill', topleft.x, topleft.y,
               w+20, h+20)

   g.setColor(255, 255, 255, opacity)
   g.print(msg, topleft.x+10, topleft.y+10)
end

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
   local goal = self.manager:find('goal_blocker')[1]

   if goal then
      local g = love.graphics

      g.push()
      g.translate(goal.body:getX(), goal.body:getY())
      g.setColor(10, 70, 10)
      g.circle('fill', 0, 0, goal.shape:getRadius())

      if self.gem_count > 0 then
         g.rotate(-math.pi/2)
         g.setColor(40, 230, 40)
         local a = math.pi * 2 * (self.player.gem_count / self.gem_count)
         g.arc('fill', 0, 0, goal.shape:getRadius(), 0, a)
      end

      g.pop()
   end
end