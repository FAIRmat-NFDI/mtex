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
mtexdir = ['C:/Users/kuehbacm/Research/Maintain/mtex-dev/mtex'];
targetdir = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint16/EbsdOasis'];
workdir = ['D:/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint10/extend_dataconverter_em_for_ebsd_and_nion/production'];
addpath(mtexdir);
addpath(targetdir);
addpath(workdir);
% diary 'diary.log'
mtex_pref = configure_mtex_preferences();
disp(getMTEXpref('xAxisDirection'));
disp(getMTEXpref('zAxisDirection'));
% diary off

%% load configuration from dataset extraction Python script
run_id = '06';  % '05' second lot, '04' first lot
cfg_tbl = readtable([targetdir '/mtex_to_nxmtex_configuration.' run_id '.csv']);
n_size = size(cfg_tbl);
n_rows = n_size(1);
clearvars n_size;

%% begin batch loop
map_ids_malformed_osc = [92]; % new osc files 2096, 2097 are not supported by MTex
% Warning: more column data was passed in than expected. Check your column names make sense!
map_ids_malformed_cpr = [229, 236];
map_ids_malformed_ang = [2018, 2027, 2028, 2032, 2036, 2039, ...
                         2042, 2048, 2056, 2066, 2068, 2072];
map_ids_not_matching_crc = [237, 254, 269, 299, 415, 487, ...
                            589, 706, 768, 1033, 1150];
map_ids_unknown_format = [342, 350, 427, 555, 603, 726, 1131];
map_ids_other_issues = [736, 1394];
% is not restricted to only one phase, maybe malformed phase list because Your variable contains the phases: Ti O, Ti O
map_ids_undesired_uicall = [1643, 1786, 1888, 1930];
% this implementation of uitable is no longer supported and will be removed in a future release

skip_these_map_ids = cat(2, ...
    map_ids_malformed_osc, ...
    map_ids_malformed_cpr, ...
    map_ids_malformed_ang, ...
    map_ids_not_matching_crc, ...
    map_ids_unknown_format, ...
    map_ids_other_issues, ...
    map_ids_undesired_uicall);

% 1919 are there axes included in the plot which shouldnt?
% 1942 shows that all scan points are notIndexed? index issues??
perf_file_name = [targetdir '/performance.' run_id '.log'];
% writelines('Input;WallClockTime(s);length(ebsd_raw)', ...
%     perf_file_name, WriteMode="overwrite");

% additional errors:
% proj_id 31 revealed an older version of proj_id 35
for row_idx = 2203:1:2211  % 22096:1:2096  % 1:1:n_rows
    clearvars proj_id map_id mime_type use_mtex cnvrsn;
    proj_id = cfg_tbl{row_idx, 2};
    map_id = cfg_tbl{row_idx, 3};
    mime_type = cfg_tbl{row_idx, 4}{1};
    use_mtex = cfg_tbl{row_idx, 5}{1};
    cnvrsn = cfg_tbl{row_idx, 6}{1};
    % file name is of Python format f"{proj_id}_{map_id}.{mime_type}"
    if strcmp(use_mtex, 'yes')
        clearvars input output;
        input = nexus_compose_file_path(workdir, proj_id, map_id, mime_type);
        if 1 == 0
            input = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment' ...
                '/Sprint10/extend_dataconverter_em_for_ebsd_and_nion/teaching' ...
                '/186_ger_freiberg_hielscher/Forsterite.ctf'];
        end
        cnvrsn = 's2e';
        output = [input '.nxs.mtex'];
        if ~ismember(map_id, skip_these_map_ids)
            clearvars status ebsd_raw ebsd_roi_hweb ebsd_ipf_hweb;
            disp(['Processing ' input]);

            tic;
            status = nexus_write_init(output);
            status = nexus_write_mtex_preferences( ...
                output, '/entry1/roi1/ebsd/indexing1');
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

            status = nexus_write_ebsd_phase(ebsd_raw, output, ...
                '/entry1/roi1/ebsd/indexing1');

            ebsd_roi_hweb = squarify_map(ebsd_raw, 'h5web_max_size', 2^14 - 1);
            status = nexus_write_ebsd_overview(ebsd_roi_hweb, output, ...
                '/entry1/roi1/ebsd/indexing1');
            clearvars ebsd_roi_hweb;

            ebsd_ipf_hweb = squarify_map(ebsd_raw, 'h5web_max_size', 2^11 - 1);
            status = nexus_write_ebsd_phase_ipf(ebsd_raw, ...
                ebsd_ipf_hweb, output, '/entry1/roi1/ebsd/indexing1');
            clearvars ebsd_ipf_hweb;

            % skip for now computations which will increase the file size
            % substantially, i.e. ODF, PF, and microstructure
            if 1 == 0
                status = nexus_write_ebsd_microstructure( ...
                    ebsd_raw, output, '/entry1/roi1/ebsd/indexing1');
                status = nexus_write_ebsd_odf( ...
                    ebsd_raw, output, '/entry1/roi1/ebsd/indexing1');
                status = nexus_write_ebsd_pf( ...
                    ebsd_raw, output, '/entry1/roi1/ebsd/indexing1');
            end

            dt = toc;
            disp(['Analysis took ' num2str(dt) ' s']);
            writelines([input ';' num2str(dt) ';' ...
                num2str(uint64(length(ebsd_raw)))], ....
                perf_file_name, WriteMode="append");
        else
            % disp(['Skipping ' input]);
        end
    end
end










%% begin debug
% input = 'C:\Users\kuehbacm\Research\HU_HU_HU\FAIRmatSoftwareDevelopment\Sprint10\extend_dataconverter_em_for_ebsd_and_nion\teaching\186_ger_freiberg_hielscher\Forsterite.ctf';
% ebsd_raw = EBSD.load(input, 'convertEuler2SpatialReferenceFrame');
% need to find a better place for this group
% h5w = HdfFiveSeqHdl(output);
% grpnm = '/entry1/performance';
% attr = io_attributes();
% attr.add('NX_class', 'NXcs_profiling');
% h5w.nexus_write_group(grpnm, attr);
% dsnm = strcat(grpnm, '/total_elapsed_time');
% attr = io_attributes();
% attr.add('units', 's');
% h5w.nexus_write(dsnm, double(toc), attr);
%% end debug