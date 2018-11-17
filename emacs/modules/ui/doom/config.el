;;; ui/nucleus/config.el -*- lexical-binding: t; -*-

(defvar +nucleus-solaire-themes
  '((doom-city-lights . t)
    (doom-dracula . t)
    (doom-molokai . t)
    (doom-nord . t)
    (doom-nord-light . t)
    (doom-nova)
    (doom-one . t)
    (doom-one-light . t)
    (doom-opera . t)
    (doom-solarized-light)
    (doom-spacegrey)
    (doom-vibrant)
    (doom-tomorrow-night))
  "An alist of themes that support `solaire-mode'. If CDR is t, then use
`solaire-mode-swap-bg'.")


;;
;; Packages

(def-package! leuven-theme)

;; <https://github.com/hlissner/emacs-doom-theme>
(def-package! doom-themes
  :defer t
  :init
  (unless nucleus-theme
    (setq nucleus-theme 'doom-one-light))
  ;; improve integration w/ org-mode
  (add-hook 'nucleus-load-theme-hook #'doom-themes-org-config)
  ;; more Atom-esque file icons for neotree/treemacs
  (when (featurep! :ui neotree)
    (add-hook 'nucleus-load-theme-hook #'doom-themes-neotree-config)
    (setq nucleus-neotree-enable-variable-pitch t
          nucleus-neotree-file-icons 'simple
          nucleus-neotree-line-spacing 2))
  (when (featurep! :ui treemacs)
    (add-hook 'nucleus-load-theme-hook #'doom-themes-treemacs-config)
    (setq nucleus-treemacs-enable-variable-pitch t)))

(def-package! solaire-mode
  :defer t
  :init
  (defun +nucleus|solaire-mode-swap-bg-maybe ()
    (when-let* ((rule (assq nucleus-theme +nucleus-solaire-themes)))
      (require 'solaire-mode)
      (if (cdr rule) (solaire-mode-swap-bg))))
  (add-hook 'nucleus-load-theme-hook #'+nucleus|solaire-mode-swap-bg-maybe t)
  :config
  (add-hook 'change-major-mode-after-body-hook #'turn-on-solaire-mode)
  ;; fringe can become unstyled when deleting or focusing frames
  (add-hook 'focus-in-hook #'solaire-mode-reset)
  ;; Prevent color glitches when reloading either DOOM or loading a new theme
  (add-hook! :append '(nucleus-load-theme-hook nucleus-reload-hook)
    #'solaire-mode-reset)
  ;; org-capture takes an org buffer and narrows it. The result is erroneously
  ;; considered an unreal buffer, so solaire-mode must be restored.
  (add-hook 'org-capture-mode-hook #'turn-on-solaire-mode)

  ;; Because fringes can't be given a buffer-local face, they can look odd, so
  ;; we remove them in the minibuffer and which-key popups (they serve no
  ;; purpose there anyway).
  (defun +nucleus|disable-fringes-in-minibuffer (&rest _)
    (set-window-fringes (minibuffer-window) 0 0 nil))
  (add-hook 'solaire-mode-hook #'+nucleus|disable-fringes-in-minibuffer)

  (defun nucleus*no-fringes-in-which-key-buffer (&rest _)
    (+nucleus|disable-fringes-in-minibuffer)
    (set-window-fringes (get-buffer-window which-key--buffer) 0 0 nil))
  (advice-add 'which-key--show-buffer-side-window :after #'nucleus*no-fringes-in-which-key-buffer)

  (add-hook! '(minibuffer-setup-hook window-configuration-change-hook)
    #'+nucleus|disable-fringes-in-minibuffer))
