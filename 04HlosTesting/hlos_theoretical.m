clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute theoretical error on HLOS wind
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%possible values of u and v. Arbitrary.
u = -100:1:100;
v = -95:1:95;

%values of psi
psi = 335;%0:1:360;


%hence, compute projected values
[ui,vi,psii] = ndgrid(u,v,psi);

HLOS = (-ui .* sind(psii)) - (vi .* cosd(psii));
Uproj = -HLOS.*sind(psii);
Vproj = -HLOS.*cosd(psii);
clear HLOS
  
%find difference and ratio
delta_u = ui - Uproj; frac_u = Uproj./ui;
delta_v = vi - Vproj; frac_v = Vproj./vi;


