/*
 * Copyright (c) 2016 - 2026 Ember
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include "WorldSessions.h"

namespace ember::realm {

void WorldSessions::insert(unsigned int map_id, WorldConnection* connection) {
	connections_.insert_or_assign(map_id, connection);
}

void WorldSessions::erase(unsigned int map_id) {
	connections_.erase(map_id);
}

void WorldSessions::erase(const WorldConnection* connection) {
	for(auto it = connections_.begin(); it != connections_.end();) {
		if(it->second == connection) {
			it = connections_.erase(it);
		} else {
			++it;
		}
	}
}

WorldConnection* WorldSessions::find(unsigned int map_id) const {
	if(auto it = connections_.find(map_id); it != connections_.end()) {
		return it->second;
	}

	return nullptr;
}


} // realm, ember
