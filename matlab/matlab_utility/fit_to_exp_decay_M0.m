% This version fits y(0), given a fixed decay rate R and a set of points.
% The equation is
%
%   S(x) = S0 * exp(-x*R)
%
% Used for M0 estimation with a fixed T2
function [S0, S0sd] = fit_to_exp_decay_M0(...
    xvals, yvals, R, TolFun, TolX)

if nargin<5
    TolX = 1e-6;
end

if nargin<4
    TolFun = 1e-6;
end

% Ignore noise
Sinf = 0;

% The yvals need to be scaled uniformly so that the tolerances are applied
% proportionally to the highest signal. This makes the convergence criteria
% more consistent for different datasets.
yscale_factor = 1/max(yvals(:));

% Nonlinear fit to exponential
%funcstring = sprintf('b(1)*exp(-x*%f) + %f', R, Sinf*yscale_factor);
funcstring = sprintf('b(1)*exp(-x*%f)', R);
decayfunc = inline(funcstring, 'b', 'x');

% First point is a good estimate
S0initial = yvals(1);

N = max(size(xvals)); % Number of points to fit


beta0(1) = S0initial * yscale_factor; % Initial guess of amplitude
lowBounds = [0.0];
upBounds = [100];

options = optimset;
options = optimset(options, 'TolFun', TolFun);
options = optimset(options, 'TolX', TolX);
options = optimset(options, 'MaxFunEvals', 1000);
options = optimset(options, 'Diagnostics', 'off');
options = optimset(options, 'Display', 'off');

[fitbeta, resnorm, residual, exitflag, output, lambda, J]  = ...
    lsqcurvefit(decayfunc, beta0, xvals, yvals'.*yscale_factor, ...
    double(lowBounds), double(upBounds), options);

S0=fitbeta(1)/yscale_factor;

% standard deviation estimate
ci = nlparci(fitbeta,residual,J);
S0sd = (fitbeta(1)-ci(1,1)) / 2 * (1/yscale_factor) ;

bShowFitting = true;
% Optional graphic diagnostic
if ( bShowFitting)
    disp(sprintf('S0 = %f +/- %f', S0, S0sd))
    
    %plot fit
    plot(xvals, yvals, '-o');
    xlabel('x')
    ylabel('Signal Amplitude')
    hold on
    
    simX = 0:1:max(xvals(:));
    
    plot(simX, S0*exp(-simX*R) + Sinf, ':r');
    hold off
    set(gca, 'ylim', [0 S0] .* 1.1)
    %set(gca, 'xtick', 0:25:150)
    title(sprintf(...
        '1-param M0 Fit: S0=%.1f+/-%.1f\n',  ...
        S0, S0sd));
    legend('data', 'fit')
    
    pause(0.2);
    %dummy = input('press Return');
end
1;