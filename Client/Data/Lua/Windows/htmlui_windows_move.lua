-- HTML skin for the SFDataNpcTalk move window.
-- SFData remains the data source, Lua is the controller, Sciter is only the skin.
if createwinhtml and sfui and sfui.html and imports then
	local window_id = "#windows_move"
	imports("package.systems.npctalk")
	local move_data = npctalk

	local function sync_move(reason)
		if not move_data then
			return false
		end

		sfui.html.send(window_id, {
			target = "#move-root",
			action = "setData",
			payload = {
				reason = reason or "sync",
				context = move_data.get_context(),
				rows = move_data.get_rows(),
				selected = move_data.get_selected(),
				selected_index = move_data.get_selected_index(),
				selected_id = move_data.get_selected_id(),
				count = move_data.get_count()
			}
		})
		return true
	end

	sfui.on("NpcMove.Ready", function()
		sync_move("ready")
	end)

	sfui.on("NpcMove.Refresh", function()
		sync_move("refresh")
	end)

	sfui.on("NpcMove.Select", function(payload)
		local row = 0
		if type(payload) == "table" then
			row = tonumber(payload.row or payload.index or 0) or 0
		end

		if move_data then
			move_data.select_by_row(row)
		end
		sync_move("select")
	end)

	sfui.on("NpcMove.Confirm", function(payload)
		if move_data then
			if type(payload) == "table" and payload.id ~= nil then
				move_data.request_action(tonumber(payload.id) or -1)
			else
				move_data.request_selected()
			end
		end
	end)

	local win = createwinhtml("npcmove", {
		id = window_id,
		title = "Move",
		x = 150,
		y = 80,
		width = 300,
		height = 250,
		data = {
			source = "npctalk",
			target = "#move-root"
		},
		events = {
			["#move-list:click"] = "NpcMove.Select",
			["#btn-move:click"] = "NpcMove.Confirm",
			["#btn-refresh:click"] = "NpcMove.Refresh",
			["#btn-close:click"] = "NpcMove.Close"
		},
		closable = true,
		movable = false,
		close_on_move = true,
		show_background = false,
		show_border = false,
		show_header = false,
		show_title = false,
	})

	if win then
		win:load_events({
			events = {
				["#move-list:click"] = "NpcMove.Select",
				["#btn-move:click"] = "NpcMove.Confirm",
				["#btn-refresh:click"] = "NpcMove.Refresh",
				["#btn-close:click"] = "NpcMove.Close"
			}
		})

		sfui.on("NpcMove.Close", function()
			win:close()
		end)
	end
end
