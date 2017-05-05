function plotNavigation(navSolutions, settings)
%Functions plots variations of coordinates over time and a 3D position
%plot. It plots receiver coordinates in UTM system or coordinate offsets if
%the true UTM receiver coordinates are provided.
%
%plotNavigation(navSolutions, settings)
%
%   Inputs:
%       navSolutions    - Results from navigation solution function. It
%                       contains measured pseudoranges and receiver
%                       coordinates.
%       settings        - Receiver settings. The true receiver coordinates
%                       are contained in this structure.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

% CVS record:
% $Id: plotNavigation.m,v 1.1.2.25 2006/08/09 17:20:11 dpl Exp $

%% Plot results in the necessary data exists ==============================
if (~isempty(navSolutions))

    %% If reference position is not provided, then set reference position
    %% to the average postion
    if isnan(settings.truePosition.E) || isnan(settings.truePosition.N) ...
            || isnan(settings.truePosition.U)

        %=== Compute mean values ==========================================
        % Remove NaN-s or the output of the function MEAN will be NaN.
        refCoord.E = mean(navSolutions.E(~isnan(navSolutions.E)));
        refCoord.N = mean(navSolutions.N(~isnan(navSolutions.N)));
        refCoord.U = mean(navSolutions.U(~isnan(navSolutions.U)));

        %Also convert geodetic coordinates to deg:min:sec vector format
        meanLongitude = dms2mat(deg2dms(...
            mean(navSolutions.longitude(~isnan(navSolutions.longitude)))), -5);
        meanLatitude  = dms2mat(deg2dms(...
            mean(navSolutions.latitude(~isnan(navSolutions.latitude)))), -5);

        refPointLgText = ['Mean Position\newline  Lat: ', ...
            num2str(meanLatitude(1)), '{\circ}', ...
            num2str(meanLatitude(2)), '{\prime}', ...
            num2str(meanLatitude(3)), '{\prime}{\prime}', ...
            '\newline Lng: ', ...
            num2str(meanLongitude(1)), '{\circ}', ...
            num2str(meanLongitude(2)), '{\prime}', ...
            num2str(meanLongitude(3)), '{\prime}{\prime}', ...
            '\newline Hgt: ', ...
            num2str(mean(navSolutions.height(~isnan(navSolutions.height))), '%+6.1f')];
    else
        refPointLgText = 'Reference Position';
        refCoord.E = settings.truePosition.E;
        refCoord.N = settings.truePosition.N;
        refCoord.U = settings.truePosition.U;
    end

    figureNumber = 300;
    % The 300 is chosen for more convenient handling of the open
    % figure windows, when many figures are closed and reopened. Figures
    % drawn or opened by the user, will not be "overwritten" by this
    % function if the auto numbering is not used.

    %=== Select (or create) and clear the figure ==========================
    fh=figure(figureNumber);
    clf   (figureNumber);
    set   (figureNumber, 'Name', 'Navigation solutions');

    %Position the figure at the center
    screenSize=get(0,'ScreenSize');
    figWidth=900;
    figHeight=600;
    figPosition=[0.5*(screenSize(3)-figWidth),...
        0.5*(screenSize(4)-figHeight),figWidth,figHeight];
    set(fh,'Position',figPosition);

    %--- Draw axes --------------------------------------------------------


    handles(1) = axes('Position',[0.1 0.75 0.80 0.20],'FontSize',8);
    handles(2) = axes('Position',[0.1 0.55 0.80 0.20],'FontSize',8);
    handles(3) = axes('Position',[0.1 0.05 0.5 0.5],'FontSize',8);
    handles(4) = axes('Position',[0.6 0.075 0.35 0.4],'FontSize',8);

    %% Plot all figures =======================================================

    %--- Coordinate differences in UTM system -----------------------------
    plot(handles(1), [(navSolutions.E - refCoord.E)', ...
        (navSolutions.N - refCoord.N)',...
        (navSolutions.U - refCoord.U)']);

    title (handles(1), 'Coordinates variations in UTM system, Receiver Clock Error');
    legend(handles(1), 'E', 'N', 'U');
    xlabel(handles(1), ['Measurement period: ', ...
        num2str(settings.navSolPeriod), 'ms']);
    ylabel(handles(1), 'Variations (m)');
    grid  (handles(1));
    axis  (handles(1), 'tight');

    %--- Oscillator Error Plot --------------------------------------------

    diffSampleCount = diff(navSolutions.absoluteSample);
    diffGPSTOW      = diff(navSolutions.GPSTOW);
    trueClock   = diffSampleCount./diffGPSTOW;
    clockError  = trueClock - settings.samplingFreq;
    clockErrorPpm = (clockError/settings.samplingFreq)* 1.0e6;
    clockErrorPpm = [0 clockErrorPpm];
    plot(handles(2), clockErrorPpm,'b');

    xlabel(handles(2), ['Measurement period: ', ...
        num2str(settings.navSolPeriod), 'ms']);
    ylabel(handles(2), 'Clock Error (ppm)');
    grid  (handles(2));
    axis  (handles(2), 'tight');

    %--- Position plot in UTM system --------------------------------------
    plot3 (handles(3), navSolutions.E - refCoord.E, ...
        navSolutions.N - refCoord.N, ...
        navSolutions.U - refCoord.U, '+');
    hold  (handles(3), 'on');
    %Plot the reference point
    plot3 (handles(3), 0, 0, 0, 'r+', 'LineWidth', 1.5, 'MarkerSize', 10);
    hold  (handles(3), 'off');

    view  (handles(3), 0, 90);
    axis  (handles(3), 'equal');
    grid  (handles(3), 'minor');

    legend(handles(3),'Location','NorthEastOutside', 'Measurements', refPointLgText);

    title (handles(3), 'Positions in UTM system (3D plot)');
    xlabel(handles(3), 'East (m)');
    ylabel(handles(3), 'North (m)');
    zlabel(handles(3), 'Upping (m)');

    %--- Satellite sky plot -----------------------------------------------
    skyPlot(handles(4), ...
        navSolutions.channel.az, ...
        navSolutions.channel.el, ...
        navSolutions.channel.K(:, 1));

    title (handles(4), ['Sky plot (mean PDOP: ', ...
        num2str(mean(navSolutions.DOP(2,:))), ')']);

else
    disp('plotNavigation: No navigation data to plot.');
end % if (~isempty(navSolutions))
