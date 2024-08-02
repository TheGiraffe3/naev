local cmark = require "cmark"
local lyaml = require "lyaml"
local lf = require "love.filesystem"
local luatk = require 'luatk'
local md = require "luatk.markdown"
local fmt = require "format"
local utf8 = require "utf8"

local naevpedia = {}

local function strsplit( str, sep )
   sep = sep or "%s"
   local t={}
   for s in utf8.gmatch(str, "([^"..sep.."]+)") do
      table.insert(t, s)
   end
   return t
end

--[[--
Pulls out the metadata header of the naevpedia file.
--]]
local function extractmetadata( entry, s )
   local path = strsplit( entry, "/" )
   local meta = {
      entry = entry,
      category = path[1],
      name = path[#path],
   }
   if #path >= 3 then
      meta.parent = path[2] -- Just use subcategory (assuming only same category is visible)
   end
   if utf8.find( s, "---\n", 1, true )==1 then
      local es, ee = utf8.find( s, "---\n", 4, true )
      meta = tmerge( meta, lyaml.load( utf8.sub( s, 4, es-1 ) ) )
      s = utf8.sub( s, ee+1 )
   end
   -- Post-processing
   if meta.cond then
      local c, cerror = loadstring(meta.cond)
      if not c then
         warn( cerror )
      else
         setfenv( c, _G )
         meta.condchunk = c
         if __debugging then
            meta.condchunk()
         end
      end
   end
   return s, meta
end

-- Load into the cache to avoid having to slurp all the files all the time
local nc = naev.cache()
function naevpedia.load()
   local mds = {}
   local function find_md( dir )
      for k,v in ipairs(lf.getDirectoryItems('naevpedia/'..dir)) do
         local f = v
         if dir ~= "" then
            f = dir.."/"..f
         end
         local i = lf.getInfo( 'naevpedia/'..f )
         if i then
            if i.type == "file" then
               local suffix = utf8.sub(f, -3)
               if suffix=='.md' then
                  local dat = lf.read( 'naevpedia/'..f )
                  local entry = utf8.sub( f, 1, -4 )
                  local _s, meta = extractmetadata( entry, dat )
                  mds[ entry ] = meta
               end
            elseif i.type == "directory" then
               find_md( f )
            end
         end
      end
   end
   find_md( '' )
   nc._naevpedia = mds
end
-- See if we have to load the naevpedia, since we want to cache it for speed
if not nc._naevpedia then
   naevpedia.load()
end

--[[--
Processes the Lua in the markdown file as nanoc does.

<%= print('foo') %> statements get printed in the text, while <% if foo then %> get processed otherwise.
--]]
local function dolua( s )
   -- Do early stopping if no Lua is detected
   local ms, me = utf8.find( s, "<%", 1, true )
   if not ms then
      return true, s
   end

   -- Start up the Lua stuff
   local luastr = [[local out = ""
   local pr = _G.print
   local pro = function( str )
      out = out..str
   end
   ]]
   local function embed_str( str )
      for i=1,20 do
         local sep = ""
         for j=1,i do
            sep = sep.."="
         end
         if (not utf8.find(str,"["..sep.."[",1,true)) and (not utf8.find(str,"]"..sep.."]",1,true)) then
            luastr = luastr.."out = out..["..sep.."["..str.."]"..sep.."]\n"
            break
         end
      end
   end

   local be = 1
   while ms do
      local bs
      local display = false
      embed_str( utf8.sub( s, be+1, ms-1 ) )
      bs, be = utf8.find( s, "%>", me, true )
      if utf8.sub( s, me+1, me+1 )=="=" then
         me = me+1
         display = true
         luastr = luastr.."_G.print = pro\n"
      else
         luastr = luastr.."_G.print = pr\n"
      end
      local ss = utf8.sub( s, me+1, bs-1 )
      luastr = luastr..ss.."\n"
      if display then
         luastr = luastr.."out = out..'\\n'\n"
      end
      ms, me = utf8.find( s, "<%", me, true )
   end
   embed_str( utf8.sub( s, be+1 ) )
   luastr = luastr.."return out"
   local pr = _G.print
   local c,cerror = loadstring(luastr)
   if not c then
      warn( cerror )
      return false, "#r"..cerror.."#0"
   end
   setfenv( c, _G )
   local success,result_or_err = pcall( c )
   _G.print = pr
   if not success then
      warn( result_or_err )
      return "#r"..result_or_err.."#0"
   end
   return success, result_or_err
end

--[[--
Parse document
--]]
local function loaddoc( filename )
   local meta = {}

   -- Load the file
   local rawdat = lf.read( 'naevpedia/'..filename..'.md' )
   if not rawdat then
      warn(fmt.f(_("File '{filename}' not found!"),{filename=filename}))
      return false, fmt.f("#r".._("404\nfile '{filename}' not found"), {filename=filename}), meta
   end

   -- Extract metadata
   rawdat, meta = extractmetadata( filename, rawdat )

   -- Preprocess Lua
   local success, dat = dolua( rawdat )
   if not success then
      return success, dat, meta
   end

   -- Finally parse the remaining text as markdown
   return success, cmark.parse_string( dat, cmark.OPT_DEFAULT ), meta
end

--[[--
Sets up the naevpedia. Meant to be used through naevpedia.open or naevpedia,vn.
--]]
function naevpedia.setup( name )
   name = name or "index"

   local history = {}
   local historyrev = {}
   local current = "index"

   -- Set up the window
   local open_page
   local w, h = naev.gfx.dim()
   local wdw = luatk.newWindow( nil, nil, w, h )
   luatk.newText( wdw, 0, 10, w, 20, _("Naevpedia"), nil, "center" )
   luatk.newButton( wdw, -20, -20, 80, 30, _("Close"), luatk.close )

   local btnback, btnfwd
   local function goback ()
      local n = #history
      table.insert( historyrev, current )
      current = history[n]
      history[n] = nil
      open_page( current )
      if #history <= 0 then
         btnback:disable()
         btnfwd:enable()
      end
   end
   local function gofwd ()
      local n = #historyrev
      table.insert( history, current )
      current = historyrev[n]
      historyrev[n] = nil
      open_page( current )
      if #historyrev <= 0 then
         btnfwd:disable()
         btnback:enable()
      end
   end

   -- TODO make list filterable / searchable
   local lstnav, lstcategory
   local function update_list( meta )
      if not meta.entry then return end
      if lstcategory==meta.category then
         -- No need to recreate
         return
      end
      if lstnav then
         lstnav:destroy()
      end
      lstcategory = meta.category

      local lstelem = {}
      for k,v in pairs(nc._naevpedia) do
         if meta.category == v.category and (not v.condchunk or v.condchunk()) then
            table.insert( lstelem, v.entry )
         end
      end
      table.sort( lstelem, function ( a, b )
         local na = nc._naevpedia[a]
         local nb = nc._naevpedia[b]
         local pa = na.priority or 5
         local pb = nb.priority or 5
         if pa < pb then
            return true
         elseif pa > pb then
            return false
         end
         return a < b
      end )
      local titles = {}
      local defelem = 1 -- Defaults to highest priority element otherwise
      for k,v in ipairs(lstelem) do
         if v==meta.entry then
            defelem = k
         end
         local e = nc._naevpedia[v]
         local prefix = (e.parent and "↳ ") or ""
         titles[k] = prefix.._(e.title or e.name)
      end
      lstnav = luatk.newList( wdw, 40, 100, 300, h-200, titles, function ( _name, idx )
         open_page( lstelem[idx] )
      end, defelem )
      wdw:setFocus( lstnav )
   end

   -- Top bar
   local topbar = {"mechanics","ships","outfits","history"}
   local bw, bh = 100, 30
   local topbarw = #topbar*(20+bw)-20
   local xoff = 340 + (w-340-topbarw)*0.5
   for k,v in ipairs(topbar) do
      local bx = xoff+(20+bw)*(k-1)
      luatk.newButton( wdw, bx, 40, bw, bh, _(v), function ()
         local e = nc._naevpedia[v]
         if e then
            open_page( e.name )
         end
      end )
   end

   -- Backbutton
   btnfwd = luatk.newButton( wdw, -20-80-20, -20, 80, 30, _("Forward"), gofwd )
   if #historyrev <= 0 then
      btnfwd:disable()
   end
   btnback = luatk.newButton( wdw, -20-(80+20)*2, -20, 80, 30, _("Back"), goback )
   if #history <= 0 then
      btnback:disable()
   end
   local mrk
   function open_page( filename )
      if mrk then
         mrk:destroy()
      end

      -- Load the document
      local success, doc, meta = loaddoc( filename )

      -- Update the list first
      update_list( meta )

      -- Set markdown dimensions here
      local mx, my, mw, mh = 20+300+40+20, 80, w-(20+300+40+40), h-110-40

      -- Create widget
      if not success then
         -- Failed, so just display the error
         mrk = luatk.newText( wdw, mx, my, mw, mh, doc )
      else
         -- Success so we try to load the markdown
         mrk = md.newMarkdown( wdw, doc, mx, my, mw, mh, {
            linkfunc = function ( target )
               local newdoc = target
               if not newdoc then
                  -- do warning
                  luatk.msg( _("404"), fmt.f(_("Unable to find link to '{target}'!"),{target=target}))
                  return
               end
               table.insert( history, current )
               btnback:enable()
               current = target
               mrk:destroy()
               open_page( newdoc )
               -- Clear forward history
               historyrev = {}
               btnfwd:disable()
            end,
            linktargetfunc = function ( target )
               local lmeta = nc._naevpedia[target]
               if not lmeta or (lmeta.condchunk and not lmeta.condchunk())then
                  return nil
               end
               return _(lmeta.title or lmeta.name)
            end,
         } )

         -- Clean up the document
         cmark.node_free( doc )
      end
   end
   open_page( name )
   wdw:setCancel( function ()
      wdw:destroy()
      return true
   end )
   wdw:setKeypress( function ( key )
      if key=="left" then
         if #history > 0 then
            goback()
         end
      elseif key=="right" then
         if #historyrev > 0 then
            gofwd()
         end
      end
   end )
end

--[[--
For running the naevpedia from a Lua script.

   @luatparam name string Name of the file to open.
--]]
function naevpedia.open( name )
   naevpedia.setup( name )
   luatk.run()
end

--[[--
For running the naevpedia from the VN.

   @luatparam name string Name of the file to open.
   @luatreturn State The newly created VN state.
--]]
function naevpedia.vn( name )
   return luatk.vn( function ()
      naevpedia.setup( name )
   end )
end

return naevpedia