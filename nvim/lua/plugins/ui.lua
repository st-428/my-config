return {
  -- 設定主題為透明
  {
    "folke/tokyonight.nvim",
    lazy = false,
    opts = {
      style = "storm", -- 或者 "moon", "night"
      transparent = true, -- 核心：開啟透明背景
      styles = {
        sidebars = "transparent", -- 側邊欄透明
        floats = "transparent", -- 浮動視窗透明
      },
    },
  },
}
