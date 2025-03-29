a = ipfColorKey();
a.CS1 = crystalSymmetry('mmm');
a.CS2 = specimenSymmetry('3');
plot(a)
tmp = getframe(gcf);
b = tmp.cdata();
close all force;
