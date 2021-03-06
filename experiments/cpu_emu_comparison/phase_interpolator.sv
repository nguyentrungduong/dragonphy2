// simple model used for performance comparison with emulation

`timescale 1s/1fs

`include "iotype.sv"

`ifndef JITTER_RMS
    `define JITTER_RMS 0
`endif

module phase_interpolator #(
    parameter Nbit = 9,
    parameter Nctl_dcdl = 2,
    parameter Nunit = 32,
    parameter Nblender = 4
)(
    input rstb,
    input clk_in,
    input clk_async,
    input clk_encoder,
    input disable_state,
    input en_arb,
    input en_cal,
    input en_clk_sw,
    input en_delay,
    input en_ext_Qperi,
    input en_gf,
    input ctl_valid,
    input [Nbit-1:0]  ctl,
    input [Nctl_dcdl-1:0] ctl_dcdl_sw,
    input [Nctl_dcdl-1:0] ctl_dcdl_slice,
    input [Nctl_dcdl-1:0] ctl_dcdl_clk_encoder,
    input [Nunit-1:0]  inc_del,
    input [$clog2(Nunit)-1:0] ext_Qperi,
    input [1:0] sel_pm_sign,
    input en_pm,

    output cal_out,
    output reg clk_out_slice=1'b0,
    output clk_out_sw,
    output del_out,

    output [$clog2(Nunit)-1:0] Qperi,
    output [$clog2(Nunit)-1:0] max_sel_mux,
    output cal_out_dmm,
    output [19:0]  pm_out
);

    // random seed initialization

    integer seed;
    initial begin
        seed = $urandom();
    end

    // delay clk_in to clk_out_slice

    real delay_s;
    always @(clk_in) begin
        // compute the delay
        delay_s = ((1.0*ctl)/(2.0**(Nbit)))*(250.0e-12);

        // add jitter
        delay_s += (`JITTER_RMS)*($dist_normal(seed, 0, 10000000)/10000000.0);

        // clamp non-negative
        if (delay_s < 0) begin
            delay_s = 0.0;
        end

        // apply the delay
        clk_out_slice <= #(delay_s*1s) clk_in;
    end

    // outputs that are not modeled

    assign cal_out = 0;
    assign clk_out_sw = 0;
    assign del_out = 0;
    assign Qperi = 0;
    assign max_sel_mux = 0;
    assign cal_out_dmm = 0;
    assign pm_out = 0;

endmodule

