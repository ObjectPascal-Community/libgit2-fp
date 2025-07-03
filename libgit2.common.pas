unit LibGit2.Common;

{$mode objfpc}{$H+}{$ScopedEnums on}

interface

uses
	LibGit2.Platform;

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

implementation

var
	CachedFeatures: TGitFeatures;
	FeaturesCached: Boolean = False;

function Libgit2GetVersion(Major, Minor, rev: PInteger): Integer;
	cdecl; external LibGit2Dll name 'git_libgit2_version';
function Libgit2GetPrerelease: Pansichar; cdecl; external LibGit2Dll name 'git_libgit2_prerelease';
function Libgit2Features: Integer; cdecl; external LibGit2Dll name 'git_libgit2_features';
function Libgit2FeatureBackend(feature: Integer): Pansichar;
	cdecl; external LibGit2Dll name 'git_libgit2_feature_backend';

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

end.
