from dragonphy import *
from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt
import yaml
import math
import shutil

def write_files(parameters, codes, weights, path="."):
    with open(path + '/' + "adapt_coeff.txt", "w+") as f:
        f.write("\n".join([str(int(w)) for w in weights]) + '\n')
    with open(path + '/' +  "adapt_codes.txt", "w+") as f:
        f.write("\n".join([str(int(c)) for c in codes]) + '\n')
    #f.write('mu: ' + str(parameters[2]) + '\n')

    #This is the most compatible way of writing for verilog - given its a fairly low level language

def write_weights_sv(weights, bitwidth, path="."):
    with open(path + '/' + 'weights_pack.sv', "w+") as f:
        f.write('package weights_pack;\n')
        f.write('logic signed [' + str(bitwidth) + '-1:0]  read_weights   [0:' + str(len(weights)) + '-1] = ')
        f.write('{' + ",".join([str(int(w)) for w in weights]) + '};\n')
        f.write('endpackage')

def deconvolve(weights, chan):
    plt.plot(chan(weights))
    plt.show()

def plot_adapt_input(codes, chan_out, n, plt_mode='normal'):
    if plt_mode == 'stem':
        plt.stem(codes[:n], markerfmt='C0o', basefmt='C0-')
        plt.stem(chan_out[:n], markerfmt='C1o', basefmt='C1-')
    else:
        plt.plot(codes[:n], 'o-')
        plt.plot(chan_out[:n], 'o-')
    plt.show()

def perform_wiener(ideal_input, chan, chan_out, M = 11, u = 0.1, pos=2, iterations=200000 ):
    adapt = Wiener(step_size = u, num_taps = M, cursor_pos=pos)
    for i in range(iterations-pos):
        adapt.find_weights_pulse(ideal_input[i-pos], chan_out[i])   
    

    print(f'Adapted Weights: {adapt.weights}')


    return adapt.weights

def execute_fir(ffe_config, quantized_weights, depth, quantized_chan_out):
    f = Fir(len(quantized_weights), quantized_weights, ffe_config["parameters"]["width"])
    
    # Only works when all channel weights are the same
    single_matrix = []
    for i in range(0, depth - len(quantized_weights) + 1, ffe_config["parameters"]["width"]):
        single_matrix.extend(f.single(quantized_chan_out, i).flatten())

    single_matrix = f(quantized_chan_out)
    # Works when all channel weights are different
    channel_matrix = f.channelized(quantized_chan_out)

    assert(compare(channel_matrix, single_matrix, length=500))
    # Format conv_matrix to match SV output
    return np.divide(np.array(single_matrix), 1)

def read_svfile(fname):
    with open(fname, "r") as f:
        f_lines = f.readlines()
        return np.array([int(x) for x in f_lines])

def convert_2s_comp(np_arr, width):
    signed_arr=[]
    for x in np_arr:
        if x - (2**(width-1)-1) > 0:
            x_new = x - (2**width)
            signed_arr.append(x_new)
        else:
            signed_arr.append(x)
    return signed_arr

def compare(arr1, arr2, arr2_trim=0, length=None, debug=False):
    equal = True
    arr2 = arr2[arr2_trim:-1]

    if debug:
        # Print out outputs
        print(f'Compare arr1: {arr1[:length]}')
        print(f'Compare arr2: {arr2[:length]}')

    min_len = min(len(arr1), len(arr2)) 
    length = min_len if length == None else min(min_len, length)

    for x in range(length):
        if arr1[x] != arr2[x]:
            equal = False
    return equal

def test_fir_main():
    module_name = 'fir'
    build_dir = 'tests/' + module_name + '/build_fir'
    pack_dir  = 'tests/' + module_name + '/pack'

    # Make the build directory
    Path(build_dir).mkdir(exist_ok=True) 

    system_config = Configuration('system')
    test_config   = Configuration('test_' + module_name, 'tests/' + module_name)
    tb_path = 'tests/' + module_name + '/test_' + module_name + '.sv'

    #Associate the correct build directory to the python collateral
    test_config['parameters']['ideal_code_filename'] = str(Path(build_dir + '/' + test_config['parameters']['ideal_code_filename']).resolve())
    test_config['parameters']['adapt_code_filename'] = str(Path(build_dir + '/' + test_config['parameters']['adapt_code_filename']).resolve())
    test_config['parameters']['adapt_coef_filename'] = str(Path(build_dir + '/' + test_config['parameters']['adapt_coef_filename']).resolve())
    test_config['parameters']['output_filename'] = str(Path(build_dir + '/' + test_config['parameters']['output_filename']).resolve())

    # Get config parameters from system.yml file
    ffe_config = system_config['generic']['ffe']

    # Number of iterations of Wiener Steepest Descent
    iterations  = 200000
    depth = 1000
    test_config['parameters']['num_of_codes'] = depth
    print(test_config['parameters'])
    # Cursor position with the most energy 
    pos = 2
    resp_len = 125

    ideal_codes = np.random.randint(2, size=iterations)*2 - 1

    chan = Channel(channel_type='dielectric1', normal='area', tau=0.87, sampl_rate=5, cursor_pos=pos, resp_depth=resp_len)
    chan_out = chan(ideal_codes)

    #plot_adapt_input(ideal_codes, chan_out, 100)
    qc = Quantizer(width=ffe_config["parameters"]["input_precision"], signed=True)
    quantized_chan_out = qc.quantize_2s_comp(chan_out)

    weights = []
    if ffe_config["adaptation"]["type"] == "wiener":
        weights = perform_wiener(ideal_codes, chan, chan_out, ffe_config['parameters']["length"], \
            ffe_config["adaptation"]["args"]["mu"], pos, iterations )
    else: 
        print(f'Do Nothing')

    quantized_chan_out = quantized_chan_out[300:300+depth]

    print(f'Quantized Chan: {quantized_chan_out}')
    print(f'Chan: {chan_out}')
    qw = Quantizer(width=ffe_config["parameters"]["weight_precision"], signed=True)
    quantized_weights = qw.quantize_2s_comp(weights)

    qffe_resp = Fir(len(quantized_weights), quantized_weights, ffe_config["parameters"]["width"]).impulse_response
    ffe_shift = FFEHelper(ffe_config, qffe_resp).calculate_shift(chan)
    system_config['generic']['parameters']['ffe_shift'] = ffe_shift
    print(ffe_shift)
    print(f'Weights: {weights}')
    print(f'Quantized Weights: {quantized_weights}')
    write_files([depth, ffe_config['parameters']["length"], ffe_config["adaptation"]["args"]["mu"]], quantized_chan_out, quantized_weights, build_dir)   
         
    #Create Package Generator Object 
    generic_packager   = Packager(package_name='constant', parameter_dict=system_config['generic']['parameters'], path=pack_dir)
    testbench_packager = Packager(package_name='test',     parameter_dict=test_config['parameters'], path=pack_dir)
    ffe_packager       = Packager(package_name='ffe',      parameter_dict=ffe_config['parameters'], path=pack_dir)

    #Create package file from parameters specified in system.yaml under generic
    generic_packager.create_package()
    testbench_packager.create_package()
    ffe_packager.create_package()

    write_weights_sv(quantized_weights, ffe_config["parameters"]["weight_precision"], path=pack_dir)        

    #Create TestBench Object
    tester   = Tester(
                        top 	  = 'test',
                        testbench = [tb_path],
                        libraries = ['src/flat_buffer/syn/flat_buffer.sv', 'src/flat_buffer/syn/buffer.sv', 'src/flat_buffer/syn/flatten_buffer.sv', 'src/fir/syn/comb_ffe.sv', 'src/fir/syn/flat_ffe.sv', 'verif/tb/beh/signed_recorder.sv'],
                        packages  = [generic_packager.path, testbench_packager.path, ffe_packager.path, pack_dir + '/weights_pack.sv'],
                        flags     = ['-sv', '-64bit', '+libext+.v', '+libext+.sv', '+libext+.vp'],
                        build_dir = build_dir,
                        overload_seed=True,
                        wave=True
                    )

    #Execute TestBench Object
    tester.run()

    #Packager.delete_pack_dir(path=pack_dir)

    #Execute ideal python FIR 
    py_arr = execute_fir(ffe_config, quantized_weights, depth, quantized_chan_out)
    py_arr = [int(np.floor(py_val/2**float(ffe_shift))) for py_val in py_arr]

    # Read in the SV results file
    sv_arr = read_svfile(build_dir + '/FFE_results.txt')

    sv_arr = convert_2s_comp(sv_arr, ffe_config["parameters"]["output_precision"])

    # Compare
    sv_trim = (3 + math.ceil((ffe_config["parameters"]["length"]-1)/ffe_config["parameters"]["width"]))* ffe_config["parameters"]["width"] - (ffe_config["parameters"]["length"]-1)

    # This trim needs to be fixed - I think the current approach is ""hacky""
    comp_len = math.floor((depth - ffe_config["parameters"]["length"] + 1) \
        /ffe_config["parameters"]["width"]) * ffe_config["parameters"]["width"]

    # Comparison
    result = compare(py_arr, sv_arr, sv_trim, 100, True)
    if result:
        print('TEST PASSED')
    else:
        print('TEST FAILED')
    assert(result)


# Used for testing 
if __name__ == "__main__":
    test_fir_main()