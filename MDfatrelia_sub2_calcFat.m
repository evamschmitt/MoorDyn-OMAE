
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Run FatigueAnalysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Matlab Scrpit for Fatigue Analysis of MoorDyn Tension Outputs
% Please make sure necessary inputs are correct!
% Make sure to cut away enough start time (with weird results)



%% Convert .out to .txt file

% File zu .txt Format konvertieren (weil writematrix kein .out lesen kann)
file1= OutputFileLocation;
file2=strrep(file1,'.out','.txt');
copyfile(file1, file2)


%% Read in .txt file

% writematrix from .txt File
%Min = dlmread(MDout, ' ', 1, 0);    % creates Matrix from inputfile, separates after ' ' skips the first row and no column
Min = readmatrix(MDout);
Min(1,:) = [];
%plot(Min)

%% Set Start and End Timestep
% Set StartTimeStep
STS = ST/dt;
% Set Cut End Time Steps
CETS = CET/dt;
lenm = length(Min);
ETS = lenm-CETS;

%% Create Vectors and Matrices from .txt file

% Define border of output types
tc = 1;                     % time column
sp = 2;                     % start position column
ep = (nls+1)*3 +1;          % end position column
st = ep + 1;                % start tension column
et = st + nls -1;           % end tension column


tenperseg = Min(STS:ETS,st:et);          % Create segment tension matrix

clear Min;                  % clear large matrix to save space

tenmean = mean(tenperseg, 1);

%% Damage Vector prep
%Create Damage Vector for later filling by the for loop
%DamagePerSegment = [];
DamagePerSegment = zeros(nls, 1);
AnnualDamagePerSegment = zeros(nls, 1);

%% Time prep     
runtime = length(tenperseg)*dt;                % get considered runtime in s

%% Fatigue Analysis Loop 

for k = 1:nls 
Z = tenperseg(:,k);                 % pick tension per segment

% Rainflow Counting
[C,BinCounts,BinEdges] = rainflow(Z); %AH, hier C relevante outputmatrix
BinCountsVector = sum(BinCounts,2);         % Gibt BinCounts für Bins in Vektor an. = N



% BinMean (Vektor mit Tensionmittelwerten von BinEdges) erstellen
BinMean = BinEdges + (BinEdges(2) - BinEdges(1))/2;
BinMean(end) = [];

%% Calculate Damage

% Formel TN-Kurve
% NR^M = K
% N = Number of Cycles
% R = Ratio of Tension Range to Reference Breaking Strength
% M, K = from table API RP 2SK, for chain common studlink


% NR^M = K, 
R1 = BinMean;
R = R1/R2;                                  % (R1 = tension range, R2 = reference breaking strength)




N = K./(R.^M); %Das ist die Kurve für max. Tension


% Damage Bins -> Gesamtschaden.
Damage = BinCountsVector./N;
Damage = sum(Damage);

% Create Fatigue Damage Vector (Element 1 close to Anchor)
DamagePerSegment(k, 1) = Damage;                                % Fatigue Damage for considered Runtime

AnnualDamagePerSegment(k, 1) = Damage*365*24*60*60/runtime;     % Fatigue Damage Annual




%% Visualisierung
%histogram('BinEdges',BinEdges','BinCounts',sum(BinCounts,2))
%xlabel('Stress Range')  
%ylabel('Cycle Counts')
end


% Collect Fatigue Data in Matrix


Mfatout(:, j)  = AnnualDamagePerSegment;        % Add annual damage per segment for this iteration to output matrix

Mtenmean(:, j)  = tenmean;                      % same for mean tension per segment

writematrix(Mfatout, 'result_fatigue_annual.xls');  % Save output matrix to Excel
writematrix(Mtenmean, 'result_tension_mean.xls');


disp(['Fatigue Calculation Loop (', num2str(j), ') done']);