% Now the tricky part: figure out which format is most likely
% Here are the possibilities:
% PHILIPS_SPAR_SDAT
% PHILIPS_PRIVATE_DICOM
% DICOM_MRS
% GE_PFILE
% SIEMENS_RDA
% SIEMENS_PRIVATE_DICOM
% UNKNOWN
% UNKNOWN_DICOM
% VARIANFID
% XML-MRSTK
% Or XXXX_DIR if it is a directory containing such files
function fileformat = get_mrs_file_format(filename)
[pathstr, name, ext] = fileparts(filename);

% First check if this is a directory
if (isdir(filename))
    
    % First see if it ends in .fid
    if (strcmpi(ext, '.fid') == 1)
        % this is a varian .fid
        fileformat = 'VARIANFID';
    else
        
        % For directories, pick the first file inside
        files = dirWithNoDotsNoDirs(filename);
        firstfile = [pathstr filesep name ext filesep files(1).name];
        firstfile_format = get_mrs_file_format(firstfile);
        
        fileformat = [firstfile_format '_DIR'];
    end
else
    
    switch lower(ext)
        case {'.spar','.sdat'}
            fileformat = 'PHILIPS_SPAR_SDAT';
            
        case {'.dic', '.dicom', '.dcm'}
            fileformat = determine_dicom_format(filename);
            
        case '.rda'
            fileformat = 'SIEMENS_RDA';
            
        case '.dat'
            fileformat = 'SIEMENS_RAW';
            
        case '.xml'
            fileformat = 'XML-MRSTK';
            
        otherwise
            if lower(name(1)) == 'p'
                % Probably a GE p-file
                fileformat = 'GE_PFILE';
                
            elseif isdicom(filename)
                fileformat = determine_dicom_format(filename);
                
            else
                fileformat = 'UNKNOWN';
            end
            
    end
end

% Private function to determine Service-object pair class.
function fileformat = determine_dicom_format(filename)
% Load it and get the SOP Class UID
info = dicominfo(filename);
switch info.SOPClassUID
    case '1.3.46.670589.11.0.0.12.1'
        fileformat = 'PHILIPS_PRIVATE_DICOM';
        
    case '1.2.840.10008.5.1.4.1.1.4.2'
        fileformat = 'DICOM_MRS';
        
    case '1.3.12.2.1107.5.9.1'
        fileformat = 'SIEMENS_PRIVATE_DICOM';
        
    %  Next 2 are not MRS
    case '1.2.840.10008.5.1.4.1.1.4.1'
        fileformat = 'ENAHNCED_MR_IMAGE_STORAGE';
        
    case '1.2.840.10008.5.1.4.1.1.4'
        fileformat = 'MR_IMAGE_STORAGE';
        
    otherwise
        fileformat = 'UNKNOWN_DICOM';
end
