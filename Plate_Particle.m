%% 写入预处理信息，将会创建一个板和许多球粒子。各部件都创建了set。
%% 请在Abaqus中手动Merge
model_name = 'Model-1';
python_script_name = 'script.py';
file_name = 'AbaqusModel.cae';
% 板材尺寸
plate_width = ;
plate_height = ;


% 孔的坐标和直径 (x, y, d)
particles = [];

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

% ==== 给每个particle单独创建surface ====
fprintf(fid, 'p = mdb.models[model_name].parts["Particle"]\n');
fprintf(fid, ' = p.edges\n');
for i = 1:size(particles,1)
    x = particles(i,1);
    y = particles(i,2);
    r = particles(i,3)/2;

    surfaceName = sprintf('Surf_%d', i);
    fprintf(fid, 'edge = .findAt(((%.6f, %.6f, 0.0),))\n', x+r, y);
    fprintf(fid, 'p.Surface(side1Edges=[edge], name="%s")\n', surfaceName);
    fprintf(fid, 'particle_sketch.CircleByCenterPerimeter(center=(%.9f, %.9f), point1=(%.9f, %.9f))\n', x, y, x+r, y);
end

% ==== 创建用于从面的他粒子节点集 ====
fprintf(fid, 'p = mdb.models[model_name].parts["Particle"]\n');
fprintf(fid, 'p.Set(name="PARTICLE", faces=p.faces[:])\n');
fprintf(fid, 'all_faces = p.sets["PARTICLE"].faces\n');
for i = 1:size(particles,1)

    ParticleSetName = sprintf('PARTICLE_EXCL_%d', i);
    fprintf(fid, 'faceList = []\n');

    for j = 1:size(particles,1)
        if j ~= i
            xj = particles(j,1);
            yj = particles(j,2);
            rj = particles(j,3)/2;

            fprintf(fid, 'face = p.faces.findAt(((%.6f, %.6f, 0.0),))\n', xj+rj, yj);
            fprintf(fid, 'faceList.append(face)\n');
            
        end
    end

    fprintf(fid, 'p.Set(faces=faceList, name="%s")\n\n', ParticleSetName);
end

% ==== 切割粒子便于mesh ====
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

% ==== STEP ====
fprintf(fid, 'mdb.models[model_name].ExplicitDynamicsStep(\n');
fprintf(fid, '    name="Step-1",\n');
fprintf(fid, '    previous="Initial",\n');
fprintf(fid, '    timePeriod=1e-05)\n');
fprintf(fid, 'mdb.models[model_name].fieldOutputRequests["F-Output-1"].setValues(variables=(\n');
fprintf(fid, '    "S", "PEEQ", "LE", "U", "V", "RF", "CSTRESS", "SDEG", "STATUS"),\n');
fprintf(fid, '    numIntervals=50)\n');

% ==== ASSEMBLY ====
fprintf(fid, 'a = mdb.models[model_name].rootAssembly\n');
fprintf(fid, 'a.DatumCsysByDefault(CARTESIAN)\n');
fprintf(fid, 'a.Instance(name="Plate-1", part=Plate, dependent=ON)\n');
fprintf(fid, 'a.Instance(name="Particle-1", part=Particle, dependent=ON)\n');

fprintf(fid, 'a.InstanceFromBooleanCut(name="Binder",\n');
fprintf(fid, '    instanceToBeCut=mdb.models[model_name].rootAssembly.instances["Plate-1"],\n');
fprintf(fid, '    cuttingInstances=(a.instances["Particle-1"], ), originalInstances=DELETE)\n');

%fprintf(fid, 'session.viewports["Viewport: 1"].assemblyDisplay.setValues(interactions=OFF,\n');
%fprintf(fid, '    constraints=OFF, connectors=OFF, engineeringFeatures=OFF)\n');
fprintf(fid, 'a.Instance(name="Particle-1", part=Particle, dependent=ON)\n');

% ==== INTERACTION ====
%fprintf(fid, 'session.viewports["Viewport: 1"].setValues(displayedObject=a)\n');
%fprintf(fid, 'session.viewports["Viewport: 1"].assemblyDisplay.setValues(interactions=ON,\n');
%fprintf(fid, '    constraints=ON, connectors=ON, engineeringFeatures=ON,\n');
%fprintf(fid, '    optimizationTasks=OFF, geometricRestrictions=OFF, stopConditions=OFF)\n');
fprintf(fid, 'mdb.models[model_name].ContactProperty("ContactProp")\n');
fprintf(fid, 'mdb.models[model_name].interactionProperties["ContactProp"].TangentialBehavior(\n');
fprintf(fid, '    formulation=PENALTY, directionality=ISOTROPIC, slipRateDependency=OFF,\n');
fprintf(fid, '    pressureDependency=OFF, temperatureDependency=OFF, dependencies=0, table=((\n');
fprintf(fid, '    0.2, ), ), shearStressLimit=None, maximumElasticSlip=FRACTION,\n');
fprintf(fid, '    fraction=0.005, elasticSlipStiffness=None)\n');
fprintf(fid, 'mdb.models[model_name].interactionProperties["ContactProp"].NormalBehavior(\n');
fprintf(fid, '    pressureOverclosure=HARD, allowSeparation=ON,\n');
fprintf(fid, '    constraintEnforcementMethod=DEFAULT)\n');

for i = 1:size(particles, 1)
    fprintf(fid, 'region1=a.instances["Particle-1"].surfaces["Surf_%d"]\n',i);
    fprintf(fid, 'region2=a.instances["Binder-1"].sets["BINDER"]\n');
    fprintf(fid, 'mdb.models[model_name].SurfaceToSurfaceContactExp(name="Int-%d",\n',i);
    fprintf(fid, '    createStepName="Initial", master=region1, slave=region2,\n');
    fprintf(fid, '    mechanicalConstraint=KINEMATIC, sliding=FINITE,\n');
    fprintf(fid, '    interactionProperty="ContactProp", initialClearance=OMIT, datumAxis=None,\n');
    fprintf(fid, '    clearanceRegion=None)\n'); 
end

for i = 1:size(particles, 1)
    fprintf(fid, 'region1=a.instances["Particle-1"].surfaces["Surf_%d"]\n',i);
    fprintf(fid, 'region2=a.instances["Particle-1"].sets["PARTICLE_EXCL_%d"]\n',i);
    fprintf(fid, 'mdb.models[model_name].SurfaceToSurfaceContactExp(name="Int-%d_P",\n',i);
    fprintf(fid, '    createStepName="Step-1", master=region1, slave=region2,\n');
    fprintf(fid, '    mechanicalConstraint=KINEMATIC, sliding=FINITE,\n');
    fprintf(fid, '    interactionProperty="ContactProp", initialClearance=OMIT, datumAxis=None,\n');
    fprintf(fid, '    clearanceRegion=None)\n'); 
end

% 关闭文件
fprintf(fid, 'mdb.saveAs(pathName="%s")\n', file_name);
fclose(fid);

% 提示完成
fprintf('Python 脚本已生成：%\n', python_script_name);
