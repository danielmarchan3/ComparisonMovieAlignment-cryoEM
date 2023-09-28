import requests
import os
import subprocess
import shutil
import argparse

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
		<Param Name="CorrectDefects" Value="False" />
		<Param Name="DosePerAngstromFrame" Value="{dose}" />
	</Import>
</Settings>'''

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
    import time
    # use the fact that for each processed movie, an xml file will be created
    to_process = [os.path.abspath(os.path.join(path, f.replace(ext, '.xml'))) for f in os.listdir(path) if f.endswith(ext)]
    while not all([os.path.isfile(f) for f in to_process]):
        time.sleep(1)
       
def move_mics(path, dest):
    mics = [f for f in os.listdir(os.path.join(path, 'average')) if f.endswith('.mrc')]
    for m in mics:
        f = 'warp_' + m.replace('.mrc', '_avg.mrc')
        os.rename(os.path.join(path, 'average', m), os.path.join(dest, f))


def run_10288(movie_dir, result_dir):
    path = os.path.join(movie_dir, '10288')
    dest = os.path.join(result_dir, '10288')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.tif'
    gain = os.path.join(path, 'CountRef_CB1__00000_Feb18_23.26.46.dm4')
    settings = template_109.format(path=path, pixel_size='0.86', extension=ext, gain=gain, gain_flip_x='False', gain_flip_y='True', gain_transpose='False', correct_gain='True', dose='1.25')

    load_settings(path, settings)
    
    requests.post(URL + 'StartProcessing', json = {})
    wait(path, ext)
    requests.post(URL + 'StopProcessing', json = {})
    
    move_mics(path, dest)
    clean(path, ext)

def run_10196(movie_dir, result_dir):
    path = os.path.join(movie_dir, '10196')
    dest = os.path.join(result_dir, '10196')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.tif'
    gain = os.path.join(path, 'SuperRef_sq05_3.mrc')
    settings = template_109.format(path=path, pixel_size='0.745', extension=ext, gain=gain, gain_flip_x='True', gain_flip_y='True', gain_transpose='True', correct_gain='True', dose='1.264')
    
    load_settings(path, settings)
    
    requests.post(URL + 'StartProcessing', json = {})
    wait(path, ext)
    requests.post(URL + 'StopProcessing', json = {})
    
    move_mics(path, dest)
    clean(path, ext)
     
def run_10314(movie_dir, result_dir):
    path = os.path.join(movie_dir, '10314')
    dest = os.path.join(result_dir, '10314')
    if not os.path.exists(dest):
        os.makedirs(dest)
    ext = '.tif'
    settings = template_109.format(path=path, pixel_size='1.12', extension=ext, gain='', gain_flip_x='False', gain_flip_y='False', gain_transpose='False', correct_gain='False', dose='1.51')

    load_settings(path, settings)
    
    requests.post(URL + 'StartProcessing', json = {})
    wait(path, ext)
    requests.post(URL + 'StopProcessing', json = {})
    
    move_mics(path, dest)
    clean(path, ext)
     

def remove_old_settings(warp_dir):
    settings = os.path.join(warp_dir, 'previous.settings')
    if os.path.exists(settings):
        os.remove(settings)

def main(args):
    warp_dir = os.path.abspath(args.warp_path)
    parent_dir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
    movie_dir = os.path.abspath(os.path.join(parent_dir, 'empiar_movies'))
    result_dir = os.path.abspath(os.path.join(parent_dir, args.machine, 'empiar_movies'))
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)
    
    # prepare and run Warp
    remove_old_settings(warp_dir)
    proc = subprocess.Popen([os.path.join(warp_dir, 'Warp.exe')], cwd=warp_dir)
    
    run_10196(movie_dir, result_dir)
    run_10288(movie_dir, result_dir)
    run_10314(movie_dir, result_dir)
      
    
    # we're done
    proc.terminate()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('machine', help='Machine name')
    parser.add_argument('warp_path', help='Path to Warp folder')
    args = parser.parse_args()
    main(args)