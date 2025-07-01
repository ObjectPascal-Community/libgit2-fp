unit LibGit2;

{$mode objfpc}{$H+}

interface

uses
	CTypes,
	SysUtils;

const
	{$IFDEF MSWINDOWS}
	LibGit2Dll = 'libgit2.dll';
	{$ELSEIF DEFINED(MACOS)}
	LibGit2Dll = 'libgit2.dylib';
	{$ELSE}
	LibGit2Dll = 'libgit2.so';
	{$ENDIF}

	{$I git2/stdint.inc}


implementation

end.
