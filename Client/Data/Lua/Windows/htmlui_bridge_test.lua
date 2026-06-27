-- Generic HTML bridge test.
-- Sciter is only the visual skin; Lua owns the behavior and data.
if createwinhtml and sfui and sfui.html then
	local window_id = "html_bridge_test"

	local function build_rows()
		return {
			{ rank = 1, name = "LuisADM", class = "Blade Master", score = 98812 },
			{ rank = 2, name = "Atenea", class = "Soul Master", score = 91244 },
			{ rank = 3, name = "Sephiroth", class = "Duel Master", score = 88703 },
			{ rank = 4, name = "Nightfall", class = "Magic Gladiator", score = 84391 },
			{ rank = 5, name = "Valquiria", class = "Muse Elf", score = 80650 },
			{ rank = 6, name = "Ragnar", class = "Dark Lord", score = 79108 },
			{ rank = 7, name = "Kira", class = "Dimension Master", score = 72410 },
			{ rank = 8, name = "Orion", class = "Blade Knight", score = 68735 },
		}
	end

	local function send_preview_data(reason)
		sfui.html.send(window_id, {
			target = "#bridge-body",
			action = "setData",
			payload = {
				title = "Generic HTML Bridge",
				reason = reason or "manual",
				rows = build_rows()
			}
		})
	end

	sfui.on("HtmlBridge.Ready", function()
		send_preview_data("ready")
	end)

	sfui.on("HtmlBridge.Refresh", function()
		send_preview_data("refresh")
		sfui.html.send(window_id, {
			target = "#status",
			action = "setText",
			payload = { text = "Lua refreshed mock data" }
		})
	end)

	sfui.on("HtmlBridge.Select", function(payload_json)
		sfui.html.send(window_id, {
			target = "#status",
			action = "setText",
			payload = { text = "Lua received HTML event: " .. tostring(payload_json) }
		})
	end)

	local win = createwinhtml("bridge_test", {
		id = window_id,
		title = "HTML Bridge",
		x = 180,
		y = 90,
		width = 620,
		height = 420,
		key = "F10",
		html = "bridge_test",
		data = {
			provider = "mock",
			target = "#bridge-body"
		},
		events = {
			["#btn-refresh:click"] = "HtmlBridge.Refresh",
			["#bridge-body:click"] = "HtmlBridge.Select"
		},
		closable = true,
		movable = true,
		show_background = false,
		show_border = false,
		show_header = false,
		show_title = false,
	})

	if win then
		win:load_events({
			events = {
				["#btn-refresh:click"] = "HtmlBridge.Refresh",
				["#bridge-body:click"] = "HtmlBridge.Select"
			}
		})
	end
end
