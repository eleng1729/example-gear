% This is a generic function for fitting to an exponential decay with two
% parameters, using the linearized method. This is fast, but gives a biased
% result.
% The function is:
%
%   S(x) = S0 * exp(-x*R)
%
% It is linearized by taking the log:
%
% log(S(x)) = log(S0) -x*R
% 
% The two fits are S0, the value at x=0, and the decay rate R. This can be
% used for T2 or ADC fitting.
function [S0, R, S0sd, Rsd, Sinf, Sinfsd] = fit_to_exp_decay_2param_linear(...
    xvals, yvals, ~, ~, ~, bShowFitting)

if nargin<6
    bShowFitting = 0;
end

% The linear fit assumes it decays to zero
Sinf = 0;
Sinfsd = 0;

% This doesn't work if any values are zero. Just disregard those
nzindices = yvals~=0;
xvals = xvals(nzindices);
yvals = yvals(nzindices);

% Using compact matlab notation: AX=B --> X = A\B. 
% Adding the ones column gives a non-zero intercept
results = [ones(length(xvals), 1) xvals'] \ log(yvals);
S0 = exp(results(1));
R = -results(2);
S0sd =0;
Rsd = 0;

if (S0==0)
    bShowFitting = 1;
end


% Optional graphic diagnostic
if ( bShowFitting )
    disp(sprintf('S0 = %f +/- %f, R = %f +/- %f', S0, S0sd, R, Rsd))
    
    %plot fit
    figure(5)
    % in log domain
    subplot(1,2,1)
    plot(xvals, log(yvals), '-o');
    xlabel('x')
    ylabel('Signal Amplitude')
    hold on
    
    simX = 0:1:max(xvals(:));
    
    plot(simX, log(S0*exp(-simX*R)), ':r');
    hold off
    %set(gca, 'ylim', [0 S0] .* 1.1)
    %set(gca, 'xtick', 0:25:150)
    
    % Without log transformatio
    subplot(1,2,2)
    plot(xvals, yvals, '-o');
    set(gca, 'ylim', [0 S0] .* 1.1)
    xlabel('x')
    ylabel('Signal Amplitude')
    hold on
    plot(simX, S0*exp(-simX*R), ':r');
    hold off
    
    
    
    
    title(sprintf(...
        'LOG 2-param R Fit: S0=%.1f+/-%.1f, R=%.1f+/-%.1f, 1/R=%.1f+/-%.1f\n',  ...
        S0, S0sd, R, Rsd, 1/R, Rsd/R^2));
    legend('data', 'fit')

    %dummy = input('press Return');
end