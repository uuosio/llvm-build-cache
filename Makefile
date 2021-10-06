
# aliases
all: tinygo

# Default build and source directories, as created by `make llvm-build`.
LLVM_BUILDDIR ?= llvm-build
LLVM_PROJECTDIR ?= llvm-project
CLANG_SRC ?= $(LLVM_PROJECTDIR)/clang
LLD_SRC ?= $(LLVM_PROJECTDIR)/lld

# Try to autodetect LLVM build tools.
detect = $(shell command -v $(1) 2> /dev/null && echo $(1))
CLANG ?= $(word 1,$(abspath $(call detect,llvm-build/bin/clang))$(call detect,clang-11)$(call detect,clang-10)$(call detect,clang))
LLVM_AR ?= $(word 1,$(abspath $(call detect,llvm-build/bin/llvm-ar))$(call detect,llvm-ar-11)$(call detect,llvm-ar-10)$(call detect,llvm-ar))
LLVM_NM ?= $(word 1,$(abspath $(call detect,llvm-build/bin/llvm-nm))$(call detect,llvm-nm-11)$(call detect,llvm-nm-10)$(call detect,llvm-nm))

# Go binary and GOROOT to select
GO ?= go
export GOROOT = $(shell $(GO) env GOROOT)

# md5sum binary
MD5SUM = md5sum

# tinygo binary for tests
TINYGO ?= $(word 1,$(call detect,tinygo)$(call detect,build/tinygo))

# Use CCACHE for LLVM if possible
ifneq (, $(shell command -v ccache 2> /dev/null))
    LLVM_OPTION += '-DLLVM_CCACHE_BUILD=ON'
endif

# Allow enabling LLVM assertions
ifeq (1, $(ASSERT))
    LLVM_OPTION += '-DLLVM_ENABLE_ASSERTIONS=ON'
else
    LLVM_OPTION += '-DLLVM_ENABLE_ASSERTIONS=OFF'
endif

.PHONY: all $(LLVM_BUILDDIR) llvm-source


# Other libraries that are needed to link TinyGo.
EXTRA_LIB_NAMES = LLVMInterpreter

# These build targets appear to be the only ones necessary to build all TinyGo
# dependencies. Only building a subset significantly speeds up rebuilding LLVM.
# The Makefile rules convert a name like lldELF to lib/liblldELF.a to match the
# library path (for ninja).
# This list also includes a few tools that are necessary as part of the full
# TinyGo build.
NINJA_BUILD_TARGETS = clang llvm-config llvm-ar llvm-nm $(addprefix lib/lib,$(addsuffix .a,$(LIBCLANG_NAME) $(CLANG_LIB_NAMES) $(LLD_LIB_NAMES) $(EXTRA_LIB_NAMES)))

# Get LLVM sources.
$(LLVM_PROJECTDIR)/llvm:
	git clone -b xtensa_release_11.0.0 --depth=1 https://github.com/tinygo-org/llvm-project $(LLVM_PROJECTDIR)
llvm-source: $(LLVM_PROJECTDIR)/llvm

# Configure LLVM.
TINYGO_SOURCE_DIR=$(shell pwd)
$(LLVM_BUILDDIR)/build.ninja: llvm-source
	mkdir -p $(LLVM_BUILDDIR); cd $(LLVM_BUILDDIR); cmake -G Ninja $(TINYGO_SOURCE_DIR)/$(LLVM_PROJECTDIR)/llvm "-DLLVM_TARGETS_TO_BUILD=X86;ARM;AArch64;RISCV;WebAssembly" "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=AVR;Xtensa" -DCMAKE_BUILD_TYPE=Release -DLIBCLANG_BUILD_STATIC=ON -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_LIBEDIT=OFF -DLLVM_ENABLE_Z3_SOLVER=OFF -DLLVM_ENABLE_OCAMLDOC=OFF -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_TOOL_CLANG_TOOLS_EXTRA_BUILD=OFF -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF $(LLVM_OPTION)

# Build LLVM.
$(LLVM_BUILDDIR): $(LLVM_BUILDDIR)/build.ninja
	cd $(LLVM_BUILDDIR); ninja $(NINJA_BUILD_TARGETS)
