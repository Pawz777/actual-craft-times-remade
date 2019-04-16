Calculator = require "prototypes.calculator"

function player_setup(playerIndex)
    if not global.ACTR then
        global.ACTR = {}
    end
    if not global.ACTR[playerIndex] then
        global.ACTR[playerIndex] = {show_calculator = false}
    end
    if not global.ACTR.registeredEntityMultipliers then
        global.ACTR.registeredEntityMultipliers = {}
    end

    local player = game.players[playerIndex]
    --remove any old frames
    if (player.gui["left"][playerIndex .. "_ACT_Frame"]) then
        player.gui["left"][playerIndex .. "_ACT_Frame"].destroy()
    end

    --setup new button
    if (mod_gui.get_button_flow(player).ACTR_mod_button) then
        mod_gui.get_button_flow(player).ACTR_mod_button.destroy()
    end
    mod_gui.get_button_flow(player).add {
        type = "sprite-button",
        name = "ACTR_mod_button",
        tooltip = {"gui.ACTR_mod_button"},
        sprite = "item/assembling-machine-1",
        style = "mod_gui_button"
    }
end

script.on_configuration_changed(
    function(event)
        for i, player in pairs(game.players) do
            player_setup(player.index)
        end
    end
)

script.on_init(
    function(event)
        for i, player in pairs(game.players) do
            player_setup(player.index)
        end
    end
)

script.on_event(
    defines.events.on_player_created,
    function(event)
        player_setup(event.player_index)
    end
)

script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        player_setup(event.player_index)
    end
)

script.on_event(
    defines.events.on_gui_click,
    function(event)
        if (global.ACTR and event.element.name == "ACTR_mod_button") then
            if (global.ACTR[event.player_index].show_calculator) then
                global.ACTR[event.player_index].show_calculator = false
                Calculator.closeGui(event.player_index)
            else
                global.ACTR[event.player_index].show_calculator = true
                Calculator.openGui(event.player_index)
            end
        end
    end
)
