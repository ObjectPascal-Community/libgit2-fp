{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit libgit2_fp;

{$warn 5023 off : no warning about unused units}
interface

uses
  LibGit2, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('libgit2_fp', @Register);
end.
