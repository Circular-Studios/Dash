module deimos.cef1.base;

// Copyright (c) 2011 Marshall A. Greenblatt. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the name Chromium Embedded
// Framework nor the names of its contributors may be used to endorse
// or promote products derived from this software without specific prior
// written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


// #ifndef CEF_INCLUDE_CAPI_CEF_BASE_CAPI_H_

// #ifdef __cplusplus
extern(C) {
// #endif

import deimos.cef1.internal.export;
import deimos.cef1.internal.string;
import deimos.cef1.internal.string_list;
import deimos.cef1.internal.string_m;
import deimos.cef1.internal.string_multim;
import deimos.cef1.internal.types;

///
// Structure defining the reference count implementation functions. All
// framework structures must include the cef_base_t structure first.
///
struct cef_base_t {
  ///
  // Size of the data structure.
  ///
  size_t size;

  ///
  // Increment the reference count.
  ///
  extern(System) int function(cef_base_t* self) add_ref;

  ///
  // Decrement the reference count.  Delete this object when no references
  // remain.
  ///
  extern(System) int function(cef_base_t* self) release;

  ///
  // Returns the current number of references.
  ///
  extern(System) int function(cef_base_t* self) get_refct;
}


// Check that the structure |s|, which is defined with a cef_base_t member named
// |base|, is large enough to contain the specified member |f|.
//   ((intptr_t)&((s)->f) - (intptr_t)(s) + sizeof((s)->f) <= (s)->base.size)



// #ifdef __cplusplus
}
// #endif

// #endif CEF_INCLUDE_CAPI_CEF_BASE_CAPI_H_
