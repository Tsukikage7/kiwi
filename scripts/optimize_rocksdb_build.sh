#!/usr/bin/env bash
# Copyright (c) 2024-present, arana-db Community.  All rights reserved.
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to skip librocksdb-sys compilation if possible
# This helps reduce build time by reusing already compiled rocksdb libraries

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kiwi RocksDB Build Optimization ===${NC}"

# Check if SKIP_LIBROCKSDB_SYS_BUILD is set
if [ "${SKIP_LIBROCKSDB_SYS_BUILD:-false}" = "true" ]; then
	echo -e "${YELLOW}SKIP_LIBROCKSDB_SYS_BUILD is set to true${NC}"

	# Check if rocksdb is already installed on the system
	if command -v pkg-config &>/dev/null && pkg-config --exists rocksdb; then
		echo -e "${GREEN}Found system rocksdb installation via pkg-config${NC}"

		# Get rocksdb version and paths
		ROCKSDB_VERSION=$(pkg-config --modversion rocksdb 2>/dev/null || echo "unknown")
		ROCKSDB_INCLUDE=$(pkg-config --cflags-only-I rocksdb 2>/dev/null | sed 's/-I//g' || echo "")
		ROCKSDB_LIB=$(pkg-config --libs-only-L rocksdb 2>/dev/null | sed 's/-L//g' || echo "")

		echo -e "${GREEN}System rocksdb version: ${ROCKSDB_VERSION}${NC}"
		echo -e "${GREEN}Include path: ${ROCKSDB_INCLUDE}${NC}"
		echo -e "${GREEN}Library path: ${ROCKSDB_LIB}${NC}"

		# Set environment variables to use system rocksdb
		export ROCKSDB_INCLUDE_DIR="${ROCKSDB_INCLUDE}"
		export ROCKSDB_LIB_DIR="${ROCKSDB_LIB}"

		echo -e "${GREEN}Using system rocksdb installation${NC}"
		echo -e "${GREEN}Build time should be significantly reduced!${NC}"

	elif [ -d "/usr/local/include/rocksdb" ] || [ -d "/opt/homebrew/include/rocksdb" ]; then
		echo -e "${GREEN}Found rocksdb headers in common locations${NC}"

		# Try to detect common installation paths
		for prefix in "/usr/local" "/opt/homebrew" "/usr"; do
			if [ -d "${prefix}/include/rocksdb" ] && [ -f "${prefix}/lib/librocksdb.a" ]; then
				export ROCKSDB_INCLUDE_DIR="${prefix}/include"
				export ROCKSDB_LIB_DIR="${prefix}/lib"
				echo -e "${GREEN}Using rocksdb from: ${prefix}${NC}"
				break
			fi
		done

		if [ -n "${ROCKSDB_INCLUDE_DIR}" ]; then
			echo -e "${GREEN}Using system rocksdb installation${NC}"
			echo -e "${GREEN}Build time should be significantly reduced!${NC}"
		else
			echo -e "${YELLOW}Could not find complete rocksdb installation${NC}"
			echo -e "${YELLOW}Falling back to building from source${NC}"
		fi

	else
		echo -e "${YELLOW}SKIP_LIBROCKSDB_SYS_BUILD is set but no system rocksdb found${NC}"
		echo -e "${YELLOW}Consider installing rocksdb system-wide:${NC}"
		echo -e "${YELLOW}  macOS: brew install rocksdb${NC}"
		echo -e "${YELLOW}  Ubuntu: apt-get install librocksdb-dev${NC}"
		echo -e "${YELLOW}  CentOS: yum install rocksdb-devel${NC}"
		echo -e "${YELLOW}Or build from source and set ROCKSDB_INCLUDE_DIR/ROCKSDB_LIB_DIR${NC}"
		echo -e "${YELLOW}Falling back to building from source${NC}"
	fi
else
	echo -e "${GREEN}SKIP_LIBROCKSDB_SYS_BUILD not set, building rocksdb from source${NC}"
	echo -e "${YELLOW}To speed up builds, you can:${NC}"
	echo -e "${YELLOW}1. Install rocksdb system-wide and set SKIP_LIBROCKSDB_SYS_BUILD=true${NC}"
	echo -e "${YELLOW}2. Or use sccache (already configured) for faster recompilation${NC}"
fi

echo -e "${GREEN}=== Build Optimization Complete ===${NC}"
echo ""
