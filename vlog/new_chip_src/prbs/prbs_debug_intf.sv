interface prbs_debug_intf;

	import const_pack::*;

    logic prbs_cke;
    logic [(Nprbs-1):0] prbs_eqn;
    logic [(Nti-1):0] prbs_chan_sel;
    logic [1:0] prbs_inv_chicken;
    logic [1:0] prbs_checker_mode;

    logic [31:0] prbs_error_bits_upper;
    logic [31:0] prbs_error_bits_lower;
    logic [31:0] prbs_total_bits_upper;
    logic [31:0] prbs_total_bits_lower;

    modport prbs (
        input prbs_cke,
        input prbs_eqn,
        input prbs_chan_sel,
        input prbs_inv_chicken,
        input prbs_checker_mode,
        output prbs_error_bits_upper,
        output prbs_error_bits_lower,
        output prbs_total_bits_upper,
        output prbs_total_bits_lower
    );

    modport jtag (
        output prbs_cke,
        output prbs_eqn,
        output prbs_chan_sel,
        output prbs_inv_chicken,
        output prbs_checker_mode,
        input prbs_error_bits_upper,
        input prbs_error_bits_lower,
        input prbs_total_bits_upper,
        input prbs_total_bits_lower
    );
endinterface
