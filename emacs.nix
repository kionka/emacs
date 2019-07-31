{ pkgs, ... }:

{
  home.file."./.emacs.d/init.el".source = ./init.el;
  programs.emacs.enable = true;
  programs.emacs.extraPackages = epkgs: [
    epkgs.general
    epkgs.use-package
    epkgs.general
    epkgs.nix-sandbox
    epkgs.flycheck
    epkgs.haskell-mode
    epkgs.dante
    epkgs.hindent
  ];
}
