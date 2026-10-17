# VLSI_Internship_SKY130

This repository documents my hands-on work with the open-source **SkyWater SKY130** design flow (xschem, ngspice, magic, netgen) on Ubuntu inside WSL2. It follows the course on the VSDIAT platform. The final goal is the slides' **"Backend validation DIY"** lab: take one small circuit (a CMOS inverter) through the full flow, from schematic to LVS.

All commands, results and screenshots here are from my own work. 
**Last updated:** 14 October 2026

**Status key:** ✅ done and verified | ⏳ in progress | ⬜ not started

## Index

- [Current status](#current-status)
- [Chapter 0 - Setting up the environment](#chapter-0---setting-up-the-environment)
- [Chapter 1 - Getting the tools](#chapter-1---getting-the-tools)
- [Chapter 2 - Installing the SKY130 PDK](#chapter-2---installing-the-sky130-pdk)
- [Chapter 3 - Understanding the design flow](#chapter-3---understanding-the-design-flow)
- [Problems and fixes](#problems-and-fixes)
- [Lessons learned](#lessons-learned)

## Current status

| Stage | Status |
|---|---|
| WSL2 + Ubuntu 26.04 running | ✅ |
| GUI works (`DISPLAY=:0`, `xeyes`) | ✅ |
| System updated (69 packages) | ✅ |
| WSL memory raised (4.8 GiB RAM, 6 GiB swap) | ✅ |
| magic, ngspice, xschem, netgen-lvs, klayout installed | ✅ |
| Newer magic (8.3.685) built from source | ✅ |
| SKY130 PDK installed with open_pdks | ✅ |
| magic loads `sky130A` without errors | ✅ |
| `PDK_ROOT` / `PDK` environment variables set | ✅ |
| Lab 1 folders and config files prepared | ✅ |
| xschem, ngspice, netgen opened with the PDK | ⬜ |
| Inverter: schematic, simulation, layout, DRC, LVS | ⬜ |
| All screenshots added | ⏳ |

## Background

| Term | Meaning |
|---|---|
| **PDK** | Process Design Kit: the foundry's rulebook and parts library (device models, layers, manufacturing rules). SKY130 is the free PDK for SkyWater's 130 nm process. |
| **open_pdks** | Scripts that convert the raw PDK into formats each tool understands. Install the tools first, `open_pdks` last. |
| **xschem** | Schematic capture |
| **ngspice** | Circuit simulator |
| **magic** | Layout editor, DRC, netlist extraction |
| **netgen** | Netlist comparison, used for LVS |
| **DRC** | Design Rule Check: does the layout obey the foundry's manufacturing rules? |
| **LVS** | Layout vs Schematic: is the layout electrically the same circuit as the schematic? |
| **Netlist** | Text file listing components and their connections |

**Manual design flow from the slides:**

1. Draw the circuit in **xschem**, simulate with **ngspice**
2. Draw the layout in **magic**, run **DRC**
3. Extract the layout and compare with the schematic using **netgen** (**LVS**)

**Slide topics:** SKY130 libraries (`sky130_fd_sc_hd` standard cells, `sky130_fd_pr` primitive devices, `sky130_fd_io` I/O cells, SRAM macros); layers and devices (metal1 to metal5, MiM caps, RDL, bipolar devices, resistors); tools supported by `open_pdks`.

## Chapter 0 - Setting up the environment

### My system

| Item | Value |
|---|---|
| Laptop | 12th Gen Intel Core i3-1215U, 8 GB RAM (7.65 GB usable) |
| Host OS | Windows 11 Home Single Language, 25H2 |
| Linux | WSL2, Ubuntu 26.04.1 LTS (*resolute*), kernel `6.18.33.2-microsoft-standard-WSL2` |
| Python | 3.14.4 |
| WSL memory | 4.8 GiB RAM, 6 GiB swap (default was 3.7 GiB / 1 GiB) |

**Why WSL2:** the EDA tools are built for Linux. WSL2 runs Ubuntu inside Windows, and WSLg shows Linux graphical windows on the Windows desktop.

```
$ uname -r
$ free -h
$ lsb_release -a      # "No LSB modules are available" is harmless
```

[![system_info](Resources/Stage1/system_info.png)](Resources/Stage1/system_info.png)
*(screenshot TODO)*

### Checking the GUI ✅

xschem, magic and netgen are graphical, so the display must work.

```
$ echo $DISPLAY                                   # :0
$ sudo apt update && sudo apt install -y x11-apps # 10 packages
$ xeyes                                           # two eyes window appeared
```

[![xeyes](Resources/Stage1/xeyes.png)](Resources/Stage1/xeyes.png)
*(screenshot TODO)*

### Updating the system ✅

```
$ sudo apt upgrade -y
```

69 packages were upgraded (including `openssl`, `sudo`, `libx11`, `mesa`). Two packages were held back by Ubuntu's phased updates, which is normal.

### Giving WSL more memory ✅

The default 3.7 GB can run out during the PDK build, so I raised it. In Windows PowerShell:

```
notepad $env:USERPROFILE\.wslconfig
```

```
[wsl2]
memory=5GB
swap=6GB
```

```
wsl --shutdown
```

After reopening Ubuntu, `free -h` showed 4.8 GiB RAM and 6.0 GiB swap.

[![free_h_after](Resources/Stage1/free_h_after.png)](Resources/Stage1/free_h_after.png)
*(screenshot TODO)*

## Chapter 1 - Getting the tools

To use the open-source SKY130 PDK and understand the design flow, we first need to install all the tools:

- magic
- ngspice
- xschem
- netgen
- open_pdks

*Note: open_pdks has to be installed last so it can correctly associate the xschem and magic directories.*

*Note: Ubuntu 26.04 is very new, so I checked package availability first.*

```
$ apt-cache policy magic ngspice netgen-lvs xschem iverilog klayout
$ sudo apt install magic ngspice netgen-lvs xschem klayout
$ sudo apt install -y git build-essential python3
```

| Tool | Purpose | Version |
|---|---|---|
| magic | layout, DRC, extraction | 8.3.105 from apt (replaced, see below) |
| ngspice | simulation | 45.2 |
| xschem | schematic | 3.4.4 |
| netgen-lvs | LVS | 1.5.133-1.2 |
| klayout | optional layout viewer | 0.30.0 |
| iverilog | digital simulation (already present, not needed) | 12.0 |

About 425 MB of dependencies (Qt5, Tcl/Tk, Ruby) came with these. The first `xschem --version` created `~/.xschem`.

[![tool_versions](Resources/Stage2/tool_versions.png)](Resources/Stage2/tool_versions.png)
*(screenshot TODO)*

### Magic: building a newer version from source

Magic is an open-source VLSI layout tool. The apt version (8.3.105) turned out to be too old for the current PDK (see [the first PDK attempt](#problems-and-fixes)), so I built the latest from source.

Build dependencies:

```
$ sudo apt update
$ sudo apt install -y build-essential git m4 tcsh csh tcl-dev tk-dev \
    libx11-dev libxext-dev libcairo2-dev libglu1-mesa-dev freeglut3-dev \
    mesa-common-dev zlib1g-dev libncurses-dev
```

Install steps:

```
$ cd ~
$ git clone https://github.com/RTimothyEdwards/magic
$ cd magic
$ CFLAGS="-g -std=gnu17" ./configure
$ make 2>&1 | tee ~/magic-build.log
$ sudo make install
$ hash -r
$ which magic                       # /usr/local/bin/magic
$ magic --version                   # 8.3.685
```

*Note: the plain `./configure && make` failed on this very new compiler with `too many arguments to function 'WindMove'`. Magic uses old C style declarations (`extern void WindMove();`) and the new compiler defaults to a C standard where empty parentheses mean "no arguments". Forcing `-std=gnu17` fixes it. If you already built once, run `make distclean` first. You can confirm the flag was picked up with `grep -n "gnu17" defs.mak`.*

`/usr/local/bin` takes priority over the old `/usr/bin/magic`.

More info: <http://opencircuitdesign.com/magic/index.html>

### Netgen, Xschem, Ngspice

Netgen (LVS), xschem (schematic capture) and ngspice (simulator) came from apt (versions in the table above), so no source build was needed.

More info: <http://opencircuitdesign.com/netgen/index.html>, <http://repo.hu/projects/xschem/index.html>, <https://ngspice.sourceforge.io/index.html>

## Chapter 2 - Installing the SKY130 PDK

Open_PDKs sets up the SkyWater sky130 process for open-source tools such as magic, xschem, ngspice, netgen and klayout.

Install steps:

```
$ cd ~
$ git clone https://github.com/RTimothyEdwards/open_pdks
$ cd open_pdks
$ ./configure --enable-sky130-pdk
$ make 2>&1 | tee ~/make.log
$ sudo make install
```

*Note: my first attempt failed because the apt magic was too old. If you hit this, fix magic first, then run `make distclean` in `open_pdks` and start again.*

The build ended with `Done.` The `No CDL file contains ...` lines are informational notes about I/O pad cells. Searching the log for "ERROR" only matches the script's own `echo "*** ERROR: ..."` text, which is printed only if a stage fails.

```
$ ls /usr/local/share/pdk
scripts  sky130A  sky130B
$ ls /usr/local/share/pdk/sky130A
libs.ref  libs.tech
```

`sky130A` is the variant used in all labs.

[![pdk_installed](Resources/Stage4/pdk_installed.png)](Resources/Stage4/pdk_installed.png)
*(screenshot TODO)*

## Chapter 3 - Understanding the design flow

### Verifying the open_pdks installation ✅

**Wrong test:** `magic -T sky130A` alone printed `Could not find file 'sky130A.tech'` and fell back to `minimum`. That option only searches magic's own folders, so it did not mean the install was broken.

**Correct test:** use the PDK's startup file.

```
$ magic -dnull -noconsole -rcfile /usr/local/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc <<'EOF'
puts "tech loaded: [tech name]"
quit -noprompt
EOF
```

```
Using technology "sky130A", version 1.0.588-90-g0ec4fa6
tech loaded: sky130A
```

There are no "Malformed line" messages, so the original problem is fixed. The `RLIMIT_NOFILE is above 1024` warning can be ignored.

[![magic_tech_loaded](Resources/Stage5/magic_tech_loaded.png)](Resources/Stage5/magic_tech_loaded.png)
*(screenshot TODO)*

Set the environment variables:

```
$ echo 'export PDK_ROOT=/usr/local/share/pdk' >> ~/.bashrc
$ echo 'export PDK=sky130A' >> ~/.bashrc
$ source ~/.bashrc
$ echo "PDK_ROOT=$PDK_ROOT PDK=$PDK"
```

### Creating the Lab 1 working directory ✅

An initial working directory is made by copying the required files from the PDK:

```
$ ls /usr/local/share/pdk/sky130A/libs.tech/xschem   # xschemrc
$ ls /usr/local/share/pdk/sky130A/libs.tech/ngspice  # spinit
$ ls /usr/local/share/pdk/sky130A/libs.tech/netgen   # sky130A_setup.tcl

$ mkdir -p ~/my-sky130-labs/Lab1_inverter/{xschem,mag,netgen}
$ cd ~/my-sky130-labs/Lab1_inverter
$ cp $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc xschem/
$ cp $PDK_ROOT/$PDK/libs.tech/ngspice/spinit xschem/.spiceinit
$ cp $PDK_ROOT/$PDK/libs.tech/magic/sky130A.magicrc mag/.magicrc
$ cp $PDK_ROOT/$PDK/libs.tech/netgen/sky130A_setup.tcl netgen/
```

| File | What it does |
|---|---|
| `xschemrc` | tells xschem where the SkyWater symbols are |
| `.spiceinit` | ngspice startup file for that folder |
| `.magicrc` | makes magic load sky130A when started from `mag/` |
| `sky130A_setup.tcl` | rules netgen uses for LVS |

```
my-sky130-labs/
└── Lab1_inverter/
    ├── xschem/   (schematic, symbol, testbench, .spiceinit)
    ├── mag/      (layout, .magicrc)
    └── netgen/   (sky130A_setup.tcl, LVS output)
```

### Inverter lab (next)

Circuit: a CMOS inverter (one NMOS, one PMOS).

| Step | Tool | Status |
|---|---|---|
| 0. Open each tool with the PDK | all | ⬜ |
| 1. Schematic, symbol, testbench | xschem | ⬜ |
| 2. Transient simulation and waveform | ngspice | ⬜ |
| 3. Layout and DRC | magic | ⬜ |
| 4. Extract layout netlist | magic | ⬜ |
| 5. LVS | netgen | ⬜ |

#### Step 0: Open each tool from its own folder

```
$ cd ~/my-sky130-labs/Lab1_inverter/xschem && xschem &
$ cd ~/my-sky130-labs/Lab1_inverter/mag && magic &
```

In xschem, check that the SkyWater parts (`sky130_fd_pr` library) appear in the Insert menu.

#### Step 1: Creating the inverter schematic using xschem

Place `sky130_fd_pr__nfet_01v8` and `sky130_fd_pr__pfet_01v8`. Wire the gates together (input) and the drains together (output). Connect the PMOS source and body to VDD, and the NMOS source and body to GND. Add pins, save as `inverter.sch`, then create the symbol. Make a testbench (`inverter_tb.sch`) with a 1.8 V supply, a pulse input and a load capacitor.

#### Step 2: Simulating the testbench

Netlist and simulate from xschem. Capture a waveform showing the output switching opposite to the input, and record the propagation delay.

#### Step 3: Creating the layout in magic and running DRC

Draw the NMOS and PMOS (PDK devices from the magic Devices menu), connect poly gates, drains and supplies, and add substrate and n-well taps. Run DRC:

```
% drc check
% drc why
% drc count
```

Fix violations until the count is 0.

#### Step 4: Extracting the layout netlist

```
% extract all
% ext2spice lvs
% ext2spice
```

#### Step 5: Performing LVS on the schematic and layout netlists

```
$ cd ~/my-sky130-labs/Lab1_inverter/netgen
$ netgen -batch lvs "../mag/inverter.spice inverter" "../xschem/inverter.spice inverter" sky130A_setup.tcl
```

Goal: the report says the circuits match. Save the output.

## Problems and fixes

| Problem | Cause | Fix |
|---|---|---|
| `make` in open_pdks: "Malformed line for keyword device", magic exit code -11 | apt magic 8.3.105 is too old for the current PDK (`sky130A.tech` uses newer commands, so magic crashed) | Build magic from source (8.3.685) |
| magic compile: "too many arguments to function 'WindMove'" | Newer compiler defaults to a C standard where `()` means no arguments | `CFLAGS="-g -std=gnu17" ./configure` |
| `magic -T sky130A`: "Could not find file 'sky130A.tech'" | Option only searches magic's own folders | Test with `-rcfile .../sky130A.magicrc` |
| Build risked running out of memory | WSL default is 3.7 GB RAM, 1 GB swap | `.wslconfig`: 5 GB RAM, 6 GB swap |

The first failure looked like this:

```
sky130A.tech: line 6042: section extract:
        Malformed line for keyword device.  Correct usage:
...
SystemError: Command magic failed with exit code: -11
make: *** [Makefile:132: tech-sky130] Error 2
```

[![make_failure](Resources/Stage3/make_failure.png)](Resources/Stage3/make_failure.png)
*(screenshot TODO)*

## Lessons learned

- Check tool versions against what the PDK needs. A package manager version can be too old.
- Read the first error in a log, not the last. The crash was a result of the "Malformed line" messages.
- A very new OS can break old C code. The `gnu17` standard fixed the build.
- Test the PDK through its own startup file; plain `-T sky130A` is misleading.
- Simulation, DRC and LVS each catch a different kind of mistake: the idea, the foundry rules, and layout versus plan.
