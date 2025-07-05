unit LibGit2.Tests.Common;

{$mode objfpc}{$H+}

interface

uses
	Classes,
	fpcunit,
	typinfo,
	LibGit2.Platform,
	SysUtils,
	jsonparser,
	testregistry,
	LibGit2.Common,
	LibGit2.StdInt,
	Generics.Collections;

type

	TTestCommon = class(TTestCase)
	protected
		procedure SetUp; override;
		procedure TearDown; override;
	published
		procedure TestVersion;
		procedure TestCheckIfNotEmptyFeatureSet;
		procedure TestCheckIfAlwaysAvailableFeaturesExist;
		{$IF DEFINED(WINDOWS) OR DEFINED(MSWINDOWS)}
		procedure TestCheckIfWindowsFeaturesExist;
		{$ENDIF}
		procedure TestCheckIfPrereleaseValid;
		procedure TestGetFeatureBackends;
		procedure TestCheckGetMaximumWindowSize;
		procedure TestCheckGetMaximumWindowMappedLimit;
		procedure TestCheckGetMaximumWindowFileLimit;
		procedure TestCheckSetMaximumWindowSize;
		procedure TestCheckSetMaximumWindowMappedLimit;
		procedure TestCheckSetMaximumWindowFileLimit;
		procedure TestGetSetResetSearchPath;
		procedure TestCacheObjectMaxSize;
		procedure TestCacheObjectLimit;
		procedure TestEnableCaching;
		procedure TestGetCachedMemory;
		procedure TestTemplatePath;
		procedure TestSetSSLCertLocations;
		procedure TestAddSSLX509Cert;
		procedure TestSetGetUserAgent;
		procedure TestSetGetUserAgentUnicode;
		procedure TestSetGetUserAgentProduct;
		procedure TestSetGetUserAgentProductUnicode;
		procedure TestAllFeatureToggles;
		procedure TestSetGetPackMaxObjects;
		procedure TestSetGetODBPriority;
		procedure TestSetGetExtensions;
		procedure TestSetGetOwnerValidation;
		procedure TestSetGetHomeDirectory;
		procedure TestSetGetServerTimeout;
		procedure TestSetGetServerConnectTimeout;
	end;

implementation

// TODO: move this into the right unit
function Libgit2Init: Integer; cdecl; external LibGit2Dll name 'git_libgit2_init';
// TODO: move this into the right unit
function Libgit2Shutdown: Integer; cdecl; external LibGit2Dll name 'git_libgit2_shutdown';

procedure TTestCommon.SetUp;
begin
	inherited SetUp;
	Libgit2Init;
end;

procedure TTestCommon.TearDown;
begin
	Libgit2Shutdown;
	inherited TearDown;
end;

procedure TTestCommon.TestVersion;
var
	version: TGitVersion;
begin
	version := GetVersion;
	CheckFalse(version.Major < 0, 'Major version shouldn''t be less than zero');
	CheckFalse(version.Minor < 0, 'Minor version shouldn''t be less than zero');
	CheckFalse(version.Revision < 0, 'Revision version shouldn''t be less than zero');
end;

procedure TTestCommon.TestCheckIfNotEmptyFeatureSet;
var
	features: TGitFeatures;
begin
	features := GetFeatures;
	CheckTrue(features <> [], 'Features set shouldn''t be empty.');
end;

procedure TTestCommon.TestCheckIfAlwaysAvailableFeaturesExist;
const
	alwaysPresentFeatures: TGitFeatures = [TGitFeature.HttpParser, TGitFeature.Regex,
		TGitFeature.Compression, TGitFeature.SHA1];
var
	features: TGitFeatures;
	feature:  TGitFeature;
begin
	features := GetFeatures;

	for feature in alwaysPresentFeatures do
	begin
		CheckTrue(feature in features,
			'Missing expected feature: ' + GetEnumName(TypeInfo(TGitFeature), Ord(feature)));
	end;
end;

{$IF DEFINED(WINDOWS)}
procedure TTestCommon.TestCheckIfWindowsFeaturesExist;
const
	windowsFeatures: TGitFeatures = [TGitFeature.AuthNegociate, TGitFeature.AuthNTLM];
var
	features: TGitFeatures;
	feature:  TGitFeature;
begin
	// According to the libgit2 code, GIT_FEATURE_AUTH_NTLM and GIT_FEATURE_AUTH_NEGOTIATE should be available.
	features := GetFeatures;
	for feature in windowsFeatures do
	begin
		CheckTrue(feature in features,
			'Missing Windows feature: ' + GetEnumName(TypeInfo(TGitFeature), Ord(feature)));
	end;
end;
{$ENDIF}

procedure TTestCommon.TestCheckIfPrereleaseValid;
var
	PrereleaseString: String;
begin
	PrereleaseString := GetPrerelease;

	// In practice, PrereleaseString should be empty, and the last version I saw alpha is 1.8.0.
	// While comments and commit descriptions indicate beta versions should exist, I haven't seen them through commits,
	// and the only rc versions were 1.8.2-rc1 and pre-0.28 versions (but then, what are you doing with a version
	// from pre-2018? I sure hope you are not going to use an ancient DLL.)

	// Still, for the sake of the test, I need to test each possibility.
	// Abandon all hope, ye who use RC/beta/alpha libgit2 DLLs here.
	CheckTrue(PrereleaseString.IsEmpty or PrereleaseString.StartsWith('rc') or (PrereleaseString = 'beta') or
		(PrereleaseString = 'alpha'),
		'Prerelease string is different from empty (full release), alpha, beta or rc*');
end;

const
	allowedBackends: array[TGitFeature] of TStringArray = (
		// Threads
		('pthread', 'win32'),
		// HTTPS
		('mbedtls', 'openssl', 'openssl-dynamic', 'schannel', 'securetransport', 'winhttp'),
		// SSH
		('exec', 'libssh2'),
		// NSec
		('mtime', 'mtim', 'mtimespec', 'win32'),
		// HttpParser
		('builtin', 'httpparser', 'llhttp'),
		// Regex
		('builtin', 'pcre', 'pcre2', 'regcomp', 'regcomp_l'),
		// I18N
		('iconv'),
		// AuthNTLM
		('ntlmclient', 'sspi'),
		// AuthNegotiate
		('gssapi', 'sspi'),
		// Compression
		('builtin', 'zlib'),
		// SHA1
		('builtin', 'commoncrypto', 'mbedtls', 'openssl', 'openssl-dynamic', 'openssl-fips', 'win32'),
		// SHA256
		('builtin', 'commoncrypto', 'mbedtls', 'openssl', 'openssl-dynamic', 'openssl-fips', 'win32')
		);

procedure TTestCommon.TestGetFeatureBackends;
var
	features: TGitFeatures;
	feature: TGitFeature;
	backend: String;
	allowedList: TStringArray;
	featureName: String;
	left, right, mid, cmp: Integer;
	found: Boolean;
begin
	features := GetFeatures;

	for feature := Low(TGitFeature) to High(TGitFeature) do
	begin
		featureName := GetEnumName(TypeInfo(TGitFeature), Ord(feature));
		backend	  := Trim(GetFeatureBackend(feature));

		if feature in features then
		begin
			CheckNotEquals('', backend,
				Format('Enabled feature %s has empty backend', [featureName])
				);

			allowedList := allowedBackends[feature];
			if Length(allowedList) = 0 then
			begin
				Fail(Format('No allowed backends specified for feature %s', [featureName]));
				Continue;
			end;

			left  := 0;
			right := High(allowedList);
			found := False;
			while left <= right do
			begin
				mid := (left + right) div 2;
				cmp := AnsiCompareText(backend, allowedList[mid]);
				if cmp = 0 then
				begin
					found := True;
					Break;
				end
				else if cmp < 0 then
				begin
					right := mid - 1;
				end
				else
				begin
					left := mid + 1;
				end;
			end;

			CheckTrue(found,
				Format('Backend "%s" for feature %s is not in the allowed list', [backend, featureName])
				);
		end
		else
		begin
			CheckTrue(
				backend = '',
				Format('Disabled feature %s unexpectedly has backend "%s"', [featureName, backend])
				);
		end;
	end;
end;

procedure TTestCommon.TestCheckGetMaximumWindowSize;
var
	actual, expected: size_t;
begin
	{
         #define DEFAULT_WINDOW_SIZE \
         (sizeof(void*) >= 8 \
            ? 1 * 1024 * 1024 * 1024 \
            : 32 * 1024 * 1024)

   I seriously doubt people are going to change the default, because at that point you know what you are doing.
   1GB on 64 bits and 32MB on 32 bits is more than enough (and not in a 640K way). If that's not enough, well, use
   SetMaximumWindowSize. Do **not** even dare to file an issue if you changed any of the constants in mwindow.c at build
   time.
   }
	{$IFDEF CPU64}
     expected := 1 * 1024 * 1024 * 1024;
	{$ELSE}
	expected := 32 * 1024 * 1024;
	{$ENDIF}

	actual := GetMaximumWindowSize;
	CheckEquals(expected, actual,
		'DEFAULT_WINDOW_SIZE not the same as the expected compile time value. ' +
		'DEFAULT_WINDOW_SIZE constant changed or running 32 bit DLL on 64 bit.');
end;

procedure TTestCommon.TestCheckGetMaximumWindowMappedLimit;
var
	actual, expected: size_t;
begin
	{
         #define DEFAULT_MAPPED_LIMIT \
                 ((1024 * 1024) * (sizeof(void*) >= 8 ? UINT64_C(8192) : UINT64_C(256)))
   }
	{$IFDEF CPU64}
     expected := 8 * 1024 * 1024 * 1024;
	{$ELSE}
	expected := 256 * 1024 * 1024;
	{$ENDIF}

	actual := GetMaximumWindowMappedLimit;
	CheckEquals(expected, actual,
		'DEFAULT_MAPPED_LIMIT not the same as the expected compile time value. ' +
		'DEFAULT_MAPPED_LIMIT constant changed or running 32 bit DLL on 64 bit.');
end;

procedure TTestCommon.TestCheckGetMaximumWindowFileLimit;
begin
	{
         /* default is unlimited */
         #define DEFAULT_FILE_LIMIT 0

         I would genuinely be surprised if someone didn't want an unlimited file size limit.
   }

	CheckEquals(GetMaximumWindowFileLimit, 0, 'DEFAULT_FILE_LIMIT not unlimited (0).');
end;

procedure TTestCommon.TestCheckSetMaximumWindowSize;
var
	original, testValue, retrieved: size_t;
begin
	original  := GetMaximumWindowSize;
	testValue := 4 * 1024 * 1024; // 4 MB

	SetMaximumWindowSize(testValue);
	retrieved := GetMaximumWindowSize;

	CheckEquals(testValue, retrieved, 'Failed to set maximum window size');

	SetMaximumWindowSize(original);
	retrieved := GetMaximumWindowSize;
	CheckEquals(original, retrieved, 'Failed to reset maximum window size to original value');
end;

procedure TTestCommon.TestCheckSetMaximumWindowMappedLimit;
var
	original, testValue, retrieved: size_t;
begin
	original  := GetMaximumWindowMappedLimit;
	testValue := 4 * 1024 * 1024; // 4 MB

	SetMaximumWindowMappedLimit(testValue);
	retrieved := GetMaximumWindowMappedLimit;

	CheckEquals(testValue, retrieved, 'Failed to set maximum window mapped limit');

	SetMaximumWindowMappedLimit(original);
	retrieved := GetMaximumWindowMappedLimit;
	CheckEquals(original, retrieved, 'Failed to reset maximum window mapped limit to original value');
end;

procedure TTestCommon.TestCheckSetMaximumWindowFileLimit;
var
	original, testValue, retrieved: size_t;
begin
	original  := GetMaximumWindowFileLimit;
	testValue := 256;

	SetMaximumWindowFileLimit(testValue);
	retrieved := GetMaximumWindowFileLimit;

	CheckEquals(testValue, retrieved, 'Failed to set maximum window file limit');

	SetMaximumWindowFileLimit(original);
	retrieved := GetMaximumWindowFileLimit;
	CheckEquals(original, retrieved, 'Failed to reset maximum window file limit to original value');
end;

type
	PGitError = ^TGitError;

	TGitError = record
		message: Pansichar;
		kind:	 Integer;
	end;

// TODO: move this into the right unit
function Libgit2GetLastError: PGitError; cdecl; varargs; external LibGit2Dll name 'git_error_last';

procedure TTestCommon.TestGetSetResetSearchPath;
const
	TestBasePath = 'test_path';

	procedure CheckLibgit2(ResultCode: Integer; const Msg: String);
	var
		err: PGitError;
	begin
		if ResultCode <> 0 then
		begin
			err := Libgit2GetLastError;
			if Assigned(err) and Assigned(err^.message) then
			begin
				Fail(Format('%s: %s (code %d)', [Msg, String(err^.message), ResultCode]));
			end
			else
			begin
				Fail(Format('%s: unknown error (code %d)', [Msg, ResultCode]));
			end;
		end;
	end;

	procedure TestLevelPath(const level: TGitConfigLevel);
	var
		levelName: String;
		originalPath, testPath, appendedPath, actualPath: String;
	begin
		levelName := GetEnumName(TypeInfo(TGitConfigLevel), Ord(level));
		testPath  := Format('%s_%d', [TestBasePath, Ord(level)]);

		CheckLibgit2(GetSearchPath(level, originalPath), Format('[%s] GetSearchPath (original)', [levelName]));
		CheckLibgit2(SetSearchPath(level, testPath), Format('[%s] SetSearchPath', [levelName]));

		CheckLibgit2(GetSearchPath(level, actualPath), Format('[%s] GetSearchPath (after set)', [levelName]));
		CheckEquals(testPath, actualPath, Format('[%s] Set path mismatch', [levelName]));

		appendedPath := actualPath + PathSeparator + testPath;
		CheckLibgit2(SetSearchPath(level, appendedPath), Format('[%s] SetSearchPath (append)', [levelName]));

		CheckLibgit2(GetSearchPath(level, actualPath), Format('[%s] GetSearchPath (after append)', [levelName]));
		CheckEquals(appendedPath, actualPath, Format('[%s] Appended path mismatch', [levelName]));

		CheckLibgit2(ResetSearchPath(level), Format('[%s] ResetSearchPath', [levelName]));
		CheckLibgit2(GetSearchPath(level, actualPath), Format('[%s] GetSearchPath (after reset)', [levelName]));

		if level <> TGitConfigLevel.System then
		begin
			CheckEquals(originalPath, actualPath, Format('[%s] Reset did not restore path', [levelName]));
		end;
	end;

var
	level: TGitConfigLevel;
begin
	for level in [TGitConfigLevel.ProgramData .. TGitConfigLevel.Global] do
	begin
		TestLevelPath(level);
	end;
end;


procedure TTestCommon.TestCacheObjectMaxSize;
var
	originalMaxSize, testMaxSize, actualMaxSize: ssize_t;
	Success: Boolean;
begin
	originalMaxSize := GetCacheObjectMaxSize;

	testMaxSize := 16 * 1024 * 1024; // 16 MB

	Success := SetCacheObjectMaxSize(testMaxSize);
	CheckTrue(Success, 'SetCacheObjectMaxSize failed');

	actualMaxSize := GetCacheObjectMaxSize;
	CheckEquals(testMaxSize, actualMaxSize, 'Cache object max size was not set correctly');

	Success := SetCacheObjectMaxSize(originalMaxSize);
	CheckTrue(Success, 'Failed to restore original CacheObjectMaxSize');
end;

procedure TTestCommon.TestCacheObjectLimit;
const
	testLimit: size_t = 8 * 1024;
var
	originalLimit, actualLimit: size_t;
	Success:	Boolean;
	objType:	TGitObjectType;
	levelName: String;

	function IsInvalidObjectType(const ObjectType: TGitObjectType): Boolean;
	begin
		Result := (ObjectType = TGitObjectType.Any) or (ObjectType = TGitObjectType.Invalid);
	end;

begin

	for objType := Low(TGitObjectType) to High(TGitObjectType) do
	begin
		levelName := GetEnumName(TypeInfo(TGitObjectType), Ord(objType));
		if IsInvalidObjectType(objType) then
		begin
			Success := SetCacheObjectLimit(objType, testLimit);
			CheckFalse(Success,
				Format('SetCacheObjectLimit should fail for invalid object type %s', [levelName]));
		end
		else
		begin
			originalLimit := GetCacheObjectLimit(objType);

			Success := SetCacheObjectLimit(objType, testLimit);
			CheckTrue(Success,
				Format('SetCacheObjectLimit failed for valid object type %s', [levelName]));

			actualLimit := GetCacheObjectLimit(objType);
			CheckEquals(testLimit, actualLimit,
				Format('CacheObjectLimit was not set correctly for object type %s', [levelName]));

			Success := SetCacheObjectLimit(objType, originalLimit);
			CheckTrue(Success,
				Format('Failed to restore original CacheObjectLimit for object type %s', [levelName]));
		end;
	end;
end;

procedure TTestCommon.TestEnableCaching;
begin
	CheckTrue(EnableCaching, 'Enabling cache failed');
	CheckTrue(DisableCaching, 'Disabling cache failed');
	CheckTrue(EnableCaching, 'Enabling cache again failed');
end;

procedure TTestCommon.TestGetCachedMemory;
var
	current, allowed: ssize_t;
begin
	GetCachedMemory(current, allowed);

	CheckTrue(allowed > 0, 'Allowed cache memory should be positive');
	CheckTrue(current >= 0, 'Current cache usage should be non-negative');
	CheckTrue(current <= allowed, 'Current cache usage should not exceed allowed cache memory');

	GetCachedMemory(current, allowed);
	CheckTrue(allowed > 0, 'Allowed cache memory should still be positive');
end;

procedure TTestCommon.TestTemplatePath;
var
	originalPath, testPath, actualPath: String;
	res: Integer;
begin
	// TODO: test more potential failure points

	res := GetTemplatePath(originalPath);
	CheckEquals(0, res, 'GetTemplatePath failed');

	testPath := 'C:\fake\template\path';
	res		:= SetTemplatePath(testPath);
	CheckEquals(0, res, 'SetTemplatePath failed for ASCII path');

	res := GetTemplatePath(actualPath);
	CheckEquals(0, res, 'GetTemplatePath after set failed for ASCII path');
	CheckEquals(testPath, actualPath, 'SetTemplatePath did not update ASCII path correctly');

	testPath := 'C:\fäke\templäte\路径';
	res		:= SetTemplatePath(testPath);
	CheckEquals(0, res, 'SetTemplatePath failed for UTF-8 path');

	res := GetTemplatePath(actualPath);
	CheckEquals(0, res, 'GetTemplatePath after set failed for UTF-8 path');
	CheckEquals(testPath, actualPath, 'SetTemplatePath did not update UTF-8 path correctly');

	testPath := '';
	res		:= SetTemplatePath(testPath);
	CheckEquals(0, res, 'SetTemplatePath failed for empty path');

	res := GetTemplatePath(actualPath);
	CheckEquals(0, res, 'GetTemplatePath after set failed for empty path');
	CheckEquals(testPath, actualPath, 'SetTemplatePath did not update empty path correctly');

	res := SetTemplatePath(originalPath);
	CheckEquals(0, res, 'SetTemplatePath failed to restore original path');

	res := GetTemplatePath(actualPath);
	CheckEquals(0, res, 'GetTemplatePath after restore failed');
	CheckEquals(originalPath, actualPath, 'Restore of template path did not work');
end;

procedure TTestCommon.TestSetSSLCertLocations;
var
	res, i: Integer;
	err:	 PGitError;
begin
	// TODO: add more failure points

	res := SetSSLCertLocations('', '');
	if res < 0 then
	begin
		err := Libgit2GetLastError;
		CheckFalse(err = nil, 'Error info should be available on failure');
		CheckTrue(
			(err^.message = 'TLS backend doesn''t support certificate locations') or
			(err^.message = 'some other expected SSL error'),
			'Unexpected error message: ' + String(err^.message)
			);
	end
	else
	begin
		CheckEquals(0, res, 'SetSSLCertLocations failed unexpectedly');
	end;

	res := SetSSLCertLocations('nonexistent.pem', 'nonexistent_dir');
	if res < 0 then
	begin
		err := Libgit2GetLastError;
		CheckFalse(err = nil, 'Error info should be available on failure');
		CheckTrue(
			(err^.message = 'TLS backend doesn''t support certificate locations') or
			(err^.message = 'some other expected SSL error'),
			'Unexpected error message: ' + String(err^.message)
			);
	end
	else
	begin
		CheckEquals(0, res, 'SetSSLCertLocations failed unexpectedly');
	end;

	res := SetSSLCertLocations('', '');
	CheckTrue((res = 0) or (res < 0), 'SetSSLCertLocations with empty strings should succeed or fail gracefully');

	res := SetSSLCertLocations('validfile.pem', '');
	CheckTrue((res = 0) or (res < 0), 'SetSSLCertLocations with valid file and empty path');

	res := SetSSLCertLocations('', 'validpath');
	CheckTrue((res = 0) or (res < 0), 'SetSSLCertLocations with empty file and valid path');

	for i := 1 to 5 do
	begin
		res := SetSSLCertLocations('', '');
		CheckTrue((res = 0) or (res < 0), 'Repeated SetSSLCertLocations call failed');
	end;
end;

procedure TTestCommon.TestAddSSLX509Cert;
var
	res: Integer;
	err: PGitError;
begin
	// TODO: add more failure points

	res := AddSSLX509Cert(nil);
	CheckTrue(res < 0, 'AddSSLX509Cert with nil should fail');

	err := Libgit2GetLastError;
	CheckFalse(err = nil, 'Error info should be available on failure');
	CheckTrue(
		(err^.message = 'TLS backend doesn''t support adding of the raw certs') or
		(err^.message = 'some other expected SSL error'),
		'Unexpected error message: ' + String(err^.message)
		);

	res := AddSSLX509Cert(Pointer($1234));
	if res < 0 then
	begin
		err := Libgit2GetLastError;
		CheckFalse(err = nil, 'Error info should be available on failure');
		CheckTrue(
			(err^.message = 'TLS backend doesn''t support adding of the raw certs') or
			(err^.message = 'some other expected SSL error'),
			'Unexpected error message: ' + String(err^.message)
			);
	end;
end;

procedure TTestCommon.TestSetGetUserAgent;
var
	setAgent, getAgent: String;
	res: Integer;
	v:	TGitVersion;
	libgitVersion: String;
begin
	setAgent := 'FPCUnitAgent/1.0';

	res := SetUserAgent(setAgent);
	CheckEquals(0, res, 'SetUserAgent failed');

	res := GetUserAgent(getAgent);
	CheckEquals(0, res, 'GetUserAgent failed');
	CheckEquals(setAgent, getAgent, 'GetUserAgent did not return the expected value');

	res := SetUserAgent('');
	CheckEquals(0, res, 'SetUserAgent with empty string failed');

	res := GetUserAgent(getAgent);
	CheckEquals(0, res, 'GetUserAgent after empty string failed');

	v := GetVersion;
	libgitVersion := Format('libgit2 %d.%d.%d%s', [v.Major, v.Minor, v.Revision, GetPrerelease]);

	CheckEquals(libgitVersion, getAgent,
		'GetUserAgent after empty string did not reset to default (' + libgitVersion + ')');
end;

procedure TTestCommon.TestSetGetUserAgentProduct;
var
	setProduct, getProduct: String;
	res: Integer;
begin
	setProduct := 'MyProduct/2025.1';
	res := SetUserAgentProduct(setProduct);
	CheckEquals(0, res, 'SetUserAgentProduct failed');

	res := GetUserAgentProduct(getProduct);
	CheckEquals(0, res, 'GetUserAgentProduct failed');
	CheckEquals(setProduct, getProduct, 'GetUserAgentProduct did not return the expected value');

	res := SetUserAgentProduct('');
	CheckEquals(0, res, 'SetUserAgentProduct with empty string failed');

	res := GetUserAgentProduct(getProduct);
	CheckEquals(0, res, 'GetUserAgentProduct after empty string failed');
	CheckEquals('git/2.0', getProduct,
		'GetUserAgentProduct after empty string did not return default');
end;

procedure TTestCommon.TestSetGetUserAgentUnicode;
var
	setAgent, getAgent: String;
	res: Integer;
	v:	TGitVersion;
	libgitVersion: String;
begin
	setAgent := 'FPCUnitAgent/1.0 Ω≈ç√∫˜µ≤≥÷ 漢字中國中国ჩინეთი😄';

	res := SetUserAgent(setAgent);
	CheckEquals(0, res, 'SetUserAgent failed with UTF-8');

	res := GetUserAgent(getAgent);
	CheckEquals(0, res, 'GetUserAgent failed with UTF-8');
	CheckEquals(setAgent, getAgent, 'GetUserAgent did not return expected UTF-8 value');

	res := SetUserAgent('');
	CheckEquals(0, res, 'SetUserAgent with empty string failed');

	res := GetUserAgent(getAgent);
	CheckEquals(0, res, 'GetUserAgent after empty string failed');


	v := GetVersion;
	libgitVersion := Format('libgit2 %d.%d.%d%s', [v.Major, v.Minor, v.Revision, GetPrerelease]);

	CheckEquals(libgitVersion, getAgent,
		'GetUserAgent after empty string did not reset to default (' + libgitVersion + ')');
end;

procedure TTestCommon.TestSetGetUserAgentProductUnicode;
var
	setProduct, getProduct: String;
	res: Integer;
begin
	setProduct := 'MyProduct/1.0 Ω≈ç√∫˜µ≤≥÷ 漢字中國中国ჩინეთი😄';

	res := SetUserAgentProduct(setProduct);
	CheckEquals(0, res, 'SetUserAgentProduct failed with UTF-8');

	res := GetUserAgentProduct(getProduct);
	CheckEquals(0, res, 'GetUserAgentProduct failed with UTF-8');
	CheckEquals(setProduct, getProduct, 'GetUserAgentProduct did not return expected UTF-8 value');

	res := SetUserAgentProduct('');
	CheckEquals(0, res, 'SetUserAgentProduct with empty string failed');

	res := GetUserAgentProduct(getProduct);
	CheckEquals(0, res, 'GetUserAgentProduct after empty string failed');
	CheckEquals('git/2.0', getProduct, 'GetUserAgentProduct after empty string did not return default');
end;



procedure TTestCommon.TestAllFeatureToggles;
type
	TFeatureToggle = record
		Name: String;
		EnableProc: procedure;
		DisableProc: procedure;
		IsEnabledFunc: function: Boolean;
	end;
const
	FeatureToggles: array[0..7] of TFeatureToggle = (
		(Name: 'StrictObjectCreation'; EnableProc: @EnableStrictObjectCreation; DisableProc: @DisableStrictObjectCreation;
		IsEnabledFunc: @IsStrictObjectCreationEnabled),
		(Name: 'StrictSymbolicRefCreation'; EnableProc: @EnableStrictSymbolicRefCreation;
		DisableProc: @DisableStrictSymbolicRefCreation; IsEnabledFunc: @IsStrictSymbolicRefCreationEnabled),
		(Name: 'OfsDelta'; EnableProc: @EnableOfsDelta; DisableProc: @DisableOfsDelta; IsEnabledFunc: @IsOfsDeltaEnabled),
		(Name: 'FSyncGitdir'; EnableProc: @EnableFSyncGitdir; DisableProc: @DisableFSyncGitdir;
		IsEnabledFunc: @IsFSyncGitdirEnabled),
		(Name: 'StrictHashVerification'; EnableProc: @EnableStrictHashVerification;
		DisableProc: @DisableStrictHashVerification; IsEnabledFunc: @IsStrictHashVerificationEnabled),
		(Name: 'UnsavedIndexSafety'; EnableProc: @EnableUnsavedIndexSafety; DisableProc: @DisableUnsavedIndexSafety;
		IsEnabledFunc: @IsUnsavedIndexSafetyEnabled),
		(Name: 'PackKeepFileChecks'; EnableProc: @DisablePackKeepFileChecks; DisableProc: @EnablePackKeepFileChecks;
		IsEnabledFunc: @IsPackKeepFileChecksDisabled), // note inverse logic
		(Name: 'HttpExpectContinue'; EnableProc: @EnableHttpExpectContinue; DisableProc: @DisableHttpExpectContinue;
		IsEnabledFunc: @IsHttpExpectContinueEnabled)
		);
var
	toggle: TFeatureToggle;
begin
	for toggle in FeatureToggles do
	begin
		toggle.DisableProc;
		CheckFalse(toggle.IsEnabledFunc(), toggle.Name + ' should be disabled');

		toggle.EnableProc;
		CheckTrue(toggle.IsEnabledFunc(), toggle.Name + ' should be enabled');
	end;
end;

procedure TTestCommon.TestSetGetPackMaxObjects;
var
	original, testValue, readBack: size_t;
begin
	original := GetPackMaxObjects;
	CheckTrue(original <= UINT32_MAX, 'Pack max object limit is bigger than UINT32_MAX');
	CheckTrue(original <> 0, 'Pack max object limit is zero');

	testValue := 123456;
	SetPackMaxObjects(testValue);

	readBack := GetPackMaxObjects;
	CheckEquals(testValue, readBack, 'GetPackMaxObjects did not return the set value');

	SetPackMaxObjects(original);

	readBack := GetPackMaxObjects;
	CheckEquals(original, readBack, 'Original PackMaxObjects value was not restored');
end;

procedure TTestCommon.TestSetGetODBPriority;
var
	originalPacked, originalLoose: Integer;
begin
	originalPacked := GetODBPackedPriority;
	CheckEquals(2, originalPacked, 'Expected default packed priority = 2. Has the DLL changed?');

	originalLoose := GetODBLoosePriority;
	CheckEquals(1, originalLoose, 'Expected default loose priority = 1. Has the DLL changed?');

	SetODBPackedPriority(20);
	CheckEquals(20, GetODBPackedPriority, 'Packed priority was not updated to 20');

	SetODBLoosePriority(10);
	CheckEquals(10, GetODBLoosePriority, 'Loose priority was not updated to 10');

	SetODBPackedPriority(20);
	CheckEquals(20, GetODBPackedPriority, 'Packed priority changed unexpectedly on re-set');

	SetODBPackedPriority(originalPacked);
	CheckEquals(originalPacked, GetODBPackedPriority, 'Failed to restore original packed priority');

	SetODBLoosePriority(originalLoose);
	CheckEquals(originalLoose, GetODBLoosePriority, 'Failed to restore original loose priority');
end;

const
	ExpectedBuiltinExtensions: TStringArray = (
		'noop', 'objectformat', 'preciousobjects', 'worktreeconfig'
		);

function HasExtension(const Extensions: TStringArray; const Ext: String): Boolean;
var
	i: Integer;
begin
	Result := False;
	for i := Low(Extensions) to High(Extensions) do
	begin
		if Extensions[i] = Ext then
		begin
			Exit(True);
		end;
	end;
end;

procedure CheckExtensionsContain(Test: TTestCase; const Extensions: TStringArray; const expected: array of String);
var
	i: Integer;
begin
	for i := Low(expected) to High(expected) do
	begin
		Test.CheckTrue(HasExtension(Extensions, expected[i]), Format('Missing builtin extension: %s', [expected[i]]));
	end;
end;

function HasDuplicates(const Arr: TStringArray): Boolean;
var
	Seen: specialize TDictionary<String, Boolean>;
	Ext:  String;
begin
	Seen := specialize TDictionary<String, Boolean>.Create;
	try
		for Ext in Arr do
		begin
			if Seen.ContainsKey(Ext) then
			begin
				Exit(True);
			end;
			Seen.Add(Ext, True);
		end;
		Result := False;
	finally
		Seen.Free;
	end;
end;

function CountExtension(const Extensions: TStringArray; const Ext: String): Integer;
var
	i: Integer;
begin
	Result := 0;
	for i := Low(Extensions) to High(Extensions) do
	begin
		if Extensions[i] = Ext then
		begin
			Inc(Result);
		end;
	end;
end;

procedure TTestCommon.TestSetGetExtensions;
var
	original, updated: TStringArray;
	testExtensions: TStringArray;
	Ext: String;
	builtinToNegate: String;
begin
	CheckEquals(0, GetExtensions(original), 'GetExtensions (original) failed');
	CheckExtensionsContain(Self, original, ExpectedBuiltinExtensions);
	CheckFalse(HasDuplicates(original), 'Original extensions have duplicates');

	if Length(ExpectedBuiltinExtensions) = 0 then
	begin
		Fail('No builtin extensions to test negation with');
	end;
	builtinToNegate := ExpectedBuiltinExtensions[0];

	testExtensions := ['foo',			 // user extension
		'bar',			  // user extension
		'bar',			  // duplicate user extension (expected to be removed)
		'!' + builtinToNegate, // negation of builtin
		'Üñïçødë',		 // unicode user extension
		'naïve'			// unicode user extension
		];

	CheckEquals(0, SetExtensions(testExtensions), 'SetExtensions failed');
	CheckEquals(0, GetExtensions(updated), 'GetExtensions (after set) failed');

	for Ext in ExpectedBuiltinExtensions do
	begin
		if Ext = builtinToNegate then
		begin
			CheckFalse(HasExtension(updated, Ext), Format('Negated builtin "%s" still present', [Ext]));
		end
		else
		begin
			CheckTrue(HasExtension(updated, Ext), Format('Builtin extension "%s" missing after set', [Ext]));
		end;
	end;

	CheckTrue(HasExtension(updated, 'foo'), 'User extension "foo" missing');
	CheckTrue(HasExtension(updated, 'bar'), 'User extension "bar" missing');
	CheckEquals(1, CountExtension(updated, 'bar'), 'User extension "bar" should appear only once');

	CheckTrue(HasExtension(updated, 'Üñïçødë'), 'Unicode extension "Üñïçødë" missing');
	CheckTrue(HasExtension(updated, 'naïve'), 'Unicode extension "naïve" missing');

	testExtensions := ['foo', 'bar', '!foo'];
	CheckEquals(0, SetExtensions(testExtensions), 'SetExtensions with negated user extension failed');
	CheckEquals(0, GetExtensions(updated), 'GetExtensions after negated user ext failed');
	CheckTrue(HasExtension(updated, 'foo'), 'User extension "foo" was wrongly removed by negation');

	CheckFalse(HasDuplicates(updated), 'Extensions have duplicates after setting');

	CheckEquals(0, SetExtensions([]), 'SetExtensions([]) failed');
	CheckEquals(0, GetExtensions(updated), 'GetExtensions after reset failed');
	CheckExtensionsContain(Self, updated, ExpectedBuiltinExtensions);
	CheckFalse(HasDuplicates(updated), 'Extensions after reset have duplicates');

	CheckEquals(0, SetExtensions(original), 'SetExtensions (restore original) failed');
end;

procedure TTestCommon.TestSetGetOwnerValidation;
var
	original, current: Boolean;
begin
	original := GetOwnerValidation;

	SetOwnerValidation(False);
	current := GetOwnerValidation;
	CheckFalse(current, 'OwnerValidation should be disabled');

	SetOwnerValidation(True);
	current := GetOwnerValidation;
	CheckTrue(current, 'OwnerValidation should be enabled');

	SetOwnerValidation(True);
	CheckTrue(GetOwnerValidation, 'OwnerValidation should remain enabled');

	SetOwnerValidation(original);
	CheckEquals(original, GetOwnerValidation, 'OwnerValidation was not restored properly');
end;

procedure TTestCommon.TestSetGetHomeDirectory;
var
	original, actual: String;
	originalParts, actualParts: TStringList;
	testPath, unicodePath, nonExistentPath: String;

	procedure SplitPaths(const pathList: String; out parts: TStringList);
	var
		delimiter: Char;
	begin
		parts := TStringList.Create;
		try
			delimiter := GIT_PATH_LIST_SEPARATOR;
			parts.StrictDelimiter := True;
			parts.delimiter := delimiter;
			if pathList <> '' then
			begin
				parts.DelimitedText := pathList;
			end
			else
			begin
				parts.Clear;
			end;
		except
			parts.Free;
			raise;
		end;
	end;

	procedure CheckPathsExist(const parts: TStringList; const Msg: String);
	var
		i: Integer;
	begin
		for i := 0 to parts.Count - 1 do
		begin
			CheckTrue(
				DirectoryExists(parts[i]) or FileExists(parts[i]),
				Format('%s: Path does not exist: %s', [Msg, parts[i]])
				);
		end;
	end;

	procedure CleanupDir(const dir: String);
	begin
		if DirectoryExists(dir) then
		begin
			CheckTrue(RemoveDir(dir), 'Failed to remove directory: ' + dir);
		end;
	end;

begin
	CheckEquals(0, GetHomeDirectory(original), 'GetHomeDirectory (original) failed');
	CheckNotEquals('', original, 'Original home directory string is empty');

	SplitPaths(original, originalParts);
	try
		CheckTrue(originalParts.Count > 0, 'Original home directory list is empty');
		CheckPathsExist(originalParts, 'Original home directory');
	finally
		originalParts.Free;
	end;

	testPath := IncludeTrailingPathDelimiter(GetTempDir) + 'libgit2_test_home';
	CheckTrue(ForceDirectories(testPath), 'Failed to create test directory');
	CheckTrue(DirectoryExists(testPath), 'Test directory does not exist after creation');

	unicodePath := IncludeTrailingPathDelimiter(GetTempDir) + 'hømê-Üñïçødë';
	CheckTrue(ForceDirectories(unicodePath), 'Failed to create unicode directory');
	CheckTrue(DirectoryExists(unicodePath), 'Unicode directory does not exist after creation');

	nonExistentPath := IncludeTrailingPathDelimiter(GetTempDir) + 'libgit2_nonexistent_home';
	CleanupDir(nonExistentPath);
	CheckFalse(DirectoryExists(nonExistentPath), 'Nonexistent path unexpectedly exists');

	try
		CheckEquals(0, SetHomeDirectory(testPath), 'SetHomeDirectory (test path) failed');
		CheckEquals(0, GetHomeDirectory(actual), 'GetHomeDirectory (after set test path) failed');
		SplitPaths(actual, actualParts);
		try
			CheckEquals(1, actualParts.Count, 'Expected one home directory after setting single path');
			CheckTrue(SameText(testPath, ExcludeTrailingPathDelimiter(actualParts[0])),
				'Home directory does not match test path');
		finally
			actualParts.Free;
		end;

		CheckEquals(0, SetHomeDirectory(unicodePath), 'SetHomeDirectory (unicode path) failed');
		CheckEquals(0, GetHomeDirectory(actual), 'GetHomeDirectory (after set unicode) failed');
		SplitPaths(actual, actualParts);
		try
			CheckEquals(1, actualParts.Count, 'Expected one home directory after setting unicode path');
			CheckTrue(SameText(unicodePath, ExcludeTrailingPathDelimiter(actualParts[0])),
				'Home directory does not match unicode path');
		finally
			actualParts.Free;
		end;

		CheckEquals(0, SetHomeDirectory(nonExistentPath), 'SetHomeDirectory (nonexistent path) failed');
		CheckEquals(0, GetHomeDirectory(actual), 'GetHomeDirectory (after set nonexistent) failed');
		SplitPaths(actual, actualParts);
		try
			CheckEquals(1, actualParts.Count, 'Expected one home directory after setting nonexistent path');
			CheckTrue(SameText(nonExistentPath, ExcludeTrailingPathDelimiter(actualParts[0])),
				'Home directory does not match nonexistent path');
		finally
			actualParts.Free;
		end;

		CheckEquals(0, SetHomeDirectory(''), 'SetHomeDirectory (reset) failed');
		CheckEquals(0, GetHomeDirectory(actual), 'GetHomeDirectory (after reset) failed');
		SplitPaths(actual, actualParts);
		try
			CheckTrue(actualParts.Count > 0, 'Reset home directory list is empty');
			CheckPathsExist(actualParts, 'Reset home directory');
		finally
			actualParts.Free;
		end;

	finally
		CleanupDir(testPath);
		CleanupDir(unicodePath);
	end;

	CheckEquals(0, SetHomeDirectory(original), 'Restoring original home directory failed');
	CheckEquals(0, GetHomeDirectory(actual), 'Verifying restored home directory failed');
	CheckTrue(SameText(ExcludeTrailingPathDelimiter(original), ExcludeTrailingPathDelimiter(actual)),
		'Restored home directory does not match original');
end;

procedure TTestCommon.TestSetGetServerTimeout;
var
	originalTimeout, newTimeout: Integer;
	Success: Boolean;
begin
	Success := TryGetServerTimeout(originalTimeout);
	CheckTrue(Success, 'Failed to get original server timeout');
	CheckFalse(originalTimeout < 0, 'Original server timeout should be non-negative');
	CheckEquals(0, originalTimeout, 'Original server timeout should be 0 (did you change the defaults?)');

	newTimeout := originalTimeout + 10;
	Success	 := TrySetServerTimeout(newTimeout);
	CheckTrue(Success, 'TrySetServerTimeout should succeed for non-negative value');

	Success := TryGetServerTimeout(originalTimeout);
	CheckTrue(Success, 'Failed to get server timeout after set');
	CheckEquals(newTimeout, originalTimeout, 'Server timeout should match newly set value');

	Success := TrySetServerTimeout(0);
	CheckTrue(Success, 'TrySetServerTimeout should succeed for zero timeout');

	Success := TryGetServerTimeout(newTimeout);
	CheckTrue(Success, 'Failed to get server timeout after zero set');
	CheckEquals(0, newTimeout, 'Server timeout should be zero after setting it');

	Success := TrySetServerTimeout(-1);
	CheckFalse(Success, 'TrySetServerTimeout should fail for negative value');

	Success := TryGetServerTimeout(newTimeout);
	CheckTrue(Success, 'Failed to get server timeout after failed set');
	CheckEquals(0, newTimeout, 'Server timeout should remain unchanged after failed set');

	Success := TryGetServerTimeout(originalTimeout);
	CheckTrue(Success, 'Failed to get current server timeout before idempotent set');
	Success := TrySetServerTimeout(originalTimeout);
	CheckTrue(Success, 'TrySetServerTimeout should succeed when setting current value');

	Success := TryGetServerTimeout(newTimeout);
	CheckTrue(Success, 'Failed to get server timeout after idempotent set');
	CheckEquals(originalTimeout, newTimeout, 'Server timeout should be unchanged after idempotent set');
end;

procedure TTestCommon.TestSetGetServerConnectTimeout;
var
	originalConnectTimeout, newConnectTimeout: Integer;
	Success: Boolean;
begin
	Success := TryGetServerConnectTimeout(originalConnectTimeout);
	CheckTrue(Success, 'Failed to get original server connect timeout');
	CheckFalse(originalConnectTimeout < 0, 'Original server connect timeout should be non-negative');
	CheckEquals(0, originalConnectTimeout, 'Original server connect timeout should be 0 (did you change the defaults?)');

	newConnectTimeout := originalConnectTimeout + 10;
	Success := TrySetServerConnectTimeout(newConnectTimeout);
	CheckTrue(Success, 'TrySetServerConnectTimeout should succeed for non-negative value');

	Success := TryGetServerConnectTimeout(originalConnectTimeout);
	CheckTrue(Success, 'Failed to get server connect timeout after set');
	CheckEquals(newConnectTimeout, originalConnectTimeout, 'Server connect timeout should match newly set value');

	Success := TrySetServerConnectTimeout(0);
	CheckTrue(Success, 'TrySetServerConnectTimeout should succeed for zero timeout');

	Success := TryGetServerConnectTimeout(newConnectTimeout);
	CheckTrue(Success, 'Failed to get server connect timeout after zero set');
	CheckEquals(0, newConnectTimeout, 'Server connect timeout should be zero after setting it');

	Success := TrySetServerConnectTimeout(-1);
	CheckFalse(Success, 'TrySetServerConnectTimeout should fail for negative value');

	Success := TryGetServerConnectTimeout(newConnectTimeout);
	CheckTrue(Success, 'Failed to get server connect timeout after failed set');
	CheckEquals(0, newConnectTimeout, 'Server connect timeout should remain unchanged after failed set');

	Success := TryGetServerConnectTimeout(originalConnectTimeout);
	CheckTrue(Success, 'Failed to get current server connect timeout before idempotent set');
	Success := TrySetServerConnectTimeout(originalConnectTimeout);
	CheckTrue(Success, 'TrySetServerConnectTimeout should succeed when setting current value');

	Success := TryGetServerConnectTimeout(newConnectTimeout);
	CheckTrue(Success, 'Failed to get server connect timeout after idempotent set');
	CheckEquals(originalConnectTimeout, newConnectTimeout,
		'Server connect timeout should be unchanged after idempotent set');

	Success := TrySetServerConnectTimeout(originalConnectTimeout);
	CheckTrue(Success, 'Restoring original server connect timeout should succeed');

	Success := TryGetServerConnectTimeout(newConnectTimeout);
	CheckTrue(Success, 'Verifying restored server connect timeout failed');
	CheckEquals(originalConnectTimeout, newConnectTimeout, 'Original server connect timeout should be restored');
end;


initialization
	RegisterTest(TTestCommon);
end.
