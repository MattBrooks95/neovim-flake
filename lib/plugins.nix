let
  packDir = "$out/share/nvim/runtime/pack";
  colorSchemePackageDirName = "colorschemes";
  languageServerPackageDirName = "language-server";
  languagePluginsPackageDirName = "languages";
  vimPluginsPackageDirName = "vim-plugins";
  telescopeDirName = "telescope";
  nvim-lualineDirName = "nvim-lualine";
  nvim-web-deviconsDirName = "nvim-web-dev-icons";
  tree-sitterDirName = "tree-sitter";
in rec {
  #build paths for install phase by prepending $out for the derivation
  concatSlash = builtins.concatStringsSep "/";
  paths = {
    colorSchemePackageDir = concatSlash [packDir colorSchemePackageDirName "start"];
    languageServerPackageDir = concatSlash [packDir languageServerPackageDirName "start"];
    languagePackageDir = concatSlash [packDir languagePluginsPackageDirName "start"];
    vimPluginsPackageDir = concatSlash [packDir vimPluginsPackageDirName "start"];
    telescopePackageDir = concatSlash [packDir telescopeDirName"start"];
    lualinePackDir = concatSlash [packDir nvim-lualineDirName "start"];
    webdevIconsPackDir = concatSlash [packDir nvim-web-deviconsDirName "start"];
    treeSitterPackDir = concatSlash [packDir tree-sitterDirName "start"];
  };
}
