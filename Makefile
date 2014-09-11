PROJECT = stm32f3_blinky
TARGET = $(PROJECT).elf
CC = arm-none-eabi-gcc
GDB = arm-none-eabi-gdb
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE = arm-none-eabi-size

CFLAGS += -mlittle-endian -mcpu=cortex-m4 -march=armv7e-m -mthumb
CFLAGS += -Wall -std=gnu99 -Os -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CFLAGS += -MD -MP -MT $(*F).o -MF $(@F).d 
CFLAGS += -I./

STD_PERIPH_LIB = ext_lib
CFLAGS += -I $(STD_PERIPH_LIB)
CFLAGS += -I $(STD_PERIPH_LIB)/CMSIS/Device/ST/STM32F30x/Include
CFLAGS += -I $(STD_PERIPH_LIB)/CMSIS/Include
CFLAGS += -I $(STD_PERIPH_LIB)/STM32F30x_StdPeriph_Driver/inc
CFLAGS += -I $(STD_PERIPH_LIB)/Utilities
CFLAGS += -D USE_STDPERIPH_DRIVER

ASFLAGS = $(COMMON)
ASFLAGS += $(CFLAGS)
ASFLAGS += -x assembler-with-cpp

LDFLAGS = $(COMMON) 
#-lgcc -lc -lm
LDFLAGS += -Wl,-Map=$(PROJECT).map
LDFLAGS += -nostdlib -T./stm32_flash.ld

SOURCES := $(wildcard ext_lib/STM32F30x_StdPeriph_Driver/src/*.c)
SOURCES += $(wildcard ./*.c)

ASSOURCES = $(STD_PERIPH_LIB)/CMSIS/Device/ST/STM32F30x/Source/Templates/gcc_ride7/startup_stm32f30x.s

OBJECTS = $(patsubst %.c, %.o, $(SOURCES))
ASOBJECTS = $(patsubst %.s, %.o, $(ASSOURCES))

DEPS=$(patsubst %.o, %.o.d, $(notdir $(OBJECTS)))
DEPS+=$(patsubst %.o, %.o.d, $(notdir $(ASOBJECTS)))


all: $(TARGET) $(PROJECT).bin $(PROJECT).lss size

$(PROJECT).bin: $(TARGET)
	$(OBJCOPY) -O binary  $< $@

$(PROJECT).lss: $(TARGET)
	$(OBJDUMP) -h -S $< > $@

$(TARGET): $(OBJECTS) $(ASOBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) $(ASOBJECTS) -o $@

$(OBJECTS): %.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(ASOBJECTS): %.o: %.s
	$(CC) $(ASFLAGS) -c $< -o $@

size: ${TARGET}
	@echo
	@$(SIZE) ${TARGET}

## Clean target
.PHONY: clean program

program:
	sudo st-flash --reset write $(PROJECT).bin 0x8000000

clean:
	rm $(OBJECTS) $(ASOBJECTS) $(PROJECT).bin $(PROJECT).elf $(PROJECT).map $(PROJECT).lss $(DEPS)
