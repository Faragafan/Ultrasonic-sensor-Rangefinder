%% Servo Calibration Evaluation
clear; clc; close all;

% ------------------------------------------------------------
% INPUT: Desired vs Measured angles (deg)
% Fill these arrays with your data from experiment
desired = [0 30 60 90 120 150 180];   % Commanded angles
measured = [0 30 61 88 118 150 182];  % Measured angles

% ------------------------------------------------------------
% 1. Error Analysis
error = measured - desired;   % signed error
abs_error = abs(error);       % absolute error

% Accuracy (how close to true value, mean of errors)
mean_error = mean(error);             % bias
mean_abs_error = mean(abs_error);     % MAE

% Precision (repeatability, std of error)
std_error = std(error);               % standard deviation

% ------------------------------------------------------------
% 2. Summary Stats
fprintf('Servo Calibration Evaluation:\n');
fprintf('Mean Absolute Error (Accuracy): %.3f deg\n', mean_abs_error);
fprintf('Standard Deviation (Precision): %.3f deg\n', std_error);
fprintf('Max Absolute Error: %.3f deg\n', max(abs_error));

% ------------------------------------------------------------
% 3. Plot Results
figure('Color','w');
subplot(2,1,1);
plot(desired, measured,'bo-','LineWidth',1.5,'MarkerSize',6); hold on;
plot([min(desired), max(desired)], [min(desired), max(desired)],'r--','LineWidth',1.5);
grid on; box on;
xlabel('Desired Angle (°)'); ylabel('Measured Angle (°)');
title('Servo Calibration: Desired vs Measured');
legend('Measured','Ideal (y=x)','Location','best');

subplot(2,1,2);
stem(desired, error,'filled');
grid on; box on;
xlabel('Desired Angle (°)'); ylabel('Error (Measured - Desired) (°)');
title('Servo Calibration Error per Angle');

