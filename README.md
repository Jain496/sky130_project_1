# SKY130_Open_Source_VLSI_Flow

This repository documents my hands-on work with the open-source **SkyWater SKY130** chip design flow. It follows the course on VSDIAT and covers installing the complete toolchain (xschem, ngspice, magic, netgen and the SKY130A PDK) on Ubuntu running inside WSL2 on a Windows 11 laptop.

The final goal, taken from the slides' **"Backend validation DIY"** lab, is to take one small circuit (a CMOS inverter) through the full manual design flow:

1. **xschem**: draw the schematic
2. **ngspice**: simulate it to check it works
3. **magic**: draw the layout and run DRC (Design Rule Check)
4. **netgen**: run LVS (Layout vs Schematic) to prove the layout matches the schematic

Chip design tools are normally expensive and closed. SKY130 is one of the few processes with a free, public PDK, so the whole flow can be learned on an ordinary laptop. Running one tiny circuit end to end (schematic, simulation, layout, DRC, LVS) shows what each step is for and how the tools depend on each other, which is the foundation for larger designs later.

> The documentation format follows <https://github.com/yathAg/Physical_Verification_SKY130A>, which was used only as a model for how to structure a lab write-up. All steps, commands, errors and fixes recorded here come from my own work on my own machine.

## Current status (last updated 17 October 2026)

| Stage | Status |
|---|---|
| WSL2 + Ubuntu 26.04, GUI check, memory settings | Done |
| EDA tools installed (magic, ngspice, xschem, netgen, klayout) | Done |
| Newer magic built from source (8.3.685) | Done |
| SKY130A PDK installed with `open_pdks` | Done |
| PDK verified in magic, environment variables set | Done |
| Lab 1 working folder prepared with PDK config files | Done |
| Verify xschem / ngspice / netgen open with the PDK | Not yet done |
| Inverter: schematic, simulation, layout + DRC, LVS | Not yet done |

## Index

- [Chapter 0 - Background: the tools and the flow](#chapter-0---background-the-tools-and-the-flow)
- [Chapter 1 - Preparing the environment](#chapter-1---preparing-the-environment)
  - [1.1 My system](#11-my-system)
  - [1.2 Checking graphics (X11) support](#12-checking-graphics-x11-support)
  - [1.3 Installing x11-apps and testing with xeyes](#13-installing-x11-apps-and-testing-with-xeyes)
  - [1.4 Updating the system](#14-updating-the-system)
  - [1.5 Giving WSL more memory](#15-giving-wsl-more-memory)
- [Chapter 2 - Installing the tools](#chapter-2---installing-the-tools)
- [Chapter 3 - Installing the SKY130 PDK](#chapter-3---installing-the-sky130-pdk)
  - [3.1 First attempt and the failure](#31-first-attempt-and-the-failure)
  - [3.2 Diagnosis](#32-diagnosis)
  - [3.3 Building a newer magic from source](#33-building-a-newer-magic-from-source)
  - [3.4 Rebuilding and installing the PDK](#34-rebuilding-and-installing-the-pdk)
  - [3.5 Verifying that magic loads the PDK](#35-verifying-that-magic-loads-the-pdk)
- [Chapter 4 - Configuration and the Lab 1 working folder](#chapter-4---configuration-and-the-lab-1-working-folder)
- [Chapter 5 - Lab 1: inverter through the full flow (planned)](#chapter-5---lab-1-inverter-through-the-full-flow-planned)
- [Problems and fixes](#problems-and-fixes)
- [Lessons learned](#lessons-learned)
- [Repository layout](#repository-layout)
- [References](#references)

---

## Chapter 0 - Background: the tools and the flow

> **Why this is done:** the later chapters install and configure many tools. Knowing first what each tool and term means makes it clear why every install step exists and why the order matters.

### Terms used in this document

| Term | Meaning |
|---|---|
| **PDK** | Process Design Kit. The foundry's rulebook and parts library: device models, layer definitions and manufacturing rules. SKY130 is the free PDK for SkyWater's 130 nm process. The tools cannot design anything for SKY130 until it is installed. |
| **open_pdks** | A set of scripts that converts the raw SkyWater PDK into the file formats each open-source tool understands. It does not contain the tools themselves. |
| **Netlist** | A text file listing circuit components and how they are connected. |
| **DRC** | Design Rule Check. Asks whether the layout obeys the foundry's manufacturing rules. |
| **LVS** | Layout vs Schematic. Asks whether the layout is electrically the same circuit as the schematic. |

### The tools

| Tool | Role in the flow |
|---|---|
| **xschem** | Schematic capture: draws the circuit |
| **ngspice** | Circuit simulator: checks the circuit behaves correctly |
| **magic** | Layout editor: draws the physical shapes, runs DRC and extracts a netlist from the layout |
| **netgen** | Netlist comparison: runs LVS |
| **klayout** | Optional layout viewer |
| **iverilog** | Verilog simulator (was already installed; not needed for this lab) |

### The flow

Each step catches a different kind of mistake: simulation checks the idea, DRC checks the foundry rules, and LVS checks that what was drawn matches the plan.

```
xschem (schematic) -> ngspice (simulate) -> magic (layout + DRC) -> magic (extract netlist) -> netgen (LVS)
```

> **Install order matters:** the tools must be installed first and `open_pdks` last, so that `open_pdks` can find the tool directories and install the right configuration files for them.

---

## Chapter 1 - Preparing the environment

> **Why this is done:** the EDA tools are Linux programs and most of them are graphical. Before installing anything big, I want to be sure the Linux environment, the display and the memory limits can actually support them, so problems show up early and are cheap to fix.

### 1.1 My system

> **Why this is done:** WSL2 gives a real Linux environment inside Windows, so the Linux-only tools run without dual-booting or a heavy virtual machine. Recording the OS, kernel and hardware also lets someone else compare their setup with mine, which matters because some errors later (Chapter 3) depend on how new the operating system is.

I run Linux inside Windows using **WSL2** (Windows Subsystem for Linux). The EDA tools are built for Linux, and WSLg lets Linux graphical windows appear on the Windows desktop, which matters because xschem and magic are graphical programs.

| Item | Value |
|---|---|
| Laptop processor | 12th Gen Intel Core i3-1215U |
| Installed RAM | 8 GB (7.65 GB usable) |
| Host OS | Windows 11 Home Single Language, version 25H2 |
| Linux environment | WSL2, Ubuntu 26.04 LTS (codename *resolute*) |
| Kernel | `6.18.33.2-microsoft-standard-WSL2` |
| Python | 3.14.4 (3.14.3 when first checked) |

Commands used to check the system:

```bash
uname -r
lsb_release -a
free -h
```

Ubuntu reports `No LSB modules are available`; this line is normal and harmless.

By default WSL showed only **3.7 GiB of RAM and 1 GiB of swap**, about half of the laptop's memory. This was raised in section 1.5.

![System info](Resources/Chapter1/system_info.png)

### 1.2 Checking graphics (X11) support

> **Why this is done:** xschem, magic and netgen draw windows. If `DISPLAY` is not set, those windows cannot open, and the failure would otherwise show up much later and look like a tool bug.

Design tools such as xschem and magic open windows, so Linux needs to know where to draw them.

```bash
echo $DISPLAY
```

Output: `:0`. The variable is set, so WSLg is available for graphical programs.

![DISPLAY check](Resources/Chapter1/display.png)

### 1.3 Installing x11-apps and testing with xeyes

> **Why this is done:** `xeyes` is a tiny program that does nothing except open a window. If it appears, the whole graphics path (Linux, WSLg, Windows desktop) works. Testing with a small program first is faster than debugging a large tool.

The `x11-apps` package provides small test programs, including `xeyes`, used to confirm that windows can open.

```bash
sudo apt update && sudo apt install -y x11-apps
xeyes
```

10 packages were installed (`x11-apps` plus 9 X11 libraries such as `libxaw7`, `libxmu6` and `libxt6t64`). These are the same graphics libraries the EDA tools need. `apt update` also reported 71 upgradable packages.

**Result:** the `xeyes` window (two eyes following the cursor) opened on the Windows desktop, so GUI applications work.

![xeyes](Resources/Chapter1/xeyes.png)

### 1.4 Updating the system

> **Why this is done:** an up-to-date system has current libraries and security fixes, which avoids version conflicts when large packages (Qt, Tcl/Tk, Mesa) are installed on top. Doing it before the installs keeps later problems separate from old-package problems.

```bash
sudo apt update
sudo apt upgrade -y
```

69 packages were upgraded, including security and bug-fix updates (`openssl`, `sudo`, `libx11`, `mesa`). Two packages (`python3-software-properties` and `software-properties-common`) were held back by Ubuntu's phased-update mechanism, which is normal.

### 1.5 Giving WSL more memory

> **Why this is done:** compiling magic and building the PDK use a lot of RAM, and WSL gave Linux only 3.7 GiB of my 8 GB. A build killed halfway wastes time and leaves confusing errors. Extra swap makes a heavy build slow down instead of dying.

Building the PDK needs a lot of memory and can be killed if memory runs out. I raised the limit to 5 GB and added 6 GB of swap. Swap is disk space Linux uses as emergency memory, so a heavy build slows down instead of being killed.

In Windows PowerShell I opened the WSL settings file:

```powershell
notepad $env:USERPROFILE\.wslconfig
```

and saved:

```ini
[wsl2]
memory=5GB
swap=6GB
```

Then restarted Linux from PowerShell:

```powershell
wsl --shutdown
```

After reopening Ubuntu I verified the change with `free -h`:

| | Before | After |
|---|---|---|
| Memory | 3.7 GiB | 4.8 GiB |
| Swap | 1.0 GiB | 6.0 GiB |

![free -h after](Resources/Chapter1/free_h_after.png)

---

## Chapter 2 - Installing the tools

> **Why this is done:** these are the programs that make up the flow: xschem draws, ngspice simulates, magic lays out and checks, netgen compares. Checking `apt-cache policy` first avoids assuming that a brand-new Ubuntu release has packages for everything. I used `apt` instead of building from source because it is faster and simpler, and `build-essential`, `git` and `python3` are installed because the PDK build and any source build need a compiler, `make` and scripting support. Recording the versions matters because the PDK is sensitive to them (see Chapter 3).

Because Ubuntu 26.04 is very new, I checked which versions `apt` offers before installing anything:

```bash
apt-cache policy magic ngspice netgen-lvs xschem iverilog klayout
```

Then installed the tools and the build tools needed later for the PDK:

```bash
sudo apt install magic ngspice netgen-lvs xschem klayout
sudo apt install -y git build-essential python3
```

The install pulled in dependencies such as Qt5, Tcl/Tk and Ruby, about 425 MB in total. `git` and `python3` were already present; `build-essential` was new (`gcc`/`g++` 15.2, `make` 4.4.1).

| Tool | Version installed from `apt` |
|---|---|
| magic | 8.3.105 (**later replaced**, see Chapter 3) |
| ngspice | 45.2 |
| xschem | 3.4.4 |
| netgen-lvs | 1.5.133-1.2 |
| klayout | 0.30.0-1build1 |
| iverilog | 12.0-3 (already installed) |

Verification:

```bash
magic --version      # 8.3.105
ngspice --version    # ngspice-45.2
xschem --version     # XSCHEM V3.4.4
```

Running `xschem --version` for the first time created `~/.xschem` containing a template `xschemrc`.

> **Note:** the reference repository builds all these tools from source. I used the prebuilt Ubuntu packages because they are simpler. This turned out to be fine for every tool except magic (see Chapter 3).

![Tool versions](Resources/Chapter2/tool_versions.png)

---

## Chapter 3 - Installing the SKY130 PDK

> **Why this is done:** without the PDK the tools know nothing about the SkyWater process: no transistor models, no layers, no design rules. A schematic or layout made without it would not be manufacturable. `open_pdks` is used because it converts the raw SkyWater files into the exact formats each tool reads.

The tools installed so far are only programs; they know nothing about the SkyWater process. `open_pdks` installs the SKY130 files in formats that magic, xschem, ngspice and netgen can use.

### 3.1 First attempt and the failure

> **Why this is done:** I followed the course slides' install commands as given, using the latest `open_pdks`, and logged the output with `tee ~/make.log`. The log is kept so the first error can be found afterwards instead of guessing from the last lines on screen. The failure is recorded here because it is the real story of the setup and will help anyone with a similar, very new system.

```bash
cd ~
git clone https://github.com/RTimothyEdwards/open_pdks
cd open_pdks
./configure --enable-sky130-pdk
make 2>&1 | tee ~/make.log
```

`make` stopped with these key messages:

```
sky130A.tech: line 6042: section extract:
        Malformed line for keyword device.  Correct usage:
...
SystemError: Command magic failed with exit code: -11
make: *** [Makefile:132: tech-sky130] Error 2
```

What the errors mean:

- **"Malformed line for keyword device"**: magic reads the PDK file `sky130A.tech`, which describes the chip layers. That file uses newer commands than my magic understood.
- **exit code -11**: magic crashed (a segmentation fault) while converting layout files, so the build stopped. This crash was a result of the first error.

![make failure](Resources/Chapter3/make_failure.png)

### 3.2 Diagnosis

> **Why this is done:** before changing anything I compared the versions of what was installed. Fixing the right thing (the old magic) is quicker than trying random fixes, and it turns a confusing error into a clear cause.

```bash
which magic        # /usr/bin/magic
magic --version    # 8.3.105
apt policy magic   # 8.3.105+ds.1-1.1
git -C ~/open_pdks log -1 --oneline
```

The installed magic was the old version from Ubuntu's package manager, while `open_pdks` was the latest main branch. **Conclusion: magic was too old for the current PDK, so a newer magic had to be built from source.**

### 3.3 Building a newer magic from source

#### Build dependencies

> **Why this is done:** building magic from source needs a compiler and the development headers for the libraries it uses (X11, Cairo, OpenGL, Tcl/Tk). If any are missing, `./configure` or `make` fails, so they are installed first.

```bash
sudo apt update
sudo apt install -y build-essential git m4 tcsh csh tcl-dev tk-dev \
  libx11-dev libxext-dev libcairo2-dev libglu1-mesa-dev freeglut3-dev \
  mesa-common-dev zlib1g-dev libncurses-dev
```

#### First compile attempt (failed)

> **Why this is done:** building from source gets the newest magic, which understands the newest `sky130A.tech`. The `apt` version cannot. The failure is documented because it is caused by the newness of Ubuntu 26.04 and the fix is not obvious from the error text.

```bash
cd ~
git clone https://github.com/RTimothyEdwards/magic
cd magic
./configure
make
```

The compile stopped with many errors of this form:

```
CMWmain.c:228:9: error: too many arguments to function 'WindMove'; expected 0, have 2
../windows/windows.h:266:13: note: declared here
  266 | extern void WindMove();
```

**Cause:** magic's source uses the old C style `extern void WindMove();`, where empty parentheses mean "arguments not specified". The very new compiler on Ubuntu 26.04 uses a newer C standard by default, where empty parentheses mean "no arguments", so every call looks wrong.

**Fix:** tell the compiler to use the older `gnu17` C standard.

```bash
cd ~/magic
make distclean
CFLAGS="-g -std=gnu17" ./configure
grep -n "gnu17" defs.mak
```

The `grep` showed `CFLAGS = -g -std=gnu17 -m64 -fPIC ...`, confirming the setting was applied.

#### Compile and install

> **Why this is done:** `make distclean` and a fresh `./configure` remove leftovers of the failed build so the `gnu17` setting is used everywhere. `hash -r` makes the shell forget the old `/usr/bin/magic` location, and `which magic` plus `magic --version` prove that the new copy in `/usr/local/bin` is the one that runs. Without that check the PDK build could silently use the old magic again.

```bash
make 2>&1 | tee ~/magic-build.log
sudo make install
hash -r
which magic        # /usr/local/bin/magic
magic --version    # 8.3.685
```

The new magic (8.3.685) is installed in `/usr/local/bin`, which takes priority over the old `/usr/bin/magic`.

### 3.4 Rebuilding and installing the PDK

> **Why this is done:** the earlier build used the old magic, so it had to be redone with the new one. `make distclean` clears stale output from the failed attempt. The log is checked for real errors so a successful `Done.` can be trusted. `sky130A` is chosen because it is the standard variant that the course and the reference lab use; `sky130B` differs mainly in some extra memory-related devices.

```bash
cd ~/open_pdks
make distclean
./configure --enable-sky130-pdk
make 2>&1 | tee ~/make.log
sudo make install
```

This time the build ended with `Done.` The `No CDL file contains ...` lines in the log are informational notes about I/O pad cells, not errors. Searching the log for the word `ERROR` only matched the build script's own `echo "*** ERROR: ..."` command text, which is printed only if a stage fails.

The PDK installed into `/usr/local/share/pdk`:

```
$ ls /usr/local/share/pdk
scripts  sky130A  sky130B
$ ls /usr/local/share/pdk/sky130A
libs.ref  libs.tech
```

`sky130A` is the standard variant and is the one used in all labs. `libs.ref` holds the reference libraries (cells and devices); `libs.tech` holds the per-tool configuration files.

![PDK installed](Resources/Chapter3/pdk_installed.png)

### 3.5 Verifying that magic loads the PDK

> **Why this is done:** a build that ends with `Done.` does not prove the tools can use the result. Loading the technology in magic and printing its name is a direct test that the original `Malformed line` problem is gone. The first test is kept in the write-up because it gave a misleading failure and would confuse anyone else who tries it.

**First test (misleading):** starting magic with only `-T sky130A` printed `Could not find file 'sky130A.tech'` and fell back to a technology called `minimum`. Magic only searches its own folders with that option, so this did **not** mean the install was broken.

**Second test (correct):** give magic the PDK's startup file, which tells it where the tech file is.

```bash
magic -dnull -noconsole -rcfile /usr/local/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc <<'EOF'
puts "tech loaded: [tech name]"
quit -noprompt
EOF
```

Result:

```
Using technology "sky130A", version 1.0.588-90-g0ec4fa6
tech loaded: sky130A
```

There were no "Malformed line" messages, so the original problem was fixed. The warning `RLIMIT_NOFILE is above 1024` can be ignored here.

![magic tech loaded](Resources/Chapter3/magic_tech_loaded.png)

---

## Chapter 4 - Configuration and the Lab 1 working folder

> **Why this is done:** installing the PDK is not enough on its own. Each tool must be told where the PDK is and which settings to use. This chapter does that once, so every lab starts from a working setup.

### Environment variables

> **Why this is done:** the PDK scripts and many tool configs look for `PDK_ROOT` (where the PDK lives) and `PDK` (which variant). Putting them in `~/.bashrc` makes them apply to every new terminal, so I do not have to type them again.

```bash
echo 'export PDK_ROOT=/usr/local/share/pdk' >> ~/.bashrc
echo 'export PDK=sky130A' >> ~/.bashrc
source ~/.bashrc
echo "PDK_ROOT=$PDK_ROOT PDK=$PDK"
```

Output: `PDK_ROOT=/usr/local/share/pdk PDK=sky130A`

### Checking the PDK's tool configuration files

> **Why this is done:** these files are produced by `open_pdks`. If one is missing, the install was incomplete, and it is better to find that now than in the middle of a lab.

```bash
ls /usr/local/share/pdk/sky130A/libs.tech/xschem   # contains xschemrc
ls /usr/local/share/pdk/sky130A/libs.tech/ngspice  # contains spinit
ls /usr/local/share/pdk/sky130A/libs.tech/netgen   # contains sky130A_setup.tcl
```

### Creating the project folder

> **Why this is done:** a separate folder for each tool (`xschem`, `mag`, `netgen`) is the structure recommended by the PDK and used by the reference repo. The tools read their startup files from the folder they are launched in, so copying `xschemrc`, `.spiceinit`, `.magicrc` and `sky130A_setup.tcl` there is what makes each tool load SKY130A automatically.

```bash
mkdir -p ~/my-sky130-labs/Lab1_inverter/{xschem,mag,netgen}
cd ~/my-sky130-labs/Lab1_inverter
cp $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc xschem/
cp $PDK_ROOT/$PDK/libs.tech/ngspice/spinit xschem/.spiceinit
cp $PDK_ROOT/$PDK/libs.tech/magic/sky130A.magicrc mag/.magicrc
cp $PDK_ROOT/$PDK/libs.tech/netgen/sky130A_setup.tcl netgen/
ls -A xschem mag netgen
```

| File | What it does |
|---|---|
| `xschemrc` | Tells xschem where the SkyWater symbols are |
| `.spiceinit` | Startup file read by ngspice from that folder |
| `.magicrc` | Makes magic load the sky130A technology when started from `mag/` |
| `sky130A_setup.tcl` | Rules netgen uses to compare schematic and layout |

### Checking that each tool opens (still to do)

> **Why this is done:** this is the final proof that the whole setup works together: if each tool opens in its own folder with the SKY130 parts available, the lab can start.

Start `magic` from `Lab1_inverter/mag` and `xschem` from `Lab1_inverter/xschem`, then record the result:

| Tool | Opens with PDK? | Screenshot |
|---|---|---|
| magic | Pending | `Resources/Chapter4/magic_window.png` |
| xschem | Pending | `Resources/Chapter4/xschem_window.png` |
| ngspice | Pending | |
| netgen | Pending | |
| klayout | Pending | |

---

## Chapter 5 - Lab 1: inverter through the full flow (planned)

> **Why this is done:** an inverter has only two transistors, so every step of the flow can be done and understood without a large design getting in the way. Each step catches a different kind of mistake: simulation checks that the idea works, DRC checks the foundry's manufacturing rules, and LVS checks that the layout is the same circuit as the schematic. Extraction is needed because LVS compares netlists, not pictures, so a netlist must first be produced from the drawn layout.

**Status: not started.** Planned circuit: a CMOS inverter (one NMOS and one PMOS transistor).

| Step | Tool | Purpose | Status |
|---|---|---|---|
| 1. Project folders and config files | shell | Standard layout, PDK config files copied | Done (Chapter 4) |
| 2. Schematic, symbol and testbench | xschem | Draw the design intent | Pending |
| 3. Simulation | ngspice | Confirm the circuit behaves correctly, capture the waveform | Pending |
| 4. Layout and DRC | magic | Draw the physical shapes, check foundry rules | Pending |
| 5. Extraction | magic | Produce a netlist of what was actually drawn | Pending |
| 6. LVS | netgen | Confirm layout matches schematic | Pending |

The commands below are the standard ones from the reference material. **They have not been run by me yet** and will be updated with my own results and screenshots.

Extract the layout netlist in magic:

```
% extract do local
% extract all
% ext2spice lvs
% ext2spice
```

Run LVS in netgen, comparing the layout netlist with the schematic netlist:

```bash
netgen -batch lvs "../mag/inverter.spice inverter" "../xschem/inverter.spice inverter"
```

### Progress checklist

- [x] GUI works under WSL2 (`xeyes`)
- [x] Ubuntu system updated
- [x] WSL memory and swap increased and verified
- [x] magic, ngspice, xschem, netgen-lvs and klayout installed
- [x] Build tools installed (`git`, `build-essential`, `python3`)
- [x] Newer magic built from source and installed
- [x] SKY130A PDK installed with `open_pdks`
- [x] magic loads the `sky130A` technology
- [x] `PDK_ROOT` and `PDK` set
- [x] Lab 1 folder created with config files
- [ ] Verify each tool opens with the PDK
- [ ] xschem: schematic, symbol, testbench
- [ ] ngspice: simulation and waveform
- [ ] magic: layout and DRC
- [ ] netgen: LVS
- [ ] Final screenshots and write-up

---

## Problems and fixes

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | `make` in `open_pdks` stopped with `Malformed line for keyword device` and `magic failed with exit code: -11` | `apt` magic 8.3.105 is too old for the current `sky130A.tech`, so it rejected the file and then crashed | Build a newer magic from source |
| 2 | magic source build failed with `too many arguments to function 'WindMove'; expected 0, have 2` | Old-style C declarations (`extern void WindMove();`) break under the newer default C standard of the Ubuntu 26.04 compiler | `make distclean`, then `CFLAGS="-g -std=gnu17" ./configure` and rebuild |
| 3 | `magic -T sky130A` printed `Could not find file 'sky130A.tech'` and used the `minimum` technology | `-T` alone only searches magic's own folders; the PDK is elsewhere | Start magic with `-rcfile .../sky130A.magicrc` (or use the `.magicrc` copied into `mag/`) |
| 4 | Worry that the log contained `ERROR` | Only the build script's own `echo "*** ERROR: ..."` text matched; `No CDL file contains ...` lines are informational | No fix needed; confirmed the build ended with `Done.` |
| 5 | Heavy builds risk being killed on low memory | WSL defaulted to 3.7 GiB RAM and 1 GiB swap | `.wslconfig` with `memory=5GB`, `swap=6GB`, then `wsl --shutdown` |

## Lessons learned

- A PDK is the foundry rulebook; the tools need it to know what is manufacturable.
- Always check tool versions against what the PDK needs. A package manager version can be too old.
- Read the **first** error in a log, not the last. The "Malformed line" messages pointed to the real cause; the crash was a result of it.
- A very new OS can break old C code. Setting the compiler standard to `gnu17` fixed the build.
- Test the PDK through its own startup file; a plain `-T sky130A` gives a misleading result.
- WSL2 plus WSLg lets Linux GUI tools run on a Windows 11 laptop, but the default memory limit may need raising for large builds.
- Simulation, DRC and LVS each catch a different kind of mistake.

## Repository layout

```
Physical-verification-notes/
├── README.md
├── Lab1_inverter/
│   ├── xschem/      (xschemrc, .spiceinit, schematics, testbench)
│   ├── mag/         (.magicrc, layout, extracted netlist)
│   └── netgen/      (sky130A_setup.tcl, LVS output)
└── Resources/
    ├── Chapter1/    (system_info, display, xeyes, free_h_after)
    ├── Chapter2/    (tool_versions)
    ├── Chapter3/    (make_failure, pdk_installed, magic_tech_loaded)
    └── Chapter4/    (magic_window, xschem_window)
```

## References

- Course slides: *Introduction to the SkyWater PDK*, VLSI System Design (27 slides)
- SkyWater SKY130 PDK: <https://github.com/google/skywater-pdk>
- open_pdks: <https://github.com/RTimothyEdwards/open_pdks>
- magic: <https://github.com/RTimothyEdwards/magic> and <http://opencircuitdesign.com/magic/>
- netgen: <http://opencircuitdesign.com/netgen/>
- xschem: <https://github.com/StefanSchippers/xschem>
- ngspice: <https://ngspice.sourceforge.io/>
- Documentation format reference: <https://github.com/yathAg/Physical_Verification_SKY130A>
