import os
import pandas as pd
import scipy.stats as stats
import itertools
import copy
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.style as style


machine = "MACHINE"
headers = ["PROGRAM", "RESOLUTION", "FILE"]
programs = ['cryosparc', 'flexalign', 'motioncorr', 'relion', 'warp']
CONFIDENCE_LEVEL = 0.05

def anovaTest(group_data, file, entry):
    print("do ANOVA TEST for %s and entry %s" % (file, entry))
    # print(group_data)

    print(' CHECK Normality on the data')
    for i, group in enumerate(group_data):
        stat, p_norm = stats.shapiro(group)
        print(" Group", programs[i], "Shapiro-Wilk p-value:", p_norm)

    print(' Check Homogeneity of variance')
    stat, p_hvar = stats.levene(*group_data)
    print(" Levene's test p-value:", p_hvar)

    f_statistic, p_value = stats.f_oneway(*group_data)
    print("ANOVA p-value:", p_value)
    if p_value < CONFIDENCE_LEVEL:
        print("     SIGNIFICANT DIFFERENCE BETWEEN MEANs")

def do_paired_test(dict1, dict2):
    (key1, data1) = dict1.popitem()
    (key2, data2) = dict2.popitem()
    print('Comparing %s and %s' % (key1, key2))
    differences = np.array(data1) - np.array(data2)
    # NORMALITY TEST
    print(" CHECK Normality on the data")
    stat, p_norm = stats.shapiro(differences)
    print(" Shapiro-Wilk p-value:", p_norm)
    # HOMOGENEITY OF VARIANCE
    print(' Check Homogeneity of variance')
    stat, p_hvar = stats.levene(data1, data2)
    print(" Levene's test p-value:", p_hvar)
    # PERFORM PAIRED T-TEST
    t_statistic, p_value = stats.ttest_rel(data1, data2)
    mean1 = np.mean(data1)
    mean2 = np.mean(data2)
    print("     PAIRED T-TEST p-value: %f    mean1: %f  mean2: %f" % (p_value, mean1, mean2))
    if p_value < CONFIDENCE_LEVEL:
        print("     SIGNIFICANT DIFFERENCE BETWEEN MEANs")
    print('--------------------------')



def paired_t_tests(dataDicts, file, entry):
    print("do paired t-TEST for %s and entry %s" % (file, entry))
    combinations = list(itertools.combinations(dataDicts, 2))
    print('Number of possible pairs', str(len(combinations)))
    for dict1, dict2 in combinations:
        dict1_copy = copy.copy(dict1)
        dict2_copy = copy.copy(dict2)
        do_paired_test(dict1_copy, dict2_copy)

def plotBarplots(dataDicts, file, entry, dirOut):
    mean_values = []
    std_values = []
    keys = []
    cmap = 'Set1'
    program = file[:file.find("_")]

    for dictData in dataDicts:
        (key, data) = dictData.popitem()
        std_values.append(np.std(data))
        mean_values.append(np.mean(data))
        keys.append(key)

    # Create a bar plot
    plt.figure()
    style.use('ggplot')
    plt.bar(keys, mean_values, yerr=std_values, capsize=5, color=plt.get_cmap(cmap).colors)
    # Add extra space in the y-axis
    padding = 3.3  # Adjust the padding as desired
    y_max = max(mean_values) + padding
    plt.ylim(0, y_max)
    # Add labels and title
    plt.xlabel('Programs')
    plt.ylabel('Critical resolution (A)')
    title = entry + ' ' + program + " ctf estimation"
    plt.title(title)

    # Show the plot
    figName = entry + '_' + program + '_histogram_summary.jpeg'
    plt.savefig(os.path.join(dirOut, figName))
    # plt.show()






if __name__ == "__main__":
    resultsPath = os.path.join(os.path.dirname(os.getcwd()), os.getenv(machine))
    resultsEmpiar = os.path.join(resultsPath, "empiar_movies")
    pattern = '^(\w)'
    dict_Res = {}


    for folder in os.listdir(resultsEmpiar):
        folder_path = os.path.join(resultsEmpiar, folder)
        for file in os.listdir(folder_path):
            if file.endswith("freq_summary.txt"):
                temp = {}
                print("\n" + file)
                df = pd.read_csv(os.path.join(folder_path, file), delimiter="\t", header=None, names=headers)
                df['RESOLUTION'] = df['RESOLUTION'].round(1)
                df['FileName'] = df['FILE'].apply(os.path.basename)
                # Group by program
                grouped = df.groupby(df['FileName'].str.extract(pattern, expand=False))
                group_data = []
                # Individual test
                group_data_dicts = []

                for group, data in grouped:
                    # print(group)
                    # Extract general statistics
                    # print(data.describe())
                    # print('\n')
                    #Extract data for ANOVA test
                    group_data.append(data['RESOLUTION'].tolist())

                    # Prepare data for individual t-tests
                    group_dict = {}
                    group_dict[group] = data['RESOLUTION'].tolist()
                    group_data_dicts.append(group_dict)

                # ANOVA TEST
                anovaTest(group_data, file, folder)

                #  Individual paired t-test
                paired_t_tests(group_data_dicts, file, folder)

                # Plots
                plotBarplots(group_data_dicts, file, folder, folder_path)

