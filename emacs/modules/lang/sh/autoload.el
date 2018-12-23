;;; lang/sh/autoload.el -*- lexical-binding: t; -*-
;;
;; Copyright (c) 2018 Boris Buliga
;;
;; Author: Boris Buliga <boris@d12frosted.io>
;; Maintainer: Boris Buliga <boris@d12frosted.io>
;;
;; Created: 04 Dec 2018
;;
;; URL: https://github.com/d12frosted/environment/emacs
;;
;; License: GPLv3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;; Code:

(defvar sh-shell-file)

;;;###autoload
(defun +sh--match-variables-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by
LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward
                      "[^\\]\\(\\$\\)\\({.+?}\\|\\<[a-zA-Z0-9_]+\\|[@*#!]\\)"
                      limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

;;;###autoload
(defun +sh--match-command-subst-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by
LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward "[^\\]\\(\\$(.+?)\\|`.+?`\\)"
                                        limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

;;;###autoload
(defun +sh/repl ()
  "Open a shell REPL."
  (let* ((dest-sh (symbol-name sh-shell))
         (sh-shell-file dest-sh)
         (dest-name (format "*shell [%s]*" dest-sh)))
    (sh-shell-process t)
    (with-current-buffer "*shell*"
      (rename-buffer dest-name))
    (get-buffer dest-name)))