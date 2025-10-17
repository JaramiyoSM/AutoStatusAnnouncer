local A="AutoStatusAnnouncer"
local F=CreateFrame("Frame")
ASA_DB=ASA_DB or {}

-- CONFIG (edit these)
local SILENT=false      -- true: only you see; false: send to chat
local ONLYGRP=true     -- only when in party/raid
local CH="PARTY"        -- AUTO|PARTY|RAID|SAY (used if SILENT=false)
local BURST=3          -- repeats for 10%/5% (1..5)
local DMG=true         -- damage notifications on
local DMGINT=5         -- seconds between damage msgs
local HP50,HP20,HP10,HP5=50,20,10,5
local MP50,MP20,MP10,MP5=50,20,10,5

-- INTERNALS
local st={hp="normal",mp="normal",lastD=0,dead=false}
local function nParty() if GetNumPartyMembers then return GetNumPartyMembers() or 0 else return 0 end end
local function nRaid() if GetNumRaidMembers then return GetNumRaidMembers() or 0 else return 0 end end
local function inGrp() return (nParty()>0) or (nRaid()>0) end
local function chan() if CH=="PARTY" then return "PARTY" end; if CH=="RAID" then return "RAID" end; if CH=="SAY" then return "SAY" end; if nRaid()>0 then return "RAID" end; if nParty()>0 then return "PARTY" end; return "SAY" end
local function pct(c,m) if not c or not m or m==0 then return 0 end return math.floor((c/m)*100+0.5) end
local function hp() return pct(UnitHealth("player"),UnitHealthMax("player")) end
local function mp() local t=UnitPowerType("player") or 0; if t~=0 then return nil end; return pct(UnitMana("player"),UnitManaMax("player")) end
local function out(s) if ONLYGRP and not inGrp() then return end; if SILENT then DEFAULT_CHAT_FRAME:AddMessage("[ASA] "..s) else SendChatMessage(s,chan()) end end
local function burst(s) local n=BURST or 3; if n<1 then n=1 end; if n>5 then n=5 end; local i=1; while i<=n do out(s); i=i+1 end end
local ord={normal=5,["50"]=4,["20"]=3,["10"]=2,["5"]=1}
local function down(p,z) local a=ord[p] or 5; local b=ord[z] or 5; return b<a end
local function zHP(v) if v<=HP5 then return "5" elseif v<=HP10 then return "10" elseif v<=HP20 then return "20" elseif v<=HP50 then return "50" else return "normal" end end
local function zMP(v) if v<=MP5 then return "5" elseif v<=MP10 then return "10" elseif v<=MP20 then return "20" elseif v<=MP50 then return "50" else return "normal" end end
local function aHP(v,z) if z=="50" then out(string.format("HP at %d%% - be careful.",v)) elseif z=="20" then out(string.format("HP at %d%% - danger zone.",v)) elseif z=="10" then burst(string.format("HP at %d%% - critical! Healer help!",v)) elseif z=="5" then burst(string.format("HP at %d%% - about to die!",v)) end end
local function aMP(v,z) if z=="50" then out(string.format("Mana at %d%% - steady usage.",v)) elseif z=="20" then out(string.format("Mana at %d%% - running low.",v)) elseif z=="10" then burst(string.format("Mana at %d%% - need to recharge soon!",v)) elseif z=="5" then burst(string.format("Mana at %d%% - OOM incoming, need to drink now!",v)) end end
local function mayHP() local v=hp(); local z=zHP(v); if down(st.hp,z) then aHP(v,z) end; st.hp=z end
local function mayMP() local v=mp(); if not v then return end; local z=zMP(v); if down(st.mp,z) then aMP(v,z) end; st.mp=z end
local function onDmg(u,a,_,amt) if not DMG then return end; if u~="player" then return end; if a~="WOUND" then return end; local now=GetTime(); if (now-(st.lastD or 0))<(DMGINT or 5) then return end; out(string.format("Taking damage (%d). HP: %d%%.",amt or 0,hp())); st.lastD=now end
local function onDead() if st.dead then return end; st.dead=true; out("I'm dead!") end
local function onAlive() st.dead=false end

F:SetScript("OnEvent", function()
  if event=="ADDON_LOADED" then local n=arg1; if n~=A then return end; DEFAULT_CHAT_FRAME:AddMessage("[ASA] Core Lite loaded.")
  elseif event=="PLAYER_ENTERING_WORLD" then st.dead=UnitIsDeadOrGhost("player") or false; mayHP(); mayMP()
  elseif event=="UNIT_HEALTH" then if arg1=="player" then mayHP() end
  elseif event=="UNIT_MANA"   then if arg1=="player" then mayMP() end
  elseif event=="UNIT_COMBAT" then onDmg(arg1,arg2,arg3,arg4)
  elseif event=="PLAYER_DEAD" then onDead()
  elseif event=="PLAYER_ALIVE" or event=="PLAYER_UNGHOST" then onAlive()
  end
end)
F:RegisterEvent("ADDON_LOADED")
F:RegisterEvent("PLAYER_ENTERING_WORLD")
F:RegisterEvent("UNIT_HEALTH")
F:RegisterEvent("UNIT_MANA")
F:RegisterEvent("UNIT_COMBAT")
F:RegisterEvent("PLAYER_DEAD")
F:RegisterEvent("PLAYER_ALIVE")
F:RegisterEvent("PLAYER_UNGHOST")
