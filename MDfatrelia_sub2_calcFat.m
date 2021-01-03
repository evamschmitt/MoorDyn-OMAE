
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

%% Create Matrix to store Rainflow results (for later processing in reliability process)

M_R1 = zeros(nls, 10);                 % 10 placeholder here, not clear how many bincounts there are/will be. Actually, enlarge matrix later if vectors grow dynamically.
M_BinCountsVector = zeros(nls, 10);    % 10 placeholder here, not clear how many bincounts there are/will be.

%% Fatigue Analysis Loop 

for k = 1:nls 
Z = tenperseg(:,k);                 % pick tension per segment

% Rainflow Counting
[C,BinCounts,BinTensionRange] = rainflow(Z); %AH, hier C relevante outputmatrix
BinCountsVector = sum(BinCounts,2);         % Gibt BinCounts für Bins in Vektor an. = N



% BinMean (Vektor mit Tensionmittelwerten von BinEdges) erstellen
BinMeanTensionRange = BinTensionRange + (BinTensionRange(2) - BinTensionRange(1))/2;
BinMeanTensionRange(end) = [];

%% Calculate Damage

% Formel TN-Kurve
% NR^M = K
% N = Number of Cycles
% R = Ratio of Tension Range to Reference Breaking Strength
% M, K = from table API RP 2SK, for chain common studlink


%R = Ratio of tension range (double amplitude) to reference breaking strength (RBS).
R1 = BinMeanTensionRange;


R = R1/R2;                                  % (R1 = tension range, R2 = reference breaking strength)


%Write calc results for R1 and BinCountsVector to matrix now to write later in sheet
%processing in reliability calculation

lenR1 = length(R1);

M_R1(1:lenR1,k) = R1;
M_BinCountsVector(1:lenR1,k) = BinCountsVector; % works because R1 and BCV same length.


% N = max. possible number of cycles
N = K./(R.^M); %Das ist die Kurve für max. Tension


% Damage Bins -> Gesamtschaden.
Damage = BinCountsVector./N; % Damage per bin = actual cycles per bin / max. possible cycles (this is per bin)
Damage = sum(Damage);       % sum the bin damage up to get total damage

% Create Fatigue Damage Vector (Element 1 close to Anchor)
DamagePerSegment(k, 1) = Damage;                                % Fatigue Damage for considered Runtime

AnnualDamagePerSegment(k, 1) = Damage*365*24*60*60/runtime;     % Fatigue Damage Annual




%% Visualisierung
%histogram('BinEdges',BinEdges','BinCounts',sum(BinCounts,2))
%xlabel('Stress Range')  
%ylabel('Cycle Counts')
end

% for later reliability analysis write R1 and BinCountsVector Matrices to
% Excel spreadsheet (1st run = spreadsheet 1, 2nd = ...)
writematrix(M_R1,'M_R1.xlsx','Sheet',j);
writematrix(M_R1,'M_BinCountsVector.xlsx','Sheet',j);


% Collect Fatigue Data in Matrix


Mfatout(:, j)  = AnnualDamagePerSegment;        % Add annual damage per segment for this iteration to output matrix

Mtenmean(:, j)  = tenmean;                      % same for mean tension per segment

writematrix(Mfatout, 'result_fatigue_annual.xls');  % Save output matrix to Excel
writematrix(Mtenmean, 'result_tension_mean.xls');


disp(['Fatigue Calculation Loop (', num2str(j), ') done']);