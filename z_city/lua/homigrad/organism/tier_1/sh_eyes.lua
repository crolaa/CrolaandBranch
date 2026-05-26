hg.organism = hg.organism or {}

hg.organism.EYE_BLIND_THRESH = 0.55
hg.organism.EYE_PARTIAL_THRESH = 0.2

-- Client nets into ply.organism + ply.new_organism; effects must read the merged view.
function hg.organism.GetClientOrganism(ply)
	if not IsValid(ply) then return nil end

	local base = ply.organism
	local latest = ply.new_organism

	if base and latest then
		local org = table.Copy(base)
		table.Merge(org, latest, true)
		return org
	end

	return latest or base
end

-- Shader / flash modes: 1 = right eye, 2 = left eye
function hg.organism.GetEyeBlindModes(org)
	if not org then return false, false end

	local blindL = (org.eyeL or 0) >= hg.organism.EYE_BLIND_THRESH
	local blindR = (org.eyeR or 0) >= hg.organism.EYE_BLIND_THRESH

	if not blindL and not blindR and org.blindness then
		local rounded = math.Round(org.blindness)
		if rounded == 3 then
			return true, true
		elseif rounded == 2 then
			return true, false
		elseif rounded == 1 then
			return false, true
		end
	end

	return blindL, blindR
end

function hg.organism.GetEyeBlindShaderModes(org)
	local blindL, blindR = hg.organism.GetEyeBlindModes(org)
	local modes = {}

	if blindL then
		modes[#modes + 1] = 2
	end

	if blindR then
		modes[#modes + 1] = 1
	end

	return modes
end
