% This is a function to fit an inversion recovery experiment, where xvals
% are the different inversion times and yvals are the signal intensity. The
% function is: 
%
%   S(TI) = S0 * (1 - 2 * exp(-TI/T1))
%
% The two values are S0, the value at x=0, and the recovery rate R (1/T1)
function [S0, R, S0sd, Rsd] = fit_to_inversion_recovery(...
    xvals, yvals, TolFun, TolX, bShowFitting)


% TolFun, TolX, and bShowFitting are all optional
if nargin<5
    bShowFitting = 1;
end
if nargin<4 
    TolX = [];
end
if nargin<3
    TolFun = [];
end


% The yvals need to be scaled uniformly so that the tolerances are applied
% proportionally to the highest signal. This makes the convergence criteria
% more consistent for different datasets.
yscale_factor = 1/max(abs(yvals(:)));
%yscale_factor = 1;

% Nonlinear fit to exponential Inversion recovery
funcstring = sprintf('b(1)*(1-2*exp(-x*b(2)))');
irfunc = inline(funcstring, 'b', 'x');

% Initial guesses. S0 is the max of all yvals, R is the median 1/TI
S0initial = max(abs(yvals(:)));
Rinitial = 1/median(xvals(:));

N = max(size(xvals)); % Number of points to fit

beta0(1) = S0initial * yscale_factor; % Initial guess of amplitude
beta0(2) = Rinitial; % R
lowBounds = [0.0 Rinitial/100];
upBounds = [100 Rinitial*100];

options = optimset;
options = optimset(options, 'TolFun', TolFun);
options = optimset(options, 'TolX', TolX);
options = optimset(options, 'MaxFunEvals', 1000);


if bShowFitting
    options = optimset(options, 'Diagnostics', 'on');
    options = optimset(options, 'Display', 'iter');
else
    options = optimset(options, 'Diagnostics', 'off');
    options = optimset(options, 'Display', 'off');
end

% Perform the fit
[fitbeta, resnorm, residual, exitflag, output, lambda, J]  = ...
    lsqcurvefit(irfunc, beta0, xvals, yvals'.*yscale_factor, ...
    double(lowBounds), double(upBounds), options);

S0=fitbeta(1)/yscale_factor;
R=fitbeta(2);

% standard deviation estimate
%disp('standard deviation estimate of R')
ci = nlparci(fitbeta,residual,J);
Rsd = (R-ci(2,1))/2;
%Rsd = Rsd(1);

S0sd = (fitbeta(1)-ci(1,1)) / 2 * (1/yscale_factor) ;

% Optional graphic diagnostic
if ( bShowFitting)
    disp(sprintf('S0 = %f +/- %f, R = %f +/- %f', S0, S0sd, R, Rsd))
    
    %plot fit
    plot(xvals, yvals, '-o');
    xlabel('TI (s)')
    ylabel('Signal Amplitude')
    hold on
    
    simX = 0:0.1:max(xvals(:));
    simY = S0*(1-2.*exp(-1*simX.*R));
    %plot(simX, S0*exp(-simX*R) + Sinf, ':r');
    plot(simX, simY, ':r');
    
    hold off
    
    ymax = max(abs(simY(:)));
    set(gca, 'ylim', [-ymax ymax] .* 1.1)
    %set(gca, 'xtick', 0:25:150)
    title(sprintf(...
        '2-param R Fit: S0=%.1f+/-%.1f, R=%.1f+/-%.1f, 1/R=%.1f+/-%.1f\n',  ...
        S0, S0sd, R, Rsd, 1/R, Rsd/R^2));
    legend('data', 'fit', 'Location', 'SouthEast')

    pause(0.2);
    %dummy = input('press Return');
end
