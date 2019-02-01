;;; wwp-insert-lb-and-jump-forward-8-words.el --- what it says  -*- lexical-binding: t; -*-

;; © 2018 Syd Bauman

;; Author: Syd Bauman <sbauman@northeastern.edu>
;; Keywords: local

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

;;; Commentary:

;; A one-off program intended to be used to fix the lack of line
;; breaks in scott-s.cornelia.xml.
;;
;; See the README.md file in this directory.

;;; Code:

;; Note that these functions use a space as a surogate for a token as
;; a surogate for a word. That means that the expectation is that
;; there will not be 2+ spaces between words. Luckily I have my Emacs
;; set up so that `fill-paragraph` (bound to M-q) reduces strings of
;; space to single space. So it beehoves you (Syd) to pop off a M-q or
;; a query-replace before using these.

(defun wwp-insert-lb-then-jump-forward-8-words ()
  (interactive)
  ;; If in the middle of a word ...
  (if (not (= (following-char) ? ))
      ;; jump backward to the beginning of it
      (search-backward " "))
  (forward-char 1)			; move to 1st char of word
  (delete-char -1)			; delete space before word
  (insert "\C-j    <lb/>")		; insert newline before word
  ;; Now, move forward 8 blanks (U+0020), using 100 chars from here as
  ;; an upper limit -- i.e., go forward 8 space chars or 100 total
  ;; chars, whichever comes first.
  (search-forward " " (+ (point) 100) 'not-nil-nor-t 8))

(defun wwp-insert-shy-and-lb-then-jump-forward-8-words ()
  (interactive)
  ;; Note that the first character of the string being inserted is
  ;; U+00AD (not U+002D) which is what the WWP uses for soft hyphens.
  ;; You may well want to change that to U+002D, and change the <lb>
  ;; so it has a break='no' attribute.
  (insert "­\C-j    <lb/>")
  (search-forward " " (+ (point) 100) 'not-nil-nor-t 8))

(provide 'wwp-insert-lb-then-jump-forward-8-words)
(provide 'wwp-insert-shy-and-lb-then-jump-forward-8-words)

;;; wwp-insert-lb-and-jump-forward-8-words.el ends here
