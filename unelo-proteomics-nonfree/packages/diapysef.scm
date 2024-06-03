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

;; look at (nvidia-driver)

(define-module (unelo-proteomics-nonfree packages diapysef)
  #:use-module (unelo-proteomics packages openms)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system python)
  #:use-module (guix build-system pyproject)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages bootstrap)
  #:use-module (guix build-system copy))


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



(define-public bruker-tims-sdk
  (package
    (name "bruker-tims-sdk")
    (version "0.0.1")
    (license (undistributable "file://LICENCE-BRUKER.txt"
		      "You are specifically prohibited from distributing the Software or Software Libraries with any software that is
subject to the GNU General Public License (GPL) or similar license in a manner that would create a
combined work."))
    (synopsis "Bruker software development kit for TIMStof results")
    (description synopsis)
    (home-page "bruker.org")
    (source (origin
	      (method git-fetch)
	      (uri (git-reference
		    (url "https://github.com/MatteoLacki/timsdata/")
		    (commit "2949f16f5a34c478926d51f0b6bca10f34f11e40")))
	      (sha256
	     (base32 "1y1lk35hg02325004r0xhl0yk7r5ricmplglz3nvkrnkg8b36srk"))))
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (native-inputs (list patchelf))
    (inputs
     (list
      `(,gcc "lib")
       glibc))
    (arguments
     (list
      #:install-plan
      ''(("./timsdata/cpp/" "lib/" #:include-regexp (".so$")))
      #:phases
      #~(modify-phases
	    %standard-phases
	  (add-before 'install 'chmod-so
	    (lambda _
	      (for-each
	       (lambda (x)
		 (chmod x #o777))  
		 (find-files "./timsdata/cpp/" ".so$"))))
	  (add-after 'install 'patch-elf
	    (lambda _
	      (let*
		  ((ld.so (string-append #$(this-package-input "glibc")
					 #$(glibc-dynamic-linker)))
		   (rpath  
		    (string-join
		     (list
		      (string-append #$output "/lib")
		      (string-append (ungexp (this-package-input "gcc") "lib") "/lib")
		      (string-append #$(this-package-input "glibc") "/lib"))
		     ":")))
		(define (patch-elf file)
                  (format #t "Patching ~a ..." file)
                  (unless (string-contains file ".so")
                    (invoke "patchelf" "--set-interpreter" ld.so file))
                  (invoke "patchelf" "--set-rpath" rpath file)
                  (display " done\n"))
                (for-each (lambda (file)
                                 (when (elf-file? file)
                                   (patch-elf file)))
                          (find-files #$output "\\.so$"))))))))))

(define-public python-diapysef
  (package
    (name "python-diapysef")
    (version "1.0.10")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "diapysef" version))
       (sha256
        (base32 "1m50dwn7wwlzc1wjayz8czsiks82ya68qr0awzrvsf0kbnf07rwx"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
	  (add-after 'unpack 'replace-libtims-so-with-store-path
	    (lambda _
	      (substitute* (find-files "." "\\.py$")
		(("libtimsdata.so" all)
		 (car (find-files #$(this-package-input "bruker-tims-sdk")
				  all)))))))))
      (inputs
       (list
	bruker-tims-sdk))
      (propagated-inputs (list python-click
                               python-joblib
                               python-matplotlib
                               python-numpy
                               python-pandas
                               python-patsy
                               `(,openms "python")
                               python-scikit-image
                               python-scipy
                               python-seaborn
                               python-statsmodels
                               python-tqdm))
    (home-page "https://github.com/Roestlab/dia-pasef")
    (synopsis "Analysis, conversion and visualization of diaPASEF data.")
    (description
     "Analysis, conversion and visualization of @code{diaPASEF} data.")
    (license license:expat)))



bruker-tims-sdk	  
python-diapysef
