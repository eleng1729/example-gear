% This is a generic function for fitting to an exponential decay with two
% parameters. It could be easily extended to 3-parameter to account for
% noise. The function is:
%
%   S(x) = S0 * exp(-x*R) + Sinf
%
% The two fits are S0, the value at x=0, and the decay rate R. This can be
% used for T2 or ADC fitting.
% This version has a fixed value for S at infinity, which should be the
% Rician noise level. This must be passed in.
function [S0, R, S0sd, Rsd, Sinf, Sinfsd] = fit_to_exp_decay_2param_fixednoise(...
    xvals, yvals, Sinf, TolFun, TolX, bShowFitting)

if nargin<6
    bShowFitting = 0;
end

if nargin<5
    TolX = 1e-6;
end

if nargin<4
    TolFun = 1e-6;
end

% The yvals need to be scaled uniformly so that the tolerances are applied
% proportionally to the highest signal. This makes the convergence criteria
% more consistent for different datasets.
yscale_factor = 1/max(yvals(:));
%yscale_factor = 1;

% Nonlinear fit to exponential
funcstring = sprintf('b(1)*exp(-x*b(2)) + %f', Sinf*yscale_factor);
decayfunc = inline(funcstring, 'b', 'x');
Sinfsd = 0;

% Initial guess for S0 and R will be based on the full linear fit
[S0initial, Rinitial] = fit_to_exp_decay_2param_linear(...
    xvals, yvals);

N = max(size(xvals)); % Number of points to fit

% Pick a reasonable Rinitial
if ((Rinitial <= 0) || (Rinitial == Inf) || isnan(Rinitial))
    Rinitial = 1/ (xvals(N) - xvals(1));
end

if (N==2)
    % Best you can do is a linear fit
    R = Rinitial;
    S0 = S0initial;
    S0sd = 0;
    Rsd = 0;
    return;
end


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


%plot(xvals, beta0(1)*exp(-xvals/beta0(2))+beta0(3) );

[fitbeta, resnorm, residual, exitflag, output, lambda, J]  = ...
    lsqcurvefit(decayfunc, beta0, xvals, yvals'.*yscale_factor, ...
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
    xlabel('x')
    ylabel('Signal Amplitude')
    hold on
    
    %simX = 0:1:max(xvals(:));
    simX = linspace(0,max(xvals(:)));
    
    plot(simX, S0*exp(-simX*R) + Sinf, ':r');
    hold off
    set(gca, 'ylim', [0 S0] .* 1.1)
    %set(gca, 'xtick', 0:25:150)
    title(sprintf(...
        '2-param R Fit: S0=%.1f+/-%.1f, R=%.1f+/-%.1f, 1/R=%.1f+/-%.1f\n',  ...
        S0, S0sd, R, Rsd, 1/R, Rsd/R^2));
    legend('data', 'fit')

    pause(0.2);
    %dummy = input('press Return');
end







