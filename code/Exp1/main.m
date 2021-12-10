%  Description: Time reproduction tast mixed with WM task
%  WMPresent, production,WM test, reproduction
%   The structure of stored 'trials'
%    column 1: set size, 1,3,5
%           2: short or long group
%           3: duration 1-5
%           4: test target present/absent 
%           5: target position
%           6: number of trial
%           7: presented color (in rad)
%           8: tested color (in rad)
%           9-11 (or 8:14): presented colors (1,3,5) in degree
%               degrees are selected from colorwheel360.mat
% 2017-09-03
%removed singleton and catch trial condition, set size changed to 1, 3, 5, always one
%target
% Dural task: production-reproduction between WM task
function main
  try
    
    clear all;
    clc;
    Screen('Preference', 'SkipSyncTests', [],[0 0 800 600], 1);
      startIntro = ['Trial Sequence: \n\n'  ...
          '1st - Memory presentation:  remember the squares   \n \n' ...
          '2nd - Time production:   feel the time duration            \n \n' ...
          '3rd - Memory test:  LEFT = yes       RIGHT = no  \n\n' ...
          '4th - Time reproduction:  press and hold the DOWN arrow key'  ];
    KbName('UnifyKeyNames');
    esckey = KbName('ESCAPE');
    kbRP = CInput('k', [1], {'DownArrow'});
    kbWM = CInput('k');
    %18 blocks, each block with 20 trials, all with 360 trials, around 1
    %hour
    nTrlsBlk = 20;
    exp = CExp(1,[3 1 5 2],'blockRepetition', 12); 
    exp.seq(:,1) = (exp.seq(:,1) -1)*2 + 1; % convert to 1,3,5
    exp.subInfo;            % acquire subject information
    prepareEnvironment;
    window = openWindow();
    v = window.disp;
    prefs = getPreferences(); 
    % set time reproduction parameters
    para.nDurations = [0.5:0.3:1.7; 0.5:0.3:1.7]; % short (0.6-1.0), long (0.9-1.2)
    para.vSize = 150; % size is 2 times as large as VM stimuli
    para.fColor = [187,187, 187]; % foreground color
    para.fColorW = [252];
    para.green = [0, 192, 0];
    para.red = [192, 0, 0];
    para.vFeedDivid = 150;
    para.xyFeedbackArray = [-2,0; -1, 0; 0, 0; 1, 0; 2,  0] * 1.5; 
%     para.xyFeedbackArray = [-2,0; -1, 0; 0, 0; 1, 0; 2,  0]; 
    para.fbRange = [-100, -0.3; -0.3, -0.05; -0.05, 0.05; 0.05, 0.3; 0.3, 100]; %feedback range with respect to the reproduction error
    vGreenDisk = v.createShape('circle', para.vSize/para.vFeedDivid, para.vSize/para.vFeedDivid, 'color', para.green);
    vRedDisk = v.createShape('circle', para.vSize/para.vFeedDivid, para.vSize/para.vFeedDivid, 'color', para.red);
    vDiskFrame = v.createShape('circle',para.vSize/para.vFeedDivid, para.vSize/para.vFeedDivid, 'color', para.fColorW,'fill',0);
    para.vFullFrames = [vDiskFrame, vDiskFrame, vDiskFrame, vDiskFrame, vDiskFrame];
    para.vFullDisks = [vRedDisk, vGreenDisk, vGreenDisk, vGreenDisk, vRedDisk];
    % add item locations
    for i=1:length(exp.seq)
        r_pos = randperm(exp.seq(i,1));
        exp.seq(i,5) = r_pos(1); % target position
    end
    exp.seq(:,6) = 1:length(exp.seq(:,5) ); 
    % put up instructions and wait for keypress
    v.dispText(startIntro);
    kbRP.wait;
%     v.dispFixation(10,2);    
%     WaitSecs(1);
    
    % get rects for items
    for i = 1:max(prefs.setSizes)
      rects{i} = circularArrayRects([0, 0, prefs.squareSize, prefs.squareSize], i, prefs.radius, window.centerX, window.centerY)';
    end
    rectDur = CenterRectOnPoint([0, 0, para.vSize, para.vSize], window.centerX, window.centerY);
    colorWheelLocations = colorwheelLocations(window,prefs);
    
    for trialIndex = 1:exp.maxTrls
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 1.WM presentation
    %%%%%%%%%%%%%%%%%%%%%%%%%%
        if  mod( (trialIndex-1), nTrlsBlk) == 0 
             v.dispText(' Please press any key to start this block\n');
             kbRP.wait;
        end
        cond = exp.getCondition %get condition array from exp configuration
        curDuration = para.nDurations(cond(2),cond(3));
        nItems = cond(1); % 3 or 6
       % pick colors for this trial (an array that contains 3 or 6 values)
       colorsInDegrees = ceil(rand(1,nItems)*360);
       % draw fixation
       v.dispFixation(20);
       WaitSecs(0.5);      
      colorsToDisplay = prefs.colorwheel(colorsInDegrees, :)';
      % add additional frames
%       drawColorWheel(window, prefs);
%       v.flip;
      for i=1:nItems
          curRect = rectExpand(rects{nItems}(:,i), prefs.expandSize, prefs.expandSize);
            Screen('FrameRect', window.onScreen, prefs.distractorColor, curRect);
      end
      % fill colors
      Screen('FillRect', window.onScreen, colorsToDisplay, rects{nItems});
      % post stimulus and wait
      v.flip;
      WaitSecs(prefs.stimulusDuration);

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 2. time production
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % production
    v.dispText('Production');
    WaitSecs(0.5);
    v.dispFixation(20);
    WaitSecs(0.5);
     Screen('FillOval', window.onScreen, para.fColor , rectDur);    
     [vbl,  vInitTime] = Screen('Flip', window.onScreen);
     WaitSecs(curDuration - 0.003);
     [vbl, vStopTime] = Screen('Flip', window.onScreen);
     keyReleaseTime = kbRP.keyRelease;   
     phyDuration = vStopTime - vInitTime;      %visual duration
     proDuration = keyReleaseTime - vInitTime; %key production    
     WaitSecs(0.500);
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 3 WM test
    %%%%%%%%%%%%%%%%%%%%%%%%%%
       targetItem = cond(5); % 1st rand position %RandSample(1:nItems);
       targetSame = cond(4);
       if  targetSame == 1       % target present
            testedColor = colorsInDegrees(targetItem);
       else
           testedColor = ceil(rand(1,1)*360);%generate new color for the test target
       end
      colorsOfTest = repmat([120 120 120], nItems, 1);
      colorsOfTest(targetItem, :) = prefs.colorwheel(testedColor, :)';     
      v.dispText('?', 0);
      Screen('FillRect', window.onScreen, colorsOfTest', rects{nItems});
      v.flip;
      % Yes/no response
      [keyWM, keyRPTimeWM] = kbWM.response;
     v.flip;
     % set 1 seconds break time between WM and time duration-reproducation
     % task
     WaitSecs(1);    
     
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 4. reproduction
    %%%%%%%%%%%%%%%%%%%%%%%%%%
     v.dispText('Reproduction');
     [key, keyInitTime] = kbRP.response;
     Screen('FillOval', window.onScreen, para.fColor , rectDur);    
     [vbl, vInitTime] =Screen('Flip', window.onScreen);
     keyReleaseTime = kbRP.keyRelease;
      [vbl, vStopTime] =  Screen('Flip', window.onScreen);
      repDuration = keyReleaseTime - keyInitTime; % key reproduction
      repVDuration = vStopTime - vInitTime; % visual reproduction
      
       if kbRP.wantStop
            break;
        end 
       % present a feedback display
        feedbackDisplay = para.vFullFrames;
        delta = (repDuration - phyDuration)/phyDuration;
        % find the range of the error
        cIdx = para.fbRange > delta; % column index of left and right boundary
        idx = find(xor(cIdx(:,1),cIdx(:,2)));
        feedbackDisplay(idx(1)) = para.vFullDisks(idx(1));

%         WaitSecs(0.25); % wait 250 ms
        v.dispItems(para.xyFeedbackArray, feedbackDisplay,[para.vSize/para.vFeedDivid para.vSize/para.vFeedDivid]); % draw texture 
       if abs(delta) > 0.3
           WaitSecs(1.500);
       else
            WaitSecs(0.500); % display the feedback for 500 ms
       end
        v.flip;  
       %ITI = 1seconds
        WaitSecs(1);
    % save response
    % curDur, phyDur, proDur, repVDur, repDur, targetColor, testColor,
    % WMRP, PresentedColor
     [curDuration, phyDuration, proDuration, repVDuration, repDuration, ...
           deg2rad(colorsInDegrees(targetItem)), deg2rad(testedColor), keyWM, colorsInDegrees]
       exp.setResp( [curDuration, phyDuration, proDuration, repVDuration, repDuration, ...
           deg2rad(colorsInDegrees(targetItem)), deg2rad(testedColor), keyWM, colorsInDegrees]); %store response:
    end
    
    
     %closing the experiment
    exp.saveData;   %save data
%   save data.mat data prefs
    postpareEnvironment;
    
  catch ME
    postpareEnvironment;
    disp(ME.message);
    disp(ME.stack);
    for iTrl=1:length(ME.stack)
        disp(ME.stack(iTrl).name);
        disp(ME.stack(iTrl).line);
    end
    
  end % end try/catch
end % end whole colorworkingmemoryscript

function prepareEnvironment
  
  clear all;
  HideCursor;
  commandwindow; % select the command window to avoid typing in open scripts
  % seed the random number generator
  rand('seed',sum(clock*100));
end

function postpareEnvironment
  ShowCursor;
  ListenChar(0);
  Screen('CloseAll');
end

function offsets = circularArrayOffsets(n, centerX, centerY, radius, rotation)
  degreeStep = 360/n;
  offsets = [sind([0:degreeStep:(360-degreeStep)] + rotation)'.* radius, cosd([0:degreeStep:(360-degreeStep)] + rotation)'.* radius];
end

function rects = circularArrayRects(rect, nItems, radius, centerX, centerY)
  coor = circularArrayOffsets(nItems, centerX, centerY, radius, 0) + repmat([centerX centerY], nItems, 1);
  rects = [coor(:, 1)-rect(3)/2 , coor(:, 2)-rect(3)/2, coor(:, 1)+rect(3)/2, coor(:, 2)+rect(3)/2];
end

function rects = rectExpand(rect, rx,ry)
    rects = [rect(1)-rx, rect(2)-ry, rect(3)+rx, rect(4)+ry];
end

function window = openWindow()
    para.viewDistance = 57; % viewing distance 57 cm
    para.monitor = 22; % monitor size
    para.fntSize = 18; % font size
    para.bkColor = 128; % background color
%   Screen('Preference', 'SkipSyncTests', 1);
   V  = CDisplay('bgColor',para.bkColor,'fontSize',para.fntSize,'monitorSize',para.monitor,...
        'viewDistance',para.viewDistance,'fullWindow', 0);
   window.onScreen  = V.wnd;
   window.disp = V;
  window.screenNumber = max(Screen('Screens'));
    Screen('BlendFunction', window.onScreen, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%   [window.onScreen rect] = Screen('OpenWindow', window.screenNumber, [128 128 128],[],[],[],[]);
 % [window.onScreen rect] = Screen('OpenWindow', window.screenNumber, [128 128 128],[0 0 700 700],[],[],[]);
 %  Screen('Preference', 'SkipSyncTests', 1);
    [window.screenX, window.screenY] = Screen('WindowSize', window.onScreen); % check resolution
  window.screenRect  = [0 0 window.screenX window.screenY]; % screen rect
  window.centerX = window.screenX * 0.5; % center of screen in X direction
  window.centerY = window.screenY * 0.5; % center of screen in Y direction
  window.centerXL = floor(mean([0 window.centerX])); % center of left half of screen in X direction
  window.centerXR = floor(mean([window.centerX window.screenX])); % center of right half of screen in X direction
  
  % basic drawing and screen variables
  window.black    = BlackIndex(window.onScreen);
  window.white    = WhiteIndex(window.onScreen);
  window.gray     = mean([window.black window.white]);
  window.fontsize = 24;
  window.bcolor   = window.gray;
end

function drawColorWheel(window, prefs)
  colorWheelLocations = [cosd([1:360]).*prefs.colorWheelRadius + window.centerX; ...
    sind([1:360]).*prefs.colorWheelRadius + window.centerY];
  colorWheelSizes = 20;
  Screen('DrawDots', window.onScreen, colorWheelLocations, colorWheelSizes, prefs.colorwheel', [], 1);
end

function L = colorwheelLocations(window,prefs)
  L = [cosd([1:360]).*prefs.colorWheelRadius + window.centerX; ...
    sind([1:360]).*prefs.colorWheelRadius + window.centerY];
end

function prefs = getPreferences
  prefs.nTrialsPerCondition = 2;
  prefs.setSizes = [3,6];
  prefs.retentionInterval = 0.75;
  prefs.stimulusDuration = 0.5;
  prefs.squareSize = 75; % size of each stimulus object, in pixels
  prefs.radius = 180;
  prefs.fixationSize = 10;
  
  % singleton details
  prefs.expandSize = 15; % expanded size to the target size
  prefs.distractorColor = [255 255 255];
  
  % colorwheel details
  prefs.colorWheelRadius = 350;
  prefs.colorwheel = load('colorwheel360.mat', 'fullcolormatrix');
  prefs.colorwheel = prefs.colorwheel.fullcolormatrix;
  
end
