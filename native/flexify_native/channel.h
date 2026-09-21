//
// Created by joseph on 22/06/24.
//

#ifndef NATIVE_HANDLER_H
#define NATIVE_HANDLER_H

#include "timestamp.h"
#include "timer_service.h"

#include <chrono>
#include <iostream>
#include <optional>

namespace FossFit {

    enum MethodCall {
        Timer,
        Add,
        Stop
    };

    struct TimerArgs {
        std::string title;
        std::optional<std::chrono::time_point<fclock_t>> timestamp;
        std::chrono::milliseconds restMs;
    };

    template <Platform P, MethodCall M, typename Channel, typename Result>
    inline void handleMethodCall(Channel channel, Result methodCall) {
        switch (M) {
            case Timer:
            {
                const auto args = platform_specific::getTimerArgs<P>(channel, methodCall);
                FossFit::platform_specific::getTimerService<P>().start(args.title, args.timestamp, args.restMs);
                FossFit::platform_specific::sendResult<P, Result, true>(methodCall);
                break;
            }
            case Add: {
                auto& timerService = FossFit::platform_specific::getTimerService<P>();
                if (!timerService.isRunning()) {
                    const auto timestamp = FossFit::platform_specific::getAddArgs<P>(channel, methodCall);
                    timerService.start("Rest timer", timestamp, FossFit::ONE_MINUTE_MILLI);
                } else {
                    timerService.add(std::nullopt);
                }
                FossFit::platform_specific::sendResult<P, Result, true>(methodCall);
                break;
            }
            case Stop:
                FossFit::platform_specific::getTimerService<P>().stop();
                FossFit::platform_specific::sendResult<P, Result, true>(methodCall);
                break;
            default:
                FossFit::platform_specific::sendResult<P, Result, false>(methodCall);
                break;
        }
    }
}

#endif //NATIVE_HANDLER_H
