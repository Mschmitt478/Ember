/*
 * Copyright (c) 2026 Ember
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include "WorldRPCServer.h"
#include <logger/Logger.h>

namespace ember::world {

using namespace rpc::World;
using namespace spark;

WorldRPCServer::WorldRPCServer(spark::Server& spark, log::Logger& logger)
	: WorldService(spark)
	, logger_(logger) {
}

void WorldRPCServer::on_link_up(const spark::Link& link) {
	LOG_DEBUG(logger_, "Link up: {}", link.peer_banner);
}

void WorldRPCServer::on_link_down(const spark::Link& link) {
	LOG_DEBUG(logger_, "Link down: {}", link.peer_banner);
}

std::optional<StatusT>
WorldRPCServer::handle_get_status(const RequestStatus& msg, const Link& link, const Token& token) {
	(void) msg;
	(void) token;

	LOG_TRACE(logger_, "Status requested by {}", link.peer_banner);

	StatusT status;
	status.population = 0;
	return status;
}

std::optional<PlayerEnterResultT>
WorldRPCServer::handle_player_enter(const PlayerEnter& msg, const Link& link, const Token& token) {
	(void) token;

	LOG_DEBUG(logger_, "Player enter requested by {} for character {}", link.peer_banner, msg.character_id());

	PlayerEnterResultT result;
	result.result = ErrorCode::success;
	return result;
}

std::optional<PlayerLeaveResultT>
WorldRPCServer::handle_player_leave(const PlayerLeave& msg, const Link& link, const Token& token) {
	(void) token;

	LOG_DEBUG(logger_, "Player leave requested by {} for character {}", link.peer_banner, msg.character_id());

	PlayerLeaveResultT result;
	result.result = ErrorCode::success;
	return result;
}

} // world, ember
