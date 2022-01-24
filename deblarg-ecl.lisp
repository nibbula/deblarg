;;;
;;; deblarg-ecl.lisp - Embedded Common Lisp specific parts of the debugger.
;;;

(in-package :deblarg)

(defclass ecl-deblargger (deblargger)
  ()
  (:documentation "Deblargger for ECL."))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *deblargger-implementation-class* 'ecl-deblargger))

(defparameter *stack-base* 0)

(defun env-assoc (arg env)
  (loop :for a :in env
     :when (and (consp a)
		(equal (prin1-to-string (car a)) (prin1-to-string arg)))
     :return (cdr a)))

(defun ecl-args (func frame)
  "Return a list of (ARG-NAME-STRING . VALUE) for each argument of FUNC in
stack frame number FRAME."
  (let* ((ff (or (and (symbolp func) (fboundp func) (fdefinition func))
		 (and (functionp func) func)))
	 (ll (ignore-errors (si::function-lambda-list func)))
	 (env (when ll (si::decode-ihs-env (si::ihs-env frame)))))
    (loop :with arg
       :for a :in ll
       :do
       ;; (setf arg (assoc (prin1-to-string a) env :test #'equal))
       (setf arg (env-assoc a env))
       :when arg
       :collect arg)))

;; @@@ This isn't really good yet.
(defun print-frame (frame &optional (stream *debug-io*))
  (let* ((func (si::ihs-fun frame))
	 (funcp (or (functionp func) (and (symbolp func) (fboundp func))))
	 (args (when funcp (ecl-args func frame))))
    (if funcp
	(progn
	  (format stream "(~(~s~)" func)
	  (loop :for a :in args :do
	     (format stream " ~s" (cdr a)))
	  (format stream ")"))
	(format stream "~s" func))))

(defmethod debugger-backtrace ((d ecl-deblargger) n)
  (loop
     :with top = (if n (min n (si::ihs-top)) (si::ihs-top))
     :for frame :from top :above 1
     :and i = 0 :then (1+ i)
     :do 
     (with-simple-restart
	 (skip-printing-frame "Skip printing deblarg frame ~d" i)
       (print-stack-line (cons i
			       (with-output-to-fat-string (str)
				 (print-frame frame str)))))))

(defmethod debugger-old-backtrace ((d ecl-deblargger) n)
  ;; (loop :for i :from 0 :below (min (si::ihs-top) n)
  ;;    :do (format *debug-io* "~a ~a~%" (si::ihs-fun i) #|(ecl-args i)|#))
  (let* ((top (if n (min n (si::ihs-top)) (si::ihs-top)))
	 (stack (reverse (loop :for i :from 1 :below top
			    :collect (si::ihs-fun i)))))
    (loop :for s :in stack :and i = 0 :then (1+ i)
       :do (format *debug-io* "~3d: ~w~%" i s))))

(declaim (inline debugger-internal-frame))
(defun debugger-internal-frame ()
  ;; We don't want to be sorry here, so just be wrong.
  #-(or sbcl ccl) nil)

(defmethod debugger-hook ((d (eql 'ecl-deblargger)))
  ;; *debugger-hook*
  ext:*invoke-debugger-hook*)

(defmethod debugger-set-hook ((d (eql 'ecl-deblargger)) function)
  (setf ext:*invoke-debugger-hook* function))

;; EOF
