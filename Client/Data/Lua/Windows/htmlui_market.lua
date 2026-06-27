-- HTML skin for a marketplace preview.
-- All data is mock/local for now; later this can be replaced by server data.
if createwinhtml and sfui and sfui.html then
	local window_id = "html_market"

	local state = {
		category = "all",
		query = "",
		sort = "default",
		page = 1,
		page_size = 8,
		last_message = "Mock market loaded from Lua"
	}

	local categories = {
		{ id = "all", label = "All Items", icon = "box" },
		{ id = "weapons", label = "Weapons", icon = "sword" },
		{ id = "armors", label = "Armors", icon = "armor" },
		{ id = "shields", label = "Shields", icon = "shield" },
		{ id = "helmets", label = "Helmets", icon = "helm" },
		{ id = "accessories", label = "Accessories", icon = "ring" },
		{ id = "potions", label = "Potions", icon = "potion" },
		{ id = "scrolls", label = "Scrolls", icon = "scroll" },
		{ id = "boxes", label = "Boxes", icon = "chest" },
		{ id = "wings", label = "Wings", icon = "wing" },
		{ id = "pets", label = "Pets", icon = "pet" },
		{ id = "bundles", label = "Bundles", icon = "bundle" }
	}

	local items = {
		{ id = 101, category = "weapons", name = "Short Sword", type = "Sword / One Hand", meta = "Level: 1 ~ 7", price = 5010, currency = "WCoinC", badge = "HOT", art = "sword" },
		{ id = 102, category = "bundles", name = "Adventure Bag", type = "Expanded Inventory", meta = "+50 Slots", price = 3500, currency = "WCoinC", badge = "", art = "bag" },
		{ id = 103, category = "scrolls", name = "Reset Scroll", type = "Allows reset", meta = "Reset Stats", price = 1075, currency = "WCoinC", badge = "", art = "scroll" },
		{ id = 104, category = "potions", name = "Healing Potion", type = "Restore HP", meta = "+200 HP", price = 700, currency = "WCoinC", badge = "", art = "potion" },
		{ id = 105, category = "shields", name = "Blade of Knight", type = "Shield / Defense", meta = "120 ~ 180", price = 9000, currency = "WCoinC", badge = "", art = "shield" },
		{ id = 106, category = "armors", name = "Divine Armor", type = "Strength Requirement: 400", meta = "Defend: 89", price = 8750, currency = "WCoinC", badge = "", art = "armor" },
		{ id = 107, category = "wings", name = "Wings of Dragon", type = "Increase damage", meta = "+15", price = 15000, currency = "WCoinC", badge = "NEW", art = "wings", featured = true },
		{ id = 108, category = "accessories", name = "Jewel of Bless", type = "Increases item luck", meta = "+25%", price = 2000, currency = "WCoinC", badge = "", art = "jewel" },
		{ id = 109, category = "helmets", name = "Dragon Helm", type = "Helmet / Defense", meta = "Defense: 52", price = 6400, currency = "WCoinC", badge = "", art = "helm" },
		{ id = 110, category = "boxes", name = "Mystery Box", type = "Random reward", meta = "Rare chance", price = 1250, currency = "WCoinC", badge = "SALE", art = "chest" },
		{ id = 111, category = "pets", name = "Dark Raven", type = "Pet companion", meta = "Attack support", price = 7300, currency = "WCoinC", badge = "", art = "pet" },
		{ id = 112, category = "weapons", name = "Crystal Staff", type = "Staff / Wizard", meta = "Wizardry +18%", price = 9800, currency = "WCoinC", badge = "", art = "staff" },
		{ id = 113, category = "potions", name = "Mana Potion", type = "Restore Mana", meta = "+180 MP", price = 650, currency = "WCoinC", badge = "", art = "mana" },
		{ id = 114, category = "scrolls", name = "Master Seal", type = "Experience Boost", meta = "3 Days", price = 4500, currency = "WCoinC", badge = "", art = "seal" },
		{ id = 115, category = "bundles", name = "Starter Pack", type = "Bundle", meta = "Potions + Jewels", price = 5200, currency = "WCoinC", badge = "HOT", art = "bundle" },
		{ id = 116, category = "armors", name = "Eclipse Gloves", type = "Gloves / Defense", meta = "Attack speed +5", price = 5850, currency = "WCoinC", badge = "", art = "gloves" }
	}

	local function contains(value, query)
		if query == "" then
			return true
		end
		return string.find(string.lower(value or ""), query, 1, true) ~= nil
	end

	local function filtered_items()
		local query = string.lower(state.query or "")
		local result = {}
		for _, item in ipairs(items) do
			local match_category = state.category == "all" or item.category == state.category
			local match_query = contains(item.name, query) or contains(item.type, query) or contains(item.meta, query)
			if match_category and match_query then
				result[#result + 1] = item
			end
		end

		if state.sort == "price_asc" then
			table.sort(result, function(a, b) return a.price < b.price end)
		elseif state.sort == "price_desc" then
			table.sort(result, function(a, b) return a.price > b.price end)
		elseif state.sort == "name" then
			table.sort(result, function(a, b) return a.name < b.name end)
		end
		return result
	end

	local function featured_item()
		for _, item in ipairs(items) do
			if item.featured then
				return item
			end
		end
		return items[1]
	end

	local function sync_market(reason)
		local all = filtered_items()
		local total_pages = math.max(1, math.ceil(#all / state.page_size))
		if state.page > total_pages then
			state.page = total_pages
		end
		if state.page < 1 then
			state.page = 1
		end

		local page_items = {}
		local start_index = ((state.page - 1) * state.page_size) + 1
		local end_index = math.min(#all, start_index + state.page_size - 1)
		for index = start_index, end_index do
			page_items[#page_items + 1] = all[index]
		end

		sfui.html.send(window_id, {
			target = "#market-root",
			action = "setData",
			payload = {
				reason = reason or "sync",
				categories = categories,
				items = page_items,
				featured = featured_item(),
				category = state.category,
				query = state.query,
				sort = state.sort,
				page = state.page,
				total_pages = total_pages,
				total_items = #all,
				message = state.last_message,
				currency = {
					wcoinc = 12450,
					wcoinp = 2350,
					goblin = 750
				}
			}
		})
	end

	sfui.on("Market.Ready", function()
		sync_market("ready")
	end)

	sfui.on("Market.Category", function(payload)
		if type(payload) == "table" and payload.category then
			state.category = tostring(payload.category)
			state.page = 1
		end
		sync_market("category")
	end)

	sfui.on("Market.Search", function(payload)
		if type(payload) == "table" then
			state.query = tostring(payload.query or "")
			state.page = 1
		end
		sync_market("search")
	end)

	sfui.on("Market.Sort", function(payload)
		if type(payload) == "table" and payload.sort then
			state.sort = tostring(payload.sort)
			state.page = 1
		end
		sync_market("sort")
	end)

	sfui.on("Market.Page", function(payload)
		if type(payload) == "table" then
			state.page = tonumber(payload.page or state.page) or state.page
		end
		sync_market("page")
	end)

	sfui.on("Market.Buy", function(payload)
		local item_id = -1
		if type(payload) == "table" then
			item_id = tonumber(payload.id or -1) or -1
		end

		local selected = nil
		for _, item in ipairs(items) do
			if item.id == item_id then
				selected = item
				break
			end
		end

		state.last_message = selected and ("Compra mock: " .. selected.name) or "Item no encontrado"
		sync_market("buy")
	end)

	local win = createwinhtml("market", {
		id = window_id,
		title = "Market",
		x = 14,
		y = 18,
		width = 612,
		height = 420,
		key = "F9",
		data = {
			source = "market.mock",
			target = "#market-root"
		},
		events = {
			["#category-list:click"] = "Market.Category",
			["#market-grid:click"] = "Market.Buy",
			["#search-input:change"] = "Market.Search",
			["#sort-select:change"] = "Market.Sort",
			["#pagination:click"] = "Market.Page"
		},
		closable = true,
		movable = true,
		show_background = false,
		show_border = false,
		show_header = false,
		show_title = false
	})

	if win then
		win:load_events({
			events = {
				["#category-list:click"] = "Market.Category",
				["#market-grid:click"] = "Market.Buy",
				["#search-input:change"] = "Market.Search",
				["#sort-select:change"] = "Market.Sort",
				["#pagination:click"] = "Market.Page"
			}
		})
	end
end
