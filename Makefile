# Reproducible out-of-tree build for Free Pascal 3.2.2.
FPC ?= fpc
FPCFLAGS ?= -O3 -Miso
PYTHON ?= python3
BUILD_DIR ?= build

.PHONY: all test test-full clean

all: $(BUILD_DIR)/compile $(BUILD_DIR)/interpret

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/compile: compile.p common.p scan.p parse.p assemble.p | $(BUILD_DIR)
	$(FPC) $(FPCFLAGS) -FE$(BUILD_DIR) -FU$(BUILD_DIR) compile.p

$(BUILD_DIR)/interpret: interpret.p common.p | $(BUILD_DIR)
	$(FPC) $(FPCFLAGS) -FE$(BUILD_DIR) -FU$(BUILD_DIR) interpret.p

test: all
	$(PYTHON) tests/run_tests.py

test-full: all
	$(PYTHON) tests/run_tests.py --full

clean:
	rm -rf $(BUILD_DIR) errors
