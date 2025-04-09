function status = nexus_write_ebsd_microstructure(ebsd_orig, fpath, parent, perform_io)
% Generate extracted grains, grain- and phase boundary and triple point geometry

% ebsd_orig: array of one EBSD object per scan point
% fpath: path and filename of NeXus/HDF5 results file
% parent: parent HDF5 group below which to write
% ebsd_orig = ebsd_raw;  % TODO remove in production

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
% classical 15. high-angle to low-angle grain boundary
% use smaller values to segment sub-grain boundary network
% do not call like this [grains, ebsd_orig.grainId] as this
% is extremely slow
grains = calcGrains(ebsd_orig('indexed'), 'boundary', 'tight', 'angle', disorientation_threshold);
% for the Forsterite example grain 2842 is the largest
% for subtle orientation gradients, fast multi-scale clustering, https://doi.org/10.1016/j.ultramic.2013.04.009
% for the Forsterite example this is not useful due to interfaces strongly ragged
% grains_fmc = calcGrains(ebsd('indexed'), 'boundary', 'tight', 'FMC', 3.5);
% for subtle orientation gradients, Markov graph clustering
% https://micans.org/mcl/, http://dx.doi.org/10.1007/s11661-018-4904-9
% for the Forsterite example this tried to allocate a 294GB matrix, hence 
% grains_mcl = calcGrains(ebsd('indexed'), 'boundary', ...
%     'tight', 'mcl', [1.24 50], 'soft', [0.2 0.3]*degree);

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
grpnm = [parent '/microstructure1'];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = [parent '/microstructure1/configuration'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/algorithm'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'disorientation_clustering', attr);
dsnm = [grpnm '/disorientation_threshold'];
attr = io_attributes();
attr.add('units', '°');
ret = h5w.nexus_write(dsnm, disorientation_threshold / pi * 180., attr);

%% instantiate storage of representation of the primitives
grpnm = [parent '/microstructure1'];
dsnm = [grpnm '/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(2), attr);
% generic classes
grpnm = [parent '/microstructure1/cg_point'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_point');
ret = h5w.nexus_write_group(grpnm, attr);
grpnm = [parent '/microstructure1/cg_polyline'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_polyline');
ret = h5w.nexus_write_group(grpnm, attr);

%% summary statistics
% grains.boundary reports a summary table how many segments
% and how much boundary length between different phases

%% vertices
% TODO this implementation supports 32-bit wide identifier/indices
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
grpnm = [parent '/microstructure1/cg_point'];
dsnm = [grpnm '/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.allV, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/position'];
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, double(grains.allV)', attr);

%% the set of polylines representing individual interface facets
% problem the term facet is used for both a discretization of an interface
% patch as well as for describing a specific (low-energy or low Miller
% indices) face of a crystal
grpnm = [parent '/microstructure1/cg_polyline'];
dsnm = [grpnm '/cardinality'];
attr = io_attributes();
polylines = grains.boundary.F;
ret = h5w.nexus_write(dsnm, uint32(size(polylines, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [grpnm '/polylines'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/cg_point']);
polylines = grains.boundary.F';
ret = h5w.nexus_write(dsnm, uint32(reshape(polylines, ...
    [1, 2*length(polylines)])), attr);
p_u = grains.allV(polylines(1, :), :);
p_v = grains.allV(polylines(2, :), :);
facet_length = hypot((p_u.x - p_v.x), (p_u.y - p_v.y));
if any(isnan(facet_length))
    error('At least one entry in facet_length is NaN !');
end
dsnm = [grpnm '/length'];
attr = io_attributes();
attr.add('units', scan_unit);
ret = h5w.nexus_write(dsnm, facet_length, attr);

%% store grains
grpnm = [parent '/microstructure1/crystals'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/number_of_crystals'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(size(grains.id, 1)), attr);
dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);

%% store grain descriptors
dsnm = [grpnm '/area'];  % which type of area all pixels, polygon area?
area_per_ebsd_pixel = polyshape(ebsd_orig.unitCell.xy).area;  % clock-wise winding order
if length(ebsd_orig.unitCell) ~= 4
    error('TODO::Check correct size of that hexagonal Wigner-Seitz cell !');
end
attr = io_attributes();
attr.add('units', [scan_unit, '^2']);
ret = h5w.nexus_write(dsnm, double(grains.numPixel * area_per_ebsd_pixel), attr);
clearvars area_per_ebsd_pixel;
dsnm = [grpnm '/indices_phase'];
attr = io_attributes();
% ##MK::TODO implement case that phases might be not indexed
ret = h5w.nexus_write(dsnm, uint32(grains.phaseId), attr);
% evaluate if grain has boundary contact
% convenience, can be logically/topologically inferred from entry1/interfaces
dsnm = [grpnm '/boundary_contact'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint8(grains.isBoundary), attr);
% TODO write out as bitfield, currently happening via pynxtools-em
dsnm = [grpnm '/orientation_spread'];
attr = io_attributes();
attr.add( 'units', '°');
ret = h5w.nexus_write(dsnm, double(grains.GOS / pi * 180.), attr);

grpnm = [parent '/microstructure1/crystals/orientation'];
attr = io_attributes();
attr.add('NX_class', 'NXrotations');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [grpnm '/parameterization'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, 'quaternion', attr);
dsnm = [grpnm '/rotation'];
attr = io_attributes();
quat = double(zeros([4, length(grains.meanRotation.a)]));
quat(1,:) = double(grains.meanRotation.a');
quat(2,:) = double(grains.meanRotation.b');
quat(3,:) = double(grains.meanRotation.c');
quat(4,:) = double(grains.meanRotation.d');
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

grpnm = [parent '/microstructure1/interfaces'];
attr = io_attributes();
attr.add('NX_class', 'NXobject');
ret = h5w.nexus_write_group(grpnm, attr);

%% so far we only know the polyline segments but interfaces are composed
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
if max(mi) >= uint64(2^32) | max(mx) >= uint64(2^32)
    error('At least one crystal_id is incorrectly >= 2^32 !');
end
crystal_id_pair(1, :) = mi;
crystal_id_pair(2, :) = mx;
clearvars mi mx;
ret = h5w.nexus_write(dsnm, uint32(length(unique_interfaces)), attr);
clearvars unique_interfaces;

dsnm = [grpnm '/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
% 0 marks the virtual zero grain which specifies the boundary of the ROI !
dsnm = [grpnm '/indices_crystal'];
attr = io_attributes();
attr.add('use_these', [parent '/microstructure1/crystals']);
ret = h5w.nexus_write(dsnm, crystal_id_pair, attr);
% do not wonder why crystal_id_pair may include 0, it marks the
% discretization of the boundary of the ROI !

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
disp('NeXus/HDF5 exporting of microstructural features was successful');

status = logical(1);

end