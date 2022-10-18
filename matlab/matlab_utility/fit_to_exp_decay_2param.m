% This is a generic function for fitting to an exponential decay with two
% parameters. It could be easily extended to 3-parameter to account for
% noise. The function is:
%
%   S(x) = S0 * exp(-x*R)
%
% The two fits are S0, the value at x=0, and the decay rate R. This can be
% used for T2 or ADC fitting.
function [S0, R, S0sd, Rsd, Sinf, Sinfsd] = fit_to_exp_decay_2param(...
    xvals, yvals, dummy, TolFun, TolX, bShowFitting)


% dummy, TolFun, TolX, and bShowFitting are all optional
if nargin<6
    bShowFitting = 1;
end
if nargin<5 
    TolX = [];
end
if nargin<4
    TolFun = [];
end
if nargin<3
    dummy = [];
end



% This is a special case of the fixed noise version, where Sinf = 0;
Sinf = 0;
Sinfsd = 0;
[S0, R, S0sd, Rsd] = fit_to_exp_decay_2param_fixednoise(...
    xvals, yvals, Sinf, TolFun, TolX, bShowFitting);
