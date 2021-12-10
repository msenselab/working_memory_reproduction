%% Name: dataAna.m
%% Date: 28-01-2016
%% 
function dataAna
    close all;
    clc;
    %% resp [curDuration, phyDuration, proDuration, repVDuration, repDuration]
    subfiles = {'Libing', 'XinyueWang'};
    allArray = [];
    for isub = 1:length(subfiles)
        load(subfiles{isub});
        % NSub
        seq(:,6) = isub;
        seq(:, 5) = 1:length(seq);
        % adjust response array for Libing because the data wasn't save
        % correctly
        % resp: curDur, phyDur, proDur, repVDur, repDur, presentcolorDeg,
        % respcolorDeg
        if isub == 1
            respTmp = resp;
            respTmp(seq(:, 1) == 1, 1:5) =   ( respTmp(seq(:, 1) == 1,  4:8) );
            respTmp(seq(:, 1) == 3, 1:5) =  (respTmp(seq(:, 1) == 3,  6:10) );
            respTmp(seq(:, 1) == 5, 1:5) =  (respTmp(seq(:, 1) == 5,  8:12) );
            respTmp(:, 6:7) = resp(:, 1:2);
            resp = respTmp;
        end
        
        arrayTemp = [seq(:,[1:6]), resp(:, 1:7)];  
        exp1 = array2table(arrayTemp,'VariableNames',{'WMSize', 'ShortLong', 'DurLevel','TPos',  'NT','NSub','curDur',...
     'phyDur','proDur','repVDur','repDur', 'presentColorDeg', 'respColorDeg'});
       exp1.valid = ones(height(exp1),1);
       exp1.valid( exp1.repDur < 0.1 | exp1.repDur > 2) = 0; 
%         for i=1:height(mr)
%             idx = find(exp1.curDur == mr.curDur(i));
%             exp1.valid(idx) = exp1.repDur(idx) > mr.ub(i) | exp1.repDur(idx) < mr.lb(i);
%         end
%         exp1.valid = 1 - exp1.valid;               
        allArray = [allArray; exp1];       
    end
  
   idx = allArray.valid ==1; %valid data
    mTabel = grpstats(allArray(idx,:),{'NSub','ShortLong','curDur'},{'mean','sem'},'DataVars',{'repDur'});
    numSubFig = ceil(sqrt(length(subfiles)));
    figure();
    for isub = 1:length(subfiles)
        subplot(numSubFig,numSubFig,isub); hold on;
        idx = mTabel.NSub == isub & mTabel.ShortLong == 1 ;% short 
        plot(mTabel.curDur(idx), mTabel.mean_repDur(idx),'r.-');% short estimation
        idx = mTabel.NSub == isub & mTabel.ShortLong == 2 ;
        plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'g.-');% long estimation       
        legend('short','long');
        hold off;
    end   
  

    
end