function plotTracking(channelList, trackResults, settings)
%This function plots the tracking results for the given channel list.
%
%plotTracking(channelList, trackResults, settings)
%
%   Inputs:
%       channelList     - list of channels to be plotted.
%       trackResults    - tracking results from the tracking function.
%       settings        - receiver settings.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
%
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis
% Modified by Eric Horacek
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

%CVS record:
%$Id: plotTracking.m,v 1.5.2.23 2006/08/14 14:45:14 dpl Exp $
%--------------------------------------------------------------------------

% Protection - if the list contains incorrect channel numbers
channelList = intersect(channelList, 1:settings.numberOfChannels);

%% Phase Lock Detector
for channelNr = 1 : settings.numberOfChannels
    if (trackResults(channelNr).status ~= '-')
        trackResults(channelNr).LockTime =zeros(1,settings.msToProcess);
        for loopCnt=1:settings.msToProcess
            % If I_P is less than threshold, reset lock count
            if abs(trackResults(channelNr).I_P(loopCnt)) < settings.ldConstant*...
                    (trackResults(channelNr).plThreshold(loopCnt)/loopCnt)
                trackResults(channelNr).LockTime(loopCnt) = 0;
                % Otherwise, increase counter
            else
                if loopCnt==1
                    trackResults(channelNr).LockTime(loopCnt)=1;
                else
                    trackResults(channelNr).LockTime(loopCnt) = ...
                        trackResults(channelNr).LockTime(loopCnt-1) + 1;
                end
            end
        end
    end
end


%=== For all listed channels ==============================================
for channelNr = channelList
    
    if(trackResults(channelNr).status ~= '-')
        
        %% Select (or create) and clear the figure ================================
        % The number 200 is added just for more convenient handling of the open
        % figure windows, when many figures are closed and reopened.
        % Figures drawn or opened by the user, will not be "overwritten" by
        % this function.
        
        figure(channelNr +200);
        clf(channelNr +200);
        %Position the figure at the center
        screenSize=get(0,'ScreenSize');
        figWidth=900;
        figHeight=600;
        figPosition=[0.5*(screenSize(3)-figWidth),...
            0.5*(screenSize(4)-figHeight),figWidth,figHeight];
        newLn = sprintf('\n');
        
        set(channelNr +200, 'Name', ['Channel ', num2str(channelNr), ...
            ' (PRN ', ...
            num2str(trackResults(channelNr).PRN), ...
            ') results'],...
            'Position',figPosition);
        timeAxisInSeconds = (1:settings.msToProcess)/1000;
        %% Draw axes============================================================
        
        dtsppanel = uipanel('Position',[0.02 0.535 0.33 0.45], 'BackgroundColor',[.8 .8 .8],'BorderType','none');
        %handles(1, 1) = axes ('Position',[0.1 0.775 0.15 0.15],'FontSize',8);
        hPlot(1) = axes('Position',[0.4 0.875 0.50 0.10],'FontSize',8); %I
        hPlot(2) = axes('Position',[0.4 0.775 0.50 0.10],'FontSize',8); %Q
        hPlot(3) = axes('Position',[0.4 0.675 0.50 0.10],'FontSize',8); %EPL
        hPlot(4) = axes('Position',[0.4 0.575 0.50 0.10],'FontSize',8); %Lock Detector
        hPlot(5) = axes('Position',[0.4 0.475 0.50 0.10],'FontSize',8); %CNo
        hPlot(6) = axes('Position',[0.4 0.175 0.50 0.10],'FontSize',8); %Carrier Freq
        hPlot(7) = axes('Position',[0.4 0.075 0.50 0.10],'FontSize',8); %Code Freq
        
        
        %% Plot =Controls==================================================
        hMp = uipanel('Position',[0.08 0.01 0.22 0.5]);
        
        %Plot Selection Options
        hp = uipanel('Parent',hMp,'Title','Plot Selection','FontSize',8,...
            'Position',[0.075 0.41 0.85 0.57]);
        hCb(1) = uicontrol('Parent',hp,'Style','checkbox','String','I   Correlator',...
            'Position',[10 130 150 20],'Callback',{@plotSelectionCallback,hPlot,1});
        hCb(2) = uicontrol('Parent',hp,'Style','checkbox','String','Q Correlator',...
            'Position',[10 110 150 20],'Callback',{@plotSelectionCallback,hPlot,2});
        hCb(3) = uicontrol('Parent',hp,'Style','checkbox','String','Correlation Results',...
            'Position',[10 90 150 20],'Callback',{@plotSelectionCallback,hPlot,3});
        hCb(4) = uicontrol('Parent',hp,'Style','checkbox','String','Lock Detector',...
            'Position',[10 70 150 20],'Callback',{@plotSelectionCallback,hPlot,4});
        hCb(5) = uicontrol('Parent',hp,'Style','checkbox','String','C/No',...
            'Position',[10 50 150 20],'Callback',{@plotSelectionCallback,hPlot,5});
        hCb(6) = uicontrol('Parent',hp,'Style','checkbox','String','Carrier Frequency',...
            'Position',[10 30 150 20],'Callback',{@plotSelectionCallback,hPlot,6});
        hCb(7) = uicontrol('Parent',hp,'Style','checkbox','String','Code Frequency',...
            'Position',[10 10 150 20],'Callback',{@plotSelectionCallback,hPlot,7});
        
        
        hTp = uipanel('Parent',hMp,'Title','Time Window','FontSize',8,...
            'Position',[0.075 0.04 0.85 0.35]);
        
        timeWindow.Start=0;
        timeWindow.End  = settings.msToProcess/1000;
        
        % Define the slider step to enable the plot when the data length is
        % less than 1 second
        if timeWindow.End<1
            stepMin=timeWindow.End/5;
        else
            stepMin=1;
        end
        stepMax=10*stepMin;
        
        hsmin = uicontrol('Parent',hTp,'Style','slider','Tag','SliderMin',...
            'Max',timeWindow.End,'Min',timeWindow.Start,'Value',timeWindow.Start,...
            'SliderStep',[stepMin/timeWindow.End stepMax/timeWindow.End],'Position',[10 50 140 15],...
            'Callback',{@sliderCallback,hPlot,dtsppanel,trackResults,channelNr});
        
        hsmax = uicontrol('Parent',hTp,'Style','slider','Tag','SliderMax',...
            'Max',timeWindow.End,'Min',timeWindow.Start,'Value',timeWindow.End,...
            'SliderStep',[stepMin/timeWindow.End stepMax/timeWindow.End],'Position',[10 10 140 15],...
            'Callback',{@sliderCallback,hPlot,dtsppanel,trackResults,channelNr});
        
        hsmindisp = uicontrol('Parent',hTp,'Style','edit','Tag','SliderMinDisp',...
            'Position',[100 70 50 15],'String',num2str(timeWindow.Start,'%6.3f'),...
            'Callback',{@dispCallback,hPlot,timeWindow,dtsppanel,trackResults,channelNr});
        hsmaxdisp = uicontrol('Parent',hTp,'Style','edit','Tag','SliderMaxDisp',...
            'Position',[100 30 50 15],'String',num2str(timeWindow.End,'%6.3f'),...
            'Callback',{@dispCallback,hPlot,timeWindow,dtsppanel,trackResults,channelNr});
        
        %Select all the plots initially
        for count=1:size(hCb,2)
            set(hCb(count),'Value',1);
        end
        
        for count=1:size(hCb,2)
            set(hCb(count),'Interruptible','off');
        end
        
        %% Plot all figures====================================================
        
        
        %----- Discrete-Time Scatter Plot ---------------------------------
        
        subplot(1,1,1,'parent',dtsppanel);
        scatter(trackResults(channelNr).I_P,trackResults(channelNr).Q_P,...
            12,1:settings.msToProcess,'filled');
        h = colorbar('location','southoutside');
        set(get(h,'xlabel'),'String', 'milliseconds', 'Rotation', 0,...
            'VerticalAlignment', 'Top');
        axis  equal;
        colormap('summer')
        title ('Discrete-Time Scatter Plot');
        xlabel('I prompt');
        ylabel('Q prompt');
        grid;
        
        %----- I Correlator -----------------------------------------------
        plot  (hPlot(1), timeAxisInSeconds, ...
            trackResults(channelNr).I_P, 'Color',[0.21 0.31 0.46]);
        
        grid  (hPlot(1));
        title ('Parent',hPlot(1), ['I',newLn, 'Correlator'],...
            'Units','normalized','Position',[1.1 0.4]);
        axis  (hPlot(1), 'tight');
        xlabel(hPlot(1), 'Time (s)');
        
        %----- Q Correlator -----------------------------------------------
        plot  (hPlot(2), timeAxisInSeconds, ...
            trackResults(channelNr).Q_P, 'Color',[0.21 0.31 0.46]);
        
        grid  (hPlot(2));
        title ('Parent',hPlot(2), ['Q',newLn, 'Correlator'],...
            'Units','normalized','Position',[1.1 0.4]);
        axis  (hPlot(2), 'tight');
        xlabel(hPlot(2), 'Time (s)');
        
        %----- Correlation ------------------------------------------------
        plot(hPlot(3), timeAxisInSeconds, ...
            [sqrt(trackResults(channelNr).I_E.^2 + ...
            trackResults(channelNr).Q_E.^2)', ...
            sqrt(trackResults(channelNr).I_P.^2 + ...
            trackResults(channelNr).Q_P.^2)', ...
            sqrt(trackResults(channelNr).I_L.^2 + ...
            trackResults(channelNr).Q_L.^2)'], ...
            '-*');
        xlabel(hPlot(3), 'Time (s)');
        hLegend = legend(hPlot(3), 'E','P','L','Location','SouthEast');
        set(hLegend,'FontSize',8);
        grid  (hPlot(3));
        title ('Parent',hPlot(3), ['Correlation',newLn,'Results'],...
            'Units','normalized','Position',[1.1 0.4]);
        axis  (hPlot(3), 'tight');
        %The next line will introduce warnings in matlab
        %hLabel =     ylabel(hPlot(2),'$\sqrt{I^2 + Q^2}$');
        hLabel =     ylabel(hPlot(3),'$sqrt(I^2 + Q^2)$');
        set(hLabel, 'Interpreter', 'Latex','FontSize',8);
        
        %----- Lock Detector ----------------------------------------------
        plot  (hPlot(4), timeAxisInSeconds, ...
            trackResults(channelNr).LockTime/1000, 'Color',[0.21 0.31 0.46]);
        
        grid  (hPlot(4));
        title ('Parent',hPlot(4), ['Lock',newLn, 'Detector'],...
            'Units','normalized','Position',[1.1 0.4]);
        axis  (hPlot(4), 'tight');
        xlabel(hPlot(4), 'Time (s)');
        ylabel(hPlot(4),' lock time (s)');
        
        
        % ---- C/No--------------------------------------------------------
        if(settings.CNo.Plot==1)
            plot(hPlot(5),trackResults(channelNr).CNo.PRMIndex/1000,trackResults(channelNr).CNo.PRMValue,'r', ...
                trackResults(channelNr).CNo.VSMIndex/1000,trackResults(channelNr).CNo.VSMValue,'b',...
                trackResults(channelNr).CNo.MOMIndex/1000,trackResults(channelNr).CNo.MOMValue,'k');
            grid  (hPlot(5));
            axis (hPlot(5), 'tight');
            hLegend= legend(hPlot(5),'PRM','VSM','MOM','Location','SouthEast');
            set(hLegend,'FontSize',8);
            
            xlabel(hPlot(5),'Time (s)');
            ylabel(hPlot(5),'dB-Hz');
            title ('Parent',hPlot(5), 'C/No','Units','normalized',...
                'Position',[1.1 0.4]);
        end
        
        %----- Carrier Frequency----------------------------------
        plot  (hPlot(6), timeAxisInSeconds, ...
            trackResults(channelNr).carrFreq, 'Color',[0.42 0.25 0.39]);
        
        grid  (hPlot(6));
        axis  (hPlot(6), 'tight');
        xlabel(hPlot(6), 'Time (s)');
        ylabel(hPlot(6), 'Hz');
        title ('Parent',hPlot(6), ['Carrier',newLn,'Frequency'],...
            'Units','normalized','Position',[1.1 0.4]);
        
        
        %----- Code Frequency----------------------------------
        plot  (hPlot(7), timeAxisInSeconds, ...
            trackResults(channelNr).codeFreq, 'Color',[0.2 0.3 0.49]);
        grid  (hPlot(7));
        axis  (hPlot(7), 'tight');
        xlabel(hPlot(7), 'Time (s)');
        ylabel(hPlot(7), 'Hz');
        title ('Parent',hPlot(7), ['Code',newLn,'Frequency'],...
            'Units','normalized','Position',[1.1 0.4]);
        for count=1:size(hPlot,2)
            xtick=get(hPlot(count),'XTick');
            set(hPlot(count),'XTick',xtick(1:end-1));
        end
    end %trackResults(channelNr).status ~= '-'
    
    % Hide some plots from the default frame.
    for i=[2,4,6,7]
        set(hCb(i),'Value',0);
        plotSelectionCallback(hCb(i), [], hPlot,i);
    end
    
    % If the length of the data is larger than 39 seconds, then in the
    % default mode, only the first 39 seconds of tracking results are
    % plotted, the slider bar can still be used to show all tracking
    % results
    if timeWindow.End > 39
        set(hsmax,'Value',39);
        set(findobj(gcf,'Tag','SliderMaxDisp'),'String',num2str(39,'%6.3f'));
        sliderCallback(hsmax,[],hPlot,dtsppanel,trackResults,channelNr);
    end
    
end % for channelNr = channelList


%% Callback Functions======================================================


%%Call back function to perform necessary actions when a plot is selected
%%or unselected
function plotSelectionCallback(hObject, eventdata, hPlot,plotNo)

if (get(hObject,'Value') == get(hObject,'Max'))
    set(hPlot(plotNo),'Visible','on');
    set(get(hPlot(plotNo),'children'),'Visible','on');
    if ((plotNo==2)||(plotNo==3))
        legend(hPlot(plotNo),'show');
    end
else
    set(hPlot(plotNo),'Visible','off');
    set(get(hPlot(plotNo),'children'),'Visible','off');
    legend(hPlot(plotNo),'hide');
end

plotCount=getVisiblePlotCount(hPlot);
if(plotCount)
    plotHeight = (0.10*9)/plotCount;
else
    plotHeight = 0;
end
plotBottom = (0.075 + 0.10*9)-plotHeight;

for count=1:size(hPlot,2)
    if (strcmp(get(hPlot(count),'Visible'),'on')==1)
        set(hPlot(count),'Position',[0.4 plotBottom 0.5 plotHeight]);
        plotBottom=plotBottom-plotHeight;
    end
end

%Function to find the number of selected plots
function visiblePlotCount = getVisiblePlotCount(hPlot)
visiblePlotCount=0;
for count=1:size(hPlot,2)
    if(strcmp(get(hPlot(count),'Visible'),'on')==1)
        visiblePlotCount=visiblePlotCount+1;
    end
end

%%Callback function to adjust the time window using sliders
function sliderCallback(hObject,eventdata,hPlot,dtsppanel,trackResults,channelNr)
min = get(findobj(gcf,'Tag','SliderMin'),'Value');
max = get(findobj(gcf,'Tag','SliderMax'),'Value');
set(findobj(gcf,'Tag','SliderMinDisp'),'String',num2str(min,'%6.3f'));
set(findobj(gcf,'Tag','SliderMaxDisp'),'String',num2str(max,'%6.3f'));
if (min>=max)
    errordlg('End Time must be greater than Start Time !');
else
    for count=1:size(hPlot,2)
        xlim(hPlot(count),[min max]);
        
        step = ((max-min)/10);
        if step>1
            step=floor(step);
        end
        set(hPlot(count),'XTick',floor(min)+step:step:ceil(max)-step);
    end
    
    minMs = round(min * 1000 + 1);
    maxMs = round(max * 1000);
    
    subplot(1,1,1,'replace','parent',dtsppanel);
    scatter(trackResults(channelNr).I_P(minMs:maxMs),...
        trackResults(channelNr).Q_P(minMs:maxMs),12,minMs:maxMs,...
        'filled');
    h = colorbar('location','southoutside');
    set(get(h,'xlabel'),'String', 'milliseconds', 'Rotation', 0,...
        'VerticalAlignment', 'Top');
    
    axis  tight;
    title ('Discrete-Time Scatter Plot');
    xlabel('I prompt');
    ylabel('Q prompt');
    grid;
    
end



%%Callback function to adjust the time window using text boxes
function dispCallback(hObject,eventdata,hPlot,timeWindow,dtsppanel,trackResults,channelNr)

min = str2num(get(findobj(gcf,'Tag','SliderMinDisp'),'String'));
max = str2num(get(findobj(gcf,'Tag','SliderMaxDisp'),'String'));

if (isempty(min)||isempty(max))
    errordlg('Please enter a numeric value !');
elseif ((min<timeWindow.Start)||max>timeWindow.End)
    errordlg(['Please enter a value between ',num2str(timeWindow.Start),...
        ' and ',num2str(timeWindow.End)'',' !']);
elseif (min>=max)
    errordlg('End Time must be greater than Start Time !');
else
    set(findobj(gcf,'Tag','SliderMin'),'Value',min);
    set(findobj(gcf,'Tag','SliderMax'),'Value',max);
    for count=1:size(hPlot,2)
        xlim(hPlot(count),[min max]);
        
        step = ((max-min)/10);
        if step>1
            step=floor(step);
        end
        set(hPlot(count),'XTick',floor(min)+step:step:ceil(max)-step);
        
    end
    
    minMs = round(min * 1000 + 1);
    maxMs = round(max * 1000);
    
    subplot(1,1,1,'replace','parent',dtsppanel);
    scatter(trackResults(channelNr).I_P(minMs:maxMs),...
        trackResults(channelNr).Q_P(minMs:maxMs),12,minMs:maxMs,...
        'filled');
    h = colorbar('location','southoutside');
    set(get(h,'xlabel'),'String', 'milliseconds', 'Rotation', 0,...
        'VerticalAlignment', 'Top');
    
    axis  tight;
    title ('Discrete-Time Scatter Plot');
    xlabel('I prompt');
    ylabel('Q prompt');
    grid;
    
end

