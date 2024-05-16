%% header
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics
% NOMAD, FAIRmat 2023/07/28

%% context
% an example to show how a collection of EBSD mappings can be processed
% to extract common descriptors from EBSD mappings using MTex to generate
% a database for SEM/EBSD as a demonstrator inside a NOMAD Oasis

%% method section
% y1. Supervised harvesting all project data from OpenAIRE matching keywords EBSD and datasets
% y2. Supervised collecting of EBSD data from colleagues, broad, globally,
% diff. formats, diff. research communities
% y3. Supervised step assisted with Python scripting to remove nested archives
% y4. Script unzipping all EBSD maps
% y5. Manually curated list switching some EBSD maps out
% y6. Assigning new proj_id_map_id for easier handling
% y7. Supervised loading of all maps (osc, cpr, ang) MTex to get phase name
% glossary, identification of potential problems
% y8. Supervised normalization of phase name glossary, lacking cif, mineral,
% element, and mineral group, rock names, typos and procedural details make
% mapping nontrivial
% ~9. Script EBSD processing (overview (bc), ipf, odf, pf, 
% dictionary-based mapping of phase_names to atom_types,
% microstructure,mtex/matlab settings)
% 10. Inject generated .nxs.mtex files into pynxtools add supplementary
% info
% 11. Handling of h5, hdf5, h5oina files (orix), dream3d 3D datasets, and
% 1d line profile datasets
% 12. Kikuchi pattern example
% 13. EMsoft simulation Wiik
% 11. Automated upload to NOMAD OASIS dev instance

%% init
clear; clc;
mtex_pref = configure_mtex_preferences();
disp(getMTEXpref('xAxisDirection'));
disp(getMTEXpref('zAxisDirection'));

mtexdir = ['C:/Users/kuehbacm/Research/Maintain/mtex-dev/mtex'];
targetdir = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint16/EbsdOasis'];
workdir = ['D:/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint10/extend_dataconverter_em_for_ebsd_and_nion/production'];
addpath(mtexdir);
addpath(targetdir);
addpath(workdir);

%% load configuration from dataset extraction Python script
cfg_tbl = readtable([targetdir '/mtex_to_nxmtex_configuration.04.csv']);
n_size = size(cfg_tbl);
n_rows = n_size(1);
clearvars n_size;

%% begin batch loop
skip_these_map_ids = [92, 229, 236, 237, 254, 269, 299, 342, 350, 415, ...
    427, 487, 555, 603, 726, 1131, 1150, 589, 706, 768, 1033, 1421, ...
    1643, 1786, 1888, 1930];
broken_ang_files = [2018, 2027, 2028, 2036, 2039, 2042, ...
    2048, 2056, 2066, 2072];  % these files are practically empty only 1kiB?

for row_idx = 1:1:n_rows
    clearvars proj_id map_id mime_type use_mtex cnvrsn;
    proj_id = cfg_tbl{row_idx, 2};
    map_id = cfg_tbl{row_idx, 3};
    mime_type = cfg_tbl{row_idx, 4}{1};
    use_mtex = cfg_tbl{row_idx, 5}{1};
    cnvrsn = cfg_tbl{row_idx, 6}{1};
    input = nexus_compose_file_path(workdir, proj_id, map_id, mime_type);
    output = [input '.nxs.mtex'];
    % if ismember(map_id, breaking_map_ids)
    %     delete output;
    %     file_ifo = dir(input);
    %     disp(file_ifo.bytes);
    % end
end
% ##MK::TODO add stats, aabb, grid, unit cell, etc..., 
% reduce verbosity of HDF5 writer
breaking_map_ids = [94, 123, 158, 187, 202, 223, 251, 264, ...
    283, 288, 290, 293, 297, 298, 318, 319, 325, 370, 373, ...
    377, 389, 392, 410, 425, 442, 460, 472, 476, 488, 494, ...
    500, 510, 520, 547, 568, 583, 587, 590, 602, 606, 609, ...
    616, 618, 629, 647, 664, 692, 710, 733, 736, 741, 746, ...
    749, 785, 794, 804, 837, 843, 860, 862, 908, 911, 912, ...
    921, 923, 933, 937, 938, 939, 948, 986, 993, 994, ...
    1014, 1039, 1059, 1087, 1088, 1090, 1101, 1103, 1112, ...
    1117, 1121, 1138, 1154, 1159, 1167, 1172, 1173, 1179, ...
    1194, 1199, 1201, 1210, 1213, 1216, 1230, 1265, 1268, ...
    1269, 1271, 1274, 1300, 1321, 1331, 1335, 1344, 1345, ...
    1347, 1350, 1352, 1356, 1367, 1385, 1390, 1394, 1407, ...
    1415, 1418, 1420, 1422, 1429, 1431, 1432, 1439, 1445, ...
    1448, 1457, 1458, 1475, 1476, 1502, 1525, 1538, 1549, ...
    1551, 1552, 1554, 1565, 1568, 1579, 1582, 1595, 1606, ...
    1613, 1627, 1637, 1645, 1647, 1648, 1652, 1659, 1676, ...
    1677, 1681, 1692, 1693, 1697, 1703, 1712, 1716, 1735, ...
    1738, 1748, 1749, 1751, 1753, 1754, 1765, 1775, 1776, ...
    1807, 1838, 1853, 1874, 1876, 1882, 1883, 1891, 1896, ...
    1903, 1906, 1908, 1909, 1917, 1919, 1921, 1929, 1932, ...
    1942, 1959, 1968, 1974, 1977, 1979, 1985, 2002, 2008, ...
    2032, 2068];
% most issues are related to problems in the squarify function line 49
% some because of index out of range e.g. map_id 736
% but this has now been fixed with the new squarify_map implementation
% https://de.mathworks.com/help/matlab/ref/try.html
% notes about specific map_id
% 1407 phases? 1524, 1743, 1932, both with 15phases and rocks, man...??
% 2035, 2044, project 53, which fancy color maps are these??

% summary of warning on particular maps
% osc: 
%   Warning: more column data was passed in than expected. Check your column names make sense!
% summary of failures on particular maps due to specific problems
% ang malformed: 2018, 2027, 2028, 2032, 2036, 2039, 2042, 2048, 2056,
% 2066, 2068, 2072
% osc malformed: 92
% cpr malformed: 229, 236
% crc not matching cpr: 237, 254, 269, 299, 415, 487, 589, 706, 768, 1033,
% 1150
% unable to detect file format: 342, 350, 427, 555, 603, 726, 1131
% 736 has another problem
% 1394 is not restricted to only one phase, maybe malformed phase list because Your variable contains the phases: Ti O, Ti O
% MTex demands GUI interaction to customize the meaning of certain columns
% 1643, 1786, 1888, 1930
% This implementation of uitable is no longer supported and will be removed in a future release

% 1919 are there axes included in the plot which shouldnt?
% 1942 shows that all scan points are notIndexed? index issues??
for row_idx = 1:1:n_rows
    clearvars proj_id map_id mime_type use_mtex cnvrsn;
    proj_id = cfg_tbl{row_idx, 2};
    map_id = cfg_tbl{row_idx, 3};
    mime_type = cfg_tbl{row_idx, 4}{1};
    use_mtex = cfg_tbl{row_idx, 5}{1};
    cnvrsn = cfg_tbl{row_idx, 6}{1};
    % file name is of Python format f"{proj_id}_{map_id}.{mime_type}"
    if map_id == 986
        continue
    end

    if strcmp(use_mtex, 'yes')
        clearvars input output;
        input = nexus_compose_file_path(workdir, proj_id, map_id, mime_type);
        output = [input '.nxs.mtex'];
        if ismember(map_id, skip_these_map_ids) || ismember(map_id, broken_ang_files) || ismember(map_id, breaking_map_ids)
        % if 1 == 1  % ~ismember(map_id, skip_these_map_ids) & ~ismember(map_id, broken_ang_files)
            clearvars status ebsd_raw ebsd_roi_hweb ebsd_ipf_hweb;
            disp(['Processing ' input]);

            tic;
            status = nexus_write_init(output);
            status = nexus_write_mtex_preferences(output, '/entry1');
            if strcmp(cnvrsn, 's2e')
                % ##MK::TODO assuming just setting 2 is a very strong
                % if not a wrong assumption
                ebsd_raw = EBSD.load(input, ...
                    'convertSpatial2EulerReferenceFrame', 'setting 2');
            elseif strcmp(cnvrsn, 'e2s')
                ebsd_raw = EBSD.load(input, ...
                    'convertEuler2SpatialReferenceFrame');
            else
                ebsd_raw = EBSD.load(input);
            end
            % ebsd_raw is a classical EBSD object (2D scan points set)
            % plot(ebsd_raw);

            status = nexus_write_ebsd_phase(ebsd_raw, output, '/entry1');

            ebsd_roi_hweb = squarify_map(ebsd_raw, 'h5web_max_size', 2^14 - 1);
            status = nexus_write_ebsd_overview(ebsd_roi_hweb, output, '/entry1');
            clearvars ebsd_roi_hweb;

            ebsd_ipf_hweb = squarify_map(ebsd_raw, 'h5web_max_size', 2^11 - 1);
            status = nexus_write_ebsd_ipf(ebsd_ipf_hweb, output, '/entry1');

            % ebsd_hweb = regrid_for_hfive_web(ebsd_raw);
            % is an EBSDsquare, i.e. square-pixel gridded EBSD map      
        
            h5w = HdfFiveSeqHdl(output);
            grpnm = '/entry1/performance';
            attr = io_attributes();
            attr.add('NX_class', 'NXcs_profiling');
            h5w.nexus_write_group(grpnm, attr);
            dsnm = strcat(grpnm, '/total_elapsed_time');
            attr = io_attributes();
            attr.add('units', 's');
            h5w.nexus_write(dsnm, double(toc), attr); % dt = toc;
            
            % skip for now computations which will increase the file size
            % substantially, i.e. ODF, PF, and microstructure
            % status = nexus_write_ebsd_odf(ebsd_raw, ebsd_hweb, ...
            %     output, '/entry1');
            % status = nexus_write_ebsd_pf(ebsd_raw, ebsd_hweb, ...
            %     output, '/entry1');
            % status = nexus_write_ebsd_microstructure(ebsd_raw, ...
            %     output, '/entry1');
        else
            % disp(['Skipping ' input]);
        end
    end
end

%% begin debug
% input = 'C:\Users\kuehbacm\Research\HU_HU_HU\FAIRmatSoftwareDevelopment\Sprint10\extend_dataconverter_em_for_ebsd_and_nion\teaching\186_ger_freiberg_hielscher\Forsterite.ctf';
% ebsd_raw = EBSD.load(input, 'convertEuler2SpatialReferenceFrame');
%% end debug