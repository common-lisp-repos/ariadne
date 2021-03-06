;;;; Ariadne Web Server
;;;; Configuration File Manager
;;;; By Tylor Kobierski

;;;; Loads the config file plist
;;;; Placing it into a hashtable

(in-package :ariadne)

(defclass <ariadne-config> (<middleware>)
  ((config-file
    :initarg :config-file
    :initform "./settings.lisp"
    :reader  config-file
    :documentation "The settings file to read in")
   (config-data
    :initform (make-hash-table)
    :accessor config-data
    :documentation "The actual settings in a property list format"))
  (:documentation "The Ariadne Configuration File Manager"))

(defmethod call ((this <ariadne-config>) env)
  ;; Load configuration and place it onto the environment
  ;; The config module uniquely should not interact through API calls.
  ;; Consideration: Config should be loaded once in a global parameter
  ;;                If we do this, then it would be necessary to update
  ;;                it manually each time it changed.

  (load-config this)
  (setf (getf env :ariadne.config) (config-data this))
  (let ((response (call-next this env)))
    (declare (ignore response))
    ;; Do nothing
    ))


(defgeneric load-config (this)
  (:documentation "Loads a configuration file as a plist"))
(defmethod load-config ((this <ariadne-config>))
  (let ((read-data     nil)
	(keylist       nil)
	(vallist       nil))

    (with-open-file (config-stream 
		     (cl-fad:pathname-as-file "./Projects/ariadne/settings.lisp")
		     :direction :input)
      (with-standard-io-syntax
	(setq read-data (read config-stream))))

    ;; Sort keywords and their values into separate lists
    (mapcar #'(lambda (x)
		(if (keywordp x)
		    (push x keylist)
		    (push x vallist))
		x)
	    read-data)
    
    ;; Associate all the list items into a hash table
    (do ((i           0               (incf i))
	 (current-key (elt keylist 0) (elt keylist i))
	 (current-val (elt vallist 0) (elt vallist i)))
	((eql i (length keylist)) nil)
      (setf (gethash current-key (config-data this)) current-val))))

