const
	{$IF DEFINED(MSWINDOWS)}
	GIT_PATH_LIST_SEPARATOR = ';';
	{$ELSE}
	GIT_PATH_LIST_SEPARATOR = ':';
	{$ENDIF}

	GIT_PATH_MAX = 4096;

type
	TGitFeature = CInt;
	TGitOption  = CInt;

function Libgit2Version(out major, minor, rev: CInt): CInt; cdecl; external LibGit2Dll name 'git_libgit2_version';
function Libgit2Prerelease: PCChar; cdecl; external LibGit2Dll name 'git_libgit2_prerelease';
function Libgit2Features: CInt; cdecl; external LibGit2Dll name 'git_libgit2_features';
function Libgit2FeatureBackend(const feature: TGitFeature): PCChar; cdecl;
	external LibGit2Dll name 'git_libgit2_feature_backend';
function Libgit2Opts(const option: TGitOption): CInt; cdecl; varargs; external LibGit2Dll name 'git_libgit2_opts';
