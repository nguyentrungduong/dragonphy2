// dragon uses rx_adc flat_ffe flat_buffer

`include "signals.sv"

module rx #(
    parameter integer n_del=3
) (
    `ANALOG_INPUT data_ana_i,
    input wire logic rstb,
    output wire logic clk_o,
    output wire logic data_o
);

    // Import packages needed for FFE
    import weights_pack::*; 
    import constant_gpack::*;

    // instantiate the clock
    osc_model rx_clk_i (
        .clk_o(clk_o)
    );
    
    // instantiate the ADC
    // FIXME: Fix this hack for channelized interface
    logic signed [7:0] adc_o [0:0];
    rx_adc rx_adc_i (
        .in(data_ana_i),
        .out(adc_o[0]),
        .clk(clk_o)
    );

    // instantiate the FFE
    logic signed [ffe_gpack::output_precision-1:0]  ffe_o  	        [ffe_gpack::width-1:0];
    logic signed [ffe_gpack::weight_precision-1:0]  weights        [ffe_gpack::length-1:0][ffe_gpack::width-1:0];
    logic [ffe_gpack::shift_precision-1:0] shift_default = ffe_shift;
    logic [ffe_gpack::shift_precision-1:0] shift_index  [ffe_gpack::width-1:0];

    flat_ffe #(
        .ffeDepth(ffe_gpack::length),
        .numChannels(ffe_gpack::width),
        .codeBitwidth(ffe_gpack::input_precision),
        .weightBitwidth(ffe_gpack::weight_precision),
        .resultBitwidth(ffe_gpack::output_precision),
        .shiftBitwidth   (ffe_gpack::shift_precision )
    ) ffe_inst (
        .clk(clk_o),
        // TODO: fixme
        .rstb(rstb),
        .new_shift_index(shift_index),
        .new_weights(weights),
        .codes      (adc_o),
        .results    (ffe_o)
    );

    // initialize weights and shift_index
    genvar gi,gj;    
    generate
        for(gi=0; gi<ffe_gpack::length; gi=gi+1) begin
            for(gj=0; gj<ffe_gpack::width; gj=gj+1) begin
                assign weights[gi][gj] = read_weights[gi];
            end
        end
        for(gj=0;gj<ffe_gpack::width;gj=gj+1) begin
            assign shift_index[gj] = shift_default;
        end
    endgenerate 

    // create digital comparator
    logic cmp_o [ffe_gpack::width-1:0];
    generate
        for (gi=0; gi<ffe_gpack::width;gi+=1) begin
            assign cmp_o[gi] = (ffe_o[gi] > 0) ? 1'b1 : 1'b0;
        end
    endgenerate

    // sample comparator output
    assign data_o = cmp_o[0];

endmodule