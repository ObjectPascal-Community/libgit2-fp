const
	{$IF DEFINED(MSWINDOWS)}
	GIT_PATH_LIST_SEPARATOR = ';';
	{$ELSE}
	GIT_PATH_LIST_SEPARATOR = ':';
	{$ENDIF}

	GIT_PATH_MAX = 4096;

function git_libgit2_version(major, minor, rev: PCInt): CInt; cdecl; external LibGit2Dll;
function git_libgit2_prerelease: PCChar; cdecl; external LibGit2Dll;

type
	git_feature_t = CInt;

function git_libgit2_features: CInt; cdecl; external LibGit2Dll;
function git_libgit2_feature_backend(feature: git_feature_t): PCChar; cdecl; external LibGit2Dll;
function git_libgit2_opts(option: CInt): Integer; cdecl; varargs; external LibGit2Dll;
