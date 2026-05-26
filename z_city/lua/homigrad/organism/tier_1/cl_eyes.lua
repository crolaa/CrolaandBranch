local gradientL = Material("vgui/gradient-l")
local gradientR = Material("vgui/gradient-r")
local blindMat = Material("effects/shaders/zb_blind")

local function drawShaderEye(mode)
	render.UpdateScreenEffectTexture()
	render.UpdateFullScreenDepthTexture()
	blindMat:SetFloat("$c0_x", 5)
	blindMat:SetFloat("$c0_y", CurTime())
	blindMat:SetFloat("$c0_z", mode)
	render.SetMaterial(blindMat)
	render.DrawScreenQuad()
end

-- zb_blind does not stack two passes; bilateral loss uses screen-space panels instead.
local function drawScreenEyeBlind(blindL, blindR, intensity)
	local w, h = ScrW(), ScrH()
	local cover = w * 0.44
	local feather = w * 0.08
	local alpha = math.Clamp(math.Round(intensity * 255), 200, 252)

	cam.Start2D()

	if blindL then
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(0, 0, cover, h)

		surface.SetMaterial(gradientR)
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawTexturedRect(cover, 0, feather, h)
	end

	if blindR then
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawRect(w - cover, 0, cover, h)

		surface.SetMaterial(gradientL)
		surface.SetDrawColor(0, 0, 0, alpha)
		surface.DrawTexturedRect(w - cover - feather, 0, feather, h)
	end

	cam.End2D()
end

function hg.organism.DrawEyeBlindOverlay(org)
	if not org then return end

	local blindL, blindR = hg.organism.GetEyeBlindModes(org)

	if not blindL and not blindR then return end

	local intensity = math.Clamp(math.max(org.eyeL or 0, org.eyeR or 0, 0.55), 0.55, 1)

	if blindL and blindR then
		cam.Start2D()
		surface.SetDrawColor(0, 0, 0, math.Clamp(math.Round(intensity * 255), 200, 252))
		surface.DrawRect(0, 0, ScrW(), ScrH())
		cam.End2D()
return
	end

	if blindL then
		drawShaderEye(2)
	elseif blindR then
		drawShaderEye(1)
	end
end

function hg.organism.DrawFlashEyeBlind()
	render.UpdateScreenEffectTexture()
	render.UpdateFullScreenDepthTexture()
	drawScreenEyeBlind(true, true, 1)
end

concommand.Add("hg_organism_eye_debug", function()
	local ply = LocalPlayer()
	local org = hg.organism.GetClientOrganism(ply)
	if not org then
		print("[ZCity eyes] no organism")
		return
	end

	local blindL, blindR = hg.organism.GetEyeBlindModes(org)
	print(string.format(
		"[ZCity eyes] eyeL=%.3f eyeR=%.3f blindness=%s | blindL=%s blindR=%s | shaderModes=%s",
		org.eyeL or 0,
		org.eyeR or 0,
		tostring(org.blindness),
		tostring(blindL),
		tostring(blindR),
		table.concat(hg.organism.GetEyeBlindShaderModes(org), ",")
	))
end)
