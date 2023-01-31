;;;								-*- Lisp -*-
;;; deblarg.asd -- System definition for deblarg
;;;

(defsystem deblarg
    :name               "deblarg"
    :description        "Command line Lisp debugger."
    :version            "0.2.0"
    :author             "Nibby Nebbulous <nibbula -(. @ .)- uucp!gmail.com>"
    :license            "GPL-3.0-only"
    :source-control	:git
    :long-description
    "The “Dynamic Environment Belated Lisp Activation Record Grappler”.

This exists because I wanted command line editing in the debugger from my
REPL. It does afford one that modicum of efficacy, but scant else. Another
smidgeon of utility is a uniform interface between platforms. Otherwise, it is
quite lacking of features."
    :depends-on
    (:dlib :char-util :keymap :dlib-misc :table-print :opsys :terminal
     :terminal-ansi :terminal-crunch :terminal-table :rl :collections :ochar
     :fatchar :fatchar-io :tiny-repl :reader-ext :source-path
     #+sbcl :sb-introspect)
    :components
    ((:file "package")
     (:file "base" :depends-on ("package"))
     (:file "deblarg" :depends-on ("base" "package"))
     (:module "impl"
      :pathname ""
      :depends-on ("package" "base" "deblarg")
      :components
      ((:file "deblarg-sbcl"   :if-feature :sbcl)
       (:file "deblarg-ccl"    :if-feature :ccl)
       (:file "deblarg-ecl"    :if-feature :ecl)
       (:file "deblarg-clisp"  :if-feature :clisp)
       (:file "deblarg-others" :if-feature
	      (:not (:or :sbcl :ccl :ecl :clisp)))))))
