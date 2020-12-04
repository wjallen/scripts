#!/usr/bin/env python3

from sys import argv
import numpy as np
from matplotlib import pyplot as plt

data = []
#names = argv[1:]
names = ['GPUs=4', 'GPUs=8', 'GPUs=12', 'GPUs=16', 'GPUs=20']
bins = np.arange(0, 5, 0.025)
xlimit = 4
ylimit = 15000

for i in range(len(argv) - 1):
    data.append([])
    with open(argv[i+1], 'r') as f:
        for line in f:
            data[i].append(float(line.strip()))

plt.hist(data, bins, histtype='step', stacked=False, label=names)

plt.title('Distribution of docking times for 84K ligands\nwhen each GPU uses unique initpop file')
#plt.title('Distribution of docking times for 84K ligands\n when all GPUs share "initpop.txt"')
plt.xlabel('Time (seconds)')
plt.ylabel('Count')
plt.legend(loc='upper right')

axes = plt.gca()
axes.set_xlim([0, xlimit])
axes.set_ylim([0, ylimit])

#plt.show()
plt.savefig('out.png')

