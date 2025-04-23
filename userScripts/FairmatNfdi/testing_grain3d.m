clc;
clear;

fname = fullfile(mtexDataPath,'EBSD','SmallIN100_MeshStats.dream3d');
grains = grain3d.load(fname);

nexus_fpath = [pwd 'data.ebsd.SmallIN100_MeshStats.dream3d.nxs'];
h5w = HdfFiveSeqHdl(nexus_fpath);

parent = 'microstructure';
grpnm = [parent];
attr = io_attributes();
attr.add('NX_class', 'NXmicrostructure');
ret = h5w.nexus_write_group(grpnm, attr);

grpnm = [parent '/cg_point'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_point');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [parent  '/cg_point/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(3), attr);
dsnm = [parent  '/cg_point/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains.allV)), attr);
dsnm = [parent  '/cg_point/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [parent  '/cg_point/position'];
attr = io_attributes();
attr.add( "units", "1");
ret = h5w.nexus_write(dsnm, double(grains.allV), attr);

% find unique triangles
% TODO does F = grains.boundary.F yield triangles in winding order?
uniq_facets_adjacent_grains = containers.Map;
for i = 146:1:length(grains)
    g = grains(i);
    grain_id = g.id;
    bnd = g.boundary;
    nbs = uint32(g.numNeighbors);
    nf = uint32(full(g.numFaces));
    triangles_uvw = bnd.F;
    triangles_area = bnd.area;
    triangles_phase = bnd.phaseId; % phaseId == 0 is ROI boundary
    no_boundary_contact = all(triangles_phase, 2);
    roi_contact_area = sum(triangles_area) - sum(triangles_area(no_boundary_contact));
    total_area = sum(triangles_area);
    roi_contact_cnt = length(triangles_area) - length(triangles_area(no_boundary_contact));
    total_cnt = length(triangles_area);
    % disp('Get MTex summary statistics as a proof of understanding');
    % bnd
    % disp(['notIndexed (ROI)/unknown ' num2str(roi_contact_area / total_area)]);
    % disp(['unknown/unknown ' num2str((total_area - roi_contact_area) / total_area)]);
    % disp(['notIndexed (ROI)/unknown cnt ' num2str(roi_contact_cnt)]);
    % disp(['unknown/unknown cnt ' num2str(total_cnt - roi_contact_cnt)]);
    for j = 1:1:length(triangles_uvw)
        triplet = sort([triangles_uvw(j, :)]);
        key = [num2str(triplet(1)) '_' num2str(triplet(2)) '_' num2str(triplet(3))];
        if ~isKey(uniq_facets_adjacent_grains, key)
            uniq_facets_adjacent_grains(key) = [grain_id];
        else
            uniq_facets_adjacent_grains(key) = [uniq_facets_adjacent_grains(key), grain_id];
        end
    end
    clearvars g grain_id bnd nbs nf triangles_uvw triangles_area triangles_phase no_boundary_contact roi_contact_area total_area roi_contact_cnt total_cnt j triplet key;
end
boundary_facets = 0;
nf = uint32(full(grains.numFaces));  % is sparse, use full(nf) to convert to full
nbs = uint32(grains.numNeighbors);
% A = grains.boundary.area;
k = keys(unique_triangles);
v = values(unique_triangles);
uniq_facet_ids_of_grains = containers.Map;
for uniq_facet_id = 1:1:length(v)
    % disp(uniq_facet_id);
    tmp = v{uniq_facet_id};
    if length(tmp) == 2
        continue
    else
        boundary_facets = boundary_facets + 1;
        disp(['Not exactly two grains meet ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    end
    % for j = 1:1:length(tmp)
    %     key = num2str(tmp(j));  % grain id is key
    %     if ~isKey(uniq_facet_ids_of_grains, key)
    %         uniq_facet_ids_of_grains(key) = [uniq_facet_id];
    %     else
    %         uniq_facet_ids_of_grains(key) = [uniq_facet_ids_of_grains(key), uniq_facet_id];
    %     end
    % end
    % if length(tmp) == 3
    %     disp(['Triple junction ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    % elseif length(tmp) > 3
    %     disp(['HO junction ' num2str(uniq_facet_id) ', ' num2str(length(tmp))]);
    % end
end
disp(boundary_facets);
grains.boundary
k = keys(uniq_facet_ids_of_grains);
v = values(uniq_facet_ids_of_grains);

        

grpnm = [parent '/cg_triangle'];
attr = io_attributes();
attr.add('NX_class', 'NXcg_triangle');
ret = h5w.nexus_write_group(grpnm, attr);
dsnm = [parent  '/cg_point/dimensionality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(3), attr);
dsnm = [parent  '/cg_point/cardinality'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(length(grains.F)), attr);
dsnm = [parent  '/cg_point/index_offset'];
attr = io_attributes();
ret = h5w.nexus_write(dsnm, uint32(1), attr);
dsnm = [parent  '/cg_point/position'];
attr = io_attributes();
attr.add( "units", "1");
ret = h5w.nexus_write(dsnm, double(grains.allV), attr);







% get largest grain
[max, gmax_idx] = max(grains.volume);
g = grains(gmax_idx);
% largest boundary face of it
[max, bmax_idx] = max(g.boundary.area);
bnds = g.boundary;
b = bnds(bmax_idx);
V = grains.allV;




f_v_mx = 0;
for i = 1:1:length(grains)
    disp(i);
    g = grains(i);
    if max(max(g.F)) >= f_v_mx
        f_v_mx = max(max(g.F));
    end
end


%% distinguish hex and square

fnm_hex = fullfile(mtexDataPath,'EBSD',['testdata_hex.ctf']);
fnm_sqr = fullfile(mtexDataPath,'EBSD',['testdata_sqr.ctf']);
ebsd_hex = loadEBSD_ctf(fnm_hex);
ebsd_sqr = loadEBSD_ctf(fnm_sqr);
a_hex = ebsd_hex(1);
a_sqr = ebsd_sqr(1);
u_hex = a_hex.unitCell;
u_sqr = a_sqr.unitCell;


