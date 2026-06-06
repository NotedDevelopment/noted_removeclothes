Config = {}

-- When TRUE, the player must request permission to remove EVERY clothing slot,
-- including the normally-free ones below.
-- When FALSE (default), the free slots can be removed without asking; all other
-- slots still require a granted permission request.
Config.AlwaysAsk = false

-- Slots that can be removed WITHOUT permission (unless Config.AlwaysAsk is true).
Config.FreeSlots = {
    hat     = true,
    glasses = true,
    mask    = true,
    neck    = true,
    gloves  = true,
}

-- Item given to the player who successfully steals shoes.
Config.ShoeItem = 'shoes'

-- Max interaction distance (meters).
Config.MaxDistance = 2.0

-- Duration of the steal-shoes progressbar (ms).
Config.StealShoesDuration = 5000

-- Duration of each clothing removal progressbar (ms).
Config.RemoveClothingDuration = 3000

-- How long a granted permission lasts before the player must ask again (ms).
Config.ApprovalDuration = 5 * 60 * 1000  -- 5 minutes

-- ─── menu distance watcher ──────────────────────────────────────────────────
-- How often (ms) to re-check that the target hasn't walked away while the
-- undress menu is open.
Config.MenuDistanceCheckInterval = 1000
-- If the target gets further than this (meters) during that check, the menu closes.
Config.MenuMaxDistance = 5.0

-- ─── removal animations ─────────────────────────────────────────────────────
-- How much LOWER (meters, head-to-head) the target must be than you for them
-- to count as "on the ground", which makes you kneel while undressing them.
Config.KneelHeightDiff = 0.45

Config.Anims = {
    -- Played when the target is low / on the ground (you kneel + fidget).
    kneel    = { dict = 'mini@repair',  anim = 'fixing_a_player', flag = 1 },
    -- Played when the target is upright (standing fiddle, like an uncuff).
    standing = { dict = 'mp_arresting', anim = 'a_uncuff',        flag = 1 },
}

-- Animations that mark a player as incapacitated / vulnerable. These are the
-- exact clips qbx plays, so the client-side pre-check matches their actual
-- state. Pulled from qbx_medical (death, last stand) and qbx_police
-- (handcuffed, surrender / hands up).
Config.VulnerableAnims = {
    -- death — qbx_medical/client/dead.lua
    { dict = 'dead',                 anim = 'dead_a'      },  -- dead
    { dict = 'dead',                 anim = 'dead_f'      },  -- dead / downed while cuffed
    -- last stand — qbx_medical/client/main.lua
    { dict = 'combat@damage@writhe', anim = 'writhe_loop' },
    -- handcuffed — qbx_police/client/interactions.lua
    { dict = 'mp_arresting',         anim = 'idle'                  },
    -- surrender / hands up
    { dict = 'missminuteman_1ig_2',  anim = 'handsup_base'          },
    { dict = 'missminuteman_1ig_2',  anim = 'handsup_enter'         },
    { dict = 'random@mugging3',      anim = 'handsup_standing_base' },
}

-- Default "naked" component drawables for male MP peds.
-- Adjust if your server uses a custom base ped.
Config.NakedMale = {
    [1]  = { drawable = 0,  texture = 0 },  -- mask
    [2]  = { drawable = 0,  texture = 0 },  -- hair accessory
    [3]  = { drawable = 15, texture = 0 },  -- arms / gloves
    [4]  = { drawable = 61, texture = 0 },  -- pants / legs
    [5]  = { drawable = 0,  texture = 0 },  -- bag / parachute
    [6]  = { drawable = 34, texture = 0 },  -- shoes / feet
    [7]  = { drawable = 0,  texture = 0 },  -- neck accessory
    [8]  = { drawable = 15, texture = 0 },  -- undershirt
    [9]  = { drawable = 0,  texture = 0 },  -- body armor
    [10] = { drawable = 0,  texture = 0 },  -- decals
    [11] = { drawable = 15, texture = 0 },  -- top / jacket
}

-- Default "naked" component drawables for female MP peds.
Config.NakedFemale = {
    [1]  = { drawable = 0,  texture = 0 },
    [2]  = { drawable = 0,  texture = 0 },
    [3]  = { drawable = 15, texture = 0 },
    [4]  = { drawable = 34, texture = 0 },
    [5]  = { drawable = 0,  texture = 0 },
    [6]  = { drawable = 35, texture = 0 },
    [7]  = { drawable = 0,  texture = 0 },
    [8]  = { drawable = 2,  texture = 0 },
    [9]  = { drawable = 0,  texture = 0 },
    [10] = { drawable = 0,  texture = 0 },
    [11] = { drawable = 15, texture = 0 },
}
