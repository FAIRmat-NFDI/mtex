function status = nexus_write_ebsd_microstructure(ebsd_orig, fpath, parent)
% Generate extracted grains, grain- and phase boundary and triple point geometry

% ebsd_orig
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write

%% generate discretization of crystal interface network
% see https://mtex-toolbox.github.io/EBSD.calcGrains.html for details
% especially more advanced strategies how to account for non-indexed
% points could be used ##MK::TODO

% the idea with this function here is to show how irrespective how the
% grains were reconstructed, we can then export the geometry description
% using NeXus classes

h5w = HdfFiveSeqHdl(fpath);

scan_unit = 'n/a';
if isprop(ebsd_orig, 'scanUnit')
    if strcmp(ebsd_orig.scanUnit, 'um')
        scan_unit = 'µm'; 
    else
        scan_unit = lower(ebsd_orig.scanUnit);
    end
end

disorientation_threshold = 15.0*degree;
% classical argument 15. for high-angle grain boundary network
% use smaller values to segment sub-grain boundary network
grains_old = calcGrains(ebsd_orig('indexed'), ...
    'boundary', 'tight', 'angle', disorientation_threshold);
grains_old.scanUnit = scan_unit;
% for subtle orientation gradients, fast multi-scale clustering, https://doi.org/10.1016/j.ultramic.2013.04.009
% for the ger_freiberg_hielscher (forsterite example) this is not very useful as the interfaces are strongly ragged
% grains_fmc = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'FMC', 3.5);
% also for subtle orientation gradients, Markov graph clustering
% https://micans.org/mcl/
% http://dx.doi.org/10.1007/s11661-018-4904-9
% for the ger_freiberg_hielscher (forsterite example) this is useless as it
% tries to allocate a 294GB matrix :D !!
% grains_mcl = calcGrains(ebsd('indexed'), 'boundary', ...
%     'tight', 'mcl', [1.24 50], 'soft', [0.2 0.3]*degree);

% % hold on
% % plot(grains_fmc.boundary, 'linewidth', 1.5, 'linecolor', 'blue')
% % % hold
% % % plot(grains_mcl.boundary, 'linewidth', 1.5, 'linecolor', 'orange')
% % hold off
% % % for a mixture of homo and hetero-phase boundaries no misorientation is
% % % computed
% % gB = grains_old.boundary('Forsterite', 'Forsterite');
% % Sigma3 = gB(angle(gB.misorientation, CSL(3, ebsd('Forsterite').CS)) < 30.0*degree);
% % hold on
% % plot(ebsd('Forsterite'),log(ebsd('Forsterite').prop.bc), 'figSize', 'large')
% % mtexColorMap black2white
% % hold on
% % plot(gB, 'linewidth', 1.5, 'linecolor', 'black', 'DisplayName', 'Forsterite/Forsterite homo-phase boundaries')
% % hold on
% % plot(Sigma3, 'lineColor', 'gold', 'linewidth', 1.5, 'DisplayName','CSL3 within 30deg')
% % hold off
% % % the large/complex Enstatite OPX Av77 crystal with island grains inside
% % test_grain_x = 5336;
% % test_grain_y = 8251;
% % hold on
% % plot(grains_old(test_grain_x, test_grain_y).boundary,'linewidth',4,'linecolor','blue')
% % hold off
% % outer_bnd_id = any(grains_old.boundary.grainId == 0, 2);
% % inner_bnd_id = ~outer_bnd_id;

%% preview for development purposes
% hold on
% plot(grains_old.boundary, 'linewidth', 1.5, 'linecolor', 'black')

% check that each support vertex of a triplePoint is just a copy of a
% vertex to the boundary network support vertices
bnd_vrts = KDTreeSearcher(grains_old.V);
nn = knnsearch(bnd_vrts, grains_old.triplePoints.V);
disp(['Check triple points are copies of support vertices: ' ...
    num2str(max(abs(nn - grains_old.triplePoints.id))) ', 0 means OK']);
% we observe nn is grains_old.triplePoints.id
clearvars bnd_vrts nn;

%% store discretization of crystal interface network
% some of these vertices represent triplePoints
% some of them support the discretization of the ROI boundary
% most of the vertices discretize polygons about each crystal
% each interface is conceptually a half-edge as it connects two crystals
% the ROI is tessellated by polygons of two types crystals and notIndexed
% crystals are bounded by interfaces, interfaces meet at triple junctions
% the edge of the ROI cuts crystals which have contact at the edge of the
% dataset

% eventually wrap this into an ROI
grpnm = strcat(parent, '/microstructure1');
attr = io_attributes();
attr.add('NX_class', 'NXms_recon');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = strcat(parent, '/microstructure1/configuration');
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/algorithm');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'disorientation_clustering', attr);
dsnm = strcat(grpnm, '/disorientation_threshold');
attr = io_attributes();
attr.add('unit', '°');
ret = h5w.nexus_write(dsnm, disorientation_threshold / pi * 180., attr);


%% instantiate ms_feature_set
grpnm = strcat(parent, '/microstructure1/ms_feature_set1');
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/dimensionality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
% generic classes
grpnm = strcat(parent, '/microstructure1/ms_feature_set1/points');
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
grpnm = strcat(parent, '/microstructure1/ms_feature_set1/lines');
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);

%% vertices
grpnm = strcat(parent, '/microstructure1/ms_feature_set1/points/geometry');
attr = io_attributes();
attr.add('NX_class', 'NXcg_point_set');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.V, 1)), attr);
dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% dsnm = strcat(grpnm, '/identifier');
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, uint32(1:1:size(grains_old.V, 1)), attr);
dsnm = strcat(grpnm, '/position');
attr = io_attributes();
attr.add('unit', grains_old.scanUnit);
ret = h5w.nexus_write(dsnm, double(grains_old.V)', attr);

%% the set of polylines representing individual interface facets
% problem the term facet is used for both a discretization of an interface
% patch as well as for describing a specific (low-energy or low Miller
% indices) face of a crystal
grpnm = strcat(parent, '/microstructure1/ms_feature_set1/lines/geometry');
attr = io_attributes();
attr.add('NX_class', 'NXcg_polyline_set');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.boundary.F, 1)), attr);
dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% dsnm = strcat(grpnm, '/identifier');
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, uint32(1:1:size(grains_old.boundary.F, 1)), attr);
dsnm = strcat(grpnm, '/polylines');
attr = io_attributes();
attr.add('depends_on', strcat(parent, '/microstructure1/ms_feature_set1/points/geometry'));
ret = h5w.nexus_write(dsnm, uint32(reshape( ...
    grains_old.boundary.F', [1, 2*length(grains_old.boundary.F')])), attr);

% facet_length = double(nan([1, length(grains_old.boundary.F')]));
polylines = grains_old.boundary.F';
p_u = grains_old.V(polylines(1, :), :);
p_v = grains_old.V(polylines(2, :), :);
facet_length = sqrt((p_u(:, 1) - p_v(:, 1)).^2 ...
    + (p_u(:, 2) - p_v(:, 2)).^2);
if any(isnan(facet_length))
    disp('ERROR: None of these should be NaN!');
end
dsnm = strcat(grpnm, '/length');
attr = io_attributes();
attr.add('unit', grains_old.scanUnit);
ret = h5w.nexus_write(dsnm, facet_length, attr);

%% store grains
grpnm = strcat(parent, ['/microstructure1/ms_feature_set1' ...
    '/crystallite_projections']);
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.id, 1)), attr);
dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% dsnm = strcat(grpnm, '/identifier');
% going for implicit naming, or should we use explicit naming?
% attr = io_attributes();
% ret = h5w.nexus_write(dsnm, uint32(grains_old.id), attr);

%% store grain descriptors
dsnm = strcat(grpnm, '/pixel_area');  % which type of area all pixels, polygon area?
area_per_ebsd_pixel = polyshape(ebsd_orig.unitCell).area;  % clock-wise winding order
% area_per_ebsd_pixel = (max(max(ebsd_orig.unitCell)) - min(min(ebsd_orig.unitCell)))^2;
if length(ebsd_orig.unitCell) ~= 4
    disp('TODO::Check correct size of that hexagonal Wigner-Seitz cell !');
end
attr = io_attributes();
attr.add('unit', strcat(grains_old.scanUnit, '^2'));
ret = h5w.nexus_write(dsnm, double(grains_old.grainSize * area_per_ebsd_pixel), attr);
clearvars area_per_ebsd_pixel;
dsnm = strcat(grpnm, '/phase_identifier');
attr = io_attributes();
% ##MK::TODO implement case that phases might be not indexed
ret = h5w.nexus_write(dsnm, uint32(grains_old.phaseId), attr);
% evaluate if grain has boundary contact
% convenience, can be logically/topologically inferred from entry1/interfaces 
dsnm = strcat(grpnm, '/boundary_contact');
attr = io_attributes();
% boundary_contact = logical(zeros(size(grains_old.id)));
grain_ids = grains_old.boundary.grainId';
boundary_contact(max(grain_ids)) = any(grain_ids == 0, 1);
clearvars grain_ids;
ret = h5w.nexus_write(dsnm, uint8(boundary_contact), attr);
clearvars boundary_contact;
dsnm = strcat(grpnm, '/grain_orientation_spread');
attr = io_attributes();
attr.add( 'unit', '°');
ret = h5w.nexus_write(dsnm, double(grains_old.prop.GOS / pi * 180.), attr);

grpnm = strcat(parent, ['/microstructure1/ms_feature_set1' ...
    '/crystallite_projections/mean_rotation']);
attr = io_attributes();
attr.add('NX_class', 'NXrotation_set');
% ##MK::TODO why not an orientation set ??
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/parameterization');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'quaternion', attr);
dsnm = strcat(grpnm, '/rotation');
attr = io_attributes();
quat = double(zeros([4, length(grains_old.prop.meanRotation.a)]));
quat(1,:) = double(grains_old.prop.meanRotation.a');
quat(2,:) = double(grains_old.prop.meanRotation.b');
quat(3,:) = double(grains_old.prop.meanRotation.c');
quat(4,:) = double(grains_old.prop.meanRotation.d');
ret = h5w.nexus_write(dsnm, quat, attr);
clearvars quat;

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

grpnm = strcat(parent, ['/microstructure1/ms_feature_set1' ...
    '/interface_projections']);
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
ret = h5w.nexus_write_group(grpnm, attr);
%% so far we only know the polyline segments but interfaces are composed
% eventually of multiple such segments because the vertices from MTex
% represent on the one hand vertices at triple points and virtual
% vertices discretizing the facets of the Voronoi cells from which
% the individual regions are composed,
% group interface facets to grains via hashing min/max crystal id pair
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
mi = min(grains_old.boundary.grainId');
mx = max(grains_old.boundary.grainId');
segment_to_interface_lu = uint64(mi) + uint64(2^32) * uint64(mx);
clearvars mi mx;
unique_interfaces = unique(segment_to_interface_lu);
keys = num2cell(unique_interfaces');
values = uint32(1:1:length(unique_interfaces));
hash_to_interface_idx = containers.Map(keys, values);
clearvars keys values;
% includes interfaces of crystals to the edge of the ROI / boundary
crystal_id_pair = uint32(zeros([2, length(unique_interfaces)]));
mx = unique_interfaces ./ uint64(2^32);
mi = unique_interfaces - (uint64(2^32) .* uint64(mx));
if max(mi) >= uint64(2^32) | max(mx) >= uint64(2^32)
    disp('ERROR: crystal_id must not be >= 2^32 !');
    % stop
end
crystal_id_pair(1, :) = mi;
crystal_id_pair(2, :) = mx;
clearvars mi mx;
ret = h5w.nexus_write(dsnm, uint32(length(unique_interfaces)), attr);
clearvars unique_interfaces;

dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% 0 marks the virtual zero grain which specifies the boundary of the ROI
dsnm = strcat(grpnm, '/crystallites');
attr = io_attributes();
attr.add('depends_on', strcat(parent, ['/microstructure1' ...
    '/ms_feature_set1/crystallite_projections']));
ret = h5w.nexus_write(dsnm, crystal_id_pair, attr);
dsnm = strcat(grpnm, '/phase_identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(0), attr);

dsnm = strcat(grpnm, '/phase_identifier');
attr = io_attributes();
% check that for each facet with the same interface_hash
% the phase_id pair is exactly the same!
phase_id_pair = int64(zeros(size(crystal_id_pair))) - 1; % mark unknown with -1 
mi = uint32(min(grains_old.boundary.phaseId'));
mx = uint32(max(grains_old.boundary.phaseId'));
for idx = 1:1:size(grains_old.boundary.phaseId, 1)
    % never zero unless 0 + (2^32 * 0) not possible by virtue of construction?
    interface_id = segment_to_interface_lu(idx);
    interface_idx = hash_to_interface_idx(interface_id);
    % mi = min(uint32(grains_old.boundary.phaseId(idx, :)));
    % mx = max(uint32(grains_old.boundary.phaseId(idx, :)));
    % in the case of mi == mx we have a homophase interface
    % in the case of any([mi, mx]) zero we have boundary contact
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
            disp([num2str(idx) ' problem !']);
        end
    end
end
% check that no index remains -1
if min(min(phase_id_pair)) >= 0 & max(max(phase_id_pair)) < int64(2^32)
    phase_id_pair = uint32(phase_id_pair);
end
% so the information e.g. phase_id_pair  (0, 2) means this interface
% is an interface between some crystallite_projections of phase 0 and phase 2
ret = h5w.nexus_write(dsnm, phase_id_pair, attr);
clearvars idx interface_id interface_idx mi mx phase_id_pair crystal_id_pair;


%% triple junctions
grpnm = strcat(parent, ['/microstructure1' ...
    '/ms_feature_set1/triple_line_projections']);
attr = io_attributes();
attr.add('NX_class', 'NXms_feature_set');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = strcat(grpnm, '/cardinality');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains_old.triplePoints.id, 1)), attr);
dsnm = strcat(grpnm, '/identifier_offset');
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = strcat(grpnm, '/location');  % THE SPECIAL SITUATION FOR indexing with offset +1 is that
attr = io_attributes();
attr.add('depends_on', strcat(parent, ['/microstructure1' ...
    '/ms_feature_set1/points/geometry']));
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.id), attr);

dsnm = strcat(grpnm, '/crystallite_projections');
attr = io_attributes();
attr.add('depends_on', strcat(parent, ['/microstructure1' ...
    '/ms_feature_set1/crystallite_projections']));
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.grainId)', attr);

%% ##MK::TODO
dsnm = strcat(grpnm, '/polylines');
attr = io_attributes();
attr.add('depends_on', strcat(parent, ['/microstructure1' ...
    '/ms_feature_set1/lines/geometry/polylines']));
ret = h5w.nexus_write(dsnm, uint32(grains_old.triplePoints.boundaryId)', attr);

dsnm = strcat(grpnm, '/interfaces');
% the adjoining interface, (also see above comment) not necessary
attr = io_attributes();
attr.add('depends_on', ['/entry1/roi1/ebsd/microstructure1' ...
    '/ms_feature_set1/interface_projections']);
interface_ids = int64(zeros([3, size(grains_old.triplePoints.boundaryId, 1)]) - 1);
bnd_idxs = grains_old.triplePoints.boundaryId';
a_bnd_hsh = segment_to_interface_lu(bnd_idxs(1, :));
b_bnd_hsh = segment_to_interface_lu(bnd_idxs(2, :));
c_bnd_hsh = segment_to_interface_lu(bnd_idxs(3, :));
clearvars bnd_idxs;
for idx = 1:1:size(grains_old.triplePoints.boundaryId, 1)
    % a_idx = grains_old.triplePoints.boundaryId(idx, 1);
    % b_idx = grains_old.triplePoints.boundaryId(idx, 2);
    % c_idx = grains_old.triplePoints.boundaryId(idx, 3);
    % a_bnd_hsh = segment_to_interface_lu(a_idx);
    % b_bnd_hsh = segment_to_interface_lu(b_idx);
    % c_bnd_hsh = segment_to_interface_lu(c_idx);
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
end
clearvars idx a_bnd b_bnd c_bnd a_bnd_hsh b_bnd_hsh c_bnd_hsh;
ret = h5w.nexus_write(dsnm, interface_ids, attr);
clearvars interface_ids;

clearvars hash_to_interface_id segment_to_interface_lu ret;
disp('NeXus/HDF5 exporting of microstructural features was successful');

status = logical(1);

% HOW TO DECIDE WHICH ONE KICKS IN AND HOW TO RESOLVE AMBIGUITIES?
% e.g. if one just gives identifier_offset and assumes as a NeXus default
% that ids run from offset:1:: then what if there is another field called
% identifier, see below which refers to completely different ids though?
% at least two possibilities exist how to interpret "identifier"
% TRICKY, benefit of explicit stating which vertices are triple junctions
% is that minimal information is stored and one is explicit, more
% cumbersome one could add a boolean array behind discretization/vertices
% and name which are triple junctions then from the order one would have to
% compute back their ids but explicit names are always clearer than rely on
% implicit assumptions also for the sake of being self-descriptive
% above-mentioned means we introduce explicitly the ids of each triple
% junction
% alternatively one could here list the indices of the discretized vertices
% i.e. those vertices of the interface network which are triple points
% all other vertices are supporting vertices between triple junctions for
% discretizing the polyline contour approximation of the interface segment
% in the grain growth literature these are known as e.g. virtual vertices
% their spacing is dictated by the discretization of the underlying EBSD
% map

% the key question here is from which level to describe the hierarchy
% top-down or bottom-up
% from bottom-up triple lines connect interfaces which delineate crystals
% from top-down crystals are delineated by interface (s segments) two of which meet at triple
% junctions
% both description describe equally the topological and logical grouping
% identifier and indices can have the same value but represent two different
% concepts: an identifier is a name of an instance (a specific vertex)
% while an index is a variable to know from where to dereference pieces of
% information in a sequence (tuple, list, array)

% THIS SCREAMS for getting an own i.e. vertex_identifier/@depends_on but not on interfaces but on
% discretization, but then there is no more relation between the triple
% junctions and the interfaces, hooking to interfaces is also ambiguous
% because the here written indices must not be resolved from
% identifier/index arrays inside interfaces but from discretization
% CLEARLY one could avoid such ambiguity by making copies at the costs of
% store and duplication of information

% strictly speaking this is redundant information as it can be inferred via
% analyzing the topology of which facets are connected to the triple point
% and to which interfaces are these facets belonging and then which unique
% triplet of crystals meets at the interface
% THE TRICKY PART FOR NUMERICAL ALGORITHMS IS THAT IN SOME CASES MORE THAN
% three crystals can meet at the triple line / here point as an algorithm
% may not be topologically robust enough to distinguish geometrical corner
% cases
% four crystal junctions are considered as thermodynamically unstable but
% of course in reality interfaces are just imaginary segmentation surfaces
% which delineate the crystal i.e. interfaces are models and therefore may have
% numerical inaccuracies

end