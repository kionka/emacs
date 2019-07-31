(require 'package)
;; using home-manager for package install
(setq package-enable-at-startup nil)
(package-initialize)
(require 'use-package)
(setq use-package-always-ensure t)

(setq backup-directory-alist
      `(("." . ,(expand-file-name (concat user-emacs-directory "backups")))))
;; I have no idea why this directory requires to be created manually.
(let ((backup-dir (expand-file-name (concat user-emacs-directory "auto-save/") t)))
   (unless (file-directory-p backup-dir)
     (mkdir backup-dir t))
   (setq auto-save-file-name-transforms
         `((".*" ,backup-dir))))
;;(setq auto-save-file-name-transforms
;;      `((".*" ,(expand-file-name (concat user-emacs-directory "auto-save/") t))))

;; suppress annoying defaults
(setq inhibit-startup-message t
      inhibit-startup-message t
      initial-scratch-message nil)

; whitespace
(setq tab-width 2)
(setq-default indent-tabs-mode nil)
(setq require-final-newline t)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq-default show-trailing-whitespace t)
(setq-default indicate-empty-lines t)
(when (not indicate-empty-lines)
  (toggle-indicate-empty-lines))

(menu-bar-mode -1)

(use-package general)

(use-package haskell-mode
  :mode "\\.\\(hs\\|lhs\\|hsc\\|cpphs\\|c2hs\\)\\'"
  :general
  :config
  ;; https://github.com/srid/reflex-platform/blob/emacs-setup-v2/docs/project-editor.md#spacemacs
  (setq haskell-process-wrapper-function
        (lambda (args) (apply 'nix-shell-command (nix-current-sandbox) args)))
  (setq haskell-process-type 'cabal-new-repl))

(use-package dante
  :after haskell-mode
  :init
  (add-hook 'haskell-mode-hook 'dante-mode)
  (add-hook 'haskell-mode-hook 'flycheck-mode)
  :config
  (add-to-list 'flycheck-disabled-checkers 'haskell-stack-ghc)
  (reflex-set-dante-locals)
  (flycheck-haskell-set-nix-executables)
  (flycheck-add-next-checker 'haskell-dante '(warning . haskell-hlint)))

;; Prevent emacs from complaining about .dir-locals.el containing dante-target
(put 'dante-target 'safe-local-variable #'stringp)

(use-package hindent
  :after haskell-mode
  :init
  (add-hook 'haskell-mode-hook 'hindent-mode))

; https://github.com/reflex-frp/reflex-platform/pull/237#issuecomment-374548470
;; Configure flycheck to use Nix
;; Requires `nix-sandbox` package added to dotspacemacs-additional-packages
(defun flycheck-haskell-set-nix-executables ()
  ;; Find any executables flycheck needs in the nix sandbox
  ;(make-local-variable 'flycheck-command-wrapper-function)
  ;(make-local-variable 'flycheck-executable-find)
  (setq flycheck-command-wrapper-function
        (lambda (cmd) (apply 'nix-shell-command (nix-current-sandbox) cmd))
        flycheck-executable-find
        (lambda (cmd) (nix-executable-find (nix-current-sandbox) cmd)))

  ;; Explicitly set the ghc and hlint buffer-local executable values
  ;(make-local-variable 'flycheck-haskell-ghc-executable)
  ;(make-local-variable 'flycheck-haskell-hlint-executable)
  (setq flycheck-haskell-ghc-executable
        (nix-executable-find (nix-current-sandbox) "ghc")
        flycheck-haskell-hlint-executable
        (nix-executable-find (nix-current-sandbox) "hlint"))

  ; I think the executable-find override is only necessary for hoggle
  ;; Make the executable-find a local function that uses nix
  ;(make-local-variable 'executable-find)

  (setq executable-find
        (lambda (cmd) (nix-executable-find (nix-current-sandbox) cmd)))
  (message "set flycheck-haskell-ghc-executable to: %S"
           flycheck-haskell-ghc-executable))

;; Setup the dante project values according to the proposed layout for
;; shared common code, i.e
;;
;; dante-project-root === <immediate folder with a shell.nix>
;; dante-repl-command-line === cabal new-repl <dante-target> --buildir=dist/dante
(defun reflex-set-dante-locals ()
  ;(make-local-variable 'dante-project-root)
  ;(make-local-variable 'dante-repl-command-line)
  (setq dante-project-root
        (locate-dominating-file buffer-file-name "shell.nix"))
  (if dante-target
      (let ((cabal-cmd
             (concat "cabal new-repl " dante-target " --builddir=dist/dante")))
        (setq dante-repl-command-line (list "nix-shell" "--run" cabal-cmd)))
    nil))

(defun flycheck-haskell-setup-nix-locals ()
  ;; disable the haskell-stack-ghc checker
  (add-to-list 'flycheck-disabled-checkers 'haskell-stack-ghc)
  (add-hook 'hack-local-variables-hook #'reflex-set-dante-locals
            nil 'local)
  (add-hook 'hack-local-variables-hook #'flycheck-haskell-set-nix-executables
            nil 'local))
