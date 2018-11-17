;;; nucleus-cli.el --- the heart of every cell -*- lexical-binding: t; -*-
;;
;;; Copyright (c) 2015-2018 Boris Buliga
;;
;;; Author: Boris Buliga <boris@d12frosted.io>
;;; URL: https://github.com/d12frosted/environment/emacs
;;; License: GPLv3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;; Code:

;; Eagerly load these libraries because this module may be loaded in a session
;; that hasn't been fully initialized (where autoloads files haven't been
;; generated or `load-path' populated).
(load! "nucleus-debug")
(load! "nucleus-message")
(load! "nucleus-packages")

;;
;; Dispatcher API

(defvar nucleus-auto-accept (getenv "YES")
  "If non-nil, Nucleus will auto-accept any confirmation prompts
during batch commands like `nucleus-packages-install',
`nucleus-packages-update' and `nucleus-packages-autoremove'.")

(defconst nucleus--dispatch-command-alist ())
(defconst nucleus--dispatch-alias-alist ())

(defun nucleus--dispatch-format (desc &optional short)
  (with-temp-buffer
    (let ((fill-column 72))
      (insert desc)
      (goto-char (point-min))
      (while (re-search-forward "\n\n[^ \n]" nil t)
        (fill-paragraph)))
    (if (not short)
        (buffer-string)
      (goto-char (point-min))
      (buffer-substring-no-properties
       (line-beginning-position)
       (line-end-position)))))

(defun nucleus--dispatch-help (&optional command desc &rest args)
  "Display help documentation for a dispatcher command. If
COMMAND and DESC are omitted, show all available commands, their
aliases and brief descriptions."
  (if command
      (princ (nucleus--dispatch-format desc))
    (print! (bold "%-10s\t%s\t%s") "Command:" "Alias" "Description")
    (dolist (spec (cl-sort nucleus--dispatch-command-alist #'string-lessp
                           :key #'car))
      (cl-destructuring-bind (command &key desc _body) spec
        (let ((aliases (cl-loop for (alias . cmd) in nucleus--dispatch-alias-alist
                                if (eq cmd command)
                                collect (symbol-name alias))))
          (print! "  %-10s\t%s\t%s"
                  command (if aliases (string-join aliases ",") "")
                  (nucleus--dispatch-format desc t)))))))

(defun nucleus-dispatch (cmd args &optional show-help)
  "Parses ARGS and invokes a dispatcher.

If SHOW-HELP is non-nil, show the documentation for said
dispatcher."
  (when (equal cmd "help")
    (setq show-help t)
    (when args
      (setq cmd  (car args)
            args (cdr args))))
  (cl-destructuring-bind (command &key desc body)
      (let ((sym (intern cmd)))
        (or (assq sym nucleus--dispatch-command-alist)
            (assq (cdr (assq sym nucleus--dispatch-alias-alist))
                  nucleus--dispatch-command-alist)
            (user-error "Invalid command: %s" sym)))
    (if show-help
        (apply #'nucleus--dispatch-help command desc args)
      (funcall body args))))

(defmacro dispatcher! (command form &optional docstring)
  "Define a dispatcher command. COMMAND is a symbol or a list of
symbols representing the aliases for this command. DESC is a
string description. The first line should be short (under 60
letters), as it will be displayed for bin/nucleus help.

BODY will be run when this dispatcher is called."
  (declare (indent defun) (doc-string 3))
  (cl-destructuring-bind (cmd &rest aliases)
      (nucleus-enlist command)
    (macroexp-progn
     (append
      (when aliases
        `((dolist (alias ',aliases)
            (setf (alist-get alias nucleus--dispatch-alias-alist) ',cmd))))
      `((setf (alist-get ',cmd nucleus--dispatch-command-alist)
              (list :desc ,docstring
                    :body (lambda (args) (ignore args) ,form))))))))


;;
;; Dummy dispatch commands (no-op because they're handled especially)

(dispatcher! run :noop
  "Run Nucleus Emacs from bin/nucleus's parent directory.

All arguments are passed on to Emacs (except for -p and -e).

  nucleus run
  nucleus run -nw init.el

WARNING: this command exists for convenience and testing. Nucleus
will suffer additional overhead by being started this way. For
the best performance, it is best to run Nucleus out of ~/.emacs.d
and ~/.nucleus.d.")

(dispatcher! (doctor doc) :noop
  "Checks for issues with your environment & Nucleus config.

Also checks for missing dependencies for any enabled modules.")

(dispatcher! (help h) :noop
  "Look up additional information about a command.")

;;
;; Real dispatch commands

(load! "cli/autoloads")
(load! "cli/byte-compile")
(load! "cli/debug")
(load! "cli/packages")
(load! "cli/patch-macos")
(load! "cli/quickstart")
(load! "cli/upgrade")
(load! "cli/test")

;;
(defun nucleus-refresh (&optional force-p)
  "Ensure Nucleus is in a working state by checking autoloads and
packages, and recompiling any changed compiled files. This is the
shotgun solution to most problems with nucleus."
  (nucleus-reload-nucleus-autoloads force-p)
  (unwind-protect
      (progn
        (ignore-errors
          (nucleus-packages-autoremove nucleus-auto-accept))
        (ignore-errors
          (nucleus-packages-install nucleus-auto-accept)))
    (nucleus-reload-package-autoloads force-p)
    (nucleus-byte-compile nil 'recompile)))

(dispatcher! (refresh re) (nucleus-refresh 'force)
  "Refresh Nucleus. Same as autoremove+install+autoloads.

This is the equivalent of running autoremove, install, autoloads,
then recompile. Run this whenever you:

  1. Modify your `nucleus!' block,
  2. Add or remove `package!' blocks to your config,
  3. Add or remove autoloaded functions in module autoloaded files.
  4. Update Nucleus outside of Nucleus (e.g. with git)")

(provide 'nucleus-cli)

;;; nucleus-cli.el ends here
