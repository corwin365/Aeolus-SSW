clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute theoretical error on HLOS wind
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%possible values of u and v. Arbitrary.
u = -100:1:100;
v = -100:1:100;

%values of psi
psi = 0:1:360;


%hence, compute projected values
[ui,vi,psii] = ndgrid(u,v,psi);

HLOS = (-ui .* sind(psii)) - (vi .* cosd(psii));
Uproj = -HLOS.*sind(psii);
Vproj = -HLOS.*cosd(psii);
  

%difference?
delta_u = ui - Uproj;
delta_v = vi - Vproj;


%plots made by hand, but decided the practical ERA5 version was more informative