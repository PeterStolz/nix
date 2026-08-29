{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.detesiaSkills;
  repoPath = cfg.checkoutPath;
  skills = [
    "communications"
    "detesia-observability"
    "detesia-pipedrive"
    "hermes-docs"
  ];
  legacySkills = skills ++ [
    "transcribe-call"
    "update-prod"
  ];

  skillLinks = lib.listToAttrs (
    lib.concatMap (
      skill:
      map
        (root: {
          name = "${root}/${skill}";
          value.source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/${skill}";
        })
        [
          ".agents/skills"
          ".claude/skills"
        ]
    ) skills
  );
in
{
  options.local.detesiaSkills = {
    enable = lib.mkEnableOption "Detesia shared agent skills" // {
      default = true;
    };

    checkoutPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/detesia/repos/skills";
      description = ''
        Mutable, per-user checkout of the private Detesia/skills repository.
        The checkout stays outside the Nix store so its contents and GitHub
        authentication remain subject to the user's normal home permissions.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = skillLinks;

    home.activation.detesiaSkillsCheckout = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      repo=${lib.escapeShellArg repoPath}
      parent="$(${pkgs.coreutils}/bin/dirname "$repo")"

      if [[ -e "$repo" && ! -d "$repo/.git" ]]; then
        echo "Detesia skills checkout path exists but is not a Git repository: $repo" >&2
        exit 1
      fi

      if [[ ! -d "$repo/.git" ]]; then
        ${pkgs.coreutils}/bin/mkdir -p "$parent"
        echo "Cloning Detesia/skills into $repo"
        PATH=${
          lib.escapeShellArg (
            lib.makeBinPath [
              pkgs.git
              pkgs.openssh
            ]
          )
        } ${pkgs.gh}/bin/gh repo clone Detesia/skills "$repo" -- --branch main
      else
        remote="$(${pkgs.git}/bin/git -C "$repo" remote get-url origin)"
        case "$remote" in
          https://github.com/Detesia/skills|https://github.com/Detesia/skills.git|git@github.com:Detesia/skills.git)
            ;;
          *)
            echo "Refusing to update unexpected Detesia skills remote: $remote" >&2
            exit 1
            ;;
        esac

        branch="$(${pkgs.git}/bin/git -C "$repo" branch --show-current)"
        status="$(${pkgs.git}/bin/git -C "$repo" status --porcelain)"
        if [[ "$branch" != main ]]; then
          echo "Detesia skills checkout is on $branch; leaving it unchanged" >&2
        elif [[ -n "$status" ]]; then
          echo "Detesia skills checkout has local changes; leaving it unchanged" >&2
        elif ! ${pkgs.git}/bin/git -C "$repo" fetch --quiet origin main; then
          echo "Could not refresh Detesia skills; using the existing checkout" >&2
        elif ! ${pkgs.git}/bin/git -C "$repo" merge --quiet --ff-only origin/main; then
          echo "Detesia skills checkout has diverged from origin/main" >&2
          exit 1
        fi
      fi

      for skill in ${lib.escapeShellArgs skills}; do
        if [[ ! -f "$repo/$skill/SKILL.md" ]]; then
          echo "Detesia skill is missing SKILL.md: $repo/$skill" >&2
          exit 1
        fi
      done

      for skill in ${lib.escapeShellArgs legacySkills}; do
        legacy="$HOME/.codex/skills/$skill"
        if [[ -L "$legacy" && "$(${pkgs.coreutils}/bin/readlink "$legacy")" == "$repo/$skill" ]]; then
          echo "Removing installer-owned legacy skill link: $legacy"
          ${pkgs.coreutils}/bin/rm "$legacy"
        fi
      done
    '';
  };
}
