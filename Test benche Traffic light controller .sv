`timescale 1ns/1ps

module tb_traffic_light;

    reg  clk = 0;
    reg  rst = 1;
    wire red, yellow, green;
    integer errors = 0;

    traffic_light dut (.clk(clk), .rst(rst),
                       .red(red), .yellow(yellow), .green(green));

    // 10 ns clock
    always #5 clk = ~clk;

    // Waveform dump (required by EPWave)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_traffic_light);
    end

    // ---------------- Checker ----------------
    // Encodes current light: 1=RED, 2=GREEN, 3=YELLOW, 0=invalid
    function [1:0] code;
        input r, y, g;
        begin
            if      ( r && !y && !g) code = 2'd1;
            else if (!r && !y &&  g) code = 2'd2;
            else if (!r &&  y && !g) code = 2'd3;
            else                     code = 2'd0;
        end
    endfunction

    reg [1:0] prev = 2'd0;
    integer   run  = 0;
    reg       tracking = 0;   // becomes 1 after first full state after reset

    always @(posedge clk) begin
        if (rst) begin
            tracking <= 0;
            prev     <= 2'd0;
            run      <= 0;
        end else begin : chk
            reg [1:0] cur;
            cur = code(red, yellow, green);

            if (cur == 2'd0) begin
                $display("[%0t] ERROR: invalid light combination", $time);
                errors = errors + 1;
            end

            if (cur == prev) begin
                run <= run + 1;
            end else begin
                // state just changed: verify the state that ended
                if (prev != 0) begin
                    case (prev)
                        2'd1: if (run != 10) begin
                                $display("[%0t] ERROR: RED lasted %0d cycles (exp 10)", $time, run);
                                errors = errors + 1; end
                        2'd2: if (run != 8) begin
                                $display("[%0t] ERROR: GREEN lasted %0d cycles (exp 8)", $time, run);
                                errors = errors + 1; end
                        2'd3: if (run != 2) begin
                                $display("[%0t] ERROR: YELLOW lasted %0d cycles (exp 2)", $time, run);
                                errors = errors + 1; end
                    endcase
                    // check legal order RED->GREEN->YELLOW->RED
                    if (!((prev==2'd1 && cur==2'd2) ||
                          (prev==2'd2 && cur==2'd3) ||
                          (prev==2'd3 && cur==2'd1))) begin
                        $display("[%0t] ERROR: illegal transition %0d -> %0d", $time, prev, cur);
                        errors = errors + 1;
                    end
                end
                prev <= cur;
                run  <= 1;
            end
        end
    end

    // ---------------- Stimulus ----------------
    initial begin
        // 1) Initial reset
        #22 rst = 0;

        // 2) Run for a few full cycles (one cycle = 200 ns)
        #1000;

        // 3) Reset in the middle of GREEN: must jump to RED immediately
        wait (green);
        #20;
        rst = 1;
        @(posedge clk); #1;
        if (!red) begin
            $display("ERROR: reset did not force RED");
            errors = errors + 1;
        end
        #20 rst = 0;

        // 4) Run again after reset
        #800;

        // 5) Reset in the middle of YELLOW
        wait (yellow);
        #5 rst = 1;
        @(posedge clk); #1;
        if (!red) begin
            $display("ERROR: reset during YELLOW did not force RED");
            errors = errors + 1;
        end
        #20 rst = 0;
        #600;

        if (errors == 0) $display("PASS: all checks passed");
        else             $display("FAIL: %0d error(s)", errors);
        $finish;
    end

    // Console monitor
    initial $monitor("t=%0t rst=%b R=%b Y=%b G=%b", $time, rst, red, yellow, green);

endmodule
