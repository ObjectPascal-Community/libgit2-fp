unit LibGit2.Buffer;

{$mode objfpc}{$H+}

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

const
	GitInitBuf: TGitBuf = (Ptr: nil; Reserved: 0; Size: 0);

procedure DisposeBuffer(var Buffer: TGitBuf);

implementation

procedure Libgit2BufferDispose(Buffer: PGitBuf); cdecl; external LibGit2Dll name 'git_buf_dispose';

procedure DisposeBuffer(var Buffer: TGitBuf);
begin
	if Buffer.Ptr <> nil then
	begin
		Libgit2BufferDispose(@Buffer);
		FillChar(Buffer, SizeOf(Buffer), 0);
	end;
end;

end.
