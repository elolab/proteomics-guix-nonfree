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


(define-module (proteomics-guix-nonfree packages diann)
  #:use-module (proteomics-guix-nonfree packages diapysef)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (gnu packages machine-learning)
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
  #:use-module (guix utils)
  #:use-module (gnu packages python)
  #:use-module (gnu packages bootstrap)
  #:use-module (guix build-system copy))



(define license (@@ (guix licenses) license))
(define* (nonfree uri #:optional (comment ""))
  "Return a nonfree license, whose full text can be found
at URI, which may be a file:// URI pointing the package's tree."
  (license "Nonfree"
           uri
           (string-append
	    "This a nonfree license.Check the URI for details.  "
            comment)))


(define-public diann-nonfree
  (package
    (name "diann-nonfree")
    (version "1.8.1")
    (home-page "https://github.com/vdemichev/DiaNN")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
	     "https://github.com/vdemichev/DiaNN/releases/download/" version "/diann_" version ".tar.gz"))
       (sha256
	(base32
	 "0b5va3jj47hdac0g28jjg7a9zg9mjkpk7sfljyj3m7xfj48rl8zv"

	 ))))

    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
    #:install-plan
    ''(("diann-1.8.1" "share/diann")
       ("unimod.obo" "share/")
       ;; symbol mismatch in guix's libtorch_cpu.so,
       ;; so we need to use the bundled one
       ("libtorch_cpu.so" "lib/")
       ;; also from libtorch
       ("libc10.so" "lib/"))
    #:phases
    (let ((python-version (version-major+minor (package-version python))))
      #~(modify-phases
	    %standard-phases
	  (add-before 'install 'chmod-bin
	    (lambda _
	      (for-each
	       (lambda (x)
		 (chmod x #o777))  
		 (find-files "." "^diann-1.8.1$"))))
	  (add-after 'install 'patch-elf
	    (lambda _
	      (let*
		  ((ld.so (string-append #$(this-package-input "glibc")
					 #$(glibc-dynamic-linker)))
		   (site-packages (string-append "/lib/python"
                                                      #$python-version
                                                      "/site-packages"))
		   ;;(interpreter (car (find-files #$(this-package-input "glibc") "ld-linux.*\\.so")))
		   (binary (car (find-files #$output "^diann$")))
		   (rpath  
		    (string-join
		     (list
		      (string-append #$(this-package-input "bruker-tims-sdk") "/lib")
		      (string-append (ungexp (this-package-input "gcc") "lib") "/lib")
		      (string-append #$(this-package-input "glibc") "/lib")
		      (string-append #$output "/lib"))
		     ":")))

		(define (patch-elf file)
                  (format #t "Patching ~a ..." file)
                  (unless (string-contains file ".so")
                    (system* "patchelf" "--set-interpreter" ld.so file))
                  (invoke "patchelf" "--set-rpath" rpath file)
                  (display " done\n"))
		
		(symlink (search-input-file %build-inputs "/lib/libgomp.so.1")
			 (string-append #$output "/lib/libgomp-52f2fd74.so.1"))
		;; diann requires unimod.obo in same dir,
		;; but we dont want it in $PATH so put diann in share and symlink it to bin
		(mkdir-p (string-append #$output "/bin"))
		(symlink (string-append #$output "/share/diann")
			 (string-append #$output "/bin/diann"))
		(for-each (lambda (file)
                            (when (elf-file? file)
                              (patch-elf file)))
                          (find-files #$output "\\.so$"))
		(patch-elf binary))))))))
    (native-inputs (list patchelf))
    (license (nonfree home-page))
    (synopsis "Software suite for data-independent acquisition (DIA) proteomics data processing.")
    (description synopsis)
    (inputs
     (list
      glibc
      ;;python-pytorch-for-r-torch
      bruker-tims-sdk
      `(,gcc "lib")))))
      
      

    
       
	      
