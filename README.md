# noted_removeclothes

A FiveM resource for **QBX Core** that lets players remove clothing from vulnerable targets (dead, downed, handcuffed, or surrendering). Includes a permission system for consensual stripping and a dedicated shoe-stealing mechanic with a skill-check defense.

## Features

- **Undress menu** — orbit camera lets you inspect and remove individual clothing slots (hat, glasses, mask, top, pants, shoes, etc.)
- **Vulnerability check** — free slots (hat, glasses, mask, neck, gloves) can be removed without asking when the target is downed/cuffed; all other slots require a permission request
- **Permission system** — initiator sends a request; the target gets a UI prompt and must accept within 12 seconds; approval is cached for a configurable window so they don't have to re-confirm every slot
- **Shoe stealing** — dedicated action that triggers a skill-check on the target; they auto-fail if incapacitated, succeed or fail based on the mini-game otherwise
- **Contextual animations** — kneels over prone targets, uses a standing fiddle animation for upright ones
- **Distance enforcement** — menu closes if target walks too far; all server events do a secondary distance check

## Dependencies

| Resource | Purpose |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | Progress bars, skill checks, notifications |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Player data (death / last-stand / cuff state) |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Gives the shoe item on a successful steal |
| [ox_target](https://github.com/overextended/ox_target) | "Undress Player" and "Steal Shoes" interactions |

## Installation

1. Drop the `noted_removeclothes` folder into your server's `resources` directory.
2. Add `ensure noted_removeclothes` to your `server.cfg`.
3. Add the shoe item to your `ox_inventory` items file (default name: `shoes`).

## Configuration

All options live in [config.lua](config.lua).

| Option | Default | Description |
|---|---|---|
| `Config.AlwaysAsk` | `false` | When `true`, every slot requires a permission request, even the normally-free ones |
| `Config.FreeSlots` | hat, glasses, mask, neck, gloves | Slots removable without asking on a vulnerable target |
| `Config.ShoeItem` | `'shoes'` | Inventory item name given when shoes are stolen |
| `Config.MaxDistance` | `2.0` m | Maximum range for all interactions |
| `Config.StealShoesDuration` | `5000` ms | Progress bar length for the shoe-steal action |
| `Config.RemoveClothingDuration` | `3000` ms | Progress bar length per clothing removal |
| `Config.ApprovalDuration` | `300000` ms (5 min) | How long a granted permission lasts before expiring |
| `Config.MenuDistanceCheckInterval` | `1000` ms | How often to check that the target hasn't walked away |
| `Config.MenuMaxDistance` | `5.0` m | Distance at which the open menu force-closes |
| `Config.KneelHeightDiff` | `0.45` m | Head-height difference that triggers the kneel animation |
| `Config.NakedMale` / `Config.NakedFemale` | GTA defaults | Component drawables used when a slot is "removed" |

## How It Works

### Undress flow

1. Aim at another player and select **Undress Player** via ox_target.
2. The orbit camera opens — right-drag to rotate, scroll to zoom.
3. Clothing slots are displayed as world-space labels over the ped.
4. **Free slots** (when target is vulnerable) can be removed immediately.
5. **Locked slots** require clicking **Request Permission**; the target sees a prompt and has 12 s to accept or deny.
6. Once approved, every subsequent removal in that session skips the prompt until the approval expires.

### Shoe stealing

1. Select **Steal Shoes** via ox_target.
2. A 5-second progress bar plays ("Untying their laces…").
3. If the target is downed/dead, shoes are taken automatically.
4. Otherwise the target receives a warning and must pass a skill check to keep them.

## Clothing Slots Reference

| ID | Label | Type |
|---|---|---|
| `hat` | Hat | prop |
| `glasses` | Glasses | prop |
| `earpiece` | Earpiece | prop |
| `watch` | Watch | prop |
| `bracelet` | Bracelet | prop |
| `mask` | Mask | component |
| `hair` | Hair | component |
| `top` | Top | component |
| `undershirt` | Undershirt | component |
| `armor` | Body Armor | component |
| `neck` | Neck Accessory | component |
| `bag` | Bag | component |
| `gloves` | Gloves | component |
| `decals` | Decals | component |
| `pants` | Pants | component |
| `shoes` | Shoes | component |
