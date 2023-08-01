import os
import shutil
import sys
import time
import re
import argparse

CRYOSPARC_HOME = '/usr/local/cryosparc3'
CRYO_PROJECTS_DIR = '/home/dmarchan/DM/AlignmentPaper/' # SOME PATH WITH CRYOSPARC WRITTING PERMISSIONS
CRYOSPARC_USER = 'Irene'
CRYOSPARC_MASTER = 'cryosparc_master'
CRYOSPARC_WORKSPACE_NAME ='AlignmentMotionPatch'
PROJECT_NAME = 'MovieAlignmentPaper'
HOST_NAME = 'galileo-shadow.cnb.csic.es'

STATUS_FAILED = "failed"
STATUS_ABORTED = "aborted"
STATUS_COMPLETED = "completed"
STATUS_KILLED = "killed"
STATUS_RUNNING = "running"
STATUS_QUEUED = "queued"
STATUS_LAUNCHED = "launched"
STATUS_STARTED = "started"
STATUS_BUILDING = "building"

STOP_STATUSES = [STATUS_ABORTED, STATUS_COMPLETED, STATUS_FAILED, STATUS_KILLED]
ACTIVE_STATUSES = [STATUS_QUEUED, STATUS_RUNNING, STATUS_STARTED,
                   STATUS_LAUNCHED, STATUS_BUILDING]


def getProjectName(scipionProjectName):
    """ returns the name of the cryosparc project """
    return scipionProjectName

def getCryosparcProjectsDir():
    """ Get the path on the worker node to a writable directory """
    cryoProject_Dir = CRYO_PROJECTS_DIR
    if not os.path.exists(cryoProject_Dir):
        os.mkdir(cryoProject_Dir)

    return cryoProject_Dir

def createProjectDir(project_container_dir):
    """
    Given a "root" directory, create a project (PXXX) dir if it doesn't already
     exist
    :param project_container_dir: the "root" directory in which to create the
                                  project (PXXX) directory
    :returns: str - the final path of the new project dir with shell variables
              still in the returned path (the path should be expanded every
              time it is used)
    """
    create_project_dir_cmd = (getCryosparcProgram() +
                              ' %scheck_or_create_project_container_dir("%s")%s '
                              % ("'", project_container_dir, "'"))
    return runCmd(create_project_dir_cmd, printCmd=True)

def getCryosparcProgram(mode="cli"):
    """ Get the cryosparc program to launch any command """
    csDir = getCryosparcDir()
    if csDir is not None:
        if os.path.exists(os.path.join(csDir, CRYOSPARC_MASTER, "bin")):
            return os.path.join(csDir, CRYOSPARC_MASTER, "bin",
                                'cryosparcm %s' % mode)

    return None

def getCryosparcDir():
    """ Get the root directory where cryoSPARC code and dependencies are installed. """
    return CRYOSPARC_HOME

def runCmd(cmd, printCmd=False):
    """ Runs a command and check its exit code. If different than 0 it raises an exception
    :parameter cmd command to run
    :parameter printCmd (default True) prints the command"""
    import subprocess
    if printCmd:
         print("Running: %s" % cmd)
    exitCode, cmdOutput = subprocess.getstatusoutput(cmd)

    if exitCode != 0:
        raise Exception("%s failed --> Exit code %s, message %s" % (cmd, exitCode, cmdOutput))

    return exitCode, cmdOutput

def getProjectPath(projectDir):
    """ Gets all projects of given path .
    projectDir: Folder path to get sub folders.
    returns: Set with all sub folders. """
    folderPaths = os.listdir(projectDir)
    return folderPaths

def createEmptyProject(projectDir, projectTitle):
    """ create_empty_project(owner_user_id, project_container_dir, title=None, desc=None) """
    create_empty_project_cmd = (getCryosparcProgram() +
                                ' %screate_empty_project("%s", "%s", "%s")%s '
                                % ("'", str(getCryosparcUser()),
                                   str(projectDir), str(projectTitle), "'"))

    return runCmd(create_empty_project_cmd, printCmd=True)

def getCryosparcUser():
    """ Get the user """
    user = CRYOSPARC_USER

    return user

def getProjectInformation(project_uid, info='project_dir'):
    """Get information about a single project
    :param project_uid: the id of the project
    :return: the information related to the project thats stored in the database """
    import ast
    getProject_cmd = (getCryosparcProgram() +
                                ' %sget_project("%s")%s '
                                % ("'", str(project_uid), "'"))

    project_info = runCmd(getProject_cmd, printCmd=True)
    dictionary = ast.literal_eval(project_info[1])
    return str(dictionary[info])

def getCryosparcProjectId(projectDir):
    """ Get the project Id form project.json file.
    :param projectDir: project directory path """
    import json
    projectJsonFilePath = os.path.join(projectDir, 'project.json')

    with open(projectJsonFilePath, 'r') as file:
        prjson = json.load(file)

    pId = prjson['uid']
    return pId

def createEmptyWorkSpace(projectName, workspaceTitle, workspaceComment):
    """ create_empty_workspace(project_uid, created_by_user_id,
                               created_by_job_uid=None,
                               title=None, desc=None)
        returns the new uid of the workspace that was created """
    create_work_space_cmd = (getCryosparcProgram() +
                             ' %screate_empty_workspace("%s", "%s", "%s", "%s", "%s")%s '
                             % ("'", projectName, str(getCryosparcUser()),
                                "None", str(workspaceTitle),
                                str(workspaceComment), "'"))
    return runCmd(create_work_space_cmd, printCmd=True)

def doImportMovies(protocol, params):
    """ do_import_particles_star(puid, wuid, uuid, abs_star_path,
                                 abs_blob_path=None, psize_A=None)
        returns the new uid of the job that was created """
    print("Importing movies...")
    className = "import_movies"

    import_movies = enqueueJob(className, protocol.projectName, protocol.workSpaceName,
                                  str(params).replace('\'', '"'), '{}', protocol.lane)

    waitForCryosparc(protocol.projectName, import_movies,
                     "An error occurred importing movies. "
                     "Please, go to cryoSPARC software for more "
                     "details.")

    return import_movies

def doMovieAlignment(protocol, gpus_num):
    """ do_run_patch_alignment:  do_job(job_type, puid='P1', wuid='W1',
                                    uuid='devuser', params={},
                                    input_group_connects={})
        returns: the new uid of the job that was created """
    input_group_connect = {"movies": protocol.movies}
    # Determinate the GPUs or the number of GPUs to use
    try:
        gpusToUse = getGpuList(gpus_num=gpus_num)
        numberGPU = len(gpusToUse)
    except Exception:
        gpusToUse = False
        numberGPU = 1

    print("GPUs to use:")
    print(gpusToUse)
    params = protocol.assignParamValue()
    params["compute_num_gpus"] = str(numberGPU)

    runMovieAlignmentJob = enqueueJob(protocol._className, protocol.projectName,
                               protocol.workSpaceName,
                               str(params).replace('\'', '"'),
                               str(input_group_connect).replace('\'', '"'),
                               protocol.lane, gpusToUse)

    protocol.runMovieAlignment = str(runMovieAlignmentJob)
    waitForCryosparc(protocol.projectName, protocol.runMovieAlignment,
                     "An error occurred in the movie alignment process. "
                     "Please, go to cryoSPARC software for more "
                     "details.")

    clearIntermediateResults(protocol.projectName, protocol.runMovieAlignment)
    return str(runMovieAlignmentJob)


def enqueueJob(jobType, projectName, workSpaceName, params, input_group_connect,
               lane, gpusToUse=False, group_connect=None, result_connect=None):
    """ make_job(job_type, project_uid, workspace_uid, user_id,
                 created_by_job_uid=None, params={}, input_group_connects={}) """
    make_job_cmd = (getCryosparcProgram() +
                    ' %smake_job("%s","%s","%s", "%s", "None", "None", %s, %s, "False", 0)%s' %
                    ("'", jobType, projectName, workSpaceName,
                    getCryosparcUser(),
                    params, input_group_connect, "'"))

    print("Make job: " + make_job_cmd)
    exitCode, cmdOutput = runCmd(make_job_cmd)
    # Extract the jobId
    jobId = str(cmdOutput.split()[-1])

    if group_connect is not None:
        for key, valuesList in group_connect.items():
            for value in valuesList:
                job_connect_group = (getCryosparcProgram() +
                                     ' %sjob_connect_group("%s", "%s", "%s")%s' %
                                     ("'", projectName, value, (str(jobId) + "." + key), "'"))
                runCmd(job_connect_group, printCmd=True)

    if result_connect is not None:
        for key, value in result_connect.items():
            job_connect_group = (getCryosparcProgram() +
                                 ' %sjob_connect_result("%s", "%s", "%s")%s' %
                                 ("'", projectName, value, (str(jobId) + "." + key), "'"))
            runCmd(job_connect_group, printCmd=True)

    print("Got %s for JobId" % jobId)
    # Queue the job
    user = getCryosparcUser()
    hostname = HOST_NAME
    if gpusToUse:
        gpusToUse = str(gpusToUse)
    no_check_inputs_ready = False
    enqueue_job_cmd = (getCryosparcProgram() +
                               ' %senqueue_job("%s","%s","%s", "%s", "%s", %s, "%s")%s' %
                               ("'", projectName, jobId,
                                lane, user, hostname, gpusToUse,
                                no_check_inputs_ready, "'"))

    print("Enqueue job: " + enqueue_job_cmd)
    runCmd(enqueue_job_cmd)
    return jobId

def waitForCryosparc(projectName, jobId, failureMessage):
    """ Waits for cryosparc to finish or fail a job
    :parameter projectName: Cryosparc project name
    :parameter jobId: cryosparc job id
    :parameter failureMessage: Message for the exception thrown in case job fails
    :returns job Status
    :raises Exception when parsing cryosparc's output looks wrong"""

    # While is needed here, cause waitJob has a timeout of 5 secs.
    while True:
        status = getJobStatus(projectName, jobId)
        if status not in STOP_STATUSES:
            waitJob(projectName, jobId)
        else:
            break

    if status != STATUS_COMPLETED:
        raise Exception(failureMessage)

    return status

def waitJob(projectName, job):
    """ Wait while the job not finished """
    wait_job_cmd = (getCryosparcProgram() +
                    ' %swait_job_complete("%s", "%s")%s'
                    % ("'", projectName, job, "'"))
    runCmd(wait_job_cmd, printCmd=True)

def getJobStatus(projectName, job):
    """ Return the job status """
    get_job_status_cmd = (getCryosparcProgram() +
                          ' %sget_job_status("%s", "%s")%s'
                          % ("'", projectName, job, "'"))

    status = runCmd(get_job_status_cmd, printCmd=True)
    return status[-1]

def clearIntermediateResults(projectName, job, wait=3):
    """ Clear the intermediate result from a specific Job
    :param projectName: the uid of the project that contains the job to clear
    :param job: the uid of the job to clear """
    print("Removing intermediate results...")
    clear_int_results_cmd = (getCryosparcProgram() +
                             ' %sclear_intermediate_results("%s", "%s")%s'
                             % ("'", projectName, job, "'"))
    runCmd(clear_int_results_cmd, printCmd=True)
    # wait a delay in order to delete intermediate results correctly
    time.sleep(wait)

def getGpuList(gpus_num):
    gpuList = []
    if gpus_num>=1:
        for gpu in range(gpus_num):
            gpuList.append(gpu)
    else:
        print("Not gpus assigned")
        exit(0)

    return gpuList

def get_job_streamlog(projectName, job):
    get_job_streamlog_cmd = (getCryosparcProgram() +
                             ' %sget_job_streamlog("%s", "%s")%s'
                             % ("'", projectName, job, "'"))

    _, info = runCmd(get_job_streamlog_cmd, printCmd=True)
    return info

def getExecutionTime(eventLog, outMic, save=False):
    # ''' TODO - It caches the complete job running it may include the plotting'''
    timeDict = {}
    start = eventLog.find("Total time ") + len("Total time ")
    end = eventLog[start:].find(",") - 4
    time = eventLog[start:start + end]
    timeDict["total_time"] = time
    print("Total execution time: %s secs" %time)
    start = eventLog.find("Loaded passthrough dset with ") + len("Loaded passthrough dset with ")
    end = eventLog[start:].find(",") - 3
    countStr = eventLog[start:start+end]
    outputNumber = int(re.search(r'\d+', countStr).group())
    time_per_movie = float(time)/outputNumber
    timeDict["time_per_movie"] = str(time_per_movie)
    print("Execution time per movie: %s secs" % time_per_movie)

    if save:
        with open(os.path.join(os.path.dirname(outMic),'times.txt'), 'w') as data:
            data.write(str(timeDict))

    # real    1m30.134s Format
    print()
    time = time.replace('.', ',')
    print("real    %ss" %time)

    return timeDict

def copyFiles(src, dst, files=None):
    """
    Copy a list of files from src to dst. If files is None, all files of src are
    copied to dst
    :param src: source folder path
    :param dst: destiny folder path
    :param files: a list of files to be copied
    :return:
    """
    try:
        if files is None:
            shutil.copytree(src, dst)
        else:
            for file in files:
                shutil.copy(os.path.join(src, file),
                            os.path.join(dst, file))

    except Exception as ex:
        print("Unable to execute the copy: Files or directory does not exist: ",
              ex)

class CryosparcPatchMotionCorrection:

    _className = "patch_motion_correction_multi"

    def __init__(self):
        pass

    def _initializeUtilsVariables(self):
        """ Initialize all utils cryoSPARC variables """
        # Create a cryoSPARC project dir
        self.projectDirName = getProjectName(PROJECT_NAME)
        self.projectPath = os.path.join(getCryosparcProjectsDir(),
                                           self.projectDirName)
        self.projectContainerDir = createProjectDir(self.projectPath)[1]
        self.lane = "default"

    def assignParamValue(self):
        params  = {"do_plots":"True","num_plots":"10","memoryfix":"True","memoryfix2":"False" ,"res_max_align":"5",
                   "bfactor":"500","frame_start":"0","output_fcrop_factor":"1","variable_dose":"False",
                   "smooth_lambda_cal":"0.5"}

        return params

    def initializeCryosparcProject(self):
        """ Initialize the cryoSPARC project and workspace """
        self._initializeUtilsVariables()
        # create empty project or load an exists one
        folderPaths = getProjectPath(self.projectPath)
        if not folderPaths:
            self.emptyProject = createEmptyProject(self.projectPath, self.projectDirName)
            self.projectName = str(self.emptyProject[-1].split()[-1])
            self.projectDir = str(getProjectInformation(self.projectName, info='project_dir'))
        else:
            self.projectDir = str(os.path.join(self.projectContainerDir, str(folderPaths[0])))
            self.projectName = str(getCryosparcProjectId(self.projectDir))

        # create empty workspace
        self.emptyWorkSpace = createEmptyWorkSpace(self.projectName, CRYOSPARC_WORKSPACE_NAME,'WorkSpace')
        self.workSpaceName = str(self.emptyWorkSpace[-1].split()[-1])
        self.currentJob = ""

    def importMovies(self, micIn=None, gain=None, rotGain=0, flipGain=0, pixSize=1,
                     kV=200, cs_mm=2.7, total_dose=50):
        params = {"blob_paths": micIn,
                  "gainref_path": gain,
                  "gainref_flip_x": flipGain == 2, #Cual de las dos mirar en la docu de motioncorr para ver aqui que poner
                  "gainref_flip_y": flipGain == 1,
                  "gainref_rotate_num": rotGain, #1
                  "psize_A": pixSize,
                  "accel_kv": kV,
                  "cs_mm": cs_mm, # TODO hace falta si o si (spherical aberation)
                  "total_dose_e_per_A2": total_dose, # TODO hace falta si o si (Total exposure dose (e/A^2))
                  #"":dark
                  }

        importedMoviesJob = doImportMovies(self, params)
        self.currentJob = str(importedMoviesJob)
        self.movies = str(importedMoviesJob + '.imported_movies')

    def alignMovies(self, gpus_num=1):
        print('Aligning movies....')
        alignmentJob = doMovieAlignment(self, gpus_num=gpus_num)
        self.alignmentJob = alignmentJob
        self.currentJob = alignmentJob
        self.micrographs = str(alignmentJob)+'.micrographs'

    def createOutputStep(self, outMic):
        """ Copying the programs output."""
        print("Copying results...")
        csOutputFolder = os.path.join(self.projectDir, self.currentJob)
        csOutputFolder = os.path.join(csOutputFolder, "motioncorrected")
        included_extensions = ["_patch_aligned.mrc", "_rigid_traj.npy", "_bending_traj.npy"]
        file_names = [fn for fn in os.listdir(csOutputFolder)
                      if any(fn.endswith(ext) for ext in included_extensions)]
        print("copying %d files...." % len(file_names))
        # Copy the CS output to output folder
        outDir = os.path.dirname(outMic)
        copyFiles(csOutputFolder, outDir, files=file_names) # copy file names and change name outMic
        for old_name in file_names:
            if old_name.endswith("_patch_aligned.mrc"):
                old_name = os.path.join(outDir,old_name)
                os.rename(old_name, outMic)
            elif old_name.endswith("_rigid_traj.npy"):
                new_name = outMic.replace("_avg.mrc","_rigid_traj.npy")
                old_name = os.path.join(outDir,old_name)
                os.rename(old_name, new_name)
            elif old_name.endswith("_bending_traj.npy"):
                new_name = outMic.replace("_avg.mrc","_bending_traj.npy")
                old_name = os.path.join(outDir,old_name)
                os.rename(old_name, new_name)

        print("Finish copying")

# ------------------------ MAIN PROGRAM -----------------------------
if __name__ == "__main__":
    msg = "python3 cryosparc_patch_motion_correction.py --InTiff hola --OutMrc chao --Gain welcome --RotGain 0 --FlipGain 1 --PixSize 0.95 --kV 200 --CSmm 2.7 --TotalDose 50.56 --GpuNum 1"

    # Initialize parser
    parser = argparse.ArgumentParser()
    # Add an argument
    parser.add_argument('--InTiff', type=str, required=True)  # Parse the argument
    parser.add_argument('--OutMrc', type=str, required=True)
    parser.add_argument('--Gain', type=str, required=False)
    parser.add_argument('--RotGain', type=int, required=False)
    parser.add_argument('--FlipGain', type=int, required=False)
    parser.add_argument('--PixSize', type=float, required=True)
    parser.add_argument('--kV', type=int, required=True)
    parser.add_argument('--CSmm', type=float, required=True)
    parser.add_argument('--TotalDose', type=float, required=True)
    parser.add_argument('--GpuNum', type=int, required=True)
    # parser.add_argument('--Dark', type=str, required=False) There is no option in cryosparc
    args = parser.parse_args()

    motion_correction_program = CryosparcPatchMotionCorrection()
    motion_correction_program.initializeCryosparcProject()
    # WORKSPACE WN: NEW ONE PER EXECUTION IN THE SAME PROJECT
    motion_correction_program.importMovies(micIn=args.InTiff, gain=args.Gain, rotGain=args.RotGain,
                                           flipGain=args.FlipGain, pixSize=args.PixSize, kV=args.kV,
                                           cs_mm=args.CSmm, total_dose=args.TotalDose)
    motion_correction_program.alignMovies(gpus_num=args.GpuNum) #params for motion correction and gpus
    motion_correction_program.createOutputStep(outMic=args.OutMrc)
    print("Getting execution times")
    txtLog = get_job_streamlog(motion_correction_program.projectName, motion_correction_program.alignmentJob)
    timeDict = getExecutionTime(eventLog=txtLog, outMic=args.OutMrc, save=False)
