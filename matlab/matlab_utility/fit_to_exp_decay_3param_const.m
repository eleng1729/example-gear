% This is a generic function for fitting to an exponential decay with two
% parameters. 
%
%   S(x) = S0 * exp(-x/T) + Sinf
%
% The two fits are S0, the value at x=0, and the decay constant T. This can be
% used for T2 or ADC fitting.
% This version has a fixed value for S at infinity, which should be the
% Rician noise level. This will be fit, and returned
%
% PJB: Adding and R^2 calculation
% Note the error estimations from this are 1/2 the confidence interval, so
% that the 95% confidence on S0 is in [SO-S0ci, S0+S0ci]. THis is not the
% standard deviation; it depends on the DOF of hte distribution (see tinv)
% Also, this function directly estimates the decay constant T and not the
% rate, which makes it easier to interpret the confidence intervals if
% you're interested in decay constant estimation (e.g., ADC, T2). For one
% degree of freedeom, the 1/2 interval distance is 1.96* standard
% deviation.
% Repackaging to return sd by CRB
function [S0, T, S0crb, Tcrb, Sinf, Sinfcrb, Rsq] = fit_to_exp_decay_3param_const(...
    xvals, yvals, ~, TolFun, TolX, bShowFitting)

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
funcstring = sprintf('b(1)*exp(-x/b(2)) + b(3)');
decayfunc = inline(funcstring, 'b', 'x');

% Initial guess for S0 and R will be based on the full linear fit
[S0initial, Rinitial] = fit_to_exp_decay_2param_linear(...
    xvals, yvals);

N = max(size(xvals)); % Number of points to fit

% Pick a reasonable Rinitial
if ((Rinitial <= 0) || (Rinitial == Inf) || isnan(Rinitial))
    Rinitial = 1/ (xvals(N) - xvals(1));
end
Tinitial = 1/Rinitial;

if (N==2)
    % Best you can do is a linear fit
    T = 1/Rinitial;
    S0 = S0initial;
    S0ci = 0;
    Tci = 0;
    return;
end


beta0(1) = S0initial * yscale_factor; % Initial guess of amplitude
beta0(2) = Tinitial; % T, =1 /R
beta0(3) = 0;
lowBounds = [0.0 Tinitial/100 0];
upBounds = [100 Tinitial*100 max(abs(yvals(:)))];

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
T=fitbeta(2);
Sinf=fitbeta(3)/yscale_factor;

% standard deviation estimate
% Note these values are 1/2 of the 95% convidence interval
%ci = nlparci(fitbeta,residual,J);
[ci, varb, corrb, varinf] = nlparci3( fitbeta, residual, J);
crb = sqrt(diag(varb)).';

S0crb = crb(1);
Tcrb = crb(2);
Sinfcrb = crb(3);

Tci = (T-ci(2,1))/2;
S0ci = (fitbeta(1)-ci(1,1)) / 2 * (1/yscale_factor) ;
Sinfci = (fitbeta(3)-ci(3,1)) / 2 * (1/yscale_factor) ;



% Calculate R-squared
ypred = S0 * exp(-xvals/T) + Sinf;
Rsq = coefficient_of_determination(yvals.', ypred);

% Optional graphic diagnostic
if ( bShowFitting)
    fprintf('S0 = %f +/- %f, T = %f +/- %f\n', S0, S0ci, T, Tci);
    fprintf('Sinf =  %f +/- %f\n', Sinf, Sinfci);
    
    %plot fit
    figure(5)
    plot(xvals, yvals, '-o');
    xlabel('x')
    ylabel('Signal Amplitude')
    hold on
    
    simX = 0:1:max(xvals(:));
    
    plot(simX, S0*exp(-simX/T) + Sinf, ':r');
    hold off
    set(gca, 'ylim', [0 S0] .* 1.1)
    %set(gca, 'xtick', 0:25:150)
    title(sprintf(...
        '2-param R Fit: S0=%.1f+/-%.1f, T=%.1f+/-%.1f, Sinf=%.1f\n',  ...
        S0, S0ci, T, Tci, Sinf));
    legend('data', 'fit')

    %dummy = input('press Return');
end
return;




% Calc R-squared
% Shouuld be in shared file
function R2 = coefficient_of_determination(ymeas, ypred)

% In matlab it is hard to square and sum in one shot, so this is 2-steps:
sumsq = (ymeas - mean(ymeas(:))).^2;
sqres = (ymeas-ypred).^2;

R2 = 1 - sum(sqres(:))/sum(sumsq(:));

return;



