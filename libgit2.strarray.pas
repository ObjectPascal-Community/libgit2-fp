unit LibGit2.StrArray;

{$mode objfpc}{$H+}

interface

uses
	LibGit2.Platform,
	LibGit2.StdInt;

type
	PGitStrArray = ^TGitStrArray;

	TGitStrArray = record
		Strings: PPChar;
		Count:	size_t;
	end;


procedure DisposeStrArray(var StrArray: TGitStrArray);

implementation

procedure Libgit2StrArrayDispose(StrArray: PGitStrArray); cdecl; external LibGit2Dll name 'git_strarray_dispose';

procedure DisposeStrArray(var StrArray: TGitStrArray);
begin
	Libgit2StrArrayDispose(@StrArray);
end;

end.
