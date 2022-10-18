function ts = secondsToDicomTimestamp(secs)
% Convert from #seconds of the day since midnight to a DICOM timestamp,
% which is HHMMSS.ffffff 
% HH-hour, MM-minute, SS-seconds, ffffff-microseconds

% Parse out the integer number of seconds
integersecs = floor(secs);
hrs = floor(integersecs/3600);
temp = integersecs - hrs*3600;
minutes = floor(temp/60);
seconds = temp - minutes*60;

fractionalsecs = secs - integersecs;

ts = sprintf('%02d%02d%02d.%06d', ...
    hrs, minutes, seconds, floor(fractionalsecs*1000000));