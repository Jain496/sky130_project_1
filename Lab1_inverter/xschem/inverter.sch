v {xschem version=3.4.4 file_version=1.2
}
G {}
K {}
V {}
S {}
E {}
N -230 -160 -230 -150 {
lab=vss}
N -230 -150 -230 -140 {
lab=vss}
N -230 -140 -230 -130 {
lab=vss}
N -230 -130 -230 -120 {
lab=vss}
N -230 -260 -230 -220 {
lab=out}
N -230 -250 -150 -250 {
lab=out}
N -230 -380 -230 -320 {
lab=vdd}
N -320 -290 -320 -250 {
lab=in}
N -320 -290 -270 -290 {
lab=in}
N -320 -250 -320 -190 {
lab=in}
N -320 -190 -270 -190 {
lab=in}
N -230 -120 -200 -120 {
lab=vss}
N -230 -190 -210 -190 {
lab=vss}
N -210 -190 -210 -120 {
lab=vss}
C {sky130_fd_pr/nfet_01v8.sym} -250 -190 0 0 {name=M1
W=4.5
L=0.18
nf=3 
mult=1
ad="'int((nf + 1)/2) * W / nf * 0.29'"
pd="'2*int((nf + 1)/2) * (W / nf + 0.29)'"
as="'int((nf + 2)/2) * W / nf * 0.29'"
ps="'2*int((nf + 2)/2) * (W / nf + 0.29)'"
nrd="'0.29 / W '" nrs="'0.29 / W '"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {sky130_fd_pr/pfet3_01v8.sym} -250 -290 0 0 {name=M2
W=3
L=0.18
body=vdd
nf=3
mult=1
ad="'int((nf + 1)/2) * W / nf * 0.29'"
pd="'2*int((nf + 1)/2) * (W / nf + 0.29)'"
as="'int((nf + 2)/2) * W / nf * 0.29'"
ps="'2*int((nf + 2)/2) * (W / nf + 0.29)'"
nrd="'0.29 / W '" nrs="'0.29 / W '"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {ipin.sym} -320 -250 0 0 {name=p1 lab=in}
C {opin.sym} -150 -250 0 0 {name=p2 lab=out}
C {iopin.sym} -230 -380 0 0 {name=p3 lab=vdd}
C {iopin.sym} -200 -120 0 0 {name=p4 lab=vss}
