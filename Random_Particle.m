%% 需要预输入以下参数
area_target = 2000;  % 目标总面积
L = 100;             % 区域大小
r_min = 5;         % 最小半径
r_max = 5;         % 最大半径
min_dist = 0.2;      % 粒子间最小边缘距离

%% 初始化
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

% 粒子数据：每行是 [x, y, 直径]
% 如果你的数据保存在变量 particles 中，则直接用它

num_particles = size(circles, 1);
min_dis = inf;  % 初始化最小间距
min_pair = [];

for i = 1:num_particles-1
    for j = i+1:num_particles
        center_dist = norm(circles(i,1:2) - circles(j,1:2));
        surface_dist = center_dist - (circles(i,3) + circles(j,3));

        if surface_dist < min_dis
            min_dis = surface_dist;
            min_pair = [i, j];
        end
    end
end

fprintf('最小表面间距为：%.4f\n', min_dis);
fprintf('最小间距粒子编号为：%d 和 %d\n', min_pair(1), min_pair(2));

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
