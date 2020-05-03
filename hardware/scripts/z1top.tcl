add_files -norecurse [glob src/riscv_core/*.v]
add_files -norecurse [glob src/io_circuits/*.v]
add_files -norecurse [glob src/accelerator/*.v]
add_files -norecurse [glob src/*.v]
add_files -norecurse [glob src/*.vh]
# Add memory initialization file
add_files -norecurse ../software/bios151v3/bios151v3.mif

set_property top z1top [get_filesets sources_1]
