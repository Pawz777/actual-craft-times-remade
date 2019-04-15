local ACT = require("prototypes.shared")

--- Round a number.
function round(val, decimal)
    local exp = decimal and 10 ^ decimal or 1
    return math.ceil(val * exp - 0.5) / exp
end

local function getValidSprite(player, spritePath)
    if player.gui.is_valid_sprite_path(spritePath) then
        return spritePath
    else
        return "utility/questionmark"
    end
end

-- Creates an item that is several controls grouped together
local function addListItem(gui_element, text, value, spritePath)
    if (gui_element and gui_element.valid) then
        local cont = gui_element.add {type = "flow", direction = "horizontal"}
        cont.add {type = "sprite", sprite = spritePath, style = "ACT_small_sprite"}
        cont.add {type = "label", caption = text}
        cont.add {type = "label", caption = round(value, 1) .. " /s"}
    end
end

local function createProductionDetailsInElement(gui_element, entity, playerIndex, multiplier)
    local production = ACT.getProductionNumbersForEntity(entity, playerIndex)
    local player = game.players[playerIndex]
    if production then
        productionFrame = gui_element.add {type = "flow", direction = "horizontal", name = playerIndex .. "_productionFrame"}
        ingredientFrame = productionFrame.add {type = "flow", direction = "horizontal", name = playerIndex .. "_ingredientFrame"}
        local container = ingredientFrame.add {type = "frame", direction = "vertical", caption = "Ingredients"}
        if (production.ingredients) then
            for i = 1, #production.ingredients do
                local ingredient = production.ingredients[i]
                local sprite = getValidSprite(player, ingredient.spritePath)
                local amount = ingredient.amount
                amount = production.productsPerSecond * amount * multiplier
                local name = game[ingredient.type .. "_prototypes"][ingredient.name].localised_name

                addListItem(container, name, amount, sprite)
            end
        end
        local container = ingredientFrame.add {type = "frame", direction = "vertical", caption = "Products"}
        if (production.products) then
            for i = 1, #production.products do
                local prod = production.products[i]
                local sprite = getValidSprite(player, prod.spritePath)
                local amount = prod.amount
                amount = production.productsPerSecond * amount * multiplier
                local name = game[prod.type .. "_prototypes"][prod.name].localised_name
                addListItem(container, name, amount, sprite)
            end
        end
    end
end

local function createProductionMultiplierInElement(gui_element, playerIndex, multiplier)
    local container = gui_element.add {type = "frame", direction = "vertical", name = playerIndex .. "_slider_container"}
    container.add {type = "label", caption = "Multiplier: " .. multiplier, name = playerIndex .. "_slider_label"}
    container.add {type = "slider", caption = "Multiplier", name = playerIndex .. "_slider", value = multiplier, minimum_value = 1, maxiumum_value = 50}
    container.add {type = "text-box", caption = "Multiplier", name = playerIndex .. "_slider_value", value = multiplier}
end

local function openGui(entity, playerIndex)
    if (playerIndex) then
        local player = game.players[playerIndex]
        if (settings.get_player_settings(player)["ACT-show-interface"].value and entity) then
            local productionNumbers = ACT.getProductionNumbersForEntity(entity)
            if (productionNumbers) then
                local guiContext = player.gui["left"]
                local frameName = playerIndex .. "_ACT_Frame"
                local frame =
                    guiContext.add {
                    type = "frame",
                    name = frameName,
                    direction = "vertical",
                    caption = "Current Production Details"
                }
                prod = frame.add {type = "flow", name = playerIndex .. "_production_flow"}
                createProductionDetailsInElement(prod, entity, playerIndex, 1)
                control = frame.add {type = "flow", name = playerIndex .. "_control_flow"}
                createProductionMultiplierInElement(control, playerIndex, 1)
            end
        end
    end
end

local function closeGui(playerIndex)
    local player = game.players[playerIndex]
    if (player) then
        local guiContext = player.gui["left"]
        local frameName = playerIndex .. "_ACT_Frame"
        if guiContext[frameName] then
            guiContext[frameName].destroy()
        end
    end
end

local function on_gui_opened(event)
    if event.gui_type == defines.gui_type.entity then
        openGui(event.entity, event.player_index)
    end
end

local function on_gui_closed(event)
    if event.gui_type == defines.gui_type.entity then
        closeGui(event.player_index)
    end
end

local function on_gui_value_changed(event)
    if event.element.name == event.player_index .. "_slider" then
        local playerIndex = event.player_index
        local player = game.players[playerIndex]
        local entity = player.opened
        local entityMultiplier = round(event.element.slider_value, 0) or 1
        local guiContext = player.gui["left"]
        local frameName = playerIndex .. "_ACT_Frame"
        if guiContext[frameName] and entity then
            guiContext[frameName][playerIndex .. "_production_flow"].clear()
            createProductionDetailsInElement(guiContext[frameName][playerIndex .. "_production_flow"], entity, playerIndex, entityMultiplier)
            guiContext[frameName][playerIndex .. "_control_flow"][playerIndex .. "_slider_container"][playerIndex .. "_slider_label"].caption = "Multiplier: " .. entityMultiplier
            guiContext[frameName][playerIndex .. "_control_flow"][playerIndex .. "_slider_container"][playerIndex .. "_slider"].slider_value = entityMultiplier
        end
    end
end

local function on_gui_click(event)
end

script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)

script.on_event(defines.events.on_gui_click, on_gui_click)

script.on_event(defines.events.on_gui_value_changed, on_gui_value_changed)
