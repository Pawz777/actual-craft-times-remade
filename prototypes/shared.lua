local ACT = {}

--[[
Production Numbers table returned:
 production = {
        summary_ingredients = {
            name, 
            quantity,
            spritePath,
            type
        },
        summary_products = {
            name,
            quantity,
            spritePath,
            type
        },
        craftingSpeed = 0,
        productCraftingTime = 0,
        productsPerSecond = 0,
        effects = {
            consumption = {bonus = 0.0},
            speed = {bonus = 0.0},
            productivity = {bonus = 0.0},
            pollution = {bonus = 0.0}
        }
    }

]]
function ACT.getProductionNumbersForEntity(entity, playerIndex)
    local production = {
        summary_ingredients = {},
        summary_products = {},
        craftingSpeed = 0,
        productCraftingTime = 0,
        productsPerSecond = 0,
        effects = {
            consumption = {bonus = 0.0},
            speed = {bonus = 0.0},
            productivity = {bonus = 0.0},
            pollution = {bonus = 0.0}
        }
    }
    if entity.effects then
        if entity.effects.speed then
            production.effects.speed.bonus = entity.effects.speed.bonus
        end
        if entity.effects.productivity then
            production.effects.productivity.bonus = entity.effects.productivity.bonus
        end
    end
    local recipe = getRecipeFromEntity(entity, playerIndex)
    if (recipe) then
        if entity.type:find("lab") then
            production.craftingSpeed = 1
            production.productCraftingTime = recipe.energy / 60 --ticks to seconds
        elseif entity.type:find("mining%-drill") then
            production.craftingSpeed = entity.prototype.mining_speed
            production.productCraftingTime = 1 --confirm?
        elseif entity.type:find("pumpjack") then
            production.craftingSpeed = entity.miningTarget.amount
            production.productCraftingTime = 1 / 30000
        elseif entity.type:find("assembling%-machine") or entity.type:find("furnace") or entity.type:find("rocket%-silo") then
            production.craftingSpeed = entity.prototype.crafting_speed
            production.productCraftingTime = recipe.energy
        end
        for i = 1, #recipe.ingredients do
            local ing = recipe.ingredients[i]
            production.summary_ingredients[i] = {
                name = ing.name,
                spritePath = ing.type .. "/" .. ing.name,
                amount = ing.extra or ing.amount or ing.amount_max,
                type = ing.type
            }
        end
        for i = 1, #recipe.products do
            local ing = recipe.products[i]
            production.summary_products[i] = {
                name = ing.name,
                spritePath = ing.type .. "/" .. ing.name,
                amount = ing.extra or ing.amount or ing.amount_max,
                type = ing.type
            }
        end

        --Calculate crafting speed with bonuses
        production.craftingSpeed = production.craftingSpeed + (production.craftingSpeed * production.effects.speed.bonus)
        production.productsPerSecond = production.craftingSpeed / production.productCraftingTime

        --Calculate Production bonus
        production.productsPerSecond = production.productsPerSecond + (production.productsPerSecond * production.effects.productivity.bonus)
        --Recipe's energy is exactly its crafting time in seconds, when crafted in an assembling machine with crafting speed exactly equal to one.
        return production
    else
        return nil
    end
end

function getRecipeFromCraftingMachine(entity)
    if entity.type:find("assembling%-machine") or entity.type:find("furnace") or entity.type:find("rocket%-silo") then
        return entity.get_recipe()
    end
    return nil
end

function getRecipeFromOutput(entity)
    if (entity.get_output_inventory()) then
        for item, _ in pairs(entity.get_output_inventory().get_contents()) do --can get several *oil*?
            return game.recipe_prototypes[item]
        end
    end
    return nil
end

function getRecipeFromFurnace(entity)
    if entity.type == "furnace" then
        return entity.previous_recipe
    else
        return nil
    end
end

function getRecipeFromMiningDrill(entity)
    local recipe
    if entity.type:find("mining%-drill") then
        local miningTarget = entity.mining_target
        if miningTarget then
            recipe = {
                name = miningTarget.name,
                energy = entity.prototype.mining_speed,
                localised_name = miningTarget.localised_name,
                products = miningTarget.prototype.mineable_properties.products,
                ingredients = {}
            }
            if miningTarget.prototype.mineable_properties.fluid_amount then
                recipe.ingredients = {
                    {
                        name = miningTarget.prototype.mineable_properties.required_fluid,
                        amount = miningTarget.prototype.mineable_properties.fluid_amount / 10,
                        type = "fluid"
                    }
                }
            end
            if entity.name:find("pumpjack") then
                recipe.products[1].extra = (miningTarget.amount / 30000)
            end
            return recipe
        end
    end
    return nil
end

function getRecipeFromLab(entity, playerIndex)
    if (entity.type:find("lab")) then
        recipe = nil
        research = game.players[playerIndex].force.current_research
        if (research) then
            recipe = {
                name = "research",
                type = "research",
                ingredients = research.research_unit_ingredients,
                products = {},
                energy = research.research_unit_energy or 0
            }

            for i = 1, #recipe.ingredients do
                recipe.ingredients[i].amount = recipe.ingredients[i].amount * research.research_unit_count
            end
        end
        return recipe
    else
        return nil
    end
end

--Gets the currently crafting recipe
function getRecipeFromEntity(entity, playerIndex)
    return getRecipeFromOutput(entity) or getRecipeFromMiningDrill(entity) or getRecipeFromFurnace(entity) or getRecipeFromLab(entity, playerIndex) or
        getRecipeFromCraftingMachine(entity)
end

return ACT
