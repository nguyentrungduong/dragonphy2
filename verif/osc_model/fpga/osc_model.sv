`include "signals.sv"

module osc_model #(
    parameter real t_hi=0.5e-9,
    parameter real t_lo=0.5e-9
) (
    output wire logic clk_o
);

    // signals use for external I/O
    (* dont_touch = "true" *) logic __emu_clk_val;
    (* dont_touch = "true" *) logic __emu_rst;
    (* dont_touch = "true" *) logic __emu_clk;
    (* dont_touch = "true" *) logic signed [((`DT_WIDTH)-1):0] __emu_dt;
    (* dont_touch = "true" *) logic signed [((`DT_WIDTH)-1):0] __emu_dt_req;
    (* dont_touch = "true" *) logic __emu_clk_i;

    // Pass through "clk_i" to "clk_o"
    // "dont_touch" is used because clk_i
    // is written hierarchically, even though
    // it does not appear as a module input
    assign clk_o = __emu_clk_i;

    // import emu_dt as a svreal signal
    logic signed [((`DT_WIDTH)-1):0] emu_dt_significand;
    logic signed [15:0] emu_dt_exponent;
    localparam integer emu_dt_significand_width = `DT_WIDTH;
    assign emu_dt_significand = __emu_dt;
    assign emu_dt_exponent = `DT_EXPONENT;

    // Main control logic.  "dont_touch" is used
    // because the dt_req and clk_val signals are
    // read hierarchically, even though they are
    // not outputs of the module
    `DECL_DT_LOCAL(dt_req);
    assign __emu_dt_req = dt_req_significand;

    // check if the emulator timestep matches the 
    // requested timestep
    logic dt_req_eq_emu_dt;
    `SVREAL_EQ(dt_req, emu_dt, dt_req_eq_emu_dt);

    // compute difference between requested 
    `DECL_DT_LOCAL(dt_req_minus_emu_dt);
    `SVREAL_SUB(dt_req, emu_dt, dt_req_minus_emu_dt);

    // compute the duration of the next half period
    `DECL_DT_LOCAL(next_half_period);
    `DT_CONST(t_hi_const, t_hi);
    `DT_CONST(t_lo_const, t_lo);
    `SVREAL_MUX(__emu_clk_val, t_hi_const, t_lo_const, next_half_period);

    // determine the next value of dt_req
    `DECL_DT_LOCAL(dt_req_imm);
    `SVREAL_MUX(dt_req_eq_emu_dt, dt_req_minus_emu_dt, next_half_period, dt_req_imm);

    // assign to dt_req with memory
    `SVREAL_DFF(dt_req_imm, dt_req, __emu_rst, __emu_clk, 1'b1, t_lo_const);

    // clock toggling logic
    always @(posedge __emu_clk) begin
        if (__emu_rst == 1'b1) begin
            __emu_clk_val <= 1'b0;
        end else if (dt_req_eq_emu_dt == 1'b1) begin
            __emu_clk_val <= ~__emu_clk_val;
        end else begin
            __emu_clk_val <= __emu_clk_val;
        end
    end

endmodule