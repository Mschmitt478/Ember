/*
 * Copyright (c) 2024 - 2025 Ember
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#pragma once

#include <logger/LoggerFwd.h>
#include <chrono>
#include <cstdint>
#include <vector>

namespace ember::map {

class MapRunner final {
	std::vector<std::int32_t> map_ids_;
	log::Logger& logger_;
	std::uint64_t ticks_;
	std::chrono::milliseconds elapsed_;

	void update(std::chrono::milliseconds delta);

public:
	MapRunner(std::vector<std::int32_t> map_ids, log::Logger& logger);

	void run(bool& stop_flag);

	std::uint64_t ticks() const;
	const std::vector<std::int32_t>& map_ids() const;
};

} // map, ember
