# How to compile on Ubuntu

1. Assure to have installed ```build-essentials``` and ```gcc/g++ compiler``` (e.g. via ```sudo apt-get update```, ```sudo apt-get install```)
2. ld preload start matlab
https://de.mathworks.com/matlabcentral/answers/1907290-how-to-manually-select-the-libstdc-library-to-use-to-resolve-a-version-glibcxx_-not-found
https://datalowe.com/post/matlab-mex-files/
https://de.mathworks.com/matlabcentral/answers/643300-why-do-i-receive-the-error-libstdc-so-6-version-glibcxx_3-4-22-not-found-when-trying-to-star
3. Compile in the Matlab console ```mex jcvoronoi_mex.cpp```
4. Move that jcvoronoi_mex.mexa64 file into the mex directory replacing the existent one

Be careful: Depending on compiler this mexa64 file might be system specific !
