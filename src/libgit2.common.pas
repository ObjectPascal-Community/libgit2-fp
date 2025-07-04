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
		Reserved,
		ProgramData,
		System,
		XDG,
		Global,
		Local,
		Worktree,
		App
		);

function GetSearchPath(const level: TGitConfigLevel; out path: String): Integer;
function SetSearchPath(const level: TGitConfigLevel; const path: String): Integer;
function ResetSearchPath(const level: TGitConfigLevel): Integer;

type
	TGitObjectType = (
		Any,
		Invalid,
		Commit,
		Tree,
		Blob,
		Tag,
		OffsetDelta,
		RefDelta
		);

function GetCacheObjectLimit(const ObjectType: TGitObjectType): size_t;
function SetCacheObjectLimit(const ObjectType: TGitObjectType; const CacheSize: size_t): Boolean;

function GetCacheObjectMaxSize: ssize_t;
function SetCacheObjectMaxSize(const MaxStorageBytes: ssize_t): Boolean;

function EnableCaching: Boolean;
function DisableCaching: Boolean;
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


procedure EnableStrictObjectCreation;
procedure DisableStrictObjectCreation;

procedure EnableStrictSymbolicRefCreation;
procedure DisableStrictSymbolicRefCreation;

procedure EnableOfsDelta;
procedure DisableOfsDelta;

procedure EnableFSyncGitdir;
procedure DisableFSyncGitdir;

procedure EnableStrictHashVerification;
procedure DisableStrictHashVerification;

procedure EnableUnsavedIndexSafety;
procedure DisableUnsavedIndexSafety;

procedure EnablePackKeepFileChecks;
procedure DisablePackKeepFileChecks;

procedure EnableHttpExpectContinue;
procedure DisableHttpExpectContinue;

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
	CachedFeatures:	 TGitFeatures;
	FeaturesCached:	 Boolean = False;
	CacheObjectLimits: array[TGitObjectType] of size_t = ( // .
		High(size_t), // Any
		High(size_t), // Invalid
		4096, // Commit
		4096, // Tree
		0,	 // Blob
		4096, // Tag
		0,	 // OffsetDelta
		0	  // RefDelta
		);
	CacheMaxSize:		ssize_t = 256 * 1024 * 1024; // 256 MB, as per the docs


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

function ResetSearchPath(const level: TGitConfigLevel): Integer;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetSearchPath), Ord(level), nil);
end;

function IsInvalidObjectType(const ObjectType: TGitObjectType): Boolean;
begin
	Result := (ObjectType = TGitObjectType.Any) or (ObjectType = TGitObjectType.Invalid);
end;

function SetCacheObjectLimit(const ObjectType: TGitObjectType; const CacheSize: size_t): Boolean;
const
	CValues: array[TGitObjectType] of Integer = ( // .
		-2,  // Any
		-1,  // Invalid
		1,	// Commit
		2,	// Tree
		3,	// Blob
		4,	// Tag
		6,	// OffsetDelta
		7	 // RefDelta
		);
begin
	if IsInvalidObjectType(ObjectType) then
	begin
		Result := False;
		Exit;
	end;

	Result := Libgit2Opts(Ord(TGitOption.SetCacheMaxSize), CValues[ObjectType], CacheSize) = 0;
	if Result then
	begin
		CacheObjectLimits[ObjectType] := CacheSize;
	end;
end;

function SetCacheObjectMaxSize(const MaxStorageBytes: ssize_t): Boolean;
begin
	Result := Libgit2Opts(Ord(TGitOption.SetCacheMaxSize), MaxStorageBytes) = 0;
	if Result then
	begin
		CacheMaxSize := MaxStorageBytes;
	end;
end;


function GetCacheObjectLimit(const ObjectType: TGitObjectType): size_t;
begin
	if IsInvalidObjectType(ObjectType) then
	begin
		Result := High(size_t);
		Exit;
	end
	else
	begin
		Result := CacheObjectLimits[ObjectType];
	end;
end;

function GetCacheObjectMaxSize: ssize_t;
begin
	Result := CacheMaxSize;
end;

function EnableCaching: Boolean;
begin
	Result := Libgit2Opts(Ord(TGitOption.EnableCaching), 1) = 0;
end;

function DisableCaching: Boolean;
begin
	Result := Libgit2Opts(Ord(TGitOption.EnableCaching), 0) = 0;
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
	Result := Libgit2Opts(Ord(TGitOption.GetTemplatePath), @Buffer);
	if Result <> 0 then
	begin
		path := '';
		Exit;
	end;

	try
		if Buffer.Ptr <> nil then
		begin
			path := UTF8ToString(Buffer.Ptr);
		end
		else
		begin
			path := '';
		end;
	finally
		DisposeBuffer(Buffer);
	end;
end;

function SetTemplatePath(const path: String): Integer;
var
	Utf8Path: Utf8string;
begin
	Utf8Path := UTF8Encode(path);
	Result	:= Libgit2Opts(Ord(TGitOption.SetTemplatePath), Pansichar(Utf8Path));
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
	utf8: Ansistring;
begin
	if userAgent = '' then
	begin
		Result := Libgit2Opts(Ord(TGitOption.SetUserAgent), nil);
	end
	else
	begin
		utf8	:= UTF8Encode(userAgent);
		Result := Libgit2Opts(Ord(TGitOption.SetUserAgent), Pansichar(utf8));
	end;
end;

function GetUserAgent(out userAgent: String): Integer;
var
	buf: TGitBuf;
begin
	FillChar(buf, SizeOf(buf), 0);
	Result := Libgit2Opts(Ord(TGitOption.GetUserAgent), @buf);
	if Result = 0 then
	begin
		if buf.Ptr <> nil then
		begin
			userAgent := UTF8ToString(Ansistring(buf.Ptr));
		end
		else
		begin
			userAgent := '';
		end;
		DisposeBuffer(buf);
	end
	else
	begin
		userAgent := '';
	end;
end;


function SetUserAgentProduct(const userAgentProduct: String): Integer;
var
	utf8: Ansistring;
begin
	if userAgentProduct = '' then
	begin
		Result := Libgit2Opts(Ord(TGitOption.SetUserAgentProduct), nil);
	end
	else
	begin
		utf8	:= UTF8Encode(userAgentProduct);
		Result := Libgit2Opts(Ord(TGitOption.SetUserAgentProduct), Pansichar(utf8));
	end;
end;

function GetUserAgentProduct(out userAgentProduct: String): Integer;
var
	buf: TGitBuf;
begin
	FillChar(buf, SizeOf(buf), 0);
	Result := Libgit2Opts(Ord(TGitOption.GetUserAgentProduct), @buf);
	if Result = 0 then
	begin
		if buf.Ptr <> nil then
		begin
			userAgentProduct := UTF8ToString(Ansistring(buf.Ptr));
		end
		else
		begin
			userAgentProduct := '';
		end;
		DisposeBuffer(buf);
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

var
	StrictObjectCreationEnabled: Boolean = False;
	StrictSymbolicRefCreationEnabled: Boolean = False;
	OfsDeltaEnabled:	 Boolean = False;
	FSyncGitdirEnabled: Boolean = False;
	StrictHashVerificationEnabled: Boolean = False;
	UnsavedIndexSafetyEnabled: Boolean = False;
	PackKeepFileChecksDisabled: Boolean = False;
	HttpExpectContinueEnabled: Boolean = False;

procedure EnableStrictObjectCreationInternal(const Enabled: Boolean);
begin
	if StrictObjectCreationEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableStrictObjectCreation), Ord(Enabled));
		StrictObjectCreationEnabled := Enabled;
	end;
end;


procedure EnableStrictSymbolicRefCreationInternal(const Enabled: Boolean);
begin
	if StrictSymbolicRefCreationEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableStrictSymbolicRefCreation), Ord(Enabled));
		StrictSymbolicRefCreationEnabled := Enabled;
	end;
end;

procedure EnableOfsDeltaInternal(const Enabled: Boolean);
begin
	if OfsDeltaEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableOfsDelta), Ord(Enabled));
		OfsDeltaEnabled := Enabled;
	end;
end;

procedure EnableFSyncGitdirInternal(const Enabled: Boolean);
begin
	if FSyncGitdirEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableFSyncGitdir), Ord(Enabled));
		FSyncGitdirEnabled := Enabled;
	end;
end;

procedure EnableStrictHashVerificationInternal(const Enabled: Boolean);
begin
	if StrictHashVerificationEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableStrictHashVerification), Ord(Enabled));
		StrictHashVerificationEnabled := Enabled;
	end;
end;

procedure EnableUnsavedIndexSafetyInternal(const Enabled: Boolean);
begin
	if UnsavedIndexSafetyEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableUnsavedIndexSafety), Ord(Enabled));
		UnsavedIndexSafetyEnabled := Enabled;
	end;
end;

procedure DisablePackKeepFileChecksInternal(const Enabled: Boolean);
begin
	if PackKeepFileChecksDisabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.DisablePackKeepFileChecks), Ord(Enabled));
		PackKeepFileChecksDisabled := Enabled;
	end;
end;

procedure EnableHttpExpectContinueInternal(const Enabled: Boolean);
begin
	if HttpExpectContinueEnabled <> Enabled then
	begin
		Libgit2Opts(Ord(TGitOption.EnableHttpExpectContinue), Ord(Enabled));
		HttpExpectContinueEnabled := Enabled;
	end;
end;

procedure EnableStrictObjectCreation;
begin
	EnableStrictObjectCreationInternal(True);
end;

procedure DisableStrictObjectCreation;
begin
	EnableStrictObjectCreationInternal(False);
end;

procedure EnableStrictSymbolicRefCreation;
begin
	EnableStrictSymbolicRefCreationInternal(True);
end;

procedure DisableStrictSymbolicRefCreation;
begin
	EnableStrictSymbolicRefCreationInternal(False);
end;

procedure EnableOfsDelta;
begin
	EnableOfsDeltaInternal(True);
end;

procedure DisableOfsDelta;
begin
	EnableOfsDeltaInternal(False);
end;

procedure EnableFSyncGitdir;
begin
	EnableFSyncGitdirInternal(True);
end;

procedure DisableFSyncGitdir;
begin
	EnableFSyncGitdirInternal(False);
end;

procedure EnableStrictHashVerification;
begin
	EnableStrictHashVerificationInternal(True);
end;

procedure DisableStrictHashVerification;
begin
	EnableStrictHashVerificationInternal(False);
end;

procedure EnableUnsavedIndexSafety;
begin
	EnableUnsavedIndexSafetyInternal(True);
end;

procedure DisableUnsavedIndexSafety;
begin
	EnableUnsavedIndexSafetyInternal(False);
end;

procedure EnablePackKeepFileChecks;
begin
	DisablePackKeepFileChecksInternal(False);
end;

procedure DisablePackKeepFileChecks;
begin
	DisablePackKeepFileChecksInternal(True);
end;

procedure EnableHttpExpectContinue;
begin
	EnableHttpExpectContinueInternal(True);
end;

procedure DisableHttpExpectContinue;
begin
	EnableHttpExpectContinueInternal(False);
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
	StrArray: TGitStrArray;
	i: Integer;
begin
	FillChar(StrArray, SizeOf(StrArray), 0);

	Result := Libgit2Opts(Ord(TGitOption.GetExtensions), @StrArray);
	if Result = 0 then
	begin
		try
			SetLength(extensions, StrArray.Count);
			for i := 0 to StrArray.Count - 1 do
			begin
				extensions[i] := UTF8ToString(StrArray.strings[i]);
			end;
		finally
			DisposeStrArray(StrArray);
		end;
	end
	else
	begin
		SetLength(extensions, 0);
	end;
end;

function SetExtensions(const extensions: TStringArray): Integer;
var
	UTF8Strings: array of Utf8string;
	CExtensions: array of Pansichar;
	i: Integer;
begin
	SetLength(UTF8Strings, Length(extensions));
	SetLength(CExtensions, Length(extensions));

	for i := 0 to High(extensions) do
	begin
		UTF8Strings[i] := UTF8Encode(extensions[i]);
		CExtensions[i] := Pansichar(UTF8Strings[i]);
	end;

	if Length(CExtensions) > 0 then
	begin
		Result := Libgit2Opts(Ord(TGitOption.SetExtensions), @CExtensions[0], Length(CExtensions));
	end
	else
	begin
		Result := Libgit2Opts(Ord(TGitOption.SetExtensions), nil, 0);
	end;
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
