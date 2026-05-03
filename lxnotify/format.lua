local format = {}

---Return the best available human-readable title for a notification.
---@param notification table|nil
---@return string
function format.title(notification)
    if not notification then
        return "Notification"
    end

    local title = notification.title
    if title and title ~= "" then
        return title
    end

    local message = notification.message
    if message and message ~= "" then
        return message
    end

    local text = notification.text
    if text and text ~= "" then
        return text
    end

    return "Notification"
end

---Strip common Pango/HTML-ish markup from notification strings.
---@param text string|nil
---@return string
function format.strip_markup(text)
    if not text or text == "" then
        return ""
    end

    return text
        :gsub("<br%s*/?>", "\n")
        :gsub("</p>", "\n")
        :gsub("<[^>]+>", "")
        :gsub("&nbsp;", " ")
        :gsub("&lt;", "<")
        :gsub("&gt;", ">")
        :gsub("&amp;", "&")
        :gsub("&quot;", "\"")
        :gsub("&#39;", "'")
end

---Collapse markup-heavy notification text into a compact single-line preview.
---@param text string|nil
---@return string
function format.collapse_whitespace(text)
    if not text or text == "" then
        return ""
    end

    return format.strip_markup(text)
        :gsub("[\r\n\t]+", " ")
        :gsub("%s%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
end

---Truncate text to a maximum character count with an ellipsis.
---@param text string|nil
---@param limit integer
---@return string
function format.truncate_text(text, limit)
    if not text or text == "" then
        return ""
    end

    if #text <= limit then
        return text
    end

    return text:sub(1, math.max(1, limit - 1)):gsub("%s+$", "") .. "…"
end

---Return the compact body preview for a notification.
---@param notification table|nil
---@return string
function format.body(notification)
    if not notification then
        return ""
    end

    local body = notification.message or notification.text or ""
    local compact_body = format.collapse_whitespace(body)
    local compact_title = format.collapse_whitespace(notification.title or "")

    if compact_body == compact_title then
        return ""
    end

    return compact_body
end

---Return the source label used in lxnotify cards.
---@param notification table|nil
---@return string
function format.source(notification)
    if not notification then
        return "unknown"
    end

    local source = format.collapse_whitespace(notification.app_name or "")
    if source ~= "" then
        return source
    end

    local category = format.collapse_whitespace(notification.category or "")
    if category ~= "" then
        return category
    end

    return "unknown"
end

---Normalize urgency names to the supported set.
---@param notification table|nil
---@return "low"|"normal"|"critical"
function format.urgency(notification)
    local urgency = notification and notification.urgency or "normal"
    if urgency ~= "low" and urgency ~= "normal" and urgency ~= "critical" then
        urgency = "normal"
    end
    return urgency
end

---Build the compact stored representation used by lxnotify entries.
---@param instance table
---@param notification table
---@param timestamp string|nil
---@return table
function format.summary(instance, notification, timestamp)
    local icon = nil
    if notification then
        if type(notification.get_icon) == "function" then
            local ok, value = pcall(notification.get_icon, notification)
            if ok then
                icon = value
            end
        else
            icon = notification.icon
        end
    end

    return {
        title = format.truncate_text(format.collapse_whitespace(format.title(notification)), instance:notification_title_max_length()),
        body = format.truncate_text(format.body(notification), instance:notification_body_max_length()),
        source = format.truncate_text(format.source(notification), instance:notification_source_max_length()),
        category = format.collapse_whitespace(notification.category or ""),
        icon = icon,
        urgency = format.urgency(notification),
        created_at = timestamp or os.date(instance:notification_time_format()),
    }
end

---Return the grouping key used for burst notifications.
---@param entry table
---@return string
function format.group_key(entry)
    local title = format.collapse_whitespace(entry.title or "")
    if title ~= "" and title ~= "Notification" then
        return "title:" .. title
    end

    local category = format.collapse_whitespace(entry.category or "")
    if category ~= "" then
        return "category:" .. category
    end

    return "source:" .. (entry.source or "unknown")
end

return format
