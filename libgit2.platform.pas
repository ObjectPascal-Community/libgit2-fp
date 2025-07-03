unit LibGit2.Platform;

{$mode objfpc}{$H+}

interface

const
	{$IF DEFINED(MSWINDOWS)}
	LibGit2Dll = 'libgit2.dll';
	{$ELSEIF DEFINED(MACOS)}
	LibGit2Dll = 'libgit2.dylib';
	{$ELSE}
	LibGit2Dll = 'libgit2.so';
	{$ENDIF}

implementation

end.
