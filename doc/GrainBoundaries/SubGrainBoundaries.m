%% Subgrain Boundaries
%
%%
% Low-angle grain boundaries (LAGB) or subgrain boundaries are those with a
% misorientation less than about 15 degrees. Generally speaking they are
% composed of an array of dislocations and their properties and structure
% are a function of the misorientation. In contrast the properties of
% high-angle grain boundaries, whose misorientation is greater than about
% 15 degrees, are normally found to be independent of the misorientation.
% However, there are special boundaries at particular orientations whose
% interfacial energies are markedly lower than those of general high-angle
% grain boundaries.
%
% In order to demonstrate the analysis of subgrain boundaries in MTEX we
% start by importing an sample EBSD data set and preforming some polishing
% by removing all 5 pixel grains.

mtexdata ferrite silent

[grains,ebsd.grainId] = calcGrains(ebsd('indexed'));

% remove one pixel grains
ebsd(grains(grains.grainSize<5)) = [];

%%
% For the computation of the subgrain boundaries we specify two thresholds:
% the first value controls the subgrain boundaries whereas the second is used
% for the high-angle grain boundaries.

[grains,ebsd.grainId] = calcGrains(ebsd('indexed'),'threshold',[1*degree, 15*degree]);

% lets smooth the grain boundaries a bit
grains = smooth(grains,5)

%%
% We observe that we have 11330 high-angle boundary segments and 29476
% low-angle boundary segments. In order to visualize the the subgrain
% boundaries we first plot the ebsd data colorized by orientation. On top
% we plot with solid lines the grain boundaries and with thinner lines the
% subgrain boundaries. We even make the misorientation angle at the
% subgrain boundaries visible by setting it as the transparency value of
% the segments.

% plot the ebsd data
plot(ebsd('indexed'),ebsd('indexed').orientations,'faceAlpha',0.5,'figSize','large')

% init override mode
hold on

% plot grain boundares
plot(grains.boundary,'linewidth',2)

% compute transparency from misorientation angle
alpha = grains.subBoundary.misorientation.angle / (5*degree);

% plot the subgrain boundaries
plot(grains.subBoundary,'linewidth',1.5,'edgeAlpha',alpha);

% stop override mode
hold off

%% Subgrain Boundary Density
%
% The number of subgrain boundary segments inside each grain can be
% computed by the command <grain2d.subBoundarySize.html |subBoundarySize|>.
% In the following figure we use it to visualize the density of subgrain
% boundaries per grain pixel.

plot(grains, grains.subBoundarySize ./ grains.grainSize)

%% 
% We may compute also the density of subgrain boundaries per grain as the
% length of the subgrain boundaries divided by the grain area. This can be
% done using the commands <grain2d.subBoundaryLength.html
% |subBoundaryLength|> and <grain2d.area.html |area|>

plot(grains, grains.subBoundaryLength ./ grains.area)


%% Misorientation Axes
%
% Analyse the misorientation axes of the subgrain boundary misorientations

plot(grains.subBoundary.misorientation.axis,'fundamentalRegion','contourf')

mtexColorbar