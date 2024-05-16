%% example showing how to convert class instances from MatLab/MTex
% for ingestion into the nomad-parser-nexus developed in the FAIRmat
% project of the German National Research Data Infrastructure
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics


%% initalize, specify crystal and specimen symmetries
clear;
clc;
setMTEXpref('showCoordinates', 'on');
setMTEXpref('FontSize', 12.0);
setMTEXpref('figSize', 'normal');
% coordinate system, utilize SI units
% we redefine the MTex default coordinate system conventions from x2north
% and z out of plane to x east and zinto plane which is the Setting 2 case
% of TSL
% https://github.com/mtex-toolbox/mtex/issues/56
setMTEXpref('xAxisDirection','east');
setMTEXpref('zAxisDirection','intoPlane');
% right-handed Cartesian coordinate system
% getMTEXpref('EulerAngleConvention');
% getMTEXpref('xAxisDirection');
% getMTEXpref('zAxisDirection');

%% specify location of production datasets
location = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/' ...
    'Sprint16/EbsdOasis/'];
workdir = ['D:/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint10/' ...
    'extend_dataconverter_em_for_ebsd_and_nion/production'];

%% load configuration from dataset extraction Python script
cfg_tbl = readtable([location 'mtex_to_nxmtex_configuration.04.csv']);
n_size = size(cfg_tbl);
n_rows = n_size(1);
clearvars n_size;

phase_names_file = "phase_names.04.txt";
% lines = "proj_id_map_id;phase_names";
% writelines(lines, phase_names_file, WriteMode="overwrite");

% failures for specific row_indices
% maldeformed:
% 92
% unknown format:
% 229, 236, 237, 254, 269, 299, 342, 350, 415, 427, 487, 555, 603, 726,
% 1131, 1150
% crc does not match data:
% 589, 706, 768, 1033
% ctf parsing error:
% 1421
% uitable issues 1643, 1786, 1888, 1930
% (maldeformed or modified and renamed to ctf)?
% ang issues:
% 2018, 2027, 2028, 2036, 2039, 2042, 2048, 2056, 2066, 2072

for row_idx = 2073:1:n_rows
    clearvars proj_id map_id mime_type use_mtex cnvrsn fpath ebsd phase_names;
    proj_id = cfg_tbl{row_idx, 2};
    map_id = cfg_tbl{row_idx, 3};
    mime_type = cfg_tbl{row_idx, 4}{1};
    use_mtex = cfg_tbl{row_idx, 5}{1};
    cnvrsn = cfg_tbl{row_idx, 6}{1};
    % file name is of Python format f"{proj_id}_{map_id}.{mime_type}"
    fpath = strcat(workdir, '/');
    if proj_id < 100 fpath = strcat(fpath, '0'); end
    if proj_id < 10 fpath = strcat(fpath, '0'); end
    fpath = strcat(fpath, num2str(proj_id), '_');
    if map_id < 1000 fpath = strcat(fpath, '0'); end
    if map_id < 100 fpath = strcat(fpath, '0'); end
    if map_id < 10 fpath = strcat(fpath, '0'); end      
    fpath = strcat(fpath, num2str(map_id));
    fpath = strcat(fpath, '.');
    fpath = strcat(fpath, mime_type);
    disp(fpath);
    if strcmp(use_mtex, 'yes')
        if strcmp(cnvrsn, 's2e')
            % ##MK::TODO assuming just setting 2 is a very strong if not a wrong assumption
            ebsd = EBSD.load(fpath, 'convertSpatial2EulerReferenceFrame', 'setting 2');
        elseif strcmp(cnvrsn, 'e2s')
            ebsd = EBSD.load(fpath, 'convertEuler2SpatialReferenceFrame');
        else
            ebsd = EBSD.load(fpath);
        end
        % ##MK::TODO conversions needed for each mime_type in the same way?
        phase_names = '';
        for phase_idx = 1:1:length(ebsd.CSList)
            if strcmp(ebsd.CSList{phase_idx}, 'notIndexed')
                phase_names = strcat(phase_names, ['notIndexed' ';']);
            else
                phase_names = strcat(phase_names, [ebsd.CSList{phase_idx}.mineral ';']);
            end
        end
        disp(phase_names);
        writelines([fpath ';' phase_names], phase_names_file, WriteMode="append");
    end
end
