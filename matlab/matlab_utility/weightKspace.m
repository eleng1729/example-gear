% Creates a k-space weigthing function and multiplies the k-in by that
% value.
% kin - the input 3D matrix
% mode - the weighting function: 'none', 'sinebell', 'hamming'
% width - the length of the filtered dimension, expressed as a fraction.
%       For example, width = .05 means 5%, so for a dimension of 256, there
%       will be round(256*.05)=13 filtered pixels on each side.
% if width is greater than 0.5, this will fail.
% For a disucssion about weighting, see Bernstein JMRI 2001
function kout = weightKspace(kin, mode, width)

% Default for 5% transition
if (nargin < 3)
    width = .05;
    disp(sprintf('Defaulting to %.0f%% transition width.', width*100));
end

if width>0.5
   error('weightKspace: width > 50% (%f)\n', width);
end

dims = size(kin);
if (size(dims,2)<3)
    dims(3) = 1;
end

switch lower(mode)
    case 'none'
        disp('no weighting');
        kout = kin;
        return;
        %weightfunc = ones(dims);
        
    case 'sinebell'
        % simple sinebell
        disp('Sinebell weighting');
        weightfunc = sinebell(dims);
        
    case 'hamming'
        transition1 = round(width * dims(1));
        temp = hamming(2*transition1);
        kweight1 = [temp(1:transition1)' ones(dims(1)-2*(transition1),1)' temp(transition1+1:2*transition1)'];
        
        transition2 = round(width * dims(2));
        temp = hamming(2*transition2);
        kweight2 = [temp(1:transition2)' ones(dims(2)-2*(transition2),1)' temp(transition2+1:2*transition2)'];
        
        transition3 = round(width * dims(3));
        temp = hamming(2*transition3);
        kweight3 = [temp(1:transition3)' ones(dims(3)-2*(transition3),1)' temp(transition3+1:2*transition3)'];
        
        % This combines 3 linear functions into a volume
        weightfunc = makeweightingfunction(kweight1, kweight2, kweight3);
        disp(sprintf('Hamming edge weighting. Affects (%.0f, %.0f, %.0f) pixels on each edge.',transition1, transition2, transition3));
        
        
    case 'boxcar'
        % Simple low-pass filter - zeros everything outside the filter
        % region.
        % Note that 50% width means no data (each edge is 50% of total)
        width1 = 2* round(width / 2 * dims(1));
        kweight1 = ones(dims(1),1);
        kweight1(1:width1) = 0;
        kweight1(end-width1:end) = 0;
        
        width2 = 2* round(width / 2 * dims(2));
        kweight2 = ones(dims(2),1);
        kweight2(1:width2) = 0;
        kweight2(end-width2:end) = 0;

        width3 = 2* round(width / 2 * dims(3));
        kweight3 = ones(dims(3),1);
        kweight3(1:width3) = 0;
        kweight3(end-width3:end) = 0;

        weightfunc = makeweightingfunction(kweight1, kweight2, kweight3);
        disp(sprintf('Boxcar weighting. Zeros (%.0f, %.0f, %.0f) pixels on each edge.',...
            width1, width2, width3));        
        
        
    case 'tukey'
        % A cosine taper or Tukey window. See Bernstein, Handbook of MRI
        % sequences, 2004. This builds up a sin^2 ramp over the transition
        % band, and puts it on both sides.
        transition1 = round(width * dims(1));
        temp = sin(0:pi/2/transition1:pi/2);
        temp = temp(1:transition1); % The above function makes transition1+1 points
        kweight1 = [temp ones(dims(1)-2*(transition1),1)' temp(transition1:-1:1)];
        
        transition2 = round(width * dims(2));
        temp = sin(0:pi/2/transition2:pi/2);
        temp = temp(1:transition2); % The above function makes transition1+1 points
        kweight2 = [temp ones(dims(2)-2*(transition2),1)' temp(transition2:-1:1)];
        
        transition3 = round(width * dims(3));
        temp = sin(0:pi/2/transition3:pi/2);
        temp = temp(1:transition3); % The above function makes transition1+1 points
        kweight3 = [temp ones(dims(3)-2*(transition3),1)' temp(transition3:-1:1)];
        
        % This combines 3 linear functions into a volume
        weightfunc = makeweightingfunction(kweight1, kweight2, kweight3);
        disp(sprintf('Tukey (cos^2) edge weighting. Affects (%.0f, %.0f, %.0f) pixels on each edge.',transition1, transition2, transition3));
        
        
    otherwise
        error(sprintf('Weighting function <%s> not known.', mode));
end

kout = kin .* weightfunc;

% DEBUG. Only works on 3d
if 0
    midslice = dims(3)/2;
    
    figure(34)
    subplot(2,2,1);
    imagesc(abs(kin(:,:,midslice)));
    colormap gray;
    title('kin');
    
    subplot(2,2,2);
    imagesc(abs(kout(:,:,midslice)));
    colormap gray;
    title('kout');
    
    subplot(2,2,3);
    imagesc(weightfunc(:,:,midslice));
    colorbar;
    colormap jet;
    title('weightfunc');
    
    subplot(2,2,4);
    plot(weightfunc(:,dims(2)/2, midslice), '-b.');
    axis tight
    set(gca, 'ylim', [0 1.1]);
    set(gca, 'xlim', [-10 dims(1) + 10]);
    title('profile');
    
    dummy = input('press return');
    
end



% creates a k-space weighting function based on the one dimensional arrays
% that are entered
% Expects columnar data

function weighting=makeweightingfunction(a1,a2,a3);

if (size(a1,1) < size(a1,2))
    a1=a1';
end
if (size(a2,1) < size(a2,2))
    a2=a2';
end

funct1 = a1(:,ones(1,size(a2,1)));
temp=a2';
funct2 = temp(ones(1,size(a1,1)),:);
weighting=funct1.*funct2;

if (nargin > 2)
    if (size(a3,1) < size(a3,2))
        a3=a3';
    end
    
    funct3=weighting(:,:,ones(1,1,size(a3,1)));
    for idx=1:size(a3,1)
        funct3(:,:,idx)=funct3(:,:,idx)*a3(idx);
    end
    weighting=funct3;
end


