add_files -norecurse [glob src/riscv_core/*.v]
add_files -norecurse [glob src/io_circuits/*.v]
add_files -norecurse [glob src/accelerator/*.v]
<<<<<<< HEAD
add_files -norecurse [glob src/riscv_core/EX/*.v]
add_files -norecurse [glob src/riscv_core/ID/*.v]
add_files -norecurse [glob src/riscv_core/WB/*.v]
add_files -norecurse src/EECS151.v
add_files -norecurse src/clk_wiz.v
add_files -norecurse src/z1top.v
=======
add_files -norecurse [glob src/*.v]
add_files -norecurse [glob src/*.vh]
>>>>>>> d3fbb7dd9ae3dddf459369540fdcd2f2e571d18d
# Add memory initialization file
add_files -norecurse ../software/bios151v3/bios151v3.mif

set_property top z1top [get_filesets sources_1]
