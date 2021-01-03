;;;
;;; base.lisp - Things that need to be defined before the system specific code.
;;;

(in-package :deblarg)

(declaim
 (optimize (speed 0) (safety 3) (debug 3) (space 0) (compilation-speed 0)))

(defstruct thread
  "Per thread state."
  repeat-condition
  repeat-restart)

(defstruct deblargger
  "Debugger state."
  current-frame
  saved-frame
  condition
  term
  (visual-mode nil :type boolean)
  visual-term)

(defvar *deblarg* nil
  "The current debugger instance.")

(defvar *thread* nil
  "Per thread state.")

;; (defvar *interceptor-condition* nil
;;   "The condition that happened.")

;; @@@ Do we really need this separate here? Could we just use *terminal*
;; in with-new-terminal?
(defvar *debug-term* nil
  "*debug-io* as a terminal.")

(defvar *dont-use-a-new-term* nil
  "Prevent the debugger from opening a new terminal.")

(defmacro with-new-debugger-io ((d) &body body)
  "Evaluate BODY with a new *terminal* redirected to *debug-io*."
  (with-unique-names (thunk)
    `(flet ((,thunk () ,@body))
       (if *dont-use-a-new-term*
	   (progn
	     (setf (deblargger-term ,d) *terminal*)
	     (,thunk))
	   (let ((fd (nos:stream-system-handle *debug-io*))
		 device-name)
	     (when fd
	       (setf device-name (nos:file-handle-terminal-name fd)))
	     (if device-name
		 ;; @@@ Could we just use *terminal*?
		 (with-new-terminal ((pick-a-terminal-type) *debug-term*
				     :device-name device-name
				     :output-stream
				     (make-broadcast-stream *debug-io*))
		   (setf (deblargger-term ,d) *debug-term*)
		   (,thunk))
		 (with-new-terminal ((pick-a-terminal-type) *debug-term*
				     :output-stream
				     (make-broadcast-stream *debug-io*))
		   (setf (deblargger-term ,d) *debug-term*)
		   (,thunk))))))))

(defmacro with-debugger-io ((d) &body body)
  "Evaluate BODY with *debug-term* set up, either existing or new."
  (with-unique-names (thunk)
    `(flet ((,thunk () ,@body))
       (if *debug-term*
	   (,thunk)
	   (with-new-debugger-io (,d)
	     (,thunk))))))

(defun debugger-sorry (x)
  "What to say when we can't do something."
  (format *debug-io* "~%Sorry, don't know how to ~a on ~a. ~
		       Snarf some slime!~%" x (lisp-implementation-type)))

;; @@@ Figure out some way to make these respect *debug-io*, even when not
;; in the debugger.

(defun debugger-print-string (string)
  (with-slots (term) *deblarg*
    (typecase string
      (string (princ string term))
      (fatchar-string
       (render-fatchar-string string :terminal term))
      (fat-string
       (render-fat-string string :terminal term)))))

(defun print-span (span)
  ;; This doesn't work since some implementations wrap our terminal stream
  ;; with something else before it gets to print-object.
  ;;(princ (span-to-fat-string span) *terminal*)
  (render-fatchar-string (span-to-fatchar-string span)
			 :terminal (deblargger-term *deblarg*)))

(defun display-value (v stream)
  "Display V in a way which hopefully won't mess up the display. Also errors
are indicated instead of being signaled."
  (restart-case
      (typecase v
	;; Make strings with weird characters not screw up the display.
	(string
	 (prin1 (with-output-to-string (str)
		  (loop :for c :across v :do
		     (displayable-char c :stream str
				       :all-control t :show-meta nil)))
		stream))
	(t (prin1 v stream)))
    (error (c)
      (declare (ignore c))
      (return-from display-value
	(format nil "<<Error printing a ~a>>" (type-of v))))))

(defun print-stack-line (line &key width)
  "Print a stack LINE, which is a cons of (line-numbner . string)."
  (destructuring-bind (num . str) line
    (print-span `((:fg-yellow ,(format nil "~3d" num) " ")))
    (debugger-print-string
     (if width
	 (osubseq str 0 (min (olength str) (- width 4)))
	 str))
    ;;(terpri *terminal*)
    (terminal-write-char (deblargger-term *deblarg*) #\newline)))

;; EOF
