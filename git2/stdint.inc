(* ISO C9x  compliant stdint.h for Microsoft Visual Studio
 * Based on ISO/IEC 9899:TC2 Committee draft (May 6, 2005) WG14/N1124
 *
 *  Copyright (c) 2006-2008 Alexander Chemeris
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   1. Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. The name of the author may be used to endorse or promote products
 *      derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *******************************************************************************)

(*
 * 7.18.1 Integer types
 *)

(*
 * 7.18.1.1 Exact-width integer types
 *)

type
	int8_t  = cint8;
	int16_t = cint16;
	int32_t = cint32;
	int64_t = cint64;

	uint8_t  = cint8;
	uint16_t = cint16;
	uint32_t = cint32;
	uint64_t = cint64;

(*
 * 7.18.1.2 Minimum-width integer types
 *)

type
	int_least8_t  = int8_t;
	int_least16_t = int16_t;
	int_least32_t = int32_t;
	int_least64_t = int64_t;

	uint_least8_t  = uint8_t;
	uint_least16_t = uint16_t;
	uint_least32_t = uint32_t;
	uint_least64_t = uint64_t;

(*
 * 7.18.1.2 Fastest minimum-width integer types
 *)

type
	int_fast8_t  = int8_t;
	int_fast16_t = int16_t;
	int_fast32_t = int32_t;
	int_fast64_t = int64_t;

	uint_fast8_t  = uint8_t;
	uint_fast16_t = uint16_t;
	uint_fast32_t = uint32_t;
	uint_fast64_t = uint64_t;

(*
 * 7.18.1.4 Integer types capable of holding object pointers
 *)

type
	intptr_t  = {$IFDEF CPU64}cint64{$ELSE}cint32{$ENDIF};
	uintptr_t = {$IFDEF CPU64}cuint64{$ELSE}cuint32{$ENDIF};

(*
 * 7.18.1.5 Greatest-width integer types
 *)

type
	intmax_t  = int64_t;
	uintmax_t = uint64_t;

(*
 * 7.18.2 Limits of specified-width integer types
 *)

const
(*
 * 7.18.2.1 Limits of exact-width integer types
 *)
	INT8_MIN  = int8_t(Low(int8_t));
	INT8_MAX  = int8_t(High(int8_t));
	INT16_MIN = int16_t(Low(int16_t));
	INT16_MAX = int16_t(High(int16_t));
	INT32_MIN = int32_t(Low(int32_t));
	INT32_MAX = int32_t(High(int32_t));
	INT64_MIN = int64_t(Low(int64_t));
	INT64_MAX = int64_t(High(int64_t));

	UINT8_MAX  = uint8_t(High(uint8_t));
	UINT16_MAX = uint16_t(High(uint16_t));
	UINT32_MAX = uint32_t(High(uint32_t));
	UINT64_MAX = uint64_t(High(uint64_t));

(*
 * 7.18.2.2 Limits of minimum-width integer types
 *)
	INT8_LEAST_MIN  = INT8_MIN;
	INT8_LEAST_MAX  = INT8_MAX;
	INT16_LEAST_MIN = INT16_MIN;
	INT16_LEAST_MAX = INT16_MAX;
	INT32_LEAST_MIN = INT32_MIN;
	INT32_LEAST_MAX = INT32_MAX;
	INT64_LEAST_MIN = INT64_MIN;
	INT64_LEAST_MAX = INT64_MAX;

	UINT8_LEAST_MAX  = UINT8_MAX;
	UINT16_LEAST_MAX = UINT16_MAX;
	UINT32_LEAST_MAX = UINT32_MAX;
	UINT64_LEAST_MAX = UINT64_MAX;

(*
 * 7.18.2.2 Limits of fastest minimum-width integer types
 *)
	INT8_FAST_MIN  = INT8_MIN;
	INT8_FAST_MAX  = INT8_MAX;
	INT16_FAST_MIN = INT16_MIN;
	INT16_FAST_MAX = INT16_MAX;
	INT32_FAST_MIN = INT32_MIN;
	INT32_FAST_MAX = INT32_MAX;
	INT64_FAST_MIN = INT64_MIN;
	INT64_FAST_MAX = INT64_MAX;

	UINT8_FAST_MAX  = UINT8_MAX;
	UINT16_FAST_MAX = UINT16_MAX;
	UINT32_FAST_MAX = UINT32_MAX;
	UINT64_FAST_MAX = UINT64_MAX;

(*
 * 7.18.2.4 Limits of integer types capable of holding object pointers
 *)
	INTPTR_MIN  = {$IFDEF CPU64}INT64_MIN{$ELSE}INT32_MIN{$ENDIF};
	INTPTR_MAX  = {$IFDEF CPU64}INT64_MAX{$ELSE}INT32_MAX{$ENDIF};
	UINTPTR_MAX = {$IFDEF CPU64}UINT64_MAX{$ELSE}UINT32_MAX{$ENDIF};

(*
 * 7.18.2.5 Limits of maximum-width integer types
 *)
	INTMAX_MIN  = INT64_MIN;
	INTMAX_MAX  = INT64_MAX;
	UINTMAX_MAX = UINT64_MAX;

(*
 * 7.18.3 Limits of other integer types
 *)
const
	PTRDIFF_MIN = {$IFDEF CPU64}INT64_MIN{$ELSE}INT32_MIN{$ENDIF};
	PTRDIFF_MAX = {$IFDEF CPU64}INT64_MAX{$ELSE}INT32_MAX{$ENDIF};

	SIG_ATOMIC_MIN = {$IFDEF CPU64}INT64_MIN{$ELSE}INT32_MIN{$ENDIF};
	SIG_ATOMIC_MAX = {$IFDEF CPU64}INT64_MAX{$ELSE}INT32_MAX{$ENDIF};

	SIZE_MAX = {$IFDEF CPU64}UINT64_MAX{$ELSE}UINT32_MAX{$ENDIF};

const
	WCHAR_MIN = 0;
	WCHAR_MAX = UINT16_MAX;
	WINT_MIN  = 0;
	WINT_MAX  = UINT16_MAX;

(*
  /* 7.18.4.1 Macros for minimum-width integer constants */

   #define INT8_C(val)  val##i8
   #define INT16_C(val) val##i16
   #define INT32_C(val) val##i32
   #define INT64_C(val) val##i64
   #define UINT8_C(val)  val##ui8
   #define UINT16_C(val) val##ui16
   #define UINT32_C(val) val##ui32
   #define UINT64_C(val) val##ui64

   /* 7.18.4.2 Macros for greatest-width integer constants */
   #define INTMAX_C   INT64_C
   #define UINTMAX_C  UINT64_C
*)
