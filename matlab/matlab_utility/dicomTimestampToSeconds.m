function sod = dicomTimestampToSeconds(ts)
% This converts a DICOM timestamp into the number of seconds since the
% beginning of the current day, starting at midnight. 
% The DICOM timestamp is a string in the format:
%   HHMMSS.ffffff
% HH-hour, MM-minute, SS-seconds, ffffff-microseconds

% Matlab's datevec cannot handle fractional seconds. Maybe I'm not using it
% right? Ah well. 

% Take the left part and parse it with datevec
[Y, M, D, H, MN, S] = datevec( ts(1:6), 'HHMMSS' );

% Then the right part is the #ms 
% (although some nonstandard data do not include this)
if size(ts,2)>6
    us = str2num( ts(8:end) );
else
    us = 0;
end

% Then add them up

sod = H * 3600 + MN * 60 + S + us / 1000000;