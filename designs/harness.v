`define MAX_ADDRESSIBLE_BYTE 256

// a little harness that emulates RAM for testing the CPU
// (initially vibecoded w/ claude, but now I'm expanding it to actually be useful)
module harness;
    reg clk, rst;
    reg [15:0] mem_in;
    wire R, W;
    wire [15:0] addr, data_out;
    wire stop;
    
    dCPU cpu(clk, rst, mem_in, R, W, addr, data_out, stop);
    
    // clock emulation
    initial begin
        clk = 0;
        forever begin
            #5
            if (!stop) begin
                // increment clock
                clk = ~clk;
                $display("Time=%0t-c%b state=%d pc=%h ir=%h, ar=%h acc=%d R=%b W=%b pc_inc=%b pc_l=%b ir_l=%b ar_l=%b ac_l=%b addr_m=%d, bus_m=%d sp=%d", 
                    $time, clk, cpu.c.state, cpu.pc, cpu.ir, addr, cpu.acc, R, W, cpu.pc_inc, cpu.pc_load, cpu.ir_load, cpu.ar_load, cpu.ac_load, cpu.addr_mux, cpu.bus_mux, cpu.sp);
            end else begin
                // otherwise, the CPU wants to stop, so print output
                $display("CPU wants to stop");
                $display("8'd%d", data_out);
                $finish();
            end
        end
    end
    
    // simple memory model
    reg [7:0] memory [0:`MAX_ADDRESSIBLE_BYTE];

    integer file, i, read, file_sz;
    reg [256*8-1:0] file_path;
    initial begin
        {memory[1], memory[0]} = `INSTR_LITA;
        {memory[3], memory[2]} = 16'd12345;
        {memory[5], memory[4]} = `INSTR_STOP;
        // memory[1] = 1'd99;
        // memory[2] = `INSTR_PUSH;
        // memory[3] = `INSTR_ADD;
        // memory[4] = 1'd5;
        // memory[5] = `INSTR_STORA;
        // memory[6] = 1'd254;
        // memory[7] = `INSTR_ADD;
        // memory[8] = 1'd5;
        // memory[9] = `INSTR_POP;

        // try to read memory from file if provided
        if ($value$plusargs("memory_from_file=%s", file_path)) begin
            file = $fopen(file_path, "rb");
            if (file) begin
                read = $fseek(file, 0, 2); // seek to end of the file
                file_sz = $ftell(file);    // see how far we went
                read = $fseek(file, 0, 0);
                
                if (file_sz > `MAX_ADDRESSIBLE_BYTE + 1) begin
                    $error("ERROR: given file is %0d bytes, can only load %d bytes", file_sz, `MAX_ADDRESSIBLE_BYTE + 1);
                    $finish(1);
                end
                
                read = $fread(memory, file, 0, `MAX_ADDRESSIBLE_BYTE + 1);
                $display("NOTE: loaded memory with %d bytes from given file", read);
                $fclose(file);
            end else begin
                $error("ERROR: could not open given file");
                $finish(1);
            end
        end
    end
    
    // Read from memory when CPU requests
    always @(*) begin
        if (!R) begin  // R is active low
            mem_in = {memory[addr + 1], memory[addr]};
            // $display("Time=%0t setting mem_in to %h", $time, mem_in);
        end else begin
            mem_in = 16'haaaa;
        end
    end

    // write to memory when the CPU requests
    always @(posedge clk) begin
        if (!W) begin
            {memory[addr + 1], memory[addr]} <= data_out;
            $display("Time=%0t writing %h to memory[%h]", $time, data_out, addr);
        end
        if (!W && !R) begin
            $error("WARNING: trying to read and write from memory at the same time");
            $error("terminating simulation early just in case, please debug me!");
            $finish(1);
        end
    end
    
    // Test sequence
    initial begin
        $dumpfile("harness.vcd");  // For waveform viewing
        $dumpvars(0, harness);
        
        rst = 1;
        #1;
        rst = 0;
        
        #3000;  // Run for a while
        // #30;
        
        $display("PC = %h, IR = %h, ACC = %h", cpu.pc, cpu.ir, cpu.acc);
        $finish;
    end
endmodule