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
	LibGit2.StdInt;

type

	TTestCommon = class(TTestCase)
	published
		procedure SetUp; override;
		procedure TearDown; override;

		procedure TestVersion;
		procedure TestCheckIfNotEmptyFeatureSet;
		procedure TestCheckIfAlwaysAvailableFeaturesExist;
		{$IF DEFINED(WINDOWS) OR DEFINED(MSWINDOWS)}
		procedure TestCheckIfWindowsFeaturesExist;
		{$ENDIF}
		procedure TestCheckIfPrereleaseValid;
		procedure TestBackends;

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

procedure TTestCommon.TestBackends;
const
	allowedBackends: array[TGitFeature] of TStringArray = (
		// Threads
		('win32', 'pthread'),
		// HTTPS
		('openssl', 'openssl-dynamic', 'mbedtls', 'securetransport', 'schannel', 'winhttp'),
		// SSH
		('exec', 'libssh2'),
		// NSec
		('mtimespec', 'mtim', 'mtime', 'win32'),
		// HttpParser
		('httpparser', 'llhttp', 'builtin'),
		// Regex
		('regcomp_l', 'regcomp', 'pcre', 'pcre2', 'builtin'),
		// I18N
		('iconv'),
		// AuthNTLM
		('ntlmclient', 'sspi'),
		// AuthNegotiate
		('gssapi', 'sspi'),
		// Compression
		('zlib', 'builtin'),
		// SHA1
		('builtin', 'openssl', 'openssl-fips', 'openssl-dynamic', 'mbedtls', 'commoncrypto', 'win32'),
		// SHA256
		('builtin', 'openssl', 'openssl-fips', 'openssl-dynamic', 'mbedtls', 'commoncrypto', 'win32')
		);
var
	features: TGitFeatures;
	feature: TGitFeature;
	backend: String;
	allowedList: TStringArray;
	allowedBackend: String;
	found: Boolean;
	i:	  Integer;
	featureName: String;
begin
	features := GetFeatures;

	for feature := Low(TGitFeature) to High(TGitFeature) do
	begin
		featureName := GetEnumName(TypeInfo(TGitFeature), Ord(feature));
		backend	  := GetFeatureBackend(feature);

		if feature in features then
		begin
			CheckNotEquals(backend, '',
				Format('Enabled feature %s has empty backend', [featureName])
				);

			allowedList := allowedBackends[feature];
			found := False;

			if Length(allowedList) = 0 then
			begin
				Fail(Format('No allowed backends specified for feature %s', [featureName]));
				Continue;
			end;

			for allowedBackend in allowedList do
			begin
				if SameText(backend, allowedBackend) then
				begin
					found := True;
					Break;
				end;
			end;

			CheckTrue(found,
				Format('Backend "%s" for feature %s is not in the allowed list', [backend, featureName])
				);
		end
		else
		begin
			CheckTrue(
				backend.IsEmpty,
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
	Pgit_error = ^Tgit_error;

	Tgit_error = record
		message: Pansichar;
		klass:	Integer;
	end;

// TODO: move this into the right unit
function Libgit2GetLastError: Pgit_error; cdecl; varargs; external LibGit2Dll name 'git_error_last';

procedure TTestCommon.TestGetSetResetSearchPath;
const
	TestBasePath = 'test_path';

	function JoinPaths(const Paths: array of String): String;
	var
		sb: TStringBuilder;
		i:  Integer;
	begin
		sb := TStringBuilder.Create;
		try
			for i := Low(Paths) to High(Paths) do
			begin
				if Paths[i] = '' then
				begin
					Continue;
				end;
				if sb.Length > 0 then
				begin
					sb.Append(PathSeparator);
				end;
				sb.Append(Paths[i]);
			end;
			Result := sb.ToString;
		finally
			sb.Free;
		end;
	end;

	procedure CheckLibgit2(ResultCode: Integer; const Msg: String);
	var
		err: Pgit_error;
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
		res: Integer;
	begin
		levelName := GetEnumName(TypeInfo(TGitConfigLevel), Ord(level));
		testPath  := Format('%s_%d', [TestBasePath, Ord(level)]);

		res := GetSearchPath(level, originalPath);
		CheckLibgit2(res, Format('[%s] GetSearchPath (original)', [levelName]));

		res := SetSearchPath(level, testPath);
		CheckLibgit2(res, Format('[%s] SetSearchPath', [levelName]));

		res := GetSearchPath(level, actualPath);
		CheckLibgit2(res, Format('[%s] GetSearchPath (after set)', [levelName]));
		CheckEquals(testPath, actualPath, Format('[%s] Set path mismatch', [levelName]));

		appendedPath := JoinPaths([actualPath, testPath]);
		res := SetSearchPath(level, appendedPath);
		CheckLibgit2(res, Format('[%s] SetSearchPath (append)', [levelName]));

		res := GetSearchPath(level, actualPath);
		CheckLibgit2(res, Format('[%s] GetSearchPath (after append)', [levelName]));
		CheckEquals(appendedPath, actualPath, Format('[%s] Appended path mismatch', [levelName]));

		res := ResetSearchPath(level);
		CheckLibgit2(res, Format('[%s] ResetSearchPath', [levelName]));

		res := GetSearchPath(level, actualPath);
		CheckLibgit2(res, Format('[%s] GetSearchPath (after reset)', [levelName]));

		if level <> TGitConfigLevel.System then
		begin
			CheckEquals(originalPath, actualPath, Format('[%s] Reset did not restore path', [levelName]));
		end;
	end;

var
	i: Integer;
begin
	for i := Ord(TGitConfigLevel.ProgramData) to Ord(TGitConfigLevel.Global) do
	begin
		TestLevelPath(TGitConfigLevel(i));
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
	CheckTrue(EnableCaching(True), 'Enabling cache failed');
	CheckTrue(EnableCaching(False), 'Disabling cache failed');
	CheckTrue(EnableCaching(True), 'Enabling cache again failed');
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
	err:	 Pgit_error;
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
	err: Pgit_error;
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

initialization
	RegisterTest(TTestCommon);
end.
