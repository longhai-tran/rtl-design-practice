TOP  = encoder_8to3_tb
SRCS = ../../encoder_8to3.v ../../encoder_8to3_tb.v
SNAP = $(TOP)_snap

.PHONY: all sim gui do clean
all: sim

sim:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP)
	xsim $(SNAP) -runall -log sim.log

gui:
	xvlog $(SRCS)
	xelab $(TOP) -s $(SNAP) -debug typical
	xsim $(SNAP) -gui -tclbatch wave.tcl

do:
	xtclsh simulate.tcl

clean:
	rm -rf xsim.dir/ *.pb *.log *.jou *.wdb webtalk/ .Xil/ dfx_runtime.txt
