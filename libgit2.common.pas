unit LibGit2.Common;

{$mode objfpc}{$H+}{$ScopedEnums on}

interface

uses
	SysUtils,
	LibGit2.Alloc,
	LibGit2.Buffer,
	LibGit2.StdInt;

const
	{$IFDEF MSWINDOWS}
	GIT_PATH_LIST_SEPARATOR = ';';
	{$ELSE}
	GIT_PATH_LIST_SEPARATOR = ':';
	{$ENDIF}

	GIT_MAX_PATH = 4096;

type
	TGitFeature = (Threads, HTTPS, SSH, NSec,
		HttpParser, Regex, I18N, AuthNTLM,
		AuthNegociate, Compression, SHA1, SHA256);

	TGitFeatures = set of TGitFeature;

	TGitVersion = record
		Major, Minor, Revision: Integer;
	end;

function GetFeatures: TGitFeatures;
function GetVersion: TGitVersion;
function GetPrerelease: String;

function HasThreadSupport: Boolean;
function HasHttpsSupport: Boolean;
function HasSshSupport: Boolean;
function HasNsecResolution: Boolean;
function HasHttpParser: Boolean;
function HasRegexSupport: Boolean;
function HasI18nSupport: Boolean;
function HasNTLMAuthSupport: Boolean;
function HasKerberosAuthSupport: Boolean;
function HasCompressionSupport: Boolean;
function HasSHA1ObjectSupport: Boolean;
function HasSHA256ObjectSupport: Boolean;

function GetFeatureBackend(const feature: TGitFeature): String;

function GetMaximumWindowSize: size_t;
procedure SetMaximumWindowSize(const size: size_t);

function GetMaximumWindowMappedLimit: size_t;
procedure SetMaximumWindowMappedLimit(const size: size_t);

function GetMaximumWindowFileLimit: size_t;
procedure SetMaximumWindowFileLimit(const size: size_t);

type
	TGitConfigLevel = (
		HighestLevel = -1,
		ProgramData = 1,
		System = 2,
		XDG = 3,
		Global = 4,
		Local = 5,
		Worktree = 6,
		App = 7
		);

function GetSearchPath(const level: TGitConfigLevel; out path: String): Integer;
function SetSearchPath(const level: TGitConfigLevel; const path: String): Integer;

type
	TGitObjectType = (
		Any = -2,
		Invalid = -1,
		Commit = 1,
		Tree = 2,
		Blob = 3,
		Tag = 4,
		OffsetDelta = 6,
		RefDelta = 7
		);

function SetCacheObjectLimit(const ObjectType: TGitObjectType; const CacheSize: size_t): Integer;
function SetCacheObjectMaxSize(const MaxStorageBytes: ssize_t): Integer;

procedure EnableCaching(const Enabled: Boolean);
procedure GetCachedMemory(out current, allowed: ssize_t);

function GetTemplatePath(out path: String): Integer;
function SetTemplatePath(const path: String): Integer;

function SetSSLCertLocations(const filename, path: String): Integer;
function AddSSLX509Cert(const cert: Pointer): Integer;

function SetUserAgent(const userAgent: String): Integer;
function GetUserAgent(out userAgent: String): Integer;

function SetUserAgentProduct(const userAgentProduct: String): Integer;
function GetUserAgentProduct(out userAgentProduct: String): Integer;

{$IF DEFINED(WINDOWS)}
type
   TWindowsShareMode = (Prevent, Read, Write, Delete);

function SetWindowsShareMode(const mode: TWindowsShareMode): Integer;
function GetWindowsShareMode(out mode: TWindowsShareMode): Integer;
{$ENDIF}

procedure SetSSLCiphers(const ciphers: String);

procedure EnableStrictObjectCreation(const Enabled: Boolean);
procedure EnableStrictSymbolicRefCreation(const Enabled: Boolean);
procedure EnableOfsDelta(const Enabled: Boolean);
procedure EnableFSyncGitdir(const Enabled: Boolean);
procedure EnableStrictHashVerification(const Enabled: Boolean);
procedure EnableUnsavedIndexSafety(const Enabled: Boolean);
procedure DisablePackKeepFileChecks(const Enabled: Boolean);
procedure EnableHttpExpectContinue(const Enabled: Boolean);

function GetPackMaxObjects: size_t;
procedure SetPackMaxObjects(const objects: size_t);

function SetAllocator(allocator: PGitAllocator): Integer;

procedure SetODBPackedPriority(const priority: Integer);
procedure SetODBLoosePriority(const priority: Integer);

function GetExtensions(out extensions: TStringArray): Integer;
function SetExtensions(const extensions: TStringArray): Integer;

function GetOwnerValidation: Boolean;
procedure SetOwnerValidation(const Enabled: Boolean);

function GetHomeDirectory(out path: String): Integer;
function SetHomeDirectory(const path: String): Integer;

function GetServerConnectTimeout: Integer;
function SetServerConnectTimeout(const timeoutMs: Integer): Integer;

function GetServerTimeout: Integer;
function SetServerTimeout(const timeoutMs: Integer): Integer;

implementation

uses
	LibGit2.Platform,
	LibGit2.StrArray;

var
	CachedFeatures: TGitFeatures;
	FeaturesCached: Boolean = False;

type
	TGitOption = (
		GetMWindowSize,
		SetMWindowSize,
		GetMWindowMappedLimit,
		SetMWindowMappedLimit,
		GetSearchPath,
		SetSearchPath,
		SetCacheObjectLimit,
		SetCacheMaxSize,
		EnableCaching,
		GetCachedMemory,
		GetTemplatePath,
		SetTemplatePath,
		SetSSLCertLocations,
		SetUserAgent,
		EnableStrictObjectCreation,
		EnableStrictSymbolicRefCreation,
		SetSSLCiphers,
		GetUserAgent,
		EnableOfsDelta,
		EnableFSyncGitdir,
		GetWindowsShareMode,
		SetWindowsShareMode,
		EnableStrictHashVerification,
		SetAllocator,
		EnableUnsavedIndexSafety,
		GetPackMaxObjects,
		SetPackMaxObjects,
		DisablePackKeepFileChecks,
		EnableHttpExpectContinue,
		GetMWindowFileLimit,
		SetMWindowFileLimit,
		SetODBPackedPriority,
		SetODBLoosePriority,
		GetExtensions,
		SetExtensions,
		GetOwnerValidation,
		SetOwnerValidation,
		GetHomeDir,
		SetHomeDir,
		SetServerConnectTimeout,
		GetServerConnectTimeout,
		SetServerTimeout,
		GetServerTimeout,
		SetUserAgentProduct,
		GetUserAgentProduct,
		AddSSLX509Cert
		);

function Libgit2GetVersion(Major, Minor, Revision: PInteger): Integer;
	cdecl; external LibGit2Dll name 'git_libgit2_version';
function Libgit2GetPrerelease: Pansichar; cdecl; external LibGit2Dll name 'git_libgit2_prerelease';
function Libgit2Features: Integer; cdecl; external LibGit2Dll name 'git_libgit2_features';
function Libgit2FeatureBackend(feature: Integer): Pansichar;
	cdecl; external LibGit2Dll name 'git_libgit2_feature_backend';
function Libgit2Opts(option: Integer): Integer; cdecl; varargs; external LibGit2Dll name 'git_libgit2_opts';

function GetVersion: TGitVersion;
begin
	Libgit2GetVersion(@Result.Major, @Result.Minor, @Result.Revision);
end;

function GetPrerelease: String;
var
	PrereleaseStr: Pansichar;
begin
	PrereleaseStr := Libgit2GetPrerelease;
	if PrereleaseStr = nil then
	begin
		Result := '';
	end
	else
	begin
		Result := String(Ansistring(PrereleaseStr));
	end;
end;

function GetFeatures: TGitFeatures;
var
	mask: Integer;
	f:	 TGitFeature;
begin
	if not FeaturesCached then
	begin
		mask := Libgit2Features;
		CachedFeatures := [];
		for f := Low(TGitFeature) to High(TGitFeature) do
		begin
			if (mask and (1 shl Ord(f))) <> 0 then
			begin
				Include(CachedFeatures, f);
			end;
		end;
		FeaturesCached := True;
	end;
	Result := CachedFeatures;
end;

function HasFeature(feature: TGitFeature): Boolean;
begin
	Result := feature in GetFeatures;
end;

function HasThreadSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.Threads);
end;

function HasHttpsSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.HTTPS);
end;

function HasSshSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.SSH);
end;

function HasNsecResolution: Boolean;
begin
	Result := HasFeature(TGitFeature.NSec);
end;

function HasHttpParser: Boolean;
begin
	Result := HasFeature(TGitFeature.HttpParser);
end;

function HasRegexSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.Regex);
end;

function HasI18nSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.I18N);
end;

function HasNTLMAuthSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.AuthNTLM);
end;

function HasKerberosAuthSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.AuthNegociate);
end;

function HasCompressionSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.Compression);
end;

function HasSHA1ObjectSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.SHA1);
end;

function HasSHA256ObjectSupport: Boolean;
begin
	Result := HasFeature(TGitFeature.SHA256);
end;

function GetFeatureBackend(const feature: TGitFeature): String;
var
	raw: Pansichar;
begin
	raw := Libgit2FeatureBackend(1 shl Ord(feature));
	if raw = nil then
	begin
		Result := '';
	end
	else
	begin
		Result := String(raw);
	end;
end;

function GetMaximumWindowSize: size_t;
begin
	Libgit2Opts(Ord(TGitOption.GetMWindowSize), @Result);
end;

procedure SetMaximumWindowSize(const size: size_t);
begin
	Libgit2Opts(Ord(TGitOption.SetMWindowSize), size);
end;

function GetMaximumWindowMappedLimit: size_t;
begin
	Libgit2Opts(Ord(TGitOption.GetMWindowMappedLimit), @Result);
end;

procedure SetMaximumWindowMappedLimit(const size: size_t);
begin
	Libgit2Opts(Ord(TGitOption.SetMWindowMappedLimit), size);
end;

function GetMaximumWindowFileLimit: size_t;
begin
	Libgit2Opts(Ord(TGitOption.GetMWindowFileLimit), @Result);
end;

procedure SetMaximumWindowFileLimit(const size: size_t);
begin
	Libgit2Opts(Ord(TGitOption.SetMWindowFileLimit), size);
end;

function GetSearchPath(const level: TGitConfigLevel; out path: String): Integer;
var
	Buffer: TGitBuf;
begin
	Buffer := GitInitBuf;
	FillChar(Buffer, SizeOf(Buffer), 0);

	Result := Libgit2Opts(Ord(TGitOption.GetSearchPath), Ord(level), @Buffer);
	if Result = 0 then
	begin
		if Buffer.Ptr <> nil then
		begin
			path := String(Ansistring(Buffer.Ptr));
		end
		else
		begin
			path := '';
		end;

		DisposeBuffer(Buffer);
	end
	else
	begin
		path := '';
	end;
end;

function SetSearchPath(const level: TGitConfigLevel; const path: String): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetSearchPath), Ord(level), Pansichar(UTF8Encode(path)));
end;

function SetCacheObjectLimit(const ObjectType: TGitObjectType; const CacheSize: size_t): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetCacheObjectLimit), Ord(ObjectType), CacheSize);
end;

function SetCacheObjectMaxSize(const MaxStorageBytes: ssize_t): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetCacheMaxSize), MaxStorageBytes);
end;

procedure EnableCaching(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableCaching), Ord(Enabled));
end;

procedure GetCachedMemory(out current, allowed: ssize_t);
begin
	Libgit2Opts(Ord(TGitOption.GetCachedMemory), @current, @allowed);
end;

function GetTemplatePath(out path: String): Integer;
var
	Buffer: TGitBuf;
begin
	Buffer := GitInitBuf;
	FillChar(Buffer, SizeOf(Buffer), 0);

	Result := Libgit2Opts(Ord(TGitOption.GetTemplatePath), @Buffer);
	if Result = 0 then
	begin
		if Buffer.Ptr <> nil then
		begin
			path := String(Ansistring(Buffer.Ptr));
		end
		else
		begin
			path := '';
		end;
		DisposeBuffer(Buffer);
	end
	else
	begin
		path := '';
	end;
end;

function SetTemplatePath(const path: String): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetTemplatePath), Pansichar(Ansistring(path)));
end;

function SetSSLCertLocations(const filename, path: String): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetSSLCertLocations), Pansichar(Ansistring(filename)),
		Pansichar(Ansistring(path)));
end;

function AddSSLX509Cert(const cert: Pointer): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.AddSSLX509Cert), cert);
end;

function SetUserAgent(const userAgent: String): Integer;
var
  ansiUserAgent: AnsiString;
begin
  ansiUserAgent := AnsiString(userAgent);
  Result := Libgit2Opts(Ord(TGitOption.SetUserAgent), PAnsiChar(ansiUserAgent));
end;

function GetUserAgent(out userAgent: String): Integer;
var
	Buffer: TGitBuf;
begin
	FillChar(Buffer, SizeOf(Buffer), 0);
	Result := Libgit2Opts(Ord(TGitOption.GetUserAgent), @Buffer);
	if Result = 0 then
	begin
		if Buffer.Ptr <> nil then
		begin
			userAgent := String(AnsiString(Buffer.Ptr));
		end
		else
		begin
			userAgent := '';
		end;
		DisposeBuffer(Buffer);
	end
	else
	begin
		userAgent := '';
	end;
end;

function SetUserAgentProduct(const userAgentProduct: String): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetUserAgentProduct), Pansichar(Ansistring(userAgentProduct)));
end;

function GetUserAgentProduct(out userAgentProduct: String): Integer;
var
	Buffer: TGitBuf;
begin
	Buffer := GitInitBuf;
	FillChar(Buffer, SizeOf(Buffer), 0);
	Result := Libgit2Opts(Ord(TGitOption.GetUserAgentProduct), @Buffer);
	if Result = 0 then
	begin
		if Buffer.Ptr <> nil then
		begin
			userAgentProduct := String(Ansistring(Buffer.Ptr));
		end
		else
		begin
			userAgentProduct := '';
		end;
		DisposeBuffer(Buffer);
	end
	else
	begin
		userAgentProduct := '';
	end;
end;


{$IF DEFINED(WINDOWS)}
function SetWindowsShareMode(const mode: TWindowsShareMode): Integer;
begin
    Result := Libgit2Opts(Ord(TGitOption.SetWindowsShareMode), Cardinal(mode));
End;
function GetWindowsShareMode(out mode: TWindowsShareMode): Integer;
var
  value: Cardinal;
begin
  Result := Libgit2Opts(Ord(TGitOption.GetWindowsShareMode), @value);
  if Result = 0 then
    mode := TWindowsShareMode(value)
  else
    mode := Low(TWindowsShareMode);
end;
{$ENDIF}

procedure SetSSLCiphers(const ciphers: String);
begin
	Libgit2Opts(Ord(TGitOption.SetSSLCiphers), Pansichar(Ansistring(ciphers)));
end;

procedure EnableStrictObjectCreation(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableStrictObjectCreation), Ord(Enabled));
end;

procedure EnableStrictSymbolicRefCreation(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableStrictSymbolicRefCreation), Ord(Enabled));
end;

procedure EnableOfsDelta(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableOfsDelta), Ord(Enabled));
end;

procedure EnableFSyncGitdir(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableFSyncGitdir), Ord(Enabled));
end;

procedure EnableStrictHashVerification(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableStrictHashVerification), Ord(Enabled));
end;

procedure EnableUnsavedIndexSafety(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableUnsavedIndexSafety), Ord(Enabled));
end;

procedure DisablePackKeepFileChecks(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.DisablePackKeepFileChecks), Ord(Enabled));
end;

procedure EnableHttpExpectContinue(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.EnableHttpExpectContinue), Ord(Enabled));
end;

function GetPackMaxObjects: size_t;
begin
	Result := 0;
	Libgit2Opts(Ord(TGitOption.GetPackMaxObjects), @Result);
end;

procedure SetPackMaxObjects(const objects: size_t);
begin
	Libgit2Opts(Ord(TGitOption.SetPackMaxObjects), objects);
end;

function SetAllocator(allocator: PGitAllocator): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetAllocator), allocator);
end;

procedure SetODBPackedPriority(const priority: Integer);
begin
	Libgit2Opts(Ord(TGitOption.SetODBPackedPriority), priority);
end;

procedure SetODBLoosePriority(const priority: Integer);
begin
	Libgit2Opts(Ord(TGitOption.SetODBLoosePriority), priority);
end;

function GetExtensions(out extensions: TStringArray): Integer;
var
	StrArray: PGitStrArray = nil;
	i: Integer;
begin
	StrArray := GetMem(SizeOf(TGitStrArray));
	try
		FillChar(StrArray^, SizeOf(TGitStrArray), 0);
		Result := Libgit2Opts(Ord(TGitOption.GetExtensions), StrArray);
		if Result = 0 then
		begin
			SetLength(extensions, StrArray^.Count);
			for i := 0 to StrArray^.Count - 1 do
			begin
				extensions[i] := String(Ansistring(StrArray^.strings[i]));
			end;
		end
		else
		begin
			SetLength(extensions, 0);
		end;
	finally
		FreeMem(StrArray);
	end;
end;

function SetExtensions(const extensions: TStringArray): Integer;
var
	CExtensions: array of Pansichar = nil;
	i: Integer;
begin
	SetLength(CExtensions, Length(extensions));
	for i := 0 to High(extensions) do
	begin
		CExtensions[i] := Pansichar(UTF8Encode(extensions[i]));
	end;
	Result := Libgit2Opts(Ord(TGitOption.SetExtensions), @CExtensions[0], Length(CExtensions));
end;

function GetOwnerValidation: Boolean;
var
	Enabled: Integer;
begin
	Result := False;
	if Libgit2Opts(Ord(TGitOption.GetOwnerValidation), @Enabled) = 0 then
	begin
		Result := Enabled <> 0;
	end;
end;

procedure SetOwnerValidation(const Enabled: Boolean);
begin
	Libgit2Opts(Ord(TGitOption.SetOwnerValidation), Ord(Enabled));
end;

function GetHomeDirectory(out path: String): Integer;
var
	Buffer: TGitBuf;
begin
	Buffer := GitInitBuf;
	FillChar(Buffer, SizeOf(Buffer), 0);
	Result := Libgit2Opts(Ord(TGitOption.GetHomeDir), @Buffer);
	if Result = 0 then
	begin
		if Buffer.Ptr <> nil then
		begin
			path := String(Ansistring(Buffer.Ptr));
		end
		else
		begin
			path := '';
		end;
		DisposeBuffer(Buffer);
	end
	else
	begin
		path := '';
	end;
end;

function SetHomeDirectory(const path: String): Integer;
var
	cPath: Pansichar;
begin
	cPath  := Pansichar(UTF8Encode(path));
	Result := Libgit2Opts(Ord(TGitOption.SetHomeDir), cPath);
end;

function GetServerConnectTimeout: Integer;
var
	timeout: Integer;
begin
	if Libgit2Opts(Ord(TGitOption.GetServerConnectTimeout), @timeout) = 0 then
	begin
		Result := timeout;
	end
	else
	begin
		Result := -1;
	end;
end;

function SetServerConnectTimeout(const timeoutMs: Integer): Integer;
begin
	if timeoutMs < 0 then
	begin
		Exit(-1);
	end;

	Result := Libgit2Opts(Ord(TGitOption.SetServerConnectTimeout), timeoutMs);
end;

function GetServerTimeout: Integer;
var
	timeout: Integer;
begin
	if Libgit2Opts(Ord(TGitOption.GetServerTimeout), @timeout) = 0 then
	begin
		Result := timeout;
	end
	else
	begin
		Result := -1;
	end;
end;

function SetServerTimeout(const timeoutMs: Integer): Integer;
begin
	if timeoutMs < 0 then
	begin
		Exit(-1);
	end;

	Result := Libgit2Opts(Ord(TGitOption.SetServerTimeout), timeoutMs);
end;

end.
