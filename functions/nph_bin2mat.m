

%%%% My version of our beloved bin2mat function, only this can be up to an
%%%% order of magnitude faster. Uses histcounts to do the binning, which is
%%%% rapid, but unfortunately I can't think of a way to include a function
%%%% handle for the binning (mean, sum, etc).

%%%% EDIT: Updated to support 1-D binning too.

%%%% EDIT: Note that this function has been adjusted to use bin CENTRES
%%%% rather than bin EDGES. Histcounts is great, but it only specifies bin
%%%% edges as inputs. This is annoying because if the bins edges are 1 2 3
%%%% 4, then 1.9 would be binned into element 1, even though it's much
%%%% closer to 2. So I'm gonna make the inputs bin centres.

function OUT = nph_bin2mat(varargin)

%%%% USAGE
% OUT = nph_bin2mat(x,z,xi,___)         [1-D]
% OUT = nph_bin2mat(x,y,z,xi,yi,___)    [2-D]
%
% options:
% OUT = nph_bin2mat(___,'method',['nanmean'|'nansum'],'weights',w)
%
%%%%% INPUTS: (1-D)
% x = x coords of input data
% z = input data to be binned (must be same size as x)
% xi = x bin CENTRES of the output grid
%
%%%%% INPUTS: 2-D
% x = x coords of input data
% y = y coords of input data
% z = input data to be binned (must be same size as x and y)
% xi = x bin CENTRES of the output grid
% yi = y bin CENTRES of the output grid
%
% EXAMPLES:
% OUT = nph_bin2mat(x,z,xi);
% OUT = nph_bin2mat(x,z,xi,'method','nansum');
% OUT = nph_bin2mat(x,z,xi,'weights',w);
% OUT = nph_bin2mat(x,y,z,xi,yi,'method','nansum');
% OUT = nph_bin2mat(x,y,z,xi,yi,'weights',w);


%%%%%%%% First, determine whether it's 1-D or 2-D binning we're doing:
type = 0;
% 1-D case:
if isnumeric(varargin{1}) && isnumeric(varargin{2}) && isnumeric(varargin{3})
    type = 1;
end
% 2-D case:
if length(varargin) > 3
    if isnumeric(varargin{1}) && isnumeric(varargin{2}) && isnumeric(varargin{3}) && isnumeric(varargin{4}) && isnumeric(varargin{5})
        type = 2;
    end
    if type == 0
        error('First 3 (for 1-D) or 5 (for 2-D) inputs must be numeric.')
    end
end

% Split varargin into inputs and options:
options = {};
switch type
    case 1
        x = varargin{1}; z = varargin{2}; xi = varargin{3};
        if length(varargin) > 3
            options = varargin(4:end);
        end
    case 2
        x = varargin{1};  y = varargin{2};  z = varargin{3};
        xi = varargin{4}; yi = varargin{5};
        if length(varargin) > 5
            options = varargin(6:end);
        end
end

% detemine method:
% method = 'nanmean'; % default
if ~isempty(options)
    if any(strcmpi(options,'method'))
        method = options{find(strcmpi(options,'method'))+1};
    else
        method = 'nanmean';
    end
    
    if any(strcmpi(options,'weights'))
        weighting = 1;
        w = options{find(strcmpi(options,'weights'))+1};
    else
        weighting = 0;
    end
    
    % % % %         % ensure weightings sum to one:
    % % % %         w = w ./ nansum(w(:));
    % % % %         % shouldn't need this since we divide by the sum of the
    % % % %         % weights in a bin down below
    %     switch varargin{1}
    %         case {'mean','nanmean'}
    %             method = 'nanmean';
    %         case {'sum','nansum'}
    %             method = 'nansum';
    %         case {'weights'}
    %         otherwise
    %             method = 'nanmean';
    %     end
    
else
    
    weighting = 0;
    method = 'nanmean';
    
end

% can't do weighted sums yet
if any(strcmpi(method,{'sum','nansum'})) && weighting == 1
    error('Currently only weighted mean is supported.')
end


switch type
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 2-D BINNING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 2
        
        if ~ismonotonic(xi) || ~ismonotonic(yi)
            error('Sorry, output grids must be monotonically increasing.')
        end
        
        % linearise everything:
        x = x(:);
        y = y(:);
        z = z(:);
        xi = xi(:);
        yi = yi(:);
        
        % remove any NaNs:
        nanlocs = isnan(z) | isnan(x) | isnan(y);
        x = x(~nanlocs); y = y(~nanlocs); z = z(~nanlocs);
        
        %%%% Convert bin CENTRES to bin EDGES for use with histcounts:
        dxi = diff(xi); dyi = diff(yi);
        xi_edges = [xi - dxi([1 1:end])./2 ; xi(end) + dxi(end)/2];
        yi_edges = [yi - dyi([1 1:end])./2 ; yi(end) + dyi(end)/2];
        
        % I *think*, using histcounts, there will never be anything allocated to
        % the final bin edge index unless you specify ...,'includedege','right')?
        % This means we can trim it off in my bin centres method?
        
        % linearise everything:
        z = z(:);
        [~,~,~,xbin,ybin] = histcounts2(x(:),y(:),xi_edges(:),yi_edges(:));
        
        %%%% Important point: although the bin locations here correspond to the
        %%%% xi_edges/yi_edges data, they should actually correspond perfectly to
        %%%% the input bin CENTRES data, because nothing with ever be put in the
        %%%% final "edge" bin of xi_edges/yi_edges. I think.
        %%%% This means our output should always be the same size as the input, and
        %%%% we shouldn't get any cases of allocating outside the data limits. In
        %%%% theory, anyway.
        
        % remove nans and zeros (zeros are where a data point doesn't fall in any bin):
        goodinds = xbin ~= 0 & ybin ~= 0 & ~isnan(z);
        z = z(goodinds);
        xbin = xbin(goodinds);
        ybin = ybin(goodinds);
        
        % preallocate output
        osz = [length(xi) length(yi)];
        OUT         = zeros(osz);
        W           = zeros(osz);
        emptycount  = zeros(osz);
        
        % % try a loop, can't think of a better way to do it.
        switch weighting
            case 0 % just a standard mean
                switch method
                    
                    case {'nanmean','mean'}
                        count = ones(osz);
                        for i = 1:length(z)
                            OUT(xbin(i),ybin(i)) = OUT(xbin(i),ybin(i)) + z(i);
                            count(xbin(i),ybin(i)) = count(xbin(i),ybin(i)) + 1;
                            emptycount(xbin(i),ybin(i)) = 1;
                        end
                        OUT = OUT ./ count;
                        OUT(emptycount == 0) = NaN;
                        
                    case {'nansum','sum'}
                        for i = 1:length(z)
                            OUT(xbin(i),ybin(i)) = OUT(xbin(i),ybin(i)) + z(i);
                            emptycount(xbin(i),ybin(i)) = 1;
                        end
                        OUT(emptycount == 0) = NaN;
                        
                end
                % turns out loop is pretty fast because no functions are called in it, I
                % think...
                
            case 1 % NEW WEIGHTED MEAN
                
                switch method
                    
                    case {'nanmean','mean'}
                        for i = 1:length(z)
                            OUT(xbin(i),ybin(i)) = OUT(xbin(i),ybin(i)) + (z(i) .* w(i));
                            W(xbin(i),ybin(i)) = W(xbin(i),ybin(i)) + w(i);
                            emptycount(xbin(i),ybin(i)) = 1;
                        end
                        OUT = OUT ./ W;
                        OUT(emptycount == 0) = NaN;
                        
                end
                
                
        end % switch weighting
        
        
        
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% 1-D BINNING
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 1
        
        if ~ismonotonic(xi)
            error('Sorry, output grid must be monotonically increasing.')
        end
        
        % linearise everything:
        x = x(:);
        z = z(:);
        xi = xi(:);
        
        % remove any NaNs:
        nanlocs = isnan(z) | isnan(x);
        x = x(~nanlocs); z = z(~nanlocs);
        
        %%%% Convert bin CENTRES to bin EDGES for use with histcounts:
        dxi = diff(xi);
        xi_edges = [xi - dxi([1 1:end])./2 ; xi(end) + dxi(end)/2];
        
        % I *think*, using histcounts, there will never be anything allocated to
        % the final bin edge index unless you specify ...,'includedege','right')?
        % This means we can trim it off in my bin centres method?
        
        % linearise everything:
        [~,~,xbin] = histcounts(x(:),xi_edges(:));
        
        %%%% Important point: although the bin locations here correspond to the
        %%%% xi_edges/yi_edges data, they should actually correspond perfectly to
        %%%% the input bin CENTRES data, because nothing with ever be put in the
        %%%% final "edge" bin of xi_edges/yi_edges. I think.
        %%%% This means our output should always be the same size as the input, and
        %%%% we shouldn't get any cases of allocating outside the data limits. In
        %%%% theory, anyway.
        
        % remove nans and zeros (zeros are where a data point doesn't fall in any bin):
        goodinds = xbin ~= 0 & ~isnan(z);
        z = z(goodinds);
        xbin = xbin(goodinds);
        
        % preallocate output
        osz = size(xi);
        OUT         = zeros(osz);
        W           = zeros(osz);
        emptycount  = zeros(osz);
        
        % % try a loop, can't think of a better way to do it.
        switch weighting
            case 0 % just a standard mean
                switch method
                    
                    case {'nanmean','mean'}
                        count = ones(osz);
                        for i = 1:length(z)
                            OUT(xbin(i)) = OUT(xbin(i)) + z(i);
                            count(xbin(i)) = count(xbin(i)) + 1;
                            emptycount(xbin(i)) = 1;
                        end
                        OUT = OUT ./ count;
                        OUT(emptycount == 0) = NaN;
                        
                    case {'nansum','sum'}
                        for i = 1:length(z)
                            OUT(xbin(i)) = OUT(xbin(i)) + z(i);
                            emptycount(xbin(i)) = 1;
                        end
                        OUT(emptycount == 0) = NaN;
                        
                end
                % turns out loop is pretty fast because no functions are called in it, I
                % think...
                
            case 1 % NEW WEIGHTED MEAN
                
                switch method
                    
                    case {'nanmean','mean'}
                        for i = 1:length(z)
                            OUT(xbin(i)) = OUT(xbin(i)) + (z(i) .* w(i));
                            W(xbin(i)) = W(xbin(i)) + w(i);
                            emptycount(xbin(i)) = 1;
                        end
                        OUT = OUT ./ W;
                        OUT(emptycount == 0) = NaN;
                        
                end
                
                
        end % switch weighting
        
end % end switch for 1/2-D binning



