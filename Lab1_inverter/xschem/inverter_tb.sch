v {xschem version=3.4.4 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N -630 -610 -580 -610 {
lab=in}
N -730 -660 -730 -610 {
lab=#net1}
N -730 -660 -280 -660 {
lab=#net1}
N -280 -660 -280 -610 {
lab=#net1}
N -280 -570 -280 -540 {
lab=GND}
N -730 -540 -280 -540 {
lab=GND}
N -730 -550 -730 -540 {
lab=GND}
N -630 -550 -630 -540 {
lab=GND}
N -630 -640 -630 -610 {
lab=in}
N -280 -590 -170 -590 {
lab=out}
C {inverter.sym} -430 -590 0 0 {name=x1}
C {vsource.sym} -630 -580 0 0 {name=V1 value="PWL(0 0 20n 0 900n 1.8)" savecurrent=false}
C {vsource.sym} -730 -580 0 0 {name=V2 value=1.8 savecurrent=false}
C {gnd.sym} -510 -540 0 0 {name=l1 lab=GND}
C {opin.sym} -170 -590 0 0 {name=p1 lab=out}
C {opin.sym} -630 -640 0 0 {name=p2 lab=in}
C {code_shown.sym} -400 -430 0 0 {name=s2 only_toplevel=false value=".control
tran 1n 1u
plot V(in) V(out)
.endc"}
C {code_shown.sym} -400 -720 0 0 {name=s1 only_toplevel=false value=".lib /usr/local/share/pdk/sky130A/libs.tech/ngspice/sky130.lib.spice tt"}
