;;; Copyright © 2016 Dennis Mungai <dmngaie@gmail.com>
;;; Copyright © 2018 Fis Trivial <ybbs.daans@hotmail.com>
;;;
;;; This file is NOT part of GNU Guix.
;;;
;;; This file is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; This file is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with This file.  If not, see <http://www.gnu.org/licenses/>.

(define-module (opencl)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages check)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages mpi)
  #:use-module (gnu packages opencl)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python))


(define-public gmmlib
  (let* ((commit "b32d2124aa5187b20b64df24d2e83bcbe7a57d7d")
         (revision "1")
         (version (git-version "0.0.0" revision commit)))
    (package
      (name "gmmlib")
      (version version)
      (home-page "https://github.com/intel/gmmlib")
      (source (origin
                (method git-fetch)
                (uri (git-reference (url home-page)
                                    (commit commit)))
                (sha256
                 (base32
                  "0d6w7bfp1my3jb8m5wa8ighjr8msq993m0flhfb0d34sackyn7s6"))))
      (build-system cmake-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (delete 'install))           ; No such a phase
         #:tests? #f))                  ; Run automatically.
      (native-inputs `(("googletest" ,googletest)))
      (synopsis "Device specific buffer management for Intel(R) Graphics
Compute Runtime")
      (description "The Intel(R) Graphics Memory Management Library provides
device specific and buffer management for the Intel(R) Graphics Compute Runtime
for OpenCL(TM) and the Intel(R) Media Driver for VAAPI.")
      (license license:non-copyleft))))

(define-public clew
  (let* ((commit "b9bb66beb5cb4bde16315424a57d32d01fda8868")
         (revision "0")
         (version (string-append "1.1.1" revision commit)))
    (package
      (name "clew")
      (version version)
      (home-page "https://github.com/hughperkins/clew.git")
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url home-page)
                      (commit commit)))
                (sha256
                 (base32
                  "0b7jg38g9cjyli79rmymbpkqwap2jp0wrrrlr2dgraxfbzg6rc28"))
                (file-name (git-file-name name version))))
      (build-system cmake-build-system)
      ;; To test it works ok. You'll need at least one OpenCL-enabled device to
      ;; do this bit:
      ;;   open a cmd
      ;;   change into the 'dist' directory you created
      ;;   type 'clewTest' => should see something like 'num platforms: 1'
      (arguments
       `(#:configure-flags
         '("-DBUILD_TESTS=OFF"
           "-DBUILD_SHARED_LIBRARY=ON")
         #:tests? #f))
      (synopsis "The OpenCL Extension Wrangler Library")
      (description "This basically works like glew, but for OpenCL
@itemize
@item You can build opencl code without needing any opencl library or include
files!
@item At runtime, even if there is no opencl-enabled device present, your code
will still run! Of course, you wont be able to do anything opencl-related, but
you wont get any errors about missing dlls and stuff, no linker errors (at
least, not until you try to use a non-existent opencl-enabled device of course)
@end itemize")
      (license license:expat))))		; Not sure, please check

(define-public easycl
  (let* ((commit "d4d47ff25fce4c761c8004ee15ebd12d90ca6f2a")
         (revision "0")
         (version (string-append "1.1.1" revision commit)))
    (package
      (name "easycl")
      (version version)
      (home-page "https://github.com/hughperkins/EasyCL")
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url home-page)
                      (commit commit)))
                (sha256
                 (base32
                  "0c3j4zmqxl5qm0i4i4gn7sahv0hgznk0c59gyhsd4g3268qmw506"))
                (file-name (git-file-name name version))))
      (build-system cmake-build-system)
      ;; To test it, run ./gpuinfo inside build dir.
      (arguments
       `(#:configure-flags
         '("-DUSE_SYSTEM_CLEW=ON")
         #:tests? #f))
      (inputs
       `(("clew", clew)))
      (synopsis "Easy to run kernels using OpenCL.")
      (description "Easy to run kernels using OpenCL. (renamed from
OpenCLHelper)
@itemize
@item makes it easy to pass input and output arguments
@item handles much of the boilerplate
@item uses clew to load opencl dynamically
@end itemize")
      (license license:mpl2.0))))
