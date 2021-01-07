%% Info: Integrated Script to run MoorDyn, run FatigueAnalysis and store results

%% Setup
% Inputfile: lines.txt
% Results: look at Line1.out or run PlotMoorLine(...).m
% Line1.out und Line1.txt schliessen vor Start, 
% damit neue Outputs geschrieben werden können!



%% Make necessary inputs:


% MoorDyn specific Inputs

% give simulation time [s]
simtime = 1200;     %20min

% Cut out start and end time of simulation for Fatigue Calc
ST = 60;            % Start Time in [s] (cut out time before that from analysis)
CET = 60;           % Cut End Time [s] (cut out so much end time from analysis)

% Time Step Size and Number
dt =  0.01;              %0.01;                          % coupling time step size (time between MoorDyn calls)
Nts = (simtime+ST+CET)/dt;              %37200;                  % number of coupling time steps (add 120s to cut away from simulation at start and ending)

% Give Number of Line Segments (also change in lines.txt (Inputfile))
nls = 50;                       % 100

% Give paths
% Give MoorDyn Library paths
fileLinesdll = 'Lines.dll';
fileMoorDynh = 'MoorDyn.h';
% Give Output File paths
OutputFileLocation = 'Mooring/Line1.out';
MDout = 'Mooring/Line1.txt';


% Fatigue specific Inputs

% Give Factors
M = 3;              % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN
K = 316;            % Factor siehe API RP 2SK - FUER COMMON STUDLESS LINK CHAIN (CHECK FOR SEMISUB!)
R2 = 8167000;       % Minimum Breaking Strength [N] FOR 90MM R4 STUDLESS CHAIN (e.g. from https://ramnas.com/wp-content/uploads/2012/11/Ramnas-Technical-Broschure.pdf )



%% Give Floater Movement
Ax_start = 10;                                  % Amplitude Surge X [m] (Start, can be stepped up later)
Ax = Ax_start;
Ay_start = 0;                                     % Amplitude Surge Y [m] (Start, can be stepped up later)
Ay = Ay_start;  
P = 60;                                  % Period [s]


%% Give Loop Definition

nloop = 1;                              % number of loops
Axstep = 0;                              % per loop: how much is Ax [m] stepped up
Aystep = 0;                              % per loop: how much is Ay [m] stepped up

%% Prep Fatigue Output Matrix

Mfatout = zeros ([nls nloop]);

Mtenmean = zeros ([nls nloop]);

% First of all, delete old files before writing new ones, otherwise old
% content still possibly in there!
delete('M_R1.xlsx');
delete('M_BinCountsVector.xlsx');
delete('result_fatigue_annual.xls');
delete('result_tension_mean.xls');

%% Run multiple Simulations Loop

for j=1:nloop


% Define position and velocity variables %rot=rotation v= velocity pos=position xyz = coordinates
posx = 0;
posy = 0;
posz = 0;
rotposx = 0;
rotposy = 0;
rotposz = 0;
vx = 0;
vy = 0;
vz = 0;
rotvx = 0;
rotvy = 0;
rotvz = 0;

%% Run MoorDyn
tic
run('MDfatrelia_sub1_runMDgetTen.m');
toc    

%% Run FatigueAnalysis
run('MDfatrelia_sub2_calcFat.m');

%% Step up Amplitude for next loop

Ax = Ax + Axstep;
Ay = Ay + Aystep;

%% Plot
plot(DamagePerSegment);
xlabel('Line Segment Number ( 1 is close to Anchor)');
ylabel('Fatigue Damage Per Segment ( 1 = Failure due to Fatigue)');

plot(AnnualDamagePerSegment);
xlabel('Line Segment Number ( 1 is close to Anchor)');
ylabel('Annual Fatigue Damage Per Segment ( 1 = Failure due to Fatigue)');

disp(['Main Loop (', num2str(j), ') done']);
end


disp('Script done');