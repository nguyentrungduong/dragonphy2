

/****************************************************************
* This code is automatically generated by "mGenero"
* at Thu, 02 Jul 2020 15:34:39.
*
* Copyright (c) 2014-Present by Stanford University. All rights reserved.
*
* The information and source code contained herein is the property
* of Stanford University, and may not be disclosed or reproduced
* in whole or in part without explicit written authorization from
* Stanford University.
* For more information, contact bclim@stanford.edu
****************************************************************/
/********************************************************************
filename: phase_blender.sv
Description: 
multi-bit phase blender.
Assumptions:
Todo:
********************************************************************/

module phase_blender #(
  parameter integer Nblender = 4 // # of control bits
) (
  input logic [1:0] ph_in, // ph_in
  output logic  ph_out, // ph_out
  input logic [15:0] thm_sel_bld // thm_sel_bld
);

    timeunit 1fs;
    timeprecision 1fs;

    import model_pack::PIParameter;

    // design parameter class init
    PIParameter pi_obj;
    initial begin
        pi_obj = new();
    end

// map pins between generic names and user names, if they are different
 

// Declare parameters
real gain;
real offset;

always @(*) begin

  gain = 0.0625*thm_sel_bld[0]+0.0625*thm_sel_bld[1]+0.0625*thm_sel_bld[2]+0.0625*thm_sel_bld[3]+0.0625*thm_sel_bld[4]+0.0625*thm_sel_bld[5]+0.0625*thm_sel_bld[6]+0.0625*thm_sel_bld[7]+0.0625*thm_sel_bld[8]+0.0625*thm_sel_bld[9]+0.0625*thm_sel_bld[10]+0.0625*thm_sel_bld[11]+0.0625*thm_sel_bld[12]+0.0625*thm_sel_bld[13]+0.0625*thm_sel_bld[14]+0.0625*thm_sel_bld[15];
  offset = pi_obj.td_mixermb*(1.0);

end

real wgt;
real td;
assign wgt = gain;
assign td = offset;

// fixed blender error by sjkim85 (3th May 2020) ------------------------------------------------
real rise_lead;
real rise_lag;
real fall_lead;
real fall_lag;
real rise_diff_in;
real fall_diff_in;
real ttotr;
real ttotf;
real flip;

    assign ph_and = ph_in[0]&ph_in[1];
    assign ph_or = ph_in[0]|ph_in[1];

    always @(posedge ph_in[0]) flip = ph_in[1];
    always @(negedge ph_in[0]) flip = ~ph_in[1];

    always @(posedge ph_or) begin
        rise_lead = $realtime/1s;
    end
    always @(posedge ph_and) begin
        rise_lag = $realtime/1s;
        rise_diff_in = rise_lag - rise_lead;
        ttotr = (flip+(1-2*flip)*wgt)*rise_diff_in + td + pi_obj.get_rj_mixermb() - rise_diff_in;
        ph_out <= #(ttotr*1s) 1'b1;
    end
    always @(negedge ph_and) begin
        fall_lead = $realtime/1s;
    end
    always @(negedge ph_or) begin
        fall_lag = $realtime/1s;
        fall_diff_in = fall_lag - fall_lead;
        ttotf = (flip+(1-2*flip)*wgt)*fall_diff_in + td + pi_obj.get_rj_mixermb() - fall_diff_in;
        ph_out <= #(ttotf*1s) 1'b0;
    end

//---------------------------------------------- ------------------------------------------------

endmodule

