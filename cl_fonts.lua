nzcwhud = nzcwhud or {}

nzcwhud.fonts = {}

function nzcwhud.cFont(scale)
    surface.CreateFont("CWHUD_XS", {
        font = "Open Sans",
        extended = true,
        size = 15 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_S", {
        font = "Open Sans",
        extended = true,
        size = 20 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_M", {
        font = "Open Sans",
        extended = true,
        size = 25 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_L_THIN", {
        font = "Open Sans",
        extended = true,
        size = 30 / scale,
        weight = 600
    })

    surface.CreateFont("CWHUD_L_THINEST", {
        font = "Open Sans",
        extended = true,
        size = 30 / scale,
        weight = 0
    })

    surface.CreateFont("CWHUD_L", {
        font = "Open Sans",
        extended = true,
        size = 30 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_XL", {
        font = "Open Sans",
        extended = true,
        size = 35 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_XXL", {
        font = "Open Sans",
        extended = true,
        size = 40 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_XXXL", {
        font = "Open Sans",
        extended = true,
        size = 50 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_XXXXL", {
        font = "Open Sans",
        extended = true,
        size = 60 / scale,
        weight = 1000
    })

    surface.CreateFont("CWHUD_XXXXXL", {
        font = "Open Sans ExtraBold",
        extended = true,
        size = 90 / scale
    })
end
