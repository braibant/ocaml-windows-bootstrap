# ocaml-windows-bootstrap

From a powershell, run
```

set-executionpolicy remotesigned
.\bootstrap.ps1
```

This installs cygwin and the required cygwin packages. Then, from a cygwin terminal, execute `provision.sh`. This should install ocaml and all the opam dependencies (similar to `make lib-ext`). The whole process takes around 15 minutes on a VM. 

From a powershell again, 
```
$env:Path = $env:Path + ";C:\ocaml\bin;C:\cygwin\bin"
$env:HOME = "C:\Users\USER"
```

Then, `opam.exe init` should work.
