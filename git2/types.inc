type
	TGitOffset	 = int64_t;
	TGitTimestamp = int64_t;

	TGitObjectSize = uint64_t;

	TGitObjectType = (
		gotAny = -2,
		gotInvalid = -1,
		gotCommit = 1,
		gotTree = 2,
		gotBlob = 3,
		gotTag = 4,
		gotOfsDelta = 6,
		gotRefDelta = 7
		);

	PGitODB = ^TGitODB;
	TGitODB = record
	end;

	PGitODBBackend = ^TGitODBBackend;
	TGitODBBackend = record
	end;

	PGitODBObject = ^TGitODBObject;
	TGitODBObject = record
	end;

	PGitODBStream = ^TGitODBStream;
	TGitODBStream = record
	end;

	PGitODBWritepack = ^TGitODBWritepack;
	TGitODBWritepack = record
	end;

	PGitMidxWriter = ^TGitMidxWriter;
	TGitMidxWriter = record
	end;

	PGitRefDB = ^TGitRefDB;
	TGitRefDB = record
	end;

	PGitRefDBBackend = ^TGitRefDBBackend;
	TGitRefDBBackend = record
	end;

	PGitCommitGraph = ^TGitCommitGraph;
	TGitCommitGraph = record
	end;

	PGitCommitGraphWriter = ^TGitCommitGraphWriter;
	TGitCommitGraphWriter = record
	end;

	PGitRepository = ^TGitRepository;
	TGitRepository = record
	end;

	PGitWorktree = ^TGitWorktree;
	TGitWorktree = record
	end;

	PGitObject = ^TGitObject;
	TGitObject = record
	end;

	PGitRevWalk = ^TGitRevWalk;
	TGitRevWalk = record
	end;

	PGitTag = ^TGitTag;
	TGitTag = record
	end;

	PGitBlob = ^TGitBlob;
	TGitBlob = record
	end;

	PGitCommit = ^TGitCommit;
	TGitCommit = record
	end;

	PGitTreeEntry = ^TGitTreeEntry;
	TGitTreeEntry = record
	end;

	PGitTree = ^TGitTree;
	TGitTree = record
	end;

	PGitTreeBuilder = ^TGitTreeBuilder;
	TGitTreeBuilder = record
	end;

	PGitIndex = ^TGitIndex;
	TGitIndex = record
	end;

	PGitIndexIterator = ^TGitIndexIterator;
	TGitIndexIterator = record
	end;

	PGitIndexConflictIterator = ^TGitIndexConflictIterator;
	TGitIndexConflictIterator = record
	end;

	PGitConfig = ^TGitConfig;
	TGitConfig = record
	end;

	PGitConfigBackend = ^TGitConfigBackend;
	TGitConfigBackend = record
	end;

	PGitReflogEntry = ^TGitReflogEntry;
	TGitReflogEntry = record
	end;

	PGitReflog = ^TGitReflog;
	TGitReflog = record
	end;

	PGitNote = ^TGitNote;
	TGitNote = record
	end;

	PGitPackBuilder = ^TGitPackBuilder;
	TGitPackBuilder = record
	end;

	TGitTime = record
		Time:	TGitTimestamp;
		Offset: CInt;
		Sign:	CChar;
	end;

	TGitSignature = record
		Name:  PCChar;
		Email: PCChar;
		When:  TGitTime;
	end;

	PGitReference = ^TGitReference;
	TGitReference = record
	end;

	PGitReferenceIterator = ^TGitReferenceIterator;
	TGitReferenceIterator = record
	end;

	PGitTransaction = ^TGitTransaction;
	TGitTransaction = record
	end;

	PGitAnnotatedCommit = ^TGitAnnotatedCommit;
	TGitAnnotatedCommit = record
	end;

	PGitStatusList = ^TGitStatusList;
	TGitStatusList = record
	end;

	PGitRebase = ^TGitRebase;
	TGitRebase = record
	end;

	TGitReferenceType = (
		grtInvalid = 0,
		grtDirect = 1,
		grtSymbolic = 2,
		grtAll = 3
		);

	TGitBranchType = (
		gbtLocal = 1,
		gbtRemote = 2,
		gbtAll = 3
		);

	TGitFilemodeType = (
		gfmUnreadable = 0,
		gfmTree = 0040000,
		gfmBlob = 0100644,
		gfmBlobExecutable = 0100755,
		gfmLink = 0120000,
		gfmCommit = 0160000
		);

	PGitRefSpec = ^TGitRefSpec;
	TGitRefSpec = record
	end;

	PGitRemote = ^TGitRemote;
	TGitRemote = record
	end;

	PGitTransport = ^TGitTransport;
	TGitTransport = record
	end;

	PGitPush = ^TGitPush;
	TGitPush = record
	end;

	PGitRemoteHead = ^TGitRemoteHead;
	TGitRemoteHead = record
	end;

	PGitRemoteCallbacks = ^TGitRemoteCallbacks;
	TGitRemoteCallbacks = record
	end;

	PGitCert = ^TGitCert;
	TGitCert = record
	end;

	PGitSubmodule = ^TGitSubmodule;
	TGitSubmodule = record
	end;

	TGitSubmoduleUpdateType = (
		gsuDefault = 0,
		gsuCheckout = 1,
		gsuRebase = 2,
		gsuMerge = 3,
		gsuNone = 4
		);

	TGitSubmoduleIgnoreType = (
		gsiUnspecified = -1,
		gsiNone = 1,
		gsiUntracked = 2,
		gsiDirty = 3,
		gsiAll = 4
		);

	TGitSubmoduleRecurseType = (
		gsrNo = 0,
		gsrYes = 1,
		gsrOnDemand = 2
		);

	PGitWriteStream = ^TGitWriteStream;

	TGitWritestreamWriteFunc = function(Stream: PGitWriteStream; const Buffer: PCChar; Length: size_t): CInt; cdecl;
	TGitWritestreamCloseFunc = function(Stream: PGitWriteStream): CInt; cdecl;
	TGitWritestreamFreeFunc = procedure(Stream: PGitWriteStream); cdecl;

	TGitWriteStream = record
		WriteFunc: TGitWritestreamWriteFunc;
		CloseFunc: TGitWritestreamCloseFunc;
		FreeFunc:  TGitWritestreamFreeFunc;
	end;

	PGitMailmap = ^TGitMailmap;
	TGitMailmap = record
	end;
