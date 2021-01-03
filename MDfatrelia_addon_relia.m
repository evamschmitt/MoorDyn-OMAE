%% Script to calculate Reliability against Mooring Line Tension Fatigue Failure
% To use this first run MDfatrelia_master to excecute MoorDyn and collect
% rainflow counting data for fatigue

% Uncertainities: 
% 1. Load (In form of Movement Amplitude)
%       -> To reduce MoorDyn and rainflow calculation time, let moordyn  and rainflow run several
%       times in the beginning resulting in saves for a certain amplitude
%       accuracy for R1 and BinCountsVector. The former is done by executing
%       MDfatrelia_master.m. 

%% Check the below is same with MDfatrelia_master.m!

Ax_start = 0;
Axstep = 0.1;
nloop = 200;

Ax_end = nloop*Axstep;

% Fatigue specific Inputs (Factors)
M = 3;              % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN
K = 316;            % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN (CHECK FOR SEMISUB!)
R2 = 8167000;       % Minimum Breaking Strength [N] FOR 90MM R4 STUDLESS CHAIN (e.g. from https://ramnas.com/wp-content/uploads/2012/11/Ramnas-Technical-Broschure.pdf )
R2_base = R2;       % to save original R2 value, when uncertainty is applied later on

%% Uncertainty Distribution Factors for Random Variables
% Give uncertainity distribution factors to determine random values later

% 1. Load = Amplitude -> Weibull Distribution
Amp_scaleParameter = 3;     % just assumption In Weibull analysis, what exactly is the scale parameter, η (Eta)? And why, at t = η , will 63.21% of the population have failed, regardless of the value of the shape parameter, β (Beta)?
Amp_shapeParameter = 2;     % just assumption


% 2. Resistance (Max. endurable fatigue) = reference breaking strength = R2
mean_R2 = R2;
standard_deviation_R2 = 0.05; % just assumption for now


% 3. Miner Sum (Uncertainty from damage calculation procedure ((summing
% up)) ) Lognormal
MinerSum_Mean_of_logarithmic_values = 1;                   % just assumption for now
MinerSum_standard_derivation_of_logarithmic_values = 0.05; % just assumption for now


%% Get further variables from outputfiles
M_R1 = readmatrix('M_R1.xlsx','Sheet',1);
nls = width(M_R1);


%% Calc Reliability against Tension Fatigue -> lots of cases

for j = 1:1000000 % how many iterations to I need to reach convergence? Adjust this number accordingly!
    tic
    %% Generate random values:
    
    % 1. Load = Amplitude -> Weibull Distribution
        Amp_rand_value = wblrnd(Amp_scaleParameter, Amp_shapeParameter);
        % Round rand value, so that it fits pre calculated results:
        Amp_rand_value = round(Amp_rand_value, 1);
        % if rand value is larger than max. calculated value, set rand value to
        % max. calculated value:
        if Amp_rand_value > Ax_end
            Amp_rand_value = Ax_end;    
        end

    % 2. Resistance (Max. endurable fatigue) = reference breaking strength = R2
        R2_rand_value = normrnd(mean_R2, standard_deviation_R2);
        % Apply randomness to R2 defined (base) value
        R2 = R2_base*R2_rand_value;

    % 3. Miner Sum
        MinerSum_rand_value = lognrnd(MinerSum_Mean_of_logarithmic_values, MinerSum_standard_derivation_of_logarithmic_values);

        
        
%% Apply random values





%% Calc Fatigue for current set of random values:

% Get precalculated MoorDyn and rainflow results
% First find out which iteration of MoorDynCalc to use:
    MDit = Amp_rand_value/Axstep;
% Then get rainflow count for that iteration:
    M_R1 = readmatrix('M_R1.xlsx','Sheet',MDit);
    M_BinCountsVector = readmatrix('M_BinCountsVector.xlsx','Sheet',MDit);

len_M_R1 = length(M_R1);


for k = 1:nls % loop through all the line segments

R1 = M_R1(1:len_M_R1,k);
BinCountsVector = M_BinCountsVector(1:len_M_R1,k); % works because R1 and BCV same length.



R = R1/R2;                                  % (R1 = tension range, R2 = reference breaking strength)

% N = max. possible number of cycles
    N = K./(R.^M); %Das ist die Kurve für max. Tension

% Damage Bins -> Gesamtschaden.
    Damage = BinCountsVector./N; % Damage per bin = actual cycles per bin / max. possible cycles (this is per bin)
    Damage = sum(Damage)*MinerSum_rand_value;       % sum the bin damage up to get total damage

% Create Fatigue Damage Vector (Element 1 close to Anchor)
    DamagePerSegment(k, 1) = Damage;                                % Fatigue Damage for considered Runtime

AnnualDamagePerSegment(k, 1) = Damage*365*24*60*60/runtime;     % Fatigue Damage Annual




writematrix(Mfatout, 'result_fatigue_annual.xls');  % Save output matrix to Excel

toc
end

%% Before this create survival matrix that you then later save!

Lifetime_Damage = AnnualDamagePerSegment.*25;                    % for 25years runtime

Survival = ones(nls,1);                                      % Creates Surival Vector with ones (=survival) as default

for 1:nls
    if Lifetime_Damage(1,nls) > 1
    Survival(1,nls) = 0;
    end
end

% save survival to excel
writematrix(Survival,'Survival.xlsx','Sheet',j);



Survival_Out(:, j) = Survival;                              % Add annual damage per segment for this iteration to output matrix
Lifetime_Damage_Out(:, j)  = Lifetime_Damage;                % same for mean tension per segment

writematrix(Survival_Out, 'Survival.xls');  % Save output matrix to Excel
writematrix(Lifetime_Damage_Out, 'Lifetime_Damage.xls');


end

