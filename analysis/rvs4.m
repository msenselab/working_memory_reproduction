%%
% author: Jiao Wu
% date: May 29, 2024
% contact: jiaowu2020@gmail.com
close all
clear
clc

%% load data
data = readtable('../data/AllValidData.csv');

dataExp1 = data(strcmp(data.Exp, 'Exp4'),:);
dataExp1.bias = dataExp1.repDur - dataExp1.curDur;


%% linear regression
parlist = unique(dataExp1.NSub);
npar = length(parlist);
wmlevel = unique(dataExp1.WMSize);
nwm = length(wmlevel);
% lm_para columns:
% nt1, wm1b0, wm1b1, wm1r2, nt3, wm3b0, wm3b1, wm3r2, nt5, wm5b0, wm5b1, wm5r2
lm_para2 = zeros(npar, 15);
for ipar = 1:npar
    lm_wm = [];
    for iwm = 1:nwm
        x = dataExp1.curDur(dataExp1.NSub==parlist(ipar) & dataExp1.WMSize==wmlevel(iwm));
        X = [ones(length(x),1), x];
        y = dataExp1.bias(dataExp1.NSub==parlist(ipar) & dataExp1.WMSize==wmlevel(iwm));
        n = length(x);
%         b = X\y; % b represents the relation y = b0+ b1*x; b=[b0, b1]
%         lm_y = X*b;
%         R2 = 1 - sum((y - lm_y).^2)/sum((y - mean(y)).^2);

        b = polyfit(x,y,1); % b=[b1, b0]
        lm_y = polyval(b,x);
%         R2 = 1 - sum((y-lm_y).^2)/((length(y)-1)*var(y));
        R2adj = 1 - sum((y-lm_y).^2)/((length(y)-1)*var(y)) * (length(y)-1)/(length(y)-length(b));
        lm_wm = [lm_wm, n, b, R2adj];
    end
    lm_para2(ipar,:) = lm_wm;
end

ip_par = lm_para2(:, [2,3,7,8,12,13]);
ip_par(:,7) = -ip_par(:,2)./ip_par(:,1);
ip_par(:,8) = -ip_par(:,4)./ip_par(:,3);
ip_par(:,9) = -ip_par(:,6)./ip_par(:,5);

disp(mean(ip_par(:, [7,8,9]),1));

mip=mean(ip_par(:, 1:6),1);
disp([-mip(2)/mip(1), -mip(4)/mip(3), -mip(6)/mip(5)]);



%%
figure;
scatter(x,y);
hold on
plot(x,lm_y,'--')
xlabel('Durations')
ylabel('Bias')
legend('Data','Slope & Intercept','Location','best');

%% fitting CV
bias_cv_par = grpstats(dataExp1, {'WMSize', 'curDur', 'NSub'}, {'mean'}, 'DataVars', {'repDur', 'bias'});
bias_cv = grpstats(bias_cv_par, {'WMSize', 'curDur'}, {'mean', 'std'}, 'DataVars', {'mean_repDur', 'mean_bias'});
bias_cv.cv_bias = bias_cv.std_mean_bias ./ bias_cv.mean_mean_bias;
bias_cv.cv_repDur = bias_cv.std_mean_repDur ./ bias_cv.mean_mean_repDur;
durList = reshape(bias_cv.curDur, [], 3);
cvList = reshape(bias_cv.cv_bias, [], 3);
rprcvList = reshape(bias_cv.cv_repDur, [], 3);
colorList = {'k', 'b', 'g'};

figure; hold on;
for iwm = 1:3
    scatter(durList(:,iwm),rprcvList(:,iwm), colorList{iwm});
end
xlabel('Durations')
ylabel('Bias CV')

x = durList(:,1)';
y = rprcvList(:,1)';
cftool(x, y)

mod1 = 'f(x) = a*log(x)/log(b)+c';
mod2 = 'f(x) = a*x/(b*x+c)';
mod3 = 'f(x) = p1*x^2 + p2*x + p3'; % best

y1 = 0.15*log(x)/log(100)-0.1;
y2 = (0.15*log(x)/log(100)-0.1)./0.2;
y3 = (0.15*log(x)/log(100)-0.1)./10;
figure; hold on; 
plot(x, y, 'k*-'); 
plot(x, -y1, 'g-'); 
plot(x, -y2, 'b-'); 
plot(x, -y3); 

