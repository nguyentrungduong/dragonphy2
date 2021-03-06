`include "iotype.sv"
//`include "/aha/sjkim85/github_repo/dragonphy2/inc/asic/iotype.sv"


module analog_core import const_pack::*; #(
) (
    input `pwl_t rx_inp,                                 // RX input (+) (from pad)
	input `pwl_t rx_inn,                                 // RX input (-) (from pad)
	input `real_t Vcm,                                   // common mode voltate for termination
	                                                     // (from pad/inout)
	
    input `pwl_t rx_inp_test,                            // RX input (+) for replica ADC (from pad)
    input `pwl_t rx_inn_test,                            // RX input (-) for replica ADC (from pad)
    
	input wire logic ext_clk,                            // (+) 4GHz clock input (from pad)
	input wire logic mdll_clk,                           // (+) 4GHz clock input (from mdll)

	input wire logic ext_clk_test0,                      // (+) 4GHz clock input (from pad)
    input wire logic ext_clk_test1,                      // (-) 4GHz clock input (from pad)
    	
	input wire logic clk_async,                          // asynchronous clock for phase measurement
	                                                     // (from DCORE)
	input wire logic [Npi-1:0] ctl_pi[Nout-1:0],         // PI control code (from DCORE)
	input wire logic ctl_valid,                          // PI control valid flag (from DCORE) 

	inout `voltage_t Vcal,                               // bias voltage for V2T (from pad)
	
	output wire logic clk_adc,                           // clock for retiming adc data assigned from ADC_0
	                                                     // (to DCORE)
    output wire logic [Nadc-1:0] adder_out [Nti-1:0],    // adc output (to DCORE)
    output wire logic [Nti-1:0] sign_out,                // adc output (to DCORE)

    output wire logic [Nadc-1:0] adder_out_rep [1:0],    // adc_rep output (to DCORE)
    output wire logic [1:0] sign_out_rep,                // adc_rep_output (to DOORE)
    
	acore_debug_intf.acore adbg_intf_i
);

    // internal signals
 	`pwl_t VinP_slice [Nout-1:0];
 	`pwl_t VinN_slice [Nout-1:0];
	
	logic [Nti-1:0] en_sync_in;
	logic [Nti-1:0] en_sync_out;
	logic [Nti-1:0] clk_v2t_prev;
	logic [Nti-1:0] clk_v2t_next;
	logic [1:0] clk_v2t_next_rep;
	logic [1:0] clk_div_rep;
	
	logic [Nout-1:0] clk_interp_slice;
	logic [Nout-1:0] clk_interp_sw;
	logic [Nout-1:0] clk_interp_sw_s2d;
	logic [Nout-1:0] clk_interp_swb_s2d;
	logic clk_in_pi;

    // for simulation and synthesis, clk_div[0] can just be assigned directly to clk_adc
    // however, for emulation, clk_div[0] is a clock value that needs to be converted
    // into a true clock signal for use by the digital.  this works by assigning the clock
    // value (clk_div[0]) to a signal (clk_adc_val), which is connected hierarchically to
    // the emulation clock generator at the top level (specified in clks.yaml).  that clock
    // generator converts the clock value into a true clock signal and writes it back to
    // a signal in analog_core (clk_adc_i).

	`ifndef VIVADO
        logic [Nti-1:0] clk_div;
	    assign clk_adc = clk_div[0];
	`else
	    (* dont_touch = "true" *) logic [Nti-1:0] clk_div;
	    (* dont_touch = "true" *) logic clk_adc_val;
	    assign clk_adc_val = clk_div[0];
	    (* dont_touch = "true" *) logic clk_adc_i;
	    assign clk_adc = clk_adc_i;
	`endif

    // termination

    // for emulation, ideally we would have an empty declaration for this module.  however,
    // Vivado doesn't work well with empty modules that are not black boxes, so the module
    // instantiation is just just ifdef'd out for emulation here

    `ifndef VIVADO
        termination iterm(
            .VinP(rx_inp),
            .VinN(rx_inn),
            .Vcm(Vcm)
        );
    `endif

    // 1st-level SnH
    snh iSnH (
        .clk(clk_interp_sw_s2d),
        .clkb(clk_interp_swb_s2d),
        .in_p(rx_inp),
        .in_n(rx_inn),
        .out_p(VinP_slice),
        .out_n(VinN_slice)
    );

   //assign clk_interp_swb[k] = ~clk_interp_sw[k];
	V2T_clock_gen_S2D isw_s2d[Nout-1:0] (.in(clk_interp_sw), .out(clk_interp_sw_s2d), .outb(clk_interp_swb_s2d));	

    // 16-way TI ADC
    generate
        for (genvar k=0; k<Nti; k=k+1) begin:iADC
            stochastic_adc_PR iADC (
                //inputs
                .VinP(VinP_slice[k/Nout]),
                .VinN(VinN_slice[k/Nout]),
                .clk_in(clk_interp_slice[k/Nout]),
                .clk_retimer(clk_adc),
                .Vcal(Vcal),
                .en_sync_in(en_sync_in[k]),
                .rstb(adbg_intf_i.rstb),
                .en_slice(adbg_intf_i.en_slice[k]),
                .ctl_v2t_n(adbg_intf_i.ctl_v2tn[k]),
                .ctl_v2t_p(adbg_intf_i.ctl_v2tp[k]),
                .init(adbg_intf_i.init[k]),
                .alws_on(adbg_intf_i.ALWS_ON[k]),
                .ctl_dcdl_late(adbg_intf_i.ctl_dcdl_late[k]),
                .ctl_dcdl_early(adbg_intf_i.ctl_dcdl_early[k]),
                .ctl_dcdl(adbg_intf_i.ctl_dcdl_TDC[k]),
                .en_TDC_phase_reverse(adbg_intf_i.en_TDC_phase_reverse),
                .retimer_mux_ctrl_1(adbg_intf_i.retimer_mux_ctrl_1[(k/Nout)+((k%Nout)*Nout)]),
                .retimer_mux_ctrl_2(adbg_intf_i.retimer_mux_ctrl_2[(k/Nout)+((k%Nout)*Nout)]),
				.sel_PFD_in(adbg_intf_i.sel_PFD_in[k]),
				.sign_PFD_clk_in(adbg_intf_i.sign_PFD_clk_in[k]),
				
                //outputs
                .en_sync_out(en_sync_out[k]),
                .adder_out(adder_out[k]),
                .sign_out(sign_out[k]),
                .clk_adder(clk_div[k]),
                .del_out(adbg_intf_i.del_out[k])
            );
            if (k != 0) begin
                assign en_sync_in[k] = en_sync_out[k-1];
            end else begin
                assign en_sync_in[k] = adbg_intf_i.en_v2t;
            end
        end
    endgenerate
 
    logic [3:0] inv_del_out_pi;
    logic [Nunit_pi-1:0] en_unit_pi [Nout-1:0]; 
	// 4ch. PI
    generate
        for (genvar k=0; k<Nout; k=k+1) begin: iPI
            phase_interpolator iPI(
                 //inputs
                .rstb(adbg_intf_i.rstb),
                .clk_in(clk_in_pi),
                .clk_async(clk_async),
                .clk_encoder(clk_adc),
                .ctl(ctl_pi[k]),
                .ctl_valid(ctl_valid),

                .en_gf(adbg_intf_i.en_gf),
                .en_arb(adbg_intf_i.en_arb_pi[k]),
                .en_delay(adbg_intf_i.en_delay_pi[k]),
                .en_ext_Qperi(adbg_intf_i.en_ext_Qperi[k]),
                .en_pm(adbg_intf_i.en_pm_pi[k]),
                .en_cal(adbg_intf_i.en_cal_pi[k]),
                .en_unit(en_unit_pi[k]),
                .ext_Qperi(adbg_intf_i.ext_Qperi[k]),
                .sel_pm_sign(adbg_intf_i.sel_pm_sign_pi[k]),
                .inc_del(adbg_intf_i.del_inc[k]),
                .ctl_dcdl_slice(adbg_intf_i.ctl_dcdl_slice[k]),
                .ctl_dcdl_sw(adbg_intf_i.ctl_dcdl_sw[k]),
                .ctl_dcdl_clk_encoder(adbg_intf_i.ctl_dcdl_clk_encoder[k]),
                .disable_state(adbg_intf_i.disable_state[k]),
                .en_clk_sw(adbg_intf_i.en_clk_sw[k]),

                //outputs
                .clk_out_slice(clk_interp_slice[k]),
                .clk_out_sw(clk_interp_sw[k]),
                .Qperi(adbg_intf_i.Qperi[k]),
                .cal_out(adbg_intf_i.cal_out_pi[k]),
                .del_out(inv_del_out_pi[k]),
                .pm_out(adbg_intf_i.pm_out_pi[k]),
                .max_sel_mux(adbg_intf_i.max_sel_mux[k])
            );
            assign adbg_intf_i.pi_out_meas[k] = (adbg_intf_i.sel_meas_pi[k] ? clk_interp_slice[k] : clk_interp_sw[k]) & adbg_intf_i.en_meas_pi[k];
        	assign en_unit_pi[k] = ~adbg_intf_i.enb_unit_pi[k];
		end
    endgenerate

    // replica ADCs

    stochastic_adc_PR iADCrep0 (
        // inputs
        .VinP(rx_inp_test),
        .VinN(rx_inn_test),
        .clk_in(clk_in_pi),
        .clk_retimer(clk_adc),
        .Vcal(Vcal),
        .en_sync_in(adbg_intf_i.en_v2t),
        .rstb(adbg_intf_i.rstb),
        .en_slice(adbg_intf_i.en_slice_rep[0]),
        .ctl_v2t_p(adbg_intf_i.ctl_v2tn_rep[0]),
        .ctl_v2t_n(adbg_intf_i.ctl_v2tp_rep[0]),
        .init(adbg_intf_i.init_rep[0]),
        .alws_on(adbg_intf_i.ALWS_ON_rep[0]),
        .ctl_dcdl_late(adbg_intf_i.ctl_dcdl_late_rep[0]),
        .ctl_dcdl_early(adbg_intf_i.ctl_dcdl_early_rep[0]),
        .ctl_dcdl(adbg_intf_i.ctl_dcdl_TDC_rep[0]),
        .en_TDC_phase_reverse(adbg_intf_i.en_TDC_phase_reverse),
        .retimer_mux_ctrl_1(adbg_intf_i.retimer_mux_ctrl_1_rep[0]),
        .retimer_mux_ctrl_2(adbg_intf_i.retimer_mux_ctrl_2_rep[0]),
		.sel_PFD_in(adbg_intf_i.sel_PFD_in_rep[0]),
		.sign_PFD_clk_in(adbg_intf_i.sign_PFD_clk_in_rep[0]),

        // outputs
        .en_sync_out(),
        .adder_out(adder_out_rep[0]),
        .sign_out(sign_out_rep[0]),
        .clk_adder(clk_div_rep[0]),
        .del_out(adbg_intf_i.del_out_rep[0])
    );

    stochastic_adc_PR iADCrep1 (
        // inputs
		.VinP(rx_inp_test),
    	.VinN(rx_inn_test),
    	.clk_in(clk_in_pi),
    	.clk_retimer(clk_adc),
    	.Vcal(Vcal),
		.en_sync_in(adbg_intf_i.en_v2t),
    	.rstb(adbg_intf_i.rstb),
    	.en_slice(adbg_intf_i.en_slice_rep[1]),
	    .ctl_v2t_p(adbg_intf_i.ctl_v2tn_rep[1]),
    	.ctl_v2t_n(adbg_intf_i.ctl_v2tp_rep[1]),
	    .init(adbg_intf_i.init_rep[1]),
	    .alws_on(adbg_intf_i.ALWS_ON_rep[1]),
	    .ctl_dcdl_late(adbg_intf_i.ctl_dcdl_late_rep[1]),
	    .ctl_dcdl_early(adbg_intf_i.ctl_dcdl_early_rep[1]),
	    .ctl_dcdl(adbg_intf_i.ctl_dcdl_TDC_rep[1]),
		.en_TDC_phase_reverse(adbg_intf_i.en_TDC_phase_reverse),
        .retimer_mux_ctrl_1(adbg_intf_i.retimer_mux_ctrl_1_rep[1]),
        .retimer_mux_ctrl_2(adbg_intf_i.retimer_mux_ctrl_2_rep[1]),
		.sel_PFD_in(adbg_intf_i.sel_PFD_in_rep[1]),
		.sign_PFD_clk_in(adbg_intf_i.sign_PFD_clk_in_rep[1]),

	    // outputs
	    .en_sync_out(),
	    .adder_out(adder_out_rep[1]),
	    .sign_out(sign_out_rep[1]),
	    .clk_adder(clk_div_rep[1]),
	    .del_out(adbg_intf_i.del_out_rep[1])
    );

    // bias generator

    // for emulation, ideally we would have an empty declaration for this module.  however,
    // Vivado doesn't work well with empty modules that are not black boxes, so the module
    // instantiation is just just ifdef'd out for emulation here

    `ifndef VIVADO
        generate
            for (genvar k=0; k<4; k=k+1) begin:iBG
                biasgen iBG (
                    //inputs
                    .en(adbg_intf_i.en_biasgen[k]),
                    .ctl(adbg_intf_i.ctl_biasgen[k]),
                    .Vbias(Vcal)
                );
            end
        endgenerate
    `endif

    // input clock buffer
	input_divider iindiv (
	    // inputs
		.in(ext_clk),
		.in_mdll(mdll_clk),
		.sel_clk_source(adbg_intf_i.sel_clk_source),
		.en(adbg_intf_i.en_inbuf),
		.bypass_div(adbg_intf_i.bypass_inbuf_div),
		.bypass_div2(adbg_intf_i.bypass_inbuf_div2),
		.ndiv(adbg_intf_i.inbuf_ndiv),
		.en_meas(adbg_intf_i.en_inbuf_meas),
	    // outputs
		.out(clk_in_pi),
		.out_meas(adbg_intf_i.inbuf_out_meas)
	);

    // output drivers

    wire del_out;
    assign del_out = adbg_intf_i.sel_del_out_pi ? inv_del_out_pi[0] : clk_in_pi ;
    assign adbg_intf_i.del_out_pi = del_out & adbg_intf_i.en_del_out_pi;

endmodule
