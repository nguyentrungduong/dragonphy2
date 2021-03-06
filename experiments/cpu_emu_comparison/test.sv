`timescale 1s/1fs

`include "mLingua_pwl.vh"

`ifdef FAST_JTAG
    `define SET_JTAG(name, value) force top_i.idcore.jtag_i.rjtag_intf_i.``name`` = ``value``
    `define GET_JTAG(name) jtag_result = top_i.idcore.jtag_i.rjtag_intf_i.``name``
    `define SET_JTAG_ARRAY(name, value, index) tmp_``name``[``index``] = ``value``
    `define COMMIT_JTAG_ARRAY(name) `SET_JTAG(``name``, tmp_``name``);
`else
    `define SET_JTAG(name, value) jtag_drv_i.write_tc_reg(``name``, ``value``)
    `define GET_JTAG(name) jtag_drv_i.read_sc_reg(``name``, jtag_result)
    `define SET_JTAG_ARRAY(name, value, index) `SET_JTAG(``name``[``index``], ``value``)
    `define COMMIT_JTAG_ARRAY(name) 
`endif

`ifndef NBITS
    `define NBITS 600000
`endif

`ifndef CHAN_TAU
    `define CHAN_TAU 25.0e-12
`endif

`ifndef CHAN_DLY
    `define CHAN_DLY 31.25e-12
`endif

`ifndef CHAN_ETOL
    `define CHAN_ETOL 0.001
`endif

`ifndef TX_TTR
    `define TX_TTR 10e-12
`endif

module test;

	import const_pack::*;
	import jtag_reg_pack::*;

    import ffe_gpack::length;
    import ffe_gpack::weight_precision;
    import constant_gpack::channel_width;

    localparam real dt=1.0/(16.0e9);
    localparam real tau=(`CHAN_TAU);
    localparam real dly=(`CHAN_DLY);
    localparam integer coeff0 = 128.0/(1.0-$exp(-dt/tau));
    localparam integer coeff1 = -128.0*$exp(-dt/tau)/(1.0-$exp(-dt/tau));

    // clock inputs
	logic ext_clkp;
	logic ext_clkn;

	// reset
	logic rstb;

	// JTAG
	jtag_intf jtag_intf_i();
    jtag_drv jtag_drv_i (jtag_intf_i);

	// Analog inputs

	pwl ch_outp;
	pwl ch_outn;

    real inp, inn;
    assign inp = ch_outp.a;
    assign inn = ch_outn.a;

	// instantiate top module

	dragonphy_top top_i (
	    // analog inputs
		.ext_rx_inp(ch_outp),
		.ext_rx_inn(ch_outn),

		// external clocks
		.ext_clkp(ext_clkp),
		.ext_clkn(ext_clkn),

		// reset
        .ext_rstb(rstb),

        // JTAG
		.jtag_intf_i(jtag_intf_i)

		// other I/O not used...
	);

    // prbs stimulus

    logic tx_clk;
    logic tx_data;

    tx_prbs #(
        .freq(16.0e9),
        .td(0.0) // delay is applied later
    ) tx_prbs_i (
        .clk(tx_clk),
        .out(tx_data)
    );

// uncomment to try using the same PRBS stimulus used in the emulator

//    logic tx_rst;
//    initial begin
//        tx_rst = 1'b1;
//        #(1ns);
//        tx_rst = 1'b0;
//    end
//
//    prbs_generator_syn #(
//        .n_prbs(32)
//    ) prbs_generator_syn_i (
//        .clk(tx_clk),
//        .rst(tx_rst),
//        .cke(1'b1),
//        .init_val(32'h00000001),
//        .eqn(32'h100002),
//        .inj_err(1'b0),
//        .inv_chicken(2'b00),
//        .out(tx_data)
//    );

// Uncomment to use a pattern generator that is
// useful for debugging the sequence of operations

//    pwl fake_p;
//    pwl fake_n;
//
//    integer bit_index = 0;
//    integer pattern_index = 0;
//    always @(posedge tx_clk) begin
//        if (bit_index == pattern_index) begin
//            fake_p <= #(dly*1s) '{0.4, 0, 0};        
//            fake_n <= #(dly*1s) '{0.1, 0, 0};        
//        end else begin
//            fake_p <= #(dly*1s) '{0.25, 0, 0};        
//            fake_n <= #(dly*1s) '{0.25, 0, 0};        
//        end
//        bit_index = bit_index + 1;
//        if (bit_index == 16) begin
//            bit_index = 0;
//            pattern_index = pattern_index + 1;
//            if (pattern_index == 17) begin
//                pattern_index = 0;
//            end
//        end
//    end

    // apply delay to data

    logic tx_data_dly;
    always @(tx_data) begin
        tx_data_dly <= #(dly*1s) tx_data;
    end

    // TX driver

    pwl tx_p;
    pwl tx_n;

    diff_tx_driver #(
        .tr(`TX_TTR),
        .vl(0.1),
        .vh(0.4)
    ) diff_tx_driver_i (
        .in(tx_data_dly),
        .out_p(tx_p),
        .out_n(tx_n)
    );

    // Differential channel

    diff_channel #(
        .etol(`CHAN_ETOL),
        .tau(tau)
    ) diff_channel_i (
        .in_p(tx_p),
        .in_n(tx_n),
        .out_p(ch_outp),
        .out_n(ch_outn)
    );

	// Divide down 16 GHz clock to
    // produce 8 GHz clock to make
    // sure that it stays synchronized

    initial begin
        ext_clkp = 0;
    end

    always @(posedge tx_clk) begin
        ext_clkp = ~ext_clkp;
    end

    assign ext_clkn = ~ext_clkp;

    //  Main test

    logic [Nprbs-1:0] tmp_prbs_eqn;

    integer loop_var, loop_var2;
    integer offset;

	logic [31:0] jtag_result;

    longint err_bits, total_bits;

    // for loading one FFE weight with specified depth and width
    task load_weight(
        input logic [$clog2(length)-1:0] d_idx,
        logic [$clog2(channel_width)-1:0] w_idx,
        logic signed [weight_precision-1:0] value
    );
        $display("Loading weight d_idx=%0d, w_idx=%0d with value %0d", d_idx, w_idx, value);
        `SET_JTAG(wme_ffe_inst, {1'b0, w_idx, d_idx});
        `SET_JTAG(wme_ffe_data, value);
        #(3ns);
        `SET_JTAG(wme_ffe_exec, 1);
        #(3ns);
        `SET_JTAG(wme_ffe_exec, 0);
        #(3ns);
    endtask

    function real get_time();
        // this function is modified from:
        // https://verificationguide.com/how-to/how-to-display-system-time-in-systemverilog/

        int file_pointer;

        // Stores time and date to file tmp_sys_time
        void'($system("date +%s.%N > tmp_sys_time"));

        // Open the file tmp_sys_time with read access
        file_pointer = $fopen("tmp_sys_time", "r");

        // Assign the value from file to variable
        void'($fscanf(file_pointer, "%f", get_time));

        // Close the file
        $fclose(file_pointer);

        // Remove file tmp_sys_time
        void'($system("rm tmp_sys_time"));
    endfunction

    real start_time;
    real stop_time;
    real target_sim_time;

    logic [7:0] tmp_ext_pfd_offset [(Nti-1):0];
    logic [4:0] tmp_ffe_shift [(Nti-1):0];

	initial begin
        `ifdef DUMP_WAVEFORMS
            // Set up probing
            $shm_open("waves.shm");
            $shm_probe("ASMC");
        `endif

        // print test condition
        $display("tau=%0.3f (ps)", tau*1.0e12);

        // initialize control signals
		rstb = 1'b0;
        #(1ns);

		// Release reset
		$display("Releasing external reset...");
		rstb = 1'b1;
        #(1ns);

        // Initialize JTAG
        $display("Initializing JTAG...");
        jtag_drv_i.init();

        // Soft reset sequence
        $display("Soft reset sequence...");
        `SET_JTAG(int_rstb, 1);
        #(1ns);
        `SET_JTAG(en_inbuf, 1);
		#(1ns);
        `SET_JTAG(en_gf, 1);
        #(1ns);
        `SET_JTAG(en_v2t, 1);
        #(64ns);

        // Set up the PFD offset
        $display("Setting up the PFD offset...");
        for (int idx=0; idx<Nti; idx=idx+1) begin
            `SET_JTAG_ARRAY(ext_pfd_offset, 0, idx);
        end
        `COMMIT_JTAG_ARRAY(ext_pfd_offset)
        #(1ns);

        // Set the equation for the PRBS checker
        $display("Setting the PRBS equation");
        tmp_prbs_eqn = 0;
        tmp_prbs_eqn[ 1] = 1'b1;
        tmp_prbs_eqn[20] = 1'b1;
        `SET_JTAG(prbs_eqn, tmp_prbs_eqn);
        #(10ns);

        // Select the PRBS checker data source
        $display("Select the PRBS checker data source");
        `SET_JTAG(sel_prbs_mux, 2'b01); // 2'b00: ADC, 2'b01: FFE
        #(10ns);

        // Release the PRBS checker from reset
        $display("Release the PRBS tester from reset");
        `SET_JTAG(prbs_rstb, 1);
        #(50ns);

        // Set up the FFE
        for (loop_var=0; loop_var<Nti; loop_var=loop_var+1) begin
            for (loop_var2=0; loop_var2<ffe_gpack::length; loop_var2=loop_var2+1) begin
                if (loop_var2 == 0) begin
                    // The argument order for load() is depth, width, value
                    load_weight(loop_var2, loop_var, coeff0);
                end else if (loop_var2 == 1) begin
                    load_weight(loop_var2, loop_var, coeff1);
                end else begin
                    load_weight(loop_var2, loop_var, 0);
                end
            end
            `SET_JTAG_ARRAY(ffe_shift, 7, loop_var);
        end
        `COMMIT_JTAG_ARRAY(ffe_shift)
        #(10ns);

        // Configure the CDR offsets
        $display("Setting up the CDR offset...");
        `SET_JTAG(ext_pi_ctl_offset[0],   0);
        `SET_JTAG(ext_pi_ctl_offset[1], 128);
        `SET_JTAG(ext_pi_ctl_offset[2], 256);
        `SET_JTAG(ext_pi_ctl_offset[3], 384);
        #(5ns);
        `SET_JTAG(en_ext_max_sel_mux, 1);
        #(5ns);

        // Configure the retimer (first option matches the emulator, 
        // second option matches the chip defaults)
        `SET_JTAG(retimer_mux_ctrl_1, 16'b1111111111111111);
        `SET_JTAG(retimer_mux_ctrl_2, 16'b1111111111111111);
        //`SET_JTAG(retimer_mux_ctrl_1, 16'b0000111111110000);
        //`SET_JTAG(retimer_mux_ctrl_2, 16'b1111000000000000);
        #(5ns);

        // Assert the CDR reset
        `SET_JTAG(cdr_rstb, 0);
        #(5ns);

        // Configure the CDR
      	$display("Configuring the CDR...");
      	`SET_JTAG(Kp, 18);
      	`SET_JTAG(Ki, 0);
      	`SET_JTAG(invert, 1);
		`SET_JTAG(en_freq_est, 0);
		`SET_JTAG(en_ext_pi_ctl, 0);
		`SET_JTAG(sel_inp_mux, 1); // "0": use ADC output, "1": use FFE output
		#(10ns);

        // Toggle the en_v2t signal to re-initialize the V2T ordering
        $display("Toggling en_v2t...");
        `SET_JTAG(en_v2t, 0);
        #(5ns);
        `SET_JTAG(en_v2t, 1);
        #(5ns);

        // De-assert the CDR reset
        `SET_JTAG(cdr_rstb, 1);
        #(5ns);

		// Wait for MM_CDR to lock
		$display("Waiting for MM_CDR to lock...");
		for (loop_var=0; loop_var<100; loop_var=loop_var+1) begin
		    $display("Interval %0d/100", loop_var);
		    #(100ns);
		end

        // Run the PRBS tester

        // Nothing is printed out during the test to get the most aggressive (i.e. fairest)
        // throughput comparison when examining FPGA vs. CPU performance.

        $display("Running the PRBS tester");
        `SET_JTAG(prbs_checker_mode, 2);

        target_sim_time = 62.5e-12*(`NBITS);
        start_time = get_time();
        #(target_sim_time*1s);
		stop_time = get_time();

        // Print out results of runtime experiment
        $display("PRBS test took %0f seconds.", stop_time - start_time);

        // Get results
        `SET_JTAG(prbs_checker_mode, 3);
        #(10ns);

        err_bits = 0;
        `GET_JTAG(prbs_err_bits_upper);
        err_bits |= jtag_result;
        err_bits <<= 32;
        `GET_JTAG(prbs_err_bits_lower);
        err_bits |= jtag_result;

        total_bits = 0;
        `GET_JTAG(prbs_total_bits_upper);
        total_bits |= jtag_result;
        total_bits <<= 32;
        `GET_JTAG(prbs_total_bits_lower);
        total_bits |= jtag_result;

        // Print results
        $display("err_bits: %0d", err_bits);
        $display("total_bits: %0d", total_bits);
        $display("BER: %0e", (1.0*err_bits)/(1.0*total_bits));

        // Check results

        if (!(total_bits >= 9500)) begin
            $error("Not enough bits transmitted");
        end else begin
            $display("Number of bits transmitted is OK");
        end

        if (!(err_bits == 0)) begin
            $error("Bit error detected");
        end else begin
            $display("No bit errors detected");
        end

		// Finish test
		$display("Test complete.");
		$finish;
    end

    // wired for debug purposes
    `ifdef VCS
        logic [8:0] ctl_pi_0;
        assign ctl_pi_0 = top_i.iacore.ctl_pi[0];
    `endif
endmodule
