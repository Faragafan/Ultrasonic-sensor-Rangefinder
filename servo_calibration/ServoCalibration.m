%% Servo Calibration: Angle vs Pulse Width
clear; close all; clc;

%% Procedure

% 设定一系列不同的 PWM 脉宽（例如 1000 µs, 1200 µs, …, 2000 µs），对应理想角度 0°–180°。
% 对每个脉宽，等舵机转动稳定后，用量角器读出实际角度。

% Experimental data here
% angle_deg (unit: degree)
% pulse_us  (unit: microseconds)

angle_deg = [];         
pulse_us  = 500:300:2500; 

% Linear regression 
p = polyfit(pulse_us, angle_deg, 1);  % angle = a*pw + b
a = p(1); b = p(2);

% Generate fitted curve
pulse_dense = linspace(min(pulse_us), max(pulse_us), 200);
angle_fit   = polyval(p, pulse_dense);

% Plot Calibration Graph
figure('Color','w');
scatter(pulse_us, angle_deg, 70, 'filled'); hold on;
plot(pulse_dense, angle_fit, 'r-', 'LineWidth', 1.5);
grid on; box on;
xlabel('Pulse width (\mus)');
ylabel('Angle (°)');
title(sprintf('Calibration: angle = %.5f * pw + %.2f ', a, b));
legend('Measured data','Linear fit','Location','best');

% Print calibration formula
fprintf('Calibration result:\n');
fprintf('Angle (deg) = %.6f * PulseWidth (us) + %.6f\n', a, b);
fprintf('Inverse: PulseWidth (us) = (Angle - %.6f)/%.6f\n', b, a);
