function Wind = compute_geostrophic_wind_2D_FAST(Data)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute geostrophic wind from GPH data
%
%implements u = -(1/f) .* (dZ./dy)
%and        v = -(1/f) .* (dZ./dx)
%
%
%Inputs:
%  Data - struct, containing:
%     GPH [nlons x nlats x nlevels x ntimes]: geopotential HEIGHT
%     LonScale [nlons]:   longitude (degrees), -180 to +180 range
%     LatScale [nlats]:   latitude (degrees)
%     PrsScale [nlevels]: pressure (hPa)
%     TimeScale [ntimes]: Matlab time units
%
%
%   Corwin Wright, corwin.wright@trinity.oxon.org
%   28/APR/2015
%
%   Andrew Moss, a.moss@bath.ac.uk
%   13/05/2015
% 
% Improvements made to include meridional component of Geostrophic Wind.
% Also vectorised code to make it quick. Cross-checked against unvectorised
% code to verify it works. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Constants

Omega = 2.0*pi/86400.0;
g = 9.81;
Re    = 6371000.0;   
% For focus on  the tropics should use 6378000.0. 
% For high latitude should use 6371000

%% Prep
LatS = Data.LatScale(1:end-1)+diff(Data.LatScale)./2;
% Lats after differencing

fv = 2.* Omega .* sin(deg2rad(Data.LatScale));
fu = 2.* Omega .* sin(deg2rad(LatS));
% Coriolis at latitudes for u and v (Different because of taking
% differences along different axis)

Data.GPH = [Data.GPH; Data.GPH(1,:,:,:)];
Data.LonScale = [Data.LonScale; Data.LonScale(1)+360];
% Longitude completes a circle so add data to end so don't lose information
% from differencing. 

LatScale = repmat(Data.LatScale',size(Data.GPH,1),1,size(Data.GPH,3),size(Data.GPH,4));
LonScale = repmat(Data.LonScale,1,size(Data.GPH,2),size(Data.GPH,3),size(Data.GPH,4));
f_for_v = repmat(fv',size(Data.GPH,1)-1,1,size(Data.GPH,3),size(Data.GPH,4));
f_for_u = repmat(fu',size(Data.GPH,1),1,size(Data.GPH,3),size(Data.GPH,4));
% Preparing f, lat and lon for U and V calulation

dy = diff(LatScale,[],2).* (2 .* pi .* Re ./ 360);
dx = diff(LonScale,[],1).* (2 .* pi .* Re ./ 360);
% differences in latitude and longitude between adjacent points

dZ_lat = diff(Data.GPH,[],2);
dZ_lon= diff(Data.GPH,[],1);
% difference in GPH along latitude and longitude axis respectively

dZdy = dZ_lat./dy;
dZdx = dZ_lon./dx;
% division of change of GPH with latitude and longitude respectively

%% Calculation of U and V (as in equation in header)
V = dZdx .* (g./f_for_v);
U = -dZdy .* (g./f_for_u);

%% Returning Variables (In return structure 'Wind')
LonS = Data.LonScale(1:end-1)+diff(Data.LonScale)./2;

Wind.U         = U(1:end-1,:,:,:);
Wind.V         = V;
Wind.ULatScale  = LatS;
Wind.ULonScale  = Data.LonScale(1:end-1);
Wind.VLatScale  = Data.LatScale;
Wind.VLonScale  = LonS;
Wind.PrsScale  = Data.PrsScale;
Wind.TimeScale = Data.TimeScale;

end



