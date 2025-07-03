{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

Unit libgit2_fp;

{$warn 5023 off : no warning about unused units}
Interface

uses
      LibGit2, LibGit2.Common, LibGit2.StdInt, LibGit2.Version, LibGit2.Platform, LibGit2.Buffer, LibGit2.Alloc, 
      LibGit2.StrArray, LazarusPackageIntf;

Implementation

Procedure Register;
Begin
End;

Initialization
  RegisterPackage('libgit2_fp', @Register);
End.
