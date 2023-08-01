import sys
import os
import numpy as np
import subprocess

to_process = []

def generate_plot(path, group, ref_val, pixel_size):
    # expected filename format:
    # dir_path/sw_moviename_avg_psd.txt
    filename = path.split(os.sep)[-1]
    dir = path.split(os.sep)[:-1]
    suffix = filename.split('_', 1)[1] # sw_moviename_avg_psd.txt
    plot = suffix.replace('.txt', '.plot')
    script = path.replace(filename, plot)
    with open(script, 'w') as f:
        f.write('''
set term pngcairo enhanced size 1000, 600
set output "{}"
unset colorbox


set xlabel "Spatial Frequency (1/A)"
show xlabel
set ylabel "PSD (Log_{{10}})"
show ylabel
set key right top
set autoscale

plot \
'''.format(script.replace('.plot', '.png')))
        for i, fn in enumerate(group):
            # expected file format:
            # sw_moviename_avg_psd.txt
            program = fn.split('_', 1)[0].capitalize()
            psd = os.path.join(*dir, fn)
            psd = "/" + psd
            offset = find_max(psd) - ref_val
            window_size = int(384*pixel_size)
            f.write('"{}" u ($0/{}):($1 - {}):({}) w l palette title "{}",\\\n'.format(psd, window_size, offset, i, program)) # CHANGE

    return script

def find_max(filename):
    with open(filename, 'r') as f:
        values = np.array([l for l in (line.strip() for line in f) if l]) # get rid of EOF and empty lines
        values = values.astype(np.float)
        return np.max(values)


def generate_psd(dir, filename, pixel_size):
    # expected filename format:
    # sw_moviename_avg_psd.txt
    suffix = filename.split('_', 1)[1] # moviename_avg_psd.txt
    group = [f for f in to_process if f.endswith(suffix)]
    group.sort()
    to_process[:] = [f for f in to_process if f not in group]
    ref_val = find_max(os.path.join(dir, group[0]))
    script = generate_plot(os.path.join(dir, filename), group, ref_val, pixel_size)
    subprocess.run(['gnuplot', '-p', script], stderr=subprocess.DEVNULL)

def main():
    dir = sys.argv[1]
    pixel_size = float(sys.argv[2])
    to_process[:] = [f for f in os.listdir(dir) if f.endswith('_avg_psd.txt')]
    while to_process:
        generate_psd(dir, to_process[0], pixel_size)

if __name__ == "__main__":
    main()
