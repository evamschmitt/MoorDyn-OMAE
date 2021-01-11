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
nloop = 198;

Ax_end = nloop*Axstep;

% give simulation time [s]
runtime = 1200;

% Fatigue specific Inputs (Factors)
M = 3;              % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN
K = 316;            % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN (CHECK FOR SEMISUB!)
R2 = 8167000;       % Minimum Breaking Strength [N] FOR 90MM R4 STUDLESS CHAIN (e.g. from https://ramnas.com/wp-content/uploads/2012/11/Ramnas-Technical-Broschure.pdf )


%% Uncertainty Distribution Factors for Random Variables
% Give uncertainity distribution factors to determine random values later

% 1. Load = Normal Distribution
Amp_mean = 10;     
Amp_variance = 3;    


% 2. Uncertainty Resistance (how much damage can the system take?)
% Lognormal Distribution
% Mu and Sigma parameters therefor
% the below are calculated for 1 mean and 0.05 variance
% see matlab webpage help on how to calculate
mu = -0.0244;
sigma = 0.2209;


%% Get further variables from outputfiles
M_R1 = readmatrix('M_R1.xlsx','Sheet',1);
nls = width(M_R1);
%nls = 50;

%% Calc Reliability against Tension Fatigue -> lots of cases

runs = 10000; %10000

% Prepare vector to save all the results
Survival_Average = zeros(nls,1);
Lifetime_Damage_Average = zeros(nls,1);

% delete old excel output file so no numbers are mistaken for the new ones
delete('Survival_Average.xls');
delete('Lifetime_Damage_Average.xls');

% For reproducability of results, random numbers are always generated the
% same way
rng('default');

for j = 1:runs  % how many iterations to I need to reach convergence? Adjust this number accordingly!
    tic
    %% Generate random values:
    
    % 1. Load = Amplitude -> Normal Distribution
        Amp_rand_value = normrnd(Amp_mean, Amp_variance);
        % Round rand value, so that it fits pre calculated results:
        Amp_rand_value = round(Amp_rand_value, 1);
        % if rand value is larger than max. calculated value, set rand value to
        % max. calculated value:
        if Amp_rand_value > Ax_end
            Amp_rand_value = Ax_end;    
        end
        if Amp_rand_value < 0
            Amp_rand_value = 0;
        end
            
        

    % 2. Resistance (Max. endurable fatigue) rand value (vary around the
    % total damage 1)
    resistance_rand = lognrnd(mu,sigma);
           

%% Calc Fatigue for current set of random values:

% Get precalculated MoorDyn and rainflow results
% First find out which iteration of MoorDynCalc to use:
    MDit = Amp_rand_value/Axstep + 1; %+1 because sheets start from sheet 1, so if amp is roundet zero, it has a sheet.
    MDit = round(MDit); %Maybe round because Sheet function below can take only whole numbers, so the zeros are taken away? does this matter?
% Then get rainflow count for that iteration and apply uncertainty to it:
    M_R1 = readmatrix('M_R1.xlsx','UseExcel',1,'Sheet',MDit);
    M_BinCountsVector = readmatrix('M_BinCountsVector.xlsx','UseExcel',1,'Sheet',MDit);

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

Lifetime_Damage = AnnualDamagePerSegment.*25;                    % for 25years runtime

Survival = ones(nls,1);                                      % Creates Surival Vector with ones (=survival) as default

for k = 1:nls
    if Lifetime_Damage(k, 1) > resistance_rand % value should be around 1
    Survival(k,1) = 0;
    end
end


% save survival to excel
Survival_Average = Survival_Average + Survival./runs;                              % Add annual damage per segment for this iteration to output matrix
Lifetime_Damage_Average = Lifetime_Damage_Average + Lifetime_Damage./runs;                % same for mean tension per segment

% Survival_Average
% Lifetime_Damage_Average
% %Lifetime_Damage
% MinerSum_rand_value
fprintf('loop nuber')
j
toc

end


writematrix(Survival_Average, 'Survival_Average.xls');  % Save output matrix to Excel
writematrix(Lifetime_Damage_Average, 'Lifetime_Damage_Average.xls');
