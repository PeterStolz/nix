{ pkgs, ... }:

{
  enable = true;
  viAlias = true;
  vimAlias = true;
  withNodeJs = true;
  withPython3 = true;
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
  plugins = with pkgs.vimPlugins; [
    gruvbox
    vim-terraform
    coc-nvim # Optional for other language support, if needed
    nvim-lspconfig # Essential for LSP support
    nvim-cmp # Optional, for autocompletion
    cmp-nvim-lsp # Optional, integrates LSP with nvim-cmp
    coc-pyright
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
}
