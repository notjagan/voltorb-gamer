require("solver")

LEFT_BOARD_PIXEL = 10
TOP_BOARD_PIXEL = 10
BOARD_OFFSET = 32
BOARD_WIDTH = 5
BOARD_HEIGHT = 5
BOTTOM_DIALOG_PIXEL = 189
LEFT_DIALOG_PIXEL = 3
DIALOG_OUTLINE_COLOR = { 74, 66, 66 }
CURSOR_COLOR = { 255, 66, 49 }
COLUMN_SUM_TENS_LEFT_PIXEL = 17
COLUMN_SUM_TENS_TOP_PIXEL = 168
COLUMN_SUM_ONES_LEFT_PIXEL = 25
COLUMN_SUM_ONES_TOP_PIXEL = 168
COLUMN_VOLTORBS_LEFT_PIXEL = 25
COLUMN_VOLTORBS_TOP_PIXEL = 181
ROW_SUM_TENS_LEFT_PIXEL = 177
ROW_SUM_TENS_TOP_PIXEL = 8
ROW_SUM_ONES_LEFT_PIXEL = 185
ROW_SUM_ONES_TOP_PIXEL = 8
ROW_VOLTORBS_LEFT_PIXEL = 185
ROW_VOLTORBS_TOP_PIXEL = 21
NUMBER_COLOR = { 66, 66, 66 }
PLAY_CURSOR_RIGHT_PIXEL = 250
PLAY_CURSOR_TOP_PIXEL = 70
PLAY_CURSOR_COLOR = { 255, 0, 0 }


local function save_image(path, x, y, size_x, size_y)
    local file = assert(io.open(path, "wb"))
    file:write(string.char(size_x), string.char(size_y))
    for i = x, x + size_x - 1 do
        for j = y, y + size_y - 1 do
            local r, g, b = gui.getpixel(i, j)
            file:write(string.char(r), string.char(g), string.char(b))
        end
    end
    file:close()
end

local function save_mask(path, x, y, size_x, size_y, color)
    local file = assert(io.open(path, "wb"))
    file:write(string.char(size_x), string.char(size_y))
    local r, g, b = unpack(color)
    for i = x, x + size_x - 1 do
        for j = y, y + size_y - 1 do
            local game_r, game_g, game_b = gui.getpixel(i, j)
            if game_r == r and game_g == g and game_b == b then
                file:write(string.char(1))
            else
                file:write(string.char(0))
            end
        end
    end
    file:close()
end

local function read_byte(file)
    return string.byte(file:read(1))
end

local function load_image(path)
    local file = assert(io.open(path, "rb"))
    local size_x, size_y = read_byte(file), read_byte(file)
    local image = {}
    for i = 1, size_x do
        image[i] = {}
        for j = 1, size_y do
            image[i][j] = { read_byte(file), read_byte(file), read_byte(file) }
        end
    end
    file:close()
    return image
end

local function load_mask(path)
    local file = assert(io.open(path, "rb"))
    local size_x, size_y = read_byte(file), read_byte(file)
    local mask = {}
    for i = 1, size_x do
        mask[i] = {}
        for j = 1, size_y do
            mask[i][j] = read_byte(file) == 1
        end
    end
    file:close()
    return mask
end

local function match_image(image, x, y)
    for i, row in ipairs(image) do
        for j, color in ipairs(row) do
            local r, g, b = unpack(color)
            local game_r, game_g, game_b = gui.getpixel(x + i - 1, y + j - 1)
            if game_r ~= r and game_g ~= g and game_b ~= b then
                return false
            end
        end
    end
    return true
end

local function match_mask(mask, color, x, y)
    local r, g, b = unpack(color)
    for i, row in ipairs(mask) do
        for j, flag in ipairs(row) do
            local game_r, game_g, game_b = gui.getpixel(x + i - 1, y + j - 1)
            if flag ~= (game_r == r and game_g == g and game_b == b) then
                return false
            end
        end
    end
    return true
end

X1_SPRITE = load_image("res/tiles/x1")
X2_SPRITE = load_image("res/tiles/x2")
X3_SPRITE = load_image("res/tiles/x3")
VOLTORB_SPRITE = load_image("res/tiles/voltorb")
NUMBER_SPRITES = {}
for i = 0, 9 do
    NUMBER_SPRITES[i] = load_mask("res/numbers/" .. i)
end

local function get_board_value(i, j)
    local x, y = LEFT_BOARD_PIXEL + BOARD_OFFSET * (i - 1), TOP_BOARD_PIXEL + BOARD_OFFSET * (j - 1)
    if match_image(X1_SPRITE, x, y) then
        return 1
    elseif match_image(X2_SPRITE, x, y) then
        return 2
    elseif match_image(X3_SPRITE, x, y) then
        return 3
    elseif match_image(VOLTORB_SPRITE, x, y) then
        return 4
    else
        return nil
    end
end

local function is_dialog_active()
    local game_r, game_g, game_b = gui.getpixel(LEFT_DIALOG_PIXEL, BOTTOM_DIALOG_PIXEL)
    local r, g, b = unpack(DIALOG_OUTLINE_COLOR)
    return game_r == r and game_g == g and game_b == b
end

local function has_cursor(i, j)
    local x, y = LEFT_BOARD_PIXEL + BOARD_OFFSET * (i - 1) - 2, TOP_BOARD_PIXEL + BOARD_OFFSET * (j - 1) - 2
    local game_r, game_g, game_b = gui.getpixel(x, y)
    local r, g, b = unpack(CURSOR_COLOR)
    return game_r == r and game_g == g and game_b == b
end

local function get_cursor_position()
    for i = 1, BOARD_HEIGHT do
        for j = 1, BOARD_WIDTH do
            if has_cursor(i, j) then
                return i, j
            end
        end
    end
    return nil
end

local function get_digit(x, y)
    for number = 0, 9 do
        if match_mask(NUMBER_SPRITES[number], NUMBER_COLOR, x, y) then
            return number
        end
    end
end

local function get_column_sums()
    local sums = {}
    for i = 1, BOARD_WIDTH do
        local ones = get_digit(COLUMN_SUM_ONES_LEFT_PIXEL + BOARD_OFFSET * (i - 1), COLUMN_SUM_ONES_TOP_PIXEL)
        local tens = get_digit(COLUMN_SUM_TENS_LEFT_PIXEL + BOARD_OFFSET * (i - 1), COLUMN_SUM_TENS_TOP_PIXEL) or 0
        if ones ~= nil then
            sums[i] = 10 * tens + ones
        end
    end
    return sums
end

local function get_row_sums()
    local sums = {}
    for j = 1, BOARD_HEIGHT do
        local ones = get_digit(ROW_SUM_ONES_LEFT_PIXEL, ROW_SUM_ONES_TOP_PIXEL + BOARD_OFFSET * (j - 1))
        local tens = get_digit(ROW_SUM_TENS_LEFT_PIXEL, ROW_SUM_TENS_TOP_PIXEL + BOARD_OFFSET * (j - 1)) or 0
        if ones ~= nil then
            sums[j] = 10 * tens + ones
        end
    end
    return sums
end

local function get_column_voltorbs()
    local sums = {}
    for i = 1, BOARD_WIDTH do
        sums[i] = get_digit(COLUMN_VOLTORBS_LEFT_PIXEL + BOARD_OFFSET * (i - 1), COLUMN_VOLTORBS_TOP_PIXEL)
    end
    return sums
end

local function get_row_voltorbs()
    local sums = {}
    for j = 1, BOARD_HEIGHT do
        sums[j] = get_digit(ROW_VOLTORBS_LEFT_PIXEL, ROW_VOLTORBS_TOP_PIXEL + BOARD_OFFSET * (j - 1))
    end
    return sums
end

local function press(key, duration, delay)
    duration = duration or 2
    delay = delay or 5
    if joypad.get()[key] then
        joypad.set({ [key] = false })
    end
    joypad.set({ [key] = true })
    for _ = 1, duration do
        emu.frameadvance()
    end
    joypad.set({ [key] = false })
    for _ = 1, delay do
        emu.frameadvance()
    end
end

local function move_cursor(i, j)
    local x, y = get_cursor_position()
    if x == nil then
        return false
    end
    while x ~= i do
        if x > i then
            press("left")
        else
            press("right")
        end
        x, y = get_cursor_position()
        if x == nil then
            return false
        end
    end
    while y ~= j do
        if y > j then
            press("up")
        else
            press("down")
        end
        x, y = get_cursor_position()
        if x == nil then
            return false
        end
    end
    return true
end

local function is_board_revealed()
    for i = 1, BOARD_WIDTH do
        for j = 1, BOARD_WIDTH do
            if not get_board_value(i, j) then
                return false
            end
        end
    end
    return true
end

local function is_play_button_active()
    local game_r, game_g, game_b = gui.getpixel(PLAY_CURSOR_RIGHT_PIXEL, PLAY_CURSOR_TOP_PIXEL)
    local r, g, b = unpack(PLAY_CURSOR_COLOR)
    return game_r == r and game_g == g and game_b == b
end

local function play_round()
    while true do
        if is_dialog_active() or is_board_revealed() then
            press("A")
        elseif #get_column_voltorbs() == 0 or get_cursor_position() == nil then
            emu.frameadvance()
        else
            break
        end
    end

    local co = Solve(get_column_sums(), get_row_sums(), get_column_voltorbs(), get_row_voltorbs())
    local code, result = coroutine.resume(co)
    while code do
        if type(result) == "boolean" then
            break
        end

        local j, i = unpack(result)
        while get_cursor_position() == nil do
            emu.frameadvance()
        end
        if not move_cursor(i, j) then
            break
        end
        press("A")

        local complete = false
        while get_board_value(i, j) == nil do
            press("A")
            emu.frameadvance()
            if is_board_revealed() then
                complete = true
            end
        end
        if complete then
            break
        end

        local value = get_board_value(i, j)
        for _ = 1, 10 do
            emu.frameadvance()
        end

        while is_dialog_active() do
            press("A")
            if is_board_revealed() then
                complete = true
            end
        end
        if complete then
            break
        end

        code, result = coroutine.resume(co, value)
    end
end

while true do
    play_round()
    while not is_play_button_active() do
        press("A")
    end
end
