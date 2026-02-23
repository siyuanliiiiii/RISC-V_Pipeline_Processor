# RISC-V 5-Stage Pipelined Processor

## 📌 Overview
A good-performance **RISC-V (RV32I)** processor implemented in **SystemVerilog**, featured with pipeline hazard management, and memory hierarchy integration.

## 🚀 Key Features
* **Classic 5-Stage Pipeline**: Implemented Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), and Write-back (WB) stages.
* **Hazard Handling**:
    * **Data Forwarding**: Optimized bypass paths to minimize stalls for ALU-to-ALU and MEM-to-ALU dependencies.
    * **Load-Use Detection**: Automatic hardware-inserted bubbles to maintain data integrity.
    * **Control Flow**: Pipeline flushing mechanism for branch and jump instructions.
* **Instruction Set**: Full support for the **RV32I** Base Integer Instruction Set.
* **Memory Integration**: Interfaced with a cache-subsystem to simulate realistic memory latency and throughput.

## 🛠 Tech Stack
* **Language**: SystemVerilog
* **Simulation**: Synopsys VCS
* **Verification**: Verdi
* **Target Architecture**: RISC-V

## 📂 Project Structure
* `hdl/`: Core logic including the Datapath, Control Unit, and Hazard Unit.
* `testbench/`: Verification environment and assembly test cases.
* `docs/`: Architecture diagrams and design specifications.

---
*Disclaimer: This project is for portfolio purposes. If you are a current student, please adhere to your university's academic integrity policies.*
