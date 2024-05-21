function mtex_pref = configure_mtex_preferences()
% set a clear and defined state for MTex and used reference frames
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

mtex_pref = getMTEXpref;
end