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
Amp_stand_deviation = 3;    


%% Get further variables from outputfiles
M_R1 = readmatrix('M_R1.xlsx','Sheet',1);
nls = width(M_R1);
%nls = 100;

%% Calc Reliability against Tension Fatigue -> lots of cases

runs = 500; %500

% Prepare vector to save all the results
Damage_for_fs = zeros(nls,runs);

% delete old excel output file so no numbers are mistaken for the new ones
delete('Damage_for_fs.xlsx');

% For reproducability of results, random numbers are always generated the
% same way
rng('default');

for j = 1:runs  % how many iterations to I need to reach convergence? Adjust this number accordingly!
    tic
    %% Generate random values:
    
    % 1. Load = Amplitude -> Normal Distribution
        Amp_rand_value = normrnd(Amp_mean, Amp_stand_deviation);
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


end


Lifetime_Damage = AnnualDamagePerSegment.*25;                    % for 25years runtime
Damage_for_fs(:,j) = Lifetime_Damage;
xlswrite('Damage_for_fs.xlsx',Damage_for_fs) % Save output matrix to Excel

fprintf('loop nuber')
j
toc

end
Lifetime_Damage_Average
Damage_for_fs


