{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    # New default as of 26.05; no ruby plugins here, so adopt it and drop the provider.
    withRuby = false;
    coc = {
      enable = true;
      settings = {
        "languageserver" = {
          "nix" = {
            "command" = "nil";
            "filetypes" = [ "nix" ];
            "rootPatterns" = [ "flake.nix" ];
            "settings" = {
              "nil" = {
                "formatting" = {
                  "command" = [ "nixfmt" ];
                };
              };
            };
          };
        };
      };
    };
    # coc is the only completion/LSP stack that is actually configured here.
    # nvim-lspconfig / nvim-cmp / cmp-nvim-lsp used to be listed too, but nothing
    # ever called their setup(), so they were loaded and inert.
    plugins = with pkgs.vimPlugins; [
      coc-nvim
      coc-pyright
      gruvbox
      vim-terraform
    ];
    extraConfig = ''
      set number relativenumber
      set tabstop=2 shiftwidth=2 expandtab
      syntax enable

      autocmd BufRead,BufNewFile Tiltfile set filetype=python
      autocmd BufNewFile,BufRead Dockerfile* set filetype=dockerfile

      set list listchars=eol:$
      colorscheme gruvbox
    '';
  };
}
