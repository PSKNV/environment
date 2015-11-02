;;; packages.el --- elfeed Layer extensions File for Spacemacs
;;
;; Copyright (c) 2012-2015 Sylvain Benner
;; Copyright (c) 2014-2015 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(setq elfeed-packages
      '(elfeed
        elfeed-web
        elfeed-org))

(defun elfeed/init-elfeed ()
  (use-package elfeed
    :defer t
    :commands (elfeed-web-start elfeed-web-stop)
    :init
    (evil-leader/set-key "af" 'elfeed)
    :config
    (progn
      (evilify elfeed-search-mode elfeed-search-mode-map
               (kbd "q") 'quit-window
               (kbd "c") 'elfeed-db-compact
               (kbd "o") 'elfeed-load-opml
               (kbd "w") 'elfeed-web-start
               (kbd "W") 'elfeed-web-stop)
      (evilify elfeed-show-mode elfeed-show-mode-map
               (kbd "q") 'quit-window))))

(defun elfeed/init-elfeed-org ()
  (use-package elfeed-org
    :commands elfeed-org
    :init
    (when (boundp 'rmh-elfeed-org-files)
      (elfeed-org))))

(defun elfeed/init-elfeed-web ()
  (use-package elfeed-web
    :commands elfeed-web-start
    :init
    (progn
      (when elfeed-web-enabled-on-emacs-startup
        (elfeed-web-start)))))