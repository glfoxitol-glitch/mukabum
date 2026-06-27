-- HTML skin for the ranking window.
-- Lua owns the binding; Sciter only renders the visual shell.
if createwinhtml and sfui and sfui.html and imports then
	local window_id = "html_ranking"
	imports("package.systems.rankings")
	local ranking_data = rankings

	local function sync_ranking(reason)
		if not ranking_data then
			return false
		end

		sfui.html.send(window_id, {
			target = "#ranking-root",
			action = "setData",
			payload = {
				reason = reason or "sync",
				title = ranking_data.get_title(),
				summary = ranking_data.get_summary(),
				score_column = ranking_data.get_score_name(),
				rows = ranking_data.get_rows(),
				table = ranking_data.get_table(),
				preview = ranking_data.get_preview(),
				current_tab = ranking_data.get_current_tab(),
				max_tabs = ranking_data.get_max_tabs(),
				count = ranking_data.get_count()
			}
		})
		return true
	end

	sfui.on("Ranking.Ready", function()
		if ranking_data then
			ranking_data.request_refresh()
		end
		sync_ranking("ready")
	end)

	sfui.on("Ranking.Sync", function()
		sync_ranking("sync")
	end)

	sfui.on("Ranking.Refresh", function()
		if ranking_data then
			ranking_data.request_refresh()
		end
		sync_ranking("refresh")
	end)

	sfui.on("Ranking.Tab", function(payload)
		local tab = 0
		if type(payload) == "table" then
			tab = tonumber(payload.tab or payload.index or 0) or 0
		end

		if ranking_data then
			ranking_data.request_tab(tab)
		end
		sync_ranking("tab")
	end)

	sfui.on("Ranking.Select", function(payload)
		if not ranking_data or type(payload) ~= "table" then
			return
		end

		local row = tonumber(payload.row or payload.index or -1) or -1
		if row >= 0 then
			ranking_data.request_character(row)
		end
		sync_ranking("select")
	end)

	local win = createwinhtml("ranking", {
		id = window_id,
		title = "Ranking",
		x = 50,
		y = 50,
		width = 500,
		height = 320,
		key = "F8",
		data = {
			source = "rankings",
			target = "#ranking-root"
		},
		render_slots = {
			preview = {
				type = "character",
				bind = "rankings.preview",
				x = 318,
				y = 96,
				width = 112,
				height = 150,
				interactive = true,
				copy_hero_on_invalid = true,
				angle = 90,
				zoom = 0.78
			}
		},
		events = {
			["#ranking-tabs:click"] = "Ranking.Tab",
			["#ranking-table:click"] = "Ranking.Select",
			["#btn-refresh:click"] = "Ranking.Refresh"
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
				["#ranking-tabs:click"] = "Ranking.Tab",
				["#ranking-table:click"] = "Ranking.Select",
				["#btn-refresh:click"] = "Ranking.Refresh"
			}
		})
	end
end
