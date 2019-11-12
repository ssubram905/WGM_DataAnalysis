function matType=LV2MatlabDataType(LVType)
%Cross Refernce Labview TDMS Data type to MATLAB
switch LVType
    case 0   %tdsTypeVoid
        matType='';
    case 1   %tdsTypeI8
        matType='int8';
    case 2   %tdsTypeI16
        matType='int16';
    case 3   %tdsTypeI32
        matType='int32';
    case 4   %tdsTypeI64
        matType='int64';
    case 5   %tdsTypeU8
        matType='uint8';
    case 6   %tdsTypeU16
        matType='uint16';
    case 7   %tdsTypeU32
        matType='uint32';
    case 8   %tdsTypeU64
        matType='uint64';
    case 9  %tdsTypeSingleFloat
        matType='single';
    case 10  %tdsTypeDoubleFloat
        matType='double';
    case 11  %tdsTypeExtendedFloat
        matType='10*char';
    case 25 %tdsTypeSingleFloat with units
        matType='Undefined';
    case 26 %tdsTypeDoubleFloat with units
        matType='Undefined';
    case 27 %tdsTypeextendedFloat with units
        matType='Undefined';
    case 32  %tdsTypeString
        matType='uint8=>char';
    case 33  %tdsTypeBoolean
        matType='bit1';
    case 68  %tdsTypeTimeStamp
        matType='2*int64';
    % Added by Haench for tdsTypeComplexSingleFloat=0x08000c,tdsTypeComplexDoubleFloat=0x10000d,
   case 524300
        matType='single';
    case 1048589
        matType='double';
    % end add haench
    otherwise
        matType='Undefined';
end

end
