;;; vulpea.el --- Collection of note taking helpers -*- lexical-binding: t -*-

;; Author: Boris Buliga
;; Maintainer: Boris Buliga
;; Version: 0.1
;; Package-Requires: ((org-mode "9.1.0") (org-brain "0.5"))
;; Homepage: https://github.com/d12frosted/environment/tree/master/emacs/spacemacs/vulpea/local/vulpea
;; Keywords: personal


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;;; Code:

(defun vulpea-brain/insert-link ()
  "Insert a link to brain entry."
  (interactive)
  (insert (vulpea-brain--make-link (vulpea-brain--choose-entry))))

(defun vulpea-brain--make-link (entry-or-id)
  "Make an org-mode link to ENTRY."
  (org-make-link-string
   (concat "brain:"
           (vulpea-brain--as-id entry-or-id))
   (org-brain-title (vulpea-brain--as-entry entry-or-id))))

(defun vulpea-brain--choose-entry ()
  "Choose a brain entry."
  (org-brain-choose-entry
   "Entry: "
   (append (org-brain-files t) (org-brain-headline-entries))
   nil
   t))

(defun vulpea-brain--choose-entry-by-parent (parent)
  "Choose a brain entry from children of PARENT."
  (org-brain-choose-entry
   "Entry: "
   (org-brain-children (vulpea-brain--as-entry parent))
   nil
   t))

(defun vulpea-brain--is-transitive-child-of (child parent)
  "Returns non-nil, when CHILD is a transitive child of PARENT."
  (let ((children (org-brain-children (vulpea-brain--as-entry parent))))
    (if (seq-contains children child #'vulpea-brain--entry-id-equal)
        t
      (seq-some (lambda (new-parent)
                  (vulpea-brain--is-transitive-child-of child new-parent))
                children))))

(defun vulpea-brain--transitive-children (parent)
  "Returns list of transitive children of PARENT."
  (seq-mapcat
   (lambda (entry)
     (seq-concatenate
      'list
      (list entry)
      (vulpea-brain--transitive-children entry)))
   (org-brain-children (vulpea-brain--as-entry parent))))

(defun vulpea-brain--as-entry (entry-or-id)
  "Returns brain entry."
  (if (stringp entry-or-id)
      (org-brain-entry-from-id entry-or-id)
    entry-or-id))

(defun vulpea-brain--as-id (entry-or-id)
  "Returns identifier of ENTRY-OR-ID."
  (if (stringp entry-or-id)
      entry-or-id
    (org-brain-entry-identifier entry-or-id)))

(defun vulpea-brain--entry-id-equal (a b)
  "Returns non-nil, when id of A equals id of B."
  (string-equal (vulpea-brain--as-id a)
                (vulpea-brain--as-id b)))



(defvar vulpea-places-config
  '(("country" . "EC4A5BD7-71C4-479A-8BBB-8F022E78F52D")
    ("province" . "5C3F532B-4BB6-46F5-8A0C-741501299EC2")
    ("prefecture" . "9BF13CFD-A3FB-4103-8C8D-4B4ABCA2566C")
    ("county" . "F758B504-77A7-4919-9D98-BF555BC61E3F")
    ("township" . "915880E1-B7AE-4013-A11A-BA99D8DB929F")
    ("village" . "342CB150-A231-41D9-B275-334F0EC057FE")
    ("mountain" . "D8D1A193-81A3-47AE-9E14-892948FA4A1F")
    ("lake" . "D190F748-9223-4AAC-844F-0F3AEECBBF14")))

(defun vulpea/set-place-dwim ()
  (interactive)
  (let* ((level (completing-read "Level: " (seq-map #'car vulpea-places-config) nil t))
         (level-id (cdr (assoc-string level vulpea-places-config)))
         (level-entries (seq-map (lambda (x)
                                   (cons (car x)
                                         (org-brain-entry-from-id (cdr x))))
                                 vulpea-places-config))
         (entry (vulpea-brain--choose-entry-by-parent level-id))
         (entry-id (org-brain-entry-identifier entry)))
    (seq-do
     (lambda (x)
       (org-set-property (upcase (car x))
                         (vulpea-brain--make-link (cdr x))))
     ;; list of (level . specific-place-id) to set
     (seq-map
      (lambda (level-cfg)
        (cons (car level-cfg)
              (car (seq-filter
                    (lambda (e)
                      (vulpea-brain--is-transitive-child-of entry-id e))
                    (org-brain-children (cdr level-cfg))))))
      ;; list of levels to set
      (seq-filter
       (lambda (level-cfg)
         (and (not (string-equal level (car level-cfg)))
              (vulpea-brain--is-transitive-child-of entry-id (cdr level-cfg))))
       level-entries)))

    ;; set the level value
    (org-set-property (upcase level)
                      (vulpea-brain--make-link entry))))



(defvar vulpea-properties-order
  '("ID" "CUSTOM_ID"
    "TEA_GROUP"
    "TAG"
    "NAME" "NAME_ORIGINAL" "NAME_TRANSCRIPTION" "NAME_MEANING"
    "YEAR_GATHERED" "YEAR_MANUFACTURED"
    "PRESSING"
    "COUNTRY" "PROVINCE" "PREFECTURE" "COUNTY" "TOWNSHIP" "VILLAGE" "MOUNTAIN" "LAKE" "PLACE"
    "RATE"
    "PRICE"
    "AVAILABLE" "TOTAL_IN" "TOTAL_OUT"))

(defun vulpea/sort-entry-properties ()
  "Sort properties in entry at point."
  (interactive)
  (let ((p0 (car (org-get-property-block)))
        (p1 (- (cdr (org-get-property-block)) 1))
        (props (org-entry-properties))
        (maxv (seq-length vulpea-properties-order))
        (pregx "^:\\([a-zA-Z_\\-]+\\):.*$"))
    (save-excursion
      (save-restriction
        (narrow-to-region p0 p1)
        (goto-char (point-min))
        (let ;; To make `end-of-line' and etc. to ignore fields.
            ((inhibit-field-text-motion t))
          (sort-subr
           nil 'forward-line 'end-of-line nil nil
           (lambda (l1 l2)
             (< (or
                 (seq-position vulpea-properties-order
                               (vulpea--match-regexp pregx l1))
                 maxv)
                (or
                 (seq-position vulpea-properties-order
                               (vulpea--match-regexp pregx l2))
                 maxv)))))))))

(defun vulpea/format-entry-properties ()
  "Format properties in entry at point."
  (interactive)
  (let ((p0 (car (org-get-property-block)))
        (p1 (cdr (org-get-property-block))))
    (save-excursion
      (goto-char p0)
      (while (< (point) p1)
        (org-indent-line)
        (forward-line 1)
        (beginning-of-line)))))

(defun vulpea/pretty-entry-properties ()
  "Prettify properties of entry at point.

- `vulpea/format-entry-properties'
- `vulpea/sort-entry-properties'"
  (interactive)
  (vulpea/format-entry-properties)
  (vulpea/sort-entry-properties))

(defun vulpea/pretty-buffer-properties ()
  "Prettify properties of all entries in buffer.

- `vulpea/format-entry-properties'
- `vulpea/sort-entry-properties'"
  (interactive)
  (vulpea--map-outline
   (lambda ()
     (vulpea/format-entry-properties)
     (vulpea/sort-entry-properties))))



(defun vulpea--map-outline (f)
  "Call function F on every outline in buffer."
  (save-excursion
    (beginning-of-buffer)
    (while (search-forward-regexp outline-regexp)
      (funcall f))))

(defun vulpea--match-regexp (regexp val)
  "Get the 1 match from the VAL."
  (let ((s (if (stringp val)
               val
             (buffer-substring (car val) (cdr val)))))
    (string-match regexp s)
    (match-string 1 s)))

(provide 'vulpea)

;;; vulpea.el ends here
