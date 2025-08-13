%% 写入预处理信息，将会创建一个板和许多球粒子。粒子周围可设置Cohesive层。各部件都创建了set。
%% 请在Abaqus中手动Merge
model_name = '';
python_script = 'PLATE_PARTICLE_COHESIVE.py';

% 板材尺寸
plate_width = ;
plate_height = ;

% cohesive的厚度
dr = ;

% 孔的坐标和直径 (x, y, d)
particles = [ ];

%% ==== Life finds a way ====
% ==== Abaqus initialization ====
fid = fopen(python_script, 'w');
fprintf(fid, 'from abaqus import *\n');
fprintf(fid, 'from abaqusConstants import *\n');
fprintf(fid, 'from mesh import ElemType\n');
fprintf(fid, 'import regionToolset\n');
fprintf(fid, 'import mesh\n');
fprintf(fid, 'import part\n');
fprintf(fid, 'import assembly\n');
fprintf(fid, 'import interaction\n\n');

% ==== Part ====
fprintf(fid, 'model_name = "%s"\n', model_name);
fprintf(fid, 'mdb.Model(name=model_name, modelType=STANDARD_EXPLICIT)\n\n');

% ==== PLATE ====
fprintf(fid, ' = mdb.models[model_name].ConstrainedSketch(name="plate_sketch", sheetSize=10.0)\n');
fprintf(fid, '.rectangle(point1=(0, 0), point2=(%.9f, %.9f))\n', plate_width, plate_height);
fprintf(fid, 'p = mdb.models[model_name].Part(name="Plate", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)\n');
fprintf(fid, 'Plate = mdb.models[model_name].parts["Plate"]\n');
fprintf(fid, 'p.BaseShell(sketch=)\n\n');
fprintf(fid, 'p.Set(name="BINDER", faces=p.faces[:])\n');

% ==== PARTICLE ====
fprintf(fid, 'particle_sketch = mdb.models[model_name].ConstrainedSketch(name="particle_sketch", sheetSize=10.0)\n');
for i = 1:size(particles,1)
    x = particles(i,1);
    y = particles(i,2);
    r = particles(i,3)/2;
    fprintf(fid, 'particle_sketch.CircleByCenterPerimeter(center=(%.9f, %.9f), point1=(%.9f, %.9f))\n', x, y, x+r, y);
end
fprintf(fid, 'p = mdb.models[model_name].Part(name="Particle", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)\n');
fprintf(fid, 'p.BaseShell(sketch=particle_sketch)\n\n');
fprintf(fid, 'Particle = mdb.models[model_name].parts["Particle"]\n');
fprintf(fid, 'p.Set(name="PARTICLE", faces=p.faces[:])\n');

for i = 1:size(particles, 1)
    x = particles(i, 1);
    y = particles(i, 2);
    r = particles(i, 3)/2;
    
    fprintf(fid, 'pickedFaces = p.faces.findAt(((%.9f, %.9f, 0.0),))\n', x, y);
    fprintf(fid, ' = mdb.models["%s"].ConstrainedSketch(name="partition_sketch", sheetSize=100.0)\n', model_name);
    fprintf(fid, '.Line(point1=(%.9f, %.9f), point2=(%.9f, %.9f))\n', x-2*r, y, x+2*r, y); % 水平
    fprintf(fid, '.Line(point1=(%.9f, %.9f), point2=(%.9f, %.9f))\n', x, y-2*r, x, y+2*r); % 竖直
    fprintf(fid, 'p.PartitionFaceBySketch(faces=pickedFaces, sketch=)\n');
end

% ==== COHESIVE ====
fprintf(fid, 'ring_sketch = mdb.models[model_name].ConstrainedSketch(name="ring_sketch", sheetSize=10.0)\n');
for i = 1:size(particles,1)
    x = particles(i,1);
    y = particles(i,2);
    r = particles(i,3)/2;
    % 外圆
    fprintf(fid, 'ring_sketch.CircleByCenterPerimeter(center=(%.9f, %.9f), point1=(%.9f, %.9f))\n', x, y, x + r + dr, y);
    % 内圆
    fprintf(fid, 'ring_sketch.CircleByCenterPerimeter(center=(%.9f, %.9f), point1=(%.9f, %.9f))\n', x, y, x + r, y);
end
fprintf(fid, 'p_ring = mdb.models[model_name].Part(name="Cohesive", dimensionality=TWO_D_PLANAR, type=DEFORMABLE_BODY)\n');
fprintf(fid, 'p_ring.BaseShell(sketch=ring_sketch)\n');
fprintf(fid, 'Cohesive = mdb.models[model_name].parts["Cohesive"]\n');
fprintf(fid, 'p_ring.Set(name="COHESIVE", faces=p_ring.faces[:])\n');

for i = 1:size(particles,1)
    x = particles(i,1);
    y = particles(i,2);
    r = particles(i,3)/2 + dr; % 切割线覆盖外圆
    
    fprintf(fid, 'f = p_ring.faces.getByBoundingBox(%.9f, %.9f, -1e-6, %.9f, %.9f, 1e-6)\n', x - r*1.1, y - r*1.1, x + r*1.1, y + r*1.1);
    fprintf(fid, 'partition_sketch = mdb.models[model_name].ConstrainedSketch(name="partition_sketch", sheetSize=10.0, gridSpacing=0.1)\n');
    fprintf(fid, 'partition_sketch.Line(point1=(%.9f, %.9f), point2=(%.9f, %.9f))\n', x - r*1.5, y, x + r*1.5, y); % 水平线
    fprintf(fid, 'partition_sketch.Line(point1=(%.9f, %.9f), point2=(%.9f, %.9f))\n', x, y - r*1.5, x, y + r*1.5); % 垂直线
    fprintf(fid, 'p_ring.PartitionFaceBySketch(faces=f, sketch=partition_sketch)\n');
end

% ==== STEP ====
fprintf(fid, 'mdb.models[model_name].StaticStep(\n');
fprintf(fid, '    name="Step-1",\n');
fprintf(fid, '    previous="Initial",\n');
fprintf(fid, '    timePeriod=1.0,\n');
fprintf(fid, '    maxNumInc=1000,\n');
fprintf(fid, '    initialInc=1e-5,\n');
fprintf(fid, '    minInc=1e-10,\n');
fprintf(fid, '    maxInc=0.01,\n');
fprintf(fid, '    nlgeom=ON\n');
fprintf(fid, ')\n');

% ==== ASSEMBLY ====
fprintf(fid, 'a = mdb.models[model_name].rootAssembly\n');
fprintf(fid, 'a.DatumCsysByDefault(CARTESIAN)\n');
fprintf(fid, 'a.Instance(name="Plate-1", part=Plate, dependent=ON)\n');
fprintf(fid, 'a.Instance(name="Particle-1", part=Particle, dependent=ON)\n');
fprintf(fid, 'a.Instance(name="Cohesive-1", part=Cohesive, dependent=ON)\n');

% ==== INTERACTION ====
fprintf(fid, 'mdb.models[model_name].ContactProperty("ContactProp")\n');
fprintf(fid, 'mdb.models[model_name].interactionProperties["ContactProp"].TangentialBehavior(\n');
fprintf(fid, '    formulation=PENALTY,\n');
fprintf(fid, '    directionality=ISOTROPIC,\n');
fprintf(fid, '    slipRateDependency=OFF,\n');
fprintf(fid, '    pressureDependency=OFF,\n');
fprintf(fid, '    temperatureDependency=OFF,\n');
fprintf(fid, '    dependencies=0,\n');
fprintf(fid, '    table=((0.2,),),\n');
fprintf(fid, '    shearStressLimit=None,\n');
fprintf(fid, '    maximumElasticSlip=FRACTION,\n');
fprintf(fid, '    fraction=0.005,\n');
fprintf(fid, '    elasticSlipStiffness=None)\n');

fprintf(fid, 'mdb.models[model_name].interactionProperties["ContactProp"].NormalBehavior(\n');
fprintf(fid, '    pressureOverclosure=HARD,\n');
fprintf(fid, '    contactStiffness=1e6,\n');
fprintf(fid, '    allowSeparation=ON,\n');
fprintf(fid, '    constraintEnforcementMethod=DEFAULT)\n');

% 关闭文件
fprintf(fid, 'mdb.saveAs(pathName="Battery_Model.cae")\n');
fclose(fid);

% 提示完成
fprintf('Python 脚本已生成：%\n', python_script);

