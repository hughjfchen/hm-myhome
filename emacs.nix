{ config, pkgs, ... }:

let

  pcfg = config.programs.emacs.init.usePackage;

in {
  imports = [ ./hmModules/emacs/emacs-init.nix ];

  home.file = {
  #  ".emacs.d/nxml-schemas".source = ./dotfiles/emacs/nxml-schemas;
    ".emacs.d/snippets".source = ./resource/emacs/snippets;
  };

  programs.emacs.init = {
    enable = true;
    packageQuickstart = false;
    recommendedGcSettings = true;
    usePackageVerbose = false;

    earlyInit = ''
      ;; Disable some GUI distractions. We set these manually to avoid starting
      ;; the corresponding minor modes.
      (push '(menu-bar-lines . 0) default-frame-alist)
      (push '(tool-bar-lines . nil) default-frame-alist)
      (push '(vertical-scroll-bars . nil) default-frame-alist)

      ;; Set up fonts early.
      (set-face-attribute 'default
                          nil
                          :height 80
                          :family "Fantasque Sans Mono")
      (set-face-attribute 'variable-pitch
                          nil
                          :family "DejaVu Sans")

      ;; Configure color theme and modeline in early init to avoid flashing
      ;; during start.
      ;; (require 'base16-theme)
      (load-theme 'tsdh-dark t)

      (require 'doom-modeline)
      (setq doom-modeline-buffer-file-name-style 'truncate-except-project)
      (doom-modeline-mode)
    '';

    prelude = ''
      ;; Disable startup message.
      (setq inhibit-startup-screen t
            inhibit-startup-echo-area-message (user-login-name))

      (setq initial-major-mode 'fundamental-mode
            initial-scratch-message nil)

      ;; Don't blink the cursor.
      (setq blink-cursor-mode nil)

      ;; Set frame title.
      (setq frame-title-format
            '("" invocation-name ": "(:eval
                                      (if (buffer-file-name)
                                          (abbreviate-file-name (buffer-file-name))
                                        "%b"))))

      ;; Make sure the mouse cursor is visible at all times.
      (set-face-background 'mouse "#ffffff")

      ;; Accept 'y' and 'n' rather than 'yes' and 'no'.
      (defalias 'yes-or-no-p 'y-or-n-p)

      ;; Don't want to move based on visual line.
      (setq line-move-visual nil)

      ;; Stop creating backup and autosave files.
      (setq make-backup-files nil
            auto-save-default nil)

      ;; Default is 4k, which is too low for LSP.
      (setq read-process-output-max (* 1024 1024))

      ;; Always show line and column number in the mode line.
      (line-number-mode)
      (column-number-mode)

      ;; Enable some features that are disabled by default.
      (put 'narrow-to-region 'disabled nil)

      ;; Typically, I only want spaces when pressing the TAB key. I also
      ;; want 4 of them.
      (setq-default indent-tabs-mode nil
                    tab-width 4
                    c-basic-offset 4)

      ;; Trailing white space are banned!
      (setq-default show-trailing-whitespace t)

      ;; Use one space to end sentences.
      (setq sentence-end-double-space nil)

      ;; I typically want to use UTF-8.
      (prefer-coding-system 'utf-8)

      ;; Nicer handling of regions.
      (transient-mark-mode 1)

      ;; Make moving cursor past bottom only scroll a single line rather
      ;; than half a page.
      (setq scroll-step 1
            scroll-conservatively 5)

      ;; Enable highlighting of current line.
      (global-hl-line-mode 1)

      ;; Improved handling of clipboard in GNU/Linux and otherwise.
      (setq select-enable-clipboard t
            select-enable-primary t
            save-interprogram-paste-before-kill t)

      ;; Pasting with middle click should insert at point, not where the
      ;; click happened.
      (setq mouse-yank-at-point t)

      ;; Enable a few useful commands that are initially disabled.
      (put 'upcase-region 'disabled nil)
      (put 'downcase-region 'disabled nil)

      (setq custom-file (locate-user-emacs-file "custom.el"))
      (when (file-exists-p custom-file)
        (load custom-file))

      ;; When finding file in non-existing directory, offer to create the
      ;; parent directory.
      (defun with-buffer-name-prompt-and-make-subdirs ()
        (let ((parent-directory (file-name-directory buffer-file-name)))
          (when (and (not (file-exists-p parent-directory))
                     (y-or-n-p (format "Directory `%s' does not exist! Create it? " parent-directory)))
            (make-directory parent-directory t))))

      (add-to-list 'find-file-not-found-functions #'with-buffer-name-prompt-and-make-subdirs)

      ;; Don't want to complete .hi files.
      (add-to-list 'completion-ignored-extensions ".hi")

      (defun rah-disable-trailing-whitespace-mode ()
        (setq show-trailing-whitespace nil))

      ;; Shouldn't highlight trailing spaces in terminal mode.
      (add-hook 'term-mode #'rah-disable-trailing-whitespace-mode)
      (add-hook 'term-mode-hook #'rah-disable-trailing-whitespace-mode)

      ;; Ignore trailing white space in compilation mode.
      (add-hook 'compilation-mode-hook #'rah-disable-trailing-whitespace-mode)

      (defun rah-prog-mode-setup ()
        ;; Use a bit wider fill column width in programming modes
        ;; since we often work with indentation to start with.
        (setq fill-column 80))

      (add-hook 'prog-mode-hook #'rah-prog-mode-setup)

      (defun rah-lsp ()
        (interactive)
        (envrc-mode)
        (lsp))

      ;(defun rah-sort-lines-ignore-case ()
      ;  (interactive)
      ;  (let ((sort-fold-case t))
      ;    (call-interactively 'sort-lines)))
    '';

    usePackage = {
      abbrev = {
        enable = true;
        functions = [ "org-in-src-block-p" ];
        hook = [
          "(text-mode . abbrev-mode)"

          # When used in org-mode we want to disable expansion inside source
          # blocks. See https://emacs.stackexchange.com/a/63581.
          ''
            (org-mode .
              (lambda ()
                (setq abbrev-expand-function
                  (lambda ()
                    (unless (org-in-src-block-p) (abbrev--default-expand))))))
          ''
        ];
        config = ''
          (define-abbrev-table 'text-mode-abbrev-table
            '(("acl" "article")
              ("afaik" "as far as I know")
              ("atm" "at the moment")
              ("btw" "by the way")
              ("f" "the")
              ("F" "The")
              ("i" "I")
              ("ndr" "understand")
              ("tnk" "think")))
        '';
      };

      adoc-mode = {
        enable = true;
        mode = [ ''"\\.adoc\\'"'' ];
        hook = [''
          (adoc-mode . (lambda ()
                         (visual-line-mode)
                         (buffer-face-mode)))
        ''];
        config = ''
          (set-face-background 'markup-verbatim-face nil)
        '';
      };

      autorevert = {
        enable = true;
        command = [ "auto-revert-mode" ];
      };

      #back-button = {
      #  enable = true;
      #  package = epkgs:
      #    epkgs.back-button.overrideAttrs (drv:
      #      let
      #        isNotUcsUtils = p:
      #          (builtins.parseDrvName p.name).name != "emacs-ucs-utils";
      #      in {
      #        patches = [
      #          # ucs-utils makes Emacs shutdown very slow, remove its use through this patch.
      #          (pkgs.fetchpatch {
      #            name = "remove-ucs-utils.patch";
      #            url =
      #              "https://github.com/rutger-eiq/back-button/commit/164cf6e2a536a8da6e45c0365922ea1887acde79.patch";
      #            sha256 =
      #              "0czii9hdk7l6j3palpb68377phms9jw9ldb51apjhbmscjyr55q3";
      #          })
      #        ];

              # Also need to remove ucs-utils from the various build inputs.
      #        buildInputs = builtins.filter isNotUcsUtils drv.buildInputs;
      #        propagatedBuildInputs =
      #          builtins.filter isNotUcsUtils drv.propagatedBuildInputs;
      #        propagatedUserEnvPkgs =
      #          builtins.filter isNotUcsUtils drv.propagatedUserEnvPkgs;
      #      });
      #  defer = 2;
      #  command = [ "back-button-mode" ];
      #  config = ''
      #    (back-button-mode 1)

      #    ;; Make mark ring larger.
      #    (setq global-mark-ring-max 50)
      #  '';
      #};

      base16-theme = {
        enable = true;
        extraConfig = ":disabled";
      };

      solarized-theme = {
        enable = true;
      };

      calc = {
        enable = true;
        command = [ "calc" ];
        config = ''
          (setq calc-date-format '(YYYY "-" MM "-" DD " " Www " " hh ":" mm ":" ss))
        '';
      };

      compile = {
        enable = true;
        defer = true;
        after = [ "xterm-color" ];
        config = ''
          (setq compilation-environment '("TERM=xterm-256color"))
          (defun rah-advice-compilation-filter (f proc string)
            (funcall f proc (xterm-color-filter string)))
          (advice-add 'compilation-filter :around #'rah-advice-compilation-filter)
        '';
      };

      beacon = {
        enable = false;
        command = [ "beacon-mode" ];
        defer = 1;
        config = "(beacon-mode 1)";
      };

      browse-at-remote = { command = [ "browse-at-remote" ]; };

      cue-mode.enable = true;

      cc-mode = {
        enable = true;
        defer = true;
        hook = [''
          (c-mode-common . (lambda ()
                             (subword-mode)
                             (c-set-offset 'arglist-intro '++)))
        ''];
      };

      consult = {
        enable = true;
        bind = {
          "C-s" = "consult-line";
          "C-x b" = "consult-buffer";
          "M-g M-g" = "consult-goto-line";
          "M-g g" = "consult-goto-line";
          "M-s f" = "consult-find";
          "M-s r" = "consult-ripgrep";
          "M-y" = "consult-yank-pop";
        };
        command = [ "consult-completing-read-multiple" ];
        config = ''
          (setq consult-project-root-function
                (lambda ()
                  (let ((p (project-current)))
                    (when p (project-root p)))))

          (defvar rah/consult-line-map
            (let ((map (make-sparse-keymap)))
              (define-key map "\C-s" #'vertico-next)
              map))

          (advice-add #'completing-read-multiple
                      :override #'consult-completing-read-multiple)

          (consult-customize
            consult-line
              :history t ;; disable history
              :keymap rah/consult-line-map
            consult-buffer consult-find consult-ripgrep
              :preview-key (kbd "M-.")
            consult-theme
              :preview-key '(:debounce 1 any)
          )
        '';
      };

      consult-xref = {
        enable = true;
        after = [ "consult" "xref" ];
        command = [ "consult-xref" ];
        init = ''
          (setq xref-show-definitions-function #'consult-xref
                xref-show-xrefs-function #'consult-xref)
        '';
      };

      deadgrep = {
        enable = true;
        bind = { "C-x f" = "deadgrep"; };
      };

      dhall-mode = {
        enable = true;
        hook = [ "(dhall-mode . subword-mode)" ];
        config = ''
          (setq dhall-use-header-line nil)
        '';
      };

      # lsp-dhall = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(dhall-mode . rah-lsp)" ];
      # };

      dockerfile-mode.enable = true;

      doom-modeline = {
        enable = true;
        extraConfig = ":disabled";
      };

      drag-stuff = {
        enable = true;
        bind = {
          "M-<up>" = "drag-stuff-up";
          "M-<down>" = "drag-stuff-down";
        };
      };

      ediff = {
        enable = true;
        defer = true;
        config = ''
          (setq ediff-window-setup-function 'ediff-setup-windows-plain)
        '';
      };

      eldoc = {
        enable = true;
        command = [ "eldoc-mode" ];
        init = ''
          (setq eldoc-echo-area-use-multiline-p nil
            eldoc-documentation-strategy #'eldoc-documentation-compose)
            ;; eglot has 3 eldoc functions: `eglot-hover-eldoc-function', and
            ;; `eglot-signature-eldoc-function', using the default strategy
            ;; will only show one information, setting to the following option
            ;; allows the possibility to show both information in eldoc
            ;; buffer.
        '';
      };

      # Enable Electric Indent mode to do automatic indentation on RET.
      electric = {
        enable = true;
        command = [ "electric-indent-local-mode" ];
        hook = [
          "(prog-mode . electric-indent-mode)"

          # Disable for some modes.
          "(purescript-mode . (lambda () (electric-indent-local-mode -1)))"
        ];
      };

      elm-mode.enable = true;

      envrc = {
        enable = true;
        command = [ "envrc-mode" ];
      };

      etags = {
        enable = true;
        defer = true;
        # Avoid spamming reload requests of TAGS files.
        config = "(setq tags-revert-without-query t)";
      };

      gcmh = {
        enable = true;
        defer = 1;
        command = [ "gcmh-mode" ];
        config = ''
          (setq gcmh-idle-delay 'auto)
          (gcmh-mode)
        '';
      };

      ggtags = {
        enable = true;
        defer = true;
        command = [ "ggtags-mode" ];
      };

      groovy-mode = {
        enable = true;
        mode = [
          ''"\\.gradle\\'"'' # \
          ''"\\.groovy\\'"'' # \
          ''"Jenkinsfile\\'"'' # \
        ];
      };

      ispell = {
        enable = true;
        defer = 1;
      };

      js = {
        enable = true;
        mode = [
          ''("\\.js\\'" . js-mode)'' # \
          ''("\\.json\\'" . js-mode)'' # \
        ];
        config = ''
          (setq js-indent-level 2)
        '';
      };

      # See https://github.com/mickeynp/ligature.el
      #ligature = {
      #  enable = true;
      #  package = epkgs:
      #    epkgs.trivialBuild {
      #      pname = "ligature.el";
      #      src = sources."ligature.el";
      #      preferLocalBuild = true;
      #      allowSubstitutes = false;
      #    };
      #  command = [ "ligature-set-ligatures" ];
      #  hook = [
      #    "(nxml-mode . ligature-mode)" # \
      #    "(prog-mode . ligature-mode)" # \
      #  ];
      #  config = ''
      #    ;; Prepare Fantasque Sans Mono ligatures in some modes.
      #    (ligature-set-ligatures 'nxml-mode '("<!--" "-->"))
      #    (ligature-set-ligatures 'prog-mode '("!=" "!==" "-->" "->" "->>" "-<" "-<<"
      #                                         "&&" "||" "|>" "==>" "=>" "=>>" "<="
      #                                         "=<<" "=/=" ">-" ">=" ">=>" ">>" ">>-" ">>="
      #                                         "<|" "<|>" "<-" "<--" "<->" "<=" "<==" "<=>"
      #                                         "<=<" "<>" "<<" "<<-" "<<=" "<~" "<~~" "~>"
      #                                         "~~" "~~>"))
      #  '';
      #};

      notifications = {
        enable = true;
        command = [ "notifications-notify" ];
      };

      notmuch = {
        command = [
          "notmuch"
          "notmuch-show-tag"
          "notmuch-search-tag"
          "notmuch-tree-tag"
        ];
        functions = [ "notmuch-read-tag-changes" "string-trim" ];
        hook = [ "(notmuch-show . rah-disable-trailing-whitespace-mode)" ];
        bindLocal = {
          notmuch-show-mode-map = {
            "S" = "rah-notmuch-show-tag-spam";
            "d" = "rah-notmuch-show-tag-deleted";
          };
          notmuch-tree-mode-map = {
            "S" = "rah-notmuch-tree-tag-spam";
            "d" = "rah-notmuch-tree-tag-deleted";
          };
          notmuch-search-mode-map = {
            "S" = "rah-notmuch-search-tag-spam";
            "d" = "rah-notmuch-search-tag-deleted";
          };
        };
        config = let
          listTags = ts: "(list ${toString (map (t: ''"${t}"'') ts)})";
          spamTags = listTags [ "+spam" "-inbox" ];
          deletedTags = listTags [ "+deleted" "-inbox" ];
        in ''
          (defun rah-notmuch-show-tag-spam ()
            (interactive)
            (notmuch-show-tag ${spamTags}))

          (defun rah-notmuch-show-tag-deleted ()
            (interactive)
            (notmuch-show-tag ${deletedTags}))

          (defun rah-notmuch-tree-tag-spam ()
            (interactive)
            (notmuch-tree-tag ${spamTags}))

          (defun rah-notmuch-tree-tag-deleted ()
            (interactive)
            (notmuch-tree-tag ${deletedTags}))

          (defun rah-notmuch-search-tag-spam (&optional beg end)
            (interactive)
            (notmuch-search-tag ${spamTags} beg end))

          (defun rah-notmuch-search-tag-deleted (&optional beg end)
            (interactive)
            (notmuch-search-tag ${deletedTags} beg end))

          (setq notmuch-show-logo nil
                notmuch-always-prompt-for-sender t
                notmuch-archive-tags '("-inbox" "+archive"))

          ;; Fix use with consult-completing-read-multiple.
          (advice-add #'notmuch-read-tag-changes
                      :filter-return (lambda (x) (mapcar #'string-trim x)))
        '';
      };

      flyspell = {
        enable = true;
        command = [ "flyspell-mode" "flyspell-prog-mode" ];
        bindLocal = {
          flyspell-mode-map = { "C-;" = "flyspell-auto-correct-word"; };
        };
        hook = [
          # Spell check in text and programming mode.
          "(text-mode . flyspell-mode)"
          "(prog-mode . flyspell-prog-mode)"
        ];
        init = ''
          ;; Completely override flyspell's own keymap.
          (setq flyspell-mode-map (make-sparse-keymap))
        '';
        config = ''
          ;; In flyspell I typically do not want meta-tab expansion
          ;; since it often conflicts with the major mode. Also,
          ;; make it a bit less verbose.
          (setq flyspell-issue-message-flag nil
                flyspell-issue-welcome-flag nil
                flyspell-use-meta-tab nil)
        '';
      };

      # Remember where we where in a previously visited file. Built-in.
      saveplace = {
        enable = true;
        defer = 1;
        config = ''
          (setq-default save-place t)
          (setq save-place-file (locate-user-emacs-file "places"))
        '';
      };

      # More helpful buffer names. Built-in.
      uniquify = {
        enable = true;
        defer = 5;
        config = ''
          (setq uniquify-buffer-name-style 'post-forward)
        '';
      };

      # Hook up hippie expand.
      hippie-exp = {
        enable = true;
        bind = { "M-?" = "hippie-expand"; };
      };

      which-key = {
        enable = true;
        command = [
          "which-key-mode"
          "which-key-add-major-mode-key-based-replacements"
        ];
        defer = 3;
        config = "(which-key-mode)";
      };

      # Enable winner mode. This global minor mode allows you to
      # undo/redo changes to the window configuration. Uses the
      # commands C-c <left> and C-c <right>.
      winner = {
        enable = true;
        defer = 2;
        config = "(winner-mode 1)";
      };

      writeroom-mode = {
        enable = true;
        command = [ "writeroom-mode" ];
        bindLocal = {
          writeroom-mode-map = {
            "M-[" = "writeroom-decrease-width";
            "M-]" = "writeroom-increase-width";
            "M-'" = "writeroom-toggle-mode-line";
          };
        };
        hook = [ "(writeroom-mode . visual-line-mode)" ];
        config = ''
          (setq writeroom-bottom-divider-width 0)
        '';
      };

      buffer-move = {
        enable = true;
        bind = {
          "C-S-<up>" = "buf-move-up";
          "C-S-<down>" = "buf-move-down";
          "C-S-<left>" = "buf-move-left";
          "C-S-<right>" = "buf-move-right";
        };
      };

      nyan-mode = {
        enable = true;
        command = [ "nyan-mode" ];
        config = ''
          (setq nyan-wavy-trail t)
        '';
      };

      string-inflection = {
        enable = true;
        bind = { "C-c C-u" = "string-inflection-all-cycle"; };
      };

      # Configure magit, a nice mode for the git SCM.
      magit = {
        enable = true;
        command = [ "magit-project-status" ];
        bind = { "C-c g" = "magit-status"; };
        config = ''
          (add-to-list 'git-commit-style-convention-checks
                       'overlong-summary-line)
        '';
      };

      git-auto-commit-mode = {
        enable = true;
        command = [ "git-auto-commit-mode" ];
        config = ''
          (setq gac-debounce-interval 60)
        '';
      };

      git-messenger = {
        enable = true;
        bind = { "C-x v p" = "git-messenger:popup-message"; };
      };

      marginalia = {
        enable = true;
        command = [ "marginalia-mode" ];
        after = [ "vertico" ];
        defer = 1;
        config = "(marginalia-mode)";
      };

      mml-sec = {
        enable = true;
        defer = true;
        config = ''
          (setq mml-secure-openpgp-encrypt-to-self t
                mml-secure-openpgp-sign-with-sender t)
        '';
      };

      multiple-cursors = {
        enable = true;
        bind = {
          "C-S-c C-S-c" = "mc/edit-lines";
          "C-c m" = "mc/mark-all-like-this";
          "C->" = "mc/mark-next-like-this";
          "C-<" = "mc/mark-previous-like-this";
        };
      };

      nix-sandbox = {
        enable = true;
        command = [ "nix-current-sandbox" "nix-shell-command" ];
      };

      avy = {
        enable = true;
        bind = { "M-j" = "avy-goto-word-or-subword-1"; };
        config = ''
          (setq avy-all-windows t)
        '';
      };

      undo-tree = {
        enable = true;
        defer = 1;
        command = [ "global-undo-tree-mode" ];
        config = ''
          (setq undo-tree-visualizer-relative-timestamps t
                undo-tree-visualizer-timestamps t
                undo-tree-enable-undo-in-region t)
          (global-undo-tree-mode)
        '';
      };

      # Configure AUCTeX.
      #latex = {
      #  enable = true;
      #  package = epkgs: epkgs.auctex;
      #  hook = [''
      #    (LaTeX-mode
      #     . (lambda ()
      #         (turn-on-reftex)       ; Hook up AUCTeX with RefTeX.
      #         (auto-fill-mode)
      #         (define-key LaTeX-mode-map [adiaeresis] "\\\"a")))
      #  ''];
      #  config = ''
      #    (setq TeX-PDF-mode t
      #          TeX-auto-save t
      #          TeX-parse-self t)

      #    ;; Add Glossaries command. See
      #    ;; http://tex.stackexchange.com/a/36914
      #    (eval-after-load "tex"
      #      '(add-to-list
      #        'TeX-command-list
      #        '("Glossaries"
      #          "makeglossaries %s"
      #          TeX-run-command
      #          nil
      #          t
      #          :help "Create glossaries file")))
      #  '';
      #};

      # lsp-elm = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(elm-mode . rah-lsp)" ];
      #   config = ''
      #     (setq lsp-elm-elm-language-server-path
      #             "${pkgs.elmPackages.elm-language-server}/bin/elm-language-server")
      #   '';
      # };

      # lsp-haskell = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(haskell-mode . rah-lsp)" ];
      #   config = ''
      #     (setq lsp-haskell-server-path
      #             "haskell-language-server")
      #   '';
      # };

      # lsp-purescript = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(purescript-mode . rah-lsp) " ];
      # };

      # lsp-ui = {
      #   enable = true;
      #   command = [ "lsp-ui-mode" ];
      #   bindLocal = {
      #     lsp-mode-map = {
      #       "C-c r d" = "lsp-ui-doc-glance";
      #       "C-c f s" = "lsp-ui-find-workspace-symbol";
      #     };
      #   };
      #   config = ''
      #     (setq lsp-ui-sideline-enable t
      #           lsp-ui-sideline-show-symbol nil
      #           lsp-ui-sideline-show-hover nil
      #           lsp-ui-sideline-show-code-actions nil
      #           lsp-ui-sideline-update-mode 'point)
      #     (setq lsp-ui-doc-enable nil
      #           lsp-ui-doc-position 'at-point
      #           lsp-ui-doc-max-width 120
      #           lsp-ui-doc-max-height 15)
      #   '';
      # };

      # lsp-ui-flycheck = {
      #   enable = true;
      #   after = [ "flycheck" "lsp-ui" ];
      # };

      # lsp-completion = {
      #   enable = true;
      #   after = [ "lsp-mode" ];
      #   config = ''
      #     (setq lsp-completion-enable-additional-text-edit nil)
      #   '';
      # };

      # lsp-diagnostics = {
      #   enable = true;
      #   after = [ "lsp-mode" ];
      # };

      # lsp-mode = {
      #   enable = true;
      #   command = [ "lsp" ];
      #   after = [ "company" "flycheck" ];
      #   hook = [ "(lsp-mode . lsp-enable-which-key-integration)" ];
      #   bindLocal = {
      #     lsp-mode-map = {
      #       "C-c r r" = "lsp-rename";
      #       "C-c r f" = "lsp-format-buffer";
      #       "C-c r g" = "lsp-format-region";
      #       "C-c r a" = "lsp-execute-code-action";
      #       "C-c f r" = "lsp-find-references";
      #     };
      #   };
      #   init = ''
      #     (setq lsp-keymap-prefix "C-c l")
      #   '';
      #   config = ''
      #     (setq lsp-diagnostics-provider :flycheck
      #           lsp-eldoc-render-all nil
      #           lsp-headerline-breadcrumb-enable nil
      #           lsp-modeline-code-actions-enable nil
      #           lsp-modeline-diagnostics-enable nil
      #           lsp-modeline-workspace-status-enable nil)
      #     (define-key lsp-mode-map (kbd "C-c l") lsp-command-map)
      #   '';
      # };

      # lsp-java = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(java-mode . rah-lsp)" ];
      #   bindLocal = {
      #     java-mode-map = { "C-c r o" = "lsp-java-organize-imports"; };
      #   };
      #   config = ''
      #     (setq lsp-java-save-actions-organize-imports nil
      #           lsp-java-completion-favorite-static-members
      #               ["org.assertj.core.api.Assertions.*"
      #                "org.assertj.core.api.Assumptions.*"
      #                "org.hamcrest.Matchers.*"
      #                "org.junit.Assert.*"
      #                "org.junit.Assume.*"
      #                "org.junit.jupiter.api.Assertions.*"
      #                "org.junit.jupiter.api.Assumptions.*"
      #                "org.junit.jupiter.api.DynamicContainer.*"
      #                "org.junit.jupiter.api.DynamicTest.*"
      #                "org.mockito.ArgumentMatchers.*"])
      #   '';
      # };

      # lsp-python-ms = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(python-mode . rah-lsp)" ];
      #   config = ''
      #     (setq lsp-python-ms-executable (executable-find "python-language-server"))
      #   '';
      # };

      # lsp-rust = {
      #   enable = true;
      #   defer = true;
      #   hook = [ "(rust-mode . rah-lsp)" ];
      # };

      # lsp-treemacs = {
      #   enable = true;
      #   after = [ "lsp-mode" ];
      #   command = [ "lsp-treemacs-errors-list" ];
      # };

      # dap-mode = {
      #   enable = false;
      #   after = [ "lsp-mode" ];
      # };

      # dap-mouse = {
      #   enable = false;
      #   hook = [ "(dap-mode . dap-tooltip-mode)" ];
      # };

      # dap-ui = {
      #   enable = false;
      #   hook = [ "(dap-mode . dap-ui-mode)" ];
      # };

      # dap-java = {
      #   enable = false;
      #   after = [ "dap-mode" "lsp-java" ];
      # };

      #  Setup RefTeX.
      #reftex = {
      #  enable = true;
      #  defer = true;
      #  config = ''
      #    (setq reftex-default-bibliography '("~/research/bibliographies/main.bib")
      #          reftex-cite-format 'natbib
      #          reftex-plug-into-AUCTeX t)
      #  '';
      #};

      treesit = {
        enable = true;
        init = ''
        (setq treesit-language-source-alist
          '((bash . ("https://github.com/tree-sitter/tree-sitter-bash"))
            (c . ("https://github.com/tree-sitter/tree-sitter-c"))
            (cpp . ("https://github.com/tree-sitter/tree-sitter-cpp"))
            (css . ("https://github.com/tree-sitter/tree-sitter-css"))
            (cmake . ("https://github.com/uyha/tree-sitter-cmake"))
            (csharp     . ("https://github.com/tree-sitter/tree-sitter-c-sharp.git"))
            (dockerfile . ("https://github.com/camdencheek/tree-sitter-dockerfile"))
            (elisp . ("https://github.com/Wilfred/tree-sitter-elisp"))
            (go . ("https://github.com/tree-sitter/tree-sitter-go"))
            (gomod      . ("https://github.com/camdencheek/tree-sitter-go-mod.git"))
            (html . ("https://github.com/tree-sitter/tree-sitter-html"))
            (java       . ("https://github.com/tree-sitter/tree-sitter-java.git"))
            (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
            (json . ("https://github.com/tree-sitter/tree-sitter-json"))
            (lua . ("https://github.com/Azganoth/tree-sitter-lua"))
            (make . ("https://github.com/alemuller/tree-sitter-make"))
            (markdown . ("https://github.com/MDeiml/tree-sitter-markdown" nil "tree-sitter-markdown/src"))
            (ocaml . ("https://github.com/tree-sitter/tree-sitter-ocaml" nil "ocaml/src"))
            (org . ("https://github.com/milisims/tree-sitter-org"))
            (python . ("https://github.com/tree-sitter/tree-sitter-python"))
            (php . ("https://github.com/tree-sitter/tree-sitter-php"))
            (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "typescript/src"))
            (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" nil "tsx/src"))
            (ruby . ("https://github.com/tree-sitter/tree-sitter-ruby"))
            (rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
            (sql . ("https://github.com/derekstride/tree-sitter-sql" "gh-pages"))
            (vue . ("https://github.com/merico-dev/tree-sitter-vue"))
            (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))
            (toml . ("https://github.com/tree-sitter/tree-sitter-toml"))
            (zig . ("https://github.com/GrayJack/tree-sitter-zig")))

          major-mode-remap-alist
          '((c-mode          . c-ts-mode)
            (c++-mode        . c++-ts-mode)
            (c-or-c++-mode   . c-or-c++-ts-mode)
            (cmake-mode      . cmake-ts-mode)
            (conf-toml-mode  . toml-ts-mode)
            (css-mode        . css-ts-mode)
            (js-mode         . js-ts-mode)
            (java-mode       . java-ts-mode)
            (js-json-mode    . json-ts-mode)
            (python-mode     . python-ts-mode)
            (sh-mode         . bash-ts-mode)
            (typescript-mode . typescript-ts-mode)
            (rust-mode       . rust-ts-mode)
            (go-mode         . go-ts-mode)))

          (add-to-list 'auto-mode-alist '("CMakeLists\\'" . cmake-ts-mode))
          (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-ts-mode))
          (add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
          (add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
          (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))
          (add-to-list 'auto-mode-alist '("\\.y[a]?ml\\'" . yaml-ts-mode))
        '';
      };

      eglot = {
        enable = true;
        init = ''
        (setq eglot-stay-out-of '(company)
          read-process-output-max (* 1024 1024)
          eglot-sync-connect 0)
        '';
        config = ''
        (fset #'jsonrpc--log-event #'ignore)  ; massive perf boost---don't log every event
        (add-to-list 'eglot-server-programs
                 '(python-ts-mode . ("pyright-langserver" "--stdio")))

        (add-to-list 'eglot-server-programs
                 '(sql-mode . ("sqls")))

        (add-to-list 'eglot-server-programs
                 '(haskell-mode . ("haskell-language-server" "--lsp")))

        (add-to-list 'eglot-server-programs '((org-mode markdown-mode) "efm-langserver"))

        (add-to-list 'eglot-server-programs '(nix-mode . ("nil")))
        '';
      };

      haskell-mode = {
        enable = true;
        mode = [
          ''("\\.hs\\'" . haskell-mode)''
          ''("\\.hsc\\'" . haskell-mode)''
          ''("\\.c2hs\\'" . haskell-mode)''
          ''("\\.cpphs\\'" . haskell-mode)''
          ''("\\.lhs\\'" . haskell-literate-mode)''
        ];
        hook = [ "(haskell-mode . subword-mode)" "(haskell-mode . eglot-ensure)" ];
        bindLocal.haskell-mode-map = {
          "C-c C-l" = "haskell-interactive-bring";
        };
        config = ''
          (setq tab-width 2)

          (setq haskell-process-log t
                haskell-notify-p t)

          (setq haskell-process-args-cabal-repl
                '("--ghc-options=+RTS -M500m -RTS -ferror-spans -fshow-loaded-modules"))
        '';
      };

      haskell-cabal = {
        enable = true;
        mode = [ ''("\\.cabal\\'" . haskell-cabal-mode)'' ];
        bindLocal = {
          haskell-cabal-mode-map = {
            "C-c C-c" = "haskell-process-cabal-build";
            "C-c c" = "haskell-process-cabal";
            "C-c C-b" = "haskell-interactive-bring";
          };
        };
      };

      haskell-doc = {
        enable = true;
        command = [ "haskell-doc-current-info" ];
      };

      markdown-mode = {
        enable = true;
        hook = [ "(markdown-mode . eglot-ensure)" ];
        config = ''
          (setq markdown-command "${pkgs.pandoc}/bin/pandoc")
        '';
      };

      pandoc-mode = {
        enable = true;
        after = [ "markdown-mode" ];
        hook = [ "markdown-mode" ];
        bindLocal = {
          markdown-mode-map = { "C-c C-c" = "pandoc-run-pandoc"; };
        };
      };

      nix-mode = {
        enable = true;
        hook = [ "(nix-mode . subword-mode)" "(nix-mode . eglot-ensure)" ];
      };

      # Use ripgrep for fast text search in projects. I usually use
      # this through Projectile.
      ripgrep = {
        enable = true;
        command = [ "ripgrep-regexp" ];
      };

      org = {
        enable = true;
        # package = epkgs: epkgs.org-plus-contrib;
        bind = {
          "C-c o c" = "org-capture";
          "C-c o a" = "org-agenda";
          "C-c o l" = "org-store-link";
          "C-c o b" = "org-switchb";
        };
        hook = [''
          (org-mode
           . (lambda ()
               (add-hook 'completion-at-point-functions
                         'pcomplete-completions-at-point nil t)))
        '' "(org-mode . eglot-ensure)"];
        config = ''
          ;; Some general stuff.
          (setq org-reverse-note-order t
                org-use-fast-todo-selection t
                org-adapt-indentation nil
                org-hide-leading-stars t
                org-hide-emphasis-markers t
                org-ctrl-k-protect-subtree t)

          ;; Add some todo keywords.
          (setq org-todo-keywords
                '((sequence "TODO(t)"
                            "STARTED(s!)"
                            "WAITING(w@/!)"
                            "DELEGATED(@!)"
                            "|"
                            "DONE(d!)"
                            "CANCELED(c@!)")))

          ;; set plantmul jar path
          (setq org-plantuml-jar-path (expand-file-name "${pkgs.plantuml}/lib/plantuml.jar"))

          ;; Active Org-babel languages
          (org-babel-do-load-languages 'org-babel-load-languages
                                       '((plantuml . t)
                                         (http . t)
                                         (shell . t)
                                         (sql . t)
                                         (verb . t)))

          ;; Unfortunately org-mode tends to take over keybindings that
          ;; start with C-c.
          (unbind-key "C-c SPC" org-mode-map)
          (unbind-key "C-c w" org-mode-map)
          (unbind-key "C-'" org-mode-map)
        '';
      };

      org-agenda = {
        enable = true;
        after = [ "org" ];
        defer = true;
        config = ''
          ;; Set up agenda view.
          ;; (setq org-agenda-files (rah-all-org-files)
              (setq org-agenda-span 5
                org-deadline-warning-days 14
                org-agenda-show-all-dates t
                org-agenda-skip-deadline-if-done t
                org-agenda-skip-scheduled-if-done t
                org-agenda-start-on-weekday nil)
        '';
      };

      ob-http = {
        enable = true;
        after = [ "org" ];
        defer = true;
      };

      ob-plantuml = {
        enable = true;
        after = [ "org" ];
        defer = true;
      };

      ol-notmuch = {
        enable = pcfg.org.enable && pcfg.notmuch.enable;
        after = [ "notmuch" "org" ];
      };

      org-roam = {
        enable = true;
        command = [ "org-roam-db-autosync-mode" ];
        defines = [ "org-roam-v2-ack" ];
        bind = { "C-' f" = "org-roam-node-find"; };
        bindLocal = {
          org-mode-map = {
            "C-' b" = "org-roam-buffer-toggle";
            "C-' i" = "org-roam-node-insert";
          };
        };
        init = ''
          (setq org-roam-v2-ack t)
        '';
        config = ''
          (setq org-roam-directory "~/roam")
          (org-roam-db-autosync-mode)
        '';
      };

      org-table = {
        enable = true;
        after = [ "org" ];
        command = [ "orgtbl-to-generic" ];
        functions = [ "org-combine-plists" ];
        hook = [
          # For orgtbl mode, add a radio table translator function for
          # taking a table to a psql internal variable.
          ''
            (orgtbl-mode
             . (lambda ()
                 (defun rah-orgtbl-to-psqlvar (table params)
                   "Converts an org table to an SQL list inside a psql internal variable"
                   (let* ((params2
                           (list
                            :tstart (concat "\\set " (plist-get params :var-name) " '(")
                            :tend ")'"
                            :lstart "("
                            :lend "),"
                            :sep ","
                            :hline ""))
                          (res (orgtbl-to-generic table (org-combine-plists params2 params))))
                     (replace-regexp-in-string ",)'$"
                                               ")'"
                                               (replace-regexp-in-string "\n" "" res))))))
          ''
        ];
        config = ''
          (unbind-key "C-c SPC" orgtbl-mode-map)
          (unbind-key "C-c w" orgtbl-mode-map)
        '';
      };

      org-capture = {
        enable = true;
        after = [ "org" ];
        config = ''
          ;; (setq org-capture-templates rah-org-capture-templates) ; not sure where this variable defined, comment out for now.
        '';
      };

      org-clock = {
        enable = true;
        after = [ "org" ];
        config = ''
          (setq org-clock-rounding-minutes 5
                org-clock-out-remove-zero-time-clocks t)
        '';
      };

      org-duration = {
        enable = true;
        after = [ "org" ];
        config = ''
          ;; I always want clock tables and such to be in hours, not days.
          (setq org-duration-format (quote h:mm))
        '';
      };

      org-refile = {
        enable = true;
        after = [ "org" ];
        config = ''
          ;; Refiling should include not only the current org buffer but
          ;; also the standard org files. Further, set up the refiling to
          ;; be convenient with IDO. Follows norang's setup quite closely.
          (setq org-refile-targets '((nil :maxlevel . 2)
                                     (org-agenda-files :maxlevel . 2))
                org-refile-use-outline-path t
                org-outline-path-complete-in-steps nil
                org-refile-allow-creating-parent-nodes 'confirm)
        '';
      };

      org-superstar = {
        enable = true;
        hook = [ "(org-mode . org-superstar-mode)" ];
      };

      org-tree-slide = {
        enable = true;
        command = [ "org-tree-slide-mode" ];
      };

      org-variable-pitch = {
        enable = false;
        hook = [ "(org-mode . org-variable-pitch-minor-mode)" ];
      };

      orderless = {
        enable = true;
        init = ''
          (setq completion-styles '(orderless)
                read-file-name-completion-ignore-case t)
        '';
      };

      purescript-mode = {
        enable = true;
        hook = [ "(purescript-mode . subword-mode)" ];
      };

      purescript-indentation = {
        enable = true;
        hook = [ "(purescript-mode . purescript-indentation-mode)" ];
      };

      # Set up yasnippet. Defer it for a while since I don't generally
      # need it immediately.
      yasnippet = {
        enable = true;
        defer = 3;
        command = [ "yas-global-mode" "yas-minor-mode" "yas-expand-snippet" ];
        hook = [
          # Yasnippet interferes with tab completion in ansi-term.
          "(term-mode . (lambda () (yas-minor-mode -1)))"
        ];
        config = "(yas-global-mode 1)";
      };

      yasnippet-snippets = {
        enable = true;
        after = [ "yasnippet" ];
      };

      # Setup the cperl-mode, which I prefer over the default Perl
      # mode.
      cperl-mode = {
        enable = true;
        defer = true;
        hook = [ "ggtags-mode" ];
        command = [ "cperl-set-style" ];
        config = ''
          ;; Avoid deep indentation when putting function across several
          ;; lines.
          (setq cperl-indent-parens-as-block t)

          ;; Use cperl-mode instead of the default perl-mode
          (defalias 'perl-mode 'cperl-mode)
          (cperl-set-style "PerlStyle")
        '';
      };

      # Setup ebib, my chosen bibliography manager.
      ebib = {
        enable = false;
        command = [ "ebib" ];
        hook = [
          # Highlighting of trailing whitespace is a bit annoying in ebib.
          "(ebib-index-mode-hook . rah-disable-trailing-whitespace-mode)"
          "(ebib-entry-mode-hook . rah-disable-trailing-whitespace-mode)"
        ];
        config = ''
          (setq ebib-latex-preamble '("\\usepackage{a4}"
                                      "\\bibliographystyle{amsplain}")
                ebib-print-preamble '("\\usepackage{a4}")
                ebib-print-tempfile "/tmp/ebib.tex"
                ebib-extra-fields '(crossref
                                    url
                                    annote
                                    abstract
                                    keywords
                                    file
                                    timestamp
                                    doi))
        '';
      };

      smartparens = {
        enable = true;
        defer = 3;
        command = [ "smartparens-global-mode" "show-smartparens-global-mode" ];
        bindLocal = {
          smartparens-mode-map = {
            "C-M-f" = "sp-forward-sexp";
            "C-M-b" = "sp-backward-sexp";
          };
        };
        config = ''
          (require 'smartparens-config)
          (smartparens-global-mode t)
          (show-smartparens-global-mode t)
        '';
      };

      fill-column-indicator = {
        enable = true;
        command = [ "fci-mode" ];
      };

      flycheck = {
        enable = true;
        command = [ "global-flycheck-mode" ];
        defer = 1;
        bind = {
          "M-n" = "flycheck-next-error";
          "M-p" = "flycheck-previous-error";
        };
        config = ''
          ;; Only check buffer when mode is enabled or buffer is saved.
          (setq flycheck-check-syntax-automatically '(mode-enabled save))

          ;; Enable flycheck in all eligible buffers.
          (global-flycheck-mode)
        '';
      };

      flycheck-plantuml = {
        enable = true;
        hook = [ "(flycheck-mode . flycheck-plantuml-setup)" ];
        config = ''
          (setq plantuml-jar-path (expand-file-name "${pkgs.plantuml}/lib/plantuml.jar"))
        '';
      };

      project = {
        enable = true;
        command = [ "project-root" ];
        bindKeyMap = { "C-x p" = "project-prefix-map"; };
        bindLocal.project-prefix-map = { "m" = "magit-project-status"; };
        config = ''
          (add-to-list 'project-switch-commands '(magit-project-status "Magit") t)
        '';
      };

      plantuml-mode = {
        enable = true;
        mode = [ ''"\\.puml\\'"'' ];
        config = ''
          (setq plantuml-jar-path (expand-file-name "${pkgs.plantuml}/lib/plantuml.jar"))
        '';
      };

      pikchr-mode = {
        enable = true;
      };

      ox-pandoc = {
        enable = true;
      };

      gnuplot = {
        enable = true;
      };

      ace-window = {
        enable = true;
        extraConfig = ''
          :bind* (("C-c w" . ace-window)
                  ("M-o" . ace-window))
        '';
      };

      company = {
        enable = true;
        command = [ "company-mode" "company-doc-buffer" "global-company-mode" ];
        defer = 1;
        extraConfig = ''
          :bind (:map company-mode-map
                      ([remap completion-at-point] . company-complete-common)
                      ([remap complete-symbol] . company-complete-common))
        '';
        config = ''
          (setq company-idle-delay 0.3
                company-show-quick-access t
                company-tooltip-maximum-width 100
                company-tooltip-minimum-width 20
                ; Allow me to keep typing even if company disapproves.
                company-require-match nil)

          (global-company-mode)
        '';
      };

      company-box = {
        enable = true;
        hook = [ "(company-mode . company-box-mode)" ];
        config = ''
          (setq company-box-icons-alist 'company-box-icons-all-the-icons)
        '';
      };

      company-yasnippet = {
        enable = true;
        after = [ "company" "yasnippet" ];
        bind = { "M-/" = "company-yasnippet"; };
      };

      company-dabbrev = {
        enable = true;
        after = [ "company" ];
        bind = { "C-M-/" = "company-dabbrev"; };
        config = ''
          (setq company-dabbrev-downcase nil
                company-dabbrev-ignore-case t)
        '';
      };

      company-quickhelp = {
        enable = true;
        after = [ "company" ];
        command = [ "company-quickhelp-mode" ];
        config = ''
          (company-quickhelp-mode 1)
        '';
      };

      company-cabal = {
        enable = true;
        after = [ "company" ];
        command = [ "company-cabal" ];
        config = ''
          (add-to-list 'company-backends 'company-cabal)
        '';
      };

      php-mode = { hook = [ "ggtags-mode" ]; };

      # Needed by Flycheck.
      pkg-info = {
        enable = true;
        command = [ "pkg-info-version-info" ];
      };

      popper = {
        enable = true;
        bind = {
          "C-`" = "popper-toggle-latest";
          "M-`" = "popper-cycle";
          "C-M-`" = "popper-toggle-type";
        };
        command = [ "popper-mode" "popper-group-by-project" ];
        config = ''
          (setq popper-reference-buffers
                  '("Output\\*$"
                    "\\*Async Shell Command\\*"
                    "\\*Buffer List\\*"
                    "\\*Flycheck errors\\*"
                    "\\*Messages\\*"
                    compilation-mode
                    help-mode)
                popper-group-function #'popper-group-by-project)
          (popper-mode)
        '';
      };

      python = {
        enable = true;
        mode = [ ''("\\.py\\'" . python-mode)'' ];
        hook = [ "ggtags-mode" ];
      };

      transpose-frame = {
        enable = true;
        bind = { "C-c f t" = "transpose-frame"; };
      };

      tt-mode = {
        enable = true;
        mode = [ ''"\\.tt\\'"'' ];
      };

      yaml-mode = {
        enable = true;
        hook = [ "(yaml-mode . rah-prog-mode-setup)" ];
      };

      wc-mode = {
        enable = true;
        command = [ "wc-mode" ];
      };

      web-mode = {
        enable = true;
        mode = [
          ''"\\.html\\'"'' # \
          ''"\\.jsx?\\'"'' # \
        ];
        config = ''
          (setq web-mode-attr-indent-offset 4
                web-mode-code-indent-offset 2
                web-mode-markup-indent-offset 2)

          (add-to-list 'web-mode-content-types '("jsx" . "\\.jsx?\\'"))
        '';
      };

      dired = {
        enable = true;
        command = [ "dired" "dired-jump" ];
        config = ''
          (put 'dired-find-alternate-file 'disabled nil)

          ;; Be smart about choosing file targets.
          (setq dired-dwim-target t)

          ;; Use the system trash can.
          (setq delete-by-moving-to-trash t)
          (setq dired-listing-switches "-alvh --group-directories-first")
        '';
      };

      all-the-icons-dired = {
        enable = true;
        hook = [ "(dired-mode . all-the-icons-dired-mode)" ];
      };

      wdired = {
        enable = true;
        bindLocal = {
          dired-mode-map = { "C-c C-w" = "wdired-change-to-wdired-mode"; };
        };
        config = ''
          ;; I use wdired quite often and this setting allows editing file
          ;; permissions as well.
          (setq wdired-allow-to-change-permissions t)
        '';
      };

      # Hide hidden files when opening a dired buffer. But allow showing them by
      # pressing `.`.
      dired-x = {
        enable = true;
        hook = [ "(dired-mode . dired-omit-mode)" ];
        bindLocal.dired-mode-map = { "." = "dired-omit-mode"; };
        config = ''
          (setq dired-omit-verbose nil
                dired-omit-files (concat dired-omit-files "\\|^\\..+$"))
        '';
      };

      recentf = {
        enable = true;
        command = [ "recentf-mode" ];
        config = ''
          (setq recentf-save-file (locate-user-emacs-file "recentf")
                recentf-max-menu-items 20
                recentf-max-saved-items 500
                recentf-exclude '("COMMIT_MSG" "COMMIT_EDITMSG"))

          ;; Save the file list every 10 minutes.
          (run-at-time nil (* 10 60) 'recentf-save-list)

          (recentf-mode)
        '';
      };

      nxml-mode = {
        enable = true;
        mode = [ ''"\\.xml\\'"'' ];
        config = ''
          (setq nxml-child-indent 2
                nxml-attribute-indent 4
                nxml-slash-auto-complete-flag t)
          (add-to-list 'rng-schema-locating-files
                       "~/.emacs.d/nxml-schemas/schemas.xml")
        '';
      };

      rust-mode.enable = true;

      savehist = {
        enable = true;
        init = "(savehist-mode)";
        config = ''
          (setq history-delete-duplicates t
                history-length 100)
        '';
      };

      sendmail = {
        command = [ "mail-mode" "mail-text" ];
        mode = [
          ''("^mutt-" . mail-mode)'' # \
          ''("\\.article" . mail-mode)'' # \
        ];
        bindLocal = {
          mail-mode-map = {
            # Make it easy to include references.
            "C-c [" = "rah-mail-reftex-citation";
          };
        };
        hook = [ "rah-mail-mode-hook" ];
        config = ''
          (defun rah-mail-reftex-citation ()
            (let ((reftex-cite-format 'locally))
              (reftex-citation)))

          (defun rah-mail-flyspell ()
            "Enable flyspell and set dictionary based on To: field."
            (save-excursion
              (goto-char (point-min))
              (when (re-search-forward "^To: .*\\.se\\($\\|,\\|>\\)" nil t)
                (ispell-change-dictionary "swedish"))))

          (defun rah-mail-mode-hook ()
            (auto-fill-mode)     ; Avoid having to M-q all the time.
            (rah-mail-flyspell)  ; I spel funily soemtijms.
            (mail-text))         ; Jump to the actual text.

          (setq sendmail-program "${pkgs.msmtp}/bin/msmtp"
                send-mail-function 'sendmail-send-it
                mail-specify-envelope-from t
                message-sendmail-envelope-from 'header
                mail-envelope-from 'header)
        '';
      };

      shr = {
        enable = true;
        defer = true;
        config = ''
          (setq shr-use-colors nil)
        '';
      };

      sv-kalender = {
        enable = true;
        defer = 5;
      };

      systemd = {
        enable = true;
        defer = true;
      };

      treemacs = {
        enable = true;
        bind = {
          "C-c t f" = "treemacs-find-file";
          "C-c t t" = "treemacs";
        };
      };

      verb = {
        enable = true;
        defer = true;
        after = [ "org" ];
        config = ''
          (define-key org-mode-map (kbd "C-c C-r") verb-command-map)
          (setq verb-trim-body-end "[ \t\n\r]+")
        '';
      };

      vertico = {
        enable = true;
        command = [ "vertico-mode" "vertico-next" ];
        init = "(vertico-mode)";
      };

      visual-fill-column = {
        enable = true;
        command = [ "visual-fill-column-mode" ];
      };

      vterm = {
        enable = true;
        command = [ "vterm" ];
        hook = [ "(vterm-mode . rah-disable-trailing-whitespace-mode)" ];
        config = ''
          (setq vterm-kill-buffer-on-exit t
                vterm-max-scrollback 10000)
        '';
      };

      xterm-color = {
        enable = true;
        defer = 1;
        command = [ "xterm-color-filter" ];
      };
    };
  };

}
