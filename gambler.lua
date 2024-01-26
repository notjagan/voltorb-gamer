LEFT_BOARD_PIXEL = 10
TOP_BOARD_PIXEL = 10
BOARD_OFFSET = 32

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

local function match_image(image, x, y)
    for i, row in ipairs(image) do
        for j, color in ipairs(row) do
            local r, g, b = unpack(color)
            local game_r, game_g, game_b = gui.getpixel(x + i - 1, y + j - 1)
            if r ~= game_r or g ~= game_g or b ~= game_b then
                return false
            end
        end
    end
    return true
end

SPRITE_X1 = load_image("res/x1")
SPRITE_X2 = load_image("res/x2")
SPRITE_X3 = load_image("res/x3")
SPRITE_VOLTORB = load_image("res/voltorb")

local function get_board_value(i, j)
    local x, y = LEFT_BOARD_PIXEL + BOARD_OFFSET * (i - 1), TOP_BOARD_PIXEL + BOARD_OFFSET * (j - 1)
    if match_image(SPRITE_X1, x, y) then
        return 1
    elseif match_image(SPRITE_X2, x, y) then
        return 2
    elseif match_image(SPRITE_X3, x, y) then
        return 3
    elseif match_image(VOLTORB, x, y) then
        return 4
    else
        return nil
    end
end
