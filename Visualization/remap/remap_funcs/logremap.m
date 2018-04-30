function out = logremap(x)
% LOGREMAP Logarithmic remap
%
% //////////////////////////////////////////
% /// CLASSIFICATION: UNCLASSIFIED       ///
% //////////////////////////////////////////

[out, disp_min, disp_max] = logremap_float(x);
out = uint8(255*(out-disp_min)/(disp_max-disp_min));

end
% //////////////////////////////////////////
% /// CLASSIFICATION: UNCLASSIFIED       ///
% //////////////////////////////////////////
