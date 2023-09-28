import requests
import os
import subprocess
import shutil
import argparse
import logging
import time
import uuid

URL = 'http://localhost:2134/Warp/'

template_109 = '''<?xml version="1.0" encoding="utf-16"?>
<Settings>
	<Param Name="PixelSizeX" Value="{pixel_size}" />
	<Param Name="PixelSizeY" Value="{pixel_size}" />
	<Param Name="ProcessCTF" Value="False" />
	<Param Name="ProcessMovement" Value="True" />
	<Param Name="ProcessPicking" Value="False" />
	<Import>
		<Param Name="Folder" Value="{path}" />
		<Param Name="Extension" Value="*{extension}" />
		<Param Name="GainPath" Value="{gain}" />
		<Param Name="GainFlipX" Value="{gain_flip_x}" />
		<Param Name="GainFlipY" Value="{gain_flip_y}" />
		<Param Name="GainTranspose" Value="{gain_transpose}" />
		<Param Name="CorrectGain" Value="{correct_gain}" />
		<Param Name="CorrectDefects" Value="{correct_defects}" />
        <Param Name="DefectsPath" Value="{dark}" />
	</Import>
</Settings>'''

WARP_PROCESS = None
WARP_DIR = ''

def load_settings(path, settings):
    path = os.path.abspath(os.path.join(path, 'warp.settings'))
    with open(path, 'w', encoding='utf_16_le') as f:
        f.write(settings)
    requests.post(URL + 'LoadSettings', json = {'path': path})
    

def clean(path, ext):
    shutil.rmtree(os.path.join(path, 'average'), ignore_errors=True)
    shutil.rmtree(os.path.join(path, 'denoising'), ignore_errors=True)
    shutil.rmtree(os.path.join(path, 'thumbnails'), ignore_errors=True)
    candidates = [f for f in os.listdir(path) if f.endswith(ext)]
    for f in candidates:
        os.remove(os.path.abspath(os.path.join(path,f)).replace(ext, '.xml'))
    
def wait(path, ext):
    
    # use the fact that for each processed movie, an xml file will be created
    to_process = [os.path.abspath(os.path.join(path, f.replace(ext, '.xml'))) for f in os.listdir(path) if f.endswith(ext)]
    while not all([os.path.isfile(f) for f in to_process]):
        time.sleep(0.1)
       
def move_mics(path, dest):
    mics = [f for f in os.listdir(os.path.join(path, 'average')) if f.endswith('.mrc')]
    for m in mics:
        f = 'warp_' + m.replace('.mrc', '_avg.mrc')
        shutil.move(os.path.join(path, 'average', m), os.path.join(dest, f))

def stop_processing():
    logging.info('Stopping Warp')
    requests.post(URL + 'StopProcessing', json = {})
    while (requests.get(URL + 'GetProcessingStatus').text) != 'stopped':
        time.sleep(0.5)
    logging.info('Warp stopped')
    # we're done
    WARP_PROCESS.terminate()
    
def start_warp():
    global WARP_PROCESS    
    # prepare and run Warp
    remove_old_settings(WARP_DIR)
    WARP_PROCESS = subprocess.Popen([os.path.join(WARP_DIR, 'Warp.exe')], cwd=WARP_DIR)   
    time.sleep(5) # so it loads in peace
    while (requests.get(URL + 'GetProcessingStatus', timeout=None).text) != 'stopped':
        time.sleep(0.5)    
    requests.get(URL + 'GetSettingsGeneral') # just to make sure it works
     
def run_noisy(movie_dir, result_dir):
    logging.info('processing noisy movies')
    path = os.path.join(movie_dir, 'noisy')
    dest = os.path.join(result_dir, 'noisy', 'runtime')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.mrc'
    gain = os.path.join(path, 'gain')
    dark = os.path.join(path, 'dark')
    
    mics = [f for f in os.listdir(path) if f.endswith(ext)]
    for m in mics:
        # micrograph has to be moved to separate folder so we can process just a single one
        tmp = os.path.join(dest, 'tmp')
        os.makedirs(tmp, exist_ok=True)
        shutil.move(os.path.join(path, m), os.path.join(tmp, m))
        for i in range(0,10):
            # Warp is very picky with folders, it doesn't like working more times in the same folder
            work_dir = os.path.join(tmp, str(uuid.uuid4()))
            os.makedirs(work_dir, exist_ok=True)
            shutil.move(os.path.join(tmp, m), os.path.join(work_dir, m))
            # load correct settings
            start_warp()
            settings = template_109.format(path=work_dir, pixel_size='1', extension=ext, gain=os.path.join(gain, m), gain_flip_x='False', gain_flip_y='False', gain_transpose='False', correct_gain='True', dark=os.path.join(dark, m), correct_defects='True')       
            load_settings(work_dir, settings)
            
            logging.info('runtime - filename: {}'.format(m))
            # give it a second to get ready
            time.sleep(1)
            t0 = time.perf_counter()
            requests.post(URL + 'StartProcessing', json = {})
            t1 = time.perf_counter()
            while not os.path.isfile(os.path.join(work_dir, 'average', m)):
                time.sleep(0.01)
            t = time.perf_counter()
            logging.info('real {}s'.format(t - t1))
            logging.info('runtime - filename: {} (including StartProcessing overhead'.format(m))
            logging.info('real {}s'.format(t - t0))
            stop_processing()
            # save results for analysis
            if 0 == i:
                move_mics(work_dir, dest)
            # move movie back where it was
            shutil.move(os.path.join(work_dir, m), os.path.join(tmp, m))
            # remove entire directory
            shutil.rmtree(work_dir, ignore_errors=True)
            
        shutil.move(os.path.join(tmp, m), os.path.join(path, m))
        shutil.rmtree(tmp, ignore_errors=True)
    logging.info('processing noisy movies done')
     
def run_noisless(movie_dir, result_dir):
    logging.info('processing noiseless movies')
    path = os.path.join(movie_dir, 'pristine')
    dest = os.path.join(result_dir, 'pristine', 'runtime')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.mrc'
    gain = os.path.join(path, 'gain')
    dark = os.path.join(path, 'dark')
    
    mics = [f for f in os.listdir(path) if f.endswith(ext)]
    for m in mics:
        # micrograph has to be moved to separate folder so we can process just a single one
        logging.info('processing {}'.format(m))
        tmp = os.path.join(dest, str(uuid.uuid4()))
        os.makedirs(tmp, exist_ok=True)
        shutil.move(os.path.join(path, m), os.path.join(tmp, m))
        # load correct settings
        start_warp()
        settings = template_109.format(path=tmp, pixel_size='1', extension=ext, gain=os.path.join(gain, m), gain_flip_x='False', gain_flip_y='False', gain_transpose='False', correct_gain='True', dark=os.path.join(dark, m), correct_defects='True')       
        load_settings(tmp, settings)
            
        requests.post(URL + 'StartProcessing', json = {})
        while not os.path.isfile(os.path.join(tmp, 'average', m)):
            time.sleep(0.5)
        stop_processing()
        move_mics(tmp, dest)
        # get to the original state
        shutil.move(os.path.join(tmp, m), os.path.join(path, m))
        shutil.rmtree(tmp, ignore_errors=True)
    logging.info('processing noiseless movies done')

def run_shifts(movie_dir, result_dir):
    logging.info('processing shifts in {}'.format(movie_dir))
    path = os.path.join(movie_dir, 'shift')
    dest = os.path.join(result_dir, 'runtime')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.mrc'
    gain = os.path.join(path, 'gain')
    dark = os.path.join(path, 'dark')
    
    mics = [f for f in os.listdir(path) if f.endswith(ext)]
    for m in mics:
        logging.info('processing {}'.format(m))
        # micrograph has to be moved to separate folder so we can process just a single one
        tmp = os.path.join(dest, str(uuid.uuid4()))
        os.makedirs(tmp, exist_ok=True)
        shutil.move(os.path.join(path, m), os.path.join(tmp, m))
        # load correct settings
        start_warp()
        settings = template_109.format(path=tmp, pixel_size='1', extension=ext, gain=os.path.join(gain, m), gain_flip_x='False', gain_flip_y='False', gain_transpose='False', correct_gain='True', dark=os.path.join(dark, m), correct_defects='True')       
        load_settings(tmp, settings)
            
        requests.post(URL + 'StartProcessing', json = {})
        while not os.path.isfile(os.path.join(tmp, 'average', m)):
            time.sleep(0.5)
        stop_processing()
        move_mics(tmp, dest)
        # get to the original state
        shutil.move(os.path.join(tmp, m), os.path.join(path, m))
        shutil.rmtree(tmp, ignore_errors=True)
    logging.info('processing shifts done')

def remove_old_settings(warp_dir):
    settings = os.path.join(warp_dir, 'previous.settings')
    if os.path.exists(settings):
        os.remove(settings)

def main(args):
    global WARP_DIR
    WARP_DIR = os.path.abspath(args.warp_path)
    parent_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
    movie_dir = os.path.abspath(os.path.join(parent_dir, 'phantom_movies'))
    result_dir = os.path.abspath(os.path.join(parent_dir, args.machine, 'phantom_movies'))
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    
    logging.basicConfig(filename=os.path.join(result_dir, os.path.basename(__file__).replace('.py', '.log')), level=logging.INFO) 
        
    # measure runtime / get data for quality (noise)
    run_noisy(movie_dir, result_dir)
    # get data for quality (noiseless)
    run_noisless(movie_dir, result_dir)
    # get data for quality (shift) - keep the order noisy - noiseless. Its because otherwise Warp will get stuck reading from the same tmp folder
    run_shifts(os.path.join(movie_dir, 'noisy'), os.path.join(result_dir, 'noisy'))
    run_shifts(os.path.join(movie_dir, 'pristine'), os.path.join(result_dir, 'pristine'))
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('machine', help='Machine name')
    parser.add_argument('warp_path', help='Path to Warp folder')
    args = parser.parse_args()
    main(args)
