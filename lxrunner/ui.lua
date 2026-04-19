local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

local util = require("lxcommon.util")

local M = {}

local function resolve_default(value)
    if type(value) == "function" then
        return value()
    end

    return value
end

local function alias_decoration(instance, alias_name)
    if not instance or type(alias_name) ~= "string" or alias_name == "" then
        return nil
    end

    for _, alias in ipairs(instance._aliases or {}) do
        if alias.name == alias_name then
            if type(alias.icon) == "string" and alias.icon ~= "" then
                return {
                    icon = alias.icon,
                }
            end

            if type(alias.glyph) == "string" and alias.glyph ~= "" then
                return {
                    glyph = alias.glyph,
                    glyph_font = alias.glyph_font,
                }
            end

            return nil
        end
    end

    return nil
end

---Build one result row with optional image or glyph decoration.
local function build_row(text, selected, decoration)
    local fg = selected
        and (beautiful.lxrunner_row_selected_fg or beautiful.fg_focus or "#ffffff")
        or (beautiful.lxrunner_row_fg or beautiful.fg_normal or "#bbbbbb")
    local icon_size = beautiful.lxrunner_icon_size or 14

    local icon_widget
    if decoration and decoration.icon then
        icon_widget = wibox.widget({
            image = gears.color.recolor_image(decoration.icon, fg),
            resize = true,
            forced_width = icon_size,
            forced_height = icon_size,
            widget = wibox.widget.imagebox,
        })
    elseif decoration and decoration.glyph then
        icon_widget = wibox.widget({
            markup = string.format(
                '<span foreground="%s" font="%s">%s</span>',
                fg,
                gears.string.xml_escape(decoration.glyph_font or beautiful.lxrunner_icon_font or beautiful.font),
                gears.string.xml_escape(decoration.glyph)
            ),
            align = "center",
            valign = "center",
            forced_width = icon_size,
            forced_height = icon_size,
            widget = wibox.widget.textbox,
        })
    else
        icon_widget = wibox.widget({
            text = "",
            forced_width = icon_size,
            forced_height = icon_size,
            widget = wibox.widget.textbox,
        })
    end

    return wibox.widget({
        {
            icon_widget,
            {
                {
                    text = text,
                    align = "left",
                    valign = "center",
                    font = beautiful.lxrunner_row_font or beautiful.font,
                    widget = wibox.widget.textbox,
                },
                left = beautiful.lxrunner_icon_text_spacing or 8,
                widget = wibox.container.margin,
            },
            left = beautiful.lxrunner_row_padding or 10,
            right = beautiful.lxrunner_row_padding or 10,
            top = 4,
            bottom = 4,
            layout = wibox.layout.fixed.horizontal,
        },
        bg = selected
            and (beautiful.lxrunner_row_selected_bg or beautiful.bg_focus or "#444444")
            or (beautiful.lxrunner_row_bg or beautiful.bg_normal or "#222222"),
        fg = fg,
        widget = wibox.container.background,
    })
end

---Attach UI rendering helpers to lxrunner.
function M.extend(instance_methods)
    ---Populate the list with instructional placeholder rows before history exists.
    function instance_methods:_set_placeholder_rows()
        local rows = {
            "Type to search PATH commands, aliases, and apps",
            "Recent launches will appear here",
            "Tab completes the highlighted match",
            "Desktop entries are searched by name",
            "Escape closes the runner",
        }

        self._results:reset()

        for i = 1, self.opts.row_count do
            self._results:add(build_row(rows[i] or "", i == 1))
        end
    end

    ---Pick the row decoration for the current source type.
    function instance_methods:_decoration_for_entry(entry)
        if not entry then
            return nil
        end

        local source = entry.source == "history" and entry.launch_source or entry.source

        if source == "path" then
            return {
                icon = self._icons.path,
            }
        end

        if source == "alias" then
            if type(entry.icon) == "string" and entry.icon ~= "" then
                return {
                    icon = entry.icon,
                }
            end

            if type(entry.glyph) == "string" and entry.glyph ~= "" then
                return {
                    glyph = entry.glyph,
                    glyph_font = entry.glyph_font,
                }
            end

            return alias_decoration(self, entry.alias_name or entry.name) or {
                icon = self._icons.alias,
            }
        end

        if source == "desktop" then
            return {
                icon = self._icons.desktop,
            }
        end

        return nil
    end

    ---Re-render the result area from either history, matches, or placeholder rows.
    function instance_methods:_render_results()
        self._results:reset()

        if self._input == "" then
            if #self._history == 0 then
                self:_set_placeholder_rows()
                return
            end

            for i = 1, self.opts.row_count do
                local entry = self._history[i]
                if entry then
                    self._results:add(build_row(entry.name, i == self._selected_index, self:_decoration_for_entry(entry)))
                else
                    self._results:add(build_row("", false))
                end
            end

            return
        end

        if #self._matches == 0 then
            self._results:add(build_row("No matches", true))

            for _ = 2, self.opts.row_count do
                self._results:add(build_row("", false))
            end

            return
        end

        for i = 1, self.opts.row_count do
            local match = self._matches[i]
            if match then
                self._results:add(build_row(match.display or match.name, i == self._selected_index, self:_decoration_for_entry(match)))
            else
                self._results:add(build_row("", false))
            end
        end
    end

    ---Re-render the prompt line including the fake text cursor.
    function instance_methods:_render_prompt()
        local cursor = self.visible and (beautiful.lxrunner_cursor or "_") or ""
        self._prompt:set_markup(string.format(
            '<span foreground="%s">%s</span><span foreground="%s"> %s%s</span>',
            beautiful.lxrunner_prompt_fg or beautiful.fg_focus or "#ffffff",
            gears.string.xml_escape(self.opts.prompt .. ":"),
            beautiful.lxrunner_input_fg or beautiful.fg_normal or "#ffffff",
            gears.string.xml_escape(self._input),
            gears.string.xml_escape(cursor)
        ))
    end

    ---Refresh prompt text, match state, and result rows in one place.
    function instance_methods:_refresh()
        self:_render_prompt()
        self:_filter_matches()
        self:_render_results()
    end

    ---Build the centered popup shell and hook prompt-local mouse actions.
    function instance_methods:_build_popup()
        self._prompt = wibox.widget({
            markup = "",
            font = beautiful.lxrunner_input_font or beautiful.font,
            align = "left",
            valign = "center",
            widget = wibox.widget.textbox,
        })

        self._results = wibox.layout.fixed.vertical()

        local input_box = wibox.widget({
            {
                self._prompt,
                left = beautiful.lxrunner_padding or 12,
                right = beautiful.lxrunner_padding or 12,
                top = beautiful.lxrunner_padding or 12,
                bottom = beautiful.lxrunner_padding or 12,
                widget = wibox.container.margin,
            },
            bg = beautiful.lxrunner_input_bg or beautiful.bg_focus or "#111111",
            fg = beautiful.lxrunner_input_fg or beautiful.fg_normal or "#ffffff",
            widget = wibox.container.background,
        })
        input_box:buttons(gears.table.join(
            awful.button({}, 2, function()
                self:_paste_primary_selection()
            end)
        ))

        self.popup = awful.popup({
            ontop = true,
            visible = false,
            type = "splash",
            minimum_width = self.opts.width,
            maximum_width = self.opts.width,
            placement = function(c)
                awful.placement.centered(c, { honor_workarea = true })
            end,
            shape = function(cr, width, height)
                gears.shape.rounded_rect(cr, width, height, beautiful.lxrunner_radius or 6)
            end,
            border_width = beautiful.lxrunner_border_width or beautiful.border_width or 1,
            border_color = beautiful.lxrunner_border_color or beautiful.border_focus or "#666666",
            bg = beautiful.lxrunner_bg or beautiful.bg_normal or "#222222",
            widget = {
                {
                    input_box,
                    {
                        self._results,
                        top = 8,
                        widget = wibox.container.margin,
                    },
                    spacing = 0,
                    layout = wibox.layout.fixed.vertical,
                },
                margins = beautiful.lxrunner_outer_margin or 10,
                widget = wibox.container.margin,
            },
        })

        self:_render_prompt()
        self:_set_placeholder_rows()
    end
end

return M
