;; Copyright (C) 2024

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(define-module (unelo-proteomics-nonfree packages diatracer)
  #:use-module (guix packages)
  #:use-module (unelo-proteomics-nonfree packages diapysef)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (gnu packages java)
  #:use-module (gnu packages bash)
  #:use-module (guix gexp)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (ice-9 match)
  #:use-module (guix derivations)
  #:use-module (guix packages)
  #:use-module (guix store)
  #:use-module (guix monads)
  #:use-module (guix gexp)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  )

(define* (just-error-if-not-in-store #:key recursive?)
  (lambda*  
      (ref hash-algo hash
	   #:optional name
	   #:key (system (%current-system))
	   (guile (default-guile)))

    (mlet %store-monad ((guile (package->derivation (or guile (default-guile)) system)))
      (gexp->derivation
       (or name "just-error")
       #~(begin
	   (error (string-append "source of package " #$output   "is not downloadable\n")
		  "please manually dowload it, and call 'guix download' on the file."))
       #:script-name "fail"
       #:system system
       #:local-build? #t ;don't offload repo cloning
       #:hash-algo hash-algo
       #:hash hash
       #:recursive? recursive?
       #:env-vars '()
       #:leaked-env-vars '()

       #:guile-for-build guile))))



(define license (@@ (guix licenses) license))
(define* (undistributable uri #:optional (comment ""))
  "Return a nonfree license, whose full text can be found
at URI, which may be a file:// URI pointing the package's tree."
  (license "Nonfree Undistributable"
           uri
           (string-append
	    "This a nonfree license.  This package may NOT be redistributed "
            "in prebuilt form.  Check the URI for details.  "
            comment)))

  

(define-public diatracer
  (package
    (name "diatracer")
    (home-page "https://github.com/Nesvilab")
    (version "1.1.3")
    (source
     (origin
       (method (just-error-if-not-in-store))
       (file-name "diaTracer-1.1.3.jar")
       (uri     "diaTracer-1.1.3.jar")
       (sha256 (base32
		"05ydhvvm9sjfl4wrqr3pmf3fjg46blwjvlv7lg26npysk2yiq3qg"
		 ))))
    (build-system trivial-build-system)
    (description (string-append "Please manually download " name "-" version " from" home-page " and run 'guix download' on it, for this package to be able to build."))
    (synopsis "DIAtracer turns timstof diapasef data into DDA type data.")
    (license (undistributable "baaaah"))
    (arguments
     (list
      ;; not substitutable because jar is behind a confirmation wall
      ;; #:substitutable? #f 
      #:modules
	'((guix build utils))
       #:builder
       #~(begin
	 (use-modules (guix build utils))
	 (let* (;;(out (assoc-ref %outputs "out"))
		(output-share (string-append %output "/share"))
		(output-lib (string-append %output "/lib"))
		(out-jar (string-append output-share "/diatracer.jar"))
		(executable (string-append %output "/bin/diatracer"))
		)
	   (mkdir-p output-share)
	   (mkdir-p output-lib)
	   (symlink (search-input-file %build-inputs "/lib/libtimsdata.so")
		    (format #f "~a/libtimsdata-2-21-0-4.so" output-lib))
	   (copy-file (assoc-ref %build-inputs  "source") out-jar)
;;	   (copy-file (search-input-file %build-inputs "libtimsdata
	   (mkdir-p (string-append %output "/bin"))
	   ;;(install-file diaumpire-se-jar output-share)
	   ;;(rename-file diaumpire-se-jar diaumpire-out-jar)
	   (with-output-to-file executable
      (lambda _
	(format #t "\
#!~a
JAVA_OPTS_HERE=\"\"
# find '--' in arguments, put everything before in JAVA_OPTS
while [ \"$1\"x != \"--x\" ] && [ \"$#\" -gt 0 ]; do
     JAVA_OPTS_HERE=\"$JAVA_OPTS_HERE $1\"
     shift 1
done
# if '--' was found, skip it
if [ \"$#\" -gt 0 ]; then
	shift 1;
fi
export LD_LIBRARY_PATH=~a
~a $JAVA_OPTS_HERE -jar ~a $@"
		
		#;"\
#!~a
		~a -jar ~a $@"
 		(search-input-file %build-inputs "/bin/sh")
		output-lib
		(search-input-file %build-inputs "/bin/java")
	        out-jar)))
	   (chmod executable #o555)
	   #t
	   ))))
    (inputs (list openjdk11 bash bruker-tims-sdk))))

diatracer
