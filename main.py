#!/usr/bin/env python3

import flywheel
import os
import sys
import shutil

ROOT_PATH = '/flywheel/v0'
sys.path.append(ROOT_PATH)

import numpy as np
import pandas as pd
import re
import SimpleITK as sitk
from scipy import ndimage
from funcs_misc import read_DICOM, write_im_registered_DICOM
from funcs_registration import apply_registration, im_register

# gear context and directories
context = flywheel.GearContext()
config = context.config

series_directories_file = context.get_input_path('series_directories')
data_file = context.get_input_path('data')

series_directories = pd.read_csv(series_directories_file, header=None)
num_case, name_case, name_target, name_tse1, name_tse2, name_tse3, name_adc, name_dce = series_directories.iloc[:, 1]

output_path = ROOT_PATH + '/output'

output_orig = output_path + '/orig'
output_reg = output_path + '/reg'
output_params = output_path + '/reg_params'

os.mkdir(output_orig)
os.mkdir(output_reg)
os.mkdir(output_params)

shutil.unpack_archive(data_file, output_orig)

# target
im_target, reader_target = read_DICOM(output_orig + '/' + name_target)

# capsule mask from segmentation
im_mask = sitk.ReadImage(output_orig + '/' + num_case + '_seg.nii.gz')
mask_array = sitk.GetArrayFromImage(im_mask)

mask_capsule_array = np.where(mask_array == 2, 1, mask_array)
mask_capsule_array = ndimage.binary_fill_holes(mask_capsule_array).astype(int)

im_mask_capsule = sitk.GetImageFromArray(mask_capsule_array)
im_mask_capsule.CopyInformation(im_target)

# T2
im_TSE1, reader_TSE1 = read_DICOM(output_orig + '/' + name_tse1)
im_TSE1_reg, reg_TSE1 = im_register(im_target, im_TSE1, im_mask_capsule, 100, 0.05, 1.05, 0.98)
sitk.WriteTransform(reg_TSE1, output_params + '/TSE1.txt')

os.mkdir(output_reg + '/TSE1_' + name_tse1)
dcm_file_dirs = [re.sub(output_orig + '/', output_reg + '/TSE1_', x) for x in reader_TSE1.GetFileNames()]
write_im_registered_DICOM(im_TSE1_reg, dcm_file_dirs, reader_target, reader_TSE1)

im_TSE2, reader_TSE2 = read_DICOM(output_orig + '/' + name_tse2)
im_TSE2_reg, reg_TSE2 = im_register(im_target, im_TSE2, im_mask_capsule, 100, 0.05, 1.05, 0.98)
sitk.WriteTransform(reg_TSE2, output_params + '/TSE2.txt')

os.mkdir(output_reg + '/TSE2_' + name_tse2)
dcm_file_dirs = [re.sub(output_orig + '/', output_reg + '/TSE2_', x) for x in reader_TSE2.GetFileNames()]
write_im_registered_DICOM(im_TSE2_reg, dcm_file_dirs, reader_target, reader_TSE2)

im_TSE3, reader_TSE3 = read_DICOM(output_orig + '/' + name_tse3)
im_TSE3_reg, reg_TSE3 = im_register(im_target, im_TSE3, im_mask_capsule, 100, 0.05, 1.05, 0.98)
sitk.WriteTransform(reg_TSE3, output_params + '/TSE3.txt')

os.mkdir(output_reg + '/TSE3_' + name_tse3)
dcm_file_dirs = [re.sub(output_orig + '/', output_reg + '/TSE3_', x) for x in reader_TSE3.GetFileNames()]
write_im_registered_DICOM(im_TSE3_reg, dcm_file_dirs, reader_target, reader_TSE3)

# DWI
im_b0, reader_b0 = read_DICOM(output_orig + '/DICOM_b0')
im_b0_reg, reg_b0 = im_register(im_target, im_b0, im_mask_capsule, 100, 0.05, 1.05, 0.98)
sitk.WriteTransform(reg_b0, output_params + '/dwi.txt')

os.mkdir(output_reg + '/b0')
dcm_file_dirs = [re.sub(output_orig + '/' + name_target + '/', output_reg + '/b0/Reg-b0-to-', x) for x in reader_target.GetFileNames()]
write_im_registered_DICOM(im_b0_reg, dcm_file_dirs, reader_target, reader_b0)

im_adc, reader_adc = read_DICOM(output_orig + '/' + name_adc)
im_adc_reg = apply_registration(im_target, im_adc, reg_b0, 'nn')

os.mkdir(output_reg + '/ADC')
dcm_file_dirs = [re.sub(output_orig + '/' + name_target + '/', output_reg + '/ADC/RS-ADC-to-', x) for x in reader_target.GetFileNames()]
write_im_registered_DICOM(im_adc_reg, dcm_file_dirs, reader_target, reader_adc)

mask_all = np.where(mask_capsule_array == 0, 1, mask_capsule_array)
im_mask_all = sitk.GetImageFromArray(mask_all)
im_mask_all.CopyInformation(im_target)

# DCE
im_dce, reader_dce = read_DICOM(output_orig + '/DICOM_DCE_49')
im_dce_reg, reg_dce = im_register(im_target, im_dce, im_mask_all, 200, 0.1, 1.1, 0.98)
sitk.WriteTransform(reg_dce, output_params + '/DCE_49.txt')

os.mkdir(output_reg + '/DCE_49')
dcm_file_dirs = [re.sub(output_orig + '/' + name_target + '/', output_reg + '/DCE_49/Reg-DCE_49-to-', x) for x in reader_target.GetFileNames()]
write_im_registered_DICOM(im_dce_reg, dcm_file_dirs, reader_target, reader_dce)

NAMES_PK = ['AUGC', 'KEP', 'KTRANS', 'VE']

for name_pk in NAMES_PK:
    im_pk, reader_pk = read_DICOM(output_orig + '/DICOM_' + name_pk)
    im_reg = apply_registration(im_target, im_pk, reg_dce, 'nn')
    
    os.mkdir(output_reg + '/' + name_pk)
    dcm_file_dirs = [re.sub(output_orig + '/' + name_target + '/', output_reg + '/' + name_pk + '/RS-' + name_pk + '-to-', x) for x in reader_target.GetFileNames()]
    write_im_registered_DICOM(im_reg, dcm_file_dirs, reader_target, reader_pk)
    
os.system('chmod -R 777 ./')
os.system('rm -rf __pycache__')

# shutil.make_archive('output', 'zip', output_path)
# 
# shutil.move(ROOT_PATH + '/output.zip', output_path + '/output.zip')
# shutil.rmtree(output_orig)
# shutil.rmtree(output_reg)
# shutil.rmtree(output_params)