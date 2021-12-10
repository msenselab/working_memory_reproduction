%% Name: dataAna.m
%% Date: 28-01-2016
%% 
function dataAna
%     close all;
    clc;
    %% resp [curDuration, phyDuration, proDuration, repVDuration, repDuration]
%         subfiles = {'XYW','AG','SE','JY', 'JK','JM','BZ'};
    subfiles = {'XYW','AG','ES','JK',   'JM','SK','WTL','LR',   'JS', 'AY', 'FM', 'CQ',    'WD','CZ', 'BYH' , 'CY'};
    dur = [0.5:0.3:1.7];
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
%         if isub == 1
%             respTmp = resp;
%             respTmp(seq(:, 1) == 1, 1:5) =   ( respTmp(seq(:, 1) == 1,  4:8) );
%             respTmp(seq(:, 1) == 3, 1:5) =  (respTmp(seq(:, 1) == 3,  6:10) );
%             respTmp(seq(:, 1) == 5, 1:5) =  (respTmp(seq(:, 1) == 5,  8:12) );
%             respTmp(:, 6:7) = resp(:, 1:2);
%             resp = respTmp;
%         end
        
        arrayTemp = [seq(:,[1:6]), resp(:, 1:8)];  
        exp1 = array2table(arrayTemp,'VariableNames',{'WMSize', 'ShortLong', 'DurLevel','TPresent',  'NT','NSub','curDur',...
     'phyDur','proDur','repVDur','repDur', 'presentColorDeg', 'respColorDeg','WMRP'});
       exp1.valid = ones(height(exp1),1);
       exp1.valid( exp1.repDur < 0.1 | exp1.repDur > 2.5) = 0; 
       
       exp1.stdRepDur =  -1*ones( length(exp1.NSub) ,1);
       for iWM =1:3
            WMLoad =  (iWM - 1) * 2 + 1;
                for idur = 1:5 % for the idurth duration
                    idx =  (  exp1.curDur == dur( idur)  &  exp1.WMSize == WMLoad);
                      exp1(  idx , :) ;
                      exp1.stdRepDur( idx) = std(  exp1.repDur(idx,:)  );           
                end
       end   
        allArray = [allArray; exp1];       
    end
  save('allArray', 'allArray');
  
    dat = table2array(allArray);
    xlswrite('Exp3_WMatBothStage.xlsx', dat,1,'A2:P5761');
  
   idx = allArray.valid ==1; %valid data
   allArray.Crr = allArray.TPresent == allArray.WMRP;
%     mTabel = grpstats(allArray(idx,:),{'NSub','WMSize','curDur','TPresent'},{'mean','sem'},'DataVars',{'repDur', 'Crr'});
   mTabel = grpstats(allArray(idx,:),{'NSub','WMSize','curDur'},{'mean','sem'},'DataVars',{'repDur', 'Crr'});   
    WM = grpstats( mTabel,{'NSub','WMSize'},{'mean','sem'},'DataVars',{ 'mean_Crr'});
    WMCrrRate = reshape(WM.mean_mean_Crr,[], length(subfiles))';
    figure(); hold on; bar(WMCrrRate); ylabel('WM correct rates'); xlabel('# subjects'); hold off;
    
%     numSubFig = ceil(sqrt(length(subfiles)));
%     figure();
%     for isub = 1:length(subfiles)
%         subplot(numSubFig,numSubFig,isub); hold on;
%         
%         idx = mTabel.NSub == isub & mTabel.WMSize == 1;% WM1, WM target present
%         plot(mTabel.curDur(idx), mTabel.mean_repDur(idx),'r.--');% short estimation
%         idx = mTabel.NSub == isub & mTabel.WMSize == 3 ;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'g.--');% long estimation       
%         idx = mTabel.NSub == isub & mTabel.WMSize == 5 ;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'b.--');% long estimation       
%         
%         idx = mTabel.NSub == isub & mTabel.WMSize == 1 & mTabel.TPresent == 1;% WM1, WM target present
%         plot(mTabel.curDur(idx), mTabel.mean_repDur(idx),'r.--');% short estimation
%         idx = mTabel.NSub == isub & mTabel.WMSize == 3 & mTabel.TPresent == 1;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'g.--');% long estimation       
%         idx = mTabel.NSub == isub & mTabel.WMSize == 5 & mTabel.TPresent == 1;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'b.--');% long estimation       
% 
%         idx = mTabel.NSub == isub & mTabel.WMSize == 1 & mTabel.TPresent ~= 1;% WM1, WM target present
%         plot(mTabel.curDur(idx), mTabel.mean_repDur(idx),'r*-');% short estimation
%         idx = mTabel.NSub == isub & mTabel.WMSize == 3 & mTabel.TPresent ~= 1;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'g*-');% long estimation       
%         idx = mTabel.NSub == isub & mTabel.WMSize == 5 & mTabel.TPresent ~= 1;
%         plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'b*-');% long estimation  
%        if isub == 5
%              xlabel('Sample duration');
%             ylabel('Reproduced duration');
%        end
%         
%         if isub == 1 
%             legend('WM1TargetPresent','WM3TargetPresent','WM5TargetPresent','WM1TargetAbsent','WM3TargetAbsent','WM5TargetAbsent');
%         end
%         hold off;
%     end   
  
%     mTabel = grpstats(mTabel,{'WMSize','curDur','TPresent'},{'mean','sem'},'DataVars',{'mean_repDur'});
%     figure(); hold on;
%         idx = mTabel.WMSize == 1& mTabel.TPresent == 1 ;% WM1
%         plot(mTabel.curDur(idx), mTabel.mean_mean_repDur(idx),'r.-');% short estimation
%        
%         idx =  mTabel.WMSize == 3 & mTabel.TPresent == 1;
%         plot(mTabel.curDur(idx),mTabel.mean_mean_repDur(idx),'g.-');% long estimation       
%        
%         idx =  mTabel.WMSize == 5 & mTabel.TPresent == 1;
%         plot(mTabel.curDur(idx),mTabel.mean_mean_repDur(idx),'b.-');% long estimation       
%         
%        
%         
%         idx = mTabel.WMSize == 1& mTabel.TPresent ~= 1 ;% WM1
%         plot(mTabel.curDur(idx), mTabel.mean_mean_repDur(idx),'r*-');% short estimation
%        
%         idx =  mTabel.WMSize == 3 & mTabel.TPresent ~= 1;
%         plot(mTabel.curDur(idx),mTabel.mean_mean_repDur(idx),'g*-');% long estimation       
%        
%         idx =  mTabel.WMSize == 5 & mTabel.TPresent ~= 1;
%         plot(mTabel.curDur(idx),mTabel.mean_mean_repDur(idx),'b*-');% long estimation  
%         plot(mTabel.curDur(idx), mTabel.curDur(idx), 'k-');
%         legend('WM1TargetPresent','WM3TargetPresent','WM5TargetPresent','WM1TargetAbsent','WM3TargetAbsent','WM5TargetAbsent','diag');
%     
%         xlabel('Sample duration');
%         ylabel('Reproduced duration');
%         hold off;
%      
        idx = allArray.valid ==1; %valid data
        mTabel = grpstats(allArray(idx,:),{'WMSize','curDur'},{'mean','sem'},'DataVars',{'repDur', 'Crr'});
        figure(); hold on;
        idx = mTabel.WMSize == 1;% WM1
        plot(mTabel.curDur(idx), mTabel.mean_repDur(idx),'r.-');% short estimation
       
        idx =  mTabel.WMSize == 3 ;
        plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'g.-');% long estimation       
       
        idx =  mTabel.WMSize == 5;
        plot(mTabel.curDur(idx),mTabel.mean_repDur(idx),'b.-');% long estimation       

        plot(mTabel.curDur(idx), mTabel.curDur(idx), 'k-');
        legend('WM1','WM3','WM5','diag');
    
        xlabel('Sample duration');
        ylabel('Reproduced duration');
        hold off;
end