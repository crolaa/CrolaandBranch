hg.organism.module.eyes = hg.organism.module.eyes or {}
local module = hg.organism.module.eyes

local EYE_BLIND_THRESH = hg.organism.EYE_BLIND_THRESH
local EYE_PARTIAL_THRESH = hg.organism.EYE_PARTIAL_THRESH

-- Networked summary; client screen FX uses eyeL/eyeR and draws one overlay per blind eye.
function hg.organism.UpdateBlindness(org)
	local eyeL = org.eyeL or 0
	local eyeR = org.eyeR or 0
	local blindL, blindR = hg.organism.GetEyeBlindModes(org)

	if blindL and blindR then
		org.blindness = 3
	elseif blindL then
		org.blindness = 2
	elseif blindR then
		org.blindness = 1
	elseif eyeL >= EYE_PARTIAL_THRESH or eyeR >= EYE_PARTIAL_THRESH then
		org.blindness = math.max(eyeL, eyeR)
	else
		org.blindness = nil
	end
end

module[1] = function(org)
	org.eyeL = 0
	org.eyeR = 0
	org.blindness = nil
end

module[2] = function(owner, org, timeValue)
	hg.organism.UpdateBlindness(org)

	if not org.isPly or org.otrub then return end

	local eyeL = org.eyeL or 0
	local eyeR = org.eyeR or 0
	if eyeL < EYE_PARTIAL_THRESH and eyeR < EYE_PARTIAL_THRESH then return end

	org.disorientation = math.max(org.disorientation, (eyeL + eyeR) * 4)
end

if SERVER then
	-- Usage (admin, console or chat with sv_cheats):
	--   hg_organism_injure_eye          -- both eyes to blind threshold
	--   hg_organism_injure_eye l        -- left eye only
	--   hg_organism_injure_eye r 0.3    -- right eye, partial damage
	--   hg_organism_injure_eye both 1   -- both eyes destroyed
	local function injureEye(ply, side, amt)
		if not IsValid(ply) or not ply.organism then return end

		local org = ply.organism
		side = string.lower(side or "both")
		amt = math.Clamp(tonumber(amt) or EYE_BLIND_THRESH, 0, 1)

		if side == "l" or side == "left" or side == "both" then
			org.eyeL = amt
		end
		if side == "r" or side == "right" or side == "both" then
			org.eyeR = amt
		end

		org.painadd = (org.painadd or 0) + amt * 30
		org.disorientation = (org.disorientation or 0) + amt * 6

		hg.organism.UpdateBlindness(org)

		ply.organism = org
		ply.fullsend = true
		hg.send_organism(org, ply)

		ply:ChatPrint(string.format(
			"[ZCity] Eye test: %s = %.2f | eyeL=%.2f eyeR=%.2f blindness=%s",
			side, amt, org.eyeL or 0, org.eyeR or 0, tostring(org.blindness)
		))
	end

	concommand.Add("hg_organism_injure_eye", function(ply, cmd, args)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		if not ply:IsAdmin() then return end

		injureEye(ply, args[1], args[2])
	end)
end
