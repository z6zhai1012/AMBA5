#LAB_DIR = /home/cyl/target/personal/sync_fifo
#LAB_DIR = /home/cyl/target/personal/async_fifo
#LAB_DIR = /home/cyl/target/personal/uart
#LAB_DIR = /home/cyl/target/personal/uartnew
#LAB_DIR = /home/cyl/target/personal/spi
LAB_DIR = /home/cyl/target/personal/apb
#LAB_DIR = /home/cyl/target/personal/ahb2apb
#LAB_DIR = /home/cyl/target/personal/csdn
#LAB_DIR = /home/cyl/target/personal/check
#LAB_DIR = /home/cyl/target/personal/compare
#LAB_DIR = /home/cyl/target/personal/vote
#LAB_DIR = /home/cyl/target/personal/div
#LAB_DIR = /home/cyl/target/personal/shift
#LAB_DIR = /home/cyl/target/personal/sclsda
#LAB_DIR = /home/cyl/target/personal/test
#LAB_DIR = /home/cyl/target/personal/traffic_lights
#LAB_DIR = /home/cyl/target/personal/subway

DFILES = $(LAB_DIR)/*.v 

all:clean elab rung
elab:
	vcs -full64 -LDFLAGS -Wl,-no-as-needed -debug_acc+all -timescale=1ns/1ns \
	-fsdb -sverilog -l comp.log \
	${DFILES}

run:
	./simv -l run.log

rung:
	./simv -gui -l run.log

verdi:
	verdi ${DFILES} \
	-ssf ./*.fsdb &

clean:
	rm -rf  AN.DB \
	rm -rf  DVEfiles \
	rm -rf  csrc \
	rm -rf  simv.* \
	rm -rf  *simv \
	rm -rf  inter.vpd \
	rm -rf  ucli.key \
	rm -rf  *.log \
	rm -rf  verdiLog \
	rm -rf  novas* \
	rm -rf  *.fsdb






