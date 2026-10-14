;;;; build-sbcl.lisp -- build the RASP parser image (gde) with SBCL.
;;;; Usage, from rasp3os/:  sbcl --non-interactive --load gde/build-sbcl.lisp
;;;; Writes bin/<arch>/gde-sbcl, an executable that takes the same -e arguments
;;;; as the Clozure CL image.

(let* ((gde-dir (make-pathname :name nil :type nil :defaults *load-truename*))
       (root (merge-pathnames "../" gde-dir))
       (arch (format nil "~(~A~)_~(~A~)"
                     (string-trim '(#\Newline)
                                  (with-output-to-string (s)
                                    (sb-ext:run-program "/usr/bin/uname" '("-m") :output s)))
                     (string-trim '(#\Newline)
                                  (with-output-to-string (s)
                                    (sb-ext:run-program "/usr/bin/uname" '("-s") :output s)))))
       (out (merge-pathnames (format nil "bin/~A/gde-sbcl" arch) root)))
  (ensure-directories-exist out)
  (let ((*default-pathname-defaults* gde-dir))
    (load (merge-pathnames "cgde/load.lsp" gde-dir))
    (load (merge-pathnames "cpar/load.lsp" gde-dir))
    (load (merge-pathnames "../prob/code/load.lsp" gde-dir)))
  (format t "~&Saving ~A~%" (namestring out))
  (funcall (intern "SAVE-GDE-IMAGE" "CL-USER") (namestring out)
           :executable t :save-runtime-options t))
