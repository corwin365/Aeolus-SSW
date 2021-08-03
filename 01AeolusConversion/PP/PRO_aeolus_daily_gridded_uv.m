
%%%% EDIT: Updated to run on ubpc-2027
% also, we now apply the QC flags here rather than in the matlab files


%%%% THE PLAN
%%%% take the netcdf files of Aeolus orbits that Tim generated and grid
%%%% them into a daily mean estimated "true" u and v globally, using the
%%%% method described by Isabell Krisch where ascending and desceding
%%%% orbits are averaged to break the HLOS/u/v ambiguity.

% why don't we just do some reallly simple binning for now?
% i.e. bin the asc/desc wind, then bin the asc/desc lat lon too.
% save the binned lat lons too so you know where the meas was taken from
% advantages:
% - very simple to implement
% - isabell has done work on the error from this process
% - can easily save and regrid the binned data later
% - easy to find out what the distance was between "assumed" same asc/desc
% measurements.


% dayrange = datenum(2021,01,01):datenum(2021,01,01);
dayrange = datenum(2018,09,03):datenum(2021,07,12);

% Select QC Flags
% ErrandObs | ObsType | HLOSErr | ALL | Generic
qcflags = {'ErrandObs'};

fformat = 'mat'; % netcdf | matlab | nc | mat

plotflag = 0;
binfirst = 0;

%%%% We're gonna load multiple days now and use a day weighting.
%%%% Data are weighted centred at midnight on the specified day. This means
%%%% we need to load days either side and weight them accordingly. The FWHM
%%%% below and the dayseitherside specifiy how many days data to load.
fwhm_time = 7;                      % days
std_time = fwhm_time * (1/2.355);   % STD in days, centred on specified day.

% extra days on the start and end:
dayseitherside = 2;

% Also, make a structure to save having to load adjacent days multiple
% times:
Days = struct;
% This makes a BIG difference for speed if you're including multiple days.


%%%% DIRECTORIES:
%%%% local...
switch fformat
    case {'netcdf','nc'}
        direc = '/Users/neil/data/Aeolus/';
    case {'matlab','mat'}
        direc = '/Users/neil/data/Aeolus/matlab/newQC/';
%         direc = '/media/LNER/Hub/Aeolus/matlab/newQC/';
end
savedirec = [direc 'daily_gridded_uv_' num2str(fwhm_time) 'day/'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD ALL AEOLUS FOR TODAY:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic

for dy = 1:length(dayrange)
    
    lat = [];
    lon = [];
    alt = [];
    hloswind = [];
    qc = [];
    tim = [];
    hlosaz = [];
    
    % take the specified number of days either side (also factoring in the
    % FWHM of the gaussian window for time)
    selecteddayrange = dayrange(dy) + (-(dayseitherside+floor(std_time*2.355/2)):(dayseitherside+floor(std_time*2.355/2)-1));
    %     selecteddayrange = dayrange(dy) + (-dayseitherside:(dayseitherside-1));
    
    % deal with zero days either side
    if dayseitherside == 0
        selecteddayrange = dayrange(dy);
    end
    
    % first, check if there are any days in Days we don't need any more:
    f = fieldnames(Days);
    for g = 1:length(f)
        converteddate = datenum(f{g}(2:end),'yyyymmdd');
        if ~any(converteddate == selecteddayrange)
            Days = rmfield(Days,['d' datestr(converteddate,'yyyymmdd')]);
        end
    end
    
    % load just the single matlab file for this day:
    yyyymmdd = datestr(dayrange(dy),'yyyymmdd');
    
    disp(yyyymmdd)
    %             disp([yyyymmdd ' + ' num2str(dayseitherside) 'd either side'])
    
    %%%% load the days eitherside:
    for dd = 1:length(selecteddayrange)
        
        yyyymmdd = datestr(selecteddayrange(dd),'yyyymmdd');
        files = dir([direc '*' yyyymmdd '*.mat']);
        
        % check if we already have this day loaded:
        dyyyymmdd = ['d' yyyymmdd];
        if isfield(Days,dyyyymmdd)
            continue
        end
        
        % cope with start/end days:
        if ~isempty(files)
            
            load([direc yyyymmdd '_aeolus_hloswind.mat'])
            
            Days.(dyyyymmdd).lat        = Aeolus.lat;
            Days.(dyyyymmdd).lon        = Aeolus.lon;
            Days.(dyyyymmdd).alt        = Aeolus.alt;
            Days.(dyyyymmdd).hloswind   = Aeolus.hloswind;
            Days.(dyyyymmdd).time       = Aeolus.time;
            Days.(dyyyymmdd).hlosaz     = Aeolus.hlosaz;
            
            % combine QC flags:
            Days.(dyyyymmdd).qc     = true(size(Aeolus.lat));
            for q = 1:length(qcflags)
                Days.(dyyyymmdd).qc = Days.(dyyyymmdd).qc & Aeolus.QC_Flags.(qcflags{q});
            end
            
        end
        
    end
    
    %%%% reset yyyymmdd
    yyyymmdd = datestr(dayrange(dy),'yyyymmdd');
    
    %             return
    %     end
    
    %%%% COMBINE ALL THE SELECTED DAYS TOGETHER:
    f = fieldnames(Days);
    for g = 1:length(f)
        lat         = cat(1,lat,Days.(f{g}).lat);
        lon         = cat(1,lon,Days.(f{g}).lon);
        alt         = cat(1,alt,Days.(f{g}).alt);
        hloswind    = cat(1,hloswind,Days.(f{g}).hloswind);
        qc          = cat(1,qc,Days.(f{g}).qc);
        tim         = cat(1,tim,Days.(f{g}).time);
        hlosaz      = cat(1,hlosaz,Days.(f{g}).hlosaz);
    end
    
    %%%% apply the QC flags
    qc          = logical(qc);
    lat         = lat(qc);
    lon         = lon(qc);
    alt         = alt(qc);
    hloswind    = hloswind(qc);
    tim         = tim(qc);
    hlosaz      = hlosaz(qc);

    % apply some latitude limits:
    latlims = [-80 85];
    latinds = inrange(lat,latlims);
    lat         = lat(latinds);
    lon         = lon(latinds);
    alt         = alt(latinds);
    hloswind    = hloswind(latinds);
    tim         = tim(latinds);
    hlosaz      = hlosaz(latinds);
    
    
    %%%% WRAPAROUND:
    % add some extra bits on the +/-180 ends for wraparound:
    westend = lon < -150;
    eastend = lon >  150;
    lon = cat(1,lon(eastend)-360,lon,lon(westend)+360);
    lat = cat(1,lat(eastend),lat,lat(westend));
    alt = cat(1,alt(eastend),alt,alt(westend));
    hloswind = cat(1,hloswind(eastend),hloswind,hloswind(westend));
    tim = cat(1,tim(eastend),tim,tim(westend));
    hlosaz = cat(1,hlosaz(eastend),hlosaz,hlosaz(westend));
    
    %%%% IMPORTANT:
    % So it was good to do a bit of wraparound, but remember when you're
    % doing the zonal mean this means you'll have a slight skew to
    % locations that have been duplicated.
    % Solution: introduce an extra set of indeces that are JUST between
    % -180:180
    zm_inds = inrange(lon,[-180 180]);
    
    % split into asc/desc:
    asc = hlosaz > 180;
    desc = ~asc;
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% binny mcbinface
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    latbins = -90:2.5:90;
    lonbins = -180:22.5:180;
    zrange = 1:25;
    
    std_z       = 0.85;           % std=0.85, FHWM ~ 2km
    std_time    = 1./2.355;       % FHWM ~ 1day
    
    
    %%%% Compute the time weightings, centred at midnight today:
    w_time = exp(- ((tim - dayrange(dy)).^2) ./ (2 * std_time^2));
    w_time(w_time < 0.05) = 0;
    
    % To save a bit of time, pre-compute the gaussian weighting
    % functions for the height bins, they'll be the same each time:
    Gauss_z = struct;
    for z = 1:length(zrange)
        Gauss_z(z).vec = exp(- ((alt - zrange(z)).^2) ./ (2 * std_z^2));
        % set a 2STD limit:
        Gauss_z(z).vec(Gauss_z(z).vec < 0.05) = 0;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% First thing to do: Bin the lat and lon onto a grid to find where the
    %%%% measurements were actually made in each bin.
    % include time weights, but don't worry about altitude, it won't change
    % things much between cells.
    
    latb_asc             = nph_bin2mat(lat(asc), lon(asc), lat(asc), latbins,lonbins,'weights',w_time);
    lonb_asc             = nph_bin2mat(lat(asc), lon(asc), lon(asc), latbins,lonbins,'weights',w_time);
    latb_desc            = nph_bin2mat(lat(desc),lon(desc),lat(desc),latbins,lonbins,'weights',w_time);
    lonb_desc            = nph_bin2mat(lat(desc),lon(desc),lon(desc),latbins,lonbins,'weights',w_time);
    
    % also introduce a binned zonal mean:
    sintheta_asc_zm      = nph_bin2mat(lat(asc & zm_inds),sind(-hlosaz(asc & zm_inds)),latbins);
    sintheta_desc_zm     = nph_bin2mat(lat(desc & zm_inds),sind(-hlosaz(desc & zm_inds)),latbins);
    costheta_zm          = nph_bin2mat(lat(zm_inds),cosd(-hlosaz(zm_inds)),latbins);
    lat_zm               = nph_bin2mat(lat(zm_inds),lat(zm_inds),latbins);
    
    % rempat it to full size:
    sintheta_asc         = repmat(sintheta_asc_zm(:),1,length(lonbins),length(zrange));
    sintheta_desc        = repmat(sintheta_desc_zm(:),1,length(lonbins),length(zrange));
    costheta             = repmat(costheta_zm(:),1,length(lonbins),length(zrange));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Next, for each altitude fit the hlos wind into these bins:
    
    hloswind_asc        = nan(length(latbins),length(lonbins),length(zrange));
    hloswind_desc       = nan(length(latbins),length(lonbins),length(zrange));
    walt                = nan(length(latbins),length(lonbins),length(zrange));
    npoints             = nan(length(latbins),length(lonbins),length(zrange));
    
    % also introduce a binned zonal mean:
    vcostheta_asc_zm        = nan(length(latbins),length(zrange));
    usintheta_asc_zm        = nan(length(latbins),length(zrange));
    vcostheta_desc_zm       = nan(length(latbins),length(zrange));
    usintheta_desc_zm       = nan(length(latbins),length(zrange));
    walt_zm                 = nan(length(latbins),length(zrange));
    
    
    for z = 1:length(zrange)
        
        %     % quick check to see if there's any data here within 1FWHM of the centre
        %     % of the altitude weighting function:
        %     if isempty(hloswind(Gauss_z(z).vec > 0.5))
        
        %%%% compute weightings:
        w = Gauss_z(z).vec .* w_time;
        asc_inds    = asc  & w > 0.05;
        desc_inds   = desc & w > 0.05;
        inds = w > 0.05;
        
        % and do a weighted binning!
        hloswind_asc(:,:,z)   = nph_bin2mat(lat(asc_inds),lon(asc_inds),hloswind(asc_inds),latbins,lonbins,'weights',w(asc_inds));
        hloswind_desc(:,:,z)  = nph_bin2mat(lat(desc_inds),lon(desc_inds), hloswind(desc_inds),latbins,lonbins,'weights',w(desc_inds));
        
        % weighted altitude:
        walt(:,:,z)         = nph_bin2mat(lat(inds),lon(inds),alt(inds),latbins,lonbins,'weights',w(inds));
        
        % number of points in each bin:
        npoints(:,:,z)      = nph_bin2mat(lat(inds),lon(inds),ones(size(lon(inds))),latbins,lonbins,'method','nansum');
        
        %%%% ALSO BIN A ZONAL MEAN
        % we'll need this to check that our binned data has the same mean as
        % the zonal mean?
        walt_zm(:,z)         = nph_bin2mat(lat(inds & zm_inds),alt(inds & zm_inds),latbins,'weights',w(inds & zm_inds));
        
        % we need to break down by asc/desc in case there's a non-equal number
        % of asc/desc measurements, which will introduce a bias.
        % compute zonal mean vcostheta:
        asc_inds        = asc_inds & zm_inds;
        desc_inds       = desc_inds & zm_inds;
        IN_asc = hloswind(asc_inds);
        IN_desc = hloswind(desc_inds);
        vcostheta_asc_zm(:,z)     = nph_bin2mat(lat(asc_inds),IN_asc,latbins,'weights',w(asc_inds));
        vcostheta_desc_zm(:,z)    = nph_bin2mat(lat(desc_inds),IN_desc,latbins,'weights',w(desc_inds));
        % and now usintheta:
        IN_desc                   = -1 .* IN_desc; % flip sign before averaging
        usintheta_asc_zm(:,z)     = nph_bin2mat(lat(asc_inds),IN_asc,latbins,'weights',w(asc_inds));
        usintheta_desc_zm(:,z)    = nph_bin2mat(lat(desc_inds),IN_desc,latbins,'weights',w(desc_inds));
        
        
    end
    
    
    % % %%
    
    % set a threshold for number of data points in each bin:
    npoints_threshold = 10;
    hloswind_asc(npoints < npoints_threshold) = NaN;
    hloswind_desc(npoints < npoints_threshold) = NaN;
    
    
    % Zonal wind is a simple average, where one is flipped, then removing
    % an average of sintheta, where one is flipped:
    usintheta = nanmean(cat(4,hloswind_asc,-hloswind_desc),4);
    sintheta  = nanmean(cat(4,sintheta_asc,-sintheta_desc),4);
    u = usintheta ./ sintheta;
    
    % Meridional wind, which also contains the error term, is done by removing
    % costheta, which is symmetric for both asc and desc:
    vcostheta = nanmean(cat(4,hloswind_asc,hloswind_desc),4);
    v = vcostheta ./ costheta;
    
    %%%% and do the zonal means:
    usintheta_zm = mean(cat(3,usintheta_asc_zm,usintheta_desc_zm),3);
    vcostheta_zm = mean(cat(3,vcostheta_asc_zm,vcostheta_desc_zm),3);
    u_zm = usintheta_zm ./ squeeze(nanmean(sintheta,2));
    v_zm = vcostheta_zm ./ squeeze(nanmean(costheta,2));
    
    
    % figure;
    % hold on; pcolor(lonb_asc,latb_asc,latb_asc); shat;
    % hold on; imagesc(lonbins,latbins,-hloswind_desc(:,:,15)); ydir;
    % hold on; imagesc(lonbins,latbins,u(:,:,24)); ydir;
    % hold on; plot(lon(asc),lat(asc),'.');
    % hold on; plot(lon(desc),lat(desc),'.'); grid on
    
    % hold on; imagesc(latbins,zrange,squeeze(nanmean(u,2))'); ydir
    % [X,Y] = meshgrid(latbins,zrange);
    
    % hold on; pcolor(X,squeeze(nanmean(walt,2))',squeeze(nanmean(u,2))'); shat; grid on
    % hold on; pcolor(X,squeeze(nanmean(walt,2))',squeeze(nanmean(npoints,2))'); shat
    
    
    %%%% SUBSCRIBE AND SAVE:
    Aeolus                  = struct;
    Aeolus.Date             = datestr(dayrange(dy));
    
    Aeolus.lat              = nanmean(cat(3,latb_asc,latb_desc),3);
    Aeolus.lon              = nanmean(cat(3,lonb_asc,lonb_desc),3);
    Aeolus.walt             = walt;
    Aeolus.u                = u;
    Aeolus.v                = v;
    Aeolus.lat_zm           = lat_zm;
    Aeolus.walt_zm          = walt_zm;
    Aeolus.u_zm             = u_zm;
    Aeolus.v_zm             = v_zm;
    
    Aeolus.BinInfo.Method               = 'lat/lon binning, time/height gaussian weighting';
    Aeolus.BinInfo.latbincentres        = latbins;
    Aeolus.BinInfo.lonbincentres        = lonbins;
    Aeolus.BinInfo.altbincentres        = zrange;
    Aeolus.BinInfo.npoints_threshold    = npoints_threshold;
    Aeolus.BinInfo.std_z                = std_z;
    Aeolus.BinInfo.std_time             = std_time;
    
    
    savename = [savedirec datestr(dayrange(dy),'yyyymmdd') '_aeolus_gridded_uv.mat'];
    disp(['Saving to ' savename '...'])
    save(savename,'Aeolus');
    
    timesofar = toc;
    totaltime = timesofar / (dy/length(dayrange));
    eta = (1 - dy/length(dayrange)) .* totaltime;
    
    disp([num2str(round(eta/60)) 'mins remaining...'])
    
    
end % NEXT DAY















return






































