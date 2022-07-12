function  [vert,edges,frames,edgesLabel]=getGraph(obj)
% Philippe Roudot 2018
    if(numel(obj)==1)
        obj=fillTrackGaps(obj);
        vert=[obj.x' obj.y' obj.z'];
        edges=[1:numel(obj.f)-1 ; 2:numel(obj.f)]';
        frames=obj.f(2:end)';
        edgesLabel=ones(size(edges,1),1);
    else
        [vert,edges,frames,edgesLabel]=arrayfun(@(t) t.getGraph,obj,'unif',0);
        NID=0;
        for tIdx=1:numel(edges)
            edges{tIdx}=edges{tIdx}+NID;
            NID=NID+size(vert{tIdx},1);
            edgesLabel{tIdx}=tIdx*edgesLabel{tIdx};
        end
        vert=vertcat(vert{:});
        edges=vertcat(edges{:});
        frames=vertcat(frames{:});
        edgesLabel=vertcat(edgesLabel{:});
    end

end
