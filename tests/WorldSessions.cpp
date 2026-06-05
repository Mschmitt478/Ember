/*
 * Copyright (c) 2026 Ember
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

#include <realm/WorldSessions.h>
#include <gtest/gtest.h>

using namespace ember::realm;

TEST(WorldSessions, FindsInsertedMapConnection) {
	WorldSessions sessions;
	auto* connection = reinterpret_cast<WorldConnection*>(0x1);

	sessions.insert(0, connection);

	EXPECT_EQ(sessions.find(0), connection);

	sessions.erase(0);
}

TEST(WorldSessions, ReplacesExistingMapConnection) {
	WorldSessions sessions;
	auto* first = reinterpret_cast<WorldConnection*>(0x1);
	auto* second = reinterpret_cast<WorldConnection*>(0x2);

	sessions.insert(0, first);
	sessions.insert(0, second);

	EXPECT_EQ(sessions.find(0), second);

	sessions.erase(0);
}

TEST(WorldSessions, ErasesAllMapsForConnection) {
	WorldSessions sessions;
	auto* first = reinterpret_cast<WorldConnection*>(0x1);
	auto* second = reinterpret_cast<WorldConnection*>(0x2);

	sessions.insert(0, first);
	sessions.insert(1, first);
	sessions.insert(2, second);

	sessions.erase(first);

	EXPECT_EQ(sessions.find(0), nullptr);
	EXPECT_EQ(sessions.find(1), nullptr);
	EXPECT_EQ(sessions.find(2), second);

	sessions.erase(2);
}
