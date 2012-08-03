module(..., package.seeall)

local point = require('point')

methods = {}

function new(w, h)
   local tbl = {
      width = w or 10,
      height = h or w or 10,
   }

   setmetatable(tbl, {__index=methods,
                      __tostring=__tostring,
                      __call=methods.at})
   tbl:clear(0)
   return tbl
end

function new_from_strings(strs)
   local m = new(#(strs[1]), #strs)
   for p in m:each() do
      local s = strs[p.y+1]:sub(p.x+1, p.x+1)
      m(p, s)
   end
   return m
end

function methods:at(pt, val)
   if self:inside(pt) then
      if val~=nil then self[pt.x+pt.y*self.width] = val end
      return self[pt.x+pt.y*self.width]
   else
      return nil
   end
end

function methods:clamp(pt)
   pt = pt:copy()
   if pt.x < 0 then pt.x = 0 end
   if pt.x > self.width-1 then pt.x = self.width-1 end
   if pt.y < 0 then pt.y = 0 end
   if pt.y > self.height-1 then pt.y = self.height-1 end
   return pt
end

function methods:inside(pt)
   return pt >= point(0, 0) and pt < point(self.width, self.height)
end

function methods:clear(value)
   for p in self:each() do
      self:at(p, value)
   end
end

function methods:each(start, w, h)
   local maxx, maxy

   if w then maxx = start.x + w-1 else maxx = self.width-1 end
   if h then maxy = start.y + h-1 else maxy = self.height-1 end

   start = start or point(0, 0)
   local p = start

   return function()
             local r = p -- return this one...

             -- Decide what the next one will be:
             p = p + point(1, 0)
             if p.x > maxx then p = point(start.x, p.y+1) end

             if r.y > maxy then return nil
             else return r end
          end
end

function __tostring(self)
   local s = ''

   for y = 0, self.height-1 do
      for x = 0, self.width-1 do
         s = s .. tostring(self:at(point(x,y))) .. ' '
      end
      s = s .. "\n"
   end

   return s
end

function methods:find(fn)
   local fit = {}
   for pt in self:each() do
      if not fn or fn(self, pt) then table.insert(fit, pt) end
   end
   return fit
end

function methods:random(fn)
   local fit = self:find(fn)
   if #fit == 0 then return nil
   else return fit[math.random(#fit)] end
end

----------------------------------------

function methods:empty(pt)
   return self:at(pt) == ''
end

function methods:full(pt)
   return not self:empty(pt)
end

function methods:neighbors(pt, fn)
   local all = {pt + point(-1, 0),
                pt + point(1, 0),
                pt + point(0, -1),
                pt + point(0, 1)}

   local fit = {}
   for _, p in ipairs(all) do
      if self:inside(p) and (not fn or fn(self, p)) then table.insert(fit, p) end
   end
   return fit
end

function methods:random_walk(current)
   return function()
             local r = current -- return this one...

             if r then
                local possibles = self:neighbors(current, self.empty)
                if #possibles == 0 then current = nil
                else current = possibles[math.random(#possibles)] end
             end

             return r, current
          end
end

function methods:maze()
   self:clear('')
   local current_start = self:random()

   local function valid_start(map, pt)
      return map:full(pt) and #(map:neighbors(pt, map.empty)) > 0
   end

   while current_start do
      for pt, nx in self:random_walk(current_start) do
         if nx then self:connect(pt, nx) end
      end

      current_start = self:random(valid_start)
   end

   local function normalize(str)
      local s = ''
      if str:match('e') then s = s .. 'e' end
      if str:match('n') then s = s .. 'n' end
      if str:match('s') then s = s .. 's' end
      if str:match('w') then s = s .. 'w' end
      return s
   end

   for pt in self:each() do
      self:at(pt, normalize(self:at(pt)))
   end
end

function methods:connect(pt1, pt2)
   assert(self:inside(pt1) and self:inside(pt2) and pt1:adjacent(pt2))

   local dir = nil -- one-char dir from 1 to 2
   if pt1.x < pt2.x then dir = 'e'
   elseif pt1.x > pt2.x then dir = 'w'
   elseif pt1.y < pt2.y then dir = 's'
   elseif pt1.y > pt2.y then dir = 'n' end

   if dir == 'n' then
      self:at(pt1, self:at(pt1)..'n')
      self:at(pt2, self:at(pt2)..'s')
   elseif dir == 's' then
      self:at(pt1, self:at(pt1)..'s')
      self:at(pt2, self:at(pt2)..'n')
   elseif dir == 'e' then
      self:at(pt1, self:at(pt1)..'e')
      self:at(pt2, self:at(pt2)..'w')
   elseif dir == 'w' then
      self:at(pt1, self:at(pt1)..'w')
      self:at(pt2, self:at(pt2)..'e')
   end
end

function methods:connected(pt, fn)
   local c = {}
   local s = self:at(pt)
   if s:match('n') then table.insert(c, pt+point(0,-1)) end
   if s:match('e') then table.insert(c, pt+point(1, 0)) end
   if s:match('s') then table.insert(c, pt+point(0, 1)) end
   if s:match('w') then table.insert(c, pt+point(-1,0)) end

   if fn then
      local m = {}
      for _, p in ipairs(c) do
         if fn(self,p) then table.insert(m, p) end
      end
      c = m
   end

   return c
end

----------------------------------------

function test()
   -- Constructor
   local m = _M.new(10)
   assert(m.width == 10)
   assert(m:inside(point(3,3)))
   assert(not m:inside(point(10,10)))

   -- clear / set
   m:clear(0)
   m:at(point(3,2),1)

   -- at
   assert(m:at(point(1,1)) == 0)
   assert(m:at(point(3,2)) == 1)
   assert(m:at(point(10,10)) == nil)

   -- each
   local n = 0
   for p in m:each() do n = n + 1 end
   assert(n == 100)

   -- fit
   m:clear('')
   m:at(point(1,0),1)
   assert(#(m:neighbors(point(5,5))) == 4)
   assert(#(m:neighbors(point(0,1))) == 3)
   assert(#(m:neighbors(point(0,0))) == 2)
   assert(#(m:neighbors(point(0,0), m.empty)) == 1)

   -- random_walk
   m:clear('')
   for pt, nx in m:random_walk(point(5,5)) do
      -- print(pt, nx)
      assert(m:empty(pt))
      assert(not nx or m:empty(nx))
      m:at(pt, 1)
   end
   -- print(m)

   -- maze
   m:maze()
   --print(m)

   local n2 = 0
   for p in m:each(point(2, 2), 4, 4) do n2 = n2 + 1 end
   assert(n2 == 16)
end

test()