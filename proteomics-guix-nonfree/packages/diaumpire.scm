(define-module (proteomics-guix-nonfree packages diaumpire)
  #:use-module (guix packages)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (gnu packages java)
  #:use-module (gnu packages bash)
  #:use-module ((guix licenses)
                #:prefix license:)
  )

;; this is not a nonfree package, but unable to be built with guix atm.
;; sorry about this.
;; dia-umpire is built with gradle
;; and guix doesn't yet support that because of circular depencies
;; that haven't been detangled yet.
;; https://guix.gnu.org/blog/2019/reproducible-builds-summit-5th-edition/
;; https://framagit.org/tyreunom/guix-more/-/tree/master
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

(define-public diaumpire-se
  (package
    (name "diaumpire-se")
    (home-page "https://github.com/Nesvilab/DIA-Umpire")
    (version "2.2.8")

    (source
     (origin
       (method url-fetch)
       (uri (string-append 
	     "https://github.com/Nesvilab/DIA-Umpire/releases/download/v"
	     version
	     "/DIA_Umpire_SE-"
	     version
	     ".jar"))
       (sha256 (base32
		"0jjl937i2maazwlcrspmwmdbfb2fb0ipvclvnijp2m07b4ndlg0l"
		))))
    (build-system trivial-build-system)
    (description "diaumpire se")
    (synopsis description)
    (license license:gpl3+)
    (arguments
     `(#:modules
       ((guix build utils))
       #:builder
       (begin
	 (use-modules (guix build utils))
	 (let* (;;(out (assoc-ref %outputs "out"))
		(output-share (string-append %output "/share"))
		(diaumpire-out-jar (string-append output-share "/DIA_Umpire_SE.jar"))
		(diaumpire-se-executable (string-append %output "/bin/diaumpire-se"))
		)
	   (mkdir-p output-share)
	   (copy-file (assoc-ref %build-inputs  "source") diaumpire-out-jar)
	   (mkdir-p (string-append %output "/bin"))
	   ;;(install-file diaumpire-se-jar output-share)
	   ;;(rename-file diaumpire-se-jar diaumpire-out-jar)
	   (with-output-to-file diaumpire-se-executable
      (lambda _
	(format #t "\
#!~a
JAVA_OPTS_HERE=\"\"
while [ \"$#\" -gt 2 ]; do
     JAVA_OPTS_HERE=\"$JAVA_OPTS_HERE $1\"
     shift 1
done
~a $JAVA_OPTS_HERE -jar ~a $@"
 		(search-input-file %build-inputs "/bin/sh")
		(search-input-file %build-inputs "/bin/java")
		diaumpire-out-jar)))
	   (chmod diaumpire-se-executable #o555)
	   #t
	   ))))
    (inputs (list openjdk11 bash))))

diaumpire-se
