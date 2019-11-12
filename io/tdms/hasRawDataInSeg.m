function ccnt=hasRawDataInSeg(segCnt,ob)
%Function to check and see if a channel has raw data in a particulr
%segment.  If it does, return the index of index (ccnt).  If not present,
%return ccn=0

indexList=ob.index;
ccnt=find(indexList==segCnt);
if isempty(ccnt)
    ccnt=0;
else
    ccnt=ccnt(1);
end
end
