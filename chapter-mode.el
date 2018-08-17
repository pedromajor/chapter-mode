;;; chapter.el --- Chapter Mode

;; Copyright (C) 2017 Pedro Major

;; Author: Pedro Major <pedro.major@gmail.com>
;; Keywords: notes index
;; Created: 2017-02-01
;; Version: 0.0.1
;; URL: http://github.com/pedromajor/chapter-mode

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A derived fundamental mode for quick note taking, allowing indexing
;; with a centered sentence between -~- delimiters like bellow. Use the
;; key binding `C-c m p' to promote and center the text automatically.
;;
;;                  -~- O capitulo -~-
;;
;; Highlight of words is matched with: _Word_ *Word* `Word'
;;
;; With the kind help of https://www.emacswiki.org/emacs/DerivedMode

;;; Code:
(require 'thingatpt)

(defconst chapter-mode--chapter-marker "-~-")

(defface chapter-mode-chapter-face '((t (:foreground "white")))
  "Chapter face for chapter separation/title")

(defface chapter-mode-code-face '((t (:foreground "#0087AF")))
  "Chapter face for source code")

(defface chapter-mode-highlight-face
  '((t (:foreground "cyan" :background "#1f4f6f" :slant italic)))
  "Chapter face to highlight stuff")

(defface chapter-mode-highlight-face2 '((t (:foreground "#EDAA7F")))
  "Chapter face to highlight stuff")

(defface chapter-mode-unchecked-face '((t (:foreground "#FF007F" :background "#ffefef" :bold t)))
  "Chapter face for unchecked box")

(defface chapter-mode-checked-face '((t (:foreground "#40c7eF" :bold t)))
  "Chapter face for checked box")

(defface chapter-mode-box-face '((t (:foreground "#4aa" :bold nil)))
  "Chapter face for checked box")

(defface chapter-mode-vblock-face
  '((t (:foreground "#40c7eF" :background "#a0f7fF":bold t)))
  "Chapter face for vertical blocks (eg. a quote block)")

(defface chapter-mode-quote-mark-face
  '((t (:foreground "#e0e7f4")))
  "Chapter face for vertical blocks (eg. a quote block)")

(defface chapter-mode-quote-face
  '((t (:foreground "#ec9346")))
  "Chapter face for vertical blocks (eg. a quote block)")

(define-derived-mode chapter-mode fundamental-mode
  "Chapter"
  "Major mode derived from Fundamental to allow chapter navigation"
  (font-lock-add-keywords
   nil
   '(("\s*-~-\s*.+\s.*-~-\s*"           . 'chapter-mode-chapter-face)
     ("`\\([a-z-A-Z-0-9\s]*\\)'*" . 'chapter-mode-code-face)
     ("\s+_\\([a-zA-Z0-9'\s-.]+\\)_\s+" . 'chapter-mode-highlight-face)
     ("^[\s]?+\\*\\(.*\\)\\*" . 'chapter-mode-highlight-face2)
     ("^-\s\\[\s?\\]" . 'chapter-mode-unchecked-face)
     ("^-\s\\[[xX]\\]" . 'chapter-mode-checked-face)
     ("^\\[\\(.*\\)]" 1 'chapter-mode-box-face)
     ("^|\s" . 'chapter-mode-vblock-face)
     ("^|>\s+\\(.+\\)" 1 'chapter-mode-quote-face)
     ("^|>\s+" 0 'chapter-mode-quote-mark-face)
     ("https?.+" . 'link)
     (".*`\\{3\\}\\(.+\n*.*\\)*\n" 1 'chapter-mode-code-face)))
  (add-to-list 'imenu-generic-expression
               '("Chapter" "-~-\s*\\(.+\\)\s.*-~-" 1) t)
  (add-to-list 'imenu-generic-expression
               '("Topic" "^\\*\\(.+\\)\\*" 1) t))

(defun chapter-mode--extract-from (region-type)
  "Extracts the text marked or found by `REGION-TYPE'
`REGION-TYPE' can take the values: 'word 'sentence"
  (cond
   ((region-active-p)
    (delete-and-extract-region (region-beginning)
                               (region-end)))
   (t
    ;; fix when no next line after region
    (end-of-line) (new-line-dwim) (previous-line)
    (destructuring-bind
        (b . e) (bounds-of-thing-at-point region-type)
      (if e
          (delete-and-extract-region b e))))))

(defun chapter-mode-promote ()
  "Promotes sentence to chapter"
  (interactive)
  (when-let (text (chapter-mode--extract-from 'sentence))
    (insert (concat chapter-mode--chapter-marker
                    " " text " "
                    chapter-mode--chapter-marker))
    (center-line) (newline) (newline)
    (message "Promoted to chapter")))

(defun chapter-mode--mark-thing-at-point ()
  (interactive)
  (when (not (use-region-p))
    (let ((b (bounds-of-thing-at-point 'sentence)))
      (goto-char (car b))
      (set-mark (cdr b)))))

(defun chapter-mode-promote-2 ()
  "Promotes sentence to chapter variation 2"
  (interactive)
  (save-excursion
    (center-line)
    (beginning-of-line)
    (insert (concat chapter-mode--chapter-marker " "))
    (end-of-line)
    (while (< (current-column) (- fill-column 3))
      (insert " "))
    (insert chapter-mode--chapter-marker)))

(defun chapter-mode-insert-mode-header ()
  (interactive)
  (save-excursion
    (beginning-of-buffer)
    (goto-char (point-min))
    (insert (format "-*- %s -*-\n" mode-name))))

(defun chapter-mode-mark-1 ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (insert "|> ")))

(define-key chapter-mode-map (kbd "C-c m p")
  #'chapter-mode-promote)

(define-key chapter-mode-map (kbd "C-c m i h")
  #'chapter-mode-insert-mode-header)

(require 'hydra)
(defhydra hydra-chapter-mode (chapter-mode-map "C-c m")
  ("o" chapter-mode-promote "Promote to Chapter")
  ("p" chapter-mode-promote-2 "Promote to Chapter V2")
  ("m1" chapter-mode-mark-1  "|>")
  ("h" hydra-chapter-mode/body))

(provide 'chapter-mode)
