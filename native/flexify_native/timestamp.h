//
// Created by joseph on 22/06/24.
//

#ifndef FossFitNATIVE_TIMESTAMP_H
#define FossFitNATIVE_TIMESTAMP_H

#include <chrono>
#include <optional>

#include "timer.h"

namespace FossFit {
    inline std::optional<std::chrono::time_point<fclock_t>> convertLongToTimePoint(int64_t timestamp) {
        if (timestamp == 0) return std::nullopt;
        return std::chrono::time_point<fclock_t>(std::chrono::milliseconds(timestamp));
    }
}

#endif //FossFitNATIVE_TIMESTAMP_H
