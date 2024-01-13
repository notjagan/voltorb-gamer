VOLTORB = 4
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

local function lookup_key(rows, columns, column_totals, row_totals, column_voltorbs, row_voltorbs, max_value)
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

local function new_lookup()
    local lookup = {}
    setmetatable(lookup, { __mode = "v" })
    return lookup
end

local function search_helper(rows, columns, column_totals, row_totals, column_voltorbs, row_voltorbs, max_value, lookup)
    local key = lookup_key(rows, columns, column_totals, row_totals, column_voltorbs, row_voltorbs, max_value)
    local ret = lookup[key]
    if ret ~= nil then
        return ret
    end

    local probs = {}
    for _ = 1, rows do
        local row = {}
        table.insert(probs, row)
        for _ = 1, columns do
            local values = {}
            table.insert(row, values)
            for value = 1, max_value do
                values[value] = 0
            end
            values[VOLTORB] = 0
        end
    end

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
        for row in IterCombinations(columns, total, voltorbs, max_value) do
            local new_column_totals = { unpack(column_totals) }
            local new_column_voltorbs = { unpack(column_voltorbs) }
            for i, value in ipairs(row) do
                if value == VOLTORB then
                    new_column_voltorbs[i] = new_column_voltorbs[i] - 1
                else
                    new_column_totals[i] = new_column_totals[i] - value
                end
            end
            local result = search_helper(
                rows - 1,
                columns,
                new_column_totals,
                row_totals,
                new_column_voltorbs,
                row_voltorbs,
                max_value,
                lookup
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
        for column in IterCombinations(rows, total, voltorbs, max_value) do
            local new_row_totals = { unpack(row_totals) }
            local new_row_voltorbs = { unpack(row_voltorbs) }
            for i, value in ipairs(column) do
                if value == VOLTORB then
                    new_row_voltorbs[i] = new_row_voltorbs[i] - 1
                else
                    new_row_totals[i] = new_row_totals[i] - value
                end
            end
            local result = search_helper(rows,
                columns - 1,
                column_totals,
                new_row_totals,
                column_voltorbs,
                new_row_voltorbs,
                max_value,
                lookup
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
        lookup[key] = false
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

    lookup[key] = probs
    return probs
end
