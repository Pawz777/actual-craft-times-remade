local ACT = {}

function ACT.getProductionNumbersForEntity(entity, playerIndex)
    local production = {
        ingredients = {},
        products = {},
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
    local recipe = ACT.getRecipeFromEntity(entity,playerIndex)
    if (recipe) then
        if entity.type:find("lab") then
            --spritePath = spriteCheck(player, "technology/" .. recipe.name)
            production.craftingSpeed = 1
            production.productCraftingTime = recipe.research_unit_energy / 60 --ticks to seconds
        else
        if entity.type:find("mining%-drill") then
            --spritePath = spriteCheck(player, "entity/" .. recipe.name)
            production.craftingSpeed = entity.prototype.mining_speed
            production.productCraftingTime = 1 --confirm?
        elseif entity.type:find("pumpjack") then
            production.craftingSpeed = entity.miningTarget.amount
            production.productCraftingTime = 1 / 30000
        elseif entity.type:find("assembling%-machine") or entity.type:find("furnace") or entity.type:find("rocket%-silo") then
            production.craftingSpeed = entity.prototype.crafting_speed
            production.productCraftingTime = recipe.energy
        --spritePath = spriteCheck(player, "recipe/" .. recipe.name)
        end
        production.ingredients = recipe.ingredients
        production.products = recipe.products
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

function getRecipe(entity)
    return entity.get_recipe() or getRecipeFromOutput(entity) or getRecipeFromFurnace(entity)
end

function getRecipeFromOutput(entity)
    for item, _ in pairs(entity.get_output_inventory().get_contents()) do --can get several *oil*?
        return game.recipe_prototypes[item]
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

function ACT.writeRecipe(recipePrototype)
    local recipe = {}
    recipe.name = recipePrototype.name or nil
    recipe.energy = recipePrototype.energy or nil
    recipe.localised_name = recipePrototype.localised_name or nil
    recipe.products = recipePrototype.products or nil
    recipe.ingredients = recipePrototype.ingredients or nil
    --recipe.type = recipePrototype.type or nil
    return serpent.block(recipe)
end

--Gets the currently crafting recipe
function ACT.getRecipeFromEntity(entity, playerIndex)
    local recipe
    if entity.type:find("lab") then
        recipe = nil --game.players[playerIndex].force.current_research
    elseif entity.type:find("mining%-drill") then
        local miningTarget = entity.mining_target
        if miningTarget then
            recipe = {
                name = miningTarget.name,
                energy = entity.prototype.mining_speed,
                localised_name = miningTarget.localised_name,
                products = miningTarget.prototype.mineable_properties.products
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
        end
    elseif entity.type:find("assembling%-machine") or entity.type:find("furnace") or entity.type:find("rocket%-silo") then
        recipe = getRecipe(entity)
    end
    return recipe
end

return ACT
