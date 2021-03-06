from argparse import ArgumentParser

from dragonphy import BuildGraph

def create_fpga_graph():
    graph = BuildGraph('fpga')

    # Configs
    graph.add_config('system', folders=['config'])
    graph.add_config('jtag_config', folders=['config'])
    graph.add_config('chan', folders=['config', 'fpga'])
    graph.add_config('analog_slice_cfg', folders=['config', 'fpga'])
    graph.add_config('osc_model', folders=['config', 'fpga'])
    graph.add_config('rx_adc', folders=['config', 'fpga'])
    graph.add_config('tx', folders=['config', 'fpga'])
    graph.add_config('clk_delay', folders=['config', 'fpga'])

    # Dependencies
    graph.add_input('acore_intf', ext='md', folders=['md'])
    graph.add_input('cdr_intf', ext='md', folders=['md'])
    graph.add_input('dcore_intf', ext='md', folders=['md'])
    graph.add_input('hist_intf', ext='md', folders=['md'])
    graph.add_input('mdll_r1_top_intf', ext='md', folders=['md'])
    graph.add_input('prbs_intf', ext='md', folders=['md'])
    graph.add_input('error_intf', ext='md', folders=['md'])
    graph.add_input('sm_ffe_intf', ext='md', folders=['md'])
    graph.add_input('sram_multi_intf', ext='md', folders=['md'])
    graph.add_input('txdata_intf', ext='md', folders=['md'])
    graph.add_input('tx_intf', ext='md', folders=['md'])
    graph.add_input('wme_intf', ext='md', folders=['md'])

    # Scripts
    graph.add_python('adapt_fir', 'adapt_fir', 'AdaptFir', view='chip_src',
                     folders=['dragonphy'], configs={'system'})
    graph.add_python('jtag', 'jtag', 'JTAG', view='all',
                     folders=['dragonphy'],
                     configs={'jtag_config'},
                     sources={'acore_intf', 'cdr_intf', 'dcore_intf',
                              'hist_intf', 'mdll_r1_top_intf',
                              'prbs_intf', 'sm_ffe_intf',
                              'sram_multi_intf', 'txdata_intf',
                              'tx_intf', 'wme_intf'})
    graph.add_python('chan_core', 'chan_core', 'ChannelCore', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], sources={'adapt_fir'},
                     configs={'chan'})
    graph.add_python('analog_slice', 'analog_slice', 'AnalogSlice', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], sources={'adapt_fir'},
                     configs={'analog_slice_cfg'})
    graph.add_python('osc_model_core', 'osc_model_core', 'OscModelCore', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], configs={'osc_model'})
    graph.add_python('rx_adc_core', 'rx_adc_core', 'RXAdcCore', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], configs={'rx_adc'})
    graph.add_python('tx_core', 'tx_core', 'TXCore', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], configs={'tx'})
    graph.add_python('clk_delay_core', 'clk_delay_core', 'ClkDelayCore', view='fpga_models',
                     folders=['dragonphy', 'fpga_models'], configs={'clk_delay'})

    return graph


def create_asic_graph():
    graph = BuildGraph('asic')

    # Configs
    graph.add_config('system', folders=['config'])
    graph.add_config('jtag_config', folders=['config'])

    # Dependencies
    graph.add_input('acore_intf', ext='md', folders=['md'])
    graph.add_input('cdr_intf', ext='md', folders=['md'])
    graph.add_input('dcore_intf', ext='md', folders=['md'])
    graph.add_input('hist_intf', ext='md', folders=['md'])
    graph.add_input('mdll_r1_top_intf', ext='md', folders=['md'])
    graph.add_input('prbs_intf', ext='md', folders=['md'])
    graph.add_input('error_intf', ext='md', folders=['md'])
    graph.add_input('sm_ffe_intf', ext='md', folders=['md'])
    graph.add_input('sram_multi_intf', ext='md', folders=['md'])
    graph.add_input('txdata_intf', ext='md', folders=['md'])
    graph.add_input('tx_intf', ext='md', folders=['md'])
    graph.add_input('wme_intf', ext='md', folders=['md'])

    # Scripts
    graph.add_python('adapt_fir', 'adapt_fir', 'AdaptFir', view='chip_src',
                     folders=['dragonphy'], configs={'system'})
    graph.add_python('jtag', 'jtag', 'JTAG', view='all',
                     folders=['dragonphy'], 
                     configs={'jtag_config'},
                     sources={'acore_intf', 'cdr_intf', 'dcore_intf',
                              'hist_intf', 'mdll_r1_top_intf',
                              'prbs_intf', 'sm_ffe_intf',
                              'sram_multi_intf', 'txdata_intf',
                              'tx_intf', 'wme_intf'})

    return graph


def create_cpu_graph():
    graph = BuildGraph('chip_src')

    # Configs
    graph.add_config('system', folders=['config'])
    graph.add_config('jtag_config', folders=['config'])

    # Dependencies
    graph.add_input('acore_intf', ext='md', folders=['md'])
    graph.add_input('cdr_intf', ext='md', folders=['md'])
    graph.add_input('dcore_intf', ext='md', folders=['md'])
    graph.add_input('hist_intf', ext='md', folders=['md'])
    graph.add_input('mdll_r1_top_intf', ext='md', folders=['md'])
    graph.add_input('prbs_intf', ext='md', folders=['md'])
    graph.add_input('error_intf', ext='md', folders=['md'])
    graph.add_input('sm_ffe_intf', ext='md', folders=['md'])
    graph.add_input('sram_multi_intf', ext='md', folders=['md'])
    graph.add_input('txdata_intf', ext='md', folders=['md'])
    graph.add_input('tx_intf', ext='md', folders=['md'])
    graph.add_input('wme_intf', ext='md', folders=['md'])

    # Scripts
    graph.add_python('adapt_fir', 'adapt_fir', 'AdaptFir', view='chip_src',
                     folders=['dragonphy'], configs={'system'})
    graph.add_python('jtag', 'jtag', 'JTAG', view='all',
                     folders=['dragonphy'], 
                     configs={'jtag_config'},
                     sources={'acore_intf', 'cdr_intf', 'dcore_intf',
                              'hist_intf', 'mdll_r1_top_intf',
                              'prbs_intf', 'sm_ffe_intf',
                              'sram_multi_intf', 'txdata_intf',
                              'tx_intf', 'wme_intf'})

    return graph


def main():
    parser = ArgumentParser()

    parser.add_argument('-v', '--view', type=str, default=None)
    parser.add_argument('--visualize', type=str, default=None)
    
    cmd_inputs = parser.parse_args()

    if cmd_inputs.view == "fpga":
        graph = create_fpga_graph()
    elif cmd_inputs.view == "asic":
        graph = create_asic_graph()
    elif cmd_inputs.view == "cpu":
        graph = create_cpu_graph()
    else:
        print('Unknown View, View set to CPU')
        graph = create_cpu_graph()

    if cmd_inputs.visualize:
        graph.visualize(cmd_inputs.visualize)

    graph.build()


if __name__ == "__main__":
    main()
