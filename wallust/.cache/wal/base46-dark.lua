local M = {}

local lighten = require("base46.colors").change_hex_lightness

M.base_30 = {
  white = '#dee3e5',
  black = '#0e1416',
  darker_black = lighten('#0e1416', -3),
  black2 = lighten('#0e1416', 6),
  one_bg = lighten('#0e1416', 10),
  one_bg2 = lighten('#0e1416', 16),
  one_bg3 = lighten('#0e1416', 22),
  grey = '#3f484a',
  grey_fg = lighten('#3f484a', -10),
  grey_fg2 = lighten('#3f484a', -20),
  light_grey = '#899295',
  red = '#ffb4ab',
  baby_pink = lighten('#ffb4ab', 10),
  pink = '#bcc5eb',
  line = '#899295',
  green = '#b1cbd1',
  vibrant_green = lighten('#b1cbd1', 10),
  blue = '#82d3e3',
  nord_blue = lighten('#82d3e3', 10),
  yellow = lighten('#bcc5eb', 10),
  sun = lighten('#bcc5eb', 20),
  purple = '#bcc5eb',
  dark_purple = lighten('#bcc5eb', -10),
  teal = '#334b4f',
  orange = '#ffb4ab',
  cyan = '#b1cbd1',
  statusline_bg = lighten('#0e1416', 6),
  pmenu_bg = '#3f484a',
  folder_bg = lighten('#82d3e3', 0),
  lightbg = lighten('#0e1416', 10),
}

M.base_16 = {
  base00 = '#0e1416',
  base01 = lighten('#3f484a', 0),
  base02 = '#b1cbd1',
  base03 = lighten('#899295', 0),
  base04 = lighten('#bfc8ca', 0),
  base05 = '#dee3e5',
  base06 = lighten('#dee3e5', 0),
  base07 = '#0e1416',
  base08 = lighten('#ffb4ab', -10),
  base09 = '#bcc5eb',
  base0A = '#82d3e3',
  base0B = '#dbe1ff',
  base0C = '#82d3e3',
  base0D = lighten('#004e59', 20),
  base0E = '#a0efff',
  base0F = '#dee3e5',
}

M.type = "dark"  -- or "light" depending on your theme

M.polish_hl = {
  defaults = {
    Comment = {
      italic = true,
      fg = M.base_16.base03,
    },
  },
  Syntax = {
    String = {
      fg = '#bcc5eb'
    }
  },
  treesitter = {
    ["@comment"] = {
      fg = M.base_16.base03,
    },
    ["@string"] = {
      fg = '#bcc5eb'
    },
  }
}

return M
