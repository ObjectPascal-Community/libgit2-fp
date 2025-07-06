unit LibGit2.StrArray;

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

uses
	LibGit2.Platform,
	SysUtils,
	LibGit2.StdInt;

type
	PGitStrArray = ^TGitStrArray;

	TGitStrArray = record
		Strings: PPChar;
		Count:	size_t;
	end;

	TGitStrArrayHelper = record helper for TGitStrArray
		procedure Dispose; inline;
		function IsEmpty: Boolean; inline;
		function ToArray: TStringArray;
		function Item(Index: SizeInt): String;
	end;


implementation

procedure Libgit2StrArrayDispose(StrArray: PGitStrArray); cdecl; external LibGit2Dll name 'git_strarray_dispose';

procedure TGitStrArrayHelper.Dispose; inline;
begin
	Libgit2StrArrayDispose(@Self);
	Self := Default(TGitStrArray);
end;


function TGitStrArrayHelper.IsEmpty: Boolean; inline;
begin
	Result := (Count = 0) or (Strings = nil);
end;

function TGitStrArrayHelper.ToArray: TStringArray;
var
	i: SizeInt;
begin
	SetLength(Result, Count);
	for i := 0 to Count - 1 do
	begin
		Result[i] := Ansistring(UTF8ToString(Strings[i]));
	end;
end;

function TGitStrArrayHelper.Item(Index: SizeInt): String;
begin
	if (Index < 0) or (Index >= Count) then
	begin
		raise ERangeError.CreateFmt('Index %d out of bounds (0..%d)', [Index, Count - 1]);
	end;
	Result := Strings[Index];
end;

end.
