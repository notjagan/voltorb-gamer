VOLTORB = 0
DEFAULT_MAX_VALUE = 3

function IterCombinations(length, total, voltorbs, max_value)
    return coroutine.wrap(function()
        if total < 0 or voltorbs < 0 then
            return
        end

        if length == 1 then
            if 0 < total and total <= max_value and voltorbs == 0 then
                coroutine.yield({ total })
            elseif total == 0 and voltorbs == 1 then
                coroutine.yield({ VOLTORB })
            else
                return
            end
        else
            for value = 1, max_value do
                for combo in IterCombinations(length - 1, total - value, voltorbs, max_value) do
                    table.insert(combo, value)
                    coroutine.yield(combo)
                end
            end
            for combo in IterCombinations(length - 1, total, voltorbs - 1, max_value) do
                table.insert(combo, VOLTORB)
                coroutine.yield(combo)
            end
        end
    end)
end
