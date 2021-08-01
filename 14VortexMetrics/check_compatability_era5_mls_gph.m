clear all

%compare ERA5 GPH and MLS GPH, to provide metrics on how much we can trust
%using ERA5 in some figures and MLS in others
%
%this is desirable if the data support it as the ERA5 are seamless down to
%the surface while the MNLS stop at the bottom of the stratosphere


%load and merge ERA5 GPH
Data      = rCDF('era5_gph/nd2020.nc');
B         = rCDF('era5_gph/jfm2021.nc');
Data.z    = cat(4,Data.z,B.z);
Data.time = cat(1,Data.time,B.time);
clear B
ERA5 = Data; clear Data

%fix ERA5 latitude to ascend monotonically
ERA5.z        = ERA5.z(:,end:-1:1,:,:);
ERA5.latitude = ERA5.latitude(end:-1:1);

%load MLS GPH
MLS = load('mls_gph.mat');

%reduce data to 10hPa and 7hPa levels, to reflect ERA5 files
p = h2p(MLS.Settings.Grid.HeightScale);
idx1 = closest(p,10); idx2 = closest(p,70);
MLS.Results.Data = MLS.Results.Data(:,:,[idx1,idx2],:,:);
clear p idx1 idx2

%interpolate the ERA5 onto the MLS (as it's higher-res)
Z.MLS = squeeze(MLS.Results.Data);

[xi,yi,zi,ai] = ndgrid(MLS.Settings.Grid.TimeScale,   ...
                       [10,70],                       ...
                       MLS.Settings.Grid.Lat,         ...
                       MLS.Settings.Grid.Lon);
                     
ERA5.z = permute(ERA5.z,[3,4,2,1]);
[x,y,z,a] = ndgrid(ERA5.level,ERA5.time,ERA5.latitude,ERA5.longitude);
I = griddedInterpolant(x,y,z,a,ERA5.z);
Z.ERA5 = I(xi,yi,zi,ai);

clear xi yi zi ai x y z a I

hist(Z.MLS(:) - Z.ERA5(:),100)

