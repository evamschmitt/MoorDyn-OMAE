


% Define position and velocity vectors
pos = [posx posy posz rotposx rotposy rotposz];     %Um alle xyz richtungen separat ansteuern
v = [vx vy vz rotvx rotvy rotvz];                   %zu kønnen %rot=rotation v= velocity pos=position xyz = coordinates


Vdt = zeros(Nts,1);                    % time step array

FLines_temp = zeros(1,6);           % going to make a pointer so LinesCalc can modify FLines
FLines_p = libpointer('doublePtr',FLines_temp);  % access returned value with FLines_p.value

%% Initialization
loadlibrary(fileLinesdll,fileMoorDynh);     % load MoorDyn DLL


calllib('Lines','LinesInit',pos,v)   % initialize MoorDyn 
    
%% MoorDyn Simulation Loop
for i=1:Nts        
    calllib('Lines', 'LinesCalc', pos, v, FLines_p, Vdt(i), dt);  % some MoorDyn time stepping
    % Update position
    posx = Ax*sin(1.5 + P/(2*pi*dt)*i);      % x position calculation
    %posy = Ay*sin(1.5 + P/(2*pi*dt)*i);     % y position calculation
    %Update vectors for MoorDyn
    pos = [posx posy posz rotposx rotposy rotposz];
    
   Vdt(i+1) = dt*i;                 % store time
end
%% Ending
calllib('Lines','LinesClose');       % close MoorDyn
unloadlibrary Lines;              % unload library (never forget to do this!)


disp(['MoorDyn Loop (', num2str(j), ') done'])

