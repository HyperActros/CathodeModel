# 供Abaqus使用的（电池电极）随机多孔材料二维模型脚本
This code made by Actros0

# THIS IS 2D MODEL
# HOW TO USE

1.打开Random_Particle.m，预输入参数后运行脚本，生成随机分布的粒子数据。

2.根据需要选择打开Plate_Particle (_Cohesive),将粒子数据写入对应位置，并填入相关参数，运行脚本。即可得到'name.py'脚本文件。

3.打开Abaqus，点击File-Run Script-‘name.py'运行脚本，生成半成品Model。在Assembly中Merge合并所有部件（注意Intersecting Boundaries选择Retain！）。材料参数和设置网格可使用选定Set完成。

![image](https://github.com/user-attachments/assets/cd1e20e6-cd5c-4b8c-af6e-60189415c0dc)

# 关于Random_Particle
预输入后仅供设置粒子之间最小距离额外条件，没有添加其他的条件，而且只能嵌入圆形。

导致最后只能勉强达到60%的粒子面积占比。

# 没有学会代码的封装和可视化，所以没有GUI导致依托
应该设置成最开始可以选择：粒子，粒子+Cohesive，空孔三种模型类型。
