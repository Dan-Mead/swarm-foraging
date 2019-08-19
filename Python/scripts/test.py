import numpy as np

heading = 125
bearing = 70

def d2r(d):

    return d * np.pi/180

def r2d(r):

    return r * 180/np.pi


h = d2r(heading)
b = d2r(bearing)

d = (h + np.pi) + np.pi/4 * np.sin(h - b)

if abs(d) > np.pi:
    d = d - np.sign(d) * 2 * np.pi

direction = r2d(d)



print(direction)