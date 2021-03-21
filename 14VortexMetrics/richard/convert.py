from scipy.io import savemat
import numpy as np
import glob
import os
npzFiles = glob.glob("*.npy")
for f in npzFiles:
    print(f)
    fm = os.path.splitext(f)[0]+'.mat'
    d = np.load(f)
    savemat(fm, {"D":d})
    print('generated ', fm, 'from', f)