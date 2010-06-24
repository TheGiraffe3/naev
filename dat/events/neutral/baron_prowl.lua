--[[
-- Prowl Event for the Crazy Baron mission string. Only used when NOT doing any Baron missions.
--]]

-- localization stuff, translators would work here
lang = naev.lang()
if lang == "es" then
else -- default english
end

function create ()
    -- TODO: Change this to the Krieger once the Baron has it. Needs "King" mission first.
    shipname = "pinnacle"
    baronship = pilot.add("Proteron Kahan", "trader", planet.get("Ulios"):pos() + vec2.new(-400,-400))[1]
    baronship:setFaction("Civilian")
    baronship:rename(shipname)
    baronship:setInvincible(true)
    baronship:control()
    baronship:goto(planet.get("Ulios"):pos() + vec2.new( 400, -400), false)
    hook.pilot(baronship, "idle", "idle")
end

function idle()
    baronship:goto(planet.get("Ulios"):pos() + vec2.new( 400,  400), false)
    baronship:goto(planet.get("Ulios"):pos() + vec2.new(-400,  400), false)
    baronship:goto(planet.get("Ulios"):pos() + vec2.new(-400, -400), false)
    baronship:goto(planet.get("Ulios"):pos() + vec2.new( 400, -400), false)
end