function text=convertToText(bytes)
%Convert numeric bytes to the character encoding localy set in MATLAB (TDMS uses UTF-8)
text=native2unicode(bytes,'UTF-8');
end
