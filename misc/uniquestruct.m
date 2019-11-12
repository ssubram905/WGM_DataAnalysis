function ostruct = uniquestruct(istruct)
% returns a unique structure without duplicate elements
isUnique = true(size(istruct));
for ii = 1:length(istruct)-1
    for jj = ii+1:length(istruct)
        if isequal(istruct(ii),istruct(jj))
            isUnique(ii) = false;
            break;
        end
    end
end
istruct(~isUnique) = [];
ostruct = istruct;