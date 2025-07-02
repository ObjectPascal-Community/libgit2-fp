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

type
	size_t  = uintptr_t;
	ssize_t = intptr_t;

	{$I git2/version.inc}
	{$I git2/common.inc}


implementation

function LIBGIT2_VERSION_CHECK(major, minor, revision: Integer): Boolean;
begin
	Result := (LIBGIT2_VERSION_NUMBER >= major * 1000000 + minor * 10000 + revision * 100);
end;

end.
