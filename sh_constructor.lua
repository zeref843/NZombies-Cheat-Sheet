
nzEnemies = nzEnemies or AddNZModule("Enemies")
nzEnemies.Updated = true //im gonna run out of 'module.updated' bools if i keep this shit up


nzEnemies.EyeGlowStyles = nzEnemies.EyeGlowStyles or {}

function nzEnemies:NewEyeGlowStyle(id, data)
	nzEnemies.EyeGlowStyles[id] = data
end

function nzEnemies:GetEyeGlowStyle(id)
	return nzEnemies.EyeGlowStyles[id]
end

function nzEnemies:GetEyeGlowStyleList()
	local tbl = {}

	for k, v in pairs(nzEnemies.EyeGlowStyles) do
		tbl[k] = v.name
	end

	return tbl
end

nzEnemies:NewEyeGlowStyle("eyeglow_style_bo1", {
	name = "Basic",
	fx = "zmb_eyeglow_bo1",
})

nzEnemies:NewEyeGlowStyle("eyeglow_style_bo2", {
	name = "High Beams",
	fx = "zmb_eyeglow_bo2",
})

nzEnemies:NewEyeGlowStyle("eyeglow_style_flare", {
	name = "Flare",
	fx = "zmb_eyeglow_lensflare",
})

nzEnemies:NewEyeGlowStyle("eyeglow_style_trail", {
	name = "Trail",
	fx = "zmb_eyeglow_bo1_trail",
})
