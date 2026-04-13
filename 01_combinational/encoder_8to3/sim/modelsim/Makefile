TOP  = encoder_8to3_tb
SRCS = ../../encoder_8to3.v ../../encoder_8to3_tb.v

.PHONY: all sim gui do clean
all: sim

sim:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -c work.$(TOP) -do "run -all; quit -f"

gui:
	vlib work
	vmap work work
	vlog $(SRCS)
	vsim -voptargs=+acc work.$(TOP) -do wave.do -do "run -all"

do:
	vsim -c -do simulate.do

clean:
	rm -rf work/ transcript *.wlf wlf* *.log modelsim.ini
