function status = nexus_write_ebsd_microstructure(ebsd_orig, fpath, parent, perform_io)
% Generate extracted grains, grain- and phase boundary and triple point geometry

% ebsd_orig = ebsd_raw;  % array of one EBSD object per scan point
% fpath = ofpath; path and filename of NeXus/HDF5 results file
% parent = '/entry1/roi1/ebsd/indexing'; % parent HDF5 group below which to write

%% generate discretization of crystal interface network
% the idea with this function here is to show how irrespective how the
% grains were reconstructed, we can then export the geometry description
% using NeXus classes

if ~perform_io
    return;
end
h5w = HdfFiveSeqHdl(fpath);

scan_unit = 'n/a';
if strcmp(ebsd_orig.scanUnit, 'um')
    scan_unit = 'µm';
else
    scan_unit = lower(ebsd_orig.scanUnit);
end

disorientation_threshold = 15.0*degree;
discretization_threshold = 1;
% classical 15. high-angle to low-angle grain boundary
% use smaller values to segment sub-grain boundary network
% do not call like this [grains, ebsd_orig.grainId] as this
% is extremely slow

disp(['Grain reconstruction ...']);
% [grains,ebsd_orig.grainId,ebsd_orig.mis2mean] 
% [grains, ebsd_orig.grainId] 
grains = calcGrains( ...
    ebsd_orig('indexed'), ...
    'boundary', 'tight', ...
    'angle', disorientation_threshold, ...
    'minPixel', discretization_threshold);
disp(['Grain reconstruction: OK']);
% plot(grains)
% use [val , idx] = max(grains.area('2d')); to find the largest grain
% alternative grain reconstruction methods exist e.g.
% for subtle orientation gradients, fast multi-scale clustering, 
% https://doi.org/10.1016/j.ultramic.2013.04.009
% for the Forsterite example this is not useful due to interfaces strongly ragged
% grains_fmc = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'FMC', 3.5);
% for subtle orientation gradients, Markov graph clustering
% https://micans.org/mcl/, http://dx.doi.org/10.1007/s11661-018-4904-9
% for the Forsterite example this tried to allocate a 294GB matrix 
% grains_mcl = calcGrains(ebsd('indexed'), 'boundary', ...
%     'tight', 'mcl', [1.24 50], 'soft', [0.2 0.3]*degree);
% so for the run-through we use the default voronoi tessellation based
% approach https://doi.org/10.1016/j.ultramic.2011.08.002

%% store discretization of crystal interface network
% MTex generates vertices and interfaces discretized into linear segments
% each segment is stored as a grainBoundary class object, therefore
% we need to reconstruct which segments are part of individual interface
% segments between grains i, j
% some of the vertices represent triplePoints, these store their adjacent
% grains and interface segments
% with reconstruction parameter 'boundary' set the edge of the ROI adds
% segments which by definition belong to the virtual grain 0 i.e. the edge
% each interface is conceptually a half-edge as it connects two crystals
% the ROI is tessellated by polygons of two types crystals and notIndexed
% crystals are bounded by interfaces, interfaces meet at triple junctions
% the edge of the ROI cuts crystals which have contact at the edge of the
% dataset

% eventually wrap this into an ROI
grpnm = [parent '/microstructure1'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = [parent '/microstructure1/configuration'];
attr = io_attributes();
attr.add('NX_class', 'NXparameters');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/algorithm'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'disorientation_clustering', attr);
dsnm = [grpnm '/comments'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'indexed, boundary, tight', attr);
dsnm = [grpnm '/disorientation_threshold'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, disorientation_threshold / degree, attr);
dsnm = [grpnm '/discretization_threshold'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, discretization_threshold, attr);

% TODO this implementation currently supports 32-bit wide identifier
% for integer valued quantities, the support can be extended by
% changing the reporting type from (u)int32 to (u)int64
% typically though a width of 32 bits allows to store 2^32 identifier
% if counting from zero which especially for 2D are extremely large
% EBSD maps that one would not even exhaust if each hexagon-shaped pixel
% of a 500 million !!! scan point EBSD map is naively stored with each
% of its six vertices repeated
% using 32 bit instead of blindly 64 bit makes each processing
% take half the cache and feeding half the payload to the compression
% that is happening within the nexus_write calls
% another benefit of 32-bit ids is that adjacencies of two grains
% at interfaces can be encoded as an uint64 that is beneficial for
% dictionary lookup as used in several occasions in the code below
if size(grains.boundary.F, 1) >= 2^32 - 1 || length(grains) >= 2^32 - 1
    error(['The interface network of grains has more individuals ' ...
           'than the here used 32bit ID handling can deal with!']);
end

%% summary statistics
% grains.boundary reports a summary table how many segments
% and how much boundary length between different phases
% in what follows we store the raw data from which these
% summary statistics can be computed

%% instantiate storage of representation of the primitives
grpnm = [parent '/microstructure1'];
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);

%% vertices
grpnm = [parent '/microstructure1/cg_point'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_point');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
dsnm = [grpnm '/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.allV.xy, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/position'];
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, double(grains.allV.xy), attr);

%% polylines, representing individual interface facets
% problem the term facet is used for both a discretization of an interface
% patch as well as for describing a specific (low-energy or low Miller
% indices) face of a crystal
grpnm = [parent '/microstructure1/cg_polyline'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_polyline');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
dsnm = [grpnm '/cardinality'];
attr = io_attributes();
polylines = grains.boundary.F;
ret = h5w.nexus_write(dsnm, uint32(size(polylines, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/number_of_vertices'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2*ones([1, size(polylines, 1)]))', attr);
clearvars polylines;
dsnm = [grpnm '/polylines'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_point']);
dsnm = [grpnm '/length'];
polylines = grains.boundary.F';
ret = h5w.nexus_write(dsnm, uint32(reshape(polylines, ...
    [1, 2*length(polylines)])), attr);
p_u = grains.allV(polylines(1, :), :);
p_v = grains.allV(polylines(2, :), :);
facet_length = hypot((p_u.x - p_v.x), (p_u.y - p_v.y));
if any(isnan(facet_length))
    error('At least one entry in facet_length is NaN !');
end
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, facet_length, attr);
clearvars polylines p_u p_v facet_length;

%% store crystals/grains
grpnm = [parent '/microstructure1/crystals'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/number_of_crystals'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/area_by_pixel'];  % which type of area all pixels, polygon area?
area_per_ebsd_pixel = polyshape(ebsd_orig.unitCell.xy).area;  % clock-wise winding order?
attr = io_attributes();
attr.add('units', [scan_unit, '^2']);
ret = h5w.nexus_write(dsnm, double(grains.numPixel * area_per_ebsd_pixel), attr);
clearvars area_per_ebsd_pixel;
dsnm = [grpnm '/area_by_mtex'];
attr = io_attributes();
attr.add('units', [scan_unit, '^2']);
ret = h5w.nexus_write(dsnm, double(grains.area('2d')), attr);
dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(grains.phaseId), attr); 
% 0 is boundary
% convenience, can be logically/topologically inferred from entry1/interfaces
dsnm = [grpnm '/boundary_contact'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint8(grains.isBoundary), attr);
% TODO write out as bitfield, currently happening via pynxtools-em
dsnm = [grpnm '/orientation_spread'];
attr = io_attributes();
attr.add( 'units', '°');
ret = h5w.nexus_write(dsnm, double(grains.GOS / degree), attr);
grpnm = [parent '/microstructure1/crystals/orientation'];
attr = io_attributes();
attr.add('NX_class', 'NXrotations');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/parameterization'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'quaternion', attr);
dsnm = [grpnm '/rotation_quaternion'];
attr = io_attributes();
quat = nan([4, length(grains)]);
quat(1,:) = grains.meanRotation.a';
quat(2,:) = grains.meanRotation.b';
quat(3,:) = grains.meanRotation.c';
quat(4,:) = grains.meanRotation.d';
ret = h5w.nexus_write(dsnm, double(quat), attr);
% per grains.meanOrientation cannot be called directly for EBSD data with
% multiple phases (see Forsterite example...)
% Your variable contains the phases: Forsterite, Enstatite
% However, you are executing a command that is only permitted for a single phase!
% contains the phases: Forsterite, Enstatite -phasefor nothing but Euler angles
% as a solution meanOrientation is collected in the loop that collects
% per boundary misorientation
clearvars quat;

% https://mtex-toolbox.github.io/GrainOrientationParameters.html
% gam = ebsd_orig.grainMean(ebsd_orig.KAM, grains);

%% interface facets which discretize the segments of the polygons
% which describe the crystallite and ROI boundar(ies) as polylines
% are not mandatory they can be interferred from topological analysis
% ideally for this the grains should be stored as a half-edge data
% structure instead of face, vertex lists

%% store crystal boundaries which can be homo (aka grain) or hetero (phase) boundaries/interfaces
% (not their facets as a boundary can be discretized with differing number of support points)
% interfaces are pairs of half-edges because an interface separates two crystals
% each interface is discretized using at least one so-called facet, i.e.
% typically much more facets (polyline segments or triangles exist than
% conceptual interfaces
% [val, idx] = max(grains.area('2d'));

%% polyline segment to interface patches
grpnm = [parent '/microstructure1/interfaces'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
% eventually of multiple such segments because the vertices from MTex
% represent on the one hand vertices at triple points and virtual
% vertices discretizing the facets of the Voronoi cells from which
% the individual regions are composed,
% group interface facets to grains via hashing min/max crystal id pair
dsnm = [grpnm '/number_of_interfaces'];
attr = io_attributes();
pairs = grains.boundary.grainId';
segment_to_interface_lu = uint64(min(pairs)) + uint64(2^32) * uint64(max(pairs));
clearvars pairs;
unique_interfaces = unique(segment_to_interface_lu);
hash_to_interface_idx = containers.Map( ...
    num2cell(unique_interfaces'), ...
    uint32(1:1:length(unique_interfaces)));
% includes interfaces of crystals to the edge of the ROI / boundary
crystal_id_pair = uint32(zeros([2, length(unique_interfaces)]));
mx = unique_interfaces ./ uint64(2^32);
mi = unique_interfaces - (uint64(2^32) .* uint64(mx));
crystal_id_pair(1, :) = mi;
crystal_id_pair(2, :) = mx;
clearvars mi mx;
ret = h5w.nexus_write(dsnm, uint32(length(unique_interfaces)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% 0 marks the virtual zero grain which specifies the boundary of the ROI !
dsnm = [grpnm '/indices_crystal'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/crystals']);
ret = h5w.nexus_write(dsnm, uint32(crystal_id_pair), attr);
% do not wonder why crystal_id_pair may include 0, it marks the
% discretization of the boundary of the ROI !
clearvars unique_interfaces;

disp(['Identify misorientation for interface patches...']);
% compute misorientation for interface patches (not individual segments)
% as all segments of the patch for 2d have the same misorientation
% boundary plane of course is a per segment quantity but this is stored
% already as we have vertex positions and first, last so also directions
% two-staged computation of per-interface misorientation
% a convenient call like bnd = grains.boundary.misorientation does not
% work because different phases and ROI boundaries need to be dealt with
% stage 1 get pairings
mean_ori_quaternion = nan([4, length(grains)]);
misori = containers.Map();
for i = 1:1:length(grains)
    bnd = grains(i).boundary;
    mean_ori_quaternion(1, i) = grains(i).meanOrientation.a;
    mean_ori_quaternion(2, i) = grains(i).meanOrientation.b;
    mean_ori_quaternion(3, i) = grains(i).meanOrientation.c;
    mean_ori_quaternion(4, i) = grains(i).meanOrientation.d;    
    [pairs, idx] = unique(bnd.grainId, 'rows');
    for j = 1:1:size(pairs, 1)
        if all(pairs(j, :) > 0)  % no misorientation for boundary segments in contact with the edge
            lu_key = num2str(uint64(min(pairs(j, :))) + uint64(2^32) * uint64(max(pairs(j, :))));
            if ~isKey(misori, lu_key)
                misori(lu_key) = bnd(idx(j)).misorientation;
            end
        end
    end
    clearvars bnd pairs idx j lu_key;
end
grpnm = [parent '/microstructure1/crystals/orientation'];
dsnm = [grpnm '/orientation_quaternion'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, double(mean_ori_quaternion), attr);
clearvars mean_ori_quaternion;
% stage 2
misori_euler = nan([3, size(crystal_id_pair, 2)]);
misori_angle = nan([1, size(crystal_id_pair, 2)]);
% decode misorientation and sort out back correctly
% crystal_id_pair, 1 and 2 store mi and mx respectively, in order of interface_id
for i=1:1:length(crystal_id_pair)
    if all(crystal_id_pair(:, i) > 0)
        lu_key = num2str(uint64(crystal_id_pair(1, i)) + uint64(2^32) * uint64(crystal_id_pair(2, i)));
        if isKey(misori, lu_key)
            val = misori(lu_key);
            misori_euler(1, i) = val.phi1 / degree;
            misori_euler(2, i) = val.Phi / degree;
            misori_euler(3, i) = val.phi2 / degree;
            misori_angle(1, i) = val.angle / degree;
        else
            error('Stage 2 decode misorientation lu_key is not a key!');
        end
        clearvars lu_key val;
    end
    % uniq = uint64(str2num(k{1}));
    % mx = uniq ./ uint64(2^32);
    % mi = uniq - (uint64(2^32) .* uint64(mx));
end
grpnm = [parent '/microstructure1/interfaces/misorientation'];
attr = io_attributes();
attr.add('NX_class', 'NXrotations');
ret = h5w.nexus_write_group(grpnm, attr);
% dsnm = [grpnm '/parameterization'];
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, 'euler', attr);
dsnm = [grpnm '/misorientation_euler'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, double(misori_euler), attr);
dsnm = [grpnm '/misorientation_angle'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, double(misori_angle), attr);
clearvars misori_euler misori_angle;
disp(['Identify misorientation for interface patches: OK']);


dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
% check that for each facet with the same interface_hash
% the phase_id pair is exactly the same!
phase_id_pair = int64(zeros(size(crystal_id_pair))) - 1;% mark unknown with -1
mi = uint32(min(grains.boundary.phaseId'));
mx = uint32(max(grains.boundary.phaseId'));
for idx = 1:1:size(grains.boundary.phaseId, 1)
    % never zero unless 0 + (2^32 * 0) not possible by virtue of construction?
    interface_id = segment_to_interface_lu(idx);
    interface_idx = hash_to_interface_idx(interface_id);
    % mi = min(uint32(grains.boundary.phaseId(idx, :)));
    % mx = max(uint32(grains.boundary.phaseId(idx, :)));
    % in the case of mi == mx we have a homophase interface
    % in the case of any([mi, mx]) == 0 we have boundary contact
    % but the flag isBoundary is a cleaner way to query these cases
    % in all other cases we have heterophase interface
    if phase_id_pair(1, interface_idx) == -1 ...
            & phase_id_pair(2, interface_idx) == -1
        phase_id_pair(1, interface_idx) = mi(idx);
        phase_id_pair(2, interface_idx) = mx(idx);
    else
        % test consistency and throw if there are double assignments
        if phase_id_pair(1, interface_idx) == mi(idx) ...
                & phase_id_pair(2, interface_idx) == mx(idx)
        else
            error(['Resetting values in a phase_id_pair ' ...
                num2str(idx) ' is not allowed !']);
        end
    end
end
if min(min(phase_id_pair)) >= 0 & max(max(phase_id_pair)) < int64(2^32)
    phase_id_pair = uint32(phase_id_pair);
else
    error('At least one phase_id_pair value remained incorrectly -1 !');
end
% so the information e.g. phase_id_pair  (0, 2) means this interface
% is an interface between some crystallite_projections of phase 0 and phase 2
% phase 0 is notIndexed and used for representing the interface
ret = h5w.nexus_write(dsnm, phase_id_pair, attr);

% TODO::export indices_polylines segments
dsnm = [grpnm '/indices_polylines'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1:1:size(polylines, 2))', attr);

clearvars idx interface_id interface_idx mi mx phase_id_pair crystal_id_pair;

%% triple junctions
grpnm = [parent '/microstructure1/triple_junctions'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/number_of_junctions'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.triplePoints.id, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

dsnm = [grpnm '/indices_crystal'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/crystals']);
ret = h5w.nexus_write(dsnm, uint32(grains.triplePoints.grainId)', attr);

dsnm = [grpnm '/indices_polyline'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_polyline']);
ret = h5w.nexus_write(dsnm, uint32(grains.triplePoints.boundaryId)', attr);

dsnm = [grpnm '/indices_interface'];
% the adjoining interface, (also see above comment) not necessary
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/interfaces']);
interface_ids = int64(zeros([3, size(grains.triplePoints.boundaryId, 1)]) - 1);
bnd_idxs = grains.triplePoints.boundaryId';
a_bnd_hsh = segment_to_interface_lu(bnd_idxs(1, :));
b_bnd_hsh = segment_to_interface_lu(bnd_idxs(2, :));
c_bnd_hsh = segment_to_interface_lu(bnd_idxs(3, :));
clearvars bnd_idxs;
for idx = 1:1:size(grains.triplePoints.boundaryId, 1)
    a_bnd = hash_to_interface_idx(a_bnd_hsh(idx));
    b_bnd = hash_to_interface_idx(b_bnd_hsh(idx));
    c_bnd = hash_to_interface_idx(c_bnd_hsh(idx));
    if all(interface_ids(1:3, idx) == -1)
        interface_ids(1, idx) = a_bnd;
        interface_ids(2, idx) = b_bnd;
        interface_ids(3, idx) = c_bnd;
    else
        if interface_ids(1, idx) == a_bnd ...
                & interface_ids(2, idx) == b_bnd ...
                & interface_ids(3, idx) == c_bnd
        else
            disp([num2str(idx) ' problem !']);
        end
    end
end
% check that no index remains -1
if min(min(interface_ids)) >= 0 & max(max(interface_ids)) < int64(2^32)
    interface_ids = uint32(interface_ids);
else
    error(['At least on interface_id is incorrectly >= 2^32 !']);
end
clearvars idx a_bnd b_bnd c_bnd a_bnd_hsh b_bnd_hsh c_bnd_hsh;
ret = h5w.nexus_write(dsnm, interface_ids, attr);
clearvars interface_ids;

clearvars hash_to_interface_id segment_to_interface_lu ret;

disp('NeXus/HDF5 exporting of microstructure: OK');
status = logical(1);

end