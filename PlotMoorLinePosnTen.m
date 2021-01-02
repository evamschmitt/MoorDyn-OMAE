%% Matlab Skript um MoorDyn .out Datei zu visualisieren
% Please make sure necessary inputs are correct!
% Run "RunMoorDyn.m" befor executing this script.
%% Make necessary inputs:

% Give Number of Line Segments
nls = 50;

% Give File paths
OutputFileLocation = 'Mooring/Line1.out';
TxtFileLocation = 'Mooring/Line1.txt';

% Print speed (original speed =1, increase for faster print)
ps = 3;





%% Convert .out to .txt file

% File zu .txt Format konvertieren (weil writematrix kein .out lesen kann)
file1= OutputFileLocation;
file2=strrep(file1,'.out','.txt');
copyfile(file1,file2)


%% Read in .txt file

% writematrix from .txt File
M = dlmread(TxtFileLocation, ' ', 1, 0);    % creates Matrix from inputfile, separates after ' ' skips the first row and no column



%% Create Vectors and Matrices from .txt file

% Define Time Step Variable
ts = 1;

% Define border of output types
tc = 1;                     % time column
sp = 2;                     % start position column
ep = (nls+1)*3 +1;          % end position column
st = ep + 1;                % start tension column
et = st + nls -1;           % end tension column

% Create time vector from Matrix
time = M(:, tc);            % Gets all Data from tc(time)column
LT = length(time);          % Gets runtime

% Create position vectors
Xp = M(ts,sp:3:ep);         % Create X node position vector from Matrix (for ts row, starting from sp column, every third element, until ep)
Yp = M(ts,(sp+1):3:ep);     % Create Y node position vector
Zp = M(ts,(sp+2):3:ep);     % Create Z node position vector

% Create tension vector
ten = M(ts,st:et);          % Create segment tension vector
%fliplr(ten);                  % Inverse tension vector for better visualization

% Create segments vector
segments = 0:(nls-1);       % Create segment vector (used for plotting ten later)
%segments(end:-1:1);        % Inverse segments vector for better
%visualization doesnt work atm, why??

%% Plot ~

% Set up figure(s)
figure
spp = subplot(4,1,1);       %Sub Plot (Line) Position
spp2 = subplot(4,1,2);      %Sub Plot (Line) Position from side
spt = subplot(4,1,3);       %Sub Plot (Line) Tension
spt2 = subplot(4,1,4);      %Sub Plot (Line) Tension Time Record
xlabel(spp,'x in m');
ylabel(spp,'y in m');
xlabel(spp2,'x in m');
ylabel(spp2,'water depths in m');
xlabel(spt,'mooring segments (0 = close to anchor)');
ylabel(spt,'tension in N');
hold(spp,'on');
hold(spp2,'on')
hold(spt,'on')
grid(spp,'on')
grid(spp2,'on')
grid(spt,'on')
%axis([-1000  1000    -1000  1000   -350  50])

%Update figures
for k = 1 : (LT/ps)
%2D Plot
  PlotPos = plot(spp,Xp,Yp,'-ob');          % Plot Sub Plot (Line) Position
  PlotPos2 = plot(spp2,Xp,Zp,'-ob');          % Plot Sub Plot (Line) Position
  PlotTen = plot(spt,segments,ten,'-xk');   % Plot Sub Plot (Line) Tension
  

% Plot Tension History
if k == 1
    % Create tension Matrix
    tenmat = M(1:LT,st:et);         % Skip over the first minute
    plot (time, tenmat);   
    xlabel('time in s');
    ylabel('tension in N');
    title('Tension over Time');
    legend
end
%plot(,0,  '-or');



hold off
  title(spp,sprintf('Mooring Line Position Bird''s Eye view, t = %.1f', time(ts)) );
  title(spp2,sprintf('Mooring Line Position Side View, t = %.1f', time(ts)) );
  title(spt,sprintf('Mooring Line Tension, t = %.1f', time(ts)) );
  hold all
  pause( 0.1 );
  
  %3D Plot (if it freezes just click on the plot and it continues, still just stops
  %3D Plot throws error into plotten, maybe try to integrate 3D Plot later

  
  % Step up time
  ts = ts + ps;
  
  % Update position vectors
  Xp = M(ts,sp:3:ep);         % Update X node position vector from Matrix (for ts row, starting from sp column, every third element, until ep)
  Yp = M(ts,(sp+1):3:ep);     % Update Y node position vector
  Zp = M(ts,(sp+2):3:ep);     % Update Z node position vector

  % Update tension vector
  ten = M(ts,st:et);
  %fliplr(ten);                  % Inverse tension vector for better
                                 %visualization doesnt work right now
  
delete(PlotPos);
delete(PlotPos2);
delete(PlotTen);
%delete(PlotPosNoSubPlot);      % not currently used

end

