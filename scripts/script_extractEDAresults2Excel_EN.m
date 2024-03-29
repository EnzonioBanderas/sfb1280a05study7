%% Initialize
clearvars

script_init_study7

%% Settings
% addpath /media/diskEvaluation/Evaluation/sfb1280a05study6/scripts/packages/toolbox_ter
% addpath /media/diskEvaluation/Evaluation/sfb1280a05study6/scripts/essbids
% fp_de = '/media/diskEvaluation/Evaluation/sfb1280a05study7/derivatives/';
% fp_der = '/media/diskEvaluation/Evaluation/sfb1280a05study7/dumpHereForSorting/derivatives/';
fp0 = fullfile(fp_de, 'EDAevaluation_processed_161to301');
fp_fig = fullfile(fp_de, 'figures', 'EDA');

if ~exist(fp_fig, 'dir')
    mkdir(fp_fig)
end

% Get file paths
fl = ter_listFiles(fullfile(fp0,''),'*_EDA_Result.mat');
nFiles = length(fl);
edaRes_all = cell(1,2);
warning('off',    'MATLAB:xlswrite:AddSheet');
fname = fullfile(fp0,strcat('EDAresults_', datestr(datetime, 'yyyymmddTHHMMSS'), '.xlsx'));
EIRResults = [];
TIRResults = [];

%%
for i=1:length(fl)
    [~,subject,~] = ter_fparts(fl{i},3);
    [~,currentfile,~] = ter_fparts(fl{i},1);
    [~,session,~] = ter_fparts(fl{i},2);
    fprintf('Reading file %d of %d (%s)...\n',i,numel(fl), currentfile);
    clearvars EIRResults TIRResults;
    
    [EIRResults,~] = exportEDA2Excel(fl{i},1,5.9,1);
    [TIRResults,~] = exportEDA2Excel(fl{i},6,12.5,1);
    [fp,fn,~] = fileparts(fl{i});
    
    
    try
%         load(strrep(flist{i},'_EDA_EDA_Result.mat','_eventTable.mat'),'eventtable');
        load(strrep(fl{i},'_EDA_EDA_Result.mat','_trialDefinition.mat'),'sPos', 'numTrials');
        fp_parsed = essbids_parseLabel(fl{i});
        EIReventtable = cell(numTrials, 1);
        TIReventtable = cell(numTrials, 1);
        group_cell = cell(numTrials, 1);
        block_cell = cell(numTrials, 1);
        block_CSplus = 0;
        block_CSminus = 0;
        for j = 1:numTrials
            if sPos{3}.time(j) > 0
                eventStr1 = sPos{3}.name;
            elseif sPos{4}.time(j) > 0
                eventStr1 = sPos{4}.name;
            else
                error('sPos does not contain all trial CS information')
            end
            
            switch eventStr1
                case 'CSplus'
                    block_CSplus = block_CSplus + 1;
                    block_cell{j} = block_CSplus;
                case 'CSminus'
                    block_CSminus = block_CSminus + 1;
                    block_cell{j} = block_CSminus;
            end
            
            if sPos{5}.time(j) > 0
                eventStr2 = sPos{5}.name;
            elseif sPos{6}.time(j) > 0
                eventStr2 = sPos{6}.name;
            else
                error('sPos does not contain all trial US information')
            end
            
            switch [fp_parsed.ses, fp_parsed.run]
                case '11'
                    eventStr3 = 'phase-Habituation';
                case '12'
                    eventStr3 = 'phase-Acquisition';
                case '21'
                    eventStr3 = 'phase-Extinction';
                case '31'
                    eventStr3 = 'phase-Recall';
                case '32'
                    eventStr3 = 'phase-Volatile';
            end
            
            EIReventtable{j} = ['EIR_', eventStr1, '_', eventStr2, '_', eventStr3, '_context-1'];
            TIReventtable{j} = ['TIR_', eventStr1, '_', eventStr2, '_', eventStr3, '_context-1'];
            
            group_cell{j} = 1;
            
        end
        EIReventtable = cell2table([EIReventtable, block_cell, group_cell], 'VariableNames', {'event_label', 'Block', 'Grp'});
        TIReventtable = cell2table([TIReventtable, block_cell, group_cell], 'VariableNames', {'event_label', 'Block', 'Grp'});
%         EIREvents = eventtable(contains(eventtable.event_label, "EIR"),:);
%         TIREvents = eventtable(contains(eventtable.event_label, "TIR"),:);    
        
%         TIREvents(contains(TIREvents.event_label,"context-C"),:) = [];
%         TIREvents(contains(TIREvents.event_label,"TIR_context-B"),:) = [];
%         TIREvents(contains(TIREvents.event_label,"TIR_context-A"),:) = [];
%         TIREvents(TIREvents.evalBlock_start < 0,:) = [];
        
        EIRResults = [EIReventtable EIRResults]; 
        TIRResults = [TIReventtable TIRResults];        

        
        %adding phase, subject and specific events to the table    
        
        vars = {EIRResults, TIRResults};
        for v = 1:numel(vars)
            try
                event=split(vars{v}.event_label,"_phase-");                
                CS = split(event(:,1),"_");
                CS = CS(:,2);  
                phase = split(event(:,2),"_");
                context = phase(:,2);
                phase = phase(:,1);
                
            catch ME
                CS = [];
                phase = [];           
                disp('some event labels do not contain full info');
                for i1=1:numel(vars{v}.event_label)
                    if contains(vars{v}.event_label(i1),"phase")
                        event=split(vars{v}.event_label(i1),"_phase-");
                        contextAndPhase = split(event(2),"_");
                        phase = vertcat(phase,contextAndPhase(1));
                       
                        CS_ = split(event(1),"_");
                        CS = vertcat(CS,CS_(2));
        
                    else
                        %since it's context A cs minus is missing from recall 
                        % and reinstatement end-1 trial, fixing that
                        CS = vertcat(CS,"CSminus");
                      
                        phase = vertcat(phase,phase(end));
                    end
                end
            end
            vars{v}{:,'Phase'} = string(phase);
            vars{v}{:,'CS'} = string(CS);
            vars{v}{:,'Subject'} = string(subject);
            vars{v}{:,'Context'} = string(context);
            vars{v}{:,'Event'} = cellfun(@(s)s(1:3),vars{v}.event_label,'UniformOutput',false);
        end
            
            for v = 1:numel(vars)
            edaRes_all{v} = vertcat(edaRes_all{v}, vars{v});
            end
        catch ME
            disp("Eventtable not found");
    end

end

fprintf('writing results to file:\n   %s\n',fname)
edaRes_all_summary = cell(1, numel(edaRes_all));
for v = 1:numel(edaRes_all)

    % calculate
    edaRes_all{v}.logEDA = log(edaRes_all{v}.maxEDA + 1);
    
    % groupsummary
    edaRes_all_summary{v} = groupsummary(edaRes_all{v}, {'Phase', 'Block', 'CS'}, 'nnz', 'Trial');
    edaRes_all_summary{v} = groupsummary(edaRes_all_summary{v}, 'Phase', 'max', 'GroupCount');

    SheetName = strcat(edaRes_all{v}.Event{1},"-Results");
    writetable(edaRes_all{v},fname,'Sheet',SheetName);
end
warning('on',    'MATLAB:xlswrite:AddSheet');

fp_workSpace = fullfile(fp_de, 'script_extractEDAresult2Excel.mat');
save(fullfile(fp_de, 'script_extractEDAresult2Excel.mat'))

%% plot errorbar
close all
c = colormap('lines');

if ~exist('edaRes_all', 'var')
    script_init_study7
    fp_workSpace = fullfile(fp_de, 'script_extractEDAresult2Excel.mat');
    load(fp_workSpace)
end

uniq_Measure = {'SCR_CS', 'SCR_US'};
for iM = 1:length(edaRes_all)
    tb_eda = edaRes_all{iM};
    tb_eda_summary = edaRes_all_summary{iM};

    tb_eda_CSplus = tb_eda(strcmp(tb_eda.CS, 'CSplus'), :);
    tb_eda_CSminus = tb_eda(strcmp(tb_eda.CS, 'CSminus'), :);
    uniq_Phase = unique(tb_eda.Phase);
    figure('units', 'normalized', 'outerposition', [0, 0, .5, .7])
    for i=1:length(uniq_Phase)
        tb_eda_CSplus_Phase = tb_eda_CSplus(strcmp(tb_eda_CSplus.Phase, uniq_Phase{i}), :);
        tb_eda_CSminus_Phase = tb_eda_CSminus(strcmp(tb_eda_CSminus.Phase, uniq_Phase{i}), :);
    
        uniq_Block = unique([tb_eda_CSplus_Phase.Block; tb_eda_CSminus_Phase.Block]);
        mean_CSplus_Block = zeros(length(uniq_Block), 1);
        std_CSplus_Block = zeros(length(uniq_Block), 1);
        sem_CSplus_Block = zeros(length(uniq_Block), 1);
        mean_CSminus_Block = zeros(length(uniq_Block), 1);
        std_CSminus_Block = zeros(length(uniq_Block), 1);
        sem_CSminus_Block = zeros(length(uniq_Block), 1);
        for j=1:length(uniq_Block)
            tb_eda_CSplus_Phase_Block = tb_eda_CSplus_Phase(tb_eda_CSplus_Phase.Block == uniq_Block(j), :);
            mean_CSplus_Block(j) = nanmean(tb_eda_CSplus_Phase_Block.logEDA);
            std_CSplus_Block(j) = nanstd(tb_eda_CSplus_Phase_Block.logEDA);
            length_Block = length(tb_eda_CSplus_Phase_Block.logEDA);
            sem_CSplus_Block(j) = std_CSplus_Block(j) / sqrt(length_Block);
            
            tb_eda_CSminus_Phase_Block = tb_eda_CSminus_Phase(tb_eda_CSminus_Phase.Block == uniq_Block(j), :);
            mean_CSminus_Block(j) = nanmean(tb_eda_CSminus_Phase_Block.logEDA);
            std_CSminus_Block(j) = nanstd(tb_eda_CSminus_Phase_Block.logEDA);
            length_Block = length(tb_eda_CSminus_Phase_Block.logEDA);
            sem_CSminus_Block(j) = std_CSminus_Block(j) / sqrt(length_Block);
        end

%         figure % CS, CS+ and CS-
        switch uniq_Phase{i}
            case 'Habituation'
                subplot(3, 2, 1)
            case 'Acquisition'
                subplot(3, 2, 2)
            case 'Extinction'
                subplot(3, 2, 3)
            case 'Recall'
                subplot(3, 2, 4)
            case 'Volatile'
                subplot(3, 2, [5, 6])
                plot(uniq_Block(ismember(uniq_Block, [7, 13, 18])), ...
                     mean_CSplus_Block(ismember(uniq_Block, [7, 13, 18])), ...
                     'o', 'MarkerSize',13, 'MarkerEdgeColor', 'g'), hold on
                plot(uniq_Block(ismember(uniq_Block, [31, 37, 42])), ...
                     mean_CSplus_Block(ismember(uniq_Block, [31, 37, 42])), ...
                     'o', 'MarkerSize',13, 'MarkerEdgeColor', 'y')
        end
        err1 = errorbar(uniq_Block, mean_CSminus_Block, sem_CSminus_Block, ...
            'Color', c(1, :), 'DisplayName', 'CS-'); hold on
        err2 = errorbar(uniq_Block, mean_CSplus_Block, sem_CSplus_Block, ....
            'Color', c(2, :), 'DisplayName', 'CS+');
        legend([err1, err2]) 
        title(sprintf([uniq_Phase{i}, ' (n=%d)'], ...
            tb_eda_summary.max_GroupCount(strcmp(tb_eda_summary.Phase, uniq_Phase{i}))))
        xlabel('log(SCR)')
        ylabel('Block') 
    
    end
    
    sgtitle(['All subjects ', uniq_Measure{iM}], 'Interpreter', 'none')
    saveas(gcf, fullfile(fp_fig, ['AllSubjects_', uniq_Measure{iM}, '.pdf']))
    saveas(gcf, fullfile(fp_fig, ['AllSubjects_', uniq_Measure{iM}, '.png']))
    saveas(gcf, fullfile(fp_fig, ['AllSubjects_', uniq_Measure{iM}, '.fig']))
%     print(gcf, fullfile(fp_fig, ['AllSubjects_', uniq_Measure{iM}, '.pdf']), '-bestfit')
end

%% plot errorbar
close all
c = colormap('lines');

if ~exist('edaRes_all', 'var')
    load(fp_workSpace)
end

uniq_Measure = {'SCR_CS', 'SCR_US'};
for iM = 1:length(uniq_Measure)
    tb_eda = edaRes_all{iM};

    uniq_Subject = unique(tb_eda.Subject);
    for s=1:length(uniq_Subject)
        tb_eda_CSplus = tb_eda(strcmp(tb_eda.CS, 'CSplus') & ...
            strcmp(tb_eda.Subject, uniq_Subject{s}), :);
        tb_eda_CSminus = tb_eda(strcmp(tb_eda.CS, 'CSminus') & ...
            strcmp(tb_eda.Subject, uniq_Subject{s}), :);
        uniq_Phase = unique(tb_eda.Phase);
        figure('units', 'normalized', 'outerposition', [0, 0, .5, .7])
        for i=1:length(uniq_Phase)
            tb_eda_CSplus_Phase = tb_eda_CSplus(strcmp(tb_eda_CSplus.Phase, uniq_Phase{i}), :);
            tb_eda_CSminus_Phase = tb_eda_CSminus(strcmp(tb_eda_CSminus.Phase, uniq_Phase{i}), :);

            uniq_Block = unique([tb_eda_CSplus_Phase.Block; tb_eda_CSminus_Phase.Block]);
            try
                mean_CSplus_Block = zeros(length(uniq_Block), 1);
                std_CSplus_Block = zeros(length(uniq_Block), 1);
                sem_CSplus_Block = zeros(length(uniq_Block), 1);
                mean_CSminus_Block = zeros(length(uniq_Block), 1);
                std_CSminus_Block = zeros(length(uniq_Block), 1);
                sem_CSminus_Block = zeros(length(uniq_Block), 1);
                for j=1:length(uniq_Block)
                    tb_eda_CSplus_Phase_Block = tb_eda_CSplus_Phase(tb_eda_CSplus_Phase.Block == uniq_Block(j), :);
                    mean_CSplus_Block(j) = nanmean(tb_eda_CSplus_Phase_Block.logEDA);
                    std_CSplus_Block(j) = nanstd(tb_eda_CSplus_Phase_Block.logEDA);
                    length_Block = length(tb_eda_CSplus_Phase_Block.logEDA);
                    sem_CSplus_Block(j) = std_CSplus_Block(j) / sqrt(length_Block);

                    tb_eda_CSminus_Phase_Block = tb_eda_CSminus_Phase(tb_eda_CSminus_Phase.Block == uniq_Block(j), :);
                    mean_CSminus_Block(j) = nanmean(tb_eda_CSminus_Phase_Block.logEDA);
                    std_CSminus_Block(j) = nanstd(tb_eda_CSminus_Phase_Block.logEDA);
                    length_Block = length(tb_eda_CSminus_Phase_Block.logEDA);
                    sem_CSminus_Block(j) = std_CSminus_Block(j) / sqrt(length_Block);
                end

        %         figure % CS, CS+ and CS-
                switch uniq_Phase{i}
                    case 'Habituation'
                        subplot(3, 2, 1)
                    case 'Acquisition'
                        subplot(3, 2, 2)
                    case 'Extinction'
                        subplot(3, 2, 3)
                    case 'Recall'
                        subplot(3, 2, 4)
                    case 'Volatile'
                        subplot(3, 2, [5, 6])
                        plot(uniq_Block(ismember(uniq_Block, [7, 13, 18])), ...
                             mean_CSplus_Block(ismember(uniq_Block, [7, 13, 18])), ...
                             'o', 'MarkerSize',13, 'MarkerEdgeColor', 'g'), hold on
                        plot(uniq_Block(ismember(uniq_Block, [31, 37, 42])), ...
                             mean_CSplus_Block(ismember(uniq_Block, [31, 37, 42])), ...
                             'o', 'MarkerSize',13, 'MarkerEdgeColor', 'y')
                end
                plot(uniq_Block, mean_CSminus_Block, 'Marker', 'o', ...
                    'Color', c(1, :), 'DisplayName', 'CS-'); hold on
                plot(uniq_Block, mean_CSplus_Block, 'Marker', '*', ...
                    'Color', c(2, :), 'DisplayName', 'CS-');
                title(uniq_Phase{i})
%                 legend([plt1, plt2], {'CS-', 'CS+'}, 'Interpreter', 'none')
                xlabel('log(SCR)')
                ylabel('Block')
                legend show
            catch
            end
        end
        
        sgtitle([uniq_Subject{s}, ' ', uniq_Measure{iM}], 'Interpreter', 'none')
        saveas(gcf, fullfile(fp_fig, [uniq_Subject{s}, '_', uniq_Measure{iM}, '.pdf']))
        saveas(gcf, fullfile(fp_fig, [uniq_Subject{s}, '_', uniq_Measure{iM}, '.png']))
        saveas(gcf, fullfile(fp_fig, [uniq_Subject{s}, '_', uniq_Measure{iM}, '.fig']))
    end
end

% edaRes_all_acquisition = edaRes_all{1}(edaRes_all{1}.Phase == 'Acquisition', :);
% 
% subUniq = unique(edaRes_all_acquisition.Subject);
% figure;
% for iSub = 1:length(subUniq)
%     edaRes_all_sub = edaRes_all_acquisition(edaRes_all_acquisition.Subject == subUniq{iSub}, :);
%     
%     % split between CS+ and CS-
%     edaRes_all_CSmin = edaRes_all_sub(contains(edaRes_all_sub.event_label, 'CSminus'), :);
%     edaRes_all_CSplu = edaRes_all_sub(contains(edaRes_all_sub.event_label, 'CSplus'), :);
%     
%     G = contains(edaRes_all_sub.event_label, 'CSminus');
%     
%     figure;
%     scatter(G, edaRes_all_sub.maxEDA)
%     
% %     boxplot(edaRes_all_CSmin.maxEDA, 'Color', 'blue'), hold on
% %     boxplot(edaRes_all_CSplu.maxEDA, 'Color', 'red')
% end
% 
% figure;

%% Plot first extinction trial responses, separated for CS and subprotocol 
if ~exist('edaRes_all', 'var')
    load(fp_workSpace)
end

tb_eda = edaRes_all{1}; % CS response EDA table
tb_eda_CSplus1Ext = tb_eda(strcmp(tb_eda.CS, 'CSplus') & ...
                           tb_eda.Trial == 1 & ...
                           strcmp(tb_eda.Phase, 'Extinction'), :);
tb_eda_CSminus1Ext = tb_eda(strcmp(tb_eda.CS, 'CSminus') & ...
                            tb_eda.Trial == 1 & ...
                            strcmp(tb_eda.Phase, 'Extinction'), :);
tb_eda_CSplus2Ext = tb_eda(strcmp(tb_eda.CS, 'CSplus') & ...
                           tb_eda.Trial == 2 & ...
                           strcmp(tb_eda.Phase, 'Extinction'), :);
tb_eda_CSminus2Ext = tb_eda(strcmp(tb_eda.CS, 'CSminus') & ...
                            tb_eda.Trial == 2 & ...
                            strcmp(tb_eda.Phase, 'Extinction'), :);
histBinWidth = 0.1;
figure
subplot(2,2,1)
title('')
histogram(tb_eda_CSplus1Ext.logEDA, 'BinWidth', histBinWidth, ...
    DisplayName=['CS+_t-1 mean=', num2str(mean(tb_eda_CSplus1Ext.logEDA))])
legend('Interpreter', 'none')
title(['CS+_t-1 mean=', num2str(mean(tb_eda_CSplus1Ext.logEDA))], ...
    'Interpreter', 'none')
hold on
subplot(2,2,2)
histogram(tb_eda_CSminus1Ext.logEDA, 'BinWidth', histBinWidth, ...
    DisplayName=['CS-_t-1 mean=', num2str(mean(tb_eda_CSminus1Ext.logEDA))])
legend('Interpreter', 'none')
title(['CS-_t-1 mean=', num2str(mean(tb_eda_CSminus1Ext.logEDA))], ...
    'Interpreter', 'none')
subplot(2,2,3)
histogram(tb_eda_CSplus2Ext.logEDA, 'BinWidth', histBinWidth, ...
    DisplayName=['CS+_t-2 mean=', num2str(mean(tb_eda_CSplus2Ext.logEDA))])
legend('Interpreter', 'none')
title(['CS+_t-2 mean=', num2str(mean(tb_eda_CSplus2Ext.logEDA))], ...
    'Interpreter', 'none')
subplot(2,2,4)
histogram(tb_eda_CSminus2Ext.logEDA, 'BinWidth', histBinWidth, ...
    DisplayName=['CS-_t-2 mean=', num2str(mean(tb_eda_CSminus2Ext.logEDA))])
legend('Interpreter', 'none')
title(['CS-_t-2 mean=', num2str(mean(tb_eda_CSminus2Ext.logEDA))], ...
    'Interpreter', 'none')

tb_eda_CSplus1Ext = tb_eda(strcmp(tb_eda.CS, 'CSplus') & ...
                           ismember(tb_eda.Trial, [1, 2]) & ...
                           strcmp(tb_eda.Phase, 'Extinction'), :);
tb_eda_CSminus1Ext = tb_eda(strcmp(tb_eda.CS, 'CSminus') & ...
                            ismember(tb_eda.Trial, [1, 2]) & ...
                            strcmp(tb_eda.Phase, 'Extinction'), :);


function [results,specialresults] = exportEDA2Excel(edaFile, timeStart, timeStop, width)
% Use this function to export the computed EDA's to an Excel file. Only the
% largest EDA is exported per trial.
% By default this function creates an Excel file with one EDA per trial
% and optional as many Excel files as optional positions were specified.
% These files only print EDA values for a trial, if the special position
% occured in the trial. In addition tht time of the EDA is based on the
% optional poisition

% Tobias Otto
% 1.4
% 22.06.2021

% 14.11.2017, Tobias: first draft, based on exportEDA
% 16.11.2017, Tobias: added more outputs to Excel files
% 20.11.2019, Tobias: added check for no optional markers
% 09.02.2021, Tobias: modified code to work with AppDesigner
% 22.06.2021, Tobias: save in mat file as well; replaced xlswrite

    %% Init variables
    load(edaFile);
    trials = 1:length(EDAANALYSIS.edaRes);
    if(any(EDAANALYSIS.sPosTime ~= -99))
        numSPos = size(EDAANALYSIS.sPosTime,2);
    else
        numSPos = 0;
    end
    
    partsOnly   = 0;
    if(~isempty(timeStart) && ~isempty(timeStop))
        partsOnly = 1;
    end
    
    %% Find max EDA for each trial
    for i=1:length(EDAANALYSIS.edaRes)
        % Init variables
        if(partsOnly == 0)
            timeStart   = EDAANALYSIS.trialTime{i}(1);
            timeStop    = EDAANALYSIS.trialTime{i}(end);
        end
    
        
        %remove responses shorter than width
        EDAToRemove = find((EDAANALYSIS.edaRes(i).maxTime - EDAANALYSIS.edaRes(i).minTime) < width);        
        if EDAToRemove > 0
            for ii=length(EDAToRemove):1            
            EDAANALYSIS.edaRes(i).minData(EDAToRemove(ii)) = [];
            EDAANALYSIS.edaRes(i).amplitude(EDAToRemove(ii)) = [];
            EDAANALYSIS.edaRes(i).edaTimeRes(EDAToRemove(ii)) = [];
            EDAANALYSIS.edaRes(i).maxData(EDAToRemove(ii)) = [];
            EDAANALYSIS.edaRes(i).maxTime(EDAToRemove(ii)) = [];                
            EDAANALYSIS.edaRes(i).minTime(EDAToRemove(ii)) = [];              
            end
        end

        

        % Find EDA for the fiven time range
        index       = EDAANALYSIS.edaRes(i).edaTimeRes >= timeStart & EDAANALYSIS.edaRes(i).edaTimeRes <= timeStop;
        tmpAmpl     = EDAANALYSIS.edaRes(i).amplitude(index);
        tmpTime     = EDAANALYSIS.edaRes(i).edaTimeRes(index);
        
    
        if(~isempty(tmpAmpl))
            % Find the max EDA in the given time range
            [edaMax(i), pos]    = max(tmpAmpl);
            edaTime(i)          = tmpTime(pos);    % Time with reference to stimulus onset
        else
            edaMax(i)   = 0;
            edaTime(i)  = 0;
        end
    end
    
    %% Separate eda by time and trial
    % Init veriables to zero
    resSPos     = zeros(numSPos, length(EDAANALYSIS.edaRes));
    timeSPos    = zeros(numSPos, length(EDAANALYSIS.edaRes));
    
    % Copy eda and time values for each trial
    % Time is with reference to stimulus onset!
    res	= edaMax;
    tim	= edaTime;
    
    % And now only trials with special Positions
    for i=1:numSPos
        ind             = EDAANALYSIS.sPosTime(:,i)' >= 0;
        timeSPos(i,ind)	= edaTime(ind) - EDAANALYSIS.sPosTimeStimOnset(ind,i)';
        resSPos(i,ind)	= edaMax(ind);
        
        % If time is negative, remove entry
        ind2                = timeSPos(i,:) < 0;
        timeSPos(i,ind2)	= 0;
        resSPos(i,ind2)     = 0;
        
        % Save position of sPlus a sindex
        sPInd(i,:)	= EDAANALYSIS.sPos{i}.time > 0;
    end
    
    %% Save result of Stimulus onset EDA
    % Write header
    
    mat  =   table;
    mat.Trial = trials';
    mat.maxEDA = res';
    mat.StimOnsetTime = tim';
    
    
    % Make it look nice for SPSS
    %mat     = mat';
    allEDA  = mat;                  % Save variable for mat file
    
    
    
    
    %% Save result to EDA file with special/optional positions
    clear mat;
    for k=1:numSPos
        clear mat2;
        
        % Write header
        mat{k}     = [{'Trial'} {'maxEda'} {['time(' EDAANALYSIS.sPos{k}.name ')']} {[EDAANALYSIS.sPos{k}.name ' active']}];
        mat2    = mat{k};
        
        % Write to file for general EDA
        j = 2;
        l = 2;
        for i=1:length(EDAANALYSIS.edaRes)
            % Store all trials
            mat{k}(j,:)	= [{trials(i)}, {resSPos(k,i)}, {timeSPos(k,i)}, {double(sPInd(k,i))}];
            j           = j+1;
            
            % Store only trials with an active marker
            if(sPInd(k,i) == 1)
                mat2(l,:)	= [{trials(i)}, {resSPos(k,i)}, {timeSPos(k,i)}, {double(sPInd(k,i))}];
                l           = l+1;
            end
        end
    
        % Make it look nice for SPSS
        mat2(1,:) = [];
        mat2 = cell2table(mat2);
        mat2.Properties.VariableNames = {'Trial', 'maxEda', ['time_' EDAANALYSIS.sPos{k}.name ''], [EDAANALYSIS.sPos{k}.name '_active']};
        
        mat{k} = mat2;
        % mat2    = mat2';
        
    
    
    end
    results = allEDA;
    specialresults = mat;

end
