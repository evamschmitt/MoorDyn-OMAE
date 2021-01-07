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

% give simulation time [s]
runtime = 300;

% Fatigue specific Inputs (Factors)
M = 3;              % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN
K = 316;            % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN (CHECK FOR SEMISUB!)
R2 = 8167000;       % Minimum Breaking Strength [N] FOR 90MM R4 STUDLESS CHAIN (e.g. from https://ramnas.com/wp-content/uploads/2012/11/Ramnas-Technical-Broschure.pdf )
R2_base = R2;       % to save original R2 value, when uncertainty is applied later on

%% Uncertainty Distribution Factors for Random Variables
% Give uncertainity distribution factors to determine random values later

% 1. Load = Amplitude -> Weibull Distribution
Amp_scaleParameter = 2;     % just assumption In Weibull analysis, what exactly is the scale parameter, η (Eta)? And why, at t = η , will 63.21% of the population have failed, regardless of the value of the shape parameter, β (Beta)?
Amp_shapeParameter = 1;     % just assumption

% 1.b Uncertainty for Simplified Approach to Load (having pre-defined, rounded
% values)
mean_SimAppLoad = 0;
standard_deviation_SimAppLoad = 0.05;


% 2. Resistance (Max. endurable fatigue) = reference breaking strength = R2
mean_R2 = R2;
standard_deviation_R2 = 0.05; % just assumption for now


% 3. Miner Sum (Uncertainty from damage calculation procedure ((summing
% up)) ) Lognormal
MinerSum_Mean_of_logarithmic_values = 0;   % needs to be zero so average is 1                % just assumption for now
MinerSum_standard_derivation_of_logarithmic_values = 0.05; %0.05; % just assumption for now


%% Get further variables from outputfiles
M_R1 = readmatrix('M_R1_1sec.xlsx','Sheet',1);
nls = width(M_R1);
%nls = 50;

%% Calc Reliability against Tension Fatigue -> lots of cases

runs = 10000; %10000

% Prepare vector to save all the results
Survival_Average = zeros(nls,1);
Lifetime_Damage_Average = zeros(nls,1);

% Prepare things for choosing Period.
Periods = [1 2 3 5 10 30 60 300]; % create vector with chosen periods
Periods = flip(Periods); % for more realistic loads
Per_scaleParameter = 2;
Per_shapeParameter = 1;

% Number of runs to determine lifetime damage for one scenario:
runs_for_lifetime_damage = 20;

for j = 1:runs  % how many iterations to I need to reach convergence? Adjust this number accordingly!
    tic
    Lifetime_Damage = 0; %reset lifetime damage for next iteration
    
    for l = 1:runs_for_lifetime_damage
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
        
        %1.a periode
        
    % 1.b Uncertainty for Simplified Approach to Load (having pre-defined, rounded
    % values)
    SimAppLoad_rand_value = lognrnd(mean_SimAppLoad, standard_deviation_SimAppLoad);
    

    % 2. Resistance (Max. endurable fatigue) = reference breaking strength = R2
        %R2_rand_value = lognrnd(mean_R2/1000000, standard_deviation_R2); %->doesn't work become infinite, instead:
        R2_rand_value = lognrnd(0, standard_deviation_R2)*mean_R2; %maybe
        %isn't accurate, since 
        %R2_rand_value = lognrnd(mean_R2/1000000, standard_deviation_R2);
        %-> leads to very high values, is this correct??
        % Apply randomness to R2 defined (base) value
        %R2 = R2_rand_value;
        
    % 3. Miner Sum
        MinerSum_rand_value = lognrnd(MinerSum_Mean_of_logarithmic_values, MinerSum_standard_derivation_of_logarithmic_values);

        
        
%% Apply random values





%% Calc Fatigue for current set of random values:

% Get precalculated MoorDyn and rainflow results
% First find out which iteration of MoorDynCalc to use:
    MDit = Amp_rand_value/Axstep + 1; %+1 because sheets start from sheet 1, so if amp is roundet zero, it has a sheet.
    MDit = round(MDit); %Maybe round because Sheet function below can take only whole numbers, so the zeros are taken away? does this matter?



% Prepare to get period
Per_Weibull = wblrnd(Per_scaleParameter, Per_shapeParameter);
% round rand value
        Per_Weibull = round(Per_Weibull, 0);
        % if rand value is larger than max. calculated value, set rand value to
        % max. calculated value:
        len_Periods = length(Periods);
        if Per_Weibull > len_Periods
            Per_Weibull = len_Periods;    
        end
        if Per_Weibull == 0 %because I have no zero period, we start at place one
            Per_Weibull = 1;
        end
        
 % Get according Period to Distribution
 Per_Rand = Periods(1, Per_Weibull);       
        
%         
% M_R1_xls_name = fullfile('M_R1_', Per_Rand, 'sec.xlsx');
% M_BinCountsVector_name = fullfile('M_BinCountsVector', Per_Rand, 'sec.xlsx');
Per_Rand = num2str(Per_Rand); %convert to text so can be processed below
M_R1_xls_name = append('M_R1_', Per_Rand, 'sec.xlsx');
M_BinCountsVector_name = append('M_BinCountsVector_', Per_Rand, 'sec.xlsx');


    
    % Then get rainflow count for that iteration and apply uncertainty to it:
    M_R1 = readmatrix(M_R1_xls_name,'Sheet',MDit)*SimAppLoad_rand_value;
    M_BinCountsVector = readmatrix(M_BinCountsVector_name,'Sheet',MDit)*SimAppLoad_rand_value;

len_M_R1 = length(M_R1);


for k = 1:nls % loop through all the line segments

R1 = M_R1(1:len_M_R1,k);
BinCountsVector = M_BinCountsVector(1:len_M_R1,k); % works because R1 and BCV same length.



R = R1/R2;                                  % (R1 = tension range, R2 = reference breaking strength)

% N = max. possible number of cycles
    N = K./(R.^M); %Das ist die Kurve für max. Tension

% Damage Bins -> Gesamtschaden.
    Damage = BinCountsVector./N; % Damage per bin = actual cycles per bin / max. possible cycles (this is per bin)
    Damage = sum(Damage);       % sum the bin damage up to get total damage

% Create Fatigue Damage Vector (Element 1 close to Anchor)
    DamagePerSegment(k, 1) = Damage;                                % Fatigue Damage for considered Runtime

AnnualDamagePerSegment(k, 1) = Damage*365*24*60*60/runtime;     % Fatigue Damage Annual




%writematrix(Mfatout, 'result_fatigue_annual.xls');  % Save output matrix
%to Excel
% no need since already done in previous fat calcs.


end

%% Before this create survival matrix that you then later save!

Lifetime_Damage = Lifetime_Damage + AnnualDamagePerSegment.*25./runs_for_lifetime_damage; %   % for 25years runtime
    end
Survival = ones(nls,1);                                      % Creates Surival Vector with ones (=survival) as default

for k = 1:nls
    if Lifetime_Damage(k, 1) > MinerSum_rand_value % MinerSum_rand_value should be around 1, Distribution for Uncertainty Miner Sum
    Survival(k,1) = 0;
    end
end


% save survival to excel
Survival_Average = Survival_Average + Survival./runs;                              % Add annual damage per segment for this iteration to output matrix
Lifetime_Damage_Average = Lifetime_Damage_Average + Lifetime_Damage./runs;                % same for mean tension per segment

Survival_Average
Lifetime_Damage_Average
%Lifetime_Damage
MinerSum_rand_value
j
toc



end


writematrix(Survival_Average, 'Survival_Average.xls');  % Save output matrix to Excel
writematrix(Lifetime_Damage_Average, 'Lifetime_Damage_Average.xls');
