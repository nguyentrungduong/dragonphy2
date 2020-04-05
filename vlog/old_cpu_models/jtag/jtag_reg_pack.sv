package jtag_reg_pack;
    // Domain: tc
    localparam integer en_v2t = 4096; // Writeable: True
    localparam integer en_slice = 4100; // Writeable: True
    localparam integer ALWS_ON = 4104; // Writeable: True
    localparam integer sel_clk_TDC = 4108; // Writeable: True
    localparam integer en_pm = 4112; // Writeable: True
    localparam integer en_v2t_clk_next = 4116; // Writeable: True
    localparam integer en_sw_test = 4120; // Writeable: True
    localparam integer en_gf = 4124; // Writeable: True
    localparam integer en_arb_pi = 4128; // Writeable: True
    localparam integer en_delay_pi = 4132; // Writeable: True
    localparam integer en_ext_Qperi = 4136; // Writeable: True
    localparam integer en_pm_pi = 4140; // Writeable: True
    localparam integer en_cal_pi = 4144; // Writeable: True
    localparam integer disable_state = 4148; // Writeable: True
    localparam integer en_clk_sw = 4152; // Writeable: True
    localparam integer en_meas_pi = 4156; // Writeable: True
    localparam integer sel_meas_pi = 4160; // Writeable: True
    localparam integer en_slice_rep = 4164; // Writeable: True
    localparam integer ALWS_ON_rep = 4168; // Writeable: True
    localparam integer sel_clk_TDC_rep = 4172; // Writeable: True
    localparam integer en_pm_rep = 4176; // Writeable: True
    localparam integer en_v2t_clk_next_rep = 4180; // Writeable: True
    localparam integer en_sw_test_rep = 4184; // Writeable: True
    localparam integer sel_pfd_in = 4188; // Writeable: True
    localparam integer sel_pfd_in_meas = 4192; // Writeable: True
    localparam integer en_pfd_inp_meas = 4196; // Writeable: True
    localparam integer en_pfd_inn_meas = 4200; // Writeable: True
    localparam integer sel_del_out = 4204; // Writeable: True
    localparam integer disable_ibuf_async = 4208; // Writeable: True
    localparam integer disable_ibuf_aux = 4212; // Writeable: True
    localparam integer disable_ibuf_test0 = 4216; // Writeable: True
    localparam integer disable_ibuf_test1 = 4220; // Writeable: True
    localparam integer en_inbuf = 4224; // Writeable: True
    localparam integer sel_inbuf_in = 4228; // Writeable: True
    localparam integer bypass_inbuf_div = 4232; // Writeable: True
    localparam integer inbuf_ndiv = 4236; // Writeable: True
    localparam integer en_inbuf_meas = 4240; // Writeable: True
    localparam integer en_biasgen = 4244; // Writeable: True
    localparam integer sel_del_out_pi = 4248; // Writeable: True
    localparam integer en_del_out_pi = 4252; // Writeable: True
    localparam integer pd_offset_ext = 4256; // Writeable: True
    localparam integer i_val = 4260; // Writeable: True
    localparam integer p_val = 4264; // Writeable: True
    localparam integer en_ext_pi_ctl_cdr = 4268; // Writeable: True
    localparam integer ext_pi_ctl_cdr = 4272; // Writeable: True
    localparam integer en_ext_pfd_offset = 4276; // Writeable: True
    localparam integer en_ext_pfd_offset_rep = 4280; // Writeable: True
    localparam integer en_ext_max_sel_mux = 4284; // Writeable: True
    localparam integer en_pfd_cal = 4288; // Writeable: True
    localparam integer en_pfd_cal_rep = 4292; // Writeable: True
    localparam integer Navg_adc = 4296; // Writeable: True
    localparam integer Nbin_adc = 4300; // Writeable: True
    localparam integer DZ_hist_adc = 4304; // Writeable: True
    localparam integer Navg_adc_rep = 4308; // Writeable: True
    localparam integer Nbin_adc_rep = 4312; // Writeable: True
    localparam integer DZ_hist_adc_rep = 4316; // Writeable: True
    localparam integer Ndiv_clk_avg = 4320; // Writeable: True
    localparam integer Ndiv_clk_cdr = 4324; // Writeable: True
    localparam integer int_rstb = 4328; // Writeable: True
    localparam integer sram_rstb = 4332; // Writeable: True
    localparam integer cdr_rstb = 4336; // Writeable: True
    localparam integer sel_outbuff = 4340; // Writeable: True
    localparam integer sel_trigbuff = 4344; // Writeable: True
    localparam integer en_outbuff = 4348; // Writeable: True
    localparam integer en_trigbuff = 4352; // Writeable: True
    localparam integer Ndiv_outbuff = 4356; // Writeable: True
    localparam integer Ndiv_trigbuff = 4360; // Writeable: True
    localparam integer bypass_out = 4364; // Writeable: True
    localparam integer bypass_trig = 4368; // Writeable: True
    localparam integer in_addr = 4372; // Writeable: True
    localparam integer ctl_v2tn [16] = '{4608, 4612, 4616, 4620, 4624, 4628, 4632, 4636, 4640, 4644, 4648, 4652, 4656, 4660, 4664, 4668}; // Writeable: True
    localparam integer ctl_v2tp [16] = '{4864, 4868, 4872, 4876, 4880, 4884, 4888, 4892, 4896, 4900, 4904, 4908, 4912, 4916, 4920, 4924}; // Writeable: True
    localparam integer init [16] = '{5120, 5124, 5128, 5132, 5136, 5140, 5144, 5148, 5152, 5156, 5160, 5164, 5168, 5172, 5176, 5180}; // Writeable: True
    localparam integer sel_pm_sign [16] = '{5376, 5380, 5384, 5388, 5392, 5396, 5400, 5404, 5408, 5412, 5416, 5420, 5424, 5428, 5432, 5436}; // Writeable: True
    localparam integer sel_pm_in [16] = '{5632, 5636, 5640, 5644, 5648, 5652, 5656, 5660, 5664, 5668, 5672, 5676, 5680, 5684, 5688, 5692}; // Writeable: True
    localparam integer ctl_dcdl_late [16] = '{5888, 5892, 5896, 5900, 5904, 5908, 5912, 5916, 5920, 5924, 5928, 5932, 5936, 5940, 5944, 5948}; // Writeable: True
    localparam integer ctl_dcdl_early [16] = '{6144, 6148, 6152, 6156, 6160, 6164, 6168, 6172, 6176, 6180, 6184, 6188, 6192, 6196, 6200, 6204}; // Writeable: True
    localparam integer ctl_dcdl_TDC [16] = '{6400, 6404, 6408, 6412, 6416, 6420, 6424, 6428, 6432, 6436, 6440, 6444, 6448, 6452, 6456, 6460}; // Writeable: True
    localparam integer ext_Qperi [4] = '{6656, 6660, 6664, 6668}; // Writeable: True
    localparam integer sel_pm_sign_pi [4] = '{6912, 6916, 6920, 6924}; // Writeable: True
    localparam integer del_inc [4] = '{7168, 7172, 7176, 7180}; // Writeable: True
    localparam integer ctl_dcdl_slice [4] = '{7424, 7428, 7432, 7436}; // Writeable: True
    localparam integer ctl_dcdl_sw [4] = '{7680, 7684, 7688, 7692}; // Writeable: True
    localparam integer ctl_v2tn_rep [2] = '{7936, 7940}; // Writeable: True
    localparam integer ctl_v2tp_rep [2] = '{8192, 8196}; // Writeable: True
    localparam integer init_rep [2] = '{8448, 8452}; // Writeable: True
    localparam integer sel_pm_sign_rep [2] = '{8704, 8708}; // Writeable: True
    localparam integer sel_pm_in_rep [2] = '{8960, 8964}; // Writeable: True
    localparam integer ctl_dcdl_late_rep [2] = '{9216, 9220}; // Writeable: True
    localparam integer ctl_dcdl_early_rep [2] = '{9472, 9476}; // Writeable: True
    localparam integer ctl_dcdl_TDC_rep [2] = '{9728, 9732}; // Writeable: True
    localparam integer ctl_biasgen [4] = '{9984, 9988, 9992, 9996}; // Writeable: True
    localparam integer ext_pi_ctl_offset [4] = '{10240, 10244, 10248, 10252}; // Writeable: True
    localparam integer ext_pfd_offset [16] = '{10496, 10500, 10504, 10508, 10512, 10516, 10520, 10524, 10528, 10532, 10536, 10540, 10544, 10548, 10552, 10556}; // Writeable: True
    localparam integer ext_pfd_offset_rep [2] = '{10752, 10756}; // Writeable: True
    localparam integer ext_max_sel_mux [4] = '{11008, 11012, 11016, 11020}; // Writeable: True

    // Domain: sc
    localparam integer cal_out_pi = 4096; // Writeable: False
    localparam integer addr = 4100; // Writeable: False
    localparam integer pm_out [16] = '{4608, 4612, 4616, 4620, 4624, 4628, 4632, 4636, 4640, 4644, 4648, 4652, 4656, 4660, 4664, 4668}; // Writeable: False
    localparam integer pm_out_pi [4] = '{4864, 4868, 4872, 4876}; // Writeable: False
    localparam integer Qperi [4] = '{5120, 5124, 5128, 5132}; // Writeable: False
    localparam integer max_sel_mux [4] = '{5376, 5380, 5384, 5388}; // Writeable: False
    localparam integer pm_out_rep [2] = '{5632, 5636}; // Writeable: False
    localparam integer adcout_avg [16] = '{5888, 5892, 5896, 5900, 5904, 5908, 5912, 5916, 5920, 5924, 5928, 5932, 5936, 5940, 5944, 5948}; // Writeable: False
    localparam integer adcout_sum [16] = '{6144, 6148, 6152, 6156, 6160, 6164, 6168, 6172, 6176, 6180, 6184, 6188, 6192, 6196, 6200, 6204}; // Writeable: False
    localparam integer adcout_hist_center [16] = '{6400, 6404, 6408, 6412, 6416, 6420, 6424, 6428, 6432, 6436, 6440, 6444, 6448, 6452, 6456, 6460}; // Writeable: False
    localparam integer adcout_hist_side [16] = '{6656, 6660, 6664, 6668, 6672, 6676, 6680, 6684, 6688, 6692, 6696, 6700, 6704, 6708, 6712, 6716}; // Writeable: False
    localparam integer pfd_offset [16] = '{6912, 6916, 6920, 6924, 6928, 6932, 6936, 6940, 6944, 6948, 6952, 6956, 6960, 6964, 6968, 6972}; // Writeable: False
    localparam integer adcout_avg_rep [2] = '{7168, 7172}; // Writeable: False
    localparam integer adcout_sum_rep [2] = '{7424, 7428}; // Writeable: False
    localparam integer adcout_hist_center_rep [2] = '{7680, 7684}; // Writeable: False
    localparam integer adcout_hist_side_rep [2] = '{7936, 7940}; // Writeable: False
    localparam integer pfd_offset_rep [2] = '{8192, 8196}; // Writeable: False
    localparam integer out_data [18] = '{8448, 8452, 8456, 8460, 8464, 8468, 8472, 8476, 8480, 8484, 8488, 8492, 8496, 8500, 8504, 8508, 8512, 8516}; // Writeable: False

endpackage
