DEFAULT_MAX_VALUE = 3
VOLTORB = 4

local function iter_combinations(length, total, voltorbs, max_value, mask)
    return coroutine.wrap(function()
        if total < 0 or voltorbs < 0 then
            return
        end

        if length == 1 then
            local flags = unpack(mask)
            if 0 < total and total <= max_value and voltorbs == 0 and flags[total] then
                coroutine.yield { total }
            elseif total == 0 and voltorbs == 1 and flags[VOLTORB] then
                coroutine.yield { VOLTORB }
            else
                return
            end
        else
            local flags = mask[#mask]
            local tail = { unpack(mask, 1, #mask - 1) }
            for value = 1, max_value do
                if flags[value] then
                    for combo in iter_combinations(length - 1, total - value, voltorbs, max_value, tail) do
                        table.insert(combo, value)
                        coroutine.yield(combo)
                    end
                end
            end
            if flags[VOLTORB] then
                for combo in iter_combinations(length - 1, total, voltorbs - 1, max_value, tail) do
                    table.insert(combo, VOLTORB)
                    coroutine.yield(combo)
                end
            end
        end
    end)
end

local function cache_key(rows, columns, column_totals, row_totals, column_voltorbs, row_voltorbs, max_value)
    local key = rows .. "," .. columns .. "," .. max_value
    for _, total in ipairs(column_totals) do
        key = key .. "," .. total
    end
    for _, total in ipairs(row_totals) do
        key = key .. "," .. total
    end
    for _, voltorbs in ipairs(column_voltorbs) do
        key = key .. "," .. voltorbs
    end
    for _, voltorbs in ipairs(row_voltorbs) do
        key = key .. "," .. voltorbs
    end

    return key
end

local function create_cache()
    local lookup = {}
    setmetatable(lookup, { __mode = "v" })
    return lookup
end


local function create_mask(rows, columns, max_value, fill)
    local mask = {}
    for i = 1, rows do
        mask[i] = {}
        for j = 1, columns do
            mask[i][j] = {}
            for value = 1, max_value do
                mask[i][j][value] = fill
            end
            mask[i][j][VOLTORB] = fill
        end
    end

    return mask
end

local function solve_helper(
    rows,
    columns,
    column_totals,
    row_totals,
    column_voltorbs,
    row_voltorbs,
    max_value,
    cache,
    mask
)
    local key = cache_key(
        rows,
        columns,
        column_totals,
        row_totals,
        column_voltorbs,
        row_voltorbs,
        max_value
    )
    local ret = cache[key]
    if ret ~= nil then
        return ret
    end

    local probs = create_mask(rows, columns, max_value, 0)
    local any = false
    if rows == 1 and columns == 1 then
        local column_total = unpack(column_totals)
        local row_total = unpack(row_totals)
        local column_voltorb = unpack(column_voltorbs)
        local row_voltorb = unpack(row_voltorbs)
        if
            column_total == row_total
            and column_total >= 0
            and column_total <= max_value
            and column_voltorb == row_voltorb
            and column_voltorb >= 0
            and column_voltorb <= 1
        then
            local total = column_total
            local voltorbs = column_voltorb
            if total > 0 and voltorbs == 0 then
                probs[1][1][total] = 1
                any = true
            elseif total == 0 and voltorbs > 0 then
                probs[1][1][VOLTORB] = 1
                any = true
            end
        end
    elseif rows >= columns then
        local total = row_totals[1]
        row_totals = { unpack(row_totals, 2) }
        local voltorbs = row_voltorbs[1]
        row_voltorbs = { unpack(row_voltorbs, 2) }
        local row_mask = mask[1]
        mask = { unpack(mask, 2) }
        for row in iter_combinations(columns, total, voltorbs, max_value, row_mask) do
            local new_column_totals = { unpack(column_totals) }
            local new_column_voltorbs = { unpack(column_voltorbs) }
            for i, value in ipairs(row) do
                if value == VOLTORB then
                    new_column_voltorbs[i] = new_column_voltorbs[i] - 1
                else
                    new_column_totals[i] = new_column_totals[i] - value
                end
            end
            local result = solve_helper(
                rows - 1,
                columns,
                new_column_totals,
                row_totals,
                new_column_voltorbs,
                row_voltorbs,
                max_value,
                cache,
                mask
            )

            if result then
                for j, value in ipairs(row) do
                    probs[1][j][value] = probs[1][j][value] + 1
                end
                for i, result_row in ipairs(result) do
                    for j, values in ipairs(result_row) do
                        for value, probability in ipairs(values) do
                            probs[i + 1][j][value] = probs[i + 1][j][value] + probability
                        end
                    end
                end
                any = true
            end
        end
    else
        local total = column_totals[1]
        column_totals = { unpack(column_totals, 2) }
        local voltorbs = column_voltorbs[1]
        column_voltorbs = { unpack(column_voltorbs, 2) }
        local column_mask = {}
        local new_mask = {}
        for i, row_mask in ipairs(mask) do
            column_mask[i] = row_mask[1]
            new_mask[i] = { unpack(row_mask, 2) }
        end
        mask = new_mask
        for column in iter_combinations(rows, total, voltorbs, max_value, column_mask) do
            local new_row_totals = { unpack(row_totals) }
            local new_row_voltorbs = { unpack(row_voltorbs) }
            for i, value in ipairs(column) do
                if value == VOLTORB then
                    new_row_voltorbs[i] = new_row_voltorbs[i] - 1
                else
                    new_row_totals[i] = new_row_totals[i] - value
                end
            end
            local result = solve_helper(
                rows,
                columns - 1,
                column_totals,
                new_row_totals,
                column_voltorbs,
                new_row_voltorbs,
                max_value,
                cache,
                mask
            )

            if result then
                for i, value in ipairs(column) do
                    probs[i][1][value] = probs[i][1][value] + 1
                end
                for i, result_row in ipairs(result) do
                    for j, values in ipairs(result_row) do
                        for value, probability in ipairs(values) do
                            probs[i][j + 1][value] = probs[i][j + 1][value] + probability
                        end
                    end
                end
                any = true
            end
        end
    end

    if not any then
        cache[key] = false
        return false
    end

    for _, row in ipairs(probs) do
        for _, values in ipairs(row) do
            local sum = 0
            for _, prob in ipairs(values) do
                sum = sum + prob
            end
            for value, prob in ipairs(values) do
                values[value] = prob / sum
            end
        end
    end

    cache[key] = probs
    return probs
end

function Solve(column_totals, row_totals, column_voltorbs, row_voltorbs, max_value)
    max_value = max_value or DEFAULT_MAX_VALUE
    assert(#column_totals == #column_voltorbs)
    assert(#row_totals == #row_voltorbs)
    local rows = #column_totals
    local columns = #row_totals
    local mask = create_mask(rows, columns, max_value, true)
    local knowns = {}
    for i = 1, rows do
        knowns[i] = {}
    end

    return coroutine.create(function()
        while true do
            local cache = create_cache()
            local probs = solve_helper(
                rows,
                columns,
                column_totals,
                row_totals,
                column_voltorbs,
                row_voltorbs,
                max_value,
                cache,
                mask
            )
            if not probs then
                return false
            end

            local min_chance = 1
            local min = { 1, 1 }
            local all_known = true
            for i, row in ipairs(probs) do
                for j, values in ipairs(row) do
                    for value, prob in ipairs(values) do
                        if prob == 0 then
                            mask[i][j][value] = false
                        end
                    end
                    if values[VOLTORB] < min_chance and not knowns[i][j] then
                        min_chance = values[VOLTORB]
                        min = { i, j }
                    end
                    if not knowns[i][j] then
                        all_known = false
                    end
                end
            end

            if all_known then
                return true
            end

            local flip = coroutine.yield({ min, min_chance })
            if flip == VOLTORB then
                return false
            end
            local i, j = unpack(min)
            knowns[i][j] = true
            for value, _ in ipairs(mask[i][j]) do
                mask[i][j][value] = value == flip
            end
        end
    end)
end
