local ui = SFUI.ui
local bind = SFUI.bind
local actions = SFUI.actions
local events = ui.import("events")

local SELECTED_INDEX = "eventos.selected_index"
local SELECTED_VALUE = "eventos.selected_value"
local FILTER_TYPE = "eventos.filter_type"
local ONLY_AVAILABLE = "eventos.only_available"

local colors = {
	window_bg = ui.color(8, 9, 11, 224),
	panel = ui.color(10, 11, 13, 205),
	panel_deep = ui.color(0, 0, 0, 130),
	panel_soft = ui.color(28, 22, 17, 160),
	line = ui.color(99, 70, 38, 185),
	line_hot = ui.color(240, 119, 21, 235),
	title = ui.color(255, 202, 104, 255),
	gold = ui.color(255, 188, 58, 255),
	text = ui.color(236, 232, 222, 255),
	muted = ui.color(166, 158, 148, 255),
	online = ui.color(112, 255, 151, 255),
	waiting = ui.color(255, 204, 71, 255),
	offline = ui.color(255, 124, 124, 255),
	blue = ui.color(124, 198, 255, 255)
}

local function to_bool(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

local function get_filter_type()
	return tonumber(bind.get(FILTER_TYPE)) or 0
end

local function get_only_available()
	return to_bool(bind.get(ONLY_AVAILABLE))
end

local function get_raw_rows()
	local rows = events.get_rows()
	if type(rows) ~= "table" then
		return {}
	end

	return rows
end

local function get_status(row)
	if not row then
		return "SIN DATOS"
	end

	if row.time_remaining == 0 then
		return "ONLINE"
	end

	if row.time_remaining < 0 then
		return "OFFLINE"
	end

	return "PROGRAMADO"
end

local function get_status_color(row)
	local status = get_status(row)
	if status == "ONLINE" then
		return colors.online
	end
	if status == "OFFLINE" then
		return colors.offline
	end
	return colors.waiting
end

local function get_type_text(row)
	if not row then
		return "--"
	end

	if tonumber(row.type) == 0 then
		return "Global"
	end

	return "Personaje"
end

local function get_time_text(row)
	if not row or not row.time or row.time == "" then
		return "--:--:--"
	end

	return row.time
end

local function get_badge_text(row)
	local status = get_status(row)
	if status == "ONLINE" or status == "OFFLINE" then
		return status
	end

	return get_time_text(row)
end

local function get_event_icon_color(row)
	local name = string.lower(row and row.name or "")
	if string.find(name, "blood", 1, true) then
		return ui.color(255, 62, 48, 255)
	end
	if string.find(name, "devil", 1, true) then
		return ui.color(55, 235, 96, 255)
	end
	if string.find(name, "chaos", 1, true) then
		return ui.color(186, 72, 255, 255)
	end
	if string.find(name, "temple", 1, true) then
		return ui.color(46, 145, 255, 255)
	end
	if string.find(name, "lottery", 1, true) or string.find(name, "drop", 1, true) then
		return ui.color(255, 166, 38, 255)
	end
	if string.find(name, "quiz", 1, true) then
		return ui.color(255, 210, 74, 255)
	end

	return ui.color(255, 196, 82, 255)
end

local function accepts_filter(row)
	local filter_type = get_filter_type()
	if filter_type == 1 and tonumber(row.type) ~= 0 then
		return false
	end

	if filter_type == 2 and tonumber(row.type) == 0 then
		return false
	end

	if get_only_available() and row.time_remaining ~= 0 then
		return false
	end

	return true
end

local function get_event_rows()
	local rows = {}
	for _, row in ipairs(get_raw_rows()) do
		if accepts_filter(row) then
			rows[#rows + 1] = row
		end
	end
	return rows
end

local event_list = {}

function event_list.clear()
	bind.set(SELECTED_INDEX, -1)
	bind.set(SELECTED_VALUE, -1)
end

function event_list.select(index)
	local rows = get_event_rows()
	if #rows == 0 then
		event_list.clear()
		return nil
	end

	index = tonumber(index) or tonumber(bind.get(SELECTED_INDEX)) or 0
	if index < 0 or index >= #rows then
		index = 0
	end

	local row = rows[index + 1]
	bind.set(SELECTED_INDEX, index)
	bind.set(SELECTED_VALUE, row and row.index or -1)
	return row
end

function event_list.selected()
	return event_list.select(nil)
end

function event_list.list_items()
	local result = {}
	for index, row in ipairs(get_event_rows()) do
		local name = row.name or "Evento"

		result[#result + 1] = {
			id = index - 1,
			item_index = -1,
			name = name,
			text = name,
			badge = get_badge_text(row),
			icon_color = get_event_icon_color(row),
			text_color = colors.text,
			badge_color = get_status_color(row),
			parts = {
				{
					kind = "icon",
					x = 5,
					y = 7,
					width = 16,
					height = 16,
					texture = ui.sprite("Lua\\Texture\\craftpix\\icons.craftpix", 0.0, 0.0, 128.0, 128.0)
					--color = get_event_icon_color(row)
				},
				{
					kind = "text",
					text = name,
					x = 28,
					y = 8,
					width = 88,
					height = 14,
					font = "bold",
					color = colors.text
				},
				{
					kind = "text",
					text = get_badge_text(row),
					right = 4,
					y = 8,
					width = 56,
					height = 14,
					font = "normal",
					align = "right",
					color = get_status_color(row)
				}
			}
		}
	end
	return result
end

local function selected_row()
	return event_list.selected()
end

local function selected_name()
	local row = selected_row()
	return row and row.name or "Sin eventos"
end

local function selected_time()
	local row = selected_row()
	return get_time_text(row)
end

local function selected_status()
	local row = selected_row()
	return get_status(row)
end

local function selected_schedule()
	local row = selected_row()
	if not row then
		return "No hay horarios disponibles para el filtro actual."
	end

	if row.time_remaining == 0 then
		return "El evento se encuentra disponible ahora."
	end

	if row.time_remaining > 0 then
		return "Proxima apertura en " .. get_time_text(row) .. "."
	end

	return "El evento no esta disponible actualmente."
end

local function selected_description()
	local row = selected_row()
	if not row then
		return "Selecciona un evento en la lista para revisar sus horarios, estado y recompensas."
	end

	local name = row.name or "este evento"
	return "Preparate para " .. name .. ". Revisa el tiempo restante y organiza tu entrada antes de que cambie el estado."
end

local function selected_command()
	local row = selected_row()
	if not row then
		return "/event"
	end

	return "/event " .. tostring(row.index or 0)
end

local function empty_hint()
	if #get_event_rows() > 0 then
		return ""
	end

	return "Sin eventos para este filtro."
end

bind.set(SELECTED_INDEX, -1)
bind.set(SELECTED_VALUE, -1)
bind.set(FILTER_TYPE, bind.get(FILTER_TYPE) or 0)
bind.set(ONLY_AVAILABLE, bind.get(ONLY_AVAILABLE) or false)

actions.register("eventos.open", function()
	events.request_refresh()
	event_list.select(nil)
end)

actions.register("eventos.close", function()
	events.set_current_tab(0)
	event_list.clear()
	ui.close("eventos")
end)

actions.register("eventos.refresh", function()
	events.request_refresh()
	event_list.select(nil)
end)

actions.register("eventos.join", function()
	local row = selected_row()
	if row and events.request_join then
		events.request_join(row.index or 0)
		return
	end

	events.request_refresh()
	event_list.select(nil)
end)

actions.register("eventos.select_event", function(index)
	event_list.select(index)
end)

actions.register("eventos.set_page", function(index)
	events.set_current_tab(tonumber(index) or 0)
	event_list.select(0)
end)

actions.register("eventos.filter_changed", function()
	event_list.select(0)
end)

local win = ui.window("eventos", {
	title = events.get_title(),
	rect = ui.rect(142, 54, 500, 280),
	hotkey = "H",
	closable = true,
	movable = true,
	on_open = function()
		actions.run("eventos.open")
	end,
	on_close = function()
		events.set_current_tab(0)
		event_list.clear()
	end
})


win:panel("event_list_panel", {
	rect = ui.rect(10, 20, 230, 250),
	header_visible = false,
	show_background = false,
	show_border = false,
	background_color = colors.panel,
	border_color = colors.line,
	padding_left = 0,
	padding_top = 0,
	padding_right = 0,
	padding_bottom = 0
})

win:text("list_title", {
	parent = "event_list_panel",
	rect = ui.rect(15, 5, 90, 18),
	text = "EVENT",
	font = "bold",
	style = { text_color = colors.gold }
})

win:text("list_time_title", {
	parent = "event_list_panel",
	rect = ui.rect(80, 5, 88, 18),
	text = "TIME LEFT",
	font = "bold",
	align = "right",
	style = { text_color = colors.gold }
})

win:item_list("event_list", {
	parent = "event_list_panel",
	rect = ui.rect(8, 30, 160, 190),
	row_height = 30,
	model_size = 0,
	current_bind = SELECTED_INDEX,
	current = 0,
	bind_items = event_list.list_items,
	on_item_selected = function(index)
		actions.run("eventos.select_event", index)
	end,
	text_color = colors.text,
	count_color = colors.gold,
	hover_color = ui.color(54, 38, 24, 200),
	selected_color = ui.color(111, 44, 12, 225)
})

win:text("empty_hint", {
	parent = "event_list_panel",
	rect = ui.rect(22, 150, 194, 24),
	align = "center",
	bind_text = empty_hint,
	style = { text_color = colors.offline }
})
-- select: < >
win:selector("page_selector", {
	parent = "event_list_panel",
	rect = ui.rect(84, 228, 122, 24),
	current_bind = "events.current_tab",
	max_bind = "events.max_tabs",
	wrap = false,
	format_text = function(current, max)
		return string.format("%d / %d", current + 1, max)
	end,
	action = "eventos.set_page"
})


-- panel secundario
win:panel("detail_panel", {
	rect = ui.rect(185, 20, 300, 250),
	header_visible = false,
	show_background = true,
	show_border = false,
	background_color = colors.panel,
	border_color = colors.line,
	padding_left = 0,
	padding_top = 0,
	padding_right = 0,
	padding_bottom = 0
})

win:panel("hero_art", {
    parent = "detail_panel",
    rect = ui.rect(0, 0, 300, 130),
    header_visible = false,
    show_background = true,
    show_border = false,

    background_texture = ui.sprite(
        "Lua\\Texture\\craftpix\\blood-castle-safe-zone.craftpix",
        0.0, 0.0, 823.0, 388.0
    ),

    background_color = ui.color(17, 24, 31, 225),
    border_color = colors.line,
    padding_left = 0,
    padding_top = 0,
    padding_right = 0,
    padding_bottom = 0
})

win:text("hero_kicker", {
	parent = "hero_art",
	rect = ui.rect(5, 5, 180, 18),
	text = "NEXT EVENT",
	font = "bold",
	style = { text_color = colors.gold }
})

win:text("hero_name", {
	parent = "hero_art",
	rect = ui.rect(0, 112, 300, 34),
	bind_text = selected_name,
	font = "big",
	align = "center",
	style = { text_color = colors.title }
})

win:text("hero_status", {
	parent = "hero_art",
	rect = ui.rect(0, 92, 300, 18),
	bind_text = selected_status,
	font = "bold",
	align = "center",
	style = { text_color = colors.blue }
})

win:text("hero_description", {
	parent = "detail_panel",
	rect = ui.rect(0, 130, 300, 18),
	bind_text = selected_description,
	align = "center",
	style = { text_color = colors.text }
})

win:panel("rewards_panel", {
	parent = "detail_panel",
	rect = ui.rect(10, 150, 160, 50),
	header_visible = false,
	show_background = true,
	show_border = true,
	background_color = colors.panel_deep,
	border_color = colors.line,
	padding_left = 0,
	padding_top = 0,
	padding_right = 0,
	padding_bottom = 0
})

win:text("rewards_title", {
	parent = "rewards_panel",
	rect = ui.rect(0, 4, 160, 16),
	text = "REWARDS",
	font = "bold",
	align = "center",
	style = { text_color = colors.gold }
})

local reward_labels = { "ZEN", "JEWEL", "BOX", "DROP" }
for i, label in ipairs(reward_labels) do
	local x = 8 + ((i - 1) * 38)
	win:panel("reward_box_" .. i, {
		parent = "rewards_panel",
		rect = ui.rect(x, 18, 30, 25),
		header_visible = false,
		show_background = true,
		show_border = true,
		background_color = colors.panel_soft,
		border_color = i == 2 and ui.color(153, 67, 220, 220) or colors.line_hot,
		padding_left = 0,
		padding_top = 0,
		padding_right = 0,
		padding_bottom = 0
	})
	win:text("reward_text_" .. i, {
		parent = "reward_box_" .. i,
		rect = ui.rect(0, 7, 38, 14),
		text = label,
		font = "bold",
		align = "center",
		style = { text_color = colors.title }
	})
end

win:panel("timer_panel", {
	parent = "detail_panel",
	rect = ui.rect(180, 150, 110, 50),
	header_visible = false,
	show_background = true,
	show_border = true,
	background_color = colors.panel_deep,
	border_color = colors.line,
	padding_left = 0,
	padding_top = 0,
	padding_right = 0,
	padding_bottom = 0
})

win:text("timer_title", {
	parent = "timer_panel",
	rect = ui.rect(0, 4, 110, 16),
	text = "TIME LEFT",
	font = "bold",
	align = "center",
	style = { text_color = colors.gold }
})

win:text("timer_value", {
	parent = "timer_panel",
	rect = ui.rect(0, 22, 110, 24),
	bind_text = selected_time,
	font = "big",
	align = "center",
	style = { text_color = ui.color(255, 196, 82, 255) }
})

win:button("join_event", {
	parent = "detail_panel",
	rect = ui.rect(100, 204, 100, 26),
	text = "ENTRAR EVENTO",
	font = "bold",
	action = "eventos.join"
})

win:button("refresh", {
	rect = ui.rect(548, 412, 88, 20),
	text = "Actualizar",
	action = "eventos.refresh"
})

event_list.select(nil)
