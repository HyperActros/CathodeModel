% 参数
area_target = 6500;  % 目标总面积
L = 100;             % 区域大小
r_min = 1;         % 最小半径
r_max = 3.5;         % 最大半径
min_dist = 0.2;      % 粒子间最小边缘距离

% 初始化
circles = []; % 每行 [x, y, r]
current_area = 0;

% 随机数种子（可选，保证复现）
rng(1);

while current_area < area_target
    % 随机生成一个半径
    r = r_min + (r_max - r_min) * rand();
    
    % 随机生成一个圆心
    x = r + (L - 2*r) * rand();
    y = r + (L - 2*r) * rand();
    
    % 检查是否和已有圆重叠
    if isempty(circles)
        overlap = false;
    else
        distances = sqrt((circles(:,1) - x).^2 + (circles(:,2) - y).^2);
        required_clearance = circles(:,3) + r + min_dist;
        overlap = any(distances < required_clearance);
    end
    
    % 如果不重叠，接受这个圆
    if ~overlap
        circles = [circles; x, y, r];
        current_area = current_area + pi * r^2;
    end
end
%% 

% 绘制结果
figure;
hold on;
axis equal;
xlim([0, L]);
ylim([0, L]);
for i = 1:size(circles,1)
    viscircles(circles(i,1:2), circles(i,3), 'EdgeColor','b');
end
title(sprintf('生成粒子数: %d，实际面积占比: %.2f%%', size(circles,1), current_area / (L*L) * 100));
hold off;