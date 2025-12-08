// a little harness that emulates RAM for testing the CPU
// (initially vibecoded w/ claude, but now I'm expanding it to actually be useful)
module harness;
    reg clk, rst;
    reg [7:0] mem_in;
    wire R, W;
    wire [7:0] addr, data_out;
    
    dCPU cpu(clk, rst, mem_in, R, W, addr, data_out);
    
    // clock emulation
    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
            $display("Time=%0t-c%b state=%d pc=%h ir=%h, ar=%h acc=%d R=%b W=%b pc_inc=%b pc_l=%b ir_l=%b ar_l=%b ac_l=%b addr_m=%d, bus_m=%d sp=%d", 
                 $time, clk, cpu.c.state, cpu.pc, cpu.ir, addr, cpu.acc, R, W, cpu.pc_inc, cpu.pc_load, cpu.ir_load, cpu.ar_load, cpu.ac_load, cpu.addr_mux, cpu.bus_mux, cpu.sp);
        end
    end
    
    // simple memory model
    reg [7:0] memory [0:255];

    integer file, i, read, file_sz;
    reg [256*8-1:0] file_path;
    initial begin
        memory[0] = `INSTR_LITA;
        memory[1] = 8'd99;
        memory[2] = `INSTR_PUSH;
        memory[3] = `INSTR_ADD;
        memory[4] = 8'd5;
        memory[5] = `INSTR_STORA;
        memory[6] = 8'd254;
        memory[7] = `INSTR_ADD;
        memory[8] = 8'd5;
        memory[9] = `INSTR_POP;

        if ($value$plusargs("memory_from_file=%s", file_path)) begin
            // $display("Value of file memory: %s", file_path);
            file = $fopen(file_path, "rb");
            if (file) begin
                read = $fseek(file, 0, 2); // seek to end of the file
                file_sz = $ftell(file);
                read = $fseek(file, 0, 0);
                $display("file sz is %d", file_sz);
                
                if (file_sz > 256) begin
                    $error("WARNING: File is %0d bytes, can only load 256 bytes", file_sz);
                end
                
                read = $fread(memory, file, 0, 256);
                $display("read %d bytes", read);
                $fclose(file);
            end else begin

            end
        end
    end
    
    // Read from memory when CPU requests
    always @(*) begin
        if (!R) begin  // R is active low
            mem_in = memory[addr];
            // $display("Time=%0t setting mem_in to %h", $time, mem_in);
        end else begin
            mem_in = 8'h00;
        end
    end

    // write to memory when the CPU requests
    always @(posedge clk) begin
        if (!W) begin
            memory[addr] <= data_out;
            $display("Time=%0t writing %h to memory[%h]", $time, data_out, addr);
        end
        if (!W && !R) begin
            $error("WARNING: trying to read and write from memory at the same time");
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
        
        $display("PC = %h, IR = %h, ACC = %h", cpu.pc, cpu.ir, cpu.acc);
        $finish;
    end
endmodule