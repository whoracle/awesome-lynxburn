return {
    terminal = "alacritty",
    browser = "firefox",
    autostart_once = {
        "nm-applet --sm-disable",
    },
    redshift = {
        enabled = true,
        autostart = false,
        latitude = 52.52,
        longitude = 13.405,
        temperature_day = 6500,
        temperature_night = 4500,
        refresh_interval = 120,
        schedule_transition_seconds = 3600,
        day_start = "07:00",
        night_start = "19:00",
    },
}
