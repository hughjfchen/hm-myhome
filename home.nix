{ config, pkgs, ... }:

{

  imports = [ ];

  # turn off the check between home-manager and nixpkgs version
  # home.enableNixpkgsReleaseCheck = false;

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "chenjf";
  home.homeDirectory = "/home/chenjf";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # some utils
    pkgs.wget
    pkgs.ripgrep

    # some dev tools
    pkgs.shellcheck
    pkgs.nil
    pkgs.efm-langserver
    pkgs.pyright

    # some useful nix tools
    pkgs.nixfmt-rfc-style
    pkgs.nix-diff
    pkgs.nix-du
    pkgs.nix-index
    pkgs.nix-melt
    pkgs.nix-tree
    pkgs.nvd
    pkgs.statix
    pkgs.nix-output-monitor

    # nix doc
    pkgs.manix
    pkgs.nix-doc

    # nix tools written in haskell
    # pkgs.haskellPackages.nix-thunk
    # pkgs.haskellPackages.nix-graph
    # pkgs.haskellPackages.nix-narinfo
    # pkgs.haskellPackages.nix-derivation
    # pkgs.haskellPackages.nix-freeze-tree

    # my only editor
    pkgs.emacs-nox

    # and some graph tool
    pkgs.graphviz-nox
    pkgs.imagemagick
    pkgs.pikchr
    pkgs.plantuml

    # and the ONE plot tool
    pkgs.gnuplot

    # the ultimate document handling tool
    pkgs.pandoc

    # for java, and the ultimate text-based drawing tool, plantuml
    pkgs.jre

    # for rabbitmq AMQP
    #pkgs.rabtap

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    # smarter CD command
    pkgs.zoxide

    # Open tmux for current project.
    (pkgs.writeShellApplication {
      name = "pux";
      runtimeInputs = [ pkgs.tmux ];
      text = ''
        PRJ="''$(zoxide query -i)"
        echo "Launching tmux for ''$PRJ"
        set -x
        cd "''$PRJ" && \
          exec tmux -S "''$PRJ".tmux attach
      '';
    })

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    # to let me login with ssh
    # don't want to config ssh with home-manager because the key would be put under nix store
    # comment out for now.
    # ".ssh/authorized_keys" = {
    #   text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDouazcY0grLX8lAz/XrtDS1ZIo0s91BS7VrCKlzfRZtmcoI041vz+SBCCWbtnOMmWRFtA948aGtCN6EKD3JSREmrmJU1JfTIoekYzemdbjMbsTnIw0czP7weFtfFgdwhn8vro11k3uy0uG/32+aUYNUx+CNaDKulBRtg+oXRmjkrHCtapCHpN9/FMsvZjP0NbqVKtbf5Jem6Pqx8Himo3cZq3SKSYG8UIC/mAebEz793M5rR4FSvzXlfgiwCBn07F3+0rQAL6ZtsNEE521iJyU88tk6VsewPsZNvguCY21y3eKGYsny+ITMfR4liZjToIkrJGt3l7EMJawsAUemMWz hugh.jf.chen@gmail.com";
    #   onChange = ''chmod 600 ~/.ssh/authorized_keys'';
    #};

    # my org template and the docx template for export
    "documents/template/org-template.org".source = ./resource/org/org-template.org;
    "documents/template/pandoc-reference.docx".source = ./resource/pandoc/pandoc-reference.docx;
    "documents/template/pandoc-filter-abstract-section.lua".source = ./resource/pandoc/pandoc-filter-abstract-section.lua;
    "documents/template/pandoc-filter-remove-header-attrs-when-convert-from-docx-to-org.lua".source = ./resource/pandoc/pandoc-filter-remove-header-attrs-when-convert-from-docx-to-org.lua;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/chenjf/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nano";
    TERM = "xterm-256color";
    LC_ALL = "C.UTF-8";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # let home-manager manage my shell
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      [[ -f ~/.oldbashrc ]] && . ~/.oldbashrc
    '';
    shellAliases = {
      ls = "ls --color=always";
      ll = "ls -l";
      ltr = "ls -ltr";
      ltra = "ls -ltra";
      hm = "cp -R ~/projects/hm-myhome/* ~/.config/home-manager/ ; home-manager";
      hms = "cp -R ~/projects/hm-myhome/* ~/.config/home-manager/ ; home-manager switch";
    };
  };

  programs.git = {
    enable = true;
    userName  = "Hugh JF Chen";
    userEmail = "hugh.jf.chen@gmail.com";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    newSession = true;
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];

    extraConfig = ''
      # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Mouse works as expected
      set-option -g mouse on
      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  programs.tmate = {
    enable = true;
    # FIXME: This causes tmate to hang.
    # extraConfig = config.xdg.configFile."tmux/tmux.conf".text;
  };

  # disable kanshi service
  services.kanshi.enable = false;
}
