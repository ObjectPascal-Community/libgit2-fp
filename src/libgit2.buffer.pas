unit LibGit2.Buffer;

{$mode objfpc}{$H+}{$modeswitch advancedrecords}

interface

uses
	LibGit2.Platform,
	LibGit2.StdInt;

type
	PGitBuf = ^TGitBuf;

	TGitBuf = record
		Ptr:		Pansichar;
		Reserved: size_t;
		Size:	  size_t;
	end;

	TGitBufHelper = record helper for TGitBuf
		procedure Dispose;
		function ToString: String;
		function Length: size_t;
		function IsEmpty: Boolean;
	end;

implementation

procedure Libgit2BufferDispose(Buffer: PGitBuf); cdecl; external LibGit2Dll name 'git_buf_dispose';

procedure TGitBufHelper.Dispose;
begin
	if Self.Ptr <> nil then
	begin
		Libgit2BufferDispose(@Self);
		Self := Default(TGitBuf);
	end;
end;

function TGitBufHelper.ToString: String;
begin
	if Ptr = nil then
	begin
		Result := '';
	end
	else
	begin
		Result := StrPas(Ptr);
	end;
end;

function TGitBufHelper.Length: size_t;
begin
	Result := Size;
end;

function TGitBufHelper.IsEmpty: Boolean;
begin
	Result := (Ptr = nil) or (Size = 0);
end;

end.
