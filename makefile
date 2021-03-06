# Lua interpreter to use to build vm.
LUA := luajit

# LuaJIT flags
CFLAGS := -DLUAJIT_TARGET=LUAJIT_ARCH_ARM -DLUAJIT_OS=LUAJIT_OS_OTHER -m32

# Directories
LJ_DIR := ./LuaJIT
LJ_SRC=$(LJ_DIR)/src

DASM_DIR := $(LJ_DIR)/dynasm
DASM := $(LUA) $(DASM_DIR)/dynasm.lua

DASC := $(LJ_SRC)/vm_arm.dasc

DKP_DIR := ./dkp
DKP_SRC := $(DKP_DIR)/source
DKP_INC := $(DKP_DIR)/include

BUILDVM := ./buildvm

# LuaJIT libs to build VM
ALL_LIB := $(LJ_SRC)/lib_base.c $(LJ_SRC)/lib_math.c $(LJ_SRC)/lib_bit.c \
	$(LJ_SRC)/lib_string.c $(LJ_SRC)/lib_table.c $(LJ_SRC)/lib_io.c $(LJ_SRC)/lib_os.c \
	$(LJ_SRC)/lib_package.c $(LJ_SRC)/lib_debug.c $(LJ_SRC)/lib_jit.c $(LJ_SRC)/lib_ffi.c

all: src

bin: src
	make -C $(DKP_DIR)
	mkdir -p $@
	cp -r $(DKP_DIR)/include $(DKP_DIR)/lib $@/

clean:
	rm $(DKP_SRC)/* || true
	rm $(DKP_INC)/* || true

src: lj_vm lj_inc
	cp $(LJ_SRC)/lib_*.c $(DKP_SRC)/
	cp $(LJ_SRC)/lj_* $(DKP_SRC)/

lj_inc: $(LJ_SRC)/luajit.h $(LJ_SRC)/lua.h $(LJ_SRC)/lua.hpp $(LJ_SRC)/lauxlib.h $(LJ_SRC)/lualib.h $(LJ_SRC)/luaconf.h
	mkdir -p $(DKP_INC)
	cp $^ $(DKP_DIR)/include/

lj_vm: buildvm
	mkdir -p $(DKP_SRC)
	$(BUILDVM) -m elfasm -o $(DKP_SRC)/lj_vm.s
	$(BUILDVM) -m bcdef -o $(DKP_SRC)/lj_bcdef.h $(ALL_LIB)
	$(BUILDVM) -m ffdef -o $(DKP_SRC)/lj_ffdef.h $(ALL_LIB)
	$(BUILDVM) -m libdef -o $(DKP_SRC)/lj_libdef.h $(ALL_LIB)
	$(BUILDVM) -m recdef -o $(DKP_SRC)/lj_recdef.h $(ALL_LIB)
	# $(BUILDVM) -m vmdef -o $(DKP_SRC)/jit/vmdef.lua $(ALL_LIB)
	$(BUILDVM) -m folddef -o $(DKP_SRC)/lj_folddef.h $(LJ_SRC)/lj_opt_fold.c	 

buildvm: $(LJ_SRC)/host/buildvm_arch.h
	$(CC) -I$(LJ_SRC) -I$(DASM_DIR) $(CFLAGS) $(LJ_SRC)/host/buildvm*.c -o buildvm

$(LJ_SRC)/host/buildvm_arch.h:
	$(DASM) -LN -o $@ $(DASC)

.PHONY: all bin clean src lj_vm lj_inc buildvm
