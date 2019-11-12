function sz=getDataSize(LVType)
%Get the number of bytes for each LV data type. See LV2MatlabDataType.
switch(LVType)
    case 0
        sz=0;
    case {1,5,33}
        sz=1;
    case 68
        sz=16;
    case {8,10}
        sz=8;
    case {3,7,9}
        sz=4;
    case {2,6}
        sz=2;
    case 32
        e=errordlg('Do not call the getDataSize function for strings.  Their size is written in the data file','Error');
        uiwait(e)
        sz=NaN;
    case 11
        sz=10;
    % Added by Haench for tdsTypeComplexSingleFloat=0x08000c,tdsTypeComplexDoubleFloat=0x10000d,
    case 524300
        sz=8;
    case 1048589
        sz=16;
    % end add haench
    otherwise
        error('LVData type %d is not defined',LVType)
end
end
