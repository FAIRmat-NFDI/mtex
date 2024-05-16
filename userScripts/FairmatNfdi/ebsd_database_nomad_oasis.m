%% header
% Markus Kühbach, Humboldt-Universität zu Berlin, Department of Physics
% NOMAD, FAIRmat 2023/07/28

%% context
% an example to show how a collection of EBSD mappings can be processed
% to extract common descriptors from EBSD mappings using MTex to generate
% a database for SEM/EBSD as a demonstrator inside a NOMAD Oasis

%% method section
% 1. Supervised harvesting all project data from OpenAIRE matching keywords EBSD and datasets
% 2. Supervised collecting of EBSD data from colleagues, broad, globally,
% diff. formats, diff. research communities
% 3. Supervised step assisted with Python scripting to remove nested archives
% 4. Script unzipping all EBSD maps
% 5. Manually curated list switching some EBSD maps out
% 6. Assigning new proj_id_map_id for easier handling
% 7. Supervised loading of all maps (osc, cpr, ang) MTex to get phase name
% glossary, identification of potential problems
% 8. Supervised normalization of phase name glossary, lacking cif, mineral,
% element, and mineral group, rock names, typos and procedural details make
% mapping nontrivial
% 9. Script EBSD processing (overview (bc), ipf, odf, pf, 
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
addpath 'C:\Users\kuehbacm\Research\HU_HU_HU\FAIRmatSoftwareDevelopment\Sprint16\EbsdOasis'
clear; clc;
mtex_pref = configure_mtex_preferences();

targetdir = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/' ...
    'Sprint16/EbsdOasis/'];
workdir = ['D:/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/Sprint10/' ...
    'extend_dataconverter_em_for_ebsd_and_nion/production'];


%% begin batch loop
% ##MK::TODO replace by batch processing code, run in batch, loader here parms for ctf!

workdir = ['C:/Users/kuehbacm/Research/HU_HU_HU/FAIRmatSoftwareDevelopment/' ...
    'Sprint10/extend_dataconverter_em_for_ebsd_and_nion/teaching/186_ger_freiberg_hielscher'];
dset_file_name = [workdir '/Forsterite.ctf'];

nexus_file_name = [targetdir 'test.h5'];
status = nexus_write_init(...
    nexus_file_name);  % switch to '.nxs.mtex'
status = nexus_write_mtex_preferences( ...
    nexus_file_name, '/entry1');
ebsd_raw = EBSD.load(dset_file_name, ...
    'convertSpatial2EulerReferenceFrame');
    % is a classical EBSD object (2D scan points set)
ebsd_hweb = regrid_for_hfive_web(ebsd_raw);
    % is an EBSDsquare object
status = nexus_write_ebsd_overview(ebsd_raw, ebsd_hweb, ...
    nexus_file_name, '/entry1');
status = nexus_write_ebsd_phase(ebsd_hweb, ...
    nexus_file_name, '/entry1');
status = nexus_write_ebsd_ipf(ebsd_raw, ebsd_hweb, ...
    nexus_file_name, '/entry1');
status = nexus_write_ebsd_odf(ebsd_raw, ebsd_hweb, ...
    nexus_file_name, '/entry1');
status = nexus_write_ebsd_pf(ebsd_raw, ebsd_hweb, ...
    nexus_file_name, '/entry1');
status = nexus_write_ebsd_microstructure(ebsd_raw, ...
    nexus_file_name, '/entry1');

%% end of batch loop
