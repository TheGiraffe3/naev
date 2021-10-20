local graphics = require 'love.graphics'

local log = {
   border = 100,
   spacer = 10,
   headerw = 280,
   bodyw = 800
}

local _log, _header, _body, _colour

function log.reset ()
   _log = {
      { who="", what=_("[START]"), colour={1,1,1} },
   }
end

function log.add( entry )
   table.insert( _log, 1, entry )
end

function log.open ()
   local lw, lh = graphics.getDimensions()
   local border = log.border

   -- Build the tables
   -- TODO use vn.textbox_font
   log.font = graphics.newFont(16)
   local font = log.font
   local headerw = log.headerw
   local bodyw = log.bodyw
   _header = {}
   _body = {}
   _colour = {}
   local th = 0
   for id=#_log,1,-1 do
      local v = _log[id]
   end
   for id=#_log,1,-1 do
      local v = _log[id]
      local _maxw, headertext = font:getWrap( v.who, headerw )
      local _maxw, bodytext = font:getWrap( v.what, bodyw )

      local nlines = math.max( #headertext, #bodytext )
      for k=1,nlines do
         table.insert( _header, headertext[k] or "" )
         table.insert( _body,   bodytext[k] or "" )
         table.insert( _colour, v.colour )
      end
      table.insert( _header, "_" )
      table.insert( _body, "_" )
      table.insert( _colour, "_" )
      th = th + nlines * font:getLineHeight() + log.spacer
   end

   -- Determine offset
   log.y = lh-border-th
   log.miny = log.y
   log.maxy = log.border
end

function log.draw ()
   graphics.setColor( 0, 0, 0, 0.9 )
   local lw, lh = graphics.getDimensions()
   graphics.rectangle( "fill", 0, 0, lw, lh )

   local font = log.font
   local x = (lw-1080)/2
   local headerx = x
   local bodyx = x+200
   local lineh = font:getLineHeight()
   local y = log.y - lineh
   for k = 1,#_header do
      local c = _colour[k]
      if c == "_" then
         y = y+log.spacer
      else
         y = y+lineh
         if y > 0 and y < lh then
            graphics.setColor( c[1], c[2], c[3], 1 )
            graphics.print( _header[k], font, headerx, y )
            graphics.print( _body[k],   font, bodyx,   y )
         end
      end
   end

   graphics.setColor( 1, 1, 1, 1 )
   x = log.border + log.headerw + log.bodyw + log.spacer
   if log.y < log.maxy then
      graphics.print( "↑", font, x, 100 )
   end

   if log.y > log.miny then
      graphics.print( "↓", font, x, lh-100 )
   end
end

function log.update ()
end

function log.keypress( key )
   local lh = log.font:getLineHeight()
   if key=="up" then
      log.y = log.y + lh
   elseif key=="pageup" then
      log.y = log.y + 20*lh
   elseif key=="down" then
      log.y = log.y - lh
   elseif key=="pagedown" then
      log.y = log.y - 20*lh
   elseif key=="home" then
      log.y = log.maxy
   elseif key=="end" then
      log.y = log.miny
   end
   log.y = math.max( log.miny, math.min( log.maxy, log.y ) )

   if key=="tab" or key=="escape" or key=="space" or key=="enter" then
      return true, false
   end

   return true, true
end

function log.mousepressed( mx, my, button )
end

return log
