function s = getSparse(obj)
    m = obj.getMatrix;
    m = m + eps;
    m(isnan(m)) = 0;
    s = sparse(m);
end
