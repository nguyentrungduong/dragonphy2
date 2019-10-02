from dragonphy import *

import numpy as np
import matplotlib.pyplot as plt
import yaml

def get_configs():
	f = open("../../config/system.yml", "r")
	system_info = yaml.load(f)
	return system_info["generic"]["ffe"]
 
def write_file(parameters, codes, weights):
	f = open("adapt_params.txt", "w+")
	f.write('code_len\n' + str(parameters[0]) + '\n')
	f.write('num_taps\n' + str(parameters[1]) + '\n')
	f.write('mu\n' + str(parameters[2]) + '\n')
	f.write('codes\n' + ",".join([str(c) for c in codes]) + '\n')
	f.write('weights\n' + ",".join([str(w) for w in weights]) + '\n')

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

def perform_wiener(ideal_input, chan, chan_out, M = 11, u = 0.1):

	adapt = Wiener(step_size = u, num_taps = M, cursor_pos=pos)
	for i in range(iterations-2):
		adapt.find_weights_pulse(ideal_codes[i-pos], chan_out[i])	
	
	pulse_weights = adapt.weights	
	for i in range(iterations-2):
		adapt.find_weights_error(ideal_codes[i-pos], chan_out[i])	
	
	pulse2_weights = adapt.find_weights_pulse2()

	print(pulse_weights)
	print(adapt.weights)
	print(pulse2_weights[-1])
	
	plt.plot(adapt.weights)
	plt.show()

	print(f'Filter input: {adapt.filter_in}')
	print(f'Weights: {adapt.weights}')
	write_file([iterations, M, u], ideal_codes, adapt.weights)	
	
	deconvolve(adapt.weights, chan)

	plt.plot(chan(np.reshape(pulse_weights, len(pulse_weights))))
	plt.plot(chan(pulse2_weights[-1]))
	plt.show()


# Used for testing 
if __name__ == "__main__":
	# Get config parameters from system.yml file
	ffe_configs = get_configs() 

	# Number of iterations of Wiener Steepest Descent
	iterations  = 200000
	# Cursor position with the most energy 
	pos = 2

	ideal_codes = np.random.randint(2, size=iterations)*2 - 1
	print(f'Ideal Code Sequence: {ideal_codes}')

	chan = Channel(channel_type='skineffect', normal='area', tau=2, sampl_rate=5, cursor_pos=pos, resp_depth=125)
	
	chan_out = chan(ideal_codes)
	print(f'Channel output: {chan_out}')

	plot_adapt_input(ideal_codes, chan_out, 100)

	print(ffe_configs)

	if ffe_configs["adaptation"]["type"] == "wiener":
		perform_wiener(ideal_codes, chan, chan_out, ffe_configs["length"], \
			ffe_configs["adaptation"]["args"]["mu"])
	else: 
		print(f'Do Nothing')
	
	