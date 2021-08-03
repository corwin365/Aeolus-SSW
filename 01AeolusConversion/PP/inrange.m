

% determine if input is within a given numeric range, inclusive of end values.
% OUT is logical 1 or 0.
% should work for scalars, vectors and matrices.

% OUT = inrange(IN,low,high)
% OUT = inrange(IN,[low high])
% OUT = inrange(IN,isexactlyequaltothisvalue)

function OUT = inrange(IN,low,high)

switch nargin
    case 2
        switch length(low)
            case 1 % for one scalar input, output only where it's exactly equal to this value
                OUT = IN == low;
            case 2 % for a high/low input, specify between these points. Inclusive, because it's nice to be nice.
                OUT = IN >= low(1) & IN <= low(2);
        end
    case 3
        OUT = IN >= low & IN <= high;
    otherwise
        return
end














