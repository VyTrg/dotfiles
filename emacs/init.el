;; Add Nano-Emacs to the load path
(add-to-list 'load-path "~/.emacs.d/lisp/nano-emacs")

;; Load Nano-Emacs
(require 'nano)
(require 'nano-faces)

;;components
(require 'nano-layout)
(require 'nano-modeline)
(require 'nano-splash)
(require 'nano-help)

;;behavior + setting
(require 'nano-defaults)
(require 'nano-session)
(require 'nano-bindings)

;;modes
;;(require 'nano-writer)
;;(add-hook 'org-mode-hook 'writer-mode)

;;init
;;(nano-theme-set-light)


