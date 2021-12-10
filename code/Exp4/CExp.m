classdef CExp < handle
% class of experiment
% store experiment data, structure, procedure etc
% 10 July, 2011
% Created by: Z. Shi, shi@lmu.de
% ver. 0.2
% 21 June, 2012
%   add option: Continue. If will continue run experiment with given subject name
%   add additional Data variable
%
%constructor: two ways to initialize: 
    % constant method: 
    %   p1, repetition, 
    %   p2, factors
    % adapative method:
    %   p1, alpha 
    %   p2, beta
    %optional parameters: blockReptition, blockFactors;  
    % adaptive method:maxTrials,maxRespRev, gamma, lambda

    properties
        sName = 'test'; %subject information
        sAge = 20;
        sGender = 'f';
        sPara; %additional parameter
        eType = 1; % 1 - constant stimuli; 2- bayesian adaptive method        
        % type 1
        seq;    % sequences of the trials
        resp;   % corresponding responses
        aData;  % store additional data, can be anything...
        % only for type 2
        beta;
        alpha;
        gamma;
        lambda;
        maxTrls; %maximum trial number
        maxRev; % maximum reversal number
        % index
        curTrl; %current trial index
        curIntensity;
        practice;
        % other information
        startTime;
        endTime;
     end
    
    methods
        function obj = CExp(p1,p2,varargin)
            % constant method: 
            %   p1, repetition, 
            %   p2, factors
            % adapative method:
            %   p1, alpha 
            %   p2, beta
            %optional parameters: blockRepetition, blockFactors;  
            % adaptive method:maxTrials,maxRespRev, gamma, lambda
            p = inputParser;
            p.addOptional('eType','c', @(x) any(strcmpi(x,{'c','a'})));
            p.addParamValue('blockRepetition',1,@(x) x>0);
            p.addParamValue('blockFactors', [], @isnumeric);
            p.addParamValue('maxTrials', 40, @isnumeric);
            p.addParamValue('maxRespRev',8, @isnumeric);
            p.addParamValue('gamma',0.025,@(x) min(x)>=0);
            p.addParamValue('lambda',0.025, @(x) x>=0);
            p.addParamValue('practice',5, @(x) x>=0);
            p.parse(varargin{:});
            
            
            if p.Results.eType == 'c' %constant method
                obj.eType = 1;
                obj.curTrl = 1;
                obj.seq = obj.genTrials(p1,p2,p.Results.blockRepetition,p.Results.blockFactors);
                obj.resp = [];
                obj.maxTrls = length(obj.seq);
                
            else % adaptive method
                obj.alpha = p1;
                obj.beta = p2;
                obj.gamma = p.Results.gamma;
                obj.lambda = p.Results.lambda;
                obj.maxTrls = p.Results.maxTrials;
                obj.maxRev = p.Results.maxRespRev;
                obj.practice = p.Results.practice;
                obj.eType = 2;
                obj.curTrl = 1;
                obj.seq = zeros(obj.maxTrls,2);
                obj.resp = [];
            end
        end
        
        function obj = guessThreshold(obj,x)
            obj.seq(1,1:2) = [x 0];
            obj.curIntensity = x;
        end
        
        function obj = setResp(obj,resp)
            obj.resp(obj.curTrl,1:size(resp,2)) = resp;
            obj.curTrl = obj.curTrl+1;
        end
        
        function curSeq = getCondition(obj)
            curSeq = obj.seq(obj.curTrl,:);
        end
        
        function obj = updateThreshold(obj, p_target)
            % logistic function
            % p = Logistic(x, alpha, beta, gamma, lambda)
            %       alpha - threshold
            %       beta - slope
            %       gamma - chance performance / fa
            %       lambda - lapsing rate
            % Based on MLP toolbox
            % updated intensity and fa are stored in obj.seq
            if obj.curTrl < obj.practice
                % practice
                ra = randperm(length(obj.alpha));
                obj.seq(obj.curTrl,1)= obj.alpha(ra(1));
                obj.seq(obj.curTrl,2) = obj.gamma(1);
            else
                ll=zeros(length(obj.alpha), 1);
                x = obj.seq(obj.practice:max(obj.curTrl-1,1),1);
                responses = obj.resp(obj.practice:max(obj.curTrl-1,1));

                % calculate the likelihood of each psychometric function
                for i=1:length(obj.alpha)
                    for j=1:length(obj.gamma)
                        ll(i, j)=CalculateLikelihood(obj,x, responses, obj.alpha(i), obj.gamma(j));
                    end
                end

                % find the most likely psychometric function
                [i, j]=find(ll==max(max(ll)));
                if length(i)+length(j) > 2
                    i = i(1);
                    j = j(1);
                end;
                % calculate the level of the stimulus at p_target performance
                % using inverse logistic function
                obj.curIntensity = obj.alpha(i)-(1/obj.beta)*log(((1-obj.lambda-obj.gamma(j))./(p_target-obj.gamma(j)))-1);
                obj.seq(obj.curTrl,1)= obj.curIntensity;
                obj.seq(obj.curTrl,2) = obj.gamma(j);
            end
        end

        function bFinish = canStop(obj)
            if obj.eType == 2
                bFinish = 0;
                revnum = sum(abs(diff(obj.resp(obj.practice:obj.curTrl-1,1))));
                if revnum > obj.maxRev
                    bFinish = 1;
                end
                if obj.curTrl > obj.maxTrls
                    bFinish = 1;
                end
            else
                disp('This is only available for adaptive method');
            end
        end
        
        function ll=CalculateLikelihood(obj,x, responses, alpha, gamma)
            if obj.eType == 2
                warning off
                ll = 0;
                % calculate logistic probablity
                p=gamma+((1-obj.lambda-gamma).*(1./(1+exp(obj.beta.*(alpha-x)))));

                ll = sum(log(p(responses ==1)))+ sum(log(1-p(responses == 0)));
            else
                disp('This is only available for adaptive method');
            end
        end
        
        function h = plotLogistic(obj, a, g)
            %plot a logistic function for specify parameter, only available
            %for adaptive method
            if obj.eType == 2
                x = obj.alpha;
                if nargin < 2
                    a = median(obj.alpha);
                    g = median(obj.gamma);
                end
                y = g+((1-obj.lambda-g).*(1./(1+exp(obj.beta.*(a-x)))));
                h = figure; 
                plot(x,y);
            else
                disp('This is only available for adaptive method');
                h = -1;
            end
        end
        
        function trials=genTrials(obj,withinblock_repetitions, withinblock_factors, betweenblock_repetitions, betweenblock_factors)
            % syntax: genTrials(withinblock_repetition, betweenblock_repetition, withinblock_factors, [ betweenblock_factors])
            % eg: genTrials(2, [2 3],10); generate two factors (2 levels and 3 levels resp. ) with within block repetition 2 and between block repetition 10
            % coded by: strongway
            rand('seed',sum(clock*100));
            if  nargin < 3
                    error('Incorrect number of arguments for genTrials function');
            elseif nargin == 3
                    betweenblock_repetitions = 1;
                    betweenblock_factors  = [];
            elseif nargin == 4
                % when there's only betweenblock_repetitions, which is equal to swap
                % between block repetitions and factors -strongway 14. Dec. 2006
                    betweenblock_factors = betweenblock_repetitions;
                    betweenblock_repetitions  = 1;
            end

            trials = [];
            block_design = [];
            numblock = betweenblock_repetitions;
            if ~isempty(betweenblock_factors)
                block_design = fullfact(betweenblock_factors);
                block_design = repmat(block_design, betweenblock_repetitions,1);
                idxb = randperm(length(block_design));
                block_design = block_design(idxb,:);
                numblock = length(block_design);
            end

            for iblock = 1:numblock
                %generate within block trials
                inblock_trials = fullfact(withinblock_factors);
                inblock_trials = repmat(inblock_trials,withinblock_repetitions,1);
                idx=randperm(size(inblock_trials,1));
                inblock_trials = inblock_trials(idx,:);
                if ~isempty(block_design)
                    %add between factors
                    blockwise_factors = repmat(block_design(iblock,:),length(inblock_trials),1);
                    inblock_trials = [inblock_trials blockwise_factors];
                end
                trials = [trials; inblock_trials];
            end
        end

        function obj = subInfo(obj,sp1,sp2)
            % Get Subject information, sp1 and sp2 for additional parameters caption and parameters.
            promptParameters = {'Subject Name', 'Age', 'Gender (F or M?)'};
            defaultParameters = {'test', '20','F'};
            if nargin == 2
                promptParameters = [promptParameters, sp1];
                defaultParameters = {'test', '20','F','[]'};
            end
            if nargin == 3
                promptParameters = [promptParameters, sp1];
                defaultParameters = {'test', '20','F',sp2};
            end
            sub = inputdlg(promptParameters, 'Subject Info  ', 1, defaultParameters); 
            obj.sName = sub{1};
            obj.sAge = eval(sub{2});
            obj.sGender = sub{3};
            if nargin >= 2
                obj.sPara = eval(sub{4});
            end
            
            obj.startTime = now;
            % if it is continue, read the data
            if nargin == 3 && strcmp(sp1,'continue') 
                if obj.sPara == 1
                    subfile = ['data' filesep obj.sName '.mat'];
                    if ~exist(subfile)
                        error('No such data file');
                    else
                        load(subfile); % trials, expInfo, seq, resp
                        %restore the data
                        obj.seq = seq;
                        obj.resp = resp;
                        obj.aData = aData;
                        obj.curTrl = length(obj.resp)+1;
                        clear trials expInfo aData seq resp; 
                    end
                else % new subject, check if there is already a file
                    subfile = ['data' filesep obj.sName '.mat'];
                    if exist(subfile)
                        error('Data file already exist');
                    end
                end
            end
        end
        
        function saveData(obj,filename)
            if nargin<2
                filename = obj.sName;
            end
            obj.endTime = now;
            if ~isdir('data')
                mkdir('data'); %create a directory for storing files
            end
            seq = obj.seq;
            resp = obj.resp;
            trials = [seq(1:length(obj.resp),:), resp];
            expInfo.name = obj.sName;
            expInfo.age = obj.sAge;
            expInfo.sex = obj.sGender;
            expInfo.para = obj.sPara;
            expInfo.time = [obj.startTime, obj.endTime];
            aData = obj.aData;
            save(['data' filesep filename],'trials','expInfo','aData','seq','resp');
            
        end
        
    end
end