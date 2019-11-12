function [DataStructure,GroupNames]=postProcess(ob,index)
%Re-organize the 'ob' structure into a more user friendly format for output.


DataStructure.Root=[];
DataStructure.MeasuredData.Name=[];
DataStructure.MeasuredData.Data=[];

obFieldNames=fieldnames(index);

cntData=1;

for i=1:numel(obFieldNames)
    
    cname=obFieldNames{i};
    
    if strcmp(index.(cname).long_name,'Root')
        
        DataStructure.Root.Name=index.(cname).long_name;
        
        %Assign all the 'Property' values
        if isfield(index.(cname),'PropertyInfo')
            for p=1:numel(index.(cname).PropertyInfo)
                cfield=index.(cname).PropertyInfo(p).FieldName;
                if isfield(index.(cname).(cfield),'datatype')
                    DataType=index.(cname).(cfield).datatype;
                else
                    %ASSUME a 'string' data type
                    DataType='String';
                end
                DataStructure.Root.Property(p).Name=index.(cname).PropertyInfo(p).Name;
                
                switch DataType
                    case 'String'
                        if iscell(index.(cname).(cfield).value)
                            Value=index.(cname).(cfield).value';
                        else
                            Value=cellstr(index.(cname).(cfield).value);
                        end
                        
                    case 'Time'
                        clear Value
                        if index.(cname).(cfield).cnt==1
                            if iscell(index.(cname).(cfield).value)
                                Value=datestr(cell2mat(index.(cname).(cfield).value),'dd-mmm-yyyy HH:MM:SS');
                            else
                                Value=datestr(index.(cname).(cfield).value,'dd-mmm-yyyy HH:MM:SS');
                            end
                        else
                            Value=cell(index.(cname).(cfield).cnt,1);
                            for c=1:index.(cname).(cfield).cnt
                                if iscell(index.(cname).(cfield).value)
                                    Value(c)={datestr(cell2mat(index.(cname).(cfield).value),'dd-mmm-yyyy HH:MM:SS')};
                                else
                                    Value(c)={datestr(index.(cname).(cfield).value,'dd-mmm-yyyy HH:MM:SS')};
                                end
                            end
                        end
                        
                    case 'Numeric'
                        if isfield(index.(cname).(cfield),'cnt')
                            Value=NaN(index.(cname).(cfield).cnt,1);
                        else
                            if iscell(index.(cname).(cfield).value)
                                Value=NaN(numel(cell2mat(index.(cname).(cfield).value)),1);
                            else
                                Value=NaN(numel(index.(cname).(cfield).value),1);
                            end
                        end
                        for c=1:numel(Value)
                            if iscell(index.(cname).(cfield).value)
                                Value(c)=index.(cname).(cfield).value{c};
                            else
                                Value(c)=index.(cname).(cfield).value(c);
                            end
                        end
                    otherwise
                        e=errordlg(sprintf(['No format defined for Data Type ''%s'' in the private function ''postProcess'' '...
                            'within %s.m.'],index.(cname).(cfield).datatype,mfilename),'Undefined Property Data Type');
                        uiwait(e)
                        return
                end
                if isempty(Value)
                    DataStructure.Root.Property(p).Value=[];
                else
                    DataStructure.Root.Property(p).Value=Value;
                end
            end
        end
        
        
    end
    
    DataStructure.MeasuredData(cntData).Name=index.(cname).long_name;
    %Should only need the 'ShortName' for debugging the function
    %DataStructure.MeasuredData(cntData).ShortName=cname;
    if (isfield(ob,cname))
        if isfield(ob.(cname),'data')
            DataStructure.MeasuredData(cntData).Data=ob.(cname).data;
            %The following field is redundant because the information can be obtained from the size of the 'Data' field.
            DataStructure.MeasuredData(cntData).Total_Samples=ob.(cname).nsamples;
        else
            DataStructure.MeasuredData(cntData).Data=[];
            DataStructure.MeasuredData(cntData).Total_Samples=0;
        end
    else
        DataStructure.MeasuredData(cntData).Data=[];
        DataStructure.MeasuredData(cntData).Total_Samples=0;
    end
    
    %Assign all the 'Property' values
    if isfield(index.(cname),'PropertyInfo')
        for p=1:numel(index.(cname).PropertyInfo)
            cfield=index.(cname).PropertyInfo(p).FieldName;
            DataStructure.MeasuredData(cntData).Property(p).Name=index.(cname).(cfield).name;
            
            if strcmpi(DataStructure.MeasuredData(cntData).Property(p).Name,'Root')
                Value=index.(cname).(cfield).value;
            else
                
                switch index.(cname).(cfield).datatype
                    case 'String'
                        clear Value
                        if index.(cname).(cfield).cnt==1
                            if iscell(index.(cname).(cfield).value)
                                Value=char(index.(cname).(cfield).value);
                            else
                                Value=index.(cname).(cfield).value;
                            end
                        else
                            Value=cell(index.(cname).(cfield).cnt,1);
                            for c=1:index.(cname).(cfield).cnt
                                if iscell(index.(cname).(cfield).value)
                                    Value(c)=index.(cname).(cfield).value;
                                else
                                    Value(c)={index.(cname).(cfield).value};
                                end
                            end
                        end
                        
                    case 'Time'
                        clear Value
                        if index.(cname).(cfield).cnt==1
                            if iscell(index.(cname).(cfield).value)
                                Value=datestr(cell2mat(index.(cname).(cfield).value),'dd-mmm-yyyy HH:MM:SS');
                            else
                                Value=datestr(index.(cname).(cfield).value,'dd-mmm-yyyy HH:MM:SS');
                            end
                        else
                            Value=cell(index.(cname).(cfield).cnt,1);
                            for c=1:index.(cname).(cfield).cnt
                                if iscell(index.(cname).(cfield).value)
                                    Value(c)={datestr(cell2mat(index.(cname).(cfield).value),'dd-mmm-yyyy HH:MM:SS')};
                                else
                                    Value(c)={datestr(index.(cname).(cfield).value,'dd-mmm-yyyy HH:MM:SS')};
                                end
                            end
                        end
                        
                    case 'Numeric'
                        if isfield(index.(cname).(cfield),'cnt')
                            Value=NaN(index.(cname).(cfield).cnt,1);
                        else
                            if iscell(index.(cname).(cfield).value)
                                Value=NaN(numel(cell2mat(index.(cname).(cfield).value)),1);
                            else
                                Value=NaN(numel(index.(cname).(cfield).value),1);
                            end
                        end
                        for c=1:numel(Value)
                            if iscell(index.(cname).(cfield).value)
                                Value(c)=index.(cname).(cfield).value{c};
                            else
                                Value(c)=index.(cname).(cfield).value(c);
                            end
                        end
                        
                    otherwise
                        e=errordlg(sprintf(['No format defined for Data Type ''%s'' in the private function ''postProcess'' '...
                            'within %s.m.'],index.(cname).(cfield).datatype,mfilename),'Undefined Property Data Type');
                        uiwait(e)
                        return
                end
            end
            if isempty(Value)
                DataStructure.MeasuredData(cntData).Property(p).Value=[];
            else
                DataStructure.MeasuredData(cntData).Property(p).Value=Value;
            end
        end
    else
        DataStructure.MeasuredData(cntData).Property=[];
    end
    
    cntData = cntData + 1;
end %'end' for the 'groups/channels' loop

%Extract the Group names
GroupIndices=false(numel(DataStructure.MeasuredData),1);
for d=1:numel(DataStructure.MeasuredData)
    
    if ~strcmpi(DataStructure.MeasuredData(d).Name,'Root')
        if (DataStructure.MeasuredData(d).Total_Samples==0)
            fs=strfind(DataStructure.MeasuredData(d).Name,'/');
            if (isempty(fs))
                GroupIndices(d)=true;
            end
        end
    end
    
end
if any(GroupIndices)
    GroupNames=sort({DataStructure.MeasuredData(GroupIndices).Name})';
else
    GroupNames=[];
end

end
