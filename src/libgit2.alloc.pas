unit LibGit2.Alloc;

{$mode objfpc}{$H+}

interface

uses
	LibGit2.StdInt;

type
	TGitMalloc = function(n: size_t; const file_: Pansichar; line: Integer): Pointer; cdecl;
	TGitRealloc = function(ptr: Pointer; size: size_t; const file_: Pansichar; line: Integer): Pointer; cdecl;
	TGitFree = procedure(ptr: Pointer); cdecl;

	TGitAllocator = record
		gmalloc:  TGitMalloc;
		grealloc: TGitRealloc;
		gfree:	 TGitFree;
	end;
	PGitAllocator = ^TGitAllocator;

implementation

end.
