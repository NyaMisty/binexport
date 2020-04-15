// Copyright 2011-2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "third_party/zynamics/binexport/ida/log_sink.h"

// clang-format off
#include "third_party/zynamics/binexport/ida/begin_idasdk.inc"  // NOLINT
#include <kernwin.hpp>                                          // NOLINT
#include "third_party/zynamics/binexport/ida/end_idasdk.inc"    // NOLINT
// clang-format on

#include "base/logging.h"
#include "third_party/absl/strings/string_view.h"
#include "third_party/zynamics/binexport/util/logging.h"

namespace security::binexport {

void IdaLogSink::Send(const not_absl::LogEntry& entry) {
  struct LoggingExecutor : public exec_request_t {
    explicit LoggingExecutor(absl::string_view text_message)
        : text_message(text_message) {}

    int idaapi execute() override {
      msg("%s\n", text_message.c_str());
      return 0;
    }

    std::string text_message;
  } executor(entry.text_message());

  // Do all logging in IDA's main thread.
  execute_sync(executor, MFF_FAST);
}

}  // namespace security::binexport
