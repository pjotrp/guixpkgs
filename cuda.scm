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

(define-module (cuda)
  #:use-module (guix download)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix build-system trivial)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bootstrap)
  ;; #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages file)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages perl)
  )

;; (define EULA
;;   (license "EULA"
;; 	   "http://www.nvidia.com/object/nv_sw_license.html"
;; 	   "http://www.nvidia.com/object/nv_sw_license.html"))

(define-private cuda-patch-85-1
  (package
    (name "cuda-patch-85-1")
    (version "9.1.85.1")
    (source
     (origin
       (method url-fetch)
       (uri
	(string-append
	 "https://developer.nvidia.com/compute/cuda/9.1/Prod/patches/1/cuda_"
	 version "_linux"))
       (sha256
	(base32 "1f53ij5nb7g0vb5pcpaqvkaj1x4mfq3l0mhkfnqbk8sfrvby775g"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
	 (replace 'unpack
	   (lambda (#:key inputs outputs #:allow-other-keys)
	     (use-modules (guix build utils))
	     (let* ([source (assoc-ref inputs "source")]
		    [file-name "cuda-patch.run"])
	       (copy-file source file-name))))
	 (delete 'build)
	 (delete 'configure)
	 (replace 'install
	   (lambda (#:key inputs outputs #:allow-other-keys)
	     (let* ([out (assoc-ref outputs "out")])
	       (copy-file "cuda-patch.run" (string-append out "cuda-patch.run")))))
	 (delete 'validate-runpath)
	 (delete 'check))
       #:strip-binaries? #f))
    (home-page "https://developer.nvidia.com/cuda-toolkit")
    (synopsis "Cuda binary patches.")
    (description "Cuda binary patches.")
    (license gpl3+)))


(define-public cuda
  ;; This DOESN'T work yet, due to runpath, I'm kind of running out of idea now.
  (package
    (name "cuda")
    (version "9.1.85")
    (source (origin
	      (method url-fetch)
	      (uri (string-append
		    "https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_"
		    version
		    "_387.26_linux"))
	      (sha256
	       (base32
		"0lz9bwhck1ax4xf1fyb5nicb7l1kssslj518z64iirpy2qmwg5l4"))))
    (build-system gnu-build-system)
    (native-inputs `(
		     ("perl" ,perl)
		     ;; ("bash" ,bash)
		     ;; ("sed" ,sed)
		     ("patchelf" ,patchelf)))
    (inputs `(("gcc:lib" ,gcc-6 "lib")))
    (propagated-inputs `(("gcc:lib" ,gcc-6 "lib")
			 ("gcc:out" ,gcc-6 "out")))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
	 (replace 'unpack
	   (lambda* (#:key inputs outputs #:allow-other-keys)
	     (use-modules (guix build utils))
	     (let* ((source (assoc-ref inputs "source"))
		    (file-name (string-append ,name "-" ,version ".run"))
		    (build-root (getcwd)))
	       (copy-file source (string-append ,name "-" ,version ".run"))

	       (mkdir-p "tmp")
	       (invoke "sh" (string-append "./" ,name "-" ,version ".run")
		       "--keep" "--noexec"
		       "--tmpdir=" (string-append build-root "/tmp")
		       "--verbose")
	       (chdir "pkg/run_files")
	       (invoke "sh" "./cuda-linux.9.1.85-23083092.run" "--keep" "--noexec"
		       "--tmpdir" (string-append build-root "/tmp"))
	       (invoke "sh" "./cuda-samples.9.1.85-23083092-linux.run" "--keep" "--noexec"
		       "--tempdir" (string-append build-root "/tmp"))

	       (invoke "mv" "pkg" (string-append "../../cuda"))
	       (chdir "../../")
	       (invoke "ls" "-l")

	       (invoke "rm" "-rf" "./pkg"))))

	 (delete 'configure)
	 (delete 'build)
	 (replace 'install	; patchelf
	   (lambda* (#:key inputs outputs #:allow-other-keys)
	     (use-modules (ice-9 ftw)
	 		  (ice-9 regex)
	 		  (ice-9 popen)
			  (ice-9 rdelim)) ;for read-line
	     (let* ((ld-so (string-append
	 		    (assoc-ref
	 		     inputs "libc") ,(glibc-dynamic-linker)))
	 	    (gcclib (string-append (assoc-ref
	 	    			    inputs "gcc:lib") "/lib"))
	 	    (out (assoc-ref outputs "out"))
	 	    (rpath (string-append
	 		    gcclib ":"
	 		    (string-append out "/lib64" ":")
	 		    (string-append out "/lib" ":")
	 		    (string-append out "/nvvm/lib64" ":")
	 		    (string-append out "/nvvm/lib"))))
	       (invoke "pwd")
	       (invoke "ls" "-l")
	       (let* ((out (assoc-ref outputs "out")))
		 (chdir "cuda")
		 (invoke "./install-linux.pl" (string-append "--prefix=" out)
	 		 "--noprompt")
		 (chdir out))

	       (invoke "rm" "-rf" (string-append out "lib"))
	       (invoke "rm" "-rf" (string-append out "bin/uninstall*"))

	       ;; (let* ((hd (string-append out "include/host_defines.h"))
	       ;; 	      (sedcommand (string-append "'1 i#define _BITS_FLOATN_H " hd "'")))
	       ;; 	 (invoke "sed" "-i" sedcommand))
	       ;; (invoke "sed" "-i" "'1 i#define _BITS_FLOATN_H" "$out/include/host_defines.h'")
	       ;; (setenv "lib" lib)
	       (format #t "ld-so: ~s\n" ld-so)
	       (format #t "rpath: ~s\n" rpath)
	       (format #t "out: ~s\n" out)
	       (format #t "gcclib: ~s\n" gcclib)
	       (display "\n")
	       (format "cwd ~s\n" (getcwd))
	       (invoke "ls" "-l")
	       ;; (invoke "chmod" "u-x" (string-append out "/libnsight/icon.xpm"))
	       (let ([elf?
		      (lambda (filename)
			(let* ((file-port (open-input-pipe
					   (string-append "file " filename)))
			       (file-return (read-line file-port)))
			  (close-pipe file-port)
			  (if (or (and (zero? (system* "test" "-x" filename))
				       (not (zero? (system* "test" "-d" filename))))
				  (and (not (eof-object? file-return))
				       (string-match "ELF" file-return)))
			      #t
			      #f)))])
		 (nftw "./"
	 	       (lambda (filename statinfo flag base level)
			 (format #t "Testing: ~s\n" filename)
			 (if (elf? filename) ; use if-let
			     (begin
			       (format #t "Filename: ~s is an ELF file.\n" filename)
			       (format #t "CWD: ~s\n" (getcwd))
			       (when (string-match "\\.so" filename)
				 (begin
				   (format #t "patching ~s for interpreter\n" filename)
				   (system* "patchelf" "--set-interpreter" ld-so filename)))
			       (format #t "Patching ~s rpath.\n" filename)
			       (if (string-match "libcudart" filename)
				   (begin
				     (format #t "libcudart? ~s\n" filename)
				     (format #t "rpath: ~s\n" "(nil)")
				     (system* "patchelf" "--set-rpath" " " "--force-rpath" filename))
				   (begin
				     (format #t "Not libcudart\n")
				     (format #t "rpath: ~s\n" rpath)
				     (system* "patchelf" "--set-rpath" rpath filename))))) ; "--force-rpath"
			 #t))))))
	 ;; (add-after 'install 'wrap-program
	 ;;   (lambda* (#:key inputs outputs #:allow-other-keys)
	 ;;     (let* ((out (assoc-ref outputs "out"))
	 ;; 	    (nvcc (string-append out "/bin/nvcc")))
	 ;;       ;; The environment variable DTK_PROGRAM tells emacspeak what
	 ;;       ;; program to use for speech.
         ;;       (wrap-program nvcc
         ;;         `("--prefix" ))
         ;;       #t)))
	 ;; (delete 'validate-runpath)
	 (delete 'check))
       #:strip-binaries? #f))
    (home-page "https://developer.nvidia.com/cuda-toolkit")
    (supported-systems '("x86_64-linux"))
    (synopsis "The NVIDIA® CUDA® Toolkit provides a development environment for
creating high performance GPU-accelerated applications.")
    (description "With the CUDA Toolkit, you can develop, optimize and deploy
your applications on GPU-accelerated embedded systems, desktop workstations,
enterprise data centers, cloud-based platforms and HPC supercomputers. The
toolkit includes GPU-accelerated libraries, debugging and optimization tools,
a C/C++ compiler and a runtime library to deploy your application.")
    (license (list asl2.0
		   gpl3+
		   bsd-3
		   bsd-2
		   unlicense)))) ; Please check out EULA.txt along with distribution.
