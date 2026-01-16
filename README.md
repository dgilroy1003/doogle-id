# doogle-id

Simple Doogle-compatible ID card resource for RedM (renamed from `rsg-id`).

Features:
- NUI form to input name, DOB, job and a photo URL
- Canvas composition with an official background (replace html/assets/bg.svg with your art)
- Generates base64 PNG and attempts to add an item (`Config.ItemName`) to player's inventory via `ox_inventory` or common fallbacks

Usage:
- Start the resource and run `/makeid` in-game to open the creator UI.
- If you use a different inventory system, adapt `tryAddToInventory` in `server.lua` to call your API.

Upload integrations and config: edit `html/upload-config.json` and see README in the original resource for examples (Imgur, ImgBB, transfer.sh, self-hosted proxy).
