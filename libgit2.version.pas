unit LibGit2.Version;

{$mode objfpc}{$H+}

interface

const
	LIBGIT2_VERSION = '1.9.1';
	LIBGIT2_VERSION_MAJOR = 1;
	LIBGIT2_VERSION_MINOR = 9;
	LIBGIT2_VERSION_REVISION = 1;
	LIBGIT2_VERSION_PATCH = 0;

	LIBGIT2_VERSION_PRERELEASE: String = '';

	LIBGIT2_SOVERSION = '1.9';

	LIBGIT2_VERSION_NUMBER =
		(LIBGIT2_VERSION_MAJOR * 1000000) + (LIBGIT2_VERSION_MINOR * 10000) + (LIBGIT2_VERSION_REVISION * 100);

function GitVersionCheck(const major, minor, revision: Integer): Boolean;

implementation

function GitVersionCheck(const major, minor, revision: Integer): Boolean;
begin
	Result := (LIBGIT2_VERSION_NUMBER >= major * 1000000 + minor * 10000 + revision * 100);
end;

end.
