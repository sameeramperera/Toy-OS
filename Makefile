ASM = nasm
ASMFLAGS = -f bin

all: boot.bin

boot.bin: boot/boot.asm
	$(ASM) $(ASMFLAGS) boot/boot.asm -o boot.bin

clean:
	rm -f boot.bin