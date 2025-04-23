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


