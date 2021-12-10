classdef CDisplay < handle
    % a display class, manage the most common display functions, such as
    % display text, fixation, flip, degree of visual angle. It also stores
    % display informations, such as resolution, center x,y, ifi ...
    % methods:
    %   1. constructor
    %       obj=CDisplay('monitorSize',size,'viewDistance',viewDistance,'bgColor',bgColor,'Color',color,'fontSize',fz,'skipSync',bSync);
    %   2. display text
    %       dispText(txt[,flip,clearBackground]);
    %   3. close screen
    %       close();
    %   4. calculate visual angle (deg) to pixels
    %       deg2pix(degree)
    %   5. display fixation
    %       dispFixation(size [,type, flip, clearBackground]);
    %   6. flip: bring back buffer to front (display)
    %       flip(obj [, clearBackground])    
    % Screen class of PTB
    % Last modify: 7.7.2011
    % Created by: Z. Shi, shi@lmu.de
    
    % 14.07.2011 add createShape function to create simple shapes
    % 07.07.2014 add debug option - fullWindow, 

    properties
        wnd = -1;   %window handle
        bSkipSync = 0;
        fullWindow = 1; % full screen
        ifi = -1;   %inter-frame interval (refresh rate)
        cx = -1;    % center x
        cy = -1;    % center y
        pdeg;       % pixels per degree
        bgColor = 0;     % background color
        color = 255;     % front color
        fontSize = 14;
        lineWidth = 60;
        lineSpace = 1.5;
        inch = 20;
        viewDistance = 57;
        nItem = 0;
        items; 
    end
    
    methods
        function obj = CDisplay(varargin) 
        	% constructure
            % inch,viewDistance, bgColor, color, fontsize
            p = inputParser;
            p.addParamValue('monitorSize',20,@isnumeric);
            p.addParamValue('viewDistance',57,@isnumeric);
            p.addParamValue('bgColor',[0 0 0],@isnumeric);
            p.addParamValue('Color',[255 255 255],@isnumeric);
            p.addParamValue('fontSize',14,@isnumeric);
            p.addParamValue('lineWidth',60,@isnumeric);
            p.addParamValue('lineSpace',1.5,@isnumeric);
            p.addParamValue('skipSync',0,@isnumeric);
            p.addParamValue('fullWindow',1,@isnumeric);
            p.parse(varargin{:});
            
            %init screens
            obj.inch = p.Results.monitorSize;
            obj.viewDistance = p.Results.viewDistance;
            obj.bgColor = p.Results.bgColor;
            obj.color = p.Results.Color;
            obj.fontSize = p.Results.fontSize;
            obj.lineWidth = p.Results.lineWidth;
            obj.lineSpace = p.Results.lineSpace;
            obj.bSkipSync = p.Results.skipSync;
            obj.fullWindow = p.Results.fullWindow;
           try
                InitializeMatlabOpenGL;
                AssertOpenGL;
                priority = MaxPriority('KbCheck');
                Priority(priority);
                HideCursor; 
                if obj.bSkipSync
                    Screen('Preference','SkipSyncTests',1);
                else
                    Screen('Preference','SkipSyncTests',0);
                end

                screens=Screen('Screens');
                screenNumber=max(screens);
                if obj.fullWindow
                 [obj.wnd wsize] = Screen('OpenWindow',screenNumber); % Open On Screen window, mainWnd
                else
                    [obj.wnd wsize] = Screen('OpenWindow',screenNumber,[],[0 0 800 600]); 
                end
                obj.ifi=Screen('GetFlipInterval', obj.wnd); 
                
                obj.cx = wsize(3)/2; %center x
                obj.cy = wsize(4)/2; %center y
                pix = obj.inch*2.54/sqrt(1+9/16)/wsize(3);  % calculate one pixel in cm
                obj.pdeg = round(2*tan((1/2)*pi/180) * obj.viewDistance / pix); 
            catch ME
                Screen('CloseAll');
                Priority(0);
                disp(ME.message);
                disp('error in initial display');
            end
        end % end of constructor

        function nframes = sec2frames(obj,secs)
            %convert seconds to number of frames
            nframes = round(secs/obj.ifi);
        end
        
        function dispText(obj,txt, flip,clearBackground)
        % dispText
            try
                if nargin < 3  
                    flip = 1;
                    clearBackground = 1;
                end
                if nargin == 3
                    clearBackground = 1;
                end
                if clearBackground 
                	Screen('FillRect',obj.wnd,obj.bgColor);
                end
                Screen('TextSize',obj.wnd,obj.fontSize);
                DrawFormattedText(obj.wnd,txt,'center','center',obj.color,obj.lineWidth,[],[],obj.lineSpace);
                if flip
                    Screen('Flip', obj.wnd);
                end  
            catch ME
                Screen('CloseAll');
                Priority(0);
                disp(ME.message);
            end
        end % end of dispText method
        
        function itemIndex = createItem(obj,itemData)
            %create items (texture, image, etc.)
             itemIndex= Screen('MakeTexture', obj.wnd, itemData);
             obj.nItem = obj.nItem + 1;
             obj.items(obj.nItem) = itemIndex;
        end
        
        function itemIndex = createShape(obj,name,x,y,varargin)
            %create simple shape 
            %be sure to do this before the trial starts
            p = inputParser;
            p.addRequired('name', @(x) any(strcmpi(x,{'rectangle','circle'})));
            p.addRequired('x',@(x) x>0);
            p.addRequired('y',@(x) x>0);
            p.addParamValue('fill',1,@isnumeric);
            p.addParamValue('border',0.1,@(x) x>0);
            p.addParamValue('bgColor',obj.bgColor,@isnumeric);
            p.addParamValue('color',obj.color,@isnumeric);
            p.parse(name,x,y,varargin{:});
            
            xp = round(p.Results.x * obj.pdeg)/2;
            yp = round(p.Results.y * obj.pdeg)/2; %convert to pixels
            bp = round(p.Results.border * obj.pdeg);
            bc = p.Results.bgColor;
            fc = p.Results.color;
            if length(bc) == 1
                bc = repmat(bc,3,1);
            end
            if length(fc) == 1
                fc = repmat(fc,3,1);
            end
            data = zeros(xp*2,yp*2,3); %store in rgb format
            switch p.Results.name
                case {'circle'}
                    if p.Results.fill == 1 %fill
                        for ix = 1:xp*2
                            for iy = 1:yp*2
                                if (ix-xp)*(ix-xp)/xp/xp + (iy-yp)*(iy-yp)/yp/yp < 1 
                                    data(ix,iy,:) = fc;
                                else
                                    data(ix,iy,:) = bc;
                                end
                            end
                        end
                    else % frame
                        for ix = 1:xp*2
                            for iy = 1:yp*2
                                if (ix-xp)*(ix-xp)/xp/xp + (iy-yp)*(iy-yp)/yp/yp < 1 && ...
                                        (ix-xp)*(ix-xp)/(xp-bp)/(xp-bp) + (iy-yp)*(iy-yp)/(yp-bp)/(yp-bp) >= 1 
                                    data(ix,iy,:) = fc;
                                else
                                    data(ix,iy,:) = bc;
                                end
                            end
                        end
                    end
                case {'rectangle'}
                    if p.Results.fill == 1 %fill
                        for ix = 1:xp*2
                            for iy = 1:yp*2
                                    data(ix,iy,:) = fc;
                            end
                        end
                    else %frame
                        for ix = 1:xp*2
                            for iy = 1:yp*2
                                if abs(ix-xp)>xp-bp || abs(iy-yp)>yp-bp
                                    data(ix,iy,:) = fc;
                                else
                                    data(ix,iy,:) = bc;
                                end
                            end
                        end
                    end
            end %end of switch
            %create texture
            itemIndex= Screen('MakeTexture', obj.wnd, data);
            obj.nItem = obj.nItem + 1;
            obj.items(obj.nItem) = itemIndex;
            
        end
        function dispItems(obj, xys, itemIndex, itemSizes,rotations, flip)
            %disp items at xys (in visual angle, center 0,0)
            if nargin < 6
                flip = 1;
            end
            if nargin < 5
                rotations = [];
            end
            if nargin < 4
                itemSizes = [obj.cx / obj.pdeg, obj.cy/obj.pdeg]*2;
            end
            destRects = zeros(4, length(itemIndex));
            for iObj = 1: length(itemIndex)
                if size(itemSizes,1) == 1
                    itemRect = [0 0 itemSizes*obj.pdeg];
                else
                    itemRect = [0 0 itemSizes(iObj,:)*obj.pdeg];
                end
                rect = CenterRectOnPoint(itemRect,obj.pdeg*xys(iObj,1)+obj.cx, obj.pdeg*xys(iObj,2)+obj.cy);
                destRects(:,iObj) = rect';
            end
            Screen('DrawTextures',obj.wnd,itemIndex,[],destRects,rotations);
            if flip
                Screen('Flip', obj.wnd);
            end
        end
        
        function close(obj)
        %% dispClose: close display
            %close display and delete Screen
            Screen('CloseAll');
            ShowCursor;
            Priority(0);
            obj.wnd = -1;
        end % end of closeDisp
        
        function pixs=deg2pix(obj, degree) 
        %% deg2pix: calculate degree to pixels
            screenWidth = obj.inch*2.54/sqrt(1+9/16);  % calculate screen width in cm
            pix=screenWidth/obj.cx/2;  %calculates the size of a pixel in cm 
            pixs = round(2*tan((degree/2)*pi/180) * obj.viewDistance / pix); 
        end %end of deg2pix
        
        function deg = pix2deg(obj, pixels)
            deg = 1/obj.pdeg*pixels;
        end
        
        function dispFixation(obj,sz,type,flip,clearBackground)
        %% dispCrossFix: display cross fixation
            if nargin < 3
                type = 1;
                flip = 1;
                clearBackground = 1;
            end
            if nargin == 3
                flip = 1;
                clearBackground = 1;
            end
            if nargin == 4
                clearBackground = 1;
            end
            if clearBackground
                Screen('FillRect',obj.wnd, obj.bgColor);
            end
            if type == 1
                rect = CenterRectOnPoint([0 0 2 sz],obj.cx,obj.cy);
                Screen('FillRect',obj.wnd,obj.color,rect);
                rect = CenterRectOnPoint([0 0 sz 2],obj.cx,obj.cy);
                Screen('FillRect',obj.wnd,obj.color, rect);
            else
                rect = CenterRectOnPoint([0 0 sz sz],obj.cx,obj.cy);
                Screen('FillOval',obj.wnd,obj.color,rect);
            end
            if flip
                Screen('Flip',obj.wnd);
            end
        end %end of dispCrossFix
                        
        function [vbl visonset] = flip(obj,clearBackground, when)
        %% flip: put back buffer to screen
            if nargin < 3
                when = 0;
            end
            if nargin < 2
                clearBackground = 0;
            end
            if clearBackground
                Screen('FillRect',obj.wnd,obj.bgColor);
            end
            [vbl visonset] = Screen('Flip',obj.wnd, when);
        end
        
    end
end