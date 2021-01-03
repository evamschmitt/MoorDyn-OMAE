%% Script to calculate Reliability against Mooring Line Tension Fatigue Failure
% To use this first run MDfatrelia_master to excecute MoorDyn and collect
% rainflow counting data for fatigue

% Uncertainities: 
% 1. Load (In form of Movement Amplitude)
%       -> To reduce MoorDyn and rainflow calculation time, let moordyn  and rainflow run several
%       times in the beginning resulting in saves for a certain amplitude
%       accuracy for R1 and BinCountsVector. The former is done by executing
%       MDfatrelia_master.m. 

%% Check this is same with MDfatrelia_master.m!

Ax_start = 0;
Axstep = 0.1;
nloop = 200;

Ax_end = nloop*Axstep;

%% Uncertainty Distributions

% 1. Amplitude -> Weibull Distribution
Amp_scaleParameter = 3;     % just assumption In Weibull analysis, what exactly is the scale parameter, η (Eta)? And why, at t = η , will 63.21% of the population have failed, regardless of the value of the shape parameter, β (Beta)?
Amp_shapeParameter = 2;     % just assumption
Amp_rand_value = wblrnd(Amp_scaleParameter, Amp_shapeParameter);
% Round rand value, so that it fits pre calculated results:
Amp_rand_value = round(Amp_rand_value, 1);
if Amp_rand_value > Ax_end
    Amp_rand_value = Ax_end;    % if rand value is larger than max. calculated value, set rand value to max. calculated value.
end



% 2. Max. endurable fatigue (resistance) = reference breaking strength = R2
%R2_Distribution =
