import matplotlib.pyplot as plt
import numpy as np
import xmippLib as xmipp
import matplotlib.style as style
import os
import pandas as pd
import copy
import itertools
from scipy import stats

machine = "MACHINE"
programs = ['cryosparc', 'flexalign', 'motioncorr', 'relion', 'warp']
CONFIDENCE_LEVEL = 0.05
headers = ["FILE", "MIC", "PROGRAM", "ENTRY"]

def normalizeImage(data):
    mean_value = np.mean(data)
    std_value = np.std(data)
    return (data - mean_value) / std_value

def do_Kolmogorov_Smirnov_test(file1, file2):
    data1 = xmipp.Image(file1).getData()
    data2 = xmipp.Image(file2).getData()
    data1_normalized = normalizeImage(data1)
    data2_normalized = normalizeImage(data2)
    print(np.shape(data1))
    print(np.shape(data2))

    ks_statistic, p_value = stats.ks_2samp(data1_normalized.flatten(), data2_normalized.flatten())

    if p_value < CONFIDENCE_LEVEL:
        print("REJECT HO, the two datasets come from different distributions")


def paired_Kolmogorov_Smirnovs(listFiles, file):
    print("Do paired Kolmogorov for %s" % file)
    combinations = list(itertools.combinations(listFiles, 2))
    print('Number of possible pairs', str(len(combinations)))
    for file1, file2 in combinations:
        do_Kolmogorov_Smirnov_test(file1, file2)


# ------------------------ MAIN PROGRAM -----------------------------
if __name__ == "__main__":
    resultsPath = os.path.join(os.path.dirname(os.getcwd()), os.getenv(machine))

    resultsEmpiar = os.path.join(resultsPath, "empiar_movies")
    pattern = '^(\w)'
    dict_Res = {}

    results=[]
    for folder in os.listdir(resultsEmpiar):
        folder_path = os.path.join(resultsEmpiar, folder)
        for file in os.listdir(folder_path):
            if file.endswith(".mrc"):
                program = file[:file.find("_")]
                mic = file[file.find("_"):]
                pathFile = os.path.join(folder_path, file)
                results.append([pathFile, mic, program, folder])

    df = pd.DataFrame(results, columns=headers)
    grouped = df.groupby("MIC")

    for name, data in grouped:
        print()
        print(f"Group: {name}")
        print(data)

        # Prepare data for individual t-tests
        paired_Kolmogorov_Smirnovs(data['FILE'].tolist(), name)




    # print(group_data_dicts)
    # # Read data from the .txt file
    # data_file = '/home/dmarchan/AlignmentPaper_delete/galileoShadow/empiar_movies/10288/warp_CB1__00004_Feb18_23.33.18_avg.mrc'
