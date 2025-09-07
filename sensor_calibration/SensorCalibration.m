%% Rangefinder Calibration: True Distance vs Measured Distance
clear; close all; clc;

%% Procedure

% 在每个已知距离，采集多次传感器读数（例如 20 次），计算平均值。
% 同时记录标准差，作为测量波动的误差范围

% Enter your experimental data here 
% true_dist: ground truth distance using ruler (cm)
% meas_dist: measured distance from sensor (cm)
true_dist = 4:2:24;      
meas_dist = [4.291 6.239 7.871 11.266 11.936 14.021 16.063 17.673 19.602 21.208 23.645]; 

% Linear regression 
p = polyfit(meas_dist, true_dist, 1);   % true = a*measured + b
a = p(1); b = p(2);

% Generate fitted curve
meas_dense = linspace(min(meas_dist), max(meas_dist), 200);
true_fit   = polyval(p, meas_dense);

% Plot Calibration Graph
figure('Color','w');
scatter(meas_dist, true_dist, 70, 'filled'); hold on;
plot(meas_dense, true_fit, 'r-', 'LineWidth', 1.5);
grid on; box on;
xlabel('Measured distance by sensor (cm)');
ylabel('True distance (cm)');
title(sprintf('Calibration: true = %.5f * meas + %.2f', a, b));
legend('Measured data','Linear fit','Location','best');

% Print calibration formula
fprintf('Calibration result:\n');
fprintf('TrueDist (cm) = %.6f * MeasuredDist (cm) + %.6f\n', a, b);
fprintf('Inverse: MeasuredDist (cm) = (TrueDist - %.6f)/%.6f\n', b, a);

