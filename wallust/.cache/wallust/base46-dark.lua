local M = {}

local lighten = require("base46.colors").change_hex_lightness

M.base_30 = {
  white = "#E2DDD2",
  darker_black = lighten("#3A3A3A", -3),
  black = "#3A3A3A",
  black2 = lighten("#3A3A3A", 6),
  one_bg = lighten("#3A3A3A", 10),
  grey = lighten("#3A3A3A", 40),
  light_grey = "#9E9A93",
  red = "#434545",
  baby_pink = "#464849",
  pink = "#A5C6DD",
  line = "#9E9A93",
  green = "#4E5454",
  vibrant_green = "#4E5454",
  nord_blue = "#529A9D",
  blue = "#529A9D",
  yellow = "#5790A6",
  sun = lighten("#5790A6", 6),
  purple = "#A5C6DD",
  dark_purple = "#A5C6DD",
  teal = "#529A9D",
  orange = "#434545",
  cyan = "#529A9D",
  pmenu_bg = "#9E9A93",
  folder_bg = "#529A9D",
}

M.base_30.statusline_bg = M.base_30.black2
M.base_30.lightbg = M.base_30.one_bg
M.base_30.one_bg2 = lighten(M.base_30.one_bg, 6)
M.base_30.one_bg3 = lighten(M.base_30.one_bg2, 6)
M.base_30.grey_fg = lighten(M.base_30.grey, 10)
M.base_30.grey_fg2 = lighten(M.base_30.grey, 5)

M.base_16 = {
  base00 = "#3A3A3A",
  base01 = "#3A3A3A",
  base02 = "#9E9A93",
  base03 = "#9E9A93",
  base04 = "#E2DDD2",
  base05 = "#E2DDD2",
  base06 = "#E2DDD2",
  base07 = "#E2DDD2",
  base08 = "#434545",
  base09 = "#4E5454",
  base0A = "#5790A6",
  base0B = "#529A9D",
  base0C = "#7C94A6",
  base0D = "#A19888",
  base0E = "#434545",
  base0F = "#E2DDD2",
}

M.type = "dark"

M.polish_hl = {
  Operator = {
    fg = M.base_30.nord_blue,
  },

  ["@operator"] = {
    fg = M.base_30.nord_blue,
  },
}

return M
