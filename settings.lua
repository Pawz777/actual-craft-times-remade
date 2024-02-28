data:extend({
{
    type = "double-setting",
    name = "ACTR-Multiplier",
    setting_type = 'runtime-per-user',
    minimum_value = 1,
    default_value = 100
},
{
    type = "string-setting",
    name = "ACTR-Interval",
    setting_type = 'runtime-per-user',
    allowed_values = { "second", "minute", "hour", "day" },
    default_value = "second",
},
})
