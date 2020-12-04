#!/usr/bin/env python3

from sys import argv
from matplotlib import pyplot as plt

data = []
points = [4, 8, 12, 16, 20]
#points = [4, 8, 12, 16, 20, 128]

for i in range(len(argv) - 1):
    with open(argv[i+1], 'r') as f:
        for line in f:
            pass
        timing=line.strip().split()   # just want the very last line
        data.append(int(timing[3]))

data1 = data[0:5]
data2 = data[6:11]

plt.plot(points, data1, label='with -initpopfn')
plt.plot(points, data1, 'bo')
plt.plot(points, data2, label='original code')
plt.plot(points, data2, 'ro')

#plt.plot(points, data)
#plt.plot(points, data, 'bo')
#plt.plot(points[:-1], data[:-1])
#plt.plot(points[:-1], data[:-1], 'bo')


plt.title('Time to dock 84K ligands with increasing number of GPUs')
plt.legend(loc='upper right')

axes = plt.gca()
axes.set_xlim([0, 24])
axes.set_ylim([0, 17000])

plt.xlabel('Number of GPUs')
plt.ylabel('Time (seconds)')

#plt.show()
plt.savefig('out.png')

