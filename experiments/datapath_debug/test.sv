`ifndef CHANNEL_TXT
    `define CHANNEL_TXT
`endif

`ifndef WEIGHT_TXT
    `define WEIGHT_TXT
`endif

class File #(
    parameter integer bitwidth=8,
    parameter integer depth   =10,
    parameter string file_name = "channel.txt",
    parameter type T = logic signed [bitwidth-1:0]
);
    static task load_array(output T values [depth-1:0]);
        integer ii, fid;
        fid = $fopen(file_name, "r");

        for(ii=0; ii < depth; ii=ii+1) begin
            $fscanf(fid, "%d", values[ii]);
        end

        $fclose(fid);
    endtask : load_array
endclass : File

class Broadcast #(
    parameter integer bitwidth=8,
    parameter integer width   =16,
    parameter integer depth   =10,
    parameter type T = logic signed [bitwidth-1:0]
    );

    static task all(input T broadcast_values [depth-1:0], output T broadcast_target [width-1:0][depth-1:0] );
        integer ii, jj;
        $display($typename(broadcast_values));
        for(ii=0; ii < width; ii=ii+1) begin
            for(jj =0; jj < depth; jj=jj+1) begin
                broadcast_target[ii][jj] = broadcast_values[jj];
            end
        end
    endtask : all
endclass : Broadcast

module test ();
    Broadcast #(
        channel_gpack::est_channel_precision,
        constant_gpack::channel_width, 
        channel_gpack::est_channel_depth
    ) broadcast_channel;

    Broadcast #(
        ffe_gpack::weight_precision, 
        constant_gpack::channel_width, 
        ffe_gpack::length
    ) broadcast_weights;

    File #(
        .bitwidth(channel_gpack::est_channel_precision), 
        .depth(channel_gpack::est_channel_depth),
        .file_name(`CHANNEL_TXT)
    ) file_channel;

    File #(
        .bitwidth(ffe_gpack::weight_precision),
        .depth(ffe_gpack::length),
        .file_name(`WEIGHT_TXT)
    ) file_weights;

    logic signed [constant_gpack::code_precision-1:0] adc_codes [constant_gpack::channel_width-1:0];
    logic signed [channel_gpack::est_channel_precision-1:0] channel_est [channel_gpack::est_channel_depth-1:0];
    logic signed [ffe_gpack::weight_precision-1:0] ffe_weights [ffe_gpack::length-1:0];
    logic bits [constant_gpack::channel_width-1:0];
    logic [15:0] prbs_flags;
    logic clk, rstb, start;


    weight_clock #(.period(1ns)) clk_gen (.clk(clk), .en(start));

    logic sliced_bits [constant_gpack::channel_width-1:0];
    logic signed [error_gpack::est_error_precision-1:0] est_error   [constant_gpack::channel_width-1:0];
    logic [1:0] sd_flags [constant_gpack::channel_width-1:0];

    dsp_debug_intf dsp_dbg_intf_i();
    datapath_core #(
        .ffe_pipeline_depth(constant_gpack::ffe_pipeline_depth), 
        .channel_pipeline_depth(constant_gpack::chan_pipeline_depth), 
        .error_output_pipeline_depth(constant_gpack::err_out_pipeline_depth), 
        .sliding_detector_output_pipeline_depth(constant_gpack::sld_dtct_out_pipeline_depth)
    ) dp_core_i (
        .adc_codes(adc_codes),
        .clk(clk),
        .rstb(rstb),
        .sliced_bits_out(sliced_bits),
        .est_errors_out(est_error),
        .sd_flags(sd_flags),
        .dsp_dbg_intf_i(dsp_dbg_intf_i)
    );

    error_tracker_debug_intf #(.addrwidth(12)) errt_dbg_intf_i();

    error_tracker #(
        .width(16),
        .error_bitwidth(error_gpack::est_error_precision),
        .addrwidth(12)
    ) errt_i (
        .prbs_flags(prbs_flags),
        .est_error(est_error),
        .sliced_bits(sliced_bits),
        .sd_flags(sd_flags),

        .clk(clk),
        .rstb(rstb),
        .errt_dbg_intf_i(errt_dbg_intf_i)
    );
    assign dsp_dbg_intf_i.align_pos = 0;
    genvar gi, gj;
    generate
        for(gi = 0; gi < constant_gpack::channel_width; gi = gi + 1) begin
            assign dsp_dbg_intf_i.ffe_shift[gi] = 0;
            assign dsp_dbg_intf_i.thresh[gi] = 0;

            assign dsp_dbg_intf_i.channel_shift[gi] = 0;
            for(gj = 0; gj < ffe_gpack::length; gj = gj + 1 ) begin
                assign dsp_dbg_intf_i.disable_product[gj][gi] = 0;
            end
        end
    endgenerate

    initial begin
        $shm_open("waves.shm"); $shm_probe("ASMC");
    end

    integer ii, jj;

    always_ff @(posedge clk or negedge rstb) begin
        if(~rstb) begin
            for(ii = 0; ii < constant_gpack::channel_width; ii = ii + 1) begin
                bits[ii] <= $signed(($urandom() % 2) ? 1: 0);
            end
        end else begin
            for(ii = 0; ii < constant_gpack::channel_width; ii = ii + 1) begin
                bits[ii] <= $signed(($urandom() % 2) ? 1 : 0);
            end
        end
    end


    localparam total_channel_bit_depth = constant_gpack::channel_width*(3);
    localparam actual_channel_bit_depth = constant_gpack::channel_width + channel_gpack::est_channel_depth - 2;
    
    logic bits_buffer [constant_gpack::channel_width-1:0][2:0];
    //Bits Pipeline
    buffer #(
        .numChannels (constant_gpack::channel_width),
        .bitwidth    (1),
        .depth       (2)
    ) bits_buff_i (
        .in      (bits),
        .clk     (clk),
        .rstb    (1),
        .buffer  (bits_buffer)
    );

    logic flat_bits [total_channel_bit_depth-1:0];
    flatten_buffer_slice #(
        .numChannels(constant_gpack::channel_width),
        .bitwidth   (1),
        .buff_depth (2),
        .slice_depth(2),
        .start      (0)
    ) ch_fb_i (
        .buffer    (bits_buffer),
        .flat_slice(flat_bits)
    );


    //Channel Filter
    logic signed [channel_gpack::est_code_precision-1:0] estimated_codes [constant_gpack::channel_width-1:0];
    channel_filter #(
        .width(constant_gpack::channel_width),
        .depth(channel_gpack::est_channel_depth),
        .shift_bitwidth(channel_gpack::shift_precision),
        .est_channel_bitwidth(channel_gpack::est_channel_precision),
        .est_code_bitwidth(channel_gpack::est_code_precision)
    ) chan_filt_i (
        .bitstream(flat_bits[total_channel_bit_depth-1:total_channel_bit_depth-1 - actual_channel_bit_depth]),
        .channel(dsp_dbg_intf_i.channel_est),
        .shift(dsp_dbg_intf_i.channel_shift),
        .est_code(adc_codes)
    );


    initial begin
        rstb = 0;
        start = 0;
        prbs_flags = 4'h0000;
        errt_dbg_intf_i.addr = 0;
        errt_dbg_intf_i.read = 0;
        errt_dbg_intf_i.enable = 0;
        $display(`CHANNEL_TXT);
        $display(`WEIGHT_TXT);
        
        file_channel.load_array(channel_est);
        file_weights.load_array(ffe_weights);

        broadcast_channel.all(channel_est, dsp_dbg_intf_i.channel_est);
        broadcast_weights.all(ffe_weights, dsp_dbg_intf_i.weights);
        start = 1;
        repeat (5) @(posedge clk);
        rstb = 1;
        repeat (3) @(posedge clk);
        prbs_flags = 16'h0101;
        repeat (2) @(posedge clk);
        prbs_flags = 16'h0000;
        repeat (10) @(posedge clk);
        prbs_flags = 16'h1010;
        repeat (3) @(posedge clk); 
        prbs_flags = 16'h0000;
        repeat (10) @(posedge clk);
        errt_dbg_intf_i.read = 1;
        @(posedge clk);
        errt_dbg_intf_i.addr = 0;
        @(posedge clk);
        errt_dbg_intf_i.addr = 1;
        @(posedge clk);
        errt_dbg_intf_i.addr = 2;
        prbs_flags = 16'h1010;
        @(posedge clk);
        errt_dbg_intf_i.addr = 3;
        prbs_flags = 16'h0000;
        repeat (10) @(posedge clk);
        errt_dbg_intf_i.read   = 0;
        errt_dbg_intf_i.enable = 1;
        repeat (5) @(posedge clk);
        prbs_flags = 16'h1010;
        repeat (1) @(posedge clk);
        prbs_flags = 16'h0000;
        repeat (10) @(posedge clk);
        $finish;
    end

endmodule : test

