/*
 * Copyright (c) 2024 - 2025 Ember
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include "MapRunner.h"
#include "Watchdog.h"
#include <logger/Logger.h>
#include <shared/utility/Timing.h>
#include <chrono>
#include <source_location>
#include <thread>
#include <utility>

using namespace std::chrono_literals;

namespace ember::map {

const auto UPDATE_FREQUENCY = 60.0;
const auto TARGET_UPDATE_TIME { 1000ms / UPDATE_FREQUENCY };
const auto TIME_PERIOD = 1ms;
const auto WATCHDOG_PERIOD = 120s;

MapRunner::MapRunner(std::vector<std::int32_t> map_ids, log::Logger& logger)
	: map_ids_(std::move(map_ids))
	, logger_(logger)
	, ticks_(0)
	, elapsed_(0ms) {
}

void MapRunner::update(std::chrono::milliseconds delta) {
	elapsed_ += delta;
	++ticks_;
}

/* 
 * We can't always guarantee the update rate on a server and may
 * wish to slow it down as required, so the main update loop uses
 * a variable rather than fixed time step. If a subsystem wishes
 * to use a fixed time step, it can still do so by running its own
 * timing loop within the update.
 * 
 * A monotonic clock is being used as we don't want any changes in
 * system time (e.g. DST) to impact the game logic.
 */
void MapRunner::run(bool& stop_flag) {
	LOG_TRACE(logger_, log_func);
	LOG_INFO(logger_, "Starting map runner for {} map(s)", map_ids_.size());

	const utility::ScopedTimerPeriod timer_guard(TIME_PERIOD);

	/*
	 * If we can't increase timer resolution, the worst that happens
	 * is that timers/sleep may overshoot and cause a drop in update
	 * rate, but it shouldn't affect the game logic since it'll be
	 * accounted for in the delta.
	 */
	if(!timer_guard.success()) {
		const auto src = std::source_location::current();
		LOG_ERROR(logger_, "{}:{} - failed to set time period", src.file_name(), src.line());
	}

	Watchdog watchdog(WATCHDOG_PERIOD, logger_);

	auto previous = std::chrono::steady_clock::now() - TARGET_UPDATE_TIME;

	while(!stop_flag) {
		const auto begin = std::chrono::steady_clock::now();
		const auto delta = begin - previous;
		const auto delta_ms = std::chrono::duration_cast<std::chrono::milliseconds>(delta);

		update(delta_ms);
		watchdog.notify();

		const auto end = std::chrono::steady_clock::now();
		const auto update_time = end - begin;

		/*
		 * If we've finished updating but still have time to spare, we'll
		 * sleep to use the rest of it up. We should have decent enough
		 * timer resolution for this to be accurate enough and if not,
		 * too bad, because platform-specific APIs run at the same resolution
		 * 
		 * Chrome, Firefox and so on pretty much do things the same way.
		 */
		if(update_time < TARGET_UPDATE_TIME) {
			std::this_thread::sleep_for(TARGET_UPDATE_TIME - update_time);
		}

		previous = begin;
	}

	LOG_INFO(logger_, "Stopped map runner after {} tick(s)", ticks_);
}

std::uint64_t MapRunner::ticks() const {
	return ticks_;
}

const std::vector<std::int32_t>& MapRunner::map_ids() const {
	return map_ids_;
}

} // map, ember
