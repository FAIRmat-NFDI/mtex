%% Neper
%
%% General
% Neper is an open source software package for polycrystal generation and
% meshing developed by Romain Query. It can be obtained from
% https://neper.info, where also the documentation is located.
%
%% General workflow
% A general workflow using neper conatins usually three parts:
% * setting up the neper instance
% * tesselation
% * slicing
% 
%% Setting-up the neper instance
% If you do not want to make any further adjustments to the default values,
% this step could be done very easily:

myneper=neperInstance;

%% 
% File options:
% By default your neper will work under the temporary folder of your matlab
% (matlab command |tempdir|). If you want to do your tesselations elsewhere or
% your tesselations are already located under another path, you can change
% it:

myneper.filePath='C:\Users\user\Documents\work\MtexWork\neper';
%or
myneper.filePath=pwd;

%%
% By default a new folder, named neper will be created for the tesselation 
% data. If you do not want to create a new folder you can switch it of by 
% setting |newfolder| to False.

myneper.newfolder=False;

%%
% If |newfolder| is true (default) the slicing module also works in the
% subfolder neper, if it exists.
%
% By deafult the 3d tesselation data will be named "allgrains" with the
% endings .tess and .ori and the 2d slices will be named "2dslice" with the
% ending .tess and .ori . You can change the file names in variables
% |fileName3d| and |fileName2d|.

myneper.fileName3d='my100grains';
myneper.fileName2d='my100GrSlice';

%%
% Tesselation options
% The grains will be generated in cubic domain. By default the domain has
% the edge length 1 in each direction. To change the size of the domain, 
% store a row vector with 3 entries (x,y,z) in the variable |cubeSize|.

myneper.cubeSize=[4 4 2];

%%
% Neper uses an id to identify the tesselation. This interger value "is
% used as seed of the random number generator to compute the (initial) 
% seed positions" (neper.info/doc/neper_t.html#cmdoption-id) By default the
% tesselation id is always |1|.

myneper.id=529;

%%
% Neper allows to specify the morphological properties of the cells. See
% https://neper.info/doc/neper_t.html#cmdoption-morpho for more
% information. By default graingrowth is used, that is an alias for:

myneper.morpho='diameq:lognormal(1,0.35),1-sphericity:lognormal(0.145,0.03),aspratio(3,1.5,1)';

%% Tesselation
%

%% Diskussion von parametern 
% * output files
% * which slice, how to pameterize slice
% * morphological parameters
% * mehrere schöne Ebenen (3)