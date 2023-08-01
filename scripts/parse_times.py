import sys
import os
import csv
import numpy
# import pandas as pd

results = {} # {testcase : {filename: {metric: value}}}
metrics = {'min': numpy.min, 'max': numpy.max, 'mean': numpy.mean, 'standard_dev': numpy.std, 'median': numpy.median, 'measurements': len}

def parse_time(l):
    # expected format: real	1m6,488s | real    44.98s
    # result: 66.501469803 | 44.98
    r = l.split()[-1] # take time
    m = float(r.split('m')[0]) if ('m' in r) else 0 # extract minute
    s = r.split('m')[1][:-1] if ('m' in r) else r.split('s')[0] # extract seconds, remove s
    s = float(s.replace(',', '.'))
    return (m * 60 + s)


def report_times(lines, filename):
    import re
    # match lines like:
    # benchmark - filename: 4096x4096x70.mrc
    # ignore lines like:
    # + echo benchmark - filename: 4096x4096x70.mrc
    p = re.compile('[^\+ echo].* - .*\:')
    times = {}
    skip_to_time = False
    label = ''
    for l in lines:
        if l.startswith('INFO:root:'):
            l = l.replace('INFO:root:', '') # Warp logging
        if l.startswith('real'):
            skip_to_time = False
            times[label].append(parse_time(l))
        if skip_to_time:
            continue
        if p.match(l):
            label = l
            skip_to_time = True
            if l not in times:
                times[l] = []
    
    for k in times:
        print(k.strip())
        for v in times[k]:
            print('{:.2f}'.format(v))
        
        def add_print(metric, value):
            tc = results.get(k.strip(), {})
            fn = tc.get(filename, {})
            m = fn.get(metric, {})
            fn = {**fn, **{metric : value}}
            tc = {**tc, **{filename: fn}}
            results[k.strip()] = tc
            print('{}: {:.2f}'.format(metric, value))

        for m in metrics:
            add_print(m, round(metrics[m](times[k]), 1))
        print('')


def report_errors(lines):
    for l in lines:
        lc = l.lower()
        if 'error' in lc or 'fail' in lc:
             # header of the autotuning or MotionCor2 report
            if (not lc.startswith('rank|placeness|type|data|') and not l.startswith('Iteration') 
                and not 'NewConnectionError' in l): # Warp still did not load
                print(l)
        if 'Output metadata:' in l or 'Aligned micrograph:' in l:
            file = l.split(':', 1)[-1].strip() # Aligned micrograph:    /home/david/experiments/flexalign_opt/XPS/phantom_movies/noisy/runtime/3838x3710x6_avg.mrc
            if not os.path.exists(file):
                print(file, "not found!")


def main():
    for file in sys.argv[1:]:    
        lines = []
        with open(file, 'r', errors='replace') as f:
            lines = f.readlines()
        report_times(lines, file)
        report_errors(lines)

    fields = [ 'file'] + list(metrics.keys())
    with open ('times.csv','w') as f:
        writer = csv.DictWriter(f, fields)
        for testcase in results:
            f.write('{}\n'.format(testcase.replace(',', ':')))
            writer.writeheader()
            tc = results[testcase]
            for k in tc:
                writer.writerow({field: tc[k].get(field) or k for field in fields})
            f.write('\n')

if __name__ == "__main__":
    main()
