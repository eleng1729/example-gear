import SimpleITK as sitk

def read_DICOM(DICOM_dir):
    reader = sitk.ImageSeriesReader()
    dcm_file_dirs = reader.GetGDCMSeriesFileNames(DICOM_dir)
    
    reader.SetFileNames(dcm_file_dirs)
    reader.MetaDataDictionaryArrayUpdateOn()
    
    im = reader.Execute()
    
    return im, reader

def write_DICOM(im, dcm_file_dirs, reader):
    writer = sitk.ImageFileWriter()
    writer.KeepOriginalImageUIDOn()

    for ii in range(im.GetDepth()):
        im_slice = im[:, :, ii]
        
        for x, key in enumerate(reader.GetMetaDataKeys(ii)):
            im_slice.SetMetaData(key, reader.GetMetaData(ii, key))
            
        writer.SetFileName(dcm_file_dirs[ii])
        writer.Execute(im_slice)
    
    return

def write_im_registered_DICOM(im, dcm_file_dirs, reader_target, reader_source):
    writer = sitk.ImageFileWriter()
    writer.KeepOriginalImageUIDOn()

    for ii in range(im.GetDepth()):
        im_slice = im[:, :, ii]
        
        for x, key in enumerate(reader_source.GetMetaDataKeys(0)):
            im_slice.SetMetaData(key, reader_source.GetMetaData(0, key))
            
            im_slice.SetMetaData('0018|1310', reader_target.GetMetaData(ii, '0018|1310'))  # acquisition matrix
            im_slice.SetMetaData('0020|0013', reader_target.GetMetaData(ii, '0020|0013'))  # instance number
            im_slice.SetMetaData('0020|0032', reader_target.GetMetaData(ii, '0020|0032'))  # image position
            im_slice.SetMetaData('0020|0037', reader_target.GetMetaData(ii, '0020|0037'))  # image orientation
            im_slice.SetMetaData('0020|1041', reader_target.GetMetaData(ii, '0020|1041'))  # slice location
            im_slice.SetMetaData('0028|0030', reader_target.GetMetaData(ii, '0028|0030'))  # pixel spacing
            
        writer.SetFileName(dcm_file_dirs[ii])
        writer.Execute(im_slice)
     
    return